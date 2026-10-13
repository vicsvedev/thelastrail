import Foundation

enum PlayerLocation: String, Codable {
    case onTrain
    case exploring
}

struct SavedPosition: Codable, Equatable {
    var station: StationID
    var x: Double
    var y: Double
}

/// Complete persistent game state. Everything that must survive a relaunch lives here.
struct GameState: Codable, Equatable {
    static let currentVersion = 1

    var version = GameState.currentVersion
    var inventory = Inventory()
    var train = TrainState()
    var currentStation: StationID = .depot
    var location: PlayerLocation = .exploring
    var playerPosition: SavedPosition?
    var health: Double = 100
    var journey: JourneyState?

    var discoveredStations: Set<StationID> = [.depot]
    var visitedStations: Set<StationID> = [.depot]
    var traveledRoutes: Set<RouteID> = []

    /// One-time objects that were collected/opened, keyed "station/object".
    var collectedObjects: Set<String> = []
    /// Renewable objects that are depleted, mapped to the journey count when depleted.
    var depletedRenewables: [String: Int] = [:]
    /// Partially looted piles/containers (the backpack was full), keyed "station/object".
    var remainingLoot: [String: ResourceCost] = [:]
    var discoveredSecrets: Set<SecretID> = []
    /// Ordered by discovery.
    var journal: [JournalID] = []
    var knownBlueprints: Set<RecipeID> = []
    var completedUpgrades: Set<RecipeID> = []
    var flags: Set<StoryFlag> = []
    var tutorial = TutorialState()
    var journeyCount = 0
    var playTime: Double = 0

    static let maxHealth: Double = 100

    func has(_ flag: StoryFlag) -> Bool { flags.contains(flag) }

    static func newGame() -> GameState { GameState() }
}

extension GameState {
    static func objectKey(_ station: StationID, _ object: String) -> String {
        "\(station.rawValue)/\(object)"
    }
}
