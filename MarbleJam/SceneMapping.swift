import SceneKit

/// Where engine points sit in the 3D room, and where the camera goes. 1 scene unit = 100 engine points; the marble runs in
/// the plane z = 0, engine y grows downward while scene y grows upward.
enum SceneMapping {
    static let unit = 100.0
    static let fieldOfView: CGFloat = 20                     // vertical, degrees: narrow, so the straight-on view looks nearly flat

    static func scene(x: Double, y: Double, z: Double = 0) -> SCNVector3 {
        SCNVector3(Float((x - Rules.width / 2) / unit), Float(-y / unit), Float(z))
    }

    static func engine(_ v: SCNVector3) -> (x: Double, y: Double) { (Double(v.x) * unit + Rules.width / 2, -Double(v.y) * unit) }

    struct Pose { var position: SCNVector3; var angles: SCNVector3 }

    /// Straight-on camera showing the same strip as the 2D view: 720 points across, engine y `camY` at the top edge.
    static func buildCamera(camY: Double, viewSize: CGSize) -> Pose {
        let (center, distance) = frame(camY: camY, viewSize: viewSize)
        return Pose(position: SCNVector3(0, Float(center), Float(distance)), angles: SCNVector3Zero)
    }

    /// The show camera: the same spot seen from a little above and to the side, a step further back.
    static func playCamera(camY: Double, viewSize: CGSize, pitch: Double = -0.16, yaw: Double = 0.07) -> Pose {
        let (center, distance) = frame(camY: camY, viewSize: viewSize), d = distance * 1.12     // a step back, so the whole width stays in view
        let offset = (x: sin(yaw) * cos(pitch), y: -sin(pitch), z: cos(yaw) * cos(pitch))
        return Pose(position: SCNVector3(Float(d * offset.x), Float(center + d * offset.y), Float(d * offset.z)),
                    angles: SCNVector3(Float(pitch), Float(yaw), 0))
    }

    static func blend(_ a: Pose, _ b: Pose, _ t: Double) -> Pose {
        func mix(_ u: SCNVector3, _ v: SCNVector3) -> SCNVector3 {
            let k = Float(t)
            return SCNVector3(u.x + (v.x - u.x) * k, u.y + (v.y - u.y) * k, u.z + (v.z - u.z) * k)
        }
        return Pose(position: mix(a.position, b.position), angles: mix(a.angles, b.angles))
    }

    /// Scene y of the strip's centre, and the camera distance at which it exactly fills the view's height.
    private static func frame(camY: Double, viewSize: CGSize) -> (center: Double, distance: Double) {
        let base = max(0.01, Double(viewSize.width) / Rules.width), engineHeight = Double(viewSize.height) / base
        let half = engineHeight / unit / 2
        return (-(camY + engineHeight / 2) / unit, half / tan(Double(fieldOfView) / 2 * .pi / 180))
    }
}
