import Testing
@testable import The_Last_Rail

@MainActor
struct InteractionTests {
    @Test func oneTimePickupDisappears() {
        var s = GameState.newGame()
        let r = TH.use("skrot_1", at: .depot, &s)
        #expect(r.objectChanged)
        #expect(s.inventory.backpackCount(.scrap) == 2)
        let again = TH.use("skrot_1", at: .depot, &s)
        #expect(!again.objectChanged)
        #expect(s.inventory.backpackCount(.scrap) == 2)
    }

    @Test func renewablesRespawnAfterAJourney() {
        var s = TH.finishTutorial()
        s.currentStation = .tallkorset
        let pile = WorldCatalog.layout(.tallkorset)!.object("vedtrave_1")!
        InteractionSystem.interact(pile, station: .tallkorset, &s)
        #expect(!InteractionSystem.isActive(pile, station: .tallkorset, s))
        s.journeyCount += 1
        #expect(InteractionSystem.isActive(pile, station: .tallkorset, s))
    }

    @Test func flaggedObjectsOnlyExistAfterFlag() {
        var s = GameState.newGame()
        let drum = WorldCatalog.layout(.depot)!.object("lackande_fat")!
        #expect(!InteractionSystem.isActive(drum, station: .depot, s))
        #expect(InteractionSystem.prompt(drum, station: .depot, s) == nil)
        s.flags.insert(.tutorialComplete)
        #expect(InteractionSystem.isActive(drum, station: .depot, s))
    }

    @Test func fullBackpackLeavesRemainderInPile() {
        var s = GameState.newGame()
        let cap = InventorySystem.capacity(.backpack, s)
        InventorySystem.add(.wood, cap - 1, to: .backpack, &s)
        TH.use("skrot_1", at: .depot, &s)
        #expect(s.inventory.backpackCount(.scrap) == 1)
        #expect(s.remainingLoot["gamla_depan/skrot_1"] == [.scrap: 1])
        let pile = WorldCatalog.layout(.depot)!.object("skrot_1")!
        #expect(InteractionSystem.isActive(pile, station: .depot, s))
        ProgressionSystem.board(&s)
        TH.use("skrot_1", at: .depot, &s)
        #expect(!InteractionSystem.isActive(pile, station: .depot, s))
        #expect(s.inventory.total(.scrap) == 2)
    }

    @Test func crowbarDoorNeedsTool() {
        var s = TH.finishTutorial()
        let door = WorldCatalog.layout(.rosthamn)!.object("lager_dorr")!
        InteractionSystem.interact(door, station: .rosthamn, &s)
        #expect(InteractionSystem.blocksMovement(door, station: .rosthamn, s))
        InventorySystem.addItem(.crowbar, 1, &s)
        InteractionSystem.interact(door, station: .rosthamn, &s)
        #expect(!InteractionSystem.blocksMovement(door, station: .rosthamn, s))
    }

    @Test func codeDoorUsesNoteCode() {
        var s = TH.finishTutorial()
        let door = WorldCatalog.layout(.rosthamn)!.object("kodrum_dorr")!
        let wrong = InteractionSystem.enterCode("1234", for: door, station: .rosthamn, &s)
        #expect(!wrong.objectChanged)
        #expect(InteractionSystem.blocksMovement(door, station: .rosthamn, s))
        let right = InteractionSystem.enterCode("4172", for: door, station: .rosthamn, &s)
        #expect(right.objectChanged)
        #expect(right.secret == .rosthamnCodeRoom)
        #expect(s.discoveredSecrets.contains(.rosthamnCodeRoom))
        // The code really is in the Tallkorset note.
        #expect(JournalCatalog.entry(.tallkorsetHiddenNote).text.contains("4-1-7-2"))
    }

    @Test func darkBarrierNeedsHeadlamp() {
        var s = TH.finishTutorial()
        let barrier = WorldCatalog.layout(.djupgruvan)!.object("morker")!
        #expect(InteractionSystem.blocksMovement(barrier, station: .djupgruvan, s))
        InventorySystem.addItem(.headlamp, 1, &s)
        #expect(!InteractionSystem.blocksMovement(barrier, station: .djupgruvan, s))
    }

    @Test func signalBoxNeedsFuseAndKit() {
        var s = TH.finishTutorial()
        s.inventory.items[.repairKit] = nil
        let box = WorldCatalog.layout(.rosthamn)!.object("stallverk")!
        InteractionSystem.interact(box, station: .rosthamn, &s)
        #expect(!s.has(.junctionSwitched))
        #expect(s.journal.contains(.rosthamnSignalBox))
        InventorySystem.addItem(.fuse, 1, &s)
        InventorySystem.addItem(.repairKit, 1, &s)
        InteractionSystem.interact(box, station: .rosthamn, &s)
        #expect(s.has(.junctionSwitched))
        #expect(!s.inventory.has(.fuse) && !s.inventory.has(.repairKit))
        #expect(s.discoveredStations.contains(.nordpasset))
    }

    @Test func mineBlueprintRevealsHiddenRoute() {
        var s = TH.finishTutorial()
        TH.use("gruvbanan_ritning", at: .djupgruvan, &s)
        #expect(s.knownBlueprints.contains(.trackRepair))
        #expect(s.has(.mineLineRevealed))
        #expect(TravelSystem.isRevealed(WorldCatalog.route(.mineLine), s))
    }

    @Test func generatorAndTerminalRevealStory() {
        var s = TH.finishTutorial()
        TH.use("terminal", at: .nordpasset, &s)
        #expect(!s.has(.signalSourceFound), "No power yet")
        InventorySystem.add(.coal, 3, to: .backpack, &s)
        TH.use("generator", at: .nordpasset, &s)
        #expect(s.has(.nordpassetGeneratorOn))
        #expect(s.inventory.total(.coal) == 0)
        let r = TH.use("terminal", at: .nordpasset, &s)
        #expect(s.has(.signalSourceFound) && s.has(.chapterOneComplete))
        #expect(r.dialog != nil)
        #expect(s.discoveredStations.contains(.polaris))
    }

    @Test func hazardsDamageAndFaintKeepsProgress() {
        var s = TH.finishTutorial()
        InventorySystem.add(.copper, 4, to: .backpack, &s)
        let unlocked = s.flags
        var fainted = false
        for _ in 0..<200 where !fainted { fainted = InteractionSystem.damage(1, &s) }
        #expect(fainted)
        InteractionSystem.faint(&s)
        #expect(s.health == GameState.maxHealth)
        #expect(s.inventory.backpackCount(.copper) == 2)
        #expect(s.flags == unlocked)
        #expect(s.train.locomotiveRepaired)
    }

    @Test func decoderRevealsRadioFragments() {
        var s = TH.finishTutorial()
        #expect(ProgressionSystem.decodeRadio(&s) == nil)
        InventorySystem.addItem(.signalDecoder, 1, &s)
        #expect(ProgressionSystem.decodeRadio(&s) == .decodedFragment1)
        #expect(ProgressionSystem.decodeRadio(&s) == nil, "Second fragment needs the mountains")
        s.currentStation = .nordpasset
        #expect(ProgressionSystem.decodeRadio(&s) == .decodedFragment2)
    }
}
