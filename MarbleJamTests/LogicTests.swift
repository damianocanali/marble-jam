import XCTest
@testable import MarbleJam

final class LogicTests: XCTestCase {
    func testDemoSongHasNotes() {
        XCTAssertFalse(Engine.simulate(Engine.demo()).hits.isEmpty)
    }

    func testClampPad() {
        XCTAssertEqual(Rules.clampPad(x: -50, y: 10).x, 20)
        XCTAssertEqual(Rules.clampPad(x: -50, y: 10).y, 40)
        XCTAssertEqual(Rules.clampPad(x: 9999, y: 500).x, Rules.width - 20)
        XCTAssertEqual(Rules.clampPad(x: 300, y: 500).y, 500)
    }

    func testClampAngle() {
        XCTAssertEqual(Rules.clampAngle(2), 1.4)
        XCTAssertEqual(Rules.clampAngle(-2), -1.4)
        XCTAssertEqual(Rules.clampAngle(0.3), 0.3)
    }

    func testBarAngleFoldsDirection() {
        XCTAssertEqual(Rules.barAngle(dx: 1, dy: 1), .pi / 4, accuracy: 1e-9)
        XCTAssertEqual(Rules.barAngle(dx: -1, dy: -1), .pi / 4, accuracy: 1e-9)   // opposite end, same tilt
        XCTAssertEqual(Rules.barAngle(dx: -1, dy: 0), 0, accuracy: 1e-9)
        XCTAssertEqual(Rules.barAngle(dx: 0, dy: 1), 1.4, accuracy: 1e-9)           // straight down clamps
    }

    func testStarTiers() {
        XCTAssertEqual(Celebration.stars(onBeat: 0, total: 0), 1)
        XCTAssertEqual(Celebration.stars(onBeat: 0, total: 10), 1)
        XCTAssertEqual(Celebration.stars(onBeat: 59, total: 100), 1)
        XCTAssertEqual(Celebration.stars(onBeat: 60, total: 100), 2)
        XCTAssertEqual(Celebration.stars(onBeat: 89, total: 100), 2)
        XCTAssertEqual(Celebration.stars(onBeat: 90, total: 100), 3)
        XCTAssertEqual(Celebration.stars(onBeat: 10, total: 10), 3)
    }

    func testHeadlineComesFromTierPool() {
        for (on, tier) in [(10, 3), (7, 2), (1, 1)] {
            for _ in 0..<20 {
                let c = Celebration.make(onBeat: on, total: 10)
                XCTAssertEqual(c.stars, tier)
                XCTAssertTrue(Celebration.headlines[tier]!.contains(c.headline))
                XCTAssertEqual(c.notes, 10); XCTAssertEqual(c.onBeat, on)
            }
        }
    }

    func testPickerChoosesHeadline() {
        XCTAssertEqual(Celebration.make(onBeat: 10, total: 10) { $0.last! }.headline, "Superstar!")
    }
}
