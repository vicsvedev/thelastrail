import UIKit

/// Light haptic feedback for touch interactions.
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let notify = UINotificationFeedbackGenerator()

    static func tap() { light.impactOccurred() }
    static func bump() { medium.impactOccurred() }
    static func success() { notify.notificationOccurred(.success) }
    static func error() { notify.notificationOccurred(.error) }
}
