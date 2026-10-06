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
    private struct Snapshot { let course: Course; let instrument: Instrument }
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
    func mark() { undoStack.append(Snapshot(course: course, instrument: instrument)); if undoStack.count > 40 { undoStack.removeFirst() } }

    var selectedPad: Pad? { course.pads.first { $0.id == selected } }
    var maxY: Double { (course.pads.map(\.y) + [course.dropY]).max() ?? 0 }

    func updateSelected(_ change: (inout Pad) -> Void) {
        guard let i = course.pads.firstIndex(where: { $0.id == selected }) else { return }
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
        guard selectedPad?.kind == .bar else { return }
        updateSelected { $0.angle = Rules.clampAngle($0.angle + d) }
    }
    func setAngle(_ a: Double) {
        guard selectedPad?.kind == .bar else { return }
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
    private func selectNewest() { selected = course.pads.last?.id; focusY = course.pads.last?.y; refresh(); save() }

    /// Longer/bigger (-1) or shorter/smaller (+1): size is the note.
    func stepNote(_ d: Int) {
        guard let p = selectedPad else { return }
        mark()
        updateSelected { $0.note = max(0, min(Notes.maxNote(p.kind), $0.note + d)) }
        if let q = selectedPad { synth.start(); synth.play(midi: Notes.midi(q), bar: q.kind == .bar, gain: 0.25, at: synth.now, instrument: instrument) }
        save()
    }
    func deleteSelected() { guard selected != nil else { return }; mark(); course.pads.removeAll { $0.id == selected }; selected = nil; refresh(); save() }
    func undo() {
        guard let u = undoStack.popLast() else { return }
        course = u.course; instrument = u.instrument; selected = nil; refresh(); save()
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
    func clear() { mark(); course.pads = []; selected = nil; focusY = 0; refresh(); save(); toast = "Cleared. Undo brings it back." }
    func loadDemo() { mark(); course = Engine.demo(); selected = nil; focusY = 0; refresh(); save() }

    func toggleDrop() { playing ? stop() : start() }
    func start() {
        celebration = nil
        synth.start(); refresh()
        guard !run.hits.isEmpty else { toast = "Nothing in the way yet. Add a pad first."; return }
        synth.prepare(course.pads.map { (Notes.midi($0), $0.kind == .bar) }, instrument: instrument)   // render every note before the clock starts
        selected = nil; scheduled = 0; t0 = synth.now + 0.08; playing = true; version += 1
    }
    func stop() { playing = false; version += 1 }

    /// The marble reached the end by itself: stop and celebrate.
    func finish() {
        let on = run.hits.filter { Engine.isOnBeat($0.time) }.count
        stop()
        celebration = Celebration.make(onBeat: on, total: run.hits.count)
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
            synth.play(midi: Notes.midi(p), bar: p.kind == .bar, gain: min(0.36, 0.14 + h.speed / 3600), at: t0 + h.time, instrument: instrument)
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
