import Foundation
import Testing
@testable import The_Last_Rail

@MainActor
struct TutorialTests {
    @Test func fullTutorialWithRealSystems() throws {
        var s = GameState.newGame()
        #expect(s.tutorial.step == .wakeUp)
        // 1. Move
        TutorialSystem.refresh(&s)
        #expect(s.tutorial.step == .wakeUp, "Nothing happens before moving")
        s.tutorial.hasMoved = true
        TutorialSystem.refresh(&s)
        #expect(s.tutorial.step == .investigateLocomotive)
        // 2. Inspect locomotive
        s.tutorial.inspectedLocomotive = true
        TutorialSystem.refresh(&s)
        #expect(s.tutorial.step == .collectScrap)
        // 3. Collect scrap from the three piles
        TH.use("skrot_1", at: .depot, &s)
        TH.use("skrot_2", at: .depot, &s)
        TutorialSystem.refresh(&s)
        #expect(s.tutorial.step == .collectScrap)
        TH.use("skrot_3", at: .depot, &s)
        TutorialSystem.refresh(&s)
        #expect(s.tutorial.step == .findFuel)
        // 4. Fuel in the storage building
        TH.use("bransledunk", at: .depot, &s)
        TutorialSystem.refresh(&s)
        #expect(s.tutorial.step == .repairLocomotive)
        // 5. Repair
        #expect(ProgressionSystem.repairLocomotive(&s))
        #expect(s.train.locomotiveRepaired)
        #expect(s.inventory.total(.scrap) == 0 && s.inventory.total(.fuel) == 0)
        let events = TutorialSystem.refresh(&s)
        #expect(events.contains(.stepStarted(.radioSignal)))
        #expect(s.journal.contains(.radioFirst))
        #expect(s.discoveredStations.contains(.tallkorset))
        // 6. Map
        s.tutorial.openedMapAfterRadio = true
        TutorialSystem.refresh(&s)
        #expect(s.tutorial.step == .firstJourney)
        // 7. Travel
        ProgressionSystem.board(&s)
        if case .failure(let b) = TH.travel(.tallkorset, &s) { Issue.record("Travel failed: \(b.message)") }
        TutorialSystem.refresh(&s)
        #expect(s.tutorial.step == .firstExpedition)
        // 8. Expedition
        ProgressionSystem.disembark(&s)
        #expect(s.tutorial.leftTrainAtTallkorset)
        TH.lootStation(&s)
        ProgressionSystem.disembark(&s)
        s.tutorial.foundTallkorsetWorkshop = true
        TutorialSystem.refresh(&s)
        #expect(s.knownBlueprints.contains(.workshop))
        #expect(s.tutorial.step == .firstUpgrade)
        // 9. Build the workshop
        ProgressionSystem.board(&s)
        #expect(CraftingSystem.craft(.workshop, &s).succeeded)
        let finalEvents = TutorialSystem.refresh(&s)
        #expect(s.tutorial.step == .complete)
        #expect(finalEvents.contains(.stepStarted(.complete)))
        #expect(s.has(.tutorialComplete))
        #expect(s.inventory.has(.repairKit), "Starter reward granted")
        // 10. Acknowledge
        TutorialSystem.finish(&s)
        #expect(s.tutorial.finished)
        // Next destination unlocked
        guard case .success = TH.travel(.rosthamn, &s) else { Issue.record("Rosthamn should be reachable"); return }
    }

    @Test func stepsNeverRepeatAndRewardIsGrantedOnce() {
        var s = GameState.newGame()
        s.tutorial.step = .firstUpgrade
        s.train.locomotiveRepaired = true
        CraftingSystem.apply(.installModule(.workshopBench), &s)
        TutorialSystem.refresh(&s)
        let fuelAfter = s.inventory.total(.fuel)
        TutorialSystem.refresh(&s)
        TutorialSystem.refresh(&s)
        #expect(s.inventory.total(.fuel) == fuelAfter)
        TutorialSystem.finish(&s)
        #expect(TutorialSystem.refresh(&s).isEmpty)
    }

    @Test func outOfOrderProgressIsAccepted() {
        var s = GameState.newGame()
        // Player finds the fuel and scrap before even moving "officially".
        TH.use("bransledunk", at: .depot, &s)
        TH.use("skrot_1", at: .depot, &s)
        TH.use("skrot_2", at: .depot, &s)
        TH.use("skrot_3", at: .depot, &s)
        s.tutorial.hasMoved = true
        s.tutorial.inspectedLocomotive = true
        TutorialSystem.refresh(&s)
        #expect(s.tutorial.step == .repairLocomotive)
    }

    @Test func skipLeavesPlayableState() {
        var s = GameState.newGame()
        s.tutorial.hasMoved = true
        TutorialSystem.refresh(&s)
        TutorialSystem.skip(&s)
        #expect(s.tutorial.finished && s.tutorial.skipped)
        #expect(s.train.locomotiveRepaired)
        #expect(s.train.hasWorkshopBench)
        #expect(s.has(.tutorialComplete))
        ProgressionSystem.board(&s)
        guard case .success = TH.travel(.tallkorset, &s) else { Issue.record("Tallkorset reachable after skip"); return }
        guard case .success = TH.travel(.rosthamn, &s) else { Issue.record("Rosthamn reachable after skip"); return }
    }

    @Test func skipAfterCompletionStepDoesNotDoubleReward() {
        var s = GameState.newGame()
        s.tutorial.step = .firstUpgrade
        s.train.locomotiveRepaired = true
        CraftingSystem.apply(.installModule(.workshopBench), &s)
        TutorialSystem.refresh(&s)
        let kits = s.inventory.itemCount(.repairKit)
        TutorialSystem.skip(&s)
        #expect(s.inventory.itemCount(.repairKit) == kits)
    }

    @Test func tutorialProgressSurvivesSaveAndLoad() throws {
        let dir = TH.tempDir()
        let save = SaveSystem(directory: dir)
        var s = GameState.newGame()
        s.tutorial.hasMoved = true
        s.tutorial.inspectedLocomotive = true
        TH.use("skrot_1", at: .depot, &s)
        TutorialSystem.refresh(&s)
        try save.save(s)
        var loaded = try save.load()
        #expect(loaded.tutorial == s.tutorial)
        #expect(loaded.tutorial.step == .collectScrap)
        TH.use("skrot_2", at: .depot, &loaded)
        TH.use("skrot_3", at: .depot, &loaded)
        TutorialSystem.refresh(&loaded)
        #expect(loaded.tutorial.step == .findFuel)
        // Collected piles stay collected after reload.
        #expect(!InteractionSystem.isActive(WorldCatalog.layout(.depot)!.object("skrot_1")!, station: .depot, loaded))
    }
}
