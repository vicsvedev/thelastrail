import Foundation

/// Development tool for simulator verification. Launch with
/// `-TLRScenario "explore:tallkorset@9,4;overlay:map"` to jump straight into a game state.
/// Tokens (separated by `;`):
///   `newgame`                    start a fresh game (tutorial)
///   `skip`                       skip the tutorial and add 20 of every resource
///   `explore:<station>[@c,r]`    explore a station, optionally at a tile
///   `train:<station>`            stand on the train at a station
///   `wagons`                     add workshop + living wagons
///   `at:c,r`                     teleport the player in the current exploration scene
///   `routes`                     unlock the junction, mine line and engine upgrade I, full fuel
///   `lamp`                       give the headlamp
///   `travel:<station>`           start a journey from the current station
///   `overlay:<name>`             open a panel (map, crafting, inventory, journal, wagons, locomotive, pause, settings, help, repair)
///   `dialog`                     show a long story dialog
/// Scenarios use a throwaway save folder.
enum DebugScenario {
    /// Always nil in Release builds: scenarios are a development tool only.
    static var requested: String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-TLRScenario"), i + 1 < args.count else { return nil }
        return args[i + 1]
        #else
        return nil
        #endif
    }

    static var isRequested: Bool { requested != nil }

    static func runIfRequested(_ game: GameController) {
        guard let script = requested else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            for token in script.split(separator: ";").map(String.init) {
                apply(token, game)
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    private static func station(_ s: Substring) -> StationID? {
        StationID.allCases.first { $0.rawValue.hasPrefix(s.lowercased()) || String(describing: $0) == s }
    }

    private static func apply(_ token: String, _ game: GameController) {
        let parts = token.split(separator: ":", maxSplits: 1)
        let cmd = parts.first.map(String.init) ?? ""
        let arg = parts.count > 1 ? parts[1] : ""
        switch cmd {
        case "newgame":
            game.state = GameState.newGame()
            game.enterExploration(at: nil)
            game.showTutorialIntroIfNeeded()
        case "skip":
            TutorialSystem.skip(&game.state)
            game.state.train.storageLevel = 3
            for r in ResourceType.allCases { InventorySystem.add(r, 20, to: .storage, &game.state) }
        case "explore":
            let bits = arg.split(separator: "@")
            guard let first = bits.first, let st = station(first), let layout = WorldCatalog.layout(st) else { return }
            game.state.currentStation = st
            game.state.visitedStations.insert(st)
            TravelSystem.discoverNeighbors(of: st, &game.state)
            var pos: CGPoint?
            if bits.count > 1 {
                let nums = bits[1].split(separator: ",").compactMap { Int($0) }
                if nums.count == 2 { pos = CGPoint(x: CGFloat(nums[0]) * 16 + 8, y: CGFloat(layout.height - 1 - nums[1]) * 16 + 4) }
            }
            game.enterExploration(at: pos)
        case "train":
            if let st = station(arg) {
                game.state.currentStation = st
                game.state.visitedStations.insert(st)
                TravelSystem.discoverNeighbors(of: st, &game.state)
            }
            game.trainScene = nil
            game.enterTrain()
        case "wagons":
            CraftingSystem.apply(.addWagon(.workshop), &game.state)
            CraftingSystem.apply(.addWagon(.living), &game.state)
            game.trainScene?.rebuild()
        case "at":
            let nums = arg.split(separator: ",").compactMap { Int($0) }
            if nums.count == 2 { game.explorationScene?.debugTeleport(col: nums[0], row: nums[1]) }
        case "routes":
            game.state.flags.formUnion([.junctionSwitched, .mineLineRevealed, .mineLineRepaired])
            game.state.train.engineLevel = max(game.state.train.engineLevel, 1)
            game.state.train.fuel = TrainStats(state: game.state).fuelCapacity
        case "lamp":
            InventorySystem.addItem(.headlamp, 1, &game.state)
        case "travel":
            if let st = station(arg) {
                game.state.train.fuel = TrainStats(state: game.state).fuelCapacity
                game.state.flags.formUnion([.junctionSwitched, .mineLineRevealed, .mineLineRepaired])
                game.state.train.engineLevel = max(game.state.train.engineLevel, 1)
                game.state.train.efficiencyLevel = 1
                game.state.discoveredStations.insert(st)
                game.state.location = .onTrain
                game.travel(to: st)
            }
        case "overlay":
            let map: [String: Overlay] = ["map": .map, "crafting": .crafting, "inventory": .inventory, "journal": .journal,
                                          "wagons": .wagons, "locomotive": .locomotive, "pause": .pause, "settings": .settings,
                                          "help": .help, "repair": .repair, "complete": .tutorialComplete, "keypad": .keypad("kodrum_dorr")]
            if let o = map[String(arg)] { game.open(o) }
        case "dialog":
            game.state.journal = JournalID.allCases
            game.showDialog(.journal(.nordpassetLog))
        default:
            break
        }
    }
}
