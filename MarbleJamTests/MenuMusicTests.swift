import XCTest
@testable import MarbleJam

final class MenuMusicTests: XCTestCase {
    func testTheTuneLoopsCleanly() {
        let notes = MenuTune.notes
        XCTAssertFalse(notes.isEmpty)
        XCTAssertEqual(notes.map(\.beat), notes.map(\.beat).sorted(), "notes in order, so they can be queued one after another")
        XCTAssertTrue(notes.allSatisfy { $0.beat >= 0 && $0.beat < MenuTune.beats }, "every note inside one loop")
        XCTAssertTrue(notes.allSatisfy { (40...88).contains($0.midi) }, "pitches the instruments sound good at")
        XCTAssertTrue(notes.allSatisfy { $0.gain > 0 && $0.gain <= 0.2 }, "quiet: it plays under the menu")
        XCTAssertEqual(MenuTune.length, 32 * 60 / 90, accuracy: 0.001)
    }

    func testItPlaysUntilStopped() {
        let m = MenuMusic(synth: Synth(audio: false), otherAudioPlaying: { false })
        m.start()
        XCTAssertTrue(m.isPlaying)
        XCTAssertGreaterThan(m.queued, 0, "the first notes are queued straight away")
        m.start()                                                           // starting twice changes nothing
        XCTAssertTrue(m.isPlaying)
        m.stop()
        XCTAssertFalse(m.isPlaying)
        m.start()
        XCTAssertTrue(m.isPlaying, "coming back to the menu starts it again")
        m.stop()
    }

    func testItStaysQuietOverTheParentsOwnMusic() {
        let m = MenuMusic(synth: Synth(audio: false), otherAudioPlaying: { true })
        m.start()
        XCTAssertFalse(m.isPlaying)
    }

    func testQueuingWrapsAroundTheLoop() {
        let m = MenuMusic(synth: Synth(audio: false), otherAudioPlaying: { false })
        m.start()
        m.queue(until: m.loopStart + MenuTune.length * 2.5)                    // as if two and a half loops went by
        XCTAssertGreaterThan(m.queued, MenuTune.notes.count * 2)
        m.stop()
    }
}
