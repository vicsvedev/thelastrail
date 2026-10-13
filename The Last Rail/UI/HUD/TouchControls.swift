import SwiftUI
import UIKit

/// Geometry shared by the UIKit control view and SwiftUI hints (points, inside the safe area).
enum ControlLayout {
    static let actionRadius: CGFloat = 40
    static let sprintRadius: CGFloat = 30
    static let joystickRadius: CGFloat = 54
    static let knobRadius: CGFloat = 24
    /// Area at the top of the joystick zone that is left to the HUD.
    static let topReserved: CGFloat = 96

    static func actionCenter(in size: CGSize) -> CGPoint { CGPoint(x: size.width - 70, y: size.height - 66) }
    static func sprintCenter(in size: CGSize) -> CGPoint { CGPoint(x: size.width - 168, y: size.height - 44) }
    static func joystickHome(in size: CGSize) -> CGPoint { CGPoint(x: 92, y: size.height - 82) }

    static func inJoystickZone(_ p: CGPoint, _ size: CGSize) -> Bool {
        p.x < size.width * 0.45 && p.y > topReserved
    }
}

/// Pure multi-touch logic for the on-screen controls (unit tested).
/// Each finger is identified by an id and keeps the role it started with.
struct TouchControlModel {
    enum Role { case joystick, sprint, action }

    var size: CGSize
    private(set) var roles: [Int: Role] = [:]
    private(set) var joystickOrigin: CGPoint?
    private(set) var knob: CGPoint?
    private(set) var joystick: CGVector = .zero
    private(set) var sprinting = false
    private(set) var actionDown = false

    init(size: CGSize) { self.size = size }

    func role(at p: CGPoint) -> Role? {
        let a = ControlLayout.actionCenter(in: size), s = ControlLayout.sprintCenter(in: size)
        if hypot(p.x - a.x, p.y - a.y) <= ControlLayout.actionRadius + 14 { return .action }
        if hypot(p.x - s.x, p.y - s.y) <= ControlLayout.sprintRadius + 12 { return .sprint }
        if ControlLayout.inJoystickZone(p, size) { return .joystick }
        return nil
    }

    /// Returns true when this touch fired the action button.
    mutating func began(_ id: Int, at p: CGPoint) -> Bool {
        guard let r = role(at: p) else { return false }
        switch r {
        case .joystick:
            guard joystickOrigin == nil else { return false }   // one joystick finger at a time
            roles[id] = .joystick
            joystickOrigin = CGPoint(x: max(ControlLayout.joystickRadius + 8, p.x),
                                     y: min(size.height - ControlLayout.joystickRadius - 8, max(ControlLayout.topReserved + ControlLayout.joystickRadius, p.y)))
            updateKnob(p)
        case .sprint:
            roles[id] = .sprint
            sprinting = true
        case .action:
            roles[id] = .action
            actionDown = true
            return true
        }
        return false
    }

    mutating func moved(_ id: Int, to p: CGPoint) {
        if roles[id] == .joystick { updateKnob(p) }
    }

    mutating func ended(_ id: Int) {
        switch roles.removeValue(forKey: id) {
        case .joystick:
            joystickOrigin = nil
            knob = nil
            joystick = .zero
        case .sprint:
            sprinting = roles.values.contains(.sprint)
        case .action:
            actionDown = roles.values.contains(.action)
        case nil:
            break
        }
    }

    mutating func releaseAll() {
        roles.removeAll()
        joystickOrigin = nil
        knob = nil
        joystick = .zero
        sprinting = false
        actionDown = false
    }

    private mutating func updateKnob(_ p: CGPoint) {
        guard let o = joystickOrigin else { return }
        var dx = p.x - o.x, dy = p.y - o.y
        let r = ControlLayout.joystickRadius
        let len = hypot(dx, dy)
        if len > r { dx *= r / len; dy *= r / len }
        knob = CGPoint(x: o.x + dx, y: o.y + dy)
        let mag = min(1, len / r)
        guard len > 0, mag >= 0.15 else { joystick = .zero; return }
        joystick = CGVector(dx: dx / hypot(dx, dy) * mag, dy: -dy / hypot(dx, dy) * mag)   // screen y down → world y up
    }
}

/// Draws the controls and feeds UIKit touches into `TouchControlModel`.
final class TouchControlsView: UIView {
    var onJoystick: ((CGVector) -> Void)?
    var onSprint: ((Bool) -> Void)?
    var onAction: (() -> Void)?
    var actionAvailable = false { didSet { if oldValue != actionAvailable { setNeedsDisplay() } } }

    private var model = TouchControlModel(size: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        model.size = bounds.size
        updateAccessibility()
        setNeedsDisplay()
    }

    /// VoiceOver / UI-test elements for the drawn controls.
    private func updateAccessibility() {
        let s = bounds.size
        func element(_ label: String, center: CGPoint, radius: CGFloat, traits: UIAccessibilityTraits) -> UIAccessibilityElement {
            let e = UIAccessibilityElement(accessibilityContainer: self)
            e.accessibilityLabel = label
            e.accessibilityIdentifier = label
            e.accessibilityTraits = traits
            e.accessibilityFrameInContainerSpace = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            return e
        }
        accessibilityElements = [
            element("Styrspak", center: ControlLayout.joystickHome(in: s), radius: ControlLayout.joystickRadius, traits: .allowsDirectInteraction),
            element("Springknapp", center: ControlLayout.sprintCenter(in: s), radius: ControlLayout.sprintRadius, traits: .button),
            element("Handlingsknapp", center: ControlLayout.actionCenter(in: s), radius: ControlLayout.actionRadius, traits: .button),
        ]
    }

    /// Only claim touches on the controls; everything else falls through to the HUD/world.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        model.size = bounds.size
        return model.role(at: point) != nil
    }

    private func id(_ t: UITouch) -> Int { ObjectIdentifier(t).hashValue }

    private func publish(previousSprint: Bool) {
        onJoystick?(model.joystick)
        if model.sprinting != previousSprint {
            onSprint?(model.sprinting)
            if model.sprinting { Haptics.tap() }
        }
        setNeedsDisplay()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let sprint = model.sprinting
        for t in touches where model.began(id(t), at: t.location(in: self)) { onAction?() }
        publish(previousSprint: sprint)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let sprint = model.sprinting
        for t in touches { model.moved(id(t), to: t.location(in: self)) }
        publish(previousSprint: sprint)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { finish(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { finish(touches) }

    private func finish(_ touches: Set<UITouch>) {
        let sprint = model.sprinting
        for t in touches { model.ended(id(t)) }
        publish(previousSprint: sprint)
    }

    func releaseAll() {
        guard !model.roles.isEmpty || model.joystick != .zero || model.sprinting else { return }
        model.releaseAll()
        onJoystick?(.zero)
        onSprint?(false)
        setNeedsDisplay()
    }

    // MARK: Drawing

    private let amber = UIColor(red: 0.88, green: 0.63, blue: 0.25, alpha: 1)
    private let cream = UIColor(red: 0.94, green: 0.90, blue: 0.78, alpha: 1)

    override func draw(_ rect: CGRect) {
        let s = bounds.size
        // Joystick
        let origin = model.joystickOrigin ?? ControlLayout.joystickHome(in: s)
        let active = model.joystickOrigin != nil
        let base = UIBezierPath(ovalIn: CGRect(x: origin.x - ControlLayout.joystickRadius, y: origin.y - ControlLayout.joystickRadius,
                                               width: ControlLayout.joystickRadius * 2, height: ControlLayout.joystickRadius * 2))
        UIColor.black.withAlphaComponent(active ? 0.35 : 0.22).setFill()
        base.fill()
        amber.withAlphaComponent(active ? 0.8 : 0.4).setStroke()
        base.lineWidth = 3
        base.stroke()
        let k = model.knob ?? origin
        let knobPath = UIBezierPath(ovalIn: CGRect(x: k.x - ControlLayout.knobRadius, y: k.y - ControlLayout.knobRadius,
                                                   width: ControlLayout.knobRadius * 2, height: ControlLayout.knobRadius * 2))
        cream.withAlphaComponent(active ? 0.85 : 0.45).setFill()
        knobPath.fill()

        // Sprint
        drawButton(center: ControlLayout.sprintCenter(in: s), radius: ControlLayout.sprintRadius,
                   symbol: "figure.run", pressed: model.sprinting, glowing: false)
        // Action
        drawButton(center: ControlLayout.actionCenter(in: s), radius: ControlLayout.actionRadius,
                   symbol: "hand.point.up.left.fill", pressed: model.actionDown, glowing: actionAvailable)
    }

    private func drawButton(center: CGPoint, radius: CGFloat, symbol: String, pressed: Bool, glowing: Bool) {
        let path = UIBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        (pressed ? amber.withAlphaComponent(0.6) : UIColor.black.withAlphaComponent(glowing ? 0.55 : 0.35)).setFill()
        path.fill()
        (glowing ? amber : amber.withAlphaComponent(0.45)).setStroke()
        path.lineWidth = glowing ? 4 : 3
        path.stroke()
        let config = UIImage.SymbolConfiguration(pointSize: radius * 0.75, weight: .bold)
        if let img = UIImage(systemName: symbol, withConfiguration: config)?.withTintColor(glowing || pressed ? cream : cream.withAlphaComponent(0.6), renderingMode: .alwaysOriginal) {
            img.draw(at: CGPoint(x: center.x - img.size.width / 2, y: center.y - img.size.height / 2))
        }
    }
}

struct TouchControls: UIViewRepresentable {
    let game: GameController
    let actionAvailable: Bool

    func makeUIView(context: Context) -> TouchControlsView {
        let v = TouchControlsView()
        v.onJoystick = { [weak game] vec in game?.input.joystick = vec }
        v.onSprint = { [weak game] down in game?.input.sprinting = down }
        v.onAction = { [weak game] in
            guard let game, !game.isInputBlocked else { return }
            Haptics.tap()
            game.explorationScene?.tryInteract()
        }
        return v
    }

    func updateUIView(_ view: TouchControlsView, context: Context) {
        view.actionAvailable = actionAvailable
        if game.isInputBlocked { view.releaseAll() }
    }
}
