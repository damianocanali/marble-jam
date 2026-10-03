import XCTest
@testable import MarbleJam

@MainActor
final class ModelTests: XCTestCase {
    private func modelWithBar() -> GameModel {
        let m = GameModel()
        m.loadDemo()
        m.selected = m.course.pads.first { $0.kind == .bar }?.id
        return m
    }

    func testNudgeMovesSelectedPad() {
        let m = modelWithBar(), p = m.selectedPad!
        m.nudge(dx: 4, dy: -4)
        XCTAssertEqual(m.selectedPad!.x, p.x + 4, accuracy: 1e-9)
        XCTAssertEqual(m.selectedPad!.y, p.y - 4, accuracy: 1e-9)
    }

    func testNudgeClamps() {
        let m = modelWithBar()
        for _ in 0..<500 { m.nudge(dx: -12, dy: -12) }
        XCTAssertEqual(m.selectedPad!.x, 20)
        XCTAssertEqual(m.selectedPad!.y, 40)
    }

    func testRotateAndSetAngleClamp() {
        let m = modelWithBar()
        m.setAngle(0)
        m.rotate(by: Rules.rotateStep)
        XCTAssertEqual(m.selectedPad!.angle, Rules.rotateStep, accuracy: 1e-9)
        m.setAngle(3)
        XCTAssertEqual(m.selectedPad!.angle, 1.4)
    }

    func testRotateIgnoresBumper() {
        let m = GameModel()
        m.loadDemo()
        m.addBumper()                        // selects the new bumper
        XCTAssertEqual(m.selectedPad?.kind, .bumper)
        m.rotate(by: 0.5); m.setAngle(1)
        XCTAssertEqual(m.selectedPad!.angle, 0)
    }

    func testHoldIsOneUndoStep() {
        let m = modelWithBar(), id = m.selected, start = m.selectedPad!
        m.mark()                             // what the controller does at the start of a hold
        for _ in 0..<30 { m.nudge(dx: 4, dy: 0) }
        m.undo()
        let back = m.course.pads.first { $0.id == id }!
        XCTAssertEqual(back.x, start.x, accuracy: 1e-9)
    }

    func testFinishCelebrates() {
        let m = GameModel(); m.loadDemo(); m.start()
        m.finish()
        XCTAssertFalse(m.playing)
        XCTAssertNotNil(m.celebration)
        XCTAssertEqual(m.celebration!.notes, m.run.hits.count)
    }

    func testStopDoesNotCelebrate() {
        let m = GameModel(); m.loadDemo(); m.start()
        m.stop()
        XCTAssertNil(m.celebration)
    }

    func testStartClearsCelebration() {
        let m = GameModel(); m.loadDemo(); m.start(); m.finish()
        m.start()
        XCTAssertNil(m.celebration)
    }

    func testStartedModelsCanBeFreed() {
        for _ in 0..<150 {                   // the audio thread must be mid-render when a model goes away
            autoreleasepool { let m = GameModel(); m.chime(0); RunLoop.current.run(until: Date() + 0.02) }
        }
    }
}
