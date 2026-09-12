import SpriteKit
import UIKit

final class ArenaScene: SKScene {
    weak var store: GameStore?
    private let blueCar = SKNode()
    private let orangeCar = SKNode()
    private let ballNode = SKNode()
    private let targetRing = SKShapeNode(circleOfRadius: 12)
    private let playerTag = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let arena = SKNode()
    private var lastTime = 0.0
    private var accumulator = 0.0
    private var lastGoalCount = 0
    private var trailTick = 0
    private var idleTime = 0.0
    private let blue = UIColor(hex: 0x65E4FF)
    private let orange = UIColor(hex: 0xFF8865)

    init(store: GameStore) {
        self.store = store
        super.init(size: CGSize(width: 1100, height: 480))
        scaleMode = .resizeFill
        backgroundColor = .clear
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        buildArena()
        buildCar(blueCar, color: blue, number: "01")
        buildCar(orangeCar, color: orange, number: "02")
        arena.addChild(blueCar)
        arena.addChild(orangeCar)
        buildBall()
        arena.addChild(ballNode)
        targetRing.fillColor = UIColor(hex: 0x123B48).withAlphaComponent(0.7)
        targetRing.strokeColor = .white.withAlphaComponent(0.9)
        targetRing.lineWidth = 2.5
        targetRing.zPosition = 1
        targetRing.isHidden = true
        arena.addChild(targetRing)
        for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 2) {
            line([CGPoint(x: cos(angle) * 17, y: sin(angle) * 17),
                  CGPoint(x: cos(angle) * 22, y: sin(angle) * 22)], color: blue, width: 3, parent: targetRing)
        }
        playerTag.text = "YOU"
        playerTag.fontSize = 10
        playerTag.fontColor = blue
        playerTag.zPosition = 8
        arena.addChild(playerTag)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didChangeSize(_: CGSize) {
        let scale = min(size.width / 1020, size.height / 396)
        arena.xScale = scale
        arena.yScale = scale * 0.9
    }

    private func shape(
        _ rect: CGRect, radius: CGFloat, fill: UIColor,
        stroke: UIColor = .clear, width: CGFloat = 1, parent: SKNode
    ) -> SKShapeNode {
        let node = SKShapeNode(rect: rect, cornerRadius: radius)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = width
        parent.addChild(node)
        return node
    }

    private func line(_ points: [CGPoint], color: UIColor, width: CGFloat, parent: SKNode) {
        guard let first = points.first else { return }
        let path = CGMutablePath()
        path.move(to: first)
        points.dropFirst().forEach { path.addLine(to: $0) }
        let node = SKShapeNode(path: path)
        node.strokeColor = color
        node.lineWidth = width
        node.lineCap = .round
        parent.addChild(node)
    }

    private func label(_ text: String, at point: CGPoint, size: CGFloat, color: UIColor, parent: SKNode) {
        let node = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        node.text = text
        node.fontSize = size
        node.fontColor = color
        node.position = point
        parent.addChild(node)
    }

    private func buildArena() {
        addChild(arena)
        _ = shape(
            CGRect(x: -510, y: -215, width: 1020, height: 422),
            radius: 42,
            fill: UIColor.black.withAlphaComponent(0.28),
            parent: arena
        )
        _ = shape(
            CGRect(x: -494, y: -199, width: 988, height: 402),
            radius: 32,
            fill: UIColor(hex: 0x132F3E),
            stroke: UIColor(hex: 0x3A5964),
            width: 3,
            parent: arena
        )
        _ = shape(
            CGRect(x: -477, y: -184, width: 954, height: 381),
            radius: 25,
            fill: UIColor(hex: 0x537078),
            parent: arena
        )
        _ = shape(
            CGRect(x: -464, y: -183, width: 928, height: 378),
            radius: 22,
            fill: UIColor(hex: 0x284B50),
            parent: arena
        )
        _ = shape(
            CGRect(x: -440, y: -175, width: 880, height: 350),
            radius: 18,
            fill: UIColor(hex: 0x227D74),
            parent: arena
        )
        for index in 0 ..< 10 {
            _ = shape(
                CGRect(x: -440 + index * 88, y: -172, width: 86, height: 344),
                radius: 8,
                fill: UIColor.white.withAlphaComponent(index.isMultiple(of: 2) ? 0.025 : 0.055),
                parent: arena
            )
        }
        for sx in [-1.0, 1.0] {
            for sy in [-1.0, 1.0] {
                let wedge = CGMutablePath()
                wedge.move(to: CGPoint(x: 440, y: 175))
                wedge.addLine(to: CGPoint(x: 440, y: 105))
                wedge.addArc(
                    center: CGPoint(x: 370, y: 105),
                    radius: 70,
                    startAngle: 0,
                    endAngle: .pi / 2,
                    clockwise: false
                )
                wedge.closeSubpath()
                let bumper = SKShapeNode(path: wedge)
                bumper.fillColor = UIColor(hex: 0x284B50)
                bumper.strokeColor = UIColor(hex: 0x547D7A)
                bumper.lineWidth = 2
                bumper.xScale = sx
                bumper.yScale = sy
                arena.addChild(bumper)
            }
        }
        let ink = UIColor(hex: 0xBEF3D9).withAlphaComponent(0.47)
        _ = shape(
            CGRect(x: -421, y: -156, width: 842, height: 312),
            radius: 51,
            fill: .clear,
            stroke: ink,
            width: 2,
            parent: arena
        )
        line([CGPoint(x: 0, y: -155), CGPoint(x: 0, y: 155)], color: ink, width: 2, parent: arena)
        let circle = SKShapeNode(circleOfRadius: 69)
        circle.strokeColor = ink
        circle.lineWidth = 2
        arena.addChild(circle)
        let center = SKShapeNode(circleOfRadius: 4)
        center.fillColor = ink
        center.strokeColor = .clear
        arena.addChild(center)
        for side in [-1.0, 1.0] {
            let color = side < 0 ? blue : orange
            let x = side < 0 ? -421.0 : 310.0
            _ = shape(
                CGRect(x: x, y: -112, width: 111, height: 224),
                radius: 12,
                fill: color.withAlphaComponent(0.05),
                stroke: ink,
                width: 2,
                parent: arena
            )
            let goalX = side < 0 ? -487.0 : 440.0
            _ = shape(
                CGRect(x: goalX, y: -76, width: 47, height: 152),
                radius: 8,
                fill: UIColor(hex: 0x132F3E),
                stroke: color,
                width: 4,
                parent: arena
            )
            for y in stride(from: -68.0, through: 68.0, by: 17) {
                line(
                    [CGPoint(x: goalX + 3, y: y), CGPoint(x: goalX + 44, y: y)],
                    color: color.withAlphaComponent(0.3),
                    width: 1,
                    parent: arena
                )
            }
            for gx in stride(from: goalX + 10, through: goalX + 40, by: 10) {
                line(
                    [CGPoint(x: gx, y: -72), CGPoint(x: gx, y: 72)],
                    color: color.withAlphaComponent(0.3),
                    width: 1,
                    parent: arena
                )
            }
            for y in [-76.0, 76.0] {
                let post = SKShapeNode(circleOfRadius: 6)
                post.position = CGPoint(x: side * 440, y: y)
                post.fillColor = .white
                post.strokeColor = color
                post.lineWidth = 3
                arena.addChild(post)
            }
            for y in [-186.0, 184.0] {
                line(
                    [CGPoint(x: side * 95, y: y), CGPoint(x: side * 375, y: y)],
                    color: color.withAlphaComponent(0.8),
                    width: 4,
                    parent: arena
                )
            }
        }
        label(
            "ROOFTOP  /  01",
            at: CGPoint(x: 0, y: -202),
            size: 10,
            color: UIColor(hex: 0x91ACB4),
            parent: arena
        )
        label(
            "POCKET  ATHLETIC  CLUB",
            at: CGPoint(x: 0, y: 181),
            size: 9,
            color: UIColor(hex: 0x91ACB4),
            parent: arena
        )
        label(
            "DEFEND",
            at: CGPoint(x: -255, y: -145),
            size: 11,
            color: blue.withAlphaComponent(0.65),
            parent: arena
        )
        label(
            "SCORE  →",
            at: CGPoint(x: 255, y: -145),
            size: 11,
            color: orange.withAlphaComponent(0.7),
            parent: arena
        )
        for side in [-1.0, 1.0] {
            for x in stride(from: -380.0, through: 380.0, by: 76) {
                _ = shape(
                    CGRect(x: x, y: side * 211, width: 30, height: 7),
                    radius: 3,
                    fill: UIColor(hex: 0x67888A).withAlphaComponent(0.32),
                    parent: arena
                )
            }
        }
    }

    private func buildCar(_ car: SKNode, color: UIColor, number: String) {
        car.zPosition = 5
        _ = shape(
            CGRect(x: -27, y: -20, width: 56, height: 36),
            radius: 13,
            fill: .black.withAlphaComponent(0.28),
            parent: car
        )
        for x in [-16.0, 13.0] {
            for y in [-20.0, 13.0] {
                _ = shape(
                    CGRect(x: x - 5, y: y, width: 12, height: 8),
                    radius: 3,
                    fill: UIColor(hex: 0x081F2B),
                    stroke: UIColor(hex: 0x678089),
                    parent: car
                )
            }
        }
        _ = shape(
            CGRect(x: -26, y: -16, width: 52, height: 32),
            radius: 11,
            fill: color.withAlphaComponent(0.6),
            parent: car
        )
        _ = shape(
            CGRect(x: -25, y: -12, width: 51, height: 29),
            radius: 10,
            fill: color,
            stroke: UIColor.white.withAlphaComponent(0.48),
            width: 1.5,
            parent: car
        )
        _ = shape(
            CGRect(x: -14, y: -8, width: 26, height: 22),
            radius: 6,
            fill: UIColor(hex: 0x173C51),
            stroke: UIColor.white.withAlphaComponent(0.3),
            parent: car
        )
        _ = shape(
            CGRect(x: -12, y: -6, width: 17, height: 19),
            radius: 5,
            fill: color.withAlphaComponent(0.75),
            parent: car
        )
        _ = shape(
            CGRect(x: 7, y: -4, width: 5, height: 15),
            radius: 2,
            fill: UIColor(hex: 0xCCF7FD).withAlphaComponent(0.8),
            parent: car
        )
        _ = shape(
            CGRect(x: -26, y: -16, width: 6, height: 34),
            radius: 2,
            fill: color,
            stroke: UIColor(hex: 0x143641),
            parent: car
        )
        for y in [-8.0, 9.0] {
            _ = shape(
                CGRect(x: 21, y: y, width: 5, height: 5),
                radius: 2,
                fill: UIColor(hex: 0xFFFFD9),
                parent: car
            )
        }
        label(number, at: CGPoint(x: -4, y: -3), size: 9, color: .white, parent: car)
    }

    private func buildBall() {
        ballNode.zPosition = 7
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 41, height: 26))
        shadow.position = CGPoint(x: 3, y: -9)
        shadow.fillColor = .black.withAlphaComponent(0.24)
        shadow.strokeColor = .clear
        ballNode.addChild(shadow)
        let outer = SKShapeNode(circleOfRadius: 18)
        outer.fillColor = UIColor(hex: 0xF5F2D9)
        outer.strokeColor = UIColor(hex: 0xD0D5C5)
        outer.lineWidth = 2
        ballNode.addChild(outer)
        let path = CGMutablePath()
        for index in 0 ..< 6 {
            let a = Double(index) * .pi * 2 / 5 + .pi / 2
            let p = CGPoint(x: cos(a) * 7, y: sin(a) * 7)
            if index == 0 {
                path.move(to: p)
            } else {
                path.addLine(to: p)
            }
        }
        let patch = SKShapeNode(path: path)
        patch.fillColor = UIColor(hex: 0x355362)
        patch.strokeColor = .clear
        ballNode.addChild(patch)
        for index in 0 ..< 5 {
            let a = Double(index) * .pi * 2 / 5 + .pi / 2
            line(
                [CGPoint(x: cos(a) * 7, y: sin(a) * 7), CGPoint(x: cos(a) * 17, y: sin(a) * 17)],
                color: UIColor(hex: 0x54737D),
                width: 1,
                parent: ballNode
            )
        }
        let shine = SKShapeNode(ellipseOf: CGSize(width: 11, height: 5))
        shine.position = CGPoint(x: -6, y: 10)
        shine.fillColor = .white.withAlphaComponent(0.7)
        shine.strokeColor = .clear
        ballNode.addChild(shine)
    }

    override func update(_ currentTime: TimeInterval) {
        guard let store else { return }
        let delta = lastTime == 0 ? 0 : min(currentTime - lastTime, 0.05)
        lastTime = currentTime
        accumulator += delta
        while accumulator >= 1.0 / 120 {
            store.tick(1.0 / 120)
            accumulator -= 1.0 / 120
        }
        let engine = store.engine
        if store.screen == .title {
            idleTime += store.reducedMotion ? 0 : delta
            blueCar.position = CGPoint(x: -115, y: -40)
            blueCar.zRotation = 0.35
            orangeCar.position = CGPoint(x: 165, y: 55)
            orangeCar.zRotation = .pi + 0.4
            ballNode.position = CGPoint(x: 0, y: sin(idleTime * 1.3) * 5)
            targetRing.isHidden = true
            playerTag.isHidden = true
            return
        }
        playerTag.isHidden = false
        playerTag.position = CGPoint(x: engine.player.position.x, y: engine.player.position.y + 31)
        blueCar.position = engine.player.position.point
        blueCar.zRotation = engine.player.heading
        orangeCar.position = engine.opponent.position.point
        orangeCar.zRotation = engine.opponent.heading
        ballNode.position = engine.ball.point
        if !engine.paused {
            ballNode.zRotation += engine.ballVelocity.x * delta * 0.012
        }
        targetRing.isHidden = engine.driveTarget == nil || engine.phase != .playing
        if let target = engine.driveTarget {
            targetRing.position = target.point
        }
        trailTick += 1
        if trailTick.isMultiple(of: 3), !engine.paused, !store.reducedMotion, engine.phase == .playing {
            trail(car: engine.player, color: blue)
            trail(car: engine.opponent, color: orange)
        }
        let goals = engine.playerGoals + engine.opponentGoals
        if goals != lastGoalCount {
            lastGoalCount = goals
            if goals > 0 {
                celebrate(player: engine.lastScorerIsPlayer, reduced: store.reducedMotion)
            }
        }
    }

    private func trail(car: Car, color: UIColor) {
        guard car.velocity.length > 100 else { return }
        let boosting = car.velocity.length > 235
        let node = SKShapeNode(rectOf: CGSize(width: boosting ? 24 : 10, height: boosting ? 14 : 7), cornerRadius: 4)
        node.fillColor = color.withAlphaComponent(boosting ? 0.65 : 0.16)
        node.strokeColor = .clear
        node.position = (car.position - Vector(x: cos(car.heading), y: sin(car.heading)) * 30).point
        node.zRotation = car.heading
        node.zPosition = 2
        arena.addChild(node)
        node.run(.sequence([
            .group([.fadeOut(withDuration: 0.35), .scale(to: 0.3, duration: 0.35)]),
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
        ripple.glowWidth = 6
        ripple.zPosition = 9
        arena.addChild(ripple)
        ripple.run(.sequence([.group([.scale(to: reduced ? 2 : 9, duration: 0.7), .fadeOut(withDuration: 0.7)]),
                              .removeFromParent()]))
        guard !reduced else { return }
        for index in 0 ..< 34 {
            let confetti = SKShapeNode(rectOf: CGSize(width: 6, height: 11), cornerRadius: 2)
            confetti.fillColor = index.isMultiple(of: 3) ? .white : color
            confetti.strokeColor = .clear
            confetti.position = origin
            confetti.zPosition = 10
            arena.addChild(confetti)
            let a = Double(index) * 2.399
            let distance = Double(70 + index * 5)
            confetti.run(.sequence([.group([
                .moveBy(x: cos(a) * distance, y: sin(a) * distance, duration: 1.0),
                .rotate(byAngle: a, duration: 1.0), .fadeOut(withDuration: 1.0)
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

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255,
            alpha: 1
        )
    }
}
