import SpriteKit

/// How pads, the marble and a hit look. Shared by the game (RunScene) and the menu's demo (AttractScene).
/// Nodes live in a world whose y grows downward, like the engine's coordinates.
enum PadArt {
    static func color(_ p: Pad) -> UIColor { UIColor(hue: Notes.hue(p), saturation: 0.82, brightness: 1, alpha: 1) }

    /// A glowing bar or bumper, placed and turned like the pad.
    static func node(for p: Pad) -> SKShapeNode {
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
        return node
    }

    static func marble(glow: UIColor = Theme.standard.marbleGlow.uiColor) -> SKShapeNode {
        let m = SKShapeNode(circleOfRadius: Rules.radius)
        m.fillColor = .white
        m.strokeColor = glow
        m.glowWidth = 8
        m.zPosition = 10
        return m
    }

    /// The pad pulses and glows, and sparks fly from the point of contact.
    static func flash(_ node: SKShapeNode, color: UIColor, at point: CGPoint, sparksIn layer: SKNode) {
        node.removeAllActions()
        node.run(.sequence([.scale(to: 1.2, duration: 0.04), .scale(to: 1, duration: 0.26)]))
        node.glowWidth = 14
        node.run(.customAction(withDuration: 0.4) { n, t in (n as? SKShapeNode)?.glowWidth = 14 - 9 * t / 0.4 })
        for _ in 0..<12 {
            let s = SKShapeNode(rectOf: CGSize(width: 4, height: 4))
            s.fillColor = color; s.strokeColor = .clear; s.position = point
            let a = Double.random(in: 0..<(2 * .pi)), v = Double.random(in: 30...110)
            layer.addChild(s)
            s.run(.sequence([.group([.moveBy(x: cos(a) * v, y: sin(a) * v + 40, duration: 0.5), .fadeOut(withDuration: 0.5)]), .removeFromParent()]))
        }
    }

    static let beatGold = UIColor(red: 1, green: 0.85, blue: 0.35, alpha: 1)

    /// A gold outline around a pad that is on the beat (pulsing) or close to it (faint).
    static func halo(for p: Pad, onBeat: Bool) -> SKShapeNode {
        let h = node(for: p)
        h.fillColor = .clear; h.strokeColor = beatGold; h.lineWidth = 3
        h.glowWidth = onBeat ? 16 : 8
        h.zPosition = -1
        if onBeat {
            h.run(.repeatForever(.sequence([.fadeAlpha(to: 0.45, duration: 0.6), .fadeAlpha(to: 1, duration: 0.6)])))
        } else {
            h.alpha = 0.35
        }
        return h
    }
}

/// Small taps felt when a pad lands on the beat.
enum Haptics {
    static func onBeat() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func snapped() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
}
