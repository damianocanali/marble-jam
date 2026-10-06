import Foundation

/// Which drum a pad plays when the song uses the drum kit: the note picks it.
enum Drum: Equatable {
    case kick, snare, hat, tom

    static func piece(midi: Int, bar: Bool) -> Drum {
        guard bar else { return .tom }
        return midi <= 67 ? .kick : midi <= 77 ? .snare : .hat
    }

    var label: String {
        switch self {
        case .kick: "Kick"
        case .snare: "Snare"
        case .hat: "Hat"
        case .tom: "Tom"
        }
    }
}

extension Instrument {
    /// One note as mono samples, normalised to a peak of 0.9. Pure: the same input always gives the same sound.
    func samples(midi: Int, bar: Bool, sampleRate sr: Double) -> [Float] {
        let f = 440 * pow(2, Double(midi - 69) / 12)
        var noise = Noise(seed: UInt64(midi * 31 + (bar ? 7 : 3)))
        let out: [Double]
        switch self {
        case .bells:
            out = render(bar ? 1.5 : 0.7, sr) { u in
                let w = 2 * .pi * f * u
                return min(1, u / 0.008) * exp(-u * (bar ? 4.2 : 8.5)) * (sin(w) + (bar ? 0.28 : 0.5) * sin(2 * w) + (bar ? 0.1 : 0.22) * sin(3 * w))
            }
        case .piano:
            out = render(bar ? 1.6 : 1.1, sr) { u in
                var s = 0.0
                for n in 1...6 {
                    let k = Double(n), w = 2 * .pi * f * k * (1 + 0.0004 * k * k) * u      // slightly stretched, like real strings
                    s += sin(w) / pow(k, 1.3) * exp(-u * (1.1 + 0.7 * k) * (f < 200 ? 0.7 : 1))
                }
                return min(1, u / 0.003) * s
            }
        case .guitar:                                                                  // plucked string: noise through a damped delay line
            let n = max(2, Int(sr / f)), len = Int(1.4 * sr)
            var y = [Double](repeating: 0, count: len)
            for i in 0..<len {
                y[i] = i < n ? noise.next() : 0.996 * 0.5 * (y[i - n] + y[i - n + (i - n > 0 ? -1 : 0)])
            }
            out = y.enumerated().map { i, v in v * min(1, Double(i) / (0.002 * sr)) }
        case .marimba:
            out = render(0.9, sr) { u in
                let w = 2 * .pi * f * u
                return min(1, u / 0.002) * (exp(-u * 6) * sin(w) + 0.25 * exp(-u * 22) * sin(4 * w))
            }
        case .drums:
            switch Drum.piece(midi: midi, bar: bar) {
            case .kick:
                var phase = 0.0
                out = render(0.5, sr) { u in phase += 2 * .pi * (45 + 75 * exp(-u * 30)) / sr; return exp(-u * 8) * sin(phase) }
            case .snare:
                out = render(0.3, sr) { u in exp(-u * 18) * 0.8 * noise.next() + exp(-u * 20) * 0.5 * sin(2 * .pi * 180 * u) }
            case .hat:
                var last = 0.0
                out = render(0.12, sr) { u in let n = noise.next(); defer { last = n }; return exp(-u * 45) * (n - last) * 0.6 }
            case .tom:
                var phase = 0.0
                out = render(0.6, sr) { u in phase += 2 * .pi * f * (0.8 + 0.2 * exp(-u * 12)) / sr; return exp(-u * 7) * sin(phase) }
            }
        case .chip:
            out = render(bar ? 0.6 : 0.4, sr) { u in min(1, u / 0.003) * exp(-u * 5) * (sin(2 * .pi * f * u) >= 0 ? 0.5 : -0.5) }
        }
        let peak = out.map(abs).max() ?? 0
        let k = peak > 0 ? 0.9 / peak : 0
        return out.map { Float($0 * k) }
    }

    private func render(_ seconds: Double, _ sr: Double, _ sample: (Double) -> Double) -> [Double] {
        (0..<Int(seconds * sr)).map { sample(Double($0) / sr) }
    }
}

/// Repeatable white noise, -1...1.
private struct Noise {
    var s: UInt64
    init(seed: UInt64) { s = seed &* 0x9E37_79B9_7F4A_7C15 | 1 }
    mutating func next() -> Double {
        s = s &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(s >> 11) / Double(1 << 52) - 1
    }
}
