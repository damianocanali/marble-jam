import Foundation

/// The player's songs, one JSON file each in a folder. Unreadable files are skipped, never fatal.
final class SongStore {
    static let demoName = "Twinkle Twinkle"
    let folder: URL

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
        try JSONEncoder().encode(s).write(to: url(s.id), options: .atomic)
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

    func duplicate(_ id: UUID) -> Song? {
        guard let s = song(id) else { return nil }
        let names = Set(all().map(\.name))
        var name = "\(s.name) copy", k = 2
        while names.contains(name) { name = "\(s.name) copy \(k)"; k += 1 }
        return try? save(Song(name: name, course: s.course, instrument: s.instrument))
    }

    func delete(_ id: UUID) { try? FileManager.default.removeItem(at: url(id)) }

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
    @discardableResult func resetDemo() -> Song {
        all().filter(\.isDemo).forEach { delete($0.id) }
        var s = Song(name: Self.demoName, course: Engine.demo())
        s.isDemo = true
        return (try? save(s)) ?? s
    }
}
