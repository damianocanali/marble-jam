# Challenges — Design and Plan

Date: 2026-10-07 · Approved in chat (types: melody, fix, target; unlock in order by stars; ~30 levels in 5 worlds).
Builds on the ramps branch (World 4 uses ramps).

## Levels are generated from a working solution

Every level is built from a complete course (laid out by the engine, so it is right by construction):

- **Melody** — a short public-domain tune. Some pads are missing; the player gets them in a tray with their notes set
  (each first appears beside its spot, mirrored across the screen) and must place them so the tune plays in order.
- **Fix** — the tune's course with a few pads knocked out of place; only those can be moved.
- **Target** — a few locked pads, a cup, and a tray of pieces (bars, and ramps in World 4): get the marble into the cup.

Scoring (`Challenge.stars(for:placed:)`):
- Melody / Fix: 0 unless every note plays, in order (same pitches as the solution). Then 1–3 stars by notes on the beat
  (the celebration rule: ≥ 60 % → 2, ≥ 90 % → 3).
- Target: 0 unless the marble's path passes within 30 points of the cup. Then 3 stars using at most the solution's number
  of pieces, 2 with one more, else 1. The tray always offers two spare pieces.

Every level is tested: its solution scores 3 stars and its start scores less (melody/target: 0; fix: under 3).

## Worlds (6 levels each)

1. **First Notes** (melody): Twinkle, Baa Baa Black Sheep, Row Row Row Your Boat, Hickory Dickory Dock, Ode to Joy.
2. **Fix It** (fix): Twinkle, Baa Baa, Pop Goes the Weasel, Happy Birthday, Ode to Joy, Jingle Bells.
3. **Bullseye** (target, bars).
4. **Ramps** (target, ramps and bars).
5. **Maestro** (mixed, longer).

Songs: transcribed from the Wikipedia scores (Ode to Joy, Row Row, Baa Baa, Pop Goes the Weasel, Hickory Dickory Dock,
Happy Birthday — the 1893 "Good Morning to All" melody), transposed to C, played at half speed so eighth notes keep their
rhythm on the beat grid (0–3 small rhythm changes per song).

## Unlocking and progress

`ChallengeProgress` (UserDefaults `challenges.v1`, injectable): best stars per level. Level 1 of World 1 is open; a level
opens when the previous one has a star; World w opens when World w−1's last level has a star and the total is at least
10 × (w − 1).

## Play

`GameModel.open(challenge:)` loads the start course (no song saving). Locked pieces can't be moved, tilted, re-noted or
deleted (shown with a small lock). The tray row lists the remaining tray pieces; placing one adds it at its hint spot;
deleting a placed piece returns it to the tray; "Reset" restores the start. Drop plays as usual; at the end the level is
scored, progress saved, and the star sticker shows with **Next level**; 0 stars shows a hint toast instead.

Screens: Menu → Challenges (worlds with star totals and locks) → level grid → builder in challenge mode
(header: level title and goal; ⌂ back to the level grid).

## Plan (TDD, branch `challenges`)

1. `Engine.rampAdd` (shared by `addRamp` and level generation) — model tests still pass.
2. `Songbook.swift` (the six melodies) — test: each lays out fully on the beat.
3. `Challenge.swift` (`Challenge`, `Challenges.all`, generators, scoring) — tests: 30 levels, 5×6, unique ids; solution
   3 stars, start below; target cup reached only with the pieces.
4. `ChallengeProgress` — tests: best kept, unlock rules.
5. `GameModel` challenge mode — tests: locked pieces refuse edits, tray place/return, reset, finish records stars.
6. UI: `ChallengesView` (worlds, levels), builder header/tray, cup and lock drawing, Next level. Screenshots.
