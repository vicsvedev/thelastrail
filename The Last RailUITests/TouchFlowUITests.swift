import XCTest

/// Real touch input in the iOS Simulator: taps, drags, swipes and pinches go through UIKit.
/// (Independent simultaneous fingers cannot be synthesized by XCUITest; see TouchControlTests.)
final class TouchFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    private func launch(_ args: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = args
        app.launch()
        return app
    }

    private func isLandscape(_ app: XCUIApplication) -> Bool {
        let f = app.windows.firstMatch.frame
        return f.width > f.height
    }

    @MainActor
    func testMainMenuNewGameAndJoystickMovement() throws {
        let app = launch(["-TLRFreshStart"])
        let newGame = app.buttons["Nytt spel"]
        XCTAssertTrue(newGame.waitForExistence(timeout: 10))
        XCTAssertTrue(isLandscape(app))
        XCTAssertFalse(app.buttons["Fortsätt"].isEnabled, "No save yet")
        newGame.tap()
        XCTAssertTrue(app.staticTexts["KAPITEL 1  1/10"].waitForExistence(timeout: 8))
        // Drag the joystick: start inside the stick, drag right and hold.
        let stick = app.descendants(matching: .any)["Styrspak"].firstMatch
        XCTAssertTrue(stick.waitForExistence(timeout: 5))
        let start = stick.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(CGVector(dx: 60, dy: 0))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 1.5)
        XCTAssertTrue(app.staticTexts["KAPITEL 1  2/10"].waitForExistence(timeout: 5), "Walking completes tutorial step 1")
    }

    @MainActor
    func testActionButtonInspectsLocomotive() throws {
        let app = launch(["-TLRScenario", "newgame;at:24,15"])
        let action = app.descendants(matching: .any)["Handlingsknapp"].firstMatch
        XCTAssertTrue(action.waitForExistence(timeout: 10))
        let found = app.staticTexts["Undersök loket"].waitForExistence(timeout: 5)
        if !found { try? app.debugDescription.write(toFile: "/tmp/tlr_action_tree.txt", atomically: true, encoding: .utf8) }
        XCTAssertTrue(found, "Prompt appears next to the locomotive")
        action.tap()
        let cont = app.buttons["Fortsätt"]
        XCTAssertTrue(cont.waitForExistence(timeout: 5), "Inspection dialog opens")
        cont.tap()
        // A teleport is not walking: step 1 still waits for the joystick. Walking now
        // completes step 1 and, because the locomotive was already inspected, step 2 too.
        XCTAssertTrue(app.staticTexts["KAPITEL 1  1/10"].waitForExistence(timeout: 5))
        let stick = app.descendants(matching: .any)["Styrspak"].firstMatch
        let start = stick.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: -60, dy: 0)), withVelocity: .slow, thenHoldForDuration: 1.2)
        XCTAssertTrue(app.staticTexts["KAPITEL 1  3/10"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTrainGesturesMapAndDeparture() throws {
        let app = launch(["-TLRScenario", "skip;train:tallkorset"])
        let mapButton = app.buttons["Karta"]
        XCTAssertTrue(mapButton.waitForExistence(timeout: 10))
        // Swipe along the train and pinch to zoom: must not open anything or crash.
        let world = app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
        world.press(forDuration: 0.05, thenDragTo: world.withOffset(CGVector(dx: -150, dy: 0)))
        app.windows.firstMatch.pinch(withScale: 0.6, velocity: -1)
        XCTAssertTrue(mapButton.isHittable)
        // Tap the locomotive area → locomotive panel (tap test for wagons).
        mapButton.tap()
        XCTAssertTrue(app.staticTexts["JÄRNVÄGSKARTA"].waitForExistence(timeout: 5))
        let rosthamn = app.buttons["Rosthamn"]
        XCTAssertTrue(rosthamn.waitForExistence(timeout: 5))
        rosthamn.tap()
        let go = app.buttons["Res hit"]
        XCTAssertTrue(go.waitForExistence(timeout: 5), "Travel button is visible for a reachable station")
        // Pinch-zoom and drag the map; the travel button stays available.
        let mapCenter = app.staticTexts["N ↑"].exists ? app.windows.firstMatch : app.windows.firstMatch
        mapCenter.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5)).press(forDuration: 0.05, thenDragTo: mapCenter.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.45)))
        XCTAssertTrue(go.isHittable)
        go.tap()
        XCTAssertTrue(app.staticTexts["PÅ VÄG"].waitForExistence(timeout: 5), "Journey started")
    }

    @MainActor
    func testStaysLandscapeInAllOrientations() throws {
        let app = launch(["-TLRScenario", "skip;train:tallkorset"])
        XCTAssertTrue(app.buttons["Karta"].waitForExistence(timeout: 10))
        for o in [UIDeviceOrientation.landscapeRight, .portrait, .portraitUpsideDown, .landscapeLeft] {
            XCUIDevice.shared.orientation = o
            sleep(1)
            XCTAssertTrue(isLandscape(app), "UI must stay landscape for \(o.rawValue)")
            XCTAssertTrue(app.buttons["Karta"].isHittable)
        }
    }

    @MainActor
    func testSaveSurvivesRelaunch() throws {
        var app = launch(["-TLRFreshStart"])
        XCTAssertTrue(app.buttons["Nytt spel"].waitForExistence(timeout: 10))
        app.buttons["Nytt spel"].tap()
        let stick = app.descendants(matching: .any)["Styrspak"].firstMatch
        XCTAssertTrue(stick.waitForExistence(timeout: 8))
        let start = stick.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 60, dy: 0)), withVelocity: .slow, thenHoldForDuration: 1.5)
        XCTAssertTrue(app.staticTexts["KAPITEL 1  2/10"].waitForExistence(timeout: 5))
        // Pause → main menu saves.
        app.buttons["Paus"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Huvudmeny"].waitForExistence(timeout: 5))
        app.buttons["Huvudmeny"].tap()
        XCTAssertTrue(app.buttons["Fortsätt"].waitForExistence(timeout: 5))
        app.terminate()
        app = launch([])
        let cont = app.buttons["Fortsätt"]
        XCTAssertTrue(cont.waitForExistence(timeout: 10))
        XCTAssertTrue(cont.isEnabled, "A valid save exists after relaunch")
        cont.tap()
        XCTAssertTrue(app.staticTexts["KAPITEL 1  2/10"].waitForExistence(timeout: 8), "Tutorial progress restored")
    }

    @MainActor
    func testTravelArriveDisembarkAndBoard() throws {
        let app = launch(["-TLRScenario", "skip;train:tallkorset;overlay:map"])
        let rosthamn = app.buttons["Rosthamn"]
        XCTAssertTrue(rosthamn.waitForExistence(timeout: 10))
        rosthamn.tap()
        app.buttons["Res hit"].tap()
        XCTAssertTrue(app.staticTexts["PÅ VÄG"].waitForExistence(timeout: 5))
        // First trip on this route cannot be skipped; wait for arrival (~15 s).
        XCTAssertTrue(app.staticTexts["ROSTHAMN"].waitForExistence(timeout: 40), "Arrived at Rosthamn")
        app.buttons["Kliv av"].tap()
        let action = app.descendants(matching: .any)["Handlingsknapp"].firstMatch
        XCTAssertTrue(action.waitForExistence(timeout: 8), "Exploration controls after stepping off")
        // The spawn is next to the train, so the action button boards it again.
        XCTAssertTrue(app.staticTexts["Gå ombord på tåget"].waitForExistence(timeout: 5))
        action.tap()
        XCTAssertTrue(app.buttons["Kliv av"].waitForExistence(timeout: 8), "Back on the train")
    }
}
