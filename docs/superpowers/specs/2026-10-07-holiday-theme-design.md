# Holiday Theme (colours + automatic icon) — Design and Plan

Date: 2026-10-07 · Approved in chat (holiday-look design, parts 1 and 3). Title artwork (part 2) shipped in PR #7.

## Goal

During a holiday the app's controls take the holiday's colours, the marble glows in a holiday tint, and the app icon
switches to a holiday version (when one is bundled), switching back afterwards.

## Decisions

- Scope: menu, My Songs and the game UI (buttons, panels, accents, marble). Pads keep their note colours.
- Icon: switched automatically by date, using iOS alternate icons. iOS shows its own "You have changed the icon"
  notice; apps can't hide it. Holiday icons are the user's own art; until one is bundled, nothing switches.

## Design

`Theme` (pure, in `Theme.swift`): `primary`, `primaryText`, `chipFill`, `chipStroke`, `accent`, `marbleGlow` as RGB values,
with SwiftUI/UIKit colour helpers. `Theme.standard` is today's look (cyan, navy). `Theme.forSeason(_ id: String?)`:

| Season | primary | chip fill | chip stroke / accent | marble glow |
|---|---|---|---|---|
| none | cyan #3FD7F5 | navy #0E1226 | white 18% / cyan | ice blue #9ED4FF |
| halloween | orange #FF7A1A | deep purple #2A0F45 | violet #B070FF | orange #FF9A3C |
| thanksgiving | amber #F2A33A | brown #3A1E10 | gold #E8B04A | amber #FFC27A |
| christmas | red #D63A3A (white text) | pine #0F3A26 | gold #E8C45A | gold #FFE08A |

- The theme flows through a SwiftUI environment value `\.theme`, set once in `RootView` from the live season (DEBUG preview
  included). `Chip` (all buttons), the picker's selection ring, the pad controller's dial needle and section accents read it.
- The game scene and the menu demo get the theme's marble glow (`RunScene.theme`, `AttractScene.theme`).
- Primary text must stay readable: contrast ratio ≥ 4.5 between `primary` and `primaryText` (tested).

`AppIcons` (pure + one UIKit call):
- `AppIcons.name(for season: String?, available: Set<String>) -> String?` — `"AppIcon-<season>"` if that icon is bundled,
  else `nil` (the main icon).
- `AppIcons.available` reads the bundled alternate icon names from the Info.plist (`CFBundleIcons` → `CFBundleAlternateIcons`).
- `RootView`, when the app becomes active, asks for the right icon and calls `setAlternateIconName` only if it differs from
  the current one (so the iOS notice appears only when the holiday starts or ends).
- Adding a holiday icon later: an `AppIcon-<season>` app icon set in `Assets.xcassets` (made with `tools/icon_from_logo.swift`
  or `icon_from_art.swift`) and its name in `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` in `project.yml`. README explains.

## Plan (TDD, one branch `holiday-theme`)

1. `ThemeTests`: standard for nil/unknown; each season differs from standard and from each other; contrast ≥ 4.5 for every theme. → `Theme.swift`.
2. `AppIconTests`: name for a season with/without a bundled icon; nil season → nil. → `AppIcons.swift`.
3. Wire: environment value; `Chip`, picker ring, dial needle, accents; `RootView` sets theme and switches icon on `.active`;
   scenes take `marbleGlow`. README.
4. Screenshots with the DEBUG preview for each season (menu, My Songs, game). Full test run.

## Out of scope

The icon artwork itself (the user's), pad recolouring, holiday games, marble skins.
