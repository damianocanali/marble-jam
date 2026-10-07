import XCTest
@testable import MarbleJam

final class ThemeTests: XCTestCase {
    func testNoSeasonOrUnknownIsTheStandardLook() {
        XCTAssertEqual(Theme.forSeason(nil), .standard)
        XCTAssertEqual(Theme.forSeason("easter"), .standard)
    }

    func testEachHolidayHasItsOwnLook() {
        let looks = Seasons.all.map { Theme.forSeason($0.id) }
        XCTAssertFalse(looks.contains(.standard))
        XCTAssertEqual(Set(looks.map(\.primary)).count, looks.count, "every holiday has its own main colour")
    }

    func testMainButtonTextIsReadable() {
        for t in [Theme.standard] + Seasons.all.map({ Theme.forSeason($0.id) }) {
            XCTAssertGreaterThanOrEqual(Theme.contrast(t.primary, t.primaryText), 4.5, "\(t.primary)")
        }
    }
}

final class AppIconTests: XCTestCase {
    func testHolidayIconOnlyWhenBundled() {
        XCTAssertEqual(AppIcons.name(for: "christmas", available: ["AppIcon-christmas"]), "AppIcon-christmas")
        XCTAssertNil(AppIcons.name(for: "halloween", available: ["AppIcon-christmas"]))
        XCTAssertNil(AppIcons.name(for: nil, available: ["AppIcon-christmas"]))
    }
}
