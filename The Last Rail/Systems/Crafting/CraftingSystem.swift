import Foundation

enum RecipeStatus: Equatable {
    case available
    case missingResources(ResourceCost)
    case locked([String])
    case alreadyBuilt
    case unknown
}

enum CraftResult: Equatable {
    case success(String)
    case failure(String)

    var succeeded: Bool {
        if case .success = self { return true }
        return false
    }
}

enum CraftingSystem {
    static func isKnown(_ recipe: Recipe, _ state: GameState) -> Bool {
        !recipe.needsBlueprint || state.knownBlueprints.contains(recipe.id)
    }

    /// Unmet non-resource requirements, as Swedish sentences.
    static func unmetRequirements(_ recipe: Recipe, _ state: GameState) -> [String] {
        let stats = TrainStats(state: state)
        var reasons: [String] = []
        for req in recipe.requirements {
            switch req {
            case .blueprint:
                if !state.knownBlueprints.contains(recipe.id) { reasons.append("Ritning saknas") }
            case .locomotiveRepaired:
                if !state.train.locomotiveRepaired { reasons.append("Loket måste repareras") }
            case .workshopLevel(let level):
                if stats.workshopLevel < level {
                    reasons.append(level >= 2 ? "Kräver Verkstadsvagn" : "Kräver Grundläggande verkstad")
                }
            case .completed(let other):
                if !state.completedUpgrades.contains(other) {
                    reasons.append("Kräver \(RecipeCatalog.recipe(other).name)")
                }
            }
        }
        return reasons
    }

    static func status(_ recipe: Recipe, _ state: GameState) -> RecipeStatus {
        guard isKnown(recipe, state) else { return .unknown }
        if recipe.oneTime && state.completedUpgrades.contains(recipe.id) { return .alreadyBuilt }
        let reasons = unmetRequirements(recipe, state)
        if !reasons.isEmpty { return .locked(reasons) }
        if case .repairTrain = recipe.effect, state.train.condition >= 100 {
            return .locked(["Tåget är redan i toppskick"])
        }
        let missing = InventorySystem.missing(recipe.cost, state)
        if !missing.isEmpty { return .missingResources(missing) }
        return .available
    }

    /// Recipes shown in the construction UI (known ones), in catalog order.
    static func visibleRecipes(_ state: GameState) -> [Recipe] {
        RecipeCatalog.all.filter { isKnown($0, state) }
    }

    @discardableResult
    static func craft(_ id: RecipeID, _ state: inout GameState) -> CraftResult {
        let recipe = RecipeCatalog.recipe(id)
        switch status(recipe, state) {
        case .unknown:
            return .failure("Du känner inte till den här konstruktionen ännu.")
        case .alreadyBuilt:
            return .failure("\(recipe.name) är redan byggd.")
        case .locked(let reasons):
            return .failure(reasons.joined(separator: ". "))
        case .missingResources(let missing):
            let list = missing.sorted { $0.key.rawValue < $1.key.rawValue }
                .map { "\($0.value) \(ResourceCatalog.name($0.key).lowercased())" }
                .joined(separator: ", ")
            return .failure("Saknar \(list).")
        case .available:
            break
        }
        guard InventorySystem.consume(recipe.cost, &state) else {
            return .failure("Resurserna räcker inte.")
        }
        apply(recipe.effect, &state)
        if recipe.oneTime { state.completedUpgrades.insert(recipe.id) }
        return .success(successMessage(recipe))
    }

    static func apply(_ effect: RecipeEffect, _ state: inout GameState) {
        switch effect {
        case .repairTrain(let amount):
            state.train.condition = min(100, state.train.condition + amount)
        case .addItem(let item, let count):
            InventorySystem.addItem(item, count, &state)
        case .installModule(let module):
            if let index = state.train.wagons.firstIndex(where: { $0.type == .cargo && !$0.modules.contains(module) }) {
                state.train.wagons[index].modules.append(module)
            }
        case .addWagon(let type):
            let n = state.train.wagons.count + 1
            state.train.wagons.append(Wagon(id: "wagon-\(n)-\(type.rawValue)", type: type))
        case .engineLevel(let level):
            state.train.engineLevel = max(state.train.engineLevel, level)
        case .efficiencyLevel(let level):
            state.train.efficiencyLevel = max(state.train.efficiencyLevel, level)
        case .storageLevel(let level):
            state.train.storageLevel = max(state.train.storageLevel, level)
        case .tankLevel(let level):
            state.train.tankLevel = max(state.train.tankLevel, level)
        case .backpackLevel(let level):
            state.train.backpackLevel = max(state.train.backpackLevel, level)
        case .setFlag(let flag):
            state.flags.insert(flag)
        }
    }

    private static func successMessage(_ recipe: Recipe) -> String {
        switch recipe.effect {
        case .repairTrain: return "Tåget är lagat."
        case .addItem(let item, _): return "\(ItemCatalog.name(item)) tillverkad."
        case .addWagon: return "\(recipe.name) är kopplad till tåget!"
        case .setFlag(.mineLineRepaired): return "Gamla gruvbanan är lagad! Rutten Djupgruvan – Nordpasset är öppen."
        default: return "\(recipe.name) är klar!"
        }
    }
}
