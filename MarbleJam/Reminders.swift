import Foundation

/// A local notification to book: when, and what it says.
struct Reminder: Equatable {
    let id: String
    let date: Date
    let title: String
    let body: String
}

/// Works out the notifications for the next year: each holiday's start, a few days before it ends, and one come-back
/// nudge after a few days away. Pure, so it can be tested with fixed dates.
enum Reminders {
    static let hour = 16, minute = 30, endingDaysBefore = 3, comeBackAfterDays = 4

    static func plan(now: Date, lastPlayed: Date, progress: ChallengeProgress, calendar: Calendar) -> [Reminder] {
        let horizon = calendar.date(byAdding: .day, value: 366, to: now)!
        let done = progress.holidaysDone()
        func at(_ d: Date) -> Date { calendar.date(bySettingHour: hour, minute: minute, second: 0, of: d)! }
        var seasonal: [Reminder] = []
        let year = calendar.component(.year, from: now)
        for s in Seasons.all {
            for y in (year - 1)...(year + 1) {
                let w = s.window(y, calendar)
                let start = at(w.first), ending = at(calendar.date(byAdding: .day, value: -endingDaysBefore, to: w.last)!)
                let levels = Challenges.holidayIDs(s.id).count
                seasonal.append(Reminder(id: "start-\(s.id)-\(y)", date: start, title: s.banner, body: "New songs and \(levels) holiday levels."))
                if ending > start, !done.contains(s.id) {
                    seasonal.append(Reminder(id: "ending-\(s.id)-\(y)", date: ending, title: "\(s.emoji) \(s.title)",
                                             body: "Last few days for the \(s.title) levels \(s.emoji)"))
                }
            }
        }
        seasonal = seasonal.filter { $0.date > now && $0.date <= horizon }
        var all = seasonal
        let back = at(calendar.date(byAdding: .day, value: comeBackAfterDays, to: lastPlayed)!)
        if back > now, !seasonal.contains(where: { abs($0.date.timeIntervalSince(back)) <= 24 * 3600 }) {
            all.append(Reminder(id: "comeback", date: back, title: "Marble Beats", body: comeBackText(progress)))
        }
        return Array(all.sorted { $0.date < $1.date }.prefix(64))
    }

    /// Names the first main world with stars still to win, or a general nudge when they're all won.
    static func comeBackText(_ progress: ChallengeProgress) -> String {
        for w in 1...5 {
            let ids = Challenges.mainIDs.filter { $0.hasPrefix("w\(w)-") }
            let left = ids.count * 3 - progress.totalStars(ids: ids)
            if left > 0 { return "Your marble is waiting: \(left) \(left == 1 ? "star" : "stars") left in World \(w) ⭐" }
        }
        return "Your marble misses you! Come make some music 🎵"
    }
}
