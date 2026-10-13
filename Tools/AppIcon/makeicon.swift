// Regenerates The Last Rail/Assets.xcassets/AppIcon.appiconset/icon_1024.png (opaque RGB, no alpha).
// Usage: xcrun swiftc -O Tools/AppIcon/makeicon.swift -o /tmp/makeicon && /tmp/makeicon "The Last Rail/Assets.xcassets/AppIcon.appiconset/icon_1024.png"

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// 32x32 pixel-art app icon for The Last Rail, drawn with the game's palette.
let N = 64
var px = [UInt32](repeating: 0, count: N * N)

func set(_ x: Int, _ y: Int, _ c: UInt32) { if x >= 0, x < N, y >= 0, y < N { px[y * N + x] = c } }
func get(_ x: Int, _ y: Int) -> UInt32 { px[y * N + x] }
func rect(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ c: UInt32) { for y in y0...y1 { for x in x0...x1 { set(x, y, c) } } }
func hline(_ x0: Int, _ x1: Int, _ y: Int, _ c: UInt32) { rect(x0, y, x1, y, c) }
func disc(_ cx: Double, _ cy: Double, _ r: Double, _ c: UInt32) {
    for y in 0..<N { for x in 0..<N {
        let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
        if dx * dx + dy * dy <= r * r { set(x, y, c) }
    } }
}
func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
    func ch(_ v: UInt32, _ s: UInt32) -> Double { Double((v >> s) & 0xFF) }
    func m(_ s: UInt32) -> UInt32 { UInt32((ch(a, s) * (1 - t) + ch(b, s) * t).rounded()) << s }
    return m(16) | m(8) | m(0)
}

// Palette (from Pal / ascii palette in the game)
let outline: UInt32 = 0x1A1418
let cream: UInt32 = 0xF0E6C8
let amber: UInt32 = 0xE0A040
let amberLight: UInt32 = 0xF0C060
let red: UInt32 = 0xB0402F, redLight: UInt32 = 0xD0603A, redDark: UInt32 = 0x7A2C24
let iron: UInt32 = 0x3A3A40, ironLight: UInt32 = 0x5A5A62, steel: UInt32 = 0xB0B0B8, gray: UInt32 = 0x8A8A90

// 1. Sky gradient, night to a faint ember horizon
for y in 0..<N {
    let t = min(1.0, Double(y) / 44.0)
    let c = t < 0.6 ? mix(0x12152A, 0x2A2846, t / 0.6) : mix(0x2A2846, 0x7A4844, (t - 0.6) / 0.4)
    hline(0, N - 1, y, c)
}

// 2. Stars
for (x, y) in [(4, 4), (22, 17), (8, 22), (2, 31), (56, 30), (61, 4), (30, 18), (14, 2), (45, 3)] { set(x, y, 0xC8C4B4) }
for (x, y) in [(5, 16), (60, 24)] { set(x, y, cream); set(x - 1, y, 0x6A6880); set(x + 1, y, 0x6A6880); set(x, y - 1, 0x6A6880); set(x, y + 1, 0x6A6880) }

// 3. Moon (upper right) with soft halo
disc(52, 11, 10.5, 0x262848)
disc(52, 11, 8.5, 0x302F52)
disc(52, 11, 6.8, cream)
disc(50, 9, 1.6, 0xDDD2B0); disc(55, 13, 1.3, 0xDDD2B0); disc(53, 7, 0.9, 0xE4DABC); disc(49.5, 14, 0.9, 0xE4DABC)

// 4. Far mountains with snow caps
var ridge = [Int](repeating: 44, count: N)
for x in 0..<N {
    let peaks: [(Double, Double)] = [(6, 31), (19, 35), (33, 30), (47, 33), (60, 29)]
    var top = 44.0
    for (px0, py) in peaks { top = min(top, py + abs(Double(x) - px0) * 0.9) }
    ridge[x] = Int(top)
}
for x in 0..<N {
    for y in ridge[x]...45 { set(x, y, y > 39 ? 0x2A2C46 : 0x33354F) }
    if ridge[x] <= 33 { set(x, ridge[x], 0xA8B0C6); set(x, ridge[x] + 1, 0x7E88A4) }
}

// 5. Pine silhouettes
func pine(_ cx: Int, _ top: Int, _ base: Int, _ c: UInt32) {
    for y in top...base { let w = (y - top) / 2; hline(cx - w, cx + w, y, c) }
}
pine(3, 32, 46, 0x1A2A26); pine(58, 34, 46, 0x1A2A26); pine(62, 31, 46, 0x1E302A)

// 6. Ground, ballast, sleepers, rails
rect(0, 46, N - 1, N - 1, 0x1E1C22)
for x in stride(from: 0, to: N, by: 6) { rect(x, 54, x + 3, 55, 0x4A3424); hline(x, x + 3, 54, 0x5E4430) }
hline(0, N - 1, 51, 0xD0D0D8); hline(0, N - 1, 52, steel); hline(0, N - 1, 53, gray)
for x in 0..<N { if (x * 7) % 11 == 0 { set(x, 58, 0x2E2A30) }; if (x * 5) % 13 == 2 { set(x, 61, 0x2C282E) } }

// 7. Exhaust plume drifting back from the stack
let puffs: [(Double, Double, Double, UInt32)] = [(13, 8, 4.4, 0x5A5A6C), (22, 7.5, 4.8, 0x72728A), (31, 10.5, 3.9, 0x8A8A9C), (38, 15, 2.9, 0xA0A0AE)]
for (cx, cy, r, c) in puffs { disc(cx, cy, r + 0.8, mix(c, 0x12152A, 0.55)) }
for (cx, cy, r, c) in puffs { disc(cx, cy, r, c); disc(cx - r * 0.35, cy - r * 0.35, r * 0.45, mix(c, 0xFFFFFF, 0.22)) }

// 8. Lok 7, the game's red diesel locomotive (cab at the rear, long hood, yellow nose), facing right
let body: UInt32 = 0xA8442F, bodyLight: UInt32 = 0xC85A3A, bodyDark: UInt32 = 0x6E2A22, gold: UInt32 = 0xD0A840
// Cab
rect(3, 17, 22, 19, outline); hline(4, 21, 18, ironLight)
rect(4, 20, 21, 45, outline); rect(5, 20, 20, 44, body); rect(5, 20, 20, 21, bodyLight); rect(19, 22, 20, 44, bodyDark)
rect(7, 24, 17, 31, outline); rect(8, 25, 16, 30, amberLight); rect(8, 25, 11, 26, 0xFFE8A8)
// Number plate "7"
rect(8, 34, 14, 41, 0x2A2A2A); hline(9, 13, 35, amberLight); set(13, 36, amberLight); set(12, 37, amberLight); set(12, 38, amberLight); set(11, 39, amberLight); set(11, 40, amberLight)
// Hood
rect(20, 27, 51, 45, outline); rect(21, 28, 50, 44, body)
hline(21, 50, 28, bodyLight); hline(21, 50, 29, bodyLight)
for x in stride(from: 24, through: 46, by: 4) { rect(x, 32, x, 37, bodyDark); rect(x + 1, 32, x + 1, 37, 0x4A1E16) }
hline(21, 50, 43, bodyDark); hline(21, 50, 44, bodyDark)
// Gold stripe along cab and hood
hline(5, 50, 40, gold); hline(5, 50, 41, 0xA07E30)
// Handrail
hline(21, 50, 25, 0x9A9AA2); for x in [22, 32, 42, 50] { set(x, 26, 0x9A9AA2) }
// Exhaust stack
rect(37, 20, 42, 27, outline); rect(38, 21, 41, 27, iron); hline(38, 41, 21, ironLight)
// Nose with warning stripes and headlamp
rect(50, 29, 55, 45, outline); rect(51, 30, 54, 44, gold)
for y in stride(from: 32, through: 43, by: 3) { hline(51, 54, y, 0x2A2A2A) }
rect(52, 30, 57, 35, outline); rect(53, 31, 56, 34, 0xFFF4C8); rect(54, 32, 55, 33, 0xFFFFFF)
for x in 58..<N {
    let spread = Double(x - 57) * 0.6
    for y in Int(32.5 - spread)...Int(32.5 + spread) where y >= 0 && y < 46 {
        let edge = abs(Double(y) - 32.5) / max(spread, 1)
        let a = max(0, 0.85 - Double(x - 58) * 0.06) * (1 - edge * 0.55)
        set(x, y, mix(get(x, y), 0xF6D888, a))
    }
}
// Underframe, buffers
rect(3, 45, 56, 47, outline); hline(4, 55, 46, 0x2E2E34)
rect(1, 44, 2, 46, 0x2A2A2A); rect(57, 44, 58, 46, 0x2A2A2A)
// Bogies and wheels
func wheel(_ cx: Double, _ cy: Double, _ r: Double) {
    disc(cx, cy, r + 0.9, outline)
    disc(cx, cy, r, 0x3A3A40)
    disc(cx, cy, r - 1.2, 0x2A2A30)
    let ix = Int(cx), iy = Int(cy)
    for d in -Int(r - 1)...Int(r - 1) { set(ix + d, iy, 0x6A6A72); set(ix, iy + d, 0x6A6A72) }
    disc(cx + 0.5, cy + 0.5, 1.1, 0x9A9AA2)
}
for bx in [14.0, 43.0] { rect(Int(bx) - 9, 47, Int(bx) + 9, 48, 0x2E2E34) }
for cx in [9.5, 18.5, 38.5, 47.5] { wheel(cx, 47.8, 3.2) }
// Lamp glow on the rails ahead
for x in 57..<N { let a = max(0, 0.7 - Double(x - 57) * 0.08); set(x, 51, mix(get(x, 51), 0xFFE8A0, a)); set(x, 52, mix(get(x, 52), 0xFFE8A0, a * 0.7)) }

// Export at 1024x1024 (nearest neighbour), RGB, no alpha
func write(_ size: Int, _ path: String) {
    let scale = size / N
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let buf = ctx.data!.bindMemory(to: UInt8.self, capacity: size * size * 4)
    for y in 0..<size { for x in 0..<size {
        let c = px[(y / scale) * N + (x / scale)]
        let o = (y * size + x) * 4
        buf[o] = UInt8((c >> 16) & 0xFF); buf[o + 1] = UInt8((c >> 8) & 0xFF); buf[o + 2] = UInt8(c & 0xFF); buf[o + 3] = 255
    } }
    let img = ctx.makeImage()!
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}
let out = CommandLine.arguments[1]
write(1024, out)
print("wrote \(out)")
