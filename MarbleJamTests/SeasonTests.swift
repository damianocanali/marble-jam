import XCTest
@testable import MarbleJam

final class SeasonTests: XCTestCase {
    private var cal: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }()
    private func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date { cal.date(from: DateComponents(year: y, month: m, day: d, hour: hour))! }
    private func season(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> String? { Seasons.active(on: day(y, m, d, hour: hour), calendar: cal)?.id }

    func testHalloweenWindow() {
        XCTAssertNil(season(2026, 9, 30))
        XCTAssertEqual(season(2026, 10, 1, hour: 0), "halloween")
        XCTAssertEqual(season(2026, 10, 31), "halloween")
        XCTAssertEqual(season(2026, 11, 1, hour: 23), "halloween")
    }

    func testThanksgivingFollowsTheFourthThursday() {
        XCTAssertEqual(Seasons.thanksgiving(year: 2026, calendar: cal), day(2026, 11, 26, hour: 0))
        XCTAssertEqual(Seasons.thanksgiving(year: 2027, calendar: cal), day(2027, 11, 25, hour: 0))
        XCTAssertEqual(Seasons.thanksgiving(year: 2028, calendar: cal), day(2028, 11, 23, hour: 0))
        XCTAssertEqual(season(2026, 11, 2), "thanksgiving")
        XCTAssertEqual(season(2026, 11, 27, hour: 23), "thanksgiving")          // the day after
        XCTAssertNil(season(2026, 11, 28))
        XCTAssertNil(season(2028, 11, 25))                                       // 2028: Nov 23 + 1 = 24 is the last day
    }

    func testChristmasCrossesNewYear() {
        XCTAssertNil(season(2026, 11, 30))
        XCTAssertEqual(season(2026, 12, 1, hour: 0), "christmas")
        XCTAssertEqual(season(2026, 12, 31), "christmas")
        XCTAssertEqual(season(2027, 1, 6, hour: 23), "christmas")
        XCTAssertNil(season(2027, 1, 7))
    }

    func testSummerIsOffSeason() { XCTAssertNil(season(2027, 7, 4)) }

    func testPreviewOverridesTheDate() {
        let summer = day(2027, 7, 4)
        XCTAssertEqual(Seasons.current(on: summer, preview: "christmas", calendar: cal)?.id, "christmas")
        XCTAssertNil(Seasons.current(on: day(2026, 10, 5), preview: "off", calendar: cal))
        XCTAssertEqual(Seasons.current(on: day(2026, 10, 5), preview: "", calendar: cal)?.id, "halloween")
    }

    func testEveryHolidaySongIsAllOnTheBeat() {
        for s in Seasons.all {
            XCTAssertGreaterThanOrEqual(s.songs.count, 3, s.id)
            for r in s.songs {
                let run = Engine.simulate(r.course())
                XCTAssertEqual(run.hits.count, r.melody.count, "\(r.name): every note gets a pad")
                XCTAssertEqual(run.hits.map(\.pad), Array(0..<r.melody.count), "\(r.name): pads play in melody order")
                XCTAssertTrue(run.hits.allSatisfy { Engine.isOnBeat($0.time) }, "\(r.name): all on the beat")
            }
        }
    }

    func testSeasonsUseGregorianDatesWhateverThePhonesCalendar() {
        for id in [Calendar.Identifier.hebrew, .islamicUmmAlQura, .persian] {
            var other = Calendar(identifier: id); other.timeZone = TimeZone(identifier: "UTC")!
            XCTAssertEqual(Seasons.active(on: day(2026, 12, 15), calendar: other)?.id, "christmas", "\(id)")
            XCTAssertEqual(Seasons.active(on: day(2026, 11, 26), calendar: other)?.id, "thanksgiving", "\(id)")
            XCTAssertNil(Seasons.active(on: day(2027, 7, 4), calendar: other), "\(id)")
        }
    }

    func testThanksgivingWhenNovemberStartsOnThursdayOrFriday() {
        XCTAssertEqual(Seasons.thanksgiving(year: 2029, calendar: cal), day(2029, 11, 22, hour: 0))   // Nov 1 2029 is a Thursday
        XCTAssertEqual(Seasons.thanksgiving(year: 2030, calendar: cal), day(2030, 11, 28, hour: 0))   // Nov 1 2030 is a Friday
    }
}
