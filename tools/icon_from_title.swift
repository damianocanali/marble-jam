// Makes a stand-in app icon: a square crop of one of the artist's backgrounds with the MARBLE BEATS lettering on top
// (until the artist sends an everyday icon). Run from the repo root:
//   swift tools/icon_from_title.swift art/backgrounds-artist/38-moonlit-melody.jpg MarbleJam/Assets.xcassets/Title.imageset/Title.png MarbleJam/Assets.xcassets/AppIcon.appiconset/AppIcon.png 0.55 0.86 0.45
// Arguments after the output: where the square sits in the background (0 top … 1 bottom), lettering width, and its centre (0 top … 1 bottom).
import CoreGraphics; import Foundation; import ImageIO; import UniformTypeIdentifiers
let a = CommandLine.arguments
func load(_ p: String) -> CGImage { CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(URL(fileURLWithPath: p) as CFURL, nil)!, 0, nil)! }
let bg = load(a[1]), title = load(a[2]); let topF = Double(a[4])!, tw = Double(a[5])!, ty = Double(a[6])!
let n = 1024.0
let c = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
c.interpolationQuality = .high
// square crop of the background: full width, starting topF of the way down
let side = Double(bg.width), y0 = (Double(bg.height) - side) * topF
let crop = bg.cropping(to: CGRect(x: 0, y: y0, width: side, height: side))!
c.draw(crop, in: CGRect(x: 0, y: 0, width: n, height: n))
// a soft dark pool behind the lettering so it reads at home-screen size
let w = n * tw, h = w * Double(title.height) / Double(title.width), cy = n * (1 - ty)
let g = CGGradient(colorsSpace: nil, colors: [CGColor(gray: 0, alpha: 0.45), CGColor(gray: 0, alpha: 0)] as CFArray, locations: [0, 1])!
c.saveGState(); c.translateBy(x: n / 2, y: cy); c.scaleBy(x: 1, y: h / w)
c.drawRadialGradient(g, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: w * 0.62, options: [])
c.restoreGState()
c.draw(title, in: CGRect(x: (n - w) / 2, y: cy - h / 2, width: w, height: h))
let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[3]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(d, c.makeImage()!, nil); CGImageDestinationFinalize(d)
