// Makes a rounded "card" from artwork that is meant to keep its own background (e.g. a patterned page that can't be
// cut out cleanly): crops a rectangle, rounds its corners (transparent outside) and writes a PNG.
// Run from the repo root:
//   swift tools/card_from_art.swift <input> <output.png> <x> <y> <width> <height> [corner radius, default 48]
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
let rect = CGRect(x: Double(a[3])!, y: Double(a[4])!, width: Double(a[5])!, height: Double(a[6])!)
let radius = a.count >= 8 ? CGFloat(Double(a[7])!) : 48
let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil)!
let art = CGImageSourceCreateImageAtIndex(src, 0, nil)!.cropping(to: rect)!            // top-left origin
let w = art.width, h = art.height
let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
c.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: w, height: h), cornerWidth: radius, cornerHeight: radius, transform: nil)); c.clip()
c.draw(art, in: CGRect(x: 0, y: 0, width: w, height: h))
let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(d, c.makeImage()!, nil); CGImageDestinationFinalize(d)
print("wrote \(a[2]) \(w)x\(h)")
