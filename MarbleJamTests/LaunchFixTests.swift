import XCTest
@testable import MarbleJam

final class LaunchFixTests: XCTestCase {
    private func defaults() -> UserDefaults { let n = "test.\(UUID())"; let d = UserDefaults(suiteName: n)!; d.removePersistentDomain(forName: n); return d }

    @MainActor func testACancelledGameCenterSheetIsNotShownAgainNextLaunch() {
        let d = defaults(), gc = GameCenter(defaults: d)
        gc.finishSignIn(name: nil, failed: true)                           // the player closed Apple's sheet
        XCTAssertFalse(d.bool(forKey: "gamecenter.on"), "resume() at the next launch stays quiet")
        XCTAssertFalse(gc.isSignedIn)
        XCTAssertNotNil(gc.problem)
    }

    @MainActor func testSigningInIsRememberedAndReportsStars() {
        let d = defaults(), gc = GameCenter(defaults: d)
        var reported = false
        gc.onSignIn = { reported = true }
        gc.finishSignIn(name: "Player", failed: false)
        XCTAssertTrue(d.bool(forKey: "gamecenter.on"))
        XCTAssertEqual(gc.playerName, "Player")
        XCTAssertNil(gc.problem)
        XCTAssertTrue(reported)
    }

    func testTheHolidayIconWaitsUntilAfterTheFirstLaunch() {
        let d = defaults()
        XCTAssertTrue(AppIcons.isFirstLaunch(d), "no icon notice the moment a new player opens the app")
        XCTAssertFalse(AppIcons.isFirstLaunch(d))
        XCTAssertFalse(AppIcons.isFirstLaunch(d))
    }
}
