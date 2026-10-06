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
        for _ in 0..<10 { m.rotate(by: Rules.rotateStep) }
        m.undo()
        let back = m.course.pads.first { $0.id == id }!
        XCTAssertEqual(back.angle, start.angle, accuracy: 1e-9)
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

    func testLettingGoOfAClosePadSnapsItOnTheBeat() throws {
        let m = GameModel(); m.loadDemo()
        let i = 5; m.selected = m.course.pads[i].id
        var dy = 0
        repeat { dy += 1; m.updateSelected { $0.y += 1 } } while m.beats[i] != .near && dy < 40
        XCTAssertEqual(m.beats[i], .near)
        XCTAssertTrue(m.finishEdit())
        XCTAssertEqual(m.beats[i], .on)
    }

    func testLettingGoOfAPadOnTheBeatChangesNothing() {
        let m = GameModel(); m.loadDemo()
        m.selected = m.course.pads[5].id
        let before = m.course
        XCTAssertFalse(m.finishEdit())
        XCTAssertEqual(m.course, before)
    }

    private func tempStore() -> SongStore { SongStore(folder: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)) }

    func testEditsSaveIntoTheOpenSong() {
        let store = tempStore(), s = store.newSong(), m = GameModel(store: store)
        m.open(s)
        m.addPad()
        XCTAssertEqual(store.song(s.id)?.course.pads.count, 1)
    }

    func testOpeningASongClearsUndo() {
        let store = tempStore(), a = store.newSong(), b = store.resetDemo(), m = GameModel(store: store)
        m.open(a); m.addPad()
        m.open(b); m.undo()
        XCTAssertEqual(m.course, b.course)
    }

    func testInstrumentChangeIsSavedAndUndoable() {
        let store = tempStore(), s = store.newSong(), m = GameModel(store: store)
        m.open(s)
        m.setInstrument(.guitar)
        XCTAssertEqual(store.song(s.id)?.instrument, .guitar)
        m.undo()
        XCTAssertEqual(m.instrument, .bells)
        XCTAssertEqual(store.song(s.id)?.instrument, .bells)
    }

    func testRenameFromTheBuilder() {
        let store = tempStore(), s = store.newSong(), m = GameModel(store: store)
        m.open(s)
        m.rename(to: " Funky ")
        XCTAssertEqual(m.song?.name, "Funky")
        XCTAssertEqual(store.song(s.id)?.name, "Funky")
    }

    func testTappingAClosePadWithoutMovingItChangesNothing() {
        let m = GameModel(); m.loadDemo()
        let i = 5; m.selected = m.course.pads[i].id
        var dy = 0
        repeat { dy += 1; m.updateSelected { $0.y += 1 } } while m.beats[i] != .near && dy < 40
        let before = m.course
        m.mark()                                                   // what touch-down does
        XCTAssertFalse(m.finishEdit())                             // released without moving
        XCTAssertEqual(m.course, before, "a tap must not snap the pad")
        m.undo()                                                   // the tap left no step, so undo goes back past loading the demo
        XCTAssertTrue(m.course.pads.isEmpty, "and must not leave an empty undo step behind")
    }

    func testHeaderInfoIsNotesAndBeatsOnly() {
        let m = GameModel()
        XCTAssertEqual(m.info, "No notes yet")
        m.loadDemo()
        XCTAssertEqual(m.info, "42 notes · 42 on the beat")
    }
}
