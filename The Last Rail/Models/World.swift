import Foundation

enum StationID: String, Codable, CaseIterable, Identifiable {
    case depot = "gamla_depan"
    case tallkorset = "tallkorset"
    case rosthamn = "rosthamn"
    case djupgruvan = "djupgruvan"
    case nordpasset = "nordpasset"
    case polaris = "polaris"

    var id: String { rawValue }
}

enum RouteID: String, Codable, CaseIterable, Identifiable {
    case depotTallkorset = "depan_tallkorset"
    case tallkorsetRosthamn = "tallkorset_rosthamn"
    case rosthamnDjupgruvan = "rosthamn_djupgruvan"
    case northernLine = "norra_linjen"
    case mineLine = "gruvbanan"
    case polarisLine = "polarislinjen"

    var id: String { rawValue }
}

/// Visual & audio theme of an area. Drives tile art, parallax backgrounds and ambience.
enum Region: String, Codable, CaseIterable {
    case depot
    case forest
    case industrial
    case mine
    case mountain

    var displayName: String {
        switch self {
        case .depot: return "Södra slätten"
        case .forest: return "Tallskogen"
        case .industrial: return "Rostbältet"
        case .mine: return "Gruvbergen"
        case .mountain: return "Nordfjällen"
        }
    }
}

struct StationInfo {
    let id: StationID
    let name: String
    let region: Region
    let description: String
    let specialties: [ResourceType]
    /// Normalized map position (0...1, origin top-left).
    let mapX: Double
    let mapY: Double
    /// Stations that only exist as a teaser in this version have no explorable layout.
    let explorable: Bool
}

enum RouteRequirement: Equatable {
    case flag(StoryFlag)
    case engineLevel(Int)
    /// Content that does not exist in this version. Never satisfiable.
    case futureContent
}

struct RouteInfo {
    let id: RouteID
    let a: StationID
    let b: StationID
    /// Abstract distance units. 1 unit ≈ 7 km on the map.
    let distance: Double
    let requirements: [RouteRequirement]
    /// When set, the route is not drawn until this flag is set.
    let hiddenUntil: StoryFlag?
    let lockedText: String
    let region: Region

    func connects(_ x: StationID, _ y: StationID) -> Bool {
        (a == x && b == y) || (a == y && b == x)
    }

    func other(than s: StationID) -> StationID? {
        if a == s { return b }
        if b == s { return a }
        return nil
    }
}

/// Persistent story and world flags.
enum StoryFlag: String, Codable, CaseIterable {
    case tutorialComplete
    case radioHeard
    case junctionSwitched
    case mineLineRevealed
    case mineLineRepaired
    case nordpassetGeneratorOn
    case signalSourceFound
    case decodedFragment1
    case decodedFragment2
    case chapterOneComplete
}

enum SecretID: String, Codable, CaseIterable {
    case tallkorsetCache = "tallkorset_gomstalle"
    case rosthamnCodeRoom = "rosthamn_kodrum"
    case djupgruvanSidePassage = "djupgruvan_sidogang"
    case nordpassetCairn = "nordpasset_roset"
    case depotStash = "depan_gomma"

    var name: String {
        switch self {
        case .tallkorsetCache: return "Förrådet bakom granarna"
        case .rosthamnCodeRoom: return "Det låsta utrustningsrummet"
        case .djupgruvanSidePassage: return "Den igenmurade sidogången"
        case .nordpassetCairn: return "Röset på klippavsatsen"
        case .depotStash: return "Gömman under golvet"
        }
    }
}
