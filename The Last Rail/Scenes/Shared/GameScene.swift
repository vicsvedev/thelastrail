import SpriteKit

/// Logical resolution for world rendering: a fixed height of 270 pixels and a width that
/// matches the phone's landscape aspect ratio, so the world fills the whole screen.
enum Viewport {
    static let height: CGFloat = 270
    private(set) static var size = CGSize(width: 480, height: 270)

    static func configure(for screen: CGSize) {
        let long = max(screen.width, screen.height), short = min(screen.width, screen.height)
        guard short > 0 else { return }
        size = CGSize(width: (height * long / short).rounded(), height: height)
    }
}

/// Base scene: computes frame delta and drives the controller's main loop.
class GameScene: SKScene {
    weak var controller: GameController?
    private var lastUpdate: TimeInterval?

    init(controller: GameController?) {
        self.controller = controller
        super.init(size: Viewport.size)
        scaleMode = .aspectFill
        anchorPoint = .zero
        backgroundColor = ColorMath.skColor(Pal.night)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate.map { currentTime - $0 } ?? 0
        lastUpdate = currentTime
        let clamped = min(max(dt, 0), 0.1)
        controller?.tick(clamped)
        step(clamped)
    }

    /// Override for per-frame logic.
    func step(_ dt: Double) {}

    func label(_ text: String, size: CGFloat = 10, color: UInt32 = Pal.cream) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: "Menlo-Bold")
        l.text = text
        l.fontSize = size
        l.fontColor = ColorMath.skColor(color)
        l.verticalAlignmentMode = .center
        l.horizontalAlignmentMode = .center
        return l
    }
}

enum Effects {
    static func rain(width: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = BackgroundArt.particle(0xA8B8D0, w: 1, h: 4)
        e.particleBirthRate = 180
        e.particleLifetime = 1.4
        e.particlePositionRange = CGVector(dx: width * 1.4, dy: 0)
        e.emissionAngle = -.pi / 2 - 0.25
        e.particleSpeed = 260
        e.particleSpeedRange = 40
        e.particleAlpha = 0.55
        e.particleAlphaRange = 0.2
        e.particleRotation = -0.25
        e.particleScale = 1
        e.advanceSimulationTime(2)
        return e
    }

    static func snow(width: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = BackgroundArt.particle(0xF4F6FA, w: 2, h: 2)
        e.particleBirthRate = 45
        e.particleLifetime = 7
        e.particlePositionRange = CGVector(dx: width * 1.4, dy: 0)
        e.emissionAngle = -.pi / 2 - 0.3
        e.emissionAngleRange = 0.4
        e.particleSpeed = 40
        e.particleSpeedRange = 15
        e.particleAlpha = 0.85
        e.particleAlphaRange = 0.15
        e.particleScaleRange = 0.5
        e.xAcceleration = -4
        e.advanceSimulationTime(8)
        return e
    }

    static func dust(width: CGFloat, height: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = BackgroundArt.particle(0xD8C8A8, w: 1, h: 1)
        e.particleBirthRate = 14
        e.particleLifetime = 9
        e.particlePositionRange = CGVector(dx: width, dy: height)
        e.emissionAngle = 0.1
        e.emissionAngleRange = 0.6
        e.particleSpeed = 9
        e.particleAlpha = 0.5
        e.particleAlphaSpeed = -0.05
        e.advanceSimulationTime(9)
        return e
    }

    static func smoke() -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = BackgroundArt.smokePuff()
        e.particleBirthRate = 9
        e.particleLifetime = 3.2
        e.emissionAngle = .pi / 2
        e.emissionAngleRange = 0.3
        e.particleSpeed = 22
        e.particleSpeedRange = 8
        e.particleAlpha = 0.45
        e.particleAlphaSpeed = -0.14
        e.particleScale = 0.4
        e.particleScaleSpeed = 0.45
        e.particleColorBlendFactor = 1
        e.particleColor = ColorMath.skColor(0x9A9AA6)
        return e
    }

    static func fog(in size: CGSize, count: Int = 6, alpha: CGFloat = 0.25) -> SKNode {
        let node = SKNode()
        for i in 0..<count {
            let s = SKSpriteNode(texture: BackgroundArt.fogBank())
            s.setScale(CGFloat.random(in: 1.8...3.2))
            s.alpha = alpha
            s.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat(i) / CGFloat(count) * size.height)
            let drift = CGFloat.random(in: 6...14)
            let move = SKAction.customAction(withDuration: 1000) { n, _ in
                n.position.x += drift / 60
                if n.position.x > size.width + 200 { n.position.x = -200 }
            }
            s.run(.repeatForever(move))
            node.addChild(s)
        }
        return node
    }
}
