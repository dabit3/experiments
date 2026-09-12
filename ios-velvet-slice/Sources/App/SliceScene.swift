import SpriteKit
import UIKit

@MainActor
final class FlyingFruit {
    let node: SKSpriteNode
    let kind: FruitKind
    let isBomb: Bool
    var velocity: CGVector
    var rotation: CGFloat
    var launchDelay: Double = 0

    init(node: SKSpriteNode, kind: FruitKind, isBomb: Bool, velocity: CGVector, rotation: CGFloat) {
        self.node = node
        self.kind = kind
        self.isBomb = isBomb
        self.velocity = velocity
        self.rotation = rotation
    }
}

@MainActor
final class SliceScene: SKScene {
    weak var store: GameStore?
    private var fruit: [FlyingFruit] = []
    private var previousTime: TimeInterval = 0
    private var countdownTime: TimeInterval = 0
    private var waveClock: TimeInterval = 0
    private var wave = 0
    private var previousTouch: CGPoint?
    private var chainCount = 0
    private var chainAge: Double = 0
    private var lastSlice = CGPoint.zero
    private weak var activeBanner: SKNode?
    private var hudClock: Double = 0
    private var rules = RoundRules(mode: .arcade)
    private let gravity: CGFloat = 410

    init(store: GameStore) {
        self.store = store
        super.init(size: CGSize(width: 390, height: 560))
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("Use init(store:)")
    }

    func resetRound() {
        removeAllChildren()
        fruit.removeAll()
        previousTime = 0
        countdownTime = 0
        waveClock = 0
        wave = 0
        chainCount = 0
        chainAge = 0
        previousTouch = nil
        rules = RoundRules(mode: store?.mode ?? .arcade)
    }

    override func update(_ currentTime: TimeInterval) {
        let delta = previousTime == 0 ? 0 : min(1.0 / 20, currentTime - previousTime)
        previousTime = currentTime
        guard let store, store.screen == .playing, !store.paused else { return }
        if store.countdown > 0 {
            countdownTime += delta
            store.countdown = max(0, 3 - Int(countdownTime))
            return
        }
        rules.advance(delta)
        if rules.finished {
            store.round = rules
            store.finish()
            return
        }
        chainAge += delta
        if chainCount > 0, chainAge > 0.48 {
            flushCombo()
        }
        waveClock -= delta
        if waveClock <= 0 {
            launchWave()
        }
        for item in fruit {
            if item.launchDelay > 0 {
                item.launchDelay -= delta
                item.node.isHidden = item.launchDelay > 0
                continue
            }
            item.velocity.dy -= gravity * delta
            item.node.position.x += item.velocity.dx * delta
            item.node.position.y += item.velocity.dy * delta
            item.node.zRotation += item.rotation * delta
        }
        let fallen = fruit.filter { $0.node.position.y < -110 && $0.velocity.dy < 0 }
        for item in fallen {
            if !item.isBomb {
                rules.miss()
                if rules.mode == .arcade {
                    label("−2", at: CGPoint(x: min(size.width - 28, max(28, item.node.position.x)), y: 28), color: UIColor(red: 0.82, green: 0.59, blue: 0.58, alpha: 1), small: true)
                }
            }
            item.node.removeFromParent()
        }
        fruit.removeAll { $0.node.parent == nil }
        hudClock += delta
        if hudClock > 0.08 {
            store.round = rules
            hudClock = 0
        }
    }

    private func launchWave() {
        let plan = WavePlan(wave: wave, mode: rules.mode)
        waveClock = plan.interval
        let hasBomb = plan.bombLane != nil
        let left: CGFloat = hasBomb && plan.bombLane == 0 ? 108 : 44
        let right: CGFloat = hasBomb && plan.bombLane == 1 ? size.width - 108 : size.width - 44
        let width = right - left
        for index in 0 ..< plan.fruitCount {
            let x = left + width * CGFloat(index) / CGFloat(max(1, plan.fruitCount - 1)) + CGFloat.random(in: -7 ... 7)
            let kind = FruitKind(rawValue: (wave + index) % 3) ?? .citrus
            launch(kind: kind, x: x, bomb: false, index: index)
        }
        if let lane = plan.bombLane {
            launch(kind: .citrus, x: lane == 0 ? 35 : size.width - 35, bomb: true, index: 1)
        }
        wave += 1
    }

    private func launch(kind: FruitKind, x: CGFloat, bomb: Bool, index: Int) {
        let node = SKSpriteNode(texture: SKTexture(image: bomb ? FruitArt.bomb : FruitArt.image(kind)))
        let diameter: CGFloat = bomb ? 78 : 92
        node.size = CGSize(width: diameter, height: diameter * 240 / 220)
        node.position = CGPoint(x: x, y: -68 - CGFloat(index % 2) * 10)
        node.zPosition = 5
        addChild(node)
        let arc = sin(CGFloat(index) * 1.4 + CGFloat(wave) * 0.8) * 0.08
        let height = size.height * ((rules.mode == .practice ? 0.64 : 0.69) + arc)
        let speed = sqrt(2 * gravity * (height + 68)) + CGFloat.random(in: -12 ... 12)
        let inward = bomb ? 0 : (size.width / 2 - x) * 0.07
        let item = FlyingFruit(node: node, kind: kind, isBomb: bomb, velocity: CGVector(dx: inward, dy: speed), rotation: CGFloat.random(in: -1.1 ... 1.1))
        item.launchDelay = Double(index) * (wave % 2 == 0 ? 0.07 : 0.035)
        node.isHidden = item.launchDelay > 0
        fruit.append(item)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        guard store?.paused == false, store?.countdown == 0, store?.screen == .playing,
              let touch = touches.first else { return }
        previousTouch = touch.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        guard store?.paused == false, store?.countdown == 0, store?.screen == .playing,
              let touch = touches.first, let start = previousTouch else { return }
        let end = touch.location(in: self)
        slice(from: start, to: end)
        previousTouch = end
    }

    override func touchesEnded(_: Set<UITouch>, with _: UIEvent?) {
        cancelSwipe()
    }

    override func touchesCancelled(_: Set<UITouch>, with _: UIEvent?) {
        cancelSwipe()
    }

    func cancelSwipe() {
        flushCombo()
        previousTouch = nil
    }

    private func slice(from start: CGPoint, to end: CGPoint) {
        guard hypot(end.x - start.x, end.y - start.y) > 2 else { return }
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        let halo = SKShapeNode(path: path)
        halo.strokeColor = UIColor(red: 0.55, green: 0.95, blue: 0.85, alpha: 0.35)
        halo.lineWidth = 12
        halo.glowWidth = 14
        halo.zPosition = 29
        halo.lineCap = .round
        halo.blendMode = .add
        addChild(halo)
        halo.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
        let trail = SKShapeNode(path: path)
        trail.strokeColor = UIColor(red: 0.98, green: 0.99, blue: 0.94, alpha: 1)
        trail.lineWidth = 2.4
        trail.glowWidth = 3
        trail.zPosition = 30
        trail.lineCap = .round
        addChild(trail)
        trail.run(.sequence([.fadeOut(withDuration: 0.18), .removeFromParent()]))
        let tip = SKShapeNode(circleOfRadius: 3)
        tip.fillColor = .white
        tip.strokeColor = .clear
        tip.glowWidth = 6
        tip.position = end
        tip.zPosition = 31
        tip.blendMode = .add
        addChild(tip)
        tip.run(.sequence([.group([.scale(to: 0.2, duration: 0.2), .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
        let hits = fruit.filter {
            !$0.node.isHidden && SliceGeometry.intersects(from: Point2D(x: start.x, y: start.y), to: Point2D(x: end.x, y: end.y), center: Point2D(x: $0.node.position.x, y: $0.node.position.y - 3), radius: $0.isBomb ? 28 : 34)
        }
        for item in hits {
            if item.isBomb {
                chainCount = 0
                rules.hitBomb()
                burst(at: item.node.position, color: UIColor.systemRed, count: 25)
                label("BOMB  −25", at: item.node.position, color: UIColor(red: 1, green: 0.47, blue: 0.4, alpha: 1))
                flash(UIColor(red: 1, green: 0.35, blue: 0.3, alpha: 0.55))
                store?.sound.play(bomb: true)
            } else {
                rules.slice()
                if chainCount == 0 {
                    chainAge = 0
                }
                chainCount += 1
                lastSlice = item.node.position
                split(item)
                stain(at: item.node.position, color: item.kind.juice, angle: atan2(end.y - start.y, end.x - start.x))
                burst(at: item.node.position, color: item.kind.juice, count: 16)
                label("+10", at: CGPoint(x: item.node.position.x, y: item.node.position.y + 18), color: UIColor(red: 0.88, green: 0.96, blue: 0.83, alpha: 0.85), small: true)
                store?.sound.play()
            }
            item.node.removeFromParent()
            if rules.finished {
                break
            }
        }
        fruit.removeAll { $0.node.parent == nil }
        store?.round = rules
        if rules.finished {
            store?.finish()
        }
    }

    private func flushCombo() {
        if chainCount >= 3 {
            let bonus = rules.combo(chainCount)
            comboBanner(count: chainCount, bonus: bonus, at: CGPoint(x: size.width / 2, y: min(size.height - 70, max(90, lastSlice.y + 70))))
            store?.sound.play(combo: true)
            store?.round = rules
        }
        chainCount = 0
    }

    private func split(_ item: FlyingFruit) {
        for side in [-1.0, 1.0] {
            let crop = SKCropNode()
            let half = SKSpriteNode(texture: item.node.texture)
            half.size = item.node.size
            crop.addChild(half)
            let mask = SKSpriteNode(color: .white, size: CGSize(width: half.size.width / 2, height: half.size.height))
            mask.position.x = side * half.size.width / 4
            crop.maskNode = mask
            crop.position = item.node.position
            crop.zRotation = item.node.zRotation
            crop.zPosition = 4
            addChild(crop)
            crop.run(.sequence([
                .group([
                    .moveBy(x: side * 90, y: -185, duration: 0.72),
                    .rotate(byAngle: side * 1.6, duration: 0.72),
                    .sequence([.wait(forDuration: 0.3), .fadeOut(withDuration: 0.42)]),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    private func burst(at point: CGPoint, color: UIColor, count: Int) {
        let reduced = UIAccessibility.isReduceMotionEnabled
        for _ in 0 ..< (reduced ? 4 : count) {
            let radius = CGFloat.random(in: 1.5 ... 4)
            let drop = SKShapeNode(ellipseOf: CGSize(width: radius * 1.5, height: radius * 2.6))
            drop.fillColor = color
            drop.strokeColor = .clear
            drop.position = point
            drop.zPosition = 7
            let angle = CGFloat.random(in: 0 ... (.pi * 2))
            drop.zRotation = angle
            addChild(drop)
            drop.run(.sequence([.group([
                .moveBy(x: cos(angle) * 75, y: sin(angle) * 75 - 30, duration: 0.45),
                .fadeOut(withDuration: 0.45),
            ]), .removeFromParent()]))
        }
    }

    private func comboBanner(count: Int, bonus: Int, at point: CGPoint) {
        activeBanner?.removeAllActions()
        activeBanner?.run(.sequence([.fadeOut(withDuration: 0.08), .removeFromParent()]))
        let banner = SKNode()
        activeBanner = banner
        banner.position = point
        banner.zPosition = 45
        let headline = SKLabelNode(fontNamed: "Baskerville-Italic")
        headline.text = "\(count) fruit combo"
        headline.fontSize = 32
        headline.fontColor = UIColor(red: 0.99, green: 0.95, blue: 0.86, alpha: 1)
        headline.verticalAlignmentMode = .center
        banner.addChild(headline)
        let bonusLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        bonusLabel.text = "+\(bonus)  BONUS"
        bonusLabel.fontSize = 13
        bonusLabel.fontColor = UIColor(red: 0.87, green: 0.72, blue: 0.44, alpha: 1)
        bonusLabel.position.y = -28
        bonusLabel.verticalAlignmentMode = .center
        banner.addChild(bonusLabel)
        for side in [-1.0, 1.0] {
            let rule = SKShapeNode(rectOf: CGSize(width: 36, height: 1))
            rule.fillColor = UIColor(red: 0.87, green: 0.72, blue: 0.44, alpha: 0.8)
            rule.strokeColor = .clear
            rule.position = CGPoint(x: side * (headline.frame.width / 2 + 30), y: 0)
            banner.addChild(rule)
        }
        let glow = SKShapeNode(ellipseOf: CGSize(width: headline.frame.width + 140, height: 90))
        glow.fillColor = UIColor(red: 0.72, green: 0.93, blue: 0.78, alpha: 0.12)
        glow.strokeColor = .clear
        glow.blendMode = .add
        glow.zPosition = -1
        banner.addChild(glow)
        banner.setScale(0.7)
        banner.alpha = 0
        addChild(banner)
        banner.run(.sequence([
            .group([.scale(to: 1, duration: 0.22), .fadeIn(withDuration: 0.16)]),
            .wait(forDuration: 0.55),
            .group([.moveBy(x: 0, y: 26, duration: 0.5), .fadeOut(withDuration: 0.5)]),
            .removeFromParent(),
        ]))
    }

    private func stain(at point: CGPoint, color: UIColor, angle: CGFloat) {
        let stain = SKSpriteNode(texture: FruitArt.splatter, size: CGSize(width: 150, height: 70))
        stain.color = color
        stain.colorBlendFactor = 1
        stain.alpha = 0.55
        stain.position = point
        stain.zRotation = angle
        stain.zPosition = 1
        stain.blendMode = .add
        addChild(stain)
        stain.run(.sequence([
            .group([.scaleX(to: 1.5, y: 0.75, duration: 0.5), .sequence([.wait(forDuration: 0.5), .fadeOut(withDuration: 1.6)])]),
            .removeFromParent(),
        ]))
    }

    private func flash(_ color: UIColor) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let flash = SKSpriteNode(texture: FruitArt.vignette, size: CGSize(width: size.width * 1.4, height: size.height * 1.4))
        flash.color = color
        flash.colorBlendFactor = 1
        flash.alpha = color.cgColor.alpha
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 60
        addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
    }

    private func label(_ text: String, at point: CGPoint, color: UIColor, small: Bool = false) {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = text
        label.fontSize = small ? 16 : 19
        label.fontColor = color
        let inset = label.frame.width / 2 + 12
        label.position = CGPoint(x: min(size.width - inset, max(inset, point.x)), y: point.y)
        label.zPosition = 40
        addChild(label)
        label.run(.sequence([
            .group([.moveBy(x: 0, y: 25, duration: small ? 0.65 : 0.9), .sequence([.wait(forDuration: small ? 0.2 : 0.45), .fadeOut(withDuration: 0.45)])]),
            .removeFromParent(),
        ]))
    }
}
