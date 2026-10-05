// Makes the game's title image from art/Text.PNG, whose "transparent" background is really solid white.
// White connected to the edges, and small enclosed white holes (inside A, R, B), become transparent; the big white
// letter fills stay. Edge pixels next to the background become black with partial alpha, so there's no white fringe.
// Run from the repo root: swift tools/title_from_art.swift art/Text.PNG MarbleJam/Assets.xcassets/Title.imageset/Title.png
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil)!
let img = CGImageSourceCreateImageAtIndex(src, 0, nil)!
let w = img.width, h = img.height
let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
let p = ctx.data!.assumingMemoryBound(to: UInt8.self)
func lum(_ i: Int) -> Int { (Int(p[i * 4]) + Int(p[i * 4 + 1]) + Int(p[i * 4 + 2])) / 3 }

// 1. label the white regions; the background is white touching the border, or any small enclosed hole
var background = [Bool](repeating: false, count: w * h), seen = [Bool](repeating: false, count: w * h)
for start in 0..<(w * h) where !seen[start] && lum(start) > 200 {
    var region = [start], stack = [start], border = false
    seen[start] = true
    while let i = stack.popLast() {
        let x = i % w, y = i / w
        if x == 0 || y == 0 || x == w - 1 || y == h - 1 { border = true }
        for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
            let nx = x + dx, ny = y + dy
            guard nx >= 0, ny >= 0, nx < w, ny < h else { continue }
            let j = ny * w + nx
            if !seen[j] && lum(j) > 200 { seen[j] = true; stack.append(j); region.append(j) }
        }
    }
    if border || region.count < 1500 { for i in region { background[i] = true } }
}

// 2. distance (up to 3 px) to the background, to soften the outline's outer edge
var near = [Bool](repeating: false, count: w * h)
for i in 0..<(w * h) where background[i] {
    let x = i % w, y = i / w
    for dy in -2...2 { for dx in -2...2 {
        let nx = x + dx, ny = y + dy
        if nx >= 0, ny >= 0, nx < w, ny < h { near[ny * w + nx] = true }
    } }
}

// 3. write RGBA: background clear; grey edge pixels near it become black with alpha from darkness
var out = [UInt8](repeating: 0, count: w * h * 4)
var minX = w, minY = h, maxX = 0, maxY = 0
for i in 0..<(w * h) where !background[i] {
    let l = lum(i)
    if near[i] && l > 40 {
        let alpha = UInt8(max(0, min(255, 255 - l)))
        out[i * 4 + 3] = alpha                                         // black, premultiplied: rgb stay 0
    } else {
        out[i * 4] = p[i * 4]; out[i * 4 + 1] = p[i * 4 + 1]; out[i * 4 + 2] = p[i * 4 + 2]; out[i * 4 + 3] = 255
    }
    if out[i * 4 + 3] > 10 { let x = i % w, y = i / w; minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y) }
}

// 4. crop with a little padding and save
let pad = 6
minX = max(0, minX - pad); minY = max(0, minY - pad); maxX = min(w - 1, maxX + pad); maxY = min(h - 1, maxY + pad)
let full = CGContext(data: &out, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!.makeImage()!
// CGContext rows are stored top-down, so (minX, minY) is already in image (top-left) coordinates
let cropped = full.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))!
try? FileManager.default.createDirectory(atPath: (a[2] as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(d, cropped, nil); CGImageDestinationFinalize(d)
print("wrote \(a[2]) \(cropped.width)x\(cropped.height)")
