import SpriteKit

/// Draws the run and handles touches. The `world` node is flipped so its children use the engine's coordinates (y down).
final class RunScene: SKScene {
    weak var model: GameModel?

    private let world = SKNode(), guideLayer = SKNode(), padLayer = SKNode(), fxLayer = SKNode()
    private let marble = SKShapeNode(circleOfRadius: Rules.radius)
    private var padNodes: [SKShapeNode] = []
    private var seenVersion = -1
    private var camY = -110.0
    private var targetCamY: Double?
    private var backY = -110.0
    private var wasPlaying = false
    private var hitIndex = 0

    private enum Drag { case move(dx: Double, dy: Double), tilt, hopper, pan(startY: CGFloat, camY: Double, moved: Bool) }
    private var drag: Drag?

    private var base: Double { max(0.01, Double(size.width) / Rules.width) }
    private var viewHeight: Double { Double(size.height) / base }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.04, green: 0.05, blue: 0.11, alpha: 1)
        guard world.parent == nil else { return }
        addChild(world)
        [guideLayer, padLayer, fxLayer].forEach { world.addChild($0) }
        marble.fillColor = .white
        marble.strokeColor = UIColor(red: 0.62, green: 0.83, blue: 1, alpha: 1)
        marble.glowWidth = 8
        marble.zPosition = 10
        world.addChild(marble)
        layoutWorld()
    }

    override func didChangeSize(_ oldSize: CGSize) { seenVersion = -1; layoutWorld() }

    private func layoutWorld() {
        world.xScale = base; world.yScale = -base
        world.position = CGPoint(x: 0, y: Double(size.height) + camY * base)
    }

    private func color(_ p: Pad, _ brightness: Double = 1) -> UIColor {
        UIColor(hue: Notes.hue(p), saturation: 0.82, brightness: brightness, alpha: 1)
    }

    // MARK: drawing

    private func rebuild() {
        guard let m = model else { return }
        guideLayer.removeAllChildren(); padLayer.removeAllChildren(); padNodes.removeAll()
        let live = Set(m.run.hits.map(\.pad))

        if !m.playing {                                       // the predicted path, with a ring on every beat
            let path = CGMutablePath(), pts = m.run.path
            var i = 0
            while i + 1 < pts.count {
                let pt = CGPoint(x: pts[i], y: pts[i + 1])
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                i += 2
            }
            let line = SKShapeNode(path: path.copy(dashingWithPhase: 0, lengths: [3, 7]))
            line.strokeColor = UIColor(white: 0.9, alpha: 0.32); line.lineWidth = 2
            guideLayer.addChild(line)
            var k = 1
            while Double(k) * Rules.beat / 2 < m.run.duration {
                let p = m.run.position(at: Double(k) * Rules.beat / 2), whole = k % 2 == 0
                let dot = SKShapeNode(circleOfRadius: whole ? 5 : 2.2)
                dot.position = CGPoint(x: p.x, y: p.y)
                if whole { dot.strokeColor = UIColor(red: 1, green: 0.85, blue: 0.35, alpha: 0.85); dot.lineWidth = 2; dot.fillColor = .clear }
                else { dot.fillColor = UIColor(white: 0.9, alpha: 0.5); dot.strokeColor = .clear }
                guideLayer.addChild(dot)
                k += 1
            }
            for h in m.run.hits {
                let ring = SKShapeNode(circleOfRadius: 9), on = Engine.isOnBeat(h.time)
                ring.position = CGPoint(x: h.x, y: h.y); ring.fillColor = .clear
                ring.strokeColor = on ? UIColor(red: 1, green: 0.85, blue: 0.35, alpha: 1) : UIColor(white: 1, alpha: 0.7)
                ring.lineWidth = on ? 3 : 1.5
                guideLayer.addChild(ring)
            }
        }

        let hop = CGMutablePath(), dx = m.course.dropX, dy = m.course.dropY          // the hopper the marble drops from
        hop.move(to: CGPoint(x: dx - 26, y: dy - 44)); hop.addLine(to: CGPoint(x: dx + 26, y: dy - 44))
        hop.addLine(to: CGPoint(x: dx + 9, y: dy - 22)); hop.addLine(to: CGPoint(x: dx - 9, y: dy - 22)); hop.closeSubpath()
        let hopper = SKShapeNode(path: hop); hopper.fillColor = UIColor(white: 0.88, alpha: 0.9); hopper.strokeColor = .clear
        guideLayer.addChild(hopper)

        for (i, p) in m.course.pads.enumerated() {
            let node: SKShapeNode
            if p.kind == .bar {
                let L = Notes.barLength(p.note), T = Rules.thickness
                node = SKShapeNode(rect: CGRect(x: -L / 2, y: -T / 2, width: L, height: T), cornerRadius: T / 2)
                node.zRotation = p.angle
            } else {
                node = SKShapeNode(circleOfRadius: Notes.bumperRadius(p.note))
            }
            node.position = CGPoint(x: p.x, y: p.y)
            node.fillColor = color(p); node.strokeColor = color(p); node.glowWidth = 5
            node.alpha = (live.contains(i) || m.playing) ? 1 : 0.4
            padLayer.addChild(node); padNodes.append(node)

            let label = SKLabelNode(text: Notes.name(p))
            label.fontName = "AvenirNext-Bold"; label.fontSize = 15; label.fontColor = color(p); label.yScale = -1
            label.verticalAlignmentMode = .center
            let off = p.kind == .bar ? 30.0 : Notes.bumperRadius(p.note) + 22
            label.position = CGPoint(x: p.x - sin(p.angle) * off, y: p.y + cos(p.angle) * off)
            label.alpha = node.alpha
            padLayer.addChild(label)

            if p.id == m.selected && !m.playing {                                  // selection ring and the tilt handle
                let r = p.kind == .bar ? Notes.barLength(p.note) / 2 + 12 : Notes.bumperRadius(p.note) + 10
                let ringPath = CGPath(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r), transform: nil)
                let ring = SKShapeNode(path: ringPath.copy(dashingWithPhase: 0, lengths: [5, 5]))
                ring.position = node.position; ring.strokeColor = .white; ring.lineWidth = 2
                padLayer.addChild(ring)
                if p.kind == .bar {
                    let e = p.ends, handle = SKShapeNode(circleOfRadius: 13)
                    handle.position = CGPoint(x: e.2, y: e.3); handle.fillColor = .white; handle.strokeColor = .clear; handle.zPosition = 5
                    padLayer.addChild(handle)
                }
            }
        }
    }

    private func flash(_ h: Hit, in m: GameModel) {
        guard h.pad < padNodes.count else { return }
        let node = padNodes[h.pad], col = color(m.course.pads[h.pad])
        node.removeAllActions()
        node.run(.sequence([.scale(to: 1.2, duration: 0.04), .scale(to: 1, duration: 0.26)]))
        node.glowWidth = 14
        node.run(.customAction(withDuration: 0.4) { n, t in (n as? SKShapeNode)?.glowWidth = 14 - 9 * t / 0.4 })
        for _ in 0..<12 {                                                            // sparks
            let s = SKShapeNode(rectOf: CGSize(width: 4, height: 4))
            s.fillColor = col; s.strokeColor = .clear; s.position = CGPoint(x: h.x, y: h.y)
            let a = Double.random(in: 0..<(2 * .pi)), v = Double.random(in: 30...110)
            fxLayer.addChild(s)
            s.run(.sequence([.group([.moveBy(x: cos(a) * v, y: sin(a) * v + 40, duration: 0.5), .fadeOut(withDuration: 0.5)]), .removeFromParent()]))
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard let m = model else { return }
        if m.playing != wasPlaying {                                                 // remember where the builder was looking
            if m.playing { backY = camY; hitIndex = 0 } else { targetCamY = backY }
            wasPlaying = m.playing
        }
        if let f = m.focusY { targetCamY = max(-140, f - viewHeight * 0.55); m.focusY = nil }
        if let r = m.revealY {
            if r < camY + 60 || r > camY + viewHeight * 0.6 { targetCamY = clampCam(r - viewHeight * 0.4) }   // the tray covers the bottom
            m.revealY = nil
        }
        if m.version != seenVersion { seenVersion = m.version; rebuild() }
        if m.playing {
            let t = m.playTime, p = m.run.position(at: max(0, min(t, m.run.duration)))
            marble.position = CGPoint(x: p.x, y: p.y); marble.alpha = 1
            while hitIndex < m.run.hits.count, m.run.hits[hitIndex].time <= t { flash(m.run.hits[hitIndex], in: m); hitIndex += 1 }
            camY += (p.y - viewHeight * 0.4 - camY) * 0.12                           // the camera follows the marble
            if t > m.run.duration + 0.7 { m.finish() }
        } else {
            marble.position = CGPoint(x: m.course.dropX, y: m.course.dropY); marble.alpha = 0.55
            if let ty = targetCamY, drag == nil { camY += (ty - camY) * 0.12; if abs(ty - camY) < 1 { targetCamY = nil } }
        }
        layoutWorld()
    }

    // MARK: touches

    private func pick(_ x: Double, _ y: Double, _ pads: [Pad]) -> Int? {
        for i in pads.indices.reversed() {
            let p = pads[i]
            if p.kind == .bar {
                let e = p.ends, ex = e.2 - e.0, ey = e.3 - e.1
                let u = max(0, min(1, ((x - e.0) * ex + (y - e.1) * ey) / (ex * ex + ey * ey)))
                if hypot(x - e.0 - ex * u, y - e.1 - ey * u) < Rules.thickness / 2 + 20 { return i }
            } else if hypot(x - p.x, y - p.y) < Notes.bumperRadius(p.note) + 12 { return i }
        }
        return nil
    }

    private func clampCam(_ y: Double) -> Double {
        guard let m = model else { return y }
        return max(-140, min(m.maxY + 200 - viewHeight * 0.5, y))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let m = model, !m.playing, let t = touches.first else { return }
        let loc = t.location(in: world), x = Double(loc.x), y = Double(loc.y)
        if let s = m.selectedPad, s.kind == .bar, hypot(x - s.ends.2, y - s.ends.3) < 30 { m.mark(); drag = .tilt; return }
        if hypot(x - m.course.dropX, y - (m.course.dropY - 30)) < 46 { m.mark(); drag = .hopper; return }
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
        if case let .pan(_, _, moved) = d { if !moved { m.selected = nil; seenVersion = -1 } } else { m.save() }
        drag = nil
    }
}
