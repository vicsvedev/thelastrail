import Foundation

/// Procedural 16×16 tile art. Ground and overlay (tree canopies) are baked into two large textures per station.
enum TileArt {
    static let size = 16

    static func bake(_ layout: StationLayout, region: Region) -> (ground: PixelCanvas, overlay: PixelCanvas) {
        let s = size
        let ground = PixelCanvas(layout.width * s, layout.height * s)
        let overlay = PixelCanvas(layout.width * s, layout.height * s + s)
        let pal = RegionPalette.of(region)
        for row in 0..<layout.height {
            for col in 0..<layout.width {
                let kind = layout.tile(col, row)
                draw(kind, pal: pal, region: region, layout: layout, col: col, row: row, into: ground, overlay: overlay)
            }
        }
        return (ground, overlay)
    }

    private static func baseGround(_ c: PixelCanvas, _ ox: Int, _ oy: Int, _ pal: RegionPalette, _ col: Int, _ row: Int, region: Region) {
        var rng = SeededRandom(seed: tileHash(col, row, 1))
        c.fill(ox, oy, size, size, pal.ground)
        for _ in 0..<14 {
            let x = rng.int(0...15), y = rng.int(0...15)
            c.set(ox + x, oy + y, rng.chance(0.5) ? pal.groundAlt : pal.groundDark)
        }
        switch region {
        case .forest:
            for _ in 0..<5 {
                let x = rng.int(1...14), y = rng.int(2...14)
                c.set(ox + x, oy + y, pal.foliageLight); c.set(ox + x, oy + y - 1, pal.groundAlt)
            }
        case .mountain:
            if rng.chance(0.25) { c.set(ox + rng.int(1...14), oy + rng.int(1...14), pal.rock) }
            for _ in 0..<3 { c.set(ox + rng.int(0...15), oy + rng.int(0...15), 0xF4F6FA) }
        case .industrial:
            if rng.chance(0.3) {
                let x = rng.int(0...10), y = rng.int(0...12)
                c.line(ox + x, oy + y, ox + x + rng.int(2...5), oy + y + rng.int(1...3), pal.groundDark)
            }
            if rng.chance(0.15) { c.ellipse(Double(ox + rng.int(3...12)), Double(oy + rng.int(3...12)), 3, 2, 0x5A3A2A, alpha: 90) }
        case .depot:
            if rng.chance(0.2) { c.set(ox + rng.int(1...14), oy + rng.int(1...14), 0x5A6A3A) }
        case .mine:
            if rng.chance(0.3) { c.set(ox + rng.int(1...14), oy + rng.int(1...14), pal.rockLight) }
        }
    }

    private static func draw(_ kind: TileKind, pal: RegionPalette, region: Region, layout: StationLayout,
                             col: Int, row: Int, into c: PixelCanvas, overlay o: PixelCanvas) {
        let ox = col * size, oy = row * size
        var rng = SeededRandom(seed: tileHash(col, row, 7))
        switch kind {
        case .ground:
            baseGround(c, ox, oy, pal, col, row, region: region)

        case .tallGrass:
            baseGround(c, ox, oy, pal, col, row, region: region)
            let blade = region == .mountain ? 0x9AA890 : pal.foliageLight
            for _ in 0..<6 {
                let x = rng.int(1...14), y = rng.int(5...14)
                c.vline(ox + x, oy + y - rng.int(2...4), oy + y, blade)
                c.set(ox + x + 1, oy + y, pal.foliage)
            }

        case .flowers:
            baseGround(c, ox, oy, pal, col, row, region: region)
            let colors: [UInt32] = [Pal.amberLight, Pal.cream, 0x8AA8C0, 0xD06AA0]
            for _ in 0..<4 {
                let x = rng.int(2...13), y = rng.int(2...13)
                c.set(ox + x, oy + y + 1, pal.foliage)
                c.set(ox + x, oy + y, colors[rng.int(0...3)])
            }

        case .path:
            c.fill(ox, oy, size, size, pal.path)
            for _ in 0..<18 {
                c.set(ox + rng.int(0...15), oy + rng.int(0...15), rng.chance(0.5) ? ColorMath.shade(pal.path, 0.12) : ColorMath.shade(pal.path, -0.15))
            }

        case .floor:
            c.fill(ox, oy, size, size, pal.floor)
            if region == .industrial {
                c.hline(ox, ox + 15, oy + 15, pal.floorLine); c.vline(ox + 15, oy, oy + 15, pal.floorLine)
                if rng.chance(0.3) { c.set(ox + rng.int(2...13), oy + rng.int(2...13), pal.floorLine) }
            } else {
                for y in stride(from: 3, to: 16, by: 4) { c.hline(ox, ox + 15, oy + y, pal.floorLine) }
                let seam = rng.int(2...13)
                c.vline(ox + seam, oy, oy + 3, pal.floorLine); c.vline(ox + (seam + 7) % 16, oy + 4, oy + 7, pal.floorLine)
                c.vline(ox + (seam + 3) % 16, oy + 8, oy + 11, pal.floorLine)
                for _ in 0..<4 { c.set(ox + rng.int(0...15), oy + rng.int(0...15), ColorMath.shade(pal.floor, 0.08)) }
            }

        case .darkFloor:
            c.fill(ox, oy, size, size, pal.floor)
            for _ in 0..<12 { c.set(ox + rng.int(0...15), oy + rng.int(0...15), rng.chance(0.5) ? pal.floorLine : ColorMath.shade(pal.floor, -0.2)) }
            if rng.chance(0.2) { c.set(ox + rng.int(2...13), oy + rng.int(2...13), pal.rockLight) }

        case .wall, .crackedWall:
            drawWall(c, ox, oy, pal, region: region, cracked: kind == .crackedWall, rng: &rng,
                     openBelow: !layout.tile(col, row + 1).isWallLike)

        case .tree:
            baseGround(c, ox, oy, pal, col, row, region: region)
            drawTree(c, o, ox, oy, pal, region: region, rng: &rng)

        case .bush, .secretBush:
            baseGround(c, ox, oy, pal, col, row, region: region)
            let base = kind == .secretBush ? ColorMath.shade(pal.foliage, 0.08) : pal.foliage
            c.ellipse(Double(ox) + 8, Double(oy) + 9, 7.5, 6.5, pal.foliageDark)
            c.ellipse(Double(ox) + 8, Double(oy) + 8, 6.5, 5.5, base)
            for _ in 0..<6 { c.set(ox + rng.int(3...12), oy + rng.int(4...11), pal.foliageLight) }
            if kind == .secretBush {
                // A subtle gap: someone has pushed through here.
                c.vline(ox + 8, oy + 5, oy + 12, pal.foliageDark)
                c.set(ox + 7, oy + 13, pal.path); c.set(ox + 9, oy + 14, pal.path)
            }
            if region == .mountain { c.hline(ox + 4, ox + 11, oy + 3, 0xF0F4F8) }

        case .rock:
            baseGround(c, ox, oy, pal, col, row, region: region)
            c.ellipse(Double(ox) + 8, Double(oy) + 9, 7.5, 6.5, Pal.outline)
            c.ellipse(Double(ox) + 8, Double(oy) + 8.5, 6.8, 5.8, pal.rock)
            c.ellipse(Double(ox) + 6.5, Double(oy) + 7, 3.5, 2.5, pal.rockLight)
            c.set(ox + 10, oy + 11, ColorMath.shade(pal.rock, -0.2)); c.set(ox + 11, oy + 10, ColorMath.shade(pal.rock, -0.2))
            if region == .mountain { c.ellipse(Double(ox) + 8, Double(oy) + 5, 5, 2.2, 0xF0F4F8) }

        case .rail:
            c.fill(ox, oy, size, size, 0x4E4840)
            for _ in 0..<20 { c.set(ox + rng.int(0...15), oy + rng.int(0...15), rng.chance(0.5) ? 0x5E5850 : 0x3E3832) }
            for x in stride(from: 1, to: 16, by: 5) { c.fill(ox + x, oy + 2, 3, 12, 0x4A3424); c.vline(ox + x, oy + 2, oy + 13, 0x5A4430) }
            c.hline(ox, ox + 15, oy + 4, 0x9A9AA2); c.hline(ox, ox + 15, oy + 5, 0x5A5A62)
            c.hline(ox, ox + 15, oy + 11, 0x9A9AA2); c.hline(ox, ox + 15, oy + 12, 0x5A5A62)

        case .platform:
            c.fill(ox, oy, size, size, 0x8A8478)
            c.hline(ox, ox + 15, oy + 15, 0x6E685E); c.vline(ox + 15, oy, oy + 15, 0x6E685E)
            for _ in 0..<6 { c.set(ox + rng.int(0...14), oy + rng.int(0...14), rng.chance(0.5) ? 0x9A948A : 0x7A746A) }
            if layout.tile(col, row + 1) == .rail { c.fill(ox, oy + 13, 16, 2, 0xC0A040); c.hline(ox, ox + 15, oy + 15, 0x5E584E) }
            if region == .mountain && rng.chance(0.4) { c.ellipse(Double(ox + rng.int(3...12)), Double(oy + rng.int(3...10)), 3, 2, 0xE4E8F0) }

        case .water:
            c.fill(ox, oy, size, size, 0x2E4A6A)
            for _ in 0..<3 {
                let x = rng.int(0...11), y = rng.int(1...14)
                c.hline(ox + x, ox + x + 3, oy + y, 0x4A6A8A)
            }

        case .sludge:
            if region == .mountain {
                c.fill(ox, oy, size, size, 0x5A7AA0)
                for _ in 0..<4 { let x = rng.int(0...10), y = rng.int(1...14); c.hline(ox + x, ox + x + 4, oy + y, 0xB8D0E8) }
            } else {
                // Murky toxic sludge with a darker rim where it meets solid ground.
                c.fill(ox, oy, size, size, 0x3A4A24)
                for _ in 0..<10 { c.set(ox + rng.int(0...15), oy + rng.int(0...15), 0x2E3A1C) }
                for _ in 0..<3 { c.circle(Double(ox + rng.int(3...12)), Double(oy + rng.int(3...12)), 1.3, 0x6A8A2A) }
                c.set(ox + rng.int(2...13), oy + rng.int(2...13), 0xB0D050)
                if layout.tile(col, row - 1) != .sludge { c.hline(ox, ox + 15, oy, 0x252E16); c.hline(ox, ox + 15, oy + 1, 0x4E5E2C) }
                if layout.tile(col, row + 1) != .sludge { c.hline(ox, ox + 15, oy + 15, 0x252E16) }
                if layout.tile(col - 1, row) != .sludge { c.vline(ox, oy, oy + 15, 0x252E16) }
                if layout.tile(col + 1, row) != .sludge { c.vline(ox + 15, oy, oy + 15, 0x252E16) }
            }

        case .fallingRocks:
            if region == .mine { c.fill(ox, oy, size, size, pal.floor) } else { baseGround(c, ox, oy, pal, col, row, region: region) }
            c.line(ox + 2, oy + 3, ox + 7, oy + 8, 0x1A1614); c.line(ox + 7, oy + 8, ox + 13, oy + 6, 0x1A1614)
            c.line(ox + 7, oy + 8, ox + 9, oy + 14, 0x1A1614)
            for _ in 0..<7 {
                let x = rng.int(1...14), y = rng.int(1...14)
                c.fill(ox + x, oy + y, 2, 2, pal.rockLight); c.set(ox + x + 1, oy + y + 1, ColorMath.shade(pal.rock, -0.3))
            }

        case .fence:
            baseGround(c, ox, oy, pal, col, row, region: region)
            c.fill(ox + 1, oy + 4, 2, 10, 0x5A4430); c.fill(ox + 13, oy + 4, 2, 10, 0x5A4430)
            c.hline(ox, ox + 15, oy + 6, 0x7A7A80); c.hline(ox, ox + 15, oy + 10, 0x7A7A80)
            c.set(ox + 5, oy + 6, 0xA0A0A8); c.set(ox + 9, oy + 10, 0xA0A0A8)

        case .rubble:
            if region == .forest {
                baseGround(c, ox, oy, pal, col, row, region: region)
                c.fill(ox, oy + 5, 16, 6, 0x5A4030); c.hline(ox, ox + 15, oy + 5, 0x7A5A40); c.hline(ox, ox + 15, oy + 10, 0x3A2A1E)
                c.circle(Double(ox) + 3, Double(oy) + 8, 2, 0x8A6A4A)
            } else {
                if region == .mine && layout.tile(col, row).isWallLike { c.fill(ox, oy, 16, 16, pal.floor) } else { baseGround(c, ox, oy, pal, col, row, region: region) }
                for _ in 0..<6 {
                    let x = rng.int(0...11), y = rng.int(2...12), w = rng.int(3...5)
                    c.fill(ox + x, oy + y, w, 3, rng.chance(0.5) ? pal.rock : 0x7A746A)
                    c.hline(ox + x, ox + x + w - 1, oy + y, pal.rockLight)
                    c.hline(ox + x, ox + x + w - 1, oy + y + 2, ColorMath.shade(pal.rock, -0.35))
                }
                if region == .industrial { c.line(ox + 2, oy + 3, ox + 12, oy + 13, 0x7A4428) }
                if region == .mountain { c.hline(ox + 3, ox + 12, oy + 2, 0xF0F4F8) }
            }

        case .vent:
            c.fill(ox, oy, size, size, 0x3A3A40)
            c.rectOutline(ox + 1, oy + 1, 14, 14, 0x24242A)
            for y in stride(from: 3, to: 14, by: 3) { c.hline(ox + 3, ox + 12, oy + y, 0x1A1A1E); c.hline(ox + 3, ox + 12, oy + y + 1, 0x58585E) }

        case .crates:
            baseFloorOrGround(c, ox, oy, pal, layout, col, row, region)
            c.fill(ox + 1, oy + 1, 14, 14, Pal.outline)
            c.fill(ox + 2, oy + 2, 12, 12, 0x8A6A3A)
            c.rectOutline(ox + 2, oy + 2, 12, 12, 0x6A4E2A)
            c.line(ox + 3, oy + 3, ox + 12, oy + 12, 0x6A4E2A); c.line(ox + 12, oy + 3, ox + 3, oy + 12, 0x6A4E2A)
            c.hline(ox + 2, ox + 13, oy + 2, 0xA88A5A)

        case .barrels:
            baseFloorOrGround(c, ox, oy, pal, layout, col, row, region)
            c.circle(Double(ox) + 8, Double(oy) + 8, 7, Pal.outline)
            c.circle(Double(ox) + 8, Double(oy) + 8, 6, 0x7A3A26)
            c.circle(Double(ox) + 8, Double(oy) + 8, 4.2, 0x9A4A2E)
            c.circle(Double(ox) + 8, Double(oy) + 8, 1.5, 0x3A1E14)
            c.set(ox + 5, oy + 5, 0xC07A4A)

        case .lampPost:
            baseFloorOrGround(c, ox, oy, pal, layout, col, row, region)
            c.ellipse(Double(ox) + 9, Double(oy) + 13, 5, 2, 0x000000, alpha: 70)
            c.fill(ox + 7, oy + 2, 2, 12, 0x3A3A40)
            c.fill(ox + 5, oy + 1, 6, 3, 0x2A2A30)
            c.fill(ox + 6, oy + 2, 4, 2, Pal.amberLight)
        }
    }

    private static func baseFloorOrGround(_ c: PixelCanvas, _ ox: Int, _ oy: Int, _ pal: RegionPalette,
                                          _ layout: StationLayout, _ col: Int, _ row: Int, _ region: Region) {
        // Decorations inside buildings sit on floor; outside on ground.
        let neighbors = [layout.tile(col - 1, row), layout.tile(col + 1, row), layout.tile(col, row - 1), layout.tile(col, row + 1)]
        if neighbors.contains(.floor) {
            c.fill(ox, oy, size, size, pal.floor)
        } else if neighbors.contains(.darkFloor) {
            c.fill(ox, oy, size, size, pal.floor)
        } else {
            baseGround(c, ox, oy, pal, col, row, region: region)
        }
    }

    private static func drawWall(_ c: PixelCanvas, _ ox: Int, _ oy: Int, _ pal: RegionPalette, region: Region,
                                 cracked: Bool, rng: inout SeededRandom, openBelow: Bool) {
        c.fill(ox, oy, size, size, pal.wall)
        switch region {
        case .depot:
            for y in stride(from: 0, to: 16, by: 4) {
                c.hline(ox, ox + 15, oy + y, pal.wallDark)
                let off = (y / 4) % 2 == 0 ? 0 : 4
                for x in stride(from: off, to: 16, by: 8) { c.vline(ox + x, oy + y, oy + y + 3, pal.wallDark) }
            }
            for _ in 0..<5 { c.set(ox + rng.int(0...15), oy + rng.int(0...15), pal.wallLight) }
        case .forest:
            for y in stride(from: 0, to: 16, by: 5) {
                c.hline(ox, ox + 15, oy + y, pal.wallDark); c.hline(ox, ox + 15, oy + y + 1, pal.wallLight)
            }
        case .industrial:
            for x in stride(from: 0, to: 16, by: 3) { c.vline(ox + x, oy, oy + 15, pal.wallDark); c.vline(ox + x + 1, oy, oy + 15, pal.wallLight) }
            if rng.chance(0.4) { c.ellipse(Double(ox + rng.int(3...12)), Double(oy + rng.int(3...12)), 3, 4, 0x7A4428, alpha: 140) }
        case .mine:
            for _ in 0..<10 {
                let x = rng.int(0...13), y = rng.int(0...13)
                c.fill(ox + x, oy + y, rng.int(2...3), 2, rng.chance(0.5) ? pal.wallLight : pal.wallDark)
            }
        case .mountain:
            for y in stride(from: 0, to: 16, by: 5) {
                c.hline(ox, ox + 15, oy + y, pal.wallDark)
                let off = (y / 5) % 2 == 0 ? 2 : 7
                c.vline(ox + off, oy + y, oy + y + 4, pal.wallDark); c.vline(ox + off + 8, oy + y, oy + y + 4, pal.wallDark)
            }
        }
        if openBelow {
            // Front face shadow gives a hint of height.
            c.hline(ox, ox + 15, oy + 14, pal.wallDark); c.hline(ox, ox + 15, oy + 15, Pal.outline)
        }
        if cracked {
            c.line(ox + 3, oy + 1, ox + 7, oy + 7, 0x15100E); c.line(ox + 7, oy + 7, ox + 5, oy + 14, 0x15100E)
            c.line(ox + 7, oy + 7, ox + 12, oy + 10, 0x15100E)
            c.set(ox + 8, oy + 8, 0x0A0806); c.set(ox + 6, oy + 9, 0x0A0806)
        }
    }

    private static func drawTree(_ c: PixelCanvas, _ o: PixelCanvas, _ ox: Int, _ oy: Int, _ pal: RegionPalette,
                                 region: Region, rng: inout SeededRandom) {
        // Trunk on the ground layer, canopy on the overlay (drawn above the player).
        c.ellipse(Double(ox) + 8, Double(oy) + 13, 6, 2.5, 0x000000, alpha: 60)
        c.fill(ox + 6, oy + 8, 4, 7, pal.trunk); c.vline(ox + 6, oy + 8, oy + 14, ColorMath.shade(pal.trunk, 0.15))
        let cx = Double(ox) + 8 + Double(rng.int(-1...1)), top = Double(oy) - 6
        switch region {
        case .forest, .mountain, .mine:
            // Spruce: stacked triangles.
            for (i, w) in [3.0, 5.0, 7.0, 8.5].enumerated() {
                let y = top + Double(i) * 4.5
                for dy in 0..<6 {
                    let half = w * Double(dy + 1) / 6
                    let yy = Int(y) + dy
                    o.hline(Int(cx - half), Int(cx + half), yy, dy == 5 ? pal.foliageDark : pal.foliage)
                }
                o.hline(Int(cx - w * 0.3), Int(cx), Int(y) + 2, pal.foliageLight)
                if region == .mountain { o.hline(Int(cx - w * 0.5), Int(cx + w * 0.2), Int(y) + 1, 0xEEF2F8) }
            }
            o.set(Int(cx), Int(top) - 1, pal.foliage)
        case .depot, .industrial:
            // Gnarled leafy/dead tree.
            o.ellipse(cx, top + 10, 8, 7, pal.foliageDark)
            o.ellipse(cx - 1, top + 9, 7, 6, pal.foliage)
            for _ in 0..<8 { o.set(Int(cx) + rng.int(-5...4), Int(top) + rng.int(4...14), pal.foliageLight) }
            if region == .industrial {
                for _ in 0..<10 { o.clear(Int(cx) + rng.int(-6...6), Int(top) + rng.int(3...16)) }
            }
        }
    }
}

extension TileKind {
    var isWallLike: Bool { self == .wall || self == .crackedWall }
}
