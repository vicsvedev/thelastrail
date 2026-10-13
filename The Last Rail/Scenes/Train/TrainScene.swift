import SpriteKit
import UIKit

/// Side view of the whole train. Stopped at a station it shows the platform; travelling it
/// scrolls region-specific parallax layers.
final class TrainScene: GameScene {
    private let cam = SKCameraNode()
    private let backdrop = SKNode()          // attached to camera: sky + clouds
    private let world = SKNode()
    private var layers: [ParallaxLayer] = []
    private let trainNode = SKNode()
    private var wheels: [SKSpriteNode] = []
    private var carNodes: [SKNode] = []
    private let stationSet = SKNode()
    private var stationSign: SKLabelNode?
    private var smoke: SKEmitterNode?
    private var headlamp: SKSpriteNode?
    private var weatherNode: SKNode?
    private var region: Region = .depot
    private var trainSpeed: CGFloat = 0
    private var distanceScrolled: CGFloat = 0
    private var wheelPhase: CGFloat = 0
    private var time: Double = 0
    private var zoom: CGFloat = 1
    private var pan: CGFloat = 0
    private var trainWidth: CGFloat = 0
    private let railY: CGFloat = 64
    static let maxSpeed: CGFloat = 150

    init(controller: GameController) {
        super.init(controller: controller)
        addChild(cam)
        camera = cam
        cam.addChild(backdrop)
        addChild(world)
        rebuild()
    }

    required init?(coder: NSCoder) { fatalError() }

    private var state: GameState { controller?.state ?? GameState() }

    // MARK: Build

    func rebuild() {
        let s = state
        if let j = s.journey {
            region = WorldCatalog.route(j.routeID).region
        } else {
            region = WorldCatalog.station(s.currentStation).region
        }
        buildBackground()
        if let j = s.journey {
            buildStationSet(for: j.from)
            stationSet.position.x = -3000
        } else {
            buildStationSet(for: s.currentStation)
            stationSet.position.x = 0
        }
        buildTrain()
        if s.journey == nil { trainSpeed = 0 }
        fitZoom()
    }

    private func buildBackground() {
        backdrop.removeAllChildren()
        layers.forEach { $0.node.removeFromParent() }
        layers.removeAll()
        let pal = RegionPalette.of(region)
        world.childNode(withName: "groundbase")?.removeFromParent()
        let groundBase = SKSpriteNode(color: ColorMath.skColor(pal.nearLand), size: CGSize(width: 6000, height: 600))
        groundBase.anchorPoint = CGPoint(x: 0.5, y: 1)
        groundBase.position = CGPoint(x: 0, y: 0)
        groundBase.zPosition = -61
        groundBase.name = "groundbase"
        world.addChild(groundBase)
        let sky = SKSpriteNode(texture: BackgroundArt.sky(region))
        sky.zPosition = -100
        backdrop.addChild(sky)
        for i in 0..<4 {
            let cloud = SKSpriteNode(texture: BackgroundArt.cloud(i))
            cloud.alpha = region == .forest || region == .industrial ? 0.55 : 0.35
            cloud.colorBlendFactor = 0.35
            cloud.color = ColorMath.skColor(RegionPalette.of(region).skyHorizon)
            cloud.position = CGPoint(x: CGFloat(i) * 140 - 220, y: CGFloat([90, 110, 70, 100][i]))
            cloud.zPosition = -95
            cloud.name = "cloud"
            backdrop.addChild(cloud)
        }
        func add(_ tex: SKTexture, y: CGFloat, factor: CGFloat, z: CGFloat, tile: CGFloat = 480) {
            let layer = ParallaxLayer(texture: tex, tileWidth: tile, y: y, factor: factor)
            layer.node.zPosition = z
            world.addChild(layer.node)
            layers.append(layer)
        }
        add(BackgroundArt.farMountains(region), y: 92, factor: 0.05, z: -90)
        add(BackgroundArt.midHills(region), y: 58, factor: 0.16, z: -80)
        add(BackgroundArt.treeLine(region), y: 50, factor: 0.42, z: -70)
        add(BackgroundArt.groundStrip(region), y: -10, factor: 1.0, z: -60)
        add(BackgroundArt.track(), y: railY - 16, factor: 1.0, z: -50, tile: 64)
        // Telegraph poles behind the track.
        let poles = ParallaxLayer(texture: nil, tileWidth: 480, y: railY - 2, factor: 0.8)
        for x in [60, 300] {
            let p = SKSpriteNode(texture: BackgroundArt.pole())
            p.anchorPoint = CGPoint(x: 0.5, y: 0)
            p.position = CGPoint(x: CGFloat(x), y: 0)
            poles.addToTiles(p)
        }
        poles.node.zPosition = -55
        world.addChild(poles.node)
        layers.append(poles)

        weatherNode?.removeFromParent()
        let w = SKNode()
        switch region {
        case .forest:
            let e = Effects.rain(width: Viewport.size.width)
            e.position = CGPoint(x: 0, y: 150)
            w.addChild(e)
        case .mountain:
            let e = Effects.snow(width: Viewport.size.width)
            e.position = CGPoint(x: 0, y: 150)
            w.addChild(e)
        case .industrial, .mine:
            let f = Effects.fog(in: Viewport.size, count: 4, alpha: 0.14)
            f.position = CGPoint(x: -240, y: -135)
            w.addChild(f)
        case .depot:
            let e = Effects.dust(width: Viewport.size.width, height: Viewport.size.height)
            w.addChild(e)
        }
        w.zPosition = 60
        cam.addChild(w)
        weatherNode = w
    }

    private var stationSetFor: StationID?

    private func buildStationSet(for station: StationID) {
        stationSetFor = station
        stationSet.removeAllChildren()
        stationSet.removeFromParent()
        let info = WorldCatalog.station(station)
        let platform = SKSpriteNode(texture: BackgroundArt.platform())
        platform.anchorPoint = CGPoint(x: 0.5, y: 0)
        platform.position = CGPoint(x: 0, y: railY + 1)
        platform.setScale(1)
        platform.xScale = 1.4
        platform.zPosition = -45
        stationSet.addChild(platform)
        let building = SKSpriteNode(texture: BackgroundArt.stationBuilding(info.region))
        building.anchorPoint = CGPoint(x: 0.5, y: 0)
        building.position = CGPoint(x: -40, y: railY + 10)
        building.zPosition = -46
        stationSet.addChild(building)
        let sign = label(info.name.uppercased(), size: 7, color: Pal.cream)
        sign.position = CGPoint(x: -40, y: railY + 10 + 70 - 30.5)
        sign.zPosition = -45
        stationSet.addChild(sign)
        stationSign = sign
        for x in [-110.0, 40.0] {
            let glow = SKSpriteNode(texture: BackgroundArt.softGlow(Pal.amberLight))
            glow.blendMode = .add
            glow.alpha = 0.35
            glow.setScale(1.4)
            glow.position = CGPoint(x: CGFloat(x), y: railY + 46)
            glow.zPosition = -44
            stationSet.addChild(glow)
        }
        world.addChild(stationSet)
    }

    private func buildTrain() {
        trainNode.removeAllChildren()
        trainNode.removeFromParent()
        wheels.removeAll()
        carNodes.removeAll()
        let s = state
        let lit = s.train.locomotiveRepaired
        let gap: CGFloat = 4
        let locoW = TrainSprites.sideLocoSize.width, wagonW = TrainSprites.sideWagonSize.width
        trainWidth = locoW + CGFloat(s.train.wagons.count) * (wagonW + gap)
        // Locomotive is on the right; wagons extend left.
        var x = trainWidth / 2 - locoW
        let loco = SKSpriteNode(texture: TrainSprites.sideLocomotive(lit: lit))
        loco.anchorPoint = .zero
        loco.position = CGPoint(x: x, y: railY)
        loco.name = "loco"
        trainNode.addChild(loco)
        carNodes.append(loco)
        for wx in [12.0, 28.0, 72.0, 88.0] { addWheel(to: loco, x: CGFloat(wx)) }
        if lit {
            for (wx, wy) in [(13.0, 30.0), (25.0, 30.0)] { addGlow(to: loco, x: CGFloat(wx), y: CGFloat(wy), scale: 0.8) }
            let lamp = SKSpriteNode(texture: BackgroundArt.softGlow(0xF8F0C0, radius: 32))
            lamp.blendMode = .add
            lamp.alpha = 0.6
            lamp.position = CGPoint(x: 104, y: 25)
            lamp.xScale = 2.4
            lamp.yScale = 0.8
            loco.addChild(lamp)
            headlamp = lamp
            let e = Effects.smoke()
            e.position = CGPoint(x: 73, y: 44)
            e.targetNode = self
            e.zPosition = 5
            loco.addChild(e)
            smoke = e
        } else {
            smoke = nil
            headlamp = nil
        }
        for (i, wagon) in s.train.wagons.enumerated() {
            x -= wagonW + gap
            let w = SKSpriteNode(texture: TrainSprites.sideWagon(wagon.type, hasBench: wagon.modules.contains(.workshopBench)))
            w.anchorPoint = .zero
            w.position = CGPoint(x: x, y: railY + 2)
            w.name = "wagon-\(i)"
            trainNode.addChild(w)
            carNodes.append(w)
            for wx in [10.0, 24.0, 60.0, 74.0] { addWheel(to: w, x: CGFloat(wx), yOffset: -2) }
            let coupler = SKSpriteNode(color: ColorMath.skColor(0x2A2A2A), size: CGSize(width: gap + 2, height: 2))
            coupler.anchorPoint = .zero
            coupler.position = CGPoint(x: x + wagonW - 1, y: railY + 7)
            trainNode.addChild(coupler)
            switch wagon.type {
            case .workshop:
                for wx in [14.0, 32.0, 50.0] { addGlow(to: w, x: CGFloat(wx), y: 25, scale: 0.7) }
                addChimneySmoke(to: w, x: 62, y: 40)
            case .living:
                for wx in [13.0, 29.0, 45.0, 61.0] { addGlow(to: w, x: CGFloat(wx), y: 25, scale: 0.7) }
                addChimneySmoke(to: w, x: 72, y: 40)
            case .cargo where wagon.modules.contains(.workshopBench):
                addGlow(to: w, x: 17, y: 24, scale: 0.7)
            default: break
            }
        }
        trainNode.zPosition = 0
        world.addChild(trainNode)
    }

    private func addWheel(to car: SKNode, x: CGFloat, yOffset: CGFloat = 0) {
        let w = SKSpriteNode(texture: TrainSprites.wheel(frame: 0))
        w.position = CGPoint(x: x, y: 6 + yOffset)
        w.zPosition = 1
        car.addChild(w)
        wheels.append(w)
    }

    private func addGlow(to car: SKNode, x: CGFloat, y: CGFloat, scale: CGFloat) {
        let g = SKSpriteNode(texture: BackgroundArt.softGlow(Pal.amberLight, radius: 16))
        g.blendMode = .add
        g.alpha = 0.55
        g.setScale(scale * 1.6)
        g.position = CGPoint(x: x, y: y)
        g.zPosition = 2
        g.run(.repeatForever(.sequence([.fadeAlpha(to: 0.4, duration: Double.random(in: 1.2...2)), .fadeAlpha(to: 0.6, duration: 1.4)])))
        car.addChild(g)
    }

    private func addChimneySmoke(to car: SKNode, x: CGFloat, y: CGFloat) {
        let e = Effects.smoke()
        e.particleBirthRate = 2
        e.particleScale = 0.2
        e.position = CGPoint(x: x, y: y)
        e.targetNode = self
        car.addChild(e)
    }

    // MARK: Camera

    private func fitZoom() {
        let needed = trainWidth + 60
        zoom = max(1, needed / Viewport.size.width)
        applyCamera()
    }

    private func setZoom(_ value: CGFloat) {
        let minZoom: CGFloat = 0.6
        let maxZoom = max(1.4, (trainWidth + 80) / Viewport.size.width)
        zoom = min(maxZoom, max(minZoom, value))
        applyCamera()
    }

    private func applyCamera() {
        cam.setScale(zoom)
        // Keep the rails near the bottom of the screen at every zoom level.
        let visibleH = Viewport.size.height * zoom
        let visibleW = Viewport.size.width * zoom
        let limit = max(0, (trainWidth + 80 - visibleW) / 2)
        pan = min(limit, max(-limit, pan))
        cam.position = CGPoint(x: pan, y: railY - 40 * zoom + visibleH / 2 - 30)
        backdrop.setScale(1)
        for l in layers { l.viewWidth = visibleW }
    }

    // MARK: Journey hooks

    func journeyStarted() {
        let s = state
        guard let j = s.journey else { return }
        let newRegion = WorldCatalog.route(j.routeID).region
        distanceScrolled = 0
        if newRegion != region {
            run(.sequence([.wait(forDuration: 2.5), .run { [weak self] in self?.switchRegion(newRegion) }]))
        }
    }

    private func switchRegion(_ r: Region) {
        let fade = SKSpriteNode(color: .black, size: CGSize(width: 2000, height: 2000))
        fade.alpha = 0
        fade.zPosition = 500
        cam.addChild(fade)
        fade.run(.sequence([
            .fadeAlpha(to: 0.85, duration: 0.5),
            .run { [weak self] in
                guard let self else { return }
                self.region = r
                self.buildBackground()
                self.applyCamera()
            },
            .fadeOut(withDuration: 0.6), .removeFromParent(),
        ]))
    }

    func arrived() {
        let s = state
        let r = WorldCatalog.station(s.currentStation).region
        if r != region { region = r; buildBackground(); applyCamera() }
        buildStationSet(for: s.currentStation)
        stationSet.position.x = 0
        trainSpeed = 0
    }

    // MARK: Frame

    override func step(_ dt: Double) {
        time += dt
        let s = state
        var target: CGFloat = 0
        if let j = s.journey {
            let p = CGFloat(j.progress)
            let accel = min(1, p / 0.08)
            let decel = min(1, (1 - p) / 0.1)
            target = TrainScene.maxSpeed * max(0.08, min(accel, decel)) * CGFloat(controller?.travelSpeed ?? 1).squareRoot()
        }
        let frozen = controller?.isWorldFrozen ?? false
        trainSpeed += (target - trainSpeed) * min(1, CGFloat(dt) * 2)
        if trainSpeed < 0.5 && target == 0 { trainSpeed = 0 }
        let effective = frozen ? 0 : trainSpeed
        let dx = effective * CGFloat(dt)
        distanceScrolled += dx
        for l in layers { l.scroll(dx) }
        if let j = s.journey {
            let p = CGFloat(j.progress)
            if p > 0.9 {
                // The destination platform slides into view as we brake.
                if stationSetFor != j.to { buildStationSet(for: j.to) }
                stationSet.position.x = (1 - (p - 0.9) / 0.1) * 560
            } else {
                stationSet.position.x = max(-3000, stationSet.position.x - dx)
            }
        }
        // Clouds drift slowly even when stopped.
        for c in backdrop.children where c.name == "cloud" {
            c.position.x -= CGFloat(dt) * (4 + effective * 0.04)
            if c.position.x < -300 { c.position.x = 300 }
        }
        // Wheels & bobbing
        wheelPhase += dx / 6
        let frame = Int(wheelPhase) % 2
        for w in wheels { w.texture = TrainSprites.wheel(frame: frame) }
        for (i, car) in carNodes.enumerated() {
            let base: CGFloat = i == 0 ? railY : railY + 2
            let bob: CGFloat = effective > 10 ? (sin(CGFloat(time) * 14 + CGFloat(i)) > 0.6 ? 1 : 0) : 0
            car.position.y = base + bob
        }
        smoke?.particleBirthRate = s.train.locomotiveRepaired ? (effective > 5 ? 18 : 4) : 0
        smoke?.xAcceleration = -effective * 0.6
        headlamp?.alpha = s.journey != nil ? 0.75 : 0.35
    }

    // MARK: Touch: pan along the train, pinch to zoom, tap to inspect

    private var gestureRecognizers: [UIGestureRecognizer] = []
    private var pinchStartZoom: CGFloat = 1

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gestureRecognizers = [pan, pinch, tap]
        gestureRecognizers.forEach(view.addGestureRecognizer)
    }

    override func willMove(from view: SKView) {
        gestureRecognizers.forEach(view.removeGestureRecognizer)
        gestureRecognizers.removeAll()
        super.willMove(from: view)
    }

    private var gesturesAllowed: Bool { controller.map { !$0.isInputBlocked && $0.screen == .train } ?? false }

    /// Scene units per screen point at the current zoom.
    private func sceneUnitsPerPoint(_ view: UIView) -> CGFloat {
        guard view.bounds.width > 0 else { return 1 }
        return Viewport.size.width * zoom / view.bounds.width
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        guard gesturesAllowed, let view = g.view else { return }
        let t = g.translation(in: view)
        pan -= t.x * sceneUnitsPerPoint(view)
        g.setTranslation(.zero, in: view)
        applyCamera()
    }

    @objc private func handlePinch(_ g: UIPinchGestureRecognizer) {
        guard gesturesAllowed else { return }
        if g.state == .began { pinchStartZoom = zoom }
        setZoom(pinchStartZoom / max(g.scale, 0.01))
    }

    @objc private func handleTap(_ g: UITapGestureRecognizer) {
        guard gesturesAllowed, let view = g.view, let controller else { return }
        let p = convertPoint(fromView: g.location(in: view))
        for node in nodes(at: p) {
            var n: SKNode? = node
            while let cur = n, cur.name == nil || !(cur.name!.hasPrefix("wagon") || cur.name == "loco") { n = cur.parent }
            guard let hit = n, let name = hit.name else { continue }
            hit.run(.sequence([.colorize(with: .white, colorBlendFactor: 0.3, duration: 0.05), .colorize(withColorBlendFactor: 0, duration: 0.2)]))
            Haptics.tap()
            if name == "loco" {
                controller.open(.locomotive)
            } else if let idx = Int(name.dropFirst("wagon-".count)), controller.state.train.wagons.indices.contains(idx) {
                let wagon = controller.state.train.wagons[idx]
                switch wagon.type {
                case .cargo: controller.open(wagon.modules.contains(.workshopBench) ? .crafting : .inventory)
                case .workshop: controller.open(.crafting)
                case .living: controller.rest()
                default: controller.open(.wagons)
                }
            }
            return
        }
    }
}

/// A horizontally repeating strip that scrolls at a fraction of the train speed.
final class ParallaxLayer {
    let node = SKNode()
    private var tiles: [SKNode] = []
    private let tileWidth: CGFloat
    private let factor: CGFloat
    private var offset: CGFloat = 0
    var viewWidth: CGFloat = Viewport.size.width { didSet { ensureTiles() } }

    init(texture: SKTexture?, tileWidth: CGFloat, y: CGFloat, factor: CGFloat) {
        self.tileWidth = tileWidth
        self.factor = factor
        node.position.y = y
        self.texture = texture
        ensureTiles()
    }

    private let texture: SKTexture?
    private var extras: [SKNode] = []

    private func ensureTiles() {
        let needed = Int(ceil((viewWidth * 1.6 + 400) / tileWidth)) + 2
        while tiles.count < needed {
            let t = SKNode()
            if let texture {
                let s = SKSpriteNode(texture: texture)
                s.anchorPoint = .zero
                t.addChild(s)
            }
            for e in extras { t.addChild(e.copy() as! SKNode) }
            node.addChild(t)
            tiles.append(t)
        }
        layout()
    }

    func addToTiles(_ child: SKNode) {
        extras.append(child)
        for t in tiles { t.addChild(child.copy() as! SKNode) }
    }

    func scroll(_ dx: CGFloat) {
        offset = (offset + dx * factor).truncatingRemainder(dividingBy: tileWidth)
        layout()
    }

    private func layout() {
        let total = CGFloat(tiles.count) * tileWidth
        let start = -total / 2
        for (i, t) in tiles.enumerated() {
            t.position.x = (start + CGFloat(i) * tileWidth - offset).rounded()
        }
    }
}
