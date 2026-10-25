import SwiftUI
import UserNotifications

/// What the scheduler needs from the notification system (a fake stands in for it in tests).
protocol ReminderCenter {
    func status() async -> UNAuthorizationStatus
    func requestAuthorization() async -> Bool
    func replacePending(with requests: [UNNotificationRequest]) async
    func removeAllPending()
}

struct SystemReminderCenter: ReminderCenter {
    private var center: UNUserNotificationCenter { .current() }
    func status() async -> UNAuthorizationStatus { await center.notificationSettings().authorizationStatus }
    func requestAuthorization() async -> Bool { (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false }
    func replacePending(with requests: [UNNotificationRequest]) async {
        center.removeAllPendingNotificationRequests()
        for r in requests { try? await center.add(r) }
    }
    func removeAllPending() { center.removeAllPendingNotificationRequests() }
}

/// Books `Reminders.plan` with iOS and handles permission. Never asks by itself: only the card after the first
/// challenge win and the Account switch do.
@MainActor final class ReminderScheduler: ObservableObject {
    static let shared = ReminderScheduler(center: SystemReminderCenter(), defaults: .standard)

    @Published private(set) var isOn = false
    private let center: ReminderCenter
    private let defaults: UserDefaults
    private let onKey = "notifications.on", askedKey = "notifications.asked"

    init(center: ReminderCenter, defaults: UserDefaults) { self.center = center; self.defaults = defaults }

    private var turnedOff: Bool { defaults.object(forKey: onKey) as? Bool == false }
    private var captures: Bool {
        #if DEBUG
        CaptureMode.current.isActive
        #else
        false
        #endif
    }

    func refresh() async {
        let s = await center.status()
        isOn = !turnedOff && (s == .authorized || s == .provisional)
    }

    /// Replaces everything booked with a fresh plan; the player was last here `now`.
    func reschedule(progress: ChallengeProgress, now: Date = Date()) async {
        await refresh()
        guard isOn, !captures else { return }
        let requests = Reminders.plan(now: now, lastPlayed: now, progress: progress, calendar: .current).map { r in
            let content = UNMutableNotificationContent()
            content.title = r.title; content.body = r.body; content.sound = .default
            let when = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: r.date)
            return UNNotificationRequest(identifier: r.id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false))
        }
        await center.replacePending(with: requests)
    }

    /// Apple's prompt (from the card's "Yes please"); books right away if allowed.
    func askPermission(progress: ChallengeProgress) async {
        if await center.requestAuthorization() { defaults.set(true, forKey: onKey) }
        await reschedule(progress: progress)
    }

    enum TurnOn { case on, openSettings, refused }

    /// The Account switch turned on: ask if never asked, point to Settings if the player said no before.
    func turnOn(progress: ChallengeProgress) async -> TurnOn {
        switch await center.status() {
        case .notDetermined:
            guard await center.requestAuthorization() else { await refresh(); return .refused }
        case .denied:
            return .openSettings
        default: break
        }
        defaults.set(true, forKey: onKey)
        await reschedule(progress: progress)
        return .on
    }

    func turnOff() {
        defaults.set(false, forKey: onKey)
        center.removeAllPending()
        isOn = false
    }

    /// The card shows once per install, after the celebration of a challenge won with at least one star.
    func shouldOffer(after c: Celebration, inChallenge: Bool) -> Bool {
        inChallenge && c.stars > 0 && !defaults.bool(forKey: askedKey) && !captures
    }

    func markOffered() { defaults.set(true, forKey: askedKey) }
}
