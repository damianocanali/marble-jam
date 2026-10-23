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

## Songs (holiday shelf, 3 each, all public domain or traditional)

| Holiday | Songs |
|---|---|
| New Year's Eve | Auld Lang Syne · The Blue Danube (Strauss II) · Ode to Joy (Beethoven; replaces Radetzky March, whose theme needs ten pitch classes, the bars have seven) |
| Valentine's Day | Plaisir d'amour (Martini, composed 1784, published 1785) · Drink to Me Only with Thine Eyes (traditional English, 18th c.; replaces Let Me Call You Sweetheart, which needs a black key in every transposition) · Aura Lee (1861; replaces Für Elise, whose opening needs the black key D♯) |
| St. Patrick's Day | Molly Malone · The Irish Washerwoman · Londonderry Air |
| Easter | Hot Cross Buns · Christ the Lord Is Risen Today (Easter Hymn, 1708) · Spring (Vivaldi, The Four Seasons) |
| Día de los Muertos | La Llorona · Cielito Lindo (Mendoza, 1882) · Las Mañanitas (traditional Mexican; replaces La Bamba, see below) |

Substitutions. The plan pre-approved Ode to Joy for Radetzky March and Beautiful Dreamer for Let Me Call You Sweetheart;
Beautiful Dreamer also needs a black key, so Drink to Me Only took that slot by a ruling in the SDD ledger. For La Bamba the plan's
pre-approved substitute was La Cucaracha, but that ruling replaced the plan's chain: La Bamba's best-known version is the 1958
recording (still in copyright) and it could not be transcribed, so the ruling chose Las Golondrinas (Serradell, 1862) as a farewell
song that suits the holiday, then Las Mañanitas when Las Golondrinas turned out to need a black key (A, B♭, B, C in a row in both
IMSLP editions). La Cucaracha was not tried; swapping it in later is one recipe.

Each melody is transcribed from a published score of a public-domain or traditional tune (source noted in the code), kept within
the bars' range (C4…C6, white keys; transposed where needed) and fitted so every note lands on the beat
(`testEveryHolidaySongIsAllOnTheBeat` in SeasonTests and `testEveryHolidaySongPlaysOnTheBeat` in HolidaySongTests cover every season's songs; `testSongbookTunesAreAllOnTheBeat` covers the main songbook only). Where the engine could not lay a pad out at the score's spacing,
that note's beats were lengthened to the next allowed value (the Task 1 commit lists each change). Other departures from the scores
(octave moves, rounded rhythms, capped holds, sections left out) are listed per song under "Departures" in the code comments. Three
tunes rest on being traditional or 19th-century rather than on a pre-1930 score, and say so beside their recipe: Molly Malone (published
in 1876; the ABC read is a 1974 copy), La Llorona (traditional, earliest prints 1935-36; read from a modern ABC export) and Las Mañanitas
(traditional, authorship disputed; read from a Wikipedia score and a 2024 CC0 edition). Avoided as still under copyright: "Here Comes
Peter Cottontail", "Easter Parade".

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
