import Foundation

/// Derived train numbers. Computed from `GameState` so they can never drift out of sync.
struct TrainStats: Equatable {
    let pullCapacity: Double
    let fuelCapacity: Double
    let efficiencyMultiplier: Double
    let storageCapacity: Int
    let backpackCapacity: Int
    let totalWeight: Double
    let workshopLevel: Int

    static let baseFuelPerDistance: Double = 3
    static let goodsPerTon = 20

    init(state: GameState) {
        let t = state.train
        pullCapacity = 40 + (t.engineLevel >= 1 ? 15 : 0) + (t.engineLevel >= 2 ? 20 : 0)
        fuelCapacity = 30 + Double(t.tankLevel) * 20
        efficiencyMultiplier = 1 - 0.25 * Double(min(t.efficiencyLevel, 2))
        storageCapacity = t.wagons.reduce(0) { $0 + WagonCatalog.info($1.type).storageCapacity } + t.storageLevel * 60
        backpackCapacity = 30 + t.backpackLevel * 30
        let wagonWeight = t.wagons.reduce(0.0) { $0 + WagonCatalog.info($1.type).weight }
        totalWeight = wagonWeight + Double(state.inventory.storageUsed / TrainStats.goodsPerTon)
        workshopLevel = t.has(wagon: .workshop) ? 2 : (t.hasWorkshopBench ? 1 : 0)
        condition = t.condition
        engineLevel = t.engineLevel
    }

    let condition: Double
    let engineLevel: Int

    /// >1 when the train is heavier than the locomotive can comfortably pull.
    var weightFactor: Double { max(1, totalWeight / pullCapacity) }

    var conditionFactor: Double {
        if condition < 25 { return 1.4 }
        if condition < 50 { return 1.2 }
        return 1
    }

    var fuelPerDistance: Double {
        TrainStats.baseFuelPerDistance * efficiencyMultiplier * weightFactor * conditionFactor
    }

    func fuelCost(distance: Double) -> Double {
        (fuelPerDistance * distance * 10).rounded() / 10
    }

    func travelDuration(distance: Double) -> Double {
        let base = 5 + 2.5 * distance
        let engine = engineLevel >= 2 ? 0.8 : 1
        return base * engine * min(weightFactor, 1.5)
    }
}
