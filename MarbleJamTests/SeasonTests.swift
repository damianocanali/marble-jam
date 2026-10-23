import UIKit
import XCTest
@testable import MarbleJam

final class SeasonTests: XCTestCase {
    private var cal: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }()
    private func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date { cal.date(from: DateComponents(year: y, month: m, day: d, hour: hour))! }
    private func season(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> String? { Seasons.active(on: day(y, m, d, hour: hour), calendar: cal)?.id }

    func testHalloweenWindow() {
        XCTAssertNil(season(2026, 9, 30))
        XCTAssertEqual(season(2026, 10, 1, hour: 0), "halloween")
        XCTAssertEqual(season(2026, 10, 31, hour: 23), "halloween")
        XCTAssertEqual(season(2026, 11, 1, hour: 0), "muertos")
    }

    func testThanksgivingFollowsTheFourthThursday() {
        XCTAssertEqual(Seasons.thanksgiving(year: 2026, calendar: cal), day(2026, 11, 26, hour: 0))
        XCTAssertEqual(Seasons.thanksgiving(year: 2027, calendar: cal), day(2027, 11, 25, hour: 0))
        XCTAssertEqual(Seasons.thanksgiving(year: 2028, calendar: cal), day(2028, 11, 23, hour: 0))
        XCTAssertEqual(season(2026, 11, 7, hour: 23), "muertos")
        XCTAssertEqual(season(2026, 11, 8, hour: 0), "thanksgiving")
        XCTAssertEqual(season(2026, 11, 27, hour: 23), "thanksgiving")          // the day after
        XCTAssertNil(season(2026, 11, 28))
        XCTAssertNil(season(2028, 11, 25))                                       // 2028: Nov 23 + 1 = 24 is the last day
    }

    func testChristmasThenNewYear() {
        XCTAssertNil(season(2026, 11, 30))
        XCTAssertEqual(season(2026, 12, 1, hour: 0), "christmas")
        XCTAssertEqual(season(2026, 12, 30, hour: 23), "christmas")
        XCTAssertEqual(season(2026, 12, 31, hour: 0), "newyear")
        XCTAssertEqual(season(2027, 1, 1), "newyear")
        XCTAssertEqual(season(2027, 1, 6, hour: 23), "newyear")
        XCTAssertNil(season(2027, 1, 7))
    }

    func testValentinesAndStPatricks() {
        XCTAssertNil(season(2027, 1, 31))
        XCTAssertEqual(season(2027, 2, 1, hour: 0), "valentines")
        XCTAssertEqual(season(2027, 2, 14, hour: 23), "valentines")
        XCTAssertNil(season(2027, 2, 15))
        XCTAssertEqual(season(2027, 3, 1, hour: 0), "stpatricks")
        XCTAssertEqual(season(2027, 3, 17, hour: 23), "stpatricks")
    }

    func testEasterSunday() {
        let known = [(2024, 3, 31), (2025, 4, 20), (2026, 4, 5), (2027, 3, 28), (2028, 4, 16), (2038, 4, 25), (2285, 3, 22)]
        for (y, m, d) in known { XCTAssertEqual(Seasons.easter(year: y, calendar: cal), day(y, m, d, hour: 0), "\(y)") }
        XCTAssertNil(season(2026, 3, 21, hour: 23))                             // 2026: the day before the window opens
        XCTAssertEqual(season(2026, 3, 22, hour: 0), "easter")                  // 2026: two weeks before Apr 5
        XCTAssertEqual(season(2026, 4, 6, hour: 23), "easter")                  // Easter Monday
        XCTAssertNil(season(2026, 4, 7))
    }

    func testEasterNeverStartsBeforeStPatricksEnds() {
        XCTAssertEqual(season(2027, 3, 17, hour: 23), "stpatricks")             // 2027: Easter Mar 28, two weeks before is Mar 14
        XCTAssertEqual(season(2027, 3, 18, hour: 0), "easter")
    }

    func testNoTwoHolidaysOverlapForACentury() {
        for y in 2026...2126 {
            let windows = Seasons.all.map { s -> (String, Date, Date) in let w = s.window(y, cal); return (s.id, w.first, w.last) }
                .sorted { $0.1 < $1.1 }
            for (a, b) in zip(windows, windows.dropFirst()) {
                XCTAssertLessThan(cal.startOfDay(for: a.2), cal.startOfDay(for: b.1), "\(y): \(a.0) runs into \(b.0)")
            }
            if let last = windows.last, let next = Seasons.all.map({ $0.window(y + 1, cal) }).map(\.first).min() {
                XCTAssertLessThan(cal.startOfDay(for: last.2), cal.startOfDay(for: next), "\(y): \(last.0) runs into next year")
            }
        }
    }

    func testEachHolidaysOwnDayIsInItsWindow() {
        for y in [2026, 2027, 2030, 2045] {
            let days: [String: Date] = ["halloween": day(y, 10, 31), "muertos": day(y, 11, 2), "thanksgiving": Seasons.thanksgiving(year: y, calendar: cal),
                                        "christmas": day(y, 12, 25), "newyear": day(y, 12, 31), "valentines": day(y + 1, 2, 14),
                                        "stpatricks": day(y + 1, 3, 17), "easter": Seasons.easter(year: y + 1, calendar: cal)]
            for (id, d) in days { XCTAssertEqual(Seasons.active(on: d, calendar: cal)?.id, id, "\(id) \(y)") }
        }
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

    func testTheShelfIsBuiltOnceAndRemembered() {
        let christmas = Seasons.all[2]
        let first = Seasons.shelf(for: christmas), again = Seasons.shelf(for: christmas)
        XCTAssertEqual(first.map(\.name), christmas.songs.map(\.name))
        XCTAssertEqual(first.map(\.id), again.map(\.id), "the second call reuses the first build")
    }

    func testHolidaySongsAreComplete() {
        for s in Seasons.all { for r in s.songs where !["We Gather Together", "Simple Gifts", "Hot Cross Buns"].contains(r.name) {   // the first two wait for their scores, the last is a whole song of 17 notes
            XCTAssertGreaterThanOrEqual(r.melody.count, 25, "\(r.name) is only its opening phrase")
        } }
    }

    func testHolidayTitleArtIsBundledWhereItExists() {
        let byID = Dictionary(uniqueKeysWithValues: Seasons.all.map { ($0.id, $0) })
        for id in ["halloween", "thanksgiving", "christmas", "newyear", "valentines", "stpatricks", "easter", "muertos"] {
            XCTAssertNotNil(byID[id].flatMap { UIImage(named: $0.titleArt) }, "\(id) artwork")
        }
    }

    func testTheNewHolidaysHaveTitleArt() {
        let plain = UIImage(named: "Title")!
        for id in ["newyear", "valentines", "stpatricks", "easter", "muertos"] {
            let art = UIImage(named: "SeasonTitle-\(id)")
            XCTAssertNotNil(art, id)
            XCTAssertEqual(art?.size.width ?? 0, plain.size.width, accuracy: 1, "\(id): the greeting never widens the title")
            XCTAssertGreaterThan(art?.size.height ?? 0, plain.size.height, "\(id): the greeting sits above the lettering")
        }
    }
}
