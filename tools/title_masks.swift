// title_masks.swift — split the "MARBLE BEATS" lettering (flat greyscale art on a fake-transparent
// white background) into three coverage masks (shadow / outline / fill), enlarge them cleanly,
// and composite a truly transparent Title.png.
//
// Build & run (self-contained, no other files needed):
//   swiftc -O tools/title_masks.swift -o /tmp/title_masks      (from the repo root; it is too slow to run uncompiled)
//   /tmp/title_masks art/title/source.png art/title /tmp/Title-plain.png [debugDir]   then: swift tools/make_title.swift
//
// Model: every source pixel is a mix of four tones  b (background white), g (shadow grey),
// k (black outline + 3D extrusion), w (white letter fill), b+g+k+w = 1.
//  * pure pixels ("seeds"): white >= 240, black <= 20, grey = flat 150..222 patch (incl. the ~165
//    double-shadow overlaps, which are flattened into the single shadow tone)
//  * white regions: connected to the border = background; enclosed + touching shadow grey =
//    background sliver (transparent); enclosed by black only = letter fill
//  * transition pixels are unmixed as a 2-tone blend chosen from nearby seeds (white must be within
//    ~2 px, otherwise the light side is shadow grey; shadow-rim pixels with >= 4 grey neighbours are grey)
// Fields at source resolution: A = g+k+w (whole art), D = k+w (letter silhouette), F = w (fill), G = g.
// Each gets the same light Gaussian pre-blur (sigma 0.6 src px, env MB_BLUR overrides), is upscaled 3x
// (Lanczos-3) and re-thresholded at 0.5 with a ~1.25 px linear ramp measured along the local gradient,
// so edges keep their position and get uniform AA. Then specks/pinholes are removed.
// Masks (painted in this order, each "over" the previous):
//   shadow  = min(A, max(dilate(G, 4px), erode(D, 2px))) where hidden under opaque letter, and solved
//             exactly ((A - cover)/(1 - cover)) everywhere else, so the composite alpha == A
//   outline = D                                              (extends under the fill)
//   fill    = F

import CoreGraphics; import Foundation; import ImageIO; import UniformTypeIdentifiers

let SCALE = 3
let PAD = 12
let RAMP: Float = 1.25          // AA ramp width in output px
let SHADOW_GREY: Float = 205

// ---------- I/O ----------
func loadRGBA(_ path: String) -> (Int, Int, [UInt8]) {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("cannot read \(path)") }
    let w = img.width, h = img.height
    var buf = [UInt8](repeating: 0, count: w * h * 4)
    let ctx = CGContext(data: &buf, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
    return (w, h, buf)
}
func writePNG(_ path: String, _ img: CGImage) {
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, img, nil)
    if !CGImageDestinationFinalize(d) { fatalError("cannot write \(path)") }
}
func saveGray(_ path: String, _ w: Int, _ h: Int, _ f: [Float]) {
    var b = f.map { UInt8(max(0, min(255, ($0 * 255).rounded()))) }
    let prov = CGDataProvider(data: Data(bytes: &b, count: b.count) as CFData)!
    let img = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: w,
                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                      provider: prov, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    writePNG(path, img)
}
/// straight (non-premultiplied) RGBA
func saveRGBAStraight(_ path: String, _ w: Int, _ h: Int, _ px: [UInt8]) {
    var b = px
    let prov = CGDataProvider(data: Data(bytes: &b, count: b.count) as CFData)!
    let img = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                      provider: prov, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    writePNG(path, img)
}

let args = CommandLine.arguments
guard args.count >= 4 else { print("usage: title_masks <in.png> <maskDir> <Title.png> [debugDir]"); exit(2) }
let inPath = args[1], maskDir = args[2], titlePath = args[3]
let debugDir: String? = args.count > 4 ? args[4] : nil
try? FileManager.default.createDirectory(atPath: maskDir, withIntermediateDirectories: true)
if let d = debugDir { try? FileManager.default.createDirectory(atPath: d, withIntermediateDirectories: true) }

// ---------- 1. load, luminance, crop ----------
let (SW, SH, sbuf) = loadRGBA(inPath)
var minA: Int = 255
for i in 0..<SW * SH { minA = min(minA, Int(sbuf[i * 4 + 3])) }
print("source \(SW)x\(SH), min alpha \(minA)\(minA == 255 ? " (fully opaque: background is painted, not transparent)" : "")")
func lumAt(_ x: Int, _ y: Int) -> Float {
    let o = (y * SW + x) * 4
    return (Float(sbuf[o]) + Float(sbuf[o + 1]) + Float(sbuf[o + 2])) / 3
}
var bx0 = SW, by0 = SH, bx1 = -1, by1 = -1
for y in 0..<SH { for x in 0..<SW where lumAt(x, y) < 245 { bx0 = min(bx0, x); bx1 = max(bx1, x); by0 = min(by0, y); by1 = max(by1, y) } }
print("art bbox in source: x \(bx0)...\(bx1), y \(by0)...\(by1)  (\(bx1 - bx0 + 1)x\(by1 - by0 + 1) px)")
let M = 8
let cx0 = max(0, bx0 - M), cy0 = max(0, by0 - M), cx1 = min(SW - 1, bx1 + M), cy1 = min(SH - 1, by1 + M)
let W = cx1 - cx0 + 1, H = cy1 - cy0 + 1
var L = [Float](repeating: 255, count: W * H)
for y in 0..<H { for x in 0..<W { L[y * W + x] = lumAt(cx0 + x, cy0 + y) } }

// ---------- 2. seeds ----------
// 0 = transition, 1 = white, 2 = grey (shadow, incl. the darker double-shadow overlaps), 3 = black
var seed = [UInt8](repeating: 0, count: W * H)
for y in 0..<H { for x in 0..<W {
    let i = y * W + x, v = L[i]
    if v >= 240 { seed[i] = 1; continue }
    if v <= 20 { seed[i] = 3; continue }
    if v >= 150 && v <= 222 && x > 0 && y > 0 && x < W - 1 && y < H - 1 {
        var ok = true
        for dy in -1...1 { for dx in -1...1 { let u = L[(y + dy) * W + x + dx]; if u < 140 || u > 230 { ok = false } } }
        if ok { seed[i] = 2 }
    }
}}

// ---------- 3. white components: background vs letter fill ----------
var comp = [Int32](repeating: -1, count: W * H)
var compBorder: [Bool] = [], compSize: [Int] = [], compBox: [(Int, Int, Int, Int)] = []
for s in 0..<W * H where seed[s] == 1 && comp[s] < 0 {
    let id = Int32(compBorder.count); comp[s] = id
    var stack = [s], border = false, size = 0, x0 = W, y0 = H, x1 = 0, y1 = 0
    while let p = stack.popLast() {
        size += 1; let x = p % W, y = p / W
        x0 = min(x0, x); x1 = max(x1, x); y0 = min(y0, y); y1 = max(y1, y)
        if x == 0 || y == 0 || x == W - 1 || y == H - 1 { border = true }
        for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] where nx >= 0 && ny >= 0 && nx < W && ny < H {
            let q = ny * W + nx
            if seed[q] == 1 && comp[q] < 0 { comp[q] = id; stack.append(q) }
        }
    }
    compBorder.append(border); compSize.append(size); compBox.append((x0, y0, x1, y1))
}
let nComp = compBorder.count
// grey seeds within 3 px of an enclosed white component => it is background seen between a shadow
// and the next letter (letter fills are bounded only by black outline)
var nearGrey = [Int](repeating: 0, count: nComp), nearBlack = [Int](repeating: 0, count: nComp)
for y in 3..<H - 3 { for x in 3..<W - 3 {
    let i = y * W + x; if seed[i] != 2 && seed[i] != 3 { continue }
    var seen = Set<Int32>()
    for dy in -3...3 { for dx in -3...3 { let c = comp[(y + dy) * W + x + dx]; if c >= 0 { seen.insert(c) } } }
    for c in seen { if seed[i] == 2 { nearGrey[Int(c)] += 1 } else { nearBlack[Int(c)] += 1 } }
}}
var isFill = [Bool](repeating: false, count: nComp)
for c in 0..<nComp {
    if compBorder[c] { continue }
    isFill[c] = nearGrey[c] == 0
    let b = compBox[c]
    print(String(format: "  enclosed white region #%d  size %5d  src bbox (%d,%d)-(%d,%d)  grey nbrs %4d  black nbrs %4d  -> %@",
                 c, compSize[c], b.0 + cx0, b.1 + cy0, b.2 + cx0, b.3 + cy0, nearGrey[c], nearBlack[c],
                 isFill[c] ? "LETTER FILL" : "BACKGROUND sliver (transparent)"))
}

// ---------- 4. unmix every pixel into b,g,k,w ----------
let R = 4
var offs: [(Int, Int, Float)] = []
for dy in -R...R { for dx in -R...R { let d = Float(dx * dx + dy * dy).squareRoot(); if d <= Float(R) + 0.01 { offs.append((dx, dy, d)) } } }
offs.sort { $0.2 < $1.2 }
var fB = [Float](repeating: 0, count: W * H), fG = fB, fK = fB, fW = fB
for y in 0..<H { for x in 0..<W {
    let i = y * W + x, v = L[i]
    switch seed[i] {
    case 1: if isFill[Int(comp[i])] { fW[i] = 1 } else { fB[i] = 1 }; continue
    case 2: fG[i] = 1; continue
    case 3: fK[i] = 1; continue
    default: break
    }
    var dWb = Float.infinity, dWf = Float.infinity, dG = Float.infinity, dK = Float.infinity
    var gSum: Float = 0, gN: Float = 0
    for (dx, dy, d) in offs {
        let nx = x + dx, ny = y + dy; if nx < 0 || ny < 0 || nx >= W || ny >= H { continue }
        let q = ny * W + nx
        switch seed[q] {
        case 1: if isFill[Int(comp[q])] { dWf = min(dWf, d) } else { dWb = min(dWb, d) }
        case 2: dG = min(dG, d); if d <= 3 { gSum += L[q]; gN += 1 }
        case 3: dK = min(dK, d)
        default: break
        }
    }
    let gv: Float = gN > 0 ? gSum / gN : SHADOW_GREY
    let dW = min(dWb, dWf), whiteIsFill = dWf < dWb
    func addWhite(_ t: Float) { if whiteIsFill { fW[i] += t } else { fB[i] += t } }
    // an anti-aliased white/black or white/grey edge always has a white seed within ~2 px; without one
    // the light side can only be shadow grey (thin shadow wedges squeezed between black strokes)
    let nearW = dW <= 2.3
    // shadow plateau test: a pixel with >= 4 shadow-grey neighbours sits on the rim of a shadow region
    // (an anti-aliased white/black edge passes through grey values only along a 1 px line)
    var nGrey = 0
    for dy in -1...1 { for dx in -1...1 where dx != 0 || dy != 0 {
        let nx = x + dx, ny = y + dy
        if nx >= 0 && ny >= 0 && nx < W && ny < H { let u = L[ny * W + nx]; if u >= 185 && u <= 225 { nGrey += 1 } }
    }}
    let onShadowRim = v >= 185 && v <= 225 && nGrey >= 4
    if v >= gv {
        // light side must be white; dark side is grey or black, whichever seed is closer
        if !nearW { fG[i] = 1; continue }                           // grey (noise or lighter shadow), no white around
        if (dG.isFinite && dG <= dK) || onShadowRim { let t = max(0, min(1, (v - gv) / (255 - gv))); addWhite(t); fG[i] += 1 - t }
        else { let t = max(0, min(1, v / 255)); addWhite(t); fK[i] += 1 - t }
    } else {
        // dark side is black; light side is white if a white seed is right next to it (and closer than grey),
        // otherwise grey; a pixel with neither white nor black around is a darker shadow tone (double shadow)
        if nearW && dW < dG && !onShadowRim { let t = max(0, min(1, v / 255)); addWhite(t); fK[i] += 1 - t }
        else if dK.isInfinite { fG[i] = 1 }
        else { let t = max(0, min(1, v / gv)); fG[i] += t; fK[i] += 1 - t }
    }
}}
var srcA = [Float](repeating: 0, count: W * H), srcD = srcA, srcF = srcA, srcG = srcA
for i in 0..<W * H { srcA[i] = 1 - fB[i]; srcD[i] = fK[i] + fW[i]; srcF[i] = fW[i]; srcG[i] = fG[i] }

// ---------- 5. Lanczos-3 upscale ----------
let OW = W * SCALE, OH = H * SCALE
func lanczos(_ x: Float) -> Float {
    if x == 0 { return 1 }; if abs(x) >= 3 { return 0 }
    let px = Float.pi * x; return 3 * sin(px) * sin(px / 3) / (px * px)
}
// precompute taps per output coordinate (same for x and y since the factor is identical)
func taps(_ n: Int, _ on: Int) -> [[(Int, Float)]] {
    (0..<on).map { o in
        let s = (Float(o) + 0.5) / Float(SCALE) - 0.5, base = Int(floor(s))
        var t: [(Int, Float)] = []; var sum: Float = 0
        for j in (base - 2)...(base + 3) { let wgt = lanczos(s - Float(j)); t.append((min(max(j, 0), n - 1), wgt)); sum += wgt }
        return t.map { ($0.0, $0.1 / sum) }
    }
}
let tx = taps(W, OW), ty = taps(H, OH)
func upscale(_ f: [Float]) -> [Float] {
    var tmp = [Float](repeating: 0, count: OW * H)
    for y in 0..<H { for ox in 0..<OW { var s: Float = 0; for (j, w) in tx[ox] { s += f[y * W + j] * w }; tmp[y * OW + ox] = s } }
    var out = [Float](repeating: 0, count: OW * OH)
    for oy in 0..<OH { for ox in 0..<OW { var s: Float = 0; for (j, w) in ty[oy] { s += tmp[j * OW + ox] * w }; out[oy * OW + ox] = s } }
    return out
}
// re-threshold at 0.5: signed distance ≈ (v-0.5)/|∇v|, mapped through a RAMP-wide linear ramp
func rethreshold(_ v: [Float]) -> [Float] {
    var out = [Float](repeating: 0, count: OW * OH)
    for y in 0..<OH { for x in 0..<OW {
        let i = y * OW + x, c = v[i]
        let gx = (v[y * OW + min(x + 1, OW - 1)] - v[y * OW + max(x - 1, 0)]) / 2
        let gy = (v[min(y + 1, OH - 1) * OW + x] - v[max(y - 1, 0) * OW + x]) / 2
        let g = max((gx * gx + gy * gy).squareRoot(), 0.06)
        out[i] = max(0, min(1, 0.5 + (c - 0.5) / (g * RAMP)))
    }}
    return out
}

// ---------- 6. speck / pinhole cleanup on a thresholded mask ----------
func cleanup(_ m: inout [Float], name: String, minArea: Int, keepHole: (([Int]) -> Bool)? = nil) {
    for pass in 0..<2 {           // pass 0: remove small solid specks, pass 1: fill small holes
        var lab = [Int32](repeating: -1, count: OW * OH)
        var removed = 0
        for s in 0..<OW * OH where lab[s] < 0 && ((m[s] >= 0.5) == (pass == 0)) {
            var stack = [s], members: [Int] = []; lab[s] = 1; var touchesBorder = false
            while let p = stack.popLast() {
                members.append(p); let x = p % OW, y = p / OW
                if x == 0 || y == 0 || x == OW - 1 || y == OH - 1 { touchesBorder = true }
                for (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)] where nx >= 0 && ny >= 0 && nx < OW && ny < OH {
                    let q = ny * OW + nx
                    if lab[q] < 0 && ((m[q] >= 0.5) == (pass == 0)) { lab[q] = 1; stack.append(q) }
                }
            }
            if members.count < minArea && !(pass == 1 && touchesBorder) {
                if pass == 1, let keep = keepHole, keep(members) { continue }
                removed += 1
                let p0 = members[0]; print("    \(name): \(pass == 0 ? "speck" : "pinhole") of \(members.count) px at 3x (\(p0 % OW),\(p0 / OW)) = source (\(cx0 + (p0 % OW) / SCALE),\(cy0 + (p0 / OW) / SCALE))")
                // flatten the speck/hole and its AA rim
                for p in members { m[p] = pass == 0 ? 0 : 1 }
                for p in members { let x = p % OW, y = p / OW
                    for dy in -2...2 { for dx in -2...2 { let nx = x + dx, ny = y + dy
                        if nx >= 0 && ny >= 0 && nx < OW && ny < OH { let q = ny * OW + nx
                            if pass == 0 && m[q] < 0.5 { m[q] = 0 }; if pass == 1 && m[q] >= 0.5 { m[q] = 1 } } } } }
            }
        }
        if removed > 0 { print("  \(name): removed \(removed) \(pass == 0 ? "speck(s)" : "pinhole(s)") under \(minArea) px") }
    }
}
func morph(_ m: [Float], radius r: Int, dilate: Bool) -> [Float] {
    var ofs: [(Int, Int)] = []
    for dy in -r...r { for dx in -r...r where dx * dx + dy * dy <= r * r { ofs.append((dx, dy)) } }
    var out = m
    for y in 0..<OH { for x in 0..<OW {
        var v: Float = dilate ? 0 : 1
        for (dx, dy) in ofs {
            let nx = x + dx, ny = y + dy
            let s: Float = (nx < 0 || ny < 0 || nx >= OW || ny >= OH) ? 0 : m[ny * OW + nx]
            v = dilate ? max(v, s) : min(v, s)
        }
        out[y * OW + x] = v
    }}
    return out
}

print("upscaling \(W)x\(H) -> \(OW)x\(OH)")
// light Gaussian pre-blur (same kernel for every field, so edges shared by two fields stay shared):
// smooths the few-pixel jaggies the unmix leaves where three tones meet
let PREBLUR: Float = Float(ProcessInfo.processInfo.environment["MB_BLUR"] ?? "") ?? 0.6
func blur(_ f: [Float]) -> [Float] {
    if PREBLUR <= 0 { return f }
    let r = Int(ceil(PREBLUR * 3)); var k = (-r...r).map { exp(-Float($0 * $0) / (2 * PREBLUR * PREBLUR)) }
    let ks = k.reduce(0, +); k = k.map { $0 / ks }
    var t = f, o = f
    for y in 0..<H { for x in 0..<W { var s: Float = 0; for j in -r...r { s += f[y * W + min(max(x + j, 0), W - 1)] * k[j + r] }; t[y * W + x] = s } }
    for y in 0..<H { for x in 0..<W { var s: Float = 0; for j in -r...r { s += t[min(max(y + j, 0), H - 1) * W + x] * k[j + r] }; o[y * W + x] = s } }
    return o
}
print("pre-blur sigma \(PREBLUR) source px")
let upA = upscale(blur(srcA)), upD = upscale(blur(srcD)), upF = upscale(blur(srcF)), upG = upscale(blur(srcG))
var hA = rethreshold(upA), hD = rethreshold(upD), hF = rethreshold(upF), hG = rethreshold(upG)
let minArea = 9 * SCALE * SCALE   // ~3x3 source px
cleanup(&hG, name: "shadow(visible)", minArea: 2 * SCALE * SCALE)
cleanup(&hA, name: "art", minArea: minArea)
// a hole in the letter silhouette is real art when shadow shows through it (tiny shadow wedges in counters)
cleanup(&hD, name: "outline", minArea: minArea, keepHole: { ms in ms.reduce(Float(0)) { $0 + hG[$1] } > 0.5 * Float(ms.count) })
cleanup(&hF, name: "fill", minArea: minArea)

// nesting: F ⊆ D ⊆ A
var mFill = [Float](repeating: 0, count: OW * OH), mOutline = mFill, mShadow = mFill
for i in 0..<OW * OH {
    mFill[i] = min(hF[i], hD[i] >= 0.999 ? 1 : hF[i])
    mOutline[i] = max(hD[i], mFill[i])
    hA[i] = max(hA[i], mOutline[i])
}
let gDil = morph(hG, radius: 4, dilate: true), dEro = morph(mOutline, radius: 2, dilate: false)
for i in 0..<OW * OH {
    mShadow[i] = min(hA[i], max(gDil[i], dEro[i]))
    // wherever the shadow is not hidden under opaque letter, solve for it exactly so the composite covers
    // exactly the art silhouette (fixes few-pixel notches/bulges at corners where the art edge switches
    // from letter edge to shadow edge)
    let cO = mFill[i] + (1 - mFill[i]) * mOutline[i]
    if cO < 0.999 { mShadow[i] = max(0, min(1, (hA[i] - cO) / (1 - cO))) }
}

// ---------- 7. verify the composite against the art silhouette ----------
var compA = [Float](repeating: 0, count: OW * OH)
var maxAErr: Float = 0, sumAErr: Float = 0, badA = 0, fillTouchesBg = 0
for i in 0..<OW * OH {
    let f = mFill[i], o = mOutline[i], s = mShadow[i]
    compA[i] = f + (1 - f) * (o + (1 - o) * s)
    let e = abs(compA[i] - hA[i]); maxAErr = max(maxAErr, e); sumAErr += e; if e > 0.1 { badA += 1 }
    if f > 0.02 && o < 0.98 { fillTouchesBg += 1 }
}
func reportClusters(_ flag: [Bool], _ what: String) {
    var seen = [Bool](repeating: false, count: OW * OH)
    for st in 0..<OW * OH where flag[st] && !seen[st] {
        var stack = [st]; seen[st] = true; var n = 0, x0 = OW, y0 = OH, x1 = 0, y1 = 0
        while let p = stack.popLast() { n += 1; let x = p % OW, y = p / OW
            x0 = min(x0, x); x1 = max(x1, x); y0 = min(y0, y); y1 = max(y1, y)
            for dy in -2...2 { for dx in -2...2 { let nx = x + dx, ny = y + dy
                if nx >= 0 && ny >= 0 && nx < OW && ny < OH && flag[ny * OW + nx] && !seen[ny * OW + nx] { seen[ny * OW + nx] = true; stack.append(ny * OW + nx) } } } }
        print("    \(what): \(n) px around source (\(cx0 + x0 / SCALE)...\(cx0 + x1 / SCALE), \(cy0 + y0 / SCALE)...\(cy0 + y1 / SCALE))")
    }
}
reportClusters((0..<OW * OH).map { abs(compA[$0] - hA[$0]) > 0.1 }, "alpha mismatch")
reportClusters((0..<OW * OH).map { mFill[$0] > 0.02 && mOutline[$0] < 0.98 }, "fill not backed by outline")
print(String(format: "composite alpha vs art silhouette: max err %.3f, mean err %.5f, px with err>0.1: %d; fill px not backed by outline: %d",
             maxAErr, sumAErr / Float(OW * OH), badA, fillTouchesBg))

// ---------- 8. trim ----------
var tx0 = OW, ty0 = OH, tx1 = -1, ty1 = -1
for y in 0..<OH { for x in 0..<OW where compA[y * OW + x] > 0.5 / 255 { tx0 = min(tx0, x); tx1 = max(tx1, x); ty0 = min(ty0, y); ty1 = max(ty1, y) } }
let TW = tx1 - tx0 + 1 + 2 * PAD, TH = ty1 - ty0 + 1 + 2 * PAD
func trimmed(_ m: [Float]) -> [Float] {
    var out = [Float](repeating: 0, count: TW * TH)
    for y in 0..<TH { for x in 0..<TW {
        let sx = x - PAD + tx0, sy = y - PAD + ty0
        if sx >= 0 && sy >= 0 && sx < OW && sy < OH { out[y * TW + x] = m[sy * OW + sx] }
    }}
    return out
}
let tFill = trimmed(mFill), tOutline = trimmed(mOutline), tShadow = trimmed(mShadow)
// quantise exactly as written, then composite from the 8-bit masks so Title.png == masks composite
func q8(_ m: [Float]) -> [Float] { m.map { Float(UInt8(max(0, min(255, ($0 * 255).rounded())))) / 255 } }
let qF = q8(tFill), qO = q8(tOutline), qS = q8(tShadow)
saveGray(maskDir + "/fill.png", TW, TH, qF)
saveGray(maskDir + "/outline.png", TW, TH, qO)
saveGray(maskDir + "/shadow.png", TW, TH, qS)

var px = [UInt8](repeating: 0, count: TW * TH * 4)
for i in 0..<TW * TH {
    let f = qF[i], o = qO[i], s = qS[i]
    let wF = f, wO = (1 - f) * o, wS = (1 - f) * (1 - o) * s
    let a = wF + wO + wS
    if a <= 0 { continue }
    let lum = (wF * 255 + wO * 0 + wS * SHADOW_GREY) / a       // straight colour = colour of the art underneath
    let l8 = UInt8(max(0, min(255, lum.rounded())))
    px[i * 4] = l8; px[i * 4 + 1] = l8; px[i * 4 + 2] = l8
    px[i * 4 + 3] = UInt8(max(0, min(255, (a * 255).rounded())))
}
saveRGBAStraight(titlePath, TW, TH, px)
print("output \(TW)x\(TH) px (lettering \(tx1 - tx0 + 1)x\(ty1 - ty0 + 1) px + \(PAD) px padding), source crop offset (\(cx0),\(cy0)), trim offset (\(tx0),\(ty0)) in \(SCALE)x space")

// ---------- 9. debug: reference upscale of the source + error map ----------
if let dd = debugDir {
    saveGray(dd + "/src_A.png", W, H, srcA); saveGray(dd + "/src_D.png", W, H, srcD)
    saveGray(dd + "/src_F.png", W, H, srcF); saveGray(dd + "/src_G.png", W, H, srcG)
    var seedImg = [Float](repeating: 0, count: W * H)
    for i in 0..<W * H { seedImg[i] = [0.5, 1, 0.75, 0][Int(seed[i])] }
    saveGray(dd + "/seeds.png", W, H, seedImg)
    let refL = trimmed(upscale(L.map { $0 / 255 }))
    var err = [Float](repeating: 0, count: TW * TH), big = 0
    for i in 0..<TW * TH {
        let f = qF[i], o = qO[i], s = qS[i]
        let onWhite = f + (1 - f) * ((1 - o) * (s * SHADOW_GREY / 255 + (1 - s)))
        err[i] = abs(onWhite - refL[i]); if err[i] > 0.25 { big += 1 }
    }
    saveGray(dd + "/err.png", TW, TH, err.map { min(1, $0 * 2) })
    print("debug: px whose composite-on-white differs from the plain-upscaled source by >25%: \(big) (edge sharpening + flattened double-shadow)")
}
