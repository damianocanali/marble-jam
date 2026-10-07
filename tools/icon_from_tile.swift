// Makes an app icon from a picture of an icon tile (a rounded square shown on some other background, e.g. a mockup).
// Crops the square, paints the four rounded-off corners with the tile's own colour (iOS rounds icons itself, so the
// icon must be full-bleed), scales to 1024 x 1024 and writes an opaque PNG.
// Run from the repo root:
//   swift tools/icon_from_tile.swift <input> <output.png> <x> <y> <size> <corner colour, hex e.g. FFFFFF>
import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
let x = Double(a[3])!, y = Double(a[4])!, side = Double(a[5])!
let hex = UInt32(a[6], radix: 16)!
let fill = CGColor(srgbRed: CGFloat(hex >> 16 & 255) / 255, green: CGFloat(hex >> 8 & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)

let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil)!
let tile = CGImageSourceCreateImageAtIndex(src, 0, nil)!.cropping(to: CGRect(x: x, y: y, width: side, height: side))!   // top-left origin

let n = 1024
let c = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
c.setFillColor(fill); c.fill(CGRect(x: 0, y: 0, width: n, height: n))
let r = CGFloat(n) * 0.2                                        // a little inside the tile's own rounding, so no old background shows
c.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: n, height: n), cornerWidth: r, cornerHeight: r, transform: nil)); c.clip()
c.interpolationQuality = .high
c.draw(tile, in: CGRect(x: 0, y: 0, width: n, height: n))
let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(d, c.makeImage()!, nil); CGImageDestinationFinalize(d)
print("wrote \(a[2]) \(n)x\(n)")
