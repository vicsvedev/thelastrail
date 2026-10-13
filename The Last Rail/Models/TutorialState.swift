import Foundation

enum TutorialStep: Int, Codable, CaseIterable, Comparable {
    case wakeUp = 1
    case investigateLocomotive
    case collectScrap
    case findFuel
    case repairLocomotive
    case radioSignal
    case firstJourney
    case firstExpedition
    case firstUpgrade
    case complete

    static func < (lhs: TutorialStep, rhs: TutorialStep) -> Bool { lhs.rawValue < rhs.rawValue }

    var next: TutorialStep? { TutorialStep(rawValue: rawValue + 1) }
}

struct TutorialState: Codable, Equatable {
    var step: TutorialStep = .wakeUp
    /// True once the player has acknowledged the final step (or skipped).
    var finished = false
    var skipped = false
    var hasMoved = false
    var inspectedLocomotive = false
    var openedMapAfterRadio = false
    var leftTrainAtTallkorset = false
    var foundTallkorsetWorkshop = false
    /// Step whose intro text has already been shown, so captions never repeat.
    var introShownFor: Int = 0

    var isActive: Bool { !finished }
}
