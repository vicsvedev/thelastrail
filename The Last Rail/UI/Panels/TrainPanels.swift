import SwiftUI

struct InventoryPanel: View {
    @Environment(GameController.self) private var game

    var body: some View {
        let s = game.state
        let stats = game.stats
        PhonePanel(title: s.location == .onTrain ? "Lager" : "Ryggsäck", close: { game.close() }) {
            HStack(alignment: .top, spacing: 10) {
                container("Ryggsäck", used: s.inventory.backpackUsed, cap: stats.backpackCapacity) { s.inventory.backpackCount($0) }
                container("Tågets lager", used: s.inventory.storageUsed, cap: stats.storageCapacity) { s.inventory.storageCount($0) }
                VStack(alignment: .leading, spacing: 6) {
                    Text("HÄLSA \(Int(s.health))/100").font(Theme.font(12)).foregroundStyle(Theme.amber)
                    Button { game.eat() } label: { Label("Ät mat (\(s.inventory.total(.food)))", systemImage: "fork.knife") }
                        .buttonStyle(RetroButtonStyle(accent: Theme.green, enabled: s.inventory.total(.food) > 0))
                    Text("VERKTYG").font(Theme.font(12)).foregroundStyle(Theme.amber).padding(.top, 4)
                    let items = ItemType.allCases.filter { s.inventory.itemCount($0) > 0 }
                    if items.isEmpty {
                        Text("Inga verktyg ännu. Bygg dem i verkstaden.").font(Theme.body(12)).foregroundStyle(Theme.dim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(items) { item in
                        HStack(spacing: 6) {
                            PixelIcon(image: IconSprites.item(item), size: 24)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(ItemCatalog.name(item) + (s.inventory.itemCount(item) > 1 ? " ×\(s.inventory.itemCount(item))" : ""))
                                    .font(Theme.body(13)).foregroundStyle(Theme.cream)
                                Text(ItemCatalog.info(item).description).font(Theme.body(10)).foregroundStyle(Theme.dim).lineLimit(2)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    if s.location == .exploring {
                        Text("Gå ombord på tåget för att lasta av ryggsäcken.").font(Theme.body(11)).foregroundStyle(Theme.dim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func container(_ title: String, used: Int, cap: Int, count: @escaping (ResourceType) -> Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title.uppercased()).font(Theme.font(12)).foregroundStyle(Theme.amber)
                Spacer()
                Text("\(used)/\(cap)").font(Theme.font(12)).foregroundStyle(used >= cap ? Theme.red : Theme.cream)
            }
            Bar(value: Double(used), max: Double(cap), color: Theme.amber, height: 6)
            ForEach(ResourceType.allCases) { type in
                HStack(spacing: 6) {
                    PixelIcon(image: IconSprites.resource(type), size: 22)
                    Text(ResourceCatalog.name(type)).font(Theme.body(13))
                        .foregroundStyle(count(type) > 0 ? Theme.cream : Theme.dim)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Spacer()
                    Text("\(count(type))").font(Theme.font(14)).foregroundStyle(count(type) > 0 ? Theme.amberLight : Theme.dim)
                }
                .frame(height: 25)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct CraftingPanel: View {
    @Environment(GameController.self) private var game
    @State private var selected: RecipeID?

    var body: some View {
        let s = game.state
        let recipes = CraftingSystem.visibleRecipes(s)
        let onTrain = s.location == .onTrain
        PhonePanel(title: "Bygg & tillverka", close: { game.close() }) {
            HStack(alignment: .top, spacing: 10) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(RecipeCategory.allCases, id: \.self) { cat in
                            let list = recipes.filter { $0.category == cat }
                            if !list.isEmpty {
                                Text(cat.rawValue.uppercased()).font(Theme.font(10)).foregroundStyle(Theme.amber).padding(.top, 4)
                                ForEach(list) { r in row(r, s) }
                            }
                        }
                        let unknown = RecipeCatalog.all.filter { !CraftingSystem.isKnown($0, s) }.count
                        if unknown > 0 {
                            Text("\(unknown) ritningar återstår att hitta…").font(Theme.body(11)).foregroundStyle(Theme.dim).padding(.top, 6)
                        }
                    }
                }
                .frame(width: 250)
                detail(recipes.first { $0.id == selected } ?? recipes.first, s, onTrain: onTrain)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .onAppear {
            if selected == nil {
                selected = s.tutorial.step == .firstUpgrade ? .workshop : recipes.first { CraftingSystem.status($0, s) == .available }?.id
            }
        }
    }

    private func row(_ r: Recipe, _ s: GameState) -> some View {
        let status = CraftingSystem.status(r, s)
        let color: Color
        let mark: String
        switch status {
        case .available: color = Theme.green; mark = "circle.fill"
        case .missingResources: color = Theme.amber; mark = "circle"
        case .alreadyBuilt: color = Theme.dim; mark = "checkmark"
        case .locked, .unknown: color = Theme.red; mark = "lock.fill"
        }
        return Button {
            selected = r.id
            Haptics.tap()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: mark).font(.system(size: 11, weight: .bold)).foregroundStyle(color).frame(width: 16)
                Text(r.name).font(Theme.body(14)).foregroundStyle(status == .alreadyBuilt ? Theme.dim : Theme.cream)
                    .lineLimit(1).minimumScaleFactor(0.75)
                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(height: 40)
            .background(selected == r.id ? Theme.amber.opacity(0.2) : Theme.panelLight.opacity(0.4))
            .overlay(Rectangle().strokeBorder(selected == r.id ? Theme.amber.opacity(0.8) : .clear, lineWidth: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func detail(_ recipe: Recipe?, _ s: GameState, onTrain: Bool) -> some View {
        if let r = recipe {
            let status = CraftingSystem.status(r, s)
            VStack(alignment: .leading, spacing: 8) {
                Text(r.name).font(Theme.font(18)).foregroundStyle(Theme.amberLight).lineLimit(1).minimumScaleFactor(0.7)
                Text(r.description).font(Theme.body(13)).foregroundStyle(Theme.cream).fixedSize(horizontal: false, vertical: true)
                CostRow(cost: r.cost, state: s)
                Group {
                    switch status {
                    case .locked(let reasons):
                        ForEach(reasons, id: \.self) { Label($0, systemImage: "lock.fill").font(Theme.body(12)).foregroundStyle(Theme.red) }
                    case .missingResources(let missing):
                        Text("Saknas: " + missing.sorted { $0.key.rawValue < $1.key.rawValue }.map { "\($0.value) \(ResourceCatalog.name($0.key).lowercased())" }.joined(separator: ", "))
                            .font(Theme.body(12)).foregroundStyle(Theme.amber)
                    case .alreadyBuilt:
                        Label("Redan byggd", systemImage: "checkmark.seal.fill").font(Theme.body(12)).foregroundStyle(Theme.green)
                    default:
                        if r.oneTime { Text("Engångsbygge").font(Theme.body(11)).foregroundStyle(Theme.dim) }
                    }
                }
                if case .addWagon(let type) = r.effect {
                    let stats = game.stats
                    let newWeight = stats.totalWeight + WagonCatalog.info(type).weight
                    Text("Tågets vikt blir \(Int(newWeight)) t av \(Int(stats.pullCapacity)) t dragkraft.")
                        .font(Theme.body(11)).foregroundStyle(newWeight > stats.pullCapacity ? Theme.red : Theme.dim)
                }
                Spacer(minLength: 4)
                if !onTrain {
                    Text("Du kan bara bygga ombord på tåget.").font(Theme.body(12)).foregroundStyle(Theme.red)
                }
                Button { game.craft(r.id) } label: {
                    Label(r.category == .tools ? "Tillverka" : "Bygg", systemImage: "hammer.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(RetroButtonStyle(accent: Theme.green, enabled: status == .available && onTrain))
                .disabled(status != .available || !onTrain)
                .tutorialPulse(game.state.tutorial.step == .firstUpgrade && r.id == .workshop && status == .available)
            }
            .padding(10)
            .background(Theme.panelLight.opacity(0.6))
        } else {
            Text("Inga konstruktioner kända ännu. Leta efter ritningar.").font(Theme.body(13)).foregroundStyle(Theme.dim)
        }
    }
}

struct WagonPanel: View {
    @Environment(GameController.self) private var game

    var body: some View {
        let s = game.state
        let stats = game.stats
        PhonePanel(title: "Vagnar", close: { game.close() }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 18) {
                    stat("Dragkraft", "\(Int(stats.pullCapacity)) t")
                    stat("Vikt", "\(Int(stats.totalWeight)) t", warn: stats.weightFactor > 1)
                    stat("Lager", "\(stats.storageCapacity)")
                    stat("Förbrukning", "\(Format.fuel(stats.fuelPerDistance * 10 / 7))/10 km")
                    Spacer()
                }
                if stats.weightFactor > 1 {
                    Text("Tåget är tyngre än loket orkar dra – resor blir långsammare och dyrare.")
                        .font(Theme.body(11)).foregroundStyle(Theme.red)
                }
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(Array(s.train.wagons.enumerated()), id: \.element.id) { index, wagon in
                            wagonRow(index, wagon, count: s.train.wagons.count, locked: s.journey != nil)
                        }
                    }
                }
            }
        }
    }

    private func wagonRow(_ index: Int, _ wagon: Wagon, count: Int, locked: Bool) -> some View {
        let info = WagonCatalog.info(wagon.type)
        return HStack(spacing: 8) {
            Text("\(index + 1).").font(Theme.font(13)).foregroundStyle(Theme.dim)
            VStack(alignment: .leading, spacing: 1) {
                Text(info.name + (wagon.modules.contains(.workshopBench) ? " + verkstadsbänk" : ""))
                    .font(Theme.body(14)).foregroundStyle(Theme.cream)
                Text(wagonDetails(info)).font(Theme.body(11)).foregroundStyle(Theme.dim).lineLimit(1).minimumScaleFactor(0.8)
            }
            Spacer()
            if wagon.type == .living {
                Button("Vila") { game.rest() }.buttonStyle(RetroButtonStyle(compact: true))
            }
            Button { game.moveWagon(at: index, by: -1) } label: { Image(systemName: "arrow.left") }
                .buttonStyle(RetroButtonStyle(compact: true, enabled: index > 0 && !locked)).disabled(index == 0 || locked)
            Button { game.moveWagon(at: index, by: 1) } label: { Image(systemName: "arrow.right") }
                .buttonStyle(RetroButtonStyle(compact: true, enabled: index < count - 1 && !locked)).disabled(index == count - 1 || locked)
        }
        .padding(6)
        .background(Theme.panelLight.opacity(0.6))
    }

    private func wagonDetails(_ info: WagonInfo) -> String {
        var parts: [String] = ["\(Int(info.weight)) t"]
        if info.storageCapacity > 0 { parts.append("\(info.storageCapacity) platser") }
        parts.append(info.description)
        return parts.joined(separator: " • ")
    }

    private func stat(_ label: String, _ value: String, warn: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased()).font(Theme.font(10)).foregroundStyle(Theme.dim)
            Text(value).font(Theme.font(16)).foregroundStyle(warn ? Theme.red : Theme.amberLight)
        }
    }
}

struct LocomotivePanel: View {
    @Environment(GameController.self) private var game

    var body: some View {
        let s = game.state
        let stats = game.stats
        PhonePanel(title: "Loket", close: { game.close() }) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    line("Motor", s.train.engineLevel == 0 ? "Original" : "Nivå \(s.train.engineLevel)")
                    line("Dragkraft", "\(Int(stats.pullCapacity)) ton")
                    line("Tank", "\(Format.fuel(stats.fuelCapacity)) enheter")
                    line("Effektivitet", s.train.efficiencyLevel == 0 ? "Standard" : "−\(s.train.efficiencyLevel * 25) %")
                    line("Skick", "\(Int(s.train.condition)) %")
                    if stats.conditionFactor > 1 {
                        Text("Dåligt skick ökar förbrukningen. Bygg Enkel reparation.").font(Theme.body(11)).foregroundStyle(Theme.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    Button { game.listenToRadio() } label: {
                        Label(s.inventory.has(.signalDecoder) ? "Radio (avkodare)" : "Lyssna på radion", systemImage: "antenna.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RetroButtonStyle())
                }
                .frame(width: 230)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("TANKA").font(Theme.font(12)).foregroundStyle(Theme.amber)
                        Spacer()
                        Text("\(Format.fuel(s.train.fuel)) / \(Format.fuel(stats.fuelCapacity))").font(Theme.font(14)).foregroundStyle(Theme.cream)
                    }
                    Bar(value: s.train.fuel, max: stats.fuelCapacity, color: Theme.amber, height: 14)
                    HStack(spacing: 8) {
                        ForEach(ResourceCatalog.burnables) { type in
                            Button { game.refuel(type) } label: {
                                VStack(spacing: 2) {
                                    PixelIcon(image: IconSprites.resource(type), size: 26)
                                    Text("\(ResourceCatalog.name(type)) (\(s.inventory.total(type)))").font(Theme.body(11))
                                        .lineLimit(1).minimumScaleFactor(0.7)
                                    Text("+\(Format.fuel(ResourceCatalog.info(type).fuelValue))").font(Theme.font(12)).foregroundStyle(Theme.amberLight)
                                }
                                .foregroundStyle(Theme.cream)
                                .frame(maxWidth: .infinity, minHeight: 74)
                                .background(Theme.panelLight)
                                .overlay(Rectangle().strokeBorder(s.inventory.total(type) > 0 ? Theme.amber.opacity(0.8) : Theme.border, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button { game.fillTank() } label: { Label("Fyll tanken (kol + bränsle)", systemImage: "fuelpump.fill").frame(maxWidth: .infinity) }
                        .buttonStyle(RetroButtonStyle(accent: Theme.green))
                    Text("Trä eldas bara när du väljer det – det behövs också till bygge.").font(Theme.body(11)).foregroundStyle(Theme.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func line(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.body(13)).foregroundStyle(Theme.dim).frame(width: 90, alignment: .leading)
            Text(value).font(Theme.font(14)).foregroundStyle(Theme.cream)
        }
    }
}

struct RepairPanel: View {
    @Environment(GameController.self) private var game

    var body: some View {
        let s = game.state
        let can = ProgressionSystem.canRepairLocomotive(s)
        CompactPanel(width: 520) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("REPARERA LOKET").font(Theme.font(18)).foregroundStyle(Theme.amberLight)
                    Spacer()
                    Button { game.close() } label: { Image(systemName: "xmark").frame(width: 36, height: 36) }
                        .buttonStyle(RetroButtonStyle(compact: true))
                }
                Text("Motorn är hel, men insprutarna är igensatta och tanken är torr. Med lite skrot och en dunk bränsle borde den gå att väcka till liv.")
                    .font(Theme.body(13)).foregroundStyle(Theme.cream).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 16) {
                    ForEach(ProgressionSystem.locomotiveRepairCost.sorted { $0.key.rawValue < $1.key.rawValue }, id: \.key) { type, need in
                        let have = s.inventory.total(type)
                        HStack(spacing: 6) {
                            PixelIcon(image: IconSprites.resource(type), size: 28)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(ResourceCatalog.name(type)).font(Theme.body(13)).foregroundStyle(Theme.cream)
                                Text("\(min(have, need))/\(need)").font(Theme.font(15)).foregroundStyle(have >= need ? Theme.green : Theme.red)
                            }
                        }
                    }
                }
                Button { game.repairLocomotive() } label: { Label("Reparera", systemImage: "wrench.and.screwdriver.fill").frame(maxWidth: .infinity) }
                    .buttonStyle(RetroButtonStyle(accent: Theme.green, enabled: can))
                    .disabled(!can)
                    .tutorialPulse(can)
            }
        }
    }
}

struct KeypadPanel: View {
    @Environment(GameController.self) private var game
    let objectID: String

    var body: some View {
        CompactPanel(width: 460) {
            HStack(spacing: 16) {
                VStack(spacing: 10) {
                    Text("KODLÅS").font(Theme.font(18)).foregroundStyle(Theme.amberLight)
                    Text(display).font(Theme.mono(30)).foregroundStyle(Theme.green)
                        .frame(width: 150, height: 54).background(Color.black).overlay(Rectangle().strokeBorder(Theme.border, lineWidth: 2))
                    Button("Avbryt") { game.close() }.buttonStyle(RetroButtonStyle(compact: true))
                }
                Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                    GridRow { digit(1); digit(2); digit(3) }
                    GridRow { digit(4); digit(5); digit(6) }
                    GridRow { digit(7); digit(8); digit(9) }
                    GridRow {
                        key(Image(systemName: "delete.left.fill"), accent: Theme.amber) { if !game.keypadEntry.isEmpty { game.keypadEntry.removeLast() } }
                        digit(0)
                        key(Text("OK"), accent: Theme.green) { game.submitKeypad(objectID) }
                    }
                }
            }
        }
    }

    private var display: String {
        let e = game.keypadEntry
        return e + String(repeating: "_", count: max(0, 4 - e.count))
    }

    private func digit(_ d: Int) -> some View {
        key(Text("\(d)"), accent: Theme.amber) {
            if game.keypadEntry.count < 4 { game.keypadEntry.append(String(d)); game.sound.play(.menuMove) }
        }
    }

    private func key(_ label: some View, accent: Color, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.tap(); action() }) {
            label.font(Theme.font(20)).foregroundStyle(Theme.cream)
                .frame(width: 56, height: 46)
                .background(Theme.panelLight)
                .overlay(Rectangle().strokeBorder(accent.opacity(0.9), lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}
