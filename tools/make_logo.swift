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

// MARK: background — white paper with outlined instruments and music doodles

ctx.setFillColor(rgb(1, 1, 1)); ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
let music = font("NotoMusic-Regular.ttf", 120)
let ink = rgb(0.12, 0.12, 0.16, 0.8)

/// Draws `shape` (built around the origin) at a place, angle and scale, as white fill with a dark outline.
func doodle(at x: Double, _ y: Double, angle: Double, scale: Double = 1, _ shape: () -> Void) {
    ctx.saveGState(); ctx.translateBy(x: x, y: y); ctx.rotate(by: angle); ctx.scaleBy(x: scale, y: scale)
    ctx.setLineWidth(4.5 / scale); ctx.setStrokeColor(ink); ctx.setFillColor(rgb(1, 1, 1))
    shape()
    ctx.restoreGState()
}
func outline(_ path: CGPath) { ctx.addPath(path); ctx.drawPath(using: .fillStroke) }
func lines(_ pts: [(Double, Double, Double, Double)]) {
    for (x0, y0, x1, y1) in pts { ctx.move(to: CGPoint(x: x0, y: y0)); ctx.addLine(to: CGPoint(x: x1, y: y1)) }
    ctx.strokePath()
}
func round(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double) -> CGPath {
    CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerWidth: r, cornerHeight: r, transform: nil)
}
func circle(_ x: Double, _ y: Double, _ r: Double) -> CGPath { CGPath(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r), transform: nil) }

func electricGuitar() {                                         // body at the origin, neck pointing up
    outline(round(-14, 60, 28, 280, 4))                                                      // neck
    let head = CGMutablePath()
    head.move(to: CGPoint(x: -16, y: 335)); head.addLine(to: CGPoint(x: -22, y: 420))
    head.addQuadCurve(to: CGPoint(x: 30, y: 425), control: CGPoint(x: 0, y: 440)); head.addLine(to: CGPoint(x: 16, y: 335)); head.closeSubpath()
    outline(head)
    for k in 0..<6 { outline(circle(-30, 350 + Double(k) * 13, 5)) }                        // tuning pegs
    lines((1...9).map { k in let y = 60 + Double(k) * 30; return (-14, y, 14, y) })        // frets
    let body = CGMutablePath()
    body.move(to: CGPoint(x: 0, y: -120))
    body.addCurve(to: CGPoint(x: 115, y: -55), control1: CGPoint(x: 70, y: -125), control2: CGPoint(x: 115, y: -100))
    body.addCurve(to: CGPoint(x: 70, y: 30), control1: CGPoint(x: 115, y: -10), control2: CGPoint(x: 70, y: 0))
    body.addCurve(to: CGPoint(x: 85, y: 115), control1: CGPoint(x: 70, y: 70), control2: CGPoint(x: 95, y: 95))
    body.addCurve(to: CGPoint(x: 35, y: 75), control1: CGPoint(x: 75, y: 130), control2: CGPoint(x: 40, y: 110))
    body.addLine(to: CGPoint(x: -35, y: 75))
    body.addCurve(to: CGPoint(x: -60, y: 95), control1: CGPoint(x: -40, y: 95), control2: CGPoint(x: -50, y: 100))
    body.addCurve(to: CGPoint(x: -80, y: 20), control1: CGPoint(x: -75, y: 85), control2: CGPoint(x: -80, y: 50))
    body.addCurve(to: CGPoint(x: -115, y: -60), control1: CGPoint(x: -80, y: -10), control2: CGPoint(x: -115, y: -20))
    body.addCurve(to: CGPoint(x: 0, y: -120), control1: CGPoint(x: -115, y: -105), control2: CGPoint(x: -70, y: -125))
    body.closeSubpath()
    outline(body)
    for y in [-5.0, 25, 50] { outline(round(-28, y, 56, 13, 5)) }                           // pickups
    outline(round(-30, -70, 60, 18, 4))                                                      // bridge
    for (x, y) in [(60.0, -60.0), (78, -30), (45, -88)] { outline(circle(x, y, 10)) }        // knobs
    lines((0..<6).map { k in let x = -10 + Double(k) * 4; return (x, -62, x, 335) })         // strings
}

func trumpet() {                                                // mouthpiece left, bell right
    let bell = CGMutablePath()
    bell.move(to: CGPoint(x: 70, y: 7)); bell.addQuadCurve(to: CGPoint(x: 170, y: 48), control: CGPoint(x: 140, y: 10))
    bell.addLine(to: CGPoint(x: 170, y: -48)); bell.addQuadCurve(to: CGPoint(x: 70, y: -7), control: CGPoint(x: 140, y: -10)); bell.closeSubpath()
    outline(bell)
    ctx.addEllipse(in: CGRect(x: 160, y: -48, width: 20, height: 96)); ctx.drawPath(using: .fillStroke)
    outline(round(-140, -7, 212, 14, 7))                                                     // lead pipe
    let loop = CGMutablePath(); loop.addRoundedRect(in: CGRect(x: -70, y: -55, width: 130, height: 40), cornerWidth: 20, cornerHeight: 20)
    ctx.addPath(loop); ctx.strokePath()
    ctx.addPath(CGPath(roundedRect: CGRect(x: -62, y: -47, width: 114, height: 24), cornerWidth: 12, cornerHeight: 12, transform: nil)); ctx.strokePath()
    for x in [-30.0, -5, 20] {                                                               // valves
        outline(round(x, -20, 16, 62, 3)); outline(round(x - 4, 42, 24, 9, 4)); outline(circle(x + 8, 60, 9))
    }
    let mouth = CGMutablePath()
    mouth.move(to: CGPoint(x: -140, y: 5)); mouth.addLine(to: CGPoint(x: -175, y: 13)); mouth.addLine(to: CGPoint(x: -175, y: -13))
    mouth.addLine(to: CGPoint(x: -140, y: -5)); mouth.closeSubpath()
    outline(mouth)
}

func keyboard() {                                               // a little synth: 14 white keys and a control strip
    outline(round(-170, -60, 340, 125, 12))
    outline(round(-158, -50, 316, 68, 3))
    lines((1..<14).map { k in let x = -158 + Double(k) * 316 / 14; return (x, -50, x, 18) })
    ctx.setFillColor(ink)
    for k in [0, 1, 3, 4, 5, 7, 8, 10, 11, 12] {
        let x = -158 + Double(k + 1) * 316 / 14 - 7
        ctx.fill(CGRect(x: x, y: -12, width: 14, height: 30))
    }
    ctx.setFillColor(rgb(1, 1, 1))
    outline(round(-150, 30, 90, 24, 4))                                                      // screen
    for k in 0..<5 { outline(circle(-30 + Double(k) * 40, 42, 11)) }                         // knobs
}


func snareDrum() {                                              // drum with two crossed sticks
    lines([(-110, 150, 60, -10), (110, 150, -60, -10)])
    outline(circle(-110, 150, 8)); outline(circle(110, 150, 8))
    let shell = CGMutablePath()
    shell.move(to: CGPoint(x: -100, y: 30)); shell.addLine(to: CGPoint(x: -100, y: -50))
    shell.addCurve(to: CGPoint(x: 100, y: -50), control1: CGPoint(x: -100, y: -85), control2: CGPoint(x: 100, y: -85))
    shell.addLine(to: CGPoint(x: 100, y: 30)); shell.closeSubpath()
    outline(shell)
    lines((0..<6).map { k in let x = -80 + Double(k) * 32; return (x, 20, x, -65) })         // tension rods
    ctx.addEllipse(in: CGRect(x: -100, y: 5, width: 200, height: 50)); ctx.drawPath(using: .fillStroke)
}


doodle(at: 150, 880, angle: 0.45) { trumpet() }
doodle(at: 860, 920, angle: -0.35) { keyboard() }
doodle(at: 945, 205, angle: 0.3, scale: 0.6) { electricGuitar() }
doodle(at: 105, 110, angle: -0.15, scale: 0.8) { snareDrum() }

ctx.setStrokeColor(rgb(0.15, 0.15, 0.2, 0.6)); ctx.setLineWidth(3)
for k in 0..<5 {                                                                     // a wavy staff across the top
    let y = 960.0 + Double(k) * 14
    ctx.move(to: CGPoint(x: -20, y: y))
    ctx.addCurve(to: CGPoint(x: size + 20, y: y - 40), control1: CGPoint(x: 330, y: y + 60), control2: CGPoint(x: 700, y: y - 90))
}
ctx.strokePath()
for (glyph, x, y, s, a) in [("♪", 330.0, 790.0, 1.1, -0.2), ("♫", 640, 790, 1.1, 0.15), ("♬", 740, 40, 1.0, -0.1),
                            ("♪", 40, 720, 0.9, 0.3), ("♫", 990, 400, 0.9, -0.2), ("♩", 540, 25, 0.8, 0.2)] {
    ctx.saveGState(); ctx.translateBy(x: x, y: y); ctx.rotate(by: a); ctx.scaleBy(x: s, y: s)
    ctx.addPath(textPath(glyph, music)); ctx.setFillColor(rgb(0.12, 0.12, 0.16, 0.85)); ctx.fillPath()
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
                        (560, 250, 130, 0.14, 0.9), (330, 140, 95, 0.55, 0.8), (745, 150, 132, 0.98, 0.85), (560, 60, 120, 0.64, 0.95),
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
for (glyph, x, y, s, a) in [("♫", 585.0, 365.0, 2.6, -0.2), ("♪", 735, 270, 2.2, 0.12)] {   // big notes flying off the clef
    ctx.saveGState(); ctx.translateBy(x: x, y: y); ctx.rotate(by: a); ctx.scaleBy(x: s, y: s)
    let p = textPath(glyph, music)
    ctx.addPath(p); ctx.setStrokeColor(rgb(1, 1, 1)); ctx.setLineWidth(26 / s); ctx.strokePath()
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
