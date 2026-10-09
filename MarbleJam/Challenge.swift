import Foundation

/// One challenge level. It is generated from a working solution course, so it can always be solved.
struct Challenge: Identifiable {
    enum Goal { case melody, fix, target(x: Double, y: Double) }

    let id: String                 // "w2-5"
    let world: Int
    let number: Int
    let title: String
    let goal: Goal
    let instrument: Instrument
    let solution: Course
    let start: Course              // what the player begins with
    let locked: Set<UUID>          // pieces that can't be moved, tilted, re-noted or deleted
    let tray: [Pad]                // pieces the player can add, each first appearing at a hint spot
    let par: Int                   // target: the solution's number of pieces
    let notes: [Int]               // melody/fix: the tune's notes in order (MIDI)
    var season: String? = nil      // holiday worlds: open only during that holiday

    static let cupRadius = 30.0

    var goalText: String {
        switch goal {
        case .melody: "Place the missing notes so the tune plays."
        case .fix: "Move the loose pads so every note plays on the beat."
        case .target: "Get the marble into the cup."
        }
    }

    /// 0–3 stars for a course (`placed`: tray pieces used).
    func stars(for course: Course, placed: Int) -> Int {
        let run = Engine.simulate(course)
        switch goal {
        case .melody, .fix:
            guard run.hits.map({ Notes.midi(course.pads[$0.pad]) }) == notes else { return 0 }      // every note, in order
            return Celebration.stars(onBeat: run.hits.filter { Engine.isOnBeat($0.time) }.count, total: run.hits.count)
        case let .target(x, y):
            guard Self.passes(run, x: x, y: y) else { return 0 }
            return placed <= par ? 3 : placed == par + 1 ? 2 : 1
        }
    }

    /// Whether the marble's path comes within the cup's radius of (x, y).
    static func passes(_ run: Run, x: Double, y: Double) -> Bool {
        let p = run.path
        guard p.count >= 4 else { return false }
        var i = 0
        while i + 3 < p.count {
            let ax = p[i], ay = p[i + 1], ex = p[i + 2] - ax, ey = p[i + 3] - ay, l2 = max(ex * ex + ey * ey, 1e-9)
            let u = max(0, min(1, ((x - ax) * ex + (y - ay) * ey) / l2))
            if hypot(x - ax - ex * u, y - ay - ey * u) < cupRadius { return true }
            i += 2
        }
        return false
    }
}

/// The 30 levels in 5 worlds.
enum Challenges {
    static let worldNames = ["First Notes", "Fix It", "Bullseye", "Ramps", "Maestro", "🎃 Halloween", "🦃 Thanksgiving", "🎄 Christmas"]

    /// Holiday worlds (6: Halloween, 7: Thanksgiving, 8: Christmas), built from the holiday songs; shown only during the holiday.
    static let holiday: [Challenge] = {
        let h = Seasons.all[0].songs, t = Seasons.all[1].songs, x = Seasons.all[2].songs
        let king = h[0], toccata = h[1], funeral = h[2], gather = t[0], comeYe = t[1], gifts = t[2]
        let jingle = x[0], deck = x[1], wish = x[2], silent = x[3]
        return [
            melody(6, 1, king, notes: 16, remove: [3, 7, 11], season: "halloween"),
            fix(6, 2, toccata, notes: 14, loose: [2, 6, 10], season: "halloween"),
            target(6, 3, funeral, base: 5, pieces: [.bar, .bar], season: "halloween"),
            melody(6, 4, funeral, notes: 16, remove: [4, 9, 13], season: "halloween"),
            fix(6, 5, king, notes: 26, loose: [4, 10, 16, 22], season: "halloween"),
            target(6, 6, toccata, base: 6, pieces: [.ramp, .bar], season: "halloween"),
            melody(7, 1, comeYe, notes: 14, remove: [3, 8, 11], season: "thanksgiving"),
            fix(7, 2, gather, notes: 15, loose: [3, 8, 12], season: "thanksgiving"),
            target(7, 3, gifts, base: 5, pieces: [.bar, .bar], season: "thanksgiving"),
            melody(7, 4, gifts, notes: 15, remove: [2, 6, 10, 13], season: "thanksgiving"),
            fix(7, 5, comeYe, notes: 28, loose: [4, 10, 16, 22], season: "thanksgiving"),
            target(7, 6, comeYe, base: 6, pieces: [.ramp, .bar], season: "thanksgiving"),
            melody(8, 1, jingle, notes: 11, remove: [3, 7], season: "christmas"),
            fix(8, 2, wish, notes: 15, loose: [3, 8, 12], season: "christmas"),
            target(8, 3, silent, base: 5, pieces: [.bar, .bar], season: "christmas"),
            melody(8, 4, deck, notes: 17, remove: [3, 7, 12, 15], season: "christmas"),
            fix(8, 5, silent, notes: 20, loose: [3, 8, 13, 17], season: "christmas"),
            target(8, 6, jingle, base: 6, pieces: [.ramp, .bar, .ramp], season: "christmas"),
        ]
    }()

    /// Level ids without building any level (building runs the engine many times): stars can be counted from these at launch.
    static let mainIDs: [String] = (1...5).flatMap { w in (1...6).map { "w\(w)-\($0)" } }
    static let holidayWorlds = ["halloween": 6, "thanksgiving": 7, "christmas": 8]
    static func holidayIDs(_ season: String) -> [String] { holidayWorlds[season].map { w in (1...6).map { "w\(w)-\($0)" } } ?? [] }

    /// Main and holiday levels together (for lookups and tests).
    static var everything: [Challenge] { all + holiday }

    static let all: [Challenge] = {
        let jingle = Seasons.all[2].songs[0], deck = Seasons.all[2].songs[1], silent = Seasons.all[2].songs[3]
        let s = Songbook.self
        return [
            melody(1, 1, s.twinkle, notes: 7, remove: [4]),
            melody(1, 2, s.twinkle, notes: 14, remove: [3, 10]),
            melody(1, 3, s.baaBaa, notes: 9, remove: [2, 6]),
            melody(1, 4, s.rowYourBoat, notes: 10, remove: [2, 5, 8]),
            melody(1, 5, s.hickoryDickory, notes: 8, remove: [1, 4, 6]),
            melody(1, 6, s.odeToJoy, notes: 15, remove: [3, 7, 10, 13]),
            fix(2, 1, s.twinkle, notes: 14, loose: [5]),
            fix(2, 2, s.baaBaa, notes: 16, loose: [3, 10]),
            fix(2, 3, s.popGoesTheWeasel, notes: 14, loose: [2, 7, 11]),
            fix(2, 4, s.happyBirthday, notes: 12, loose: [3, 6, 9]),
            fix(2, 5, s.odeToJoy, notes: 30, loose: [5, 12, 18, 25]),
            fix(2, 6, jingle, notes: 20, loose: [3, 8, 13, 17]),
            target(3, 1, s.twinkle, base: 4, pieces: [.bar]),
            target(3, 2, s.rowYourBoat, base: 5, pieces: [.bar]),
            target(3, 3, s.baaBaa, base: 5, pieces: [.bar, .bar]),
            target(3, 4, s.popGoesTheWeasel, base: 6, pieces: [.bar, .bar]),
            target(3, 5, s.hickoryDickory, base: 6, pieces: [.bar, .bar, .bar]),
            target(3, 6, s.odeToJoy, base: 8, pieces: [.bar, .bar, .bar]),
            target(4, 1, s.twinkle, base: 3, pieces: [.ramp]),
            target(4, 2, s.rowYourBoat, base: 4, pieces: [.ramp, .bar]),
            target(4, 3, s.baaBaa, base: 5, pieces: [.bar, .ramp]),
            target(4, 4, s.popGoesTheWeasel, base: 4, pieces: [.ramp, .ramp]),
            target(4, 5, s.hickoryDickory, base: 5, pieces: [.ramp, .bar, .ramp]),
            target(4, 6, s.odeToJoy, base: 6, pieces: [.bar, .ramp, .bar, .ramp]),
            melody(5, 1, s.happyBirthday, notes: 25, remove: [2, 6, 10, 14, 18, 22]),
            fix(5, 2, s.rowYourBoat, notes: 27, loose: [3, 8, 12, 17, 21]),
            target(5, 3, s.odeToJoy, base: 6, pieces: [.bar, .ramp, .bar, .bar]),
            melody(5, 4, deck, notes: 24, remove: [3, 7, 11, 15, 19, 22]),
            fix(5, 5, silent, notes: 24, loose: [2, 6, 10, 14, 18, 22]),
            melody(5, 6, s.odeToJoy, notes: 40, remove: [4, 9, 14, 19, 24, 29, 34, 38]),
        ]
    }()

    // MARK: generators

    private static func tune(_ c: Course) -> [Int] { Engine.simulate(c).hits.map { Notes.midi(c.pads[$0.pad]) } }

    /// Where a tray piece first appears: mirrored across the screen from its real spot, lying flat.
    private static func hint(for p: Pad) -> Pad {
        var h = p; h.id = UUID(); h.x = min(Rules.width - 60, max(60, Rules.width - p.x)); h.angle = 0
        return h
    }

    private static func melody(_ w: Int, _ n: Int, _ r: SongRecipe, notes: Int, remove: [Int], season: String? = nil) -> Challenge {
        let solution = r.prefix(notes).course(), cut = Set(remove)
        var start = solution; start.pads = solution.pads.enumerated().filter { !cut.contains($0.offset) }.map(\.element)
        return Challenge(id: "w\(w)-\(n)", world: w, number: n, title: r.name, goal: .melody, instrument: r.instrument,
                         solution: solution, start: start, locked: Set(start.pads.map(\.id)),
                         tray: remove.map { hint(for: solution.pads[$0]) }, par: remove.count, notes: tune(solution), season: season)
    }

    private static func fix(_ w: Int, _ n: Int, _ r: SongRecipe, notes: Int, loose: [Int], season: String? = nil) -> Challenge {
        let solution = r.prefix(notes).course()
        var start = solution
        for (k, i) in loose.enumerated() {                                   // knock each loose pad sideways, down and askew
            let side: Double = k % 2 == 0 ? 1 : -1
            let moved = Rules.clampPad(x: start.pads[i].x + side * 70, y: start.pads[i].y + 35)
            start.pads[i].x = moved.x; start.pads[i].y = moved.y
            start.pads[i].angle = Rules.clampAngle(start.pads[i].angle - side * 0.3)
        }
        let looseIDs = Set(loose.map { solution.pads[$0].id })
        return Challenge(id: "w\(w)-\(n)", world: w, number: n, title: r.name, goal: .fix, instrument: r.instrument,
                         solution: solution, start: start, locked: Set(start.pads.map(\.id)).subtracting(looseIDs),
                         tray: [], par: 0, notes: tune(solution), season: season)
    }

    private static func target(_ w: Int, _ n: Int, _ r: SongRecipe, base: Int, pieces: [Pad.Kind], season: String? = nil) -> Challenge {
        let start = r.prefix(base).course()
        var solution = start
        for (k, kind) in pieces.enumerated() {                               // add each piece where the marble goes next
            let note = r.melody[(base + k) % r.melody.count].note
            let ok = kind == .ramp ? Engine.rampAdd(&solution, note: note)
                : [1.0, 1.5, 2, 3].contains { b in Engine.smartAdd(&solution, beats: b, note: note) }
            precondition(ok, "challenge w\(w)-\(n): couldn't place piece \(k)")
        }
        // the cup sits on the solution's path just after its last piece, somewhere the start course alone doesn't reach
        let run = Engine.simulate(solution), tl = run.hits.last?.time ?? 0, without = Engine.simulate(start)
        let spots = [0.4, 0.55, 0.3, 0.7, 0.85, 1.0, 0.2, 1.2].map { run.position(at: min(tl + $0, run.duration - 0.05)) }
        guard let cup = spots.first(where: { (70...650).contains($0.x) && !Challenge.passes(without, x: $0.x, y: $0.y) }) else {
            preconditionFailure("challenge w\(w)-\(n): every cup spot is reachable without pieces")
        }
        // Tray pieces first appear at hint spots; move the spots until no set of untouched pieces lands the marble in the cup.
        for attempt in 0..<12 {
            let lift = Double(attempt) * 90, side: Double = attempt % 2 == 0 ? 1 : -1
            let real = solution.pads.suffix(pieces.count).map { p -> Pad in
                var h = hint(for: p); h.y -= lift; h.x = min(Rules.width - 60, max(60, h.x + side * Double(attempt) * 25)); return h
            }
            let spares = (pieces.contains(.ramp) ? [Pad.Kind.bar, .ramp] : [.bar, .bar]).enumerated().map { k, kind in
                Pad(kind: kind, x: k == 0 ? 160 : Rules.width - 160, y: cup.y - 220 - lift, note: 5 + k, length: kind == .ramp ? Rules.rampLength : nil,
                    bend: kind == .ramp ? Rules.rampBend : nil)
            }
            let tray = real + spares
            let c = Challenge(id: "w\(w)-\(n)", world: w, number: n, title: r.name, goal: .target(x: cup.x, y: cup.y), instrument: r.instrument,
                              solution: solution, start: start, locked: Set(start.pads.map(\.id)), tray: tray, par: pieces.count, notes: [], season: season)
            let freebie = (1..<(1 << tray.count)).contains { mask in
                var course = start
                for (k, p) in tray.enumerated() where mask & (1 << k) != 0 { course.pads.append(p) }
                return Challenge.passes(Engine.simulate(course), x: cup.x, y: cup.y)
            }
            if !freebie { return c }
        }
        preconditionFailure("challenge w\(w)-\(n): tray pieces win without being moved")
    }
}

/// Best stars per level, saved on the phone, and which levels are open.
final class ChallengeProgress {
    private let defaults: UserDefaults
    private let key = "challenges.v1"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    private var best: [String: Int] { (defaults.dictionary(forKey: key) as? [String: Int]) ?? [:] }

    func stars(_ id: String) -> Int { best[id] ?? 0 }

    func record(_ id: String, stars: Int) {
        var b = best
        if stars > (b[id] ?? 0) { b[id] = stars; defaults.set(b, forKey: key) }
    }

    func totalStars(in levels: [Challenge]) -> Int { totalStars(ids: levels.map(\.id)) }
    func totalStars(ids: [String]) -> Int { let b = best; return ids.reduce(0) { $0 + (b[$1] ?? 0) } }
    /// Stars in the five main worlds (what star rewards count).
    func mainStars() -> Int { totalStars(ids: Challenges.mainIDs) }

    /// Holidays whose world has a star on every level (their reward skin is earned).
    func holidaysDone() -> Set<String> {
        let b = best
        return Set(Seasons.all.map(\.id).filter { id in
            let ids = Challenges.holidayIDs(id)
            return !ids.isEmpty && ids.allSatisfy { (b[$0] ?? 0) > 0 }
        })
    }

    /// Level 1 of World 1 is open. A level opens when the previous one has a star; a world opens when the previous world's
    /// last level has a star and the earlier worlds together have at least 10 stars per world.
    func isUnlocked(_ c: Challenge, in all: [Challenge]) -> Bool {
        if c.number > 1 { return stars("w\(c.world)-\(c.number - 1)") > 0 }
        if c.world == 1 || c.season != nil { return true }                    // a holiday world opens with its holiday
        let lastOfPrevious = all.filter { $0.world == c.world - 1 }.map(\.number).max() ?? 0
        return stars("w\(c.world - 1)-\(lastOfPrevious)") > 0 && totalStars(in: all.filter { $0.world < c.world }) >= 10 * (c.world - 1)
    }
}
