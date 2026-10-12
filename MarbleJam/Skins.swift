import UIKit

/// A marble's look. Every skin is drawn in code (no stock art), so it can be sold or given as a reward.
struct Skin: Identifiable {
    enum Unlock: Equatable {
        case free
        case stars(Int)              // total challenge stars
        case holiday(String)         // every level of that holiday's world has a star
        case pack(String)            // bought in the store
    }

    let id: String
    let name: String
    let unlock: Unlock
    let draw: (CGContext, CGFloat) -> Void      // draws the marble filling a square of this side, centred
}

struct SkinPack: Identifiable {
    let id: String
    let name: String
    /// In-app purchase id; the same ids are in Products.storekit (local testing) and must be created in App Store Connect.
    var productID: String { "\(Store.productPrefix).pack.\(id)" }
}

enum Skins {
    static let classic = Skin(id: "classic", name: "Classic", unlock: .free) { c, s in glass(c, s, inner: (1, 1, 1), outer: (0.62, 0.78, 1)) }

    static let packs = [SkinPack(id: "glass", name: "Glass Pack"), SkinPack(id: "space", name: "Space Pack"),
                        SkinPack(id: "sports", name: "Sports Pack"), SkinPack(id: "candy", name: "Candy Pack"),
                        SkinPack(id: "gems", name: "Gem Pack"), SkinPack(id: "animals", name: "Animal Pack")]

    static let all: [Skin] = [
        classic,
        // rewards for challenge stars
        Skin(id: "mint", name: "Mint", unlock: .stars(5)) { c, s in glass(c, s, inner: (0.85, 1, 0.9), outer: (0.2, 0.7, 0.5)) },
        Skin(id: "sunny", name: "Sunny", unlock: .stars(10)) { c, s in glass(c, s, inner: (1, 0.97, 0.6), outer: (1, 0.72, 0.1)) },
        Skin(id: "ocean", name: "Ocean", unlock: .stars(25)) { c, s in glass(c, s, inner: (0.6, 0.95, 1), outer: (0.05, 0.35, 0.8)); swirl(c, s, (1, 1, 1), 0.5) },
        Skin(id: "sunset", name: "Sunset", unlock: .stars(35)) { c, s in sunset(c, s) },
        Skin(id: "ruby", name: "Ruby", unlock: .stars(45)) { c, s in glass(c, s, inner: (1, 0.55, 0.6), outer: (0.6, 0.02, 0.12)); sparkle(c, s) },
        Skin(id: "galaxy", name: "Galaxy", unlock: .stars(55)) { c, s in galaxy(c, s) },
        Skin(id: "rainbow", name: "Rainbow", unlock: .stars(70)) { c, s in rainbow(c, s) },
        Skin(id: "gold", name: "Gold Star", unlock: .stars(85)) { c, s in glass(c, s, inner: (1, 0.95, 0.65), outer: (0.7, 0.45, 0.02)); star(c, s) },
        // holiday rewards
        Skin(id: "pumpkin", name: "Jack-o'-lantern", unlock: .holiday("halloween")) { c, s in pumpkin(c, s) },
        Skin(id: "leaf", name: "Autumn Leaf", unlock: .holiday("thanksgiving")) { c, s in autumn(c, s) },
        Skin(id: "snowglobe", name: "Snow Globe", unlock: .holiday("christmas")) { c, s in snowGlobe(c, s) },
        // Glass Pack
        Skin(id: "catseye", name: "Cat's Eye", unlock: .pack("glass")) { c, s in glass(c, s, inner: (0.9, 0.97, 1), outer: (0.55, 0.75, 0.9)); catsEye(c, s) },
        Skin(id: "emerald", name: "Emerald Swirl", unlock: .pack("glass")) { c, s in glass(c, s, inner: (0.6, 1, 0.75), outer: (0, 0.45, 0.2)); swirl(c, s, (0.85, 1, 0.9), 0.7) },
        Skin(id: "amber", name: "Amber Swirl", unlock: .pack("glass")) { c, s in glass(c, s, inner: (1, 0.85, 0.5), outer: (0.65, 0.3, 0)); swirl(c, s, (1, 0.95, 0.8), 0.7) },
        Skin(id: "bubble", name: "Bubble", unlock: .pack("glass")) { c, s in bubble(c, s) },
        // Space Pack
        Skin(id: "earth", name: "Earth", unlock: .pack("space")) { c, s in earth(c, s) },
        Skin(id: "saturn", name: "Saturn", unlock: .pack("space")) { c, s in saturn(c, s) },
        Skin(id: "moon", name: "Moon", unlock: .pack("space")) { c, s in moon(c, s) },
        Skin(id: "sun", name: "Sun", unlock: .pack("space")) { c, s in sun(c, s) },
        // Sports Pack
        Skin(id: "soccer", name: "Soccer", unlock: .pack("sports")) { c, s in soccer(c, s) },
        Skin(id: "basketball", name: "Basketball", unlock: .pack("sports")) { c, s in basketball(c, s) },
        Skin(id: "tennis", name: "Tennis", unlock: .pack("sports")) { c, s in tennis(c, s) },
        Skin(id: "eightball", name: "8-Ball", unlock: .pack("sports")) { c, s in eightBall(c, s) },
        // Candy Pack
        Skin(id: "lollipop", name: "Lollipop", unlock: .pack("candy")) { c, s in lollipop(c, s) },
        Skin(id: "gumball", name: "Gumball", unlock: .pack("candy")) { c, s in glass(c, s, inner: (1, 0.75, 0.88), outer: (0.92, 0.25, 0.55)); sparkle(c, s) },
        Skin(id: "peppermint", name: "Peppermint", unlock: .pack("candy")) { c, s in peppermint(c, s) },
        Skin(id: "sprinkles", name: "Sprinkles", unlock: .pack("candy")) { c, s in sprinkles(c, s) },
        // Gem Pack
        Skin(id: "diamond", name: "Diamond", unlock: .pack("gems")) { c, s in gem(c, s, light: (1, 1, 1), dark: (0.7, 0.85, 0.95)) },
        Skin(id: "sapphire", name: "Sapphire", unlock: .pack("gems")) { c, s in gem(c, s, light: (0.45, 0.6, 1), dark: (0.05, 0.12, 0.55)) },
        Skin(id: "amethyst", name: "Amethyst", unlock: .pack("gems")) { c, s in gem(c, s, light: (0.85, 0.6, 1), dark: (0.4, 0.1, 0.6)) },
        Skin(id: "opal", name: "Opal", unlock: .pack("gems")) { c, s in opal(c, s) },
        // Animal Pack
        Skin(id: "ladybug", name: "Ladybug", unlock: .pack("animals")) { c, s in ladybug(c, s) },
        Skin(id: "panda", name: "Panda", unlock: .pack("animals")) { c, s in panda(c, s) },
        Skin(id: "tiger", name: "Tiger", unlock: .pack("animals")) { c, s in tiger(c, s) },
        Skin(id: "frog", name: "Frog", unlock: .pack("animals")) { c, s in frog(c, s) },
    ]

    static func skin(_ id: String) -> Skin { all.first { $0.id == id } ?? classic }

    static func isOwned(_ s: Skin, stars: Int, holidaysDone: Set<String>, purchased: Set<String>) -> Bool {
        switch s.unlock {
        case .free: true
        case let .stars(n): stars >= n
        case let .holiday(id): holidaysDone.contains(id)
        case let .pack(id): purchased.contains(packs.first { $0.id == id }?.productID ?? "")
        }
    }

    /// The skin as a round image (transparent outside the circle), with a glassy shine on top.
    static func image(_ skin: Skin, size: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).image { r in
            let c = r.cgContext
            c.addEllipse(in: CGRect(x: 0, y: 0, width: size, height: size)); c.clip()
            skin.draw(c, size)
            let shine = CGGradient(colorsSpace: nil, colors: [UIColor(white: 1, alpha: 0.75).cgColor, UIColor(white: 1, alpha: 0).cgColor] as CFArray, locations: [0, 1])!
            c.drawRadialGradient(shine, startCenter: CGPoint(x: size * 0.33, y: size * 0.3), startRadius: 0,
                                 endCenter: CGPoint(x: size * 0.33, y: size * 0.3), endRadius: size * 0.28, options: [])
        }
    }

    // MARK: drawing helpers (size s, origin top-left, y down)

    typealias RGB = (CGFloat, CGFloat, CGFloat)
    private static func col(_ v: RGB, _ a: CGFloat = 1) -> CGColor { UIColor(red: v.0, green: v.1, blue: v.2, alpha: a).cgColor }

    private static func glass(_ c: CGContext, _ s: CGFloat, inner: RGB, outer: RGB) {
        let g = CGGradient(colorsSpace: nil, colors: [col(inner), col(outer)] as CFArray, locations: [0, 1])!
        c.drawRadialGradient(g, startCenter: CGPoint(x: s * 0.4, y: s * 0.38), startRadius: 0, endCenter: CGPoint(x: s / 2, y: s / 2), endRadius: s * 0.62,
                             options: [.drawsAfterEndLocation])
    }

    private static func swirl(_ c: CGContext, _ s: CGFloat, _ color: RGB, _ alpha: CGFloat) {
        c.setStrokeColor(col(color, alpha)); c.setLineWidth(s * 0.09); c.setLineCap(.round)
        for k in 0..<3 {
            let a = CGFloat(k) * 2.1
            c.saveGState(); c.translateBy(x: s / 2, y: s / 2); c.rotate(by: a)
            c.move(to: CGPoint(x: -s * 0.45, y: 0)); c.addCurve(to: CGPoint(x: s * 0.45, y: 0), control1: CGPoint(x: -s * 0.1, y: s * 0.35), control2: CGPoint(x: s * 0.1, y: -s * 0.35))
            c.strokePath(); c.restoreGState()
        }
    }

    private static func sparkle(_ c: CGContext, _ s: CGFloat) {
        c.setFillColor(UIColor(white: 1, alpha: 0.9).cgColor)
        for (x, y, r) in [(0.65, 0.6, 0.05), (0.4, 0.72, 0.035), (0.7, 0.35, 0.03)] as [(CGFloat, CGFloat, CGFloat)] {
            c.fillEllipse(in: CGRect(x: s * (x - r), y: s * (y - r), width: s * 2 * r, height: s * 2 * r))
        }
    }

    private static func rainbow(_ c: CGContext, _ s: CGFloat) {
        let hues: [CGFloat] = [0, 0.08, 0.15, 0.33, 0.55, 0.72, 0.85]
        for (i, h) in hues.enumerated() {
            c.setFillColor(UIColor(hue: h, saturation: 0.75, brightness: 1, alpha: 1).cgColor)
            c.fill(CGRect(x: 0, y: s * CGFloat(i) / CGFloat(hues.count), width: s, height: s / CGFloat(hues.count) + 1))
        }
    }

    private static func pumpkin(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (1, 0.7, 0.25), outer: (0.85, 0.35, 0))
        c.setStrokeColor(col((0.6, 0.25, 0), 0.6)); c.setLineWidth(s * 0.04)
        for x in [0.3, 0.5, 0.7] as [CGFloat] { c.move(to: CGPoint(x: s * x, y: 0)); c.addQuadCurve(to: CGPoint(x: s * x, y: s), control: CGPoint(x: s * (x + (x - 0.5) * 0.8), y: s / 2)) }
        c.strokePath()
        c.setFillColor(col((0.2, 0.08, 0)))
        for x in [0.33, 0.67] as [CGFloat] {                      // triangle eyes
            c.move(to: CGPoint(x: s * (x - 0.09), y: s * 0.46)); c.addLine(to: CGPoint(x: s * (x + 0.09), y: s * 0.46)); c.addLine(to: CGPoint(x: s * x, y: s * 0.32)); c.fillPath()
        }
        c.move(to: CGPoint(x: s * 0.28, y: s * 0.6))
        for k in 0...6 { c.addLine(to: CGPoint(x: s * (0.28 + 0.44 * CGFloat(k) / 6), y: s * (k % 2 == 0 ? 0.6 : 0.68))) }
        c.addQuadCurve(to: CGPoint(x: s * 0.28, y: s * 0.6), control: CGPoint(x: s * 0.5, y: s * 0.85)); c.fillPath()
    }

    private static func autumn(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (1, 0.8, 0.4), outer: (0.6, 0.25, 0.05))
        c.saveGState(); c.translateBy(x: s / 2, y: s / 2); c.rotate(by: 0.5)
        c.move(to: CGPoint(x: 0, y: -s * 0.36))
        c.addQuadCurve(to: CGPoint(x: 0, y: s * 0.3), control: CGPoint(x: s * 0.36, y: -s * 0.02))
        c.addQuadCurve(to: CGPoint(x: 0, y: -s * 0.36), control: CGPoint(x: -s * 0.36, y: -s * 0.02))
        c.setFillColor(col((0.85, 0.2, 0.08))); c.fillPath()
        c.setStrokeColor(col((0.45, 0.1, 0.02))); c.setLineWidth(s * 0.03)
        c.move(to: CGPoint(x: 0, y: s * 0.38)); c.addLine(to: CGPoint(x: 0, y: -s * 0.3)); c.strokePath()
        c.restoreGState()
    }

    private static func snowGlobe(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (0.8, 0.92, 1), outer: (0.25, 0.45, 0.85))
        c.setFillColor(col((1, 1, 1))); c.fill(CGRect(x: 0, y: s * 0.72, width: s, height: s * 0.28))
        c.move(to: CGPoint(x: s * 0.5, y: s * 0.22)); c.addLine(to: CGPoint(x: s * 0.7, y: s * 0.72)); c.addLine(to: CGPoint(x: s * 0.3, y: s * 0.72))
        c.setFillColor(col((0.1, 0.5, 0.25))); c.fillPath()
        c.setFillColor(UIColor(white: 1, alpha: 0.95).cgColor)
        for (x, y) in [(0.2, 0.3), (0.8, 0.25), (0.25, 0.55), (0.75, 0.5), (0.55, 0.15)] as [(CGFloat, CGFloat)] {
            c.fillEllipse(in: CGRect(x: s * x - s * 0.03, y: s * y - s * 0.03, width: s * 0.06, height: s * 0.06))
        }
    }

    private static func catsEye(_ c: CGContext, _ s: CGFloat) {
        c.saveGState(); c.translateBy(x: s / 2, y: s / 2)
        for (k, color) in [(0.0, (0.1, 0.4, 0.95)), (1.05, (1.0, 0.75, 0.1)), (2.1, (0.15, 0.7, 0.3))] as [(CGFloat, RGB)] {
            c.saveGState(); c.rotate(by: k)
            c.move(to: CGPoint(x: -s * 0.45, y: 0)); c.addQuadCurve(to: CGPoint(x: s * 0.45, y: 0), control: CGPoint(x: 0, y: -s * 0.12))
            c.addQuadCurve(to: CGPoint(x: -s * 0.45, y: 0), control: CGPoint(x: 0, y: s * 0.12))
            c.setFillColor(col(color)); c.fillPath(); c.restoreGState()
        }
        c.restoreGState()
    }

    private static func bubble(_ c: CGContext, _ s: CGFloat) {
        let g = CGGradient(colorsSpace: nil, colors: [col((0.95, 0.98, 1), 0.3), col((0.7, 0.85, 1), 0.5), col((1, 0.7, 0.95), 0.9)] as CFArray, locations: [0, 0.7, 1])!
        c.drawRadialGradient(g, startCenter: CGPoint(x: s / 2, y: s / 2), startRadius: 0, endCenter: CGPoint(x: s / 2, y: s / 2), endRadius: s / 2, options: [])
    }

    private static func earth(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (0.35, 0.65, 1), outer: (0.05, 0.2, 0.6))
        c.setFillColor(col((0.2, 0.65, 0.3)))
        c.fillEllipse(in: CGRect(x: s * 0.15, y: s * 0.2, width: s * 0.35, height: s * 0.28))
        c.fillEllipse(in: CGRect(x: s * 0.45, y: s * 0.5, width: s * 0.38, height: s * 0.3))
        c.fillEllipse(in: CGRect(x: s * 0.3, y: s * 0.62, width: s * 0.2, height: s * 0.15))
        c.setFillColor(UIColor(white: 1, alpha: 0.7).cgColor); c.fill(CGRect(x: 0, y: 0, width: s, height: s * 0.08))
    }

    private static func saturn(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (1, 0.9, 0.65), outer: (0.75, 0.55, 0.25))
        c.setStrokeColor(col((0.55, 0.4, 0.2), 0.5)); c.setLineWidth(s * 0.05)
        for y in [0.3, 0.42, 0.7] as [CGFloat] { c.move(to: CGPoint(x: 0, y: s * y)); c.addLine(to: CGPoint(x: s, y: s * y)) }
        c.strokePath()
        c.saveGState(); c.translateBy(x: s / 2, y: s / 2); c.rotate(by: -0.35)
        c.setStrokeColor(col((0.95, 0.85, 0.6))); c.setLineWidth(s * 0.07)
        c.strokeEllipse(in: CGRect(x: -s * 0.62, y: -s * 0.14, width: s * 1.24, height: s * 0.28)); c.restoreGState()
    }

    private static func moon(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (0.95, 0.95, 0.92), outer: (0.55, 0.55, 0.6))
        c.setFillColor(col((0.6, 0.6, 0.62), 0.7))
        for (x, y, r) in [(0.3, 0.35, 0.1), (0.62, 0.3, 0.07), (0.55, 0.65, 0.12), (0.28, 0.68, 0.06)] as [(CGFloat, CGFloat, CGFloat)] {
            c.fillEllipse(in: CGRect(x: s * (x - r), y: s * (y - r), width: s * 2 * r, height: s * 2 * r))
        }
    }

    private static func sun(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (1, 1, 0.75), outer: (1, 0.45, 0))
        c.setStrokeColor(col((1, 0.95, 0.5), 0.7)); c.setLineWidth(s * 0.04)
        for k in 0..<8 {
            let a = CGFloat(k) * .pi / 4
            c.move(to: CGPoint(x: s / 2 + cos(a) * s * 0.18, y: s / 2 + sin(a) * s * 0.18)); c.addLine(to: CGPoint(x: s / 2 + cos(a) * s * 0.42, y: s / 2 + sin(a) * s * 0.42))
        }
        c.strokePath()
    }

    private static func soccer(_ c: CGContext, _ s: CGFloat) {
        c.setFillColor(UIColor.white.cgColor); c.fill(CGRect(x: 0, y: 0, width: s, height: s))
        c.setFillColor(UIColor(white: 0.1, alpha: 1).cgColor)
        func pent(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
            for k in 0..<5 {
                let a = CGFloat(k) * 2 * .pi / 5 - .pi / 2, p = CGPoint(x: s * x + cos(a) * s * r, y: s * y + sin(a) * s * r)
                k == 0 ? c.move(to: p) : c.addLine(to: p)
            }
            c.closePath(); c.fillPath()
        }
        pent(0.5, 0.5, 0.15); pent(0.12, 0.3, 0.12); pent(0.88, 0.3, 0.12); pent(0.25, 0.9, 0.12); pent(0.75, 0.9, 0.12)
    }

    private static func basketball(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (1, 0.6, 0.25), outer: (0.8, 0.35, 0.05))
        c.setStrokeColor(col((0.15, 0.07, 0))); c.setLineWidth(s * 0.04)
        c.move(to: CGPoint(x: 0, y: s / 2)); c.addLine(to: CGPoint(x: s, y: s / 2))
        c.move(to: CGPoint(x: s / 2, y: 0)); c.addLine(to: CGPoint(x: s / 2, y: s))
        c.strokePath()
        c.strokeEllipse(in: CGRect(x: -s * 0.55, y: s * 0.1, width: s * 0.8, height: s * 0.8))
        c.strokeEllipse(in: CGRect(x: s * 0.75, y: s * 0.1, width: s * 0.8, height: s * 0.8))
    }

    private static func tennis(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (0.95, 1, 0.5), outer: (0.7, 0.85, 0.1))
        c.setStrokeColor(UIColor(white: 1, alpha: 0.95).cgColor); c.setLineWidth(s * 0.05)
        c.strokeEllipse(in: CGRect(x: -s * 0.6, y: s * 0.05, width: s * 0.9, height: s * 0.9))
        c.strokeEllipse(in: CGRect(x: s * 0.7, y: s * 0.05, width: s * 0.9, height: s * 0.9))
    }

    private static func eightBall(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (0.3, 0.3, 0.35), outer: (0.02, 0.02, 0.03))
        c.setFillColor(UIColor.white.cgColor); c.fillEllipse(in: CGRect(x: s * 0.3, y: s * 0.3, width: s * 0.4, height: s * 0.4))
        let text = NSAttributedString(string: "8", attributes: [.font: UIFont.systemFont(ofSize: s * 0.3, weight: .black), .foregroundColor: UIColor.black])
        let size = text.size()
        UIGraphicsPushContext(c); text.draw(at: CGPoint(x: (s - size.width) / 2, y: (s - size.height) / 2)); UIGraphicsPopContext()
    }

    private static func dot(_ c: CGContext, _ s: CGFloat, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        c.fillEllipse(in: CGRect(x: s * (x - r), y: s * (y - r), width: s * 2 * r, height: s * 2 * r))
    }

    private static func sunset(_ c: CGContext, _ s: CGFloat) {
        let g = CGGradient(colorsSpace: nil, colors: [col((0.45, 0.2, 0.6)), col((1, 0.4, 0.35)), col((1, 0.8, 0.3))] as CFArray, locations: [0, 0.55, 1])!
        c.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: s), options: [])
        c.setFillColor(col((1, 0.95, 0.6), 0.9)); dot(c, s, 0.5, 0.72, 0.16)
    }

    private static func galaxy(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (0.45, 0.25, 0.75), outer: (0.03, 0.02, 0.15))
        swirl(c, s, (0.85, 0.6, 1), 0.35)
        c.setFillColor(UIColor(white: 1, alpha: 0.95).cgColor)
        for (x, y, r) in [(0.25, 0.3, 0.02), (0.7, 0.22, 0.025), (0.6, 0.62, 0.02), (0.32, 0.72, 0.03), (0.8, 0.55, 0.015), (0.48, 0.42, 0.02)] as [(CGFloat, CGFloat, CGFloat)] {
            dot(c, s, x, y, r)
        }
    }

    private static func star(_ c: CGContext, _ s: CGFloat) {
        for k in 0..<10 {
            let a = CGFloat(k) * .pi / 5 - .pi / 2, r = s * (k % 2 == 0 ? 0.3 : 0.13)
            let p = CGPoint(x: s / 2 + cos(a) * r, y: s / 2 + sin(a) * r)
            k == 0 ? c.move(to: p) : c.addLine(to: p)
        }
        c.closePath(); c.setFillColor(col((1, 0.98, 0.8))); c.fillPath()
    }

    private static func lollipop(_ c: CGContext, _ s: CGFloat) {
        c.setFillColor(col((1, 0.98, 0.95))); c.fill(CGRect(x: 0, y: 0, width: s, height: s))
        c.setStrokeColor(col((0.95, 0.25, 0.5))); c.setLineWidth(s * 0.08); c.setLineCap(.round)
        c.move(to: CGPoint(x: s / 2, y: s / 2))
        for k in 1...60 {                                                    // a spiral out from the middle
            let t = CGFloat(k) / 60, a = t * 4 * .pi, r = t * s * 0.5
            c.addLine(to: CGPoint(x: s / 2 + cos(a) * r, y: s / 2 + sin(a) * r))
        }
        c.strokePath()
    }

    private static func peppermint(_ c: CGContext, _ s: CGFloat) {
        c.setFillColor(UIColor.white.cgColor); c.fill(CGRect(x: 0, y: 0, width: s, height: s))
        c.setFillColor(col((0.9, 0.1, 0.15)))
        for k in 0..<8 where k % 2 == 0 {
            let a = CGFloat(k) * .pi / 4
            c.move(to: CGPoint(x: s / 2, y: s / 2))
            c.addArc(center: CGPoint(x: s / 2, y: s / 2), radius: s * 0.75, startAngle: a, endAngle: a + .pi / 4, clockwise: false)
            c.closePath(); c.fillPath()
        }
    }

    private static func sprinkles(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (0.6, 0.4, 0.28), outer: (0.3, 0.16, 0.08))
        c.setLineWidth(s * 0.045); c.setLineCap(.round)
        let bits: [(CGFloat, CGFloat, CGFloat, RGB)] = [(0.25, 0.3, 0.4, (1, 0.3, 0.5)), (0.6, 0.25, -0.8, (0.3, 0.7, 1)), (0.45, 0.5, 1.2, (1, 0.9, 0.2)),
                                                        (0.75, 0.55, 0.2, (0.4, 0.9, 0.4)), (0.3, 0.7, -0.4, (1, 1, 1)), (0.6, 0.78, 0.9, (1, 0.5, 0.1)),
                                                        (0.18, 0.5, 1.5, (0.7, 0.4, 1)), (0.82, 0.35, 1.0, (1, 1, 1))]
        for (x, y, a, color) in bits {
            c.setStrokeColor(col(color))
            c.move(to: CGPoint(x: s * x - cos(a) * s * 0.05, y: s * y - sin(a) * s * 0.05))
            c.addLine(to: CGPoint(x: s * x + cos(a) * s * 0.05, y: s * y + sin(a) * s * 0.05)); c.strokePath()
        }
    }

    /// A cut stone: triangles around the middle, alternately light and dark, with a flat table on top.
    private static func gem(_ c: CGContext, _ s: CGFloat, light: RGB, dark: RGB) {
        let n = 10, mid = CGPoint(x: s / 2, y: s / 2)
        for k in 0..<n {
            let a0 = CGFloat(k) * 2 * .pi / CGFloat(n), a1 = a0 + 2 * .pi / CGFloat(n)
            c.move(to: mid)
            c.addLine(to: CGPoint(x: mid.x + cos(a0) * s, y: mid.y + sin(a0) * s)); c.addLine(to: CGPoint(x: mid.x + cos(a1) * s, y: mid.y + sin(a1) * s))
            c.closePath(); c.setFillColor(col(k % 2 == 0 ? light : dark)); c.fillPath()
        }
        for k in 0..<8 {
            let a = CGFloat(k) * .pi / 4 + .pi / 8, p = CGPoint(x: mid.x + cos(a) * s * 0.22, y: mid.y + sin(a) * s * 0.22)
            k == 0 ? c.move(to: p) : c.addLine(to: p)
        }
        c.closePath(); c.setFillColor(col(light, 0.85)); c.fillPath()
    }

    private static func opal(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (0.98, 0.97, 1), outer: (0.8, 0.85, 0.95))
        for (x, y, r, color) in [(0.3, 0.35, 0.16, (1, 0.6, 0.75)), (0.65, 0.3, 0.13, (0.55, 0.9, 1)), (0.55, 0.65, 0.17, (0.6, 1, 0.75)),
                                 (0.28, 0.7, 0.11, (1, 0.9, 0.5))] as [(CGFloat, CGFloat, CGFloat, RGB)] {
            c.setFillColor(col(color, 0.55)); dot(c, s, x, y, r)
        }
    }

    private static func ladybug(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (1, 0.35, 0.3), outer: (0.75, 0.05, 0.05))
        c.setFillColor(col((0.08, 0.05, 0.05)))
        c.fill(CGRect(x: 0, y: 0, width: s, height: s * 0.24))                // head
        c.fill(CGRect(x: s * 0.48, y: 0, width: s * 0.04, height: s))          // wing line
        for (x, y, r) in [(0.28, 0.42, 0.08), (0.72, 0.42, 0.08), (0.3, 0.7, 0.07), (0.7, 0.7, 0.07), (0.5, 0.86, 0.06)] as [(CGFloat, CGFloat, CGFloat)] {
            dot(c, s, x, y, r)
        }
        c.setFillColor(UIColor.white.cgColor); dot(c, s, 0.38, 0.13, 0.04); dot(c, s, 0.62, 0.13, 0.04)
    }

    private static func panda(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (1, 1, 1), outer: (0.85, 0.86, 0.9))
        c.setFillColor(col((0.1, 0.1, 0.12)))
        dot(c, s, 0.15, 0.12, 0.13); dot(c, s, 0.85, 0.12, 0.13)               // ears
        for x in [0.33, 0.67] as [CGFloat] {                                    // eye patches
            c.saveGState(); c.translateBy(x: s * x, y: s * 0.47); c.rotate(by: x < 0.5 ? 0.5 : -0.5)
            c.fillEllipse(in: CGRect(x: -s * 0.09, y: -s * 0.12, width: s * 0.18, height: s * 0.24)); c.restoreGState()
        }
        dot(c, s, 0.5, 0.66, 0.05)                                              // nose
        c.setFillColor(UIColor.white.cgColor); dot(c, s, 0.35, 0.45, 0.035); dot(c, s, 0.65, 0.45, 0.035)
    }

    private static func tiger(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (1, 0.75, 0.3), outer: (0.9, 0.42, 0.02))
        c.setFillColor(col((0.1, 0.05, 0.02)))
        for (y, fromLeft) in [(0.2, true), (0.35, false), (0.5, true), (0.65, false), (0.8, true)] as [(CGFloat, Bool)] {
            let x0: CGFloat = fromLeft ? 0 : s, dir: CGFloat = fromLeft ? 1 : -1
            c.move(to: CGPoint(x: x0, y: s * (y - 0.05)))
            c.addQuadCurve(to: CGPoint(x: x0 + dir * s * 0.55, y: s * y), control: CGPoint(x: x0 + dir * s * 0.3, y: s * (y - 0.06)))
            c.addQuadCurve(to: CGPoint(x: x0, y: s * (y + 0.05)), control: CGPoint(x: x0 + dir * s * 0.3, y: s * (y + 0.04)))
            c.fillPath()
        }
    }

    private static func frog(_ c: CGContext, _ s: CGFloat) {
        glass(c, s, inner: (0.65, 0.95, 0.4), outer: (0.15, 0.55, 0.1))
        c.setFillColor(UIColor.white.cgColor); dot(c, s, 0.3, 0.3, 0.13); dot(c, s, 0.7, 0.3, 0.13)
        c.setFillColor(col((0.05, 0.1, 0.05))); dot(c, s, 0.32, 0.31, 0.06); dot(c, s, 0.68, 0.31, 0.06)
        c.setStrokeColor(col((0.05, 0.3, 0.05))); c.setLineWidth(s * 0.04); c.setLineCap(.round)
        c.move(to: CGPoint(x: s * 0.3, y: s * 0.62)); c.addQuadCurve(to: CGPoint(x: s * 0.7, y: s * 0.62), control: CGPoint(x: s * 0.5, y: s * 0.78)); c.strokePath()
        c.setFillColor(col((1, 0.55, 0.6), 0.6)); dot(c, s, 0.22, 0.6, 0.05); dot(c, s, 0.78, 0.6, 0.05)
    }
}
