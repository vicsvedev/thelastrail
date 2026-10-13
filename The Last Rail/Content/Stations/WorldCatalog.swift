import Foundation

enum WorldCatalog {
    static let stations: [StationInfo] = [
        StationInfo(id: .depot, name: "Gamla depån", region: .depot,
                    description: "Ett övergivet lokstall på den södra slätten. Här började din resa.",
                    specialties: [.scrap], mapX: 0.18, mapY: 0.86, explorable: true),
        StationInfo(id: .tallkorset, name: "Tallkorset", region: .forest,
                    description: "En liten skogsstation där spåren delar sig. Gott om trä och mat i skogen.",
                    specialties: [.wood, .food, .scrap], mapX: 0.36, mapY: 0.64, explorable: true),
        StationInfo(id: .rosthamn, name: "Rosthamn", region: .industrial,
                    description: "En rostig industristad. Fabrikerna är tysta, men lagren är fulla av koppar och maskindelar.",
                    specialties: [.copper, .machineParts, .scrap], mapX: 0.68, mapY: 0.60, explorable: true),
        StationInfo(id: .djupgruvan, name: "Djupgruvan", region: .mine,
                    description: "Gruvsamhället i bergen. Kol i överflöd – och mörka gångar ingen vågat gå in i.",
                    specialties: [.coal, .copper, .researchParts], mapX: 0.80, mapY: 0.32, explorable: true),
        StationInfo(id: .nordpasset, name: "Nordpasset", region: .mountain,
                    description: "En fjällstation högt uppe i passet. Radiosignalen är starkast här.",
                    specialties: [.researchParts, .wood], mapX: 0.44, mapY: 0.20, explorable: true),
        StationInfo(id: .polaris, name: "???", region: .mountain,
                    description: "Någonstans bortom raset i norr. Spåret fortsätter in i dimman.",
                    specialties: [], mapX: 0.50, mapY: 0.04, explorable: false),
    ]

    static let routes: [RouteInfo] = [
        RouteInfo(id: .depotTallkorset, a: .depot, b: .tallkorset, distance: 3,
                  requirements: [], hiddenUntil: nil,
                  lockedText: "Loket måste repareras först.", region: .forest),
        RouteInfo(id: .tallkorsetRosthamn, a: .tallkorset, b: .rosthamn, distance: 4,
                  requirements: [.flag(.tutorialComplete)], hiddenUntil: nil,
                  lockedText: "Spåret är igenvuxet. Slutför din första expedition först.", region: .industrial),
        RouteInfo(id: .rosthamnDjupgruvan, a: .rosthamn, b: .djupgruvan, distance: 4,
                  requirements: [.engineLevel(1)], hiddenUntil: nil,
                  lockedText: "Branta stigningar. Kräver Motoruppgradering I.", region: .mine),
        RouteInfo(id: .northernLine, a: .tallkorset, b: .nordpasset, distance: 11,
                  requirements: [.flag(.junctionSwitched)], hiddenUntil: nil,
                  lockedText: "Växeln mot Norra linjen är låst. Den styrs från ställverket i Rosthamn.", region: .mountain),
        RouteInfo(id: .mineLine, a: .djupgruvan, b: .nordpasset, distance: 5,
                  requirements: [.flag(.mineLineRepaired)], hiddenUntil: .mineLineRevealed,
                  lockedText: "Gamla gruvbanan är raserad. Kräver Spårreparation.", region: .mountain),
        RouteInfo(id: .polarisLine, a: .nordpasset, b: .polaris, distance: 9,
                  requirements: [.futureContent], hiddenUntil: nil,
                  lockedText: "Ett jättelikt ras blockerar spåret norrut. Ingen väg förbi – inte än.", region: .mountain),
    ]

    private static let stationByID: [StationID: StationInfo] = Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
    private static let routeByID: [RouteID: RouteInfo] = Dictionary(uniqueKeysWithValues: routes.map { ($0.id, $0) })

    static func station(_ id: StationID) -> StationInfo { stationByID[id]! }
    static func route(_ id: RouteID) -> RouteInfo { routeByID[id]! }

    static func route(between a: StationID, _ b: StationID) -> RouteInfo? {
        routes.first { $0.connects(a, b) }
    }

    static func routes(from s: StationID) -> [RouteInfo] {
        routes.filter { $0.a == s || $0.b == s }
    }

    static func layout(_ id: StationID) -> StationLayout? {
        switch id {
        case .depot: return DepotLayout.layout
        case .tallkorset: return TallkorsetLayout.layout
        case .rosthamn: return RosthamnLayout.layout
        case .djupgruvan: return DjupgruvanLayout.layout
        case .nordpasset: return NordpassetLayout.layout
        case .polaris: return nil
        }
    }
}
