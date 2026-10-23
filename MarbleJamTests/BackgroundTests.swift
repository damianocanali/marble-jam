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

    func testChoosingNightSkyKeepsItEvenDuringASeason() {
        let all = [opt("wood", nil), opt("pumpkin", "halloween")]
        XCTAssertNil(BackgroundLibrary.resolve(all, chosenID: BackgroundLibrary.nightID, season: "halloween"))
        XCTAssertNil(BackgroundLibrary.resolve(all, chosenID: BackgroundLibrary.nightID, season: nil))
    }

    /// The bundled set: the 32 drawn ones keep their ids (players' saved choices stay valid), the artist's come after,
    /// each holiday opens on the artist's own holiday background, and the rest of the year on the artist's Marble Track.
    func testBundledCatalogue() {
        let all = BackgroundLibrary.bundled
        XCTAssertEqual(all.map(\.id).sorted(), (1...45).map { String(format: "bg-%02d", $0) })
        XCTAssertEqual(all.first { $0.id == "bg-01" }?.name, "Dark Wood")
        XCTAssertEqual(all.first { $0.id == "bg-24" }?.name, "Pumpkin Patch")
        XCTAssertEqual(all.first { $0.id == "bg-32" }?.name, "Snowflakes")
        let defaults = ["halloween": "Spooky Track", "thanksgiving": "Piano Forest", "christmas": "Candy Cane Road"]
        for (season, name) in defaults {
            XCTAssertEqual(BackgroundLibrary.resolve(all, chosenID: "", season: season)?.name, name, season)
            XCTAssertEqual(all.filter { $0.season == season }.count, 4, season)
        }
        XCTAssertEqual(all.filter { $0.season == nil }.count, 28)
        XCTAssertEqual(BackgroundLibrary.resolve(all, chosenID: "", season: nil)?.name, "Marble Track")
        for b in all {
            XCTAssertTrue(FileManager.default.fileExists(atPath: b.image.path), b.id)
            XCTAssertTrue(FileManager.default.fileExists(atPath: b.thumb.path), b.id)
        }
    }

    func testTheNewHolidaysOpenOnTheirOwnBackground() {
        let all = BackgroundLibrary.bundled
        let defaults = ["valentines": "Love Track", "easter": "Spring Meadow", "stpatricks": "Rainbow Hills",
                        "newyear": "Fireworks", "muertos": "Marigold Path"]
        for (season, name) in defaults {
            XCTAssertEqual(all.filter { $0.season == season }.count, 1, season)
            XCTAssertEqual(BackgroundLibrary.resolve(all, chosenID: "", season: season)?.name, name, season)
        }
    }

    /// Off-season, a player who never picked a background sees the everyday one, listed first; picking the night sky still works.
    func testEverydayBackgroundIsTheOffSeasonDefault() {
        func bg(_ id: String, _ season: String? = nil) -> BackgroundOption {
            BackgroundOption(id: id, name: id, image: URL(fileURLWithPath: "/\(id)"), thumb: URL(fileURLWithPath: "/\(id)-t"), tint: 0.4, season: season)
        }
        let all = [bg("pumpkin", "halloween"), bg("wood"), bg(BackgroundLibrary.everydayID)]
        XCTAssertEqual(BackgroundLibrary.resolve(all, chosenID: "", season: nil)?.id, BackgroundLibrary.everydayID)
        XCTAssertEqual(BackgroundLibrary.resolve(all, chosenID: "", season: "halloween")?.id, "pumpkin", "a holiday still opens on its own")
        XCTAssertNil(BackgroundLibrary.resolve(all, chosenID: BackgroundLibrary.nightID, season: nil), "the night sky on purpose")
        XCTAssertEqual(BackgroundLibrary.resolve(all, chosenID: "wood", season: nil)?.id, "wood")
        XCTAssertEqual(BackgroundLibrary.available(all, season: nil).map(\.id), [BackgroundLibrary.everydayID, "wood"])
        XCTAssertEqual(BackgroundLibrary.available(all, season: "halloween").map(\.id), ["pumpkin", BackgroundLibrary.everydayID, "wood"])
        // the picker ticks what is showing: the everyday default (never chose), not the night sky
        XCTAssertEqual(BackgroundLibrary.shownID(BackgroundLibrary.resolve(all, chosenID: "", season: nil)), BackgroundLibrary.everydayID)
        XCTAssertEqual(BackgroundLibrary.shownID(BackgroundLibrary.resolve(all, chosenID: BackgroundLibrary.nightID, season: nil)), BackgroundLibrary.nightID)
        XCTAssertEqual(BackgroundLibrary.shownID(BackgroundLibrary.resolve(all, chosenID: "pumpkin", season: nil)), BackgroundLibrary.nightID,
                       "a holiday pick out of season shows the night sky, so that's what is ticked")
    }
}
