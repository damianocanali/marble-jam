import XCTest
@testable import MarbleJam

final class AttractTests: XCTestCase {
    func testTallCourseFitsTheHeight() {
        let f = CourseFit(top: 0, bottom: 2000, size: CGSize(width: 400, height: 800), margin: 40)
        XCTAssertEqual(f.scale, 720.0 / 2000, accuracy: 1e-9)                     // (800 - 2*40) / 2000
        XCTAssertEqual(f.screenY(0), 40, accuracy: 1e-9)
        XCTAssertEqual(f.screenY(2000), 760, accuracy: 1e-9)
        XCTAssertEqual(f.screenX(Rules.width / 2), 200, accuracy: 1e-9)          // centred
    }

    func testShortCourseIsLimitedByTheWidth() {
        let f = CourseFit(top: 0, bottom: 300, size: CGSize(width: 360, height: 800), margin: 40)
        XCTAssertEqual(f.scale, 360 / Rules.width, accuracy: 1e-9)
        XCTAssertEqual(f.screenY(150), 400, accuracy: 1e-9)                       // centred vertically
    }
}
