import SwiftUI

struct PausePanel: View {
    @Environment(GameController.self) private var game

    var body: some View {
        CompactPanel(width: 520) {
            VStack(spacing: 10) {
                HStack {
                    Text("PAUS").font(Theme.font(20)).foregroundStyle(Theme.amberLight)
                    Spacer()
                    Text("Speltid \(formatTime(game.state.playTime))").font(Theme.font(11)).foregroundStyle(Theme.dim)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    button("Fortsätt spela", "play.fill", accent: Theme.green) { game.close() }
                    button("Spara spelet", "square.and.arrow.down.fill") { game.manualSave() }
                    button("Hjälp / Guide", "questionmark.circle.fill") { game.open(.help) }
                    button("Inställningar", "gearshape.fill") { game.open(.settings) }
                    if game.state.tutorial.isActive {
                        button("Hoppa över tutorial", "forward.end.fill") { game.open(.confirmSkipTutorial) }
                    }
                    button("Huvudmeny", "house.fill") { game.returnToMainMenu() }
                }
                Text("Spelet sparas automatiskt.").font(Theme.body(11)).foregroundStyle(Theme.dim)
            }
        }
    }

    private func button(_ title: String, _ symbol: String, accent: Color = Theme.amber, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.tap(); action() }) {
            Label(title, systemImage: symbol).frame(maxWidth: .infinity)
        }
        .buttonStyle(RetroButtonStyle(accent: accent))
    }

    private func formatTime(_ t: Double) -> String {
        let m = Int(t) / 60
        return m >= 60 ? "\(m / 60) h \(m % 60) min" : "\(m) min"
    }
}

struct SettingsPanel: View {
    @Environment(GameController.self) private var game

    var body: some View {
        PhonePanel(title: "Inställningar", close: { game.close() }) {
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    slider("Huvudvolym", \.masterVolume)
                    slider("Musik", \.musicVolume)
                    slider("Ljudeffekter", \.effectsVolume)
                }
                VStack(alignment: .leading, spacing: 8) {
                    toggle("Stäng av allt ljud", \.muted)
                    toggle("Skärmskakning", \.screenShake)
                    toggle("Visa tips i målrutan", \.showHints)
                    Text("Inställningarna sparas automatiskt. Spelet följer telefonens ljudlösa läge.")
                        .font(Theme.body(11)).foregroundStyle(Theme.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 4)
        }
    }

    private func slider(_ label: String, _ key: WritableKeyPath<GameSettings, Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(Theme.body(14)).foregroundStyle(Theme.cream)
                Spacer()
                Text("\(Int(game.settings[keyPath: key] * 100))%").font(Theme.font(12)).foregroundStyle(Theme.dim)
            }
            Slider(value: Binding(get: { game.settings[keyPath: key] },
                                  set: { var s = game.settings; s[keyPath: key] = $0; game.updateSettings(s) }), in: 0...1)
                .tint(Theme.amber)
        }
        .frame(maxWidth: 320)
    }

    private func toggle(_ label: String, _ key: WritableKeyPath<GameSettings, Bool>) -> some View {
        Toggle(isOn: Binding(get: { game.settings[keyPath: key] },
                             set: { var s = game.settings; s[keyPath: key] = $0; game.updateSettings(s) })) {
            Text(label).font(Theme.body(14)).foregroundStyle(Theme.cream)
        }
        .tint(Theme.amber)
        .frame(maxWidth: 300)
    }
}

struct HelpPanel: View {
    @Environment(GameController.self) private var game
    @State private var section = 0

    private let sections: [(String, String)] = [
        ("Till fots", "Styrspak: dra med tummen var som helst på vänstra halvan av skärmen. Ju längre du drar, desto fortare går du.\n\nHåll in springknappen (löparen) för att springa – det fungerar samtidigt som du går.\n\nHandlingsknappen (handen) nere till höger: plocka upp, öppna, läsa, undersöka och gå ombord på tåget. Den lyser när något finns inom räckhåll, och texten ovanför visar vad som händer.\n\nKnapparna uppe till höger: ryggsäck, karta (när du har en), journal och paus."),
        ("På tåget", "Svep åt sidan för att se hela tåget och nyp för att zooma.\n\nTryck på loket för att tanka och lyssna på radion. Tryck på en lastvagn för lagret eller verkstaden, och på bostadsvagnen för att vila.\n\nKnappraden längst ner: Karta, Lager, Bygg, Vagnar, Loket, Journal och Kliv av."),
        ("Kartan", "Dra för att panorera och nyp för att zooma. Tryck på en station för att se avstånd, bränsle, restid och vad som krävs. Tryck Res hit för att åka – eller Tanka och res om tanken behöver fyllas på först."),
        ("Grundloopen", "1. Välj en station på kartan och res dit.\n2. Kliv av och utforska. Det du plockar upp hamnar i ryggsäcken.\n3. Gå tillbaka till tåget – ryggsäcken lastas av automatiskt.\n4. Bygg uppgraderingar, verktyg och vagnar.\n5. Nya rutter och områden öppnar sig."),
        ("Bränsle & faror", "Resor kostar bränsle beroende på avstånd, vikt, motor och tågets skick. Tanka med bränsle (10), kol (5) eller trä (2).\n\nGiftigt slam, ångventiler, ras och iskallt vatten skadar dig. Om hälsan tar slut vaknar du vid tåget men förlorar hälften av det du bar på. Ät mat från ryggsäcken för att läka."),
        ("Hemligheter", "Var nyfiken. Upptrampade stigar, sprickor i väggar och lappar med koder leder ofta någonstans. Allt som är värt att hitta är inte utmärkt."),
    ]

    var body: some View {
        PhonePanel(title: "Hjälp / Guide", close: { game.close() }) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 6) {
                    ForEach(sections.indices, id: \.self) { i in
                        Button(sections[i].0) { section = i; Haptics.tap() }
                            .buttonStyle(RetroButtonStyle(accent: section == i ? Theme.amberLight : Theme.border, compact: true))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: 170)
                ScrollView {
                    Text(sections[section].1)
                        .font(Theme.body(14)).foregroundStyle(Theme.cream).lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(Theme.panelLight.opacity(0.6))
            }
        }
    }
}

struct ConfirmNewGamePanel: View {
    @Environment(GameController.self) private var game

    var body: some View {
        CompactPanel {
            VStack(spacing: 12) {
                Text("Starta ett nytt spel?").font(Theme.font(18)).foregroundStyle(Theme.amberLight)
                Text("Det finns redan ett sparat spel. Om du startar om skrivs det över.")
                    .font(Theme.body(14)).foregroundStyle(Theme.cream).multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    Button("Avbryt") { game.close() }.buttonStyle(RetroButtonStyle())
                    Button("Starta nytt spel") { game.startNewGame() }.buttonStyle(RetroButtonStyle(accent: Theme.red))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ConfirmSkipTutorialPanel: View {
    @Environment(GameController.self) private var game

    var body: some View {
        CompactPanel(width: 460) {
            VStack(spacing: 12) {
                Text("Hoppa över tutorialen?").font(Theme.font(18)).foregroundStyle(Theme.amberLight)
                Text("Loket repareras, verkstaden byggs och du får ett startpaket. Tallkorset och Rosthamn blir tillgängliga på kartan.")
                    .font(Theme.body(14)).foregroundStyle(Theme.cream).multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    Button("Avbryt") { game.close() }.buttonStyle(RetroButtonStyle())
                    Button("Hoppa över") { game.skipTutorial() }.buttonStyle(RetroButtonStyle(accent: Theme.amber))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct TutorialCompletePanel: View {
    @Environment(GameController.self) private var game

    var body: some View {
        CompactPanel(width: 600) {
            VStack(spacing: 10) {
                Text("KAPITEL 1 — SISTA AVGÅNGEN").font(Theme.font(11)).foregroundStyle(Theme.dim)
                Text("Din resa har bara börjat.").font(Theme.font(22)).foregroundStyle(Theme.amberLight)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text("Loket lever och vagnen har en verkstad. Nu reser, utforskar och bygger du i din egen takt. Radiosignalen kommer från norr – och spåret mot Rosthamn är öppet.")
                    .font(Theme.body(13)).foregroundStyle(Theme.cream).multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    ForEach(TutorialSystem.reward.sorted { $0.key.rawValue < $1.key.rawValue }, id: \.key) { type, n in
                        HStack(spacing: 3) {
                            PixelIcon(image: IconSprites.resource(type), size: 22)
                            Text("+\(n)").font(Theme.font(13)).foregroundStyle(Theme.cream)
                        }
                    }
                    ForEach(TutorialSystem.rewardItems, id: \.self) { item in
                        HStack(spacing: 3) {
                            PixelIcon(image: IconSprites.item(item), size: 22)
                            Text("+1").font(Theme.font(13)).foregroundStyle(Theme.cream)
                        }
                    }
                }
                Button("Ut på spåren") { game.close(.tutorialComplete) }
                    .buttonStyle(RetroButtonStyle(accent: Theme.green))
            }
            .frame(maxWidth: .infinity)
        }
    }
}
