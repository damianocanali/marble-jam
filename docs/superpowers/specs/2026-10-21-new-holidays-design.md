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
| Día de los Muertos | La Cucaracha (traditional; replaces La Llorona) · La Paloma (Yradier, c. 1860; replaces Cielito Lindo) · Mambrú se fue a la guerra (traditional French, 18th c.; replaces Las Mañanitas, which had replaced La Bamba) — see Rights below |
| Christmas (older pack; one song swapped) | Jingle Bells · Deck the Halls · O Christmas Tree (traditional German; replaces We Wish You a Merry Christmas, see Rights below) · Silent Night |

Substitutions. The plan pre-approved Ode to Joy for Radetzky March and Beautiful Dreamer for Let Me Call You Sweetheart;
Beautiful Dreamer also needs a black key, so Drink to Me Only took that slot by a ruling in the SDD ledger. For La Bamba the plan's
pre-approved substitute was La Cucaracha, but that ruling replaced the plan's chain: La Bamba's best-known version is the 1958
recording (still in copyright) and it could not be transcribed, so the ruling chose Las Golondrinas (Serradell, 1862) as a farewell
song that suits the holiday, then Las Mañanitas when Las Golondrinas turned out to need a black key (A, B♭, B, C in a row in both
IMSLP editions). La Cucaracha was not tried then; it later took La Llorona's slot, and Mambrú se fue a la guerra took Las
Mañanitas' (see Rights).

Each melody is transcribed from a published score of a public-domain or traditional tune (source noted in the code), kept within
the bars' range (C4…C6, white keys; transposed where needed) and fitted so every note lands on the beat
(`testEveryHolidaySongIsAllOnTheBeat` in SeasonTests and `testEveryHolidaySongPlaysOnTheBeat` in HolidaySongTests cover every season's songs; `testSongbookTunesAreAllOnTheBeat` covers the main songbook only). Where the engine could not lay a pad out at the score's spacing,
that note's beats were lengthened to the next allowed value (the Task 1 commit lists each change, and the commit "Swap four holiday
songs whose rights are unclear" lists those of the four replacements). Other departures from the scores (octave moves, rounded rhythms,
capped holds, sections left out) are listed per song under "Departures" in the code comments. One tune rests on being traditional
rather than on a pre-1930 score, and says so beside its recipe: Molly Malone (published in 1876; the ABC read is a 1974 copy). La
Llorona and Las Mañanitas, the two others that did, have been swapped out (see Rights). Avoided as still under copyright: "Here Comes
Peter Cottontail", "Easter Parade".

### Rights

The owner's rule: keep a song only if using its bare melody (no words, recordings or arrangements; we transcribe the tune
ourselves) breaks no rule in any major market: the US, the EU, the UK, Canada, Japan, Brazil and Mexico, including Mexico's
protection of the traditional cultural expressions of Indigenous and Afro-Mexican peoples. Four songs did not clearly pass, so each
was swapped for a tune that does; the new song keeps the old one's instrument and slot. This is a reading of the statutes, not legal
advice.

The rules used. US: works published before 1931 are public domain; a work first published abroad from 1931 on without US formalities
is protected for 95 years from publication unless it was public domain at home on 1 January 1996 (Cornell's chart,
https://guides.library.cornell.edu/copyright/publicdomain). EU: life + 70, and anonymous works 70 years after they are made available
(Directive 2006/116/EC arts. 1(1) and 1(3), https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32006L0116). UK: the same
(CDPA 1988 s.12, https://www.legislation.gov.uk/ukpga/1988/48/section/12). Canada: unknown authors, s.6.1
(https://laws-lois.justice.gc.ca/eng/acts/c-42/page-2.html). Japan: anonymous works, art. 52 (https://www.cric.or.jp/english/clj/cl2.html).
Brazil: life + 70 from the next 1 January (art. 41), and unknown authors' works are public domain (art. 45 II)
(https://www.planalto.gov.br/ccivil_03/leis/l9610.htm). Mexico (LFDA, https://www.diputados.gob.mx/LeyesBiblio/pdf/LFDA.pdf):
life + 100, or 100 years from disclosure (art. 29); public-domain works and anonymous works are free to use (arts. 152-153); and
expressions of the traditional cultures of the peoples and communities of Constitution art. 2 may not be exploited "sin la
autorización por escrito del pueblo o comunidad titular" (arts. 157-158, reformed DOF 24-01-2020). The 2022 LFPPCPCIA lets those
communities claim against use without their free, prior and informed consent (art. 19,
https://www.diputados.gob.mx/LeyesBiblio/pdf/LFPPCPCIA.pdf). Mexico's term extensions were not retroactive, so authors who died
before 1952 are public domain there and later ones get life + 100
(https://commons.wikimedia.org/wiki/Commons:Copyright_rules_by_territory/Mexico).

- **La Llorona → La Cucaracha.** Out: La Llorona is a son istmeño from the Isthmus of Tehuantepec, Oaxaca, whose earliest printed
  versions are from 1935 and 1936 (Library of Congress, https://blogs.loc.gov/folklife/2021/10/picante-pero-sabroso-songs-of-la-llorona/);
  it "se arraiga principalmente en la nación zapoteca" (BBC Mundo,
  https://www.teletica.com/bbc-news-mundo/el-misterio-detras-de-la-llorona-el-himno-mexicano-que-inmortalizo-chavela-vargas_408040),
  and the SEP lists it among Oaxaca's representative songs
  (https://nuevaescuelamexicana.sep.gob.mx/contenido/recurso/canciones-representativas-de-mexico-oaxaca/). That makes it the kind of
  traditional expression LFDA arts. 157-158 and the LFPPCPCIA reserve to its community, whose consent we do not have; and with no
  print before 1931 its US status could not be shown either. In: La Cucaracha has no known author; it is named in an 1819 novel, its
  verses were printed in Spain in 1883 and on a Mexican broadside in 1915 (https://en.wikipedia.org/wiki/La_Cucaracha), Sandburg
  printed it with music in the US in 1927 (https://archive.org/details/americansongbag00sandb), and the edition read is CC0
  (https://doi.org/10.32881/book2). Anonymous and in print for well over 100 years, it is free in every market above (in Mexico under
  arts. 29 and 153). Its documented origin is Spanish and it is sung across the Spanish-speaking world, so it is not one Indigenous or
  Afro-Mexican community's expression. Only the tune and the title are used (some verses mention marijuana).
- **We Wish You a Merry Christmas → O Christmas Tree.** Out: "The famous version of the song was completely unknown outside the West
  Country before Arthur Warrell popularised it"; Oxford University Press published his arrangement in 1935, and the traditional-seeming
  recordings "are almost certainly derived" from it (https://en.wikipedia.org/wiki/We_Wish_You_a_Merry_Christmas). Warrell
  died in 1939, so his work was back in copyright in the UK from 1 January 1996, when life + 70 revived works still protected in the EEA
  (SI 1995/3297 regs. 1 and 16, https://www.legislation.gov.uk/uksi/1995/3297/regulation/16/made), so a 1935 British publication can
  be protected in the US for 95 years, to the end of 2030 (Cornell's chart). No print of the tune before 1931 was found, and the old
  recipe named no source. In: the folk tune 'Lauriger Horatius', in print with music by 1843 (Fink's Musikalischer Hausschatz;
  https://de.wikipedia.org/wiki/O_Tannenbaum), read from prints of 1911 (https://archive.org/details/onehundredfolkso00bant) and 1923
  (https://archive.org/details/uclamusic_9921601523606533). Anonymous, German and in print for over 180 years: free in every market,
  and with no tie to a Mexican community.
- **Cielito Lindo → La Paloma.** Out: it was "popularized in 1882 by Mexican author Quirino Mendoza y Cortés (c. 1862 – 1957)"
  (https://en.wikipedia.org/wiki/Cielito_Lindo). Life + 70 keeps it protected to the end of 2027 in the EU, the UK and Brazil, and
  since he died after 1952, Mexico's life + 100 keeps it to the end of 2057. In: Sebastián Iradier (1809-1865) wrote La Paloma around
  1860 (https://en.wikipedia.org/wiki/Sebasti%C3%A1n_Iradier); even life + 100 ended in 1965, and the scores read are US prints of 1878
  (https://archive.org/details/artistsvocalalbu00bost) and c. 1885 (https://imslp.org/wiki/La_paloma_(Yradier,_Sebasti%C3%A1n)). It
  is a signed Spanish composition, not a community's traditional expression, though it has been loved in Mexico since the 1860s
  (same article).
- **Las Mañanitas → Mambrú se fue a la guerra.** Out: its authorship is disputed. Spanish Wikipedia names Alejandro Manzo Salceda
  (1851-1950) and Manuel M. Ponce (1882-1948), who compiled versions, arranged it and registered it with the Sociedad de Autores y
  Compositores de México, the version that became the most popular, with the arrangement attributed to Alfonso Esparza Oteo
  (1894-1950) (https://es.wikipedia.org/wiki/Las_ma%C3%B1anitas); English Wikipedia credits Esparza Oteo alone
  (https://en.wikipedia.org/wiki/Las_Ma%C3%B1anitas). All three died before 1952, so the Mexican and European terms have most likely
  run out, but no print of this tune before 1931 was found (the 'Las mañanitas' in Hague's Spanish-American Folk-Songs, 1917, is a
  different tune: https://archive.org/details/spanishamerican00hagugoog), so its US status turns on when and where an unknown version
  was first published, and the app's notes came from modern scores. Not clearly free everywhere, so out. In: 'Malbrough s'en va-t-en
  guerre', an anonymous French song made after Malplaquet (1709), famous from 1781, and the tune of For He's a Jolly Good Fellow
  (https://en.wikipedia.org/wiki/Marlbrough_s%27en_va-t-en_guerre), read from prints of 1848
  (https://archive.org/details/chantsetchansons03unse) and c. 1900 (https://archive.org/details/chansonsdefrance00weck). Anonymous and
  in print for over 170 years, it is free in every market; it is a European song that spread through the Spanish-speaking world as
  Mambrú, not a Mexican community's expression.

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
