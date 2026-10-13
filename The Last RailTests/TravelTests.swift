import Testing
@testable import The_Last_Rail

@MainActor
struct TravelTests {
    private func onTrain() -> GameState {
        var s = TH.finishTutorial()
        s.location = .onTrain
        return s
    }

    @Test func cannotTravelWithBrokenLocomotive() {
        var s = GameState.newGame()
        s.discoveredStations.insert(.tallkorset)
        s.location = .onTrain
        guard case .failure(.locomotiveBroken) = TravelSystem.plan(to: .tallkorset, s) else {
            Issue.record("Expected locomotiveBroken"); return
        }
    }

    @Test func mustBeOnTrain() {
        var s = onTrain()
        s.location = .exploring
        guard case .failure(.notOnTrain) = TravelSystem.plan(to: .tallkorset, s) else {
            Issue.record("Expected notOnTrain"); return
        }
    }

    @Test func onlyConnectedRoutes() {
        var s = onTrain()
        s.discoveredStations.insert(.djupgruvan)
        guard case .failure(.notConnected) = TravelSystem.plan(to: .djupgruvan, s) else {
            Issue.record("Depot is not connected to Djupgruvan"); return
        }
    }

    @Test func lockedRouteNeedsEngineUpgrade() {
        var s = onTrain()
        s.currentStation = .rosthamn
        s.visitedStations.insert(.rosthamn)
        TravelSystem.discoverNeighbors(of: .rosthamn, &s)
        s.train.fuel = 30
        guard case .failure(.routeLocked) = TravelSystem.plan(to: .djupgruvan, s) else {
            Issue.record("Expected locked route"); return
        }
        s.train.engineLevel = 1
        guard case .success = TravelSystem.plan(to: .djupgruvan, s) else {
            Issue.record("Engine I should open the route"); return
        }
    }

    @Test func insufficientFuelBlocksAndTankSizeMatters() {
        var s = onTrain()
        s.currentStation = .tallkorset
        s.flags.insert(.junctionSwitched)
        s.discoveredStations.insert(.nordpasset)
        s.train.fuel = 30
        guard case .failure(.tankTooSmall) = TravelSystem.plan(to: .nordpasset, s) else {
            Issue.record("Northern line should exceed the base tank"); return
        }
        s.train.efficiencyLevel = 1
        guard case .success = TravelSystem.plan(to: .nordpasset, s) else {
            Issue.record("Efficiency should make the northern line possible"); return
        }
        s.train.fuel = 5
        guard case .failure(.insufficientFuel) = TravelSystem.plan(to: .nordpasset, s) else {
            Issue.record("Expected insufficientFuel"); return
        }
    }

    @Test func journeyConsumesExactFuelAndArrives() throws {
        var s = onTrain()
        s.train.fuel = 30
        let plan = try TravelSystem.plan(to: .tallkorset, s).get()
        #expect(plan.duration >= 10 && plan.duration <= 30, "Early travel should take 10–30 s")
        TravelSystem.begin(plan, &s)
        var arrived = false
        var steps = 0
        while !arrived && steps < 10_000 {
            arrived = TravelSystem.advance(0.37, &s)
            steps += 1
        }
        #expect(arrived)
        #expect(abs(s.train.fuel - (30 - plan.fuelCost)) < 0.001)
        #expect(s.currentStation == .tallkorset)
        #expect(s.journey == nil)
        #expect(s.traveledRoutes.contains(.depotTallkorset))
        #expect(s.journeyCount == 1)
        #expect(s.train.condition < 100)
        #expect(s.discoveredStations.contains(.rosthamn), "Arrival reveals neighbouring stations")
    }

    @Test func emergencyTravelPreventsStranding() {
        var s = onTrain()
        s.currentStation = .tallkorset
        s.visitedStations.insert(.tallkorset)
        s.train.fuel = 2
        for type in ResourceType.allCases {
            s.inventory.storage[type] = nil
            s.inventory.backpack[type] = nil
        }
        #expect(TravelSystem.isStranded(s))
        let plan = TravelSystem.emergencyPlan(to: .depot, s)
        #expect(plan != nil)
        TravelSystem.begin(plan!, &s)
        TravelSystem.advance(1000, &s)
        #expect(s.currentStation == .depot)
        #expect(s.train.fuel == 0)
        #expect(s.train.condition <= 80)
    }

    @Test func noEmergencyWhenPlayerHasBurnables() {
        var s = onTrain()
        s.currentStation = .tallkorset
        s.visitedStations.insert(.tallkorset)
        s.train.fuel = 0
        InventorySystem.add(.wood, 10, to: .storage, &s)
        #expect(!TravelSystem.isStranded(s))
        #expect(TravelSystem.emergencyPlan(to: .depot, s) == nil)
    }

    @Test func hiddenRouteAppearsWithFlag() {
        var s = onTrain()
        let mineLine = WorldCatalog.route(.mineLine)
        #expect(!TravelSystem.isRevealed(mineLine, s))
        s.flags.insert(.mineLineRevealed)
        #expect(TravelSystem.isRevealed(mineLine, s))
        #expect(!TravelSystem.isUnlocked(mineLine, s))
        s.flags.insert(.mineLineRepaired)
        #expect(TravelSystem.isUnlocked(mineLine, s))
    }

    @Test func futureRouteIsNeverUnlocked() {
        var s = onTrain()
        s.flags = Set(StoryFlag.allCases)
        s.train.engineLevel = 2
        #expect(!TravelSystem.isUnlocked(WorldCatalog.route(.polarisLine), s))
    }
}
