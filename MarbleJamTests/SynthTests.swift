import XCTest
@testable import MarbleJam

final class SynthTests: XCTestCase {
    func testMakingASynthLeavesTheAudioSystemAlone() {
        let s = Synth()
        XCTAssertFalse(s.isAudioSetUp, "audio starts with the first sound, not when the app opens")
        s.prepare([(60, true)], instrument: .bells)                         // rendering notes needs no audio hardware
        XCTAssertFalse(s.isAudioSetUp)
        XCTAssertEqual(s.now, 0)
    }

    func testTheClockRunsEvenWithoutSound() {
        let s = Synth(audio: false)                                        // like a phone whose audio won't start
        s.start()
        let a = s.now
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertGreaterThan(s.now - a, 0.15, "playback keeps moving on a plain clock")
    }
}
