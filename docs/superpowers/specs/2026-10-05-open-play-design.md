# Open Play (My Songs + Instruments) — Design

Date: 2026-10-05 · Builds on the beat-glow branch.

## Goal

Let players create, keep and revisit many of their own beats, and choose which instrument each song plays with.
This is the base the Challenges and the Store will build on.

## Decisions (from brainstorming)

- Library: a grid of song cards ("My Songs"), not a list or slots.
- Menu: **Challenges** and **Create** replace **Play** and **Demo Song**. Challenges shows "Challenges are coming soon" until built.
- Storage: one JSON file per song in the app's Documents folder (later moved into iCloud Drive for sync).
- Instruments: chosen per song (the whole song plays with one instrument).
- Out of scope here, each its own later project: railings and other new pieces (new physics), marble skins (with Store and
  Challenges), iCloud sync and sign-in, sharing songs, challenges.

## 1. Songs and the store of songs

`Song` (Codable): `id: UUID`, `name: String`, `created: Date`, `modified: Date`, `instrument: Instrument`, `course: Course`.
Decoding tolerates a missing `instrument` (defaults to `.bells`) so older files keep working.

`SongStore` owns a folder (Documents/Songs in the app; a temporary folder in tests). One file per song: `<id>.json`.

- `all() -> [Song]` — every readable song, newest `modified` first. Unreadable files are skipped (and logged), never crash.
- `save(_ song: Song) throws` — writes atomically; updates `modified`.
- `newSong() -> Song` — empty course (default hopper position), name "Untitled N" where N is one more than the highest
  "Untitled N" in use (1 if none). Saved immediately.
- `rename(_ id: UUID, to name: String)` — trims whitespace; empty names are refused (name unchanged).
- `duplicate(_ id: UUID) -> Song` — new id, name "<name> copy" ("<name> copy 2", ... if taken), same course and instrument.
- `delete(_ id: UUID)`.
- `migrateIfNeeded(defaults: UserDefaults)` — runs once (flag `songs.migrated.v1`):
  - if the old single course (`course.v1`) exists and has pads, it becomes "My First Song";
  - the demo is added as "Twinkle Twinkle" (`Engine.demo()`), instrument bells.
- `resetDemo()` — puts a fresh "Twinkle Twinkle" back (replaces the existing one with that name, or adds it).

## 2. Instruments

`enum Instrument: String, Codable, CaseIterable` — **bells** (today's sound), **piano**, **guitar**, **marimba**, **drums**, **8-bit**.

- Each has a display name and an SF Symbol for the picker.
- `Synth.play(midi:bar:gain:at:)` gains an `instrument:` parameter. Each instrument is its own small voice in the render block:
  - bells: today's additive tone;
  - piano: several decaying harmonics with a quick hammer attack, longer decay on low notes;
  - guitar: plucked string (Karplus–Strong style: noise burst through a short delay line with damping);
  - marimba: sine plus a soft 4th harmonic, short woody decay;
  - drums: the note picks a kit piece — low notes kick (sine pitch drop), middle snare (noise + tone), high notes
    hi-hat (filtered noise, very short), bumpers toms; size still sets "pitch" within the kit;
  - 8-bit: square wave with a short decay.
- Bars and bumpers keep their octave difference for all pitched instruments.
- The player changes the instrument in the builder: a new **instrument button** in the header (icon of the current
  instrument) opens a small picker; choosing one plays a sample note and saves it with the song. Changing it is an undo step.
- Note names on pads stay the same for pitched instruments; for drums they show the kit piece ("Kick", "Snare", "Hat", "Tom").

## 3. Screens and flow

- **Menu**: Challenges · Create · Backgrounds · Store · Sign in (same size, centred).
- **My Songs** (`LibraryView`), opened by Create:
  - top bar: back to menu (left), title "My Songs", **+ New Song** (right);
  - grid (2 columns on phone, adaptive) of `SongCard`: mini drawing of the course (pads as coloured strokes on a dark
    card, drawn from the song's data with Canvas), name, "N notes", 1–3 stars (same rule as the celebration sticker;
    no stars if the song has no notes), instrument icon;
  - tap a card: opens the builder with that song;
  - long-press menu: Rename (alert with a text field), Duplicate, Delete (confirmation: "Delete “Name”? This can't be undone.");
  - at the bottom: "Reset Twinkle Twinkle" (small, secondary).
  - empty state (all deleted): "No songs yet" with a + New Song button.
- **Builder** (today's game screen) with an open song:
  - header: the lettering, then a line "Song name · N notes · M on the beat"; tapping the song name opens Rename;
  - instrument button left of ⌂; ⌂ now returns to My Songs;
  - everything else as today; the Demo button in the tray is removed (the demo is a song now);
  - autosave: every place that saves today saves the open song (via `SongStore.save`).
- `RootView` screens: `.menu`, `.library`, `.play(Song.ID)`.

## 4. Model changes

- `GameModel` gets `open(_ song: Song)` and `var song: Song?`; `save()` writes `course` and `instrument` into the song
  through the `SongStore` it is given (injected; tests use a temporary folder). It no longer reads or writes `course.v1`.
- Undo history is per visit: opening a song clears it. Undo entries hold the course and the instrument, so changing the instrument can be undone.
- `GameModel.instrument` (from the song) is passed to every `synth.play`.

## 5. Errors

- Unreadable song file: skipped, logged with the file name; the rest of the library loads.
- Save failure: toast "Couldn't save your song" (the in-memory song is kept; the next edit tries again).
- Rename to an empty name: refused, the old name stays.

## Testing

Unit tests (`SongStoreTests`, temporary folder per test):
- new song numbering ("Untitled 1", then "Untitled 2", gaps filled with max+1);
- save/load round trip including instrument; old file without `instrument` loads as bells;
- rename (trimmed; empty refused), duplicate naming ("copy", "copy 2"), delete;
- `all()` order (newest first) and skipping a corrupt file;
- migration: old course becomes "My First Song" plus "Twinkle Twinkle"; runs only once; no old course → only Twinkle;
- resetDemo replaces a changed Twinkle.

Model tests: opening a song then editing saves into that song's file; opening another song clears undo; instrument change is saved and undoable.

Synth: each instrument renders a short non-silent, non-clipping buffer (offline render of one note into an array,
checked for peak between 0.05 and 1.0). Manual listening check in the simulator.

UI: simulator screenshots of the menu, My Songs (with cards), the rename/delete flow, and the builder header with instrument picker.

## Later projects (roadmap, not in this spec)

1. **Challenges** — goals and stars per level, public-domain melodies, unlocks; rewards include marble skins.
2. **New pieces** — railings/ramps the marble rolls along, and more (springs, funnels, teleports): needs rolling physics in the engine.
3. **Cosmetics & Store** — marble skins (glass, metal, glowing, patterned, themed), pad styles, trails, extra instruments;
   bought with in-app purchases (StoreKit 2, parental gate, restore) or earned from challenges.
4. **Sign in & sync** — iCloud Drive for songs, Game Center for challenge leaderboards/achievements.
