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
}
