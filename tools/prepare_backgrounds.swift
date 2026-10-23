// Turns the backgrounds into what the app bundles: the drawn ones in art/backgrounds-drawn (from tools/make_backgrounds.swift,
// kept out of git) and the artist's in art/backgrounds-artist (in git). Run from the repo root:  swift tools/prepare_backgrounds.swift
// Writes MarbleJamBackgrounds/: bg-NN.jpg, bg-NN-thumb.jpg and manifest.json. Files named "NN-some-name.png" become bg-NN, named
// "Some Name"; "NN-halloween-some-name.png" also belongs to that holiday. Numbers must be unique across both folders and never
// reused, since players' choices are saved by id. Within a holiday the artist's backgrounds come first (the default one).
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let srcDirs = ["art/backgrounds-drawn", "art/backgrounds-artist"], artistDir = "art/backgrounds-artist", outDir = "MarbleJamBackgrounds"
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

guard fm.fileExists(atPath: srcDirs[0]) else { print("no \(srcDirs[0]) folder (run tools/make_backgrounds.swift first): nothing to do"); exit(0) }
let art: [(dir: String, name: String)] = srcDirs.flatMap { dir in
    ((try? fm.contentsOfDirectory(atPath: dir)) ?? [])
        .filter { ["png", "jpg", "jpeg"].contains(($0 as NSString).pathExtension.lowercased()) && !$0.hasPrefix("preview") }
        .map { (dir: dir, name: $0) }
}.sorted { number($0.name) < number($1.name) }
for (k, a) in art.enumerated() where number(a.name) != k + 1 {
    print("background numbers must run 1, 2, 3... with no gaps or repeats: \(a.name) is number \(k + 1)"); exit(1)
}
try? fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)
for old in (try? fm.contentsOfDirectory(atPath: outDir)) ?? [] where old.hasPrefix("bg-") || old == "manifest.json" {
    try? fm.removeItem(atPath: outDir + "/" + old)
}

var manifest: [[String: Any]] = [], artistSeasonal: Set<String> = []
for (i, (dir, name)) in art.enumerated() {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: dir + "/" + name) as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { print("skipped \(name): not an image"); continue }
    let id = String(format: "bg-%02d", i + 1)
    let full = render(img, W, H)
    writeJPEG(full, "\(outDir)/\(id).jpg", quality: 0.82)
    writeJPEG(render(img, TW, TH), "\(outDir)/\(id)-thumb.jpg", quality: 0.8)
    let words = ((name as NSString).deletingPathExtension).split(separator: "-").drop { Int($0) != nil }
    let seasons: Set<Substring> = ["halloween", "thanksgiving", "christmas", "newyear", "valentines", "stpatricks", "easter", "muertos"]
    var parts = Array(words)
    let season = parts.first.flatMap { seasons.contains($0) ? String($0) : nil }
    if season != nil { parts.removeFirst() }
    let title = parts.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    var entry: [String: Any] = ["id": id, "name": title.isEmpty ? id : title, "image": "\(id).jpg", "thumb": "\(id)-thumb.jpg",
                                "luminance": (luminance(full) * 1000).rounded() / 1000]
    if let season { entry["season"] = season; if dir == artistDir { artistSeasonal.insert(id) } }
    manifest.append(entry)
    print("\(id)  <- \(name)")
}
manifest = manifest.filter { artistSeasonal.contains($0["id"] as! String) } + manifest.filter { !artistSeasonal.contains($0["id"] as! String) }
let json = try! JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
try! json.write(to: URL(fileURLWithPath: "\(outDir)/manifest.json"))
print("wrote \(manifest.count) backgrounds to \(outDir)/")
