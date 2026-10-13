import Testing
@testable import The_Last_Rail

@MainActor
struct InventoryTests {
    @Test func addRespectsBackpackCapacity() {
        var s = GameState.newGame()
        let cap = InventorySystem.capacity(.backpack, s)
        let added = InventorySystem.add(.scrap, cap + 10, to: .backpack, &s)
        #expect(added == cap)
        #expect(s.inventory.backpackCount(.scrap) == cap)
        #expect(InventorySystem.add(.wood, 1, to: .backpack, &s) == 0)
    }

    @Test func stackLimitIsRespected() {
        var s = GameState.newGame()
        s.train.storageLevel = 5
        let limit = ResourceCatalog.info(.fuel).stackLimit!
        InventorySystem.add(.fuel, limit + 5, to: .storage, &s)
        #expect(s.inventory.storageCount(.fuel) == limit)
    }

    @Test func consumeIsAtomicAndUsesBackpackFirst() {
        var s = GameState.newGame()
        InventorySystem.add(.scrap, 4, to: .backpack, &s)
        InventorySystem.add(.scrap, 10, to: .storage, &s)
        InventorySystem.add(.wood, 1, to: .storage, &s)
        // Cannot afford: nothing changes.
        #expect(!InventorySystem.consume([.scrap: 6, .wood: 2], &s))
        #expect(s.inventory.total(.scrap) == 14)
        #expect(s.inventory.total(.wood) == 1)
        // Affordable: backpack drained first.
        #expect(InventorySystem.consume([.scrap: 6], &s))
        #expect(s.inventory.backpackCount(.scrap) == 0)
        #expect(s.inventory.storageCount(.scrap) == 8)
    }

    @Test func unloadMovesWhatFitsAndKeepsLeftovers() {
        var s = GameState.newGame()
        let storageCap = InventorySystem.capacity(.storage, s)
        InventorySystem.add(.coal, storageCap - 5, to: .storage, &s)
        InventorySystem.add(.scrap, 12, to: .backpack, &s)
        let moved = InventorySystem.unloadBackpack(&s)
        #expect(moved[.scrap] == 5)
        #expect(s.inventory.backpackCount(.scrap) == 7)
        #expect(s.inventory.storageUsed == storageCap)
    }

    @Test func faintPenaltyHalvesCarriedResources() {
        var s = GameState.newGame()
        InventorySystem.add(.scrap, 9, to: .backpack, &s)
        InventorySystem.add(.wood, 1, to: .backpack, &s)
        InventorySystem.add(.copper, 6, to: .storage, &s)
        s.health = 0
        let lost = InteractionSystem.faint(&s)
        #expect(lost[.scrap] == 4)
        #expect(lost[.wood] == nil)
        #expect(s.inventory.backpackCount(.scrap) == 5)
        #expect(s.inventory.storageCount(.copper) == 6, "Train storage is never affected")
        #expect(s.health == GameState.maxHealth)
    }

    @Test func refuelBurnsResourcesWithoutOverfilling() {
        var s = GameState.newGame()
        s.train.locomotiveRepaired = true
        s.train.fuel = 25
        InventorySystem.add(.fuel, 2, to: .storage, &s)
        InventorySystem.add(.wood, 5, to: .storage, &s)
        // "Fill tank" never burns wood, and a canister would overflow.
        #expect(InventorySystem.autoRefuel(&s) == 0)
        #expect(s.inventory.total(.wood) == 5)
        // Refuelling for a trip burns just enough, wood included if needed.
        #expect(InventorySystem.refuel(to: 29, &s))
        #expect(s.train.fuel == 29)
        #expect(s.train.fuel <= TrainStats(state: s).fuelCapacity)
        #expect(s.inventory.total(.fuel) == 2)
        #expect(s.inventory.total(.wood) == 3)
        #expect(!InventorySystem.refuel(to: 45, &s), "Cannot exceed tank capacity")
    }

    @Test func eatingHealsAndConsumesFood() {
        var s = GameState.newGame()
        s.health = 50
        InventorySystem.add(.food, 1, to: .backpack, &s)
        #expect(InteractionSystem.eat(&s))
        #expect(s.health == 80)
        #expect(s.inventory.total(.food) == 0)
        #expect(!InteractionSystem.eat(&s))
    }
}
