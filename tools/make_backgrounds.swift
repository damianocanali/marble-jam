// Generates the game's backgrounds from scratch (noise, gradients and shapes), so they are entirely ours.
// Build and run from the repo root (optimised, a plain `swift` run is very slow):
//   xcrun swiftc -O tools/make_backgrounds.swift -o .build/make_backgrounds && .build/make_backgrounds art/backgrounds-drawn [names...]
// With no names it draws them all. Output: <dir>/<NN>-<name>.png at iPhone size.
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let W = 1170, H = 2532

// MARK: - noise

@inline(__always) func hash(_ x: Int32, _ y: Int32, _ s: Int32) -> Float {
    var h = UInt32(bitPattern: x &* 374_761_393 &+ y &* 668_265_263 &+ s &* 1_442_695_041)
    h = (h ^ (h >> 13)) &* 1_274_126_177
    h ^= h >> 16
    return Float(h & 0xFFFFFF) / Float(0xFFFFFF)
}

/// Smooth value noise, 0...1.
@inline(__always) func noise(_ x: Float, _ y: Float, _ s: Int32) -> Float {
    let xi = floorf(x), yi = floorf(y), xf = x - xi, yf = y - yi
    let u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf)
    let ix = Int32(xi), iy = Int32(yi)
    let a = hash(ix, iy, s), b = hash(ix &+ 1, iy, s), c = hash(ix, iy &+ 1, s), d = hash(ix &+ 1, iy &+ 1, s)
    return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v
}

/// Layered noise (fractal Brownian motion), 0...1.
@inline(__always) func fbm(_ x: Float, _ y: Float, _ s: Int32, _ octaves: Int = 5) -> Float {
    var sum: Float = 0, amp: Float = 0.5, f: Float = 1, norm: Float = 0
    for o in 0..<octaves {
        sum += amp * noise(x * f, y * f, s &+ Int32(o) &* 17)
        norm += amp; amp *= 0.5; f *= 2.03
    }
    return sum / norm
}

@inline(__always) func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float { let t = max(0, min(1, (x - a) / (b - a))); return t * t * (3 - 2 * t) }
@inline(__always) func mix(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }

typealias RGB = (Float, Float, Float)
@inline(__always) func mix(_ a: RGB, _ b: RGB, _ t: Float) -> RGB { (mix(a.0, b.0, t), mix(a.1, b.1, t), mix(a.2, b.2, t)) }
@inline(__always) func scale(_ a: RGB, _ k: Float) -> RGB { (a.0 * k, a.1 * k, a.2 * k) }
@inline(__always) func add(_ a: RGB, _ b: RGB) -> RGB { (a.0 + b.0, a.1 + b.1, a.2 + b.2) }
func rgb(_ hex: UInt32) -> RGB { (Float((hex >> 16) & 255) / 255, Float((hex >> 8) & 255) / 255, Float(hex & 255) / 255) }

// MARK: - canvas

/// A pixel picture filled by a per-pixel function (rows run in parallel), then optionally drawn on with Core Graphics.
final class Canvas {
    var bytes = [UInt8](repeating: 255, count: W * H * 4)

    func shade(_ f: (Int, Int) -> RGB) {
        bytes.withUnsafeMutableBufferPointer { buf in
            let p = buf.baseAddress!
            DispatchQueue.concurrentPerform(iterations: H) { y in
                for x in 0..<W {
                    let c = f(x, y), i = (y * W + x) * 4
                    p[i] = UInt8(max(0, min(255, c.0 * 255))); p[i + 1] = UInt8(max(0, min(255, c.1 * 255)))
                    p[i + 2] = UInt8(max(0, min(255, c.2 * 255))); p[i + 3] = 255
                }
            }
        }
    }

    /// Draw with Core Graphics in top-left coordinates (y down), on top of the shaded pixels.
    func draw(_ body: (CGContext) -> Void) {
        bytes.withUnsafeMutableBytes { raw in
            let ctx = CGContext(data: raw.baseAddress, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
            ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1, y: -1)
            body(ctx)
        }
    }

    func save(_ path: String) {
        let data = Data(bytes) as CFData
        let img = CGImage(width: W, height: H, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: W * 4,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                          provider: CGDataProvider(data: data)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(d, img, nil); CGImageDestinationFinalize(d)
    }
}

func cg(_ c: RGB, _ a: CGFloat = 1) -> CGColor { CGColor(srgbRed: CGFloat(c.0), green: CGFloat(c.1), blue: CGFloat(c.2), alpha: a) }

/// A soft round glow (radial gradient from `color` to transparent).
func glow(_ ctx: CGContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: RGB, _ alpha: CGFloat, sx: CGFloat = 1, sy: CGFloat = 1) {
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [cg(color, alpha), cg(color, 0)] as CFArray, locations: [0, 1])!
    ctx.saveGState(); ctx.translateBy(x: x, y: y); ctx.scaleBy(x: sx, y: sy)
    ctx.drawRadialGradient(g, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: r, options: [])
    ctx.restoreGState()
}

/// A light ray: the current path, filled with white that fades from `alpha` at the top to nothing at `bottom`.
func fadeRay(_ ctx: CGContext, alpha: CGFloat, bottom: CGFloat) {
    ctx.saveGState(); ctx.clip()
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [cg((1, 1, 1), alpha), cg((1, 1, 1), 0)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: bottom), options: [])
    ctx.restoreGState()
}

/// Deterministic random numbers for placing things.
struct Rand {
    var s: UInt64
    mutating func next() -> Double { s = s &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407; return Double(s >> 11) / Double(1 << 53) }
    mutating func range(_ a: Double, _ b: Double) -> Double { a + (b - a) * next() }
}

/// Small stars, a few with a glow and cross-shaped spikes.
func stars(_ c: Canvas, seed: UInt64, count: Int, bright: Int) {
    c.draw { ctx in
        var r = Rand(s: seed)
        for _ in 0..<count {
            let x = r.range(0, Double(W)), y = r.range(0, Double(H)), s = r.range(0.6, 2.2), a = r.range(0.35, 1)
            ctx.setFillColor(cg((1, 1, 1), a)); ctx.fillEllipse(in: CGRect(x: x - s, y: y - s, width: 2 * s, height: 2 * s))
        }
        for _ in 0..<bright {
            let x = CGFloat(r.range(0, Double(W))), y = CGFloat(r.range(0, Double(H))), s = CGFloat(r.range(10, 26))
            glow(ctx, x, y, s * 2.4, (0.8, 0.9, 1), 0.55)
            ctx.setStrokeColor(cg((1, 1, 1), 0.6)); ctx.setLineWidth(1.4)
            ctx.move(to: CGPoint(x: x - s * 2, y: y)); ctx.addLine(to: CGPoint(x: x + s * 2, y: y))
            ctx.move(to: CGPoint(x: x, y: y - s * 2)); ctx.addLine(to: CGPoint(x: x, y: y + s * 2)); ctx.strokePath()
            ctx.setFillColor(cg((1, 1, 1))); ctx.fillEllipse(in: CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5))
        }
    }
}

// MARK: - backgrounds

/// Vertical planks with grain, knots and seams. `dark`/`light` set the wood colour.
func wood(_ c: Canvas, dark: RGB, light: RGB, seed: Int32, weathered: Bool = false) {
    let planks = 5, pw = W / planks
    c.shade { x, y in
        let i = min(planks - 1, x / pw), lx = Float(x - i * pw), fy = Float(y), s = seed &+ Int32(i) &* 31
        // grain: stretched noise turned into stripes
        var g = lx * 0.02 + fbm(Float(x) * 0.006, fy * 0.0007, s) * 7
        let kx = Float(pw) * (0.3 + 0.4 * hash(Int32(i), 1, seed)), ky = Float(H) * hash(Int32(i), 2, seed)
        let dx = lx - kx, dy = (fy - ky) * 0.55, d = (dx * dx + dy * dy).squareRoot()
        let k = expf(-(d / 70) * (d / 70))                                   // a knot: rings bend around it
        g = mix(g, d * 0.06 + 2, k)
        let stripe = 0.5 + 0.5 * sinf(g * 6.283)
        let streak = fbm(Float(x) * 0.09, fy * 0.003, s &+ 5, 3)
        var col = mix(dark, light, 0.25 + 0.45 * stripe * (0.6 + 0.4 * streak) + 0.3 * streak - 0.25 * k * (d < 14 ? 1 : 0.4))
        col = scale(col, 0.85 + 0.25 * hash(Int32(i), 3, seed))              // each plank a slightly different tone
        if weathered { col = mix(col, light, 0.35 * fbm(Float(x) * 0.01, fy * 0.01, s &+ 9)) }
        let edge = min(lx, Float(pw) - lx)
        var shade: Float = edge < 4 ? 0.25 : (edge < 14 ? 0.7 + 0.3 * (edge - 4) / 10 : 1)   // gaps between planks
        let seam = Float(H) * hash(Int32(i), 4, seed)                         // a butt joint somewhere along the plank
        if abs(fy - seam) < 3 { shade *= 0.4 }
        return scale(col, shade)
    }
}

/// Warped colourful clouds over black with stars.
func nebula(_ c: Canvas, warm: RGB, cool: RGB, seed: Int32) {
    let k: Float = 1 / 520
    c.shade { x, y in
        let fx = Float(x) * k, fy = Float(y) * k
        let qx = fbm(fx, fy, seed), qy = fbm(fx + 5.2, fy + 1.3, seed &+ 1)
        let n = fbm(fx + 4 * qx, fy + 4 * qy, seed &+ 2, 6)
        let m = fbm(fx * 0.8 + 10 + 3 * qy, fy * 0.8 + 3 * qx, seed &+ 3, 6)
        let band = expf(-powf((Float(x) - Float(W) * 0.5 - (Float(y) - Float(H) * 0.5) * 0.25) / (Float(W) * 0.55), 2))
        let dust = smooth(0.25, 0.6, fbm(fx * 2.2, fy * 2.2, seed &+ 4))
        var col: RGB = (0.01, 0.012, 0.03)
        col = add(col, scale(cool, smooth(0.45, 0.85, m) * 1.1))
        col = add(col, scale(warm, smooth(0.42, 0.8, n) * 1.4 * band))
        col = add(col, scale((1, 0.9, 0.6), smooth(0.72, 0.9, n) * band * 0.9))  // hot cores
        return scale(col, 0.35 + 0.65 * dust)
    }
    stars(c, seed: UInt64(seed) &* 77, count: 2600, bright: 18)
}

/// Dark stage with coloured spotlight beams, haze and a lit floor.
func stage(_ c: Canvas, seed: Int32) {
    c.shade { x, y in
        let t = Float(y) / Float(H)
        let base = mix(rgb(0x05070F), rgb(0x0B1030), t)
        let haze = fbm(Float(x) / 380, Float(y) / 380, seed, 4)
        return add(base, scale((0.15, 0.2, 0.45), haze * 0.18))
    }
    c.draw { ctx in
        ctx.setBlendMode(.screen)
        let beams: [(CGFloat, CGFloat, RGB)] = [(0.18, 0.35, rgb(0x6F7BFF)), (0.42, 0.5, rgb(0xB58CFF)), (0.6, 0.52, rgb(0x7FD8FF)),
                                                 (0.84, 0.66, rgb(0x6F7BFF)), (0.5, 0.15, rgb(0x5BE0D0))]
        let floorY = CGFloat(H) * 0.86
        for (top, bottom, col) in beams {                                    // each beam: many faint, widening cones = soft edges
            let x0 = CGFloat(W) * top, x1 = CGFloat(W) * bottom
            for k in 0..<24 {
                let w0 = 6 + CGFloat(k) * 1.2, w1 = 60 + CGFloat(k) * 9
                let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [cg(col, 0.05), cg(col, 0.012)] as CFArray, locations: [0, 1])!
                ctx.saveGState()
                ctx.move(to: CGPoint(x: x0 - w0, y: -20)); ctx.addLine(to: CGPoint(x: x0 + w0, y: -20))
                ctx.addLine(to: CGPoint(x: x1 + w1, y: floorY)); ctx.addLine(to: CGPoint(x: x1 - w1, y: floorY)); ctx.closePath(); ctx.clip()
                ctx.drawLinearGradient(g, start: CGPoint(x: x0, y: 0), end: CGPoint(x: x1, y: floorY), options: [])
                ctx.restoreGState()
            }
            glow(ctx, x0, 10, 70, col, 0.9)                                  // the lamp
            glow(ctx, x0, 10, 18, (1, 1, 1), 0.9)
            glow(ctx, x1, floorY, 170, col, 0.35, sx: 1, sy: 0.22)          // pool of light on the floor
        }
        glow(ctx, CGFloat(W) / 2, floorY + 40, CGFloat(W) * 0.55, rgb(0x4A5BD8), 0.35, sx: 1, sy: 0.18)   // the stage floor
        ctx.setBlendMode(.normal)
        let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [cg(rgb(0x03040A), 0), cg(rgb(0x03040A), 0.9)] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: floorY + 60), end: CGPoint(x: 0, y: CGFloat(H)), options: [])
    }
}

/// Soft lavender-pink sky with fluffy clouds.
func clouds(_ c: Canvas, seed: Int32) {
    let k: Float = 1 / 460
    c.shade { x, y in
        let fx = Float(x) * k, fy = Float(y) * k
        let sky = mix(rgb(0xCFC2EC), rgb(0xF3D9EC), Float(y) / Float(H))
        let qx = fbm(fx, fy, seed), qy = fbm(fx + 3.1, fy + 7.7, seed &+ 1)
        let n = fbm(fx + 2.2 * qx, fy * 1.6 + 2.2 * qy, seed &+ 2, 6)
        let d = smooth(0.42, 0.72, n)
        let lit = fbm(fx * 1.5 + 0.08, fy * 1.5 - 0.12, seed &+ 2, 5)            // lighter on the side facing the light
        let cloud = mix(rgb(0xB9A3DA), rgb(0xFFF6FB), smooth(0.35, 0.75, lit + 0.15 * d))
        return mix(sky, cloud, d)
    }
}

/// White marble with thin grey veins.
func marbleStone(_ c: Canvas, seed: Int32) {
    let k: Float = 1 / 420
    c.shade { x, y in
        let fx = Float(x) * k, fy = Float(y) * k
        let w = fbm(fx * 0.6, fy * 0.6, seed, 6)
        let t = fx * 0.7 + fy * 0.35 + 2.6 * w
        let vein = 1 - smooth(0, 0.12 + 0.1 * fbm(fx * 2, fy * 2, seed &+ 3), abs(sinf(t * 2.2)))
        let fine = 1 - smooth(0, 0.05, abs(sinf((fx * 1.6 - fy * 0.8 + 2.5 * fbm(fx * 1.5, fy * 1.5, seed &+ 5)) * 3.3)))
        let strength = smooth(0.3, 0.75, fbm(fx * 0.5, fy * 0.5, seed &+ 7))
        let cloud = smooth(0.35, 0.8, fbm(fx * 0.9, fy * 0.9, seed &+ 9)) * 0.12
        var col = scale(rgb(0xF4F4F6), 1 - cloud)
        col = mix(col, rgb(0x55575F), vein * (0.25 + 0.6 * strength))
        return mix(col, rgb(0x8A8D96), fine * 0.35 * strength)
    }
}

/// Red brick wall with mortar joints.
func bricks(_ c: Canvas, seed: Int32) {
    let bw = 270, bh = 92, m = 16
    c.shade { x, y in
        let row = y / (bh + m), off = (row % 2) * (bw + m) / 2
        let col = (x + off) / (bw + m), lx = (x + off) % (bw + m), ly = y % (bh + m)
        let grain = fbm(Float(x) * 0.05, Float(y) * 0.05, seed, 4)
        if lx < m || ly < m {                                                  // mortar
            return scale(rgb(0xC9C2B6), 0.75 + 0.35 * grain)
        }
        let id = hash(Int32(col), Int32(row), seed)
        let base = mix(rgb(0xA8452C), rgb(0xD06A45), id)
        let blotch = fbm(Float(x) * 0.012, Float(y) * 0.012, seed &+ Int32(row), 4)
        var c2 = mix(scale(base, 0.75), base, blotch)
        c2 = scale(c2, 0.82 + 0.3 * grain)
        let ex = Float(lx - m) / Float(bw), ey = Float(ly - m) / Float(bh)       // bevel: light top-left, shadow bottom-right
        if ey < 0.08 { c2 = scale(c2, 1.12) }
        if ey > 0.9 || ex > 0.97 { c2 = scale(c2, 0.72) }
        if hash(Int32(x / 3), Int32(y / 3), seed &+ 9) > 0.97 { c2 = scale(c2, 0.7) }   // little pits
        return c2
    }
}

/// Swirling purple smoke.
func smoke(_ c: Canvas, seed: Int32) {
    let k: Float = 1 / 480
    c.shade { x, y in
        let fx = Float(x) * k, fy = Float(y) * k
        let qx = fbm(fx, fy, seed), qy = fbm(fx + 5.2, fy + 1.3, seed &+ 1)
        let rx = fbm(fx + 4 * qx + 1.7, fy + 4 * qy + 9.2, seed &+ 2), ry = fbm(fx + 4 * qx + 8.3, fy + 4 * qy + 2.8, seed &+ 3)
        let n = fbm(fx + 4 * rx, fy + 4 * ry, seed &+ 4, 6)
        var col = mix(rgb(0x0C0420), rgb(0x4B12A8), smooth(0.2, 0.7, n))
        col = add(col, scale(rgb(0xB070FF), smooth(0.6, 0.85, n) * 0.8))
        col = add(col, scale(rgb(0x20A0B0), smooth(0.55, 0.8, rx) * smooth(0.4, 0.6, n) * 0.35))
        return col
    }
    stars(c, seed: UInt64(seed), count: 300, bright: 0)
}

let musicFont: CTFont = {
    let d = CTFontManagerCreateFontDescriptorsFromURL(URL(fileURLWithPath: "art/fonts/NotoMusic-Regular.ttf") as CFURL) as! [CTFontDescriptor]
    return CTFontCreateWithFontDescriptor(d[0], 100, nil)
}()

/// Draws a music symbol centred at (x, y), `size` points tall-ish, in top-left coordinates.
func symbol(_ ctx: CGContext, _ s: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ angle: CGFloat, _ color: CGColor) {
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: [kCTFontAttributeName as NSAttributedString.Key: musicFont]))
    let path = CGMutablePath()
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let n = CTRunGetGlyphCount(run)
        var g = [CGGlyph](repeating: 0, count: n), pos = [CGPoint](repeating: .zero, count: n)
        CTRunGetGlyphs(run, CFRange(location: 0, length: n), &g); CTRunGetPositions(run, CFRange(location: 0, length: n), &pos)
        for i in 0..<n { if let gp = CTFontCreatePathForGlyph(musicFont, g[i], nil) { path.addPath(gp, transform: CGAffineTransform(translationX: pos[i].x, y: pos[i].y)) } }
    }
    let b = path.boundingBoxOfPath
    ctx.saveGState(); ctx.translateBy(x: x, y: y); ctx.rotate(by: angle)
    let k = size / max(b.height, 1)
    ctx.scaleBy(x: k, y: -k); ctx.translateBy(x: -b.midX, y: -b.midY)           // glyphs are y-up
    ctx.addPath(path); ctx.setFillColor(color); ctx.fillPath()
    ctx.restoreGState()
}

/// Old sheet-music paper: staves with notes in brown ink.
func sheetMusic(_ c: Canvas, seed: Int32) {
    c.shade { x, y in
        let fx = Float(x) / 300, fy = Float(y) / 300
        let stain = fbm(fx, fy, seed, 5)
        var col = mix(rgb(0xE9DCC0), rgb(0xD5C29C), smooth(0.4, 0.75, stain))
        col = scale(col, 0.93 + 0.07 * fbm(Float(x) / 6, Float(y) / 6, seed &+ 3, 2))
        return col
    }
    c.draw { ctx in
        var r = Rand(s: UInt64(seed))
        let ink = cg(rgb(0x4A3A28), 0.75), gap: CGFloat = 13
        var top: CGFloat = 70
        while top < CGFloat(H) - 60 {
            ctx.setStrokeColor(ink); ctx.setLineWidth(1.6)
            for k in 0..<5 { ctx.move(to: CGPoint(x: 40, y: top + CGFloat(k) * gap)); ctx.addLine(to: CGPoint(x: CGFloat(W) - 40, y: top + CGFloat(k) * gap)) }
            ctx.strokePath()
            var x: CGFloat = 70
            symbol(ctx, "𝄞", 62, top + 2 * gap, 5.4 * gap, 0, ink)
            x = 120
            while x < CGFloat(W) - 70 {
                if r.next() < 0.12 {                                             // bar line
                    ctx.setLineWidth(1.6); ctx.move(to: CGPoint(x: x, y: top)); ctx.addLine(to: CGPoint(x: x, y: top + 4 * gap)); ctx.strokePath()
                    x += 22; continue
                }
                let step = CGFloat(Int(r.range(-3, 11))), ny = top + 4 * gap - step * gap / 2
                ctx.saveGState(); ctx.translateBy(x: x, y: ny); ctx.rotate(by: -0.35)
                let filled = r.next() < 0.75
                ctx.addEllipse(in: CGRect(x: -7.5, y: -5.2, width: 15, height: 10.4))
                if filled { ctx.setFillColor(ink); ctx.fillPath() } else { ctx.setLineWidth(2); ctx.strokePath() }
                ctx.restoreGState()
                let up = step < 4
                ctx.setLineWidth(1.5)
                ctx.move(to: CGPoint(x: x + (up ? 6.5 : -6.5), y: ny)); ctx.addLine(to: CGPoint(x: x + (up ? 6.5 : -6.5), y: ny + (up ? -42 : 42))); ctx.strokePath()
                x += CGFloat(r.range(26, 46))
            }
            top += 5 * gap + CGFloat(r.range(70, 90))
        }
    }
}

/// Cartoon underwater: light rays, rock and kelp silhouettes, sand and bubbles.
func underwater(_ c: Canvas, seed: Int32) {
    c.shade { x, y in
        let t = Float(y) / Float(H), fx = Float(x)
        var col = t < 0.75 ? mix(rgb(0x8BE3FF), rgb(0x0E64B8), smooth(0, 0.75, t)) : mix(rgb(0x0E64B8), rgb(0x2A86C8), smooth(0.75, 0.86, t))
        let sandTop = Float(H) * (0.88 + 0.025 * sinf(fx / 160) + 0.02 * fbm(fx / 200, 0, seed))
        if Float(y) > sandTop { col = mix(rgb(0xF2DDA0), rgb(0xE2C27A), fbm(fx / 30, Float(y) / 30, seed &+ 1, 3)) }
        // rock pillars on both sides, two layers
        for (layer, shade) in [(Float(0.0), Float(0.55)), (1, 0.78)] {
            let s = seed &+ 10 &+ Int32(layer)
            let edgeL = Float(W) * (0.12 + 0.07 * layer) + Float(W) * 0.12 * (fbm(Float(y) / 260, layer * 7, s, 4) - 0.5) * 2
            let edgeR = Float(W) * (0.88 - 0.07 * layer) + Float(W) * 0.12 * (fbm(Float(y) / 240, layer * 7 + 3, s &+ 1, 4) - 0.5) * 2
            let shelf = smooth(Float(H) * 0.25, Float(H) * 0.45, Float(y))
            if (fx < edgeL * (0.55 + 0.45 * shelf) || fx > Float(W) - (Float(W) - edgeR) * (0.55 + 0.45 * shelf)) && Float(y) < sandTop + 30 {
                col = mix(scale(rgb(0x1474C4), shade), rgb(0x3FA6E0), layer * 0.4 * (1 - t))
            }
        }
        return col
    }
    c.draw { ctx in
        ctx.setBlendMode(.screen)
        var r = Rand(s: UInt64(seed))
        for _ in 0..<7 {                                                         // light rays from the surface
            let x0 = CGFloat(r.range(0.1, 0.9)) * CGFloat(W), w = CGFloat(r.range(40, 110)), dx = CGFloat(r.range(-200, 200))
            ctx.move(to: CGPoint(x: x0 - w / 3, y: 0)); ctx.addLine(to: CGPoint(x: x0 + w / 3, y: 0))
            ctx.addLine(to: CGPoint(x: x0 + dx + w, y: CGFloat(H) * 0.8)); ctx.addLine(to: CGPoint(x: x0 + dx - w, y: CGFloat(H) * 0.8)); ctx.closePath()
            fadeRay(ctx, alpha: 0.12, bottom: CGFloat(H) * 0.8)
        }
        ctx.setBlendMode(.normal)
        for _ in 0..<26 {                                                        // kelp and sea grass
            let x0 = CGFloat(r.range(0, 1)) * CGFloat(W), h = CGFloat(r.range(140, 520)), base = CGFloat(H) * 0.9
            let green = r.next() < 0.7
            ctx.setStrokeColor(cg(green ? rgb(0x2E9E58) : rgb(0xC0504A), 0.9)); ctx.setLineWidth(CGFloat(r.range(7, 16))); ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: x0, y: base))
            ctx.addCurve(to: CGPoint(x: x0 + CGFloat(r.range(-40, 40)), y: base - h),
                         control1: CGPoint(x: x0 + 50, y: base - h * 0.33), control2: CGPoint(x: x0 - 50, y: base - h * 0.66))
            ctx.strokePath()
        }
        for _ in 0..<40 {                                                        // bubbles
            let x = CGFloat(r.range(0, Double(W))), y = CGFloat(r.range(Double(H) * 0.3, Double(H) * 0.9)), s = CGFloat(r.range(5, 20))
            ctx.setStrokeColor(cg((1, 1, 1), 0.7)); ctx.setLineWidth(2); ctx.strokeEllipse(in: CGRect(x: x - s, y: y - s, width: 2 * s, height: 2 * s))
            ctx.setFillColor(cg((1, 1, 1), 0.6)); ctx.fillEllipse(in: CGRect(x: x - s * 0.5, y: y - s * 0.6, width: s * 0.45, height: s * 0.45))
        }
    }
}

/// Aged parchment with burnt edges and faint compass roses.
func parchment(_ c: Canvas, seed: Int32) {
    c.shade { x, y in
        let fx = Float(x) / 380, fy = Float(y) / 380
        let n = fbm(fx, fy, seed, 6)
        var col = mix(rgb(0xD8B987), rgb(0xEDDAB0), smooth(0.25, 0.8, n))
        let dx = (Float(x) / Float(W) - 0.5) * 2, dy = (Float(y) / Float(H) - 0.5) * 2
        let edge = max(abs(dx), abs(dy)) + 0.15 * (fbm(fx * 3, fy * 3, seed &+ 5) - 0.5)
        col = scale(col, 1 - 0.55 * smooth(0.7, 1.05, edge))
        col = scale(col, 1 - 0.08 * smooth(0.6, 0.85, fbm(fx * 1.2, fy * 1.2, seed &+ 9)))   // a few faint stains
        return col
    }
    c.draw { ctx in
        for (cx, cy, rr) in [(CGFloat(W) * 0.82, CGFloat(H) * 0.08, CGFloat(170)), (CGFloat(W) * 0.15, CGFloat(H) * 0.72, CGFloat(230))] {
            ctx.setStrokeColor(cg(rgb(0x6B4E2A), 0.28)); ctx.setLineWidth(3)
            for f in [1.0, 0.86, 0.5] { ctx.strokeEllipse(in: CGRect(x: cx - rr * f, y: cy - rr * f, width: 2 * rr * f, height: 2 * rr * f)) }
            for k in 0..<16 {
                let a = CGFloat(k) * .pi / 8, len = k % 2 == 0 ? rr : rr * 0.6
                let p = CGMutablePath()
                p.move(to: CGPoint(x: cx + cos(a) * len, y: cy + sin(a) * len))
                p.addLine(to: CGPoint(x: cx + cos(a + 0.12) * rr * 0.16, y: cy + sin(a + 0.12) * rr * 0.16))
                p.addLine(to: CGPoint(x: cx + cos(a - 0.12) * rr * 0.16, y: cy + sin(a - 0.12) * rr * 0.16)); p.closeSubpath()
                ctx.addPath(p); ctx.setFillColor(cg(rgb(0x6B4E2A), k % 2 == 0 ? 0.22 : 0.12)); ctx.fillPath()
            }
        }
    }
}

/// Illustrated coral reef: branching corals, fans, fish and light from above.
func reef(_ c: Canvas, seed: Int32) {
    c.shade { x, y in
        let t = Float(y) / Float(H)
        let col = mix(rgb(0x2C9BE0), rgb(0x062C66), smooth(0, 1, t))
        return add(col, scale((0.2, 0.4, 0.5), fbm(Float(x) / 300, Float(y) / 300, seed, 4) * 0.15 * (1 - t)))
    }
    c.draw { ctx in
        var r = Rand(s: UInt64(seed))
        ctx.setBlendMode(.screen)
        for _ in 0..<6 {
            let x0 = CGFloat(r.range(0, Double(W))), w = CGFloat(r.range(50, 120))
            ctx.move(to: CGPoint(x: x0 - w / 3, y: 0)); ctx.addLine(to: CGPoint(x: x0 + w / 3, y: 0))
            ctx.addLine(to: CGPoint(x: x0 + w + 150, y: CGFloat(H) * 0.7)); ctx.addLine(to: CGPoint(x: x0 - w + 150, y: CGFloat(H) * 0.7)); ctx.closePath()
            fadeRay(ctx, alpha: 0.1, bottom: CGFloat(H) * 0.7)
        }
        ctx.setBlendMode(.normal)
        func branch(_ x: CGFloat, _ y: CGFloat, _ a: CGFloat, _ len: CGFloat, _ w: CGFloat, _ depth: Int, _ col: CGColor) {
            let x2 = x + cos(a) * len, y2 = y + sin(a) * len
            ctx.setStrokeColor(col); ctx.setLineWidth(w); ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: x, y: y)); ctx.addLine(to: CGPoint(x: x2, y: y2)); ctx.strokePath()
            guard depth > 0 else { return }
            for d in [-0.5, 0.45] { branch(x2, y2, a + CGFloat(d + r.range(-0.15, 0.15)), len * 0.72, w * 0.82, depth - 1, col) }
        }
        let corals: [RGB] = [rgb(0xFF7A45), rgb(0xFF5C8A), rgb(0xB06CFF), rgb(0xFFC04A), rgb(0xFF9A6A)]
        for i in 0..<16 {                                                         // reef along the left side and the bottom
            let onBottom = i >= 7
            let x = onBottom ? CGFloat(r.range(0, Double(W))) : CGFloat(r.range(-40, Double(W) * 0.32))
            let y = onBottom ? CGFloat(r.range(Double(H) * 0.82, Double(H) + 40)) : CGFloat(r.range(Double(H) * 0.15, Double(H) * 0.8))
            let a = onBottom ? -CGFloat.pi / 2 + CGFloat(r.range(-0.4, 0.4)) : CGFloat(r.range(-0.9, -0.2))
            branch(x, y, a, CGFloat(r.range(70, 120)), CGFloat(r.range(34, 50)), 4, cg(corals[i % corals.count]))
        }
        for _ in 0..<8 {                                                          // round brain corals and rocks
            let x = CGFloat(r.range(0, Double(W))), y = CGFloat(r.range(Double(H) * 0.88, Double(H))), s = CGFloat(r.range(60, 140))
            ctx.setFillColor(cg(corals[Int(r.range(0, 5))], 1)); ctx.fillEllipse(in: CGRect(x: x - s, y: y - s * 0.7, width: 2 * s, height: 1.4 * s))
            ctx.setStrokeColor(cg((0, 0, 0), 0.2)); ctx.setLineWidth(5)
            for k in 1..<4 { let f = CGFloat(k) / 4; ctx.strokeEllipse(in: CGRect(x: x - s * f, y: y - s * 0.7 * f, width: 2 * s * f, height: 1.4 * s * f)) }
        }
        let fishColors: [(RGB, RGB)] = [(rgb(0xFFD23F), rgb(0x1D3557)), (rgb(0x2B7FFF), rgb(0xFFD23F)), (rgb(0xFF8C1A), rgb(0xFFFFFF))]
        for i in 0..<12 {                                                         // fish
            let x = CGFloat(r.range(Double(W) * 0.3, Double(W) * 0.95)), y = CGFloat(r.range(Double(H) * 0.1, Double(H) * 0.8))
            let s = CGFloat(r.range(26, 60)), (body, stripe) = fishColors[i % 3], left = r.next() < 0.5
            ctx.saveGState(); ctx.translateBy(x: x, y: y); if left { ctx.scaleBy(x: -1, y: 1) }
            let tail = CGMutablePath(); tail.move(to: CGPoint(x: -s * 0.8, y: 0)); tail.addLine(to: CGPoint(x: -s * 1.5, y: -s * 0.55)); tail.addLine(to: CGPoint(x: -s * 1.5, y: s * 0.55)); tail.closeSubpath()
            ctx.addPath(tail); ctx.setFillColor(cg(body)); ctx.fillPath()
            ctx.setFillColor(cg(body)); ctx.fillEllipse(in: CGRect(x: -s, y: -s * 0.55, width: 2 * s, height: 1.1 * s))
            ctx.setStrokeColor(cg(stripe)); ctx.setLineWidth(s * 0.18)
            ctx.move(to: CGPoint(x: -s * 0.1, y: -s * 0.5)); ctx.addLine(to: CGPoint(x: -s * 0.1, y: s * 0.5)); ctx.strokePath()
            ctx.setFillColor(cg((1, 1, 1))); ctx.fillEllipse(in: CGRect(x: s * 0.45, y: -s * 0.22, width: s * 0.26, height: s * 0.26))
            ctx.setFillColor(cg((0, 0, 0))); ctx.fillEllipse(in: CGRect(x: s * 0.52, y: -s * 0.15, width: s * 0.13, height: s * 0.13))
            ctx.restoreGState()
        }
    }
}

/// Ink-wash city skyline on a horizon with its reflection, black and white.
func skyline(_ c: Canvas, seed: Int32) {
    var r = Rand(s: UInt64(seed))
    var heights = [Float](repeating: 0, count: W)
    var x = 0
    while x < W {                                                               // buildings: random widths and heights, some spires
        let w = Int(r.range(30, 110)), h = Float(r.range(120, 620)) * (r.next() < 0.1 ? 1.5 : 1), spire = r.next() < 0.15
        for i in x..<min(W, x + w) {
            let u = Float(i - x) / Float(w)
            heights[i] = h + (spire ? max(0, 160 - abs(u - 0.5) * 900) : 0)
        }
        x += w
    }
    let horizon = Float(H) * 0.55
    c.shade { x, y in
        let fy = Float(y), fx = Float(x)
        var col = mix(rgb(0xF7F7F5), rgb(0xBFC1C6), smooth(0.45, 0.8, fbm(fx / 260, fy / 260, seed, 5)))   // washed sky
        let wob = Int(12 * (fbm(fx / 40, fy / 25, seed &+ 3, 3) - 0.5))
        let h = heights[max(0, min(W - 1, x + wob))]
        let bleed = 18 * fbm(fx / 20, fy / 20, seed &+ 5, 3)
        if fy < horizon && fy > horizon - h - bleed {
            col = mix(col, rgb(0x16181D), smooth(0, 30, fy - (horizon - h - bleed)) * (0.75 + 0.25 * fbm(fx / 60, fy / 60, seed &+ 7)))
        } else if fy >= horizon && fy < horizon + h * 0.75 {                     // reflection, lighter and rippled
            let k = 1 - (fy - horizon) / (h * 0.75)
            col = mix(col, rgb(0x3A3D45), 0.6 * k * (0.7 + 0.3 * fbm(fx / 10, fy / 4, seed &+ 9, 2)))
        }
        return col
    }
    c.draw { ctx in
        for _ in 0..<500 {                                                       // lit windows
            let x = Int(r.range(0, Double(W))), h = CGFloat(heights[x])
            guard h > 150 else { continue }
            let y = CGFloat(horizon) - CGFloat(r.range(20, Double(h) - 30))
            ctx.setFillColor(cg((0.95, 0.95, 0.9), 0.55)); ctx.fill(CGRect(x: CGFloat(x), y: y, width: 6, height: 9))
        }
    }
}

/// Warm golden bokeh lights with soft diagonal light.
func bokeh(_ c: Canvas, seed: Int32) {
    c.shade { x, y in
        let t = (Float(x) / Float(W) + Float(y) / Float(H)) / 2
        var col = mix(rgb(0x8C7A3C), rgb(0x3E3416), t)
        col = add(col, scale(rgb(0x4A3A10), 0.4 * sinf(Float(x - y) / 90) * 0.5 + 0.2))     // light streaks
        return scale(col, 0.9 + 0.1 * fbm(Float(x) / 200, Float(y) / 200, seed))
    }
    c.draw { ctx in
        ctx.setBlendMode(.screen)
        var r = Rand(s: UInt64(seed))
        for _ in 0..<70 {
            let x = CGFloat(r.range(0, Double(W))), y = CGFloat(r.range(0, Double(H))), s = CGFloat(r.range(40, 170)), a = CGFloat(r.range(0.12, 0.35))
            let col = mix(rgb(0xFFC86A), rgb(0xFFE7B0), Float(r.next()))
            for k in 0..<6 {                                                     // soft edge: a few slightly larger, fainter discs
                let rr = s * (1 + CGFloat(k) * 0.025)
                ctx.setFillColor(cg(col, a / CGFloat(k + 1))); ctx.fillEllipse(in: CGRect(x: x - rr, y: y - rr, width: 2 * rr, height: 2 * rr))
            }
            ctx.setStrokeColor(cg(col, a * 0.8)); ctx.setLineWidth(3); ctx.strokeEllipse(in: CGRect(x: x - s, y: y - s, width: 2 * s, height: 2 * s))
        }
    }
}

/// Earth seen from orbit: curved horizon, glowing atmosphere, ocean, land and clouds.
func earth(_ c: Canvas, seed: Int32) {
    let cx = Float(W) * 0.5, cy = Float(H) * 2.05, R = Float(H) * 1.85
    c.shade { x, y in
        let dx = Float(x) - cx, dy = Float(y) - cy, d = (dx * dx + dy * dy).squareRoot()
        if d > R {                                                              // space, with the atmosphere glowing just above the edge
            let a = d - R
            return add(rgb(0x01030A), scale(rgb(0x4FA3FF), expf(-a / 40) * 0.9))
        }
        let depth = (R - d) / (Float(H) * 0.9)                                  // 0 at the horizon, growing towards the viewer
        let u = atan2f(dx, -dy) * R / 900, v = sqrtf(max(depth, 0.0001)) * 6
        let land = smooth(0.55, 0.62, fbm(u * 2, v * 2, seed, 6))
        let cloud = smooth(0.5, 0.75, fbm(u * 3 + 7, v * 3, seed &+ 3, 6))
        var col = mix(rgb(0x0B2F5E), rgb(0x1A4E86), fbm(u * 6, v * 6, seed &+ 5, 3))
        col = mix(col, mix(rgb(0x6B6A45), rgb(0x9C8A5E), fbm(u * 8, v * 8, seed &+ 7, 3)), land)
        col = mix(col, rgb(0xF2F6FA), cloud * 0.9)
        col = mix(col, rgb(0x7FB8FF), expf(-depth * 14) * 0.7)                   // haze at the horizon
        let sun = expf(-powf((Float(x) - Float(W) * 0.75) / 500, 2) - powf(depth * 2.5, 2))
        return add(col, scale((1, 0.95, 0.85), sun * 0.35))
    }
    stars(c, seed: UInt64(seed) &* 3, count: 400, bright: 3)
}

/// Iridescent holographic liquid swirl.
func holo(_ c: Canvas, seed: Int32) {
    let k: Float = 1 / 520
    c.shade { x, y in
        let fx = Float(x) * k, fy = Float(y) * k
        let qx = fbm(fx, fy, seed), qy = fbm(fx + 5.2, fy + 1.3, seed &+ 1)
        let t = fbm(fx + 3.5 * qx, fy + 3.5 * qy, seed &+ 2, 5) * 3.2
        let p = (0.0 as Float, 0.33 as Float, 0.67 as Float)
        var col: RGB = (0.78 + 0.22 * cosf(6.283 * (t + p.0)), 0.75 + 0.25 * cosf(6.283 * (t + p.1)), 0.85 + 0.15 * cosf(6.283 * (t + p.2)))
        let sheen = powf(max(0, sinf(t * 9.4)), 18)                              // bright edges between bands
        col = mix(col, (1, 1, 1), sheen * 0.7)
        let dark = powf(max(0, -sinf(t * 9.4 + 0.6)), 22)
        return mix(col, rgb(0x2B3A8C), dark * 0.45)
    }
}

/// Black with gold diagonal lines and darker panels.
func blackGold(_ c: Canvas, seed: Int32) {
    c.shade { x, y in
        let fx = Float(x), fy = Float(y)
        var col = scale(rgb(0x1C1C1E), 0.9 + 0.12 * fbm(fx / 400, fy / 400, seed))
        if fx * 0.8 + fy < Float(H) * 0.42 || fx * 0.8 - fy > -Float(H) * 0.25 + Float(W) * 0.8 { col = scale(col, 0.75) }   // panels
        if -fx * 0.9 + fy > Float(H) * 0.62 { col = scale(col, 1.15) }
        return col
    }
    c.draw { ctx in
        let gold = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [cg(rgb(0x8A6A2A)), cg(rgb(0xF5D58A)), cg(rgb(0x8A6A2A))] as CFArray, locations: [0, 0.5, 1])!
        let lines: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [(-100, 900, 900, -100, 5), (300, 2600, 1300, 1600, 4), (-50, 1500, 1250, 2700, 3),
                                                                       (700, -50, 1250, 500, 3), (-80, 2200, 500, 2650, 2.5), (1250, 1100, 300, 2100, 2)]
        for (x0, y0, x1, y1, w) in lines {
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 14, color: cg(rgb(0xF5D58A), 0.6))
            ctx.setLineWidth(w); ctx.move(to: CGPoint(x: x0, y: y0)); ctx.addLine(to: CGPoint(x: x1, y: y1))
            ctx.replacePathWithStrokedPath(); ctx.clip()
            ctx.drawLinearGradient(gold, start: CGPoint(x: x0, y: y0), end: CGPoint(x: x1, y: y1), options: [])
            ctx.restoreGState()
        }
    }
}

/// Overlapping teal-green dragon scales.
func dragonScales(_ c: Canvas, seed: Int32) {
    c.shade { _, _ in rgb(0x08201F) }
    c.draw { ctx in
        let sw: CGFloat = 150, sh: CGFloat = 92
        let rows = Int(CGFloat(H) / sh) + 3
        for row in stride(from: rows, through: -1, by: -1) {                    // bottom rows first: upper scales overlap them
            let cy = CGFloat(row) * sh - 40, off = row % 2 == 0 ? 0 : sw / 2
            var x = -sw + off
            while x < CGFloat(W) + sw {
                let n = CGFloat(fbm(Float(x) / 500, Float(cy) / 500, seed))
                let base = mix(rgb(0x1F6E6A), rgb(0x3E9A6E), Float(n)), tip = mix(rgb(0x0C3B3C), rgb(0x173F57), Float(n))
                let p = CGMutablePath()
                p.move(to: CGPoint(x: x - sw / 2, y: cy))
                p.addQuadCurve(to: CGPoint(x: x, y: cy + sh * 1.55), control: CGPoint(x: x - sw / 2, y: cy + sh * 1.2))
                p.addQuadCurve(to: CGPoint(x: x + sw / 2, y: cy), control: CGPoint(x: x + sw / 2, y: cy + sh * 1.2))
                p.closeSubpath()
                ctx.saveGState(); ctx.addPath(p); ctx.clip()
                let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [cg(scale(base, 1.25)), cg(base), cg(tip)] as CFArray, locations: [0, 0.45, 1])!
                ctx.drawLinearGradient(g, start: CGPoint(x: x, y: cy), end: CGPoint(x: x, y: cy + sh * 1.55), options: [])
                ctx.setStrokeColor(cg((0.75, 1, 0.95), 0.35)); ctx.setLineWidth(3)                 // ridge highlight
                ctx.move(to: CGPoint(x: x, y: cy + 8)); ctx.addLine(to: CGPoint(x: x, y: cy + sh * 1.3)); ctx.strokePath()
                ctx.restoreGState()
                ctx.addPath(p); ctx.setStrokeColor(cg(rgb(0x041414), 0.9)); ctx.setLineWidth(4); ctx.strokePath()
                x += sw
            }
        }
    }
}

/// Green pixel blocks.
func pixels(_ c: Canvas, seed: Int32) {
    let s = 78
    let greens: [RGB] = [rgb(0x2F8F2F), rgb(0x3FA83A), rgb(0x4CBB45), rgb(0x5ACB52), rgb(0x37992F), rgb(0x67D85E)]
    c.shade { x, y in
        let cx = x / s, cy = y / s, lx = x % s, ly = y % s
        var col = greens[Int(hash(Int32(cx), Int32(cy), seed) * 5.99)]
        if lx < 4 || ly < 4 { col = scale(col, 1.08) }                           // light top-left edge
        if lx > s - 5 || ly > s - 5 { col = scale(col, 0.85) }                   // dark bottom-right edge
        return col
    }
}

/// Smooth blur of pink, orange, purple and blue.
func colorBlur(_ c: Canvas, seed: Int32) {
    let blobs: [(Float, Float, Float, RGB)] = [(0.2, 0.15, 0.45, rgb(0xFF4F8B)), (0.85, 0.3, 0.4, rgb(0xFF8A3D)), (0.3, 0.55, 0.45, rgb(0x7A3CFF)),
                                                (0.8, 0.75, 0.4, rgb(0xFF3D6E)), (0.4, 0.92, 0.35, rgb(0x3D7BFF)), (0.6, 0.45, 0.3, rgb(0xFFB04F))]
    c.shade { x, y in
        let u = Float(x) / Float(W), v = Float(y) / Float(H) * 2.16
        var sum: RGB = (0, 0, 0), wsum: Float = 0
        for (bx, by, r, col) in blobs {
            let dx = u - bx, dy = v - by * 2.16, w = expf(-(dx * dx + dy * dy) / (r * r))
            sum = add(sum, scale(col, w)); wsum += w
        }
        let grain = (hash(Int32(x), Int32(y), seed) - 0.5) * 0.03
        let col = scale(sum, 1 / max(wsum, 0.001))
        return (col.0 + grain, col.1 + grain, col.2 + grain)
    }
}

/// Shallow turquoise water over sand with bright caustic light lines.
func caustics(_ c: Canvas, seed: Int32) {
    let k: Float = 1 / 140
    c.shade { x, y in
        let fx = Float(x) * k, fy = Float(y) * k * 1.2
        let wx = fbm(fx * 0.5, fy * 0.5, seed &+ 1), wy = fbm(fx * 0.5 + 3, fy * 0.5 + 8, seed &+ 2)
        let n1 = fbm(fx + 1.5 * wx, fy + 1.5 * wy, seed, 4)
        let lines = powf(1 - min(1, abs(n1 - 0.5) * 6), 6)
        let t = Float(y) / Float(H)
        var col = mix(rgb(0x3FC9D6), rgb(0x8EE0D2), t)
        col = mix(col, rgb(0xCDEBD8), smooth(0.6, 1, t) * 0.5 * fbm(fx * 0.3, fy * 0.3, seed &+ 5))   // sand showing through
        return mix(col, (0.95, 1, 1), lines * 0.75)
    }
}

/// Kraft paper with drawn instruments, notes and stars.
func instruments(_ c: Canvas, seed: Int32) {
    c.shade { x, y in
        let n = fbm(Float(x) / 250, Float(y) / 250, seed, 5), fiber = fbm(Float(x) / 4, Float(y) / 30, seed &+ 3, 2)
        return scale(mix(rgb(0xB98A5E), rgb(0xCFA276), n), 0.94 + 0.08 * fiber)
    }
    c.draw { ctx in
        ctx.setLineCap(.round); ctx.setLineJoin(.round)
        func keys(_ y: CGFloat) {                                                // a strip of piano keys across the screen
            ctx.setFillColor(cg((0.97, 0.97, 0.95))); ctx.fill(CGRect(x: -10, y: y, width: CGFloat(W) + 20, height: 170))
            ctx.setStrokeColor(cg((0.1, 0.1, 0.1))); ctx.setLineWidth(3)
            var x: CGFloat = -10; var k = 0
            while x < CGFloat(W) + 10 {
                ctx.move(to: CGPoint(x: x, y: y)); ctx.addLine(to: CGPoint(x: x, y: y + 170)); ctx.strokePath()
                if [0, 1, 3, 4, 5].contains(k % 7) { ctx.setFillColor(cg((0.08, 0.08, 0.08))); ctx.fill(CGRect(x: x + 34, y: y, width: 26, height: 105)) }
                x += 47; k += 1
            }
        }
        keys(-40); keys(CGFloat(H) - 130)
        // acoustic guitar, tilted
        ctx.saveGState(); ctx.translateBy(x: 330, y: 760); ctx.rotate(by: -0.95)
        ctx.setShadow(offset: CGSize(width: 10, height: 14), blur: 18, color: cg((0, 0, 0), 0.35))
        let body = CGMutablePath()
        body.addEllipse(in: CGRect(x: -150, y: -10, width: 300, height: 260)); body.addEllipse(in: CGRect(x: -115, y: -200, width: 230, height: 220))
        ctx.addPath(body); ctx.setFillColor(cg(rgb(0xE3A75A))); ctx.fillPath()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        ctx.addPath(body); ctx.setStrokeColor(cg(rgb(0x6A3A12))); ctx.setLineWidth(10); ctx.strokePath()
        ctx.setFillColor(cg(rgb(0x2A1608))); ctx.fillEllipse(in: CGRect(x: -45, y: -70, width: 90, height: 90))
        ctx.setFillColor(cg(rgb(0x5A3313))); ctx.fill(CGRect(x: -26, y: -640, width: 52, height: 560))
        ctx.fill(CGRect(x: -34, y: -760, width: 68, height: 130))
        ctx.setFillColor(cg(rgb(0x3A200A))); ctx.fill(CGRect(x: -55, y: 140, width: 110, height: 22))
        ctx.setStrokeColor(cg((0.95, 0.92, 0.85), 0.9)); ctx.setLineWidth(2)
        for k in 0..<6 { let x = -15 + CGFloat(k) * 6; ctx.move(to: CGPoint(x: x, y: 150)); ctx.addLine(to: CGPoint(x: x, y: -740)) }
        ctx.strokePath()
        ctx.restoreGState()
        // golden trumpet
        ctx.saveGState(); ctx.translateBy(x: 300, y: 1450); ctx.rotate(by: 1.25)
        let goldG = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [cg(rgb(0xFFE08A)), cg(rgb(0xC98A1E))] as CFArray, locations: [0, 1])!
        let horn = CGMutablePath()
        horn.addRoundedRect(in: CGRect(x: -260, y: -14, width: 360, height: 28), cornerWidth: 14, cornerHeight: 14)
        horn.move(to: CGPoint(x: 90, y: -12)); horn.addQuadCurve(to: CGPoint(x: 260, y: -90), control: CGPoint(x: 200, y: -15))
        horn.addLine(to: CGPoint(x: 260, y: 90)); horn.addQuadCurve(to: CGPoint(x: 90, y: 12), control: CGPoint(x: 200, y: 15)); horn.closeSubpath()
        horn.addRoundedRect(in: CGRect(x: -150, y: -90, width: 210, height: 60), cornerWidth: 30, cornerHeight: 30)
        for x in [-90.0, -50, -10] { horn.addRect(CGRect(x: x, y: -40, width: 26, height: 95)) }
        ctx.setShadow(offset: CGSize(width: 10, height: 14), blur: 18, color: cg((0, 0, 0), 0.35))
        ctx.addPath(horn); ctx.setFillColor(cg(rgb(0xE0A93A))); ctx.fillPath()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        ctx.addPath(horn); ctx.clip(); ctx.drawLinearGradient(goldG, start: CGPoint(x: 0, y: -90), end: CGPoint(x: 0, y: 90), options: [])
        ctx.resetClip(); ctx.addPath(horn); ctx.setStrokeColor(cg(rgb(0x7A4E0E))); ctx.setLineWidth(4); ctx.strokePath()
        ctx.restoreGState()
        // violin, small, bottom-left
        ctx.saveGState(); ctx.translateBy(x: 320, y: 2150); ctx.rotate(by: -1.1)
        let v = CGMutablePath()
        v.addEllipse(in: CGRect(x: -95, y: 0, width: 190, height: 160)); v.addEllipse(in: CGRect(x: -80, y: -140, width: 160, height: 150))
        ctx.setShadow(offset: CGSize(width: 8, height: 12), blur: 14, color: cg((0, 0, 0), 0.35))
        ctx.addPath(v); ctx.setFillColor(cg(rgb(0x8A3A14))); ctx.fillPath()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        ctx.setFillColor(cg(rgb(0x1A0E08))); ctx.fill(CGRect(x: -14, y: -380, width: 28, height: 260))
        ctx.setStrokeColor(cg(rgb(0x1A0E08))); ctx.setLineWidth(6)
        for sgn in [-1.0, 1.0] { ctx.move(to: CGPoint(x: 38 * sgn, y: -10)); ctx.addCurve(to: CGPoint(x: 38 * sgn, y: 90), control1: CGPoint(x: 60 * sgn, y: 20), control2: CGPoint(x: 16 * sgn, y: 60)) }
        ctx.strokePath()
        ctx.restoreGState()
        // gold notes and stars scattered on the right
        var r = Rand(s: UInt64(seed))
        let golds = [cg(rgb(0xF2C14E)), cg(rgb(0xE6A93A)), cg(rgb(0xFFD873))]
        for i in 0..<34 {
            let x = CGFloat(r.range(Double(W) * 0.5, Double(W) - 60)), y = CGFloat(r.range(220, Double(H) - 260))
            ctx.saveGState(); ctx.setShadow(offset: CGSize(width: 4, height: 6), blur: 6, color: cg((0, 0, 0), 0.3))
            if i % 3 == 0 {
                let s = CGFloat(r.range(26, 48)), p = CGMutablePath()
                for k in 0..<10 { let a = CGFloat(k) * .pi / 5 - .pi / 2, rr = k % 2 == 0 ? s : s * 0.45
                    k == 0 ? p.move(to: CGPoint(x: x + cos(a) * rr, y: y + sin(a) * rr)) : p.addLine(to: CGPoint(x: x + cos(a) * rr, y: y + sin(a) * rr)) }
                p.closeSubpath(); ctx.addPath(p); ctx.setFillColor(golds[i % 3]); ctx.fillPath()
            } else {
                symbol(ctx, ["♪", "♫", "♬", "♩", "𝄞"][i % 5], x, y, CGFloat(r.range(60, 120)), CGFloat(r.range(-0.4, 0.4)), golds[i % 3])
            }
            ctx.restoreGState()
        }
    }
}

// MARK: - catalogue

let all: [(String, (Canvas) -> Void)] = [
    ("dark-wood", { wood($0, dark: rgb(0x3A1E0E), light: rgb(0x9A6436), seed: 11) }),
    ("pink-clouds", { clouds($0, seed: 12) }),
    ("white-marble", { marbleStone($0, seed: 13) }),
    ("bricks", { bricks($0, seed: 14) }),
    ("purple-smoke", { smoke($0, seed: 15) }),
    ("sheet-music", { sheetMusic($0, seed: 16) }),
    ("underwater", { underwater($0, seed: 17) }),
    ("parchment", { parchment($0, seed: 18) }),
    ("nebula", { nebula($0, warm: rgb(0xFF6A1A), cool: rgb(0x1A7AD0), seed: 21) }),
    ("deep-space", { nebula($0, warm: rgb(0x1FB59A), cool: rgb(0x1A3FA8), seed: 22) }),
    ("coral-reef", { reef($0, seed: 23) }),
    ("city-skyline", { skyline($0, seed: 24) }),
    ("golden-bokeh", { bokeh($0, seed: 25) }),
    ("earth-orbit", { earth($0, seed: 26) }),
    ("holographic", { holo($0, seed: 27) }),
    ("black-gold", { blackGold($0, seed: 28) }),
    ("dragon-scales", { dragonScales($0, seed: 29) }),
    ("pixel-green", { pixels($0, seed: 30) }),
    ("color-blur", { colorBlur($0, seed: 32) }),
    ("water-caustics", { caustics($0, seed: 33) }),
    ("stage-lights", { stage($0, seed: 31) }),
    ("white-wood", { wood($0, dark: rgb(0xB9B3AA), light: rgb(0xF4F1EC), seed: 34, weathered: true) }),
    ("instruments", { instruments($0, seed: 35) }),
]

let args = Array(CommandLine.arguments.dropFirst())
let outDir = args.first ?? "art/backgrounds-drawn"
let wanted = Set(args.dropFirst())
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
for (i, (name, make)) in all.enumerated() where wanted.isEmpty || wanted.contains(name) {
    let start = Date(), c = Canvas()
    make(c)
    let path = String(format: "%@/%02d-%@.png", outDir, i + 1, name)
    c.save(path)
    print(String(format: "%@  (%.1fs)", path, Date().timeIntervalSince(start)))
}
