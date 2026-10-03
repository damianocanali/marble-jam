import AVFoundation

/// A small bell/pluck synth. Notes are scheduled on the audio clock, so sound and picture stay together.
final class Synth {
    private struct Voice { let freq, gain, start, dur: Double; let bar: Bool }
    private let engine = AVAudioEngine()
    private var source: AVAudioSourceNode!
    private var voices: [Voice] = []
    private let lock = NSLock()
    private var clock = 0.0                 // seconds rendered so far
    private let sampleRate: Double

    init() {
        let sr = engine.outputNode.inputFormat(forBus: 0).sampleRate
        sampleRate = sr > 0 ? sr : 44100
        source = AVAudioSourceNode { [unowned self] _, _, frameCount, bufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            self.lock.lock()
            let t0 = self.clock
            self.clock += Double(frameCount) / self.sampleRate
            self.voices.removeAll { t0 > $0.start + $0.dur }
            let vs = self.voices
            self.lock.unlock()
            for f in 0..<Int(frameCount) {
                let t = t0 + Double(f) / self.sampleRate
                var s = 0.0
                for v in vs {
                    let u = t - v.start
                    if u < 0 || u > v.dur { continue }
                    let env = min(1, u / 0.008) * exp(-u * (v.bar ? 4.2 : 8.5)) * v.gain      // soft attack, no click
                    let w = 2 * Double.pi * v.freq * u
                    s += env * (sin(w) + (v.bar ? 0.28 : 0.5) * sin(2 * w) + (v.bar ? 0.1 : 0.22) * sin(3 * w))
                }
                let out = Float(tanh(s * 0.6))
                for b in buffers { b.mData?.assumingMemoryBound(to: Float.self)[f] = out }
            }
            return noErr
        }
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2))
    }

    func start() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        if !engine.isRunning { try? engine.start() }
    }

    /// Current time on the audio clock, in seconds.
    var now: Double { lock.lock(); defer { lock.unlock() }; return clock }

    func play(midi: Int, bar: Bool, gain: Double, at time: Double) {
        let v = Voice(freq: 440 * pow(2, Double(midi - 69) / 12), gain: gain, start: time, dur: bar ? 1.5 : 0.7, bar: bar)
        lock.lock(); voices.append(v); lock.unlock()
    }
}
