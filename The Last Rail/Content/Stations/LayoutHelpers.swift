import Foundation

/// Small builders that keep the handcrafted station files readable.
enum L {
    static func defaultLook(_ type: ResourceType) -> ObjectLook {
        switch type {
        case .scrap: return .scrapPile
        case .wood: return .woodPile
        case .copper: return .copperSpool
        case .coal: return .coalPile
        case .fuel: return .fuelCan
        case .machineParts: return .gearBox
        case .food: return .foodCrate
        case .researchParts: return .researchBox
        }
    }

    static func res(_ id: String, _ type: ResourceType, _ amount: Int, _ col: Int, _ row: Int,
                    look: ObjectLook? = nil, renewable: Bool = false, requires: StoryFlag? = nil,
                    secret: SecretID? = nil) -> MapObjectDef {
        MapObjectDef(id: id, kind: .resource(type, amount), at: TilePoint(col: col, row: row),
                     look: look ?? defaultLook(type), renewable: renewable, secret: secret, requires: requires)
    }

    static func crate(_ id: String, _ loot: ResourceCost, items: [ItemType] = [], _ col: Int, _ row: Int,
                      look: ObjectLook = .crate, secret: SecretID? = nil) -> MapObjectDef {
        MapObjectDef(id: id, kind: .container(loot, items), at: TilePoint(col: col, row: row), look: look, secret: secret)
    }

    static func note(_ id: String, _ journal: JournalID, _ col: Int, _ row: Int, look: ObjectLook = .note,
                     secret: SecretID? = nil) -> MapObjectDef {
        MapObjectDef(id: id, kind: .note(journal), at: TilePoint(col: col, row: row), look: look, secret: secret)
    }

    static func blueprint(_ id: String, _ recipe: RecipeID, _ journal: JournalID, _ col: Int, _ row: Int,
                          secret: SecretID? = nil) -> MapObjectDef {
        MapObjectDef(id: id, kind: .blueprint(recipe, journal), at: TilePoint(col: col, row: row), look: .blueprint, secret: secret)
    }

    static func item(_ id: String, _ item: ItemType, _ col: Int, _ row: Int, look: ObjectLook = .fuse) -> MapObjectDef {
        MapObjectDef(id: id, kind: .keyItem(item), at: TilePoint(col: col, row: row), look: look)
    }

    static func door(_ id: String, _ lock: LockRequirement, _ col: Int, _ row: Int, look: ObjectLook = .doorMetal,
                     secret: SecretID? = nil) -> MapObjectDef {
        MapObjectDef(id: id, kind: .door(lock), at: TilePoint(col: col, row: row), look: look, secret: secret)
    }

    static func barrier(_ id: String, _ lock: LockRequirement, _ message: String, _ col: Int, _ row: Int) -> MapObjectDef {
        MapObjectDef(id: id, kind: .barrier(lock, message), at: TilePoint(col: col, row: row), look: .darkness)
    }

    static func machine(_ id: String, _ kind: MachineKind, _ col: Int, _ row: Int, look: ObjectLook) -> MapObjectDef {
        MapObjectDef(id: id, kind: .machine(kind), at: TilePoint(col: col, row: row), look: look)
    }

    static func sign(_ id: String, _ title: String, _ text: String, _ col: Int, _ row: Int) -> MapObjectDef {
        MapObjectDef(id: id, kind: .sign(title, text), at: TilePoint(col: col, row: row), look: .sign)
    }

    static func building(_ id: String, _ name: String, _ col: Int, _ row: Int, _ w: Int, _ h: Int, roof: UInt32) -> BuildingDef {
        BuildingDef(id: id, name: name, rect: TileRect(col: col, row: row, width: w, height: h), roofColor: roof)
    }

    static func zone(_ id: String, _ col: Int, _ row: Int, _ w: Int, _ h: Int, _ kind: ZoneKind) -> ZoneDef {
        ZoneDef(id: id, rect: TileRect(col: col, row: row, width: w, height: h), kind: kind)
    }

    static func p(_ col: Int, _ row: Int) -> TilePoint { TilePoint(col: col, row: row) }
}
