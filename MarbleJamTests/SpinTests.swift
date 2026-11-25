import XCTest
@testable import MarbleJam

/// The marble's spin (drawn only): it rolls on what it touches and keeps its spin in the air.
final class SpinTests: XCTestCase {
    private func course(barAngle: Double) -> Course {
        var c = Course()
        c.pads = [Pad(kind: .bar, x: c.dropX, y: c.dropY + 120, angle: barAngle, note: 3)]
        return c
    }

    func testOneSpinSamplePerPathPoint() {
        let run = Engine.simulate(course(barAngle: 0.3))
        XCTAssertEqual(run.spin.count, run.path.count / 2)
    }

    func testAFreeFallDoesNotSpin() {
        let run = Engine.simulate(Course())
        XCTAssertFalse(run.spin.isEmpty)
        XCTAssertTrue(run.spin.allSatisfy { $0 == 0 }, "nothing touched, nothing turns it")
    }

    func testItRollsTheWayItGoesDownASlope() {
        let right = Engine.simulate(course(barAngle: 0.3)), left = Engine.simulate(course(barAngle: -0.3))
        XCTAssertGreaterThan(right.spin.last!, 0.5, "down to the right: clockwise")
        XCTAssertLessThan(left.spin.last!, -0.5, "down to the left: counter-clockwise")
    }

    /// On a ramp the marble stays in contact, so its turn grows by the distance travelled over its radius (rolling, not sliding).
    /// (On a bar it bounces along instead: between bounces it keeps the spin it had.)
    func testOnARampItRollsWithoutSlipping() {
        var c = Course()
        c.pads = [Pad(kind: .ramp, x: c.dropX, y: c.dropY + 120, angle: 0.3, note: 3, length: Rules.rampLength, bend: 0)]
        let run = Engine.simulate(c), landed = run.hits.first!.time
        let a = landed + 0.1, b = landed + 0.2, p = run.position(at: a), q = run.position(at: b)
        let rolled = hypot(q.x - p.x, q.y - p.y) / Rules.radius
        XCTAssertEqual(run.spin(at: b) - run.spin(at: a), rolled, accuracy: rolled * 0.1)
        XCTAssertGreaterThan(rolled, 1, "it really moved")
    }

    func testSpinNeverChangesThePath() {
        let c = course(barAngle: 0.3), a = Engine.simulate(c), b = Engine.simulate(c)
        XCTAssertEqual(a.path, b.path)
        XCTAssertEqual(a.hits.map(\.time), b.hits.map(\.time))
    }
}
