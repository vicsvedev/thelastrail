import SpriteKit

/// Starting, loading, saving and moving between screens.
extension GameController {
    func requestNewGame() {
        if hasSave { open(.confirmNewGame) } else { startNewGame() }
    }

    func startNewGame() {
        overlays.removeAll()
        dialogs.removeAll()
        fadeTransition { [self] in
            state = GameState.newGame()
            travelSpeed = 1
            trainScene = nil
            enterExploration(at: nil)
            autosave()
            showTutorialIntroIfNeeded()
        }
    }

    func continueGame() {
        do {
            let loaded = try saveSystem.load()
            overlays.removeAll()
            dialogs.removeAll()
            fadeTransition { [self] in
                state = loaded
                travelSpeed = 1
                trainScene = nil
                explorationScene = nil
                if state.location == .exploring && state.journey == nil,
                   WorldCatalog.layout(state.currentStation) != nil {
                    let pos = state.playerPosition.flatMap { $0.station == state.currentStation ? CGPoint(x: $0.x, y: $0.y) : nil }
                    enterExploration(at: pos)
                } else {
                    state.location = .onTrain
                    enterTrain()
                }
                refreshTutorial()
                showTutorialIntroIfNeeded()
                if state.tutorial.step == .complete && !state.tutorial.finished { open(.tutorialComplete) }
                toast("Spelet laddades.")
            }
        } catch SaveError.unsupportedVersion {
            showDialog(DialogContent(title: "Kan inte ladda", text: "Sparfilen kommer från en nyare version av spelet."))
        } catch {
            hasSave = false
            showDialog(DialogContent(title: "Kan inte ladda", text: "Sparfilen kunde inte läsas. Starta ett nytt spel."))
        }
    }

    func returnToMainMenu() {
        saveIfInGame()
        overlays.removeAll()
        dialogs.removeAll()
        fadeTransition { [self] in
            screen = .mainMenu
            sceneVersion += 1
            prompt = nil
            caption = nil
            explorationScene = nil
            trainScene = nil
            sound.setTrainRunning(false)
            sound.setAmbience(.depot)
        }
    }

    func enterExploration(at position: CGPoint?) {
        guard let layout = WorldCatalog.layout(state.currentStation) else { return }
        state.location = .exploring
        let scene = ExplorationScene(layout: layout, controller: self, start: position)
        explorationScene = scene
        screen = .exploration
        sceneVersion += 1
        prompt = nil
        sound.setTrainRunning(false)
        sound.setAmbience(WorldCatalog.station(state.currentStation).region)
    }

    func enterTrain() {
        state.location = .onTrain
        if let scene = trainScene {
            scene.rebuild()
        } else {
            trainScene = TrainScene(controller: self)
        }
        explorationScene = nil
        screen = .train
        sceneVersion += 1
        prompt = nil
        sound.setAmbience(state.journey == nil ? currentStationInfo.region : nil)
        sound.setTrainRunning(state.journey != nil)
    }

    // MARK: Saving

    func autosave() {
        guard screen != .mainMenu else { return }
        if let scene = explorationScene, screen == .exploration {
            let p = scene.playerPosition
            state.playerPosition = SavedPosition(station: state.currentStation, x: Double(p.x), y: Double(p.y))
        }
        do {
            try saveSystem.save(state)
            hasSave = true
        } catch {
            toast("Kunde inte spara: \(error.localizedDescription)")
        }
    }

    func manualSave() {
        autosave()
        toast("Spelet sparat.")
        sound.play(.menuSelect)
    }

    func saveIfInGame() {
        if screen != .mainMenu { autosave() }
    }

    // MARK: Tutorial

    func refreshTutorial() {
        let events = TutorialSystem.refresh(&state)
        for event in events {
            switch event {
            case .stepStarted(let step):
                if step == .radioSignal {
                    sound.play(.radio)
                    showDialog(.journal(.radioFirst))
                } else if step == .complete {
                    open(.tutorialComplete)
                    sound.play(.secret)
                }
                autosave()
            case .rewardGranted(let cost, let items):
                for (type, n) in cost { toast("+\(n) \(ResourceCatalog.name(type))") }
                for item in items { toast("+1 \(ItemCatalog.name(item))") }
            }
        }
        showTutorialIntroIfNeeded()
    }

    func showTutorialIntroIfNeeded() {
        guard state.tutorial.isActive, dialogs.isEmpty, screen != .mainMenu else { return }
        let step = state.tutorial.step
        guard state.tutorial.introShownFor < step.rawValue else { return }
        state.tutorial.introShownFor = step.rawValue
        if let text = TutorialSystem.intro(step) { showCaption(text, seconds: 6.5) }
    }

    func finishTutorial() {
        TutorialSystem.finish(&state)
        showCaption("Spåren ligger öppna. Res, utforska och bygg i din egen takt.", seconds: 6)
        autosave()
    }

    func skipTutorial() {
        overlays.removeAll()
        TutorialSystem.skip(&state)
        trainScene?.rebuild()
        explorationScene?.refreshAllObjects()
        explorationScene?.refreshTrain()
        toast("Tutorialen hoppades över. Du har fått ett startpaket.", important: true)
        autosave()
    }
}
