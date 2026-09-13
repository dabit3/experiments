import SpriteKit
import UIKit

@MainActor
final class ArenaScene: SKScene {
  private unowned let client: GameClient
  private let world = SKNode()
  private let effects = SKNode()
  private let hud = SKNode()
  private let controls = SKNode()
  private var labels: [String: SKLabelNode] = [:]
  private var bars: [String: SKSpriteNode] = [:]
  private var portraits: [String: SKSpriteNode] = [:]
  private var fighters: [String: FighterNode] = [:]
  private var bolts: [String: SKNode] = [:]
  private var touches: [UITouch: String] = [:]
  private var lastDirectionTap: [String: TimeInterval] = [:]
  private var buttonNodes: [String: SKShapeNode] = [:]
  private var lastTime: TimeInterval = 0
  private var lastPhase = ""
  private var bannerUntil: TimeInterval = 0
  private let ground: CGFloat = 225
  private let gold = UIColor(red: 1, green: 0.73, blue: 0.24, alpha: 1)
  private let cyan = UIColor(red: 0.28, green: 0.87, blue: 1, alpha: 1)

  init(client: GameClient) {
    self.client = client
    super.init(size: CGSize(width: 1280, height: 720))
    scaleMode = .aspectFit
    backgroundColor = .black
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func didMove(to view: SKView) {
    guard world.parent == nil else { return }
    view.isMultipleTouchEnabled = true
    addChild(world)
    let background = SKSpriteNode(imageNamed: "festival.png")
    background.size = size
    background.position = CGPoint(x: 640, y: 360)
    world.addChild(background)
    let veil = SKSpriteNode(color: UIColor(white: 0.015, alpha: 0.13), size: size)
    veil.position = background.position
    veil.zPosition = 1
    world.addChild(veil)
    addAmbient()
    effects.zPosition = 20
    world.addChild(effects)
    hud.zPosition = 50
    addChild(hud)
    controls.zPosition = 70
    addChild(controls)
    makeHUD()
    makeControls()
    client.eventHandler = { [weak self] event in self?.handle(event) }
  }

  private func addAmbient() {
    for index in 0..<32 {
      let dust = SKShapeNode(circleOfRadius: CGFloat(index % 3 + 1))
      dust.fillColor = index % 2 == 0 ? gold : cyan
      dust.strokeColor = .clear
      dust.alpha = 0.3
      dust.position = CGPoint(
        x: CGFloat((index * 179) % 1280), y: CGFloat(200 + (index * 79) % 380))
      dust.zPosition = 2
      world.addChild(dust)
      dust.run(
        .repeatForever(
          .sequence([
            .group([
              .moveBy(x: 25, y: 70, duration: 3 + Double(index % 4)), .fadeOut(withDuration: 4),
            ]),
            .moveBy(x: -25, y: -70, duration: 0), .fadeAlpha(to: 0.3, duration: 0),
          ])))
    }
    for index in 0..<12 {
      let glow = SKShapeNode(ellipseOf: CGSize(width: 50, height: 5))
      glow.fillColor = gold.withAlphaComponent(0.22)
      glow.strokeColor = .clear
      glow.glowWidth = 9
      glow.position = CGPoint(x: CGFloat(index * 110 + 40), y: 251)
      glow.zPosition = 2
      world.addChild(glow)
      glow.run(
        .repeatForever(
          .sequence([
            .fadeAlpha(to: 0.35, duration: 0.6 + Double(index % 3)),
            .fadeAlpha(to: 1, duration: 1.3),
          ])))
    }
  }

  @discardableResult
  private func text(
    _ key: String, _ value: String, x: CGFloat, y: CGFloat, size: CGFloat,
    color: UIColor = .white, parent: SKNode? = nil,
    alignment: SKLabelHorizontalAlignmentMode = .center
  ) -> SKLabelNode {
    let node = SKLabelNode(fontNamed: "AvenirNextCondensed-HeavyItalic")
    node.text = value
    node.fontSize = size
    node.fontColor = color
    node.horizontalAlignmentMode = alignment
    node.verticalAlignmentMode = .center
    node.position = CGPoint(x: x, y: y)
    (parent ?? hud).addChild(node)
    if !key.isEmpty { labels[key] = node }
    return node
  }

  private func panel(
    _ rect: CGRect, color: UIColor, parent: SKNode? = nil, border: UIColor = .clear
  ) {
    let node = SKShapeNode(rect: rect)
    node.fillColor = color
    node.strokeColor = border
    node.lineWidth = 1.5
    (parent ?? hud).addChild(node)
  }

  private func makeHUD() {
    panel(CGRect(x: 0, y: 590, width: 1280, height: 130), color: UIColor(white: 0.01, alpha: 0.77))
    panel(
      CGRect(x: 0, y: 0, width: 1280, height: 180),
      color: UIColor(red: 0.02, green: 0.03, blue: 0.06, alpha: 0.88))
    text("clock", "60", x: 640, y: 672, size: 49, color: .white)
    let diamond = SKShapeNode(
      path: polygon([
        CGPoint(x: 605, y: 708), CGPoint(x: 675, y: 708), CGPoint(x: 695, y: 672),
        CGPoint(x: 675, y: 635), CGPoint(x: 605, y: 635), CGPoint(x: 585, y: 672),
      ]))
    diamond.strokeColor = cyan
    diamond.lineWidth = 3
    diamond.fillColor = UIColor(red: 0.03, green: 0.12, blue: 0.18, alpha: 1)
    hud.addChild(diamond)
    labels["clock"]?.zPosition = 1
    text("round", "BOUT 01", x: 640, y: 617, size: 15, color: gold)
    text("network", "", x: 640, y: 572, size: 12, color: .white)
    text("stage", "NIGHTFALL CIRCUIT  /  OSAKA SKYLINE", x: 640, y: 548, size: 10, color: cyan)
    text("banner", "", x: 640, y: 425, size: 77, color: .white)
    labels["banner"]?.zPosition = 10
    text("subBanner", "", x: 640, y: 373, size: 18, color: gold)
    text("driver", "", x: 640, y: 17, size: 11, color: gold)
    for side in 0..<2 {
      let left = side == 0
      let start: CGFloat = left ? 158 : 705
      let portrait = SKSpriteNode(imageNamed: left ? "rook-portrait.jpg" : "sora-portrait.jpg")
      portrait.size = CGSize(width: 74, height: 82)
      portrait.position = CGPoint(x: left ? 112 : 1168, y: 663)
      portraits["main\(side)"] = portrait
      hud.addChild(portrait)
      text(
        "name\(side)", "", x: left ? 160 : 1122, y: 701, size: 19,
        color: .white, alignment: left ? .left : .right)
      panel(
        CGRect(x: start - 3, y: 660, width: 420, height: 28),
        color: UIColor(white: 0.08, alpha: 1), border: UIColor(white: 0.7, alpha: 1))
      let health = SKSpriteNode(
        color: UIColor(red: 0.52, green: 0.92, blue: 0.16, alpha: 1),
        size: CGSize(width: 414, height: 22))
      health.anchorPoint = CGPoint(x: left ? 0 : 1, y: 0.5)
      health.position = CGPoint(x: left ? start : start + 414, y: 674)
      bars["hp\(side)"] = health
      hud.addChild(health)
      for index in 1..<10 {
        panel(
          CGRect(x: start + CGFloat(index) * 41.4, y: 664, width: 1.5, height: 20),
          color: UIColor(white: 0.03, alpha: 0.55))
      }
      panel(CGRect(x: start, y: 648, width: 414, height: 5), color: UIColor(white: 0.2, alpha: 1))
      let guardBar = SKSpriteNode(color: cyan, size: CGSize(width: 414, height: 4))
      guardBar.anchorPoint = CGPoint(x: left ? 0 : 1, y: 0.5)
      guardBar.position = CGPoint(x: left ? start : start + 414, y: 650)
      bars["guard\(side)"] = guardBar
      hud.addChild(guardBar)
      text(
        "hpText\(side)", "", x: left ? 568 : 713, y: 631, size: 13,
        color: .white, alignment: left ? .right : .left)
      for member in 0..<3 {
        let x = left ? 174 + CGFloat(member) * 112 : 1106 - CGFloat(member) * 112
        let small = SKSpriteNode(imageNamed: "rook-portrait.jpg")
        small.size = CGSize(width: 33, height: 32)
        small.position = CGPoint(x: x, y: 614)
        hud.addChild(small)
        portraits["\(side)-\(member)"] = small
        text(
          "roster\(side)-\(member)", "", x: left ? x + 22 : x - 22, y: 619, size: 11,
          color: .white, alignment: left ? .left : .right)
        text(
          "rosterHP\(side)-\(member)", "", x: left ? x + 22 : x - 22, y: 605, size: 9,
          color: .gray, alignment: left ? .left : .right)
      }
      let meterX: CGFloat = left ? 92 : 850
      text("power\(side)", "0", x: left ? 72 : 1210, y: 207, size: 35, color: gold)
      for stock in 0..<3 {
        let x = meterX + CGFloat(stock) * 111
        panel(
          CGRect(x: x, y: 199, width: 105, height: 17), color: UIColor(white: 0.04, alpha: 1),
          border: gold.withAlphaComponent(0.65))
        let meter = SKSpriteNode(color: gold, size: CGSize(width: 101, height: 13))
        meter.anchorPoint = CGPoint(x: 0, y: 0.5)
        meter.position = CGPoint(x: x + 2, y: 207.5)
        bars["meter\(side)-\(stock)"] = meter
        hud.addChild(meter)
      }
      text(
        "special\(side)", "", x: left ? 90 : 1180, y: 235, size: 12,
        color: gold, alignment: left ? .left : .right)
      text("combo\(side)", "", x: left ? 170 : 1110, y: 462, size: 34, color: gold)
    }
  }

  private func makeControls() {
    button("left", title: "◀", subtitle: "", x: 110, y: 86, radius: 37, color: .white)
    button("right", title: "▶", subtitle: "", x: 235, y: 86, radius: 37, color: .white)
    button("crouch", title: "LOW", subtitle: "", x: 173, y: 52, radius: 29, color: .lightGray)
    button("hop", title: "HOP", subtitle: "", x: 105, y: 153, radius: 26, color: cyan)
    button("jump", title: "JUMP", subtitle: "", x: 179, y: 153, radius: 26, color: cyan)
    button("guard", title: "GUARD", subtitle: "", x: 321, y: 76, radius: 35, color: cyan)
    button("roll", title: "ROLL", subtitle: "", x: 286, y: 151, radius: 27, color: .lightGray)
    button("punch", title: "A", subtitle: "PUNCH", x: 970, y: 81, radius: 33, color: .systemPink)
    button("kick", title: "B", subtitle: "KICK", x: 1053, y: 52, radius: 33, color: gold)
    button("heavyPunch", title: "C", subtitle: "HEAVY P", x: 1034, y: 146, radius: 33, color: cyan)
    button(
      "heavyKick", title: "D", subtitle: "HEAVY K", x: 1139, y: 106, radius: 33, color: .systemGreen
    )
    button(
      "special", title: "SP", subtitle: "SPECIAL", x: 871, y: 90, radius: 37, color: .systemPurple)
    button("super", title: "SUPER", subtitle: "2 STOCKS", x: 752, y: 88, radius: 39, color: gold)
    button("sound", title: "♪", subtitle: "", x: 600, y: 72, radius: 20, color: .lightGray)
    button("exit", title: "EXIT", subtitle: "", x: 654, y: 72, radius: 20, color: .lightGray)
    text(
      "", "HOLD TO MOVE • DOUBLE TAP TO RUN", x: 223, y: 15, size: 9, color: .gray, parent: controls
    )
    text(
      "", "CANCEL: NORMAL → SPECIAL → SUPER", x: 976, y: 15, size: 9, color: .gray, parent: controls
    )
  }

  private func button(
    _ name: String, title: String, subtitle: String, x: CGFloat, y: CGFloat,
    radius: CGFloat, color: UIColor
  ) {
    let circle = SKShapeNode(circleOfRadius: radius)
    circle.position = CGPoint(x: x, y: y)
    circle.fillColor = color.withAlphaComponent(0.12)
    circle.strokeColor = color.withAlphaComponent(0.8)
    circle.lineWidth = 2
    circle.name = name
    circle.isAccessibilityElement = true
    circle.accessibilityLabel = name
    circle.accessibilityTraits = .button
    controls.addChild(circle)
    buttonNodes[name] = circle
    text(
      "", title, x: 0, y: subtitle.isEmpty ? 0 : 5, size: title.count > 3 ? 14 : 22, color: color,
      parent: circle)
    if !subtitle.isEmpty {
      text(
        "", subtitle, x: 0, y: -15, size: 8, color: color.withAlphaComponent(0.8), parent: circle)
    }
  }

  override func update(_ currentTime: TimeInterval) {
    let delta = lastTime == 0 ? 1.0 / 60 : min(0.05, currentTime - lastTime)
    lastTime = currentTime
    guard let state = client.state else { return }
    labels["clock"]?.text = String(format: "%02d", state.timer)
    labels["round"]?.text = String(format: "BOUT %02d", state.round)
    labels["network"]?.text =
      "ROOM \(state.code)  •  \(client.guestName.uppercased())  •  \(state.paused ? "PEER DISCONNECTED / PAUSED" : "LIVE  /  2 GUESTS")"
    labels["network"]?.fontColor = state.paused ? .systemOrange : .white
    labels["driver"]?.text = client.automationLabel
    labels["driver"]?.position.y = 184
    for (side, peer) in state.peers.enumerated() {
      updateHUD(peer, side: side)
      let fighter = fighters[peer.id] ?? FighterNode()
      if fighters[peer.id] == nil {
        fighters[peer.id] = fighter
        fighter.zPosition = 10
        world.addChild(fighter)
      }
      fighter.update(peer, ground: ground, time: currentTime, delta: delta)
    }
    updateProjectiles(state, time: currentTime)
    if state.phase == "countdown" {
      labels["banner"]?.text = state.wait > 60 ? "ROUND \(state.round)" : "READY"
      labels["subBanner"]?.text = "THREE FIGHTERS. ONE CROWN."
    } else if state.phase == "transition" {
      labels["banner"]?.text = "K.O."
      labels["subBanner"]?.text = "NEXT FIGHTER ENTERING"
    } else if state.paused {
      labels["banner"]?.text = "PAUSED"
      labels["subBanner"]?.text = "WAITING FOR RIVAL TO RECONNECT"
    } else if state.phase == "fight" && lastPhase == "countdown" {
      labels["banner"]?.text = "FIGHT!"
      labels["subBanner"]?.text = ""
      bannerUntil = currentTime + 0.7
    } else if currentTime > bannerUntil && state.phase != "countdown" {
      labels["banner"]?.text = ""
      labels["subBanner"]?.text = ""
    }
    lastPhase = state.phase
    buttonNodes["super"]?.alpha = (client.localPeer?.meter ?? 0) >= 200 ? 1 : 0.4
  }

  private func updateHUD(_ peer: PeerState, side: Int) {
    let fighter = Fighter.named(peer.member.fighter)
    labels["name\(side)"]?.text = "\(peer.name.uppercased())  /  \(fighter.title)"
    labels["hpText\(side)"]?.text = "\(peer.member.hp) HP   /   GUARD \(peer.guardValue)"
    bars["hp\(side)"]?.xScale = max(0.001, CGFloat(peer.member.hp) / 100)
    bars["hp\(side)"]?.color =
      peer.member.hp < 30 ? .systemRed : UIColor(red: 0.53, green: 0.92, blue: 0.17, alpha: 1)
    bars["guard\(side)"]?.xScale = max(0.001, CGFloat(peer.guardValue) / 100)
    portraits["main\(side)"]?.texture = SKTexture(imageNamed: "\(peer.member.fighter)-portrait.jpg")
    labels["power\(side)"]?.text = "\(peer.meter / 100)"
    labels["special\(side)"]?.text = "\(fighter.special.uppercased())  /  POWER"
    labels["combo\(side)"]?.text = peer.combo >= 2 ? "\(peer.combo) HITS" : ""
    for stock in 0..<3 {
      bars["meter\(side)-\(stock)"]?.xScale = max(
        0.001, min(1, CGFloat(peer.meter - stock * 100) / 100))
    }
    for (index, member) in peer.roster.enumerated() {
      portraits["\(side)-\(index)"]?.texture = SKTexture(
        imageNamed: "\(member.fighter)-portrait.jpg")
      portraits["\(side)-\(index)"]?.alpha = member.hp == 0 ? 0.23 : 1
      labels["roster\(side)-\(index)"]?.text = member.fighter.uppercased()
      labels["roster\(side)-\(index)"]?.fontColor = index == peer.active ? gold : .lightGray
      labels["rosterHP\(side)-\(index)"]?.text =
        member.hp == 0
        ? "ELIMINATED" : "\(index == peer.active ? "ACTIVE" : "RESERVE") / \(member.hp)"
    }
  }

  private func updateProjectiles(_ state: MatchState, time: TimeInterval) {
    let live = Set(state.projectiles.map(\.id))
    for key in Array(bolts.keys) where !live.contains(key) {
      bolts[key]?.removeFromParent()
      bolts.removeValue(forKey: key)
    }
    for projectile in state.projectiles {
      let node = bolts[projectile.id] ?? makeBolt(projectile)
      if bolts[projectile.id] == nil {
        bolts[projectile.id] = node
        effects.addChild(node)
      }
      node.position = CGPoint(x: projectile.x, y: Double(ground) + projectile.y)
      node.xScale = projectile.direction * (projectile.isSuper ? 1.9 : 1)
      node.yScale = (projectile.isSuper ? 1.7 : 1) * (1 + sin(time * 37) * 0.1)
      node.zRotation = sin(time * 24) * 0.06
    }
  }

  private func makeBolt(_ projectile: ProjectileState) -> SKNode {
    let node = SKNode()
    let color = UIColor(Fighter.named(projectile.fighter).color)
    for index in (0..<4).reversed() {
      let flame = SKShapeNode(
        path: polygon([
          CGPoint(x: 56, y: 0), CGPoint(x: 18, y: 28 + index * 5),
          CGPoint(x: -30, y: 18 + index * 4), CGPoint(x: -78 - index * 8, y: 27),
          CGPoint(x: -51, y: 0), CGPoint(x: -86, y: -22),
          CGPoint(x: -18, y: -17 - index * 4), CGPoint(x: 23, y: -22 - index * 3),
        ]))
      flame.fillColor =
        index == 0 ? .white : color.withAlphaComponent(0.3 + Double(4 - index) * 0.12)
      flame.strokeColor = index == 0 ? .yellow : color
      flame.glowWidth = CGFloat(5 + index * 2)
      flame.setScale(0.45 + CGFloat(index) * 0.22)
      node.addChild(flame)
    }
    return node
  }

  private func handle(_ event: CombatEvent) {
    if event.kind == "hit" || event.kind == "guard" {
      let point = CGPoint(x: event.x ?? 640, y: Double(ground) + (event.y ?? 100))
      let guarded = event.kind == "guard"
      burst(at: point, color: guarded ? cyan : gold, count: event.action == "super" ? 25 : 13)
      if let target = guarded ? event.player : event.target {
        fighters[target]?.flash(color: guarded ? cyan : .white)
      }
      if !guarded {
        world.removeAction(forKey: "shake")
        world.run(
          .sequence([
            .moveBy(x: 5, y: 2, duration: 0.025), .moveBy(x: -10, y: -3, duration: 0.035),
            .move(to: .zero, duration: 0.06),
          ]), withKey: "shake")
      }
    }
    if event.kind == "attack" && event.action == "super" {
      let flash = SKSpriteNode(
        color: UIColor(red: 0.04, green: 0.02, blue: 0.1, alpha: 0.72), size: size)
      flash.position = CGPoint(x: 640, y: 360)
      flash.zPosition = 4
      world.addChild(flash)
      flash.run(
        .sequence([.wait(forDuration: 0.15), .fadeOut(withDuration: 0.35), .removeFromParent()]))
      if let peer = client.state?.peers.first(where: { $0.id == event.player }) {
        burst(
          at: CGPoint(x: peer.x, y: Double(ground) + peer.y + 120),
          color: UIColor(Fighter.named(peer.member.fighter).color), count: 30)
      }
      labels["banner"]?.text = "CROWN BREAK!"
      labels["subBanner"]?.text = "SUPER SPECIAL MOVE"
      bannerUntil = lastTime + 0.6
    }
    if event.kind == "guardBreak" {
      labels["banner"]?.text = "GUARD CRUSH"
      labels["subBanner"]?.text = "DEFENSE BROKEN"
      bannerUntil = lastTime + 0.6
    }
  }

  private func burst(at point: CGPoint, color: UIColor, count: Int) {
    for index in 0..<count {
      let angle = CGFloat(index) / CGFloat(count) * .pi * 2
      let length = CGFloat(25 + (index * 17) % 65)
      let spark = SKShapeNode(
        path: polygon([
          CGPoint(x: 0, y: -3), CGPoint(x: length, y: 0), CGPoint(x: 0, y: 3),
          CGPoint(x: -9, y: 0),
        ]))
      spark.fillColor = index % 3 == 0 ? .white : color
      spark.strokeColor = .clear
      spark.glowWidth = 3
      spark.position = point
      spark.zRotation = angle
      effects.addChild(spark)
      spark.run(
        .sequence([
          .group([
            .moveBy(x: cos(angle) * 70, y: sin(angle) * 70, duration: 0.24),
            .fadeOut(withDuration: 0.26), .scale(to: 0.25, duration: 0.26),
          ]),
          .removeFromParent(),
        ]))
    }
  }

  private func polygon(_ points: [CGPoint]) -> CGPath {
    let path = CGMutablePath()
    path.addLines(between: points)
    path.closeSubpath()
    return path
  }

  private func control(at point: CGPoint) -> String? {
    buttonNodes.first { _, node in
      hypot(node.position.x - point.x, node.position.y - point.y) < node.frame.width / 2 + 6
    }?.key
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      guard let name = control(at: touch.location(in: controls)) else { continue }
      self.touches[touch] = name
      buttonNodes[name]?.fillColor = buttonNodes[name]?.strokeColor.withAlphaComponent(0.5) ?? .gray
      switch name {
      case "left", "right":
        if let previous = lastDirectionTap[name], lastTime - previous < 0.28 {
          client.input.run = true
        }
        lastDirectionTap[name] = lastTime
      case "guard", "crouch": break
      case "sound": client.muted.toggle()
      case "exit": client.leave()
      default: client.action(name)
      }
      client.record("touch", fields: ["control": name, "phase": "down"])
    }
    updateHeld()
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      guard let previous = self.touches[touch],
        ["left", "right", "guard", "crouch"].contains(previous)
      else { continue }
      let next = control(at: touch.location(in: controls))
      if next != previous {
        buttonNodes[previous]?.fillColor =
          buttonNodes[previous]?.strokeColor.withAlphaComponent(0.12) ?? .clear
        if let next, ["left", "right", "guard", "crouch"].contains(next) {
          self.touches[touch] = next
        } else {
          self.touches.removeValue(forKey: touch)
        }
      }
    }
    updateHeld()
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { release(touches) }
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { release(touches) }

  private func release(_ released: Set<UITouch>) {
    for touch in released {
      if let name = touches.removeValue(forKey: touch) {
        buttonNodes[name]?.fillColor =
          buttonNodes[name]?.strokeColor.withAlphaComponent(0.12) ?? .clear
        client.record("touch", fields: ["control": name, "phase": "up"])
      }
    }
    updateHeld()
  }

  private func updateHeld() {
    let values = Set(touches.values)
    client.input.move = (values.contains("right") ? 1 : 0) - (values.contains("left") ? 1 : 0)
    client.input.guardValue = values.contains("guard")
    client.input.crouch = values.contains("crouch")
    if client.input.move == 0 { client.input.run = false }
  }
}

@MainActor
final class FighterNode: SKNode {
  private let sprite = SKSpriteNode()
  private let shadow = SKShapeNode(ellipseOf: CGSize(width: 138, height: 21))
  private let shield = SKShapeNode(ellipseOf: CGSize(width: 150, height: 216))
  private var key = ""
  private var pose = ""
  private var changedAt: TimeInterval = 0
  private var lastTrail: TimeInterval = 0
  private var textureCache: [String: SKTexture] = [:]

  override init() {
    super.init()
    shadow.fillColor = .black.withAlphaComponent(0.55)
    shadow.strokeColor = .clear
    addChild(shadow)
    sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
    sprite.zPosition = 1
    addChild(sprite)
    shield.strokeColor = .cyan
    shield.fillColor = .cyan.withAlphaComponent(0.08)
    shield.lineWidth = 3
    shield.glowWidth = 3
    shield.zPosition = 2
    shield.position.y = 110
    shield.isHidden = true
    addChild(shield)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  func update(_ peer: PeerState, ground: CGFloat, time: TimeInterval, delta: TimeInterval) {
    if pose != peer.pose || key != peer.member.fighter {
      pose = peer.pose
      key = peer.member.fighter
      changedAt = time
    }
    let age = time - changedAt
    let attack = ["punch", "heavyPunch", "kick", "heavyKick", "special", "super"].contains(pose)
    let frame: String
    if pose == "hurt" || pose == "ko" {
      frame = "hurt"
    } else if attack && age > 0.055 {
      frame = pose.lowercased().contains("kick") ? "kick" : "punch"
    } else {
      frame = "idle"
    }
    let image = "\(key)-\(frame).png"
    if textureCache[image] == nil { textureCache[image] = SKTexture(imageNamed: image) }
    let texture = textureCache[image]!
    sprite.texture = texture
    sprite.setScale(1)
    let height: CGFloat = key == "atlas" ? 257 : 243
    sprite.size = CGSize(
      width: height * texture.size().width / texture.size().height, height: height)
    sprite.anchorPoint.x = frame == "punch" ? 0.39 : frame == "kick" ? 0.33 : 0.5
    let target = CGPoint(x: peer.x, y: Double(ground) + peer.y)
    if position == .zero { position = target }
    let factor = min(1, delta * 22)
    position.x += (target.x - position.x) * factor
    position.y += (target.y - position.y) * factor
    shadow.position.y = -CGFloat(peer.y)
    shadow.xScale = max(0.55, 1 - CGFloat(peer.y) / 500)
    let breathing = CGFloat(sin(time * 5.5)) * 0.009
    sprite.xScale = CGFloat(peer.face)
    sprite.yScale = 1 + breathing
    sprite.position = .zero
    sprite.zRotation = 0
    if pose == "walk" {
      sprite.position.y = abs(sin(time * 15)) * 6
      sprite.zRotation = -CGFloat(peer.face) * 0.035
      sprite.xScale *= 1 + sin(time * 15) * 0.025
    }
    if peer.crouch { sprite.yScale = 0.74 }
    if pose == "roll" {
      sprite.yScale = 0.58
      sprite.position.y = 32
      sprite.zRotation = -CGFloat(peer.face) * CGFloat(age * 11)
    }
    if peer.y > 10 && !attack {
      sprite.zRotation = -CGFloat(peer.face) * 0.11
      sprite.yScale = 0.94
    }
    if pose == "ko" {
      sprite.zRotation = CGFloat(peer.face) * min(1.45, CGFloat(age * 2.5))
      sprite.position.y = max(-40, -CGFloat(age * 40))
      sprite.alpha = max(0.3, 1 - CGFloat(age) * 0.15)
    } else {
      sprite.alpha = 1
    }
    shield.isHidden = !peer.guarding
    shield.yScale = peer.crouch ? 0.75 : 1
    if (pose == "special" || pose == "super" || pose == "roll") && time - lastTrail > 0.09 {
      lastTrail = time
      let trail = SKSpriteNode(texture: sprite.texture)
      trail.size = sprite.size
      trail.anchorPoint = sprite.anchorPoint
      trail.position = sprite.position
      trail.xScale = sprite.xScale
      trail.yScale = sprite.yScale
      trail.zRotation = sprite.zRotation
      trail.color = UIColor(Fighter.named(key).color)
      trail.colorBlendFactor = 0.75
      trail.alpha = 0.4
      trail.zPosition = -1
      addChild(trail)
      trail.run(
        .sequence([
          .group([
            .moveBy(x: -CGFloat(peer.face) * 45, y: 0, duration: 0.2),
            .fadeOut(withDuration: 0.2),
          ]), .removeFromParent(),
        ]))
    }
  }

  func flash(color: UIColor) {
    sprite.color = color
    sprite.colorBlendFactor = 0.8
    sprite.run(
      .customAction(withDuration: 0.17) { node, elapsed in
        guard let sprite = node as? SKSpriteNode else { return }
        sprite.colorBlendFactor = max(0, 0.8 - elapsed * 5)
      })
  }
}
