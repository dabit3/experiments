import SpriteKit
import SwiftUI
import UIKit

@MainActor
final class ArenaScene: SKScene {
  private let session: Session
  private let world = SKNode()
  private let actors = SKNode()
  private let effects = SKNode()
  private let hud = SKNode()
  private let overlay = SKNode()
  private var textures: [String: SKTexture] = [:]
  private var fighters: [String: SKSpriteNode] = [:]
  private var shadows: [String: SKShapeNode] = [:]
  private var trails: [Int: SKNode] = [:]
  private var touchControls: [UITouch: String] = [:]
  private var buttons: [String: SKShapeNode] = [:]
  private var lastTick = -1
  private var lastEffect = 0
  private var overlayKey = ""
  private var lastPhase = ""
  private var lifeBars: [SKSpriteNode] = []
  private var meterBars: [SKSpriteNode] = []
  private var lifeLabels: [SKLabelNode] = []
  private var nameLabels: [SKLabelNode] = []
  private var portraits: [SKSpriteNode] = []
  private var medals: [[SKShapeNode]] = []
  private var timerLabel = SKLabelNode()
  private var statusLabel = SKLabelNode()
  private var networkLabel = SKLabelNode()
  private var driverLabel = SKLabelNode()
  private let gold = UIColor(red: 1, green: 0.8, blue: 0.25, alpha: 1)
  private let cyan = UIColor(red: 0.36, green: 0.91, blue: 0.89, alpha: 1)
  private let ink = UIColor(red: 0.05, green: 0.07, blue: 0.14, alpha: 1)

  init(session: Session) {
    self.session = session
    super.init(size: CGSize(width: 960, height: 540))
    scaleMode = .aspectFit
    backgroundColor = .black
  }

  required init?(coder: NSCoder) { fatalError("Use init(session:)") }

  override func didMove(to view: SKView) {
    guard children.isEmpty else { return }
    view.isMultipleTouchEnabled = true
    addChild(world)
    world.addChild(actors)
    world.addChild(effects)
    addChild(hud)
    addChild(overlay)
    hud.zPosition = 100
    overlay.zPosition = 200
    actors.zPosition = 10
    effects.zPosition = 20
    let background = SKSpriteNode(texture: texture("harbor"), size: size)
    background.position = CGPoint(x: 480, y: 270)
    world.addChild(background)
    // Sparse glints and drifting embers animate the hand-authored scenic stage.
    for i in 0..<18 {
      let glint = SKSpriteNode(
        color: cyan.withAlphaComponent(0.6), size: CGSize(width: 8, height: 2))
      glint.position = CGPoint(x: 20 + i * 51, y: 204 + (i % 5) * 9)
      glint.zPosition = 1
      glint.run(
        .repeatForever(
          .sequence([
            .fadeAlpha(to: 0.1, duration: 0.5 + Double(i % 4) * 0.2),
            .fadeAlpha(to: 0.65, duration: 0.7),
          ])))
      world.addChild(glint)
    }
    makeHUD()
    makeControls()
    SoundBank.shared.start()
  }

  private func texture(_ name: String) -> SKTexture {
    if let texture = textures[name] { return texture }
    let value = SKTexture(image: assetImage(name))
    value.filteringMode = .nearest
    textures[name] = value
    return value
  }

  @discardableResult
  private func text(
    _ value: String, x: CGFloat, y: CGFloat, size: CGFloat = 16,
    color: UIColor = .white, parent: SKNode? = nil, font: String = "Menlo-Bold"
  ) -> SKLabelNode {
    let label = SKLabelNode(fontNamed: font)
    label.text = value
    label.fontSize = size
    label.fontColor = color
    label.position = CGPoint(x: x, y: y)
    label.verticalAlignmentMode = .center
    (parent ?? hud).addChild(label)
    return label
  }

  @discardableResult
  private func panel(
    x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat,
    color: UIColor, stroke: UIColor = .clear, parent: SKNode? = nil
  ) -> SKShapeNode {
    let shape = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 0)
    shape.position = CGPoint(x: x, y: y)
    shape.fillColor = color
    shape.strokeColor = stroke
    shape.lineWidth = 2
    (parent ?? hud).addChild(shape)
    return shape
  }

  private func makeHUD() {
    panel(x: 480, y: 501, width: 960, height: 78, color: ink.withAlphaComponent(0.85))
    panel(x: 480, y: 539, width: 960, height: 3, color: gold)
    for i in 0..<2 {
      let left = i == 0
      let x: CGFloat = left ? 254 : 706
      panel(
        x: x, y: 493, width: 328, height: 23,
        color: UIColor(red: 0.55, green: 0.08, blue: 0.16, alpha: 1), stroke: .white)
      let bar = SKSpriteNode(color: gold, size: CGSize(width: 320, height: 15))
      bar.anchorPoint = CGPoint(x: left ? 1 : 0, y: 0.5)
      bar.position = CGPoint(x: left ? 414 : 546, y: 493)
      hud.addChild(bar)
      lifeBars.append(bar)
      let shine = SKSpriteNode(
        color: .white.withAlphaComponent(0.45), size: CGSize(width: 320, height: 3))
      shine.anchorPoint = CGPoint(x: left ? 1 : 0, y: 0.5)
      shine.position = CGPoint(x: 0, y: 5)
      bar.addChild(shine)
      lifeLabels.append(text("100", x: x, y: 493, size: 12, color: ink))
      let name = text(
        left ? "PLAYER 1" : "PLAYER 2", x: left ? 93 : 867, y: 517, size: 17, color: cyan)
      name.horizontalAlignmentMode = left ? .left : .right
      nameLabels.append(name)
      let portrait = SKSpriteNode(
        texture: texture(left ? "kai_portrait" : "rhea_portrait"),
        size: CGSize(width: 48, height: 48))
      portrait.position = CGPoint(x: left ? 58 : 902, y: 503)
      hud.addChild(portrait)
      portraits.append(portrait)
      panel(x: left ? 58 : 902, y: 503, width: 50, height: 50, color: .clear, stroke: gold)
      var roundMedals: [SKShapeNode] = []
      for n in 0..<2 {
        let medal = SKShapeNode(circleOfRadius: 6)
        medal.fillColor = ink
        medal.strokeColor = gold
        medal.position = CGPoint(x: left ? 98 + n * 19 : 862 - n * 19, y: 469)
        hud.addChild(medal)
        roundMedals.append(medal)
      }
      medals.append(roundMedals)
      let meterX: CGFloat = left ? 184 : 776
      panel(x: meterX, y: 137, width: 232, height: 15, color: ink, stroke: .white)
      let meter = SKSpriteNode(color: cyan, size: CGSize(width: 0, height: 9))
      meter.anchorPoint = CGPoint(x: left ? 0 : 1, y: 0.5)
      meter.position = CGPoint(x: left ? 72 : 888, y: 137)
      hud.addChild(meter)
      meterBars.append(meter)
      text("SUPER", x: left ? 103 : 858, y: 155, size: 13, color: gold)
    }
    panel(
      x: 480, y: 516, width: 58, height: 22,
      color: UIColor(red: 0.77, green: 0.13, blue: 0.19, alpha: 1), stroke: gold)
    text("K.O.", x: 480, y: 516, size: 17, color: .white)
    timerLabel = text(
      "60", x: 480, y: 479, size: 39, color: gold, font: "AvenirNextCondensed-Heavy")
    statusLabel = text("HARBOR / SUNSET", x: 480, y: 160, size: 12, color: .white)
    networkLabel = text("", x: 480, y: 137, size: 10, color: cyan)
    driverLabel = text("", x: 480, y: 446, size: 11, color: gold)
  }

  private func makeControls() {
    panel(x: 480, y: 58, width: 960, height: 116, color: ink.withAlphaComponent(0.97))
    panel(
      x: 480, y: 116, width: 960, height: 2,
      color: UIColor(red: 0.32, green: 0.41, blue: 0.53, alpha: 1))
    button("left", title: "◀", x: 68, y: 56, radius: 30)
    button("right", title: "▶", x: 182, y: 56, radius: 30)
    button("jump", title: "▲", x: 125, y: 87, radius: 24)
    button("crouch", title: "▼", x: 125, y: 25, radius: 22)
    text("MOVE", x: 125, y: 55, size: 9, color: cyan)
    button("guard", title: "GUARD", x: 622, y: 49, radius: 29, color: cyan)
    button("light", title: "LIGHT", x: 710, y: 74, radius: 31, color: gold)
    button(
      "heavy", title: "HEAVY", x: 791, y: 48, radius: 32,
      color: UIColor(red: 1, green: 0.45, blue: 0.29, alpha: 1))
    button("fire", title: "WAVE", x: 872, y: 77, radius: 31, color: cyan)
    button("super", title: "SUPER", x: 877, y: 20, radius: 21, color: gold)
    button("leave", title: "EXIT", x: 266, y: 37, radius: 24)
    button("audio", title: "SOUND", x: 325, y: 37, radius: 24)
    text("LIGHT  →  HEAVY  →  WAVE", x: 423, y: 83, size: 10, color: .lightGray)
    text("LOW GUARD: ▼ + GUARD", x: 425, y: 64, size: 9, color: .lightGray)
    text("JUMP ATTACK BEATS LOW GUARD", x: 465, y: 21, size: 8, color: .lightGray)
  }

  private func button(
    _ name: String, title: String, x: CGFloat, y: CGFloat, radius: CGFloat,
    color: UIColor? = nil, parent: SKNode? = nil
  ) {
    let shape = SKShapeNode(circleOfRadius: radius)
    shape.position = CGPoint(x: x, y: y)
    shape.name = name
    shape.fillColor = (color ?? .white).withAlphaComponent(0.13)
    shape.strokeColor = color ?? UIColor.gray
    shape.lineWidth = 2
    (parent ?? hud).addChild(shape)
    let shine = SKShapeNode(circleOfRadius: radius - 4)
    shine.strokeColor = (color ?? .white).withAlphaComponent(0.16)
    shine.lineWidth = 1
    shape.addChild(shine)
    text(title, x: 0, y: 0, size: title.count > 2 ? 11 : 21, color: color ?? .white, parent: shape)
    buttons[name] = shape
  }

  private func sprite(for p: FighterState) -> SKSpriteNode {
    if let node = fighters[p.id] { return node }
    let node = SKSpriteNode(texture: texture("\(p.character)_idle_0"))
    node.anchorPoint = CGPoint(x: 0.5, y: 23.0 / 192.0)
    node.size = CGSize(width: 288, height: 288)
    actors.addChild(node)
    fighters[p.id] = node
    let shadow = SKShapeNode(ellipseOf: CGSize(width: 104, height: 15))
    shadow.fillColor = .black.withAlphaComponent(0.4)
    shadow.strokeColor = .clear
    shadow.zPosition = -1
    actors.addChild(shadow)
    shadows[p.id] = shadow
    return node
  }

  override func update(_ currentTime: TimeInterval) {
    guard let state = session.state else { return }
    if state.tick != lastTick {
      lastTick = state.tick
      updateHUD(state)
      updateFighters(state)
      updateProjectiles(state)
      updateOverlay(state)
      for impact in state.effects where impact.id > lastEffect {
        impactEffect(impact)
        lastEffect = max(lastEffect, impact.id)
      }
      if state.phase != lastPhase {
        if state.phase == "fight" { SoundBank.shared.play("start") }
        lastPhase = state.phase
      }
    }
    if state.freeze > 0 {
      let strength: CGFloat = state.freeze > 10 ? 4 : 2
      world.position = CGPoint(
        x: sin(currentTime * 120) * strength, y: cos(currentTime * 137) * strength)
    } else {
      world.position = .zero
    }
    for p in state.players {
      guard let node = fighters[p.id] else { continue }
      let target = CGPoint(x: p.x, y: 159 + p.y)
      let factor: CGFloat = state.freeze > 0 ? 1 : 0.52
      node.position.x += (target.x - node.position.x) * factor
      node.position.y += (target.y - node.position.y) * factor
    }
  }

  private func updateHUD(_ state: MatchState) {
    timerLabel.text = String(format: "%02d", max(0, Int(ceil(Double(state.remaining) / 60))))
    timerLabel.fontColor = state.remaining < 600 ? .systemRed : gold
    for p in state.players {
      let i = p.slot
      guard i < 2 else { continue }
      lifeBars[i].xScale = CGFloat(p.hp) / 100
      lifeBars[i].color = p.hp < 25 ? .systemOrange : gold
      lifeLabels[i].text = "\(p.hp)"
      nameLabels[i].text = "\(p.character.uppercased())  /  \(p.name.uppercased())"
      portraits[i].texture = texture("\(p.character)_portrait")
      meterBars[i].size.width = CGFloat(p.meter) * 2.24
      meterBars[i].color = p.meter == 100 ? gold : cyan
      for j in 0..<2 { medals[i][j].fillColor = p.wins > j ? gold : ink }
    }
    statusLabel.text = "PIER 94   /   ROUND \(state.round)   /   FIRST TO TWO"
    networkLabel.text =
      "ROOM \(state.code)   ·   \(session.latency)ms   ·   P\((session.local?.slot ?? 0) + 1)"
    driverLabel.text =
      session.driver.isEmpty
      ? "" : "AUTOMATED INPUT DRIVER · \(session.driver.uppercased()) · REAL WEBSOCKET PEER"
    buttons["super"]?.alpha = session.local?.meter == 100 ? 1 : 0.4
    buttons["audio"]?.alpha = session.muted ? 0.4 : 1
  }

  private func updateFighters(_ state: MatchState) {
    for p in state.players {
      let node = sprite(for: p)
      var pose = p.pose
      var frame = 0
      if let attack = p.attack {
        pose = attack.low && ["light", "heavy"].contains(attack.move) ? "low" : attack.move
        let startup = ["heavy": 10, "fire": 18, "super": 10][attack.move] ?? 4
        frame = attack.frame < startup ? 0 : attack.frame < startup + 9 ? 1 : 2
      } else if pose == "walk" {
        frame = (state.tick / 7) % 4
      } else if pose != "ko" {
        frame = (state.tick / 15) % 2
      }
      node.texture = texture("\(p.character)_\(pose)_\(frame)")
      node.xScale = p.facing
      if node.position == .zero { node.position = CGPoint(x: p.x, y: 159 + p.y) }
      node.zPosition = p.y > 0 ? 3 : 2
      node.color = p.pose == "hurt" ? .white : .clear
      node.colorBlendFactor = p.pose == "hurt" && state.tick % 4 < 2 ? 0.6 : 0
      shadows[p.id]?.position = CGPoint(x: p.x, y: 158)
      shadows[p.id]?.xScale = max(0.4, 1 - p.y / 300)
      if let attack = p.attack, attack.move == "super", state.tick % 4 == 0 {
        let ghost = SKSpriteNode(texture: node.texture, size: node.size)
        ghost.anchorPoint = node.anchorPoint
        ghost.position = node.position
        ghost.xScale = node.xScale
        ghost.alpha = 0.45
        ghost.color = cyan
        ghost.colorBlendFactor = 0.7
        ghost.zPosition = 1
        actors.addChild(ghost)
        ghost.run(
          .sequence([
            .group([.fadeOut(withDuration: 0.25), .moveBy(x: -p.facing * 28, y: 0, duration: 0.25)]
            ), .removeFromParent(),
          ]))
      }
    }
  }

  private func updateProjectiles(_ state: MatchState) {
    let active = Set(state.projectiles.map(\.id))
    for id in Array(trails.keys) where !active.contains(id) {
      trails.removeValue(forKey: id)?.removeFromParent()
    }
    for wave in state.projectiles {
      let node: SKNode
      if let current = trails[wave.id] {
        node = current
      } else {
        node = SKNode()
        let color =
          state.players.first(where: { $0.id == wave.owner })?.character == "rhea" ? gold : cyan
        let points: [CGPoint] = [
          CGPoint(x: -47, y: -16), CGPoint(x: -21, y: -9), CGPoint(x: -37, y: -27),
          CGPoint(x: 9, y: -18), CGPoint(x: 27, y: -3), CGPoint(x: 15, y: 18),
          CGPoint(x: -18, y: 27), CGPoint(x: -43, y: 18), CGPoint(x: -23, y: 7),
        ]
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        let flame = SKShapeNode(path: path)
        flame.fillColor = color
        flame.strokeColor = .white
        flame.lineWidth = 2
        flame.glowWidth = wave.super ? 7 : 3
        node.addChild(flame)
        let core = SKShapeNode(ellipseOf: CGSize(width: 32, height: 25))
        core.fillColor = .white
        core.strokeColor = color
        node.addChild(core)
        node.zPosition = 12
        effects.addChild(node)
        trails[wave.id] = node
      }
      node.position = CGPoint(x: wave.x, y: 159 + wave.y)
      node.xScale = wave.vx > 0 ? 1 : -1
      node.yScale = state.tick % 4 < 2 ? 1 : 0.85
    }
  }

  private func impactEffect(_ impact: ImpactState) {
    if ["hit", "block", "fire", "super", "ko"].contains(impact.kind) {
      SoundBank.shared.play(impact.kind)
    }
    guard impact.kind != "ko" else { return }
    let location = CGPoint(x: impact.x, y: 159 + impact.y)
    for i in 0..<10 {
      let angle = CGFloat(i) * .pi / 5
      let radius: CGFloat = impact.kind == "super" ? 140 : 55
      let ray = SKShapeNode(rectOf: CGSize(width: i % 2 == 0 ? 20 : 9, height: 4))
      ray.fillColor = impact.kind == "block" ? cyan : gold
      ray.strokeColor = .white
      ray.position = location
      ray.zRotation = angle
      effects.addChild(ray)
      ray.run(
        .sequence([
          .group([
            .moveBy(x: cos(angle) * radius, y: sin(angle) * radius, duration: 0.19),
            .fadeOut(withDuration: 0.23), .scale(to: 0.2, duration: 0.23),
          ]), .removeFromParent(),
        ]))
    }
    let ring = SKShapeNode(circleOfRadius: 10)
    ring.position = location
    ring.strokeColor = .white
    ring.lineWidth = 4
    effects.addChild(ring)
    ring.run(
      .sequence([
        .group([
          .scale(to: impact.kind == "super" ? 14 : 5, duration: 0.22), .fadeOut(withDuration: 0.24),
        ]), .removeFromParent(),
      ]))
    if !impact.text.isEmpty {
      let label = text(
        impact.text, x: impact.x, y: 298 + impact.y, size: 23, color: gold, parent: effects,
        font: "AvenirNextCondensed-HeavyItalic")
      label.run(
        .sequence([
          .group([.moveBy(x: 0, y: 26, duration: 0.5), .fadeOut(withDuration: 0.7)]),
          .removeFromParent(),
        ]))
    }
  }

  private func brush(_ value: String, y: CGFloat, size: CGFloat) {
    text(
      value, x: 484, y: y - 5, size: size, color: ink, parent: overlay,
      font: "AvenirNextCondensed-HeavyItalic")
    text(
      value, x: 482, y: y - 2, size: size, color: .systemOrange, parent: overlay,
      font: "AvenirNextCondensed-HeavyItalic")
    text(
      value, x: 480, y: y, size: size, color: gold, parent: overlay,
      font: "AvenirNextCondensed-HeavyItalic")
  }

  private func updateOverlay(_ state: MatchState) {
    let key =
      "\(state.phase)-\(state.round)-\(state.match)-\(state.paused)-\(session.connected)-\(session.local?.ready ?? false)-\(state.players.count)-\(session.local?.rematch ?? false)-\(state.phaseTicks > 45)"
    guard key != overlayKey else { return }
    overlayKey = key
    overlay.removeAllChildren()
    buttons.removeValue(forKey: "ready")
    buttons.removeValue(forKey: "rematch")
    if !session.connected || state.paused {
      panel(
        x: 480, y: 305, width: 590, height: 125, color: ink.withAlphaComponent(0.94), stroke: cyan,
        parent: overlay)
      brush("CONNECTION PAUSED", y: 328, size: 34)
      text(
        "Waiting for peer to reconnect · match clock is frozen", x: 480, y: 283, size: 13,
        parent: overlay)
    } else if state.phase == "waiting" {
      panel(
        x: 480, y: 312, width: 540, height: 219, color: ink.withAlphaComponent(0.93), stroke: gold,
        parent: overlay)
      brush("HERE COMES A CHALLENGER", y: 387, size: 33)
      text("ROOM  \(state.code)", x: 480, y: 346, size: 28, color: cyan, parent: overlay)
      text(
        state.players.count < 2
          ? "Share this code with the second device" : "Two players connected · both must ready",
        x: 480, y: 311, size: 14, parent: overlay)
      button(
        "ready", title: session.local?.ready == true ? "READY!" : "READY", x: 480, y: 253,
        radius: 35, color: gold, parent: overlay)
      if session.local?.ready == true {
        text("Waiting for challenger…", x: 480, y: 207, size: 12, color: cyan, parent: overlay)
      }
    } else if state.phase == "countdown" {
      brush(state.phaseTicks > 45 ? "ROUND \(state.round)" : "FIGHT!", y: 323, size: 79)
      text("PIER 94  ·  HARBOR DISTRICT", x: 480, y: 269, size: 14, parent: overlay)
    } else if state.phase == "roundOver" {
      brush(state.remaining <= 0 ? "TIME UP" : "K.O.", y: 348, size: 94)
      let winner = state.players.first { $0.id == state.roundWinner }
      text(
        winner.map { "\($0.character.uppercased()) TAKES THE ROUND" } ?? "DRAW — FIGHT AGAIN",
        x: 480, y: 275, size: 20, color: .white, parent: overlay, font: "AvenirNextCondensed-Heavy")
    } else if state.phase == "matchOver" {
      panel(
        x: 480, y: 322, width: 600, height: 253, color: ink.withAlphaComponent(0.94), stroke: gold,
        parent: overlay)
      let winner = state.players.first { $0.id == state.winner }
      brush("\(winner?.character.uppercased() ?? "") WINS", y: 396, size: 64)
      text(
        "MATCH COMPLETE  ·  \(state.players.map { String($0.wins) }.joined(separator: " — "))",
        x: 480, y: 346, size: 19, color: cyan, parent: overlay)
      text(
        winner.map { "\($0.name) / \($0.hits) HITS / \($0.damageDealt) DAMAGE" } ?? "", x: 480,
        y: 315, size: 15, parent: overlay)
      button(
        "rematch", title: session.local?.rematch == true ? "VOTED" : "AGAIN", x: 480, y: 254,
        radius: 34, color: gold, parent: overlay)
      text(
        session.local?.rematch == true
          ? "Waiting for opponent's rematch vote" : "REMATCH · BOTH PLAYERS MUST VOTE", x: 480,
        y: 206, size: 12, color: .white, parent: overlay)
    }
  }

  private func control(at point: CGPoint) -> String? {
    let candidates = buttons.filter { _, node in
      guard node.parent != nil else { return false }
      let local = convert(point, to: node)
      return hypot(local.x, local.y) <= node.frame.width / 2 + 5
    }
    return candidates.min { lhs, rhs in
      let a = lhs.value.convert(CGPoint.zero, to: self)
      let b = rhs.value.convert(CGPoint.zero, to: self)
      return hypot(a.x - point.x, a.y - point.y) < hypot(b.x - point.x, b.y - point.y)
    }?.key
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      if let key = control(at: touch.location(in: self)) {
        touchControls[touch] = key
        session.press(key)
        buttons[key]?.fillColor = gold.withAlphaComponent(0.45)
      }
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      let old = touchControls[touch]
      let next = control(at: touch.location(in: self))
      if old != next {
        if let old {
          session.release(old)
          buttons[old]?.fillColor = ink
        }
        if let next, ["left", "right", "jump", "crouch", "guard"].contains(next) {
          touchControls[touch] = next
          session.press(next)
        } else {
          touchControls.removeValue(forKey: touch)
        }
      }
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { endTouches(touches) }
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    endTouches(touches)
  }
  private func endTouches(_ touches: Set<UITouch>) {
    for touch in touches {
      if let key = touchControls.removeValue(forKey: touch) {
        if !touchControls.values.contains(key) { session.release(key) }
        buttons[key]?.fillColor = ink
      }
    }
  }
}

struct ArenaView: UIViewRepresentable {
  let session: Session
  func makeUIView(context: Context) -> SKView {
    let view = SKView()
    view.isMultipleTouchEnabled = true
    view.ignoresSiblingOrder = true
    view.preferredFramesPerSecond = 60
    view.presentScene(ArenaScene(session: session))
    return view
  }
  func updateUIView(_ uiView: SKView, context: Context) {}
}
