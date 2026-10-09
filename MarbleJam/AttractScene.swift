import SpriteKit

/// Where a course lands on screen when it is scaled to fit: whole course visible, centred, `margin` points clear top and bottom.
struct CourseFit {
    let scale: Double, offsetX: Double, offsetY: Double

    init(top: Double, bottom: Double, size: CGSize, margin: Double) {
        let w = Double(size.width), h = Double(size.height)
        scale = min(w / Rules.width, (h - 2 * margin) / max(1, bottom - top))
        offsetX = (w - Rules.width * scale) / 2
        offsetY = (h - (bottom - top) * scale) / 2 - top * scale
    }

    /// Screen position (points, y down) of a world coordinate.
    func screenX(_ x: Double) -> Double { offsetX + x * scale }
    func screenY(_ y: Double) -> Double { offsetY + y * scale }
}

/// The menu's background: the demo course with marbles dropping one after another, flashing the pads they hit.
/// Silent, and still (no marbles) when Reduce Motion is on.
final class AttractScene: SKScene {
    var animated = true
    var marbleGlow: UIColor = Theme.standard.marbleGlow.uiColor
    var skin: Skin = Skins.classic

    private struct Ball { let node: SKShapeNode; let start: TimeInterval; var hit: Int }

    private let world = SKNode(), padLayer = SKNode(), fxLayer = SKNode()
    private var course: Course?
    private var run = Run()
    private var padNodes: [SKShapeNode] = []
    private var balls: [Ball] = []
    private var nextDrop: TimeInterval = 0
    private let dropEvery = 1.6

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        guard world.parent == nil else { return }
        addChild(world)
        world.addChild(padLayer); world.addChild(fxLayer)
        DispatchQueue.global(qos: .userInitiated).async {                     // building the demo takes a moment
            let c = Engine.demo(firstNotes: 14), r = Engine.simulate(c)
            DispatchQueue.main.async { [weak self] in self?.show(c, r) }
        }
    }

    override func didChangeSize(_ oldSize: CGSize) { layoutWorld() }

    private func show(_ c: Course, _ r: Run) {
        course = c; run = r
        padNodes = c.pads.map(PadArt.node(for:))
        padNodes.forEach(padLayer.addChild)
        layoutWorld()
    }

    private func layoutWorld() {
        guard let c = course, size.width > 0 else { return }
        let fit = CourseFit(top: c.dropY - 40, bottom: (c.pads.map(\.y).max() ?? c.dropY) + 80, size: size, margin: 60)
        world.xScale = fit.scale; world.yScale = -fit.scale                       // flip: the course's y grows downward
        world.position = CGPoint(x: fit.offsetX, y: Double(size.height) - fit.offsetY)
    }

    override func update(_ now: TimeInterval) {
        guard animated, let c = course, !run.hits.isEmpty else { return }
        if now >= nextDrop {
            let n = PadArt.marble(glow: marbleGlow, skin: skin); world.addChild(n)
            balls.append(Ball(node: n, start: now, hit: 0))
            nextDrop = now + dropEvery
        }
        for i in balls.indices {
            let t = now - balls[i].start, p = run.position(at: min(t, run.duration))
            balls[i].node.position = CGPoint(x: p.x, y: p.y)
            while balls[i].hit < run.hits.count, run.hits[balls[i].hit].time <= t {
                let h = run.hits[balls[i].hit]
                PadArt.flash(padNodes[h.pad], color: PadArt.color(c.pads[h.pad]), at: CGPoint(x: h.x, y: h.y), sparksIn: fxLayer)
                balls[i].hit += 1
            }
        }
        balls.removeAll { b in
            let done = now - b.start > run.duration
            if done { b.node.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()])) }
            return done
        }
    }
}
