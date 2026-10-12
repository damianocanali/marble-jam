import Foundation

/// The player's songs, one JSON file each in a folder. Unreadable files are skipped, never fatal.
/// With a `mirror` (the iCloud Drive folder) every change is copied there too, and `syncWithMirror` brings in other devices'.
final class SongStore {
    static let demoName = "Twinkle Twinkle"
    static let demoID = UUID(uuidString: "00000000-0000-4000-8000-00000000D3E0")!
    let folder: URL
    var mirror: URL? {
        didSet { if let mirror { try? FileManager.default.createDirectory(at: mirror, withIntermediateDirectories: true) } }
    }

    init(folder: URL) {
        self.folder = folder
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    static func appFolder() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Songs")
    }

    private func url(_ id: UUID) -> URL { folder.appendingPathComponent("\(id.uuidString).json") }

    /// Every readable song, most recently changed first.
    func all() -> [Song] {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "json" }.compactMap { file in
            do { return try JSONDecoder().decode(Song.self, from: Data(contentsOf: file)) } catch {
                print("SongStore: skipped \(file.lastPathComponent): \(error)")
                return nil
            }
        }
        .sorted { $0.modified > $1.modified }
    }

    func song(_ id: UUID) -> Song? { try? JSONDecoder().decode(Song.self, from: Data(contentsOf: url(id))) }

    /// Writes the song (atomically) and returns it with its new `modified` date.
    @discardableResult func save(_ song: Song) throws -> Song {
        var s = song
        s.modified = Date()
        let data = try JSONEncoder().encode(s)
        try data.write(to: url(s.id), options: .atomic)
        if let mirror { try? data.write(to: mirror.appendingPathComponent(url(s.id).lastPathComponent), options: .atomic) }
        return s
    }

    func newSong() -> Song {
        let used = all().compactMap { s -> Int? in s.name.hasPrefix("Untitled ") ? Int(s.name.dropFirst("Untitled ".count)) : nil }
        let s = Song(name: "Untitled \((used.max() ?? 0) + 1)", course: Course())
        return (try? save(s)) ?? s
    }

    @discardableResult func rename(_ id: UUID, to name: String) -> Bool {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty, var s = song(id) else { return false }
        s.name = n
        return (try? save(s)) != nil
    }

    /// `base`, or "<base> copy", "<base> copy 2", ... whichever is free.
    private func uniqueName(_ base: String, startWithCopy: Bool) -> String {
        let names = Set(all().map(\.name))
        if !startWithCopy && !names.contains(base) { return base }
        var name = "\(base) copy", k = 2
        while names.contains(name) { name = "\(base) copy \(k)"; k += 1 }
        return name
    }

    func duplicate(_ id: UUID) -> Song? {
        guard let s = song(id) else { return nil }
        return try? save(Song(name: uniqueName(s.name, startWithCopy: true), course: s.course, instrument: s.instrument))
    }

    /// Saves a ready-made song (from a holiday shelf) as the player's own.
    func addCopy(of template: Song) -> Song {
        let s = Song(name: uniqueName(template.name, startWithCopy: false), course: template.course, instrument: template.instrument)
        return (try? save(s)) ?? s
    }

    /// Removes the song and leaves a small "deleted" marker, so a copy on another device doesn't bring it back.
    func delete(_ id: UUID) {
        for dir in [folder, mirror].compactMap({ $0 }) {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent("\(id.uuidString).json"))
            try? Data().write(to: dir.appendingPathComponent("\(id.uuidString).deleted"))
        }
    }

    /// Two-way merge with the mirror: deletions win, otherwise the more recently changed copy of each song wins.
    /// Songs iCloud hasn't downloaded yet are asked for and picked up next time.
    func syncWithMirror() {
        guard let mirror else { return }
        let fm = FileManager.default
        func names(_ dir: URL) -> [String] { (try? fm.contentsOfDirectory(atPath: dir.path)) ?? [] }
        for name in names(mirror) where name.hasPrefix(".") && name.hasSuffix(".icloud") {
            try? fm.startDownloadingUbiquitousItem(at: mirror.appendingPathComponent(String(name.dropFirst().dropLast(".icloud".count))))
        }
        func ids(_ ext: String) -> Set<String> {
            Set((names(folder) + names(mirror)).filter { $0.hasSuffix(".\(ext)") && !$0.hasPrefix(".") }.map { String($0.dropLast(ext.count + 1)) })
        }
        let deleted = ids("deleted")
        for id in deleted {
            for dir in [folder, mirror] {
                try? fm.removeItem(at: dir.appendingPathComponent("\(id).json"))
                let marker = dir.appendingPathComponent("\(id).deleted")
                if !fm.fileExists(atPath: marker.path) { try? Data().write(to: marker) }
            }
        }
        for id in ids("json").subtracting(deleted) {
            let here = folder.appendingPathComponent("\(id).json"), there = mirror.appendingPathComponent("\(id).json")
            func read(_ u: URL) -> (data: Data, modified: Date)? {
                guard let d = try? Data(contentsOf: u), let s = try? JSONDecoder().decode(Song.self, from: d) else { return nil }
                return (d, s.modified)
            }
            switch (read(here), read(there)) {
            case let (a?, b?) where a.modified > b.modified: try? a.data.write(to: there, options: .atomic)
            case let (a?, b?) where b.modified > a.modified: try? b.data.write(to: here, options: .atomic)
            case let (a?, nil): try? a.data.write(to: there, options: .atomic)
            case let (nil, b?): try? b.data.write(to: here, options: .atomic)
            default: break
            }
        }
    }

    /// Once per install: the old single course becomes "My First Song", and the demo is added.
    func migrateIfNeeded(defaults: UserDefaults) {
        guard !defaults.bool(forKey: "songs.migrated.v1") else { return }
        if let d = defaults.data(forKey: "course.v1"), let c = try? JSONDecoder().decode(Course.self, from: d), !c.pads.isEmpty {
            _ = try? save(Song(name: "My First Song", course: c))
        }
        resetDemo()
        defaults.set(true, forKey: "songs.migrated.v1")
    }

    /// A fresh "Twinkle Twinkle", replacing the built-in one (never a player's song, whatever its name).
    /// It always has the same id, so every device shares one copy instead of syncing a demo each.
    @discardableResult func resetDemo() -> Song {
        all().filter { $0.isDemo && $0.id != Self.demoID }.forEach { delete($0.id) }
        for dir in [folder, mirror].compactMap({ $0 }) { try? FileManager.default.removeItem(at: dir.appendingPathComponent("\(Self.demoID.uuidString).deleted")) }
        var s = Song(name: Self.demoName, course: Engine.demo())
        s.id = Self.demoID; s.isDemo = true
        return (try? save(s)) ?? s
    }
}
