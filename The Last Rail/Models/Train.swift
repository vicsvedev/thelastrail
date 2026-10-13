import Foundation

/// All wagon types the architecture supports. Only some are buildable in version 0.1;
/// see `WagonCatalog` for availability.
enum WagonType: String, Codable, CaseIterable, Identifiable {
    case cargo = "lastvagn"
    case workshop = "verkstadsvagn"
    case generator = "generatorvagn"
    case greenhouse = "vaxthusvagn"
    case research = "forskningsvagn"
    case living = "bostadsvagn"

    var id: String { rawValue }
}

/// Modules that can be installed inside an existing wagon.
enum WagonModule: String, Codable, CaseIterable {
    case workshopBench = "verkstadsbank"
}

struct Wagon: Codable, Equatable, Identifiable {
    var id: String
    var type: WagonType
    var modules: [WagonModule] = []
}

struct TrainState: Codable, Equatable {
    var locomotiveRepaired = false
    /// Fuel units currently in the locomotive tank.
    var fuel: Double = 0
    var engineLevel = 0
    var efficiencyLevel = 0
    var tankLevel = 0
    var storageLevel = 0
    var backpackLevel = 0
    /// 0–100. Decreases a little on every journey; low condition increases fuel use.
    var condition: Double = 100
    /// Wagons behind the locomotive, front to back.
    var wagons: [Wagon] = [Wagon(id: "wagon-1", type: .cargo)]

    func has(wagon type: WagonType) -> Bool { wagons.contains { $0.type == type } }
    func count(of type: WagonType) -> Int { wagons.filter { $0.type == type }.count }
    var hasWorkshopBench: Bool { wagons.contains { $0.modules.contains(.workshopBench) } }
}

/// An active journey. Stored in the save so a trip resumes after relaunch.
struct JourneyState: Codable, Equatable {
    var routeID: RouteID
    var from: StationID
    var to: StationID
    var fuelCost: Double
    var duration: Double
    var elapsed: Double = 0
    var fuelConsumed: Double = 0
    var emergency = false

    var progress: Double { duration <= 0 ? 1 : min(1, elapsed / duration) }
    var isFinished: Bool { elapsed >= duration }
}
