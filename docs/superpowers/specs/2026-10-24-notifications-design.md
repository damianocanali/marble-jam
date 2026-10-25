# Notifications: design

Date: 2026-10-24. Approved in chat.

## Goal

Bring players back to Marble Beats with a few friendly, local notifications: when holiday content arrives, before
it leaves, and after a few days away. Family audience, so: few messages, never at night, never about purchases.

## What is sent

All notifications are local (`UNUserNotificationCenter`), booked by the app. No server, no push, nothing leaves the
phone. Every notification fires at **16:30 local time**.

| Kind | When | Text (example) | Skipped when |
|------|------|----------------|--------------|
| Season start | first day of each season window | "🎃 Halloween is here! New songs and 6 spooky levels." | — |
| Ending soon | 3 days before the window's last day | "Last few days for the Halloween levels 🎃" | the player has a star on every level of that holiday, or it would fall on or before the season start (short windows) |
| Come-back | 4 days after the app last went to the background | "Your marble is waiting: 3 stars left in World 4 ⭐" (fallback: "Your marble misses you! Come make some music 🎵") | a season notification is within 1 day of it |

- Text comes from each `Season`'s `title` and `emoji` and the holiday's level count, so new seasons need no extra work.
- Come-back: the personal line uses the first unfinished main world (the lowest world with levels lacking stars)
  and how many stars are still missing there; if every main world is finished, the fallback text.
- At most ~3 notifications a month.

## Opt-in

- **Card after the first challenge win.** After the celebration for the player's first finished challenge (any
  challenge, first time ever), a small card: "Want a heads-up when holiday songs arrive?" with **Yes please** and
  **Not now**. Shown once per install (`UserDefaults` flag).
- **Yes please** calls `requestAuthorization(options: [.alert, .sound])`; then books notifications if granted.
  **Not now** doesn't call it, so Apple's one-time prompt is still unused.
- **Account screen switch "Notifications".** Off → on: if never asked, Apple's prompt; if denied before, opens
  the app's page in Settings. On → off: removes all pending notifications and remembers the choice
  (`notifications.on` = false). The switch shows on only when both iOS allows it and the player hasn't turned it off.
- DEBUG capture launches (`CaptureMode.isActive`) never show the card and never book anything.

## How it is built

- **`MarbleJam/Reminders.swift`**
  - `struct Reminder { id: String; date: DateComponents; title: String; body: String }`
  - `enum Reminders { static func plan(now: Date, lastPlayed: Date, progress: ChallengeProgress, calendar: Calendar) -> [Reminder] }`:
    pure; season starts and ending-soon notices for windows that start or end within the next 12 months and after
    `now`, plus one come-back; sorted by date; never more than 64.
  - `final class ReminderScheduler`: wraps `UNUserNotificationCenter` (injectable protocol for tests);
    `reschedule(progress:)` removes all pending requests and adds the plan, only when authorized and
    `notifications.on` isn't false; `askPermission() async -> Bool`.
- **`RootView`**: on `.background`, `scheduler.reschedule(progress:)` (lastPlayed = now). Owns the scheduler.
- **Card**: a small view shown by `ContentView` after the first-win celebration closes; flag `notifications.asked`.
- **`AccountView`**: the switch.
- **Privacy**: the privacy manifest and "Data Not Collected" are unchanged. Add one sentence to
  `PrivacyPolicy.swift` and to the site's privacy page (gh-pages): "If you turn on reminders, they are made on your
  device; nothing is sent anywhere."

## Testing

Unit tests on `Reminders.plan` with fixed dates and a fixed calendar:
- a season start and an ending-soon for a window in the next 12 months, at 16:30;
- ending-soon skipped when the holiday's levels all have a star;
- the come-back is 4 days after lastPlayed, and dropped when a season notice falls within 1 day of it;
- personal come-back text for a partly finished world, fallback when all are finished;
- never more than 64, nothing in the past.

Scheduler tests with a fake notification center: nothing booked when not authorized or turned off; pending ones
replaced on reschedule. Card logic: shows once, only after a win, never in capture mode.

## Out of scope

Push notifications, notification settings per kind, daily challenges, purchase or store messages.
