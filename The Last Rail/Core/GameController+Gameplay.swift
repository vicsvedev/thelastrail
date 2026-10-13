import Foundation
import SpriteKit

/// Gameplay actions triggered by scenes and UI.
extension GameController {
    // MARK: Exploration

    func playerMoved(distance: Double) {
        if !state.tutorial.hasMoved && state.tutorial.isActive {
            moveAccumulator += distance
            if moveAccumulator > 40 {
                state.tutorial.hasMoved = true
                refreshTutorial()
            }
        }
    }

    func interact(with obj: MapObjectDef) {
        let result = InteractionSystem.interact(obj, station: state.currentStation, &state)
        apply(result, object: obj)
        if result.openKeypad { open(.keypad(obj.id)) }
    }

    func submitKeypad(_ id: String) {
        let code = keypadEntry
        keypadEntry = ""
        submitCode(code, objectID: id)
    }

    func submitCode(_ code: String, objectID: String) {
        guard let layout = WorldCatalog.layout(state.currentStation), let obj = layout.object(objectID) else { return }
        let result = InteractionSystem.enterCode(code, for: obj, station: state.currentStation, &state)
        if result.objectChanged { close(.keypad(objectID)) }
        apply(result, object: obj)
    }

    private func apply(_ result: InteractionResult, object obj: MapObjectDef) {
        play(result.sound)
        if result.secret != nil { Haptics.success() }
        else if result.sound == .error { Haptics.error() }
        else if result.objectChanged { Haptics.tap() }
        for t in result.toasts { toast(t, important: result.secret != nil) }
        if let d = result.dialog { showDialog(d) }
        if let text = result.floatingText { explorationScene?.floatText(text, at: obj.at) }
        if result.objectChanged { explorationScene?.refreshObject(obj.id) }
        if result.secret != nil || result.objectChanged || result.dialog != nil { refreshTutorial() }
        if result.secret != nil || isSignificant(obj) { autosave() }
    }

    private func isSignificant(_ obj: MapObjectDef) -> Bool {
        switch obj.kind {
        case .blueprint, .keyItem, .door, .machine: return true
        default: return false
        }
    }

    func enteredZone(_ zone: ZoneDef) {
        switch zone.kind {
        case .tutorialWorkshop:
            if !state.tutorial.foundTallkorsetWorkshop {
                state.tutorial.foundTallkorsetWorkshop = true
                if state.tutorial.isActive { toast("Du hittade den övergivna verkstaden.") }
                refreshTutorial()
            }
        case .secret(let id):
            var result = InteractionResult()
            InteractionSystem.registerSecret(id, &state, &result)
            play(result.sound)
            for t in result.toasts { toast(t, important: true) }
            if result.secret != nil { autosave() }
        case .caption(let text):
            showCaption(text, seconds: 4)
        }
    }

    func hazardDamage(_ amount: Double) {
        guard !isWorldFrozen else { return }
        if InteractionSystem.damage(amount, &state) {
            faint()
        }
    }

    func faint() {
        Haptics.error()
        let lost = InteractionSystem.faint(&state)
        sound.play(.faint)
        var text = "Allt svartnar...\n\nDu vaknar vid tåget, omtöcknad men hel."
        if lost.isEmpty {
            text += " Du bar inte på något som gick förlorat."
        } else {
            let list = lost.map { "\($0.value) \(ResourceCatalog.name($0.key).lowercased())" }.joined(separator: ", ")
            text += "\n\nHälften av det du bar på är borta: \(list)."
        }
        showDialog(DialogContent(title: "Du svimmade", text: text))
        explorationScene?.respawnAtTrain()
        autosave()
    }

    func eat() {
        if InteractionSystem.eat(&state) {
            sound.play(.pickup)
            toast("Du äter något. +30 hälsa")
        } else if state.health >= GameState.maxHealth {
            toast("Du är inte hungrig.")
        } else {
            toast("Du har ingen mat.")
            sound.play(.error)
        }
    }

    // MARK: Train (exploration side)

    func interactWithTrain() {
        if !state.train.locomotiveRepaired {
            if state.tutorial.isActive && state.tutorial.step <= .investigateLocomotive {
                state.tutorial.inspectedLocomotive = true
                showDialog(DialogContent(title: "Det gamla loket",
                                         text: "Ett rostigt diesellok av gammal modell. Du vrider på nyckeln – startmotorn hostar, men inget händer.\n\nMotorn fungerar fortfarande, men bränslet är slut och flera komponenter saknas.\n\nDu behöver 6 järnskrot och 1 bränsle."))
                sound.play(.error)
                refreshTutorial()
            } else {
                state.tutorial.inspectedLocomotive = true
                refreshTutorial()
                open(.repair)
            }
            return
        }
        boardTrain()
    }

    func repairLocomotive() {
        guard ProgressionSystem.repairLocomotive(&state) else {
            sound.play(.error)
            toast("Du har inte allt som behövs.")
            return
        }
        close(.repair)
        sound.play(.engineStart)
        Haptics.success()
        explorationScene?.locomotiveStarted()
        toast("Loket lever!", important: true)
        refreshTutorial()
        autosave()
    }

    func boardTrain() {
        let (moved, leftover) = ProgressionSystem.board(&state)
        sound.play(.door)
        if !moved.isEmpty {
            let list = moved.sorted { $0.key.rawValue < $1.key.rawValue }.map { "\($0.value) \(ResourceCatalog.name($0.key).lowercased())" }.joined(separator: ", ")
            toast("Lastade av: \(list)")
        }
        if leftover { toast("Lastvagnen är full! En del ligger kvar i ryggsäcken.", important: true) }
        fadeTransition { [self] in
            enterTrain()
            refreshTutorial()
            autosave()
        }
    }

    func disembark() {
        guard state.journey == nil else { toast("Vänta tills tåget har stannat."); return }
        guard WorldCatalog.layout(state.currentStation) != nil else { return }
        ProgressionSystem.disembark(&state)
        sound.play(.door)
        fadeTransition { [self] in
            enterExploration(at: nil)
            refreshTutorial()
        }
    }

    // MARK: Travel

    func travel(to destination: StationID) {
        switch TravelSystem.plan(to: destination, state) {
        case .success(let plan):
            beginJourney(plan)
        case .failure(let block):
            sound.play(.error)
            if case .insufficientFuel = block, TravelSystem.emergencyPlan(to: destination, state) != nil {
                emergencyOffer = destination
            }
            toast(block.message)
        }
    }

    /// Burns just enough coal/fuel/wood for the trip, then departs.
    func refuelAndTravel(to destination: StationID) {
        guard case .failure(.insufficientFuel(let need, _)) = TravelSystem.plan(to: destination, state),
              InventorySystem.refuel(to: need, &state) else {
            travel(to: destination)
            return
        }
        sound.play(.refuel)
        travel(to: destination)
    }

    func emergencyTravel(to destination: StationID) {
        guard let plan = TravelSystem.emergencyPlan(to: destination, state) else { return }
        emergencyOffer = nil
        beginJourney(plan)
        toast("Nödkörning: loket kryper fram på reservbränsle. Tågets skick tar stryk.", important: true)
    }

    private func beginJourney(_ plan: TravelPlan) {
        TravelSystem.begin(plan, &state)
        overlays.removeAll { $0 == .map }
        travelSpeed = 1
        sound.play(.departure)
        sound.setAmbience(nil)
        sound.setTrainRunning(true)
        trainScene?.journeyStarted()
        autosave()
    }

    var canFastForward: Bool {
        guard let j = state.journey else { return false }
        return state.traveledRoutes.contains(j.routeID)
    }

    func toggleFastForward() {
        guard canFastForward else { return }
        travelSpeed = travelSpeed > 1 ? 1 : 4
    }

    func skipJourney() {
        guard canFastForward, let j = state.journey else { return }
        TravelSystem.advance(j.duration, &state)
        handleArrival()
    }

    func handleArrival() {
        travelSpeed = 1
        sound.setTrainRunning(false)
        sound.play(.arrival)
        let info = currentStationInfo
        sound.setAmbience(info.region)
        trainScene?.arrived()
        showCaption("\(info.name) — \(info.region.displayName)", seconds: 4)
        refreshTutorial()
        if TravelSystem.isStranded(state) {
            toast("Tanken är nästan tom. Samla trä, kol eller bränsle här och tanka vid loket.", important: true)
        }
        autosave()
    }

    // MARK: Train management

    func craft(_ id: RecipeID) {
        let result = CraftingSystem.craft(id, &state)
        switch result {
        case .success(let message):
            sound.play(.craft)
            Haptics.success()
            toast(message, important: true)
            trainScene?.rebuild()
            refreshTutorial()
            autosave()
        case .failure(let message):
            sound.play(.error)
            toast(message)
        }
    }

    func refuel(_ type: ResourceType) {
        let added = InventorySystem.refuel(with: type, maxUnits: 1, &state)
        if added > 0 {
            sound.play(.refuel)
        } else {
            sound.play(.error)
            toast(state.inventory.total(type) == 0 ? "Du har ingen \(ResourceCatalog.name(type).lowercased())." : "Tanken är full.")
        }
    }

    func fillTank() {
        let added = InventorySystem.autoRefuel(&state)
        if added > 0 {
            sound.play(.refuel)
            toast("Tankade \(Format.fuel(added)) enheter.")
            autosave()
        } else {
            sound.play(.error)
            toast(state.train.fuel >= stats.fuelCapacity - 1 ? "Tanken är full." : "Du har inget att tanka med.")
        }
    }

    func listenToRadio() {
        if state.inventory.has(.signalDecoder) {
            if let entry = ProgressionSystem.decodeRadio(&state) {
                sound.play(.secret)
                showDialog(.journal(entry))
                autosave()
                return
            }
            sound.play(.radio)
            let more = state.has(.decodedFragment2) ? "Inga fler meddelanden går att urskilja." : "Bruset är för starkt här. Kanske hörs mer närmare bergen i norr."
            showDialog(DialogContent(title: "Radion", text: "Avkodaren surrar.\n\n\(more)", style: .radio))
        } else {
            sound.play(.radio)
            showDialog(DialogContent(title: "Radion", text: "Brus... och sedan, svagt:\n\n”\(JournalCatalog.radioMessage)”\n\nNågonting annat finns också i bruset, men det går inte att urskilja.", style: .radio))
        }
    }

    func rest() {
        guard state.train.has(wagon: .living) else { return }
        state.health = GameState.maxHealth
        sound.play(.menuSelect)
        showDialog(DialogContent(title: "Bostadsvagnen", text: "Du tänder i kaminen och sträcker ut dig på britsen. Regnet trummar mot taket. För en stund känns världen nästan hel.\n\nDu är utvilad. Hälsan är full."))
    }

    func moveWagon(at index: Int, by offset: Int) {
        let target = index + offset
        guard state.journey == nil, state.train.wagons.indices.contains(index), state.train.wagons.indices.contains(target) else { return }
        state.train.wagons.swapAt(index, target)
        sound.play(.menuMove)
        trainScene?.rebuild()
        autosave()
    }
}
