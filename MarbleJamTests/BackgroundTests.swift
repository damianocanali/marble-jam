import XCTest
@testable import MarbleJam

final class BackgroundTests: XCTestCase {
    func testParsesManifestInOrder() throws {
        let json = #"[{"id":"bg-02","image":"bg-02.jpg","thumb":"bg-02-thumb.jpg","luminance":0.8},{"id":"bg-01","image":"bg-01.jpg","thumb":"bg-01-thumb.jpg","luminance":0.1}]"#
        let base = URL(fileURLWithPath: "/tmp/bgs")
        let list = BackgroundLibrary.parse(Data(json.utf8), base: base)
        XCTAssertEqual(list.map(\.id), ["bg-02", "bg-01"])
        XCTAssertEqual(list[0].image, base.appendingPathComponent("bg-02.jpg"))
        XCTAssertEqual(list[0].thumb, base.appendingPathComponent("bg-02-thumb.jpg"))
    }

    func testBadManifestGivesNoBackgrounds() {
        XCTAssertEqual(BackgroundLibrary.parse(Data("not json".utf8), base: URL(fileURLWithPath: "/tmp")).count, 0)
    }

    func testBrighterBackgroundsGetStrongerTint() {
        let dark = BackgroundLibrary.tint(forLuminance: 0.05), mid = BackgroundLibrary.tint(forLuminance: 0.5), bright = BackgroundLibrary.tint(forLuminance: 0.95)
        XCTAssertLessThan(dark, mid)
        XCTAssertLessThan(mid, bright)
        XCTAssertGreaterThanOrEqual(dark, 0.3)          // always some tint so pads glow
        XCTAssertLessThanOrEqual(bright, 0.72)          // never so dark the picture disappears
    }

    func testMissingFolderGivesNoBackgrounds() {
        XCTAssertEqual(BackgroundLibrary.load(from: URL(fileURLWithPath: "/nonexistent-\(UUID())")).count, 0)
    }

    func testNamesComeFromTheManifest() {
        let json = #"[{"id":"bg-03","name":"White Marble","image":"a.jpg","thumb":"b.jpg","luminance":0.9},{"id":"bg-04","image":"c.jpg","thumb":"d.jpg","luminance":0.4}]"#
        let list = BackgroundLibrary.parse(Data(json.utf8), base: URL(fileURLWithPath: "/tmp"))
        XCTAssertEqual(list.map(\.name), ["White Marble", "bg-04"])          // no name: fall back to the id
    }
}
