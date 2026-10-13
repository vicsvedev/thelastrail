import UIKit
import SpriteKit

/// Small RGBA bitmap used to author all pixel art procedurally.
/// Coordinates: (0,0) is the top-left pixel.
final class PixelCanvas {
    let width: Int
    let height: Int
    private(set) var pixels: [UInt32]   // stored as 0xRRGGBBAA (straight alpha)

    init(_ width: Int, _ height: Int, fill: UInt32? = nil, alpha: UInt8 = 255) {
        self.width = max(1, width)
        self.height = max(1, height)
        let initial: UInt32 = fill.map { ($0 << 8) | UInt32(alpha) } ?? 0
        pixels = Array(repeating: initial, count: self.width * self.height)
    }

    // MARK: Drawing primitives

    @inline(__always)
    func set(_ x: Int, _ y: Int, _ rgb: UInt32, alpha: UInt8 = 255) {
        guard x >= 0, y >= 0, x < width, y < height else { return }
        if alpha == 255 {
            pixels[y * width + x] = (rgb << 8) | 0xFF
        } else {
            blend(x, y, rgb, alpha: Double(alpha) / 255)
        }
    }

    func blend(_ x: Int, _ y: Int, _ rgb: UInt32, alpha a: Double) {
        guard x >= 0, y >= 0, x < width, y < height, a > 0 else { return }
        let i = y * width + x
        let dst = pixels[i]
        let da = Double(dst & 0xFF) / 255
        let outA = a + da * (1 - a)
        guard outA > 0 else { return }
        func ch(_ src: UInt32, _ d: UInt32) -> UInt32 {
            let s = Double(src), dd = Double(d)
            return UInt32(min(255, max(0, ((s * a + dd * da * (1 - a)) / outA).rounded())))
        }
        let r = ch((rgb >> 16) & 0xFF, (dst >> 24) & 0xFF)
        let g = ch((rgb >> 8) & 0xFF, (dst >> 16) & 0xFF)
        let b = ch(rgb & 0xFF, (dst >> 8) & 0xFF)
        pixels[i] = (r << 24) | (g << 16) | (b << 8) | UInt32((outA * 255).rounded())
    }

    func get(_ x: Int, _ y: Int) -> UInt32 {
        guard x >= 0, y >= 0, x < width, y < height else { return 0 }
        return pixels[y * width + x] >> 8
    }

    func alphaAt(_ x: Int, _ y: Int) -> UInt8 {
        guard x >= 0, y >= 0, x < width, y < height else { return 0 }
        return UInt8(pixels[y * width + x] & 0xFF)
    }

    func clear(_ x: Int, _ y: Int) {
        guard x >= 0, y >= 0, x < width, y < height else { return }
        pixels[y * width + x] = 0
    }

    func fill(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ rgb: UInt32, alpha: UInt8 = 255) {
        for yy in y..<(y + h) { for xx in x..<(x + w) { set(xx, yy, rgb, alpha: alpha) } }
    }

    func hline(_ x0: Int, _ x1: Int, _ y: Int, _ rgb: UInt32, alpha: UInt8 = 255) {
        guard x1 >= x0 else { return }
        for x in x0...x1 { set(x, y, rgb, alpha: alpha) }
    }

    func vline(_ x: Int, _ y0: Int, _ y1: Int, _ rgb: UInt32, alpha: UInt8 = 255) {
        guard y1 >= y0 else { return }
        for y in y0...y1 { set(x, y, rgb, alpha: alpha) }
    }

    func rectOutline(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ rgb: UInt32) {
        hline(x, x + w - 1, y, rgb); hline(x, x + w - 1, y + h - 1, rgb)
        vline(x, y, y + h - 1, rgb); vline(x + w - 1, y, y + h - 1, rgb)
    }

    func line(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ rgb: UInt32, alpha: UInt8 = 255) {
        var x0 = x0, y0 = y0
        let dx = abs(x1 - x0), sx = x0 < x1 ? 1 : -1
        let dy = -abs(y1 - y0), sy = y0 < y1 ? 1 : -1
        var err = dx + dy
        while true {
            set(x0, y0, rgb, alpha: alpha)
            if x0 == x1 && y0 == y1 { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x0 += sx }
            if e2 <= dx { err += dx; y0 += sy }
        }
    }

    func ellipse(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ rgb: UInt32, alpha: UInt8 = 255) {
        let x0 = Int((cx - rx).rounded(.down)), x1 = Int((cx + rx).rounded(.up))
        let y0 = Int((cy - ry).rounded(.down)), y1 = Int((cy + ry).rounded(.up))
        for y in y0...y1 {
            for x in x0...x1 {
                let nx = (Double(x) + 0.5 - cx) / rx
                let ny = (Double(y) + 0.5 - cy) / ry
                if nx * nx + ny * ny <= 1 { set(x, y, rgb, alpha: alpha) }
            }
        }
    }

    func circle(_ cx: Double, _ cy: Double, _ r: Double, _ rgb: UInt32, alpha: UInt8 = 255) {
        ellipse(cx, cy, r, r, rgb, alpha: alpha)
    }

    /// Soft radial glow with smooth falloff (use with linear filtering).
    func glow(_ cx: Double, _ cy: Double, _ r: Double, _ rgb: UInt32, intensity: Double = 1) {
        let x0 = Int(cx - r), x1 = Int(cx + r), y0 = Int(cy - r), y1 = Int(cy + r)
        for y in y0...y1 {
            for x in x0...x1 {
                let d = hypot(Double(x) + 0.5 - cx, Double(y) + 0.5 - cy) / r
                if d < 1 {
                    let a = pow(1 - d, 2) * intensity
                    blend(x, y, rgb, alpha: min(1, a))
                }
            }
        }
    }

    /// Stamps ASCII art. Characters map to colors via `palette`; unknown characters are transparent.
    func stamp(_ rows: [String], at ox: Int = 0, _ oy: Int = 0, palette: [Character: UInt32] = Pal.ascii, flipX: Bool = false) {
        for (y, row) in rows.enumerated() {
            let chars = Array(row)
            for (x, ch) in chars.enumerated() {
                guard let color = palette[ch] else { continue }
                let px = flipX ? (chars.count - 1 - x) : x
                set(ox + px, oy + y, color)
            }
        }
    }

    /// Copies another canvas onto this one (alpha blended).
    func draw(_ other: PixelCanvas, at ox: Int, _ oy: Int) {
        for y in 0..<other.height {
            for x in 0..<other.width {
                let p = other.pixels[y * other.width + x]
                let a = p & 0xFF
                if a == 0 { continue }
                if a == 255 { set(ox + x, oy + y, p >> 8) } else { blend(ox + x, oy + y, p >> 8, alpha: Double(a) / 255) }
            }
        }
    }

    /// Adds a 1px dark outline around opaque pixels.
    func outline(_ rgb: UInt32 = Pal.outline) {
        var marks: [(Int, Int)] = []
        for y in 0..<height {
            for x in 0..<width where alphaAt(x, y) == 0 {
                if alphaAt(x - 1, y) > 128 || alphaAt(x + 1, y) > 128 || alphaAt(x, y - 1) > 128 || alphaAt(x, y + 1) > 128 {
                    marks.append((x, y))
                }
            }
        }
        for (x, y) in marks { set(x, y, rgb) }
    }

    // MARK: Output

    func cgImage() -> CGImage? {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for i in 0..<(width * height) {
            let p = pixels[i]
            let a = UInt32(p & 0xFF)
            // Premultiply for CoreGraphics.
            bytes[i * 4 + 0] = UInt8(((p >> 24) & 0xFF) * a / 255)
            bytes[i * 4 + 1] = UInt8(((p >> 16) & 0xFF) * a / 255)
            bytes[i * 4 + 2] = UInt8(((p >> 8) & 0xFF) * a / 255)
            bytes[i * 4 + 3] = UInt8(a)
        }
        let data = Data(bytes)
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }

    func texture(smooth: Bool = false) -> SKTexture {
        guard let image = cgImage() else { return SKTexture() }
        let t = SKTexture(cgImage: image)
        t.filteringMode = smooth ? .linear : .nearest
        return t
    }

    func uiImage() -> UIImage {
        guard let image = cgImage() else { return UIImage() }
        return UIImage(cgImage: image)
    }
}

/// Deterministic pseudo-random generator for reproducible pixel noise.
nonisolated struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
    mutating func int(_ range: ClosedRange<Int>) -> Int { Int.random(in: range, using: &self) }
    mutating func chance(_ p: Double) -> Bool { unit() < p }
}

/// Stable hash for tile coordinates.
nonisolated func tileHash(_ x: Int, _ y: Int, _ salt: Int = 0) -> UInt64 {
    var h = UInt64(bitPattern: Int64(x &* 73856093 ^ y &* 19349663 ^ salt &* 83492791))
    h ^= h >> 33; h &*= 0xff51afd7ed558ccd; h ^= h >> 33
    return h
}

/// Color helpers.
enum ColorMath {
    static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        let t = min(1, max(0, t))
        func c(_ s: UInt32) -> (Double, Double, Double) {
            (Double((s >> 16) & 0xFF), Double((s >> 8) & 0xFF), Double(s & 0xFF))
        }
        let (ar, ag, ab) = c(a), (br, bg, bb) = c(b)
        let r = UInt32((ar + (br - ar) * t).rounded()), g = UInt32((ag + (bg - ag) * t).rounded()), bl = UInt32((ab + (bb - ab) * t).rounded())
        return (r << 16) | (g << 8) | bl
    }

    static func shade(_ c: UInt32, _ amount: Double) -> UInt32 {
        amount >= 0 ? mix(c, 0xFFFFFF, amount) : mix(c, 0x000000, -amount)
    }

    static func skColor(_ hex: UInt32, alpha: CGFloat = 1) -> SKColor {
        SKColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }
}
