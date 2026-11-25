import SpriteKit

/// Draws the run and handles touches. The `world` node is flipped so its children use the engine's coordinates (y down).
/// With a 3D `room` underneath, it draws only the 2D layer (labels, guides, selection) and drives the room every frame.
final class RunScene: SKScene {
    weak var model: GameModel?
    var room: Course3D? { didSet { seenVersion = -1 } }

    private let world = SKNode(), guideLayer = SKNode(), padLayer = SKNode(), fxLayer = SKNode()
    private let marble = PadArt.marble()
    /// The marble's outline and glow: the holiday tint, or ice blue.
    var marbleGlow: UIColor = Theme.standard.marbleGlow.uiColor { didSet { marble.strokeColor = marbleGlow } }
    var skin: Skin = Skins.classic { didSet { marble.fillTexture = PadArt.texture(skin) } }
    private var padNodes: [SKShapeNode] = []
    private var seenVersion = -1
    private var camY = 0.0                      // world y at the top of the screen; placed under the header once the size is known
    private var targetCamY: Double?
    private var backY = 0.0
    private var cameraPlaced = false
    private var wasPlaying = false
    private var hitIndex = 0

    private enum Drag { case move(dx: Double, dy: Double), tilt, hopper, pan(startY: CGFloat, camY: Double, moved: Bool) }
    private var drag: Drag?
    private var lastBeats: [UUID: Engine.BeatState] = [:]      // to feel the moment a dragged pad lands on the beat

    private var base: Double { max(0.01, Double(size.width) / Rules.width) }
    private var viewHeight: Double { Double(size.height) / base }
    /// The highest the camera goes: the top of the course (the hopper) sits just below the header.
    private var topCam: Double { -175 / base }

    override func didMove(to view: SKView) {
        backgroundColor = .clear                                     // the Backdrop behind the SpriteView shows through
        guard world.parent == nil else { return }
        addChild(world)
        [guideLayer, padLayer, fxLayer].forEach { world.addChild($0) }
        world.addChild(marble)
        layoutWorld()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        if !cameraPlaced && size.width > 100 { camY = topCam; backY = topCam; cameraPlaced = true }   // the scene starts as a 1x1 placeholder
        seenVersion = -1; layoutWorld()
    }

    private func layoutWorld() {
        world.xScale = base; world.yScale = -base
        world.position = CGPoint(x: 0, y: Double(size.height) + camY * base)
    }

    private func color(_ p: Pad) -> UIColor { PadArt.color(p) }

    // The 3D room's wall is light, the 2D backdrop dark: guides and labels use dark ink on the wall and light ink on the backdrop.
    private var onLightWall: Bool { room != nil }
    private var ink: UIColor { onLightWall ? UIColor(red: 0.12, green: 0.1, blue: 0.1, alpha: 1) : .white }
    private var beatColor: UIColor { onLightWall ? UIColor(red: 0.82, green: 0.48, blue: 0, alpha: 1) : UIColor(red: 1, green: 0.85, blue: 0.35, alpha: 1) }
    /// A note's label colour: the pad's colour, deepened so it reads on the light wall.
    private func labelColor(_ p: Pad) -> UIColor {
        guard onLightWall else { return color(p) }
        return UIColor(hue: Notes.hue(p), saturation: 0.95, brightness: 0.5, alpha: 1)
    }

    // MARK: drawing

    private func rebuild() {
        guard let m = model else { return }
        guideLayer.removeAllChildren(); padLayer.removeAllChildren(); padNodes.removeAll()
        let live = Set(m.run.hits.map(\.pad))
        var cup: (x: Double, y: Double)?
        if case let .target(cx, cy)? = m.challenge?.goal { cup = (cx, cy) }
        room?.rebuild(m.course, beats: m.beats, playing: m.playing, cup: cup)

        if !m.playing {                                       // the predicted path, with a ring on every beat
            let path = CGMutablePath(), pts = m.run.path
            var i = 0
            while i + 1 < pts.count {
                let pt = CGPoint(x: pts[i], y: pts[i + 1])
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                i += 2
            }
            let line = SKShapeNode(path: path.copy(dashingWithPhase: 0, lengths: [3, 7]))
            line.strokeColor = onLightWall ? ink.withAlphaComponent(0.55) : UIColor(white: 0.9, alpha: 0.32); line.lineWidth = onLightWall ? 2.5 : 2
            guideLayer.addChild(line)
            var k = 1
            while Double(k) * Rules.beat / 2 < m.run.duration {
                let p = m.run.position(at: Double(k) * Rules.beat / 2), whole = k % 2 == 0
                let dot = SKShapeNode(circleOfRadius: whole ? 5 : 2.2)
                dot.position = CGPoint(x: p.x, y: p.y)
                if whole { dot.strokeColor = beatColor.withAlphaComponent(0.9); dot.lineWidth = 2; dot.fillColor = .clear }
                else { dot.fillColor = onLightWall ? ink.withAlphaComponent(0.5) : UIColor(white: 0.9, alpha: 0.5); dot.strokeColor = .clear }
                guideLayer.addChild(dot)
                k += 1
            }
            for h in m.run.hits {
                let ring = SKShapeNode(circleOfRadius: 9), on = Engine.isOnBeat(h.time)
                ring.position = CGPoint(x: h.x, y: h.y); ring.fillColor = .clear
                ring.strokeColor = on ? beatColor : ink.withAlphaComponent(0.7)
                ring.lineWidth = on ? 3 : 1.5
                guideLayer.addChild(ring)
            }
            drawGhosts(m)
        }

        if room == nil, case let .target(cx, cy)? = m.challenge?.goal {          // the cup: a glowing ring with a dot
            let r = Challenge.cupRadius
            let glow = SKShapeNode(circleOfRadius: r); glow.position = CGPoint(x: cx, y: cy)
            glow.strokeColor = PadArt.beatGold; glow.lineWidth = 4; glow.glowWidth = 10; glow.fillColor = PadArt.beatGold.withAlphaComponent(0.15)
            glow.run(.repeatForever(.sequence([.scale(to: 1.12, duration: 0.7), .scale(to: 1, duration: 0.7)])))
            guideLayer.addChild(glow)
            let dot = SKShapeNode(circleOfRadius: 5); dot.position = glow.position; dot.fillColor = PadArt.beatGold; dot.strokeColor = .clear
            guideLayer.addChild(dot)
        }

        let hop = CGMutablePath(), dx = m.course.dropX, dy = m.course.dropY          // the hopper the marble drops from (the room draws its own)
        if room == nil {
        hop.move(to: CGPoint(x: dx - 26, y: dy - 44)); hop.addLine(to: CGPoint(x: dx + 26, y: dy - 44))
        hop.addLine(to: CGPoint(x: dx + 9, y: dy - 22)); hop.addLine(to: CGPoint(x: dx - 9, y: dy - 22)); hop.closeSubpath()
        let hopper = SKShapeNode(path: hop); hopper.fillColor = UIColor(white: 0.88, alpha: 0.9); hopper.strokeColor = .clear
        guideLayer.addChild(hopper)
        }

        for (i, p) in m.course.pads.enumerated() {
            let node = PadArt.node(for: p)
            node.alpha = (live.contains(i) || m.playing) ? 1 : 0.4
            if room == nil { padLayer.addChild(node) }                          // with the room, the 3D piece is drawn underneath
            padNodes.append(node)
            let beat = i < m.beats.count ? m.beats[i] : .unused
            if room == nil, !m.playing && (beat == .on || beat == .near) { padLayer.addChild(PadArt.halo(for: p, onBeat: beat == .on)) }
            if drag != nil, beat == .on, let was = lastBeats[p.id], was != .on { Haptics.onBeat() }
            lastBeats[p.id] = beat

            let label = SKLabelNode(text: Notes.label(p, instrument: m.instrument))
            label.fontName = "AvenirNext-Bold"; label.fontSize = 15; label.fontColor = beat == .on && !m.playing ? beatColor : labelColor(p); label.yScale = -1
            label.verticalAlignmentMode = .center
            let off = p.kind == .bumper ? Notes.bumperRadius(p.note) + 22 : 30.0
            let mid = p.kind == .ramp ? { let pts = p.rampPoints(); return pts[pts.count / 2] }() : (x: p.x, y: p.y)          // a ramp's label sits under its middle
            label.position = CGPoint(x: mid.x - sin(p.angle) * off, y: mid.y + cos(p.angle) * off)
            label.alpha = node.alpha
            if m.isLocked(p.id) { label.text = "🔒 " + (label.text ?? "") }      // locked puzzle pieces
            if room == nil || !m.playing { padLayer.addChild(label) }              // the show camera tilts: labels would drift off their pieces

            if p.id == m.selected && !m.playing {                                  // selection ring and the tilt handle
                let r = switch p.kind {
                case .bar: Notes.barLength(p.note) / 2 + 12
                case .bumper: Notes.bumperRadius(p.note) + 10
                case .ramp: (p.length ?? Rules.rampLength) / 2 + 12
                }
                let ringPath = CGPath(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r), transform: nil)
                let ring = SKShapeNode(path: ringPath.copy(dashingWithPhase: 0, lengths: [5, 5]))
                ring.position = node.position; ring.strokeColor = ink; ring.lineWidth = 2
                padLayer.addChild(ring)
                if let e = p.tiltHandle, !m.isLocked(p.id) {
                    let handle = SKShapeNode(circleOfRadius: 13)
                    handle.position = CGPoint(x: e.x, y: e.y); handle.fillColor = .white; handle.zPosition = 5
                    handle.strokeColor = onLightWall ? ink : .clear; handle.lineWidth = 2
                    padLayer.addChild(handle)
                }
            }
        }
    }

    /// Challenge hints: a glowing outline where each piece goes, and a dashed arrow from the selected piece to its outline.
    private func drawGhosts(_ m: GameModel) {
        let glow = beatColor
        for g in m.ghosts {
            let node = PadArt.node(for: g)
            node.fillColor = g.kind == .ramp ? .clear : glow.withAlphaComponent(0.22)
            node.strokeColor = glow.withAlphaComponent(g.kind == .ramp ? 0.45 : 1); node.glowWidth = 6
            if g.kind != .ramp { node.lineWidth = 2.5 }
            node.run(.repeatForever(.sequence([.fadeAlpha(to: 0.45, duration: 0.6), .fadeAlpha(to: 1, duration: 0.6)])))
            guideLayer.addChild(node)
        }
        guard let p = m.selectedPad, let g = m.ghost(for: p) else { return }
        let dx = g.x - p.x, dy = g.y - p.y, d = hypot(dx, dy)
        guard d > 60 else { return }                                                // close enough: the outline says it all
        let ux = dx / d, uy = dy / d, bx = g.x - ux * 28, by = g.y - uy * 28
        let shaft = CGMutablePath()
        shaft.move(to: CGPoint(x: p.x + ux * 28, y: p.y + uy * 28)); shaft.addLine(to: CGPoint(x: bx, y: by))
        let line = SKShapeNode(path: shaft.copy(dashingWithPhase: 0, lengths: [8, 6]))
        let head = CGMutablePath()
        head.move(to: CGPoint(x: bx - ux * 14 - uy * 9, y: by - uy * 14 + ux * 9)); head.addLine(to: CGPoint(x: bx, y: by))
        head.addLine(to: CGPoint(x: bx - ux * 14 + uy * 9, y: by - uy * 14 - ux * 9))
        let tip = SKShapeNode(path: head)
        for n in [line, tip] { n.strokeColor = glow; n.lineWidth = 3; n.lineCap = .round; n.zPosition = 4; guideLayer.addChild(n) }
    }

    private func flash(_ h: Hit, in m: GameModel) {
        if let room { room.flash(pad: h.pad, at: h); return }
        guard h.pad < padNodes.count else { return }
        let node = padNodes[h.pad], col = color(m.course.pads[h.pad])
        PadArt.flash(node, color: col, at: CGPoint(x: h.x, y: h.y), sparksIn: fxLayer)
    }

    override func update(_ currentTime: TimeInterval) {
        guard let m = model else { return }
        if m.playing != wasPlaying {                                                 // remember where the builder was looking
            if m.playing { backY = camY; hitIndex = 0 } else { targetCamY = backY }
            wasPlaying = m.playing
        }
        if let f = m.focusY { targetCamY = max(topCam, f - viewHeight * 0.55); m.focusY = nil }
        if m.version != seenVersion { seenVersion = m.version; rebuild() }
        var spin = 0.0
        if m.playing {
            let t = m.playTime, p = m.run.position(at: max(0, min(t, m.run.duration)))
            spin = m.run.spin(at: max(0, min(t, m.run.duration)))
            marble.position = CGPoint(x: p.x, y: p.y); marble.alpha = 1
            while hitIndex < m.run.hits.count, m.run.hits[hitIndex].time <= t { flash(m.run.hits[hitIndex], in: m); hitIndex += 1 }
            camY += (p.y - viewHeight * 0.4 - camY) * 0.12                           // the camera follows the marble
            if t > m.run.duration + 0.7 { m.finish() }
        } else {
            marble.position = CGPoint(x: m.course.dropX, y: m.course.dropY); marble.alpha = 0.55
            if let ty = targetCamY, drag == nil { camY += (ty - camY) * 0.12; if abs(ty - camY) < 1 { targetCamY = nil } }
        }
        layoutWorld()
        if let room {
            marble.isHidden = true                                                   // the room's chrome marble takes its place
            room.update(camY: camY, viewSize: size, playing: m.playing, marbleAt: (Double(marble.position.x), Double(marble.position.y)),
                        spin: spin,
                        marbleVisible: m.playing)
        } else { marble.isHidden = false }
    }

    // MARK: touches

    private func pick(_ x: Double, _ y: Double, _ pads: [Pad]) -> Int? {
        for i in pads.indices.reversed() {
            let p = pads[i]
            if p.distance(toX: x, y: y) < (p.kind == .bumper ? 12 : Rules.thickness / 2 + 20) { return i }
        }
        return nil
    }

    private func clampCam(_ y: Double) -> Double {
        guard let m = model else { return y }
        return max(topCam, min(m.maxY + 200 - viewHeight * 0.5, y))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let m = model, !m.playing, let t = touches.first else { return }
        let loc = t.location(in: world), x = Double(loc.x), y = Double(loc.y)
        if let s = m.selectedPad, !m.isLocked(s.id), let e = s.tiltHandle, hypot(x - e.x, y - e.y) < 30 { m.mark(); drag = .tilt; return }
        if m.challenge == nil, hypot(x - m.course.dropX, y - (m.course.dropY - 30)) < 46 { m.mark(); drag = .hopper; return }
        if let i = pick(x, y, m.course.pads) {
            let p = m.course.pads[i]
            m.selected = p.id; m.mark(); drag = .move(dx: p.x - x, dy: p.y - y)
            seenVersion = -1
            return
        }
        drag = .pan(startY: t.location(in: self).y, camY: camY, moved: false)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let m = model, let t = touches.first, let d = drag else { return }
        let loc = t.location(in: world), x = Double(loc.x), y = Double(loc.y)
        switch d {
        case let .move(dx, dy):
            m.updateSelected { let c = Rules.clampPad(x: x + dx, y: y + dy); $0.x = c.x; $0.y = c.y }
        case .tilt:
            m.updateSelected { p in p.angle = Rules.barAngle(dx: x - p.x, dy: y - p.y) }
        case .hopper:
            m.setDrop(x: max(40, min(Rules.width - 40, x)))
        case let .pan(startY, startCam, moved):
            let delta = Double(t.location(in: self).y - startY) / base                // finger up = look further down
            targetCamY = nil
            camY = clampCam(startCam + delta)
            if !moved && abs(delta) > 4 { drag = .pan(startY: startY, camY: startCam, moved: true) }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { endDrag() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { endDrag() }

    private func endDrag() {
        guard let m = model, let d = drag else { return }
        switch d {
        case let .pan(_, _, moved): if !moved { m.selected = nil; seenVersion = -1 }
        case .hopper: m.save()                                                     // moving the hopper never snaps the selected pad
        case .move, .tilt: if m.finishEdit() { Haptics.snapped() }
        }
        drag = nil
    }
}
