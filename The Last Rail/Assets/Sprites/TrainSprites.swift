import SpriteKit

/// Train art: top-down (exploration) and side view (train scene).
enum TrainSprites {
    private static var cache: [String: SKTexture] = [:]

    private static func cached(_ key: String, _ make: () -> PixelCanvas) -> SKTexture {
        if let t = cache[key] { return t }
        let t = make().texture()
        cache[key] = t
        return t
    }

    // MARK: Top-down (exploration). Locomotive faces east.

    static let topLocoSize = CGSize(width: 64, height: 16)
    static let topWagonSize = CGSize(width: 56, height: 16)
    static let topWagonSpacing: CGFloat = 64

    static func topLocomotive(lit: Bool) -> SKTexture {
        cached("top-loco-\(lit)") {
            let c = PixelCanvas(64, 16)
            c.fill(0, 1, 64, 14, Pal.outline)
            c.fill(1, 2, 62, 12, 0x7A3A2A)
            c.fill(1, 2, 62, 2, 0x9A4A32)            // roof highlight
            c.fill(1, 12, 62, 2, 0x5A2A20)
            c.fill(4, 3, 16, 10, 0x8A4A34)           // cab roof
            c.rectOutline(4, 3, 16, 10, 0x4A2018)
            for x in stride(from: 24, to: 56, by: 4) { c.vline(x, 4, 11, 0x5A2A20) }  // hood grilles
            c.circle(44, 8, 2.5, 0x2A2A2A); c.circle(44, 8, 1.4, 0x101010)              // exhaust
            c.fill(58, 3, 5, 10, 0xC0A040)           // front stripe
            for y in [4, 6, 8, 10] { c.hline(58, 62, y, 0x2A2A2A) }
            c.fill(62, 6, 2, 4, lit ? 0xF8E8A0 : 0x5A5A62)  // headlamp
            return c
        }
    }

    static func topWagon(_ type: WagonType, hasBench: Bool) -> SKTexture {
        cached("top-\(type.rawValue)-\(hasBench)") {
            let c = PixelCanvas(56, 16)
            let (base, light, dark): (UInt32, UInt32, UInt32)
            switch type {
            case .cargo: (base, light, dark) = (0x7A4A30, 0x9A5E3C, 0x5A3422)
            case .workshop: (base, light, dark) = (0x4A5A6A, 0x5E7080, 0x34404C)
            case .living: (base, light, dark) = (0x3A5A44, 0x4A7056, 0x283E30)
            default: (base, light, dark) = (0x5A5A62, 0x6A6A72, 0x3A3A40)
            }
            c.fill(0, 1, 56, 14, Pal.outline)
            c.fill(1, 2, 54, 12, base)
            c.fill(1, 2, 54, 2, light); c.fill(1, 12, 54, 2, dark)
            for x in stride(from: 6, to: 52, by: 6) { c.vline(x, 4, 11, dark) }
            if type == .living || type == .workshop {
                c.circle(46, 8, 2.2, 0x2A2A2A)
                for x in [10, 22, 34] { c.fill(x, 6, 5, 4, 0xE0A040) }
            }
            if hasBench { c.fill(22, 5, 12, 6, 0x4A5058); c.rectOutline(22, 5, 12, 6, Pal.outline); c.set(27, 7, 0xF0C060) }
            return c
        }
    }

    // MARK: Side view (train scene)

    static let sideLocoSize = CGSize(width: 104, height: 44)
    static let sideWagonSize = CGSize(width: 84, height: 40)

    static func sideLocomotive(lit: Bool) -> SKTexture {
        cached("side-loco-\(lit)") {
            let w = 104, h = 44
            let c = PixelCanvas(w, h)
            let body: UInt32 = 0x8A3A2A, bodyLight: UInt32 = 0xA84A34, bodyDark: UInt32 = 0x5A2A20
            // Underframe
            c.fill(4, 32, 96, 5, Pal.outline); c.fill(5, 33, 94, 3, 0x2E2E34)
            // Cab (rear, left side)
            c.fill(4, 4, 30, 29, Pal.outline); c.fill(5, 5, 28, 27, body)
            c.fill(3, 2, 34, 4, Pal.outline); c.fill(4, 3, 32, 2, 0x5A5A62)   // cab roof
            c.fill(8, 9, 10, 9, Pal.outline); c.fill(9, 10, 8, 7, lit ? 0xF0C060 : 0x3A4450)
            c.fill(21, 9, 9, 9, Pal.outline); c.fill(22, 10, 7, 7, lit ? 0xF0C060 : 0x3A4450)
            if lit { c.fill(9, 10, 3, 2, 0xF8E8A0); c.fill(22, 10, 2, 2, 0xF8E8A0) }
            c.hline(5, 32, 22, bodyDark); c.fill(5, 23, 28, 2, 0xC0A040)
            // Hood
            c.fill(33, 11, 64, 22, Pal.outline); c.fill(34, 12, 62, 20, body)
            c.hline(34, 95, 12, bodyLight); c.hline(34, 95, 13, bodyLight)
            for x in stride(from: 40, to: 90, by: 5) { c.vline(x, 16, 21, bodyDark); c.vline(x + 1, 16, 21, 0x3A1E16) }
            c.fill(34, 23, 62, 2, 0xC0A040)
            c.hline(34, 95, 28, bodyDark)
            // Exhaust stack
            c.fill(70, 4, 7, 8, Pal.outline); c.fill(71, 5, 5, 7, 0x3A3A40); c.hline(71, 75, 5, 0x5A5A62)
            // Nose & headlamp
            c.fill(96, 14, 6, 18, Pal.outline); c.fill(97, 15, 4, 16, 0xC0A040)
            for y in stride(from: 16, to: 31, by: 3) { c.hline(97, 100, y, 0x2A2A2A) }
            c.fill(99, 17, 4, 4, Pal.outline); c.fill(100, 18, 2, 2, lit ? 0xF8F0C0 : 0x6A6A72)
            // Handrail & steps
            c.hline(34, 95, 10, 0x9A9AA2)
            c.fill(1, 26, 4, 2, 0x5A5A62); c.fill(1, 30, 4, 2, 0x5A5A62)
            // Buffers
            c.fill(0, 32, 4, 3, 0x2A2A2A); c.fill(100, 32, 4, 3, 0x2A2A2A)
            // Number plate
            c.fill(14, 26, 10, 4, 0x2A2A2A); c.hline(16, 21, 27, Pal.amberLight); c.hline(16, 19, 28, Pal.amberLight)
            return c
        }
    }

    static func sideWagon(_ type: WagonType, hasBench: Bool) -> SKTexture {
        cached("side-\(type.rawValue)-\(hasBench)") {
            let w = 84, h = 40
            let c = PixelCanvas(w, h)
            c.fill(3, 30, 78, 4, Pal.outline); c.fill(4, 31, 76, 2, 0x2E2E34)
            c.fill(0, 30, 3, 3, 0x2A2A2A); c.fill(81, 30, 3, 3, 0x2A2A2A)
            switch type {
            case .cargo:
                c.fill(3, 6, 78, 25, Pal.outline); c.fill(4, 7, 76, 23, 0x7A4A30)
                c.fill(2, 4, 80, 3, Pal.outline); c.fill(3, 4, 78, 2, 0x5A5A62)
                for x in stride(from: 8, to: 80, by: 6) { c.vline(x, 8, 28, 0x5A3422) }
                c.fill(32, 9, 20, 20, Pal.outline); c.fill(33, 10, 18, 18, 0x8A5638)
                c.line(33, 10, 50, 27, 0x5A3422); c.line(50, 10, 33, 27, 0x5A3422)
                if hasBench {
                    // Warm workshop window + tool sign.
                    c.fill(10, 11, 14, 9, Pal.outline); c.fill(11, 12, 12, 7, 0xF0C060); c.fill(11, 12, 4, 2, 0xF8E8A0)
                    c.fill(60, 12, 14, 9, 0x2A2A2A); c.line(62, 19, 70, 13, 0xB0B0B8); c.circle(71, 13, 1.5, 0xB0B0B8)
                }
            case .workshop:
                c.fill(3, 4, 78, 27, Pal.outline); c.fill(4, 5, 76, 25, 0x4A5A6A)
                c.fill(2, 2, 80, 3, Pal.outline); c.fill(3, 2, 78, 2, 0x68707A)
                for x in [8, 26, 44] { c.fill(x, 10, 12, 9, Pal.outline); c.fill(x + 1, 11, 10, 7, 0xF0C060); c.fill(x + 1, 11, 3, 2, 0xF8E8A0) }
                c.fill(64, 8, 12, 20, Pal.outline); c.fill(65, 9, 10, 18, 0x34404C)
                c.fill(60, 0, 4, 4, 0x3A3A40)
                c.hline(4, 79, 23, 0xC0A040)
            case .living:
                c.fill(3, 4, 78, 27, Pal.outline); c.fill(4, 5, 76, 25, 0x3A5A44)
                c.fill(2, 2, 80, 3, Pal.outline); c.fill(3, 2, 78, 2, 0x6A4E36)
                for x in [8, 24, 40, 56] { c.fill(x, 9, 11, 10, Pal.outline); c.fill(x + 1, 10, 9, 8, 0xF0B050); c.vline(x + 5, 10, 17, 0x8A5A30) }
                c.fill(70, 0, 5, 5, 0x3A3A40)
                c.hline(4, 79, 24, 0xC0A040)
                c.fill(10, 20, 6, 2, 0xC04060)   // flower box
            default:
                c.fill(3, 6, 78, 25, Pal.outline); c.fill(4, 7, 76, 23, 0x5A5A62)
            }
            return c
        }
    }

    static func wheel(frame: Int) -> SKTexture {
        cached("wheel-\(frame % 2)") {
            let c = PixelCanvas(12, 12)
            c.circle(6, 6, 6, Pal.outline); c.circle(6, 6, 5, 0x3A3A40); c.circle(6, 6, 3.5, 0x2A2A30)
            if frame % 2 == 0 { c.hline(2, 9, 6, 0x6A6A72); c.vline(6, 2, 9, 0x6A6A72) } else { c.line(3, 3, 8, 8, 0x6A6A72); c.line(8, 3, 3, 8, 0x6A6A72) }
            c.circle(6, 6, 1.2, 0x9A9AA2)
            return c
        }
    }
}

/// Small resource/item icons for the UI.
enum IconSprites {
    private static var cache: [String: UIImage] = [:]

    static func resource(_ type: ResourceType) -> UIImage {
        let key = "r-\(type.rawValue)"
        if let i = cache[key] { return i }
        let img = ObjectSprites.canvas(L.defaultLook(type)).uiImage()
        cache[key] = img
        return img
    }

    static func item(_ type: ItemType) -> UIImage {
        let key = "i-\(type.rawValue)"
        if let i = cache[key] { return i }
        let c: PixelCanvas
        switch type {
        case .crowbar:
            c = PixelCanvas(16, 16)
            c.line(3, 13, 12, 4, Pal.outline); c.line(4, 13, 13, 4, 0xC04040); c.line(4, 12, 12, 4, 0xC04040)
            c.line(12, 4, 14, 5, 0xC04040); c.line(3, 13, 2, 11, 0xC04040)
        case .headlamp:
            c = PixelCanvas(16, 16)
            c.ellipse(8, 9, 7, 4, Pal.outline); c.ellipse(8, 9, 6, 3, 0x3A3A40)
            c.circle(8, 7, 3.5, Pal.outline); c.circle(8, 7, 2.5, 0xF8E8A0)
        case .fuse: c = ObjectSprites.canvas(.fuse)
        case .repairKit: c = ObjectSprites.canvas(.toolbox)
        case .signalDecoder:
            c = PixelCanvas(16, 16)
            c.fill(2, 5, 12, 9, Pal.outline); c.fill(3, 6, 10, 7, 0x4A5058)
            c.fill(4, 7, 6, 3, 0x1E4A2E); c.hline(4, 9, 8, 0x7AE0A0)
            c.line(11, 5, 14, 1, 0x8A8A90); c.circle(11, 11, 1, 0xE0A040)
        }
        let img = c.uiImage()
        cache[key] = img
        return img
    }
}
