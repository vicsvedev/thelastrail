import Foundation

enum InventoryContainer {
    case backpack
    case storage
}

/// Central inventory rules. Every change to resources or items goes through here.
enum InventorySystem {
    static func capacity(_ container: InventoryContainer, _ state: GameState) -> Int {
        let stats = TrainStats(state: state)
        return container == .backpack ? stats.backpackCapacity : stats.storageCapacity
    }

    static func used(_ container: InventoryContainer, _ state: GameState) -> Int {
        container == .backpack ? state.inventory.backpackUsed : state.inventory.storageUsed
    }

    static func freeSpace(_ container: InventoryContainer, _ state: GameState) -> Int {
        max(0, capacity(container, state) - used(container, state))
    }

    /// Adds as many as fit (respecting capacity and stack limits). Returns the amount actually added.
    @discardableResult
    static func add(_ type: ResourceType, _ amount: Int, to container: InventoryContainer, _ state: inout GameState) -> Int {
        guard amount > 0 else { return 0 }
        let current = container == .backpack ? state.inventory.backpackCount(type) : state.inventory.storageCount(type)
        var fits = min(amount, freeSpace(container, state))
        if let limit = ResourceCatalog.info(type).stackLimit {
            fits = min(fits, max(0, limit - current))
        }
        guard fits > 0 else { return 0 }
        switch container {
        case .backpack: state.inventory.backpack[type] = current + fits
        case .storage: state.inventory.storage[type] = current + fits
        }
        return fits
    }

    /// Removes from one container. Returns the amount actually removed.
    @discardableResult
    static func remove(_ type: ResourceType, _ amount: Int, from container: InventoryContainer, _ state: inout GameState) -> Int {
        guard amount > 0 else { return 0 }
        let current = container == .backpack ? state.inventory.backpackCount(type) : state.inventory.storageCount(type)
        let taken = min(current, amount)
        let remaining = current - taken
        switch container {
        case .backpack: state.inventory.backpack[type] = remaining == 0 ? nil : remaining
        case .storage: state.inventory.storage[type] = remaining == 0 ? nil : remaining
        }
        return taken
    }

    static func total(_ type: ResourceType, _ state: GameState) -> Int {
        state.inventory.total(type)
    }

    static func missing(_ cost: ResourceCost, _ state: GameState) -> ResourceCost {
        var result: ResourceCost = [:]
        for (type, need) in cost {
            let have = state.inventory.total(type)
            if have < need { result[type] = need - have }
        }
        return result
    }

    static func canAfford(_ cost: ResourceCost, _ state: GameState) -> Bool {
        missing(cost, state).isEmpty
    }

    /// Atomically consumes a cost, taking from the backpack first, then storage.
    /// Returns false (and changes nothing) if the player cannot afford it.
    @discardableResult
    static func consume(_ cost: ResourceCost, _ state: inout GameState) -> Bool {
        guard canAfford(cost, state) else { return false }
        for (type, need) in cost {
            let fromBackpack = remove(type, need, from: .backpack, &state)
            if fromBackpack < need {
                remove(type, need - fromBackpack, from: .storage, &state)
            }
        }
        return true
    }

    /// Moves everything that fits from the backpack into train storage.
    /// Returns what was moved; leftovers stay in the backpack.
    @discardableResult
    static func unloadBackpack(_ state: inout GameState) -> ResourceCost {
        var moved: ResourceCost = [:]
        for type in ResourceType.allCases {
            let carried = state.inventory.backpackCount(type)
            guard carried > 0 else { continue }
            let added = add(type, carried, to: .storage, &state)
            if added > 0 {
                remove(type, added, from: .backpack, &state)
                moved[type] = added
            }
        }
        return moved
    }

    /// Mild death penalty: lose half (rounded down) of each carried resource.
    @discardableResult
    static func applyFaintPenalty(_ state: inout GameState) -> ResourceCost {
        var lost: ResourceCost = [:]
        for type in ResourceType.allCases {
            let carried = state.inventory.backpackCount(type)
            let loss = carried / 2
            if loss > 0 {
                remove(type, loss, from: .backpack, &state)
                lost[type] = loss
            }
        }
        return lost
    }

    // MARK: Items

    static func addItem(_ item: ItemType, _ count: Int = 1, _ state: inout GameState) {
        state.inventory.items[item, default: 0] += count
    }

    @discardableResult
    static func removeItem(_ item: ItemType, _ count: Int = 1, _ state: inout GameState) -> Bool {
        let have = state.inventory.itemCount(item)
        guard have >= count else { return false }
        state.inventory.items[item] = have - count == 0 ? nil : have - count
        return true
    }

    // MARK: Fuel

    /// Burns resources (from storage, then backpack) into the locomotive tank. Returns units added.
    @discardableResult
    static func refuel(with type: ResourceType, maxUnits: Int = .max, _ state: inout GameState) -> Double {
        let value = ResourceCatalog.info(type).fuelValue
        guard value > 0 else { return 0 }
        let capacity = TrainStats(state: state).fuelCapacity
        var added = 0.0
        var burned = 0
        while burned < maxUnits, state.train.fuel + value <= capacity + 0.0001, state.inventory.total(type) > 0 {
            if remove(type, 1, from: .storage, &state) == 0 {
                remove(type, 1, from: .backpack, &state)
            }
            state.train.fuel += value
            added += value
            burned += 1
        }
        return added
    }

    /// Fills the tank with coal and fuel (never wood). Returns units added.
    @discardableResult
    static func autoRefuel(_ state: inout GameState) -> Double {
        var total = 0.0
        for type in ResourceCatalog.tankFillers {
            total += refuel(with: type, &state)
        }
        return total
    }

    /// Whether burning what the player owns can bring the tank up to `need`.
    static func canRefuel(to need: Double, _ state: GameState) -> Bool {
        need <= TrainStats(state: state).fuelCapacity + 0.0001 && state.train.fuel + burnableFuelValue(state) >= need - 0.0001
    }

    /// Burns the least valuable fuel first (coal, fuel, then wood) until the tank holds `need`.
    @discardableResult
    static func refuel(to need: Double, _ state: inout GameState) -> Bool {
        guard canRefuel(to: need, state) else { return false }
        for type in ResourceCatalog.burnables {
            while state.train.fuel < need - 0.0001, state.inventory.total(type) > 0 {
                if refuel(with: type, maxUnits: 1, &state) == 0 { break }
            }
        }
        return state.train.fuel >= need - 0.0001
    }

    /// Fuel units obtainable from everything the player owns right now.
    static func burnableFuelValue(_ state: GameState) -> Double {
        ResourceCatalog.burnables.reduce(0) { $0 + Double(state.inventory.total($1)) * ResourceCatalog.info($1).fuelValue }
    }
}
