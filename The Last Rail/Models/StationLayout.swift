import Foundation

/// Tile types used by handcrafted station layouts. Each is written as one character in the map strings.
enum TileKind: Character, CaseIterable {
    case ground = "."
    case path = ","
    case floor = "_"
    case wall = "#"
    case tree = "T"
    case bush = "t"
    case secretBush = "b"
    case rock = "R"
    case rail = "="
    case platform = "P"
    case water = "w"
    case sludge = "~"
    case fallingRocks = "^"
    case fence = "F"
    case rubble = "x"
    case crackedWall = "X"
    case vent = "V"
    case crates = "c"
    case barrels = "k"
    case tallGrass = "g"
    case flowers = "f"
    case lampPost = "L"
    case darkFloor = ":"

    init(char: Character) {
        self = TileKind(rawValue: char) ?? .ground
    }

    var isSolid: Bool {
        switch self {
        case .wall, .tree, .bush, .rock, .water, .fence, .rubble, .crates, .barrels, .lampPost:
            return true
        default:
            return false
        }
    }

    /// Damage per second while standing on this tile (vents are handled as periodic).
    var hazardDamage: Double {
        switch self {
        case .sludge: return 9
        case .fallingRocks: return 7
        case .vent: return 16
        default: return 0
        }
    }
}

struct TilePoint: Equatable, Hashable, Codable {
    var col: Int
    var row: Int
}

struct TileRect: Equatable {
    var col: Int
    var row: Int
    var width: Int
    var height: Int

    func contains(_ p: TilePoint) -> Bool {
        p.col >= col && p.col < col + width && p.row >= row && p.row < row + height
    }
}

enum LockRequirement: Equatable {
    /// A tool that is required but not consumed.
    case tool(ItemType)
    /// A numeric code entered on a keypad.
    case code(String)
}

/// Special machines with bespoke interactions.
enum MachineKind: Equatable {
    /// Rosthamn signal box: needs a fuse and a repair kit, switches the northern junction.
    case signalBox
    /// Nordpasset backup generator: needs coal.
    case generator
    /// Nordpasset radio terminal: needs generator power, reveals the main story discovery.
    case radioTerminal
    /// Locomotive radio at the depot (atmosphere).
    case depotRadio
}

enum MapObjectKind: Equatable {
    case resource(ResourceType, Int)
    case container(ResourceCost, [ItemType])
    case note(JournalID)
    case blueprint(RecipeID, JournalID)
    case keyItem(ItemType)
    case door(LockRequirement)
    /// Blocks movement until the requirement is met. Never "opened"; re-evaluated live.
    case barrier(LockRequirement, String)
    case machine(MachineKind)
    case sign(String, String)
}

enum ObjectLook: String {
    case scrapPile, woodPile, copperSpool, copperOre, coalPile, coalBin, fuelCan, oilDrum
    case berryBush, foodCrate, gearBox, researchBox
    case crate, locker, toolbox
    case note, blueprint, fuse
    case doorWood, doorMetal, keypadDoor, darkness
    case signalBox, generator, terminal, radio, sign, cairn
}

struct MapObjectDef: Equatable {
    let id: String
    let kind: MapObjectKind
    let at: TilePoint
    var look: ObjectLook
    var renewable = false
    var secret: SecretID?
    /// The object only exists once this flag is set (e.g. post-tutorial renewables).
    var requires: StoryFlag?

    var isSolid: Bool {
        switch kind {
        case .door, .barrier, .machine: return true
        case .container: return true
        default: return false
        }
    }
}

struct BuildingDef: Equatable {
    let id: String
    let name: String
    /// Interior incl. walls; the roof covers this rect.
    let rect: TileRect
    let roofColor: UInt32
}

enum ZoneKind: Equatable {
    case tutorialWorkshop
    case secret(SecretID)
    case caption(String)
}

struct ZoneDef: Equatable {
    let id: String
    let rect: TileRect
    let kind: ZoneKind
}

enum Weather: String {
    case none, rain, snow, fog, dust
}

/// Handcrafted layout of an explorable station.
struct StationLayout {
    let station: StationID
    let rows: [String]
    let objects: [MapObjectDef]
    let buildings: [BuildingDef]
    let zones: [ZoneDef]
    /// Tile of the locomotive's front (east end). Wagons extend west on the same row.
    let trainFront: TilePoint
    let spawn: TilePoint
    /// Areas covered by darkness; the player's light radius matters there.
    let darkAreas: [TileRect]
    let weather: Weather
    let width: Int
    let height: Int
    private let grid: [TileKind]

    init(station: StationID, rows: [String], objects: [MapObjectDef], buildings: [BuildingDef],
         zones: [ZoneDef], trainFront: TilePoint, spawn: TilePoint, darkAreas: [TileRect] = [], weather: Weather = .none) {
        self.station = station
        self.rows = rows
        self.objects = objects
        self.buildings = buildings
        self.zones = zones
        self.trainFront = trainFront
        self.spawn = spawn
        self.darkAreas = darkAreas
        self.weather = weather
        let w = rows.map(\.count).max() ?? 0
        width = w
        height = rows.count
        var g: [TileKind] = []
        g.reserveCapacity(w * rows.count)
        for r in rows {
            let chars = Array(r)
            // Lenient: short rows are padded with ground so a typo never crashes the game.
            for c in 0..<w { g.append(c < chars.count ? TileKind(char: chars[c]) : .ground) }
        }
        grid = g
    }

    func tile(_ col: Int, _ row: Int) -> TileKind {
        guard row >= 0, row < height, col >= 0, col < width else { return .wall }
        return grid[row * width + col]
    }

    func object(_ id: String) -> MapObjectDef? { objects.first { $0.id == id } }
}
