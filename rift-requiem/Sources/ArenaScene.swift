import SpriteKit

@MainActor
final class ArenaScene: SKScene {
    var match: MatchState?
    var previewStyle: String?
    private var artists: [String: FighterArt] = [:]
    private let world = SKNode()
    private let shots = SKNode()
    private let effects = SKNode()
    private var lastEvent = 0
    private var lastPhase = ""
    private let floor: CGFloat = 137
    private var initialized = false

    override func didMove(to view: SKView) {
        guard !initialized else { return }
        initialized = true
        backgroundColor = Ink.black
        addChild(world)
        let backdrop = SKSpriteNode(imageNamed: "cathedral")
        backdrop.size = CGSize(width: 1100, height: 670)
        backdrop.position = CGPoint(x: 550, y: 330)
        backdrop.zPosition = -20
        world.addChild(backdrop)
        let shade = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.20), size: size)
        shade.position = CGPoint(x: 550, y: 260)
        shade.zPosition = -19
        world.addChild(shade)
        for index in 0..<28 {
            let ember = SKShapeNode(circleOfRadius: CGFloat(index % 3 + 1))
            ember.fillColor = index % 2 == 0 ? Ink.gold : Ink.red
            ember.strokeColor = .clear
            ember.position = CGPoint(x: CGFloat(index * 43), y: CGFloat(index * 31 % 500))
            ember.zPosition = -2
            world.addChild(ember)
            let float = SKAction.moveBy(x: 40, y: 150, duration: Double(4 + index % 5))
            ember.run(.repeatForever(.sequence([float, .moveBy(x: -40, y: -150, duration: 0)])))
        }
        world.addChild(shots)
        world.addChild(effects)
        effects.zPosition = 30
        if let style = previewStyle {
            let artist = FighterArt(style: style)
            artist.position = CGPoint(x: 550, y: 130)
            artist.setScale(1.25)
            world.addChild(artist)
            artists["preview"] = artist
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if let artist = artists["preview"] {
            artist.animate(pose: "idle", frame: 0, time: currentTime, facing: 1, stunned: false)
            artist.xScale = 1.25
            return
        }
        guard let state = match else { return }
        for player in state.players {
            if artists[player.id] == nil {
                let shadow = SKShapeNode(ellipseOf: CGSize(width: 120, height: 20))
                shadow.name = "shadow-\(player.id)"
                shadow.fillColor = UIColor.black.withAlphaComponent(0.55)
                shadow.strokeColor = .clear
                world.addChild(shadow)
                let artist = FighterArt(style: player.style)
                artist.zPosition = 5
                artists[player.id] = artist
                world.addChild(artist)
            }
            guard let artist = artists[player.id] else { continue }
            let target = CGPoint(x: player.x, y: Double(floor) + player.y)
            if artist.position == .zero || state.phase == "countdown" {
                artist.position = target
            } else {
                artist.position.x += (target.x - artist.position.x) * 0.5
                artist.position.y += (target.y - artist.position.y) * 0.5
            }
            artist.animate(pose: player.pose, frame: player.frame, time: currentTime,
                           facing: player.facing, stunned: player.stun > 0)
            world.childNode(withName: "shadow-\(player.id)")?.position = CGPoint(x: player.x, y: floor)
            if player.pose == "dash" && Int(currentTime * 60) % 4 == 0 {
                speedLines(at: artist.position, direction: player.facing)
            }
        }
        shots.removeAllChildren()
        for shot in state.projectiles {
            let node = SKNode()
            node.position = CGPoint(x: shot.x, y: Double(floor) + shot.y)
            node.xScale = shot.direction
            shots.addChild(node)
            polygon([(-60, 0), (-26, 22), (-6, 30), (37, 0), (-6, -30),
                     (-26, -22)], shot.style == "rook" ? Ink.red : Ink.light, on: node,
                    line: Ink.cream, width: 3)
            polygon([(-43, 0), (-9, 9), (25, 0), (-9, -9)], Ink.cream, on: node, width: 0)
            ring(27, at: .zero, on: node, color: Ink.gold, width: 2).zRotation = CGFloat(currentTime * 8)
        }
        for event in state.events where event.id > lastEvent {
            lastEvent = event.id
            show(event)
        }
        if state.phase != lastPhase {
            lastPhase = state.phase
            if state.phase == "fight" { announce("LET IT RIFT", color: Ink.cream, duration: 0.8) }
        }
    }

    private func speedLines(at point: CGPoint, direction: Double) {
        let node = SKNode()
        node.position = CGPoint(x: point.x, y: point.y + 90)
        node.xScale = direction
        effects.addChild(node)
        for index in 0..<4 {
            let height = CGFloat(index * 30)
            polygon([(-120, height), (-15, height + 3), (15, height), (-10, height - 2)],
                    Ink.cream.withAlphaComponent(0.5), on: node, width: 0)
        }
        node.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
    }

    private func show(_ event: CombatEvent) {
        let point = CGPoint(x: event.x, y: Double(floor) + event.y + 90)
        switch event.type {
        case "hit", "block":
            let color = event.type == "block" ? Ink.light : Ink.cream
            let spark = SKNode()
            spark.position = point
            effects.addChild(spark)
            for index in 0..<12 {
                let angle = CGFloat(index) * .pi / 6
                let length: CGFloat = index % 3 == 0 ? 140 : 60
                let shard = polygon([(0, 0), (length, 5), (length * 0.6, 10)],
                                    index % 2 == 0 ? color : Ink.red, on: spark, width: 0)
                shard.zRotation = angle
            }
            ring(event.type == "block" ? 70 : 32, at: .zero, on: spark, color: color, width: 6)
            spark.run(.sequence([.group([.scale(to: 1.5, duration: 0.25),
                                        .fadeOut(withDuration: 0.28)]), .removeFromParent()]))
            if event.type == "hit" {
                world.run(.sequence([.moveBy(x: 6, y: 0, duration: 0.035),
                                     .moveBy(x: -11, y: 0, duration: 0.035),
                                     .moveBy(x: 5, y: 0, duration: 0.035)]))
            }
            if let text = event.text {
                combatWord(text, at: CGPoint(x: event.x < 550 ? 260 : 840, y: 345),
                           color: event.counter == true ? Ink.red : color)
            }
            Sound.shared.play(event.type)
        case "cancel":
            let color = event.color == "YELLOW" ? Ink.gold : event.color == "RED" ? Ink.red : .magenta
            let pulse = SKNode()
            pulse.position = point
            effects.addChild(pulse)
            for radius: CGFloat in [45, 65, 95] {
                ring(radius, at: .zero, on: pulse, color: color, width: 6)
            }
            polygon([(-110, 0), (0, 12), (110, 0), (0, -12)], Ink.cream, on: pulse, width: 0)
            pulse.run(.sequence([.group([.scale(to: 2.0, duration: 0.6),
                                        .fadeOut(withDuration: 0.6)]), .removeFromParent()]))
            combatWord(event.text ?? "REQUIEM", at: CGPoint(x: 550, y: 360), color: color)
            Sound.shared.play("cancel")
        case "attack":
            Sound.shared.play("slash")
        case "finish":
            announce(event.text ?? "SLASH!", color: Ink.red, duration: 1.3)
            Sound.shared.play("finish")
        case "round":
            Sound.shared.play("cancel")
        default: break
        }
    }

    private func combatWord(_ text: String, at point: CGPoint, color: UIColor) {
        let label = SKLabelNode(fontNamed: "AvenirNextCondensed-HeavyItalic")
        label.text = text
        label.fontSize = 38
        label.fontColor = color
        label.position = point
        label.zRotation = 0.08
        effects.addChild(label)
        label.run(.sequence([.group([.moveBy(x: 0, y: 20, duration: 0.5),
                                     .fadeOut(withDuration: 0.65)]), .removeFromParent()]))
    }

    private func announce(_ text: String, color: UIColor, duration: Double) {
        let node = SKNode()
        node.position = CGPoint(x: 550, y: 280)
        effects.addChild(node)
        polygon([(-560, -45), (540, -20), (560, 65), (-540, 40)],
                Ink.black.withAlphaComponent(0.90), on: node, line: Ink.gold, width: 2)
        let title = SKLabelNode(fontNamed: "AvenirNextCondensed-HeavyItalic")
        title.text = text
        title.fontSize = 80
        title.fontColor = color
        title.verticalAlignmentMode = .center
        title.zRotation = 0.025
        node.addChild(title)
        node.setScale(1.25)
        node.run(.sequence([.scale(to: 1, duration: 0.10), .wait(forDuration: duration),
                            .fadeOut(withDuration: 0.20), .removeFromParent()]))
    }
}
