import Foundation

/// The single source of truth for everything the player owns.
///
/// Resources live in one of two containers: the backpack (carried while exploring)
/// and the train storage (cargo wagons). Items (tools, key items, consumables) are
/// tracked separately and never use cargo space. All mutations go through `InventorySystem`.
struct Inventory: Codable, Equatable {
    var backpack: [ResourceType: Int] = [:]
    var storage: [ResourceType: Int] = [:]
    var items: [ItemType: Int] = [:]

    func backpackCount(_ type: ResourceType) -> Int { backpack[type, default: 0] }
    func storageCount(_ type: ResourceType) -> Int { storage[type, default: 0] }
    func total(_ type: ResourceType) -> Int { backpackCount(type) + storageCount(type) }
    func itemCount(_ type: ItemType) -> Int { items[type, default: 0] }
    func has(_ item: ItemType) -> Bool { itemCount(item) > 0 }

    var backpackUsed: Int { backpack.values.reduce(0, +) }
    var storageUsed: Int { storage.values.reduce(0, +) }
}
