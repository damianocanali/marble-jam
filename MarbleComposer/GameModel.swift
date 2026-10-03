import Foundation

@MainActor
final class GameModel: ObservableObject {
    @Published private(set) var course = Course()
    @Published private(set) var run = Run()
    @Published var selected: UUID?
    @Published private(set) var playing = false
    @Published var toast: String?
    private(set) var version = 0            // the scene redraws when this changes
    var focusY: Double?                     // the scene scrolls here once, then clears it

    private var undoStack: [Course] = []
    private let synth = Synth()
    private var t0 = 0.0
    private var scheduled = 0
    private static let key = "course.v1"
    private let nextNotes = [7, 9, 11, 12, 11, 9, 8, 7]     // what "+ Pad" hands out: a gentle up-and-down

    init() {
        if let d = UserDefaults.standard.data(forKey: Self.key), let c = try? JSONDecoder().decode(Course.self, from: d), !c.pads.isEmpty {
            course = c
        } else {
            course = Engine.demo()
        }
        refresh()
    }

    private func refresh() { run = Engine.simulate(course); version += 1 }
    func save() { if let d = try? JSONEncoder().encode(course) { UserDefaults.standard.set(d, forKey: Self.key) } }
    func mark() { undoStack.append(course); if undoStack.count > 40 { undoStack.removeFirst() } }

    var selectedPad: Pad? { course.pads.first { $0.id == selected } }
    var maxY: Double { (course.pads.map(\.y) + [course.dropY]).max() ?? 0 }

    func updateSelected(_ change: (inout Pad) -> Void) {
        guard let i = course.pads.firstIndex(where: { $0.id == selected }) else { return }
        change(&course.pads[i]); refresh()
    }
    func setDrop(x: Double) { course.dropX = x; refresh() }

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
        if let q = selectedPad { synth.start(); synth.play(midi: Notes.midi(q), bar: q.kind == .bar, gain: 0.25, at: synth.now) }
        save()
    }
    func deleteSelected() { guard selected != nil else { return }; mark(); course.pads.removeAll { $0.id == selected }; selected = nil; refresh(); save() }
    func undo() { guard let c = undoStack.popLast() else { return }; course = c; selected = nil; refresh(); save() }
    func clear() { mark(); course.pads = []; selected = nil; focusY = 0; refresh(); save(); toast = "Cleared. Undo brings it back." }
    func loadDemo() { mark(); course = Engine.demo(); selected = nil; focusY = 0; refresh(); save() }

    func toggleDrop() { playing ? stop() : start() }
    func start() {
        synth.start(); refresh()
        guard !run.hits.isEmpty else { toast = "Nothing in the way yet. Add a pad first."; return }
        selected = nil; scheduled = 0; t0 = synth.now + 0.08; playing = true; version += 1
    }
    func stop() { playing = false; version += 1 }

    /// Seconds since the drop, on the audio clock. Also queues the notes that are about to sound.
    var playTime: Double {
        let t = synth.now - t0
        while scheduled < run.hits.count, run.hits[scheduled].time < t + 0.15 {
            let h = run.hits[scheduled], p = course.pads[h.pad]
            synth.play(midi: Notes.midi(p), bar: p.kind == .bar, gain: min(0.36, 0.14 + h.speed / 3600), at: t0 + h.time)
            scheduled += 1
        }
        return t
    }

    var info: String {
        guard let last = run.hits.last else { return "No notes yet" }
        let on = run.hits.filter { Engine.isOnBeat($0.time) }.count
        return "\(run.hits.count) notes · \(String(format: "%.1f", last.time)) s · \(on) on the beat"
    }
}
