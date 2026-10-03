import Foundation

// World rules: the same as the Shorts and the web prototype. Units are points in a 720-wide world, y grows downward.
enum Rules {
    static let width = 720.0, gravity = 1800.0, radius = 14.0, thickness = 14.0
    static let barBounce = 0.45, bumperBounce = 0.9, step = 1.0 / 240.0, beat = 0.5
}

struct Pad: Codable, Identifiable, Equatable {
    enum Kind: String, Codable { case bar, bumper }
    var id = UUID()
    var kind: Kind
    var x: Double
    var y: Double
    var angle: Double = 0          // radians, bars only
    var note: Int                  // size step: bars 0...14 (C4...C6), bumpers 0...7 (C3...C4)

    /// End points of the bar's centre line (x0, y0, x1, y1).
    var ends: (Double, Double, Double, Double) {
        let h = (Notes.barLength(note) - Rules.thickness) / 2, c = cos(angle), s = sin(angle)
        return (x - c * h, y - s * h, x + c * h, y + s * h)
    }
}

struct Course: Codable, Equatable {
    var pads: [Pad] = []
    var dropX = 200.0
    var dropY = 60.0
}

struct Hit { let time, x, y: Double; let pad: Int; let speed: Double }

struct Run {
    var path: [Double] = []        // x, y sampled 60 times a second
    var hits: [Hit] = []
    var duration = 0.0

    func position(at t: Double) -> (x: Double, y: Double) {
        let n = path.count / 2
        guard n > 1 else { return (path.first ?? 0, path.count > 1 ? path[1] : 0) }
        let f = max(0, min(Double(n) - 1.001, t * 60)), i = Int(f), u = f - Double(i)
        return (path[i * 2] + (path[i * 2 + 2] - path[i * 2]) * u, path[i * 2 + 1] + (path[i * 2 + 3] - path[i * 2 + 1]) * u)
    }
}

/// Size sets the note: longer bars and bigger bumpers play lower, like xylophone bars.
enum Notes {
    static let major = [0, 2, 4, 5, 7, 9, 11]
    static let names = ["C", "D", "E", "F", "G", "A", "B"]
    static let hues = [190.0, 262, 322, 22, 44, 140, 0]
    static func midi(_ p: Pad) -> Int { (p.kind == .bar ? 60 : 48) + 12 * (p.note / 7) + major[p.note % 7] }
    static func name(_ p: Pad) -> String { names[p.note % 7] + String((p.kind == .bar ? 4 : 3) + p.note / 7) }
    static func barLength(_ n: Int) -> Double { 210 - 10 * Double(n) }
    static func bumperRadius(_ n: Int) -> Double { 46 - 4 * Double(n) }
    static func hue(_ p: Pad) -> Double { hues[p.note % 7] / 360 }
    static func maxNote(_ k: Pad.Kind) -> Int { k == .bar ? 14 : 7 }
}

enum Engine {
    /// Drops the marble and follows it with fixed steps. The preview and the performance both use this, so they always agree.
    static func simulate(_ c: Course, maxTime: Double = 120, below: Double = 500) -> Run {
        struct Geo { let ax, ay, bx, by, r, e: Double }
        let geo: [Geo] = c.pads.map { p in
            if p.kind == .bar { let e = p.ends; return Geo(ax: e.0, ay: e.1, bx: e.2, by: e.3, r: Rules.thickness / 2, e: Rules.barBounce) }
            return Geo(ax: p.x, ay: p.y, bx: p.x, by: p.y, r: Notes.bumperRadius(p.note), e: Rules.bumperBounce)
        }
        let low = (c.pads.map(\.y) + [c.dropY]).max()! + below
        var last = [Double](repeating: -1, count: geo.count)
        var x = c.dropX, y = c.dropY, vx = 0.0, vy = 0.0, t = 0.0, calm = 0.0, i = 0
        var run = Run()
        let h = Rules.step, R = Rules.radius, W = Rules.width
        while t < maxTime {
            if i % 4 == 0 { run.path.append(x); run.path.append(y) }
            i += 1
            vy += Rules.gravity * h; x += vx * h; y += vy * h; t += h
            if x < R { x = R; if vx < 0 { vx *= -0.6 } } else if x > W - R { x = W - R; if vx > 0 { vx *= -0.6 } }
            for j in geo.indices {
                let g = geo[j], ex = g.bx - g.ax, ey = g.by - g.ay, l2 = ex * ex + ey * ey
                let u = l2 > 0 ? max(0, min(1, ((x - g.ax) * ex + (y - g.ay) * ey) / l2)) : 0
                let qx = g.ax + ex * u, qy = g.ay + ey * u, rr = R + g.r
                var dx = x - qx, dy = y - qy
                let d2 = dx * dx + dy * dy
                if d2 >= rr * rr { continue }
                let d = max(d2.squareRoot(), 1e-6)
                dx /= d; dy /= d
                let vn = vx * dx + vy * dy
                if vn < 0 {
                    vx -= (1 + g.e) * vn * dx; vy -= (1 + g.e) * vn * dy
                    if -vn > 60 && t - last[j] > 0.08 { run.hits.append(Hit(time: t, x: qx + dx * g.r, y: qy + dy * g.r, pad: j, speed: -vn)); last[j] = t }
                }
                x = qx + dx * rr; y = qy + dy * rr
            }
            if y > low { break }
            if vx * vx + vy * vy < 500 { calm += h; if calm > 1 { break } } else { calm = 0 }
        }
        run.duration = t
        return run
    }

    static func isOnBeat(_ t: Double) -> Bool {
        let half = Rules.beat / 2
        return abs(t / half - (t / half).rounded()) * half < 0.04
    }

    /// The helper that makes this a composer: puts the next pad exactly where the marble is on the beat.
    static func smartAdd(_ c: inout Course, beats: Double, note: Int) -> Bool {
        let s = simulate(c, maxTime: 90, below: 2600)
        let tl = s.hits.last?.time ?? 0, ts = tl + beats * Rules.beat
        if ts > s.duration - 0.05 { return false }
        let p = s.position(at: ts), a0 = s.position(at: ts - 0.012), b0 = s.position(at: ts + 0.012)
        let vx = (b0.x - a0.x) / 0.024, vy = (b0.y - a0.y) / 0.024, sp = (vx * vx + vy * vy).squareRoot()
        var best: (score: Double, pad: Pad)?
        for deg in [10.0, -10, 18, -18, 26, -26, 34, -34, 42, -42, 50, -50] {
            let a = deg * .pi / 180, nx = sin(a), ny = -cos(a), vn = vx * nx + vy * ny
            if vn > -0.35 * sp { continue }                                  // the marble must come down onto the top face
            let ox = vx - (1 + Rules.barBounce) * vn * nx, oy = vy - (1 + Rules.barBounce) * vn * ny
            let lx = p.x + ox * Rules.beat, fall = oy * Rules.beat + 0.5 * Rules.gravity * Rules.beat * Rules.beat
            if fall < 40 { continue }                                        // keep heading downhill
            let score = abs(lx - Rules.width / 2) + (lx < 110 || lx > Rules.width - 110 ? 1000 : 0) + abs(deg) * 0.5
            if let b = best, score >= b.score { continue }
            let off = Rules.radius + Rules.thickness / 2
            let pad = Pad(kind: .bar, x: p.x - nx * off, y: p.y - ny * off, angle: a, note: note)
            var trial = c; trial.pads.append(pad)
            let h2 = simulate(trial, maxTime: 90, below: 2600).hits, m = s.hits.count
            guard h2.count == m + 1, h2[m].pad == c.pads.count, abs(h2[m].time - ts) < 0.012 else { continue }
            let same = (0..<m).allSatisfy { h2[$0].pad == s.hits[$0].pad && abs(h2[$0].time - s.hits[$0].time) < 1e-6 }
            if same { best = (score, pad) }
        }
        guard let b = best else { return false }
        c.pads.append(b.pad)
        return true
    }

    /// "Twinkle, Twinkle" (first line), built with the same helper: [beats since the last note, note].
    static func demo() -> Course {
        var c = Course()
        for (g, n) in [(1.0, 7), (1, 7), (1, 11), (1, 11), (1, 12), (1, 12), (1, 11), (2, 10), (1, 10), (1, 9), (1, 9), (1, 8), (1, 8), (1, 7)] {
            _ = smartAdd(&c, beats: g, note: n)
        }
        return c
    }
}
