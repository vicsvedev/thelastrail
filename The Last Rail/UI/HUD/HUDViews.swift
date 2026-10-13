import SwiftUI

/// What the tutorial wants the player to touch right now (drives the pulsing hints).
enum TutorialFocus: Equatable {
    case none, joystick, action, mapButton, trainMap, trainDisembark, trainBuild
}

extension GameController {
    var tutorialFocus: TutorialFocus {
        let t = state.tutorial
        guard t.isActive, dialogs.isEmpty, overlays.isEmpty else { return .none }
        switch (t.step, screen) {
        case (.wakeUp, .exploration): return .joystick
        case (.investigateLocomotive, .exploration), (.collectScrap, .exploration),
             (.findFuel, .exploration), (.repairLocomotive, .exploration):
            return prompt != nil ? .action : .none
        case (.radioSignal, .exploration): return .mapButton
        case (.radioSignal, .train), (.firstJourney, .train): return .trainMap
        case (.firstJourney, .exploration): return prompt != nil ? .action : .none
        case (.firstExpedition, .train): return state.tutorial.leftTrainAtTallkorset ? .none : .trainDisembark
        case (.firstExpedition, .exploration): return prompt != nil ? .action : .none
        case (.firstUpgrade, .train): return .trainBuild
        case (.firstUpgrade, .exploration): return prompt != nil ? .action : .none
        default: return .none
        }
    }
}

/// Compact tutorial / goal tracker. Tap to collapse so it never hides the world.
struct ObjectiveTracker: View {
    @Environment(GameController.self) private var game
    @State private var collapsed = false

    var body: some View {
        let s = game.state
        VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(s.tutorial.isActive ? "KAPITEL 1  \(s.tutorial.step.rawValue)/10" : "MÅL")
                        .font(Theme.font(10)).foregroundStyle(Theme.amber)
                    Spacer(minLength: 0)
                    Image(systemName: collapsed ? "chevron.down" : "chevron.up").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.dim)
                }
                Text(s.tutorial.isActive ? TutorialSystem.objective(s.tutorial.step) : ProgressionSystem.currentGoal(s))
                    .font(Theme.body(12)).foregroundStyle(Theme.cream)
                    .lineLimit(collapsed ? 1 : 4)
                    .fixedSize(horizontal: false, vertical: true)
                if !collapsed && s.tutorial.isActive {
                    ForEach(TutorialSystem.subObjectives(s.tutorial.step, s)) { line in
                        HStack(spacing: 5) {
                            Image(systemName: line.done ? "checkmark.square.fill" : "square").font(.system(size: 10))
                            Text(line.text).font(Theme.body(11)).lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(line.done ? Theme.green : Theme.cream)
                    }
                    if game.settings.showHints, let hint = TutorialSystem.hint(s.tutorial.step, s) {
                        Text(hint).font(Theme.body(10)).foregroundStyle(Theme.dim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        .padding(8)
        .frame(width: 236, alignment: .leading)
        .background(Color.black.opacity(0.55))
        .overlay(Rectangle().strokeBorder(Theme.border.opacity(0.8), lineWidth: 1.5))
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { collapsed.toggle() } }
    }
}

struct ExplorationHUD: View {
    @Environment(GameController.self) private var game

    var body: some View {
        let focus = game.tutorialFocus
        ZStack {
            // Joystick, sprint and action (multi-touch UIKit layer).
            TouchControls(game: game, actionAvailable: game.prompt != nil)

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    StatusCard()
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 6) {
                            IconButton(symbol: "backpack.fill", label: "Ryggsäck") { game.open(.inventory) }
                            IconButton(symbol: "map.fill", label: "Karta", enabled: game.isMapAvailable, highlighted: focus == .mapButton) { game.open(.map) }
                            IconButton(symbol: "book.closed.fill", label: "Journal") { game.open(.journal) }
                            IconButton(symbol: "pause.fill", a11y: "Paus") { game.open(.pause) }
                        }
                        ObjectiveTracker()
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)

            // Contextual prompt right above the action button.
            if let prompt = game.prompt, game.dialogs.isEmpty, game.overlays.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(prompt)
                            .font(Theme.font(13)).foregroundStyle(Theme.cream)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.black.opacity(0.7))
                            .overlay(Rectangle().strokeBorder(Theme.amber.opacity(0.8), lineWidth: 1.5))
                            .frame(maxWidth: 260, alignment: .trailing)
                    }
                    .padding(.trailing, 14)
                    .padding(.bottom, 118)
                }
                .allowsHitTesting(false)
            }

            ExplorationTutorialHints(focus: focus)
                .allowsHitTesting(false)
        }
    }
}

/// Health, backpack and carried resources in a small card (top left).
struct StatusCard: View {
    @Environment(GameController.self) private var game

    var body: some View {
        let s = game.state
        VStack(alignment: .leading, spacing: 4) {
            Text(game.currentStationInfo.name.uppercased())
                .font(Theme.font(12)).foregroundStyle(Theme.amberLight).lineLimit(1)
            HStack(spacing: 5) {
                Image(systemName: "heart.fill").font(.system(size: 11)).foregroundStyle(Theme.red)
                Bar(value: s.health, max: GameState.maxHealth, color: s.health < 30 ? Theme.red : Color(hex: 0xC05050), height: 9)
                    .frame(width: 96)
                Text("\(Int(s.health.rounded()))").font(Theme.font(11)).foregroundStyle(Theme.cream)
            }
            HStack(spacing: 5) {
                Image(systemName: "backpack.fill").font(.system(size: 10)).foregroundStyle(Theme.amber)
                Bar(value: Double(s.inventory.backpackUsed), max: Double(game.stats.backpackCapacity), color: Theme.amber, height: 7)
                    .frame(width: 96)
                Text("\(s.inventory.backpackUsed)/\(game.stats.backpackCapacity)").font(Theme.font(10)).foregroundStyle(Theme.cream)
            }
            QuickInventory()
        }
        .padding(7)
        .background(Color.black.opacity(0.5))
        .overlay(Rectangle().strokeBorder(Theme.border.opacity(0.8), lineWidth: 1.5))
        .allowsHitTesting(false)
    }
}

struct QuickInventory: View {
    @Environment(GameController.self) private var game

    var body: some View {
        let inv = game.state.inventory
        let carried = ResourceType.allCases.filter { inv.backpackCount($0) > 0 }
        if !carried.isEmpty {
            HStack(spacing: 6) {
                ForEach(carried.prefix(5)) { type in
                    HStack(spacing: 1) {
                        PixelIcon(image: IconSprites.resource(type), size: 16)
                        Text("\(inv.backpackCount(type))").font(Theme.font(10)).foregroundStyle(Theme.cream)
                    }
                }
            }
        }
    }
}

/// Visual coaching for the touch controls during the tutorial.
struct ExplorationTutorialHints: View {
    let focus: TutorialFocus
    @State private var phase = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                if focus == .joystick {
                    let home = ControlLayout.joystickHome(in: size)
                    Circle()
                        .fill(Theme.amberLight.opacity(0.85))
                        .frame(width: 26, height: 26)
                        .position(x: home.x + (phase ? 34 : -10), y: home.y - (phase ? 10 : 0))
                    HintLabel(text: "Dra med tummen här för att gå")
                        .position(x: home.x + 70, y: home.y - ControlLayout.joystickRadius - 26)
                }
                if focus == .action {
                    let c = ControlLayout.actionCenter(in: size)
                    Circle()
                        .strokeBorder(Theme.amberLight, lineWidth: 4)
                        .frame(width: ControlLayout.actionRadius * 2 + 16, height: ControlLayout.actionRadius * 2 + 16)
                        .scaleEffect(phase ? 1.15 : 0.95)
                        .opacity(phase ? 0.3 : 1)
                        .position(c)
                    HintLabel(text: "Tryck här")
                        .position(x: c.x - 96, y: c.y + 8)
                }
            }
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: phase)
            .onAppear { phase = true }
        }
    }
}

struct HintLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Theme.font(12)).foregroundStyle(Theme.night)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Theme.amberLight)
            .fixedSize()
    }
}

// MARK: - Train

struct TrainHUD: View {
    @Environment(GameController.self) private var game

    var body: some View {
        let s = game.state
        let traveling = s.journey != nil
        VStack(spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                TrainStatusCard()
                Spacer(minLength: 6)
                if traveling { TravelPanel() }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 6) {
                    IconButton(symbol: "pause.fill", a11y: "Paus") { game.open(.pause) }
                    ObjectiveTracker()
                }
            }
            Spacer()
            if s.tutorial.isActive && !traveling && game.overlays.isEmpty {
                Text("Svep för att se hela tåget • Nyp för att zooma • Tryck på en vagn")
                    .font(Theme.body(11)).foregroundStyle(Theme.cream.opacity(0.85))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.black.opacity(0.5))
                    .allowsHitTesting(false)
            }
            TrainActionBar()
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
}

struct TrainStatusCard: View {
    @Environment(GameController.self) private var game

    var body: some View {
        let s = game.state
        let stats = game.stats
        VStack(alignment: .leading, spacing: 4) {
            if let j = s.journey {
                Text("PÅ VÄG").font(Theme.font(10)).foregroundStyle(Theme.amber)
                Text("\(WorldCatalog.station(j.from).name) → \(WorldCatalog.station(j.to).name)")
                    .font(Theme.font(12)).foregroundStyle(Theme.amberLight).lineLimit(1).minimumScaleFactor(0.7)
            } else {
                Text(game.currentStationInfo.name.uppercased()).font(Theme.font(13)).foregroundStyle(Theme.amberLight)
                Text(game.currentStationInfo.region.displayName).font(Theme.body(10)).foregroundStyle(Theme.dim)
            }
            StatLine(symbol: "fuelpump.fill", value: "\(Format.fuel(s.train.fuel))/\(Format.fuel(stats.fuelCapacity))",
                     bar: (s.train.fuel, stats.fuelCapacity), color: Theme.amber)
            StatLine(symbol: "shippingbox.fill", value: "\(s.inventory.storageUsed)/\(stats.storageCapacity)",
                     bar: (Double(s.inventory.storageUsed), Double(stats.storageCapacity)), color: Theme.blue)
            StatLine(symbol: "wrench.adjustable.fill", value: "\(Int(s.train.condition))%",
                     bar: (s.train.condition, 100), color: s.train.condition < 50 ? Theme.red : Theme.green)
            Text("Vikt \(Int(stats.totalWeight))/\(Int(stats.pullCapacity)) t").font(Theme.font(10))
                .foregroundStyle(stats.weightFactor > 1 ? Theme.red : Theme.dim)
        }
        .padding(7)
        .frame(width: 200, alignment: .leading)
        .background(Color.black.opacity(0.55))
        .overlay(Rectangle().strokeBorder(Theme.border.opacity(0.8), lineWidth: 1.5))
        .allowsHitTesting(false)
    }
}

struct StatLine: View {
    let symbol: String
    let value: String
    let bar: (Double, Double)
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 11)).foregroundStyle(color).frame(width: 16)
            Bar(value: bar.0, max: bar.1, color: color, height: 8).frame(width: 90)
            Text(value).font(Theme.font(11)).foregroundStyle(Theme.cream).lineLimit(1)
        }
    }
}

struct TravelPanel: View {
    @Environment(GameController.self) private var game

    var body: some View {
        if let j = game.state.journey {
            let route = WorldCatalog.route(j.routeID)
            VStack(spacing: 5) {
                HStack {
                    Text("Mot \(WorldCatalog.station(j.to).name)").font(Theme.font(12)).foregroundStyle(Theme.cream)
                    Spacer()
                    Text(route.region.displayName).font(Theme.body(10)).foregroundStyle(Theme.dim)
                }
                Bar(value: j.progress, max: 1, color: Theme.amber, height: 9)
                HStack {
                    Text("Kvar \(Format.km(route.distance * (1 - j.progress)))").font(Theme.font(10)).foregroundStyle(Theme.cream)
                    Spacer()
                    Text("Bränsle \(Format.fuel(j.fuelConsumed))/\(Format.fuel(j.fuelCost))").font(Theme.font(10)).foregroundStyle(Theme.dim)
                }
                if game.canFastForward {
                    HStack(spacing: 6) {
                        Button(game.travelSpeed > 1 ? "Normal fart" : "Snabbspola ×4") { game.toggleFastForward() }
                            .buttonStyle(RetroButtonStyle(compact: true))
                        Button("Hoppa över") { game.skipJourney() }
                            .buttonStyle(RetroButtonStyle(compact: true))
                    }
                } else {
                    Text("Första resan här – njut av utsikten.").font(Theme.body(10)).foregroundStyle(Theme.dim)
                }
            }
            .padding(8)
            .frame(maxWidth: 280)
            .background(Color.black.opacity(0.6))
            .overlay(Rectangle().strokeBorder(Theme.amber.opacity(0.6), lineWidth: 1.5))
        }
    }
}

struct TrainActionBar: View {
    @Environment(GameController.self) private var game

    var body: some View {
        let traveling = game.state.journey != nil
        let focus = game.tutorialFocus
        HStack(spacing: 6) {
            IconButton(symbol: "map.fill", label: "Karta", highlighted: focus == .trainMap) { game.open(.map) }
            IconButton(symbol: "shippingbox.fill", label: "Lager") { game.open(.inventory) }
            IconButton(symbol: "hammer.fill", label: "Bygg", highlighted: focus == .trainBuild) { game.open(.crafting) }
            IconButton(symbol: "tram.fill", label: "Vagnar") { game.open(.wagons) }
            IconButton(symbol: "fuelpump.fill", label: "Loket") { game.open(.locomotive) }
            IconButton(symbol: "book.closed.fill", label: "Journal") { game.open(.journal) }
            if !traveling {
                IconButton(symbol: "figure.walk.departure", label: "Kliv av", highlighted: focus == .trainDisembark) { game.disembark() }
            }
        }
    }
}
