import Foundation

/// Locomotive restoration, boarding/leaving, resting and the "what next?" goal tracker.
enum ProgressionSystem {
    static let locomotiveRepairCost: ResourceCost = [.scrap: 6, .fuel: 1]

    static func canRepairLocomotive(_ state: GameState) -> Bool {
        !state.train.locomotiveRepaired && InventorySystem.canAfford(locomotiveRepairCost, state)
    }

    /// The first repair: the fuel can is poured straight into the tank.
    @discardableResult
    static func repairLocomotive(_ state: inout GameState) -> Bool {
        guard canRepairLocomotive(state), InventorySystem.consume(locomotiveRepairCost, &state) else { return false }
        state.train.locomotiveRepaired = true
        state.train.fuel = min(TrainStats(state: state).fuelCapacity, state.train.fuel + ResourceCatalog.info(.fuel).fuelValue)
        return true
    }

    /// Boarding unloads the backpack into storage and restores health.
    static func board(_ state: inout GameState) -> (moved: ResourceCost, leftover: Bool) {
        let moved = InventorySystem.unloadBackpack(&state)
        state.location = .onTrain
        state.playerPosition = nil
        state.health = GameState.maxHealth
        return (moved, state.inventory.backpackUsed > 0)
    }

    static func disembark(_ state: inout GameState) {
        guard state.journey == nil else { return }
        state.location = .exploring
        if state.currentStation == .tallkorset { state.tutorial.leftTrainAtTallkorset = true }
    }

    // MARK: Goals

    /// The medium-term goal shown in the HUD once the tutorial is done.
    static func currentGoal(_ state: GameState) -> String {
        let f = state.flags
        if !state.visitedStations.contains(.rosthamn) {
            return "Res till Rosthamn. Industristaden lär ha koppar och maskindelar."
        }
        if state.train.engineLevel < 1 {
            return "Bygg Motoruppgradering I (15 järnskrot, 5 koppar) för att klara stigningen till Djupgruvan."
        }
        if !state.visitedStations.contains(.djupgruvan) {
            return "Res till Djupgruvan i bergen."
        }
        if !f.contains(.junctionSwitched) && !f.contains(.mineLineRevealed) {
            if !state.inventory.has(.headlamp) {
                return "Bygg en Pannlampa så att du kan ta dig in i gruvans mörka inre schakt."
            }
            return "Leta efter ritningen till gamla gruvbanan i Djupgruvans inre schakt."
        }
        if !state.visitedStations.contains(.nordpasset) {
            if f.contains(.mineLineRevealed) && !f.contains(.mineLineRepaired) && !f.contains(.junctionSwitched) {
                return "Bygg Spårreparation för att öppna gamla gruvbanan till Nordpasset."
            }
            if f.contains(.junctionSwitched) && !f.contains(.mineLineRepaired) {
                let stats = TrainStats(state: state)
                let need = stats.fuelCost(distance: WorldCatalog.route(.northernLine).distance)
                if need > stats.fuelCapacity {
                    return "Norra linjen kräver \(Format.fuel(need)) bränsle. Bygg Extra bränsletank eller Bränsleeffektivisering I."
                }
                return "Res till Nordpasset via Norra linjen från Tallkorset."
            }
            return "Res till Nordpasset och hitta radiosignalens källa."
        }
        if !f.contains(.nordpassetGeneratorOn) {
            return "Starta reservgeneratorn vid radiotornet i Nordpasset (3 kol)."
        }
        if !f.contains(.signalSourceFound) {
            return "Använd terminalen i radiotornet."
        }
        let found = state.discoveredSecrets.count
        let total = SecretID.allCases.count
        if found < total {
            return "Kapitel 1 avklarat. Hitta alla hemligheter (\(found)/\(total)) och bygg ut tåget."
        }
        return "Kapitel 1 avklarat. Spåret norrut väntar – fortsättning följer."
    }

    /// Optional long-term goals for the journal.
    static func longTermGoals(_ state: GameState) -> [ObjectiveLine] {
        [
            ObjectiveLine(text: "Hitta alla hemligheter (\(state.discoveredSecrets.count)/\(SecretID.allCases.count))",
                          done: state.discoveredSecrets.count == SecretID.allCases.count),
            ObjectiveLine(text: "Bygg en Verkstadsvagn", done: state.train.has(wagon: .workshop)),
            ObjectiveLine(text: "Bygg en Bostadsvagn", done: state.train.has(wagon: .living)),
            ObjectiveLine(text: "Uppgradera motorn till nivå II", done: state.train.engineLevel >= 2),
            ObjectiveLine(text: "Avkoda radiofragmenten (\([StoryFlag.decodedFragment1, .decodedFragment2].filter { state.has($0) }.count)/2)",
                          done: state.has(.decodedFragment2)),
            ObjectiveLine(text: "Hitta källan till radiosignalen", done: state.has(.signalSourceFound)),
        ]
    }

    // MARK: Radio decoding

    /// Uses the signal decoder at the locomotive radio. Returns the decoded journal entry, if any.
    static func decodeRadio(_ state: inout GameState) -> JournalID? {
        guard state.inventory.has(.signalDecoder) else { return nil }
        if !state.has(.decodedFragment1) {
            state.flags.insert(.decodedFragment1)
            InteractionSystem.addJournal(.decodedFragment1, &state)
            return .decodedFragment1
        }
        // The second fragment is only strong enough near the mountains.
        if !state.has(.decodedFragment2),
           [.nordpasset, .djupgruvan].contains(state.currentStation) {
            state.flags.insert(.decodedFragment2)
            InteractionSystem.addJournal(.decodedFragment2, &state)
            return .decodedFragment2
        }
        return nil
    }
}
