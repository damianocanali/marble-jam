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
- `MenuView.swift`    start screen: logo, Play, Demo, Store/Sign in (coming soon)
- `PadController.swift` tilt dial and note buttons for the selected pad
- `Celebration.swift` / `CelebrationView.swift` star rating and the end-of-song sticker
- `Backgrounds.swift` / `BackgroundViews.swift` the background list, the picker and the tinted backdrop
- `MarbleJamBackgrounds/` the 23 bundled backgrounds, all drawn from scratch: `tools/make_backgrounds.swift` paints them (command at its top) into `art/backgrounds-drawn/`, then `swift tools/prepare_backgrounds.swift` sizes them for the app
- `MarbleJamTests/`   unit tests for the rules, the controller commands and the star rating
- `Assets.xcassets`   app icon (made from `art/Logo.JPG`, kept out of git, with `tools/icon_from_logo.swift`) and menu logo (made from `art/MarbleJam.png`)
- `art/`              the logo, drawn by `swift tools/make_logo.swift`, and its fonts (Luckiest Guy: Apache 2.0; Noto Music: OFL; licences next to them). Then `tools/icon_from_art.swift` (command at its top) updates the icon and menu logo

## Next steps (not built yet)
Login and store (Project B), easy mode, multiple marbles, challenge levels, store (stars + paid packs via StoreKit 2, parental gate).
