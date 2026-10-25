import AVFoundation

/// A small synth that plays pre-rendered notes (see InstrumentSound.swift) on the audio clock, so sound and picture stay together.
final class Synth {
    private struct Voice { let samples: [Float]; let gain, start: Double }
    private var engine: AVAudioEngine?          // made with the first sound, so opening the app never waits on the audio system
    private var source: AVAudioSourceNode?
    private var voices: [Voice] = []
    private let lock = NSLock()
    private var clock = 0.0                 // seconds rendered so far
    private var fade: (start: Double, length: Double)?           // fading out: silent from start + length on
    private(set) var sampleRate = 44100.0

    var isAudioSetUp: Bool { engine != nil }
    private let audioAllowed: Bool
    private let ambient: Bool                                    // background music: follows the silent switch
    private var wallClockStart: CFTimeInterval?                  // set when sound can't start: the song is timed by a plain clock

    init(audio: Bool = true, ambient: Bool = false) { audioAllowed = audio; self.ambient = ambient }

    private func setUpAudio() {
        let engine = AVAudioEngine()
        let sr = engine.outputNode.inputFormat(forBus: 0).sampleRate
        if sr > 0 && sr != sampleRate { sampleRate = sr; cache = [:] }          // notes rendered at the old rate would sound off-pitch
        let rate = sampleRate
        let source = AVAudioSourceNode { [weak self] _, _, frameCount, bufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let self else {                                                   // the synth is going away: play silence
                for b in buffers { memset(b.mData, 0, Int(b.mDataByteSize)) }
                return noErr
            }
            self.lock.lock()
            let t0 = self.clock
            self.clock += Double(frameCount) / rate
            self.voices.removeAll { t0 > $0.start + Double($0.samples.count) / rate }
            let vs = self.voices, fade = self.fade
            self.lock.unlock()
            for f in 0..<Int(frameCount) {
                let t = t0 + Double(f) / rate
                var s = 0.0
                for v in vs {
                    let i = Int((t - v.start) * rate)
                    if i >= 0 && i < v.samples.count { s += Double(v.samples[i]) * v.gain * 1.3 }
                }
                if let fade { s *= max(0, 1 - (t - fade.start) / fade.length) }
                let out = Float(tanh(s * 0.6))
                for b in buffers { b.mData?.assumingMemoryBound(to: Float.self)[f] = out }
            }
            return noErr
        }
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: AVAudioFormat(standardFormatWithSampleRate: rate, channels: 2))
        self.engine = engine; self.source = source
    }

    deinit { engine?.stop() }

    func start() {
        guard audioAllowed else { if wallClockStart == nil { wallClockStart = CACurrentMediaTime() }; return }
        try? AVAudioSession.sharedInstance().setCategory(ambient ? .ambient : .playback, options: ambient ? [] : [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        if engine == nil { setUpAudio() }
        if let engine, !engine.isRunning { try? engine.start() }
        if engine?.isRunning != true, wallClockStart == nil { wallClockStart = CACurrentMediaTime() }   // no sound, but the marble still plays
    }

    /// Stops rendering until the next `start()`; the clock waits too.
    func pause() { engine?.pause() }

    /// Fades everything playing or queued down to silence over `seconds`.
    func fadeOut(over seconds: Double) {
        lock.lock(); fade = (clock, seconds); lock.unlock()
    }

    /// Drops every queued note and any fade, for a fresh start.
    func reset() {
        lock.lock(); voices = []; fade = nil; lock.unlock()
    }

    /// Current time on the audio clock, in seconds.
    var now: Double {
        if let w = wallClockStart { return CACurrentMediaTime() - w }
        lock.lock(); defer { lock.unlock() }; return clock
    }

    private var cache: [String: [Float]] = [:]           // one rendered note per instrument/pitch/kind; used from the main thread only

    /// Renders notes ahead of time so playback never waits for them.
    func prepare(_ notes: [(midi: Int, bar: Bool)], instrument: Instrument) {
        for n in notes {
            let key = "\(instrument.rawValue)-\(n.midi)-\(n.bar)"
            if cache[key] == nil { cache[key] = instrument.samples(midi: n.midi, bar: n.bar, sampleRate: sampleRate) }
        }
    }

    func play(midi: Int, bar: Bool, gain: Double, at time: Double, instrument: Instrument = .bells) {
        let key = "\(instrument.rawValue)-\(midi)-\(bar)"
        let samples = cache[key] ?? instrument.samples(midi: midi, bar: bar, sampleRate: sampleRate)
        cache[key] = samples
        lock.lock(); voices.append(Voice(samples: samples, gain: gain, start: time)); lock.unlock()
    }
}
