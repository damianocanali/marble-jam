import AVFoundation

/// The menu's song: an original eight-bar loop (C, Am, F, G twice), a marimba tune over soft low bells.
enum MenuTune {
    struct Note { let beat: Double; let midi: Int; let instrument: Instrument; let bar: Bool; let gain: Double }

    static let bpm = 90.0, beats = 32.0
    static var length: Double { beats * 60 / bpm }

    private static let tune: [(Double, Int)] = [                       // (beat, midi): C5 = 72
        (0, 76), (1, 79), (2, 76), (2.5, 74), (3, 72),                  // C
        (4, 69), (5.5, 72), (6, 76), (7, 74),                           // Am
        (8, 72), (9, 69), (10, 65), (11, 69), (11.5, 72),               // F
        (12, 74), (13, 71), (14, 67),                                   // G
        (16, 76), (17, 79), (18, 81), (18.5, 79), (19, 76),             // C
        (20, 76), (21, 74), (22, 72), (23, 69),                         // Am
        (24, 65), (25, 69), (26, 72), (26.5, 74), (27, 76),             // F
        (28, 74), (29, 71), (30, 72),                                   // G, home to C
    ]
    private static let roots = [48, 45, 41, 43, 48, 45, 41, 43]          // C3 A2 F2 G2, one bar each

    static let notes: [Note] = {
        var n = tune.map { Note(beat: $0.0, midi: $0.1, instrument: .marimba, bar: true, gain: 0.16) }
        for (bar, root) in roots.enumerated() {
            let b = Double(bar * 4)
            n.append(Note(beat: b, midi: root, instrument: .bells, bar: false, gain: 0.1))          // root on one
            n.append(Note(beat: b + 2, midi: root + 7, instrument: .bells, bar: false, gain: 0.07))  // fifth on three
        }
        return n.sorted { $0.beat < $1.beat }
    }()
}

/// Plays `MenuTune` on a loop while the menu is open. Notes are queued a second ahead on the synth's clock, like the game does.
/// Follows the silent switch, and stays quiet when other audio (the parent's music or podcast) is already playing.
final class MenuMusic {
    private let synth: Synth
    private let otherAudioPlaying: () -> Bool
    private var timer: Timer?
    private var next = 0
    private(set) var loopStart = 0.0                                    // clock time of the current loop's first beat
    private(set) var isPlaying = false
    private(set) var queued = 0                                         // notes handed to the synth since start (for tests)

    init(synth: Synth = Synth(ambient: true), otherAudioPlaying: @escaping () -> Bool = { AVAudioSession.sharedInstance().isOtherAudioPlaying }) {
        self.synth = synth; self.otherAudioPlaying = otherAudioPlaying
    }

    func start() {
        guard !isPlaying, !otherAudioPlaying() else { return }
        synth.start()
        synth.reset()                                                   // leftovers from a faded-out run
        isPlaying = true
        next = 0; queued = 0; loopStart = synth.now + 0.15
        queue(until: synth.now + 1)
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.queue(until: self.synth.now + 1)
        }
    }

    /// Hands the synth every note that starts before `time`, wrapping round the loop.
    func queue(until time: Double) {
        guard isPlaying else { return }
        let notes = MenuTune.notes, secondsPerBeat = 60 / MenuTune.bpm
        while loopStart + notes[next].beat * secondsPerBeat < time {
            let n = notes[next]
            synth.play(midi: n.midi, bar: n.bar, gain: n.gain, at: loopStart + n.beat * secondsPerBeat, instrument: n.instrument)
            queued += 1
            next += 1
            if next == notes.count { next = 0; loopStart += MenuTune.length }
        }
    }

    /// Fades out, then lets the audio hardware rest.
    func stop(fade: Double = 0.5) {
        guard isPlaying else { return }
        isPlaying = false
        timer?.invalidate(); timer = nil
        synth.fadeOut(over: fade)
        DispatchQueue.main.asyncAfter(deadline: .now() + fade + 0.1) { [weak self] in
            guard let self, !self.isPlaying else { return }             // started again meanwhile: keep going
            self.synth.pause()
        }
    }
}
