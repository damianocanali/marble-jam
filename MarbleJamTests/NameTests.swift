import XCTest
@testable import MarbleJam

/// The game is called Rolling Notes ("Marble Jam" was taken on the App Store); the old name may live on only in code.
final class NameTests: XCTestCase {
    func testHomeScreenName() {
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, "Rolling Notes")
    }

    func testNoPlayerFacingTextUsesTheOldName() throws {
        var texts = Seasons.all.flatMap { [$0.title, $0.banner] + $0.songs.map(\.name) }
        texts += Skins.all.map(\.name) + Skins.packs.map(\.name) + Challenges.worldNames + Challenges.everything.map(\.title)
        let catalogue = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "Products", withExtension: "storekit"))
        texts.append(try String(contentsOf: catalogue, encoding: .utf8).replacingOccurrences(of: "com.marblejam", with: ""))
        for t in texts { XCTAssertFalse(t.lowercased().contains("marble jam") || t.lowercased().contains("marblejam"), t) }
    }
}
