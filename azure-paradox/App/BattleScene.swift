import SpriteKit
import UIKit

@MainActor
final class BattleScene: SKScene {
  private let gold = UIColor(red: 0.91, green: 0.75, blue: 0.38, alpha: 1)
  private let cyan = UIColor(red: 0.22, green: 0.88, blue: 1, alpha: 1)
  private let navy = UIColor(red: 0.015, green: 0.035, blue: 0.12, alpha: 0.93)
  private let stage = SKNode()
  private let fighters = SKNode()
  private let effects = SKNode()
  private let hud = SKNode()
  private var actorNodes: [String: SKNode] = [:]
  private var textures: [String: SKTexture] = [:]
  private var latest: DuelState?
  private var previousEvent = 0
  private var lastTime: TimeInterval = 0
  private let floorY = 142.0

  override init() {
    super.init(size: CGSize(width: 1200, height: 600))
    backgroundColor = navy
    addChild(stage)
    stage.zPosition = 0
    fighters.zPosition = 10
    effects.zPosition = 20
    hud.zPosition = 50
    addChild(fighters)
    addChild(effects)
    addChild(hud)
    let backdrop = SKSpriteNode(imageNamed: "celestial-stage")
    backdrop.size = size
    backdrop.position = CGPoint(x: 600, y: 300)
    stage.addChild(backdrop)
    let tint = SKSpriteNode(
      color: UIColor(red: 0.03, green: 0.08, blue: 0.24, alpha: 0.2), size: size)
    tint.position = CGPoint(x: 600, y: 300)
    stage.addChild(tint)
    for index in 0..<34 {
      let sparkle = SKShapeNode(circleOfRadius: index % 3 == 0 ? 2 : 1)
      sparkle.fillColor = index % 4 == 0 ? gold : cyan
      sparkle.strokeColor = .clear
      sparkle.glowWidth = 3
      sparkle.position = CGPoint(
        x: Double((index * 173) % 1200), y: Double((index * 97) % 480) + 70)
      let motion = SKAction.sequence([
        .group([.moveBy(x: 16, y: 55, duration: 4), .fadeAlpha(to: 0.15, duration: 4)]),
        .group([.moveBy(x: -16, y: -55, duration: 0), .fadeAlpha(to: 0.75, duration: 1)]),
      ])
      sparkle.run(.repeatForever(motion))
      stage.addChild(sparkle)
    }
    let sigil = circle(radius: 170, color: gold.withAlphaComponent(0.2), line: 1)
    sigil.position = CGPoint(x: 600, y: 156)
    sigil.yScale = 0.17
    sigil.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 40)))
    stage.addChild(sigil)
    for character in ["seraph", "lyra"] {
      for pose in 0..<8 {
        let name = "\(character)-\(pose)"
        textures[name] = SKTexture(imageNamed: name)
      }
    }
  }

  required init?(coder aDecoder: NSCoder) { fatalError("Programmatic scene") }

  private func circle(radius: CGFloat, color: UIColor, line: CGFloat = 2) -> SKShapeNode {
    let node = SKShapeNode(circleOfRadius: radius)
    node.strokeColor = color
    node.lineWidth = line
    node.glowWidth = 1
    return node
  }

  private func label(
    _ text: String, x: Double, y: Double, size: CGFloat = 20,
    color: UIColor? = nil, font: String = "Georgia-Bold",
    alignment: SKLabelHorizontalAlignmentMode = .center, parent: SKNode? = nil
  ) {
    let node = SKLabelNode(fontNamed: font)
    node.text = text
    node.fontSize = size
    node.fontColor = color ?? gold
    node.position = CGPoint(x: x, y: y)
    node.horizontalAlignmentMode = alignment
    (parent ?? hud).addChild(node)
  }

  private func panel(x: Double, y: Double, width: Double, height: Double, parent: SKNode? = nil) {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: x + 14, y: y))
    path.addLines(between: [
      CGPoint(x: x + width - 14, y: y), CGPoint(x: x + width, y: y + height / 2),
      CGPoint(x: x + width - 14, y: y + height), CGPoint(x: x + 14, y: y + height),
      CGPoint(x: x, y: y + height / 2),
    ])
    path.closeSubpath()
    let node = SKShapeNode(path: path)
    node.fillColor = navy
    node.strokeColor = gold
    node.lineWidth = 2
    (parent ?? hud).addChild(node)
  }

  private func bar(
    x: Double, y: Double, width: Double, value: Double, color: UIColor, height: Double = 13,
    reverse: Bool = false
  ) {
    let track = SKShapeNode(rect: CGRect(x: x, y: y, width: width, height: height))
    track.fillColor = UIColor(white: 0.02, alpha: 0.85)
    track.strokeColor = gold.withAlphaComponent(0.7)
    track.lineWidth = 1
    hud.addChild(track)
    let length = max(0, min(1, value)) * (width - 4)
    if length > 0 {
      let fill = SKSpriteNode(color: color, size: CGSize(width: length, height: height - 4))
      fill.anchorPoint = CGPoint(x: reverse ? 1 : 0, y: 0)
      fill.position = CGPoint(x: reverse ? x + width - 2 : x + 2, y: y + 2)
      hud.addChild(fill)
      let shine = SKSpriteNode(
        color: .white.withAlphaComponent(0.5), size: CGSize(width: length, height: 2))
      shine.anchorPoint = fill.anchorPoint
      shine.position = CGPoint(x: fill.position.x, y: y + height - 4)
      hud.addChild(shine)
    }
  }

  func render(_ state: DuelState, localID: String) {
    latest = state
    AudioEngine.shared.startMusic()
    for player in state.players {
      if actorNodes[player.id] == nil {
        let root = SKNode()
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 130, height: 20))
        shadow.fillColor = .black.withAlphaComponent(0.35)
        shadow.strokeColor = .clear
        shadow.name = "shadow"
        root.addChild(shadow)
        let sprite = SKSpriteNode()
        sprite.name = "body"
        sprite.anchorPoint = CGPoint(x: 0.45, y: 0)
        sprite.zPosition = 2
        root.addChild(sprite)
        let aura = circle(radius: 82, color: cyan.withAlphaComponent(0.9), line: 2)
        aura.name = "barrier"
        aura.position.y = 100
        aura.yScale = 1.35
        aura.zPosition = 3
        root.addChild(aura)
        root.position = CGPoint(x: player.x, y: floorY + player.y)
        fighters.addChild(root)
        actorNodes[player.id] = root
      }
      guard let root = actorNodes[player.id],
        let body = root.childNode(withName: "body") as? SKSpriteNode
      else { continue }
      var pose = 0
      if player.guard || player.stun > 0 {
        pose = 2
      } else if player.y > 0 {
        pose = 3
      } else if abs(player.vx) > 0.5 {
        pose = 1
      }
      if !player.attack.isEmpty {
        switch player.attack {
        case "light": pose = 4
        case "medium": pose = 5
        case "heavy": pose = 6
        default: pose = 7
        }
        if player.attackTick < 4 { pose = 0 }
      }
      let texture = textures["\(player.character)-\(pose)"]
      body.texture = texture
      let textureSize = texture?.size() ?? CGSize(width: 350, height: 440)
      body.size = CGSize(width: textureSize.width * 0.59, height: textureSize.height * 0.59)
      body.xScale = player.face
      body.color = player.frozen > 0 ? cyan : player.stun > 0 ? .red : .white
      body.colorBlendFactor = player.frozen > 0 ? 0.65 : player.stun > 0 ? 0.25 : 0
      root.childNode(withName: "barrier")?.isHidden = !player.guard
      root.childNode(withName: "shadow")?.alpha = player.y > 0 ? 0 : 1
      if player.dash > 0 && state.tick % 4 == 0 {
        let ghost = SKSpriteNode(texture: texture)
        ghost.size = body.size
        ghost.anchorPoint = body.anchorPoint
        ghost.xScale = player.face
        ghost.position = root.position
        ghost.alpha = 0.24
        ghost.color = cyan
        ghost.colorBlendFactor = 0.75
        ghost.zPosition = 1
        fighters.addChild(ghost)
        ghost.run(.sequence([.fadeOut(withDuration: 0.24), .removeFromParent()]))
      }
    }
    for node in effects.children where node.name == "projectile" { node.removeFromParent() }
    for shot in state.projectiles {
      let node = SKNode()
      node.name = "projectile"
      node.position = CGPoint(x: shot.x, y: floorY + shot.y)
      node.xScale = shot.face
      let path = CGMutablePath()
      path.move(to: CGPoint(x: -36, y: 0))
      path.addLines(between: [CGPoint(x: 0, y: 18), CGPoint(x: 43, y: 0), CGPoint(x: 0, y: -18)])
      path.closeSubpath()
      let shard = SKShapeNode(path: path)
      shard.fillColor = cyan
      shard.strokeColor = .white
      shard.lineWidth = 2
      shard.glowWidth = 14
      node.addChild(shard)
      effects.addChild(node)
    }
    for event in state.events where event.id > previousEvent {
      show(event, state: state)
    }
    previousEvent = state.events.last?.id ?? previousEvent
    drawHUD(state, localID: localID)
  }

  override func update(_ currentTime: TimeInterval) {
    let elapsed = min(0.05, currentTime - lastTime)
    lastTime = currentTime
    guard let latest else { return }
    for player in latest.players {
      guard let node = actorNodes[player.id] else { continue }
      let factor = min(1, elapsed * 28)
      node.position.x += (player.x - node.position.x) * factor
      node.position.y += (floorY + player.y - node.position.y) * factor
      if player.attack.isEmpty && player.stun == 0 {
        node.childNode(withName: "body")?.yScale =
          1 + sin(currentTime * 3.2 + Double(player.slot)) * 0.008
      }
    }
  }

  private func drawHUD(_ state: DuelState, localID: String) {
    hud.removeAllChildren()
    panel(x: 26, y: 498, width: 514, height: 76)
    panel(x: 660, y: 498, width: 514, height: 76)
    for player in state.players {
      let left = player.slot == 0
      let start = left ? 104.0 : 688.0
      let alignment: SKLabelHorizontalAlignmentMode = left ? .left : .right
      let nameX = left ? 105.0 : 1095.0
      let lifeColor =
        player.hp > 300 ? UIColor(red: 0.98, green: 0.81, blue: 0.27, alpha: 1) : .systemRed
      bar(
        x: start, y: 540, width: 405, value: player.hp / 1000, color: lifeColor, height: 19,
        reverse: !left)
      bar(
        x: start, y: 524, width: 330, value: player.barrier / 100,
        color: player.danger > 0 ? .red : cyan, height: 7, reverse: !left)
      label(
        player.character.uppercased(), x: nameX, y: 500, size: 22, color: .white,
        alignment: alignment)
      label(
        "\(player.name)  \(player.id == localID ? "• YOU" : "• PEER")", x: nameX, y: 581,
        size: 13, color: cyan, font: "AvenirNext-DemiBold", alignment: alignment)
      label(
        player.danger > 0 ? "DANGER" : "BARRIER", x: left ? 457 : 741, y: 524,
        size: 9, color: gold, font: "AvenirNext-Bold")
      let portrait = SKSpriteNode(texture: textures["\(player.character)-0"])
      portrait.size = CGSize(width: 66, height: 86)
      portrait.position = CGPoint(x: left ? 65 : 1135, y: 542)
      portrait.xScale = left ? 1 : -1
      hud.addChild(portrait)
      for win in 0..<2 {
        let jewel = circle(radius: 7, color: gold, line: 1.5)
        jewel.fillColor = win < player.wins ? cyan : navy
        jewel.position = CGPoint(x: left ? 473 + Double(win * 22) : 705 + Double(win * 22), y: 510)
        hud.addChild(jewel)
      }
      let meterX = left ? 306.0 : 676.0
      panel(x: meterX - 12, y: 108, width: 240, height: 35)
      bar(
        x: meterX, y: 116, width: 214, value: player.heat / 100,
        color: player.heat >= 50 ? gold : cyan, height: 10, reverse: !left)
      label(
        "HEAT  \(Int(player.heat))%\(player.heat >= 50 ? "  •  SUPER" : "")",
        x: meterX + 107, y: 132, size: 11, color: player.heat >= 50 ? gold : .white,
        font: "AvenirNext-Bold")
      if player.comboTimer > 0 && player.combo > 0 {
        let x = left ? 165.0 : 1035.0
        label("HEAT", x: x, y: 427, size: 18, color: gold)
        label(
          "\(player.combo)", x: x, y: 370, size: 62, color: left ? .systemRed : cyan,
          font: "Georgia-BoldItalic")
        label(
          "\(player.comboDamage) DAMAGE", x: x, y: 350, size: 12, color: .white,
          font: "AvenirNext-DemiBold")
      }
    }
    let clockCircle = circle(radius: 46, color: gold, line: 3)
    clockCircle.fillColor = navy
    clockCircle.position = CGPoint(x: 600, y: 545)
    hud.addChild(clockCircle)
    let inner = circle(radius: 39, color: cyan, line: 1)
    inner.position = clockCircle.position
    hud.addChild(inner)
    label(
      String(format: "%02d", state.clock), x: 600, y: 529, size: 43, color: .white,
      font: "Georgia-BoldItalic")
    label("DUEL \(state.round)", x: 600, y: 488, size: 12)
    label(
      "\(state.code)  ·  \(state.players.filter(\.connected).count)/2 PEERS  ·  60 Hz",
      x: 600, y: 469, size: 10, color: cyan, font: "AvenirNext-DemiBold")
    if state.phase == "countdown" {
      banner(
        "REBEL AGAINST FATE",
        sub: "DUEL \(state.round)   /   \(max(1, Int(ceil(Double(state.phaseTicks) / 60))))")
    } else if state.phase == "roundEnd" {
      let winner = state.players.first { $0.id == state.roundWinner }
      banner("FINISH", sub: winner.map { "\($0.name.uppercased()) TAKES THE ROUND" } ?? "DRAW")
    } else if state.paused {
      banner("LINK INTERRUPTED", sub: "DUEL PAUSED · REJOIN WITHIN 30 SECONDS")
    }
  }

  private func banner(_ text: String, sub: String) {
    panel(x: 310, y: 270, width: 580, height: 110)
    label(text, x: 600, y: 325, size: 34, color: .white, font: "Georgia-BoldItalic")
    label(sub, x: 600, y: 292, size: 16, color: gold, font: "AvenirNext-DemiBold")
  }

  private func show(_ event: CombatEvent, state: DuelState) {
    let player = state.players.first { $0.id == event.player }
    if event.kind == "attack", let player {
      AudioEngine.shared.play("swing")
      if ["light", "medium", "heavy"].contains(event.text.lowercased()) {
        let arc = CGMutablePath()
        arc.move(to: CGPoint(x: -30, y: -65))
        arc.addQuadCurve(to: CGPoint(x: 170, y: 30), control: CGPoint(x: 250, y: 210))
        let slash = SKShapeNode(path: arc)
        slash.strokeColor = player.character == "seraph" ? .systemRed : cyan
        slash.lineWidth = event.text == "HEAVY" ? 13 : 7
        slash.glowWidth = 14
        slash.position = CGPoint(x: player.x, y: floorY + player.y + 115)
        slash.xScale = player.face
        effects.addChild(slash)
        slash.run(
          .sequence([
            .group([.fadeOut(withDuration: 0.28), .scale(to: 1.2, duration: 0.28)]),
            .removeFromParent(),
          ]))
      }
    }
    if event.kind == "hit" || event.kind == "block" {
      AudioEngine.shared.play(event.kind == "hit" ? "hit" : "block")
      let origin = CGPoint(x: event.x ?? 600, y: floorY + (event.y ?? 0) + 100)
      for index in 0..<12 {
        let angle = Double(index) * .pi / 6 + Double(event.id % 6) * 0.1
        let length = event.kind == "hit" ? 80.0 : 55.0
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: cos(angle) * length, y: sin(angle) * length))
        let ray = SKShapeNode(path: path)
        ray.strokeColor = index % 3 == 0 ? .white : event.kind == "hit" ? gold : cyan
        ray.lineWidth = CGFloat(index % 3 + 2)
        ray.glowWidth = 8
        ray.position = origin
        effects.addChild(ray)
        ray.run(
          .sequence([
            .group([.scale(to: 1.5, duration: 0.26), .fadeOut(withDuration: 0.26)]),
            .removeFromParent(),
          ]))
      }
      let ring = circle(radius: 30, color: .white, line: 3)
      ring.position = origin
      effects.addChild(ring)
      ring.run(
        .sequence([
          .group([.scale(to: 2.6, duration: 0.25), .fadeOut(withDuration: 0.25)]),
          .removeFromParent(),
        ]))
      if event.text == "COUNTER" || event.text == "FROST BIND" || event.kind == "block" {
        let callout = SKNode()
        label(event.text, x: origin.x, y: origin.y + 120, size: 22, color: cyan, parent: callout)
        effects.addChild(callout)
        callout.run(
          .sequence([
            .moveBy(x: 0, y: 20, duration: 0.45), .fadeOut(withDuration: 0.2), .removeFromParent(),
          ]))
      }
      if event.kind == "hit" {
        stage.run(
          .sequence([
            .moveBy(x: -4, y: 1, duration: 0.035), .moveBy(x: 7, y: -2, duration: 0.035),
            .moveTo(x: 0, duration: 0.04), .moveTo(y: 0, duration: 0),
          ]))
      }
    }
    if event.kind == "super", let player {
      AudioEngine.shared.play("super")
      let flash = SKSpriteNode(color: navy.withAlphaComponent(0.7), size: size)
      flash.position = CGPoint(x: 600, y: 300)
      effects.addChild(flash)
      for radius in [70.0, 100, 120] {
        let seal = circle(
          radius: radius, color: player.character == "seraph" ? .systemRed : cyan, line: 3)
        seal.position = CGPoint(x: player.x, y: floorY + player.y + 120)
        for index in 0..<12 {
          let gem = SKShapeNode(rectOf: CGSize(width: 7, height: 7))
          gem.fillColor = gold
          gem.strokeColor = .white
          let angle = Double(index) * .pi / 6
          gem.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
          gem.zRotation = angle
          seal.addChild(gem)
        }
        effects.addChild(seal)
        seal.run(
          .sequence([
            .group([.rotate(byAngle: .pi, duration: 0.9), .scale(to: 2, duration: 0.9)]),
            .fadeOut(withDuration: 0.3), .removeFromParent(),
          ]))
      }
      let title = SKNode()
      label("DISTORTION", x: 600, y: 400, size: 18, color: cyan, parent: title)
      label(
        event.text, x: 600, y: 353, size: 40, color: .white, font: "Georgia-BoldItalic",
        parent: title)
      effects.addChild(title)
      title.run(
        .sequence([.wait(forDuration: 0.65), .fadeOut(withDuration: 0.3), .removeFromParent()]))
      flash.run(.sequence([.fadeOut(withDuration: 0.8), .removeFromParent()]))
    }
    if event.kind == "start" {
      let node = SKNode()
      label(
        "ENGAGE", x: 600, y: 305, size: 64, color: .white, font: "Georgia-BoldItalic", parent: node)
      effects.addChild(node)
      node.run(
        .sequence([
          .wait(forDuration: 0.6),
          .group([.scale(to: 1.5, duration: 0.2), .fadeOut(withDuration: 0.2)]),
          .removeFromParent(),
        ]))
    }
  }
}
