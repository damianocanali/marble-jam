// Draws the Marble Jam app icon (1024x1024, opaque PNG).
// Run from the repo root: swift tools/make_icon.swift
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let out = "MarbleJam/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

// Same note colours as the game (Notes.hues, saturation 0.82).
func hue(_ degrees: CGFloat, _ a: CGFloat = 1) -> CGColor {
    let h = degrees / 60, s: CGFloat = 0.82, v: CGFloat = 1
    let c = v * s, x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1)), m = v - c
    let (r, g, b): (CGFloat, CGFloat, CGFloat) = switch Int(h) {
        case 0: (c, x, 0); case 1: (x, c, 0); case 2: (0, c, x)
        case 3: (0, x, c); case 4: (x, 0, c); default: (c, 0, x)
    }
    return rgb(r + m, g + m, b + m, a)
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.translateBy(x: 0, y: CGFloat(size)); ctx.scaleBy(x: 1, y: -1)   // top-left origin

// Background: the game's night sky, lighter at the top.
let sky = CGGradient(colorsSpace: space, colors: [rgb(0.09, 0.11, 0.25), rgb(0.03, 0.035, 0.075)] as CFArray,
                     locations: [0, 1])!
ctx.drawLinearGradient(sky, start: CGPoint(x: 512, y: 0), end: CGPoint(x: 512, y: 1024), options: [])
ctx.translateBy(x: 0, y: -60)   // centre the scene vertically

// The marble's flight: three bounces, drawn as a dotted trail.
func quad(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
    let u = 1 - t
    return CGPoint(x: u * u * a.x + 2 * u * t * c.x + t * t * b.x, y: u * u * a.y + 2 * u * t * c.y + t * t * b.y)
}
let hit1 = CGPoint(x: 250, y: 650), hit2 = CGPoint(x: 512, y: 780), hit3 = CGPoint(x: 790, y: 650)
let segments: [(CGPoint, CGPoint, CGPoint, CGFloat)] = [
    (CGPoint(x: 70, y: 210), CGPoint(x: 160, y: 210), hit1, 1),
    (hit1, CGPoint(x: 381, y: 330), hit2, 1),
    (hit2, CGPoint(x: 651, y: 330), hit3, 0.5),   // marble is mid-flight here
]
// Evenly spaced dots along the path, kept clear of the hits and the marble.
var path: [CGPoint] = []
for (a, c, b, end) in segments {
    for i in 0...Int(end * 400) { path.append(quad(a, c, b, CGFloat(i) / 400)) }
}
let marble = path.last!
var trail: [CGPoint] = [], walked: CGFloat = 0
for (prev, p) in zip(path, path.dropFirst()) {
    walked += hypot(p.x - prev.x, p.y - prev.y)
    if walked >= 52 { walked = 0; trail.append(p) }
}
let clear = [hit1, hit2].map { ($0, CGFloat(128)) } + [(marble, CGFloat(160))]
trail.removeAll { p in clear.contains { hypot(p.x - $0.0.x, p.y - $0.0.y) < $0.1 } }
for (i, p) in trail.enumerated() {
    let k = CGFloat(i + 1) / CGFloat(trail.count)
    let r = 7 + 9 * k
    ctx.setFillColor(rgb(0.9, 0.95, 1, 0.25 + 0.55 * k))
    ctx.fillEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
}

// Ripples where the marble struck (the notes it played).
func ripple(_ at: CGPoint, _ colour: CGFloat) {
    ctx.setLineWidth(10); ctx.setLineCap(.round)
    for (i, radius) in [70.0, 120.0].enumerated() {
        ctx.setStrokeColor(hue(colour, i == 0 ? 0.55 : 0.28))
        ctx.addArc(center: CGPoint(x: at.x, y: at.y + 10), radius: radius,
                   startAngle: .pi * 1.15, endAngle: .pi * 1.85, clockwise: false)
        ctx.strokePath()
    }
}
ripple(hit1, 190); ripple(hit2, 322)

// Pads: glowing capsules, tilted to the bounce.
func pad(_ top: CGPoint, _ colour: CGFloat, _ angle: CGFloat) {
    ctx.saveGState()
    ctx.translateBy(x: top.x, y: top.y + 22); ctx.rotate(by: angle)
    ctx.setShadow(offset: .zero, blur: 50, color: hue(colour))
    ctx.addPath(CGPath(roundedRect: CGRect(x: -125, y: -22, width: 250, height: 44),
                       cornerWidth: 22, cornerHeight: 22, transform: nil))
    ctx.setFillColor(hue(colour)); ctx.fillPath()
    ctx.restoreGState()
}
pad(hit1, 190, 0.26); pad(hit2, 322, 0); pad(hit3, 44, -0.26)

// The marble: white glass with a cool glow and a highlight.
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 90, color: rgb(0.62, 0.83, 1, 0.95))
ctx.setFillColor(rgb(0.62, 0.83, 1)); ctx.fillEllipse(in: CGRect(x: marble.x - 125, y: marble.y - 125, width: 250, height: 250))
ctx.restoreGState()
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: marble.x - 125, y: marble.y - 125, width: 250, height: 250)); ctx.clip()
let glass = CGGradient(colorsSpace: space, colors: [rgb(1, 1, 1), rgb(0.86, 0.93, 1), rgb(0.55, 0.72, 0.98)] as CFArray,
                       locations: [0, 0.45, 1])!
ctx.drawRadialGradient(glass, startCenter: CGPoint(x: marble.x - 45, y: marble.y - 50), startRadius: 0,
                       endCenter: marble, endRadius: 135, options: [.drawsAfterEndLocation])
ctx.restoreGState()
ctx.setFillColor(rgb(1, 1, 1, 0.9))
ctx.fillEllipse(in: CGRect(x: marble.x - 78, y: marble.y - 82, width: 56, height: 40))

try? FileManager.default.createDirectory(atPath: (out as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out)")
