import Foundation

/// When to ask for an App Store rating: after a happy moment (a 3-star sticker), never the very first one, at most once per
/// app version, and only when the player closes the sticker (never on the way to the next level). iOS also limits the
/// prompt to a few times a year and may not show it at all.
struct ReviewPrompt {
    let defaults: UserDefaults
    static let shared = ReviewPrompt(defaults: .standard)
    private let winsKey = "review.wins", askedKey = "review.askedVersion"

    static var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0" }

    /// Counts a finished song or level; only 3 stars count.
    func recordWin(stars: Int) {
        if stars == 3 { defaults.set(defaults.integer(forKey: winsKey) + 1, forKey: winsKey) }
    }

    /// Whether to ask now (after the second 3-star moment, once per version). Asking marks this version as asked.
    func askNow(version: String) -> Bool {
        guard defaults.integer(forKey: winsKey) >= 2, defaults.string(forKey: askedKey) != version else { return false }
        defaults.set(version, forKey: askedKey)
        return true
    }
}
