import Foundation

/// The five newer holidays' ready-made songs (public-domain or traditional melodies on the white-key bars; see Seasons.swift
/// for the note and beat format). Each recipe names the score it was taken from and lists its "Departures": every way the
/// notes differ from that score apart from the transposition. Note numbers count from 1, and "beats" is the gap before a note.
/// Where Engine.smartAdd could not lay out a pad at the score's spacing, that note's beats were lengthened to the next allowed
/// value; the messages of the commits "Songs for the five new holidays" and "Swap four holiday songs whose rights are unclear"
/// list each of those, and they are not repeated below. Why each song is safe to use: the Rights notes in
/// docs/superpowers/specs/2026-10-21-new-holidays-design.md.
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
        // Plaisir d'amour (Martini, composed 1784, published 1785; the refrain, F major moved up a fifth to C)
        // Leduc edition, Paris 1918: https://commons.wikimedia.org/wiki/File:Plaisir_d%27amour._Paroles_de_Florian._Musique_de_J.-P._Martini_-_bpt6k889731m_(4_of_8).jpg
        // Departures: one statement of the refrain only; two 2.5-beat gaps are rounded (#5 up to 3, #12 down to 2, so 'Chagrin'
        // is back on its beat); the four 32nd-note gaps of the run on 'vie' (#24-27, each 0.125 beat) are 0.5 beat each before
        // fitting (1.5 beats longer than written); fitting then lengthened #24 and #27 to 1, so as shipped (1, 0.5, 0.5, 1) the
        // run lasts 2.5 beats longer than written.
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
        // (#23 C5 comes 3 after it); before fitting, every other beats value is the score's own (fitting then lengthened 31 of the
        // 46 notes, as the header's commit message lists).
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
        // La Cucaracha (traditional; the chorus and the verse, F major moved up a fifth to C; replaces La Llorona)
        // Score: The Public Domain Song Anthology (Berger and Israels, Aperio, 2020, CC0 1.0), p. 175 - https://doi.org/10.32881/book2
        // (its MusicXML: https://dataverse.lib.virginia.edu/api/access/datafile/3681), checked against Sandburg, The American
        // Songbag (1927), pp. 289-291 - https://archive.org/details/americansongbag00sandb
        // Public domain: traditional, no known author; named in a novel of 1819, verses printed in 1883, printed with music in the
        // US in 1927 (https://en.wikipedia.org/wiki/La_Cucaracha); the edition read is CC0. Spanish in origin, not the expression of
        // one Indigenous or Afro-Mexican community.
        // Departures: none before fitting (the chorus is not sung again after the verse); where the 1927 print differs (chorus bar
        // 3, verse bar 3, dotted eighths in chorus bars 1 and 5) the anthology is followed; fitting lengthened 33 of the 66 notes.
        SongRecipe(name: "La Cucaracha", instrument: .guitar, melody: [
            (1, 4), (1, 4), (1, 4), (1, 7), (1, 9), (1, 4), (1, 4), (1, 4), (1, 7), (1, 9), (2, 7), (0.5, 7),
            (1, 6), (0.5, 6), (1, 5), (1, 5), (1, 4), (1.5, 4), (1, 4), (1, 4), (1, 6), (1, 8), (1, 4), (1, 4),
            (1, 4), (1, 6), (1, 8), (2, 11), (0.5, 12), (1, 11), (0.5, 10), (0.5, 9), (1, 8), (0.5, 7), (3, 4), (1, 4),
            (1, 7), (1, 7), (1, 9), (1, 9), (1, 11), (1, 9), (2, 11), (0.5, 12), (1, 11), (0.5, 10), (0.5, 9), (1, 11),
            (0.5, 10), (1, 8), (2, 4), (0.5, 4), (0.5, 6), (1, 6), (0.5, 8), (0.5, 8), (0.5, 10), (1, 8), (2, 11), (0.5, 12),
            (1, 11), (0.5, 10), (1, 9), (1, 8), (1, 9), (1, 7)]),
        // La Paloma (Yradier, c. 1860; the refrain, C major as printed; replaces Cielito Lindo)
        // Score: 'Original edition', Boston, Ditson?, ca. 1885 (IMSLP PMLP100689) - https://imslp.org/wiki/La_paloma_(Yradier,_Sebasti%C3%A1n)
        // (read from its mirror https://archive.org/details/imslp-paloma-yradier-sebastin), checked against White, Smith & Co.'s
        // Artists' Vocal Album (1878/1887) - https://archive.org/details/artistsvocalalbu00bost
        // Public domain: Sebastián Iradier (Yradier) died in 1865 (https://en.wikipedia.org/wiki/Sebasti%C3%A1n_Iradier), so even
        // Mexico's life + 100 ended in 1965.
        // Departures: 1 beat is a triplet eighth (a quarter is 3), so the triplets are exact; the sixteenth pair G4 F4 (#24-25 and
        // #49-50) is 0.5 + 1 (F4 comes a quarter of a beat early); the 10.5-beat holds on G4 and E4 are 3 (#13, #26 and #38 come 3
        // after them); the refrain only (the chorus '¡Ay! chinita que sí' needs F sharp); fitting lengthened 4 of the 50 notes.
        SongRecipe(name: "La Paloma", instrument: .guitar, melody: [
            (1, 7), (1, 7), (1, 7), (1, 7), (1.5, 6), (1.5, 8), (1, 8), (1, 7), (1, 6), (1.5, 5), (1.5, 5), (1.5, 4),
            (3, 6), (1, 6), (1, 6), (1, 6), (1.5, 5), (1.5, 5), (1, 4), (1, 4), (1, 4), (1.5, 5), (1.5, 4), (1, 3),
            (1, 2), (3, 7), (1, 7), (1.5, 7), (1.5, 7), (1.5, 6), (1.5, 8), (1, 8), (1, 7), (1, 6), (1.5, 5), (1.5, 5),
            (1.5, 4), (3, 6), (1, 6), (1, 6), (1, 6), (1.5, 5), (1.5, 5), (1, 4), (1, 4), (1, 4), (1.5, 5), (1.5, 4),
            (1, 3), (1, 2)]),
        // Mambrú se fue a la guerra (traditional French 'Malbrough s'en va-t-en guerre'; one stanza, G major moved up a fourth to C;
        // replaces Las Mañanitas)
        // Score: Chansons de France pour les petits Français (Weckerlin; Paris: Plon-Nourrit, c. 1900), pp. 17-18
        // https://archive.org/details/chansonsdefrance00weck , checked against Chants et chansons populaires de la France (Paris:
        // Garnier, 1848) - https://archive.org/details/chantsetchansons03unse
        // Public domain: anonymous, made after Malplaquet (1709) and famous from 1781; the tune of For He's a Jolly Good Fellow
        // (https://en.wikipedia.org/wiki/Marlbrough_s%27en_va-t-en_guerre).
        // Departures: 1 beat is an eighth (Weckerlin's dotted pairs are exact); the 5-eighth gaps before #30 and #36 are 3; part A
        // is not played again after part B (the print's D.C. al Fine); fitting lengthened 6 of the 41 notes.
        SongRecipe(name: "Mambrú se fue a la guerra", instrument: .guitar, melody: [
            (1, 4), (1, 9), (2, 9), (1, 9), (2, 8), (1, 10), (3, 9), (1.5, 10), (1, 9), (1, 8), (2, 8), (1, 8),
            (1.5, 7), (0.5, 8), (1, 9), (3, 7), (2, 4), (1.5, 9), (2, 9), (1, 9), (2, 8), (1.5, 10), (3, 9), (2, 11),
            (1.5, 9), (2, 7), (1, 8), (2, 6), (1.5, 7), (3, 11), (1, 11), (2, 9), (1, 12), (2, 12), (1.5, 11), (3, 11),
            (1, 11), (2, 9), (1, 12), (2, 12), (1, 11)]),
    ]

    static var all: [SongRecipe] { newYear + valentines + stPatricks + easter + muertos }
}
