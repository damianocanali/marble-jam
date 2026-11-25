import XCTest
@testable import MarbleJam

final class ReviewPromptTests: XCTestCase {
    private func prompt() -> ReviewPrompt {
        let n = "test.\(UUID())"; let d = UserDefaults(suiteName: n)!; d.removePersistentDomain(forName: n); return ReviewPrompt(defaults: d)
    }

    func testAsksAfterTheSecondPerfectMomentOncePerVersion() {
        let p = prompt()
        p.recordWin(stars: 3)
        XCTAssertFalse(p.askNow(version: "1.0"), "never after the very first win")
        p.recordWin(stars: 2); p.recordWin(stars: 1)
        XCTAssertFalse(p.askNow(version: "1.0"), "only 3 stars count")
        p.recordWin(stars: 3)
        XCTAssertTrue(p.askNow(version: "1.0"))
        p.recordWin(stars: 3)
        XCTAssertFalse(p.askNow(version: "1.0"), "once per version")
        XCTAssertTrue(p.askNow(version: "1.1"), "a new version may ask again")
    }
}
