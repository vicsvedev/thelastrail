import Foundation

struct ObjectiveLine: Equatable, Identifiable {
    var id: String { text }
    let text: String
    let done: Bool
}

enum TutorialEvent: Equatable {
    case stepStarted(TutorialStep)
    case rewardGranted(ResourceCost, [ItemType])
}

/// Chapter 1 onboarding. Every step is validated against the real game state,
/// so progress survives save/load and steps never repeat.
enum TutorialSystem {
    static let title = "Kapitel 1 — Sista avgången"
    static let reward: ResourceCost = [.fuel: 2, .food: 3, .scrap: 5]
    static let rewardItems: [ItemType] = [.repairKit]

    static func intro(_ step: TutorialStep) -> String? {
        switch step {
        case .wakeUp: return "Du vaknar i ett övergivet lokstall. Någonstans hörs ett svagt radiobrus..."
        case .investigateLocomotive: return "Ett gammalt diesellok står på spåret mitt i stallet."
        case .collectScrap: return "Motorn fungerar fortfarande, men bränslet är slut och flera komponenter saknas."
        case .findFuel: return "Bra! Nu behövs bränsle. Förrådet på gården kanske har något kvar."
        case .repairLocomotive: return "Du har det du behöver. Tillbaka till loket!"
        case .radioSignal: return "Radion i förarhytten sprakar till liv..."
        case .firstJourney: return "Bara ett spår leder bort härifrån: norrut mot Tallkorset."
        case .firstExpedition: return "Tallkorset. Stationen ligger tyst i regnet."
        case .firstUpgrade: return "Med ritningen kan du bygga en verkstad i lastvagnen."
        case .complete: return nil
        }
    }

    static func objective(_ step: TutorialStep) -> String {
        switch step {
        case .wakeUp: return "Använd styrspaken till vänster för att röra dig."
        case .investigateLocomotive: return "Undersök det gamla loket."
        case .collectScrap: return "Samla 6 järnskrot."
        case .findFuel: return "Hitta bränsle till loket."
        case .repairLocomotive: return "Reparera loket."
        case .radioSignal: return "Undersök järnvägskartan."
        case .firstJourney: return "Res till Tallkorset."
        case .firstExpedition: return "Utforska Tallkorset."
        case .firstUpgrade: return "Bygg din första verkstad."
        case .complete: return "Din resa har bara börjat."
        }
    }

    static func hint(_ step: TutorialStep, _ state: GameState) -> String? {
        switch step {
        case .wakeUp: return "Dra med tummen var som helst på vänstra halvan. Håll springknappen för att springa."
        case .investigateLocomotive: return "Gå fram till loket och tryck på handlingsknappen nere till höger."
        case .collectScrap: return "Skrothögarna glimmar svagt. Gå fram och tryck på handlingsknappen."
        case .findFuel: return "Förrådet ligger norr om lokstallet."
        case .repairLocomotive: return "Gå till loket och tryck på handlingsknappen."
        case .radioSignal: return "Tryck på kartknappen uppe till höger."
        case .firstJourney:
            return state.location == .onTrain ? "Öppna kartan, tryck på Tallkorset och sedan Res hit." : "Gå till tåget och tryck på handlingsknappen för att gå ombord."
        case .firstExpedition:
            return state.location == .onTrain ? "Tryck på Kliv av för att lämna tåget." : "Verkstaden ligger öster om perrongen."
        case .firstUpgrade:
            if state.location != .onTrain { return "Gå tillbaka till tåget och gå ombord." }
            let missing = InventorySystem.missing(RecipeCatalog.recipe(.workshop).cost, state)
            if !missing.isEmpty {
                let list = missing.map { "\($0.value) \(ResourceCatalog.name($0.key).lowercased())" }.joined(separator: ", ")
                return "Du saknar \(list). Skogen runt stationen har gott om trä."
            }
            return "Tryck på Bygg och välj Grundläggande verkstad."
        case .complete: return nil
        }
    }

    static func subObjectives(_ step: TutorialStep, _ state: GameState) -> [ObjectiveLine] {
        switch step {
        case .collectScrap:
            return [ObjectiveLine(text: "Järnskrot \(min(6, state.inventory.total(.scrap)))/6", done: state.inventory.total(.scrap) >= 6)]
        case .firstExpedition:
            return [
                ObjectiveLine(text: "Kliv av tåget", done: state.tutorial.leftTrainAtTallkorset),
                ObjectiveLine(text: "Samla 10 järnskrot (\(min(10, state.inventory.total(.scrap)))/10)", done: scrapGoalMet(state)),
                ObjectiveLine(text: "Hitta den övergivna verkstaden", done: state.tutorial.foundTallkorsetWorkshop),
                ObjectiveLine(text: "Hämta verkstadsritningen", done: state.knownBlueprints.contains(.workshop)),
            ]
        case .firstUpgrade:
            let cost = RecipeCatalog.recipe(.workshop).cost
            return cost.sorted { $0.key.rawValue < $1.key.rawValue }.map { type, need in
                let have = state.inventory.total(type)
                return ObjectiveLine(text: "\(ResourceCatalog.name(type)) \(min(have, need))/\(need)", done: have >= need)
            }
        default:
            return []
        }
    }

    private static func scrapGoalMet(_ state: GameState) -> Bool {
        state.inventory.total(.scrap) >= 10 || state.train.hasWorkshopBench
    }

    static func isSatisfied(_ step: TutorialStep, _ state: GameState) -> Bool {
        let t = state.tutorial
        let repaired = state.train.locomotiveRepaired
        switch step {
        case .wakeUp: return t.hasMoved
        case .investigateLocomotive: return t.inspectedLocomotive || repaired
        case .collectScrap: return state.inventory.total(.scrap) >= 6 || repaired
        case .findFuel: return state.inventory.total(.fuel) >= 1 || repaired
        case .repairLocomotive: return repaired
        case .radioSignal: return t.openedMapAfterRadio || state.visitedStations.contains(.tallkorset)
        case .firstJourney: return state.visitedStations.contains(.tallkorset)
        case .firstExpedition:
            return (t.leftTrainAtTallkorset || state.train.hasWorkshopBench) && scrapGoalMet(state)
                && (t.foundTallkorsetWorkshop || state.knownBlueprints.contains(.workshop))
                && state.knownBlueprints.contains(.workshop)
        case .firstUpgrade: return state.train.hasWorkshopBench
        case .complete: return t.finished
        }
    }

    /// Advances through every satisfied step and applies step-entry effects.
    @discardableResult
    static func refresh(_ state: inout GameState) -> [TutorialEvent] {
        guard !state.tutorial.finished else { return [] }
        var events: [TutorialEvent] = []
        while state.tutorial.step != .complete, isSatisfied(state.tutorial.step, state), let next = state.tutorial.step.next {
            state.tutorial.step = next
            events.append(contentsOf: enter(next, &state))
        }
        return events
    }

    private static func enter(_ step: TutorialStep, _ state: inout GameState) -> [TutorialEvent] {
        var events: [TutorialEvent] = [.stepStarted(step)]
        switch step {
        case .radioSignal:
            state.flags.insert(.radioHeard)
            InteractionSystem.addJournal(.radioFirst, &state)
            state.discoveredStations.insert(.tallkorset)
        case .complete:
            grantReward(&state)
            events.append(.rewardGranted(reward, rewardItems))
        default:
            break
        }
        return events
    }

    private static func grantReward(_ state: inout GameState) {
        for (type, amount) in reward {
            let added = InventorySystem.add(type, amount, to: .storage, &state)
            if added < amount { InventorySystem.add(type, amount - added, to: .backpack, &state) }
        }
        for item in rewardItems { InventorySystem.addItem(item, 1, &state) }
        state.flags.insert(.tutorialComplete)
        InteractionSystem.addJournal(.tutorialComplete, &state)
        TravelSystem.discoverNeighbors(of: .tallkorset, &state)
    }

    /// Called when the player acknowledges the final tutorial screen.
    static func finish(_ state: inout GameState) {
        guard state.tutorial.step == .complete else { return }
        state.tutorial.finished = true
    }

    /// Skips the tutorial and leaves the player with a valid, playable starting state.
    static func skip(_ state: inout GameState) {
        guard !state.tutorial.finished else { return }
        let alreadyRewarded = state.tutorial.step == .complete
        state.train.locomotiveRepaired = true
        state.train.fuel = max(state.train.fuel, 25)
        if !state.train.hasWorkshopBench {
            CraftingSystem.apply(.installModule(.workshopBench), &state)
        }
        state.knownBlueprints.insert(.workshop)
        state.completedUpgrades.insert(.workshop)
        state.flags.insert(.radioHeard)
        InteractionSystem.addJournal(.radioFirst, &state)
        state.discoveredStations.insert(.tallkorset)
        let starter: ResourceCost = [.scrap: 10, .wood: 6, .food: 2]
        for (type, amount) in starter { InventorySystem.add(type, amount, to: .storage, &state) }
        if !alreadyRewarded { grantReward(&state) }
        state.tutorial.step = .complete
        state.tutorial.finished = true
        state.tutorial.skipped = true
    }
}
