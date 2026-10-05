// Makes the app icon from art/Logo.JPG: crops inside its drawn frame, upscales to 1024 and writes an opaque PNG.
// Run from the repo root: swift tools/icon_from_logo.swift art/Logo.JPG MarbleJam/Assets.xcassets/AppIcon.appiconset/AppIcon.png 20
// (art/Logo.JPG is kept out of git; the last argument is the frame inset in source pixels.)
import CoreGraphics
import CoreImage
import ImageIO
import Foundation
import UniformTypeIdentifiers
// Crops inside the drawn frame of art/Logo.JPG, upscales to 1024 (Lanczos) and writes an opaque PNG.
let a = CommandLine.arguments, inset = Double(a[3])!
let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil)!
let img = CIImage(cgImage: CGImageSourceCreateImageAtIndex(src, 0, nil)!)
let side = img.extent.width - 2 * inset
let cropped = img.cropped(to: CGRect(x: inset, y: inset, width: side, height: side)).transformed(by: CGAffineTransform(translationX: -inset, y: -inset))
let f = CIFilter(name: "CILanczosScaleTransform")!
f.setValue(cropped, forKey: kCIInputImageKey); f.setValue(1024 / side, forKey: kCIInputScaleKey); f.setValue(1, forKey: kCIInputAspectRatioKey)
let ci = CIContext()
let scaled = ci.createCGImage(f.outputImage!, from: CGRect(x: 0, y: 0, width: 1024, height: 1024))!
let c = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
c.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)); c.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
c.draw(scaled, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(d, c.makeImage()!, nil); CGImageDestinationFinalize(d); print("wrote \(a[2])")
