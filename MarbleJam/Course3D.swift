import SceneKit
import SwiftUI

/// The 3D room behind the 2D layer: a warm wall, a spot light with soft shadows, brass pieces hanging on wires and a chrome
/// marble. The 2D `RunScene` on top keeps drawing labels and guides and handles touches; it drives this scene every frame.
final class Course3D {
    let scene = SCNScene()
    let view: SCNView

    private let camera = SCNNode(), light = SCNNode(), wall = SCNNode(), pieces = SCNNode(), marble = SCNNode()
    private var pieceNodes: [SCNNode] = []
    private var pads: [Pad] = []
    private var playBlend = 0.0                                   // 0 = straight-on building camera, 1 = angled show camera
    var reduceMotion = false

    init() {
        view = SCNView(frame: .zero)
        view.scene = scene
        view.backgroundColor = .black
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.isPlaying = true                                     // keep rendering: the 2D layer moves things every frame
        view.isUserInteractionEnabled = false                     // touches go to the 2D layer on top
        buildRoom()
    }

    // MARK: room

    private func buildRoom() {
        let root = scene.rootNode
        scene.lightingEnvironment.contents = Self.environment()  // soft warm reflections for the chrome marble and brass
        scene.lightingEnvironment.intensity = 1.2

        camera.camera = SCNCamera()
        camera.camera!.fieldOfView = SceneMapping.fieldOfView
        camera.camera!.zNear = 0.05; camera.camera!.zFar = 400
        camera.camera!.wantsHDR = true
        camera.camera!.bloomIntensity = 0.9; camera.camera!.bloomThreshold = 1.4; camera.camera!.bloomBlurRadius = 6
        camera.camera!.vignettingIntensity = 0.6; camera.camera!.vignettingPower = 1.2
        root.addChildNode(camera)
        view.pointOfView = camera

        let plane = SCNPlane(width: 16, height: 34)                   // well past the view's edges at the wall's depth, angled camera included
        let m = SCNMaterial(); m.lightingModel = .physicallyBased
        m.diffuse.contents = UIColor(red: 0.11, green: 0.085, blue: 0.07, alpha: 1); m.roughness.contents = 0.95
        plane.materials = [m]
        wall.geometry = plane
        wall.position = SCNVector3(0, 0, -1.2)
        root.addChildNode(wall)

        let spot = SCNLight(); spot.type = .spot
        spot.color = UIColor(red: 1, green: 0.86, blue: 0.68, alpha: 1); spot.intensity = 1700
        spot.spotInnerAngle = 30; spot.spotOuterAngle = 95
        spot.castsShadow = true; spot.shadowMode = .forward; spot.shadowSampleCount = 16; spot.shadowRadius = 8
        spot.shadowColor = UIColor(white: 0, alpha: 0.7); spot.shadowMapSize = CGSize(width: 2048, height: 2048)
        spot.zNear = 0.5; spot.zFar = 40
        light.light = spot
        root.addChildNode(light)

        let fill = SCNNode(); fill.light = SCNLight(); fill.light!.type = .ambient
        fill.light!.color = UIColor(red: 0.5, green: 0.42, blue: 0.36, alpha: 1); fill.light!.intensity = 110
        root.addChildNode(fill)

        root.addChildNode(pieces)

        marble.geometry = SCNSphere(radius: CGFloat(Rules.radius / SceneMapping.unit))
        (marble.geometry as! SCNSphere).segmentCount = 48
        setSkin(Skins.classic)
        root.addChildNode(marble)
    }

    /// A warm gradient used as the environment the metal reflects: bright above, dark below.
    private static func environment() -> UIImage {
        let size = CGSize(width: 256, height: 128)
        return UIGraphicsImageRenderer(size: size).image { r in
            let colors = [UIColor(red: 1, green: 0.88, blue: 0.7, alpha: 1).cgColor, UIColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1).cgColor,
                          UIColor(red: 0.05, green: 0.04, blue: 0.04, alpha: 1).cgColor]
            let g = CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: [0, 0.45, 1])!
            r.cgContext.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        }
    }

    /// Classic is mirror chrome; other skins show their pattern with a glassy finish.
    func setSkin(_ s: Skin) {
        let m = SCNMaterial(); m.lightingModel = .physicallyBased
        if s.id == Skins.classic.id {
            m.diffuse.contents = UIColor(white: 0.95, alpha: 1); m.metalness.contents = 1; m.roughness.contents = 0.08
        } else {
            m.diffuse.contents = Skins.image(s, size: 256); m.metalness.contents = 0.15; m.roughness.contents = 0.18
        }
        marble.geometry?.materials = [m]
    }

    /// The chosen background painted on the wall, darkened; none: warm plaster.
    func setWall(_ image: UIImage?, tint: Double) {
        let m = wall.geometry!.firstMaterial!
        if let image {
            m.diffuse.contents = image
            m.multiply.contents = UIColor(white: CGFloat(max(0.2, 0.62 - tint * 0.5)), alpha: 1)   // darker than the 2D backdrop: the spot light adds back
        } else {
            m.diffuse.contents = UIColor(red: 0.11, green: 0.085, blue: 0.07, alpha: 1); m.multiply.contents = UIColor.white
        }
    }

    // MARK: pieces

    func rebuild(_ c: Course, beats: [Engine.BeatState], playing: Bool, cup: (x: Double, y: Double)?) {
        pieces.childNodes.forEach { $0.removeFromParentNode() }
        pads = c.pads
        pieceNodes = c.pads.enumerated().map { i, p in
            let n = Self.node(for: p)
            let beat = i < beats.count ? beats[i] : .unused
            if !playing, let mat = n.geometry?.firstMaterial {
                switch beat {
                case .on: mat.emission.contents = PadArt.beatGold; mat.emission.intensity = 0.32     // a warm hint; hits light up fully
                case .near: mat.emission.contents = PadArt.beatGold; mat.emission.intensity = 0.14
                case .off, .unused: break
                }
            }
            pieces.addChildNode(n)
            return n
        }
        pieces.addChildNode(Self.hopper(x: c.dropX, y: c.dropY))
        if let cup { pieces.addChildNode(Self.cup(x: cup.x, y: cup.y)) }
    }

    private static func brass(_ tint: UIColor) -> SCNMaterial {
        let m = SCNMaterial(); m.lightingModel = .physicallyBased
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        tint.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        m.diffuse.contents = UIColor(hue: h, saturation: s * 0.5, brightness: 0.62, alpha: 1)   // the note colour, softened toward brass
        m.metalness.contents = 0.75; m.roughness.contents = 0.3
        m.emission.contents = tint; m.emission.intensity = 0.06
        return m
    }

    static func node(for p: Pad) -> SCNNode {
        let tint = PadArt.color(p), depth = 0.2, t = Rules.thickness / SceneMapping.unit
        let node = SCNNode()
        switch p.kind {
        case .bar:
            let box = SCNBox(width: CGFloat(Notes.barLength(p.note) / SceneMapping.unit), height: CGFloat(t), length: CGFloat(depth), chamferRadius: CGFloat(t * 0.45))
            box.materials = [brass(tint)]
            node.geometry = box
            node.eulerAngles.z = Float(-p.angle)                       // engine angles turn clockwise on screen (y down)
            wires(on: node, halfLength: Notes.barLength(p.note) / SceneMapping.unit / 2 * 0.8, angle: p.angle)
        case .bumper:
            let r = Notes.bumperRadius(p.note) / SceneMapping.unit
            let peg = SCNCylinder(radius: CGFloat(r), height: CGFloat(depth)); peg.radialSegmentCount = 40
            peg.materials = [brass(tint)]
            node.geometry = peg
            node.eulerAngles.x = .pi / 2                               // the peg's round face looks at the camera
            let wire = thinWire(length: 2.6); wire.eulerAngles.x = -.pi / 2; wire.pivot = SCNMatrix4MakeTranslation(0, -1.3, 0)
            node.addChildNode(wire)                                    // hangs straight up from the peg's centre
        case .ramp:                                                    // the curve as an extruded rail, drawn around the pad's centre
            var local = p; local.x = Rules.width / 2; local.y = 0; local.angle = 0
            let path = UIBezierPath()
            for (k, q) in local.rampPoints().enumerated() {
                let v = SceneMapping.scene(x: q.x, y: q.y), pt = CGPoint(x: CGFloat(v.x), y: CGFloat(v.y))
                k == 0 ? path.move(to: pt) : path.addLine(to: pt)
            }
            let outline = UIBezierPath(cgPath: path.cgPath.copy(strokingWithWidth: CGFloat(t), lineCap: .round, lineJoin: .round, miterLimit: 4))
            let shape = SCNShape(path: outline, extrusionDepth: CGFloat(depth)); shape.chamferRadius = 0
            shape.materials = [brass(tint)]
            node.geometry = shape
            node.eulerAngles.z = Float(-p.angle)
            wires(on: node, halfLength: (p.length ?? Rules.rampLength) / SceneMapping.unit / 2 * 0.8, angle: p.angle)
        }
        node.position = SceneMapping.scene(x: p.x, y: p.y)
        node.castsShadow = true
        return node
    }

    /// Two thin wires from near the ends of a bar or ramp up out of the picture, like the video's hanging bars.
    private static func wires(on node: SCNNode, halfLength: Double, angle: Double) {
        for side in [-1.0, 1.0] {
            let w = thinWire(length: 2.6)
            // wires hang straight up in the room, so undo the piece's own tilt for them
            w.position = SCNVector3(Float(side * halfLength), 0, 0)
            w.eulerAngles.z = Float(angle)                               // cancels the piece's tilt: the wire points straight up
            w.pivot = SCNMatrix4MakeTranslation(0, -1.3, 0)
            node.addChildNode(w)
        }
    }

    private static func thinWire(length: CGFloat) -> SCNNode {
        let c = SCNCylinder(radius: 0.011, height: length); c.radialSegmentCount = 8     // a visible dark cord, like the video
        let m = SCNMaterial(); m.lightingModel = .physicallyBased; m.diffuse.contents = UIColor(white: 0.08, alpha: 1)
        m.metalness.contents = 0.7; m.roughness.contents = 0.35
        c.materials = [m]
        let n = SCNNode(geometry: c); n.castsShadow = true
        return n
    }

    private static func hopper(x: Double, y: Double) -> SCNNode {
        let cone = SCNCone(topRadius: 0.26, bottomRadius: 0.09, height: 0.22)
        let m = brass(UIColor(white: 0.9, alpha: 1)); m.emission.intensity = 0
        cone.materials = [m]
        let n = SCNNode(geometry: cone); n.position = SceneMapping.scene(x: x, y: y - 33)
        n.castsShadow = false                                         // once the camera (and light) follow the marble down, its shadow was thrown huge across the wall
        return n
    }

    private static func cup(x: Double, y: Double) -> SCNNode {
        let ring = SCNTorus(ringRadius: CGFloat(Challenge.cupRadius / SceneMapping.unit), pipeRadius: 0.025)
        let m = SCNMaterial(); m.lightingModel = .physicallyBased; m.diffuse.contents = PadArt.beatGold
        m.emission.contents = PadArt.beatGold; m.emission.intensity = 1.2; m.metalness.contents = 0.8
        ring.materials = [m]
        let n = SCNNode(geometry: ring); n.position = SceneMapping.scene(x: x, y: y); n.eulerAngles.x = .pi / 2
        n.runAction(.repeatForever(.sequence([.scale(to: 1.12, duration: 0.7), .scale(to: 1, duration: 0.7)])))
        return n
    }

    // MARK: every frame (called by the 2D layer)

    func update(camY: Double, viewSize: CGSize, playing: Bool, marbleAt p: (x: Double, y: Double), marbleVisible: Bool) {
        let goal = playing && !reduceMotion ? 1.0 : 0.0
        playBlend += (goal - playBlend) * 0.08                        // about 0.6 s to swing in or out
        let pose = SceneMapping.blend(SceneMapping.buildCamera(camY: camY, viewSize: viewSize),
                                      SceneMapping.playCamera(camY: camY, viewSize: viewSize), playBlend)
        SCNTransaction.begin(); SCNTransaction.disableActions = true
        camera.position = pose.position; camera.eulerAngles = pose.angles
        let c = pose.position
        light.position = SCNVector3(1.4, c.y + 6, 6)                   // high above and in front of the view, so shadows fall down-left and stay small
        light.look(at: SCNVector3(0, c.y - 0.5, -1.2))
        let lookY = SceneMapping.buildCamera(camY: camY, viewSize: viewSize).position.y
        wall.position = SCNVector3(0, lookY, -1.2)                   // centred on what the camera looks at, so the angled view never reaches its edge
        marble.position = SceneMapping.scene(x: p.x, y: p.y)
        marble.opacity = marbleVisible ? 1 : 0.6
        SCNTransaction.commit()
    }

    /// A hit: the piece glows brightly for a moment and sparks fly.
    func flash(pad i: Int, at h: Hit) {
        guard pieceNodes.indices.contains(i), let mat = pieceNodes[i].geometry?.firstMaterial else { return }
        let base = mat.emission.intensity
        pieceNodes[i].runAction(.customAction(duration: 0.45) { _, t in
            mat.emission.intensity = base + (3.2 - base) * max(0, 1 - t / 0.45)
        })
        let sparks = SCNParticleSystem()
        sparks.birthRate = 900; sparks.emissionDuration = 0.02; sparks.loops = false
        sparks.particleLifeSpan = 0.35; sparks.particleVelocity = 0.9; sparks.particleVelocityVariation = 0.5; sparks.spreadingAngle = 180
        sparks.particleSize = 0.006; sparks.particleColor = pads.indices.contains(i) ? PadArt.color(pads[i]) : PadArt.beatGold
        sparks.acceleration = SCNVector3(0, -4, 0); sparks.blendMode = .additive; sparks.isLightingEnabled = false
        let at = SceneMapping.scene(x: h.x, y: h.y, z: 0.1)
        scene.addParticleSystem(sparks, transform: SCNMatrix4MakeTranslation(at.x, at.y, at.z))
    }
}

/// SwiftUI wrapper for the 3D room.
struct Course3DView: UIViewRepresentable {
    let room: Course3D
    func makeUIView(context: Context) -> SCNView { room.view }
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
