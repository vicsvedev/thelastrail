import Foundation
@testable import The_Last_Rail

@MainActor
enum TH {
    /// Interacts with one object by id at a station.
    @discardableResult
    static func use(_ id: String, at station: StationID, _ s: inout GameState) -> InteractionResult {
        guard let obj = WorldCatalog.layout(station)?.object(id) else {
            fatalError("No object \(id) at \(station)")
        }
        return InteractionSystem.interact(obj, station: station, &s)
    }

    /// Picks up every active pickup/container/blueprint/key item at the current station,
    /// unloading to the train whenever the backpack fills up.
    static func lootStation(_ s: inout GameState, includeLocked: Bool = false) {
        let station = s.currentStation
        guard let layout = WorldCatalog.layout(station) else { return }
        for obj in layout.objects {
            switch obj.kind {
            case .resource, .container, .blueprint, .keyItem, .note:
                // Repeat in case the backpack filled up mid-pile.
                for _ in 0..<4 where InteractionSystem.isActive(obj, station: station, s) {
                    if case .note = obj.kind {
                        InteractionSystem.interact(obj, station: station, &s)
                        break
                    }
                    InteractionSystem.interact(obj, station: station, &s)
                    if InventorySystem.freeSpace(.backpack, s) < 8 {
                        ProgressionSystem.board(&s)
                        ProgressionSystem.disembark(&s)
                    }
                }
            case .door(let lock):
                if case .tool = lock { InteractionSystem.interact(obj, station: station, &s) }
            default:
                break
            }
        }
        ProgressionSystem.board(&s)
    }

    /// Fills the tank and travels; returns the arrival success.
    @discardableResult
    static func travel(_ to: StationID, _ s: inout GameState) -> Result<TravelPlan, TravelBlock> {
        s.location = .onTrain
        InventorySystem.autoRefuel(&s)
        var plan = TravelSystem.plan(to: to, s)
        if case .failure(.insufficientFuel(let need, _)) = plan, InventorySystem.refuel(to: need, &s) {
            plan = TravelSystem.plan(to: to, s)
        }
        if case .success(let p) = plan {
            TravelSystem.begin(p, &s)
            TravelSystem.advance(p.duration + 1, &s)
        }
        return plan
    }

    static func tempDir() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("TLRTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Fast-forwards a fresh game through the tutorial using real systems.
    static func finishTutorial() -> GameState {
        var s = GameState.newGame()
        TutorialSystem.skip(&s)
        return s
    }
}
