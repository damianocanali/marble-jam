import Foundation

/// What the sticker says when a song finishes by itself. Always positive: more notes on the beat earn more stars.
struct Celebration: Equatable {
    let stars: Int
    let headline: String
    let notes: Int
    let onBeat: Int

    static let headlines: [Int: [String]] = [
        3: ["Perfect Rhythm!", "Maestro!", "Superstar!"],
        2: ["Groovy!", "Congratulations!", "Great Jam!"],
        1: ["You did it!", "Nice Jam!", "Song Complete!"],
    ]

    static func stars(onBeat: Int, total: Int) -> Int {
        guard total > 0 else { return 1 }
        let score = Double(onBeat) / Double(total)
        return score >= 0.9 ? 3 : score >= 0.6 ? 2 : 1
    }

    static func make(onBeat: Int, total: Int, pick: ([String]) -> String = { $0.randomElement()! }) -> Celebration {
        let s = stars(onBeat: onBeat, total: total)
        return Celebration(stars: s, headline: pick(headlines[s]!), notes: total, onBeat: onBeat)
    }
}
