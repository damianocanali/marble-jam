# Marble Beats 1.0: App Store Connect listing

Everything to type or choose in App Store Connect for the first submission of **Marble Beats** (bundle ID `com.marblejam.app`, version 1.0). Each text field is in its own code block, ready to copy, with its length against the current limit.

- **Facts:** every number was checked against `facts.json` (made from `main` at `74196ff`) and then re-checked against the code on `main` at `ac9ea64`. Since `74196ff`, PR #25 swapped four songs: La Llorona → La Cucaracha, Cielito Lindo → La Paloma, Las Mañanitas → Mambrú se fue a la guerra, We Wish You a Merry Christmas → O Christmas Tree. No count changed (still 78 levels, 13 worlds, 41 marbles, 32 arrangements). `facts.json` still lists the old titles; this file uses the new ones.
- **Counting:** a character is one Unicode code point, so `í` and `–` count as 1. Bytes are UTF-8, where they count as 2 and 3. Line breaks count as 1. A script computed every count below.
- **Assets:**
  - `MarbleBeats-appstore/game-center/` holds the 14 Game Center images (`world1.png`…`world13.png` and `leaderboard.png`). All 14 were checked: 1024 × 1024, RGB, no alpha, 72 ppi, and each badge is labelled with its world.
  - `MarbleBeats-appstore/final/` (both device folders) was still empty when this was committed. Section 9 proposes the file names and order; match it to the captures when they land.

## 0. Limits used (October 2026)

| Field | Limit | Source |
|---|---|---|
| App name | 2–30 characters | [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information) |
| Subtitle | 30 characters | same |
| Promotional text | 170 characters, changeable at any time without review | [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information) |
| Description | 4000 characters | same |
| Keywords | 100 bytes | same |
| What's New | 4000 characters; not shown for the first version | same |
| App Review notes | 4000 bytes | same |
| Copyright | "year + owner"; the © symbol is added automatically | same |
| IAP reference name / display name / description | 64 / 2–30 / 45 characters | [In-App Purchase information](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information) |
| Achievements | at most 100 per achievement and 1000 per game; 1024 × 1024 image | [Achievements](https://developer.apple.com/help/app-store-connect/reference/game-center/achievements/) |
| Achievement title and descriptions | no length limit is published; the form sets its own. Titles here are ≤ 30 characters and descriptions ≤ 100 | same |
| Leaderboard | ID ≤ 100 characters; integer format; best score; sort order; optional score range | [Leaderboards](https://developer.apple.com/help/app-store-connect/reference/game-center/leaderboards/) |
| Screenshots | 1–10 per device size; required: iPhone "Dynamic Island (medium display)" and iPad 13-inch | [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) |

---

## 1. App Information (app level)

### Name (12 / 30 characters)

```
Marble Beats
```

### Subtitle (27 / 30 characters)

```
Marble runs that play music
```

I chose this over "Build marble runs that sing" (27). The App Store indexes subtitle words for search, so this one covers *runs*, *play* and *music*, and the keywords don't have to repeat them. It also matches the website headline, "Build a marble run that plays music".

### Privacy Policy URL

```
https://marblebeats.com/privacy/
```

### Category

- **Primary category:** Games
- **Game subcategories:** Family (first), Music (second)
- **Secondary category:** Music

This is the Family game subcategory. It is **not** the Kids Category, so leave **Made for Kids** unticked. Once the Kids choice is approved it can't be undone, and every later update would have to follow the Kids rules.

### Content Rights

Choose **"Yes, it contains, shows, or accesses third-party content"**, then confirm **"I have the necessary rights"**. The app's third-party content is:

- **Melodies:** public-domain or traditional tunes, newly arranged for the game. Each holiday song's source and rights basis are noted in `HolidaySongs.swift` / `Seasons.swift` and in the Rights notes of `docs/superpowers/specs/2026-10-21-new-holidays-design.md`. Every sound is synthesised by the app; there are no recordings.
- **Fonts:** Luckiest Guy (Apache 2.0) and Noto Music (SIL OFL), used only in the baked logo and title images. The licences are in `art/fonts/`.
- **Art:** the artist's own work: the app icon and the 8 holiday icons, the "MARBLE BEATS" lettering, and backgrounds bg-33 to bg-45. Backgrounds bg-01 to bg-32 and all 41 marbles are drawn by code. Keep the artist's written permission on file.

### Age rating

See section 6 (expected result: **4+**).

---

## 2. Version 1.0: product page text

### Promotional text (160 / 170 characters)

For launch (correct any day in October or November):

```
Holiday worlds open through the year: Halloween, Día de los Muertos and Thanksgiving this autumn, then Christmas. Build a marble run and hear it play your song.
```

Promotional text can change at any time without review. To keep it seasonal, paste the line for each holiday on the first day of its window:

| From | Line | Length |
|---|---|---|
| Oct 1 | see block `promo_halloween` | 150 / 170 |
| Nov 1 | see block `promo_muertos` | 153 / 170 |
| Nov 8 | see block `promo_thanksgiving` | 166 / 170 |
| Dec 1 | see block `promo_christmas` | 169 / 170 |
| Dec 31 | see block `promo_newyear` | 143 / 170 |
| Feb 1 | see block `promo_valentines` | 154 / 170 |
| Mar 1 | see block `promo_stpatricks` | 167 / 170 |
| Easter window (2027: Mar 18) | see block `promo_easter` | 155 / 170 |
| Between holidays | see block `promo_offseason` | 164 / 170 |

`promo_halloween`
```
Halloween is here! Six holiday levels, In the Hall of the Mountain King on the marble run, and a Jack-o'-lantern marble to win. Open until October 31.
```

`promo_muertos`
```
¡Feliz Día de los Muertos! Play La Cucaracha and La Paloma on the marble run, finish 6 holiday levels and win the Marigold marble. Open until November 7.
```

`promo_thanksgiving`
```
Happy Thanksgiving! Build runs for We Gather Together and Simple Gifts, finish 6 holiday levels and win the Autumn Leaf marble. Open until the day after Thanksgiving.
```

`promo_christmas`
```
Merry Christmas! Jingle Bells, Deck the Halls, O Christmas Tree and Silent Night are on the marble run, with 6 holiday levels and a Snow Globe marble. Until December 30.
```

`promo_newyear`
```
Happy New Year! Ring it in with Auld Lang Syne and The Blue Danube, finish 6 holiday levels and win the Fireworks marble. Open until January 6.
```

`promo_valentines`
```
Happy Valentine's Day! Play Plaisir d'amour and Aura Lee on the marble run, finish 6 holiday levels and win the Sweetheart marble. Open until February 14.
```

`promo_stpatricks`
```
Happy St. Patrick's Day! Molly Malone and The Irish Washerwoman are on the marble run, with 6 holiday levels and a Four-Leaf Clover marble to win. Open until March 17.
```

`promo_easter`
```
Happy Easter! Hot Cross Buns and Vivaldi's Spring are on the marble run, with 6 holiday levels and an Easter Egg marble to win. Open through Easter Monday.
```

`promo_offseason`
```
Build a marble run that plays music: 30 levels all year, six instruments and songs of your own. Holiday worlds come back with each holiday, starting with Halloween.
```

### Description (3892 / 4000 characters)

```
Build a marble run that plays music. Place the pads, drop the marble, and every pad it hits plays a note. Make up your own songs or solve challenge levels, on your own or together. Made for the whole family.

HOW IT WORKS
• Place the pads. Tap + Pad and the new pad lands right where the marble will be on the beat. Drag it, tilt it and change its note: longer bars play lower notes. A dotted line shows where the marble will go.
• Drop the marble. Watch it roll from pad to pad in a little 3D room with soft light and shadows. Every hit flashes and throws sparks, and pads hit right on the beat glow gold.
• Hear your song. Every hit plays a note, so the run becomes your tune. A finished song earns up to three stars for keeping the beat.

CREATE MODE
Start a new song, or open Twinkle Twinkle, the starter song that's ready to play. Build with pads, round bumpers and curved ramps you can stretch and bend. Give each song one of six instruments: bells, piano, guitar, marimba, drums or 8-bit. Every sound is made by the app itself. Undo remembers your last 40 steps, and your songs wait for you in My Songs. Paint the back wall with one of 28 all-year backgrounds, or a holiday one in season.

78 CHALLENGE LEVELS IN 13 WORLDS
Five main worlds are there all year, with 30 levels: First Notes, Fix It, Bullseye, Ramps and Maestro. Eight holiday worlds add 48 more, six levels each, and each one opens only during its holiday. Three kinds of puzzle:
• Melody: place the missing notes so the tune plays.
• Fix: move the loose pads so every note plays on the beat.
• Target: get the marble into the cup.
Each level gives up to three stars, and stars open the next level and the next world.

EIGHT HOLIDAYS THROUGH THE YEAR
When a holiday starts, the game changes with it: its own world of six levels, three or four ready-made songs, backgrounds, colours, title art, app icon and a reward marble. Holiday worlds and songs appear only in season, and they come back every year:
• Halloween: October 1–31
• Día de los Muertos: November 1–7
• Thanksgiving: November 8 to the day after US Thanksgiving
• Christmas: December 1–30
• New Year's Eve: December 31 to January 6
• Valentine's Day: February 1–14
• St. Patrick's Day: March 1–17
• Easter: up to two weeks before Easter Sunday, through Easter Monday
The dates follow your device's clock and time zone.

41 MARBLES TO COLLECT
Every marble is drawn by the game, and the one you choose is the one that rolls. 17 cost nothing: Classic to start, 8 earned with stars from the main worlds, and 8 holiday marbles, each won with a star on every level of that holiday's world while it's open. The other 24 come in six optional packs of four: Glass, Space, Sports, Candy, Gem and Animal.

ON ALL YOUR DEVICES
Signed in to iCloud, your songs, challenge stars and chosen marble follow you to your other iPhone and iPad. Sign in to Game Center if you like, for a total-stars leaderboard and an achievement for every world you finish.

FOR PARENTS
• No ads, no tracking and no data collected. No accounts or sign-up, and no camera, microphone or location access.
• Holiday reminders are optional: the game offers them once, after the first challenge win, and they never arrive at night. Turn them off any time under Notifications on the Account screen.
• A grown-up question comes before anything is bought: a multiplication written in words, answered on a number pad. Ask to Buy works too, so the purchase waits for your approval.
• Every level, song, instrument and holiday is included. The only things to buy are six optional marble packs: one-time purchases that change only how the marble looks. No subscriptions.
• With Reduce Motion on, the menu demo holds still, the camera doesn't swing and the celebration sticker doesn't spin.

For iPhone and iPad, in portrait. Requires iOS or iPadOS 17 or later. English only.
Questions? support@marblebeats.com
```

What the description deliberately leaves out, per `facts.json` and the guidelines:

- **"For kids" / "for children":** Guideline 1.3 reserves those terms for the Kids Category.
- **Prices and the word "free":** prices differ by storefront.
- **"All 78 levels any time":** the 48 holiday levels are seasonal.
- **"41 free marbles":** 24 of them need a pack.
- **Family Sharing:** add the optional sentence in section 8 only if you turn it on.
- **"Works offline":** the code has no networking, but this was never tested in airplane mode.
- **VoiceOver:** only some controls have labels.

### Keywords (97 / 100 bytes)

```
rhythm,song,melody,xylophone,piano,drum,instrument,physics,notes,composer,toy,halloween,christmas
```

The keywords use commas with no spaces, are ASCII only, and repeat no word from the name or subtitle (marble, beats, runs, play, music). They include no category names (games, family, music, puzzle), no competitor or trademarked names, and no "free" or "kids". "Halloween" and "Christmas" are there because both holidays have built-in worlds.

### Support URL

```
https://marblebeats.com/support/
```

### Marketing URL

```
https://marblebeats.com/
```

All three URLs returned HTTP 200 on 23 October 2026.

### Copyright

```
2026 Damiano Canali
```

Type it without "©": App Store Connect adds the symbol itself.

### What's New in This Version

Not needed. App Store Connect doesn't show this field for an app's first version. It is required from 1.0.1 on.

### Version, build, release

- **Version:** 1.0 (`MARKETING_VERSION`). **Build:** 1 (`CURRENT_PROJECT_VERSION`).
- **Release:** "Manually release this version" lets you choose the launch day, for example the start of a holiday window. Automatic release is fine too.

---

## 3. App Review Information

- **Sign-in required:** No (untick it). The app has no accounts.
- **Contact information:** you fill in your first name, last name and phone number. Give the phone in international format with "+" and the country code; the field rejects digits only. Email: your own address, or `support@marblebeats.com`.
- **Attachment:** none needed. Halloween (then Día de los Muertos) is live while the app is in review. Optional extras if Apple asks:
  - **Menus:** `MarbleBeats-site-raw/menu-<holiday>.png` already covers all eight holiday menus (1206 × 2622, no debug chip).
  - **Challenges:** capture each holiday's Challenges screen with `-mbScreen challenges -mbSeason <id>`. The ids are halloween, muertos, thanksgiving, christmas, newyear, valentines, stpatricks and easter.
  - **Recording:** record a holiday level being played with `xcrun simctl io <UDID> recordVideo holiday.mp4`.
  - Apple suggests a direct link to an `.mp4` file as the best way to share a demo video. An attachment also works, but it has to be uploaded again with each version.

### Notes (3434 / 4000 bytes)

```
Marble Beats is a music game for the whole family. No login or account is needed: tap Challenges or Create on the menu to play.

STORE AND GROWN-UP QUESTION
1. On the menu, tap Store.
2. Scroll down to any marble pack and tap its price button.
3. An "Ask a grown-up" alert asks a multiplication written in words, for example "What is seven times eight?". Type the answer on the number pad and tap Continue. The answer is always the product of the two numbers (here 56); each number is six, seven, eight or nine.
4. After a right answer the App Store purchase sheet appears. A wrong answer cancels with "Purchases need a grown-up."
Restore is at the top right of the Store and on the Account screen. Ask to Buy is supported: a pending purchase shows "Waiting for a grown-up to approve the purchase." The six packs are non-consumable and only change how the marble looks; no level, song or feature is behind a purchase.

SEASONAL CONTENT (Guideline 2.5.19)
Nothing is hidden or dormant, and there is no server or remote switch: the app has no networking code and picks the holiday on the device from the date (Gregorian calendar, device time zone). Eight holidays are built in. Each adds a Challenges world of 6 levels (listed first on the Challenges screen, level 1 open at once), 3 or 4 ready-made songs on the My Songs screen (Create), backgrounds, a colour theme, title art, an alternate app icon and a reward marble. Windows, both days included:
- Halloween: Oct 1-31 (world 6)
- Día de los Muertos: Nov 1-7 (world 13)
- Thanksgiving: Nov 8 to the day after US Thanksgiving, the 4th Thursday of November (2026: Nov 8-27) (world 7)
- Christmas: Dec 1-30 (world 8)
- New Year's Eve: Dec 31-Jan 6 (world 9)
- Valentine's Day: Feb 1-14 (world 10)
- St. Patrick's Day: Mar 1-17 (world 11)
- Easter: 14 days before Easter Sunday, never before Mar 18, through Easter Monday (2027: Mar 18-29) (world 12)
Outside the windows the app shows its everyday look and the 5 main worlds (30 levels).
The release build has no setting to change the holiday. From Oct 1 to Jan 6 a holiday is live every day except Nov 28-30, 2026, so you will see one during review: Halloween until Oct 31, then Día de los Muertos from Nov 1. The same windows are listed in the App Store description and in the Game Center achievement descriptions.
When a holiday starts or ends the app switches its icon, and iOS shows its own "You have changed the icon" alert. Tap OK. The icon is never switched on the very first launch, so on a fresh install the alert appears at the earliest on the next return to the app.

ACCOUNTS AND SERVICES
- No login, sign-up or account.
- Game Center is optional: Account > Sign in to Game Center. One leaderboard (total stars, 0-234) and 13 achievements, one per world. Nothing is sent unless the player signs in.
- iCloud is optional: if the device is signed in, songs, stars and the chosen marble sync between the player's devices. Otherwise everything stays on the device.
- No ads, analytics, tracking or third-party SDKs. The only permission asked is notifications: after the first challenge win, a card offers holiday reminders (local notifications only: each holiday's start, a few days before it ends, and one come-back nudge; never at night). Off by default; Account > Notifications turns them off.
- Privacy policy: in the app (Account > Privacy policy) and at https://marblebeats.com/privacy/
Contact: support@marblebeats.com
```

These notes were checked against the code:

- **The grown-up question:** `ParentalGate` (`Store.swift`) builds "What is \<six…nine\> times \<six…nine\>?". That gives 16 possible questions, with answers from 36 to 81. The answer is typed into a `.numberPad` text field (`StoreView.swift`).
- **The season:** `Seasons.current(on: Date(), preview: "")` in release builds (`RootView.swift`). The preview switch exists only under `#if DEBUG`.
- **Holiday levels:** `isUnlocked` opens level 1 of a live holiday world right away.

The device clock does decide the season. A reviewer who set the date by hand (Settings › General › Date & Time) and reopened the app would see that holiday. I left this out of the notes because Review isn't expected to change the device date. If you want to offer it, add one sentence to the notes.

---

## 4. In-App Purchases (6 non-consumables)

Shared settings for all six packs:

- **Type:** Non-Consumable.
- **Availability:** same as the app.
- **Tax category:** the default.
- **Family Sharing:** see section 8. Decide before you save, because it can't be turned off afterwards.
- **First submission:** in-app purchases have to go with an app version. On the 1.0 version page, under **In-App Purchases and Subscriptions**, select all six before you submit.

The display names and descriptions match `MarbleJam/Products.storekit` exactly. `ReleaseTests.testPacksFitAppStoreConnectLimits` already checks those against the 30 and 45 character limits.

**Prices:** the suggested prices are the test-store prices in `Products.storekit`, with the United States as the base storefront. App Store Connect sets the other storefronts' prices from the base price.

**Review screenshot, all six packs:** use the Store screen scrolled so that pack's card (its name, price button and four marbles) is fully in view. Capture it on the iPhone 17 Pro Max simulator, which gives 1320 × 2868, a valid 6.9" size. Run the app **from Xcode**, because the Run scheme loads `Products.storekit`. Launched with `simctl` alone, the cards say "Unavailable", as `site-raw/store.png` shows. A TestFlight sandbox build also works. Suggested files: `MarbleBeats-appstore/iap-review/<pack>.png`. The screenshot is used only for review and is never shown on the App Store.

### Glass Pack

| Reference name | Product ID | Price (USD) |
|---|---|---|
| `Glass Pack` | `com.marblejam.app.pack.glass` | 0.99 |

```
com.marblejam.app.pack.glass
```
Display name (10 / 30):
```
Glass Pack
```
Description (45 / 45):
```
Cat's Eye, Emerald, Amber and Bubble marbles.
```
Review notes (301 / 4000):
```
Unlocks four marble looks: Cat's Eye, Emerald Swirl, Amber Swirl and Bubble. Cosmetic only. To buy: menu > Store > Glass Pack > price button, then answer the grown-up question (the product of the two numbers, e.g. seven times eight = 56). The marbles then appear under Your marbles; tap one to use it.
```

### Space Pack

| Reference name | Product ID | Price (USD) |
|---|---|---|
| `Space Pack` | `com.marblejam.app.pack.space` | 1.99 |

```
com.marblejam.app.pack.space
```
Display name (10 / 30):
```
Space Pack
```
Description (36 / 45):
```
Earth, Saturn, Moon and Sun marbles.
```
Review notes (280 / 4000):
```
Unlocks four marble looks: Earth, Saturn, Moon and Sun. Cosmetic only. To buy: menu > Store > Space Pack > price button, then answer the grown-up question (the product of the two numbers, e.g. seven times eight = 56). The marbles then appear under Your marbles; tap one to use it.
```

### Sports Pack

| Reference name | Product ID | Price (USD) |
|---|---|---|
| `Sports Pack` | `com.marblejam.app.pack.sports` | 0.99 |

```
com.marblejam.app.pack.sports
```
Display name (11 / 30):
```
Sports Pack
```
Description (38 / 45):
```
Soccer, Basketball, Tennis and 8-Ball.
```
Review notes (291 / 4000):
```
Unlocks four marble looks: Soccer, Basketball, Tennis and 8-Ball. Cosmetic only. To buy: menu > Store > Sports Pack > price button, then answer the grown-up question (the product of the two numbers, e.g. seven times eight = 56). The marbles then appear under Your marbles; tap one to use it.
```

### Candy Pack

| Reference name | Product ID | Price (USD) |
|---|---|---|
| `Candy Pack` | `com.marblejam.app.pack.candy` | 0.99 |

```
com.marblejam.app.pack.candy
```
Display name (10 / 30):
```
Candy Pack
```
Description (41 / 45):
```
Lollipop, Gumball, Peppermint, Sprinkles.
```
Review notes (296 / 4000):
```
Unlocks four marble looks: Lollipop, Gumball, Peppermint and Sprinkles. Cosmetic only. To buy: menu > Store > Candy Pack > price button, then answer the grown-up question (the product of the two numbers, e.g. seven times eight = 56). The marbles then appear under Your marbles; tap one to use it.
```

### Gem Pack

| Reference name | Product ID | Price (USD) |
|---|---|---|
| `Gem Pack` | `com.marblejam.app.pack.gems` | 1.99 |

```
com.marblejam.app.pack.gems
```
Display name (8 / 30):
```
Gem Pack
```
Description (45 / 45):
```
Diamond, Sapphire, Amethyst and Opal marbles.
```
Review notes (287 / 4000):
```
Unlocks four marble looks: Diamond, Sapphire, Amethyst and Opal. Cosmetic only. To buy: menu > Store > Gem Pack > price button, then answer the grown-up question (the product of the two numbers, e.g. seven times eight = 56). The marbles then appear under Your marbles; tap one to use it.
```

### Animal Pack

| Reference name | Product ID | Price (USD) |
|---|---|---|
| `Animal Pack` | `com.marblejam.app.pack.animals` | 0.99 |

```
com.marblejam.app.pack.animals
```
Display name (11 / 30):
```
Animal Pack
```
Description (39 / 45):
```
Ladybug, Panda, Tiger and Frog marbles.
```
Review notes (284 / 4000):
```
Unlocks four marble looks: Ladybug, Panda, Tiger and Frog. Cosmetic only. To buy: menu > Store > Animal Pack > price button, then answer the grown-up question (the product of the two numbers, e.g. seven times eight = 56). The marbles then appear under Your marbles; tap one to use it.
```

Optional: a 1024 × 1024 promotional image per pack is needed only if you promote in-app purchases on the App Store. It isn't needed for v1.

---

## 5. Game Center

Turn on **Game Center** on the 1.0 version page, then add the leaderboard and all 13 achievements to that version, so they are reviewed together with the app. The IDs below are the ones the code uses (`GameCenter.swift`): `leaderboardID = "marblejam.stars"` and `"marblejam.world\(world)"` for worlds 1 to 13. IDs are permanent once saved. Achievements are reported when a world has at least one star on each of its 6 levels (`finishedWorlds`), at 100 % with the completion banner on.

### Leaderboard

| Property | Value |
|---|---|
| Type | Classic (never resets) |
| Reference name | `Total Stars` |
| Leaderboard ID | `marblejam.stars` |
| Score format type | Integer |
| Score submission type | Best Score (the total only goes up; stars per level keep the best result) |
| Sort order | High to Low |
| Score range | 0 to 234 (3 stars × 78 levels; holiday stars count) |
| Image | optional: `MarbleBeats-appstore/game-center/leaderboard.png` (1024 × 1024, RGB, no alpha) |

Localization, English (U.S.):

Display name (11 characters):
```
Total Stars
```
Leaderboard description (95 characters):
```
All the stars you've won in Challenges, holiday worlds included: up to 3 per level, 234 in all.
```
Score format suffix, singular:
```
 star
```
Score format suffix, plural:
```
 stars
```

Each suffix starts with a space, so a score reads "57 stars". If the preview in App Store Connect shows a double space, remove it.

### Achievements (13)

All 13 achievements have these settings:

- **Hidden:** No.
- **Achievable more than once:** No.
- **Image:** `MarbleBeats-appstore/game-center/world<N>.png` (1024 × 1024 PNG, RGB, no alpha, 72 ppi; the badge shows the world's number and name).

**Points are graded, 650 in total** (of the 1000 a game may award):

- Main worlds rise with difficulty: 25, 35, 45, 55, 90.
- Each of the 8 holiday worlds is worth 50.
- No achievement is worth more than 100.
- That leaves 350 points for future worlds.

The flat option, 13 × 50, is also 650. Each holiday pre-earned description names its window, so the seasonal worlds are documented where players see them.

#### 1. First Notes (main world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world1` | `World 01 First Notes` | 25 | No | No | `game-center/world1.png` |

```
marblejam.world1
```
Title (12 characters):
```
Note by Note
```
Pre-earned description (51 characters):
```
Get a star on all 6 levels of World 1, First Notes.
```
Earned description (48 characters):
```
You finished First Notes: a star on every level!
```

#### 2. Fix It (main world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world2` | `World 02 Fix It` | 35 | No | No | `game-center/world2.png` |

```
marblejam.world2
```
Title (11 characters):
```
Fixer-Upper
```
Pre-earned description (46 characters):
```
Get a star on all 6 levels of World 2, Fix It.
```
Earned description (54 characters):
```
You finished Fix It: every loose pad back on the beat!
```

#### 3. Bullseye (main world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world3` | `World 03 Bullseye` | 45 | No | No | `game-center/world3.png` |

```
marblejam.world3
```
Title (9 characters):
```
Bullseye!
```
Pre-earned description (48 characters):
```
Get a star on all 6 levels of World 3, Bullseye.
```
Earned description (54 characters):
```
You finished Bullseye: right into the cup, every time!
```

#### 4. Ramps (main world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world4` | `World 04 Ramps` | 55 | No | No | `game-center/world4.png` |

```
marblejam.world4
```
Title (10 characters):
```
Ramp Champ
```
Pre-earned description (45 characters):
```
Get a star on all 6 levels of World 4, Ramps.
```
Earned description (47 characters):
```
You finished Ramps: stretched, bent and rolled!
```

#### 5. Maestro (main world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world5` | `World 05 Maestro` | 90 | No | No | `game-center/world5.png` |

```
marblejam.world5
```
Title (7 characters):
```
Maestro
```
Pre-earned description (47 characters):
```
Get a star on all 6 levels of World 5, Maestro.
```
Earned description (46 characters):
```
You finished Maestro: every note in its place!
```

#### 6. Halloween (holiday world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world6` | `World 06 Halloween` | 50 | No | No | `game-center/world6.png` |

```
marblejam.world6
```
Title (14 characters):
```
Halloween Hero
```
Pre-earned description (69 characters):
```
Get a star on all 6 levels of the Halloween world, open October 1–31.
```
Earned description (50 characters):
```
You finished the Halloween world. Happy Halloween!
```

#### 7. Thanksgiving (holiday world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world7` | `World 07 Thanksgiving` | 50 | No | No | `game-center/world7.png` |

```
marblejam.world7
```
Title (14 characters):
```
Thankful Tunes
```
Pre-earned description (100 characters):
```
Get a star on all 6 levels of the Thanksgiving world, open November 8 to the day after Thanksgiving.
```
Earned description (66 characters):
```
You finished the Thanksgiving world. Something to be thankful for!
```

#### 8. Christmas (holiday world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world8` | `World 08 Christmas` | 50 | No | No | `game-center/world8.png` |

```
marblejam.world8
```
Title (16 characters):
```
Merry Marble Run
```
Pre-earned description (70 characters):
```
Get a star on all 6 levels of the Christmas world, open December 1–30.
```
Earned description (51 characters):
```
You finished the Christmas world. Merry and bright!
```

#### 9. New Year (holiday world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world9` | `World 09 New Year` | 50 | No | No | `game-center/world9.png` |

```
marblejam.world9
```
Title (14 characters):
```
Happy New Beat
```
Pre-earned description (80 characters):
```
Get a star on all 6 levels of the New Year world, open December 31 to January 6.
```
Earned description (48 characters):
```
You finished the New Year world. Happy New Year!
```

#### 10. Valentine's (holiday world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world10` | `World 10 Valentine's` | 50 | No | No | `game-center/world10.png` |

```
marblejam.world10
```
Title (19 characters):
```
Sweetheart Serenade
```
Pre-earned description (72 characters):
```
Get a star on all 6 levels of the Valentine's world, open February 1–14.
```
Earned description (51 characters):
```
You finished the Valentine's world. Lovely playing!
```

#### 11. St. Patrick's (holiday world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world11` | `World 11 St. Patrick's` | 50 | No | No | `game-center/world11.png` |

```
marblejam.world11
```
Title (11 characters):
```
Lucky Notes
```
Pre-earned description (71 characters):
```
Get a star on all 6 levels of the St. Patrick's world, open March 1–17.
```
Earned description (48 characters):
```
You finished the St. Patrick's world. Lucky you!
```

#### 12. Easter (holiday world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world12` | `World 12 Easter` | 50 | No | No | `game-center/world12.png` |

```
marblejam.world12
```
Title (18 characters):
```
Egg-cellent Rhythm
```
Pre-earned description (98 characters):
```
Get a star on all 6 levels of the Easter world, open up to 2 weeks before Easter to Easter Monday.
```
Earned description (43 characters):
```
You finished the Easter world. Egg-cellent!
```

#### 13. Día de los Muertos (holiday world)

| Achievement ID | Reference name | Points | Hidden | More than once | Image |
|---|---|---|---|---|---|
| `marblejam.world13` | `World 13 Día de los Muertos` | 50 | No | No | `game-center/world13.png` |

```
marblejam.world13
```
Title (15 characters):
```
Marigold Melody
```
Pre-earned description (78 characters):
```
Get a star on all 6 levels of the Día de los Muertos world, open November 1–7.
```
Earned description (62 characters):
```
You finished the Día de los Muertos world. Beautifully played!
```

---

## 6. Age rating questionnaire (expected result: 4+)

Answers to App Store Connect's current questionnaire, with their wording and definitions from [Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions):

| Section | Question | Answer | Why |
|---|---|---|---|
| In-app controls | Parental Controls | **No** | There are no settings parents manage. The grown-up question is a fixed check before buying; Screen Time and Ask to Buy are Apple's. "Yes" is also defensible, since Apple's examples include restricting purchases. Neither answer changes the 4+ rating. |
| In-app controls | Age Assurance | No | |
| Capabilities | Unrestricted Web Access | No | The only link is "Help & support", which opens marblebeats.com in Safari. The app has no browser. |
| Capabilities | User-Generated Content | No | Songs stay on the device and in the player's own iCloud. Nothing is shared with other players. |
| Capabilities | Social Media / Messaging and Chat / Advertising | No / No / No | |
| Mature themes | Profanity or Crude Humor | None | |
| Mature themes | Horror/Fear Themes | **None** | Judgment call: the Halloween look is friendly cartoon art (a smiling ghost, jack-o'-lanterns, bats, a haunted-house silhouette), and Día de los Muertos has decorated sugar-skull tiles and marigolds. There are no frights, story or jump-scares. If Review counts this as "Infrequent", the rating becomes 9+. |
| Mature themes | Alcohol, Tobacco, or Drug Use or References | None | The songs have no lyrics on screen. "Drink to Me Only with Thine Eyes" is a love song title. |
| Medical or wellness | Medical or Treatment Information / Health or Wellness Topics | None / No | |
| Sexuality or nudity | all three | None | |
| Violence | Cartoon or Fantasy / Realistic / Prolonged Graphic / Guns or Other Weapons | None (all four) | |
| Chance-based | Gambling / Loot Boxes | No / No | Packs show their four marbles before purchase. There is nothing random. |
| Chance-based | Simulated Gambling | None | |
| Chance-based | Contests | **Infrequent** | The definition covers competing "for rankings … or the achievement of personal goals", which fits the optional Game Center leaderboard and achievements. "Infrequent" still gives 4+ ("Frequent" would give 13+). |

Made for Kids: **No** (see section 1).

---

## 7. App Privacy

- **"Do you or your third-party partners collect data from this app?"** → **No, we do not collect data from this app.** The product page will show **"Data Not Collected"**.
- **Why it holds:**
  - The app has no networking code and no third-party SDKs, and project.yml has no packages.
  - `PrivacyInfo.xcprivacy` declares no tracking, no tracking domains and no collected data types. Its only declared API is UserDefaults, with reason CA92.1. `ReleaseTests` checks this.
  - Songs, stars and the chosen marble go only to the player's own iCloud.
  - Game Center data goes to Apple, and only after the player signs in.
  - Purchases are handled by Apple.
  - Apple: "You are not responsible for disclosing data collected by Apple" ([App privacy details](https://developer.apple.com/app-store/app-privacy-details/)).
- **Privacy Policy URL:** `https://marblebeats.com/privacy/`. The same policy is in the app (Account › Privacy policy), last updated 23 October 2026.
- **User Privacy Choices URL:** leave it empty.

---

## 8. Pricing, availability and compliance

- **Price:** Free. The website already says "Free to play, with optional marble packs".
- **Countries and regions:**
  - **Exclude China mainland.** Games there need an approval number from the NPPA, and that isn't open to a developer outside China ([App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)).
  - **Exclude Vietnam for v1 (recommended).** Vietnamese regulators require games to be licensed to stay on the App Store there (Decree 147/2024/ND-CP, same page). Unlicensed games can be removed, and a licence normally needs a Vietnamese publisher. Revisit this once the app is established.
  - **Include all other storefronts.**
- **EU:** the Account Holder must have declared **trader status** under the Digital Services Act, or the app can't be distributed in the EU. An app that earns money from in-app purchases usually makes you a trader. Your address, phone and email are then shown on the EU product page ([DSA trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)).
- **Untick "Mac with Apple silicon" and "Apple Vision Pro" for v1.** The app is portrait-only and full screen (`UIRequiresFullScreen`), you build by dragging pads by touch, and neither platform was tested.
- **Family Sharing for the packs (recommended: on, for all six):**
  - **Why:** the app is marketed to the whole family, the packs are small one-time cosmetic purchases, and one purchase covering up to six family members fits that and builds goodwill.
  - **The code already copes:** `Store.refreshPurchases` reads `Transaction.currentEntitlements`, which includes family-shared transactions and drops revoked ones, and the `Transaction.updates` listener refreshes when sharing changes.
  - **Cost:** fewer purchases per household.
  - **Irreversible:** once Family Sharing is on for a product it can't be turned off ([Apple](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases/)), so decide before saving.
  - **If you leave it off:** say nothing about Family Sharing anywhere, which matches the current website.
  - **If you turn it on:** later set `"familyShareable": true` in `Products.storekit` so local testing matches. That is a code change and not part of this listing. Then add the sentence below to the description's FOR PARENTS list (74 characters; the description stays under 4000).

```
• With Family Sharing, one marble pack works for up to six family members.
```

- **Export compliance:** handled. `ITSAppUsesNonExemptEncryption = NO` is in the Info.plist (`project.yml`, checked by `ReleaseTests`), so App Store Connect asks no encryption questions per build. If it ever does ask, the answer is that the app uses no encryption beyond Apple's operating system.
- **Accessibility Nutrition Labels (optional for now):** claim a feature only if every common task (first launch, playing, buying, settings) works with it. **Dark Interface** (the app is always dark) and **Reduced Motion** (the menu demo, camera and sticker respect it) are candidates after a check on a device. Don't claim VoiceOver, Voice Control or Larger Text: the game's pad dragging hasn't been audited, and text uses fixed sizes ([overview](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels)).
- **Optional after launch:** an [In-App Event](https://developer.apple.com/app-store/in-app-events/) for each holiday (Guideline 2.3.13). The dates must match the windows above. It's a good way to promote each holiday world on the App Store.

---

## 9. Screenshot plan

Use the same 7 screenshots in the same order for both devices, with the caption baked into each image. The first three show in search results, so they carry the core idea.

- **iPhone:** `final/iphone-6.9/` at 1320 × 2868 (iPhone 17 Pro Max).
- **iPad:** `final/ipad-13/` at 2064 × 2752 (iPad Pro 13-inch, M5). It's the same portrait UI; don't suggest a special iPad layout or landscape.

App Store Connect's help names **"iPhone with Dynamic Island (medium display)"** (1206 × 2622 or 1179 × 2556) as the required iPhone slot, and says screenshots are scaled down from the highest resolution provided. Upload the 6.9" set first. If the medium slot still shows as required, upload the same seven at 1206 × 2622 (iPhone 17 simulator); the `site-raw` captures are already that size.

Capture with a DEBUG build and the launch arguments from `CaptureMode.swift`, for example `xcrun simctl launch <UDID> com.marblejam.app -mbSong demo -mbAutoPlay 1 -mbSeason off`. With any of them set, the Preview chip is hidden and no icon alert appears.

| # | File | Screen | Caption | Small line | Launch arguments |
|---|---|---|---|---|---|
| 1 | `01-build.png` | Builder, Twinkle Twinkle mid-run: chrome marble rolling, a pad flashing, gold beat glow | Build a marble run that plays music | Drop the marble and hear your song | `-mbSong demo -mbAutoPlay 1 -mbSeason off`, captured 4–8 s after launch |
| 2 | `02-notes.png` | Builder before Drop: dotted path, beat rings, note labels | Every pad it hits plays a note | Six instruments, from bells to 8-bit | `-mbSong demo -mbSeason off` |
| 3 | `03-challenges.png` | Challenges list, a holiday world on top | 78 levels in 13 worlds | 30 all year, 48 in their holidays | `-mbScreen challenges -mbSeason christmas` |
| 4 | `04-holidays.png` | Christmas menu: holiday title art, colours and background | Eight holidays through the year | Each opens its own world in season | `-mbScreen menu -mbSeason christmas` |
| 5 | `05-holiday-songs.png` | My Songs with the Christmas shelf of ready-made songs | Holiday songs to play and change | Ready-made tunes, in season | `-mbScreen library -mbSeason christmas` |
| 6 | `06-marbles.png` | Store: Your marbles and Earn more (marbles to win with stars and holidays) | 41 marbles to collect | Win them with stars and holidays, or pick a pack | `-mbScreen store -mbSeason off`, framed so that **no pack card shows "Unavailable" or a price** |
| 7 | `07-stars.png` | Celebration sticker after the demo song ends | Keep the beat, win three stars | | `-mbSong demo -mbAutoPlay 1 -mbSeason off`, captured about 26 s after launch (the song is about 24 s) |

Caption rules:

- Never say "for kids" or show a price.
- Never imply that all 78 levels or all 41 marbles are always available. That's why captions 3 and 6 carry their small lines.
- Show only what the app really does: no landscape, no multiple marbles, no login.
- Captions 4 and 5 show seasonal content, and the review notes and description list every window, which covers Guideline 2.5.19.

App preview (optional, up to 3 per device size): `site-raw/gameplay.mp4` is a silent gameplay clip for the website. An App Store preview has to be captured at the device's preview resolution, so leave it for after v1.

---

## 10. Owner checklist (things this file can't do)

1. Agreements, tax and banking in App Store Connect (the Paid Apps agreement is needed for in-app purchases).
2. Create the app record (bundle ID `com.marblejam.app`; any unique SKU, e.g. `marblebeats-ios`). Paste sections 1–3.
3. Create the 6 in-app purchases (section 4), decide Family Sharing first, attach the review screenshots, and add them to version 1.0.
4. Create the leaderboard and 13 achievements (section 5) with their images, and add them to version 1.0.
5. Fill in the age rating (section 6), App Privacy (section 7) and pricing and availability (section 8). Declare DSA trader status.
6. Upload the screenshots (section 9). Add your name and phone under App Review Information, plus the holiday captures and recording.
7. Archive and upload build 1 (`README.md` › "Releasing to the App Store"), select it on the version page, and submit.

## Sources

- App Store Connect Help: [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information) · [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information) · [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) · [In-App Purchase information](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information) · [Family Sharing for In-App Purchases](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases/) · [Achievements](https://developer.apple.com/help/app-store-connect/reference/game-center/achievements/) · [Leaderboards](https://developer.apple.com/help/app-store-connect/reference/game-center/leaderboards/) · [Age ratings](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions) · [Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels) · [DSA trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/): 1.3 (the "For Kids" wording is reserved), 2.3.7 (metadata), 2.3.13 (In-App Events), 2.5.19 (no hidden, dormant or undocumented features), 3.1.1 (restore)
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- Code (read-only, `main` at `ac9ea64`): `Seasons.swift`, `HolidaySongs.swift`, `Challenge.swift`, `ChallengesView.swift`, `Skins.swift`, `Store.swift`, `StoreView.swift`, `GameCenter.swift`, `RootView.swift`, `AppIcons.swift`, `CaptureMode.swift`, `PrivacyPolicy.swift`, `PrivacyInfo.xcprivacy`, `Products.storekit`, `project.yml`, `MarbleJamTests/ReleaseTests.swift`
