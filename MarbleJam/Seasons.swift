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

    private static func date(_ y: Int, _ m: Int, _ d: Int, _ cal: Calendar) -> Date { cal.date(from: DateComponents(year: y, month: m, day: d))! }

    static let all: [Season] = [
        Season(id: "halloween", title: "Halloween", emoji: "🎃", banner: "🎃 Halloween is here!", songs: [
            SongRecipe(name: "In the Hall of the Mountain King", instrument: .chip, melody: [
                (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 7), (1, 9), (2, 8), (1, 6), (1, 8), (2, 8), (1, 6), (1, 8), (2, 5), (1, 6), (1, 7)]),
            SongRecipe(name: "Toccata and Fugue", instrument: .piano, melody: [
                (1, 9), (1, 8), (1, 9), (2, 8), (0.5, 7), (1, 6), (0.5, 5), (1, 4), (1, 5), (2, 9), (0.5, 8), (1, 9)]),
            SongRecipe(name: "Funeral March", instrument: .marimba, melody: [
                (1, 5), (1, 5), (1.5, 5), (1, 5), (2, 7), (1.5, 6), (1, 6), (1.5, 5), (1, 5), (1.5, 4), (0.5, 5)]),
        ], window: { y, cal in (date(y, 10, 1, cal), date(y, 11, 1, cal)) }),
        Season(id: "thanksgiving", title: "Thanksgiving", emoji: "🦃", banner: "🦃 Happy Thanksgiving!", songs: [
            SongRecipe(name: "We Gather Together", instrument: .guitar, melody: [
                (1, 11), (1, 11), (1.5, 12), (0.5, 11), (1, 9), (1.5, 10), (0.5, 11), (1, 10), (1.5, 9), (0.5, 8), (1, 9), (2, 7), (1.5, 11), (1, 11), (1.5, 12)]),
            SongRecipe(name: "Come, Ye Thankful People", instrument: .guitar, melody: [
                (1, 9), (1, 9), (1, 11), (1, 9), (1, 7), (1, 8), (1, 9), (2, 9), (1, 9), (1, 11), (1, 9), (1, 7), (1, 8), (1, 9)]),
            SongRecipe(name: "Simple Gifts", instrument: .guitar, melody: [
                (1, 4), (1, 4), (1, 7), (1, 7), (1, 8), (1, 9), (1, 7), (1.5, 9), (0.5, 10), (1, 11), (1, 11), (1, 11), (1, 9), (1, 8), (1, 7)]),
        ], window: { y, cal in (date(y, 11, 2, cal), cal.date(byAdding: .day, value: 1, to: thanksgiving(year: y, calendar: cal))!) }),
        Season(id: "christmas", title: "Christmas", emoji: "🎄", banner: "🎄 Merry Christmas!", songs: [
            SongRecipe(name: "Jingle Bells", instrument: .bells, melody: [
                (1, 9), (1, 9), (1, 9), (2, 9), (1, 9), (1, 9), (2, 9), (1, 11), (1, 7), (1.5, 8), (1, 9), (2, 10), (1.5, 10), (1, 10), (1.5, 10), (1, 10)]),
            SongRecipe(name: "Deck the Halls", instrument: .bells, melody: [
                (1, 11), (1.5, 10), (0.5, 9), (1, 8), (1, 7), (1, 8), (1, 9), (1, 7), (1, 8), (1, 9), (1, 10), (1, 8), (1, 9), (1.5, 8), (1, 7), (1, 6), (1, 7)]),
            SongRecipe(name: "We Wish You a Merry Christmas", instrument: .bells, melody: [
                (1, 4), (1, 7), (1, 7), (1, 8), (1, 7), (1, 6), (1, 5), (1, 5), (1, 5), (1, 8), (1, 8), (1, 9), (1, 8), (1, 7), (1, 6), (1, 4), (1, 4)]),
            SongRecipe(name: "Silent Night", instrument: .bells, melody: [
                (1, 4), (1.5, 5), (1, 4), (1, 2), (2, 4), (1.5, 5), (1, 4), (1, 2), (2, 8), (2, 8), (1, 6), (2, 7), (2, 7), (1, 4)]),
        ], window: { y, cal in (date(y, 12, 1, cal), date(y + 1, 1, 6, cal)) }),
    ]

    /// The season whose window contains `date` (windows starting this year or, for ones crossing New Year, last year).
    static func active(on date: Date, calendar: Calendar) -> Season? {
        let year = calendar.component(.year, from: date), today = calendar.startOfDay(for: date)
        for s in all {
            for y in [year - 1, year] {
                let w = s.window(y, calendar)
                if today >= calendar.startOfDay(for: w.first) && today <= calendar.startOfDay(for: w.last) { return s }
            }
        }
        return nil
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
