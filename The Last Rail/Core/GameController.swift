import Observation
import SpriteKit

enum Screen: Equatable {
    case mainMenu
    case train
    case exploration
}

enum Overlay: Equatable {
    case pause
    case settings
    case help
    case inventory
    case crafting
    case map
    case journal
    case wagons
    case locomotive
    case repair
    case keypad(String)
    case tutorialComplete
    case confirmNewGame
    case confirmSkipTutorial

    /// Overlays that freeze the world (movement, hazards, journeys).
    var freezesWorld: Bool {
        switch self {
        case .pause, .settings, .help, .tutorialComplete, .confirmNewGame, .confirmSkipTutorial: return true
        default: return false
        }
    }
}

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let created: Date
    var important = false
}

/// Owns the game state and coordinates systems, scenes, audio, saving and UI.
@Observable
final class GameController {
    var state = GameState.newGame()
    var screen: Screen = .mainMenu
    var overlays: [Overlay] = []
    var dialogs: [DialogContent] = []
    var toasts: [Toast] = []
    var prompt: String?
    var caption: String?
    var fadeOpacity: Double = 0
    var settings: GameSettings
    var hasSave = false
    var travelSpeed: Double = 1
    var emergencyOffer: StationID?
    var inDarkness = false
    /// Bumped whenever a scene object is replaced so SwiftUI re-presents it.
    var sceneVersion = 0

    @ObservationIgnored let sound = SoundManager()
    @ObservationIgnored let input = InputManager()
    @ObservationIgnored let saveSystem: SaveSystem
    @ObservationIgnored let settingsStore: SettingsStore
    @ObservationIgnored var explorationScene: ExplorationScene?
    @ObservationIgnored var trainScene: TrainScene?
    @ObservationIgnored lazy var menuScene: MenuScene = {
        let scene = MenuScene()
        scene.controller = self
        return scene
    }()
    @ObservationIgnored private var autosaveTimer: Double = 0
    @ObservationIgnored private var captionToken = 0
    @ObservationIgnored var moveAccumulator: Double = 0
    /// Text typed on the keypad overlay.
    var keypadEntry = ""
    /// True once the logical viewport has been sized to the screen.
    var viewportReady = false

    init(saveSystem: SaveSystem = SaveSystem(), settingsStore: SettingsStore = SettingsStore()) {
        self.saveSystem = saveSystem
        self.settingsStore = settingsStore
        settings = settingsStore.load()
        hasSave = saveSystem.hasValidSave
        sound.apply(settings)
        sound.setAmbience(.depot)
    }

    // MARK: Derived

    var stats: TrainStats { TrainStats(state: state) }
    var currentStationInfo: StationInfo { WorldCatalog.station(state.currentStation) }
    var isWorldFrozen: Bool { !dialogs.isEmpty || overlays.contains { $0.freezesWorld } || screen == .mainMenu }
    /// Movement and interaction are blocked by any overlay or dialog.
    var isInputBlocked: Bool { !dialogs.isEmpty || !overlays.isEmpty || fadeOpacity > 0.5 }
    var topOverlay: Overlay? { overlays.last }
    var isMapAvailable: Bool { state.tutorial.finished || state.tutorial.step >= .radioSignal }

    var activeScene: SKScene {
        switch screen {
        case .mainMenu: return menuScene
        case .train: return trainScene ?? menuScene
        case .exploration: return explorationScene ?? menuScene
        }
    }

    // MARK: Main loop (called by the active scene every frame)

    func tick(_ dt: Double) {
        let dt = min(dt, 0.1)
        let now = Date()
        if toasts.contains(where: { now.timeIntervalSince($0.created) > ($0.important ? 6 : 3.5) }) {
            toasts.removeAll { now.timeIntervalSince($0.created) > ($0.important ? 6 : 3.5) }
        }
        guard screen != .mainMenu, !isWorldFrozen else { return }
        state.playTime += dt
        if state.journey != nil {
            let arrived = TravelSystem.advance(dt * travelSpeed, &state)
            if arrived { handleArrival() }
        }
        autosaveTimer += dt
        if autosaveTimer > 90 {
            autosaveTimer = 0
            autosave()
        }
    }

    // MARK: Feedback helpers

    func toast(_ text: String, important: Bool = false) {
        toasts.append(Toast(text: text, created: Date(), important: important))
        if toasts.count > 5 { toasts.removeFirst(toasts.count - 5) }
    }

    func showCaption(_ text: String, seconds: Double = 5.5) {
        captionToken += 1
        let token = captionToken
        caption = text
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self, self.captionToken == token else { return }
            self.caption = nil
        }
    }

    func showDialog(_ d: DialogContent) {
        dialogs.append(d)
    }

    func dismissDialog() {
        guard !dialogs.isEmpty else { return }
        dialogs.removeFirst()
        sound.play(.menuSelect)
        showTutorialIntroIfNeeded()
    }

    func play(_ e: SoundEffect?) {
        if let e { sound.play(e) }
    }

    // MARK: Overlays

    func open(_ overlay: Overlay) {
        if overlay == .map {
            guard isMapAvailable else { toast("Du har ingen karta ännu."); return }
            if state.tutorial.step >= .radioSignal && !state.tutorial.openedMapAfterRadio {
                state.tutorial.openedMapAfterRadio = true
                refreshTutorial()
            }
        }
        if overlays.last == overlay { return }
        overlays.removeAll { $0 == overlay }
        overlays.append(overlay)
        emergencyOffer = nil
        sound.play(.menuSelect)
    }

    func close(_ overlay: Overlay? = nil) {
        guard let target = overlay ?? overlays.last else { return }
        overlays.removeAll { $0 == target }
        sound.play(.menuMove)
        if target == .tutorialComplete { finishTutorial() }
        if case .keypad = target { keypadEntry = "" }
    }

    func toggle(_ overlay: Overlay) {
        if overlays.last == overlay { close(overlay) } else { open(overlay) }
    }

    // MARK: Screens

    func fadeTransition(_ change: @escaping () -> Void) {
        Task { @MainActor in
            fadeOpacity = 1
            try? await Task.sleep(nanoseconds: 280_000_000)
            change()
            try? await Task.sleep(nanoseconds: 80_000_000)
            fadeOpacity = 0
        }
    }

    func updateSettings(_ new: GameSettings) {
        settings = new
        settingsStore.save(new)
        sound.apply(new)
    }

    /// Called when the app leaves the foreground: save and release held controls.
    func appWillResignActive() {
        input.reset()
        saveIfInGame()
    }
}
