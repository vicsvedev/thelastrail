import SwiftUI

struct JournalPanel: View {
    @Environment(GameController.self) private var game
    @State private var tab = 0
    @State private var selected: JournalID?

    var body: some View {
        let s = game.state
        PhonePanel(title: "Journal", close: { game.close() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    tabButton("Dagbok", "book.fill", 0)
                    tabButton("Ritningar", "doc.text.fill", 1)
                    tabButton("Mål", "flag.fill", 2)
                    tabButton("Stationer", "mappin.and.ellipse", 3)
                }
                switch tab {
                case 0: entries(s)
                case 1: blueprints(s)
                case 2: goals(s)
                default: stations(s)
                }
            }
        }
    }

    private func tabButton(_ title: String, _ symbol: String, _ index: Int) -> some View {
        Button { tab = index; Haptics.tap() } label: { Label(title, systemImage: symbol) }
            .buttonStyle(RetroButtonStyle(accent: tab == index ? Theme.amberLight : Theme.border, compact: true))
    }

    private func entries(_ s: GameState) -> some View {
        HStack(alignment: .top, spacing: 8) {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if s.journal.isEmpty {
                        Text("Inga anteckningar ännu.").font(Theme.body(12)).foregroundStyle(Theme.dim)
                    }
                    ForEach(s.journal.reversed(), id: \.self) { id in
                        let e = JournalCatalog.entry(id)
                        Button { selected = id; Haptics.tap() } label: {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(e.title).font(Theme.body(13)).foregroundStyle(Theme.cream).lineLimit(1).minimumScaleFactor(0.8)
                                Text(e.category.rawValue).font(Theme.body(10)).foregroundStyle(Theme.dim)
                            }
                            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                            .padding(.horizontal, 6)
                            .background(selected == id ? Theme.amber.opacity(0.2) : Theme.panelLight.opacity(0.4))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(width: 220)
            ScrollView {
                if let id = selected ?? s.journal.last {
                    let e = JournalCatalog.entry(id)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(e.title).font(Theme.font(16)).foregroundStyle(Theme.amberLight)
                        Text(e.text).font(Theme.mono(13)).foregroundStyle(Theme.cream).lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(8)
            .background(Theme.panelLight.opacity(0.6))
        }
    }

    private func blueprints(_ s: GameState) -> some View {
        let all = RecipeCatalog.all.filter(\.needsBlueprint)
        return ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                ForEach(all) { r in
                    let known = s.knownBlueprints.contains(r.id)
                    HStack(spacing: 8) {
                        PixelIcon(image: ObjectSprites.canvas(.blueprint).uiImage(), size: 26).opacity(known ? 1 : 0.25)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(known ? r.name : "Okänd ritning").font(Theme.body(13)).foregroundStyle(known ? Theme.cream : Theme.dim)
                            Text(known ? r.description : "Någonstans längs spåren…").font(Theme.body(10)).foregroundStyle(Theme.dim).lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        if s.completedUpgrades.contains(r.id) || (r.id == .trackRepair && s.has(.mineLineRepaired)) {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.green)
                        }
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .background(Theme.panelLight.opacity(0.5))
                }
            }
        }
    }

    private func goals(_ s: GameState) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("NUVARANDE MÅL").font(Theme.font(11)).foregroundStyle(Theme.amber)
                Text(s.tutorial.isActive ? TutorialSystem.objective(s.tutorial.step) : ProgressionSystem.currentGoal(s))
                    .font(Theme.body(14)).foregroundStyle(Theme.cream).fixedSize(horizontal: false, vertical: true)
                Text("LÅNGSIKTIGA MÅL").font(Theme.font(11)).foregroundStyle(Theme.amber).padding(.top, 6)
                ForEach(ProgressionSystem.longTermGoals(s)) { line in
                    Label(line.text, systemImage: line.done ? "checkmark.square.fill" : "square")
                        .font(Theme.body(12)).foregroundStyle(line.done ? Theme.green : Theme.cream)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 6) {
                Text("HEMLIGHETER").font(Theme.font(11)).foregroundStyle(Theme.amber)
                ForEach(SecretID.allCases, id: \.self) { secret in
                    let found = s.discoveredSecrets.contains(secret)
                    Label(found ? secret.name : "???", systemImage: found ? "sparkles" : "questionmark")
                        .font(Theme.body(12)).foregroundStyle(found ? Theme.amberLight : Theme.dim)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func stations(_ s: GameState) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                ForEach(WorldCatalog.stations.filter { s.discoveredStations.contains($0.id) }, id: \.id) { st in
                    let visited = s.visitedStations.contains(st.id)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(visited || st.id != .polaris ? st.name : "???").font(Theme.body(14)).foregroundStyle(visited ? Theme.amberLight : Theme.dim)
                        Text(visited ? st.description : "Ej besökt.").font(Theme.body(11)).foregroundStyle(Theme.cream.opacity(0.8)).lineLimit(3)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
                    .background(Theme.panelLight.opacity(0.5))
                }
            }
        }
    }
}
