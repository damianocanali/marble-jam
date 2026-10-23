# Five New Holidays Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add New Year's Eve, Valentine's Day, St. Patrick's Day, Easter and Día de los Muertos as full holidays: dates, look, icon, title, background, three songs, a 6-level challenge world, a reward marble and a Game Center achievement each.

**Architecture:** Everything keys off a season id (`newyear`, `valentines`, `stpatricks`, `easter`, `muertos`). Each part (songs, theme, icon, title, background, skin, world) is added for those ids first, each with its own test listing the five ids; the last task adds the five `Season`s with their dates, at which point every existing test that loops over `Seasons.all` covers them too.

**Tech Stack:** Swift 5.9, SwiftUI/SpriteKit/SceneKit iOS app, XcodeGen (`project.yml` → `xcodegen`), XCTest, Swift scripts in `tools/`.

**Spec:** `docs/superpowers/specs/2026-10-21-new-holidays-design.md`

## Global Constraints

- Season ids exactly: `newyear`, `valentines`, `stpatricks`, `easter`, `muertos`. Append new seasons after the existing three in `Seasons.all` (level lists use `Seasons.all[0...2]`).
- Windows (both days included): Christmas Dec 1 – Dec 30; New Year's Eve Dec 31 – Jan 6; Valentine's Feb 1 – Feb 14; St. Patrick's Mar 1 – Mar 17; Easter max(Easter Sunday − 14 days, Mar 18) – Easter Monday; Halloween Oct 1 – Oct 31; Día de los Muertos Nov 1 – Nov 7; Thanksgiving Nov 8 – the day after Thanksgiving.
- Titles/emoji/banners: "New Year's Eve" 🎆 "🎆 Happy New Year!"; "Valentine's Day" 💘 "💘 Happy Valentine's Day!"; "St. Patrick's Day" ☘️ "☘️ Happy St. Patrick's Day!"; "Easter" 🐣 "🐣 Happy Easter!"; "Día de los Muertos" 🌼 "🌼 ¡Feliz Día de los Muertos!".
- Worlds: `newyear` 9, `valentines` 10, `stpatricks` 11, `easter` 12, `muertos` 13; names "🎆 New Year", "💘 Valentine's", "☘️ St. Patrick's", "🐣 Easter", "🌼 Día de los Muertos".
- Songs are public domain, white keys only (bar notes 0…14 = C4…C6), every note on the beat, ≥ 25 notes except Hot Cross Buns (a complete 17-note song).
- The New Year's Eve icon keeps the "2027" in the art.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never commit Canva stock art (the artist's own AI art is fine).
- Test command (from the worktree root): `xcodegen >/dev/null && xcodebuild test -project MarbleJam.xcodeproj -scheme MarbleJam -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath <scratch>/dd-holidays` — add `-only-testing:MarbleJamTests/<Class>` for one class.

## Review Focus

- **Easter in late March overlapping St. Patrick's:** Easter on Mar 22–31 would start its window before Mar 17; the window must start Mar 18 at the earliest and the day-by-day check must never find two seasons. → Task 8 test `testNoTwoHolidaysOverlapForACentury` and `testEasterNeverStartsBeforeStPatricksEnds`.
- **New Year crossing the year:** Jan 1–6 must find last year's New Year window, Dec 30 must still be Christmas. → Task 8 test `testNewYearCrossesTheYear`.
- **A player who picked a Halloween background on Oct 31:** on Nov 1 it's out of season and the menu falls back to the Día de los Muertos default — already covered by `BackgroundLibrary.resolve`; Task 5 adds a check that each new holiday opens on its own background.
- **A level generator that can't build a level for a new song** (crash at launch from `preconditionFailure` in `Challenge.swift`). → Task 7 builds every level in tests; the parameters below are a starting point and are adjusted until the generators succeed.
- **Long greetings overflowing the title** ("HAPPY ST. PATRICK'S DAY"): `make_title.swift` scales the greeting to at most 92% of the lettering width. → Task 4 checks the image widths.

---

### Task 1: Holiday songs (15 public-domain melodies)

**Files:**
- Create: `MarbleJam/HolidaySongs.swift`
- Test: `MarbleJamTests/HolidaySongTests.swift`

**Interfaces:**
- Consumes: `SongRecipe(name:instrument:melody:)` (Seasons.swift), `Instrument` cases `.bells .piano .marimba .guitar .chip` (and any others in Instrument.swift), `Engine.simulate`, `Engine.isOnBeat`.
- Produces: `enum HolidaySongs { static let newYear, valentines, stPatricks, easter, muertos: [SongRecipe]; static var all: [SongRecipe] }`, each array exactly 3 songs in this order:
  - newYear: Auld Lang Syne, The Blue Danube, Radetzky March (instrument `.bells`)
  - valentines: Plaisir d'amour, Let Me Call You Sweetheart, Aura Lee (`.piano`) — Für Elise from the spec is replaced by Aura Lee (1861): its opening alternates E and D♯, and the bars have no black keys.
  - stPatricks: Molly Malone, The Irish Washerwoman, Londonderry Air (`.guitar`)
  - easter: Hot Cross Buns, Christ the Lord Is Risen Today, Spring (Vivaldi) (`.marimba`)
  - muertos: La Llorona, Cielito Lindo, La Bamba (`.guitar`)

Transcription rules (each song):
1. Find a public-domain score (Wikipedia LilyPond score, IMSLP, hymnary.org, thesession.org ABC); put its URL in a `//` comment above the recipe.
2. Transpose so every note is a white key between C4 and C6 (C major / A minor are the usual targets). Map C4=0, D4=1, E4=2, F4=3, G4=4, A4=5, B4=6, C5=7, D5=8, E5=9, F5=10, G5=11, A5=12, B5=13, C6=14.
3. `beats` is the time since the previous note (the first note's `beats` is 1), in quarter-note beats; use only 0.5, 1, 1.5, 2, 3 (as the existing holiday songs do).
4. Use a recognisable complete section (a verse/chorus or the main theme), at least 25 notes (Hot Cross Buns: its whole 17 notes).
5. If a melody needs a black key in every transposition, use its pre-approved substitute (also public domain) and say so in the commit: Plaisir d'amour → "Love's Old Sweet Song" (Molloy, 1884); Let Me Call You Sweetheart → "Beautiful Dreamer" (Foster, 1864); Radetzky March → "Ode to Joy" (Beethoven); La Llorona → "Las Golondrinas" (Serradell, 1862); Cielito Lindo → "Las Mañanitas" (traditional); La Bamba → "La Cucaracha" (traditional); Spring → "All Things Bright and Beautiful" (Monk, 1887). A substitute must pass the same rules; never approximate a black key with a neighbouring white key.
6. An independent reviewer compares each transcription note by note with its source score before the task is accepted.

- [ ] **Step 1: Write the failing test** (`MarbleJamTests/HolidaySongTests.swift`)

```swift
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

    func testCompleteSongs() {
        for r in HolidaySongs.all where r.name != "Hot Cross Buns" {
            XCTAssertGreaterThanOrEqual(r.melody.count, 25, "\(r.name) is only its opening phrase")
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
```

- [ ] **Step 2: Run it** — `-only-testing:MarbleJamTests/HolidaySongTests` → FAIL: "cannot find 'HolidaySongs' in scope".

- [ ] **Step 3: Write `MarbleJam/HolidaySongs.swift`** with the 15 transcriptions, in this shape:

```swift
import Foundation

/// The five newer holidays' ready-made songs (public-domain melodies on the white-key bars; see Seasons.swift for the
/// note and beat format). Each recipe names the score it was taken from.
enum HolidaySongs {
    static let newYear: [SongRecipe] = [
        // Auld Lang Syne — <score URL>
        SongRecipe(name: "Auld Lang Syne", instrument: .bells, melody: [ /* (beats, note) pairs from the score */ ]),
        // The Blue Danube (Strauss II, main waltz theme) — <score URL>
        SongRecipe(name: "The Blue Danube", instrument: .bells, melody: [ /* … */ ]),
        // Radetzky March (Strauss I, main theme) — <score URL>
        SongRecipe(name: "Radetzky March", instrument: .bells, melody: [ /* … */ ]),
    ]
    static let valentines: [SongRecipe] = [ /* Plaisir d'amour, Let Me Call You Sweetheart, Aura Lee — .piano */ ]
    static let stPatricks: [SongRecipe] = [ /* Molly Malone, The Irish Washerwoman, Londonderry Air — .guitar */ ]
    static let easter: [SongRecipe] = [ /* Hot Cross Buns, Christ the Lord Is Risen Today, Spring — .marimba */ ]
    static let muertos: [SongRecipe] = [ /* La Llorona, Cielito Lindo, La Bamba — .guitar */ ]

    static var all: [SongRecipe] { newYear + valentines + stPatricks + easter + muertos }
}
```

(The `/* … */` are filled with the actual transcriptions — the data this task exists to produce; no recipe may ship empty.)

- [ ] **Step 4: Run the test until it passes.** If `testEveryHolidaySongPlaysOnTheBeat` fails for a song, `Engine.smartAdd` couldn't place a pad for one note at that spacing (most often a repeated or far-jumping note after 0.5 beat). Find the first missing hit (`run.hits.count`), and lengthen that note's `beats` to the next allowed value (0.5 → 1, 1 → 1.5, 1.5 → 2) — the existing holiday songs were fitted the same way. List every such change against the score in the commit message.

- [ ] **Step 5: Commit** `git add MarbleJam/HolidaySongs.swift MarbleJamTests/HolidaySongTests.swift && git commit -m "Songs for the five new holidays"`

---

### Task 2: Holiday colours

**Files:**
- Modify: `MarbleJam/Theme.swift` (`forSeason`)
- Test: `MarbleJamTests/ThemeTests.swift`

**Interfaces:** Produces `Theme.forSeason("newyear" | "valentines" | "stpatricks" | "easter" | "muertos")`.

- [ ] **Step 1: Failing test** — in `ThemeTests`, change `XCTAssertEqual(Theme.forSeason("easter"), .standard)` to `XCTAssertEqual(Theme.forSeason("summer"), .standard)`, and add:

```swift
    func testTheNewHolidaysHaveTheirOwnReadableLook() {
        let ids = ["newyear", "valentines", "stpatricks", "easter", "muertos"]
        let looks = (["halloween", "thanksgiving", "christmas"] + ids).map { Theme.forSeason($0) }
        XCTAssertFalse(looks.contains(.standard))
        XCTAssertEqual(Set(looks.map(\.primary)).count, looks.count, "every holiday has its own main colour")
        for t in looks { XCTAssertGreaterThanOrEqual(Theme.contrast(t.primary, t.primaryText), 4.5, "\(t.primary)") }
    }
```

- [ ] **Step 2: Run** `-only-testing:MarbleJamTests/ThemeTests` → FAIL (new ids return `.standard`).

- [ ] **Step 3: Add the cases** before `default:` in `Theme.forSeason`:

```swift
        case "newyear":            // navy night, gold and silver
            Theme(primary: hex(0xF5C542), primaryText: hex(0x0B1030), chipFill: hex(0x121A4A), chipStroke: hex(0xF5C542),
                  chipStrokeOpacity: 0.45, accent: hex(0xFFD86B), marbleGlow: hex(0xFFE9A8))
        case "valentines":         // pink and rose
            Theme(primary: hex(0xFF5C8A), primaryText: hex(0x2A0012), chipFill: hex(0x4A1030), chipStroke: hex(0xFF9EC0),
                  chipStrokeOpacity: 0.45, accent: hex(0xFF9EC0), marbleGlow: hex(0xFFB3CC))
        case "stpatricks":         // shamrock green and gold
            Theme(primary: hex(0x2FBF5A), primaryText: hex(0x062010), chipFill: hex(0x0F3A1E), chipStroke: hex(0xF2C94C),
                  chipStrokeOpacity: 0.45, accent: hex(0xF2C94C), marbleGlow: hex(0x8CF2A6))
        case "easter":             // lavender, mint and butter yellow
            Theme(primary: hex(0xB89CFF), primaryText: hex(0x1E0F3D), chipFill: hex(0x2E2350), chipStroke: hex(0xFFE08A),
                  chipStrokeOpacity: 0.45, accent: hex(0x8FE3C8), marbleGlow: hex(0xFFD1E8))
        case "muertos":            // marigold, magenta and turquoise papel picado on purple
            Theme(primary: hex(0xFFA620), primaryText: hex(0x2A0E00), chipFill: hex(0x3A1450), chipStroke: hex(0xFF4FA3),
                  chipStrokeOpacity: 0.45, accent: hex(0x3FD7C8), marbleGlow: hex(0xFFC04D))
```

- [ ] **Step 4: Run** → PASS (if a contrast fails, darken that `primaryText`).
- [ ] **Step 5: Commit** `git commit -am "Colours for the five new holidays"`

---

### Task 3: Holiday app icons

**Files:**
- Create: `art/seasons/<id>/icon-source.jpg`, `art/seasons/<id>/icon.png`, `MarbleJam/Assets.xcassets/AppIcon-<id>.appiconset/{AppIcon.png,Contents.json}` for the five ids
- Modify: `project.yml` (`ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`), `README.md` (icon commands)
- Test: `MarbleJamTests/ThemeTests.swift` (`AppIconTests`)

Sources (scratchpad `hol/in/`) and vetted crops (`swift tools/icon_from_tile.swift <src> <out> x y size colour`):

| id | source | crop |
|---|---|---|
| newyear | IMG_9245.JPG | 223 223 1602 0F1642 (keeps "2027") |
| valentines | IMG_9239.JPG | 268 268 1512 F5D4C5 |
| stpatricks | IMG_9243.JPG | 250 250 1548 457854 |
| easter | IMG_9240.JPG | 224 224 1600 BEF2F0 |
| muertos | IMG_9246.JPG | 224 224 1600 3A2270 |

- [ ] **Step 1: Failing test** (in `AppIconTests`):

```swift
    func testTheNewHolidayIconsAreBundled() {
        for id in ["newyear", "valentines", "stpatricks", "easter", "muertos"] {
            XCTAssertTrue(AppIcons.available.contains("AppIcon-\(id)"), id)
        }
    }
```

- [ ] **Step 2: Run** `-only-testing:MarbleJamTests/AppIconTests` → FAIL.
- [ ] **Step 3: Make the icons** — for each row: `mkdir -p art/seasons/<id> MarbleJam/Assets.xcassets/AppIcon-<id>.appiconset`, copy the source to `art/seasons/<id>/icon-source.jpg`, run the crop into `art/seasons/<id>/icon.png`, copy it to the icon set's `AppIcon.png`, and write `Contents.json`:

```json
{
  "images" : [ { "filename" : "AppIcon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

Then in `project.yml` set `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES: "AppIcon-halloween AppIcon-thanksgiving AppIcon-christmas AppIcon-newyear AppIcon-valentines AppIcon-stpatricks AppIcon-easter AppIcon-muertos"`, and add the five crop commands to the README's holiday icon line. Check each `icon.png` is 1024×1024 with no alpha (`sips -g pixelWidth -g hasAlpha`).

- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `git add art/seasons MarbleJam/Assets.xcassets project.yml README.md MarbleJamTests && git commit -m "App icons for the five new holidays"`

---

### Task 4: Holiday titles

**Files:**
- Modify: `tools/make_title.swift` (`styles`)
- Create: `MarbleJam/Assets.xcassets/SeasonTitle-<id>.imageset/{Title.png,Contents.json}` ×5
- Test: `MarbleJamTests/SeasonTests.swift`

- [ ] **Step 1: Failing test:**

```swift
    func testTheNewHolidaysHaveTitleArt() {
        let plain = UIImage(named: "Title")!
        for id in ["newyear", "valentines", "stpatricks", "easter", "muertos"] {
            let art = UIImage(named: "SeasonTitle-\(id)")
            XCTAssertNotNil(art, id)
            XCTAssertEqual(art?.size.width ?? 0, plain.size.width, accuracy: 1, "\(id): the greeting never widens the title")
            XCTAssertGreaterThan(art?.size.height ?? 0, plain.size.height, "\(id): the greeting sits above the lettering")
        }
    }
```

- [ ] **Step 2: Run** `-only-testing:MarbleJamTests/SeasonTests/testTheNewHolidaysHaveTitleArt` → FAIL.
- [ ] **Step 3: Add styles** to `styles` in `tools/make_title.swift`:

```swift
    "newyear": Style(top: rgb(1, 0.88, 0.45), bottom: rgb(0.85, 0.62, 0.12), shadow: rgb(0.07, 0.1, 0.3),
                     greeting: "HAPPY NEW YEAR", greetingColor: rgb(0.92, 0.93, 0.98)),
    "valentines": Style(top: rgb(1, 0.6, 0.78), bottom: rgb(0.9, 0.2, 0.45), shadow: rgb(0.4, 0.05, 0.2),
                        greeting: "HAPPY VALENTINE'S DAY", greetingColor: rgb(1, 0.85, 0.9)),
    "stpatricks": Style(top: rgb(1, 0.84, 0.35), bottom: rgb(0.2, 0.7, 0.3), shadow: rgb(0.05, 0.25, 0.1),
                        greeting: "HAPPY ST. PATRICK'S DAY", greetingColor: rgb(0.75, 1, 0.75)),
    "easter": Style(top: rgb(1, 0.92, 0.55), bottom: rgb(0.62, 0.55, 1), shadow: rgb(0.25, 0.18, 0.45),
                    greeting: "HAPPY EASTER", greetingColor: rgb(0.7, 0.95, 0.85)),
    "muertos": Style(top: rgb(1, 0.75, 0.2), bottom: rgb(1, 0.3, 0.6), shadow: rgb(0.25, 0.05, 0.35),
                     greeting: "DÍA DE LOS MUERTOS", greetingColor: rgb(0.4, 0.9, 0.85)),
```

Create each imageset folder with `Contents.json` `{"images":[{"filename":"Title.png","idiom":"universal"}],"info":{"author":"xcode","version":1}}`, then run `swift tools/make_title.swift <id>` for the five ids. Look at all five on a dark background (contact sheet) before committing.

- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `git add tools/make_title.swift MarbleJam/Assets.xcassets MarbleJamTests && git commit -m "Title lettering for the five new holidays"`

---

### Task 5: Holiday backgrounds

**Files:**
- Create: `art/backgrounds-artist/41-valentines-love-track.jpg`, `42-easter-spring-meadow.jpg`, `43-stpatricks-rainbow-hills.jpg`, `44-newyear-fireworks.jpg`, `45-muertos-marigold-path.jpg` (vetted copies in scratchpad `hol/out/bg/`; byte-identical to the artist's IMG_9241/9242/9244/9247/9248)
- Modify: `tools/prepare_backgrounds.swift` (`seasons` set), `MarbleJamBackgrounds/*` (regenerated), `README.md`
- Test: `MarbleJamTests/BackgroundTests.swift`

- [ ] **Step 1: Failing test** — in `testBundledCatalogue` change `(1...40)` to `(1...45)`; add:

```swift
    func testTheNewHolidaysOpenOnTheirOwnBackground() {
        let all = BackgroundLibrary.bundled
        let defaults = ["valentines": "Love Track", "easter": "Spring Meadow", "stpatricks": "Rainbow Hills",
                        "newyear": "Fireworks", "muertos": "Marigold Path"]
        for (season, name) in defaults {
            XCTAssertEqual(all.filter { $0.season == season }.count, 1, season)
            XCTAssertEqual(BackgroundLibrary.resolve(all, chosenID: "", season: season)?.name, name, season)
        }
    }
```

- [ ] **Step 2: Run** `-only-testing:MarbleJamTests/BackgroundTests` → FAIL.
- [ ] **Step 3:** In `tools/prepare_backgrounds.swift` change the set to `["halloween", "thanksgiving", "christmas", "newyear", "valentines", "stpatricks", "easter", "muertos"]`; copy the five files into `art/backgrounds-artist/`; run `swift tools/prepare_backgrounds.swift` (needs `art/backgrounds-drawn/`, which is git-ignored — copy it from the main checkout). Check with `git status` that bg-01…bg-40 are unchanged (only `manifest.json` modified, bg-41…45 added).
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `git add art/backgrounds-artist MarbleJamBackgrounds tools/prepare_backgrounds.swift README.md MarbleJamTests && git commit -m "Backgrounds for the five new holidays"`

---

### Task 6: Reward marbles

**Files:**
- Modify: `MarbleJam/Skins.swift` (5 skins after `snowglobe`, 5 drawing helpers)
- Test: `MarbleJamTests/StoreTests.swift` (`SkinTests`)

- [ ] **Step 1: Failing test:**

```swift
    func testEachNewHolidayHasARewardMarble() {
        let expected = ["newyear": "Fireworks", "valentines": "Sweetheart", "stpatricks": "Four-Leaf Clover",
                        "easter": "Easter Egg", "muertos": "Marigold"]
        for (season, name) in expected {
            let rewards = Skins.all.filter { $0.unlock == .holiday(season) }
            XCTAssertEqual(rewards.map(\.name), [name], season)
        }
    }
```

- [ ] **Step 2: Run** `-only-testing:MarbleJamTests/SkinTests` → FAIL.
- [ ] **Step 3: Add the skins** after the `snowglobe` line:

```swift
        Skin(id: "fireworks", name: "Fireworks", unlock: .holiday("newyear")) { c, s in fireworks(c, s) },
        Skin(id: "sweetheart", name: "Sweetheart", unlock: .holiday("valentines")) { c, s in sweetheart(c, s) },
        Skin(id: "clover", name: "Four-Leaf Clover", unlock: .holiday("stpatricks")) { c, s in clover(c, s) },
        Skin(id: "easteregg", name: "Easter Egg", unlock: .holiday("easter")) { c, s in easterEgg(c, s) },
        Skin(id: "marigold", name: "Marigold", unlock: .holiday("muertos")) { c, s in marigold(c, s) },
```

and the helpers at the end of `enum Skins` (y grows downward, size `s`):

```swift
    /// A heart centred on (cx, cy), `w` wide, tip pointing down.
    private static func heartPath(_ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat) -> CGPath {
        let p = CGMutablePath(), h = w * 0.9, tip = CGPoint(x: cx, y: cy + h * 0.45)
        p.move(to: tip)
        p.addCurve(to: CGPoint(x: cx - w * 0.5, y: cy - h * 0.1), control1: CGPoint(x: cx - w * 0.15, y: cy + h * 0.3), control2: CGPoint(x: cx - w * 0.5, y: cy + h * 0.15))
        p.addCurve(to: CGPoint(x: cx, y: cy - h * 0.25), control1: CGPoint(x: cx - w * 0.5, y: cy - h * 0.45), control2: CGPoint(x: cx - w * 0.05, y: cy - h * 0.5))
        p.addCurve(to: CGPoint(x: cx + w * 0.5, y: cy - h * 0.1), control1: CGPoint(x: cx + w * 0.05, y: cy - h * 0.5), control2: CGPoint(x: cx + w * 0.5, y: cy - h * 0.45))
        p.addCurve(to: tip, control1: CGPoint(x: cx + w * 0.5, y: cy + h * 0.15), control2: CGPoint(x: cx + w * 0.15, y: cy + h * 0.3))
        p.closeSubpath()
        return p
    }

    private static func fireworks(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (0.2, 0.25, 0.55), outer: (0.02, 0.03, 0.15))
        c.setLineCap(.round)
        for (x, y, r, color) in [(0.35, 0.35, 0.22, (1.0, 0.82, 0.3)), (0.68, 0.45, 0.18, (1.0, 0.45, 0.7)), (0.45, 0.72, 0.16, (0.4, 0.9, 1.0))] as [(CGFloat, CGFloat, CGFloat, RGB)] {
            c.setStrokeColor(col(color)); c.setLineWidth(s * 0.025)
            for k in 0..<10 {
                let a = CGFloat(k) * .pi / 5
                c.move(to: CGPoint(x: s * x + cos(a) * s * r * 0.3, y: s * y + sin(a) * s * r * 0.3))
                c.addLine(to: CGPoint(x: s * x + cos(a) * s * r, y: s * y + sin(a) * s * r))
            }
            c.strokePath()
            c.setFillColor(col(color)); dot(c, s, x, y, 0.025)
        }
    }

    private static func sweetheart(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (1, 0.75, 0.85), outer: (0.85, 0.2, 0.45))
        c.addPath(heartPath(s / 2, s * 0.52, s * 0.56)); c.setFillColor(col((0.9, 0.05, 0.25))); c.fillPath()
        c.addPath(heartPath(s * 0.42, s * 0.44, s * 0.14)); c.setFillColor(col((1, 0.85, 0.9), 0.8)); c.fillPath()
        sparkle(c, s)
    }

    private static func clover(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (0.7, 1, 0.7), outer: (0.05, 0.45, 0.15))
        c.setStrokeColor(col((0.05, 0.35, 0.1))); c.setLineWidth(s * 0.04); c.setLineCap(.round)
        c.move(to: CGPoint(x: s / 2, y: s / 2)); c.addQuadCurve(to: CGPoint(x: s * 0.68, y: s * 0.9), control: CGPoint(x: s * 0.52, y: s * 0.75)); c.strokePath()
        c.saveGState(); c.translateBy(x: s / 2, y: s / 2)
        for k in 0..<4 {                                                   // four heart leaves, tips to the middle
            c.saveGState(); c.rotate(by: CGFloat(k) * .pi / 2 + .pi / 4)
            c.addPath(heartPath(0, -s * 0.17, s * 0.3)); c.setFillColor(col((0.15, 0.65, 0.25))); c.fillPath()
            c.restoreGState()
        }
        c.restoreGState()
        c.setFillColor(col((0.95, 0.8, 0.3))); dot(c, s, 0.5, 0.5, 0.03)
    }

    private static func easterEgg(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (0.95, 0.9, 1), outer: (0.65, 0.55, 0.95))
        c.setLineWidth(s * 0.07); c.setLineJoin(.round)
        for (y, color) in [(0.3, (1.0, 0.85, 0.35)), (0.5, (0.55, 0.9, 0.75)), (0.7, (1.0, 0.6, 0.75))] as [(CGFloat, RGB)] {
            c.setStrokeColor(col(color))
            c.move(to: CGPoint(x: 0, y: s * y))
            for k in 1...8 { c.addLine(to: CGPoint(x: s * CGFloat(k) / 8, y: s * (y + (k % 2 == 0 ? 0 : 0.06)))) }
            c.strokePath()
        }
        c.setFillColor(UIColor(white: 1, alpha: 0.9).cgColor)
        for (x, y) in [(0.25, 0.4), (0.5, 0.4), (0.75, 0.4), (0.38, 0.6), (0.62, 0.6)] as [(CGFloat, CGFloat)] { dot(c, s, x, y, 0.025) }
    }

    private static func marigold(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (1, 0.85, 0.4), outer: (0.85, 0.35, 0.02))
        c.saveGState(); c.translateBy(x: s / 2, y: s / 2)
        for (ring, color, n) in [(0.3, (0.95, 0.45, 0.05), 14), (0.2, (1.0, 0.65, 0.1), 12), (0.11, (1.0, 0.82, 0.25), 10)] as [(CGFloat, RGB, Int)] {
            for k in 0..<n {                                                // petals in rings, darker outside
                c.saveGState(); c.rotate(by: CGFloat(k) * 2 * .pi / CGFloat(n) + ring)
                c.addEllipse(in: CGRect(x: -s * 0.045, y: -s * ring - s * 0.06, width: s * 0.09, height: s * 0.14))
                c.setFillColor(col(color)); c.fillPath(); c.restoreGState()
            }
        }
        c.restoreGState()
        c.setFillColor(col((0.55, 0.25, 0.05))); dot(c, s, 0.5, 0.5, 0.05)
    }
```

(`glass`, `dot`, `sparkle`, `col` and `RGB` already exist in `Skins.swift`.)

- [ ] **Step 4: Run** → PASS. Render all skins on a contact sheet (as for the earlier packs) and look at the five new marbles at 80 px.
- [ ] **Step 5: Commit** `git commit -am "Reward marbles for the five new holidays"`

---

### Task 7: Challenge worlds 9–13

**Files:**
- Modify: `MarbleJam/Challenge.swift` (`worldNames`, `holiday`, `holidayWorlds`)
- Test: `MarbleJamTests/ChallengeTests.swift`

**Interfaces:**
- Consumes: `HolidaySongs.*` (Task 1); private generators `melody(_:_:_:notes:remove:season:hint:)`, `fix(_:_:_:notes:loose:season:spread:)`, `target(_:_:_:base:pieces:season:hint:)`.
- Produces: `Challenges.holidayWorlds` with 8 entries; `Challenges.holidayIDs(id)` for the new ids; 30 more levels in `Challenges.holiday`.

- [ ] **Step 1: Failing test** — in `testEachHolidayHasASixLevelWorld` change `48` to `78`; add:

```swift
    func testTheNewHolidaysEachHaveASixLevelWorld() {
        let worlds = ["newyear": 9, "valentines": 10, "stpatricks": 11, "easter": 12, "muertos": 13]
        for (id, w) in worlds {
            XCTAssertEqual(Challenges.holidayWorlds[id], w, id)
            let levels = Challenges.holiday.filter { $0.season == id }
            XCTAssertEqual(levels.map(\.number), Array(1...6), id)
            XCTAssertTrue(levels.allSatisfy { $0.world == w }, id)
            XCTAssertEqual(Challenges.holidayIDs(id), (1...6).map { "w\(w)-\($0)" })
            let first = levels.first { $0.number == 1 }!
            XCTAssertLessThanOrEqual(first.tray.count, 1, id)
            XCTAssertLessThanOrEqual(first.solution.pads.count, 10, id)
        }
        XCTAssertEqual(Challenges.worldNames.count, 13)
        XCTAssertEqual(Challenges.worldNames.last, "🌼 Día de los Muertos")
    }
```

(The existing loops in `ChallengeTests` over `Challenges.everything` — solution 3★, start 0★, untouched tray never wins, cups inside the screen, hints get harder — now also cover the 30 new levels.)

- [ ] **Step 2: Run** `-only-testing:MarbleJamTests/ChallengeTests` → FAIL.
- [ ] **Step 3:** Append to `worldNames`: `"🎆 New Year", "💘 Valentine's", "☘️ St. Patrick's", "🐣 Easter", "🌼 Día de los Muertos"`. Set `holidayWorlds = ["halloween": 6, "thanksgiving": 7, "christmas": 8, "newyear": 9, "valentines": 10, "stpatricks": 11, "easter": 12, "muertos": 13]`. In `holiday`, after the Christmas levels, add (same six-level pattern as Christmas):

```swift
            melody(9, 1, ny[0], notes: 8, remove: [4], season: "newyear", hint: .near),
            fix(9, 2, ny[1], notes: 15, loose: [3, 8, 12], season: "newyear", spread: 0.6),
            target(9, 3, ny[2], base: 5, pieces: [.bar, .bar], season: "newyear", hint: .mirrored),
            melody(9, 4, ny[1], notes: 16, remove: [3, 7, 12], season: "newyear", hint: .mirrored),
            fix(9, 5, ny[2], notes: 20, loose: [3, 8, 13, 17], season: "newyear"),
            target(9, 6, ny[0], base: 6, pieces: [.ramp, .bar], season: "newyear"),
            melody(10, 1, va[0], notes: 8, remove: [4], season: "valentines", hint: .near),
            fix(10, 2, va[1], notes: 15, loose: [3, 8, 12], season: "valentines", spread: 0.6),
            target(10, 3, va[2], base: 5, pieces: [.bar, .bar], season: "valentines", hint: .mirrored),
            melody(10, 4, va[1], notes: 16, remove: [3, 7, 12], season: "valentines", hint: .mirrored),
            fix(10, 5, va[2], notes: 20, loose: [3, 8, 13, 17], season: "valentines"),
            target(10, 6, va[0], base: 6, pieces: [.ramp, .bar], season: "valentines"),
            melody(11, 1, sp[0], notes: 8, remove: [4], season: "stpatricks", hint: .near),
            fix(11, 2, sp[1], notes: 15, loose: [3, 8, 12], season: "stpatricks", spread: 0.6),
            target(11, 3, sp[2], base: 5, pieces: [.bar, .bar], season: "stpatricks", hint: .mirrored),
            melody(11, 4, sp[1], notes: 16, remove: [3, 7, 12], season: "stpatricks", hint: .mirrored),
            fix(11, 5, sp[2], notes: 20, loose: [3, 8, 13, 17], season: "stpatricks"),
            target(11, 6, sp[0], base: 6, pieces: [.ramp, .bar], season: "stpatricks"),
            melody(12, 1, ea[0], notes: 8, remove: [4], season: "easter", hint: .near),          // Hot Cross Buns
            fix(12, 2, ea[1], notes: 15, loose: [3, 8, 12], season: "easter", spread: 0.6),
            target(12, 3, ea[0], base: 5, pieces: [.bar, .bar], season: "easter", hint: .mirrored),
            melody(12, 4, ea[2], notes: 16, remove: [3, 7, 12], season: "easter", hint: .mirrored),
            fix(12, 5, ea[1], notes: 20, loose: [3, 8, 13, 17], season: "easter"),
            target(12, 6, ea[2], base: 6, pieces: [.ramp, .bar], season: "easter"),
            melody(13, 1, mu[0], notes: 8, remove: [4], season: "muertos", hint: .near),
            fix(13, 2, mu[1], notes: 15, loose: [3, 8, 12], season: "muertos", spread: 0.6),
            target(13, 3, mu[2], base: 5, pieces: [.bar, .bar], season: "muertos", hint: .mirrored),
            melody(13, 4, mu[1], notes: 16, remove: [3, 7, 12], season: "muertos", hint: .mirrored),
            fix(13, 5, mu[2], notes: 20, loose: [3, 8, 13, 17], season: "muertos"),
            target(13, 6, mu[0], base: 6, pieces: [.ramp, .bar], season: "muertos"),
```

with `let ny = HolidaySongs.newYear, va = HolidaySongs.valentines, sp = HolidaySongs.stPatricks, ea = HolidaySongs.easter, mu = HolidaySongs.muertos` at the top of the closure.

- [ ] **Step 4: Run until it passes.** A `preconditionFailure("challenge wN-M: …")` while building a level means that song can't make that level: for `melody`/`fix`, move the `remove`/`loose` indices by ±1 or change `notes` by ±2; for `target`, change `base` by ±1 or swap the song with another of the same holiday. Keep the six-level pattern (L1 short with one missing note; L2 gentle fix; L3–L6 harder). Note each adjustment in the commit message.
- [ ] **Step 5: Commit** `git commit -am "Challenge worlds for the five new holidays"`

---

### Task 8: The five seasons and their dates

**Files:**
- Modify: `MarbleJam/Seasons.swift` (Easter date, moved windows, 5 new `Season`s), `MarbleJamTests/SeasonTests.swift`, `README.md` (seasons list, App Store Connect list: achievements `marblejam.world1`…`world13`, leaderboard range 0–234)

**Interfaces:**
- Consumes: `HolidaySongs.*`.
- Produces: `Seasons.easter(year: Int, calendar: Calendar) -> Date` (start of Easter Sunday), `Seasons.all` with 8 seasons in the order halloween, thanksgiving, christmas, newyear, valentines, stpatricks, easter, muertos.

- [ ] **Step 1: Failing tests** — update the existing ones and add new ones in `SeasonTests`:

```swift
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
```

Also in `testHolidaySongsAreComplete` add `"Hot Cross Buns"` to the exempt list, rename `testChristmasCrossesNewYear` → replaced by `testChristmasThenNewYear` above, and extend `testHolidayTitleArtIsBundledWhereItExists` to all eight ids.

- [ ] **Step 2: Run** `-only-testing:MarbleJamTests/SeasonTests` → FAIL ("easter" is not a member; windows wrong).
- [ ] **Step 3: Implement** in `Seasons.swift`:

```swift
    /// Western (Gregorian) Easter Sunday, at the start of the day: the anonymous Gregorian algorithm (Meeus/Jones/Butcher).
    static func easter(year y: Int, calendar: Calendar) -> Date {
        let a = y % 19, b = y / 100, c = y % 100, d = b / 4, e = b % 4, f = (b + 8) / 25, g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30, i = c / 4, k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7, m = (a + 11 * h + 22 * l) / 451
        let n = h + l - 7 * m + 114
        return calendar.date(from: DateComponents(year: y, month: n / 31, day: n % 31 + 1))!
    }
```

Change windows: Halloween `(date(y, 10, 1, cal), date(y, 10, 31, cal))`; Thanksgiving first day `date(y, 11, 8, cal)`; Christmas `(date(y, 12, 1, cal), date(y, 12, 30, cal))`. Append after Christmas:

```swift
        Season(id: "newyear", title: "New Year's Eve", emoji: "🎆", banner: "🎆 Happy New Year!", songs: HolidaySongs.newYear,
               window: { y, cal in (date(y, 12, 31, cal), date(y + 1, 1, 6, cal)) }),
        Season(id: "valentines", title: "Valentine's Day", emoji: "💘", banner: "💘 Happy Valentine's Day!", songs: HolidaySongs.valentines,
               window: { y, cal in (date(y, 2, 1, cal), date(y, 2, 14, cal)) }),
        Season(id: "stpatricks", title: "St. Patrick's Day", emoji: "☘️", banner: "☘️ Happy St. Patrick's Day!", songs: HolidaySongs.stPatricks,
               window: { y, cal in (date(y, 3, 1, cal), date(y, 3, 17, cal)) }),
        Season(id: "easter", title: "Easter", emoji: "🐣", banner: "🐣 Happy Easter!", songs: HolidaySongs.easter, window: { y, cal in
            let sunday = easter(year: y, calendar: cal)
            return (max(cal.date(byAdding: .day, value: -14, to: sunday)!, date(y, 3, 18, cal)), cal.date(byAdding: .day, value: 1, to: sunday)!)
        }),
        Season(id: "muertos", title: "Día de los Muertos", emoji: "🌼", banner: "🌼 ¡Feliz Día de los Muertos!", songs: HolidaySongs.muertos,
               window: { y, cal in (date(y, 11, 1, cal), date(y, 11, 7, cal)) }),
```

- [ ] **Step 4: Run the whole suite** → PASS (the `Seasons.all` loops in ThemeTests, AppIconTests, SkinTests, ChallengeTests, SeasonTests, NameTests now cover all eight).
- [ ] **Step 5: Look at it:** for each new id, set the DEBUG `season.preview` in the simulator app's preferences (`xcrun simctl spawn <device> defaults write <container>/Library/Preferences/com.marblejam.app season.preview <id>`), launch, and screenshot the menu; check title, colours, background and that the Challenges list shows the holiday world first.
- [ ] **Step 6: Commit** `git commit -am "Five new holidays: dates, Easter, and the seasons"`, then push, open the PR and merge after a whole-branch review.
