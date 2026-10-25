import XCTest
@testable import MarbleJam

final class RemindersTests: XCTestCase {
    private var cal: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "America/New_York")!; return c }()
    private func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date { cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))! }
    private func progress() -> ChallengeProgress {
        let n = "test.\(UUID())"; let d = UserDefaults(suiteName: n)!; d.removePersistentDomain(forName: n); return ChallengeProgress(defaults: d)
    }
    private func plan(_ now: Date, lastPlayed: Date? = nil, _ p: ChallengeProgress? = nil) -> [Reminder] {
        Reminders.plan(now: now, lastPlayed: lastPlayed ?? now, progress: p ?? progress(), calendar: cal)
    }

    func testHalloweenStartAndEndingSoonAtHalfPastFour() {
        let r = plan(day(2026, 9, 20))
        let start = r.first { $0.id == "start-halloween-2026" }, ending = r.first { $0.id == "ending-halloween-2026" }
        XCTAssertEqual(start?.date, day(2026, 10, 1, 16, 30))
        XCTAssertEqual(start?.title, "🎃 Halloween is here!")
        XCTAssertEqual(start?.body, "New songs and 6 holiday levels.")
        XCTAssertEqual(ending?.date, day(2026, 10, 28, 16, 30))
        XCTAssertEqual(ending?.body, "Last few days for the Halloween levels 🎃")
    }

    func testEndingSoonSkippedWhenTheHolidayIsDone() {
        let p = progress()
        for id in Challenges.holidayIDs("halloween") { p.record(id, stars: 1) }
        XCTAssertNil(plan(day(2026, 9, 20), p).first { $0.id == "ending-halloween-2026" })
        XCTAssertNotNil(plan(day(2026, 9, 20), p).first { $0.id == "start-halloween-2026" }, "the start is still news")
    }

    func testEveryReminderAtHalfPastFourInTheFutureAndUnder64() {
        let now = day(2026, 1, 15)
        let r = plan(now)
        XCTAssertLessThanOrEqual(r.count, 64)
        XCTAssertTrue(r.allSatisfy { $0.date > now })
        XCTAssertTrue(r.allSatisfy { cal.component(.hour, from: $0.date) == 16 && cal.component(.minute, from: $0.date) == 30 })
        XCTAssertTrue(r.allSatisfy { $0.date <= cal.date(byAdding: .day, value: 366, to: now)! }, "a year ahead at most")
        XCTAssertEqual(r.map(\.date), r.map(\.date).sorted())
    }

    func testEndingSoonAlwaysAfterItsStart() {
        let r = plan(day(2026, 1, 15))
        for e in r where e.id.hasPrefix("ending-") {
            let startID = "start-" + e.id.dropFirst("ending-".count)
            if let s = r.first(where: { $0.id == startID }) { XCTAssertGreaterThan(e.date, s.date) }
        }
    }

    func testNothingInThePast() {
        let r = plan(day(2026, 10, 1, 17, 0))                                 // Halloween's first day, after 16:30
        XCTAssertNil(r.first { $0.id == "start-halloween-2026" })
        XCTAssertNotNil(r.first { $0.id == "ending-halloween-2026" })
    }

    func testNewYearAcrossTheYearEnd() {
        let r = plan(day(2026, 12, 20))
        XCTAssertEqual(r.first { $0.id == "start-newyear-2026" }?.date, day(2026, 12, 31, 16, 30))
        XCTAssertEqual(r.first { $0.id == "ending-newyear-2026" }?.date, day(2027, 1, 3, 16, 30))
    }

    func testComeBackFourDaysLaterWithThePlayersNextWorld() {
        let p = progress()
        for id in Challenges.mainIDs where id.hasPrefix("w1-") { p.record(id, stars: 3) }
        p.record("w2-1", stars: 2)
        let c = plan(day(2026, 9, 5), lastPlayed: day(2026, 9, 5), p).first { $0.id == "comeback" }
        XCTAssertEqual(c?.date, day(2026, 9, 9, 16, 30))
        XCTAssertEqual(c?.body, "Your marble is waiting: 16 stars left in World 2 ⭐")
    }

    func testComeBackFallbackWhenEveryMainWorldIsFinished() {
        let p = progress()
        for id in Challenges.mainIDs { p.record(id, stars: 3) }
        XCTAssertEqual(plan(day(2026, 9, 5), p).first { $0.id == "comeback" }?.body, "Your marble misses you! Come make some music 🎵")
    }

    func testComeBackDroppedNextToASeasonNotice() {
        let r = plan(day(2026, 9, 27), lastPlayed: day(2026, 9, 27))           // +4 days = Oct 1, Halloween starts
        XCTAssertNil(r.first { $0.id == "comeback" })
    }
}
