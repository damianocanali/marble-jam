import XCTest
import UserNotifications
@testable import MarbleJam

final class FakeCenter: ReminderCenter {
    var current: UNAuthorizationStatus = .authorized
    var grant = true
    var pending: [UNNotificationRequest] = []
    var asked = 0
    func status() async -> UNAuthorizationStatus { current }
    func requestAuthorization() async -> Bool { asked += 1; current = grant ? .authorized : .denied; return grant }
    func replacePending(with r: [UNNotificationRequest]) async { pending = r }
    func removeAllPending() { pending = [] }
}

@MainActor final class ReminderSchedulerTests: XCTestCase {
    private func defaults() -> UserDefaults { let n = "test.\(UUID())"; let d = UserDefaults(suiteName: n)!; d.removePersistentDomain(forName: n); return d }
    private func progress() -> ChallengeProgress { ChallengeProgress(defaults: defaults()) }
    private let win = Celebration(stars: 2, headline: "Yay", notes: 10, onBeat: 9)

    func testBooksThePlanWhenAllowed() async {
        let c = FakeCenter(), s = ReminderScheduler(center: c, defaults: defaults())
        let sept5 = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 5, hour: 12))!   // no holiday near the come-back
        await s.reschedule(progress: progress(), now: sept5)
        XCTAssertFalse(c.pending.isEmpty)
        XCTAssertTrue(c.pending.contains { $0.identifier == "comeback" })
        let t = c.pending.first?.trigger as? UNCalendarNotificationTrigger
        XCTAssertEqual(t?.dateComponents.hour, 16); XCTAssertEqual(t?.dateComponents.minute, 30)
    }

    func testNothingBookedWithoutPermission() async {
        let c = FakeCenter(); c.current = .notDetermined
        await ReminderScheduler(center: c, defaults: defaults()).reschedule(progress: progress())
        XCTAssertTrue(c.pending.isEmpty)
        XCTAssertEqual(c.asked, 0, "booking never asks; only the card or the switch does")
    }

    func testNothingBookedWhenTurnedOff() async {
        let c = FakeCenter(), s = ReminderScheduler(center: c, defaults: defaults())
        s.turnOff()
        await s.reschedule(progress: progress())
        XCTAssertTrue(c.pending.isEmpty)
        await s.refresh()
        XCTAssertFalse(s.isOn)
    }

    func testRescheduleReplacesPending() async {
        let c = FakeCenter(), s = ReminderScheduler(center: c, defaults: defaults())
        await s.reschedule(progress: progress())
        let first = c.pending.count
        await s.reschedule(progress: progress())
        XCTAssertEqual(c.pending.count, first)
    }

    func testTurningOnAsksOnceThenSendsToSettingsAfterANo() async {
        let c = FakeCenter(); c.current = .notDetermined; c.grant = false
        let s = ReminderScheduler(center: c, defaults: defaults())
        let first = await s.turnOn(progress: progress())
        XCTAssertEqual(first, .refused)
        let second = await s.turnOn(progress: progress())
        XCTAssertEqual(second, .openSettings)
        XCTAssertEqual(c.asked, 1)
    }

    func testTurningOnAfterTurningOffBooksAgain() async {
        let c = FakeCenter(), s = ReminderScheduler(center: c, defaults: defaults())
        s.turnOff()
        let r = await s.turnOn(progress: progress())
        XCTAssertEqual(r, .on)
        XCTAssertFalse(c.pending.isEmpty)
        XCTAssertTrue(s.isOn)
    }

    func testOfferOnlyOnceAfterAChallengeWin() {
        let s = ReminderScheduler(center: FakeCenter(), defaults: defaults())
        XCTAssertFalse(s.shouldOffer(after: win, inChallenge: false), "not after Open Play")
        XCTAssertFalse(s.shouldOffer(after: Celebration(stars: 0, headline: "", notes: 1, onBeat: 0), inChallenge: true), "not without a star")
        XCTAssertTrue(s.shouldOffer(after: win, inChallenge: true))
        s.markOffered()
        XCTAssertFalse(s.shouldOffer(after: win, inChallenge: true))
    }
}
