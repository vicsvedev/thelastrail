import SpriteKit

/// 16×16 sprites for interactable world objects.
enum ObjectSprites {
    private static var cache: [String: SKTexture] = [:]

    /// `open` = opened container / open door / running machine.
    static func texture(_ look: ObjectLook, open: Bool = false, region: Region = .depot) -> SKTexture {
        let key = "\(look.rawValue)-\(open)-\(region.rawValue)"
        if let t = cache[key] { return t }
        let c = canvas(look, open: open, region: region)
        let t = c.texture()
        cache[key] = t
        return t
    }

    static func canvas(_ look: ObjectLook, open: Bool = false, region: Region = .depot) -> PixelCanvas {
        let c = PixelCanvas(16, 16)
        switch look {
        case .scrapPile:
            c.ellipse(8, 12, 7, 3, 0x000000, alpha: 70)
            c.stamp([
                "................",
                "................",
                "................",
                "................",
                "................",
                "......kk........",
                ".....kgGk..k....",
                "....kghgRkkgk...",
                "...kRgGhgRgGhk..",
                "..kgGRrgGhgRgGk.",
                "..kGhgRGgRrgGGk.",
                ".kRgGgrRgGgRgGRk",
                ".kkkkkkkkkkkkkkk",
            ])
        case .woodPile:
            c.ellipse(8, 13, 7, 2.5, 0x000000, alpha: 70)
            for (i, y) in [6, 9, 9, 12, 12, 12].enumerated() {
                let x = [5, 3, 8, 1, 6, 11][i]
                c.circle(Double(x) + 2, Double(y) + 0.5, 2.4, Pal.outline)
                c.circle(Double(x) + 2, Double(y) + 0.5, 1.7, 0xA88A5A)
                c.set(x + 2, y, 0x6A4E36)
            }
        case .copperSpool:
            c.ellipse(8, 13, 6, 2.5, 0x000000, alpha: 70)
            c.fill(3, 4, 10, 9, Pal.outline)
            c.fill(4, 5, 8, 7, 0xC87A3A)
            for y in stride(from: 5, to: 12, by: 2) { c.hline(4, 11, y, 0xE09A5A) }
            c.fill(2, 3, 12, 2, 0x6A4E36); c.fill(2, 12, 12, 2, 0x6A4E36)
            c.rectOutline(2, 3, 12, 11, Pal.outline)
        case .copperOre:
            c.ellipse(8, 9, 7, 6, Pal.outline); c.ellipse(8, 9, 6, 5, 0x5A5048)
            for (x, y) in [(5, 7), (9, 6), (7, 10), (11, 10), (4, 11)] { c.fill(x, y, 2, 2, 0xC87A3A); c.set(x, y, 0xF0A060) }
        case .coalPile:
            c.ellipse(8, 12, 7, 3, 0x000000, alpha: 70)
            c.ellipse(8, 10, 7, 4.5, Pal.outline); c.ellipse(8, 10, 6, 3.6, 0x2A2A2A)
            for (x, y) in [(5, 8), (8, 7), (10, 10), (6, 11), (12, 9)] { c.set(x, y, 0x5A5A62) }
        case .coalBin:
            c.fill(1, 4, 14, 11, Pal.outline); c.fill(2, 5, 12, 9, 0x5A4430)
            c.fill(3, 6, 10, 4, 0x2A2A2A); c.set(5, 6, 0x5A5A62); c.set(9, 7, 0x5A5A62)
            c.hline(2, 13, 5, 0x7A5A40)
            if open { c.fill(3, 6, 10, 4, 0x3A2E24) }
        case .fuelCan:
            c.ellipse(8, 14, 5, 1.8, 0x000000, alpha: 80)
            c.stamp([
                "................",
                "................",
                "......kkkk......",
                ".....kgkkgk.....",
                "....kkkkkkkkk...",
                "....kppppppPkk..",
                "....kpWppppPkgk.",
                "....kpppkppPk.k.",
                "....kppkpkpPk...",
                "....kpkpppkPk...",
                "....kppppppPk...",
                "....kpppppPPk...",
                "....kPPPPPPPk...",
                "....kkkkkkkkk...",
            ])
        case .oilDrum:
            c.ellipse(8, 14, 6, 2, 0x000000, alpha: 80)
            c.fill(3, 3, 10, 11, Pal.outline); c.fill(4, 4, 8, 9, 0x3A5068)
            c.hline(4, 11, 6, 0x5A7898); c.hline(4, 11, 10, 0x5A7898)
            c.ellipse(8, 4, 4, 1.5, 0x5A7898); c.set(6, 4, 0x1A1418)
            c.fill(5, 7, 3, 2, Pal.amber)
            c.set(10, 13, 0x2A2A2A); c.set(11, 14, 0x2A2A2A)
        case .berryBush:
            c.ellipse(8, 9, 7.5, 6.5, 0x1A3022); c.ellipse(8, 8.5, 6.5, 5.5, 0x2F5A3A)
            for (x, y) in [(5, 6), (10, 7), (7, 10), (11, 11), (4, 10), (8, 5)] {
                c.set(x, y, 0xC04060); c.set(x + 1, y, 0x802848)
            }
            c.set(6, 5, 0x6A9A58)
        case .foodCrate:
            c.fill(2, 5, 12, 9, Pal.outline); c.fill(3, 6, 10, 7, 0x8A6A3A)
            c.hline(3, 12, 6, 0xA88A5A)
            for x in [4, 7, 10] { c.fill(x, 3, 2, 4, 0x8A8A90); c.set(x, 3, 0xC04040) }
            c.hline(3, 12, 9, 0x6A4E2A)
        case .gearBox:
            c.fill(2, 6, 12, 8, Pal.outline); c.fill(3, 7, 10, 6, 0x4A5058)
            c.circle(7, 5, 3.5, Pal.outline); c.circle(7, 5, 2.6, 0xB0B0B8); c.circle(7, 5, 1, 0x4A4A50)
            c.circle(11, 7, 2.5, Pal.outline); c.circle(11, 7, 1.7, 0xC8A060)
            c.hline(3, 12, 10, 0x68707A)
        case .researchBox:
            c.fill(3, 5, 10, 9, Pal.outline); c.fill(4, 6, 8, 7, 0xD8E4F0)
            c.fill(5, 8, 6, 3, 0x3AA070); c.fill(6, 9, 4, 1, 0x7AE0A0)
            c.hline(4, 11, 6, 0xA0B4C8)
        case .crate:
            c.fill(1, 2, 14, 13, Pal.outline); c.fill(2, 3, 12, 11, open ? 0x5A4430 : 0x9A7A4A)
            if open {
                c.fill(3, 4, 10, 9, 0x2A2018); c.hline(2, 13, 3, 0x7A5A3A)
            } else {
                c.rectOutline(2, 3, 12, 11, 0x6A4E2A); c.hline(2, 13, 8, 0x6A4E2A)
                c.hline(2, 13, 3, 0xB89A6A); c.fill(7, 7, 2, 3, 0x8A8A90)
            }
        case .locker:
            c.fill(2, 1, 12, 14, Pal.outline); c.fill(3, 2, 10, 12, open ? 0x2A2E34 : 0x5A7898)
            if !open {
                c.vline(8, 2, 13, 0x3A5068); for y in [4, 6] { c.hline(4, 7, y, 0x3A5068); c.hline(9, 12, y, 0x3A5068) }
                c.set(7, 9, 0xF0C060); c.set(9, 9, 0xF0C060)
            }
        case .toolbox:
            c.fill(2, 6, 12, 8, Pal.outline); c.fill(3, 7, 10, 6, open ? 0x5A2020 : 0xB04040)
            c.rectOutline(5, 3, 6, 4, Pal.outline); c.hline(3, 12, 9, 0x802828); c.fill(7, 8, 2, 2, 0xB0B0B8)
        case .note:
            c.ellipse(8, 11, 5, 2, 0x000000, alpha: 50)
            c.fill(4, 4, 8, 9, 0xC8BC9C); c.fill(4, 4, 7, 8, 0xF0E6C8)
            for y in [6, 8, 10] { c.hline(5, 9, y, 0x8A8A90) }
            c.rectOutline(4, 4, 8, 9, 0x6A6050)
        case .blueprint:
            c.ellipse(8, 12, 6, 2, 0x000000, alpha: 50)
            c.fill(2, 6, 12, 6, Pal.outline); c.fill(3, 7, 10, 4, 0x3A6AA8)
            c.hline(3, 12, 9, 0x8AB0E0); c.vline(6, 7, 10, 0x8AB0E0); c.vline(10, 7, 10, 0x8AB0E0)
            c.circle(3, 9, 2.6, Pal.outline); c.circle(3, 9, 1.8, 0xD8E4F0)
        case .fuse:
            c.ellipse(8, 12, 5, 2, 0x000000, alpha: 60)
            c.fill(4, 5, 8, 6, Pal.outline); c.fill(5, 6, 6, 4, 0xF0E6C8)
            c.fill(2, 7, 2, 2, 0xC87A3A); c.fill(12, 7, 2, 2, 0xC87A3A); c.hline(5, 10, 8, 0xC04040)
        case .doorWood, .doorMetal:
            let base: UInt32 = look == .doorWood ? 0x6A4E36 : 0x5A6270
            if open {
                c.fill(0, 0, 16, 16, 0x000000, alpha: 0)
                c.fill(0, 0, 2, 16, ColorMath.shade(base, -0.3)); c.fill(14, 0, 2, 16, ColorMath.shade(base, -0.3))
            } else {
                c.fill(0, 0, 16, 16, Pal.outline); c.fill(1, 1, 14, 15, base)
                c.hline(1, 14, 5, ColorMath.shade(base, -0.25)); c.hline(1, 14, 10, ColorMath.shade(base, -0.25))
                c.hline(1, 14, 1, ColorMath.shade(base, 0.2))
                c.fill(11, 7, 2, 2, 0xE0A040)
                if look == .doorMetal { for x in [3, 7] { c.set(x, 3, 0x9AA0A8); c.set(x, 12, 0x9AA0A8) } ; c.ellipse(5, 8, 2.5, 3, 0x7A4428, alpha: 160) }
            }
        case .keypadDoor:
            if open {
                c.fill(0, 0, 2, 16, 0x32363C); c.fill(14, 0, 2, 16, 0x32363C)
            } else {
                c.fill(0, 0, 16, 16, Pal.outline); c.fill(1, 1, 14, 15, 0x4A5058)
                c.vline(8, 1, 15, 0x32363C)
                c.fill(11, 5, 4, 6, 0x1A1418); c.fill(12, 6, 2, 1, 0x7AE0A0)
                for y in [8, 9] { c.set(12, y, 0x8A8A90); c.set(13, y, 0x8A8A90) }
            }
        case .darkness:
            c.fill(0, 0, 16, 16, 0x050405, alpha: 235)
            for y in 0..<16 { c.set(0, y, 0x050405, alpha: 120); c.set(15, y, 0x050405, alpha: 120) }
        case .signalBox:
            c.fill(1, 1, 14, 14, Pal.outline); c.fill(2, 2, 12, 12, 0x4A5058)
            for (i, x) in [3, 6, 9, 12].enumerated() {
                c.vline(x, 3, 8, 0x2A2A30)
                c.set(x, 10, open ? 0x7AE0A0 : (i % 2 == 0 ? 0x802828 : 0x3A3A40))
            }
            c.hline(2, 13, 2, 0x68707A); c.fill(3, 12, 10, 1, 0x2A2A30)
        case .generator:
            c.fill(0, 3, 16, 12, Pal.outline); c.fill(1, 4, 14, 10, 0x5A6A48)
            c.fill(2, 5, 6, 6, 0x3A4430); for y in [6, 8, 10] { c.hline(2, 7, y, 0x2A3022) }
            c.circle(11.5, 8.5, 2.6, 0x2A2A2A); c.circle(11.5, 8.5, 1.4, open ? 0xF0C060 : 0x5A5A62)
            c.fill(12, 1, 2, 3, 0x3A3A40)
        case .terminal:
            c.fill(1, 2, 14, 12, Pal.outline); c.fill(2, 3, 12, 10, 0x5A5A62)
            c.fill(3, 4, 10, 6, open ? 0x1E4A2E : 0x101418)
            if open { for y in [5, 7] { c.hline(4, 4 + (y == 5 ? 7 : 4), y, 0x7AE0A0) } }
            c.hline(3, 12, 11, 0x3A3A40)
        case .radio:
            c.fill(2, 5, 12, 8, Pal.outline); c.fill(3, 6, 10, 6, 0x6A4E36)
            c.fill(4, 7, 5, 4, 0x3A2A20); for y in [7, 9] { c.hline(4, 8, y, 0x5A4430) }
            c.circle(11, 8, 1.3, 0xE0A040); c.set(11, 10, 0xB0B0B8)
            c.line(10, 5, 13, 1, 0x8A8A90)
        case .sign:
            c.fill(7, 8, 2, 7, 0x4A3424)
            c.fill(2, 2, 12, 7, Pal.outline); c.fill(3, 3, 10, 5, 0x8A6A3A)
            c.hline(4, 11, 4, 0x4A3424); c.hline(4, 9, 6, 0x4A3424)
        case .cairn:
            c.ellipse(8, 13, 6, 2, 0x000000, alpha: 60)
            for (x, y, r) in [(8.0, 12.0, 5.0), (8.0, 8.0, 3.8), (8.0, 4.5, 2.6)] {
                c.ellipse(x, y, r, r * 0.7, Pal.outline); c.ellipse(x - 0.3, y - 0.3, r - 0.9, r * 0.7 - 0.8, 0x7A808C)
                c.set(Int(x) - 2, Int(y) - 1, 0xA0A8B4)
            }
            c.hline(5, 10, 2, 0xF0F4F8)
        }
        return c
    }
}
