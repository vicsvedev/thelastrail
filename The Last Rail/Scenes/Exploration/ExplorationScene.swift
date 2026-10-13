import SpriteKit

/// Top-down exploration of a station. Rules live in `InteractionSystem`; this scene renders,
/// moves the player with tile collision and reports events to the controller.
final class ExplorationScene: GameScene {
    let layout: StationLayout
    let region: Region
    private let tile: CGFloat = 16
    private let world = SKNode()
    private let cam = SKCameraNode()
    private let player = SKSpriteNode(texture: CharacterSprites.texture(.down, frame: 0))
    private var objectNodes: [String: SKSpriteNode] = [:]
    private var roofNodes: [String: SKSpriteNode] = [:]
    private let trainNode = SKNode()
    private var trainRect = CGRect.zero
    private var smoke: SKEmitterNode?
    private let darkness = SKNode()
    private var darknessMask: SKSpriteNode?
    private var darknessEdges: [(SKSpriteNode, CGFloat, CGFloat)] = []
    private var facing: Facing = .down
    private var animTime: Double = 0
    private var stepTimer: Double = 0
    private var hurtTimer: Double = 0
    private var time: Double = 0
    private var activeZones: Set<String> = []
    private var currentTarget: Target?
    private let startPosition: CGPoint?

    private enum Target: Equatable {
        case object(String)
        case train
    }

    init(layout: StationLayout, controller: GameController, start: CGPoint?) {
        self.layout = layout
        self.region = WorldCatalog.station(layout.station).region
        self.startPosition = start
        super.init(controller: controller)
        build()
    }

    required init?(coder: NSCoder) { fatalError() }

    var playerPosition: CGPoint { player.position }
    private var state: GameState { controller?.state ?? GameState() }

    // MARK: Coordinates

    func center(_ p: TilePoint) -> CGPoint {
        CGPoint(x: CGFloat(p.col) * tile + 8, y: CGFloat(layout.height - 1 - p.row) * tile + 8)
    }

    private func tilePoint(_ pt: CGPoint) -> TilePoint {
        TilePoint(col: Int(floor(pt.x / tile)), row: layout.height - 1 - Int(floor(pt.y / tile)))
    }

    private func rect(of p: TilePoint) -> CGRect {
        CGRect(x: CGFloat(p.col) * tile, y: CGFloat(layout.height - 1 - p.row) * tile, width: tile, height: tile)
    }

    // MARK: Build

    private func build() {
        addChild(world)
        camera = cam
        addChild(cam)
        // Closer than the train view so the character reads well on a phone.
        cam.setScale(ExplorationScene.cameraScale)

        let baked = TileArt.bake(layout, region: region)
        let ground = SKSpriteNode(texture: baked.ground.texture())
        ground.anchorPoint = .zero
        ground.zPosition = 0
        world.addChild(ground)
        let overlay = SKSpriteNode(texture: baked.overlay.texture())
        overlay.anchorPoint = CGPoint(x: 0, y: 0)
        overlay.position = CGPoint(x: 0, y: -tile)
        overlay.zPosition = 40
        world.addChild(overlay)

        for row in 0..<layout.height {
            for col in 0..<layout.width where layout.tile(col, row) == .lampPost {
                let glow = SKSpriteNode(texture: BackgroundArt.softGlow(Pal.amberLight))
                glow.blendMode = .add
                glow.alpha = 0.5
                glow.setScale(1.6)
                glow.position = CGPoint(x: CGFloat(col) * tile + 8, y: CGFloat(layout.height - 1 - row) * tile + 13)
                glow.zPosition = 45
                glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.35, duration: 1.7), .fadeAlpha(to: 0.55, duration: 1.3)])))
                world.addChild(glow)
            }
        }

        buildTrain()
        for obj in layout.objects { makeObjectNode(obj) }

        for b in layout.buildings {
            let roof = SKSpriteNode(texture: roofTexture(b))
            roof.anchorPoint = .zero
            let r = rect(of: TilePoint(col: b.rect.col, row: b.rect.row + b.rect.height - 1))
            roof.position = CGPoint(x: r.minX, y: r.minY)
            roof.zPosition = 50
            roofNodes[b.id] = roof
            world.addChild(roof)
        }

        player.anchorPoint = CGPoint(x: 0.5, y: 0.1)
        player.zPosition = 30
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 10, height: 4))
        shadow.fillColor = SKColor.black.withAlphaComponent(0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: 1)
        shadow.zPosition = -1
        player.addChild(shadow)
        player.position = startPosition.flatMap { isBlocked(hitbox(at: $0)) ? nil : $0 } ?? spawnPoint()
        world.addChild(player)

        buildDarkness()
        buildWeather()
        updateRoofs(instant: true)
        updateDarkness(instant: true)
        cam.position = clampedCamera(player.position)
    }

    private func spawnPoint() -> CGPoint {
        let c = center(layout.spawn)
        return CGPoint(x: c.x, y: c.y - 4)
    }

    private func roofTexture(_ b: BuildingDef) -> SKTexture {
        let w = b.rect.width * 16, h = b.rect.height * 16
        let c = PixelCanvas(w, h)
        let base = b.roofColor
        c.fill(0, 0, w, h, Pal.outline)
        c.fill(1, 1, w - 2, h - 3, base)
        for y in stride(from: 4, to: h - 3, by: 4) { c.hline(1, w - 2, y, ColorMath.shade(base, -0.18)) }
        for y in stride(from: 2, to: h - 3, by: 8) {
            for x in stride(from: (y / 8) % 2 == 0 ? 6 : 12, to: w - 2, by: 12) { c.vline(x, y, y + 1, ColorMath.shade(base, -0.25)) }
        }
        c.hline(1, w - 2, 1, ColorMath.shade(base, 0.2))
        c.hline(1, w - 2, h / 2, ColorMath.shade(base, 0.12))
        c.fill(0, h - 3, w, 3, ColorMath.shade(base, -0.45))
        if region == .mountain { for x in 1..<(w - 1) where (x / 3) % 4 != 0 { c.vline(x, 1, 3, 0xEEF2F8) } }
        var rng = SeededRandom(seed: UInt64(w * 31 + h))
        for _ in 0..<(w * h / 90) { c.set(rng.int(2...(w - 3)), rng.int(2...(h - 5)), ColorMath.shade(base, rng.chance(0.5) ? 0.1 : -0.3)) }
        return c.texture()
    }

    private func buildTrain() {
        trainNode.removeAllChildren()
        trainNode.removeFromParent()
        let s = state
        let lit = s.train.locomotiveRepaired
        let front = center(layout.trainFront)
        let right = front.x + 8
        let y = front.y
        let loco = SKSpriteNode(texture: TrainSprites.topLocomotive(lit: lit))
        loco.position = CGPoint(x: right - 32, y: y)
        trainNode.addChild(loco)
        var left = right - 64
        for wagon in s.train.wagons {
            let w = SKSpriteNode(texture: TrainSprites.topWagon(wagon.type, hasBench: wagon.modules.contains(.workshopBench)))
            let wRight = left - 4
            w.position = CGPoint(x: wRight - 28, y: y)
            trainNode.addChild(w)
            let coupler = SKSpriteNode(color: ColorMath.skColor(0x2A2A2A), size: CGSize(width: 6, height: 2))
            coupler.position = CGPoint(x: left - 2, y: y)
            trainNode.addChild(coupler)
            left = wRight - 56
        }
        trainRect = CGRect(x: left, y: y - 7, width: right - left, height: 14)
        trainNode.zPosition = 25
        world.addChild(trainNode)
        if lit {
            let e = Effects.smoke()
            e.position = CGPoint(x: right - 20, y: y + 2)
            e.targetNode = world
            e.particleBirthRate = 4
            e.zPosition = 46
            trainNode.addChild(e)
            smoke = e
            let lamp = SKSpriteNode(texture: BackgroundArt.softGlow(0xF8E8A0))
            lamp.blendMode = .add
            lamp.alpha = 0.55
            lamp.setScale(1.3)
            lamp.position = CGPoint(x: right + 10, y: y)
            lamp.zPosition = 45
            trainNode.addChild(lamp)
        }
    }

    func refreshTrain() { buildTrain() }

    private func makeObjectNode(_ obj: MapObjectDef) {
        let node = SKSpriteNode(texture: ObjectSprites.texture(obj.look, region: region))
        node.position = center(obj.at)
        node.zPosition = obj.look == .darkness ? 48 : 20
        if case .barrier = obj.kind { node.setScale(1.05) }
        objectNodes[obj.id] = node
        world.addChild(node)
        refreshObject(obj.id)
    }

    func refreshObject(_ id: String) {
        guard let obj = layout.object(id), let node = objectNodes[id] else { return }
        let s = state
        let exists = InteractionSystem.exists(obj, s)
        let active = InteractionSystem.isActive(obj, station: layout.station, s)
        node.removeAction(forKey: "sparkle")
        node.childNode(withName: "sparkle")?.removeFromParent()
        switch obj.kind {
        case .resource, .blueprint, .keyItem:
            node.isHidden = !(exists && active)
            if exists && active && obj.secret == nil { addSparkle(node) }
        case .container:
            node.isHidden = !exists
            node.texture = ObjectSprites.texture(obj.look, open: !active, region: region)
            if exists && active && obj.secret == nil { addSparkle(node) }
        case .door:
            node.texture = ObjectSprites.texture(obj.look, open: !active, region: region)
        case .barrier:
            if !active && !node.isHidden {
                node.run(.sequence([.fadeOut(withDuration: 0.6), .hide()]))
            } else {
                node.isHidden = !active
                node.alpha = 1
            }
        case .machine(let kind):
            let on: Bool
            switch kind {
            case .signalBox: on = s.has(.junctionSwitched)
            case .generator: on = s.has(.nordpassetGeneratorOn)
            case .radioTerminal: on = s.has(.nordpassetGeneratorOn)
            case .depotRadio: on = true
            }
            node.texture = ObjectSprites.texture(obj.look, open: on, region: region)
            if kind == .generator && on, node.childNode(withName: "smoke") == nil {
                let e = Effects.smoke()
                e.name = "smoke"
                e.particleBirthRate = 3
                e.position = CGPoint(x: 5, y: 8)
                e.targetNode = world
                node.addChild(e)
            }
        case .note, .sign:
            node.isHidden = false
        }
    }

    func refreshAllObjects() {
        for obj in layout.objects { refreshObject(obj.id) }
    }

    private func addSparkle(_ node: SKSpriteNode) {
        let spark = SKSpriteNode(texture: BackgroundArt.particle(0xFFF4C0, w: 1, h: 1))
        spark.name = "sparkle"
        spark.zPosition = 1
        spark.alpha = 0
        spark.position = CGPoint(x: 4, y: 5)
        let blink = SKAction.sequence([
            .wait(forDuration: Double.random(in: 0.5...2.5)),
            .run { spark.position = CGPoint(x: CGFloat.random(in: -5...5), y: CGFloat.random(in: -2...6)) },
            .fadeIn(withDuration: 0.12), .scale(to: 2, duration: 0.12), .fadeOut(withDuration: 0.3), .scale(to: 1, duration: 0),
        ])
        spark.run(.repeatForever(blink))
        node.addChild(spark)
    }

    private func buildDarkness() {
        guard !layout.darkAreas.isEmpty else { return }
        let mask = SKSpriteNode(texture: BackgroundArt.darknessMask())
        darknessMask = mask
        darkness.addChild(mask)
        let black = ColorMath.skColor(0x05040A, alpha: 0.98)
        for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
            let r = SKSpriteNode(color: black, size: CGSize(width: 2000, height: 2000))
            darknessEdges.append((r, CGFloat(dx), CGFloat(dy)))
            darkness.addChild(r)
        }
        darkness.zPosition = 60
        darkness.alpha = 0
        world.addChild(darkness)
        layoutDarkness()
    }

    private var lightScale: CGFloat { state.inventory.has(.headlamp) ? 3.0 : 1.25 }

    private func layoutDarkness() {
        guard let mask = darknessMask else { return }
        let s = lightScale
        mask.setScale(s)
        let half = 128 * s
        for (edge, dx, dy) in darknessEdges {
            edge.position = CGPoint(x: dx * (half + 1000), y: dy * (half + 1000))
            edge.size = dx != 0 ? CGSize(width: 2000, height: 2000 + half * 2) : CGSize(width: half * 2, height: 2000)
        }
    }

    private func buildWeather() {
        let size = Viewport.size
        switch layout.weather {
        case .rain:
            let e = Effects.rain(width: size.width)
            e.position = CGPoint(x: 0, y: size.height / 2 + 10)
            e.zPosition = 70
            cam.addChild(e)
        case .snow:
            let e = Effects.snow(width: size.width)
            e.position = CGPoint(x: 0, y: size.height / 2 + 10)
            e.zPosition = 70
            cam.addChild(e)
        case .fog:
            let f = Effects.fog(in: size, count: 5, alpha: 0.12)
            f.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
            f.zPosition = 70
            cam.addChild(f)
        case .dust:
            let e = Effects.dust(width: size.width, height: size.height)
            e.zPosition = 70
            cam.addChild(e)
        case .none:
            break
        }
        // A subtle vignette tint per region for atmosphere.
        let tint = SKSpriteNode(color: ColorMath.skColor(regionTint), size: CGSize(width: size.width + 4, height: size.height + 4))
        tint.alpha = 0.10
        tint.zPosition = 69
        tint.blendMode = .alpha
        cam.addChild(tint)
    }

    private var regionTint: UInt32 {
        switch region {
        case .depot: return 0xE0A040
        case .forest: return 0x3A5068
        case .industrial: return 0x8A5030
        case .mine: return 0x14161C
        case .mountain: return 0xA8C0E0
        }
    }

    // MARK: Collision

    private func hitbox(at p: CGPoint) -> CGRect {
        CGRect(x: p.x - 5, y: p.y - 1, width: 10, height: 6)
    }

    private func isBlocked(_ r: CGRect) -> Bool {
        let minC = Int(floor(r.minX / tile)), maxC = Int(floor((r.maxX - 0.01) / tile))
        let minYi = Int(floor(r.minY / tile)), maxYi = Int(floor((r.maxY - 0.01) / tile))
        for yi in minYi...maxYi {
            let row = layout.height - 1 - yi
            for col in minC...maxC where layout.tile(col, row).isSolid { return true }
        }
        if r.intersects(trainRect) { return true }
        let s = state
        for obj in layout.objects where InteractionSystem.blocksMovement(obj, station: layout.station, s) {
            let orect = rect(of: obj.at).insetBy(dx: 1, dy: 1)
            if r.intersects(orect) { return true }
        }
        return false
    }

    // MARK: Frame

    override func step(_ dt: Double) {
        time += dt
        guard let controller else { return }
        let frozen = controller.isInputBlocked
        var moved = false
        if !frozen {
            moved = movePlayer(dt, controller: controller)
            updateTarget(controller)
            applyHazards(dt, controller: controller)
            checkZones(controller)
        } else if controller.prompt != nil, controller.topOverlay != nil || !controller.dialogs.isEmpty {
            // keep prompt; nothing
        }
        animate(moved: moved, dt: dt)
        updateRoofs(instant: false)
        updateDarkness(instant: false)
        let target = clampedCamera(player.position)
        cam.position = CGPoint(x: cam.position.x + (target.x - cam.position.x) * min(1, CGFloat(dt) * 8),
                               y: cam.position.y + (target.y - cam.position.y) * min(1, CGFloat(dt) * 8))
        player.zPosition = 30
    }

    private func movePlayer(_ dt: Double, controller: GameController) -> Bool {
        let v = controller.input.movement
        guard v != .zero else { return false }
        let sprinting = controller.input.shift
        let speed: CGFloat = sprinting ? 118 : 72
        let dx = v.dx * speed * CGFloat(dt), dy = v.dy * speed * CGFloat(dt)
        let old = player.position
        var p = old
        if dx != 0, !isBlocked(hitbox(at: CGPoint(x: p.x + dx, y: p.y))) { p.x += dx }
        if dy != 0, !isBlocked(hitbox(at: CGPoint(x: p.x, y: p.y + dy))) { p.y += dy }
        if abs(v.dx) > abs(v.dy) { facing = v.dx < 0 ? .left : .right } else { facing = v.dy < 0 ? .down : .up }
        player.position = p
        let dist = hypot(p.x - old.x, p.y - old.y)
        if dist > 0 {
            controller.playerMoved(distance: Double(dist))
            stepTimer -= dt
            if stepTimer <= 0 {
                stepTimer = sprinting ? 0.24 : 0.33
                controller.sound.play(.footstep, volume: 0.35)
            }
        }
        return dist > 0.01
    }

    private func animate(moved: Bool, dt: Double) {
        if moved {
            animTime += dt * (controller?.input.shift == true ? 11 : 8)
            let seq = [1, 0, 2, 0]
            player.texture = CharacterSprites.texture(facing, frame: seq[Int(animTime) % 4])
        } else {
            animTime = 0
            player.texture = CharacterSprites.texture(facing, frame: 0)
        }
    }

    private func updateTarget(_ controller: GameController) {
        let s = controller.state
        let feet = CGPoint(x: player.position.x, y: player.position.y + 4)
        var best: (Target, CGFloat, String)?
        for obj in layout.objects {
            guard let text = InteractionSystem.prompt(obj, station: layout.station, s) else { continue }
            let c = center(obj.at)
            let d = hypot(c.x - feet.x, c.y - feet.y)
            if d < 22, d < (best?.1 ?? .infinity) { best = (.object(obj.id), d, text) }
        }
        let dx = max(trainRect.minX - feet.x, 0, feet.x - trainRect.maxX)
        let dy = max(trainRect.minY - feet.y, 0, feet.y - trainRect.maxY)
        let trainDist = hypot(dx, dy)
        if trainDist < 16, trainDist < (best?.1 ?? .infinity) {
            let text: String
            if s.train.locomotiveRepaired { text = "Gå ombord på tåget" }
            else if s.tutorial.isActive && s.tutorial.step <= .investigateLocomotive { text = "Undersök loket" }
            else { text = "Reparera loket" }
            best = (.train, trainDist, text)
        }
        currentTarget = best?.0
        let prompt = best.map { $0.2 }
        if controller.prompt != prompt { controller.prompt = prompt }
    }

    func tryInteract() {
        guard let controller, !controller.isInputBlocked, let target = currentTarget else { return }
        switch target {
        case .train:
            controller.interactWithTrain()
        case .object(let id):
            if let obj = layout.object(id) { controller.interact(with: obj) }
        }
    }

    private func applyHazards(_ dt: Double, controller: GameController) {
        let t = tilePoint(player.position)
        let kind = layout.tile(t.col, t.row)
        var dps = kind.hazardDamage
        if kind == .vent {
            let phase = (time + Double(t.col) * 0.7).truncatingRemainder(dividingBy: 3)
            dps = phase < 1.2 ? dps : 0
        }
        guard dps > 0 else { hurtTimer = 0; return }
        controller.hazardDamage(dps * dt)
        hurtTimer -= dt
        if hurtTimer <= 0 {
            hurtTimer = 0.6
            controller.sound.play(.damage, volume: 0.6)
            player.run(.sequence([.colorize(with: .red, colorBlendFactor: 0.7, duration: 0.05), .colorize(withColorBlendFactor: 0, duration: 0.2)]))
            if controller.settings.screenShake { shake(2) }
            if kind == .fallingRocks { dropPebble(near: player.position) }
            if kind == .vent { puffSteam(at: center(t)) }
        }
    }

    private func checkZones(_ controller: GameController) {
        let t = tilePoint(player.position)
        var now: Set<String> = []
        for z in layout.zones where z.rect.contains(t) {
            now.insert(z.id)
            if !activeZones.contains(z.id) { controller.enteredZone(z) }
        }
        activeZones = now
    }

    private func updateRoofs(instant: Bool) {
        let t = tilePoint(player.position)
        for b in layout.buildings {
            guard let roof = roofNodes[b.id] else { continue }
            let inside = b.rect.contains(t)
            let target: CGFloat = inside ? 0 : 1
            if instant { roof.alpha = target } else { roof.alpha += (target - roof.alpha) * 0.18 }
        }
    }

    private func updateDarkness(instant: Bool) {
        guard darknessMask != nil else { return }
        let t = tilePoint(player.position)
        let inDark = layout.darkAreas.contains { $0.contains(t) }
        darkness.position = CGPoint(x: player.position.x, y: player.position.y + 6)
        let target: CGFloat = inDark ? 1 : 0
        if instant { darkness.alpha = target } else { darkness.alpha += (target - darkness.alpha) * 0.08 }
        let wanted = lightScale
        if let mask = darknessMask, abs(mask.xScale - wanted) > 0.01 { layoutDarkness() }
        if controller?.inDarkness != inDark { controller?.inDarkness = inDark }
    }

    static let cameraScale: CGFloat = 0.8

    private func clampedCamera(_ p: CGPoint) -> CGPoint {
        let w = CGFloat(layout.width) * tile, h = CGFloat(layout.height) * tile
        let viewW = size.width * cam.xScale, viewH = size.height * cam.yScale
        let hw = viewW / 2, hh = viewH / 2
        let x = w <= viewW ? w / 2 : min(max(p.x, hw), w - hw)
        let y = h <= viewH ? h / 2 : min(max(p.y, hh), h - hh)
        return CGPoint(x: x.rounded(), y: y.rounded())
    }

    // MARK: Effects

    func floatText(_ text: String, at tileP: TilePoint) {
        let l = label(text, size: 9, color: Pal.amberLight)
        l.position = CGPoint(x: center(tileP).x, y: center(tileP).y + 12)
        l.zPosition = 80
        let shadow = label(text, size: 9, color: Pal.outline)
        shadow.position = CGPoint(x: 1, y: -1)
        shadow.zPosition = -1
        l.addChild(shadow)
        world.addChild(l)
        l.run(.sequence([.group([.moveBy(x: 0, y: 18, duration: 1.2), .sequence([.wait(forDuration: 0.7), .fadeOut(withDuration: 0.5)])]), .removeFromParent()]))
    }

    func shake(_ amount: CGFloat) {
        var steps: [SKAction] = []
        for i in 0..<6 {
            let dir: CGFloat = i % 2 == 0 ? 1 : -1
            let dy: CGFloat = CGFloat.random(in: -amount...amount) / 2
            steps.append(SKAction.moveBy(x: dir * amount, y: dy, duration: 0.03))
        }
        steps.append(SKAction.move(to: .zero, duration: 0.03))
        world.run(SKAction.sequence(steps))
    }

    private func dropPebble(near p: CGPoint) {
        let pebble = SKSpriteNode(texture: BackgroundArt.particle(0x7A6E62, w: 2, h: 2))
        pebble.position = CGPoint(x: p.x + CGFloat.random(in: -8...8), y: p.y + 40)
        pebble.zPosition = 47
        world.addChild(pebble)
        pebble.run(.sequence([.moveBy(x: 0, y: -36, duration: 0.3), .fadeOut(withDuration: 0.2), .removeFromParent()]))
    }

    private func puffSteam(at p: CGPoint) {
        let puff = SKSpriteNode(texture: BackgroundArt.smokePuff())
        puff.position = p
        puff.alpha = 0.7
        puff.zPosition = 46
        world.addChild(puff)
        puff.run(.sequence([.group([.moveBy(x: 0, y: 16, duration: 0.8), .scale(to: 2.5, duration: 0.8), .fadeOut(withDuration: 0.8)]), .removeFromParent()]))
    }

    func locomotiveStarted() {
        buildTrain()
        shake(3)
        for i in 0..<6 {
            let puff = SKSpriteNode(texture: BackgroundArt.smokePuff())
            puff.position = CGPoint(x: trainRect.maxX - 20, y: trainRect.midY + 4)
            puff.alpha = 0.8
            puff.zPosition = 46
            world.addChild(puff)
            puff.run(.sequence([.wait(forDuration: Double(i) * 0.15),
                                .group([.moveBy(x: CGFloat.random(in: -10...10), y: 30, duration: 1.4), .scale(to: 3, duration: 1.4), .fadeOut(withDuration: 1.4)]),
                                .removeFromParent()]))
        }
    }

    /// Development helper used by the snapshot harness.
    func debugTeleport(col: Int, row: Int) {
        player.position = CGPoint(x: CGFloat(col) * tile + 8, y: CGFloat(layout.height - 1 - row) * tile + 4)
        cam.position = clampedCamera(player.position)
    }

    func respawnAtTrain() {
        player.position = spawnPoint()
        cam.position = clampedCamera(player.position)
        player.run(.sequence([.fadeAlpha(to: 0.2, duration: 0), .fadeIn(withDuration: 0.8)]))
    }
}
