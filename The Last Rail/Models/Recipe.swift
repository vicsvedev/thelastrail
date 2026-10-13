import Foundation

enum RecipeID: String, Codable, CaseIterable, Identifiable, CodingKeyRepresentable {
    case simpleRepair = "enkel_reparation"
    case repairKit = "reparationssats"
    case workshop = "grundlaggande_verkstad"
    case reinforcedStorage = "forstarkt_lager"
    case engine1 = "motoruppgradering_1"
    case efficiency1 = "bransleeffektivisering_1"
    case crowbar = "kofot"
    case headlamp = "pannlampa"
    case backpack = "storre_ryggsack"
    case fuelTank = "extra_bransletank"
    case workshopWagon = "verkstadsvagn"
    case engine2 = "motoruppgradering_2"
    case trackRepair = "sparreparation"
    case signalDecoder = "signalavkodare"
    case livingWagon = "bostadsvagn"
    case extraCargo = "extra_lastvagn"

    var id: String { rawValue }
}

enum RecipeCategory: String, CaseIterable {
    case maintenance = "Underhåll"
    case construction = "Bygg"
    case upgrades = "Uppgraderingar"
    case tools = "Verktyg"
    case wagons = "Vagnar"
}

enum RecipeRequirement: Equatable {
    /// The recipe is unknown until its blueprint has been found.
    case blueprint
    case locomotiveRepaired
    /// 1 = workbench module, 2 = workshop wagon.
    case workshopLevel(Int)
    case completed(RecipeID)
}

enum RecipeEffect: Equatable {
    case repairTrain(Double)
    case addItem(ItemType, Int)
    case installModule(WagonModule)
    case addWagon(WagonType)
    case engineLevel(Int)
    case efficiencyLevel(Int)
    case storageLevel(Int)
    case tankLevel(Int)
    case backpackLevel(Int)
    case setFlag(StoryFlag)
}

struct Recipe: Identifiable {
    let id: RecipeID
    let name: String
    let description: String
    let category: RecipeCategory
    let cost: ResourceCost
    let effect: RecipeEffect
    let requirements: [RecipeRequirement]
    let oneTime: Bool

    var needsBlueprint: Bool { requirements.contains(.blueprint) }
}
