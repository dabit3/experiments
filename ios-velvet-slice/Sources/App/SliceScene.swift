import SpriteKit
import UIKit

@MainActor
final class FlyingFruit {
    let node: SKSpriteNode
    let kind: FruitKind
    let isBomb: Bool
    var velocity: CGVector
    var rotation: CGFloat

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
            let x = left + width * CGFloat(index) / CGFloat(max(1, plan.fruitCount - 1))
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
        let height = size.height * (rules.mode == .practice ? 0.69 : 0.73)
        let speed = sqrt(2 * gravity * (height + 68)) + CGFloat.random(in: -12 ... 12)
        let inward = (size.width / 2 - x) * 0.035
        fruit.append(FlyingFruit(node: node, kind: kind, isBomb: bomb, velocity: CGVector(dx: inward, dy: speed), rotation: CGFloat.random(in: -0.75 ... 0.75)))
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
        let trail = SKShapeNode(path: path)
        trail.strokeColor = UIColor(red: 0.78, green: 1, blue: 0.94, alpha: 1)
        trail.lineWidth = 3
        trail.glowWidth = 7
        trail.zPosition = 30
        trail.lineCap = .round
        addChild(trail)
        trail.run(.sequence([.fadeOut(withDuration: 0.22), .removeFromParent()]))
        let hits = fruit.filter {
            SliceGeometry.intersects(from: Point2D(x: start.x, y: start.y), to: Point2D(x: end.x, y: end.y), center: Point2D(x: $0.node.position.x, y: $0.node.position.y - 3), radius: $0.isBomb ? 28 : 34)
        }
        for item in hits {
            if item.isBomb {
                chainCount = 0
                rules.hitBomb()
                burst(at: item.node.position, color: UIColor.systemRed, count: 25)
                label("BOMB  −25", at: item.node.position, color: UIColor(red: 1, green: 0.47, blue: 0.4, alpha: 1))
                store?.sound.play(bomb: true)
            } else {
                rules.slice()
                if chainCount == 0 {
                    chainAge = 0
                }
                chainCount += 1
                lastSlice = item.node.position
                split(item)
                burst(at: item.node.position, color: item.kind.juice, count: 16)
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
            label("\(chainCount) FRUIT COMBO  +\(bonus)", at: CGPoint(x: size.width / 2, y: min(size.height - 50, max(70, lastSlice.y + 65))), color: UIColor(red: 0.76, green: 0.98, blue: 0.75, alpha: 1))
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

    private func label(_ text: String, at point: CGPoint, color: UIColor, small: Bool = false) {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = text
        label.fontSize = small ? 16 : 19
        label.fontColor = color
        label.position = CGPoint(x: min(size.width - 90, max(90, point.x)), y: point.y)
        label.zPosition = 40
        addChild(label)
        label.run(.sequence([
            .group([.moveBy(x: 0, y: 25, duration: 0.9), .sequence([.wait(forDuration: 0.45), .fadeOut(withDuration: 0.45)])]),
            .removeFromParent(),
        ]))
    }
}
