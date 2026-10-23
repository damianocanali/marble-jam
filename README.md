# Marble Beats (iOS)

A marble-run music game for families: build a course, drop the marble, and every pad it hits plays a note.
(Called Marble Jam, then briefly Rolling Notes, while in development; the code, folder and bundle id still say "marblejam", which players never see.)

Native rebuild of the web prototype. SwiftUI for the controls, SpriteKit for the run, AVAudioEngine for sound.

**Status:** builds and passes its unit tests with `xcodegen && xcodebuild test -scheme MarbleJam -destination 'platform=iOS Simulator,name=iPhone 17'`.

## Build
1. Install XcodeGen once: `brew install xcodegen`
2. In this folder: `xcodegen` (creates `MarbleJam.xcodeproj` from `project.yml`)
3. Open the project in Xcode, set your team and bundle identifier, and run on an iPhone or the simulator (iOS 17+).

Without XcodeGen: create a new iOS App project (SwiftUI) called MarbleJam and replace its Swift files with the ones in `MarbleJam/`.

## Files
- `Engine.swift`      rules, pads, the fixed-step simulation, the "pad on the beat" helper, the demo song
- `Synth.swift`       bell/pluck synth on the audio clock
- `GameModel.swift`   app state: course, undo, saving, playback
- `Course3D.swift` / `SceneMapping.swift` the 3D room (SceneKit): warm wall, spot light with shadows, brass pieces on wires, chrome marble, angled show camera; the 2D `RunScene` on top draws labels and guides, handles touches and drives it
- `RunScene.swift`    SpriteKit drawing and touch handling
- `ContentView.swift` header, hint, buttons
- `RootView.swift`    switches between the menu and the game
- `MenuView.swift`    start screen: the holiday or everyday lettering, Challenges, Create, Backgrounds, Store, Account (iCloud, Game Center, purchases, privacy & help)
- `Seasons.swift`    holiday calendar, banners and melodies; builds run from Xcode show "Preview season" on the menu. The eight holidays and their windows (both days included; none overlap, a test checks 100 years): Halloween Oct 1-31, Día de los Muertos Nov 1-7, Thanksgiving Nov 8 to the day after US Thanksgiving, Christmas Dec 1-30, New Year's Eve Dec 31-Jan 6, Valentine's Day Feb 1-14, St. Patrick's Day Mar 1-17, Easter two weeks before Easter Sunday (never before Mar 18) to Easter Monday. `Seasons.easter(year:calendar:)` is the Western date, like `Seasons.thanksgiving`
- `Challenge.swift` / `ChallengesView.swift` / `Songbook.swift` 78 challenge levels in 13 worlds (5 main, 8 holiday), generated from working solutions (melody, fix, target), stars and unlocking; short public-domain tunes
- `GameCenter.swift` Game Center sign-in, leaderboard and achievements. Create these in App Store Connect (Game Center): the leaderboard `marblejam.stars` (a score from 0 to 234: 3 stars on each of the 78 levels) and one achievement per world, `marblejam.world1` to `marblejam.world13` (worlds 1-5 main, 6 Halloween, 7 Thanksgiving, 8 Christmas, 9 New Year's Eve, 10 Valentine's Day, 11 St. Patrick's Day, 12 Easter, 13 Día de los Muertos)
- `Skins.swift` / `Store.swift` / `StoreView.swift` 41 marble skins drawn in code (free, star and holiday rewards, six packs), StoreKit 2 purchases behind a grown-up question, Restore Purchases. `Products.storekit` is the local test store (Run in Xcode); the same product ids (`Store.productPrefix` + `.pack.glass|space|sports|candy|gems|animals`) must be created in App Store Connect
- `LibraryView.swift` "My Songs": song cards with a course preview, rename/duplicate/delete
- `Song.swift` / `SongStore.swift` each song saved as a JSON file in Documents/Songs; first-launch migration of the old course
- `Instrument.swift` / `InstrumentSound.swift` the six instruments (bells, piano, guitar, marimba, drums, 8-bit), each note rendered once and cached
- `AttractScene.swift` the menu's background: the demo course with marbles dropping and hitting the pads
- `PadArt.swift`      how pads, the marble and a hit look (shared by the game and the menu)
- `PadController.swift` tilt dial and note buttons for the selected piece; length and bend for ramps (curved tracks the marble rolls along, defined in `Engine.swift`)
- `Celebration.swift` / `CelebrationView.swift` star rating and the end-of-song sticker
- `Backgrounds.swift` / `BackgroundViews.swift` the background list, the picker and the tinted backdrop
- `MarbleJamBackgrounds/` the bundled backgrounds, made by `swift tools/prepare_backgrounds.swift` from two folders: the 32 drawn from scratch by `tools/make_backgrounds.swift` (command at its top) into `art/backgrounds-drawn/` (kept out of git), and the artist's in `art/backgrounds-artist/` (33 and up). Name files `NN-name.jpg`, or `NN-halloween-name.jpg` for a holiday (the word must be in the `seasons` set in `tools/prepare_backgrounds.swift`: halloween, thanksgiving, christmas, newyear, valentines, stpatricks, easter, muertos); numbers are ids, so never reuse one. bg-40 (Marble Track, `BackgroundLibrary.everydayID`) is shown off-season until the player picks one; its source had a status bar and the title baked in, painted out (the original is kept in `art/backgrounds-artist/originals/`). bg-41 to bg-45 are the one background each of Valentine's, Easter, St. Patrick's, New Year's Eve and Día de los Muertos (Love Track, Spring Meadow, Rainbow Hills, Fireworks, Marigold Path), shown when that holiday is live
- `MarbleJamTests/`   unit tests for the rules, the controller commands and the star rating
- `Assets.xcassets`   app icon: the artist's `art/icon-source.jpg` cropped to its tile: `swift tools/icon_from_tile.swift art/icon-source.jpg MarbleJam/Assets.xcassets/AppIcon.appiconset/AppIcon.png 126 123 781 F3F3EB` (shifted a little right and down so the notes in the bottom-right corner stay inside iOS's rounded corner). Menu logo: `art/MarbleBeats.png`
- `Title` image (menu and game header) and the `SeasonTitle-<holiday>` images: the artist's "MARBLE BEATS" lettering, kept as three tone masks in `art/title/` (fill, outline, shadow; made from the artist's `art/title/source.png` by `tools/title_masks.swift`, command at its top) and painted by `swift tools/make_title.swift [halloween|thanksgiving|christmas|newyear|valentines|stpatricks|easter|muertos]`: white for the menu, holiday colours with the greeting above for the holidays
- `art/seasons/<holiday>/` your holiday artwork:
  - (older Marble Jam art, kept for reference only) `source.jpg`, `title.png`
  - `icon-source.jpg` (the artist's Marble Beats icon) → `icon.png` via `tools/icon_from_tile.swift` (crops inside the tile drawn in the art; Halloween `112 112 800 3F3C50`, Thanksgiving `112 112 800 FAEFD4`, Christmas `36 36 952 103922`: that one is drawn edge to edge, so only a slight trim; New Year `223 223 1602 0F1642`: a slight trim that keeps the "2027", Valentine's `268 268 1512 F5D4C5`, St. Patrick's `250 250 1548 457854`, Easter `224 224 1600 BEF2F0`, Día de los Muertos `224 224 1600 3A2270`) → `AppIcon-<holiday>` icon set
- `Theme.swift`      holiday colours for buttons, panels, accents and the marble (pads keep their note colours)
- `AppIcons.swift`   holiday app icons, switched automatically. To add one: make an `AppIcon-<holiday>` app icon set in `Assets.xcassets` (1024 px, no transparency; `tools/icon_from_art.swift` prepares it) and add its name to `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` in `project.yml`
- `art/`              the logo, drawn by `swift tools/make_logo.swift` into `art/MarbleBeats.png`, and its fonts (Luckiest Guy: Apache 2.0; Noto Music: OFL; licences next to them). Don't run `tools/icon_from_art.swift` on it unless you want the drawn logo as the app icon

## Next steps (not built yet)
Login and store (Project B), easy mode, multiple marbles, challenge levels, store (stars + paid packs via StoreKit 2, parental gate).

## Releasing to the App Store
- Settings that upload validation and review need are in `project.yml`: version 1.0 (raise `CURRENT_PROJECT_VERSION` for every upload), `UIRequiresFullScreen` (portrait-only iPad; deprecated in iOS 26, so add real landscape support before moving to the iOS 27 SDK), `ITSAppUsesNonExemptEncryption: NO`.
- `MarbleJam/PrivacyInfo.xcprivacy`: no tracking, no collected data, UserDefaults for the app's own settings (CA92.1). Keep it in line with the App Privacy answers ("Data Not Collected").
- The privacy policy is in the app (Account › Privacy policy, `PrivacyPolicy.swift`) and on the web (`AppLinks`).
- `MarbleJam/Products.storekit` is for local testing only and is not shipped. App Store Connect needs the same 6 product ids, with descriptions of 45 characters or fewer.
- Archive from this checkout: Product › Archive (Any iOS Device), then Distribute App › App Store Connect.
