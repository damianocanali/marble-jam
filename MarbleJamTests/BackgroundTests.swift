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

    private func opt(_ id: String, _ season: String?) -> BackgroundOption {
        BackgroundOption(id: id, name: id, image: URL(fileURLWithPath: "/tmp/\(id)"), thumb: URL(fileURLWithPath: "/tmp/\(id)t"), tint: 0.4, season: season)
    }

    func testSeasonFieldIsRead() {
        let json = #"[{"id":"bg-24","name":"Pumpkin Patch","season":"halloween","image":"a.jpg","thumb":"b.jpg","luminance":0.2}]"#
        XCTAssertEqual(BackgroundLibrary.parse(Data(json.utf8), base: URL(fileURLWithPath: "/tmp")).first?.season, "halloween")
    }

    func testOnlyTheLiveSeasonsBackgroundsAreOfferedFirst() {
        let all = [opt("wood", nil), opt("pumpkin", "halloween"), opt("lights", "christmas")]
        XCTAssertEqual(BackgroundLibrary.available(all, season: "halloween").map(\.id), ["pumpkin", "wood"])
        XCTAssertEqual(BackgroundLibrary.available(all, season: nil).map(\.id), ["wood"])
    }

    func testOffSeasonChoiceFallsBackToNight() {
        let all = [opt("wood", nil), opt("pumpkin", "halloween")]
        XCTAssertNil(BackgroundLibrary.resolve(all, chosenID: "pumpkin", season: nil))
        XCTAssertEqual(BackgroundLibrary.resolve(all, chosenID: "pumpkin", season: "halloween")?.id, "pumpkin")
    }

    func testNoChoiceUsesTheSeasonsBackground() {
        let all = [opt("wood", nil), opt("pumpkin", "halloween")]
        XCTAssertEqual(BackgroundLibrary.resolve(all, chosenID: "", season: "halloween")?.id, "pumpkin")
        XCTAssertNil(BackgroundLibrary.resolve(all, chosenID: "", season: nil))
        XCTAssertEqual(BackgroundLibrary.resolve(all, chosenID: "wood", season: "halloween")?.id, "wood")
    }
}
