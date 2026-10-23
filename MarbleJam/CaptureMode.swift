#if DEBUG
import Foundation

/// DEBUG builds only (none of this is in the App Store build): launch arguments that open the app straight to a state,
/// so screenshots and screen recordings need no taps. For example, the demo playing off-season:
///     xcrun simctl launch booted com.marblejam.app -mbSong demo -mbAutoPlay 2 -mbSeason off
/// - `-mbScreen menu|library|play|challenges|store|account`: the screen to open on (play opens the demo song)
/// - `-mbSong demo`: the built-in Twinkle Twinkle in the builder (opens on play when no screen is given)
/// - `-mbAutoPlay <seconds>`: presses Drop that long after the builder opens
/// - `-mbSeason <holiday id|off>`: like the menu's Preview season, for this launch only
/// - `-mbSkin <skin id>`: the marble, owned or not
/// - `-mbBackground <background id|night>`: the background, if the season shown offers it
/// While any of them is given, the menu hides its Preview season button and the app icon is left alone (no icon alert).
struct CaptureMode: Equatable {
    var screen: RootView.Screen?
    var song: String?
    var autoPlay: Double?
    var season: String?
    var skin: String?
    var background: String?

    var isActive: Bool { self != CaptureMode() }

    static let current = parse(ProcessInfo.processInfo.arguments)

    /// Reads `-mbKey value` pairs; unknown keys, missing values and values that aren't allowed are ignored.
    static func parse(_ args: [String]) -> CaptureMode {
        var m = CaptureMode()
        var i = 0
        while i < args.count {
            guard args[i].hasPrefix("-mb"), i + 1 < args.count, !args[i + 1].hasPrefix("-mb") else { i += 1; continue }
            let value = args[i + 1]
            switch args[i] {
            case "-mbScreen": m.screen = RootView.Screen(rawValue: value)
            case "-mbSong": m.song = value == "demo" ? value : nil
            case "-mbAutoPlay": m.autoPlay = Double(value).flatMap { $0 >= 0 && $0.isFinite ? $0 : nil }
            case "-mbSeason": m.season = value == "off" || Seasons.all.contains { $0.id == value } ? value : nil
            case "-mbSkin": m.skin = Skins.all.contains { $0.id == value } ? value : nil
            case "-mbBackground": m.background = value.isEmpty ? nil : value
            default: break
            }
            i += 2
        }
        if m.song != nil && m.screen == nil { m.screen = .play }
        return m
    }
}
#endif
