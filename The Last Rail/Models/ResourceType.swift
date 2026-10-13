import Foundation

/// Raw materials gathered while exploring. Stable string identifiers are used in save files.
enum ResourceType: String, Codable, CaseIterable, Identifiable, CodingKeyRepresentable {
    case scrap = "jarnskrot"
    case wood = "tra"
    case copper = "koppar"
    case coal = "kol"
    case fuel = "bransle"
    case machineParts = "maskindelar"
    case food = "mat"
    case researchParts = "forskningsdelar"

    var id: String { rawValue }
}

/// Static description of a resource. Content lives in `ResourceCatalog`.
struct ResourceInfo {
    let type: ResourceType
    let name: String
    let description: String
    /// Optional per-container stack limit. `nil` means only the container capacity applies.
    let stackLimit: Int?
    /// Fuel units gained when the resource is burned in the locomotive (0 = not burnable).
    let fuelValue: Double
}

/// Crafted tools, quest items and consumables. These do not use cargo space.
enum ItemType: String, Codable, CaseIterable, Identifiable, CodingKeyRepresentable {
    case crowbar = "kofot"
    case headlamp = "pannlampa"
    case fuse = "sakring"
    case repairKit = "reparationssats"
    case signalDecoder = "signalavkodare"

    var id: String { rawValue }
}

enum ItemKind {
    case tool
    case keyItem
    case consumable
}

struct ItemInfo {
    let type: ItemType
    let name: String
    let description: String
    let kind: ItemKind
}

typealias ResourceCost = [ResourceType: Int]
