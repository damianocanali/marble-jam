import Foundation

/// What a song plays with. Chosen per song.
enum Instrument: String, Codable, CaseIterable, Identifiable {
    case bells, piano, guitar, marimba, drums, chip = "8-bit"

    var id: String { rawValue }
    var title: String {
        switch self {
        case .bells: "Bells"
        case .piano: "Piano"
        case .guitar: "Guitar"
        case .marimba: "Marimba"
        case .drums: "Drums"
        case .chip: "8-bit"
        }
    }
    /// SF Symbol for the picker and the song cards.
    var symbol: String {
        switch self {
        case .bells: "bell.fill"
        case .piano: "pianokeys"
        case .guitar: "guitars.fill"
        case .marimba: "music.note"
        case .drums: "metronome.fill"
        case .chip: "gamecontroller.fill"
        }
    }
}
