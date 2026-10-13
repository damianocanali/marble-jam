// Draws the "ROLLING NOTES" lettering (transparent PNG): chunky Luckiest Guy letters with a thick black outline and a
// block shadow, and every O is a glass marble. Plain white for the menu, or a holiday's colours with its greeting above.
// Everything is drawn here or comes from the open-licensed fonts in art/fonts, so the lettering is ours to use.
// Run from the repo root:
//   swift tools/make_title.swift                 → MarbleJam/Assets.xcassets/Title.imageset/Title.png
//   swift tools/make_title.swift halloween       → MarbleJam/Assets.xcassets/SeasonTitle-halloween.imageset/Title.png
//   (also thanksgiving, christmas)
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

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

struct Style {
    var top: CGColor, bottom: CGColor          // letter fill, top to bottom
    var shadow: CGColor                        // the block shadow
    var greeting: String?, greetingColor = rgb(1, 1, 1)
    var marbleHues: [Double]
}
let styles: [String: Style] = [
    "": Style(top: rgb(1, 1, 1), bottom: rgb(1, 1, 1), shadow: rgb(0.72, 0.72, 0.74), marbleHues: [0.58, 0.0, 0.33]),
    "halloween": Style(top: rgb(0.62, 0.36, 0.95), bottom: rgb(1, 0.5, 0.1), shadow: rgb(0.16, 0.05, 0.22),
                       greeting: "HAPPY HALLOWEEN", greetingColor: rgb(1, 0.62, 0.15), marbleHues: [0.07, 0.78, 0.33]),
    "thanksgiving": Style(top: rgb(1, 0.75, 0.25), bottom: rgb(0.85, 0.35, 0.08), shadow: rgb(0.32, 0.15, 0.04),
                          greeting: "HAPPY THANKSGIVING", greetingColor: rgb(1, 0.85, 0.45), marbleHues: [0.02, 0.1, 0.16]),
    "christmas": Style(top: rgb(1, 0.3, 0.3), bottom: rgb(0.75, 0.04, 0.1), shadow: rgb(0.05, 0.3, 0.12),
                       greeting: "MERRY CHRISTMAS", greetingColor: rgb(1, 1, 1), marbleHues: [0.36, 0.13]),
]
let season = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
guard let style = styles[season] else { print("unknown season \(season)"); exit(1) }
let out = season.isEmpty ? "MarbleJam/Assets.xcassets/Title.imageset/Title.png" : "MarbleJam/Assets.xcassets/SeasonTitle-\(season).imageset/Title.png"

// MARK: layout — each letter is its own path (y up), so the O's can be swapped for marbles

struct Piece { var path: CGPath?; var marble: CGRect?; var hue = 0.0 }
let letters = font("LuckiestGuy-Regular.ttf", 220)
var marbleCount = 0
func layout(_ s: String, baseline: Double, centerX: Double, tilt: Double) -> [Piece] {
    var chars = Array(s.utf16), glyphs = [CGGlyph](repeating: 0, count: chars.count)
    CTFontGetGlyphsForCharacters(letters, &chars, &glyphs, chars.count)
    var advances = [CGSize](repeating: .zero, count: glyphs.count)
    CTFontGetAdvancesForGlyphs(letters, .horizontal, glyphs, &advances, glyphs.count)
    let tracking = -4.0, width = advances.reduce(0) { $0 + $1.width + tracking } - tracking
    var x = centerX - width / 2, pieces: [Piece] = []
    for (k, g) in glyphs.enumerated() {
        let bounce = (k % 2 == 0 ? 1.0 : -1.0)                                   // letters rock a little, like they're rolling
        var t = CGAffineTransform(translationX: x + advances[k].width / 2, y: baseline + bounce * 6 + (x - centerX) * tilt)
            .rotated(by: bounce * 0.035 - tilt)
            .translatedBy(x: -advances[k].width / 2, y: 0)
        let glyphPath = CTFontCreatePathForGlyph(letters, g, nil)!
        if s[s.index(s.startIndex, offsetBy: k)] == "O" {
            let b = glyphPath.boundingBoxOfPath.applying(t), side = min(b.width, b.height) * 0.9     // round, and clear of the neighbours
            pieces.append(Piece(path: nil, marble: CGRect(x: b.midX - side / 2, y: b.midY - side / 2, width: side, height: side),
                                hue: style.marbleHues[marbleCount % style.marbleHues.count]))
            marbleCount += 1
        } else {
            pieces.append(Piece(path: glyphPath.copy(using: &t)))
        }
        x += advances[k].width + tracking
    }
    return pieces
}

let W = 1300.0, top = style.greeting == nil ? 0.0 : 130.0, H = 560.0 + top
var pieces = layout("ROLLING", baseline: H - top - 200, centerX: W / 2 - 40, tilt: 0.03)
pieces += layout("NOTES", baseline: H - top - 440, centerX: W / 2 + 70, tilt: -0.04)

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(W), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.setLineCap(.round); ctx.setLineJoin(.round)

func shape(_ p: Piece) -> CGPath { p.path ?? CGPath(ellipseIn: p.marble!, transform: nil) }

// MARK: block shadow, outline, fill — in layers, so neighbouring letters' outlines merge

for k in stride(from: 30.0, through: 4, by: -2) {
    ctx.saveGState(); ctx.translateBy(x: k * 0.9, y: -k)
    for p in pieces { ctx.addPath(shape(p)) }
    ctx.setStrokeColor(style.shadow); ctx.setLineWidth(38); ctx.strokePath()
    for p in pieces { ctx.addPath(shape(p)) }
    ctx.setFillColor(style.shadow); ctx.fillPath()
    ctx.restoreGState()
}
for p in pieces { ctx.addPath(shape(p)) }
ctx.setStrokeColor(rgb(0, 0, 0)); ctx.setLineWidth(38); ctx.strokePath()
ctx.saveGState()
for p in pieces where p.path != nil { ctx.addPath(p.path!) }
ctx.clip()
let fill = CGGradient(colorsSpace: space, colors: [style.top, style.bottom] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(fill, start: CGPoint(x: 0, y: H - top), end: CGPoint(x: 0, y: 40), options: [])
ctx.restoreGState()

// MARK: marbles — glossy glass with a swirl, in the O's

func marble(in r: CGRect, hue: Double) {
    let c = CGPoint(x: r.midX, y: r.midY), rad = r.width / 2
    ctx.saveGState(); ctx.addEllipse(in: r); ctx.clip()
    let body = CGGradient(colorsSpace: space, colors: [hsb(hue, 0.45, 1), hsb(hue, 0.85, 0.88), hsb(hue, 0.9, 0.4)] as CFArray, locations: [0, 0.5, 1])!
    ctx.drawRadialGradient(body, startCenter: CGPoint(x: c.x - rad * 0.3, y: c.y + rad * 0.35), startRadius: 0, endCenter: c, endRadius: rad * 1.05,
                           options: [.drawsAfterEndLocation])
    ctx.saveGState(); ctx.translateBy(x: c.x, y: c.y); ctx.rotate(by: hue * 9)
    for k in 0..<3 {
        let off = (Double(k) - 1) * rad * 0.2
        ctx.move(to: CGPoint(x: -rad, y: off - rad * 0.1))
        ctx.addCurve(to: CGPoint(x: rad, y: off + rad * 0.1), control1: CGPoint(x: -rad * 0.25, y: off + rad * 0.6), control2: CGPoint(x: rad * 0.25, y: off - rad * 0.6))
        ctx.setLineWidth(rad * (k == 1 ? 0.12 : 0.06))
        ctx.setStrokeColor(k == 1 ? rgb(1, 1, 1, 0.55) : hsb(hue, 0.9, 0.3, 0.5)); ctx.strokePath()
    }
    ctx.restoreGState()
    let rim = CGGradient(colorsSpace: space, colors: [rgb(0, 0, 0, 0), rgb(0, 0, 0, 0.35)] as CFArray, locations: [0.7, 1])!
    ctx.drawRadialGradient(rim, startCenter: c, startRadius: 0, endCenter: c, endRadius: rad, options: [])
    let shine = CGGradient(colorsSpace: space, colors: [rgb(1, 1, 1, 0.95), rgb(1, 1, 1, 0)] as CFArray, locations: [0, 1])!
    ctx.saveGState(); ctx.translateBy(x: c.x - rad * 0.36, y: c.y + rad * 0.4); ctx.rotate(by: 0.6); ctx.scaleBy(x: 1, y: 0.62)
    ctx.drawRadialGradient(shine, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: rad * 0.42, options: [])
    ctx.restoreGState()
    ctx.restoreGState()
}
for p in pieces { if let r = p.marble { marble(in: r, hue: p.hue) } }

// MARK: greeting above, in the same lettering, smaller

if let g = style.greeting {
    let attr = NSAttributedString(string: g, attributes: [kCTFontAttributeName as NSAttributedString.Key: font("LuckiestGuy-Regular.ttf", 92),
                                                          kCTKernAttributeName as NSAttributedString.Key: 4])
    let line = CTLineCreateWithAttributedString(attr), b = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    let path = CGMutablePath()
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let n = CTRunGetGlyphCount(run)
        var glyphs = [CGGlyph](repeating: 0, count: n), pos = [CGPoint](repeating: .zero, count: n)
        CTRunGetGlyphs(run, CFRange(location: 0, length: n), &glyphs); CTRunGetPositions(run, CFRange(location: 0, length: n), &pos)
        let rf = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName] as! CTFont
        for i in 0..<n { if let gp = CTFontCreatePathForGlyph(rf, glyphs[i], nil) { path.addPath(gp, transform: CGAffineTransform(translationX: pos[i].x, y: pos[i].y)) } }
    }
    var t = CGAffineTransform(translationX: W / 2 - b.midX, y: H - 105 - b.minY)
    let placed = path.copy(using: &t)!
    ctx.saveGState(); ctx.translateBy(x: 8, y: -8); ctx.addPath(placed); ctx.setStrokeColor(style.shadow); ctx.setLineWidth(22); ctx.strokePath(); ctx.restoreGState()
    ctx.addPath(placed); ctx.setStrokeColor(rgb(0, 0, 0)); ctx.setLineWidth(22); ctx.strokePath()
    ctx.addPath(placed); ctx.setFillColor(style.greetingColor); ctx.fillPath()
}

// MARK: trim to the drawing and save

let image = ctx.makeImage()!
let data = ctx.data!.assumingMemoryBound(to: UInt8.self), bpr = ctx.bytesPerRow
var minX = Int(W), minY = Int(H), maxX = 0, maxY = 0
for y in 0..<Int(H) { for x in 0..<Int(W) where data[y * bpr + x * 4 + 3] > 0 { minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y) } }
let trimmed = image.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, trimmed, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out) (\(trimmed.width)x\(trimmed.height))")
