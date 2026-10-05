import Foundation

/// One picture the player can put behind the course. `tint` is how much black goes over it so the pads stay readable.
struct BackgroundOption: Identifiable, Equatable {
    let id: String
    let name: String
    let image: URL
    let thumb: URL
    let tint: Double
}

/// The backgrounds bundled with this build: drawn by tools/make_backgrounds.swift, then sized by tools/prepare_backgrounds.swift into the
/// MarbleJamBackgrounds folder, with a manifest.json listing them. No folder or no manifest: no backgrounds.
enum BackgroundLibrary {
    static let folderName = "MarbleJamBackgrounds"

    private struct Entry: Decodable { let id, image, thumb: String; let name: String?; let luminance: Double }

    static func parse(_ data: Data, base: URL) -> [BackgroundOption] {
        guard let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return [] }
        return entries.map {
            BackgroundOption(id: $0.id, name: $0.name ?? $0.id, image: base.appendingPathComponent($0.image), thumb: base.appendingPathComponent($0.thumb),
                             tint: tint(forLuminance: $0.luminance))
        }
    }

    /// Brighter pictures need more black on top for the glowing pads and the white marble to stand out.
    static func tint(forLuminance l: Double) -> Double { max(0.3, min(0.72, 0.3 + 0.45 * l)) }

    static func load(from folder: URL) -> [BackgroundOption] {
        guard let data = try? Data(contentsOf: folder.appendingPathComponent("manifest.json")) else { return [] }
        return parse(data, base: folder)
    }

    static let bundled: [BackgroundOption] = {
        guard let folder = Bundle.main.url(forResource: folderName, withExtension: nil) else { return [] }
        return load(from: folder)
    }()
}
