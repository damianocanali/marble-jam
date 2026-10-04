// Draws the Marble Jam logo (1024x1024, opaque PNG) into art/MarbleJam.png.
// Everything is drawn here or comes from the open-licensed fonts in art/fonts, so the logo is ours to use.
// Run from the repo root: swift tools/make_logo.swift   (then tools/icon_from_art.swift to update the app icon and menu logo)
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024.0
let out = "art/MarbleJam.png"
srand48(7)                                                              // same marbles every run

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor { CGColor(srgbRed: r, green: g, blue: b, alpha: a) }
func hsb(_ h: Double, _ s: Double, _ v: Double, _ a: Double = 1) -> CGColor {
    let i = Int(h * 6) % 6, f = h * 6 - floor(h * 6), p = v * (1 - s), q = v * (1 - f * s), t = v * (1 - (1 - f) * s)
    let (r, g, b) = [(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)][i]
    return rgb(r, g, b, a)
}
func font(_ file: String, _ pt: Double) -> CTFont {
    let descs = CTFontManagerCreateFontDescriptorsFromURL(URL(fileURLWithPath: "art/fonts/" + file) as CFURL) as! [CTFontDescriptor]
    return CTFontCreateWithFontDescriptor(descs[0], pt, nil)
}

/// The outline of a string as one path, centred on the origin (y up).
func textPath(_ s: String, _ f: CTFont, tracking: Double = 0) -> CGPath {
    let attr = NSAttributedString(string: s, attributes: [kCTFontAttributeName as NSAttributedString.Key: f,
                                                          kCTKernAttributeName as NSAttributedString.Key: tracking])
    let line = CTLineCreateWithAttributedString(attr), path = CGMutablePath()
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let n = CTRunGetGlyphCount(run)
        var glyphs = [CGGlyph](repeating: 0, count: n), pos = [CGPoint](repeating: .zero, count: n)
        CTRunGetGlyphs(run, CFRange(location: 0, length: n), &glyphs); CTRunGetPositions(run, CFRange(location: 0, length: n), &pos)
        let rf = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName] as! CTFont
        for i in 0..<n { if let g = CTFontCreatePathForGlyph(rf, glyphs[i], nil) { path.addPath(g, transform: CGAffineTransform(translationX: pos[i].x, y: pos[i].y)) } }
    }
    let b = path.boundingBoxOfPath
    var t = CGAffineTransform(translationX: -b.midX, y: -b.midY)
    return path.copy(using: &t)!
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!          // opaque: App Store icons have no alpha
ctx.setLineCap(.round); ctx.setLineJoin(.round)

// MARK: background — white paper with light music doodles

ctx.setFillColor(rgb(1, 1, 1)); ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
let music = font("NotoMusic-Regular.ttf", 120)
ctx.setStrokeColor(rgb(0.15, 0.15, 0.2, 0.55)); ctx.setLineWidth(3)
for (i, staffY) in [940.0, 120.0].enumerated() {                                     // two wavy staffs
    for k in 0..<5 {
        let y = staffY + Double(k) * 14
        ctx.move(to: CGPoint(x: -20, y: y))
        ctx.addCurve(to: CGPoint(x: size + 20, y: y + (i == 0 ? -40 : 40)),
                     control1: CGPoint(x: 330, y: y + (i == 0 ? 60 : -50)), control2: CGPoint(x: 700, y: y + (i == 0 ? -90 : 80)))
    }
    ctx.strokePath()
}
for (glyph, x, y, s, a) in [("♪", 90.0, 830.0, 1.0, -0.2), ("♫", 900, 760, 1.1, 0.15), ("♩", 70, 300, 0.9, 0.1), ("♬", 920, 300, 1.0, -0.1),
                            ("♪", 560, 975, 0.7, 0.3), ("♫", 300, 60, 0.75, -0.2), ("♩", 960, 520, 0.7, 0.2), ("♪", 40, 560, 0.7, -0.3)] {
    ctx.saveGState(); ctx.translateBy(x: x, y: y); ctx.rotate(by: a); ctx.scaleBy(x: s, y: s)
    ctx.addPath(textPath(glyph, music)); ctx.setStrokeColor(rgb(0.15, 0.15, 0.2, 0.55)); ctx.setLineWidth(3 / s); ctx.strokePath()
    ctx.restoreGState()
}

// MARK: marbles — glossy glass with a coloured swirl inside

func marble(_ cx: Double, _ cy: Double, _ r: Double, hue: Double, sat: Double = 0.85, swirl: Double? = nil) {
    let c = CGPoint(x: cx, y: cy), circle = CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)
    ctx.saveGState()                                                                 // contact shadow
    ctx.setShadow(offset: CGSize(width: r * 0.08, height: -r * 0.12), blur: r * 0.35, color: rgb(0, 0, 0, 0.35))
    ctx.setFillColor(hsb(hue, sat, 0.45)); ctx.fillEllipse(in: circle)
    ctx.restoreGState()

    ctx.saveGState(); ctx.addEllipse(in: circle); ctx.clip()
    let body = CGGradient(colorsSpace: space, colors: [hsb(hue, sat * 0.55, 1), hsb(hue, sat, 0.88), hsb(hue, sat, 0.42)] as CFArray,
                          locations: [0, 0.5, 1])!
    ctx.drawRadialGradient(body, startCenter: CGPoint(x: cx - r * 0.3, y: cy + r * 0.35), startRadius: 0,
                           endCenter: c, endRadius: r * 1.05, options: [.drawsAfterEndLocation])
    let sh = swirl ?? drand48() * .pi * 2                                            // the twisted ribbon inside the glass
    ctx.saveGState(); ctx.translateBy(x: cx, y: cy); ctx.rotate(by: sh)
    for k in 0..<4 {                                                                 // thin, blurred ribbons, like a cat's-eye marble
        let off = (Double(k) - 1.5) * r * 0.16
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: r * 0.12, color: k % 2 == 0 ? hsb(hue, sat, 0.25, 0.6) : rgb(1, 1, 1, 0.6))
        ctx.move(to: CGPoint(x: -r * 0.85, y: off - r * 0.1))
        ctx.addCurve(to: CGPoint(x: r * 0.85, y: off + r * 0.1), control1: CGPoint(x: -r * 0.25, y: off + r * 0.55), control2: CGPoint(x: r * 0.25, y: off - r * 0.55))
        ctx.setLineWidth(r * (k % 2 == 0 ? 0.07 : 0.045))
        ctx.setStrokeColor(k % 2 == 0 ? hsb(fmod(hue + 0.04, 1), sat, 0.3, 0.45) : rgb(1, 1, 1, 0.35))
        ctx.strokePath(); ctx.restoreGState()
    }
    ctx.restoreGState()
    let caustic = CGGradient(colorsSpace: space, colors: [hsb(hue, sat * 0.4, 1, 0.75), hsb(hue, sat, 1, 0)] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(caustic, startCenter: CGPoint(x: cx + r * 0.35, y: cy - r * 0.5), startRadius: 0,
                           endCenter: CGPoint(x: cx + r * 0.35, y: cy - r * 0.5), endRadius: r * 0.55, options: [])
    let rim = CGGradient(colorsSpace: space, colors: [rgb(0, 0, 0, 0), rgb(0, 0, 0, 0.4)] as CFArray, locations: [0.72, 1])!
    ctx.drawRadialGradient(rim, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: [])
    ctx.restoreGState()

    let hl = CGGradient(colorsSpace: space, colors: [rgb(1, 1, 1, 0.95), rgb(1, 1, 1, 0)] as CFArray, locations: [0, 1])!   // shine
    let hc = CGPoint(x: cx - r * 0.38, y: cy + r * 0.42)
    ctx.saveGState(); ctx.translateBy(x: hc.x, y: hc.y); ctx.rotate(by: 0.6); ctx.scaleBy(x: 1, y: 0.62)
    ctx.drawRadialGradient(hl, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: r * 0.42, options: [])
    ctx.restoreGState()
    ctx.setFillColor(rgb(1, 1, 1, 0.95))
    ctx.fillEllipse(in: CGRect(x: cx + r * 0.2, y: cy + r * 0.28, width: r * 0.16, height: r * 0.16))
}

// back row (behind the title), then the pile at the bottom
for (x, y, r, h) in [(370.0, 935.0, 92.0, 0.58), (560, 905, 120, 0.33), (775, 900, 105, 0.6), (650, 1010, 75, 0.0),
                     (175, 650, 60, 0.07), (300, 600, 70, 0.95)] { marble(x, y, r, hue: h) }
for (x, y, r, h, s) in [(470.0, 420.0, 105.0, 0.0, 0.85), (640, 410, 95, 0.07, 0.9), (380, 280, 70, 0.0, 0.0), (760, 320, 120, 0.58, 0.8),
                        (560, 250, 130, 0.14, 0.9), (330, 140, 95, 0.55, 0.8), (800, 150, 150, 0.98, 0.85), (560, 60, 120, 0.64, 0.95),
                        (330, -10, 90, 0.02, 0.85)] {
    marble(x, y, r, hue: h, sat: max(s, 0.05))
}

// MARK: treble clef with motion lines

ctx.setStrokeColor(rgb(0, 0, 0)); ctx.setLineWidth(11)
for k in 0..<5 {                                                                     // speed lines sweeping out of the clef
    let y = 330.0 + Double(k) * 38
    ctx.move(to: CGPoint(x: 10, y: y + 90 - Double(k) * 10))
    ctx.addCurve(to: CGPoint(x: 680 - Double(k) * 40, y: y + 60 + Double(k) * 18),
                 control1: CGPoint(x: 230, y: y + 20), control2: CGPoint(x: 470, y: y - 30))
}
ctx.strokePath()
ctx.saveGState(); ctx.translateBy(x: 290, y: 400); ctx.rotate(by: -0.12)
let clef = textPath("𝄞", font("NotoMusic-Regular.ttf", 420))
ctx.addPath(clef); ctx.setStrokeColor(rgb(1, 1, 1)); ctx.setLineWidth(22); ctx.strokePath()   // white halo so it reads over the marbles
ctx.addPath(clef); ctx.setFillColor(rgb(0, 0, 0)); ctx.fillPath()
ctx.restoreGState()
for (glyph, x, y, s, a) in [("♫", 560.0, 370.0, 1.6, -0.25), ("♪", 690, 310, 1.3, 0.1)] {
    ctx.saveGState(); ctx.translateBy(x: x, y: y); ctx.rotate(by: a); ctx.scaleBy(x: s, y: s)
    let p = textPath(glyph, music)
    ctx.addPath(p); ctx.setStrokeColor(rgb(1, 1, 1)); ctx.setLineWidth(14 / s); ctx.strokePath()
    ctx.addPath(p); ctx.setFillColor(rgb(0, 0, 0)); ctx.fillPath()
    ctx.restoreGState()
}

// MARK: title — chunky white letters, thick black outline, grey block shadow

func title(_ s: String, at p: CGPoint, angle: Double, pt: Double) {
    let path = textPath(s, font("LuckiestGuy-Regular.ttf", pt), tracking: -2)
    ctx.saveGState(); ctx.translateBy(x: p.x, y: p.y); ctx.rotate(by: angle)
    for k in stride(from: 34.0, through: 4, by: -2) {                                // extruded grey shadow, down and right
        ctx.saveGState(); ctx.translateBy(x: k * 0.9, y: -k)
        ctx.addPath(path); ctx.setStrokeColor(rgb(0.72, 0.72, 0.74, 0.9)); ctx.setLineWidth(40); ctx.strokePath()
        ctx.restoreGState()
    }
    ctx.addPath(path); ctx.setStrokeColor(rgb(0, 0, 0)); ctx.setLineWidth(40); ctx.strokePath()
    ctx.addPath(path); ctx.setFillColor(rgb(1, 1, 1)); ctx.fillPath()
    ctx.restoreGState()
}
title("MARBLE", at: CGPoint(x: 500, y: 690), angle: 0.04, pt: 250)
title("JAM", at: CGPoint(x: 770, y: 505), angle: -0.2, pt: 230)

let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out)")
