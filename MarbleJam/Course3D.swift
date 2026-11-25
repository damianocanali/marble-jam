import SceneKit
import SwiftUI

/// The numbers that set the room's look, in one place so they are easy to tune on a device.
enum RoomLook {
    static let wall = UIColor(red: 0.6, green: 0.565, blue: 0.545, alpha: 1)       // warm light-grey plaster
    static let wallZ = -0.32                                                          // scene units behind the marble's plane: pieces stand 3 to 20 points off it on pegs
    static let keyLight = UIColor(red: 1, green: 0.95, blue: 0.88, alpha: 1), keyIntensity: CGFloat = 1150
    static let keyDirection = SCNVector3(0.45, 0.6, 1)                                // towards the light: high, right and in front, so shadows fall down-left
    static let ambient = UIColor(red: 0.62, green: 0.56, blue: 0.54, alpha: 1), ambientIntensity: CGFloat = 260
    static let pegDepth = 0.24                                                        // how thick the pieces are, front to back (scene units)
    /// Background blur (aimed at the marble), motion blur and grain while the show camera runs. Off: cheaper on old phones.
    static let cinematic = false
    static let fStop: CGFloat = 0.08                                                  // small, because the room is in metres: blurs the far wall a little
}

/// The 3D room behind the 2D layer: a light plaster wall, a soft key light with shadows, painted pieces standing off the wall on
/// pegs, wire rails and a glass marble. The 2D `RunScene` on top keeps drawing labels and guides and handles touches; it drives
/// this scene every frame. While a song plays, the camera swings from straight on to a close show camera following the marble.
final class Course3D {
    let scene = SCNScene()
    let view: SCNView

    private let camera = SCNNode(), light = SCNNode(), wall = SCNNode(), posters = SCNNode(), pieces = SCNNode()
    private let marble = SCNNode(), marbleCore = SCNNode()
    private var pieceNodes: [SCNNode] = []
    private var pads: [Pad] = []
    private var playBlend = 0.0                                   // 0 = straight-on building camera, 1 = show camera
    private var follow = (x: Rules.width / 2, y: 0.0)             // where the show camera looks (engine points), eased after the marble
    private var effectsOn = false
    var reduceMotion = false

    init() {
        view = SCNView(frame: .zero)
        view.scene = scene
        view.backgroundColor = RoomLook.wall
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.isPlaying = true                                     // keep rendering: the 2D layer moves things every frame
        view.isUserInteractionEnabled = false                     // touches go to the 2D layer on top
        buildRoom()
    }

    // MARK: room

    private func buildRoom() {
        let root = scene.rootNode
        scene.lightingEnvironment.contents = Self.environment()  // the room the paint, metal and glass reflect
        scene.lightingEnvironment.intensity = 1

        let cam = SCNCamera()
        cam.fieldOfView = SceneMapping.fieldOfView
        cam.zNear = 0.05; cam.zFar = 400
        cam.wantsHDR = true
        cam.bloomIntensity = 0.45; cam.bloomThreshold = 1.2; cam.bloomBlurRadius = 8      // only hit glows bloom, not the light wall
        cam.vignettingIntensity = 0.45; cam.vignettingPower = 1.1
        cam.saturation = 0.94; cam.contrast = 0.06                                         // slightly soft and warm, like a photo
        camera.camera = cam
        root.addChildNode(camera)
        view.pointOfView = camera

        let plane = SCNPlane(width: 16, height: 34)                   // well past the view's edges, the show camera included
        let m = SCNMaterial(); m.lightingModel = .physicallyBased
        m.diffuse.contents = Self.plaster()
        m.diffuse.wrapS = .repeat; m.diffuse.wrapT = .repeat
        m.diffuse.contentsTransform = SCNMatrix4MakeScale(8, 17, 1)   // one tile every 2 units; the wall moves in whole tiles (see update)
        m.roughness.contents = 0.92; m.metalness.contents = 0
        plane.materials = [m]
        wall.geometry = plane
        wall.castsShadow = false
        root.addChildNode(wall)
        root.addChildNode(posters)

        let key = SCNLight(); key.type = .directional
        key.color = RoomLook.keyLight; key.intensity = RoomLook.keyIntensity
        key.castsShadow = true; key.shadowMode = .forward; key.shadowSampleCount = 16; key.shadowRadius = 4
        key.shadowColor = UIColor(red: 0.12, green: 0.08, blue: 0.08, alpha: 0.55); key.shadowMapSize = CGSize(width: 2048, height: 2048)
        key.orthographicScale = 8; key.zNear = 1; key.zFar = 40
        light.light = key
        root.addChildNode(light)

        let fill = SCNNode(); fill.light = SCNLight(); fill.light!.type = .ambient
        fill.light!.color = RoomLook.ambient; fill.light!.intensity = RoomLook.ambientIntensity
        root.addChildNode(fill)

        root.addChildNode(pieces)

        let R = CGFloat(Rules.radius / SceneMapping.unit)               // the same size as the engine's marble, so it touches what it hits
        let body = SCNSphere(radius: R * 0.995); body.segmentCount = 48; body.materials = [Self.glassBody()]
        let shell = SCNSphere(radius: R); shell.segmentCount = 64; shell.materials = [Self.glassShine()]
        let bodyNode = SCNNode(geometry: body), shellNode = SCNNode(geometry: shell)
        bodyNode.renderingOrder = 10; shellNode.renderingOrder = 11; shellNode.castsShadow = false
        marble.addChildNode(marbleCore); marble.addChildNode(bodyNode); marble.addChildNode(shellNode)
        setSkin(Skins.classic)
        root.addChildNode(marble)
    }

    /// The room as the shiny things see it: a bright ceiling with a soft window, light walls, a darker floor.
    private static func environment() -> UIImage {
        let size = CGSize(width: 512, height: 256)
        return UIGraphicsImageRenderer(size: size).image { r in
            let c = r.cgContext
            let colors = [UIColor(red: 1, green: 0.97, blue: 0.92, alpha: 1).cgColor, UIColor(red: 0.66, green: 0.61, blue: 0.58, alpha: 1).cgColor,
                          UIColor(red: 0.24, green: 0.21, blue: 0.2, alpha: 1).cgColor]
            let g = CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: [0, 0.5, 1])!
            c.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            c.setFillColor(UIColor(white: 1, alpha: 0.9).cgColor)                                    // the window: the long highlight on glass and paint
            c.fill(CGRect(x: size.width * 0.58, y: size.height * 0.16, width: size.width * 0.14, height: size.height * 0.2))
        }
    }

    /// One tile of plaster: the wall colour with fine light and dark specks and a few soft blotches. Tiles seamlessly.
    private static func plaster() -> UIImage {
        let n: CGFloat = 256
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: n, height: n), format: format).image { r in
            let c = r.cgContext
            c.setFillColor(RoomLook.wall.cgColor); c.fill(CGRect(x: 0, y: 0, width: n, height: n))
            func dot(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ color: UIColor) {
                c.setFillColor(color.cgColor)
                for dx in [-n, 0, n] { for dy in [-n, 0, n] { c.fillEllipse(in: CGRect(x: x + dx - s, y: y + dy - s, width: 2 * s, height: 2 * s)) } }
            }
            for _ in 0..<40 {
                dot(.random(in: 0..<n), .random(in: 0..<n), .random(in: 18...60), UIColor(white: Bool.random() ? 1 : 0, alpha: 0.018))
            }
            for _ in 0..<2600 {
                dot(.random(in: 0..<n), .random(in: 0..<n), .random(in: 0.5...1.8), UIColor(white: Bool.random() ? 1 : 0, alpha: .random(in: 0.025...0.07)))
            }
        }
    }

    // MARK: marble

    /// The marble is clear glass; the skin is what's inside it. Classic: an ice-blue cat's eye. Others: their pattern as the core.
    func setSkin(_ s: Skin) {
        marbleCore.childNodes.forEach { $0.removeFromParentNode() }
        let R = CGFloat(Rules.radius / SceneMapping.unit)
        if s.id == Skins.classic.id {
            marbleCore.addChildNode(Self.catsEye(colors: [UIColor(red: 0.42, green: 0.7, blue: 1, alpha: 1), UIColor(red: 0.85, green: 0.95, blue: 1, alpha: 1)], radius: R))
        } else {
            let core = SCNSphere(radius: R * 0.86); core.segmentCount = 48
            let m = SCNMaterial(); m.lightingModel = .physicallyBased
            m.diffuse.contents = Self.skinTexture(s); m.roughness.contents = 0.35; m.metalness.contents = 0
            core.materials = [m]
            marbleCore.addChildNode(SCNNode(geometry: core))
        }
    }

    /// The glass's highlights and rim, added on top of whatever is behind it (it never darkens).
    private static func glassShine() -> SCNMaterial {
        let m = SCNMaterial(); m.lightingModel = .phong
        m.diffuse.contents = UIColor.black; m.ambient.contents = UIColor.black
        m.specular.contents = UIColor.white; m.shininess = 90
        m.reflective.contents = environment(); m.reflective.intensity = 0.9
        m.fresnelExponent = 1.8                                       // reflections strongest at the edge, like real glass
        m.blendMode = .add; m.writesToDepthBuffer = false
        return m
    }

    /// The glass itself: a faint, cool tint you can see through.
    private static func glassBody() -> SCNMaterial {
        let m = SCNMaterial(); m.lightingModel = .physicallyBased
        m.diffuse.contents = UIColor(red: 0.88, green: 0.94, blue: 1, alpha: 1)
        m.roughness.contents = 0.05; m.metalness.contents = 0
        m.transparency = 0.16; m.transparencyMode = .dualLayer
        return m
    }

    /// Four twisted vanes crossing in the middle: the classic cat's-eye marble.
    private static func catsEye(colors: [UIColor], radius R: CGFloat) -> SCNNode {
        let h = R * 0.8, w = R * 0.42
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: -h))
        path.addCurve(to: CGPoint(x: 0, y: h), controlPoint1: CGPoint(x: w * 1.6, y: -h * 0.35), controlPoint2: CGPoint(x: -w * 0.5, y: h * 0.55))
        path.addCurve(to: CGPoint(x: 0, y: -h), controlPoint1: CGPoint(x: -w * 1.6, y: h * 0.35), controlPoint2: CGPoint(x: w * 0.5, y: -h * 0.55))
        path.close()
        path.flatness = R * 0.01                                      // the default is for points; the marble is a tenth of a unit
        let node = SCNNode()
        for k in 0..<4 {
            let shape = SCNShape(path: path, extrusionDepth: R * 0.06)
            let m = SCNMaterial(); m.lightingModel = .physicallyBased
            let color = colors[k % colors.count]
            m.diffuse.contents = color; m.roughness.contents = 0.4; m.emission.contents = color; m.emission.intensity = 0.25
            shape.materials = [m]
            let vane = SCNNode(geometry: shape); vane.eulerAngles.y = Float(k) * .pi / 4
            node.addChildNode(vane)
        }
        return node
    }

    /// The skin's drawing filling a square (a little enlarged so its round edge leaves no corners), for wrapping round the core.
    private static func skinTexture(_ s: Skin) -> UIImage {
        let n: CGFloat = 256
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: n, height: n), format: format).image { r in
            let c = r.cgContext
            c.setFillColor(UIColor.white.cgColor); c.fill(CGRect(x: 0, y: 0, width: n, height: n))
            c.translateBy(x: -n * 0.21, y: -n * 0.21)
            s.draw(c, n * 1.42)
        }
    }

    // MARK: wall

    /// The chosen background, hung down the wall as framed pictures (left, right, left...). None: bare plaster.
    func setWall(_ image: UIImage?, tint: Double) {
        posters.childNodes.forEach { $0.removeFromParentNode() }
        guard let image, image.size.width > 0, image.size.height > 0 else { return }
        let w = 2.3, h = min(5.2, w * Double(image.size.height / image.size.width))
        let picture = SCNMaterial(); picture.lightingModel = .physicallyBased
        picture.diffuse.contents = image; picture.roughness.contents = 0.55
        picture.multiply.contents = UIColor(white: CGFloat(max(0.6, 1 - tint * 0.3)), alpha: 1)
        let frameMat = SCNMaterial(); frameMat.lightingModel = .physicallyBased
        frameMat.diffuse.contents = UIColor(red: 0.13, green: 0.11, blue: 0.1, alpha: 1); frameMat.roughness.contents = 0.45
        let frame = SCNBox(width: CGFloat(w + 0.16), height: CGFloat(h + 0.16), length: 0.05, chamferRadius: 0.012)
        frame.materials = [frameMat]
        let plane = SCNPlane(width: CGFloat(w), height: CGFloat(h)); plane.materials = [picture]
        for k in 0..<12 {                                             // enough for long songs; off-screen ones cost nothing
            let n = SCNNode(geometry: frame)
            let pic = SCNNode(geometry: plane); pic.position = SCNVector3(0, 0, 0.026)
            n.addChildNode(pic)
            n.position = SceneMapping.scene(x: k % 2 == 0 ? 135 : 585, y: 520 + Double(k) * 1150, z: RoomLook.wallZ + 0.03)
            posters.addChildNode(n)
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

    /// Glossy painted wood in the note's colour, under a clear coat. Each piece gets its own, so it can glow on its own.
    private static func paint(_ tint: UIColor) -> SCNMaterial {
        let m = SCNMaterial(); m.lightingModel = .physicallyBased
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        tint.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        m.diffuse.contents = UIColor(hue: h, saturation: s * 0.95, brightness: 0.86, alpha: 1)
        m.metalness.contents = 0; m.roughness.contents = 0.38
        m.clearCoat.contents = 0.7; m.clearCoatRoughness.contents = 0.12
        m.emission.contents = tint; m.emission.intensity = 0
        return m
    }

    private static let darkMetal: SCNMaterial = {
        let m = SCNMaterial(); m.lightingModel = .physicallyBased
        m.diffuse.contents = UIColor(red: 0.16, green: 0.15, blue: 0.15, alpha: 1); m.metalness.contents = 0.85; m.roughness.contents = 0.32
        return m
    }()

    private static let rubber: SCNMaterial = {
        let m = SCNMaterial(); m.lightingModel = .physicallyBased
        m.diffuse.contents = UIColor(white: 0.07, alpha: 1); m.metalness.contents = 0; m.roughness.contents = 0.75
        return m
    }()

    /// A dark metal peg from `z` (scene units, on the piece's back) to the wall, at the piece-local point (x, y).
    private static func peg(x: Float = 0, y: Float = 0, from z: Double, radius: CGFloat = 0.028) -> SCNNode {
        let length = max(0.01, z - RoomLook.wallZ)
        let rod = SCNCylinder(radius: radius, height: CGFloat(length)); rod.radialSegmentCount = 12
        rod.materials = [darkMetal]
        let n = SCNNode(geometry: rod)
        n.eulerAngles.x = .pi / 2                                     // the cylinder's axis along z, into the wall
        n.position = SCNVector3(x, y, Float(z - length / 2))
        return n
    }

    /// A screw head on a front face (piece-local x, y; z is the face).
    private static func screw(x: Float, y: Float = 0, z: Double) -> SCNNode {
        let head = SCNCylinder(radius: 0.022, height: 0.012); head.radialSegmentCount = 16
        head.materials = [darkMetal]
        let n = SCNNode(geometry: head)
        n.eulerAngles.x = .pi / 2
        n.position = SCNVector3(x, y, Float(z + 0.004))
        return n
    }

    static func node(for p: Pad) -> SCNNode {
        let tint = PadArt.color(p), depth = RoomLook.pegDepth, t = Rules.thickness / SceneMapping.unit
        let node = SCNNode()
        switch p.kind {
        case .bar:                                                     // a painted block on one peg, two screws on its face
            let L = Notes.barLength(p.note) / SceneMapping.unit
            let box = SCNBox(width: CGFloat(L), height: CGFloat(t), length: CGFloat(depth), chamferRadius: CGFloat(t * 0.3))
            box.chamferSegmentCount = 4
            box.materials = [paint(tint)]
            node.geometry = box
            node.addChildNode(peg(from: -depth / 2))
            for sx in [-0.3, 0.3] { node.addChildNode(screw(x: Float(L * sx), z: depth / 2)) }
            node.eulerAngles.z = Float(-p.angle)                       // engine angles turn clockwise on screen (y down)
        case .bumper:                                                  // a painted knob with a rubber ring round its rim
            let r = Notes.bumperRadius(p.note) / SceneMapping.unit, tyre = 0.028
            let knob = SCNCylinder(radius: CGFloat(r - tyre * 0.7), height: CGFloat(depth)); knob.radialSegmentCount = 48
            knob.materials = [paint(tint)]
            node.geometry = knob
            let ring = SCNTorus(ringRadius: CGFloat(r - tyre), pipeRadius: CGFloat(tyre)); ring.ringSegmentCount = 64; ring.pipeSegmentCount = 12
            ring.materials = [rubber]
            node.addChildNode(SCNNode(geometry: ring))                 // the torus already lies round the cylinder's axis
            for part in [peg(from: -depth / 2, radius: 0.04), screw(x: 0, z: depth / 2)] {
                part.eulerAngles.x = 0                                 // the knob is turned so its local y points at the camera:
                part.position = SCNVector3(0, part.position.z, 0)      // a part's depth (z) goes along that y instead
                node.addChildNode(part)
            }
            node.eulerAngles.x = .pi / 2                               // the knob's round face looks at the camera
        case .ramp:
            let track = rails(for: p, tint: tint)
            node.geometry = track.rails
            track.parts.forEach { node.addChildNode($0) }
        }
        node.position = SceneMapping.scene(x: p.x, y: p.y)
        node.castsShadow = true
        return node
    }

    /// A ramp as a wire track: two painted rails the marble rolls on, a dark spine under them, ball ends and pegs to the wall.
    /// The rails sit where the engine's marble touches the curve: its centre rides `radius + thickness / 2` above the centre line.
    private static func rails(for p: Pad, tint: UIColor) -> (rails: SCNGeometry, parts: [SCNNode]) {
        let pts = p.rampPoints(segments: 32), up = (x: sin(p.angle), y: -cos(p.angle))   // the ramp's top side (engine y is down)
        let railR = 3.2, spread = 8.0                                                    // engine points: rail radius, rail distance from the middle
        let lift = Rules.radius + Rules.thickness / 2 - ((Rules.radius + railR) * (Rules.radius + railR) - spread * spread).squareRoot()
        let origin = SceneMapping.scene(x: p.x, y: p.y)
        func line(_ off: Double, z: Double) -> [SCNVector3] {
            pts.indices.map { i -> SCNVector3 in
                let a = pts[max(0, i - 1)], b = pts[min(pts.count - 1, i + 1)]
                var nx = -(b.y - a.y), ny = b.x - a.x
                let l = max(1e-9, (nx * nx + ny * ny).squareRoot()); nx /= l; ny /= l
                if nx * up.x + ny * up.y < 0 { nx = -nx; ny = -ny }                         // always the top side
                let v = SceneMapping.scene(x: pts[i].x + nx * off, y: pts[i].y + ny * off)
                return SCNVector3(v.x - origin.x, v.y - origin.y, Float(z))
            }
        }
        let u = SceneMapping.unit, front = line(lift, z: spread / u), back = line(lift, z: -spread / u), spine = line(-3, z: 0)
        let mat = paint(tint)
        let geo = tube([front, back], radius: Float(railR / u)); geo.materials = [mat]     // the same material glows on a hit
        var parts: [SCNNode] = []
        for end in [front.first!, front.last!, back.first!, back.last!] {                   // ball ends, painted like the rails
            let ball = SCNSphere(radius: CGFloat(railR / u * 1.5)); ball.segmentCount = 16; ball.materials = [mat]
            let b = SCNNode(geometry: ball); b.position = end
            parts.append(b)
        }
        let spineGeo = tube([spine], radius: Float(2.2 / u)); spineGeo.materials = [darkMetal]
        parts.append(SCNNode(geometry: spineGeo))
        for k in [pts.count / 6, pts.count / 2, pts.count - 1 - pts.count / 6] {          // three brackets holding the wires, each on a peg
            let s = spine[k], f = front[k], dx = f.x - s.x, dy = f.y - s.y
            let plate = SCNBox(width: 0.012, height: CGFloat((dx * dx + dy * dy).squareRoot()), length: CGFloat(2 * spread / u), chamferRadius: 0.003)
            plate.materials = [darkMetal]
            let bracket = SCNNode(geometry: plate)
            bracket.position = SCNVector3(s.x + dx / 2, s.y + dy / 2, 0); bracket.eulerAngles.z = atan2(dy, dx) - .pi / 2
            parts.append(bracket)
            parts.append(peg(x: s.x, y: s.y, from: 0, radius: 0.022))
        }
        return (geo, parts)
    }

    /// Round tubes along curves (scene units, each curve in a plane of constant z), as one geometry.
    static func tube(_ curves: [[SCNVector3]], radius: Float, sides: Int = 10) -> SCNGeometry {
        var verts: [SCNVector3] = [], norms: [SCNVector3] = [], idx: [Int32] = []
        for pts in curves where pts.count > 1 {
            let start = Int32(verts.count), S = Int32(sides)
            for i in pts.indices {
                let a = pts[max(0, i - 1)], b = pts[min(pts.count - 1, i + 1)]
                var tx = b.x - a.x, ty = b.y - a.y
                let l = max(1e-6, (tx * tx + ty * ty).squareRoot()); tx /= l; ty /= l
                for k in 0..<sides {                                  // a ring round the tangent: across the curve and along z
                    let th = Float(k) / Float(sides) * 2 * .pi, c = cos(th), s = sin(th)
                    let n = SCNVector3(-ty * c, tx * c, s)
                    norms.append(n)
                    verts.append(SCNVector3(pts[i].x + n.x * radius, pts[i].y + n.y * radius, pts[i].z + n.z * radius))
                }
            }
            for i in 0..<Int32(pts.count - 1) {
                for k in 0..<S {
                    let a = start + i * S + k, b = start + i * S + (k + 1) % S, c = a + S, d = b + S
                    idx += [a, b, c, b, d, c]                         // counter-clockwise seen from outside
                }
            }
        }
        return SCNGeometry(sources: [SCNGeometrySource(vertices: verts), SCNGeometrySource(normals: norms)],
                           elements: [SCNGeometryElement(indices: idx, primitiveType: .triangles)])
    }

    private static func hopper(x: Double, y: Double) -> SCNNode {
        let cone = SCNCone(topRadius: 0.26, bottomRadius: 0.09, height: 0.22); cone.radialSegmentCount = 40
        cone.materials = [darkMetal]
        let n = SCNNode(geometry: cone); n.position = SceneMapping.scene(x: x, y: y - 33)
        n.addChildNode(peg(from: 0, radius: 0.03))                    // from inside the funnel back to the wall
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

    /// `spin`: the engine's turn of the marble (clockwise on screen, radians), so it rolls on what it touches.
    func update(camY: Double, viewSize: CGSize, playing: Bool, marbleAt p: (x: Double, y: Double), spin: Double = 0, marbleVisible: Bool) {
        let goal = playing && !reduceMotion ? 1.0 : 0.0
        playBlend += (goal - playBlend) * 0.04                        // about 1.2 s to swing in or out, gently

        if playing {                                                  // the show camera drifts after the marble: calm, never jumping at bounces
            let goalX = Rules.width / 2 + (p.x - Rules.width / 2) * 0.5      // leans toward the marble, stays mostly on the course
            follow.x += (goalX - follow.x) * 0.04; follow.y += (p.y + 60 - follow.y) * 0.07
            let viewHeight = SceneMapping.showWidth * Double(viewSize.height) / max(1, Double(viewSize.width)), keep = viewHeight * 0.28
            follow.y = min(p.y + keep, max(p.y - keep, follow.y))     // a fast fall still stays well inside the view
        } else {
            if playBlend < 0.02 { follow = (p.x, p.y + 40) }          // waits at the hopper, once the camera is back
        }

        let build = SceneMapping.buildCamera(camY: camY, viewSize: viewSize)
        let pose = SceneMapping.blend(build, SceneMapping.showCamera(target: follow, viewSize: viewSize), playBlend)
        SCNTransaction.begin(); SCNTransaction.disableActions = true
        camera.position = pose.position; camera.eulerAngles = pose.angles
        camera.camera!.fieldOfView = pose.fov
        let lookY = build.position.y, show = SceneMapping.scene(x: follow.x, y: follow.y)
        let k = Float(playBlend), target = SCNVector3(show.x * k, lookY + (show.y - lookY) * k, 0)
        let d = RoomLook.keyDirection, dl = (d.x * d.x + d.y * d.y + d.z * d.z).squareRoot() / 15
        light.position = SCNVector3(target.x + d.x / dl, target.y + d.y / dl, target.z + d.z / dl)
        light.look(at: target)
        light.light!.orthographicScale = CGFloat(8.5 - 4 * playBlend)  // the shadow map covers what the camera sees, sharper up close
        wall.position = SCNVector3(0, (lookY / 2).rounded() * 2, Float(RoomLook.wallZ))   // centred on the view, moved in whole plaster tiles
        marble.position = SceneMapping.scene(x: p.x, y: p.y)
        marble.opacity = marbleVisible ? 1 : 0.6
        marbleCore.eulerAngles.z = Float(-spin)                       // scene z points at the camera: clockwise is negative
        setEffects(RoomLook.cinematic && playBlend > 0.5, eye: pose.position, target: show)
        SCNTransaction.commit()
    }

    /// Show-camera extras: the wall ahead blurs a little (focused on the marble), motion blur and a touch of grain.
    private func setEffects(_ on: Bool, eye: SCNVector3, target: SCNVector3) {
        let cam = camera.camera!
        if on {
            let dx = eye.x - target.x, dy = eye.y - target.y, dz = eye.z - target.z
            cam.focusDistance = CGFloat((dx * dx + dy * dy + dz * dz).squareRoot())
        }
        guard on != effectsOn else { return }
        effectsOn = on
        cam.wantsDepthOfField = on; cam.fStop = RoomLook.fStop
        cam.motionBlurIntensity = on ? 0.3 : 0
        cam.grainIntensity = on ? 0.05 : 0
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
