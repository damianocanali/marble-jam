import Foundation

/// The five newer holidays' ready-made songs (public-domain melodies on the white-key bars; see Seasons.swift for the
/// note and beat format). Each recipe names the score it was taken from. Where Engine.smartAdd could not lay out a pad at the
/// score's spacing, that note's beats were lengthened to the next allowed value (the commit message lists each one).
enum HolidaySongs {
    static let newYear: [SongRecipe] = [
        // Auld Lang Syne (verse and chorus, F major score moved up a fifth to C) - https://en.wikipedia.org/wiki/Auld_Lang_Syne
        SongRecipe(name: "Auld Lang Syne", instrument: .bells, melody: [
            (1, 4), (1, 7), (1.5, 7), (1, 7), (1, 9), (1, 8), (1.5, 7), (1, 8), (1, 9), (1, 7), (1.5, 7), (1, 9),
            (1, 11), (1, 12), (3, 12), (1, 11), (1.5, 9), (1.5, 9), (1, 7), (1, 8), (1.5, 7), (1, 8), (1, 9), (1, 7),
            (1.5, 5), (1, 5), (1, 4), (1, 7), (3, 12), (1.5, 11), (1.5, 9), (0.5, 9), (1, 7), (1, 8), (1.5, 7), (1, 8),
            (1, 12), (1, 11), (1.5, 9), (1, 9), (1, 11), (1, 12), (3, 12), (1, 11), (1.5, 9), (1.5, 9), (1, 7), (1, 8),
            (1.5, 7), (1, 8), (1, 9), (1, 7), (1.5, 5), (1, 5), (1, 4), (1, 7)]),
        // The Blue Danube (Strauss II, bars 1-16 of the first waltz, D major moved down a step to C)
        // https://imslp.org/wiki/An_der_sch%C3%B6nen_blauen_Donau,_Op.314_(Strauss_Jr.,_Johann)
        SongRecipe(name: "The Blue Danube", instrument: .bells, melody: [
            (1, 0), (1, 2), (1, 4), (1, 4), (2, 11), (1, 11), (2, 9), (1, 9), (2, 0), (1, 0), (1, 2), (1, 4),
            (1, 4), (2, 11), (1, 11), (2, 10), (1, 10), (2, 6), (1, 6), (1, 8), (1, 12), (1, 12), (2, 12), (1, 12),
            (2, 10), (1, 10), (2, 6), (1, 6), (1, 8), (1, 12), (1, 12), (2, 12), (1, 12), (2, 9), (1, 9)]),
        // Ode to Joy (Beethoven, the 16-bar theme; stands in for Radetzky March, whose theme needs black keys) - https://en.wikipedia.org/wiki/Ode_to_Joy
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
        SongRecipe(name: "Plaisir d'amour", instrument: .piano, melody: [
            (1, 4), (1, 7), (1.5, 8), (1.5, 9), (3, 9), (1, 10), (1.5, 10), (1, 9), (0.5, 8), (0.5, 9), (1, 8), (2, 4),
            (1, 5), (1.5, 6), (1.5, 7), (0.5, 8), (0.5, 9), (0.5, 5), (1.5, 8), (1, 10), (1, 9), (1.5, 8), (0.5, 9), (1, 8),
            (0.5, 7), (0.5, 8), (1, 9), (1, 7)]),
        // Drink to Me Only with Thine Eyes (traditional English, c. 1770; first verse, E-flat major moved down to C; stands in for
        // Let Me Call You Sweetheart, which needs a black key in every transposition) - https://www.flutetunes.com/tunes.php?id=9
        SongRecipe(name: "Drink to Me Only with Thine Eyes", instrument: .piano, melody: [
            (1, 2), (1, 2), (1, 2), (1, 3), (1, 3), (1, 4), (1, 3), (1, 2), (1, 1), (1, 2), (1, 3), (1, 4),
            (1, 0), (1, 3), (1, 2), (1, 1), (1, 0), (3, 2), (1, 2), (1.5, 2), (1.5, 3), (1.5, 3), (0.5, 4), (0.5, 3),
            (1, 2), (0.5, 1), (1, 2), (1, 3), (1, 4), (1, 0), (1, 3), (1, 2), (1, 1), (1, 0), (2, 4), (1, 4),
            (1, 2), (1, 4), (1, 7), (1, 4), (1, 4), (1, 2), (1, 4), (1, 4), (1, 4), (1, 5), (1, 4), (1, 4),
            (1, 3), (1, 2), (1, 2), (1.5, 1), (1.5, 2), (0.5, 2), (1, 2), (1, 3), (1, 3), (1, 4), (1, 3), (1, 2),
            (1, 1), (1, 2), (1, 3), (1, 4), (1, 0), (1, 3), (1, 2), (1, 1), (1, 0)]),
        // Aura Lee (Poulton, 1861; verse and chorus, G major moved up a fourth to C)
        // first edition, J. Church Jr., Cincinnati: https://levysheetmusic.mse.jhu.edu/collection/024/002
        SongRecipe(name: "Aura Lee", instrument: .piano, melody: [
            (1, 4), (1.5, 7), (1, 6), (1, 7), (1, 8), (1, 5), (1, 8), (2, 7), (1, 6), (1, 5), (1, 6), (1, 7),
            (3, 4), (1.5, 7), (0.5, 6), (1, 7), (1, 8), (1, 5), (1, 8), (2, 7), (1.5, 6), (1, 5), (1, 6), (1, 7),
            (3, 9), (1, 9), (1.5, 9), (2, 9), (1, 9), (1, 9), (2, 9), (1.5, 8), (0.5, 7), (1, 8), (1, 9), (3, 9),
            (1, 9), (1.5, 10), (1.5, 9), (0.5, 8), (1, 5), (1, 8), (1.5, 8), (1, 7), (1, 6), (1.5, 9), (1.5, 8), (0.5, 7)]),
    ]
    static let stPatricks: [SongRecipe] = [
        // Molly Malone (verse and chorus, G major as written)
        // https://abcnotation.com/tunePage?a=dmc.lizmilner.com/viewabc.vbhtml%3Ffile=Molly+Malone/0002 (also https://thesession.org/tunes/12844)
        SongRecipe(name: "Molly Malone", instrument: .guitar, melody: [
            (1, 1), (1, 4), (1, 4), (1.5, 4), (1, 4), (1, 6), (1.5, 4), (1, 5), (1, 5), (1.5, 5), (0.5, 5), (1, 7),
            (1.5, 5), (1, 6), (1, 5), (1, 4), (1, 8), (1, 7), (1, 6), (1, 6), (1.5, 5), (1, 4), (1, 5), (2, 1),
            (0.5, 1), (1, 4), (1, 4), (1.5, 4), (0.5, 4), (1, 6), (1.5, 4), (1, 5), (1, 5), (1.5, 5), (1, 5), (1, 7),
            (1.5, 5), (0.5, 5), (1, 6), (1, 8), (1.5, 7), (1, 6), (1, 8), (1.5, 7), (1, 6), (1.5, 4), (1, 5), (1, 4),
            (2, 1), (1, 4), (1.5, 4), (1, 4), (1, 4), (1, 6), (1.5, 4), (1, 5), (1.5, 5), (0.5, 5), (1, 5), (0.5, 7),
            (1.5, 5), (0.5, 5), (1, 6), (0.5, 8), (1.5, 7), (1, 6), (1, 8), (1.5, 7), (1, 6), (1.5, 4), (1, 5), (1, 4)]),
        // The Irish Washerwoman (the A part, G major as written) - https://thesession.org/tunes/92#setting92
        SongRecipe(name: "The Irish Washerwoman", instrument: .guitar, melody: [
            (1, 6), (1, 4), (1, 4), (1, 1), (1, 4), (1, 4), (1, 6), (1, 4), (1, 6), (1, 8), (1, 7), (1, 6),
            (1, 7), (1, 5), (1, 5), (1, 2), (1, 5), (1, 5), (1, 7), (1, 5), (0.5, 7), (1, 9), (1, 8), (1, 7),
            (1, 6), (1, 4), (1, 4), (1, 1), (1, 4), (1, 4), (1, 6), (1, 4), (1, 6), (1, 8), (1, 7), (1, 6),
            (1, 7), (1, 6), (1, 7), (1, 5), (1, 8), (1, 7), (1, 6), (1, 4), (1, 4), (1, 4)]),
        // Londonderry Air (Petrie, 1855; the second strain, E-flat major moved up a step to F)
        // https://en.wikipedia.org/wiki/Londonderry_Air
        SongRecipe(name: "Londonderry Air", instrument: .guitar, melody: [
            (1, 7), (1, 8), (1, 9), (1, 10), (1.5, 9), (1, 9), (1, 8), (1, 7), (1, 5), (1, 7), (1, 5), (1, 3),
            (1.5, 7), (1, 8), (0.5, 9), (0.5, 10), (1.5, 9), (0.5, 9), (1, 8), (0.5, 7), (1, 5), (1, 4), (3, 7), (1, 7),
            (1, 7), (0.5, 12), (1.5, 11), (0.5, 11), (0.5, 10), (1, 8), (0.5, 10), (1, 7), (1, 5), (1, 3), (1.5, 2), (1, 3),
            (1, 4), (1, 5), (1, 8), (1, 7), (1, 5), (1, 4), (1, 3), (1, 1), (1, 2), (1, 3)]),
    ]
    static let easter: [SongRecipe] = [
        // Hot Cross Buns (the whole song, G major moved up a fourth to C) - https://en.wikipedia.org/wiki/Hot_Cross_Buns_(song)
        SongRecipe(name: "Hot Cross Buns", instrument: .marimba, melody: [
            (1, 9), (1, 8), (1, 7), (2, 9), (1, 8), (1, 7), (2, 7), (0.5, 7), (1, 7), (0.5, 7), (1, 8), (1, 8),
            (1, 8), (1, 8), (1, 9), (1, 8), (1, 7)]),
        // Christ the Lord Is Risen Today (Easter Hymn, 1708; the whole verse, C major as written)
        // https://en.wikisource.org/wiki/Page:The_Army_and_Navy_Hymnal.djvu/87
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
        SongRecipe(name: "La Llorona", instrument: .guitar, melody: [
            (1, 9), (1.5, 9), (0.5, 9), (1, 9), (2, 9), (1, 11), (1, 10), (1.5, 9), (0.5, 11), (1, 10), (2, 9), (1.5, 9),
            (1, 9), (1, 10), (2, 9), (1, 9), (1, 8), (3, 9), (1.5, 9), (0.5, 9), (1, 9), (1, 12), (1.5, 11), (0.5, 11),
            (1, 10), (1.5, 9), (0.5, 11), (1, 10), (2, 9), (1.5, 9), (1, 9), (1, 10), (2, 9), (1.5, 9), (1, 8)]),
        // Cielito Lindo (Mendoza, 1882; the refrain, C major as printed) - https://imslp.org/wiki/Cielito_lindo_(Fernandez,_C.)
        SongRecipe(name: "Cielito Lindo", instrument: .guitar, melody: [
            (1, 9), (3, 8), (2, 7), (1, 5), (3, 8), (3, 8), (2, 7), (1, 9), (1.5, 7), (3, 4), (1, 5), (2, 4),
            (1, 5), (2, 4), (1, 10), (1, 10), (1, 8), (1, 6), (2, 4), (1, 5), (2, 4), (1, 3), (2, 4), (1, 2),
            (1, 1), (1, 0), (3, 9), (3, 8), (2, 7), (1.5, 5), (3, 8), (3, 8), (2, 7), (1, 9), (1, 7), (3, 4),
            (1, 5), (2, 4), (1, 5), (2, 4), (1, 10), (1, 10), (1, 8), (1, 6), (2, 4), (1, 5), (2, 4), (1, 3),
            (1, 3), (1, 4), (1, 2), (1, 1), (1, 0)]),
        // Las Mañanitas (traditional Mexican; the first strophe, A major moved up a third to C; stands in for La Bamba)
        // https://en.wikipedia.org/wiki/Las_Ma%C3%B1anitas
        SongRecipe(name: "Las Mañanitas", instrument: .guitar, melody: [
            (1, 4), (1, 4), (1, 7), (1.5, 7), (1, 6), (1, 7), (1, 8), (1.5, 6), (0.5, 7), (1, 8), (1, 9), (1.5, 7),
            (1, 8), (1, 9), (0.5, 10), (2, 10), (1.5, 10), (1, 9), (1.5, 8), (1, 7), (0.5, 6), (1, 8), (1, 7), (1, 6),
            (1, 7), (1, 8), (1, 9), (1, 10), (1, 8), (1, 7), (2, 9), (1, 8), (1, 6), (0.5, 6), (1, 7), (1, 8),
            (1, 9), (1, 7), (1, 9), (1, 8), (1, 6), (1, 6), (1, 7), (1, 8), (1, 9), (2, 7), (0.5, 7), (1, 10),
            (1.5, 10), (0.5, 11), (0.5, 10), (1, 9), (1, 7), (0.5, 6), (1, 7), (0.5, 8), (0.5, 9), (1, 10), (1, 8), (1, 7)]),
    ]

    static var all: [SongRecipe] { newYear + valentines + stPatricks + easter + muertos }
}
