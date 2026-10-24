import XCTest
@testable import MarbleJam

final class HolidaySongTests: XCTestCase {
    func testFiveHolidaysWithThreeSongsEach() {
        for list in [HolidaySongs.newYear, HolidaySongs.valentines, HolidaySongs.stPatricks, HolidaySongs.easter, HolidaySongs.muertos] {
            XCTAssertEqual(list.count, 3)
        }
        XCTAssertEqual(Set(HolidaySongs.all.map(\.name)).count, 15, "no song twice")
    }

    func testEveryNoteIsAWhiteKeyOnTheBars() {
        for r in HolidaySongs.all {
            XCTAssertTrue(r.melody.allSatisfy { (0...14).contains($0.note) }, r.name)
            XCTAssertTrue(r.melody.allSatisfy { [0.5, 1, 1.5, 2, 3].contains($0.beats) }, r.name)
        }
    }

    func testCompleteSongs() throws {
        for r in HolidaySongs.all where r.name != "Hot Cross Buns" {
            XCTAssertGreaterThanOrEqual(r.melody.count, 25, "\(r.name) is only its opening phrase")
        }
        let buns = try XCTUnwrap(HolidaySongs.easter.first { $0.name == "Hot Cross Buns" })
        XCTAssertEqual(buns.melody.count, 17, "Hot Cross Buns is the whole song: E D C twice, C C C C D D D D, E D C")
    }

    /// Swapped out because their bare melodies are not clearly free to use in every market (see the Rights notes in
    /// docs/superpowers/specs/2026-10-21-new-holidays-design.md).
    func testSongsWithUnclearRightsAreGone() {
        let fold = { (s: String) in s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil) }
        let names = Seasons.all.flatMap { $0.songs.map(\.name) } + HolidaySongs.all.map(\.name) + Songbook.all.map(\.name)
            + Challenges.everything.map(\.title)
        for gone in ["La Llorona", "We Wish You a Merry Christmas", "Cielito Lindo", "Las Mañanitas"] {
            XCTAssertFalse(names.contains { fold($0).contains(fold(gone)) }, "\(gone) is still on a song list")
        }
    }

    func testEveryHolidaySongPlaysOnTheBeat() {
        for r in HolidaySongs.all {
            let run = Engine.simulate(r.course())
            XCTAssertEqual(run.hits.count, r.melody.count, "\(r.name): every note gets a pad")
            XCTAssertEqual(run.hits.map(\.pad), Array(0..<r.melody.count), "\(r.name): pads play in melody order")
            XCTAssertTrue(run.hits.allSatisfy { Engine.isOnBeat($0.time) }, "\(r.name): all on the beat")
        }
    }
}
