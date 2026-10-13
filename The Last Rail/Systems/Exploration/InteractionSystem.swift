import Foundation

struct InteractionResult: Equatable {
    var toasts: [String] = []
    var floatingText: String?
    var dialog: DialogContent?
    var sound: SoundEffect?
    var secret: SecretID?
    var openKeypad = false
    /// The scene should re-evaluate this object's appearance/collision.
    var objectChanged = false
}

/// Pure rules for exploring: what objects exist, what they do, hazards and fainting.
enum InteractionSystem {
    static let faceRadius: Double = 22

    // MARK: Availability

    static func key(_ station: StationID, _ obj: MapObjectDef) -> String {
        GameState.objectKey(station, obj.id)
    }

    /// Whether a pickup/container still has something in it (or a door is still closed, etc.).
    static func exists(_ obj: MapObjectDef, _ state: GameState) -> Bool {
        guard let flag = obj.requires else { return true }
        return state.has(flag)
    }

    static func isActive(_ obj: MapObjectDef, station: StationID, _ state: GameState) -> Bool {
        guard exists(obj, state) else { return false }
        let k = key(station, obj)
        switch obj.kind {
        case .resource, .container:
            if obj.renewable {
                if let depletedAt = state.depletedRenewables[k] { return state.journeyCount > depletedAt }
                return true
            }
            return !state.collectedObjects.contains(k)
        case .blueprint(let recipe, _):
            return !state.collectedObjects.contains(k) && !state.knownBlueprints.contains(recipe)
        case .keyItem, .door:
            return !state.collectedObjects.contains(k)
        case .barrier(let lock, _):
            return !isLockSatisfied(lock, state)
        case .note, .machine, .sign:
            return true
        }
    }

    /// Whether the object currently blocks movement.
    static func blocksMovement(_ obj: MapObjectDef, station: StationID, _ state: GameState) -> Bool {
        guard exists(obj, state) else { return false }
        switch obj.kind {
        case .door, .barrier: return isActive(obj, station: station, state)
        case .container, .machine: return true
        default: return false
        }
    }

    static func isLockSatisfied(_ lock: LockRequirement, _ state: GameState) -> Bool {
        switch lock {
        case .tool(let item): return state.inventory.has(item)
        case .code: return false
        }
    }

    static func loot(_ obj: MapObjectDef, station: StationID, _ state: GameState) -> ResourceCost {
        let k = key(station, obj)
        if let remaining = state.remainingLoot[k] { return remaining }
        switch obj.kind {
        case .resource(let type, let amount): return [type: amount]
        case .container(let cost, _): return cost
        default: return [:]
        }
    }

    // MARK: Prompts

    /// Text for the "[E] ..." prompt, or nil if the object is not interactable right now.
    static func prompt(_ obj: MapObjectDef, station: StationID, _ state: GameState) -> String? {
        guard exists(obj, state) else { return nil }
        let active = isActive(obj, station: station, state)
        switch obj.kind {
        case .resource(let type, _):
            guard active else { return nil }
            return "Plocka upp \(ResourceCatalog.name(type).lowercased())"
        case .container:
            return active ? "Öppna" : nil
        case .note:
            return "Läs"
        case .blueprint:
            return active ? "Ta ritningen" : nil
        case .keyItem(let item):
            return active ? "Ta \(ItemCatalog.name(item).lowercased())" : nil
        case .door(let lock):
            guard active else { return nil }
            switch lock {
            case .tool: return "Öppna dörren"
            case .code: return "Knappa in kod"
            }
        case .barrier:
            return active ? "Undersök" : nil
        case .machine(let kind):
            switch kind {
            case .signalBox: return "Undersök ställverket"
            case .generator: return state.has(.nordpassetGeneratorOn) ? "Lyssna på generatorn" : "Starta generatorn"
            case .radioTerminal: return "Använd terminalen"
            case .depotRadio: return "Lyssna på radion"
            }
        case .sign:
            return "Läs skylten"
        }
    }

    // MARK: Interaction

    static func interact(_ obj: MapObjectDef, station: StationID, _ state: inout GameState) -> InteractionResult {
        var result = InteractionResult()
        let k = key(station, obj)
        guard exists(obj, state), isActive(obj, station: station, state) || !obj.kind.isConsumable else { return result }

        switch obj.kind {
        case .resource, .container:
            if case .container(_, let items) = obj.kind, state.remainingLoot[k] == nil {
                for item in items {
                    InventorySystem.addItem(item, 1, &state)
                    result.toasts.append("Hittade: \(ItemCatalog.name(item))")
                }
            }
            takeLoot(obj, station: station, &state, &result)
            if result.objectChanged, let secret = obj.secret { registerSecret(secret, &state, &result) }

        case .note(let journal):
            addJournal(journal, &state)
            result.dialog = .journal(journal)
            result.sound = .paper
            if let secret = obj.secret { registerSecret(secret, &state, &result) }

        case .blueprint(let recipe, let journal):
            state.knownBlueprints.insert(recipe)
            state.collectedObjects.insert(k)
            addJournal(journal, &state)
            result.dialog = DialogContent(title: "Ny ritning: \(RecipeCatalog.recipe(recipe).name)",
                                          text: JournalCatalog.entry(journal).text, style: .blueprint)
            result.toasts.append("Ny ritning: \(RecipeCatalog.recipe(recipe).name)")
            result.sound = .secret
            result.objectChanged = true
            if recipe == .trackRepair { state.flags.insert(.mineLineRevealed) }
            if let secret = obj.secret { registerSecret(secret, &state, &result) }

        case .keyItem(let item):
            InventorySystem.addItem(item, 1, &state)
            state.collectedObjects.insert(k)
            result.toasts.append("Hittade: \(ItemCatalog.name(item))")
            result.floatingText = "+1 \(ItemCatalog.name(item))"
            result.sound = .pickup
            result.objectChanged = true

        case .door(let lock):
            switch lock {
            case .tool(let item):
                if state.inventory.has(item) {
                    state.collectedObjects.insert(k)
                    result.toasts.append("Du bänder upp dörren med \(ItemCatalog.name(item).lowercased())n.")
                    result.sound = .door
                    result.objectChanged = true
                    if let secret = obj.secret { registerSecret(secret, &state, &result) }
                } else {
                    result.dialog = DialogContent(title: "Fastrostad dörr",
                                                  text: "Dörren sitter benhårt fast. Med en \(ItemCatalog.name(item).lowercased()) skulle den gå att bända upp.\n\nKofoten kan byggas i verkstaden.")
                    result.sound = .error
                }
            case .code:
                result.openKeypad = true
            }

        case .barrier(_, let message):
            result.dialog = DialogContent(title: "Stopp", text: message)
            result.sound = .error

        case .machine(let kind):
            interactMachine(kind, station: station, &state, &result)

        case .sign(let title, let text):
            result.dialog = DialogContent(title: title, text: text, style: .note)
            result.sound = .paper
        }
        return result
    }

    /// Validates a keypad code for a door. On success the door opens.
    static func enterCode(_ code: String, for obj: MapObjectDef, station: StationID, _ state: inout GameState) -> InteractionResult {
        var result = InteractionResult()
        guard case .door(.code(let correct)) = obj.kind, isActive(obj, station: station, state) else { return result }
        if code == correct {
            state.collectedObjects.insert(key(station, obj))
            result.toasts.append("Låset klickar. Dörren glider upp.")
            result.sound = .door
            result.objectChanged = true
            if let secret = obj.secret { registerSecret(secret, &state, &result) }
        } else {
            result.toasts.append("Fel kod.")
            result.sound = .error
        }
        return result
    }

    private static func takeLoot(_ obj: MapObjectDef, station: StationID, _ state: inout GameState, _ result: inout InteractionResult) {
        let k = key(station, obj)
        var remaining = loot(obj, station: station, state)
        var gained: [String] = []
        for type in ResourceType.allCases {
            guard let amount = remaining[type], amount > 0 else { continue }
            let added = InventorySystem.add(type, amount, to: .backpack, &state)
            if added > 0 { gained.append("+\(added) \(ResourceCatalog.name(type))") }
            let left = amount - added
            remaining[type] = left > 0 ? left : nil
        }
        if gained.isEmpty {
            result.toasts.append("Ryggsäcken är full! Gå tillbaka till tåget och lasta av.")
            result.sound = .error
            return
        }
        result.floatingText = gained.joined(separator: "  ")
        result.sound = .pickup
        result.objectChanged = true
        if remaining.isEmpty {
            state.remainingLoot[k] = nil
            if obj.renewable {
                state.depletedRenewables[k] = state.journeyCount
            } else {
                state.collectedObjects.insert(k)
            }
        } else {
            state.remainingLoot[k] = remaining
            result.toasts.append("Ryggsäcken är full – resten ligger kvar.")
        }
    }

    private static func interactMachine(_ kind: MachineKind, station: StationID, _ state: inout GameState, _ result: inout InteractionResult) {
        switch kind {
        case .signalBox:
            if state.has(.junctionSwitched) {
                result.dialog = DialogContent(title: "Ställverket", text: "Lamporna lyser grönt. Växeln mot Norra linjen är omlagd.")
                return
            }
            addJournal(.rosthamnSignalBox, &state)
            let hasFuse = state.inventory.has(.fuse)
            let hasKit = state.inventory.has(.repairKit)
            if hasFuse && hasKit {
                InventorySystem.removeItem(.fuse, 1, &state)
                InventorySystem.removeItem(.repairKit, 1, &state)
                state.flags.insert(.junctionSwitched)
                TravelSystem.discoverNeighbors(of: .tallkorset, &state)
                state.discoveredStations.insert(.nordpasset)
                result.dialog = DialogContent(title: "Ställverket lever!",
                                              text: "Du sätter i säkringen och lagar de brända kablarna. Panelen tänds en lampa i taget.\n\nLångt borta hörs en tung växel slå om.\n\nNorra linjen från Tallkorset mot Nordpasset är öppen. Det är en lång resa – se till att tanken räcker.",
                                              style: .discovery)
                result.sound = .secret
                result.toasts.append("Ny rutt: Tallkorset – Nordpasset")
            } else {
                var missing: [String] = []
                if !hasFuse { missing.append("• En säkring till växelmotorerna") }
                if !hasKit { missing.append("• En reparationssats för de brända kablarna") }
                result.dialog = DialogContent(title: "Ställverket",
                                              text: JournalCatalog.entry(.rosthamnSignalBox).text + "\n\nFör att få igång det behöver du:\n" + missing.joined(separator: "\n"),
                                              style: .note)
                result.sound = .error
            }

        case .generator:
            if state.has(.nordpassetGeneratorOn) {
                result.dialog = DialogContent(title: "Generatorn", text: "Generatorn dunkar på. Radiotornet har ström.")
                return
            }
            if InventorySystem.consume([.coal: 3], &state) {
                state.flags.insert(.nordpassetGeneratorOn)
                result.dialog = DialogContent(title: "Generatorn startar",
                                              text: "Du skyfflar in kol och drar i startsnöret. Efter tre försök hostar generatorn igång. Lamporna i radiotornet flimrar och tänds.",
                                              style: .discovery)
                result.sound = .engineStart
                result.objectChanged = true
            } else {
                result.dialog = DialogContent(title: "Reservgeneratorn",
                                              text: "En kolfylld reservgenerator. Pannan är tom.\n\nDen behöver 3 kol för att starta. (Du har \(state.inventory.total(.coal)).)")
                result.sound = .error
            }

        case .radioTerminal:
            guard state.has(.nordpassetGeneratorOn) else {
                result.dialog = DialogContent(title: "Radioterminalen", text: "Skärmen är död. Radiotornet saknar ström – reservgeneratorn står utanför.")
                result.sound = .error
                return
            }
            let first = !state.has(.signalSourceFound)
            state.flags.insert(.signalSourceFound)
            state.flags.insert(.chapterOneComplete)
            addJournal(.nordpassetLog, &state)
            state.discoveredStations.insert(.polaris)
            result.dialog = .journal(.nordpassetLog)
            result.sound = first ? .secret : .radio

        case .depotRadio:
            result.dialog = DialogContent(title: "Radion", text: "Brus... och sedan, svagt:\n\n”\(JournalCatalog.radioMessage)”", style: .radio)
            result.sound = .radio
        }
    }

    static func addJournal(_ id: JournalID, _ state: inout GameState) {
        if !state.journal.contains(id) { state.journal.append(id) }
    }

    static func registerSecret(_ secret: SecretID, _ state: inout GameState, _ result: inout InteractionResult) {
        guard !state.discoveredSecrets.contains(secret) else { return }
        state.discoveredSecrets.insert(secret)
        result.secret = secret
        result.sound = .secret
        result.toasts.append("Hemlighet upptäckt: \(secret.name) (\(state.discoveredSecrets.count)/\(SecretID.allCases.count))")
    }

    // MARK: Health

    /// Applies damage. Returns true if the player fainted.
    static func damage(_ amount: Double, _ state: inout GameState) -> Bool {
        state.health = max(0, state.health - amount)
        return state.health <= 0
    }

    /// Faint: respawn at the train with full health, losing half of what was carried.
    static func faint(_ state: inout GameState) -> ResourceCost {
        let lost = InventorySystem.applyFaintPenalty(&state)
        state.health = GameState.maxHealth
        state.playerPosition = nil
        return lost
    }

    /// Eats one food from the backpack (or storage) to heal.
    static func eat(_ state: inout GameState) -> Bool {
        guard state.health < GameState.maxHealth, InventorySystem.consume([.food: 1], &state) else { return false }
        state.health = min(GameState.maxHealth, state.health + 30)
        return true
    }
}

private extension MapObjectKind {
    /// Kinds whose interaction only makes sense while active.
    var isConsumable: Bool {
        switch self {
        case .note, .machine, .sign: return false
        default: return true
        }
    }
}
