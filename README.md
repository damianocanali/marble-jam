# Marble Jam (iOS, step 1: core builder and playback)

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
- `RunScene.swift`    SpriteKit drawing and touch handling
- `ContentView.swift` header, hint, buttons
- `RootView.swift`    switches between the menu and the game
- `MenuView.swift`    start screen: lettering, Challenges (coming soon), Create, Backgrounds, Store/Sign in (coming soon)
- `Seasons.swift`    holiday calendar (Halloween, Thanksgiving, Christmas), banners and melodies; builds run from Xcode show "Preview season" on the menu
- `Challenge.swift` / `ChallengesView.swift` / `Songbook.swift` 30 challenge levels in 5 worlds, generated from working solutions (melody, fix, target), stars and unlocking; short public-domain tunes
- `LibraryView.swift` "My Songs": song cards with a course preview, rename/duplicate/delete
- `Song.swift` / `SongStore.swift` each song saved as a JSON file in Documents/Songs; first-launch migration of the old course
- `Instrument.swift` / `InstrumentSound.swift` the six instruments (bells, piano, guitar, marimba, drums, 8-bit), each note rendered once and cached
- `AttractScene.swift` the menu's background: the demo course with marbles dropping and hitting the pads
- `PadArt.swift`      how pads, the marble and a hit look (shared by the game and the menu)
- `PadController.swift` tilt dial and note buttons for the selected piece; length and bend for ramps (curved tracks the marble rolls along, defined in `Engine.swift`)
- `Celebration.swift` / `CelebrationView.swift` star rating and the end-of-song sticker
- `Backgrounds.swift` / `BackgroundViews.swift` the background list, the picker and the tinted backdrop
- `MarbleJamBackgrounds/` the 23 bundled backgrounds, all drawn from scratch: `tools/make_backgrounds.swift` paints them (command at its top) into `art/backgrounds-drawn/`, then `swift tools/prepare_backgrounds.swift` sizes them for the app
- `MarbleJamTests/`   unit tests for the rules, the controller commands and the star rating
- `Assets.xcassets`   app icon (made from `art/Logo.JPG`, kept out of git, with `tools/icon_from_logo.swift`) and menu logo (made from `art/MarbleJam.png`)
- `Title` image (game header): made from `art/Text.PNG` by `tools/title_from_art.swift` (command at its top)
- `art/seasons/<holiday>/` your holiday artwork:
  - `source.jpg` → `title.png` (menu title) via `tools/cutout_from_art.swift` (removes the white page; Halloween: `0 0 1024 1024 225 4000`, Christmas: defaults) or, for art that keeps its page, `tools/card_from_art.swift` (Thanksgiving: `70 150 884 760 56`) → `SeasonTitle-<holiday>` image
  - `icon-source.jpg` → `icon.png` via `tools/icon_from_tile.swift` (Halloween `158 110 702 FFFFFF`, Thanksgiving `168 112 744 F8F5E6`, Christmas `62 66 904 FFFFFF`) → `AppIcon-<holiday>` icon set
- `Theme.swift`      holiday colours for buttons, panels, accents and the marble (pads keep their note colours)
- `AppIcons.swift`   holiday app icons, switched automatically. To add one: make an `AppIcon-<holiday>` app icon set in `Assets.xcassets` (1024 px, no transparency; `tools/icon_from_art.swift` prepares it) and add its name to `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` in `project.yml`
- `art/`              the logo, drawn by `swift tools/make_logo.swift`, and its fonts (Luckiest Guy: Apache 2.0; Noto Music: OFL; licences next to them). Then `tools/icon_from_art.swift` (command at its top) updates the icon and menu logo

## Next steps (not built yet)
Login and store (Project B), easy mode, multiple marbles, challenge levels, store (stars + paid packs via StoreKit 2, parental gate).
