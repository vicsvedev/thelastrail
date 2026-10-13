import SwiftUI

struct MainMenuView: View {
    @Environment(GameController.self) private var game

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("THE LAST RAIL")
                        .font(.system(size: 40, weight: .black, design: .monospaced))
                        .foregroundStyle(Theme.amberLight)
                        .shadow(color: Color(hex: 0x6A3A24), radius: 0, x: 3, y: 3)
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Text("Ett äventyr längs de bortglömda spåren")
                        .font(Theme.body(14))
                        .foregroundStyle(Theme.cream)
                        .shadow(color: .black, radius: 0, x: 1, y: 1)
                }
                .padding(.bottom, 6)
                menuButton("Nytt spel", symbol: "play.fill", enabled: true) { game.requestNewGame() }
                menuButton("Fortsätt", symbol: "arrow.clockwise", enabled: game.hasSave) { game.continueGame() }
                menuButton("Inställningar", symbol: "gearshape.fill", enabled: true) { game.open(.settings) }
                Text("version \(Self.appVersion)").font(Theme.font(10)).foregroundStyle(Theme.cream.opacity(0.6))
            }
            .padding(16)
            .background(Color.black.opacity(0.45))
            .overlay(Rectangle().strokeBorder(Theme.border.opacity(0.7), lineWidth: 2))
            .padding(.leading, 16)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""

    private func menuButton(_ title: String, symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            game.sound.play(.menuSelect)
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.amber).frame(width: 20)
                Text(title).font(Theme.font(18))
                    .foregroundStyle(enabled ? Theme.cream : Theme.dim.opacity(0.6))
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(width: 270, height: 48)
            .background(Theme.panelLight.opacity(enabled ? 0.9 : 0.5))
            .overlay(Rectangle().strokeBorder(enabled ? Theme.amber.opacity(0.8) : Theme.border, lineWidth: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(title)
    }
}
