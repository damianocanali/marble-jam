# Menu, Pad Controller and Celebration Sticker — Design

Date: 2026-10-03 · Project A of two (Project B: login + store, separate spec)

## Goal

Make Marble Jam feel like a finished game for families / all ages:
a proper start menu, an easier way to adjust pads than dragging, and a rewarding moment when a song finishes.

## Decisions (from brainstorming)

- Audience: families / all ages. Playful look; standard login later (Project B) with a parental gate on purchases.
- Order: this project first; Store and Sign in appear on the menu as "coming soon".
- Pad controller layout: D-pad + rotate dial.
- Sticker text: chosen by rhythm score (star tiers), random headline within the tier, always positive.

## 1. Main menu

- New `RootView` owns a `screen` state: `.menu` or `.play`. `MarbleJamApp` shows `RootView`. The app launches on `.menu`.
- The `GameModel` is created once in `RootView` and passed to the game screen (`ContentView`), so returning to the menu keeps the course.
- `MenuView` (new file `MenuView.swift`):
  - Big logo at the top: new `Logo` image set in `Assets.xcassets`, written by `tools/make_icon.swift` alongside the app icon (same artwork, transparent rounded corners not required — shown clipped to a rounded rectangle).
  - Below it, "Marble Jam" in large heavy rounded type with the existing cyan → purple → pink → orange gradient.
  - Background: night colour with a few softly glowing marbles in the note colours drifting slowly (SwiftUI `TimelineView`; static when Reduce Motion is on).
  - Buttons (existing `Chip` style, larger):
    - **Play** — opens the game with the saved course.
    - **Demo Song** — loads the demo, then opens the game.
    - **Store** — shows a "Store is coming soon" toast.
    - **Sign in** — shows a "Sign in is coming soon" toast.
- Game header gets a **⌂** menu button (top-left). Tapping it stops playback, saves, and returns to the menu. The header currently ignores touches; only the button becomes hit-testable.

## 2. Pad controller

New file `PadController.swift`. Shown in the tray when a pad is selected and not playing; replaces the current Longer/Shorter/Delete row.

Layout (left → middle → right):

- **D-pad**: ▲ ◀ ▶ ▼ around a centre dot.
  - Tap: moves the pad 4 points in that direction.
  - Hold: repeats every 1/30 s; step grows from 4 to 12 points over the first second.
  - Clamped like dragging: x in [20, width − 20], y ≥ 40.
- **Middle**: ♭ [note name] ♯ (same as today's Longer/Shorter), then 🗑 Delete and ✓ Done (deselects).
- **Rotate dial** (bars only; dimmed and disabled for bumpers):
  - ⟲ / ⟳ buttons: 5° (0.0873 rad) per tap; hold repeats.
  - Dragging around the dial sets the angle directly from the finger's angle relative to the dial centre.
  - Clamped to ±1.4 rad, same as the tilt handle.
- Undo: each press-and-hold or dial drag calls `mark()` once at the start, so one gesture = one undo step. Saves at the end of the gesture.
- If a nudged pad leaves the visible area, the camera follows it (set `focusY`).
- Drag-to-move and the white tilt handle keep working.

`GameModel` additions:

- `nudge(dx: Double, dy: Double)` — moves the selected pad with clamping.
- `rotate(by: Double)` and `setAngle(_ a: Double)` — bars only, with clamping.
- Clamp logic lives in pure static helpers (`Rules.clampPad(x:y:)`, `Rules.clampAngle(_:)`) so the scene's drag code and the controller share them and tests can call them.

## 3. Celebration sticker

New file `CelebrationView.swift`.

- Trigger: only when the run finishes by itself. `RunScene.update` currently calls `m.stop()` when `t > duration + 0.7`; it will call `m.finish()` instead. `finish()` stops playback and sets `celebration`. Tapping Stop does not celebrate.
- `Celebration` value (pure, in `GameModel.swift` or its own small enum): `stars: Int` (1–3) and `headline: String`.
  - Score = on-beat hits / total hits.
  - ≥ 0.9 → 3 stars; headlines: "Perfect Rhythm!", "Maestro!", "Superstar!"
  - ≥ 0.6 → 2 stars; headlines: "Groovy!", "Congratulations!", "Great Jam!"
  - otherwise → 1 star; headlines: "You did it!", "Nice Jam!", "Song Complete!"
  - Headline chosen at random within the tier (random source injectable for tests).
- Visual: centred sticker card — bright gradient fill, thick white "die-cut" border, drop shadow, slight −6° tilt. Subline shows "N notes · M on the beat".
- Motion:
  1. Sticker enters from scale 0.2, rotation −25°, with a bouncy spring overshoot to scale 1, rotation −6°.
  2. Stars pop in one at a time (0.18 s apart), each with a chime from `Synth` (rising notes).
  3. Confetti burst of small coloured pieces in the note hues, falling and fading over ~1.5 s.
  - Reduce Motion: plain fade-in, no confetti, stars appear together.
- Buttons: **Play again** (dismiss + start) and **Keep editing** (dismiss). Tapping the dimmed backdrop also dismisses.

## Files

- New: `RootView.swift`, `MenuView.swift`, `PadController.swift`, `CelebrationView.swift`, `MarbleJamTests/LogicTests.swift`, `Assets.xcassets/Logo.imageset/`.
- Changed: `MarbleJamApp.swift`, `ContentView.swift`, `GameModel.swift`, `RunScene.swift`, `Engine.swift` (clamp helpers), `tools/make_icon.swift`, `project.yml` (test target), `README.md`.

## Testing

- Add a `MarbleJamTests` unit-test target in `project.yml`.
- Unit tests: star tiers at the boundaries (0, 0.59, 0.6, 0.89, 0.9, 1.0; zero hits), headline belongs to the tier's pool, `clampPad`, `clampAngle`.
- Build with `xcodegen` + `xcodebuild` for the iOS simulator and run the tests; fix compile errors (the existing code has never been compiled).
- Manual check in the simulator: menu → play → select pad → controller works → drop → sticker appears on natural finish, not on Stop.

## Out of scope

Login, accounts, cloud saves, store, currency, saving best scores — Project B.
