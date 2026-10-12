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

    func testPlayCameraLooksAtTheSameSpotFromAnAngle() {
        let size = CGSize(width: 402, height: 874)
        let build = SceneMapping.buildCamera(camY: 500, viewSize: size), play = SceneMapping.playCamera(camY: 500, viewSize: size)
        XCTAssertNotEqual(play.angles.x, 0); XCTAssertNotEqual(play.angles.y, 0)
        let mid = SceneMapping.blend(build, play, 0.5)
        XCTAssertEqual(mid.angles.x, play.angles.x / 2, accuracy: 1e-5)
        XCTAssertEqual(SceneMapping.blend(build, play, 0).position.y, build.position.y, accuracy: 1e-5)
    }

    /// While playing, the angled camera must still show the whole width of the course at the marble's height.
    func testPlayCameraShowsTheWholeWidth() {
        let size = CGSize(width: 402, height: 874), camY = 600.0
        let pose = SceneMapping.playCamera(camY: camY, viewSize: size)
        let view = SCNView(frame: CGRect(origin: .zero, size: size)), scene = SCNScene(); view.scene = scene
        let cam = SCNNode(); cam.camera = SCNCamera(); cam.camera!.fieldOfView = SceneMapping.fieldOfView; cam.camera!.zFar = 500
        cam.position = pose.position; cam.eulerAngles = pose.angles
        scene.rootNode.addChildNode(cam); view.pointOfView = cam
        let base = Double(size.width) / Rules.width, mid = camY + Double(size.height) / base * 0.45
        for x in [20.0, 700] {
            let s = view.projectPoint(SceneMapping.scene(x: x, y: mid))
            XCTAssertTrue((0...Double(size.width)).contains(Double(s.x)), "x \(x) lands at \(s.x)")
        }
    }
}
