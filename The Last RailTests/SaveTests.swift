import Foundation
import Testing
@testable import The_Last_Rail

@MainActor
struct SaveTests {
    @Test func roundTripPreservesEverything() throws {
        let save = SaveSystem(directory: TH.tempDir())
        var s = TH.finishTutorial()
        InventorySystem.add(.copper, 7, to: .storage, &s)
        InventorySystem.addItem(.crowbar, 1, &s)
        s.discoveredSecrets.insert(.tallkorsetCache)
        s.knownBlueprints.insert(.trackRepair)
        s.flags.insert(.junctionSwitched)
        s.collectedObjects.insert("tallkorset/lager_lada")
        s.depletedRenewables["tallkorset/vedtrave_1"] = 3
        s.remainingLoot["rosthamn/lager_lada"] = [.copper: 2]
        s.playerPosition = SavedPosition(station: .depot, x: 120, y: 88)
        s.location = .exploring
        CraftingSystem.apply(.addWagon(.workshop), &s)
        s.journey = JourneyState(routeID: .depotTallkorset, from: .depot, to: .tallkorset, fuelCost: 9, duration: 12, elapsed: 4, fuelConsumed: 3)
        try save.save(s)
        #expect(save.hasValidSave)
        let loaded = try save.load()
        #expect(loaded == s)
    }

    @Test func missingSaveIsReported() {
        let save = SaveSystem(directory: TH.tempDir())
        #expect(!save.hasValidSave)
        #expect(throws: SaveError.noSave) { try save.load() }
    }

    @Test func corruptedSaveFallsBackToBackup() throws {
        let save = SaveSystem(directory: TH.tempDir())
        var s = GameState.newGame()
        s.health = 42
        try save.save(s)
        s.health = 77
        try save.save(s)   // first save becomes the backup
        try Data("{ not json".utf8).write(to: save.saveURL)
        let loaded = try save.load()
        #expect(loaded.health == 42)
    }

    @Test func corruptedWithoutBackupThrows() throws {
        let save = SaveSystem(directory: TH.tempDir())
        try FileManager.default.createDirectory(at: save.directory, withIntermediateDirectories: true)
        try Data("garbage".utf8).write(to: save.saveURL)
        #expect(!save.hasValidSave)
        #expect(throws: SaveError.corrupted) { try save.load() }
    }

    @Test func futureVersionIsRejected() throws {
        let save = SaveSystem(directory: TH.tempDir())
        try save.save(GameState.newGame())
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: save.saveURL)) as! [String: Any]
        json["version"] = GameState.currentVersion + 1
        try JSONSerialization.data(withJSONObject: json).write(to: save.saveURL)
        #expect(throws: SaveError.unsupportedVersion(GameState.currentVersion + 1)) { try save.decode(Data(contentsOf: save.saveURL)) }
    }

    @Test func saveFileIsReadableJSON() throws {
        let save = SaveSystem(directory: TH.tempDir())
        try save.save(GameState.newGame())
        let text = try String(contentsOf: save.saveURL, encoding: .utf8)
        #expect(text.contains("\"version\""))
        #expect(text.contains("\"jarnskrot\"") || text.contains("inventory"))
    }

    @Test func settingsPersist() {
        let store = SettingsStore(directory: TH.tempDir())
        var settings = store.load()
        settings.musicVolume = 0.2
        settings.muted = true
        store.save(settings)
        #expect(store.load() == settings)
    }
}
