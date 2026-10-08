import Foundation

@MainActor
final class GameModel: ObservableObject {
    @Published private(set) var course = Course()
    @Published private(set) var run = Run()
    private(set) var beats: [Engine.BeatState] = []    // per pad: on the beat, close, off, or unused
    @Published var selected: UUID?
    @Published private(set) var playing = false
    @Published var toast: String?
    @Published var celebration: Celebration?
    private(set) var version = 0            // the scene redraws when this changes
    var focusY: Double?                     // the scene scrolls here once, then clears it

    @Published private(set) var instrument: Instrument = .bells
    private(set) var song: Song?
    private let store: SongStore?
    private struct Snapshot { let course: Course; let instrument: Instrument; var tray: [Pad] = []; var placed: Set<UUID> = [] }

    // Challenge mode
    @Published private(set) var challenge: Challenge?
    @Published private(set) var trayLeft: [Pad] = []               // tray pieces not placed yet
    private var placed: Set<UUID> = []                             // tray pieces on the course
    private var progress: ChallengeProgress?
    private(set) var nextChallenge: Challenge?                      // set when a finished level opens the next one
    private var undoStack: [Snapshot] = []
    private let synth = Synth()
    private var t0 = 0.0
    private var scheduled = 0
    private let nextNotes = [7, 9, 11, 12, 11, 9, 8, 7]     // what "+ Pad" hands out: a gentle up-and-down

    init(store: SongStore? = nil) {
        self.store = store
        refresh()
    }

    /// Opens a song in the builder. Undo starts fresh for each visit.
    func open(_ s: Song) {
        challenge = nil; trayLeft = []; placed = []; nextChallenge = nil
        song = s; course = s.course; instrument = s.instrument
        undoStack = []; selected = nil; playing = false; celebration = nil; focusY = 0
        refresh()
    }

    private func refresh() { run = Engine.simulate(course); beats = Engine.beatStates(run, padCount: course.pads.count); version += 1 }
    func save() {
        guard let store, var s = song else { return }
        s.course = course; s.instrument = instrument
        do { song = try store.save(s) } catch { toast = "Couldn't save your song" }
    }
    func mark() { undoStack.append(Snapshot(course: course, instrument: instrument, tray: trayLeft, placed: placed)); if undoStack.count > 40 { undoStack.removeFirst() } }

    var selectedPad: Pad? { course.pads.first { $0.id == selected } }
    /// The lowest point that matters: the lowest piece, or a challenge's cup (so the player can scroll down to it).
    var maxY: Double {
        var ys = course.pads.map(\.y) + [course.dropY]
        if case let .target(_, y)? = challenge?.goal { ys.append(y + 120) }
        return ys.max() ?? 0
    }

    func updateSelected(_ change: (inout Pad) -> Void) {
        guard let i = course.pads.firstIndex(where: { $0.id == selected }), !isLocked(course.pads[i].id) else { return }
        change(&course.pads[i]); refresh()
    }
    func setDrop(x: Double) { course.dropX = x; refresh() }

    /// After a drag, a tilt or a rotate: a selected pad that is close to the beat slides onto it. Saves either way.
    /// If nothing changed since the touch began (a plain tap), the undo step is dropped and nothing snaps.
    @discardableResult func finishEdit() -> Bool {
        if let top = undoStack.last, top.course == course, top.instrument == instrument { undoStack.removeLast(); return false }
        defer { save() }
        guard let i = course.pads.firstIndex(where: { $0.id == selected }), beats.indices.contains(i), beats[i] == .near,
              let snapped = Engine.snapToBeat(course, pad: i) else { return false }
        course = snapped; refresh()
        return true
    }

    /// Pad controller: tilt the selected bar. Bumpers have no angle.
    func rotate(by d: Double) {
        guard selectedPad.map({ $0.kind != .bumper }) == true else { return }
        updateSelected { $0.angle = Rules.clampAngle($0.angle + d) }
    }
    func setAngle(_ a: Double) {
        guard selectedPad.map({ $0.kind != .bumper }) == true else { return }
        updateSelected { $0.angle = Rules.clampAngle(a) }
    }

    func addPad() {
        mark()
        let n = nextNotes[course.pads.filter { $0.kind == .bar }.count % nextNotes.count]
        var c = course
        if !Engine.smartAdd(&c, beats: 1, note: n) {
            c.pads.append(Pad(kind: .bar, x: Rules.width / 2, y: maxY + 150, angle: 0.25, note: n))
            toast = "Placed below the run. Drag it under the dotted path."
        }
        course = c; selectNewest()
    }
    func addBumper() {
        mark()
        let s = Engine.simulate(course, maxTime: 90, below: 2600)
        let p = s.position(at: min(s.duration - 0.05, (s.hits.last?.time ?? 0) + Rules.beat))
        course.pads.append(Pad(kind: .bumper, x: max(60, min(Rules.width - 60, p.x + 18)), y: p.y + Notes.bumperRadius(3) + Rules.radius, note: 3))
        selectNewest()
    }
    /// A ramp where the marble will be a beat after its last note, sloping the way it is moving.
    func addRamp() {
        mark()
        var c = course
        if !Engine.rampAdd(&c, note: 9) {
            c.pads.append(Pad(kind: .ramp, x: Rules.width / 2, y: maxY + 200, angle: 0.3, note: 9, length: Rules.rampLength, bend: Rules.rampBend))
            toast = "Placed below the run. Drag it under the dotted path."
        }
        course = c; selectNewest()
    }

    /// Ramp controls: longer/shorter (±40 points) and more dip/hump (±0.1).
    func stepLength(_ d: Int) {
        guard selectedPad?.kind == .ramp else { return }
        mark(); defer { finishEdit() }
        updateSelected { $0.length = min(Rules.rampLengths.upperBound, max(Rules.rampLengths.lowerBound, ($0.length ?? Rules.rampLength) + 40 * Double(d))) }
    }
    func stepBend(_ d: Int) {
        guard selectedPad?.kind == .ramp else { return }
        mark(); defer { finishEdit() }
        updateSelected { $0.bend = min(Rules.rampBends.upperBound, max(Rules.rampBends.lowerBound, ((($0.bend ?? 0) + 0.1 * Double(d)) * 10).rounded() / 10)) }
    }

    private func selectNewest() { selected = course.pads.last?.id; focusY = course.pads.last?.y; refresh(); save() }

    /// Longer/bigger (-1) or shorter/smaller (+1): size is the note.
    func stepNote(_ d: Int) {
        guard let p = selectedPad else { return }
        mark()
        updateSelected { $0.note = max(0, min(Notes.maxNote(p.kind), $0.note + d)) }
        if let q = selectedPad { synth.start(); synth.play(midi: Notes.midi(q), bar: q.kind != .bumper, gain: 0.25, at: synth.now, instrument: instrument) }
        save()
    }
    func deleteSelected() {
        guard let id = selected, !isLocked(id), let i = course.pads.firstIndex(where: { $0.id == id }) else { return }
        mark()
        let pad = course.pads.remove(at: i)
        if placed.remove(id) != nil { trayLeft.append(pad) }                 // a tray piece goes back to the tray
        selected = nil; refresh(); save()
    }
    func undo() {
        guard let u = undoStack.popLast() else { return }
        course = u.course; instrument = u.instrument; selected = nil
        if challenge != nil { trayLeft = u.tray; placed = u.placed }
        refresh(); save()
    }

    func setInstrument(_ i: Instrument) {
        guard i != instrument else { return }
        mark(); instrument = i; refresh(); save()
        synth.start(); synth.play(midi: 67, bar: true, gain: 0.3, at: synth.now, instrument: i)
    }

    func rename(to name: String) {
        guard let store, let s = song, store.rename(s.id, to: name) else { return }
        song = store.song(s.id)
    }
    func clear() {
        if challenge != nil { resetChallenge(); return }
        mark(); course.pads = []; selected = nil; focusY = 0; refresh(); save(); toast = "Cleared. Undo brings it back." }
    func loadDemo() { mark(); course = Engine.demo(); selected = nil; focusY = 0; refresh(); save() }

    func toggleDrop() { playing ? stop() : start() }
    func start() {
        celebration = nil
        synth.start(); refresh()
        guard !run.hits.isEmpty else { toast = "Nothing in the way yet. Add a pad first."; return }
        synth.prepare(course.pads.map { (Notes.midi($0), $0.kind != .bumper) }, instrument: instrument)   // render every note before the clock starts
        selected = nil; scheduled = 0; t0 = synth.now + 0.08; playing = true; version += 1
    }
    func stop() { playing = false; version += 1 }

    // MARK: challenges

    /// Opens a challenge level: its start course, its tray, no song saving.
    func open(challenge c: Challenge, progress p: ChallengeProgress) {
        song = nil; challenge = c; progress = p; nextChallenge = nil
        course = c.start; instrument = c.instrument; trayLeft = c.tray; placed = []
        undoStack = []; selected = nil; playing = false; celebration = nil; focusY = 0
        refresh()
    }

    func isLocked(_ id: UUID) -> Bool { challenge?.locked.contains(id) ?? false }

    /// Puts a tray piece on the course at its hint spot and selects it.
    func placeFromTray(_ i: Int) {
        guard trayLeft.indices.contains(i) else { return }
        mark()
        let pad = trayLeft.remove(at: i)
        course.pads.append(pad); placed.insert(pad.id)
        selectNewest()
    }

    func resetChallenge() {
        guard let c = challenge else { return }
        mark()
        course = c.start; trayLeft = c.tray; placed = []; selected = nil; focusY = 0
        refresh()
    }

    /// The marble reached the end by itself: stop and celebrate (in a challenge: score the level).
    func finish() {
        if let c = challenge { finishChallenge(c); return }
        let on = run.hits.filter { Engine.isOnBeat($0.time) }.count
        stop()
        celebration = Celebration.make(onBeat: on, total: run.hits.count)
    }
    private func finishChallenge(_ c: Challenge) {
        let stars = c.stars(for: course, placed: placed.count)
        stop()
        guard stars > 0 else {
            toast = switch c.goal {
            case .melody: "Not yet: every note has to play, in order."
            case .fix: "Not yet: the tune has to play all the way through."
            case .target: "So close! The marble has to reach the cup."
            }
            return
        }
        progress?.record(c.id, stars: stars)
        let on = run.hits.filter { Engine.isOnBeat($0.time) }.count
        celebration = Celebration(stars: stars, headline: Celebration.headlines[stars]!.randomElement()!, notes: run.hits.count, onBeat: on)
        if let i = Challenges.all.firstIndex(where: { $0.id == c.id }), i + 1 < Challenges.all.count, let p = progress,
           p.isUnlocked(Challenges.all[i + 1], in: Challenges.all) { nextChallenge = Challenges.all[i + 1] }
    }

    /// Rising chime for the sticker's stars (i = 0, 1, 2).
    func chime(_ i: Int) {
        synth.start()
        synth.play(midi: 72 + [0, 4, 7, 12][min(i, 3)], bar: true, gain: 0.3, at: synth.now + 0.02)
    }

    /// Seconds since the drop, on the audio clock. Also queues the notes that are about to sound.
    var playTime: Double {
        let t = synth.now - t0
        while scheduled < run.hits.count, run.hits[scheduled].time < t + 0.15 {
            let h = run.hits[scheduled], p = course.pads[h.pad]
            synth.play(midi: Notes.midi(p), bar: p.kind != .bumper, gain: min(0.36, 0.14 + h.speed / 3600), at: t0 + h.time, instrument: instrument)
            scheduled += 1
        }
        return t
    }

    var info: String {
        guard !run.hits.isEmpty else { return "No notes yet" }
        let on = run.hits.filter { Engine.isOnBeat($0.time) }.count
        return "\(run.hits.count) notes · \(on) on the beat"
    }
}
