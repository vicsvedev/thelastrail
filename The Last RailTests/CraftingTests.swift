import Testing
@testable import The_Last_Rail

@MainActor
struct CraftingTests {
    private func readyState() -> GameState {
        var s = GameState.newGame()
        s.train.locomotiveRepaired = true
        s.location = .onTrain
        return s
    }

    @Test func workshopNeedsBlueprint() {
        var s = readyState()
        InventorySystem.add(.scrap, 10, to: .storage, &s)
        InventorySystem.add(.wood, 5, to: .storage, &s)
        #expect(CraftingSystem.status(RecipeCatalog.recipe(.workshop), s) == .unknown)
        #expect(!CraftingSystem.craft(.workshop, &s).succeeded)
        s.knownBlueprints.insert(.workshop)
        #expect(CraftingSystem.status(RecipeCatalog.recipe(.workshop), s) == .available)
    }

    @Test func craftingConsumesExactCostAndAppliesEffect() {
        var s = readyState()
        s.knownBlueprints.insert(.workshop)
        InventorySystem.add(.scrap, 13, to: .storage, &s)
        InventorySystem.add(.wood, 7, to: .storage, &s)
        let result = CraftingSystem.craft(.workshop, &s)
        #expect(result.succeeded)
        #expect(s.inventory.total(.scrap) == 3)
        #expect(s.inventory.total(.wood) == 2)
        #expect(s.train.hasWorkshopBench)
        #expect(TrainStats(state: s).workshopLevel == 1)
    }

    @Test func oneTimeUpgradesCannotBeBoughtTwice() {
        var s = readyState()
        CraftingSystem.apply(.installModule(.workshopBench), &s)
        InventorySystem.add(.scrap, 40, to: .storage, &s)
        InventorySystem.add(.copper, 10, to: .storage, &s)
        #expect(CraftingSystem.craft(.engine1, &s).succeeded)
        #expect(s.train.engineLevel == 1)
        let before = s.inventory
        #expect(!CraftingSystem.craft(.engine1, &s).succeeded)
        #expect(s.inventory == before, "A rejected craft must not consume anything")
        #expect(CraftingSystem.status(RecipeCatalog.recipe(.engine1), s) == .alreadyBuilt)
    }

    @Test func missingResourcesAreReported() {
        var s = readyState()
        CraftingSystem.apply(.installModule(.workshopBench), &s)
        InventorySystem.add(.scrap, 12, to: .storage, &s)
        let status = CraftingSystem.status(RecipeCatalog.recipe(.engine1), s)
        #expect(status == .missingResources([.scrap: 3, .copper: 5]))
    }

    @Test func workshopLevelGatesRecipes() {
        var s = readyState()
        InventorySystem.add(.scrap, 50, to: .storage, &s)
        guard case .locked = CraftingSystem.status(RecipeCatalog.recipe(.crowbar), s) else {
            Issue.record("Crowbar should need a workshop"); return
        }
        CraftingSystem.apply(.installModule(.workshopBench), &s)
        guard case .locked = CraftingSystem.status(RecipeCatalog.recipe(.signalDecoder), s) else {
            Issue.record("Decoder should need a workshop wagon"); return
        }
        CraftingSystem.apply(.addWagon(.workshop), &s)
        #expect(TrainStats(state: s).workshopLevel == 2)
    }

    @Test func repeatableRepairRestoresCondition() {
        var s = readyState()
        s.train.condition = 50
        InventorySystem.add(.scrap, 12, to: .storage, &s)
        #expect(CraftingSystem.craft(.simpleRepair, &s).succeeded)
        #expect(s.train.condition == 80)
        #expect(CraftingSystem.craft(.simpleRepair, &s).succeeded)
        #expect(s.train.condition == 100)
        #expect(!CraftingSystem.craft(.simpleRepair, &s).succeeded, "Already at full condition")
    }

    @Test func upgradesHaveRealEffects() {
        var s = readyState()
        let base = TrainStats(state: s)
        CraftingSystem.apply(.engineLevel(1), &s)
        CraftingSystem.apply(.efficiencyLevel(1), &s)
        CraftingSystem.apply(.tankLevel(1), &s)
        CraftingSystem.apply(.storageLevel(1), &s)
        CraftingSystem.apply(.backpackLevel(1), &s)
        let up = TrainStats(state: s)
        #expect(up.pullCapacity > base.pullCapacity)
        #expect(up.fuelPerDistance < base.fuelPerDistance)
        #expect(up.fuelCapacity > base.fuelCapacity)
        #expect(up.storageCapacity > base.storageCapacity)
        #expect(up.backpackCapacity > base.backpackCapacity)
    }

    @Test func wagonsAddWeightAndCanSlowTheTrain() {
        var s = readyState()
        CraftingSystem.apply(.addWagon(.workshop), &s)
        CraftingSystem.apply(.addWagon(.living), &s)
        CraftingSystem.apply(.addWagon(.cargo), &s)
        let stats = TrainStats(state: s)
        #expect(stats.totalWeight > stats.pullCapacity)
        #expect(stats.weightFactor > 1)
        #expect(stats.fuelCost(distance: 4) > TrainStats(state: readyState()).fuelCost(distance: 4))
    }

    @Test func allRecipesAreConsistent() {
        let ids = Set(RecipeCatalog.all.map(\.id))
        #expect(ids.count == RecipeCatalog.all.count, "Duplicate recipe ids")
        #expect(ids == Set(RecipeID.allCases), "Every RecipeID needs a catalog entry")
        for r in RecipeCatalog.all {
            #expect(!r.name.isEmpty && !r.description.isEmpty)
            #expect(r.cost.values.allSatisfy { $0 > 0 })
        }
    }
}
