// Cuts holiday artwork out of its white background into a transparent PNG.
// White that touches the edges (through other near-white, grey pixels) is background: pure white becomes clear, and grey
// shadows on it become see-through black, so they still read as shadows on dark screens. White inside the art (a ghost,
// a beard, the middle of a wreath) is not connected to the edges through background, so it stays.
// Run from the repo root:
//   swift tools/cutout_from_art.swift <input> <output.png> [x y width height] [lightest] [holes]
//   optional crop in source pixels (top-left origin); `lightest` (default 150) is the darkest grey still treated as background:
//   raise it (e.g. 225) for art with pale parts that touch the page, like a ghost, so only near-white is removed.
//   `holes` (default 0): enclosed patches of pure white smaller than this many pixels are cleared too (gaps between letters).
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
let lightest = a.count >= 8 ? Int(a[7])! : 150
let holes = a.count >= 9 ? Int(a[8])! : 0
let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil)!
var img = CGImageSourceCreateImageAtIndex(src, 0, nil)!
if a.count >= 7, let x = Int(a[3]), let y = Int(a[4]), let w = Int(a[5]), let h = Int(a[6]) {
    img = img.cropping(to: CGRect(x: x, y: y, width: w, height: h))!
}
let w = img.width, h = img.height
let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
let p = ctx.data!.assumingMemoryBound(to: UInt8.self)

func lum(_ i: Int) -> Int { (Int(p[i * 4]) * 3 + Int(p[i * 4 + 1]) * 6 + Int(p[i * 4 + 2])) / 10 }
/// Light and colourless: the white page or a soft grey shadow on it.
func backgroundLike(_ i: Int) -> Bool {
    let mx = Int(max(p[i * 4], p[i * 4 + 1], p[i * 4 + 2])), mn = Int(min(p[i * 4], p[i * 4 + 1], p[i * 4 + 2]))
    return lum(i) >= lightest && mx - mn <= 28
}

// 1. flood from every edge pixel through background-like pixels
var background = [Bool](repeating: false, count: w * h)
var stack: [Int] = []
for x in 0..<w { stack.append(x); stack.append((h - 1) * w + x) }
for y in 0..<h { stack.append(y * w); stack.append(y * w + w - 1) }
while let i = stack.popLast() {
    if background[i] || !backgroundLike(i) { continue }
    background[i] = true
    let x = i % w, y = i / w
    if x > 0 { stack.append(i - 1) }
    if x < w - 1 { stack.append(i + 1) }
    if y > 0 { stack.append(i - w) }
    if y < h - 1 { stack.append(i + w) }
}

// 1b. small enclosed patches of pure white (gaps the edge flood can't reach) count as background too
if holes > 0 {
    var seen = background
    for start in 0..<(w * h) where !seen[start] && lum(start) >= 245 {
        var region = [start], todo = [start]; seen[start] = true
        while let i = todo.popLast() {
            let x = i % w, y = i / w
            for j in [x > 0 ? i - 1 : -1, x < w - 1 ? i + 1 : -1, y > 0 ? i - w : -1, y < h - 1 ? i + w : -1] where j >= 0 && !seen[j] && lum(j) >= 245 {
                seen[j] = true; todo.append(j); region.append(j)
            }
        }
        if region.count < holes { for i in region { background[i] = true } }
    }
}

// 2. background: white → clear, grey → see-through black (premultiplied, so colour channels are 0)
var minX = w, minY = h, maxX = 0, maxY = 0
for i in 0..<(w * h) {
    if background[i] {
        let alpha = max(0, 245 - lum(i)) * 255 / 245
        p[i * 4] = 0; p[i * 4 + 1] = 0; p[i * 4 + 2] = 0; p[i * 4 + 3] = UInt8(min(255, alpha))
    }
    if p[i * 4 + 3] > 12 { let x = i % w, y = i / w; minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y) }
}

// 3. crop to what is left, with a little room, and save
let pad = 8
minX = max(0, minX - pad); minY = max(0, minY - pad); maxX = min(w - 1, maxX + pad); maxY = min(h - 1, maxY + pad)
let out = ctx.makeImage()!.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))!
try? FileManager.default.createDirectory(atPath: (a[2] as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(d, out, nil); CGImageDestinationFinalize(d)
print("wrote \(a[2]) \(out.width)x\(out.height)")
