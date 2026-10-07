import UIKit

/// Holiday app icons. Each is an "AppIcon-<season>" set in Assets.xcassets, listed in ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES.
/// The app switches to the live holiday's icon when it has one, and back to the main icon afterwards.
enum AppIcons {
    /// The icon for this holiday, or nil for the main icon (no holiday, or no icon bundled for it).
    static func name(for season: String?, available: Set<String>) -> String? {
        guard let season, available.contains("AppIcon-\(season)") else { return nil }
        return "AppIcon-\(season)"
    }

    /// Alternate icons bundled with this build (from the Info.plist).
    static let available: Set<String> = {
        let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any]
        let alternates = icons?["CFBundleAlternateIcons"] as? [String: Any]
        return Set(alternates.map { Array($0.keys) } ?? [])
    }()

    /// Switches only when the icon should change, so iOS's "You have changed the icon" notice appears just at a holiday's start and end.
    @MainActor static func update(for season: String?) {
        let app = UIApplication.shared
        guard app.supportsAlternateIcons else { return }
        let wanted = name(for: season, available: available)
        if app.alternateIconName != wanted { app.setAlternateIconName(wanted) }
    }
}
