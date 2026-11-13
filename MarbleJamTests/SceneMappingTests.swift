import SceneKit
import XCTest
@testable import MarbleJam

final class SceneMappingTests: XCTestCase {
    func testEngineToSceneAndBack() {
        let p = SceneMapping.scene(x: 360, y: 250)
        XCTAssertEqual(p.x, 0, accuracy: 1e-6); XCTAssertEqual(p.y, -2.5, accuracy: 1e-6); XCTAssertEqual(p.z, 0)
        let q = SceneMapping.scene(x: 720, y: 0)
        XCTAssertEqual(q.x, 3.6, accuracy: 1e-6)
        let back = SceneMapping.engine(SCNVector3(-1.2, -7.5, 0))
        XCTAssertEqual(back.x, 240, accuracy: 1e-4); XCTAssertEqual(back.y, 750, accuracy: 1e-4)
    }

    /// The straight-on building camera must show exactly the same strip of the course as the 2D view on top,
    /// so the 3D pieces sit under their labels: 720 points across, camY at the top edge.
    func testBuildCameraShowsTheSameStripAsTheTwoDView() {
        let size = CGSize(width: 402, height: 874), camY = 300.0
        let pose = SceneMapping.buildCamera(camY: camY, viewSize: size)
        let view = SCNView(frame: CGRect(origin: .zero, size: size))
        let scene = SCNScene(); view.scene = scene
        let cam = SCNNode(); cam.camera = SCNCamera(); cam.camera!.fieldOfView = SceneMapping.fieldOfView
        cam.camera!.zNear = 0.01; cam.camera!.zFar = 500
        cam.position = pose.position; cam.eulerAngles = pose.angles
        scene.rootNode.addChildNode(cam); view.pointOfView = cam
        let base = Double(size.width) / Rules.width                       // the 2D view's scale: points per engine point
        for (x, y) in [(0.0, camY), (720, camY), (360, camY + 400), (100, camY + 800)] {
            let s = view.projectPoint(SceneMapping.scene(x: x, y: y))
            XCTAssertEqual(Double(s.x), x * base, accuracy: 0.5, "x for \(x),\(y)")
            XCTAssertEqual(Double(s.y), (y - camY) * base, accuracy: 0.5, "y for \(x),\(y)")
        }
    }

    func testShowCameraLooksFromAnAngleAndBlendsFromTheBuildCamera() {
        let size = CGSize(width: 402, height: 874)
        let build = SceneMapping.buildCamera(camY: 500, viewSize: size), show = SceneMapping.showCamera(target: (300, 900), viewSize: size)
        XCTAssertLessThan(show.angles.x, 0, "looks down"); XCTAssertGreaterThan(show.angles.y, 0, "from the right")
        XCTAssertEqual(show.fov, SceneMapping.showFieldOfView); XCTAssertEqual(build.fov, SceneMapping.fieldOfView)
        let mid = SceneMapping.blend(build, show, 0.5)
        XCTAssertEqual(mid.angles.x, show.angles.x / 2, accuracy: 1e-5)
        XCTAssertEqual(mid.fov, (build.fov + show.fov) / 2, accuracy: 1e-5)
        XCTAssertEqual(SceneMapping.blend(build, show, 0).position.y, build.position.y, accuracy: 1e-5)
    }

    private func project(_ pose: SceneMapping.Pose, _ size: CGSize, _ points: [(x: Double, y: Double)]) -> [CGPoint] {
        let view = SCNView(frame: CGRect(origin: .zero, size: size)), scene = SCNScene(); view.scene = scene
        let cam = SCNNode(); cam.camera = SCNCamera(); cam.camera!.fieldOfView = pose.fov; cam.camera!.zNear = 0.01; cam.camera!.zFar = 500
        cam.position = pose.position; cam.eulerAngles = pose.angles
        scene.rootNode.addChildNode(cam); view.pointOfView = cam
        return points.map { let s = view.projectPoint(SceneMapping.scene(x: $0.x, y: $0.y)); return CGPoint(x: CGFloat(s.x), y: CGFloat(s.y)) }
    }

    /// The show camera puts what it follows in the middle of the screen.
    func testShowCameraCentresItsTarget() {
        let size = CGSize(width: 402, height: 874)
        for t in [(x: 360.0, y: 600.0), (x: 120, y: 2400)] {
            let s = project(SceneMapping.showCamera(target: t, viewSize: size), size, [t])[0]
            XCTAssertEqual(Double(s.x), 201, accuracy: 1, "x for \(t)"); XCTAssertEqual(Double(s.y), 437, accuracy: 1, "y for \(t)")
        }
    }

    /// Up close: about `showWidth` points across at the target, so the marble looks about twice as big as while building.
    func testShowCameraIsCloseUp() {
        let size = CGSize(width: 402, height: 874), t = (x: 360.0, y: 1000.0), half = SceneMapping.showWidth / 2
        let s = project(SceneMapping.showCamera(target: t, viewSize: size), size, [(t.x - half, t.y), (t.x + half, t.y)])
        let across = Double(s[1].x - s[0].x)
        XCTAssertEqual(across, Double(size.width), accuracy: Double(size.width) * 0.15)
        let marble = across / SceneMapping.showWidth * 2 * Rules.radius, building = Double(size.width) / Rules.width * 2 * Rules.radius
        XCTAssertGreaterThan(marble / building, 1.8)
    }
}
