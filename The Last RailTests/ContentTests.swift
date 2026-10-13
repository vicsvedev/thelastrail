import Testing
@testable import The_Last_Rail

/// Validates the handcrafted content so a typo can never soft-lock the game.
@MainActor
struct ContentTests {
    static let explorable = StationID.allCases.filter { WorldCatalog.layout($0) != nil }

    @Test(arguments: ContentTests.explorable)
    func mapIsRectangular(_ station: StationID) {
        let layout = WorldCatalog.layout(station)!
        let widths = Set(layout.rows.map(\.count))
        #expect(widths.count == 1, "\(station): rows have different widths \(widths)")
        for row in layout.rows {
            for ch in row { #expect(TileKind(rawValue: ch) != nil, "\(station): unknown tile '\(ch)'") }
        }
    }

    @Test(arguments: ContentTests.explorable)
    func objectsAreValid(_ station: StationID) {
        let layout = WorldCatalog.layout(station)!
        var ids = Set<String>()
        var tiles = Set<TilePoint>()
        for obj in layout.objects {
            #expect(ids.insert(obj.id).inserted, "\(station): duplicate id \(obj.id)")
            #expect(tiles.insert(obj.at).inserted, "\(station): two objects on \(obj.at)")
            #expect(obj.at.col >= 0 && obj.at.col < layout.width && obj.at.row >= 0 && obj.at.row < layout.height)
            #expect(!layout.tile(obj.at.col, obj.at.row).isSolid, "\(station): \(obj.id) is inside a solid tile")
        }
        #expect(!layout.tile(layout.spawn.col, layout.spawn.row).isSolid, "\(station): spawn is solid")
        #expect(layout.tile(layout.trainFront.col, layout.trainFront.row) == .rail, "\(station): train is not on rails")
    }

    /// Breadth-first search from the spawn. Doors and barriers count as passable (they can be opened),
    /// the parked train (at maximum length) is solid.
    private func reachable(_ layout: StationLayout) -> Set<TilePoint> {
        var blocked = Set<TilePoint>()
        let maxTrainTiles = 4 + 4 * 4
        for c in (layout.trainFront.col - maxTrainTiles + 1)...layout.trainFront.col {
            blocked.insert(TilePoint(col: c, row: layout.trainFront.row))
        }
        for obj in layout.objects {
            switch obj.kind {
            case .container, .machine: blocked.insert(obj.at)
            default: break
            }
        }
        var seen: Set<TilePoint> = [layout.spawn]
        var queue = [layout.spawn]
        while let p = queue.popLast() {
            for (dc, dr) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let n = TilePoint(col: p.col + dc, row: p.row + dr)
                guard !seen.contains(n), !blocked.contains(n), !layout.tile(n.col, n.row).isSolid else { continue }
                seen.insert(n)
                queue.append(n)
            }
        }
        return seen
    }

    @Test(arguments: ContentTests.explorable)
    func everyObjectIsReachable(_ station: StationID) {
        let layout = WorldCatalog.layout(station)!
        let reach = reachable(layout)
        for obj in layout.objects {
            let neighbors = [obj.at] + [(1, 0), (-1, 0), (0, 1), (0, -1)].map { TilePoint(col: obj.at.col + $0.0, row: obj.at.row + $0.1) }
            #expect(neighbors.contains { reach.contains($0) }, "\(station): \(obj.id) at \(obj.at) cannot be reached")
        }
        // The train must be reachable to board it.
        let front = layout.trainFront
        let nearTrain = [TilePoint(col: front.col, row: front.row - 1), TilePoint(col: front.col, row: front.row + 1),
                         TilePoint(col: front.col - 2, row: front.row - 1), TilePoint(col: front.col + 1, row: front.row)]
        #expect(nearTrain.contains { reach.contains($0) }, "\(station): cannot walk to the train")
    }

    @Test(arguments: ContentTests.explorable)
    func zonesAndBuildingsAreInBounds(_ station: StationID) {
        let layout = WorldCatalog.layout(station)!
        for r in layout.zones.map(\.rect) + layout.buildings.map(\.rect) {
            #expect(r.col >= 0 && r.row >= 0 && r.col + r.width <= layout.width && r.row + r.height <= layout.height)
        }
    }

    /// Every station must offer enough renewable burnables to leave again on a base-stats train.
    @Test(arguments: ContentTests.explorable)
    func renewableFuelPreventsStranding(_ station: StationID) {
        let layout = WorldCatalog.layout(station)!
        var units = 0.0
        for obj in layout.objects where obj.renewable {
            if case .resource(let type, let n) = obj.kind { units += Double(n) * ResourceCatalog.info(type).fuelValue }
        }
        let cheapest = WorldCatalog.routes(from: station)
            .filter { !$0.requirements.contains(.futureContent) }
            .map { TrainStats.baseFuelPerDistance * $0.distance }
            .min() ?? 0
        #expect(units >= cheapest, "\(station): renewable fuel \(units) < cheapest route \(cheapest)")
    }

    @Test func atLeastThreeOptionalSecrets() {
        var secrets = Set<SecretID>()
        for station in Self.explorable {
            let layout = WorldCatalog.layout(station)!
            for obj in layout.objects { if let s = obj.secret { secrets.insert(s) } }
            for z in layout.zones { if case .secret(let s) = z.kind { secrets.insert(s) } }
        }
        #expect(secrets == Set(SecretID.allCases))
        #expect(secrets.count >= 3)
    }

    @Test func blueprintsExistForEveryBlueprintRecipe() {
        var found = Set<RecipeID>()
        for station in Self.explorable {
            for obj in WorldCatalog.layout(station)!.objects {
                if case .blueprint(let r, _) = obj.kind { found.insert(r) }
            }
        }
        let needed = Set(RecipeCatalog.all.filter(\.needsBlueprint).map(\.id))
        #expect(needed.isSubset(of: found), "Missing blueprints: \(needed.subtracting(found))")
    }

    @Test func worldGraphIsConsistent() {
        #expect(Set(WorldCatalog.routes.map(\.id)) == Set(RouteID.allCases))
        #expect(Set(WorldCatalog.stations.map(\.id)) == Set(StationID.allCases))
        for r in WorldCatalog.routes { #expect(r.a != r.b && r.distance > 0) }
    }

    @Test func journalEntriesHaveText() {
        for id in JournalID.allCases {
            let e = JournalCatalog.entry(id)
            #expect(!e.title.isEmpty && e.text.count > 20)
        }
    }
}
