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
                    label("-2", at: CGPoint(x: min(size.width - 28, max(28, item.node.position.x)), y: 28), color: Pixel.red, small: true)
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
        let node = SKSpriteNode(texture: bomb ? FruitArt.nearest(FruitArt.bomb) : FruitArt.texture(kind))
        let scale: CGFloat = bomb ? 2.8 : 3.2
        node.size = CGSize(width: CGFloat(FruitArt.grid) * scale, height: CGFloat(FruitArt.grid + 4) * scale)
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
        halo.strokeColor = Pixel.sky
        halo.lineWidth = 10
        halo.zPosition = 29
        halo.lineCap = .square
        halo.isAntialiased = false
        addChild(halo)
        halo.run(.sequence([.wait(forDuration: 0.05), .run { halo.strokeColor = Pixel.indigo }, .wait(forDuration: 0.05), .removeFromParent()]))
        let trail = SKShapeNode(path: path)
        trail.strokeColor = Pixel.white
        trail.lineWidth = 4
        trail.zPosition = 30
        trail.lineCap = .square
        trail.isAntialiased = false
        addChild(trail)
        trail.run(.sequence([.wait(forDuration: 0.07), .run { trail.strokeColor = Pixel.sky }, .wait(forDuration: 0.05), .removeFromParent()]))
        let tip = SKSpriteNode(texture: FruitArt.square, size: CGSize(width: 10, height: 10))
        tip.color = Pixel.yellow
        tip.colorBlendFactor = 1
        tip.position = end
        tip.zPosition = 31
        addChild(tip)
        tip.run(.sequence([.wait(forDuration: 0.06), .removeFromParent()]))
        let hits = fruit.filter {
            !$0.node.isHidden && SliceGeometry.intersects(from: Point2D(x: start.x, y: start.y), to: Point2D(x: end.x, y: end.y), center: Point2D(x: $0.node.position.x, y: $0.node.position.y - 3), radius: $0.isBomb ? 28 : 34)
        }
        for item in hits {
            if item.isBomb {
                chainCount = 0
                rules.hitBomb()
                burst(at: item.node.position, color: Pixel.red, count: 20)
                burst(at: item.node.position, color: Pixel.yellow, count: 10)
                label("BOMB -25", at: item.node.position, color: Pixel.red)
                flash()
                shake()
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
                label("+10", at: CGPoint(x: item.node.position.x, y: item.node.position.y + 56), color: Pixel.white, small: true)
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
            let side = CGFloat([4, 6, 6, 8].randomElement() ?? 6)
            let drop = SKSpriteNode(texture: FruitArt.square, size: CGSize(width: side, height: side))
            drop.color = color
            drop.colorBlendFactor = 1
            drop.position = point
            drop.zPosition = 7
            let angle = CGFloat.random(in: 0 ... (.pi * 2))
            let distance = CGFloat.random(in: 40 ... 90)
            addChild(drop)
            var steps: [SKAction] = []
            for step in 0 ..< 7 {
                let fall = CGFloat(step) * 4
                steps.append(.moveBy(x: cos(angle) * distance / 7, y: sin(angle) * distance / 7 - fall, duration: 0))
                steps.append(.wait(forDuration: 0.055))
            }
            steps.append(.removeFromParent())
            drop.run(.sequence(steps))
        }
    }

    private func comboBanner(count: Int, bonus: Int, at point: CGPoint) {
        activeBanner?.removeAllActions()
        activeBanner?.run(.sequence([.fadeOut(withDuration: 0.08), .removeFromParent()]))
        let banner = SKNode()
        activeBanner = banner
        banner.position = point
        banner.zPosition = 45
        let headline = pixelText("\(count) COMBO!", size: 22, color: Pixel.yellow)
        banner.addChild(headline)
        let bonusLabel = pixelText("+\(bonus)", size: 14, color: Pixel.white)
        bonusLabel.position.y = -28
        banner.addChild(bonusLabel)
        banner.setScale(1.5)
        addChild(banner)
        let cycle: [UIColor] = [Pixel.yellow, Pixel.white, Pixel.orange, Pixel.yellow, Pixel.pink, Pixel.yellow]
        var frames: [SKAction] = [.wait(forDuration: 0.07), .scale(to: 1.15, duration: 0), .wait(forDuration: 0.07), .scale(to: 1, duration: 0)]
        for color in cycle {
            frames.append(.run { headline.tint(color) })
            frames.append(.wait(forDuration: 0.1))
        }
        frames.append(.wait(forDuration: 0.2))
        for _ in 0 ..< 3 {
            frames.append(.hide())
            frames.append(.wait(forDuration: 0.05))
            frames.append(.unhide())
            frames.append(.wait(forDuration: 0.05))
        }
        frames.append(.removeFromParent())
        banner.run(.sequence(frames))
    }

    private func stain(at point: CGPoint, color: UIColor, angle: CGFloat) {
        let stain = SKSpriteNode(texture: FruitArt.splatter, size: CGSize(width: 96, height: 48))
        stain.color = color
        stain.colorBlendFactor = 1
        stain.position = point
        stain.zRotation = angle
        stain.zPosition = 1
        addChild(stain)
        stain.run(.sequence([
            .wait(forDuration: 0.4),
            .run { stain.alpha = 0.6 },
            .wait(forDuration: 0.4),
            .run { stain.alpha = 0.3 },
            .wait(forDuration: 0.4),
            .removeFromParent(),
        ]))
    }

    private func flash() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let flash = SKSpriteNode(color: Pixel.white, size: CGSize(width: size.width * 2, height: size.height * 2))
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 60
        addChild(flash)
        flash.run(.sequence([
            .wait(forDuration: 0.05),
            .run { flash.color = Pixel.red },
            .wait(forDuration: 0.05),
            .run { flash.color = Pixel.white },
            .wait(forDuration: 0.04),
            .removeFromParent(),
        ]))
    }

    private func shake() {
        guard !UIAccessibility.isReduceMotionEnabled, let view else { return }
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.values = [0, 6, -6, 4, -4, 0]
        shake.duration = 0.24
        shake.calculationMode = .discrete
        view.layer.add(shake, forKey: "shake")
    }

    private func label(_ text: String, at point: CGPoint, color: UIColor, small: Bool = false) {
        let label = pixelText(text, size: small ? 12 : 16, color: color)
        let inset = label.calculateAccumulatedFrame().width / 2 + 12
        label.position = CGPoint(x: min(size.width - inset, max(inset, point.x)), y: point.y)
        label.zPosition = 40
        addChild(label)
        var steps: [SKAction] = []
        for _ in 0 ..< (small ? 6 : 9) {
            steps.append(.moveBy(x: 0, y: 5, duration: 0))
            steps.append(.wait(forDuration: 0.07))
        }
        steps.append(.removeFromParent())
        label.run(.sequence(steps))
    }

    private func pixelText(_ text: String, size fontSize: CGFloat, color: UIColor) -> PixelLabel {
        PixelLabel(text, size: fontSize, color: color)
    }
}

/// A Press Start 2P label with the hard one-step drop shadow of 8-bit HUD text.
@MainActor
final class PixelLabel: SKNode {
    private let face = SKLabelNode(fontNamed: "PressStart2P-Regular")
    private let shadow = SKLabelNode(fontNamed: "PressStart2P-Regular")

    init(_ text: String, size: CGFloat, color: UIColor) {
        super.init()
        for (label, offset) in [(shadow, CGPoint(x: size / 6, y: -size / 6)), (face, .zero)] {
            label.text = text
            label.fontSize = size
            label.verticalAlignmentMode = .center
            label.position = offset
            addChild(label)
        }
        shadow.fontColor = Pixel.black
        face.fontColor = color
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("Use init(_:size:color:)")
    }

    func tint(_ color: UIColor) {
        face.fontColor = color
    }
}
