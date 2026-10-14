import XCTest
@testable import MarbleJam

/// The game is called Marble Beats. "Marble Jam" was taken on the App Store and "Rolling Notes" was dropped too; the old
/// names may live on only in code (the bundle id, folder and type names), never in anything a player sees or hears.
final class NameTests: XCTestCase {
    func testHomeScreenName() {
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, "Marble Beats")
    }

    func testNoPlayerFacingTextUsesAnOldName() throws {
        var texts = Seasons.all.flatMap { [$0.title, $0.banner] + $0.songs.map(\.name) }
        texts += Skins.all.map(\.name) + Skins.packs.map(\.name) + Challenges.worldNames + Challenges.everything.map(\.title)
        texts += BackgroundLibrary.bundled.map(\.name)
        let catalogue = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "Products", withExtension: "storekit"))
        texts.append(try String(contentsOf: catalogue, encoding: .utf8).replacingOccurrences(of: "com.marblejam", with: ""))
        for t in texts {
            let l = t.lowercased()
            XCTAssertFalse(l.contains("marble jam") || l.contains("marblejam") || l.contains("rolling notes"), t)
        }
    }
}
