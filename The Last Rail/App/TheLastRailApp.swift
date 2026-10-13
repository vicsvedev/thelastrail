import SwiftUI

@main
struct TheLastRailApp: App {
    @State private var controller: GameController = {
        if DebugScenario.isRequested {
            // Development scenarios never touch the player's real save or settings.
            let sandbox = FileManager.default.temporaryDirectory.appendingPathComponent("TLRScenario", isDirectory: true)
            try? FileManager.default.removeItem(at: sandbox)
            return GameController(saveSystem: SaveSystem(directory: sandbox), settingsStore: SettingsStore(directory: sandbox))
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-TLRFreshStart") {
            // Used by UI tests to start from an empty save.
            SaveSystem().deleteAll()
        }
        #endif
        return GameController()
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(controller)
                .preferredColorScheme(.dark)
        }
    }
}
