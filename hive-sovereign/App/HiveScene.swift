import SpriteKit
import UIKit

@MainActor
final class HiveScene: SKScene {
  weak var connection: GameConnection?
  let audio = HiveAudio()
  private let landscape = SKNode()
  private let dynamic = SKNode()
  private let hud = SKNode()
  private var unitNodes: [String: SKNode] = [:]
  private var berryNodes: [String: SKSpriteNode] = [:]
  private var gateNodes: [SKNode] = []
  private var holes: [[SKShapeNode]] = [[], []]
  private var eggs: [[SKShapeNode]] = [[], []]
  private let snail = SKSpriteNode()
  private var current: Envelope?
  private var lastEvent = 0
  private var match = -1
  private var animationFrame = -1
  private var textureCache: [String: SKTexture] = [:]
  private var built = false
  private let topBlue = SKLabelNode(fontNamed: "Menlo-Bold")
  private let topGold = SKLabelNode(fontNamed: "Menlo-Bold")
  private let status = SKLabelNode(fontNamed: "Menlo-Bold")
  private let snailTrack = SKSpriteNode(color: PixelArt.ink, size: CGSize(width: 300, height: 4))
  private let snailMarker = SKSpriteNode(color: .white, size: CGSize(width: 7, height: 8))

  override init() {
    super.init(size: CGSize(width: 960, height: 540))
    scaleMode = .aspectFit
    backgroundColor = PixelArt.ink
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func didMove(to view: SKView) {
    guard !built else { return }
    built = true
    view.preferredFramesPerSecond = 60
    let sky = SKSpriteNode(texture: PixelArt.sky(), size: size)
    sky.position = CGPoint(x: 480, y: 270)
    addChild(sky)
    addChild(landscape)
    dynamic.zPosition = 5
    addChild(dynamic)
    hud.zPosition = 30
    addChild(hud)
    buildArena()
    audio.start()
    if let current { apply(current) }
  }

  private func rect(
    _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: UIColor, parent: SKNode
  ) {
    let node = SKSpriteNode(color: color, size: CGSize(width: w, height: h))
    node.anchorPoint = .zero
    node.position = CGPoint(x: x, y: y)
    parent.addChild(node)
  }

  @discardableResult
  private func label(
    _ text: String, x: Double, y: Double, size: Double = 12, color: UIColor = .white, parent: SKNode
  ) -> SKLabelNode {
    let node = SKLabelNode(fontNamed: "Menlo-Bold")
    node.text = text
    node.fontSize = size
    node.fontColor = color
    node.position = CGPoint(x: x, y: y)
    parent.addChild(node)
    return node
  }

  private func buildArena() {
    let platforms: [(Double, Double, Double)] = [
      (0, 65, 960), (25, 150, 175), (760, 150, 175), (345, 145, 270),
      (145, 235, 170), (645, 235, 170), (420, 230, 120),
      (260, 315, 160), (540, 315, 160), (330, 395, 300),
      (0, 320, 100), (860, 320, 100),
    ]
    for (index, p) in platforms.enumerated() {
      rect(p.0, p.1 - 14, p.2, 14, UIColor(hex: 0x80672b), parent: landscape)
      rect(p.0, p.1 - 3, p.2, 5, UIColor(hex: 0x587c38), parent: landscape)
      for n in 0..<Int(p.2 / 4) {
        let x = p.0 + Double(n * 4)
        let seed = (n * 17 + index * 13) % 11
        rect(x, p.1 + 2, 2, Double(seed % 4 + 1), UIColor(hex: 0x97bd5e), parent: landscape)
        rect(
          x, p.1 - Double(seed % 8 + 5), 2, 2, UIColor(hex: seed % 2 == 0 ? 0xb89d48 : 0x4b552c),
          parent: landscape)
      }
      if index > 0 {
        let x = p.0 + p.2 * 0.7
        for n in 0..<(index % 5 + 5) {
          rect(
            x + Double(n % 2) * 2, p.1 - 18 - Double(n * 6), 2, 5, UIColor(hex: 0x467c50),
            parent: landscape)
          if n % 2 == 0 {
            rect(x - 3, p.1 - 18 - Double(n * 6), 5, 2, UIColor(hex: 0x78a566), parent: landscape)
          }
        }
      }
    }
    for team in 0..<2 {
      let x = team == 0 ? 343.0 : 503.0
      rect(x - 5, 397, 119, 89, PixelArt.ink, parent: landscape)
      rect(x, 397, 109, 93, UIColor(hex: team == 0 ? 0x277bb6 : 0xb8732e), parent: landscape)
      for i in 0..<80 {
        let px = x + Double((i * 43) % 104)
        let py = 400 + Double((i * 17) % 88)
        rect(px, py, 4, 2, PixelArt.team(team).withAlphaComponent(0.23), parent: landscape)
      }
      for i in 0..<12 {
        let hole = SKShapeNode(rectOf: CGSize(width: 12, height: 9), cornerRadius: 3)
        hole.fillColor = PixelArt.ink
        hole.strokeColor = PixelArt.ink
        hole.position = CGPoint(x: x + 26 + Double(i % 4) * 19, y: 470 - Double(i / 4) * 13)
        landscape.addChild(hole)
        holes[team].append(hole)
      }
      for i in 0..<3 {
        let egg = SKShapeNode(ellipseOf: CGSize(width: 16, height: 22))
        egg.fillColor = PixelArt.gold
        egg.strokeColor = UIColor(hex: 0xfff0b7)
        egg.lineWidth = 2
        egg.position = CGPoint(x: x + 28 + Double(i) * 26, y: 412)
        landscape.addChild(egg)
        eggs[team].append(egg)
      }
      label(
        team == 0 ? "AZURE HIVE" : "AMBER HIVE", x: x + 54, y: 382, size: 8, color: PixelArt.ink,
        parent: landscape)
      let basketX = team == 0 ? 18.0 : 906.0
      for i in 0..<5 {
        rect(
          basketX + Double(i * 7), 65, 2, 29 - Double(i % 2) * 4, PixelArt.team(team),
          parent: landscape)
      }
      for i in 0..<4 {
        rect(basketX, 67 + Double(i * 7), 36, 2, PixelArt.team(team), parent: landscape)
      }
      label(
        team == 0 ? "◀" : "▶", x: basketX + 18, y: 99, size: 15, color: PixelArt.team(team),
        parent: landscape)
    }
    let gatePositions: [(Double, Double, Bool)] = [
      (280, 235, true), (680, 235, true), (480, 230, true), (105, 150, false), (855, 150, false),
    ]
    for (x, y, wings) in gatePositions {
      let gate = SKNode()
      gate.position = CGPoint(x: x, y: y)
      rect(-14, 0, 28, 28, PixelArt.ink, parent: gate)
      rect(-11, 2, 4, 24, UIColor(hex: 0x7e9a9e), parent: gate)
      rect(7, 2, 4, 24, UIColor(hex: 0x7e9a9e), parent: gate)
      let glow = SKSpriteNode(color: .white, size: CGSize(width: 12, height: 20))
      glow.name = "glow"
      glow.alpha = 0.28
      glow.position = CGPoint(x: 0, y: 12)
      gate.addChild(glow)
      if wings {
        for s in [-1.0, 1.0] {
          for i in 0..<5 {
            rect(
              s * Double(i * 5 + 4) - 3, 31 + Double(i * 2), 6, Double(8 - i),
              UIColor(hex: 0xe7f1dd), parent: gate)
          }
        }
      } else {
        label("»", x: 0, y: 29, size: 25, color: PixelArt.gold, parent: gate)
      }
      landscape.addChild(gate)
      gateNodes.append(gate)
    }
    snail.texture = PixelArt.snail(frame: 0)
    snail.size = CGSize(width: 66, height: 28)
    snail.anchorPoint = CGPoint(x: 0.5, y: 0)
    snail.position = CGPoint(x: 480, y: 65)
    dynamic.addChild(snail)
    rect(0, 0, 960, 51, PixelArt.ink, parent: hud)
    rect(0, 499, 960, 41, PixelArt.ink, parent: hud)
    rect(0, 497, 960, 2, PixelArt.gold, parent: hud)
    label("HIVE SOVEREIGN", x: 480, y: 520, size: 15, color: PixelArt.gold, parent: hud)
    for (node, x, color) in [(topBlue, 205.0, PixelArt.blue), (topGold, 755.0, PixelArt.gold)] {
      node.fontSize = 13
      node.fontColor = color
      node.position = CGPoint(x: x, y: 519)
      hud.addChild(node)
    }
    status.fontSize = 9
    status.fontColor = UIColor(hex: 0xc2d9e2)
    status.position = CGPoint(x: 480, y: 504)
    hud.addChild(status)
    label("SNAIL ROUTE", x: 480, y: 36, size: 8, color: UIColor(hex: 0xbad5db), parent: hud)
    snailTrack.color = UIColor(hex: 0x45606f)
    snailTrack.position = CGPoint(x: 480, y: 26)
    hud.addChild(snailTrack)
    snailMarker.position = CGPoint(x: 480, y: 26)
    hud.addChild(snailMarker)
    label("AZURE", x: 300, y: 23, size: 8, color: PixelArt.blue, parent: hud)
    label("AMBER", x: 660, y: 23, size: 8, color: PixelArt.gold, parent: hud)
    label(
      "12 BERRIES  /  3 QUEEN EGGS  /  1 SNAIL", x: 480, y: 9, size: 8,
      color: UIColor(hex: 0x8ba4b3), parent: hud)
    topBlue.text = "AZURE  ·  0 / 12   ♛ 3"
    topGold.text = "AMBER  ·  0 / 12   ♛ 3"
    status.text = "TWO CAPTAINS. THREE WAYS TO WIN."
  }

  func apply(_ envelope: Envelope) {
    current = envelope
    guard built, let game = envelope.game else { return }
    if match != envelope.match {
      match = envelope.match ?? 0
      lastEvent = 0
    }
    topBlue.text = "AZURE  \(game.score[0])/12  ·  EGGS \(game.lives[0])"
    topGold.text = "AMBER  \(game.score[1])/12  ·  EGGS \(game.lives[1])"
    let minutes = Int(game.time) / 60
    let seconds = Int(game.time) % 60
    status.text =
      "\(envelope.room ?? "")  •  \(String(format: "%02d:%02d", minutes, seconds))  •  \(envelope.paused == true ? "PEER DISCONNECTED — PAUSED" : "LIVE  /  30 Hz")"
    for team in 0..<2 {
      for (i, hole) in holes[team].enumerated() {
        hole.fillColor = i < game.score[team] ? UIColor(hex: 0xed6fe8) : PixelArt.ink
        hole.strokeColor = i == game.score[team] ? .white : PixelArt.ink
        hole.lineWidth = i == game.score[team] ? 2 : 1
      }
      for (i, egg) in eggs[team].enumerated() { egg.alpha = i < game.lives[team] ? 1 : 0.15 }
    }
    for (i, gate) in game.gates.enumerated() where i < gateNodes.count {
      if let glow = gateNodes[i].childNode(withName: "glow") as? SKSpriteNode {
        glow.color = gate.team < 0 ? .white : PixelArt.team(gate.team)
        glow.alpha = 0.6
      }
    }
    let active = Set(game.berries.map(\.id))
    for (id, node) in berryNodes where !active.contains(id) {
      node.removeFromParent()
      berryNodes.removeValue(forKey: id)
    }
    for berry in game.berries {
      if berryNodes[berry.id] == nil {
        let node = SKSpriteNode(texture: PixelArt.berry())
        node.size = CGSize(width: 10, height: 10)
        dynamic.addChild(node)
        berryNodes[berry.id] = node
      }
      let stack = Int(berry.id.split(separator: "-").last ?? "0") ?? 0
      berryNodes[berry.id]?.position = CGPoint(x: berry.x, y: berry.y + 6 + Double(stack / 3) * 7)
    }
    for unit in game.units {
      let node = unitNodes[unit.id] ?? makeUnit(unit)
      node.isHidden = unit.dead > 0
      let destination = CGPoint(x: unit.x, y: unit.y)
      if abs(node.position.x - destination.x) > 400 {
        node.position = destination
      } else {
        node.run(.move(to: destination, duration: 0.075), withKey: "move")
      }
      let isMe = unit.human && unit.team == connection?.team
      let name = envelope.peers?.first { $0.team == unit.team }?.name ?? "Captain"
      if let tag = node.childNode(withName: "tag") as? SKLabelNode {
        tag.text =
          unit.human
          ? (isMe ? "▼ YOU" : name.uppercased())
          : (unit.role == "queen" ? "AI QUEEN" : "AI \(unit.slot)")
        tag.fontColor = isMe ? .white : PixelArt.ink
        tag.fontSize = isMe ? 10 : 8
      }
      node.childNode(withName: "halo")?.isHidden = !isMe
      node.childNode(withName: "berry")?.isHidden = !unit.berry
      if let bar = node.childNode(withName: "progress") as? SKSpriteNode {
        bar.isHidden = unit.gateProgress <= 0
        bar.xScale = max(0.01, unit.gateProgress)
      }
    }
    snail.run(.move(to: CGPoint(x: game.snail.x, y: 65), duration: 0.075), withKey: "move")
    snail.xScale = game.snail.team == 0 ? -1 : 1
    snailMarker.position.x = 330 + game.snail.x / 960 * 300
    snailMarker.color = game.snail.team < 0 ? .white : PixelArt.team(game.snail.team)
    for event in game.events where event.id > lastEvent {
      burst(event)
      audio.play(event.kind)
    }
    lastEvent = max(lastEvent, game.events.last?.id ?? 0)
  }

  private func makeUnit(_ unit: UnitState) -> SKNode {
    let node = SKNode()
    node.position = CGPoint(x: unit.x, y: unit.y)
    let shadow = SKShapeNode(ellipseOf: CGSize(width: 22, height: 5))
    shadow.fillColor = PixelArt.ink.withAlphaComponent(0.2)
    shadow.strokeColor = .clear
    node.addChild(shadow)
    let halo = SKShapeNode(ellipseOf: CGSize(width: 33, height: 9))
    halo.strokeColor = .white
    halo.lineWidth = 2
    halo.name = "halo"
    halo.position.y = 1
    node.addChild(halo)
    let sprite = SKSpriteNode(texture: PixelArt.insect(team: unit.team, role: unit.role, frame: 0))
    sprite.size = CGSize(
      width: unit.role == "queen" ? 39 : 34, height: unit.role == "queen" ? 34 : 30)
    sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
    sprite.name = "sprite"
    node.addChild(sprite)
    let tag = label("", x: 0, y: 40, size: 8, parent: node)
    tag.name = "tag"
    let berry = SKSpriteNode(texture: PixelArt.berry())
    berry.name = "berry"
    berry.size = CGSize(width: 12, height: 12)
    berry.position = CGPoint(x: 0, y: 33)
    node.addChild(berry)
    let progress = SKSpriteNode(color: PixelArt.gold, size: CGSize(width: 30, height: 3))
    progress.name = "progress"
    progress.position.y = -5
    node.addChild(progress)
    dynamic.addChild(node)
    unitNodes[unit.id] = node
    return node
  }

  override func update(_ currentTime: TimeInterval) {
    let nextFrame = Int(currentTime * 8) % 2
    guard let game = current?.game else { return }
    for unit in game.units {
      guard let sprite = unitNodes[unit.id]?.childNode(withName: "sprite") as? SKSpriteNode else {
        continue
      }
      let moving = abs(unit.vx) > 1 || !unit.grounded
      let spriteFrame = moving ? nextFrame : 0
      let key = "\(unit.team)-\(unit.role)-\(spriteFrame)"
      if textureCache[key] == nil {
        textureCache[key] = PixelArt.insect(team: unit.team, role: unit.role, frame: spriteFrame)
      }
      sprite.texture = textureCache[key]
      sprite.xScale = unit.facing < 0 ? -1 : 1
      sprite.alpha = unit.invulnerable > 0 && nextFrame == 1 ? 0.5 : 1
      sprite.zRotation = unit.diving ? (unit.facing < 0 ? 0.3 : -0.3) : 0
      sprite.size = CGSize(
        width: unit.role == "queen" ? 39 : 34, height: unit.role == "queen" ? 34 : 30)
    }
    if animationFrame != nextFrame {
      animationFrame = nextFrame
      snail.texture = PixelArt.snail(frame: animationFrame)
    }
  }

  private func burst(_ event: GameEvent) {
    guard ["hit", "deposit", "transform", "claim", "victory"].contains(event.kind) else { return }
    let color = event.kind == "deposit" ? UIColor(hex: 0xf9a0ed) : PixelArt.team(event.team)
    for i in 0..<12 {
      let particle = SKSpriteNode(color: color, size: CGSize(width: 3, height: 3))
      particle.position = CGPoint(x: event.x, y: event.y + 20)
      particle.zPosition = 20
      dynamic.addChild(particle)
      let angle = Double(i) / 12 * .pi * 2
      particle.run(
        .sequence([
          .group([
            .moveBy(x: cos(angle) * 35, y: sin(angle) * 35, duration: 0.5),
            .fadeOut(withDuration: 0.5),
          ]),
          .removeFromParent(),
        ]))
    }
    if event.kind == "deposit" || event.kind == "transform" {
      let text = label(
        event.kind == "deposit" ? "+1 BERRY" : "WINGS!", x: event.x, y: event.y + 36, size: 10,
        color: .white, parent: dynamic)
      text.run(
        .sequence([
          .group([.moveBy(x: 0, y: 20, duration: 0.8), .fadeOut(withDuration: 0.8)]),
          .removeFromParent(),
        ]))
    }
  }
}
