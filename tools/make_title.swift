// Makes the "MARBLE BEATS" title images from the artist's lettering, kept in art/title/ as three coverage masks (fill.png,
// outline.png, shadow.png: 255 where that tone is). Plain (white letters, black outline, grey shadow) for the menu and the
// builder header, or a holiday's colours with its greeting above in the same style (Luckiest Guy, open licence, art/fonts).
// Run from the repo root:
//   swift tools/make_title.swift                 → MarbleJam/Assets.xcassets/Title.imageset/Title.png
//   swift tools/make_title.swift halloween       → MarbleJam/Assets.xcassets/SeasonTitle-halloween.imageset/Title.png
//   (also thanksgiving, christmas, newyear, valentines, stpatricks, easter, muertos)
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor { CGColor(srgbRed: r, green: g, blue: b, alpha: a) }

struct Style {
    var top: CGColor, bottom: CGColor          // letter fill, top to bottom
    var shadow: CGColor                        // the drop shadow
    var greeting: String?, greetingColor = rgb(1, 1, 1)
}
let grey = rgb(205 / 255, 205 / 255, 205 / 255)
let styles: [String: Style] = [                // holiday colours follow the artist's holiday icons
    "": Style(top: rgb(1, 1, 1), bottom: rgb(1, 1, 1), shadow: grey),
    "halloween": Style(top: rgb(1, 0.6, 0.12), bottom: rgb(0.62, 0.36, 0.95), shadow: rgb(0.2, 0.06, 0.3),
                       greeting: "HAPPY HALLOWEEN", greetingColor: rgb(1, 0.62, 0.15)),
    "thanksgiving": Style(top: rgb(1, 0.78, 0.3), bottom: rgb(0.85, 0.36, 0.08), shadow: rgb(0.36, 0.17, 0.05),
                          greeting: "HAPPY THANKSGIVING", greetingColor: rgb(1, 0.86, 0.5)),
    "christmas": Style(top: rgb(1, 0.32, 0.3), bottom: rgb(0.76, 0.05, 0.1), shadow: rgb(0.05, 0.32, 0.14),
                       greeting: "MERRY CHRISTMAS", greetingColor: rgb(1, 1, 1)),
    "newyear": Style(top: rgb(1, 0.88, 0.45), bottom: rgb(0.85, 0.62, 0.12), shadow: rgb(0.07, 0.1, 0.3),
                     greeting: "HAPPY NEW YEAR", greetingColor: rgb(0.92, 0.93, 0.98)),
    "valentines": Style(top: rgb(1, 0.6, 0.78), bottom: rgb(0.9, 0.2, 0.45), shadow: rgb(0.4, 0.05, 0.2),
                        greeting: "HAPPY VALENTINE'S DAY", greetingColor: rgb(1, 0.85, 0.9)),
    "stpatricks": Style(top: rgb(1, 0.84, 0.35), bottom: rgb(0.2, 0.7, 0.3), shadow: rgb(0.05, 0.25, 0.1),
                        greeting: "HAPPY ST. PATRICK'S DAY", greetingColor: rgb(0.75, 1, 0.75)),
    "easter": Style(top: rgb(1, 0.92, 0.55), bottom: rgb(0.62, 0.55, 1), shadow: rgb(0.25, 0.18, 0.45),
                    greeting: "HAPPY EASTER", greetingColor: rgb(0.7, 0.95, 0.85)),
    "muertos": Style(top: rgb(1, 0.75, 0.2), bottom: rgb(1, 0.3, 0.6), shadow: rgb(0.25, 0.05, 0.35),
                     greeting: "DÍA DE LOS MUERTOS", greetingColor: rgb(0.4, 0.9, 0.85)),
]
let season = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
guard let style = styles[season] else { print("unknown season \(season)"); exit(1) }
let out = season.isEmpty ? "MarbleJam/Assets.xcassets/Title.imageset/Title.png" : "MarbleJam/Assets.xcassets/SeasonTitle-\(season).imageset/Title.png"

func load(_ name: String) -> CGImage {
    let url = URL(fileURLWithPath: "art/title/\(name).png")
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil), let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
        print("missing \(url.path)"); exit(1)
    }
    // redrawn as a plain 8-bit grey image, so it can be a clip mask (white = paint)
    let c = CGContext(data: nil, width: img.width, height: img.height, bitsPerComponent: 8, bytesPerRow: img.width,
                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
    c.draw(img, in: CGRect(x: 0, y: 0, width: img.width, height: img.height))
    return c.makeImage()!
}
let fill = load("fill"), outline = load("outline"), shadow = load("shadow")
let w = Double(fill.width), h = Double(fill.height)

// MARK: greeting above, as its own path

func font(_ file: String, _ pt: Double) -> CTFont {
    let descs = CTFontManagerCreateFontDescriptorsFromURL(URL(fileURLWithPath: "art/fonts/" + file) as CFURL) as! [CTFontDescriptor]
    return CTFontCreateWithFontDescriptor(descs[0], pt, nil)
}
func textPath(_ s: String, _ f: CTFont, tracking: Double) -> CGPath {
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
    return path
}
let stroke = 0.03 * h                                                   // the greeting's outline, in proportion to the title
var greeting: CGPath?, greetingHeight = 0.0
if let g = style.greeting {
    let raw = textPath(g, font("LuckiestGuy-Regular.ttf", 100), tracking: 4), b = raw.boundingBoxOfPath
    let scale = min(w * 0.92 / b.width, h * 0.24 / b.height)          // as wide as the title at most, about a quarter of its height
    greetingHeight = b.height * scale + stroke * 3
    var t = CGAffineTransform(translationX: w / 2, y: h + greetingHeight / 2).scaledBy(x: scale, y: scale).translatedBy(x: -b.midX, y: -b.midY)
    greeting = raw.copy(using: &t)
}

// MARK: paint (y up: the lettering at the bottom, the greeting above it)

let H = (h + greetingHeight).rounded(.up)
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(w), height: Int(H), bitsPerComponent: 8, bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let letters = CGRect(x: 0, y: 0, width: w, height: h)

func paint(_ mask: CGImage, _ body: () -> Void) { ctx.saveGState(); ctx.clip(to: letters, mask: mask); body(); ctx.restoreGState() }
paint(shadow) { ctx.setFillColor(style.shadow); ctx.fill(letters) }
paint(outline) { ctx.setFillColor(rgb(0, 0, 0)); ctx.fill(letters) }
paint(fill) {
    let g = CGGradient(colorsSpace: space, colors: [style.top, style.bottom] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: h), end: CGPoint(x: 0, y: 0), options: [])
}
if let p = greeting {
    ctx.setLineJoin(.round)
    ctx.saveGState(); ctx.translateBy(x: stroke * 0.6, y: -stroke * 0.6)
    ctx.addPath(p); ctx.setStrokeColor(style.shadow); ctx.setLineWidth(stroke * 2); ctx.strokePath()
    ctx.restoreGState()
    ctx.addPath(p); ctx.setStrokeColor(rgb(0, 0, 0)); ctx.setLineWidth(stroke * 2); ctx.strokePath()
    ctx.addPath(p); ctx.setFillColor(style.greetingColor); ctx.fillPath()
}

let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out) (\(Int(w))x\(Int(H)))")
