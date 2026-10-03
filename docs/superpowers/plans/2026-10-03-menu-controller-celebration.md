# Menu, Pad Controller and Celebration Sticker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a launch menu with the big logo, an on-screen D-pad + rotate-dial pad controller, and an animated star sticker when a song finishes by itself.

**Architecture:** Pure logic (clamping, star rating) lives in `Engine.swift` / `Celebration.swift` and is unit-tested. `GameModel` gains small commands (`nudge`, `rotate`, `setAngle`, `finish`, `chime`). New SwiftUI views (`RootView`, `MenuView`, `PadController`, `CelebrationView`) sit on top; `RunScene` only changes where it calls `stop()` and how it clamps drags.

**Tech Stack:** Swift 5.9, SwiftUI, SpriteKit, AVAudioEngine, XCTest, XcodeGen, iOS 17.

**Spec:** `docs/superpowers/specs/2026-10-03-menu-controller-celebration-design.md`

## Global Constraints

- iOS 17.0 deployment target, Swift 5.9, portrait only (from `project.yml`).
- No new third-party dependencies.
- Pad position clamp: x in [20, 720 − 20], y ≥ 40. Bar angle clamp: ±1.4 rad.
- D-pad: tap = 4 points; hold repeats every 1/30 s, step grows from 4 to 12 points over the first second of repeating.
- Rotate: 5° (0.0873 rad) per tap; hold repeats.
- One press-and-hold or dial drag = one undo step (`mark()` once at start, `save()` at end).
- Star tiers: on-beat ratio ≥ 0.9 → 3, ≥ 0.6 → 2, else 1. Headlines: 3 = "Perfect Rhythm!", "Maestro!", "Superstar!"; 2 = "Groovy!", "Congratulations!", "Great Jam!"; 1 = "You did it!", "Nice Jam!", "Song Complete!".
- Celebration only on natural finish; never on Stop or Menu.
- Reduce Motion: menu marbles static, sticker fades in, no confetti, stars appear together.
- Store / Sign in show "coming soon" toasts only.

Build/test command used throughout (run from repo root):

```bash
xcodegen && xcodebuild test -project MarbleJam.xcodeproj -scheme MarbleJam \
  -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -40
```

## Review Focus

1. Tapping Stop (or ⌂ Menu) mid-song must not show the sticker — test in Task 3 (`testStopDoesNotCelebrate`).
2. Holding a D-pad arrow toward a wall keeps the pad inside the world — test in Task 2 (`testClampPad`, `testNudgeClamps`).
3. Rotate controls on a bumper do nothing (bumpers have no angle) — test in Task 2 (`testRotateIgnoresBumper`).
4. A long hold followed by Undo restores the pad to where it was before the hold, not one step back — test in Task 2 (`testHoldIsOneUndoStep`).
5. "Play again" from the sticker clears it before the new run — test in Task 3 (`testStartClearsCelebration`).

---

### Task 1: Test target and green baseline build

The existing code has never been compiled. This task makes it build and adds a test target.

**Files:**
- Modify: `project.yml`
- Create: `MarbleJamTests/LogicTests.swift`
- Modify (only if the compiler requires): any file in `MarbleJam/`

**Interfaces:**
- Produces: `MarbleJamTests` target, scheme `MarbleJam` that runs tests.

- [ ] **Step 1: Add the test target and scheme to `project.yml`** (append under `targets:` and add a top-level `schemes:`)

```yaml
  MarbleJamTests:
    type: bundle.unit-test
    platform: iOS
    sources: [MarbleJamTests]
    dependencies:
      - target: MarbleJam
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        SWIFT_VERSION: "5.9"
schemes:
  MarbleJam:
    build:
      targets:
        MarbleJam: all
        MarbleJamTests: [test]
    test:
      targets: [MarbleJamTests]
```

- [ ] **Step 2: Add a smoke test** — `MarbleJamTests/LogicTests.swift`

```swift
import XCTest
@testable import MarbleJam

final class LogicTests: XCTestCase {
    func testDemoSongHasNotes() {
        XCTAssertFalse(Engine.simulate(Engine.demo()).hits.isEmpty)
    }
}
```

- [ ] **Step 3: Build and test.** Run the build/test command. Expected on first run: compile errors in existing files.
- [ ] **Step 4: Fix compile errors one at a time with the smallest change that keeps behaviour.** Re-run after each fix. Do not refactor. Expected end state: `** TEST SUCCEEDED **` (or no failures in the `-quiet` output) with `testDemoSongHasNotes` passing.
- [ ] **Step 5: Commit**

```bash
git add project.yml MarbleJamTests MarbleJam
git commit -m "Add test target and fix first-build compile errors"
```

---

### Task 2: Pad clamping helpers and controller commands

**Files:**
- Modify: `MarbleJam/Engine.swift` (`enum Rules`)
- Modify: `MarbleJam/RunScene.swift` (`touchesMoved`, `.move` and `.tilt` cases)
- Modify: `MarbleJam/GameModel.swift`
- Test: `MarbleJamTests/LogicTests.swift`, `MarbleJamTests/ModelTests.swift`

**Interfaces:**
- Produces:
  - `Rules.clampPad(x: Double, y: Double) -> (x: Double, y: Double)`
  - `Rules.clampAngle(_ a: Double) -> Double`
  - `Rules.barAngle(dx: Double, dy: Double) -> Double` — direction folded into [−π/2, π/2] then clamped
  - `Rules.rotateStep: Double` (= 5° in radians)
  - `GameModel.nudge(dx: Double, dy: Double)`, `GameModel.rotate(by: Double)`, `GameModel.setAngle(_: Double)`
  - `GameModel.revealY: Double?` — the scene scrolls only if this y is off screen, then clears it

- [ ] **Step 1: Write failing logic tests** — add to `LogicTests`

```swift
    func testClampPad() {
        XCTAssertEqual(Rules.clampPad(x: -50, y: 10).x, 20)
        XCTAssertEqual(Rules.clampPad(x: -50, y: 10).y, 40)
        XCTAssertEqual(Rules.clampPad(x: 9999, y: 500).x, Rules.width - 20)
        XCTAssertEqual(Rules.clampPad(x: 300, y: 500).y, 500)
    }

    func testClampAngle() {
        XCTAssertEqual(Rules.clampAngle(2), 1.4)
        XCTAssertEqual(Rules.clampAngle(-2), -1.4)
        XCTAssertEqual(Rules.clampAngle(0.3), 0.3)
    }

    func testBarAngleFoldsDirection() {
        XCTAssertEqual(Rules.barAngle(dx: 1, dy: 1), .pi / 4, accuracy: 1e-9)
        XCTAssertEqual(Rules.barAngle(dx: -1, dy: -1), .pi / 4, accuracy: 1e-9)   // opposite end, same tilt
        XCTAssertEqual(Rules.barAngle(dx: -1, dy: 0), 0, accuracy: 1e-9)
        XCTAssertEqual(Rules.barAngle(dx: 0, dy: 1), 1.4, accuracy: 1e-9)           // straight down clamps
    }
```

- [ ] **Step 2: Write failing model tests** — create `MarbleJamTests/ModelTests.swift`

```swift
import XCTest
@testable import MarbleJam

@MainActor
final class ModelTests: XCTestCase {
    private func modelWithBar() -> GameModel {
        let m = GameModel()
        m.loadDemo()
        m.selected = m.course.pads.first { $0.kind == .bar }?.id
        return m
    }

    func testNudgeMovesSelectedPad() {
        let m = modelWithBar(), p = m.selectedPad!
        m.nudge(dx: 4, dy: -4)
        XCTAssertEqual(m.selectedPad!.x, p.x + 4, accuracy: 1e-9)
        XCTAssertEqual(m.selectedPad!.y, p.y - 4, accuracy: 1e-9)
    }

    func testNudgeClamps() {
        let m = modelWithBar()
        for _ in 0..<500 { m.nudge(dx: -12, dy: -12) }
        XCTAssertEqual(m.selectedPad!.x, 20)
        XCTAssertEqual(m.selectedPad!.y, 40)
    }

    func testRotateAndSetAngleClamp() {
        let m = modelWithBar()
        m.setAngle(0)
        m.rotate(by: Rules.rotateStep)
        XCTAssertEqual(m.selectedPad!.angle, Rules.rotateStep, accuracy: 1e-9)
        m.setAngle(3)
        XCTAssertEqual(m.selectedPad!.angle, 1.4)
    }

    func testRotateIgnoresBumper() {
        let m = GameModel()
        m.loadDemo()
        m.addBumper()                        // selects the new bumper
        XCTAssertEqual(m.selectedPad?.kind, .bumper)
        m.rotate(by: 0.5); m.setAngle(1)
        XCTAssertEqual(m.selectedPad!.angle, 0)
    }

    func testHoldIsOneUndoStep() {
        let m = modelWithBar(), id = m.selected, start = m.selectedPad!
        m.mark()                             // what the controller does at the start of a hold
        for _ in 0..<30 { m.nudge(dx: 4, dy: 0) }
        m.undo()
        let back = m.course.pads.first { $0.id == id }!
        XCTAssertEqual(back.x, start.x, accuracy: 1e-9)
    }
}
```

- [ ] **Step 3: Run tests; expect compile failure** ("type 'Rules' has no member 'clampPad'", "no member 'nudge'").

- [ ] **Step 4: Implement helpers** — inside `enum Rules` in `Engine.swift`, after the existing constants:

```swift
    static let rotateStep = 5 * Double.pi / 180

    /// Keeps a pad inside the world, the same limits as dragging.
    static func clampPad(x: Double, y: Double) -> (x: Double, y: Double) { (max(20, min(width - 20, x)), max(40, y)) }
    static func clampAngle(_ a: Double) -> Double { max(-1.4, min(1.4, a)) }

    /// A bar's tilt from a direction (either end works), clamped like the tilt handle.
    static func barAngle(dx: Double, dy: Double) -> Double {
        var a = atan2(dy, dx)
        if a > .pi / 2 { a -= .pi }
        if a < -.pi / 2 { a += .pi }
        return clampAngle(a)
    }
```

- [ ] **Step 5: Use them in `RunScene.touchesMoved`** — replace the `.move` and `.tilt` cases:

```swift
        case let .move(dx, dy):
            m.updateSelected { let c = Rules.clampPad(x: x + dx, y: y + dy); $0.x = c.x; $0.y = c.y }
        case .tilt:
            m.updateSelected { p in p.angle = Rules.barAngle(dx: x - p.x, dy: y - p.y) }
```

- [ ] **Step 6: Add commands to `GameModel`** — after `func setDrop(x:)`:

```swift
    var revealY: Double?                    // the scene scrolls here only if it is off screen, then clears it

    /// Pad controller: move the selected pad, staying inside the world.
    func nudge(dx: Double, dy: Double) {
        updateSelected { let c = Rules.clampPad(x: $0.x + dx, y: $0.y + dy); $0.x = c.x; $0.y = c.y }
        revealY = selectedPad?.y
    }
    /// Pad controller: tilt the selected bar. Bumpers have no angle.
    func rotate(by d: Double) {
        guard selectedPad?.kind == .bar else { return }
        updateSelected { $0.angle = Rules.clampAngle($0.angle + d) }
    }
    func setAngle(_ a: Double) {
        guard selectedPad?.kind == .bar else { return }
        updateSelected { $0.angle = Rules.clampAngle(a) }
    }
```

- [ ] **Step 7: Make the scene follow a nudged pad** — in `RunScene.update`, after the `focusY` line:

```swift
        if let r = m.revealY {
            if r < camY + 60 || r > camY + viewHeight * 0.6 { targetCamY = clampCam(r - viewHeight * 0.4) }   // the tray covers the bottom
            m.revealY = nil
        }
```

- [ ] **Step 8: Run tests; expect all PASS.**
- [ ] **Step 9: Commit**

```bash
git add MarbleJam MarbleJamTests
git commit -m "Add pad clamping helpers and nudge/rotate commands"
```

---

### Task 3: Celebration logic and natural-finish trigger

**Files:**
- Create: `MarbleJam/Celebration.swift`
- Modify: `MarbleJam/GameModel.swift`, `MarbleJam/RunScene.swift` (end-of-run check in `update`)
- Test: `MarbleJamTests/LogicTests.swift`, `MarbleJamTests/ModelTests.swift`

**Interfaces:**
- Produces:
  - `struct Celebration: Equatable { let stars: Int; let headline: String; let notes: Int; let onBeat: Int }`
  - `Celebration.headlines: [Int: [String]]`
  - `Celebration.stars(onBeat: Int, total: Int) -> Int`
  - `Celebration.make(onBeat: Int, total: Int, pick: ([String]) -> String = { $0.randomElement()! }) -> Celebration`
  - `GameModel.celebration: Celebration?` (`@Published`, settable so the view can dismiss)
  - `GameModel.finish()`, `GameModel.chime(_ i: Int)`

- [ ] **Step 1: Failing logic tests** — add to `LogicTests`

```swift
    func testStarTiers() {
        XCTAssertEqual(Celebration.stars(onBeat: 0, total: 0), 1)
        XCTAssertEqual(Celebration.stars(onBeat: 0, total: 10), 1)
        XCTAssertEqual(Celebration.stars(onBeat: 59, total: 100), 1)
        XCTAssertEqual(Celebration.stars(onBeat: 60, total: 100), 2)
        XCTAssertEqual(Celebration.stars(onBeat: 89, total: 100), 2)
        XCTAssertEqual(Celebration.stars(onBeat: 90, total: 100), 3)
        XCTAssertEqual(Celebration.stars(onBeat: 10, total: 10), 3)
    }

    func testHeadlineComesFromTierPool() {
        for (on, tier) in [(10, 3), (7, 2), (1, 1)] {
            for _ in 0..<20 {
                let c = Celebration.make(onBeat: on, total: 10)
                XCTAssertEqual(c.stars, tier)
                XCTAssertTrue(Celebration.headlines[tier]!.contains(c.headline))
                XCTAssertEqual(c.notes, 10); XCTAssertEqual(c.onBeat, on)
            }
        }
    }

    func testPickerChoosesHeadline() {
        XCTAssertEqual(Celebration.make(onBeat: 10, total: 10) { $0.last! }.headline, "Superstar!")
    }
```

- [ ] **Step 2: Failing model tests** — add to `ModelTests`

```swift
    func testFinishCelebrates() {
        let m = GameModel(); m.loadDemo(); m.start()
        m.finish()
        XCTAssertFalse(m.playing)
        XCTAssertNotNil(m.celebration)
        XCTAssertEqual(m.celebration!.notes, m.run.hits.count)
    }

    func testStopDoesNotCelebrate() {
        let m = GameModel(); m.loadDemo(); m.start()
        m.stop()
        XCTAssertNil(m.celebration)
    }

    func testStartClearsCelebration() {
        let m = GameModel(); m.loadDemo(); m.start(); m.finish()
        m.start()
        XCTAssertNil(m.celebration)
    }
```

- [ ] **Step 3: Run tests; expect compile failure** ("cannot find 'Celebration'").

- [ ] **Step 4: Create `MarbleJam/Celebration.swift`**

```swift
import Foundation

/// What the sticker says when a song finishes by itself. Always positive: more notes on the beat earn more stars.
struct Celebration: Equatable {
    let stars: Int
    let headline: String
    let notes: Int
    let onBeat: Int

    static let headlines: [Int: [String]] = [
        3: ["Perfect Rhythm!", "Maestro!", "Superstar!"],
        2: ["Groovy!", "Congratulations!", "Great Jam!"],
        1: ["You did it!", "Nice Jam!", "Song Complete!"],
    ]

    static func stars(onBeat: Int, total: Int) -> Int {
        guard total > 0 else { return 1 }
        let score = Double(onBeat) / Double(total)
        return score >= 0.9 ? 3 : score >= 0.6 ? 2 : 1
    }

    static func make(onBeat: Int, total: Int, pick: ([String]) -> String = { $0.randomElement()! }) -> Celebration {
        let s = stars(onBeat: onBeat, total: total)
        return Celebration(stars: s, headline: pick(headlines[s]!), notes: total, onBeat: onBeat)
    }
}
```

- [ ] **Step 5: Update `GameModel`**
  - Add `@Published var celebration: Celebration?` next to `toast`.
  - In `start()`, set `celebration = nil` as the first line.
  - After `stop()` add:

```swift
    /// The marble reached the end by itself: stop and celebrate.
    func finish() {
        let on = run.hits.filter { Engine.isOnBeat($0.time) }.count
        stop()
        celebration = Celebration.make(onBeat: on, total: run.hits.count)
    }
    /// Rising chime for the sticker's stars (i = 0, 1, 2).
    func chime(_ i: Int) {
        synth.start()
        synth.play(midi: 72 + [0, 4, 7, 12][min(i, 3)], bar: true, gain: 0.3, at: synth.now + 0.02)
    }
```

- [ ] **Step 6: Trigger from the scene** — in `RunScene.update` replace `if t > m.run.duration + 0.7 { m.stop() }` with `if t > m.run.duration + 0.7 { m.finish() }`.
- [ ] **Step 7: Run tests; expect all PASS.**
- [ ] **Step 8: Commit**

```bash
git add MarbleJam MarbleJamTests
git commit -m "Add celebration rating and trigger it on natural finish"
```

---

### Task 4: Pad controller view

**Files:**
- Create: `MarbleJam/PadController.swift`
- Modify: `MarbleJam/ContentView.swift` (tray: replace the selected-pad `HStack`)

**Interfaces:**
- Consumes: `GameModel.nudge`, `rotate(by:)`, `setAngle`, `stepNote`, `deleteSelected`, `mark()`, `save()`, `selected`, `selectedPad`; `Rules.barAngle`, `Rules.rotateStep`; `Chip` button style; `Notes.name`.
- Produces: `struct PadController: View { @ObservedObject var model: GameModel }`, `struct HoldButton<Label: View>: View`.

- [ ] **Step 1: Create `MarbleJam/PadController.swift`**

```swift
import SwiftUI

/// Shown while a pad is selected: D-pad to move, ♭/♯ for the note, a dial to tilt bars.
struct PadController: View {
    @ObservedObject var model: GameModel
    @State private var dialing = false

    private let ink = Color(red: 0.95, green: 0.96, blue: 1)
    private let panel = Color(red: 0.055, green: 0.07, blue: 0.15).opacity(0.9)

    var body: some View {
        if let p = model.selectedPad {
            HStack(alignment: .center, spacing: 14) {
                dpad
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Button("♭") { model.stepNote(-1) }.buttonStyle(Chip())
                        Text(Notes.name(p)).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(ink).frame(minWidth: 40)
                        Button("♯") { model.stepNote(1) }.buttonStyle(Chip())
                    }
                    HStack(spacing: 6) {
                        Button { model.deleteSelected() } label: { Image(systemName: "trash") }.buttonStyle(Chip())
                        Button("✓ Done") { model.selected = nil }.buttonStyle(Chip())
                    }
                }
                dial(enabled: p.kind == .bar, angle: p.angle)
            }
        }
    }

    // MARK: D-pad

    private var dpad: some View {
        VStack(spacing: 2) {
            arrow("chevron.up", 0, -1)
            HStack(spacing: 2) {
                arrow("chevron.left", -1, 0)
                Circle().fill(ink.opacity(0.25)).frame(width: 10, height: 10).frame(width: 38, height: 38)
                arrow("chevron.right", 1, 0)
            }
            arrow("chevron.down", 0, 1)
        }
    }

    /// Tap moves 4 points; after a short hold it keeps sliding, speeding up to 12 points a tick.
    private func arrow(_ icon: String, _ ux: Double, _ uy: Double) -> some View {
        HoldButton(onBegin: { model.mark() }, onEnd: { model.save() }, onTick: { n in
            guard n == 0 || n >= 9 else { return }
            let step = n == 0 ? 4 : min(12, 4 + 8 * Double(n - 9) / 30)
            model.nudge(dx: ux * step, dy: uy * step)
        }) {
            Image(systemName: icon).font(.system(size: 16, weight: .heavy)).foregroundStyle(ink)
                .frame(width: 38, height: 38)
                .background(panel, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.18)))
        }
    }

    // MARK: rotate dial

    private func dial(enabled: Bool, angle: Double) -> some View {
        let size = 72.0
        return VStack(spacing: 6) {
            ZStack {
                Circle().fill(panel).overlay(Circle().stroke(Color.white.opacity(0.18)))
                Capsule().fill(Color.cyan).frame(width: size * 0.7, height: 6).rotationEffect(.radians(angle))
                Circle().fill(.white).frame(width: 10, height: 10)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                if !dialing { dialing = true; model.mark() }
                model.setAngle(Rules.barAngle(dx: v.location.x - size / 2, dy: v.location.y - size / 2))
            }.onEnded { _ in dialing = false; model.save() })
            HStack(spacing: 6) {
                spin("arrow.counterclockwise", -1)
                spin("arrow.clockwise", 1)
            }
        }
        .opacity(enabled ? 1 : 0.35)
        .disabled(!enabled)
    }

    /// 5° per tap; repeats while held.
    private func spin(_ icon: String, _ dir: Double) -> some View {
        HoldButton(onBegin: { model.mark() }, onEnd: { model.save() }, onTick: { n in
            if n == 0 || (n >= 9 && n % 3 == 0) { model.rotate(by: dir * Rules.rotateStep) }
        }) {
            Image(systemName: icon).font(.system(size: 13, weight: .heavy)).foregroundStyle(ink)
                .frame(width: 33, height: 30)
                .background(panel, in: RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(0.18)))
        }
    }
}

/// A button that fires `onTick(0)` on touch-down, then `onTick(1, 2, ...)` every 1/30 s until released.
struct HoldButton<Label: View>: View {
    var onBegin: () -> Void = {}
    var onEnd: () -> Void = {}
    let onTick: (Int) -> Void
    @ViewBuilder let label: () -> Label
    @State private var task: Task<Void, Never>?
    @Environment(\.isEnabled) private var enabled

    var body: some View {
        label()
            .opacity(task == nil ? 1 : 0.7)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard task == nil, enabled else { return }
                    onBegin()
                    task = Task { @MainActor in
                        var n = 0
                        while !Task.isCancelled {
                            onTick(n); n += 1
                            try? await Task.sleep(nanoseconds: 33_000_000)
                        }
                    }
                }
                .onEnded { _ in stop() })
            .onDisappear { stop() }
    }

    private func stop() {
        guard let t = task else { return }
        t.cancel(); task = nil; onEnd()
    }
}
```

- [ ] **Step 2: Use it in `ContentView.tray`** — replace the whole `if let p = model.selectedPad, !model.playing { HStack { ... } .buttonStyle(Chip()) }` block with:

```swift
            if model.selectedPad != nil, !model.playing {
                PadController(model: model)
            }
```

  and update the bar hint text in `hint` to: `"Use the arrows to move and the dial to tilt, or drag it. Size sets the note."` (bumper: `"Use the arrows to move, or drag it. Size sets the note."`).

- [ ] **Step 3: Build and run tests** (build/test command). Expected: build succeeds, all tests PASS.
- [ ] **Step 4: Manual check in the simulator:** select a bar → tap ▲ moves it slightly, holding ▶ slides and accelerates and stops at the wall, ⟳ tilts clockwise, dial drag tilts, Undo after a hold returns the pad to its start; select a bumper → dial greyed out.
- [ ] **Step 5: Commit**

```bash
git add MarbleJam
git commit -m "Add D-pad and rotate dial pad controller"
```

---

### Task 5: Celebration sticker view

**Files:**
- Create: `MarbleJam/CelebrationView.swift`
- Modify: `MarbleJam/ContentView.swift` (overlay in `body`'s `ZStack`)

**Interfaces:**
- Consumes: `Celebration`, `GameModel.celebration`, `GameModel.chime(_:)`, `GameModel.start()`, `Notes.hues`, `Chip`.
- Produces: `struct CelebrationView: View { let celebration: Celebration; let chime: (Int) -> Void; let onPlayAgain: () -> Void; let onDismiss: () -> Void }`

- [ ] **Step 1: Create `MarbleJam/CelebrationView.swift`**

```swift
import SwiftUI

/// The "You did it!" sticker: slams in with a springy tilt, stars pop with chimes, confetti bursts.
struct CelebrationView: View {
    let celebration: Celebration
    let chime: (Int) -> Void
    let onPlayAgain: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var starsShown = 0
    @State private var burst: Date?

    var body: some View {
        ZStack {
            Color.black.opacity(shown ? 0.45 : 0).ignoresSafeArea().onTapGesture(perform: onDismiss)
            if let b = burst { Confetti(start: b).allowsHitTesting(false) }
            sticker
                .scaleEffect(reduceMotion ? 1 : (shown ? 1 : 0.2))
                .rotationEffect(.degrees(reduceMotion ? -6 : (shown ? -6 : -25)))
                .opacity(shown ? 1 : 0)
        }
        .task { await play() }
    }

    private var sticker: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < celebration.stars ? "star.fill" : "star")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(i < celebration.stars ? Color.yellow : Color.white.opacity(0.5))
                        .scaleEffect(i < starsShown ? 1 : 0.01)
                        .animation(.spring(response: 0.3, dampingFraction: 0.45), value: starsShown)
                }
            }
            Text(celebration.headline)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: 3)
                .multilineTextAlignment(.center)
            Text("\(celebration.notes) notes · \(celebration.onBeat) on the beat")
                .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.9))
            HStack(spacing: 8) {
                Button("Keep editing", action: onDismiss).buttonStyle(Chip())
                Button("Play again ▶", action: onPlayAgain).buttonStyle(Chip(primary: true))
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 26).padding(.vertical, 22)
        .background(LinearGradient(colors: [.purple, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white, lineWidth: 7))       // die-cut border
        .shadow(color: .black.opacity(0.5), radius: 18, y: 10)
        .padding(24)
    }

    private func play() async {
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.3)) { shown = true }
            starsShown = 3
            for i in 0..<celebration.stars { chime(i) }
            return
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { shown = true }
        try? await Task.sleep(nanoseconds: 350_000_000)
        burst = Date()
        for i in 0..<3 {
            starsShown = i + 1
            if i < celebration.stars { chime(i) }
            try? await Task.sleep(nanoseconds: 180_000_000)
        }
    }
}

/// A one-shot burst of coloured pieces in the note hues, falling and fading over 1.5 s.
private struct Confetti: View {
    let start: Date
    @State private var pieces: [(vx: Double, vy: Double, spin: Double, hue: Double)] = (0..<70).map { _ in
        (Double.random(in: -320...320), Double.random(in: -620 ... -220), Double.random(in: -8...8),
         Notes.hues.randomElement()! / 360)
    }

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSince(start)
                guard t < 1.5 else { return }
                let cx = size.width / 2, cy = size.height * 0.42
                for p in pieces {
                    let x = cx + p.vx * t, y = cy + p.vy * t + 0.5 * 900 * t * t
                    var c = ctx
                    c.translateBy(x: x, y: y); c.rotate(by: .radians(p.spin * t))
                    c.opacity = max(0, 1 - t / 1.5)
                    c.fill(Path(CGRect(x: -5, y: -3, width: 10, height: 6)),
                           with: .color(Color(hue: p.hue, saturation: 0.82, brightness: 1)))
                }
            }
        }
        .ignoresSafeArea()
    }
}
```

- [ ] **Step 2: Show it from `ContentView`** — inside the `body` `ZStack`, after the toast block:

```swift
            if let c = model.celebration {
                CelebrationView(celebration: c, chime: model.chime,
                                onPlayAgain: { model.celebration = nil; model.start() },
                                onDismiss: { model.celebration = nil })
                    .transition(.opacity)
            }
```

- [ ] **Step 3: Build and run tests.** Expected: all PASS.
- [ ] **Step 4: Manual check:** Demo → Drop → wait for the end → sticker springs in, stars pop with rising chimes, confetti; Play again restarts; Keep editing and backdrop tap dismiss. Drop then Stop mid-song → no sticker. Settings → Accessibility → Reduce Motion on → sticker fades, no confetti.
- [ ] **Step 5: Commit**

```bash
git add MarbleJam
git commit -m "Add animated celebration sticker"
```

---

### Task 6: Main menu, logo and navigation

**Files:**
- Modify: `tools/make_icon.swift` (write a second copy as the logo)
- Create: `MarbleJam/Assets.xcassets/Logo.imageset/Contents.json`, `Logo.png` (generated)
- Create: `MarbleJam/RootView.swift`, `MarbleJam/MenuView.swift`
- Modify: `MarbleJam/MarbleJamApp.swift`, `MarbleJam/ContentView.swift`, `README.md`

**Interfaces:**
- Consumes: `GameModel`, `GameModel.loadDemo()`, `stop()`, `save()`, `Chip`, `Notes.hues`.
- Produces: `RootView`, `MenuView(onPlay:onDemo:)`, `ContentView(model:onMenu:)`, `struct Toast: View { let text: String }`.

- [ ] **Step 1: Logo asset.** In `tools/make_icon.swift`, replace the last five lines (from `try? FileManager...` to `print`) with:

```swift
let logo = "MarbleJam/Assets.xcassets/Logo.imageset/Logo.png"
let image = ctx.makeImage()!
for path in [out, logo] {
    try? FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(path)")
}
```

  Create `MarbleJam/Assets.xcassets/Logo.imageset/Contents.json`:

```json
{
  "images" : [ { "filename" : "Logo.png", "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

  Run `swift tools/make_icon.swift`. Expected: two "wrote" lines; `git diff --stat` shows AppIcon.png unchanged or byte-identical in content.

- [ ] **Step 2: Shared toast** — in `ContentView.swift`, add at the bottom and use it for the existing toast:

```swift
/// Short message that fades out after a moment.
struct Toast: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Color(red: 0.95, green: 0.96, blue: 1))
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color(red: 0.03, green: 0.035, blue: 0.075).opacity(0.9), in: RoundedRectangle(cornerRadius: 14))
    }
}
```

  The existing block becomes `if let t = model.toast { Toast(text: t).task(id: t) { try? await Task.sleep(nanoseconds: 2_600_000_000); model.toast = nil } }`.

- [ ] **Step 3: `ContentView` takes the model and a menu callback.** Replace `@StateObject private var model = GameModel()` with:

```swift
    @ObservedObject var model: GameModel
    let onMenu: () -> Void
```

  Remove `.preferredColorScheme(.dark)` from `ContentView` (RootView sets it). Shift the header text right with `.padding(.leading, 52)` on the header's inner `VStack` and add the menu button as its own layer in the `ZStack`, right after the `VStack(spacing: 0) { header; Spacer(); tray }` line:

```swift
            VStack {
                HStack {
                    Button(action: onMenu) {
                        Image(systemName: "house.fill").font(.system(size: 16, weight: .heavy))
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(Chip())
                    .accessibilityLabel("Menu")
                    Spacer()
                }
                Spacer()
            }
            .padding(.horizontal, 12).padding(.top, 4)
```

- [ ] **Step 4: Create `MarbleJam/RootView.swift`**

```swift
import SwiftUI

/// Switches between the start menu and the game. Owns the one GameModel so the course survives the trip.
struct RootView: View {
    enum Screen { case menu, play }
    @StateObject private var model = GameModel()
    @State private var screen = Screen.menu

    var body: some View {
        ZStack {
            switch screen {
            case .menu:
                MenuView(onPlay: { screen = .play }, onDemo: { model.loadDemo(); screen = .play })
                    .transition(.opacity)
            case .play:
                ContentView(model: model, onMenu: { model.stop(); model.save(); screen = .menu })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screen)
        .preferredColorScheme(.dark)
    }
}
```

- [ ] **Step 5: Create `MarbleJam/MenuView.swift`**

```swift
import SwiftUI

/// Start screen: big logo, the name, and the main buttons. Marbles drift in the background.
struct MenuView: View {
    let onPlay: () -> Void
    let onDemo: () -> Void
    @State private var toast: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let night = Color(red: 0.03, green: 0.035, blue: 0.075)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.09, green: 0.11, blue: 0.25), night], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            DriftingMarbles(paused: reduceMotion).ignoresSafeArea().allowsHitTesting(false)
            VStack(spacing: 18) {
                Spacer()
                Image("Logo").resizable().scaledToFit().frame(width: 190, height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                    .shadow(color: .cyan.opacity(0.55), radius: 30)
                    .accessibilityHidden(true)
                Text("Marble Jam")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.cyan, .purple, .pink, .orange], startPoint: .leading, endPoint: .trailing))
                Spacer()
                VStack(spacing: 12) {
                    Button("Play ▶", action: onPlay).buttonStyle(Chip(primary: true)).scaleEffect(1.25).padding(.bottom, 6)
                    Button("Demo Song", action: onDemo).buttonStyle(Chip())
                    HStack(spacing: 10) {
                        Button("Store") { toast = "Store is coming soon" }.buttonStyle(Chip())
                        Button("Sign in") { toast = "Sign in is coming soon" }.buttonStyle(Chip())
                    }
                }
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            if let t = toast {
                VStack { Spacer(); Toast(text: t).padding(.bottom, 12) }
                    .task(id: t) { try? await Task.sleep(nanoseconds: 2_000_000_000); toast = nil }
            }
        }
    }
}

/// A few glowing marbles in the note colours, floating slowly.
private struct DriftingMarbles: View {
    let paused: Bool
    var body: some View {
        TimelineView(.animation(paused: paused)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                for (i, hue) in Notes.hues.enumerated() {
                    let k = Double(i)
                    let x = size.width * (0.5 + 0.42 * sin(t * (0.07 + 0.013 * k) + k * 1.7))
                    let y = size.height * (0.5 + 0.45 * cos(t * (0.05 + 0.011 * k) + k * 2.3))
                    let r = 10 + 4 * Double(i % 3)
                    let color = Color(hue: hue / 360, saturation: 0.82, brightness: 1)
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r * 2.5, y: y - r * 2.5, width: r * 5, height: r * 5)), with: .color(color.opacity(0.12)))
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(color.opacity(0.75)))
                }
            }
        }
    }
}
```

- [ ] **Step 6: App entry** — in `MarbleJamApp.swift` change `WindowGroup { ContentView() }` to `WindowGroup { RootView() }`.
- [ ] **Step 7: README** — in `README.md` "Files" list add:

```
- `RootView.swift`    switches between the menu and the game
- `MenuView.swift`    start screen: logo, Play, Demo, Store/Sign in (coming soon)
- `PadController.swift` D-pad and rotate dial for the selected pad
- `Celebration.swift` / `CelebrationView.swift` star rating and the end-of-song sticker
```

  Change the status line to say it builds with `xcodegen && xcodebuild`, and change "Next steps" to start with "Login and store (Project B)".

- [ ] **Step 8: Build and run tests.** Expected: all PASS.
- [ ] **Step 9: Manual check:** launch → menu with logo, title, drifting marbles; Play opens saved course; ⌂ returns to menu (stops a playing song, no sticker); Demo Song loads demo; Store / Sign in show toasts.
- [ ] **Step 10: Commit**

```bash
git add tools MarbleJam README.md
git commit -m "Add start menu with logo and navigation"
```

---

### Task 7: Final verification

- [ ] **Step 1:** Run the build/test command from a clean state (`rm -rf MarbleJam.xcodeproj && xcodegen` first). Expected: all tests PASS.
- [ ] **Step 2:** Boot the simulator, install and launch; take screenshots of the menu, the controller with a bar selected, and the sticker:

```bash
xcrun simctl boot "iPhone 17" || true
xcodebuild -project MarbleJam.xcodeproj -scheme MarbleJam -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build -quiet build
xcrun simctl install "iPhone 17" build/Build/Products/Debug-iphonesimulator/MarbleJam.app
xcrun simctl launch "iPhone 17" com.example.marblejam
xcrun simctl io "iPhone 17" screenshot build/menu.png
```

- [ ] **Step 3:** Walk the Review Focus list by hand in the simulator and note any deviation.
