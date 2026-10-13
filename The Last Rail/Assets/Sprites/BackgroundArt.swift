import SpriteKit

/// Procedural side-view scenery. Every horizontal layer is seamless over `width` so it can scroll forever.
enum BackgroundArt {
    static let width = 480
    static let height = 270
    private static var cache: [String: SKTexture] = [:]

    private static func cached(_ key: String, smooth: Bool = false, _ make: () -> PixelCanvas) -> SKTexture {
        if let t = cache[key] { return t }
        let t = make().texture(smooth: smooth)
        cache[key] = t
        return t
    }

    /// Seamless ridge line: integer frequencies guarantee wrap-around.
    private static func ridge(_ x: Int, seed: Int, base: Double, amps: [(Int, Double)]) -> Double {
        var y = base
        for (i, (k, a)) in amps.enumerated() {
            let phase = Double((seed * 37 + i * 101) % 360) * .pi / 180
            y += a * sin(2 * .pi * Double(k) * Double(x) / Double(width) + phase)
        }
        return y
    }

    static func sky(_ region: Region) -> SKTexture {
        let width = Int(Viewport.size.width)
        return cached("sky-\(region.rawValue)-\(width)") {
            let pal = RegionPalette.of(region)
            let c = PixelCanvas(width, height)
            // Banded gradient with ordered dithering for a 16-bit look.
            let bayer: [[Double]] = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
            let bands = 14.0
            for y in 0..<height {
                let t = pow(Double(y) / Double(height - 1), 1.3)
                for x in 0..<width {
                    let d = (bayer[y % 4][x % 4] / 16 - 0.5) / bands
                    let q = (min(1, max(0, t + d)) * bands).rounded() / bands
                    c.set(x, y, ColorMath.mix(pal.skyTop, pal.skyHorizon, q))
                }
            }
            var rng = SeededRandom(seed: UInt64(region.rawValue.count * 991))
            if region != .forest && region != .industrial {
                for _ in 0..<70 {
                    let x = rng.int(0...(width - 1)), y = rng.int(0...110)
                    c.set(x, y, 0xF0E6C8, alpha: UInt8(rng.int(60...200)))
                }
            }
            // Low sun / moon glow
            switch region {
            case .depot: c.glow(Double(width) * 0.75, 190, 70, 0xF8C070, intensity: 0.5); c.circle(Double(width) * 0.75, 190, 14, 0xF8D890)
            case .industrial: c.glow(120, 180, 80, 0xD08050, intensity: 0.4); c.circle(120, 180, 12, 0xE8A070)
            case .mine: c.circle(Double(width) * 0.8, 60, 9, 0xE8E4F0); c.circle(Double(width) * 0.8 + 3, 58, 8, ColorMath.mix(pal.skyTop, pal.skyHorizon, 0.2))
            case .mountain: c.glow(300, 60, 60, 0xE0F0FF, intensity: 0.35)
            case .forest: break
            }
            return c
        }
    }

    static func farMountains(_ region: Region) -> SKTexture {
        cached("far-\(region.rawValue)") {
            let pal = RegionPalette.of(region)
            let c = PixelCanvas(width, 140)
            let amps: [(Int, Double)] = region == .mountain ? [(2, 26), (5, 14), (11, 6)] : [(2, 14), (4, 9), (9, 4)]
            for x in 0..<width {
                let top = Int(ridge(x, seed: 3, base: region == .mountain ? 50 : 80, amps: amps))
                for y in max(0, top)..<140 {
                    let snow = region == .mountain && y < top + 8 && y < 62
                    c.set(x, y, snow ? 0xE8EEF6 : ColorMath.mix(pal.farMountain, pal.skyHorizon, 0.15))
                }
            }
            return c
        }
    }

    static func midHills(_ region: Region) -> SKTexture {
        cached("mid-\(region.rawValue)") {
            let pal = RegionPalette.of(region)
            let c = PixelCanvas(width, 120)
            for x in 0..<width {
                let top = Int(ridge(x, seed: 7, base: 54, amps: [(3, 12), (7, 6), (13, 3)]))
                for y in max(0, top)..<120 { c.set(x, y, pal.midHill) }
                if region == .mountain { for y in max(0, top)..<min(120, top + 3) { c.set(x, y, 0xD8E0EA) } }
            }
            var rng = SeededRandom(seed: 77)
            // Region silhouettes on the hills.
            for i in 0..<10 {
                let x = i * 48 + rng.int(0...30)
                let top = Int(ridge(x, seed: 7, base: 54, amps: [(3, 12), (7, 6), (13, 3)]))
                let dark = ColorMath.shade(pal.midHill, -0.18)
                switch region {
                case .industrial:
                    if i % 3 == 0 {
                        c.fill(x, top - 30, 6, 32, dark); c.fill(x + 10, top - 18, 22, 20, dark); c.fill(x + 26, top - 26, 4, 10, dark)
                        c.fill(x + 13, top - 12, 3, 3, 0xE0A040)
                    }
                case .mine:
                    if i % 4 == 1 {
                        c.line(x, top, x + 8, top - 26, dark); c.line(x + 16, top, x + 8, top - 26, dark)
                        c.line(x + 3, top - 10, x + 13, top - 10, dark); c.circle(Double(x + 8), Double(top - 26), 3, dark)
                    }
                case .depot:
                    if i % 4 == 2 { c.fill(x, top - 10, 18, 12, dark); c.line(x - 2, top - 10, x + 9, top - 16, dark); c.line(x + 9, top - 16, x + 20, top - 10, dark) }
                default:
                    for t in 0..<4 {
                        let tx = x + t * 7, th = rng.int(8...14)
                        for dy in 0..<th { c.hline(tx - dy / 3, tx + dy / 3, top - th + dy, dark) }
                    }
                }
            }
            return c
        }
    }

    static func treeLine(_ region: Region) -> SKTexture {
        cached("trees-\(region.rawValue)") {
            let pal = RegionPalette.of(region)
            let c = PixelCanvas(width, 90)
            var rng = SeededRandom(seed: 123 + UInt64(region.rawValue.count))
            let ground = 70
            c.fill(0, ground, width, 20, pal.nearLand)
            var x = 0
            while x < width - 10 {
                let h: Int
                switch region {
                case .forest, .mountain:
                    h = rng.int(28...56)
                    for dy in 0..<h {
                        let half = max(1, dy * 7 / h + (dy % 6 == 5 ? 1 : 0))
                        c.hline(x - half, x + half, ground - h + dy, dy % 6 == 0 ? pal.foliage : pal.foliageDark)
                        if region == .mountain && dy % 6 == 1 { c.hline(x - half, x, ground - h + dy, 0xE4EAF2) }
                    }
                    x += rng.int(6...14)
                case .industrial:
                    h = rng.int(10...40)
                    if rng.chance(0.4) {
                        c.fill(x, ground - h, rng.int(14...30), h, 0x2E2A2C)
                        if rng.chance(0.5) { c.fill(x + 3, ground - h + 4, 3, 3, 0xE0A040) }
                    } else {
                        c.vline(x, ground - h, ground, 0x3A3436); c.vline(x + 1, ground - h, ground, 0x3A3436)
                        c.line(x, ground - h, x - 6, ground - h - 6, 0x3A3436); c.line(x, ground - h + 6, x + 7, ground - h, 0x3A3436)
                    }
                    x += rng.int(18...40)
                case .mine:
                    h = rng.int(14...34)
                    c.ellipse(Double(x), Double(ground), Double(rng.int(10...22)), Double(h), pal.rock)
                    c.ellipse(Double(x - 3), Double(ground - h / 2), 4, Double(h) / 3, pal.rockLight, alpha: 120)
                    x += rng.int(16...30)
                case .depot:
                    h = rng.int(8...22)
                    if rng.chance(0.5) {
                        c.ellipse(Double(x), Double(ground - h), 9, 7, pal.foliageDark); c.vline(x, ground - h, ground, pal.trunk)
                    } else {
                        for t in 0..<5 { c.vline(x + t * 2, ground - rng.int(2...6), ground, pal.foliage) }
                    }
                    x += rng.int(14...36)
                }
            }
            return c
        }
    }

    /// Ballast, sleepers and rails. 64px tile repeated across the screen.
    static func track() -> SKTexture {
        cached("track") {
            let c = PixelCanvas(64, 18)
            c.fill(0, 4, 64, 14, 0x3E3832)
            var rng = SeededRandom(seed: 5)
            for _ in 0..<120 { c.set(rng.int(0...63), rng.int(5...17), rng.chance(0.5) ? 0x5A524A : 0x2E2824) }
            for x in stride(from: 2, to: 64, by: 8) { c.fill(x, 5, 5, 3, 0x4A3424); c.hline(x, x + 4, 5, 0x6A4E36) }
            c.fill(0, 2, 64, 3, 0x8A8A92); c.hline(0, 63, 2, 0xC0C0C8); c.hline(0, 63, 4, 0x4A4A50)
            return c
        }
    }

    static func groundStrip(_ region: Region) -> SKTexture {
        cached("ground-\(region.rawValue)") {
            let pal = RegionPalette.of(region)
            let c = PixelCanvas(width, 60)
            c.fill(0, 0, width, 60, pal.nearLand)
            var rng = SeededRandom(seed: 9 + UInt64(region.rawValue.count))
            let tuft = region == .mountain ? 0xD8E0EA : pal.foliage
            for _ in 0..<260 { c.set(rng.int(0...(width - 1)), rng.int(0...59), rng.chance(0.5) ? ColorMath.shade(pal.nearLand, 0.1) : ColorMath.shade(pal.nearLand, -0.15)) }
            for _ in 0..<60 {
                let x = rng.int(0...(width - 1)), y = rng.int(2...58)
                c.vline(x, y - 2, y, tuft); c.set(x + 1, y, tuft)
            }
            return c
        }
    }

    static func pole() -> SKTexture {
        cached("pole") {
            let c = PixelCanvas(12, 70)
            c.fill(5, 4, 2, 66, 0x2A221E); c.fill(0, 6, 12, 2, 0x2A221E); c.fill(1, 14, 10, 2, 0x2A221E)
            for x in [1, 5, 10] { c.set(x, 5, 0x9A9AA2) }
            return c
        }
    }

    static func cloud(_ variant: Int) -> SKTexture {
        cached("cloud-\(variant)", smooth: false) {
            var rng = SeededRandom(seed: UInt64(variant * 31 + 7))
            let c = PixelCanvas(96, 32)
            for _ in 0..<7 {
                let cx = Double(rng.int(18...78)), cy = Double(rng.int(14...20)), r = Double(rng.int(7...13))
                c.ellipse(cx, cy, r * 1.3, r * 0.8, 0xFFFFFF, alpha: 255)
            }
            // Shade the underside
            for y in 0..<32 { for x in 0..<96 where c.alphaAt(x, y) > 0 && y > 19 { c.set(x, y, 0xC8CCD8) } }
            return c
        }
    }

    static func softGlow(_ color: UInt32, radius: Int = 32) -> SKTexture {
        cached("glow-\(color)-\(radius)", smooth: true) {
            let c = PixelCanvas(radius * 2, radius * 2)
            c.glow(Double(radius), Double(radius), Double(radius), color)
            return c
        }
    }

    static func particle(_ color: UInt32, w: Int, h: Int) -> SKTexture {
        cached("p-\(color)-\(w)-\(h)") { PixelCanvas(w, h, fill: color) }
    }

    static func smokePuff() -> SKTexture {
        cached("smoke", smooth: true) {
            let c = PixelCanvas(16, 16)
            c.glow(8, 8, 8, 0xD0D0D8, intensity: 1.6)
            return c
        }
    }

    static func fogBank() -> SKTexture {
        cached("fog", smooth: true) {
            let c = PixelCanvas(128, 48)
            var rng = SeededRandom(seed: 41)
            for _ in 0..<10 {
                c.glow(Double(rng.int(20...108)), Double(rng.int(16...32)), Double(rng.int(14...24)), 0xE0E4EC, intensity: 0.35)
            }
            return c
        }
    }

    /// Darkness overlay with a soft transparent hole in the middle (used in mines).
    static func darknessMask() -> SKTexture {
        cached("dark-mask", smooth: true) {
            let w = 256, h = 256
            let c = PixelCanvas(w, h)
            for y in 0..<h {
                for x in 0..<w {
                    let d = hypot(Double(x) - 128, Double(y) - 128) / 40   // hole radius ≈ 40 px at scale 1
                    let a = min(1, max(0, (d - 0.55) / 0.45))
                    c.set(x, y, 0x05040A, alpha: UInt8(a * 250))
                }
            }
            return c
        }
    }

    static func stationBuilding(_ region: Region) -> SKTexture {
        cached("stationbuilding-\(region.rawValue)") {
            let pal = RegionPalette.of(region)
            let c = PixelCanvas(140, 70)
            let wall: UInt32 = region == .industrial ? 0x4A4A52 : (region == .mountain ? 0x6A5040 : 0x7A5A40)
            c.fill(10, 24, 120, 46, Pal.outline); c.fill(11, 25, 118, 45, wall)
            for y in stride(from: 28, to: 70, by: 4) { c.hline(11, 128, y, ColorMath.shade(wall, -0.15)) }
            // Roof
            for i in 0..<20 { c.hline(4 + i / 2, 135 - i / 2, 24 - i, i == 0 ? Pal.outline : pal.wallDark) }
            c.hline(14, 125, 4, Pal.outline)
            if region == .mountain { for i in 0..<5 { c.hline(10 + i, 129 - i, 20 - i, 0xEEF2F8) } }
            // Windows (warm) and door
            for x in [22, 50, 96] { c.fill(x, 36, 14, 16, Pal.outline); c.fill(x + 1, 37, 12, 14, 0xF0B050); c.vline(x + 7, 37, 50, 0x8A5A30); c.hline(x + 1, x + 12, 43, 0x8A5A30) }
            c.fill(72, 40, 16, 30, Pal.outline); c.fill(73, 41, 14, 29, 0x3A2A20)
            // Sign board
            c.fill(30, 26, 80, 9, 0x2A2A2A); c.rectOutline(30, 26, 80, 9, 0x8A8A90)
            // Chimney
            c.fill(110, 0, 8, 14, Pal.outline); c.fill(111, 1, 6, 13, 0x5A3A2A)
            return c
        }
    }

    static func platform() -> SKTexture {
        cached("platform") {
            let c = PixelCanvas(480, 10)
            c.fill(0, 0, 480, 10, 0x8A8478)
            c.fill(0, 0, 480, 2, 0xC0A040)
            for x in stride(from: 0, to: 480, by: 24) { c.vline(x, 2, 9, 0x6E685E) }
            c.hline(0, 479, 9, 0x5A544A)
            return c
        }
    }
}
