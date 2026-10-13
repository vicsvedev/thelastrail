import SwiftUI

struct RootView: View {
    @Environment(GameController.self) private var game
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                if game.viewportReady {
                    let _ = game.sceneVersion
                    SpriteKitView(scene: game.activeScene)
                        .ignoresSafeArea()
                    GameOverlayLayer()
                }
            }
            .onAppear { prepareViewport(geo) }
        }
        .ignoresSafeArea(.keyboard)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .inactive, .background: game.appWillResignActive()
            case .active: game.sound.resume()
            @unknown default: break
            }
        }
    }

    /// The world's logical width follows the real screen aspect ratio (measured including safe areas).
    private func prepareViewport(_ geo: GeometryProxy) {
        guard !game.viewportReady else { return }
        let full = CGSize(width: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                          height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
        Viewport.configure(for: full)
        game.viewportReady = true
        DebugScenario.runIfRequested(game)
    }
}

/// Everything drawn on top of the SpriteKit world: HUDs, panels, dialogs, toasts and fades.
struct GameOverlayLayer: View {
    @Environment(GameController.self) private var game

    var body: some View {
        ZStack {
            switch game.screen {
            case .mainMenu: MainMenuView()
            case .exploration: ExplorationHUD()
            case .train: TrainHUD()
            }

            if let caption = game.caption {
                CaptionView(text: caption)
            }

            ToastStack()

            if let overlay = game.topOverlay {
                OverlayHost(overlay: overlay)
                    .id(String(describing: overlay))
            }

            if let dialog = game.dialogs.first {
                DialogView(dialog: dialog)
            }

            Color.black.opacity(game.fadeOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(game.fadeOpacity > 0.5)
                .animation(.easeInOut(duration: 0.28), value: game.fadeOpacity)
        }
        .animation(.easeOut(duration: 0.15), value: game.overlays)
        .animation(.easeOut(duration: 0.2), value: game.caption)
    }
}

struct OverlayHost: View {
    let overlay: Overlay

    var body: some View {
        switch overlay {
        case .pause: PausePanel()
        case .settings: SettingsPanel()
        case .help: HelpPanel()
        case .inventory: InventoryPanel()
        case .crafting: CraftingPanel()
        case .map: MapPanel()
        case .journal: JournalPanel()
        case .wagons: WagonPanel()
        case .locomotive: LocomotivePanel()
        case .repair: RepairPanel()
        case .keypad(let id): KeypadPanel(objectID: id)
        case .tutorialComplete: TutorialCompletePanel()
        case .confirmNewGame: ConfirmNewGamePanel()
        case .confirmSkipTutorial: ConfirmSkipTutorialPanel()
        }
    }
}

/// Story captions sit centred in the free space between the left status card and the
/// right-hand HUD column, so they never cover the HUD; they never take touches.
struct CaptionView: View {
    let text: String

    var body: some View {
        GeometryReader { geo in
            Text(text)
                .font(Theme.body(13))
                .foregroundStyle(Theme.cream)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.65))
                .overlay(Rectangle().strokeBorder(Theme.border.opacity(0.7), lineWidth: 1))
                .frame(maxWidth: max(200, geo.size.width - 2 * 250))
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}

/// Short notifications, centred low so they stay clear of the joystick and buttons.
struct ToastStack: View {
    @Environment(GameController.self) private var game

    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            ForEach(game.toasts.suffix(3)) { t in
                Text(t.text)
                    .font(Theme.body(12))
                    .foregroundStyle(t.important ? Theme.amberLight : Theme.cream)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .overlay(Rectangle().strokeBorder(t.important ? Theme.amber.opacity(0.8) : Theme.border.opacity(0.6), lineWidth: 1))
                    .frame(maxWidth: 340)
                    .transition(.opacity)
            }
        }
        .padding(.bottom, game.screen == .train ? 70 : 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.2), value: game.toasts)
    }
}

struct DialogView: View {
    @Environment(GameController.self) private var game
    let dialog: DialogContent

    private var accent: Color {
        switch dialog.style {
        case .radio: return Theme.green
        case .discovery: return Theme.amberLight
        case .blueprint: return Color(hex: 0x8AB0E0)
        case .note: return Theme.cream
        case .info: return Theme.amber
        }
    }

    private var icon: String {
        switch dialog.style {
        case .radio: return "antenna.radiowaves.left.and.right"
        case .discovery: return "sparkles"
        case .blueprint: return "doc.text.fill"
        case .note: return "envelope.open.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var bodyText: some View {
        Text(dialog.text)
            .font(dialog.style == .note || dialog.style == .radio ? Theme.mono(13) : Theme.body(14))
            .foregroundStyle(Theme.cream)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { game.dismissDialog() }
            RetroPanel(padding: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: icon).foregroundStyle(accent)
                        Text(dialog.title).font(Theme.font(16)).foregroundStyle(accent).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    ViewThatFits(in: .vertical) {
                        bodyText
                        ScrollView { bodyText }.scrollIndicatorsFlash(onAppear: true)
                    }
                    HStack {
                        Spacer()
                        Button("Fortsätt") { game.dismissDialog() }
                            .buttonStyle(RetroButtonStyle(accent: accent))
                    }
                }
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .transition(.opacity)
    }
}
