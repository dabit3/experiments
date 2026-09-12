import SpriteKit
import UIKit

final class ArenaScene: SKScene {
    weak var store: GameStore?
    private let arena = SKNode()
    private let blueCar = SKNode()
    private let orangeCar = SKNode()
    private let blueGlow = SKSpriteNode()
    private let orangeGlow = SKSpriteNode()
    private let ballNode = SKNode()
    private let ballShadow = SKSpriteNode()
    private let targetRing = SKNode()
    private let playerTag = SKNode()
    private var nets: [SKNode] = []
    private var dust: SKEmitterNode?
    private var lastTime = 0.0
    private var accumulator = 0.0
    private var lastGoalCount = 0
    private var trailTick = 0
    private var idleTime = 0.0
    private let blue = UIColor(hex: 0x5FE3FF)
    private let orange = UIColor(hex: 0xFF7A55)
    private lazy var trailTextures = [
        Paint.softLight(diameter: 48, color: blue),
        Paint.softLight(diameter: 48, color: orange)
    ]

    init(store: GameStore) {
        self.store = store
        super.init(size: CGSize(width: 1100, height: 480))
        scaleMode = .resizeFill
        backgroundColor = .clear
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(arena)
        buildRooftop()
        buildGoals()
        buildLighting()
        buildCar(blueCar, glow: blueGlow, color: blue, number: "01")
        buildCar(orangeCar, glow: orangeGlow, color: orange, number: "02")
        buildBall()
        buildTarget()
        buildPlayerTag()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didChangeSize(_: CGSize) {
        let scale = min(size.width / 1040, size.height / 410)
        arena.xScale = scale
        arena.yScale = scale * 0.9
    }

    // MARK: - Rooftop

    private func buildRooftop() {
        let slab = Paint.sprite(size: CGSize(width: 1120, height: 520), scale: 2, z: 0) { ctx in
            let sideRect = CGRect(x: -512, y: -240, width: 1024, height: 448)
            let topRect = CGRect(x: -512, y: -218, width: 1024, height: 448)
            // Drop shadow onto the city below, then the slab's visible edge and top face.
            Paint.glow(
                ctx,
                Paint.rounded(topRect.offsetBy(dx: 0, dy: -16), 64),
                .black.withAlphaComponent(0.55),
                blur: 34
            )
            Paint.linear(
                ctx, Paint.rounded(sideRect, 64), [UIColor(hex: 0x0A1720), UIColor(hex: 0x132833)],
                from: CGPoint(x: 0, y: -240), to: CGPoint(x: 0, y: -200)
            )
            Paint.linear(
                ctx, Paint.rounded(topRect, 64), [UIColor(hex: 0x2A4654), UIColor(hex: 0x1B3441)],
                from: CGPoint(x: 0, y: 230), to: CGPoint(x: 0, y: -218)
            )
            Paint.stroke(
                ctx,
                Paint.rounded(topRect.insetBy(dx: 1, dy: 1), 63),
                .white.withAlphaComponent(0.09),
                width: 1.5
            )
            // Concrete paver seams.
            for x in stride(from: -384.0, through: 384.0, by: 128) {
                Paint.line(
                    ctx,
                    [CGPoint(x: x, y: -216), CGPoint(x: x, y: 228)],
                    .black.withAlphaComponent(0.13),
                    width: 1
                )
            }
            // Wall ring (rounded to match the physical bumper radius).
            let wallOuter = Paint.rounded(CGRect(x: -466, y: -201, width: 932, height: 402), 96)
            Paint.glow(ctx, wallOuter, .black.withAlphaComponent(0.45), blur: 14, fill: UIColor(hex: 0x223B47))
            Paint.linear(
                ctx, wallOuter, [UIColor(hex: 0x4A6B79), UIColor(hex: 0x2B4653)],
                from: CGPoint(x: 0, y: 201), to: CGPoint(x: 0, y: -201)
            )
            Paint.stroke(
                ctx,
                Paint.rounded(CGRect(x: -465, y: -200, width: 930, height: 400), 95),
                .white.withAlphaComponent(0.16),
                width: 1.5
            )
            // Turf.
            let turfRect = CGRect(x: -440, y: -175, width: 880, height: 350)
            let turf = Paint.rounded(turfRect, 70)
            Paint.glow(ctx, turf, .black.withAlphaComponent(0.6), blur: 10, fill: UIColor(hex: 0x1D6E64))
            Paint.linear(
                ctx, turf, [UIColor(hex: 0x33AE98), UIColor(hex: 0x1F7F71)],
                from: CGPoint(x: 0, y: 175), to: CGPoint(x: 0, y: -175)
            )
            ctx.saveGState()
            ctx.addPath(turf)
            ctx.clip()
            for index in 0 ..< 10 where index.isMultiple(of: 2) {
                ctx.setFillColor(UIColor.white.withAlphaComponent(0.045).cgColor)
                ctx.fill(CGRect(x: -440 + CGFloat(index) * 88, y: -175, width: 88, height: 350))
            }
            Paint.radial(
                ctx, nil, [.clear, .clear, .black.withAlphaComponent(0.34)],
                center: CGPoint(x: 0, y: 20), radius: 520
            )
            Paint.linear(
                ctx, turf, [.white.withAlphaComponent(0.12), .white.withAlphaComponent(0)],
                from: CGPoint(x: -440, y: 175), to: CGPoint(x: -80, y: -60)
            )
            // Team halves wash in from each goal.
            Paint.linear(
                ctx,
                turf,
                [self.blue.withAlphaComponent(0.13), self.blue.withAlphaComponent(0)],
                from: CGPoint(x: -440, y: 0),
                to: CGPoint(x: -150, y: 0)
            )
            Paint.linear(
                ctx,
                turf,
                [self.orange.withAlphaComponent(0.13), self.orange.withAlphaComponent(0)],
                from: CGPoint(x: 440, y: 0),
                to: CGPoint(x: 150, y: 0)
            )
            ctx.restoreGState()
            // Markings.
            let chalk = UIColor(hex: 0xEAFFF4).withAlphaComponent(0.62)
            Paint.stroke(ctx, Paint.rounded(turfRect.insetBy(dx: 18, dy: 18), 54), chalk, width: 2.5)
            Paint.line(ctx, [CGPoint(x: 0, y: -157), CGPoint(x: 0, y: 157)], chalk, width: 2.5)
            Paint.stroke(
                ctx,
                CGPath(ellipseIn: CGRect(x: -64, y: -64, width: 128, height: 128), transform: nil),
                chalk,
                width: 2.5
            )
            Paint.fill(ctx, CGPath(ellipseIn: CGRect(x: -5, y: -5, width: 10, height: 10), transform: nil), chalk)
            for side in [-1.0, 1.0] {
                let box = CGRect(x: side < 0 ? -422 : 302, y: -110, width: 120, height: 220)
                Paint.stroke(ctx, CGPath(rect: box, transform: nil), chalk, width: 2.5)
                let small = CGRect(x: side < 0 ? -422 : 372, y: -58, width: 50, height: 116)
                Paint.stroke(ctx, CGPath(rect: small, transform: nil), chalk, width: 2.5)
                Paint.fill(
                    ctx,
                    CGPath(ellipseIn: CGRect(x: side * 336 - 4, y: -4, width: 8, height: 8), transform: nil),
                    chalk
                )
                let arc = CGMutablePath()
                arc.addArc(
                    center: CGPoint(x: side * 336, y: 0),
                    radius: 46,
                    startAngle: side < 0 ? -.pi / 3 : .pi * 2 / 3,
                    endAngle: side < 0 ? .pi / 3 : .pi * 4 / 3,
                    clockwise: false
                )
                Paint.stroke(ctx, arc, chalk, width: 2.5)
                // Team-colour rails along the wall top.
                for y in [-188.0, 188.0] {
                    let rail = Paint.rounded(CGRect(x: side < 0 ? -392 : 96, y: y - 3, width: 296, height: 6), 3)
                    let color = side < 0 ? self.blue : self.orange
                    Paint.glow(ctx, rail, color.withAlphaComponent(0.8), blur: 10)
                }
            }
            // Corner floodlight housings.
            for sx in [-1.0, 1.0] {
                for sy in [-1.0, 1.0] {
                    let base = CGPoint(x: sx * 476, y: sy * 208)
                    Paint.fill(
                        ctx,
                        CGPath(ellipseIn: CGRect(x: base.x - 9, y: base.y - 9, width: 18, height: 18), transform: nil),
                        UIColor(hex: 0x0E1E27)
                    )
                    Paint.glow(
                        ctx,
                        CGPath(ellipseIn: CGRect(x: base.x - 5, y: base.y - 5, width: 10, height: 10), transform: nil),
                        UIColor(hex: 0xFFF6DA),
                        blur: 12
                    )
                }
            }
        }
        arena.addChild(slab)
        let monogram = SKLabelNode(fontNamed: "AvenirNext-HeavyItalic")
        monogram.text = "PD"
        monogram.fontSize = 96
        monogram.fontColor = .white.withAlphaComponent(0.06)
        monogram.verticalAlignmentMode = .center
        monogram.zPosition = 0.5
        arena.addChild(monogram)
        courtLabel("SKYLINE COURT  ·  ROOFTOP 01", at: CGPoint(x: 0, y: 207), color: UIColor(hex: 0x9FB9C2))
        courtLabel("POCKET ATHLETIC CLUB", at: CGPoint(x: 0, y: -222), color: UIColor(hex: 0x7F99A3))
        courtLabel("◀ DEFEND", at: CGPoint(x: -250, y: -148), color: blue.withAlphaComponent(0.7), size: 10)
        courtLabel("SCORE ▶", at: CGPoint(x: 250, y: -148), color: orange.withAlphaComponent(0.75), size: 10)
    }

    private func courtLabel(_ text: String, at point: CGPoint, color: UIColor, size: CGFloat = 9) {
        let node = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        node.text = text
        node.fontSize = size
        node.fontColor = color
        node.position = point
        node.verticalAlignmentMode = .center
        node.zPosition = 0.6
        arena.addChild(node)
    }

    private func buildGoals() {
        for side in [-1.0, 1.0] {
            let color = side < 0 ? blue : orange
            let goal = Paint.sprite(size: CGSize(width: 72, height: 184), z: 0.8) { ctx in
                let mouth = Paint.rounded(CGRect(x: -30, y: -82, width: 62, height: 164), 10)
                Paint.linear(
                    ctx,
                    mouth,
                    [UIColor(hex: 0x06121A), UIColor(hex: 0x0F2430)],
                    from: CGPoint(x: 32, y: 0),
                    to: CGPoint(x: -30, y: 0)
                )
                ctx.saveGState()
                ctx.addPath(mouth)
                ctx.clip()
                let net = color.withAlphaComponent(0.42)
                let vanish = CGPoint(x: 34, y: 0)
                for y in stride(from: -76.0, through: 76.0, by: 15.2) {
                    Paint.line(ctx, [CGPoint(x: -30, y: y), CGPoint(x: vanish.x, y: y * 0.55)], net, width: 1)
                }
                for step in 0 ... 5 {
                    let t = CGFloat(step) / 5
                    let x = -30 + t * 60
                    let h = 76 - 34 * t
                    Paint.line(ctx, [CGPoint(x: x, y: -h), CGPoint(x: x, y: h)], net, width: 1)
                }
                ctx.restoreGState()
                Paint.glow(ctx, Paint.rounded(CGRect(x: 26, y: -50, width: 5, height: 100), 2.5), color, blur: 12)
                for y in [-76.0, 76.0] {
                    let post = CGPath(ellipseIn: CGRect(x: -36, y: y - 7, width: 14, height: 14), transform: nil)
                    Paint.glow(ctx, post, color, blur: 14, fill: .white)
                    Paint.stroke(ctx, post, color, width: 2.5)
                }
            }
            goal.position = CGPoint(x: side * 468, y: 0)
            goal.xScale = side
            arena.addChild(goal)
            nets.append(goal)
        }
    }

    private func buildLighting() {
        let haze = SKSpriteNode(texture: Paint.softLight(
            diameter: 400,
            color: UIColor(hex: 0xFFF7E3).withAlphaComponent(0.16)
        ))
        haze.size = CGSize(width: 980, height: 430)
        haze.position = CGPoint(x: -40, y: 30)
        haze.blendMode = .add
        haze.zPosition = 0.7
        arena.addChild(haze)
        let emitter = SKEmitterNode()
        emitter.particleTexture = Paint.softLight(diameter: 10, color: .white)
        emitter.particleBirthRate = 7
        emitter.particleLifetime = 7
        emitter.particleLifetimeRange = 3
        emitter.particlePositionRange = CGVector(dx: 960, dy: 380)
        emitter.particleSpeed = 9
        emitter.particleSpeedRange = 6
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 2
        emitter.particleAlpha = 0
        emitter.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [0, 0.45, 0.45, 0], times: [0, 0.2, 0.8, 1])
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.35
        emitter.particleBlendMode = .add
        emitter.zPosition = 11
        emitter.advanceSimulationTime(8)
        arena.addChild(emitter)
        dust = emitter
    }

    // MARK: - Actors

    private func buildCar(_ car: SKNode, glow: SKSpriteNode, color: UIColor, number: String) {
        car.zPosition = 5
        glow.texture = Paint.softLight(diameter: 64, color: color)
        glow.size = CGSize(width: 96, height: 64)
        glow.blendMode = .add
        glow.alpha = 0.35
        glow.zPosition = -2
        car.addChild(glow)
        let shadow = SKSpriteNode(texture: Paint.softLight(diameter: 64, color: .black))
        shadow.size = CGSize(width: 78, height: 54)
        shadow.position = CGPoint(x: 2, y: -8)
        shadow.alpha = 0.6
        shadow.zPosition = -1
        car.addChild(shadow)
        let body = Paint.sprite(size: CGSize(width: 68, height: 48)) { ctx in
            let tyre = UIColor(hex: 0x0B1418)
            for x in [-17.0, 12.0] {
                for y in [-22.0, 12.0] {
                    let wheel = Paint.rounded(CGRect(x: x - 6, y: y, width: 13, height: 10), 3.5)
                    Paint.fill(ctx, wheel, tyre)
                    Paint.fill(
                        ctx,
                        Paint.rounded(CGRect(x: x - 3, y: y + 3, width: 7, height: 4), 2),
                        UIColor(hex: 0x5A6C74)
                    )
                }
            }
            // Spoiler.
            let spoiler = Paint.rounded(CGRect(x: -31, y: -17, width: 6, height: 34), 2.5)
            Paint.fill(ctx, spoiler, color.darker)
            Paint.stroke(ctx, spoiler, .white.withAlphaComponent(0.35), width: 1)
            // Body shell.
            let shell = Paint.rounded(CGRect(x: -27, y: -16, width: 54, height: 32), 12)
            Paint.glow(ctx, shell, .black.withAlphaComponent(0.5), blur: 4, fill: color.darker)
            let top = Paint.rounded(CGRect(x: -26, y: -13, width: 53, height: 28), 11)
            Paint.linear(
                ctx,
                top,
                [color.lighter, color, color.mixed(with: .black, 0.18)],
                from: CGPoint(x: 0, y: 15),
                to: CGPoint(x: 0, y: -13)
            )
            Paint.stroke(ctx, top, .white.withAlphaComponent(0.42), width: 1)
            // Hood stripe.
            Paint.fill(
                ctx,
                Paint.rounded(CGRect(x: 6, y: -2.5, width: 19, height: 5), 2.5),
                .white.withAlphaComponent(0.55)
            )
            // Cabin glass.
            let cabin = Paint.rounded(CGRect(x: -14, y: -9, width: 24, height: 20), 6)
            Paint.linear(
                ctx,
                cabin,
                [UIColor(hex: 0x1B4B60), UIColor(hex: 0x0A2230)],
                from: CGPoint(x: -14, y: 11),
                to: CGPoint(x: 10, y: -9)
            )
            Paint.stroke(ctx, cabin, .white.withAlphaComponent(0.3), width: 1)
            Paint.fill(
                ctx,
                Paint.rounded(CGRect(x: -11, y: 2, width: 13, height: 6), 3),
                .white.withAlphaComponent(0.42)
            )
            Paint.fill(
                ctx,
                Paint.rounded(CGRect(x: 7, y: -7, width: 4, height: 16), 2),
                UIColor(hex: 0xD4FAFF).withAlphaComponent(0.85)
            )
            // Lights.
            for y in [-11.0, 5.0] {
                Paint.glow(
                    ctx,
                    Paint.rounded(CGRect(x: 22, y: y, width: 5, height: 6), 2),
                    UIColor(hex: 0xFFF1B8),
                    blur: 8
                )
                Paint.glow(
                    ctx,
                    Paint.rounded(CGRect(x: -29, y: y + 1, width: 3, height: 4), 1.5),
                    UIColor(hex: 0xFF4D4D),
                    blur: 6
                )
            }
        }
        car.addChild(body)
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = number
        label.fontSize = 8
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: -3, y: -0.5)
        label.zPosition = 1
        car.addChild(label)
        arena.addChild(car)
    }

    private func buildBall() {
        ballShadow.texture = Paint.softLight(diameter: 64, color: .black)
        ballShadow.size = CGSize(width: 56, height: 40)
        ballShadow.alpha = 0.55
        ballShadow.zPosition = 6
        arena.addChild(ballShadow)
        ballNode.zPosition = 7
        let sphere = Paint.sprite(size: CGSize(width: 44, height: 44)) { ctx in
            let circle = CGPath(ellipseIn: CGRect(x: -18, y: -18, width: 36, height: 36), transform: nil)
            Paint.radial(
                ctx,
                circle,
                [.white, UIColor(hex: 0xF1EFE0), UIColor(hex: 0xA9B3AA)],
                center: CGPoint(x: -6, y: 7),
                radius: 30
            )
            ctx.saveGState()
            ctx.addPath(circle)
            ctx.clip()
            let patch = UIColor(hex: 0x223D4D)
            let pentagon = CGMutablePath()
            for index in 0 ..< 5 {
                let a = Double(index) * .pi * 2 / 5 + .pi / 2
                let p = CGPoint(x: cos(a) * 7, y: sin(a) * 7)
                index == 0 ? pentagon.move(to: p) : pentagon.addLine(to: p)
            }
            pentagon.closeSubpath()
            Paint.fill(ctx, pentagon, patch)
            for index in 0 ..< 5 {
                let a = Double(index) * .pi * 2 / 5 + .pi / 2
                Paint.line(
                    ctx,
                    [CGPoint(x: cos(a) * 7, y: sin(a) * 7), CGPoint(x: cos(a) * 15, y: sin(a) * 15)],
                    patch.withAlphaComponent(0.7),
                    width: 1.3
                )
                let b = a + .pi / 5
                let edge = CGMutablePath()
                edge.addArc(
                    center: CGPoint(x: cos(b) * 21, y: sin(b) * 21),
                    radius: 7,
                    startAngle: 0,
                    endAngle: .pi * 2,
                    clockwise: false
                )
                Paint.fill(ctx, edge, patch)
            }
            ctx.restoreGState()
            Paint.stroke(ctx, circle, UIColor(hex: 0x8B968F).withAlphaComponent(0.7), width: 1.2)
            Paint.fill(
                ctx,
                CGPath(ellipseIn: CGRect(x: -12, y: 6, width: 10, height: 6), transform: nil),
                .white.withAlphaComponent(0.85)
            )
        }
        ballNode.addChild(sphere)
        arena.addChild(ballNode)
    }

    private func buildTarget() {
        targetRing.zPosition = 1
        targetRing.isHidden = true
        let ring = SKShapeNode(path: CGPath(ellipseIn: CGRect(x: -15, y: -15, width: 30, height: 30), transform: nil)
            .copy(
                dashingWithPhase: 0,
                lengths: [8, 6]
            ))
        ring.strokeColor = .white
        ring.lineWidth = 2.5
        ring.glowWidth = 1
        ring.lineCap = .round
        targetRing.addChild(ring)
        let core = SKShapeNode(circleOfRadius: 5)
        core.fillColor = blue
        core.strokeColor = .white.withAlphaComponent(0.8)
        core.lineWidth = 1.5
        targetRing.addChild(core)
        ring.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 3)))
        arena.addChild(targetRing)
    }

    private func buildPlayerTag() {
        playerTag.zPosition = 8
        let chip = SKShapeNode(rectOf: CGSize(width: 34, height: 14), cornerRadius: 7)
        chip.fillColor = blue
        chip.strokeColor = .clear
        playerTag.addChild(chip)
        let arrow = SKShapeNode(path: {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -4, y: -6))
            path.addLine(to: CGPoint(x: 4, y: -6))
            path.addLine(to: CGPoint(x: 0, y: -11))
            path.closeSubpath()
            return path
        }())
        arrow.fillColor = blue
        arrow.strokeColor = .clear
        playerTag.addChild(arrow)
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "YOU"
        label.fontSize = 8
        label.fontColor = UIColor(hex: 0x082430)
        label.verticalAlignmentMode = .center
        playerTag.addChild(label)
        arena.addChild(playerTag)
    }

    // MARK: - Frame loop

    override func update(_ currentTime: TimeInterval) {
        guard let store else { return }
        let delta = lastTime == 0 ? 0 : min(currentTime - lastTime, 0.05)
        lastTime = currentTime
        accumulator += delta
        while accumulator >= 1.0 / 120 {
            store.tick(1.0 / 120)
            accumulator -= 1.0 / 120
        }
        dust?.particleBirthRate = store.reducedMotion ? 0 : 7
        let engine = store.engine
        if store.screen == .title {
            idleTime += store.reducedMotion ? 0 : delta
            blueCar.position = CGPoint(x: -120, y: -38)
            blueCar.zRotation = 0.35
            orangeCar.position = CGPoint(x: 168, y: 58)
            orangeCar.zRotation = .pi + 0.4
            place(ball: CGPoint(x: 0, y: sin(idleTime * 1.3) * 5), lift: sin(idleTime * 1.3) * 2 + 3)
            blueGlow.alpha = 0.35
            orangeGlow.alpha = 0.35
            targetRing.isHidden = true
            playerTag.isHidden = true
            return
        }
        playerTag.isHidden = false
        playerTag.position = CGPoint(x: engine.player.position.x, y: engine.player.position.y + 36)
        blueCar.position = engine.player.position.point
        blueCar.zRotation = engine.player.heading
        orangeCar.position = engine.opponent.position.point
        orangeCar.zRotation = engine.opponent.heading
        blueGlow.alpha = 0.3 + min(0.6, engine.player.velocity.length / 400)
        orangeGlow.alpha = 0.3 + min(0.6, engine.opponent.velocity.length / 400)
        place(ball: engine.ball.point, lift: 0)
        if !engine.paused {
            ballNode.zRotation -= engine.ballVelocity.x * delta * 0.012
        }
        targetRing.isHidden = engine.driveTarget == nil || engine.phase != .playing
        if let target = engine.driveTarget {
            targetRing.position = target.point
        }
        trailTick += 1
        if trailTick.isMultiple(of: 2), !engine.paused, !store.reducedMotion, engine.phase == .playing {
            trail(car: engine.player, texture: trailTextures[0])
            trail(car: engine.opponent, texture: trailTextures[1])
        }
        let goals = engine.playerGoals + engine.opponentGoals
        if goals != lastGoalCount {
            lastGoalCount = goals
            if goals > 0 {
                celebrate(player: engine.lastScorerIsPlayer, reduced: store.reducedMotion)
            }
        }
    }

    private func place(ball point: CGPoint, lift: CGFloat) {
        ballNode.position = CGPoint(x: point.x, y: point.y + lift)
        ballShadow.position = CGPoint(x: point.x + 4, y: point.y - 10)
    }

    private func trail(car: Car, texture: SKTexture) {
        guard car.velocity.length > 90 else { return }
        let boosting = car.velocity.length > 235
        let node = SKSpriteNode(texture: texture)
        node.size = CGSize(width: boosting ? 46 : 26, height: boosting ? 30 : 18)
        node.alpha = boosting ? 0.9 : 0.3
        node.blendMode = .add
        node.position = (car.position - Vector(x: cos(car.heading), y: sin(car.heading)) * 30).point
        node.zRotation = car.heading
        node.zPosition = 2
        arena.addChild(node)
        node.run(.sequence([
            .group([.fadeOut(withDuration: boosting ? 0.45 : 0.3), .scale(to: 0.4, duration: 0.45)]),
            .removeFromParent()
        ]))
    }

    private func celebrate(player: Bool, reduced: Bool) {
        let color = player ? blue : orange
        let origin = CGPoint(x: player ? 458 : -458, y: 0)
        let ripple = SKShapeNode(circleOfRadius: 20)
        ripple.position = origin
        ripple.strokeColor = color
        ripple.lineWidth = 5
        ripple.glowWidth = 8
        ripple.zPosition = 9
        arena.addChild(ripple)
        ripple.run(.sequence([
            .group([.scale(to: reduced ? 2 : 9, duration: 0.7), .fadeOut(withDuration: 0.7)]),
            .removeFromParent()
        ]))
        let flash = SKSpriteNode(texture: Paint.softLight(diameter: 128, color: color))
        flash.size = CGSize(width: 900, height: 600)
        flash.position = origin
        flash.blendMode = .add
        flash.alpha = 0.7
        flash.zPosition = 9
        arena.addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: reduced ? 0.3 : 0.6), .removeFromParent()]))
        let net = nets[player ? 1 : 0]
        net.run(.sequence([
            .scaleX(to: player ? 1.12 : -1.12, duration: 0.08),
            .scaleX(to: player ? 1 : -1, duration: 0.45)
        ]))
        guard !reduced else { return }
        arena.run(.sequence([
            .moveBy(x: 0, y: 7, duration: 0.05), .moveBy(x: 5, y: -12, duration: 0.06),
            .moveBy(x: -5, y: 5, duration: 0.06)
        ]))
        for index in 0 ..< 40 {
            let confetti = SKShapeNode(rectOf: CGSize(width: 6, height: 12), cornerRadius: 2)
            confetti.fillColor = index.isMultiple(of: 3) ? .white : index
                .isMultiple(of: 4) ? UIColor(hex: 0xFFD166) : color
            confetti.strokeColor = .clear
            confetti.position = origin
            confetti.zPosition = 10
            arena.addChild(confetti)
            let a = Double(index) * 2.399
            let distance = Double(80 + index * 5)
            confetti.run(.sequence([.group([
                .moveBy(x: cos(a) * distance, y: sin(a) * distance, duration: 1.1),
                .rotate(byAngle: a, duration: 1.1), .fadeOut(withDuration: 1.1)
            ]), .removeFromParent()]))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        aim(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        aim(touches)
    }

    private func aim(_ touches: Set<UITouch>) {
        guard let store, store.screen == .match, !store.engine.paused,
              let touch = touches.first else { return }
        let point = touch.location(in: arena)
        store.engine.driveTarget = Vector(x: max(-417, min(417, point.x)), y: max(-151, min(151, point.y)))
    }
}

extension Vector {
    var point: CGPoint {
        CGPoint(x: x, y: y)
    }
}
