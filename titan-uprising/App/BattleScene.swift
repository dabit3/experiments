import SpriteKit
import SwiftUI

@MainActor
final class BattleScene: SKScene {
  var audio: GameAudio?
  private let world = SKNode()
  private var figures: [SKSpriteNode] = []
  private var glows: [SKShapeNode] = []
  private var shields: [SKShapeNode] = []
  private var shadows: [SKShapeNode] = []
  private var latest: RoomState?
  private var localID = ""
  private var lastEvent = 0
  private var receivedAt: TimeInterval = 0
  private var clock: TimeInterval = 0
  private var textureCache: [String: SKTexture] = [:]
  private var previousHeroes = [-1, -1]
  private var banner: SKNode?

  override func didMove(to view: SKView) {
    backgroundColor = .black
    if world.parent != nil { return }
    addChild(world)
    let backdrop = SKSpriteNode(texture: SKTexture(image: GameArt.image("arena")))
    backdrop.name = "backdrop"
    backdrop.zPosition = -20
    world.addChild(backdrop)
    let shade = SKSpriteNode(color: UIColor(white: 0, alpha: 0.14), size: size)
    shade.name = "shade"
    shade.zPosition = -18
    world.addChild(shade)
    for i in 0..<2 {
      let shadow = SKShapeNode(ellipseOf: CGSize(width: 150, height: 24))
      shadow.fillColor = UIColor(white: 0, alpha: 0.65)
      shadow.strokeColor = .clear
      shadow.zPosition = -1
      world.addChild(shadow)
      shadows.append(shadow)
      let glow = SKShapeNode(ellipseOf: CGSize(width: 140, height: 18))
      glow.strokeColor = i == 0 ? .cyan : .orange
      glow.lineWidth = 2
      glow.glowWidth = 4
      glow.zPosition = 0
      world.addChild(glow)
      glows.append(glow)
      let sprite = SKSpriteNode()
      sprite.anchorPoint = CGPoint(x: 0.5, y: 0.08)
      sprite.zPosition = CGFloat(3 + i)
      world.addChild(sprite)
      figures.append(sprite)
      let shield = SKShapeNode(ellipseOf: CGSize(width: 80, height: 175))
      shield.strokeColor = .cyan
      shield.fillColor = UIColor.cyan.withAlphaComponent(0.1)
      shield.lineWidth = 3
      shield.glowWidth = 5
      shield.zPosition = 6
      shield.isHidden = true
      world.addChild(shield)
      shields.append(shield)
    }
    for i in 0..<42 {
      let streak = SKShapeNode(rectOf: CGSize(width: 0.7, height: CGFloat(8 + i % 9)))
      streak.fillColor = UIColor(red: 0.5, green: 0.75, blue: 0.9, alpha: 0.22)
      streak.strokeColor = .clear
      streak.position = CGPoint(x: CGFloat((i * 127) % 1100), y: CGFloat((i * 79) % 650))
      streak.zPosition = -2
      world.addChild(streak)
      streak.run(
        .repeatForever(
          .sequence([
            .moveBy(x: -50, y: -700, duration: 1.8 + Double(i % 5) * 0.1),
            .moveBy(x: 50, y: 700, duration: 0),
          ])))
    }
    resize()
  }

  override func didChangeSize(_ oldSize: CGSize) { resize() }

  private func resize() {
    let midpoint = CGPoint(x: size.width / 2, y: size.height / 2)
    if let backdrop = world.childNode(withName: "backdrop") as? SKSpriteNode {
      backdrop.size = CGSize(width: size.width, height: size.height)
      backdrop.position = midpoint
    }
    if let shade = world.childNode(withName: "shade") as? SKSpriteNode {
      shade.size = size
      shade.position = midpoint
    }
  }

  func apply(state: RoomState, localID: String) {
    if latest?.code != state.code {
      lastEvent = 0
      previousHeroes = [-1, -1]
      banner?.removeFromParent()
    }
    latest = state
    self.localID = localID
    receivedAt = clock
    guard figures.count == 2 else { return }
    for event in state.events where event.id > lastEvent {
      show(event, state: state)
      lastEvent = event.id
    }
  }

  private func texture(hero: Int, attacking: Bool) -> SKTexture {
    let key = "\(attacking ? "attacks" : "heroes")-\(hero)"
    if let cached = textureCache[key] { return cached }
    let texture = SKTexture(image: GameArt.image(key))
    texture.filteringMode = .linear
    textureCache[key] = texture
    return texture
  }

  override func update(_ currentTime: TimeInterval) {
    clock = currentTime
    guard let state = latest, figures.count == 2 else { return }
    let now = state.time + min(100, max(0, currentTime - receivedAt) * 1000)
    let h = min(size.height * 0.66, size.width * 0.36)
    let ground = size.height * 0.22
    for i in 0..<min(state.players.count, 2) {
      let p = state.players[i]
      let figure = figures[i]
      let direction: CGFloat = i == 0 ? 1 : -1
      let baseX = size.width * (i == 0 ? 0.365 : 0.635)
      let heroID = p.team[p.active]
      let age = max(0, now - p.actionAt)
      let duration = max(1, p.actionUntil - p.actionAt)
      let progress = min(1, age / duration)
      var lunge: CGFloat = 0
      var rise: CGFloat = sin(currentTime * 2.8 + Double(i)) * 2
      var rotation: CGFloat = 0
      var scale: CGFloat = 1
      var attacking = false
      if ["quick", "strong"].contains(p.action) {
        let windup = p.action == "quick" ? 0.36 : 0.53
        attacking = progress >= windup && progress < 0.86
        lunge = attacking ? h * 0.21 : -h * 0.035 * sin(progress * .pi)
        rotation = attacking ? -0.035 : 0.035
        if p.action == "strong" { rise += sin(progress * .pi) * 12 }
      } else if p.action == "special" {
        attacking = progress > 0.6
        rise += sin(progress * .pi) * h * 0.16
        scale = 1.04
        lunge = attacking ? h * 0.2 : -8
      } else if p.action == "hit" {
        lunge = -h * 0.1 * sin(progress * .pi)
        rotation = 0.12 * sin(progress * .pi)
      } else if p.action == "stun" {
        rotation = sin(currentTime * 20) * 0.025
        lunge = -12
      } else if p.action == "tag" {
        rise = sin(progress * .pi) * h * 0.28
        lunge = -h * 0.55 * (1 - progress)
      }
      figure.texture = texture(hero: heroID, attacking: attacking)
      figure.size = CGSize(width: h, height: h)
      figure.position = CGPoint(x: baseX + lunge * direction, y: ground + rise)
      figure.xScale = direction * scale
      figure.yScale = scale * (p.blocking ? 0.95 : 1)
      figure.zRotation = rotation * direction
      figure.color = .white
      figure.colorBlendFactor = p.action == "hit" ? 0.3 : 0
      figure.alpha = p.hp[p.active] > 0 ? 1 : 0.45
      shadows[i].position = CGPoint(x: baseX, y: ground + 3)
      glows[i].position = CGPoint(x: baseX, y: ground + 3)
      glows[i].strokeColor = UIColor(p.hero.color)
      glows[i].alpha = p.id == localID ? 0.85 : 0.4
      shields[i].position = CGPoint(x: baseX + direction * h * 0.28, y: ground + h * 0.48)
      shields[i].isHidden = !p.blocking
      shields[i].setScale(h / 250)
      if previousHeroes[i] != heroID {
        previousHeroes[i] = heroID
        burst(at: CGPoint(x: baseX, y: ground + h * 0.45), color: UIColor(p.hero.color), count: 24)
      }
    }
  }

  private func show(_ event: CombatEvent, state: RoomState) {
    let sourceIndex = state.players.firstIndex { $0.id == event.source } ?? 0
    let targetIndex = state.players.firstIndex { $0.id == event.target } ?? 1
    let targetX = size.width * (targetIndex == 0 ? 0.39 : 0.61)
    let sourceX = size.width * (sourceIndex == 0 ? 0.39 : 0.61)
    let point = CGPoint(x: targetX, y: size.height * 0.53)
    if ["hit", "block", "parry"].contains(event.type) {
      let color: UIColor =
        event.type == "hit" ? .init(red: 1, green: 0.8, blue: 0.35, alpha: 1) : .cyan
      burst(at: point, color: color, count: event.type == "hit" ? 22 : 12)
      impactRing(at: point, color: color)
      if event.type == "hit" {
        world.run(
          .sequence([
            .moveBy(x: 3, y: -2, duration: 0.035), .moveBy(x: -6, y: 3, duration: 0.035),
            .moveBy(x: 3, y: -1, duration: 0.035),
          ]))
      }
      floatText(
        event.amount == 0 ? "PARRY" : "\(event.amount)",
        point: CGPoint(x: targetX, y: size.height * 0.67),
        color: color, size: 32)
      if event.label != "STRIKE" {
        floatText(
          event.label, point: CGPoint(x: size.width / 2, y: size.height * 0.74), color: color,
          size: 18)
      }
      audio?.play(event.type == "hit" ? "hit" : "block")
    } else if event.type == "super" {
      audio?.play("super")
      guard state.players.indices.contains(sourceIndex) else { return }
      let hero = state.players[sourceIndex].hero
      cinematic(hero: hero, tier: event.amount, side: sourceIndex)
      impactRing(at: CGPoint(x: sourceX, y: size.height * 0.5), color: UIColor(hero.color))
    } else if event.type == "ko" {
      floatText("K.O.", point: point, color: .white, size: 64)
      audio?.play("ko")
      burst(at: point, color: .orange, count: 42)
    } else if event.type == "tag" {
      floatText(
        "TAG • \(event.label.uppercased())", point: CGPoint(x: sourceX, y: size.height * 0.72),
        color: .white, size: 16)
      audio?.play("tag")
    } else if event.type == "fight" {
      floatText(
        "FIGHT", point: CGPoint(x: size.width / 2, y: size.height * 0.5), color: .white, size: 56)
    }
  }

  private func burst(at point: CGPoint, color: UIColor, count: Int) {
    for i in 0..<count {
      let angle = Double(i) * .pi * 2 / Double(count)
      let length = CGFloat(20 + (i * 37) % 100)
      let spark = SKShapeNode(rectOf: CGSize(width: 3, height: 9))
      spark.fillColor = i % 3 == 0 ? .white : color
      spark.strokeColor = .clear
      spark.glowWidth = 2
      spark.position = point
      spark.zPosition = 15
      spark.zRotation = -angle
      world.addChild(spark)
      spark.run(
        .sequence([
          .group([
            .moveBy(x: cos(angle) * length, y: sin(angle) * length, duration: 0.35),
            .fadeOut(withDuration: 0.4), .scale(to: 0.1, duration: 0.4),
          ]), .removeFromParent(),
        ]))
    }
  }

  private func impactRing(at point: CGPoint, color: UIColor) {
    let path = CGMutablePath()
    for i in 0..<24 {
      let a = Double(i) * .pi * 2 / 24
      let r: Double = i % 2 == 0 ? 48 : 20
      let p = CGPoint(x: cos(a) * r, y: sin(a) * r)
      if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
    }
    path.closeSubpath()
    let ring = SKShapeNode(path: path)
    ring.fillColor = color.withAlphaComponent(0.3)
    ring.strokeColor = color
    ring.lineWidth = 2
    ring.glowWidth = 4
    ring.position = point
    ring.zPosition = 12
    world.addChild(ring)
    ring.run(
      .sequence([
        .group([.scale(to: 2, duration: 0.35), .fadeOut(withDuration: 0.35)]), .removeFromParent(),
      ]))
  }

  private func floatText(_ text: String, point: CGPoint, color: UIColor, size fontSize: CGFloat) {
    let label = SKLabelNode(fontNamed: "AvenirNextCondensed-HeavyItalic")
    label.text = text
    label.fontSize = fontSize
    label.fontColor = color
    label.position = point
    label.zPosition = 25
    world.addChild(label)
    label.run(
      .sequence([
        .group([
          .moveBy(x: 0, y: 22, duration: 0.8),
          .sequence([.wait(forDuration: 0.35), .fadeOut(withDuration: 0.45)]),
        ]), .removeFromParent(),
      ]))
  }

  private func cinematic(hero: Hero, tier: Int, side: Int) {
    banner?.removeFromParent()
    let panel = SKNode()
    panel.zPosition = 20
    let back = SKShapeNode(rectOf: CGSize(width: size.width * 0.56, height: 76))
    back.fillColor = UIColor(white: 0.02, alpha: 0.93)
    back.strokeColor = UIColor(hero.color)
    back.lineWidth = 2
    back.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
    panel.addChild(back)
    let portrait = SKSpriteNode(texture: texture(hero: hero.id, attacking: false))
    portrait.size = CGSize(width: 110, height: 110)
    portrait.position = CGPoint(x: size.width * 0.29, y: size.height * 0.65)
    panel.addChild(portrait)
    let name = SKLabelNode(fontNamed: "AvenirNextCondensed-HeavyItalic")
    name.text = hero.powerName
    name.fontColor = UIColor(hero.color)
    name.fontSize = 24
    name.position = CGPoint(x: size.width * 0.53, y: size.height * 0.65)
    panel.addChild(name)
    let sub = SKLabelNode(fontNamed: "AvenirNextCondensed-DemiBold")
    sub.text = "TIER \(tier)  /  RAPIDLY TAP SPECIAL TO AMPLIFY"
    sub.fontSize = 11
    sub.position = CGPoint(x: size.width * 0.53, y: size.height * 0.65 - 20)
    panel.addChild(sub)
    world.addChild(panel)
    panel.position.x = side == 0 ? -size.width : size.width
    panel.run(
      .sequence([
        .moveTo(x: 0, duration: 0.15), .wait(forDuration: 1.15),
        .group([
          .moveBy(x: side == 0 ? size.width : -size.width, y: 0, duration: 0.2),
          .fadeOut(withDuration: 0.2),
        ]), .removeFromParent(),
      ]))
    banner = panel
  }
}
