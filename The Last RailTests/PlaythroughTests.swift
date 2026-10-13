import Testing
@testable import The_Last_Rail

/// End-to-end progression using only the real game systems and the authored content.
/// If balance or content changes ever make chapter 1 impossible, these tests fail.
@MainActor
struct PlaythroughTests {
    private func expectTravel(_ to: StationID, _ s: inout GameState, sourceLine: Int = #line) {
        let result = TH.travel(to, &s)
        if case .failure(let block) = result {
            Issue.record("Travel to \(to) failed: \(block.message) (fuel \(s.train.fuel))")
        }
        #expect(s.currentStation == to)
    }

    private func craft(_ id: RecipeID, _ s: inout GameState) {
        let r = CraftingSystem.craft(id, &s)
        if case .failure(let msg) = r { Issue.record("Craft \(id) failed: \(msg)") }
    }

    /// Plays the tutorial for real (not skipped).
    private func playTutorial() -> GameState {
        var s = GameState.newGame()
        s.tutorial.hasMoved = true
        s.tutorial.inspectedLocomotive = true
        for id in ["skrot_1", "skrot_2", "skrot_3", "bransledunk"] { TH.use(id, at: .depot, &s) }
        ProgressionSystem.repairLocomotive(&s)
        TutorialSystem.refresh(&s)
        s.tutorial.openedMapAfterRadio = true
        TutorialSystem.refresh(&s)
        ProgressionSystem.board(&s)
        expectTravel(.tallkorset, &s)
        ProgressionSystem.disembark(&s)
        TH.lootStation(&s)
        s.tutorial.foundTallkorsetWorkshop = true
        TutorialSystem.refresh(&s)
        craft(.workshop, &s)
        TutorialSystem.refresh(&s)
        TutorialSystem.finish(&s)
        #expect(s.tutorial.finished)
        return s
    }

    @Test func chapterOneViaMineLine() {
        var s = playTutorial()
        // Rosthamn: copper and machine parts.
        expectTravel(.rosthamn, &s)
        ProgressionSystem.disembark(&s)
        TH.lootStation(&s)
        #expect(s.visitedStations.contains(.rosthamn))
        craft(.engine1, &s)
        #expect(s.train.engineLevel == 1)
        // Djupgruvan
        expectTravel(.djupgruvan, &s)
        ProgressionSystem.disembark(&s)
        TH.lootStation(&s)
        craft(.headlamp, &s)
        #expect(s.inventory.has(.headlamp))
        // The inner shaft is behind the darkness barrier; with the lamp the barrier is gone.
        let barrier = WorldCatalog.layout(.djupgruvan)!.object("morker")!
        #expect(!InteractionSystem.blocksMovement(barrier, station: .djupgruvan, s))
        #expect(s.knownBlueprints.contains(.trackRepair))
        // Gather wood/scrap for the track repair if needed: shuttle to Rosthamn/Tallkorset and back.
        var guardLoops = 0
        while CraftingSystem.status(RecipeCatalog.recipe(.trackRepair), s) != .available && guardLoops < 6 {
            guardLoops += 1
            expectTravel(.rosthamn, &s)
            ProgressionSystem.disembark(&s); TH.lootStation(&s)
            expectTravel(.tallkorset, &s)
            ProgressionSystem.disembark(&s); TH.lootStation(&s)
            expectTravel(.rosthamn, &s)
            expectTravel(.djupgruvan, &s)
            ProgressionSystem.disembark(&s); TH.lootStation(&s)
        }
        craft(.trackRepair, &s)
        #expect(s.has(.mineLineRepaired))
        // Nordpasset and the story discovery.
        expectTravel(.nordpasset, &s)
        ProgressionSystem.disembark(&s)
        TH.lootStation(&s)
        #expect(s.inventory.total(.coal) >= 3, "Nordpasset must provide coal for the generator")
        TH.use("generator", at: .nordpasset, &s)
        TH.use("terminal", at: .nordpasset, &s)
        #expect(s.has(.chapterOneComplete))
        #expect(ProgressionSystem.currentGoal(s).contains("Kapitel 1 avklarat"))
        // And the player can always get home.
        expectTravel(.djupgruvan, &s)
    }

    @Test func chapterOneViaNorthernLine() {
        var s = playTutorial()
        expectTravel(.rosthamn, &s)
        ProgressionSystem.disembark(&s)
        TH.lootStation(&s)
        craft(.crowbar, &s)
        craft(.engine1, &s)
        expectTravel(.djupgruvan, &s)
        ProgressionSystem.disembark(&s)
        TH.lootStation(&s)          // opens the foreman's office with the crowbar → fuse
        #expect(s.inventory.has(.fuse))
        expectTravel(.rosthamn, &s)
        if !s.inventory.has(.repairKit) { craft(.repairKit, &s) }
        TH.use("stallverk", at: .rosthamn, &s)
        #expect(s.has(.junctionSwitched))
        // Northern line needs either efficiency or a bigger tank.
        if CraftingSystem.status(RecipeCatalog.recipe(.efficiency1), s) == .available {
            craft(.efficiency1, &s)
        } else {
            craft(.fuelTank, &s)
        }
        expectTravel(.tallkorset, &s)
        ProgressionSystem.disembark(&s); TH.lootStation(&s)
        expectTravel(.nordpasset, &s)
        #expect(s.visitedStations.contains(.nordpasset))
    }

    @Test func noRouteEverStrandsThePlayer() {
        // From every visited station with an empty tank, either burnables exist or emergency travel works.
        var s = TH.finishTutorial()
        for station in [StationID.depot, .tallkorset, .rosthamn] {
            s.currentStation = station
            s.visitedStations.insert(station)
            s.location = .onTrain
            s.train.fuel = 0
            for t in ResourceType.allCases { s.inventory.storage[t] = nil; s.inventory.backpack[t] = nil }
            let neighbor = WorldCatalog.routes(from: station).first { TravelSystem.isUnlocked($0, s) }!.other(than: station)!
            s.visitedStations.insert(neighbor)
            #expect(TravelSystem.emergencyPlan(to: neighbor, s) != nil, "\(station) would strand the player")
        }
    }
}
