// Turns the drawn backgrounds in art/backgrounds-drawn (from tools/make_backgrounds.swift) into what the app bundles.
// Run from the repo root after redrawing:  swift tools/prepare_backgrounds.swift
// Writes MarbleJamBackgrounds/: bg-NN.jpg, bg-NN-thumb.jpg and manifest.json. Files named "NN-some-name.png" get the name "Some Name".
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let srcDir = "art/backgrounds-drawn", outDir = "MarbleJamBackgrounds"
let W = 1170, H = 2532                 // iPhone screen in pixels; the art is scaled to fill and the sides trimmed
let TW = 240, TH = 520                 // thumbnail for the picker
let fm = FileManager.default

/// "03-white-marble.png" -> 3, for sorting.
func number(_ name: String) -> Int { Int(name.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 1 }

func render(_ img: CGImage, _ w: Int, _ h: Int) -> CGImage {
    let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)); c.fill(CGRect(x: 0, y: 0, width: w, height: h))
    let s = max(Double(w) / Double(img.width), Double(h) / Double(img.height))
    let dw = Double(img.width) * s, dh = Double(img.height) * s
    c.interpolationQuality = .high
    c.draw(img, in: CGRect(x: (Double(w) - dw) / 2, y: (Double(h) - dh) / 2, width: dw, height: dh))
    return c.makeImage()!
}

/// Average brightness 0...1 of a small copy.
func luminance(_ img: CGImage) -> Double {
    let n = 32, c = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: n * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.draw(img, in: CGRect(x: 0, y: 0, width: n, height: n))
    let p = c.data!.assumingMemoryBound(to: UInt8.self)
    var sum = 0.0
    for i in 0..<(n * n) { sum += 0.2126 * Double(p[i * 4]) + 0.7152 * Double(p[i * 4 + 1]) + 0.0722 * Double(p[i * 4 + 2]) }
    return sum / Double(n * n) / 255
}

func writeJPEG(_ img: CGImage, _ path: String, quality: Double) {
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, img, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
    CGImageDestinationFinalize(d)
}

guard let names = try? fm.contentsOfDirectory(atPath: srcDir) else { print("no \(srcDir) folder: nothing to do"); exit(0) }
let art = names.filter { ["png", "jpg", "jpeg"].contains(($0 as NSString).pathExtension.lowercased()) && !$0.hasPrefix("preview") }.sorted { number($0) < number($1) }
try? fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)
for old in (try? fm.contentsOfDirectory(atPath: outDir)) ?? [] where old.hasPrefix("bg-") || old == "manifest.json" {
    try? fm.removeItem(atPath: outDir + "/" + old)
}

var manifest: [[String: Any]] = []
for (i, name) in art.enumerated() {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: srcDir + "/" + name) as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { print("skipped \(name): not an image"); continue }
    let id = String(format: "bg-%02d", i + 1)
    let full = render(img, W, H)
    writeJPEG(full, "\(outDir)/\(id).jpg", quality: 0.82)
    writeJPEG(render(img, TW, TH), "\(outDir)/\(id)-thumb.jpg", quality: 0.8)
    let words = ((name as NSString).deletingPathExtension).split(separator: "-").drop { Int($0) != nil }
    let seasons: Set<Substring> = ["halloween", "thanksgiving", "christmas"]
    var parts = Array(words)
    let season = parts.first.flatMap { seasons.contains($0) ? String($0) : nil }
    if season != nil { parts.removeFirst() }
    let title = parts.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    var entry: [String: Any] = ["id": id, "name": title.isEmpty ? id : title, "image": "\(id).jpg", "thumb": "\(id)-thumb.jpg",
                                "luminance": (luminance(full) * 1000).rounded() / 1000]
    if let season { entry["season"] = season }
    manifest.append(entry)
    print("\(id)  <- \(name)")
}
let json = try! JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
try! json.write(to: URL(fileURLWithPath: "\(outDir)/manifest.json"))
print("wrote \(manifest.count) backgrounds to \(outDir)/")
