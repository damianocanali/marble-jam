import Foundation

/// One picture the player can put behind the course. `tint` is how much black goes over it so the pads stay readable.
struct BackgroundOption: Identifiable, Equatable {
    let id: String
    let name: String
    let image: URL
    let thumb: URL
    let tint: Double
    let season: String?                 // a holiday id, or nil for all year
}

/// The backgrounds bundled with this build: drawn by tools/make_backgrounds.swift, then sized by tools/prepare_backgrounds.swift into the
/// MarbleJamBackgrounds folder, with a manifest.json listing them. No folder or no manifest: no backgrounds.
enum BackgroundLibrary {
    static let folderName = "MarbleJamBackgrounds"
    /// Stored when the player picks the night sky on purpose. "" means they never chose (a live season may then show its own).
    static let nightID = "night"
    /// The artist's everyday background: shown off-season until the player picks something, and listed first.
    static let everydayID = "bg-40"

    private struct Entry: Decodable { let id, image, thumb: String; let name: String?; let luminance: Double; let season: String? }

    static func parse(_ data: Data, base: URL) -> [BackgroundOption] {
        guard let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return [] }
        return entries.map {
            BackgroundOption(id: $0.id, name: $0.name ?? $0.id, image: base.appendingPathComponent($0.image), thumb: base.appendingPathComponent($0.thumb),
                             tint: tint(forLuminance: $0.luminance), season: $0.season)
        }
    }

    /// Brighter pictures need more black on top for the glowing pads and the white marble to stand out.
    static func tint(forLuminance l: Double) -> Double { max(0.3, min(0.72, 0.3 + 0.45 * l)) }

    /// All-year backgrounds (the everyday one first), with the live season's before them. Other seasons' are hidden until their time comes.
    static func available(_ all: [BackgroundOption], season: String?) -> [BackgroundOption] {
        let year = all.filter { $0.season == nil }
        return all.filter { $0.season != nil && $0.season == season } + year.filter { $0.id == everydayID } + year.filter { $0.id != everydayID }
    }

    /// What to show: the player's choice if it is available now. With no choice — or a holiday pick that's out of season, or an
    /// id this build doesn't have — the live season's first background, or off-season the everyday one. The pick isn't
    /// forgotten: a Halloween pick shows again next Halloween. nil means the night sky (chosen on purpose, or nothing bundled).
    static func resolve(_ all: [BackgroundOption], chosenID: String, season: String?) -> BackgroundOption? {
        let now = available(all, season: season)
        if chosenID == nightID { return nil }
        if let chosen = now.first(where: { $0.id == chosenID }) { return chosen }
        return season == nil ? now.first { $0.id == everydayID } : now.first { $0.season == season }
    }

    /// The picker's tick: the background on screen, or the night sky tile when there is none.
    static func shownID(_ shown: BackgroundOption?) -> String { shown?.id ?? nightID }

    static func load(from folder: URL) -> [BackgroundOption] {
        guard let data = try? Data(contentsOf: folder.appendingPathComponent("manifest.json")) else { return [] }
        return parse(data, base: folder)
    }

    static let bundled: [BackgroundOption] = {
        guard let folder = Bundle.main.url(forResource: folderName, withExtension: nil) else { return [] }
        return load(from: folder)
    }()
}
