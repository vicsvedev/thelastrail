import Foundation

enum TravelBlock: Error, Equatable {
    case alreadyHere
    case journeyInProgress
    case notOnTrain
    case locomotiveBroken
    case notConnected
    case undiscovered
    case routeLocked(String)
    case tankTooSmall(need: Double, capacity: Double)
    case insufficientFuel(need: Double, have: Double)

    var message: String {
        switch self {
        case .alreadyHere: return "Du är redan här."
        case .journeyInProgress: return "Tåget är redan på väg."
        case .notOnTrain: return "Gå ombord på tåget för att resa."
        case .locomotiveBroken: return "Loket måste repareras först."
        case .notConnected: return "Det finns inget spår dit härifrån."
        case .undiscovered: return "Du vet inte var den stationen ligger."
        case .routeLocked(let text): return text
        case .tankTooSmall(let need, let cap):
            return "Resan kräver \(Format.fuel(need)) bränsle men tanken rymmer bara \(Format.fuel(cap)). Bygg en större tank eller effektivisera motorn."
        case .insufficientFuel(let need, let have):
            return "Resan kräver \(Format.fuel(need)) bränsle. Tanken har \(Format.fuel(have)). Tanka vid loket."
        }
    }
}

struct TravelPlan: Equatable {
    let route: RouteInfo.ID
    let from: StationID
    let to: StationID
    let distance: Double
    let fuelCost: Double
    let duration: Double
    /// Crawl home on reserve fuel. Only offered when nothing else is possible.
    let emergency: Bool
}

extension RouteInfo { typealias ID = RouteID }

enum TravelSystem {
    static let conditionLossPerJourney: Double = 3
    static let emergencyConditionLoss: Double = 20

    static func isRevealed(_ route: RouteInfo, _ state: GameState) -> Bool {
        guard let flag = route.hiddenUntil else { return true }
        return state.has(flag)
    }

    static func unmetRequirements(_ route: RouteInfo, _ state: GameState) -> [RouteRequirement] {
        route.requirements.filter { req in
            switch req {
            case .flag(let f): return !state.has(f)
            case .engineLevel(let level): return state.train.engineLevel < level
            case .futureContent: return true
            }
        }
    }

    static func isUnlocked(_ route: RouteInfo, _ state: GameState) -> Bool {
        isRevealed(route, state) && unmetRequirements(route, state).isEmpty
    }

    static func plan(to destination: StationID, _ state: GameState, requireOnTrain: Bool = true) -> Result<TravelPlan, TravelBlock> {
        let from = state.currentStation
        if state.journey != nil { return .failure(.journeyInProgress) }
        if destination == from { return .failure(.alreadyHere) }
        if !state.discoveredStations.contains(destination) { return .failure(.undiscovered) }
        guard let route = WorldCatalog.route(between: from, destination), isRevealed(route, state) else {
            return .failure(.notConnected)
        }
        if !unmetRequirements(route, state).isEmpty { return .failure(.routeLocked(route.lockedText)) }
        if !state.train.locomotiveRepaired { return .failure(.locomotiveBroken) }
        if requireOnTrain && state.location != .onTrain { return .failure(.notOnTrain) }

        let stats = TrainStats(state: state)
        let cost = stats.fuelCost(distance: route.distance)
        let duration = stats.travelDuration(distance: route.distance)
        if cost > stats.fuelCapacity + 0.0001 {
            return .failure(.tankTooSmall(need: cost, capacity: stats.fuelCapacity))
        }
        if cost > state.train.fuel + 0.0001 {
            return .failure(.insufficientFuel(need: cost, have: state.train.fuel))
        }
        return .success(TravelPlan(route: route.id, from: from, to: destination, distance: route.distance,
                                   fuelCost: cost, duration: duration, emergency: false))
    }

    /// Emergency crawl: allowed to an already visited station when the tank and every burnable the
    /// player owns cannot cover any trip. Prevents the player from ever being stranded.
    static func emergencyPlan(to destination: StationID, _ state: GameState) -> TravelPlan? {
        guard state.journey == nil, state.location == .onTrain, state.train.locomotiveRepaired,
              state.visitedStations.contains(destination),
              let route = WorldCatalog.route(between: state.currentStation, destination),
              isUnlocked(route, state) else { return nil }
        guard isStranded(state) else { return nil }
        let stats = TrainStats(state: state)
        return TravelPlan(route: route.id, from: state.currentStation, to: destination, distance: route.distance,
                          fuelCost: state.train.fuel, duration: stats.travelDuration(distance: route.distance) * 1.6,
                          emergency: true)
    }

    /// True when no unlocked route can be afforded even after burning everything the player owns.
    static func isStranded(_ state: GameState) -> Bool {
        let stats = TrainStats(state: state)
        let available = state.train.fuel + InventorySystem.burnableFuelValue(state)
        let usable = min(available, stats.fuelCapacity)
        let routes = WorldCatalog.routes(from: state.currentStation).filter { isUnlocked($0, state) }
        guard !routes.isEmpty else { return false }
        return routes.allSatisfy { stats.fuelCost(distance: $0.distance) > usable + 0.0001 }
    }

    static func begin(_ plan: TravelPlan, _ state: inout GameState) {
        state.journey = JourneyState(routeID: plan.route, from: plan.from, to: plan.to,
                                     fuelCost: plan.fuelCost, duration: plan.duration,
                                     emergency: plan.emergency)
        state.location = .onTrain
    }

    /// Advances the journey; consumes fuel proportionally. Returns true when the train has arrived.
    @discardableResult
    static func advance(_ dt: Double, _ state: inout GameState) -> Bool {
        guard var journey = state.journey else { return false }
        journey.elapsed = min(journey.duration, journey.elapsed + dt)
        let target = journey.fuelCost * journey.progress
        let delta = max(0, target - journey.fuelConsumed)
        journey.fuelConsumed += delta
        state.train.fuel = max(0, state.train.fuel - delta)
        state.journey = journey
        if journey.isFinished {
            arrive(&state)
            return true
        }
        return false
    }

    static func arrive(_ state: inout GameState) {
        guard let journey = state.journey else { return }
        // Settle any rounding so the full cost is always consumed exactly once.
        let remaining = max(0, journey.fuelCost - journey.fuelConsumed)
        state.train.fuel = max(0, state.train.fuel - remaining)
        state.journey = nil
        state.currentStation = journey.to
        state.location = .onTrain
        state.playerPosition = nil
        state.traveledRoutes.insert(journey.routeID)
        state.visitedStations.insert(journey.to)
        state.journeyCount += 1
        let loss = journey.emergency ? emergencyConditionLoss : conditionLossPerJourney
        state.train.condition = max(0, state.train.condition - loss)
        discoverNeighbors(of: journey.to, &state)
    }

    /// Arriving somewhere reveals the stations that its (visible) tracks lead to.
    static func discoverNeighbors(of station: StationID, _ state: inout GameState) {
        state.discoveredStations.insert(station)
        for route in WorldCatalog.routes(from: station) where isRevealed(route, state) {
            if let other = route.other(than: station) { state.discoveredStations.insert(other) }
        }
    }

    static func hasTraveled(_ route: RouteID, _ state: GameState) -> Bool {
        state.traveledRoutes.contains(route)
    }
}

enum Format {
    static func fuel(_ v: Double) -> String {
        let rounded = (v * 10).rounded() / 10
        if rounded == rounded.rounded() { return String(Int(rounded)) }
        return String(format: "%.1f", rounded).replacingOccurrences(of: ".", with: ",")
    }

    static func km(_ distance: Double) -> String { "\(Int((distance * 7).rounded())) km" }

    static func seconds(_ s: Double) -> String { "\(Int(s.rounded())) s" }
}
