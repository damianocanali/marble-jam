// Makes the app icon and menu logo from the source art. Run from the repo root:
//   swift tools/icon_from_art.swift art/MarbleJam.png MarbleJam/Assets.xcassets/AppIcon.appiconset/AppIcon.png MarbleJam/Assets.xcassets/Logo.imageset/Logo.png
import CoreGraphics
import ImageIO
import Foundation
import UniformTypeIdentifiers
// Scales the source art to 1024x1024 and writes it with no alpha channel (App Store requirement for icons).
let a = CommandLine.arguments
let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil)!
let img = CGImageSourceCreateImageAtIndex(src, 0, nil)!
let n = 1024
let c = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
c.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)); c.fill(CGRect(x: 0, y: 0, width: n, height: n))
c.interpolationQuality = .high
c.draw(img, in: CGRect(x: 0, y: 0, width: n, height: n))
let out = c.makeImage()!
for path in a.dropFirst(2) {
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, out, nil); CGImageDestinationFinalize(d); print("wrote \(path)")
}
