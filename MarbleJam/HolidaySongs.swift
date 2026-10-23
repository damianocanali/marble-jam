import Foundation

/// The five newer holidays' ready-made songs (public-domain or traditional melodies on the white-key bars; see Seasons.swift
/// for the note and beat format). Each recipe names the score it was taken from and lists its "Departures": every way the
/// notes differ from that score apart from the transposition. Note numbers count from 1, and "beats" is the gap before a note.
/// Where Engine.smartAdd could not lay out a pad at the score's spacing, that note's beats were lengthened to the next allowed
/// value; the message of the commit "Songs for the five new holidays" lists each of those, and they are not repeated below.
enum HolidaySongs {
    static let newYear: [SongRecipe] = [
        // Auld Lang Syne (verse and chorus, F major score moved up a fifth to C) - https://en.wikipedia.org/wiki/Auld_Lang_Syne
        // Departures: none.
        SongRecipe(name: "Auld Lang Syne", instrument: .bells, melody: [
            (1, 4), (1, 7), (1.5, 7), (1, 7), (1, 9), (1, 8), (1.5, 7), (1, 8), (1, 9), (1, 7), (1.5, 7), (1, 9),
            (1, 11), (1, 12), (3, 12), (1, 11), (1.5, 9), (1.5, 9), (1, 7), (1, 8), (1.5, 7), (1, 8), (1, 9), (1, 7),
            (1.5, 5), (1, 5), (1, 4), (1, 7), (3, 12), (1.5, 11), (1.5, 9), (0.5, 9), (1, 7), (1, 8), (1.5, 7), (1, 8),
            (1, 12), (1, 11), (1.5, 9), (1, 9), (1, 11), (1, 12), (3, 12), (1, 11), (1.5, 9), (1.5, 9), (1, 7), (1, 8),
            (1.5, 7), (1, 8), (1, 9), (1, 7), (1.5, 5), (1, 5), (1, 4), (1, 7)]),
        // The Blue Danube (Strauss II, bars 1-16 of the first waltz, D major moved down a step to C)
        // https://imslp.org/wiki/An_der_sch%C3%B6nen_blauen_Donau,_Op.314_(Strauss_Jr.,_Johann)
        // Departures: 10 notes are an octave above the score (#18-22 and #27-31, B4 B4 D5 A5 A5; the score has B3 B3 D4 A4 A4,
        // and B3 is below the bars), so the score's octave leap up to the answering notes becomes a repeated A5 there; the grace
        // notes are left out; of the two-note chord at bar 6 beat 1 only the melody note is kept; bars 1-16 only (the D4 pickup
        // on beat 3 of bar 16 and bars 17-32 are left out).
        SongRecipe(name: "The Blue Danube", instrument: .bells, melody: [
            (1, 0), (1, 2), (1, 4), (1, 4), (2, 11), (1, 11), (2, 9), (1, 9), (2, 0), (1, 0), (1, 2), (1, 4),
            (1, 4), (2, 11), (1, 11), (2, 10), (1, 10), (2, 6), (1, 6), (1, 8), (1, 12), (1, 12), (2, 12), (1, 12),
            (2, 10), (1, 10), (2, 6), (1, 6), (1, 8), (1, 12), (1, 12), (2, 12), (1, 12), (2, 9), (1, 9)]),
        // Ode to Joy (Beethoven, the 16-bar theme; stands in for Radetzky March, whose theme needs black keys) - https://en.wikipedia.org/wiki/Ode_to_Joy
        // Departures: none (the tied E5 into the last phrase is one note).
        SongRecipe(name: "Ode to Joy", instrument: .bells, melody: [
            (1, 9), (1, 9), (1, 10), (1, 11), (1, 11), (1, 10), (1, 9), (1, 8), (1, 7), (1, 7), (1, 8), (1, 9),
            (1, 9), (1.5, 8), (1, 8), (2, 9), (1.5, 9), (1, 10), (1, 11), (1, 11), (1, 10), (1, 9), (1, 8), (1, 7),
            (1, 7), (1, 8), (1, 9), (1, 8), (1.5, 7), (1, 7), (2, 8), (1.5, 8), (1, 9), (1, 7), (1, 8), (1, 9),
            (1, 10), (1, 9), (1, 7), (1, 8), (1, 9), (1, 10), (1, 9), (1, 8), (1, 7), (1, 8), (1, 4), (1, 9),
            (2, 9), (1, 10), (1, 11), (1, 11), (1, 10), (1, 9), (1, 8), (1, 7), (1, 7), (1, 8), (1, 9), (1, 8),
            (1.5, 7), (1, 7)]),
    ]
    static let valentines: [SongRecipe] = [
        // Plaisir d'amour (Martini, first published 1785; the refrain, F major moved up a fifth to C)
        // Leduc edition, Paris 1918: https://commons.wikimedia.org/wiki/File:Plaisir_d%27amour._Paroles_de_Florian._Musique_de_J.-P._Martini_-_bpt6k889731m_(4_of_8).jpg
        // Departures: one statement of the refrain only; two 2.5-beat gaps are rounded (#5 up to 3, #12 down to 2, so 'Chagrin'
        // is back on its beat); the four 32nd-note gaps of the run on 'vie' (#24-27, each 0.125 beat) are 0.5 beat each, so the
        // run lasts 1.5 beats longer than written.
        SongRecipe(name: "Plaisir d'amour", instrument: .piano, melody: [
            (1, 4), (1, 7), (1.5, 8), (1.5, 9), (3, 9), (1, 10), (1.5, 10), (1, 9), (0.5, 8), (0.5, 9), (1, 8), (2, 4),
            (1, 5), (1.5, 6), (1.5, 7), (0.5, 8), (0.5, 9), (0.5, 5), (1.5, 8), (1, 10), (1, 9), (1.5, 8), (0.5, 9), (1, 8),
            (0.5, 7), (0.5, 8), (1, 9), (1, 7)]),
        // Drink to Me Only with Thine Eyes (traditional English, c. 1770; first verse, E-flat major moved down to C; stands in for
        // Let Me Call You Sweetheart, which needs a black key in every transposition) - https://www.flutetunes.com/tunes.php?id=9
        // Departures: the dotted-eighth + sixteenth figure that opens each A phrase (G G G at #2-3, #19-20 and #54-55) is read as
        // straight eighths, as in the Scottish Students' Song Book (same bar length); the 2.5-beat hold on the low C (#34) is 2
        // beats (#35 comes 2 after it) and the eighth pickup #35 is 1 beat (#36 comes 1 after it, 0.5 in the score), 3 in all.
        SongRecipe(name: "Drink to Me Only with Thine Eyes", instrument: .piano, melody: [
            (1, 2), (1, 2), (1, 2), (1, 3), (1, 3), (1, 4), (1, 3), (1, 2), (1, 1), (1, 2), (1, 3), (1, 4),
            (1, 0), (1, 3), (1, 2), (1, 1), (1, 0), (3, 2), (1, 2), (1.5, 2), (1.5, 3), (1.5, 3), (0.5, 4), (0.5, 3),
            (1, 2), (0.5, 1), (1, 2), (1, 3), (1, 4), (1, 0), (1, 3), (1, 2), (1, 1), (1, 0), (2, 4), (1, 4),
            (1, 2), (1, 4), (1, 7), (1, 4), (1, 4), (1, 2), (1, 4), (1, 4), (1, 4), (1, 5), (1, 4), (1, 4),
            (1, 3), (1, 2), (1, 2), (1.5, 1), (1.5, 2), (0.5, 2), (1, 2), (1, 3), (1, 3), (1, 4), (1, 3), (1, 2),
            (1, 1), (1, 2), (1, 3), (1, 4), (1, 0), (1, 3), (1, 2), (1, 1), (1, 0)]),
        // Aura Lee (Poulton, 1861; verse and chorus, G major moved up a fourth to C)
        // first edition, J. Church Jr., Cincinnati: https://levysheetmusic.mse.jhu.edu/collection/024/002
        // Departures: the 2/4 original is read in 4/4 with every value doubled (exact); three 4-beat gaps are 3 (#13 after 'tree',
        // #25 after 'Lea', #36 after 'hair'); the small grace note before 'in' in bar 15 is left out; no piano introduction,
        // accompaniment or four-part chorus repeat.
        SongRecipe(name: "Aura Lee", instrument: .piano, melody: [
            (1, 4), (1.5, 7), (1, 6), (1, 7), (1, 8), (1, 5), (1, 8), (2, 7), (1, 6), (1, 5), (1, 6), (1, 7),
            (3, 4), (1.5, 7), (0.5, 6), (1, 7), (1, 8), (1, 5), (1, 8), (2, 7), (1.5, 6), (1, 5), (1, 6), (1, 7),
            (3, 9), (1, 9), (1.5, 9), (2, 9), (1, 9), (1, 9), (2, 9), (1.5, 8), (0.5, 7), (1, 8), (1, 9), (3, 9),
            (1, 9), (1.5, 10), (1.5, 9), (0.5, 8), (1, 5), (1, 8), (1.5, 8), (1, 7), (1, 6), (1.5, 9), (1.5, 8), (0.5, 7)]),
    ]
    static let stPatricks: [SongRecipe] = [
        // Molly Malone (verse and chorus, G major as written)
        // https://abcnotation.com/tunePage?a=dmc.lizmilner.com/viewabc.vbhtml%3Ffile=Molly+Malone/0002 (also https://thesession.org/tunes/12844)
        // Basis: the tune was published in Boston in 1876 and is sung as a traditional Irish song; the ABC is a modern copy of it
        // (BBC Singing Together, 1974), not a pre-1930 print.
        // Departures: none (the rest after the last note is dropped).
        SongRecipe(name: "Molly Malone", instrument: .guitar, melody: [
            (1, 1), (1, 4), (1, 4), (1.5, 4), (1, 4), (1, 6), (1.5, 4), (1, 5), (1, 5), (1.5, 5), (0.5, 5), (1, 7),
            (1.5, 5), (1, 6), (1, 5), (1, 4), (1, 8), (1, 7), (1, 6), (1, 6), (1.5, 5), (1, 4), (1, 5), (2, 1),
            (0.5, 1), (1, 4), (1, 4), (1.5, 4), (0.5, 4), (1, 6), (1.5, 4), (1, 5), (1, 5), (1.5, 5), (1, 5), (1, 7),
            (1.5, 5), (0.5, 5), (1, 6), (1, 8), (1.5, 7), (1, 6), (1, 8), (1.5, 7), (1, 6), (1.5, 4), (1, 5), (1, 4),
            (2, 1), (1, 4), (1.5, 4), (1, 4), (1, 4), (1, 6), (1.5, 4), (1, 5), (1.5, 5), (0.5, 5), (1, 5), (0.5, 7),
            (1.5, 5), (0.5, 5), (1, 6), (0.5, 8), (1.5, 7), (1, 6), (1, 8), (1.5, 7), (1, 6), (1.5, 4), (1, 5), (1, 4)]),
        // The Irish Washerwoman (the A part, G major as written) - https://thesession.org/tunes/92#setting92
        // Departures: the A part once without its repeat; the B part is left out (it needs F sharp).
        SongRecipe(name: "The Irish Washerwoman", instrument: .guitar, melody: [
            (1, 6), (1, 4), (1, 4), (1, 1), (1, 4), (1, 4), (1, 6), (1, 4), (1, 6), (1, 8), (1, 7), (1, 6),
            (1, 7), (1, 5), (1, 5), (1, 2), (1, 5), (1, 5), (1, 7), (1, 5), (0.5, 7), (1, 9), (1, 8), (1, 7),
            (1, 6), (1, 4), (1, 4), (1, 1), (1, 4), (1, 4), (1, 6), (1, 4), (1, 6), (1, 8), (1, 7), (1, 6),
            (1, 7), (1, 6), (1, 7), (1, 5), (1, 8), (1, 7), (1, 6), (1, 4), (1, 4), (1, 4)]),
        // Londonderry Air (Petrie, 1855; the second strain, E-flat major moved up a step to F)
        // https://en.wikipedia.org/wiki/Londonderry_Air
        // Departures: the second strain only (the first needs a black key); the 2.5-beat gap after 'snow' (G4, #22) is 3 beats
        // (#23 C5 comes 3 after it); every other beats value is the score's own.
        SongRecipe(name: "Londonderry Air", instrument: .guitar, melody: [
            (1, 7), (1, 8), (1, 9), (1, 10), (1.5, 9), (1, 9), (1, 8), (1, 7), (1, 5), (1, 7), (1, 5), (1, 3),
            (1.5, 7), (1, 8), (0.5, 9), (0.5, 10), (1.5, 9), (0.5, 9), (1, 8), (0.5, 7), (1, 5), (1, 4), (3, 7), (1, 7),
            (1, 7), (0.5, 12), (1.5, 11), (0.5, 11), (0.5, 10), (1, 8), (0.5, 10), (1, 7), (1, 5), (1, 3), (1.5, 2), (1, 3),
            (1, 4), (1, 5), (1, 8), (1, 7), (1, 5), (1, 4), (1, 3), (1, 1), (1, 2), (1, 3)]),
    ]
    static let easter: [SongRecipe] = [
        // Hot Cross Buns (the whole song, G major moved up a fourth to C) - https://en.wikipedia.org/wiki/Hot_Cross_Buns_(song)
        // Departures: none.
        SongRecipe(name: "Hot Cross Buns", instrument: .marimba, melody: [
            (1, 9), (1, 8), (1, 7), (2, 9), (1, 8), (1, 7), (2, 7), (0.5, 7), (1, 7), (0.5, 7), (1, 8), (1, 8),
            (1, 8), (1, 8), (1, 9), (1, 8), (1, 7)]),
        // Christ the Lord Is Risen Today (Easter Hymn, 1708; the whole verse, C major as written)
        // https://en.wikisource.org/wiki/Page:The_Army_and_Navy_Hymnal.djvu/87
        // Departures: none (the closing Amen is not part of the verse and is left out).
        SongRecipe(name: "Christ the Lord Is Risen Today", instrument: .marimba, melody: [
            (1, 0), (1, 2), (1, 4), (1, 0), (1, 3), (1, 5), (1, 5), (1, 4), (1, 2), (1, 3), (1, 4), (1, 0),
            (1, 3), (1, 2), (1, 3), (1, 2), (1, 1), (1, 0), (2, 3), (1, 4), (1, 5), (1, 4), (1, 3), (1, 2),
            (1, 2), (1, 1), (1, 2), (1, 3), (1, 4), (1, 0), (1, 3), (1, 2), (1, 3), (1, 2), (1, 1), (1, 0),
            (2, 6), (1, 7), (1, 8), (1, 4), (1, 7), (1, 8), (1, 9), (2, 6), (0.5, 7), (1, 8), (0.5, 4), (1, 7),
            (1, 6), (1, 7), (1, 6), (1, 5), (1, 4), (2, 4), (0.5, 5), (1, 6), (0.5, 4), (1, 7), (1, 2), (1, 3),
            (1, 5), (1, 5), (1, 4), (1, 7), (1, 6), (1, 7), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 7),
            (1, 6), (1, 7)]),
        // Spring (Vivaldi, The Four Seasons; the opening ritornello, E major moved down a third to C)
        // https://www.mutopiaproject.org/cgibin/piece-info.cgi?id=301
        // Departures: 32 gaps of 0.25 beat (sixteenth-note pairs) are 0.5, the beats before #6-7, #9-10, #14-15, #17-18, #20-21,
        // #31-32, #34-35, #39-40, #42-43, #45-46, #52-53, #60-61, #71-72, #77-78, #85-86 and #96-97, so the theme lasts 58.5 beats
        // before fitting instead of 50.5; the trills on D5 are plain notes; the ritornello only (pickup and bars 1-13).
        SongRecipe(name: "Spring (Vivaldi)", instrument: .marimba, melody: [
            (1, 7), (1, 9), (1, 9), (1, 9), (1, 8), (1, 7), (1, 11), (1.5, 11), (0.5, 10), (1, 9), (0.5, 9), (0.5, 9),
            (1, 8), (1, 7), (1, 11), (1.5, 11), (0.5, 10), (1, 9), (1, 10), (1, 11), (1, 10), (1, 9), (1, 8), (1, 6),
            (1, 4), (1, 7), (1, 9), (1, 9), (1, 9), (1, 8), (1, 7), (1, 11), (1.5, 11), (0.5, 10), (1, 9), (0.5, 9),
            (0.5, 9), (1, 8), (1, 7), (1, 11), (1.5, 11), (0.5, 10), (1, 9), (1, 10), (1, 11), (1, 10), (1, 9), (1, 8),
            (1.5, 7), (0.5, 11), (1, 10), (1, 9), (1, 10), (1, 11), (1, 12), (1, 11), (1, 7), (1, 11), (1, 10), (1, 9),
            (1, 10), (1, 11), (1, 12), (1, 11), (1, 7), (1, 12), (1, 11), (1, 10), (1, 9), (1, 8), (1, 7), (1, 8),
            (1, 7), (1.5, 7), (0.5, 11), (1, 10), (0.5, 9), (1, 10), (1, 11), (1, 12), (1, 11), (1, 7), (1, 11), (1, 10),
            (1, 9), (1, 10), (1, 11), (1, 12), (1, 11), (1, 7), (1, 12), (1, 11), (1, 10), (1, 9), (1, 8), (1, 7),
            (1, 8), (1, 7)]),
    ]
    static let muertos: [SongRecipe] = [
        // La Llorona (traditional; the first couplet tune, D minor moved up to A minor)
        // https://github.com/baobach/abc_search/blob/main/database/abc/QmVxmDt9pfR6yVSK4FK38kehyaVvEoHJ5UZHcC636wwaAr.abc
        // Basis: a traditional tune of unknown authorship whose earliest prints are from 1935-36; no pre-1930 printed score was
        // found, so the notes are read from a modern MuseScore export (ABC) of the bare tune, checked against a LilyPond lead sheet.
        // Departures: the first couplet tune only (the second needs a black key); the ABC's rhythm is followed (the lead sheet has
        // a plainer one for the same pitches), so the second pass has E5 A5 G5 (#21-23) where the first has E5 E5 (#4-5); the
        // 5-beat gap (half note D5 plus a whole-bar rest) before #18 is 3 beats.
        SongRecipe(name: "La Llorona", instrument: .guitar, melody: [
            (1, 9), (1.5, 9), (0.5, 9), (1, 9), (2, 9), (1, 11), (1, 10), (1.5, 9), (0.5, 11), (1, 10), (2, 9), (1.5, 9),
            (1, 9), (1, 10), (2, 9), (1, 9), (1, 8), (3, 9), (1.5, 9), (0.5, 9), (1, 9), (1, 12), (1.5, 11), (0.5, 11),
            (1, 10), (1.5, 9), (0.5, 11), (1, 10), (2, 9), (1.5, 9), (1, 9), (1, 10), (2, 9), (1.5, 9), (1, 8)]),
        // Cielito Lindo (Mendoza, 1882; the refrain, C major as printed) - https://imslp.org/wiki/Cielito_lindo_(Fernandez,_C.)
        // Departures: five gaps longer than 3 beats are 3: the 6-beat A4s on 'thine' and 'pines' (#5 and #31 come 3 after them),
        // the 4-beat C5s on 'lover' and 'discover' (#10 and #36 come 3 after them) and the 3-beat 'hover' plus two quarter rests,
        // 5 beats in all (#27 comes 3 after it).
        SongRecipe(name: "Cielito Lindo", instrument: .guitar, melody: [
            (1, 9), (3, 8), (2, 7), (1, 5), (3, 8), (3, 8), (2, 7), (1, 9), (1.5, 7), (3, 4), (1, 5), (2, 4),
            (1, 5), (2, 4), (1, 10), (1, 10), (1, 8), (1, 6), (2, 4), (1, 5), (2, 4), (1, 3), (2, 4), (1, 2),
            (1, 1), (1, 0), (3, 9), (3, 8), (2, 7), (1.5, 5), (3, 8), (3, 8), (2, 7), (1, 9), (1, 7), (3, 4),
            (1, 5), (2, 4), (1, 5), (2, 4), (1, 10), (1, 10), (1, 8), (1, 6), (2, 4), (1, 5), (2, 4), (1, 3),
            (1, 3), (1, 4), (1, 2), (1, 1), (1, 0)]),
        // Las Mañanitas (traditional Mexican; the first strophe, A major moved up a third to C; stands in for La Bamba, see the spec)
        // https://en.wikipedia.org/wiki/Las_Ma%C3%B1anitas
        // Basis: a traditional tune of disputed authorship (Esparza Oteo, Ponce and Manzo are all credited, none died before 1931);
        // the scores read are a Wikipedia LilyPond score and a 2024 CC0 edition, and no pre-1930 printed edition was found.
        // Departures: the first strophe only (pickup and 16 bars; the second section in Ponce's edition is left out); none in rhythm.
        SongRecipe(name: "Las Mañanitas", instrument: .guitar, melody: [
            (1, 4), (1, 4), (1, 7), (1.5, 7), (1, 6), (1, 7), (1, 8), (1.5, 6), (0.5, 7), (1, 8), (1, 9), (1.5, 7),
            (1, 8), (1, 9), (0.5, 10), (2, 10), (1.5, 10), (1, 9), (1.5, 8), (1, 7), (0.5, 6), (1, 8), (1, 7), (1, 6),
            (1, 7), (1, 8), (1, 9), (1, 10), (1, 8), (1, 7), (2, 9), (1, 8), (1, 6), (0.5, 6), (1, 7), (1, 8),
            (1, 9), (1, 7), (1, 9), (1, 8), (1, 6), (1, 6), (1, 7), (1, 8), (1, 9), (2, 7), (0.5, 7), (1, 10),
            (1.5, 10), (0.5, 11), (0.5, 10), (1, 9), (1, 7), (0.5, 6), (1, 7), (0.5, 8), (0.5, 9), (1, 10), (1, 8), (1, 7)]),
    ]

    static var all: [SongRecipe] { newYear + valentines + stPatricks + easter + muertos }
}
