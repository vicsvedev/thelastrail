import SwiftUI

struct MapPanel: View {
    @Environment(GameController.self) private var game
    @State private var selected: StationID?
    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero

    var body: some View {
        let s = game.state
        PhonePanel(title: "Järnvägskarta", close: { game.close() }) {
            HStack(alignment: .top, spacing: 8) {
                GeometryReader { geo in
                    let size = geo.size
                    ZStack(alignment: .topLeading) {
                        MapCanvas(state: s, selected: selected)
                            .frame(width: size.width, height: size.height)
                        ForEach(WorldCatalog.stations, id: \.id) { st in
                            // Hide tap targets that are zoomed/panned outside the visible map:
                            // clipping does not stop SwiftUI hit-testing.
                            if s.discoveredStations.contains(st.id), isVisible(st, size) {
                                Button {
                                    selected = st.id
                                    Haptics.tap()
                                    game.sound.play(.menuMove)
                                } label: {
                                    Color.clear.frame(width: 48 / scale, height: 48 / scale).contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(st.id == .polaris ? "Okänd station" : st.name)
                                .position(x: st.mapX * size.width, y: st.mapY * size.height)
                            }
                        }
                    }
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(scale)
                    .offset(offset)
                    .contentShape(Rectangle())
                    .gesture(
                        MagnifyGesture()
                            .onChanged { v in scale = min(3, max(1, baseScale * v.magnification)); clamp(size) }
                            .onEnded { _ in baseScale = scale; baseOffset = offset }
                            .simultaneously(with: DragGesture(minimumDistance: 8)
                                .onChanged { v in
                                    offset = CGSize(width: baseOffset.width + v.translation.width, height: baseOffset.height + v.translation.height)
                                    clamp(size)
                                }
                                .onEnded { _ in baseOffset = offset })
                    )
                    .clipped()
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: 10) {
                            legend(Theme.amber, "Öppen")
                            legend(Theme.red, "Låst")
                            legend(Theme.green, "Du är här")
                            Spacer()
                            if scale > 1.01 {
                                Button("Återställ") { withAnimation { scale = 1; baseScale = 1; offset = .zero; baseOffset = .zero } }
                                    .buttonStyle(RetroButtonStyle(compact: true))
                            }
                        }
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                    }
                }
                .overlay(Rectangle().strokeBorder(Theme.border, lineWidth: 2))
                StationInfoView(station: selected ?? s.currentStation)
                    .frame(width: 270)
            }
        }
        .onAppear { if selected == nil { selected = suggestedStation(s) } }
    }

    private func isVisible(_ st: StationInfo, _ size: CGSize) -> Bool {
        let x = size.width / 2 + (st.mapX * size.width - size.width / 2) * scale + offset.width
        let y = size.height / 2 + (st.mapY * size.height - size.height / 2) * scale + offset.height
        return x >= 12 && x <= size.width - 12 && y >= 12 && y <= size.height - 12
    }

    private func clamp(_ size: CGSize) {
        let maxX = size.width * (scale - 1) / 2, maxY = size.height * (scale - 1) / 2
        offset = CGSize(width: min(maxX, max(-maxX, offset.width)), height: min(maxY, max(-maxY, offset.height)))
    }

    private func suggestedStation(_ s: GameState) -> StationID {
        if s.tutorial.isActive && s.tutorial.step <= .firstJourney && s.currentStation == .depot { return .tallkorset }
        return s.currentStation
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 4) {
            Rectangle().fill(color).frame(width: 14, height: 3)
            Text(text).font(Theme.body(10)).foregroundStyle(Theme.cream)
        }
    }
}

/// Draws terrain, tracks, stations and fog of war.
struct MapCanvas: View {
    let state: GameState
    let selected: StationID?

    var body: some View {
        Canvas { ctx, size in
            func pt(_ st: StationInfo) -> CGPoint { CGPoint(x: st.mapX * size.width, y: st.mapY * size.height) }
            // Parchment-like dark terrain
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x1E2A26)))
            var rng = SeededRandom(seed: 2147)
            for _ in 0..<160 {
                let x = Double(rng.int(0...Int(size.width))), y = Double(rng.int(0...Int(size.height)))
                let r = Double(rng.int(2...6))
                let color: UInt32 = y < size.height * 0.3 ? 0x3A4A58 : (x > size.width * 0.55 && y < size.height * 0.5 ? 0x4A4440 : 0x26402E)
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 1.4)), with: .color(Color(hex: color, alpha: 0.6)))
            }
            // Mountains in the north
            for i in 0..<14 {
                let x = Double(i) * size.width / 13
                let base = size.height * 0.16 + Double((i * 37) % 23)
                var p = Path()
                p.move(to: CGPoint(x: x - 22, y: base + 20))
                p.addLine(to: CGPoint(x: x, y: base - 14))
                p.addLine(to: CGPoint(x: x + 22, y: base + 20))
                ctx.fill(p, with: .color(Color(hex: 0x5A6478, alpha: 0.7)))
                var cap = Path()
                cap.move(to: CGPoint(x: x - 6, y: base - 4)); cap.addLine(to: CGPoint(x: x, y: base - 14)); cap.addLine(to: CGPoint(x: x + 6, y: base - 4))
                ctx.fill(cap, with: .color(Color(hex: 0xD8E0EA, alpha: 0.8)))
            }
            // Tracks
            for route in WorldCatalog.routes {
                guard TravelSystem.isRevealed(route, state) else { continue }
                let a = WorldCatalog.station(route.a), b = WorldCatalog.station(route.b)
                let knownA = state.discoveredStations.contains(route.a), knownB = state.discoveredStations.contains(route.b)
                guard knownA || knownB else { continue }
                var path = Path()
                path.move(to: pt(a)); path.addLine(to: pt(b))
                let unlocked = TravelSystem.isUnlocked(route, state) && state.train.locomotiveRepaired
                ctx.stroke(path, with: .color(.black.opacity(0.6)), style: StrokeStyle(lineWidth: 7))
                if unlocked {
                    ctx.stroke(path, with: .color(Theme.amber), style: StrokeStyle(lineWidth: 3))
                    ctx.stroke(path, with: .color(Color(hex: 0x4A3424)), style: StrokeStyle(lineWidth: 5, dash: [2, 6]))
                } else {
                    ctx.stroke(path, with: .color(Theme.red.opacity(0.85)), style: StrokeStyle(lineWidth: 2.5, dash: [6, 5]))
                }
                // Distance label
                // Label at the middle of the track, pushed sideways so it never sits on a station name.
                let pa = pt(a), pb = pt(b)
                let mid = CGPoint(x: pa.x + (pb.x - pa.x) * 0.42, y: pa.y + (pb.y - pa.y) * 0.42)
                let len = max(1, hypot(pb.x - pa.x, pb.y - pa.y))
                var nx = -(pb.y - pa.y) / len, ny = (pb.x - pa.x) / len
                if ny > 0 { nx = -nx; ny = -ny }   // always above the line
                ctx.draw(Text(Format.km(route.distance)).font(Theme.font(10)).foregroundColor(Theme.cream.opacity(0.8)),
                         at: CGPoint(x: mid.x + nx * 16, y: mid.y + ny * 16))
            }
            // Fog of war: cover everything, then clear around discovered stations.
            ctx.drawLayer { layer in
                layer.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x0E1014, alpha: 0.92)))
                layer.blendMode = .destinationOut
                for st in WorldCatalog.stations where state.discoveredStations.contains(st.id) {
                    let r: CGFloat = state.visitedStations.contains(st.id) ? 120 : 70
                    let c = pt(st)
                    layer.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r * 0.8, width: r * 2, height: r * 1.6)),
                               with: .radialGradient(Gradient(colors: [.black, .black, .black.opacity(0)]), center: c, startRadius: 0, endRadius: r))
                }
            }
            // Stations
            for st in WorldCatalog.stations where state.discoveredStations.contains(st.id) {
                let c = pt(st)
                let here = st.id == state.currentStation && state.journey == nil
                let visited = state.visitedStations.contains(st.id)
                let r: CGFloat = 9
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r - 2, y: c.y - r - 2, width: (r + 2) * 2, height: (r + 2) * 2)), with: .color(.black))
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                         with: .color(here ? Theme.green : (visited ? Theme.amberLight : Theme.dim)))
                if selected == st.id {
                    ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r - 6, y: c.y - r - 6, width: (r + 6) * 2, height: (r + 6) * 2)),
                               with: .color(Theme.cream), lineWidth: 2)
                }
                let name = visited || st.id != .polaris ? (visited ? st.name : st.name + " ?") : "???"
                ctx.draw(Text(name).font(Theme.font(11)).foregroundColor(Theme.cream), at: CGPoint(x: c.x, y: c.y + 22))
            }
            // The train during a journey
            if let j = state.journey {
                let a = pt(WorldCatalog.station(j.from)), b = pt(WorldCatalog.station(j.to))
                let p = CGPoint(x: a.x + (b.x - a.x) * j.progress, y: a.y + (b.y - a.y) * j.progress)
                ctx.fill(Path(CGRect(x: p.x - 6, y: p.y - 4, width: 12, height: 8)), with: .color(Theme.green))
            }
            // Compass
            ctx.draw(Text("N ↑").font(Theme.font(14)).foregroundColor(Theme.cream.opacity(0.7)), at: CGPoint(x: size.width - 30, y: 20))
        }
    }
}

struct StationInfoView: View {
    @Environment(GameController.self) private var game
    let station: StationID

    var body: some View {
        let s = game.state
        let info = WorldCatalog.station(station)
        let visited = s.visitedStations.contains(station)
        VStack(alignment: .leading, spacing: 6) {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text(visited || station != .polaris ? info.name : "???").font(Theme.font(18)).foregroundStyle(Theme.amberLight)
                    Text(info.region.displayName).font(Theme.body(11)).foregroundStyle(Theme.dim)
                    Text(info.description).font(Theme.body(12)).foregroundStyle(Theme.cream).fixedSize(horizontal: false, vertical: true)
                    if !info.specialties.isEmpty {
                        HStack(spacing: 6) {
                            Text("Resurser:").font(Theme.body(11)).foregroundStyle(Theme.dim)
                            ForEach(info.specialties) { PixelIcon(image: IconSprites.resource($0), size: 20) }
                        }
                    }
                    if visited {
                        let secrets = secretsAt(station, s)
                        if secrets.total > 0 {
                            Text("Hemligheter: \(secrets.found)/\(secrets.total)").font(Theme.body(11)).foregroundStyle(Theme.dim)
                        }
                    }
                    Divider().background(Theme.border)
                    routeDetails(s)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            travelButtons(s)
        }
        .padding(8)
        .background(Theme.panelLight.opacity(0.6))
    }

    private func secretsAt(_ station: StationID, _ s: GameState) -> (found: Int, total: Int) {
        let map: [SecretID: StationID] = [.depotStash: .depot, .tallkorsetCache: .tallkorset, .rosthamnCodeRoom: .rosthamn,
                                          .djupgruvanSidePassage: .djupgruvan, .nordpassetCairn: .nordpasset]
        let here = map.filter { $0.value == station }.map(\.key)
        return (here.filter { s.discoveredSecrets.contains($0) }.count, here.count)
    }

    @ViewBuilder
    private func routeDetails(_ s: GameState) -> some View {
        if let j = s.journey {
            Text("Tåget är på väg mot \(WorldCatalog.station(j.to).name).").font(Theme.body(12)).foregroundStyle(Theme.amber)
        } else if station == s.currentStation {
            Label("Du är här", systemImage: "mappin.circle.fill").font(Theme.body(13)).foregroundStyle(Theme.green)
            let outgoing = WorldCatalog.routes(from: station).filter { TravelSystem.isRevealed($0, s) }
            ForEach(outgoing, id: \.id) { r in
                let other = WorldCatalog.station(r.other(than: station)!)
                let open = TravelSystem.isUnlocked(r, s)
                Text("\(open ? "→" : "✗") \(s.discoveredStations.contains(other.id) ? other.name : "???")  \(Format.km(r.distance))")
                    .font(Theme.body(12)).foregroundStyle(open ? Theme.cream : Theme.red)
            }
        } else if let route = WorldCatalog.route(between: s.currentStation, station), TravelSystem.isRevealed(route, s) {
            let stats = game.stats
            let cost = stats.fuelCost(distance: route.distance)
            infoLine("Avstånd", Format.km(route.distance))
            infoLine("Bränsle", "≈ \(Format.fuel(cost)) (tank \(Format.fuel(s.train.fuel))/\(Format.fuel(stats.fuelCapacity)))",
                     color: cost > s.train.fuel ? Theme.red : Theme.cream)
            infoLine("Restid", "≈ \(Format.seconds(stats.travelDuration(distance: route.distance)))")
            if case .failure(let block) = TravelSystem.plan(to: station, s) {
                Text(block.message).font(Theme.body(12)).foregroundStyle(Theme.red).fixedSize(horizontal: false, vertical: true)
            }
        } else {
            Text("Ingen direkt förbindelse härifrån.").font(Theme.body(12)).foregroundStyle(Theme.dim)
        }
    }

    /// Always visible below the scrolling details.
    @ViewBuilder
    private func travelButtons(_ s: GameState) -> some View {
        if s.journey == nil, station != s.currentStation,
           let route = WorldCatalog.route(between: s.currentStation, station), TravelSystem.isRevealed(route, s) {
            switch TravelSystem.plan(to: station, s) {
            case .success:
                Button { game.travel(to: station) } label: { Label("Res hit", systemImage: "tram.fill").frame(maxWidth: .infinity) }
                    .buttonStyle(RetroButtonStyle(accent: Theme.green))
                    .tutorialPulse(s.tutorial.isActive)
            case .failure(let block):
                if case .insufficientFuel(let need, _) = block {
                    if InventorySystem.canRefuel(to: need, s) {
                        Button { game.refuelAndTravel(to: station) } label: { Label("Tanka och res", systemImage: "fuelpump.fill").frame(maxWidth: .infinity) }
                            .buttonStyle(RetroButtonStyle(accent: Theme.green))
                    } else if TravelSystem.emergencyPlan(to: station, s) != nil {
                        Button { game.emergencyTravel(to: station) } label: { Label("Nödkörning (−20 % skick)", systemImage: "exclamationmark.triangle.fill").frame(maxWidth: .infinity) }
                            .buttonStyle(RetroButtonStyle(accent: Theme.red))
                    } else {
                        Button { game.close(.map); game.open(.locomotive) } label: { Label("Till loket", systemImage: "fuelpump").frame(maxWidth: .infinity) }
                            .buttonStyle(RetroButtonStyle())
                    }
                } else if block == .notOnTrain {
                    Text("Gå ombord på tåget för att resa.").font(Theme.body(12)).foregroundStyle(Theme.amber)
                }
            }
        }
    }

    private func infoLine(_ label: String, _ value: String, color: Color = Theme.cream) -> some View {
        HStack(alignment: .top) {
            Text(label).font(Theme.body(12)).foregroundStyle(Theme.dim).frame(width: 60, alignment: .leading)
            Text(value).font(Theme.body(12)).foregroundStyle(color).fixedSize(horizontal: false, vertical: true)
        }
    }
}
