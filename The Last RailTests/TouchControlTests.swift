import CoreGraphics
import Testing
@testable import The_Last_Rail

/// The on-screen controls must handle several fingers at once.
@MainActor
struct TouchControlTests {
    let size = CGSize(width: 750, height: 372)   // iPhone landscape safe area

    @Test func joystickDirectionAndMagnitude() {
        var m = TouchControlModel(size: size)
        let start = CGPoint(x: 120, y: 280)
        _ = m.began(1, at: start)
        m.moved(1, to: CGPoint(x: start.x + 200, y: start.y))   // far right → clamped full speed
        #expect(abs(m.joystick.dx - 1) < 0.001 && abs(m.joystick.dy) < 0.001)
        m.moved(1, to: CGPoint(x: start.x, y: start.y - 27))    // half up (screen y down → world y up)
        #expect(m.joystick.dy > 0.45 && m.joystick.dy < 0.55)
        m.moved(1, to: CGPoint(x: start.x + 3, y: start.y))     // inside dead zone
        #expect(m.joystick == .zero)
        m.ended(1)
        #expect(m.joystick == .zero && m.joystickOrigin == nil)
    }

    @Test func joystickSprintAndActionSimultaneously() {
        var m = TouchControlModel(size: size)
        _ = m.began(1, at: CGPoint(x: 120, y: 280))
        m.moved(1, to: CGPoint(x: 120, y: 200))                 // walking up
        let sprintFired = m.began(2, at: ControlLayout.sprintCenter(in: size))
        #expect(!sprintFired)
        #expect(m.sprinting)
        let fired = m.began(3, at: ControlLayout.actionCenter(in: size))
        #expect(fired, "Action fires while moving and sprinting")
        #expect(m.joystick.dy > 0.9, "Joystick unaffected by other fingers")
        m.ended(3)
        #expect(m.sprinting && m.joystick.dy > 0.9)
        m.ended(2)
        #expect(!m.sprinting && m.joystick.dy > 0.9)
        m.ended(1)
        #expect(m.joystick == .zero)
    }

    @Test func secondJoystickFingerIsIgnored() {
        var m = TouchControlModel(size: size)
        _ = m.began(1, at: CGPoint(x: 120, y: 280))
        m.moved(1, to: CGPoint(x: 200, y: 280))
        _ = m.began(2, at: CGPoint(x: 60, y: 300))
        m.moved(2, to: CGPoint(x: 0, y: 300))
        #expect(m.joystick.dx > 0.9, "First finger keeps control")
    }

    @Test func touchesOutsideControlsAreNotClaimed() {
        let m = TouchControlModel(size: size)
        #expect(m.role(at: CGPoint(x: 100, y: 40)) == nil, "Top-left HUD stays free")
        #expect(m.role(at: CGPoint(x: 500, y: 150)) == nil, "Right half outside buttons stays free")
        #expect(m.role(at: CGPoint(x: 100, y: 250)) == .joystick)
        #expect(m.role(at: ControlLayout.actionCenter(in: size)) == .action)
        #expect(m.role(at: ControlLayout.sprintCenter(in: size)) == .sprint)
    }

    @Test func releaseAllClearsEverything() {
        var m = TouchControlModel(size: size)
        _ = m.began(1, at: CGPoint(x: 120, y: 280))
        m.moved(1, to: CGPoint(x: 220, y: 280))
        _ = m.began(2, at: ControlLayout.sprintCenter(in: size))
        m.releaseAll()
        #expect(m.joystick == .zero && !m.sprinting && m.roles.isEmpty)
        m.ended(1)   // a late end for a released finger is harmless
        #expect(m.joystick == .zero)
    }
}
