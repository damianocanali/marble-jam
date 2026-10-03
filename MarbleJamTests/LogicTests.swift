import XCTest
@testable import MarbleJam

final class LogicTests: XCTestCase {
    func testDemoSongHasNotes() {
        XCTAssertFalse(Engine.simulate(Engine.demo()).hits.isEmpty)
    }
}
