import SpriteKit
import UIKit

@MainActor
final class DuelScene: SKScene {
  weak var connection: DuelConnection?
  private let world = SKNode()
  private let hud = SKNode()
  private let fx = SKNode()
  private var fighters: [FighterArt] = []
  private var shadows: [SKShapeNode] = []
  private var controls: [String: SKShapeNode] = [:]
  private var activeTouches: [ObjectIdentifier: String] = [:]
  private var lastEvent = 0
  private var labels: [String: SKLabelNode] = [:]
  private var hpBars: [SKShapeNode] = []
  private var meterBars: [SKShapeNode] = []
  private var diamonds: [[SKShapeNode]] = []
  private var roundDots: [[SKShapeNode]] = []
  private let cycleRing = SKShapeNode()
  private var projectileNodes: [String: SKNode] = [:]
  private var rain: [SKShapeNode] = []
  private let violet = UIColor(hex: 0x161323)
  private let white = UIColor(hex: 0xebeafa)
  private var currentTime: TimeInterval = 0

  override init(size: CGSize) {
    super.init(size: size)
    scaleMode = .aspectFit
    backgroundColor = UIColor(hex: 0x090d21)
  }
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func didMove(to view: SKView) {
    guard fighters.isEmpty else { return }
    view.isMultipleTouchEnabled = true
    buildStage()
    addChild(world)
    world.addChild(fx)
    fx.zPosition = 20
    for index in 0..<2 {
      let shadow = SKShapeNode(ellipseOf: CGSize(width: 135, height: 15))
      shadow.fillColor = UIColor(hex: 0x090917, alpha: 0.65)
      shadow.strokeColor = .clear
      shadow.position = CGPoint(x: index == 0 ? 330 : 870, y: 149)
      world.addChild(shadow)
      shadows.append(shadow)
      let fighter = FighterArt(slot: index)
      fighter.position = CGPoint(x: index == 0 ? 330 : 870, y: 149)
      fighter.xScale = index == 0 ? 1 : -1
      fighter.zPosition = CGFloat(index + 3)
      world.addChild(fighter)
      fighters.append(fighter)
    }
    addChild(hud)
    hud.zPosition = 100
    buildHUD()
    buildControls()
  }

  private func buildStage() {
    let background = SKSpriteNode(imageNamed: "moon-station")
    background.size = CGSize(width: 1200, height: 690)
    background.position = CGPoint(x: 600, y: 340)
    background.zPosition = -20
    addChild(background)
    let floor = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 1200, height: 140))
    floor.fillColor = UIColor(hex: 0x090d24, alpha: 0.5)
    floor.strokeColor = .clear
    floor.zPosition = -10
    addChild(floor)
    for index in 0..<40 {
      let x = CGFloat((index * 197) % 1200)
      let y = CGFloat((index * 137) % 440 + 120)
      let line = SKShapeNode()
      let path = CGMutablePath()
      path.move(to: .zero)
      path.addLine(to: CGPoint(x: -4, y: -14))
      line.path = path
      line.strokeColor = UIColor(hex: 0xb5c9ed, alpha: 0.15)
      line.lineWidth = 0.7
      line.position = CGPoint(x: x, y: y)
      line.zPosition = -1
      addChild(line)
      rain.append(line)
    }
    let line = SKShapeNode(rect: CGRect(x: 0, y: 137, width: 1200, height: 1))
    line.fillColor = UIColor(hex: 0x8ca9ea, alpha: 0.3)
    line.strokeColor = .clear
    addChild(line)
  }

  @discardableResult
  private func text(
    _ value: String, x: CGFloat, y: CGFloat, size: CGFloat = 14,
    color: UIColor? = nil, align: SKLabelHorizontalAlignmentMode = .center,
    key: String? = nil, parent: SKNode? = nil
  ) -> SKLabelNode {
    let node = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    node.text = value
    node.fontSize = size
    node.fontColor = color ?? white
    node.horizontalAlignmentMode = align
    node.verticalAlignmentMode = .center
    node.position = CGPoint(x: x, y: y)
    (parent ?? hud).addChild(node)
    if let key { labels[key] = node }
    return node
  }

  private func buildHUD() {
    shape([30, 546, 508, 546, 528, 510, 30, 510], violet.withAlphaComponent(0.9), parent: hud)
    shape([1170, 546, 692, 546, 672, 510, 1170, 510], violet.withAlphaComponent(0.9), parent: hud)
    for index in 0..<2 {
      let x: CGFloat = index == 0 ? 45 : 702
      let accent = fighters[index].accent
      shape(
        [x, 511, x + 447, 511, x + 433, 490, x, 490], UIColor(hex: 0x332741), parent: hud,
        stroke: UIColor(hex: 0xb3a4c8))
      let bar = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 429, height: 15))
      bar.position = CGPoint(x: index == 0 ? 49 : 1131, y: 493)
      bar.fillColor = accent
      bar.strokeColor = .clear
      hud.addChild(bar)
      hpBars.append(bar)
      if index == 1 { bar.xScale = -1 }
      text(
        index == 0 ? "REN" : "AYA", x: index == 0 ? 49 : 1151, y: 531, size: 22,
        align: index == 0 ? .left : .right, key: "name\(index)")
      text(
        index == 0 ? "RIFTBLADE" : "MOONWIRE", x: index == 0 ? 485 : 714, y: 531, size: 11,
        color: accent, align: index == 0 ? .right : .left)
      text(
        "1000", x: index == 0 ? 50 : 1151, y: 477, size: 12, align: index == 0 ? .left : .right,
        key: "hp\(index)")
      text(
        "", x: index == 0 ? 70 : 1130, y: 378, size: 23, color: accent,
        align: index == 0 ? .left : .right, key: "combo\(index)")
      text("", x: index == 0 ? 330 : 870, y: 466, size: 13, color: accent, key: "status\(index)")
      var dots: [SKShapeNode] = []
      for dot in 0..<2 {
        let node = diamond(
          x: index == 0 ? 130 + CGFloat(dot) * 20 : 1070 - CGFloat(dot) * 20, y: 477, width: 7,
          color: .clear)
        dots.append(node)
      }
      roundDots.append(dots)
      var grid: [SKShapeNode] = []
      for block in 0..<6 {
        let node = diamond(
          x: index == 0 ? 555 - CGFloat(block) * 21 : 645 + CGFloat(block) * 21, y: 82, width: 11,
          color: .clear)
        grid.append(node)
      }
      diamonds.append(grid)
      let meterX: CGFloat = index == 0 ? 366 : 633
      let backing = SKShapeNode(rect: CGRect(x: meterX, y: 19, width: 201, height: 8))
      backing.fillColor = UIColor(hex: 0x252036)
      backing.strokeColor = UIColor(hex: 0x8a829d)
      hud.addChild(backing)
      let meter = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 197, height: 5))
      meter.position = CGPoint(x: meterX + 2, y: 21)
      meter.strokeColor = .clear
      meter.fillColor = accent
      hud.addChild(meter)
      meterBars.append(meter)
      text(
        "EXS  35.0", x: index == 0 ? 366 : 834, y: 37, size: 12, color: accent,
        align: index == 0 ? .left : .right, key: "meter\(index)")
    }
    shape(
      [559, 552, 641, 552, 656, 514, 627, 474, 573, 474, 544, 514], violet, parent: hud,
      stroke: UIColor(hex: 0xddd9ee))
    text("75", x: 600, y: 519, size: 38, key: "time")
    text("ROUND 01", x: 600, y: 486, size: 9, key: "round")
    text("HOLLOW  /  AFTERDARK", x: 600, y: 458, size: 10, color: UIColor(hex: 0xbab7d2))
    let core = SKShapeNode(circleOfRadius: 28)
    core.position = CGPoint(x: 600, y: 82)
    core.fillColor = violet
    core.strokeColor = UIColor(hex: 0xa5a1be)
    hud.addChild(core)
    cycleRing.position = core.position
    cycleRing.strokeColor = white
    cycleRing.lineWidth = 3
    hud.addChild(cycleRing)
    text("12", x: 600, y: 83, size: 20, key: "cycle")
    text("UNDERTOW", x: 600, y: 43, size: 9)
    text("", x: 600, y: 118, size: 10, color: UIColor(hex: 0xc3b6de), key: "cycleInfo")
    text("", x: 600, y: 412, size: 10, color: UIColor(hex: 0xdddded), key: "network")
    text("", x: 600, y: 327, size: 31, key: "banner")
    text("", x: 600, y: 295, size: 11, key: "subBanner")
    text(
      "TSUKIKAGE TERMINAL  /  00:17", x: 600, y: 150, size: 8,
      color: UIColor(hex: 0xc2cced, alpha: 0.7))
  }

  private func diamond(x: CGFloat, y: CGFloat, width: CGFloat, color: UIColor) -> SKShapeNode {
    polygon(
      [
        CGPoint(x: x - width, y: y), CGPoint(x: x, y: y + width * 0.6),
        CGPoint(x: x + width, y: y), CGPoint(x: x, y: y - width * 0.6),
      ], fill: color, stroke: white, width: 1, parent: hud)
  }

  private func control(
    _ id: String, label: String, subtitle: String, x: CGFloat, y: CGFloat, radius: CGFloat,
    accent: UIColor
  ) {
    let node = SKShapeNode(circleOfRadius: radius)
    node.position = CGPoint(x: x, y: y)
    node.fillColor = violet.withAlphaComponent(0.82)
    node.strokeColor = accent.withAlphaComponent(0.8)
    node.lineWidth = 1.3
    node.name = id
    node.zPosition = 3
    hud.addChild(node)
    text(label, x: 0, y: 5, size: radius > 27 ? 20 : 14, color: accent, parent: node)
    text(subtitle, x: 0, y: -14, size: 7, parent: node)
    controls[id] = node
  }

  private func buildControls() {
    let accent = UIColor(hex: 0xc5b6e1)
    control("left", label: "‹", subtitle: "MOVE", x: 67, y: 67, radius: 33, accent: accent)
    control("right", label: "›", subtitle: "MOVE", x: 145, y: 67, radius: 33, accent: accent)
    control("jump", label: "↑", subtitle: "JUMP", x: 106, y: 131, radius: 25, accent: accent)
    control("guard", label: "G", subtitle: "GUARD", x: 224, y: 67, radius: 27, accent: accent)
    control(
      "shield", label: "D", subtitle: "SHIELD", x: 289, y: 67, radius: 27,
      accent: UIColor(hex: 0x80d5f0))
    control("light", label: "A", subtitle: "LIGHT", x: 935, y: 62, radius: 32, accent: white)
    control("heavy", label: "B", subtitle: "HEAVY", x: 1010, y: 85, radius: 32, accent: white)
    control(
      "special", label: "C", subtitle: "RIFT / 25", x: 1087, y: 62, radius: 32,
      accent: UIColor(hex: 0xff5276))
    control(
      "ex", label: "EX", subtitle: "100", x: 1153, y: 109, radius: 26,
      accent: UIColor(hex: 0xff5276))
    control("throw", label: "T", subtitle: "THROW", x: 867, y: 108, radius: 25, accent: accent)
    control("shift", label: "S", subtitle: "SHIFT", x: 783, y: 121, radius: 20, accent: accent)
    control("sound", label: "♪", subtitle: "AUDIO", x: 29, y: 444, radius: 18, accent: accent)
    control("driver", label: "▷", subtitle: "AUTO", x: 1170, y: 444, radius: 18, accent: accent)
  }

  override func update(_ currentTime: TimeInterval) {
    self.currentTime = currentTime
    for (index, drop) in rain.enumerated() {
      drop.position.y -= CGFloat(2 + index % 3)
      drop.position.x -= 0.6
      if drop.position.y < 140 {
        drop.position.y = 570
        drop.position.x = CGFloat((index * 197) % 1200)
      }
    }
    guard let connection else { return }
    guard let state = connection.state else {
      lastEvent = 0
      hud.isHidden = true
      for (index, art) in fighters.enumerated() {
        art.torso.position.y = 78 + sin(currentTime * 3 + Double(index)) * 1.6
        art.aura.isHidden = true
        art.shield.isHidden = true
      }
      return
    }
    hud.isHidden = state.phase == "lobby"
    for p in state.players where p.slot < fighters.count {
      fighters[p.slot].render(p, time: currentTime)
      shadows[p.slot].position.x = p.x
      shadows[p.slot].xScale = max(0.5, 1 - p.y / 400)
      labels["name\(p.slot)"]?.text =
        "\(p.id == connection.playerID ? "▸ " : "")\(p.name.uppercased())"
      labels["hp\(p.slot)"]?.text = "\(p.hp) / 1000"
      hpBars[p.slot].xScale = CGFloat(p.hp) / 1000 * (p.slot == 0 ? 1 : -1)
      meterBars[p.slot].xScale = p.meter / 200
      labels["meter\(p.slot)"]?.text = String(format: "EXS  %05.1f", p.meter)
      labels["status\(p.slot)"]?.text =
        p.broken > 0 ? "UNDERTOW BREAK" : p.ascend ? "ASCEND / +10%" : ""
      labels["combo\(p.slot)"]?.text = p.combo >= 2 ? "\(p.combo)  CHAIN" : ""
      for index in 0..<6 {
        diamonds[p.slot][index].fillColor =
          p.grd >= Double(index) + 0.5 ? fighters[p.slot].accent : violet
        diamonds[p.slot][index].glowWidth = p.ascend ? 3 : 0
      }
      for index in 0..<2 {
        roundDots[p.slot][index].fillColor = p.wins > index ? fighters[p.slot].accent : .clear
      }
    }
    labels["time"]?.text = "\(state.remaining)"
    labels["round"]?.text = String(format: "ROUND %02d", state.round)
    labels["cycle"]?.text = "\(Int(ceil(Double(state.cycle) / 60)))"
    labels["cycleInfo"]?.text = "ADVANCE • STRIKE • SHIELD  /  CONTROL THE CYCLE"
    let path = CGMutablePath()
    path.addArc(
      center: .zero, radius: 27, startAngle: .pi / 2,
      endAngle: .pi / 2 - 2 * .pi * (1 - CGFloat(state.cycle) / 720), clockwise: true)
    cycleRing.path = path
    labels["network"]?.text =
      "\(state.room)  /  \(connection.connected ? "LIVE" : "RECONNECTING")  /  P\(connection.local.map { $0.slot + 1 } ?? 0)  •  \(connection.automation ? "AUTOMATED INPUT DRIVER" : "TOUCH CONTROL")"
    let disconnected = state.players.contains { !$0.connected }
    labels["banner"]?.text =
      disconnected
      ? "SIGNAL LOST / PAUSED"
      : state.phase == "countdown"
        ? "ROUND \(state.round)  /  \(max(1, Int(ceil(Double(state.countdown) / 60))))"
        : state.phase == "roundEnd" ? state.message : ""
    labels["subBanner"]?.text =
      disconnected
      ? "Reconnect within 60 seconds to resume the same match"
      : state.phase == "countdown" ? "BREAK THE STILLNESS" : ""
    for (id, control) in controls {
      let down = activeTouches.values.contains(id)
      control.fillColor =
        down ? UIColor(hex: 0x74638e, alpha: 0.8) : violet.withAlphaComponent(0.82)
      if id == "driver" { control.strokeColor = connection.automation ? .systemGreen : white }
      if id == "sound" { control.alpha = connection.muted ? 0.45 : 1 }
      if id == "shift" { control.alpha = connection.local?.ascend == true ? 1 : 0.35 }
      if id == "ex" { control.alpha = (connection.local?.meter ?? 0) >= 100 ? 1 : 0.4 }
    }
    renderProjectiles(state)
    for event in state.events where event.id > lastEvent {
      if event.tick > state.tick - 12 { renderEvent(event) }
      lastEvent = event.id
    }
  }

  private func renderProjectiles(_ state: MatchState) {
    let live = Set(state.projectiles.map(\.id))
    for id in Array(projectileNodes.keys) where !live.contains(id) {
      projectileNodes.removeValue(forKey: id)?.removeFromParent()
    }
    for projectile in state.projectiles {
      let node: SKNode
      if let existing = projectileNodes[projectile.id] {
        node = existing
      } else {
        let root = SKNode()
        let accent =
          state.players.first { $0.id == projectile.owner }.map { fighters[$0.slot].accent }
          ?? white
        shape(
          [-60, 0, -10, 17, 32, 0, -10, -17], accent.withAlphaComponent(0.4), parent: root,
          stroke: accent
        ).glowWidth = 8
        shape([-26, 0, 0, 9, 25, 0, 0, -9], .white, parent: root, stroke: accent)
        fx.addChild(root)
        projectileNodes[projectile.id] = root
        node = root
      }
      node.position = CGPoint(x: projectile.x, y: 149 + projectile.y)
      node.xScale = projectile.vx > 0 ? 1 : -1
    }
  }

  private func renderEvent(_ event: CombatEvent) {
    guard let connection else { return }
    let slot = connection.state?.players.first { $0.id == event.owner }?.slot ?? 0
    let accent = fighters[slot].accent
    let location = CGPoint(x: event.x, y: 149 + event.y)
    if ["hit", "block", "shield", "shift", "ascend", "result", "attack"].contains(event.type) {
      connection.audio.play(event.type)
    }
    if event.type == "attack" {
      let slash = SKShapeNode()
      let path = CGMutablePath()
      let face = CGFloat(connection.state?.players.first { $0.id == event.owner }?.face ?? 1)
      path.move(to: CGPoint(x: 15 * face, y: 85))
      path.addQuadCurve(to: CGPoint(x: 155 * face, y: -52), control: CGPoint(x: 205 * face, y: 85))
      path.addQuadCurve(to: CGPoint(x: 15 * face, y: 85), control: CGPoint(x: 147 * face, y: 36))
      slash.path = path
      slash.fillColor = accent.withAlphaComponent(0.65)
      slash.strokeColor = white
      slash.lineWidth = 2
      slash.glowWidth = 7
      slash.position = location
      slash.alpha = 0
      fx.addChild(slash)
      let delay = event.text == "light" ? 0.08 : 0.2
      slash.run(
        .sequence([
          .wait(forDuration: delay), .fadeIn(withDuration: 0.04), .fadeOut(withDuration: 0.18),
          .removeFromParent(),
        ]))
    } else if ["hit", "block", "shield", "break"].contains(event.type) {
      for index in 0..<9 {
        let angle = CGFloat(index) * .pi * 2 / 9
        let length: CGFloat = event.type == "hit" ? 42 : 24
        let spark = shape(
          [0, -2, length, 0, 0, 2, -9, 0], index.isMultiple(of: 2) ? white : accent, parent: fx,
          stroke: accent)
        spark.position = location
        spark.zRotation = angle
        spark.glowWidth = 3
        spark.run(
          .sequence([
            .group([
              .moveBy(x: cos(angle) * 35, y: sin(angle) * 35, duration: 0.24),
              .fadeOut(withDuration: 0.28),
            ]), .removeFromParent(),
          ]))
      }
      if event.type == "hit" {
        world.run(
          .sequence([
            .moveBy(x: 3, y: 1, duration: 0.025), .moveBy(x: -6, y: -2, duration: 0.025),
            .move(to: .zero, duration: 0.04),
          ]))
      }
    } else if ["ascend", "shift", "start"].contains(event.type) {
      let title = text(
        event.text, x: event.type == "start" ? 600 : event.x, y: 366, size: 22,
        color: event.type == "start" ? white : accent, parent: fx)
      title.run(
        .sequence([
          .wait(forDuration: 0.65),
          .group([.moveBy(x: 0, y: 25, duration: 0.4), .fadeOut(withDuration: 0.4)]),
          .removeFromParent(),
        ]))
      if event.type != "start" {
        let ring = SKShapeNode(circleOfRadius: 40)
        ring.position = location
        ring.strokeColor = accent
        ring.lineWidth = 4
        ring.glowWidth = 5
        fx.addChild(ring)
        ring.run(
          .sequence([
            .group([.scale(to: 4, duration: 0.4), .fadeOut(withDuration: 0.4)]),
            .removeFromParent(),
          ]))
      }
    }
  }

  private func identifier(at point: CGPoint) -> String? {
    controls.first { _, node in
      let radius = node.frame.width / 2 + 5
      return hypot(node.position.x - point.x, node.position.y - point.y) < radius
    }?.key
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      guard let id = identifier(at: touch.location(in: self)) else { continue }
      activeTouches[ObjectIdentifier(touch)] = id
      if ["left", "right", "guard", "shield"].contains(id) {
        connection?.setHeld(id, true)
      } else if id == "driver" {
        connection?.toggleDriver()
      } else if id == "sound" {
        connection?.toggleAudio()
      } else {
        connection?.press(id)
      }
    }
  }
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      let key = ObjectIdentifier(touch)
      guard let previous = activeTouches[key],
        ["left", "right", "guard", "shield"].contains(previous)
      else { continue }
      let next = identifier(at: touch.location(in: self))
      if next != previous {
        connection?.setHeld(previous, false)
        activeTouches.removeValue(forKey: key)
        if let next, ["left", "right", "guard", "shield"].contains(next) {
          activeTouches[key] = next
          connection?.setHeld(next, true)
        }
      }
    }
  }
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { release(touches) }
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { release(touches) }
  private func release(_ touches: Set<UITouch>) {
    for touch in touches {
      if let id = activeTouches.removeValue(forKey: ObjectIdentifier(touch)),
        ["left", "right", "guard", "shield"].contains(id),
        !activeTouches.values.contains(id)
      {
        connection?.setHeld(id, false)
      }
    }
  }
}
