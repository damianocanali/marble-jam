# Five New Holidays — Design

Date: 2026-10-21 · Holidays: New Year's Eve, Valentine's Day, St. Patrick's Day, Easter, Día de los Muertos.
The artist supplied one icon and one background for each (art/seasons/<id>/icon-source.jpg, art/backgrounds-artist/).

## Decisions

- Each new holiday gets everything the existing three (Halloween, Thanksgiving, Christmas) have: dates, banner, theme colours,
  alternate app icon, title lettering, a default background, three public-domain songs, a 6-level challenge world, a reward
  marble and a Game Center achievement.
- The New Year's Eve icon keeps the "2027" drawn in the art; the artist replaces it each year.
- Holiday windows never overlap (checked by a test over 100 years), so the order of `Seasons.all` doesn't matter. New
  seasons are appended after the existing three, which keeps `Seasons.all[0...2]` (used by the level lists) unchanged.

## Dates

| id | Title | Window (both days included) |
|---|---|---|
| `newyear` | New Year's Eve 🎆 | Dec 31 – Jan 6 (Christmas becomes Dec 1 – Dec 30) |
| `valentines` | Valentine's Day 💘 | Feb 1 – Feb 14 |
| `stpatricks` | St. Patrick's Day ☘️ | Mar 1 – Mar 17 |
| `easter` | Easter 🐣 | max(Easter Sunday − 14 days, Mar 18) – Easter Monday |
| `halloween` | Halloween 🎃 | Oct 1 – Oct 31 (was Nov 1) |
| `muertos` | Día de los Muertos 🌼 | Nov 1 – Nov 7 |
| `thanksgiving` | Thanksgiving 🦃 | Nov 8 – the day after Thanksgiving (was Nov 2) |

Easter Sunday: Western (Gregorian) date by the anonymous Gregorian algorithm (Meeus/Jones/Butcher), `Seasons.easter(year:calendar:)`,
like `Seasons.thanksgiving`. New Year's Eve crosses the year like Christmas did; `active(on:)` already checks last year's windows.

Banners: "🎆 Happy New Year!", "💘 Happy Valentine's Day!", "☘️ Happy St. Patrick's Day!", "🐣 Happy Easter!",
"🌼 ¡Feliz Día de los Muertos!".

## Look

- **Theme** (`Theme.forSeason`): primary button, chip fill/stroke, accent and marble glow taken from each icon's palette;
  primary text must reach WCAG 4.5 on the primary (existing contrast test covers every season).
- **App icons:** `AppIcon-<id>` sets from the artist's icons, cropped to the tile with `tools/icon_from_tile.swift` (vetted by
  agent + two reviewers), listed in `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`. `AppIcons` switches automatically.
- **Titles:** `SeasonTitle-<id>` from `tools/make_title.swift` (the artist's lettering masks in holiday colours) with greetings
  HAPPY NEW YEAR · HAPPY VALENTINE'S DAY · HAPPY ST. PATRICK'S DAY · HAPPY EASTER · DÍA DE LOS MUERTOS (the font has Í).
- **Backgrounds:** bg-41 … bg-45, tagged with the holiday (`NN-<id>-name.jpg` in art/backgrounds-artist), so each holiday opens
  on the artist's background. bg-40 (Marble Track, the everyday background) lands first.

## Songs (holiday shelf, 3 each, all public domain)

| Holiday | Songs |
|---|---|
| New Year's Eve | Auld Lang Syne · The Blue Danube (Strauss II) · Radetzky March (Strauss I) |
| Valentine's Day | Plaisir d'amour (Martini, 1784) · Let Me Call You Sweetheart (Friedman, 1910) · Für Elise (Beethoven) |
| St. Patrick's Day | Molly Malone · The Irish Washerwoman · Londonderry Air |
| Easter | Hot Cross Buns · Christ the Lord Is Risen Today (Easter Hymn, 1708) · Spring (Vivaldi, The Four Seasons) |
| Día de los Muertos | La Llorona · Cielito Lindo (Mendoza, 1882) · La Bamba (traditional son jarocho) |

Each melody is transcribed from a published public-domain score (source noted in the code), kept within the bars' range
(C4…C6, white keys; transposed where needed) and fitted so every note lands on the beat (`testSongbookTunesAreAllOnTheBeat`
covers every season's songs). Avoided as still under copyright: "Here Comes Peter Cottontail", "Easter Parade".

## Challenge worlds

Worlds 9–13 in `Challenges.holiday`, same six-level pattern as the existing holiday worlds (melody `.near` with one missing
note on a short phrase → fix with spread 0.6 → target `.mirrored` → melody `.mirrored` → fix → target with a ramp), built
from that holiday's songs. `holidayWorlds` gains `newyear: 9, valentines: 10, stpatricks: 11, easter: 12, muertos: 13`;
`worldNames` gains "🎆 New Year", "💘 Valentine's", "☘️ St. Patrick's", "🐣 Easter", "🌼 Día de los Muertos". Open only
during the holiday, like the others. All existing level tests (solution 3★, start 0★, untouched tray never wins, cups inside
the screen, difficulty never decreases, holiday opener short) run over the new worlds.

## Rewards and Game Center

- One reward marble per holiday, drawn in code (`Skins.all`, unlock `.holiday(id)`): **Fireworks** (New Year), **Sweetheart**
  (Valentine's), **Four-Leaf Clover** (St. Patrick's), **Easter Egg** (Easter), **Marigold** (Día de los Muertos).
- Game Center achievements `marblejam.world9` … `marblejam.world13` come for free (`GameCenter.finishedWorlds` reads
  `holidayWorlds`); the leaderboard score includes the new worlds' stars. The developer creates the 5 achievements in
  App Store Connect.

## Testing

- Easter dates for known years (2024-03-31, 2025-04-20, 2026-04-05, 2027-03-28, 2028-04-16, 2038-04-25, 2285-03-22).
- No two windows overlap for 2026–2126; each holiday's own day falls inside its window; spot checks for the moved edges
  (Oct 31 Halloween, Nov 1 Muertos, Nov 8 Thanksgiving, Dec 30 Christmas, Dec 31 / Jan 6 New Year).
- Every season has: an alternate icon in the bundle, a title image, a theme passing contrast, exactly one holiday reward skin,
  a 6-level world, songs on the beat, at least one tagged background.
- Existing name test (no old names in player-facing text) covers the new strings.
- Visual: simulator menu screenshot in each new season (DEBUG preview).

## Out of scope

Holiday 3D rooms, translations of the UI, regional variants (e.g. Orthodox Easter).
