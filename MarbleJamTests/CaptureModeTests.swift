#if DEBUG
import XCTest
@testable import MarbleJam

/// The DEBUG launch arguments that open the app straight to a state for screenshots and recordings.
final class CaptureModeTests: XCTestCase {
    func testNoArgumentsMeansNoCapture() {
        XCTAssertFalse(CaptureMode.parse([]).isActive)
        XCTAssertFalse(CaptureMode.parse(["/path/MarbleJam", "-NSDocumentRevisionsDebugMode", "YES"]).isActive, "Xcode's own arguments")
    }

    func testReadsEveryArgument() {
        let m = CaptureMode.parse(["/path/MarbleJam", "-mbScreen", "store", "-mbAutoPlay", "2.5", "-mbSeason", "christmas",
                                   "-mbSkin", "galaxy", "-mbBackground", "bg-40"])
        XCTAssertEqual(m, CaptureMode(screen: .store, autoPlay: 2.5, season: "christmas", skin: "galaxy", background: "bg-40"))
        XCTAssertTrue(m.isActive)
        XCTAssertEqual(CaptureMode.parse(["-mbSeason", "off"]).season, "off")
        XCTAssertEqual(CaptureMode.parse(["-mbBackground", "night"]).background, "night")
        for s in ["menu", "library", "play", "challenges", "store", "account"] { XCTAssertNotNil(CaptureMode.parse(["-mbScreen", s]).screen, s) }
    }

    func testTheDemoSongOpensTheBuilder() {
        XCTAssertEqual(CaptureMode.parse(["-mbSong", "demo"]).screen, .play)
        XCTAssertEqual(CaptureMode.parse(["-mbSong", "demo", "-mbScreen", "menu"]).screen, .menu, "an explicit screen wins")
        XCTAssertNil(CaptureMode.parse(["-mbSong", "Jingle Bells"]).song, "only the demo")
        XCTAssertNil(CaptureMode.parse(["-mbSong", "Jingle Bells"]).screen)
    }

    func testAStorePackOpensTheStore() {
        XCTAssertEqual(CaptureMode.parse(["-mbStorePack", "glass"]).storePack, "glass")
        XCTAssertEqual(CaptureMode.parse(["-mbStorePack", "glass"]).screen, .store)
        XCTAssertNil(CaptureMode.parse(["-mbStorePack", "plaid"]).storePack, "only real packs")
    }

    func testIgnoresWhatItCannotUse() {
        XCTAssertNil(CaptureMode.parse(["-mbScreen", "nowhere"]).screen)
        XCTAssertNil(CaptureMode.parse(["-mbAutoPlay", "soon"]).autoPlay)
        XCTAssertNil(CaptureMode.parse(["-mbAutoPlay", "-1"]).autoPlay)
        XCTAssertNil(CaptureMode.parse(["-mbAutoPlay", "inf"]).autoPlay)
        XCTAssertNil(CaptureMode.parse(["-mbSeason", "summer"]).season)
        XCTAssertNil(CaptureMode.parse(["-mbSkin", "plaid"]).skin)
        XCTAssertNil(CaptureMode.parse(["-mbBackground", ""]).background)
        XCTAssertFalse(CaptureMode.parse(["-mbScreen"]).isActive, "a key without its value")
        XCTAssertFalse(CaptureMode.parse(["-mbUnknown", "x"]).isActive)
    }

    func testAMissingValueDoesNotSwallowTheNextKey() {
        let m = CaptureMode.parse(["-mbSkin", "-mbScreen", "challenges"])
        XCTAssertNil(m.skin)
        XCTAssertEqual(m.screen, .challenges)
    }
}
#endif
