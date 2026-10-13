import Foundation

/// The game's limited color palette (hex RGB).
enum Pal {
    static let outline: UInt32 = 0x1A1418
    static let night: UInt32 = 0x14161C
    static let cream: UInt32 = 0xF0E6C8
    static let amber: UInt32 = 0xE0A040
    static let amberLight: UInt32 = 0xF0C060
    static let rust: UInt32 = 0xB06A3A
    static let rustDark: UInt32 = 0x7A4428
    static let forest: UInt32 = 0x2F5A3A
    static let forestDark: UInt32 = 0x1F3A2C
    static let blue: UInt32 = 0x5A7898
    static let blueDark: UInt32 = 0x3A5068
    static let gray: UInt32 = 0x8A8A90
    static let grayDark: UInt32 = 0x4A4A50
    static let grayLight: UInt32 = 0xB0B0B8

    /// Character palette for ASCII sprites.
    static let ascii: [Character: UInt32] = [
        "k": 0x1A1418, "w": 0xF0E6C8, "W": 0xFFFFFF,
        "g": 0x8A8A90, "G": 0x5A5A62, "h": 0xB0B0B8, "d": 0x3A3A40,
        "r": 0xB06A3A, "R": 0x7A4428, "o": 0xE0A040, "y": 0xF0C060,
        "b": 0x5A7898, "B": 0x3A5068, "c": 0x8AA8C0,
        "n": 0x6A4E36, "N": 0x4A3424, "l": 0x8A6A3A, "L": 0xA88A5A,
        "e": 0x3A5A34, "E": 0x2A3A28, "f": 0x6A9A58,
        "p": 0xC04040, "P": 0x802828, "m": 0xD06AA0,
        "u": 0xC87A3A, "U": 0x8A4A24, "s": 0xE0B088, "S": 0xB88060,
        "v": 0x7AE0A0, "V": 0x3AA070, "x": 0x2A2A2A, "X": 0x404044,
        "i": 0xD8E4F0, "I": 0xA0B4C8,
    ]
}

/// Per-region colors used by tiles and backgrounds.
struct RegionPalette {
    let ground: UInt32
    let groundAlt: UInt32
    let groundDark: UInt32
    let path: UInt32
    let floor: UInt32
    let floorLine: UInt32
    let wall: UInt32
    let wallDark: UInt32
    let wallLight: UInt32
    let foliage: UInt32
    let foliageDark: UInt32
    let foliageLight: UInt32
    let trunk: UInt32
    let rock: UInt32
    let rockLight: UInt32
    let hazard: UInt32
    let hazardLight: UInt32
    // Sky (side view)
    let skyTop: UInt32
    let skyHorizon: UInt32
    let farMountain: UInt32
    let midHill: UInt32
    let nearLand: UInt32

    static func of(_ region: Region) -> RegionPalette {
        switch region {
        case .depot:
            return RegionPalette(ground: 0x5E564A, groundAlt: 0x6A6152, groundDark: 0x4C463C, path: 0x7A7060,
                                 floor: 0x5C5650, floorLine: 0x4A4440, wall: 0x6A3A2A, wallDark: 0x4A2820, wallLight: 0x8A5038,
                                 foliage: 0x4A5A30, foliageDark: 0x34402A, foliageLight: 0x6A7A40, trunk: 0x4A3424,
                                 rock: 0x6E6A64, rockLight: 0x8E8A82, hazard: 0x4A6A2A, hazardLight: 0x8AAA3A,
                                 skyTop: 0x2E3450, skyHorizon: 0xE09A5A, farMountain: 0x5A4E60, midHill: 0x4A4248, nearLand: 0x3A342E)
        case .forest:
            return RegionPalette(ground: 0x3A5A34, groundAlt: 0x456A3C, groundDark: 0x2F4A2C, path: 0x6A5A40,
                                 floor: 0x6A4E36, floorLine: 0x4A3424, wall: 0x5A4030, wallDark: 0x3E2C20, wallLight: 0x7A5A40,
                                 foliage: 0x2A4A30, foliageDark: 0x1A3022, foliageLight: 0x3E6A40, trunk: 0x4A3424,
                                 rock: 0x5E6260, rockLight: 0x7E8480, hazard: 0x2E4A6A, hazardLight: 0x4A6A8A,
                                 skyTop: 0x3A4A5E, skyHorizon: 0x8A9AA0, farMountain: 0x4A5A68, midHill: 0x2E4A3C, nearLand: 0x1F3A2C)
        case .industrial:
            return RegionPalette(ground: 0x3C3C42, groundAlt: 0x46454A, groundDark: 0x303034, path: 0x55555A,
                                 floor: 0x5A5A5E, floorLine: 0x48484C, wall: 0x4A5058, wallDark: 0x32363C, wallLight: 0x68707A,
                                 foliage: 0x4A5034, foliageDark: 0x343828, foliageLight: 0x5E6440, trunk: 0x3A3430,
                                 rock: 0x5A5652, rockLight: 0x7A7672, hazard: 0x4A6A2A, hazardLight: 0x9ABA3A,
                                 skyTop: 0x3A3238, skyHorizon: 0xB07A50, farMountain: 0x4E4448, midHill: 0x3A3438, nearLand: 0x2A2628)
        case .mine:
            return RegionPalette(ground: 0x6A6058, groundAlt: 0x74695F, groundDark: 0x564C46, path: 0x7A6E60,
                                 floor: 0x2E2824, floorLine: 0x3A322C, wall: 0x3A3430, wallDark: 0x26201E, wallLight: 0x4E4640,
                                 foliage: 0x2E4430, foliageDark: 0x1E2E22, foliageLight: 0x3E5A40, trunk: 0x3A2A20,
                                 rock: 0x5A5048, rockLight: 0x7A6E62, hazard: 0x6A5A40, hazardLight: 0x8A7A5A,
                                 skyTop: 0x262A44, skyHorizon: 0x9A6A7A, farMountain: 0x3E3A50, midHill: 0x48403E, nearLand: 0x2E2824)
        case .mountain:
            return RegionPalette(ground: 0xD8DEE8, groundAlt: 0xE4E8F0, groundDark: 0xC0C8D8, path: 0xB8C0CC,
                                 floor: 0x6A5040, floorLine: 0x4E3A2E, wall: 0x6A6E78, wallDark: 0x4A4E58, wallLight: 0x8A8E98,
                                 foliage: 0x2E4A40, foliageDark: 0x1E3430, foliageLight: 0x4A6A5A, trunk: 0x3A2E28,
                                 rock: 0x5E6470, rockLight: 0x8A92A0, hazard: 0x6A8AB0, hazardLight: 0xB8D0E8,
                                 skyTop: 0x2A3A5A, skyHorizon: 0xB8C8DC, farMountain: 0x8A98B0, midHill: 0x5A6A80, nearLand: 0x3A4658)
        }
    }
}
