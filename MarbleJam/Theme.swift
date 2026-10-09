import SwiftUI
import UIKit

/// The app's colours. Holidays have their own; outside them it is the standard cyan-and-navy look. Pads keep their note colours.
struct Theme: Equatable {
    struct RGB: Hashable { let r, g, b: Double }

    let primary: RGB          // main buttons (Create, Drop, Play again)
    let primaryText: RGB      // text on them
    let chipFill: RGB         // other buttons and panels
    let chipStroke: RGB       // their outline
    let chipStrokeOpacity: Double
    let accent: RGB           // selection rings, the dial needle
    let marbleGlow: RGB       // the marble's outline and glow

    static func hex(_ v: UInt32) -> RGB { RGB(r: Double(v >> 16 & 255) / 255, g: Double(v >> 8 & 255) / 255, b: Double(v & 255) / 255) }

    static let standard = Theme(primary: hex(0x3FD7F5), primaryText: hex(0x050F1C), chipFill: hex(0x0E1226), chipStroke: hex(0xFFFFFF),
                                chipStrokeOpacity: 0.18, accent: hex(0x3FD7F5), marbleGlow: hex(0x9ED4FF))

    static func forSeason(_ id: String?) -> Theme {
        switch id {
        case "halloween":
            Theme(primary: hex(0xFF7A1A), primaryText: hex(0x1A0A00), chipFill: hex(0x2A0F45), chipStroke: hex(0xB070FF),
                  chipStrokeOpacity: 0.45, accent: hex(0xB070FF), marbleGlow: hex(0xFF9A3C))
        case "thanksgiving":
            Theme(primary: hex(0xF2A33A), primaryText: hex(0x2A1206), chipFill: hex(0x3A1E10), chipStroke: hex(0xE8B04A),
                  chipStrokeOpacity: 0.4, accent: hex(0xE8B04A), marbleGlow: hex(0xFFC27A))
        case "christmas":
            Theme(primary: hex(0xD63A3A), primaryText: hex(0xFFFFFF), chipFill: hex(0x0F3A26), chipStroke: hex(0xE8C45A),
                  chipStrokeOpacity: 0.5, accent: hex(0xE8C45A), marbleGlow: hex(0xFFE08A))
        default: .standard
        }
    }

    /// WCAG contrast ratio between two colours (1...21); 4.5 or more reads well.
    static func contrast(_ a: RGB, _ b: RGB) -> Double {
        func lin(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        func lum(_ c: RGB) -> Double { 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b) }
        let (x, y) = (lum(a), lum(b))
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }
}

extension Theme.RGB {
    var color: Color { Color(red: r, green: g, blue: b) }
    var uiColor: UIColor { UIColor(red: r, green: g, blue: b, alpha: 1) }
}

private struct SkinKey: EnvironmentKey { static let defaultValue = Skins.classic }
extension EnvironmentValues {
    /// The marble skin in use.
    var marbleSkin: Skin {
        get { self[SkinKey.self] }
        set { self[SkinKey.self] = newValue }
    }
}

private struct ThemeKey: EnvironmentKey { static let defaultValue = Theme.standard }
extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
