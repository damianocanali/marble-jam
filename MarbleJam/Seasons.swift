import Foundation

/// A ready-made song: a public-domain melody laid out as a course. Notes are bar note indexes (0...14 = C4...C6, white keys);
/// `beats` is the time since the previous note.
struct SongRecipe {
    let name: String
    let instrument: Instrument
    let melody: [(beats: Double, note: Int)]

    func course() -> Course {
        var c = Course()
        for m in melody { _ = Engine.smartAdd(&c, beats: m.beats, note: m.note) }
        return c
    }
}

/// A holiday pack. Its window comes round every year.
struct Season: Identifiable {
    let id: String
    let title: String
    let emoji: String
    let banner: String
    let songs: [SongRecipe]
    /// Asset name of this holiday's title artwork (made from art/seasons/<id>/source.jpg by tools/cutout_from_art.swift).
    /// The menu uses it when the app has it; otherwise the normal lettering and the banner text.
    var titleArt: String { "SeasonTitle-\(id)" }
    /// The window that starts in `year`: first day and last day (both included).
    let window: (_ year: Int, _ calendar: Calendar) -> (first: Date, last: Date)
}

enum Seasons {
    /// US Thanksgiving: the fourth Thursday of November, at the start of the day.
    static func thanksgiving(year: Int, calendar: Calendar) -> Date {
        let nov1 = calendar.date(from: DateComponents(year: year, month: 11, day: 1))!
        let firstThursday = 1 + (5 - calendar.component(.weekday, from: nov1) + 7) % 7      // weekday: Sunday = 1, Thursday = 5
        return calendar.date(from: DateComponents(year: year, month: 11, day: firstThursday + 21))!
    }

    /// Western (Gregorian) Easter Sunday, at the start of the day: the anonymous Gregorian algorithm (Meeus/Jones/Butcher).
    static func easter(year y: Int, calendar: Calendar) -> Date {
        let a = y % 19, b = y / 100, c = y % 100, d = b / 4, e = b % 4, f = (b + 8) / 25, g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30, i = c / 4, k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7, m = (a + 11 * h + 22 * l) / 451
        let n = h + l - 7 * m + 114
        return calendar.date(from: DateComponents(year: y, month: n / 31, day: n % 31 + 1))!
    }

    private static func date(_ y: Int, _ m: Int, _ d: Int, _ cal: Calendar) -> Date { cal.date(from: DateComponents(year: y, month: m, day: d))! }

    static let all: [Season] = [
        Season(id: "halloween", title: "Halloween", emoji: "🎃", banner: "🎃 Halloween is here!", songs: [
            SongRecipe(name: "In the Hall of the Mountain King", instrument: .chip, melody: [
                (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 9), (1, 11), (2, 12), (1, 9), (1, 12), (2, 11), (1, 9), (1, 11), (2, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 9), (1, 11), (2, 12), (0.5, 9), (1, 12), (2, 11), (1, 9), (1, 11), (2, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 6), (1, 8), (2, 9), (1, 6), (1, 9), (2, 8), (1, 6), (1, 8), (2, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 9), (1, 11), (2, 12), (1, 9), (1, 12), (2, 11), (1, 9), (1, 11), (2, 11), (1, 9), (1, 7)]),
            SongRecipe(name: "Toccata and Fugue", instrument: .piano, melody: [
                (1, 9), (1, 8), (1, 9), (3, 8), (1, 7), (1.5, 6), (1.5, 5), (1, 4), (2, 5), (3, 9), (1, 8), (1, 9), (3, 8), (1, 7), (1, 6), (1, 5), (1, 4), (2, 5), (3, 9), (1, 8), (1, 7), (1, 6), (1, 5), (1, 4), (1, 3), (1, 2), (1, 1), (2, 2), (2, 5)]),
            SongRecipe(name: "Funeral March", instrument: .marimba, melody: [
                (1, 5), (2, 5), (3, 5), (1, 5), (2, 7), (3, 6), (1, 6), (3, 5), (1, 5), (3, 4), (1, 5), (3, 5), (2, 5), (3, 5), (1, 5), (2, 7), (3, 6), (1, 6), (3, 5), (1.5, 5), (3, 4), (1, 5), (3, 9), (3, 8), (1, 7), (2, 6), (2, 5), (3, 4), (1, 5)]),
        ], window: { y, cal in (date(y, 10, 1, cal), date(y, 10, 31, cal)) }),
        Season(id: "thanksgiving", title: "Thanksgiving", emoji: "🦃", banner: "🦃 Happy Thanksgiving!", songs: [
            SongRecipe(name: "We Gather Together", instrument: .guitar, melody: [
                (1, 11), (1, 11), (1.5, 12), (0.5, 11), (1, 9), (1.5, 10), (0.5, 11), (1, 10), (1.5, 9), (0.5, 8), (1, 9), (2, 7), (1.5, 11), (1, 11), (1.5, 12)]),
            SongRecipe(name: "Come, Ye Thankful People", instrument: .guitar, melody: [
                (1, 9), (3, 9), (1, 11), (2, 9), (2, 7), (2, 8), (2, 9), (3, 9), (3, 9), (1, 11), (2, 9), (2, 7), (2, 8), (2, 9), (3, 9), (3, 9), (1, 10), (2, 10), (2, 8), (3, 8), (1, 9), (3, 9), (2, 10), (2, 11), (2, 7), (2, 6), (2, 5), (2, 4), (3, 6), (3, 6), (1, 8), (2, 6), (2, 7), (2, 8), (2, 9), (3, 9), (3, 9), (1, 11), (2, 9), (2, 10), (2, 11), (2, 12), (3, 12), (3, 12), (1, 10), (2, 8), (2, 11), (3, 11), (1, 9), (3, 10), (2, 12), (2, 11), (2, 7), (2, 9), (2, 8), (2, 7)]),
            SongRecipe(name: "Simple Gifts", instrument: .guitar, melody: [
                (1, 4), (1, 4), (1, 7), (1, 7), (1, 8), (1, 9), (1, 7), (1.5, 9), (0.5, 10), (1, 11), (1, 11), (1, 11), (1, 9), (1, 8), (1, 7)]),
        ], window: { y, cal in (date(y, 11, 8, cal), cal.date(byAdding: .day, value: 1, to: thanksgiving(year: y, calendar: cal))!) }),
        Season(id: "christmas", title: "Christmas", emoji: "🎄", banner: "🎄 Merry Christmas!", songs: [
            SongRecipe(name: "Jingle Bells", instrument: .bells, melody: [
                (1, 9), (2, 9), (2, 9), (3, 9), (2, 9), (2, 9), (3, 9), (2, 11), (2, 7), (3, 8), (1, 9), (3, 10), (2, 10), (2, 10), (3, 10), (1, 10), (2, 9), (2, 9), (2, 9), (1, 9), (1, 9), (2, 8), (2, 8), (2, 9), (2, 8), (3, 11), (3, 9), (2, 9), (2, 9), (3, 9), (2, 9), (2, 9), (3, 9), (2, 11), (2, 7), (3, 8), (1, 9), (3, 10), (2, 10), (2, 10), (3, 10), (1, 10), (2, 9), (2, 9), (2, 9), (1, 9), (1, 11), (2, 11), (2, 10), (2, 8), (2, 7)]),
            SongRecipe(name: "Deck the Halls", instrument: .bells, melody: [
                (1, 11), (3, 10), (1, 9), (2, 8), (2, 7), (2, 8), (2, 9), (2, 7), (2, 8), (1, 9), (1, 10), (1, 8), (1, 9), (3, 8), (1, 7), (2, 6), (2, 7), (3, 11), (3, 10), (1, 9), (2, 8), (2, 7), (2, 8), (2, 9), (2, 7), (2, 8), (1, 9), (1, 10), (1, 8), (1, 9), (3, 8), (1, 7), (2, 6), (2, 7), (3, 8), (3, 9), (1, 10), (2, 8), (2, 9), (3, 10), (1, 11), (2, 8), (2, 9), (1, 10), (1, 11), (2, 9), (1, 10), (1, 11), (2, 12), (1, 13), (1, 14), (2, 13), (2, 12), (2, 11), (3, 11), (3, 10), (1, 9), (2, 8), (2, 7), (2, 8), (2, 9), (2, 7), (2, 12), (1, 12), (1, 12), (1, 11), (1, 10), (3, 9), (1, 8), (2, 7)]),
            // O Christmas Tree (traditional German, the 'Lauriger Horatius' tune; the whole tune, G major moved up a fourth to C;
            // replaces We Wish You a Merry Christmas, see the Rights notes in docs/superpowers/specs/2026-10-21-new-holidays-design.md)
            // Score: Marzo, Fifty Christmas Carols of All Nations (Cincinnati: Willis, 1923), p. 22 - https://archive.org/details/uclamusic_9921601523606533
            // checked against Bantock, One Hundred Folksongs of All Nations (Ditson, 1911), no. 34 - https://archive.org/details/onehundredfolkso00bant
            // Public domain: an anonymous German folk tune, in print with music by 1843 (https://de.wikipedia.org/wiki/O_Tannenbaum);
            // both scores read are themselves pre-1931 US prints.
            // Departures: 1 beat is an eighth (the dotted-eighth + sixteenth figure is exact); the eighth rest in bar 4 is folded into
            // the gap before #16 (3); fitting lengthened #8 (0.5 to 1 to 1.5) and #35 (0.5 to 1).
            SongRecipe(name: "O Christmas Tree", instrument: .bells, melody: [
                (1, 4), (2, 7), (1.5, 7), (0.5, 7), (2, 8), (2, 9), (1.5, 9), (1.5, 9), (3, 9), (1, 8), (1, 9), (1, 10), (2, 6), (2, 8), (2, 7), (3, 11), (1, 11), (1, 9), (1, 12), (3, 11), (1, 11), (1, 10), (1, 10), (3, 10), (1, 10), (1, 8), (1, 11), (3, 10), (1, 10), (1, 9), (1, 9), (2, 4), (2, 7), (1.5, 7), (1, 7), (2, 8), (2, 9), (1.5, 9), (0.5, 9), (3, 9), (1, 8), (1, 9), (1, 10), (2, 6), (2, 8), (2, 7)]),
            SongRecipe(name: "Silent Night", instrument: .bells, melody: [
                (1, 4), (3, 5), (1, 4), (2, 2), (3, 4), (3, 5), (1, 4), (2, 2), (3, 8), (3, 8), (2, 6), (3, 7), (3, 7), (2, 4), (3, 5), (3, 5), (2, 7), (3, 6), (1, 5), (2, 4), (3, 5), (1, 4), (2, 2), (3, 5), (3, 5), (2, 7), (3, 6), (1, 5), (2, 4), (3, 5), (1, 4), (2, 2), (3, 8), (3, 8), (2, 10), (3, 8), (1, 6), (2, 7), (3, 9), (3, 7), (3, 4), (1, 2), (2, 4), (3, 3), (1, 1), (2, 0)]),
        ], window: { y, cal in (date(y, 12, 1, cal), date(y, 12, 30, cal)) }),
        Season(id: "newyear", title: "New Year's Eve", emoji: "🎆", banner: "🎆 Happy New Year!", songs: HolidaySongs.newYear,
               window: { y, cal in (date(y, 12, 31, cal), date(y + 1, 1, 6, cal)) }),
        Season(id: "valentines", title: "Valentine's Day", emoji: "💘", banner: "💘 Happy Valentine's Day!", songs: HolidaySongs.valentines,
               window: { y, cal in (date(y, 2, 1, cal), date(y, 2, 14, cal)) }),
        Season(id: "stpatricks", title: "St. Patrick's Day", emoji: "☘️", banner: "☘️ Happy St. Patrick's Day!", songs: HolidaySongs.stPatricks,
               window: { y, cal in (date(y, 3, 1, cal), date(y, 3, 17, cal)) }),
        Season(id: "easter", title: "Easter", emoji: "🐣", banner: "🐣 Happy Easter!", songs: HolidaySongs.easter, window: { y, cal in
            let sunday = easter(year: y, calendar: cal)
            return (max(cal.date(byAdding: .day, value: -14, to: sunday)!, date(y, 3, 18, cal)), cal.date(byAdding: .day, value: 1, to: sunday)!)
        }),
        Season(id: "muertos", title: "Día de los Muertos", emoji: "🌼", banner: "🌼 ¡Feliz Día de los Muertos!", songs: HolidaySongs.muertos,
               window: { y, cal in (date(y, 11, 1, cal), date(y, 11, 7, cal)) }),
    ]

    /// The season whose window contains `date` (windows starting this year or, for ones crossing New Year, last year).
    /// Holiday dates are Gregorian whatever calendar the phone shows; only its time zone is used.
    static func active(on date: Date, calendar phone: Calendar) -> Season? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = phone.timeZone
        let year = calendar.component(.year, from: date), today = calendar.startOfDay(for: date)
        for s in all {
            for y in [year - 1, year] {
                let w = s.window(y, calendar)
                if today >= calendar.startOfDay(for: w.first) && today <= calendar.startOfDay(for: w.last) { return s }
            }
        }
        return nil
    }

    private static var shelves: [String: [Song]] = [:]
    private static let shelfLock = NSLock()

    /// The season's ready-made songs as templates (not saved). Laying them out takes a moment, so each season is built once.
    static func shelf(for season: Season) -> [Song] {
        shelfLock.lock(); let cached = shelves[season.id]; shelfLock.unlock()
        if let cached { return cached }
        let built = season.songs.map { Song(name: $0.name, course: $0.course(), instrument: $0.instrument) }
        shelfLock.lock(); defer { shelfLock.unlock() }
        if let raced = shelves[season.id] { return raced }
        shelves[season.id] = built
        return built
    }

    /// The live season, unless a DEBUG preview overrides it: "" = by date, "off" = none, otherwise a season id.
    static func current(on date: Date, preview: String, calendar: Calendar = .current) -> Season? {
        switch preview {
        case "": active(on: date, calendar: calendar)
        case "off": nil
        default: all.first { $0.id == preview }
        }
    }
}
