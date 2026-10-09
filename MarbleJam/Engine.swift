import Foundation

// World rules: the same as the Shorts and the web prototype. Units are points in a 720-wide world, y grows downward.
enum Rules {
    static let width = 720.0, gravity = 1800.0, radius = 14.0, thickness = 14.0
    static let barBounce = 0.45, bumperBounce = 0.9, step = 1.0 / 240.0, beat = 0.5
    static let rampLength = 320.0, rampLengths = 160.0...560.0, rampBend = 0.0, rampBends = -0.8...0.8
    static let rotateStep = 5 * Double.pi / 180

    /// Keeps a pad inside the world, the same limits as dragging.
    static func clampPad(x: Double, y: Double) -> (x: Double, y: Double) { (max(20, min(width - 20, x)), max(40, y)) }
    static func clampAngle(_ a: Double) -> Double { max(-1.4, min(1.4, a)) }

    /// A bar's tilt from a direction (either end works), clamped like the tilt handle.
    static func barAngle(dx: Double, dy: Double) -> Double {
        var a = atan2(dy, dx)
        if a > .pi / 2 { a -= .pi }
        if a < -.pi / 2 { a += .pi }
        return clampAngle(a)
    }
}

struct Pad: Codable, Identifiable, Equatable {
    enum Kind: String, Codable { case bar, bumper, ramp }
    var id = UUID()
    var kind: Kind
    var x: Double
    var y: Double
    var angle: Double = 0          // radians, bars and ramps
    var note: Int                  // bars and ramps 0...14 (C4...C6; a bar's size is its note), bumpers 0...7 (C3...C4)
    var length: Double? = nil      // ramps: end-to-end length (default Rules.rampLength)
    var bend: Double? = nil        // ramps: -0.8...0.8, positive sags into a dip, negative arches into a hump

    /// Where the tilt handle sits: a bar's or ramp's far end (bumpers have none).
    var tiltHandle: (x: Double, y: Double)? {
        switch kind {
        case .bar: let e = ends; return (e.2, e.3)
        case .ramp: return rampPoints().last
        case .bumper: return nil
        }
    }

    /// Distance from a point to the piece's surface centre line (0 inside a bumper), for picking it up with a finger.
    func distance(toX px: Double, y py: Double) -> Double {
        func seg(_ a: (x: Double, y: Double), _ b: (x: Double, y: Double)) -> Double {
            let ex = b.x - a.x, ey = b.y - a.y, l2 = max(ex * ex + ey * ey, 1e-9)
            let u = max(0, min(1, ((px - a.x) * ex + (py - a.y) * ey) / l2))
            return hypot(px - a.x - ex * u, py - a.y - ey * u)
        }
        switch kind {
        case .bar: let e = ends; return seg((e.0, e.1), (e.2, e.3))
        case .bumper: return max(0, hypot(px - x, py - y) - Notes.bumperRadius(note))
        case .ramp: let pts = rampPoints(); return zip(pts, pts.dropFirst()).map { seg($0, $1) }.min() ?? .infinity
        }
    }

    /// Points along a ramp's centre line, first end to last (17 points: 16 short segments).
    func rampPoints(segments n: Int = 16) -> [(x: Double, y: Double)] {
        let L = length ?? Rules.rampLength, b = bend ?? Rules.rampBend, c = cos(angle), s = sin(angle)
        return (0...n).map { k in
            let t = Double(k) / Double(n)
            let lx = (t - 0.5) * L, ly = 4 * t * (1 - t) * b * L * 0.3          // a parabola: 0 at both ends, deepest in the middle
            return (x + lx * c - ly * s, y + lx * s + ly * c)
        }
    }

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
    static func midi(_ p: Pad) -> Int { (p.kind == .bumper ? 48 : 60) + 12 * (p.note / 7) + major[p.note % 7] }
    static func name(_ p: Pad) -> String { names[p.note % 7] + String((p.kind == .bumper ? 3 : 4) + p.note / 7) }
    /// What a pad's label says: the note, or the drum piece when the song plays drums.
    static func label(_ p: Pad, instrument: Instrument) -> String {
        instrument == .drums ? Drum.piece(midi: midi(p), bar: p.kind != .bumper).label : name(p)
    }
    static func barLength(_ n: Int) -> Double { 210 - 10 * Double(n) }
    static func bumperRadius(_ n: Int) -> Double { 46 - 4 * Double(n) }
    static func hue(_ p: Pad) -> Double { hues[p.note % 7] / 360 }
    static func maxNote(_ k: Pad.Kind) -> Int { k == .bumper ? 7 : 14 }
}

enum Engine {
    /// Drops the marble and follows it with fixed steps. The preview and the performance both use this, so they always agree.
    static func simulate(_ c: Course, maxTime: Double = 120, below: Double = 500) -> Run {
        struct Geo { let ax, ay, bx, by, r, e: Double; let pad: Int; let rolls: Bool }
        let geo: [Geo] = c.pads.enumerated().flatMap { j, p -> [Geo] in
            switch p.kind {
            case .bar: let e = p.ends; return [Geo(ax: e.0, ay: e.1, bx: e.2, by: e.3, r: Rules.thickness / 2, e: Rules.barBounce, pad: j, rolls: false)]
            case .bumper: return [Geo(ax: p.x, ay: p.y, bx: p.x, by: p.y, r: Notes.bumperRadius(p.note), e: Rules.bumperBounce, pad: j, rolls: false)]
            case .ramp:                                                      // short segments that don't bounce: the marble slides along them
                let pts = p.rampPoints()
                return zip(pts, pts.dropFirst()).map { a, b in Geo(ax: a.x, ay: a.y, bx: b.x, by: b.y, r: Rules.thickness / 2, e: 0, pad: j, rolls: true) }
            }
        }
        let low = (c.pads.map(\.y) + [c.dropY]).max()! + below
        var last = [Double](repeating: -1, count: c.pads.count)              // last note time per pad
        var touch = [Double](repeating: -1, count: c.pads.count)             // last contact time per pad (ramps: rolling keeps touching)
        // Ramps: only the segment nearest the marble collides, so a joint's corner can't fling a landing marble sideways.
        var rampSegments: [Int: Range<Int>] = [:]
        for (j, g) in geo.enumerated() where g.rolls { rampSegments[g.pad] = (rampSegments[g.pad]?.lowerBound ?? j)..<(j + 1) }
        var nearest = [Int](repeating: -1, count: c.pads.count)
        var rolling = 0.0                                                    // seconds of unbroken contact with ramps
        var x = c.dropX, y = c.dropY, vx = 0.0, vy = 0.0, t = 0.0, calm = 0.0, i = 0
        var run = Run()
        let h = Rules.step, R = Rules.radius, W = Rules.width
        while t < maxTime {
            if i % 4 == 0 { run.path.append(x); run.path.append(y) }
            i += 1
            vy += Rules.gravity * h; x += vx * h; y += vy * h; t += h
            if x < R { x = R; if vx < 0 { vx *= -0.6 } } else if x > W - R { x = W - R; if vx > 0 { vx *= -0.6 } }
            for (pad, r) in rampSegments {
                var best = Double.infinity
                for j in r {
                    let g = geo[j], ex = g.bx - g.ax, ey = g.by - g.ay, l2 = max(ex * ex + ey * ey, 1e-9)
                    let u = max(0, min(1, ((x - g.ax) * ex + (y - g.ay) * ey) / l2))
                    let d = hypot(x - g.ax - ex * u, y - g.ay - ey * u)
                    if d < best { best = d; nearest[pad] = j }
                }
            }
            var onRamp = false
            for j in geo.indices {
                if geo[j].rolls && nearest[geo[j].pad] != j { continue }
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
                    let landed = g.rolls ? t - touch[g.pad] > 0.1 : t - last[g.pad] > 0.08      // a ramp plays once per landing, not while rolling
                    if -vn > 60 && landed { run.hits.append(Hit(time: t, x: qx + dx * g.r, y: qy + dy * g.r, pad: g.pad, speed: -vn)); last[g.pad] = t }
                }
                touch[g.pad] = t
                if g.rolls { onRamp = true }
                x = qx + dx * rr; y = qy + dy * rr
            }
            if onRamp {                                                       // a little rolling friction, so a marble in a dip settles
                vx *= 1 - 0.3 * h; vy *= 1 - 0.3 * h
                rolling += h
                if rolling > 8 { break }                                       // still rocking after 8 s: call it stopped
            } else { rolling = 0 }
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

    /// How far a time is from the nearest half beat, in seconds.
    static func beatOffset(_ t: Double) -> Double {
        let g = Rules.beat / 2
        return abs(t - (t / g).rounded() * g)
    }

    /// Within this of a half beat, a pad counts as "close": it glows faintly and snaps on when let go.
    static let nearBeat = 0.08

    enum BeatState: Equatable { case on, near, off, unused }

    /// For each pad: on the beat (every hit is), close (every hit is near), off, or never hit.
    static func beatStates(_ run: Run, padCount: Int) -> [BeatState] {
        var times = [[Double]](repeating: [], count: padCount)
        for h in run.hits where h.pad < padCount { times[h.pad].append(h.time) }
        return times.map { ts in
            if ts.isEmpty { return .unused }
            if ts.allSatisfy(isOnBeat) { return .on }
            if ts.allSatisfy({ beatOffset($0) <= nearBeat }) { return .near }
            return .off
        }
    }

    /// Slides a pad that is close to the beat along the marble's way in, so it is hit exactly on the beat.
    /// Nil when the pad is far off, already on, or the move would change what happens before it.
    static func snapToBeat(_ c: Course, pad i: Int) -> Course? {
        guard c.pads.indices.contains(i) else { return nil }
        let original = simulate(c)
        guard let first = original.hits.first(where: { $0.pad == i }), !isOnBeat(first.time), beatOffset(first.time) <= nearBeat else { return nil }
        let g = Rules.beat / 2, target = (first.time / g).rounded() * g
        let before = original.hits.prefix { $0.pad != i }
        var free = c; free.pads.remove(at: i)
        let way = simulate(free)                                   // the marble's path as if this pad weren't there
        var trial = c
        for _ in 0..<4 {                                           // a few corrections: moving the pad shifts the contact point a little
            guard let h = simulate(trial).hits.first(where: { $0.pad == i }) else { return nil }
            if isOnBeat(h.time) && abs(h.time - target) < 0.02 { break }
            let p = way.position(at: target), q = way.position(at: h.time)
            let moved = Rules.clampPad(x: trial.pads[i].x + p.x - q.x, y: trial.pads[i].y + p.y - q.y)
            trial.pads[i].x = moved.x; trial.pads[i].y = moved.y
        }
        let result = simulate(trial)
        guard beatStates(result, padCount: trial.pads.count)[i] == .on else { return nil }
        let same = result.hits.count >= before.count && zip(before, result.hits).allSatisfy { $0.pad == $1.pad && abs($0.time - $1.time) < 1e-6 }
        return same ? trial : nil
    }

    /// Puts a ramp where the marble will be, about a beat after its last note, sloping the way the marble moves, so it lands
    /// on it and rolls on. Earlier notes are unchanged. False if no spot works.
    static func rampAdd(_ c: inout Course, note: Int, length: Double = Rules.rampLength) -> Bool {
        let s = simulate(c, maxTime: 90, below: 2600), lift = Rules.radius + Rules.thickness / 2 + 1
        for beats in [1.0, 1.5, 2, 0.5] {
            let t = (s.hits.last?.time ?? 0) + beats * Rules.beat
            guard t < s.duration - 0.05 else { continue }
            let p = s.position(at: t), q = s.position(at: t + 0.02), dir: Double = q.x >= p.x ? 1 : -1
            for a in [0.3, 0.45, 0.2] {
                let pad = Pad(kind: .ramp, x: p.x + dir * 0.35 * length * cos(a), y: p.y + lift + 0.35 * length * sin(a), angle: dir * a, note: note,
                              length: length, bend: Rules.rampBend)
                guard pad.x > 60, pad.x < Rules.width - 60 else { continue }
                var trial = c; trial.pads.append(pad)
                let h = simulate(trial, maxTime: 90, below: 2600).hits, m = s.hits.count
                let same = h.count > m && (0..<m).allSatisfy { h[$0].pad == s.hits[$0].pad && abs(h[$0].time - s.hits[$0].time) < 1e-6 }
                if same && h[m].pad == c.pads.count { c = trial; return true }
            }
        }
        return false
    }

    /// The helper that makes this a composer: puts the next pad exactly where the marble is on the beat.
    static func smartAdd(_ c: inout Course, beats: Double, note: Int) -> Bool {
        let s = simulate(c, maxTime: 90, below: 2600)
        let g = Rules.beat / 2, tl = s.hits.last?.time ?? 0
        let ts = ((tl + beats * Rules.beat) / g).rounded() * g             // aim at the beat itself, so small errors never add up over a long song
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

    /// "Twinkle, Twinkle", the whole song: [beats since the last note, note]. Built with the same helper as everything else.
    static let twinkle: [(beats: Double, note: Int)] = [(1, 7), (1, 7), (1, 11), (1, 11), (1, 12), (1, 12), (1, 11), (2, 10), (1, 10), (1, 9), (1, 9), (1, 8), (1, 8), (1, 7), (2, 11), (1, 11), (1, 10), (1, 10), (1, 9), (1, 9), (1, 8), (2, 11), (1, 11), (1, 10), (1, 10), (1, 9), (1, 9), (1, 8), (2, 7), (1, 7), (1, 11), (1, 11), (1, 12), (1, 12), (1, 11), (2, 10), (1, 10), (1, 9), (1, 9), (1, 8), (1, 8), (1, 7)]

    /// The demo course; `firstNotes` keeps it short (the menu's background plays the first line).
    static func demo(firstNotes: Int = .max) -> Course {
        var c = Course()
        for m in twinkle.prefix(firstNotes) { _ = smartAdd(&c, beats: m.beats, note: m.note) }
        return c
    }
}
