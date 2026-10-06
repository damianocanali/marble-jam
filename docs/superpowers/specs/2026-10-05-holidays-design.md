# Holiday Packs — Design

Date: 2026-10-05 · Builds on Open Play (branch `open-play`, PR #4).

## Goal

Seasonal packs (songs and backgrounds) made in advance and switched on automatically around each holiday,
so the game feels alive through the year. First packs: Halloween, Thanksgiving, Christmas.

## Decisions (from brainstorming)

- Release: packs are built into the app; each holiday has a yearly date window and switches on by itself on the device.
  No server. New packs ship in app updates a few weeks before their holiday.
- After the window: songs the player took from a holiday shelf stay in My Songs forever; holiday backgrounds and the
  holiday shelf hide until next year.
- Presentation: a festive banner on the menu, the holiday background on the menu by default (unless the player chose one),
  a holiday shelf at the top of My Songs, holiday backgrounds first in the picker.
- Catalogue lives in Swift code (type-checked, tested), not JSON. Moving to JSON/server later is a separate step.
- Out of scope: holiday games (need Challenges), holiday marble skins (need Store), App Store In-App Events (marketing),
  more holidays (New Year, Valentine's, Easter: later entries in the same catalogue).

## 1. Seasons and the calendar

`struct Season: Identifiable` — `id` ("halloween", "thanksgiving", "christmas"), `title`, `emoji`, `banner` text,
`songs: [SongRecipe]`, `backgrounds: [String]` (background ids in the manifest), and a window rule.

Windows (inclusive, local calendar):
- **Halloween**: Oct 1 – Nov 1.
- **Thanksgiving**: Nov 2 – the day after US Thanksgiving (4th Thursday of November).
- **Christmas**: Dec 1 – Jan 6 (crosses the new year).

`Seasons.active(on: Date, calendar: Calendar) -> Season?` is pure. If two windows ever overlap, the first in catalogue order wins.

**Preview**: in DEBUG builds only, the menu shows a small "Preview season" menu (None / each season / Off-season)
that overrides the date. Release builds never show it. The override is kept in `UserDefaults` (`season.preview`), DEBUG only.

## 2. Holiday songs

`SongRecipe` — `name`, `instrument`, `melody: [(beats: Double, note: Int)]` (beats since the previous note, in
multiples of 0.5; `note` is the bar note index 0…14 = C4…C6 on the white keys, as in `Engine.demo()`).

- `SongRecipe.course() -> Course` lays the melody out with `Engine.smartAdd`, exactly like the Twinkle demo.
  Every recipe must place every note on the beat (enforced by tests).
- Melodies are the opening phrase (about 11–17 notes) of public-domain tunes; hymn openings checked against the
  hymnary.org incipits (KREMSER 55653 45432 31556, ST. GEORGE'S WINDSOR 33531 23335 31233, SIMPLE GIFTS 55112 31345 55321).
  Rhythms are simplified to half-beat steps. Gounod's Marionette, Danse Macabre and Over the River were dropped because
  their melodies couldn't be checked against a source. Minor-key tunes are arranged in A minor
  (white keys only); chromatic notes are simplified to the nearest white key. The arrangements are our own.

| Season | Songs (composer, year) | Instrument |
|---|---|---|
| 🎃 Halloween | In the Hall of the Mountain King (Grieg, 1875), Toccata and Fugue in D minor (Bach, c. 1704), Funeral March (Chopin, 1839) | 8-bit, piano, marimba |
| 🦃 Thanksgiving | We Gather Together (Dutch, 1626 / Kremser 1877), Come, Ye Thankful People, Come (Elvey, 1858), Simple Gifts (Brackett, 1848) | guitar |
| 🎄 Christmas | Jingle Bells (Pierpont, 1857), Deck the Halls (Welsh trad.), We Wish You a Merry Christmas (English trad.), Silent Night (Gruber, 1818) | bells |

## 3. Holiday backgrounds

Drawn in code by `tools/make_backgrounds.swift` (no stock art), then sized by `tools/prepare_backgrounds.swift`.
The manifest gains an optional `"season"` field (file names `NN-<season>-<name>.png`, e.g. `24-halloween-pumpkin-patch.png`).

- Halloween: **pumpkin patch** under a full moon, **haunted house** silhouette on a hill, **purple fog with bats**.
- Thanksgiving: **autumn leaves** falling, **cornfield sunset**, **harvest table** (plaid cloth, pumpkins, corn, pie).
- Christmas: **snowy night village**, **Christmas lights** (strings of coloured bulbs on dark), **snowflakes** on blue.

`BackgroundOption` gains `season: String?`. `BackgroundLibrary.available(season:)` returns all-year backgrounds plus
the active season's (season ones first). If the selected background is off-season, the app shows the night sky
(the saved choice is kept; it comes back next year).

## 4. Where it shows

- **Menu**: under the lettering, while a season is live, a banner pill: "🎃 Halloween is here!", "🦃 Happy Thanksgiving!",
  "🎄 Merry Christmas!". The menu's backdrop uses the season's first background when the player never chose one
  (`background.v1` is empty).
- **My Songs**: while a season is live, a shelf at the top titled with the emoji and season name, showing its songs as
  `SongCard`s (built from the recipes). Tapping one saves a new song (the player's copy, named after the recipe; a
  second copy is named "<name> copy") and opens it. Copies are ordinary songs: they stay after the season.
  Below the shelf, a "Your songs" heading over the existing grid.
- **Background picker**: shows `available(season:)`, so holiday backgrounds appear first during their season.

## 5. Errors and edge cases

- A recipe whose melody can't be laid out fully (a note can't be placed on the beat) must fail its unit test; at run time
  the shelf shows the course as far as it was placed.
- Device date changes while the app is open: the season is re-checked when the menu or My Songs appears.

## Testing

Unit tests:
- `Seasons.active`: a date inside and outside each window; Halloween's first and last day; Thanksgiving's date for 2026
  (Nov 26), 2027 (Nov 25), 2028 (Nov 23) and the day after; Christmas on Dec 31 and Jan 6 (active) and Jan 7 (not);
  an off-season date in summer returns nil.
- Every recipe: its course has exactly one hit per melody note, every hit on the beat, in melody order.
- Shelf copy: taking a recipe creates a normal song with the recipe's name, instrument and course; taking it twice gives "<name> copy".
- `BackgroundLibrary.available`: off-season holiday backgrounds hidden, active-season ones listed first.

Simulator screenshots (using the DEBUG preview): menu banner + holiday backdrop for each season, My Songs shelf,
picker order, and one holiday song open in the builder.
