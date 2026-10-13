import CoreGraphics

/// Platform-neutral player input. On iPhone it is fed by `TouchControlsView`
/// (virtual joystick + sprint button); scenes only read the resulting state.
final class InputManager {
    /// Joystick direction, length 0...1, y pointing up.
    var joystick: CGVector = .zero
    /// True while the sprint button is held.
    var sprinting = false

    var movement: CGVector { joystick }
    var shift: Bool { sprinting }

    func reset() {
        joystick = .zero
        sprinting = false
    }
}
