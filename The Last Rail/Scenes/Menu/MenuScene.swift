import SpriteKit

/// Animated main menu backdrop: a locomotive waiting at an abandoned station at dusk.
final class MenuScene: GameScene {
    private var clouds: [SKSpriteNode] = []

    init() {
        super.init(controller: nil)
        build()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        let region = Region.depot
        let sky = SKSpriteNode(texture: BackgroundArt.sky(region))
        sky.anchorPoint = .zero
        sky.zPosition = -100
        addChild(sky)
        for i in 0..<4 {
            let c = SKSpriteNode(texture: BackgroundArt.cloud(i + 2))
            c.alpha = 0.32
            c.colorBlendFactor = 0.4
            c.color = ColorMath.skColor(0xE09A5A)
            c.position = CGPoint(x: CGFloat(i) * 150 + 40, y: CGFloat([200, 230, 185, 215][i]))
            c.zPosition = -95
            addChild(c)
            clouds.append(c)
        }
        // Background strips are 480 px wide and seamless, so tile them across any screen width.
        func strip(_ tex: SKTexture, y: CGFloat, z: CGFloat, alpha: CGFloat = 1) {
            var x: CGFloat = 0
            while x < size.width {
                let s = SKSpriteNode(texture: tex)
                s.anchorPoint = .zero
                s.position = CGPoint(x: x, y: y)
                s.zPosition = z
                s.alpha = alpha
                addChild(s)
                x += tex.size().width
            }
        }
        strip(BackgroundArt.farMountains(.mountain), y: 70, z: -90, alpha: 0.8)
        strip(BackgroundArt.midHills(.forest), y: 40, z: -80)
        strip(BackgroundArt.treeLine(.forest), y: 30, z: -70)
        strip(BackgroundArt.groundStrip(.forest), y: -10, z: -60)
        let railY: CGFloat = 46
        for i in 0..<(Int(size.width / 64) + 2) {
            let t = SKSpriteNode(texture: BackgroundArt.track())
            t.anchorPoint = .zero
            t.position = CGPoint(x: CGFloat(i) * 64, y: railY - 16)
            t.zPosition = -50
            addChild(t)
        }
        strip(BackgroundArt.platform(), y: railY + 1, z: -45)
        // The station + train composition is designed for 480 px and centred on wider screens.
        let stage = SKNode()
        stage.position.x = ((size.width - 480) / 2).rounded()
        addChild(stage)
        let building = SKSpriteNode(texture: BackgroundArt.stationBuilding(.forest))
        building.anchorPoint = CGPoint(x: 0.5, y: 0)
        building.position = CGPoint(x: 120, y: railY + 10)
        building.zPosition = -46
        stage.addChild(building)
        for x in [62.0, 176.0, 330.0] {
            let glow = SKSpriteNode(texture: BackgroundArt.softGlow(Pal.amberLight))
            glow.blendMode = .add
            glow.alpha = 0.4
            glow.setScale(1.5)
            glow.position = CGPoint(x: CGFloat(x), y: railY + 46)
            glow.zPosition = -44
            glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.28, duration: 2.1), .fadeAlpha(to: 0.45, duration: 1.6)])))
            stage.addChild(glow)
        }
        let wagon = SKSpriteNode(texture: TrainSprites.sideWagon(.cargo, hasBench: true))
        wagon.anchorPoint = .zero
        wagon.position = CGPoint(x: 232, y: railY + 2)
        stage.addChild(wagon)
        let loco = SKSpriteNode(texture: TrainSprites.sideLocomotive(lit: true))
        loco.anchorPoint = .zero
        loco.position = CGPoint(x: 320, y: railY)
        stage.addChild(loco)
        for (car, xs, dy) in [(loco, [12.0, 28.0, 72.0, 88.0], 0.0), (wagon, [10.0, 24.0, 60.0, 74.0], -2.0)] {
            for x in xs {
                let w = SKSpriteNode(texture: TrainSprites.wheel(frame: 0))
                w.position = CGPoint(x: CGFloat(x), y: 6 + CGFloat(dy))
                car.addChild(w)
            }
        }
        for (x, y) in [(13.0, 30.0), (25.0, 30.0)] {
            let g = SKSpriteNode(texture: BackgroundArt.softGlow(Pal.amberLight, radius: 16))
            g.blendMode = .add
            g.alpha = 0.6
            g.setScale(1.3)
            g.position = CGPoint(x: x, y: y)
            loco.addChild(g)
        }
        let lamp = SKSpriteNode(texture: BackgroundArt.softGlow(0xF8F0C0))
        lamp.blendMode = .add
        lamp.alpha = 0.5
        lamp.position = CGPoint(x: 112, y: 25)
        lamp.xScale = 2.2
        lamp.yScale = 0.8
        loco.addChild(lamp)
        let smoke = Effects.smoke()
        smoke.position = CGPoint(x: 73, y: 44)
        smoke.particleBirthRate = 3
        smoke.xAcceleration = -3
        smoke.targetNode = self
        loco.addChild(smoke)
        let figure = SKSpriteNode(texture: CharacterSprites.smallSide())
        figure.anchorPoint = CGPoint(x: 0.5, y: 0)
        figure.position = CGPoint(x: 205, y: railY + 11)
        figure.zPosition = 1
        stage.addChild(figure)
        let dust = Effects.dust(width: size.width, height: size.height)
        dust.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dust.zPosition = 50
        addChild(dust)
        let fog = Effects.fog(in: size, count: 4, alpha: 0.1)
        fog.zPosition = -65
        addChild(fog)
    }

    override func step(_ dt: Double) {
        for c in clouds {
            c.position.x -= CGFloat(dt) * 5
            if c.position.x < -60 { c.position.x = size.width + 60 }
        }
    }
}
