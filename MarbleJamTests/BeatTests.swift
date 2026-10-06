import XCTest
@testable import MarbleJam

final class BeatTests: XCTestCase {
    func testBeatOffsetIsDistanceToTheNearestHalfBeat() {
        XCTAssertEqual(Engine.beatOffset(0.5), 0, accuracy: 1e-9)
        XCTAssertEqual(Engine.beatOffset(0.6), 0.1, accuracy: 1e-9)
        XCTAssertEqual(Engine.beatOffset(0.7), 0.05, accuracy: 1e-9)       // nearer to 0.75
    }

    func testPadStatesFromHits() {
        var run = Run()
        run.hits = [Hit(time: 0.5, x: 0, y: 0, pad: 0, speed: 100), Hit(time: 1.0, x: 0, y: 0, pad: 0, speed: 100),
                    Hit(time: 1.31, x: 0, y: 0, pad: 1, speed: 100),             // 0.06 off: close
                    Hit(time: 1.62, x: 0, y: 0, pad: 2, speed: 100),             // 0.12 off: off
                    Hit(time: 2.0, x: 0, y: 0, pad: 4, speed: 100), Hit(time: 2.37, x: 0, y: 0, pad: 4, speed: 100)]
        XCTAssertEqual(Engine.beatStates(run, padCount: 5), [.on, .near, .off, .unused, .off])
    }

    func testSnapPutsANearlyRightPadOnTheBeat() throws {
        let demo = Engine.demo(), i = 5
        // nudge the pad down until it is close to the beat but no longer on it
        let nudged = (1...40).lazy.map { dy -> Course in var c = demo; c.pads[i].y += Double(dy); return c }
            .first { Engine.beatStates(Engine.simulate($0), padCount: $0.pads.count)[i] == .near }
        let c = try XCTUnwrap(nudged, "some small nudge should leave the pad close but off the beat")
        let before = Engine.beatStates(Engine.simulate(c), padCount: c.pads.count)
        let snapped = try XCTUnwrap(Engine.snapToBeat(c, pad: i))
        let after = Engine.beatStates(Engine.simulate(snapped), padCount: snapped.pads.count)
        XCTAssertEqual(after[i], .on)
        XCTAssertEqual(Array(after[..<i]), Array(before[..<i]), "earlier pads are untouched")
        XCTAssertLessThan(hypot(snapped.pads[i].x - c.pads[i].x, snapped.pads[i].y - c.pads[i].y), 40, "a small move, not a jump")
    }

    func testSnapLeavesFarOffPadsAlone() {
        var c = Engine.demo()
        c.pads[5].x += 200                                                     // nowhere near the marble's path now
        XCTAssertNil(Engine.snapToBeat(c, pad: 5))
    }
}
