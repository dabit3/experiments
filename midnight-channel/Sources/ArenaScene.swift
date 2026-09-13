import SpriteKit
import UIKit

private let ink = UIColor(red: 0.035, green: 0.045, blue: 0.08, alpha: 1)
private let gold = UIColor(red: 1, green: 0.78, blue: 0.02, alpha: 1)
private let cyan = UIColor(red: 0.16, green: 0.91, blue: 1, alpha: 1)
private let red = UIColor(red: 1, green: 0.15, blue: 0.25, alpha: 1)

func polygon(_ points: [CGPoint], fill: UIColor, stroke: UIColor = ink, width: CGFloat = 2)
  -> SKShapeNode
{
  let path = CGMutablePath()
  path.addLines(between: points)
  path.closeSubpath()
  let node = SKShapeNode(path: path)
  node.fillColor = fill
  node.strokeColor = stroke
  node.lineWidth = width
  return node
}

func points(_ values: [(Double, Double)]) -> [CGPoint] {
  values.map { CGPoint(x: $0.0, y: $0.1) }
}

final class FighterArt: SKNode {
  private let rig = SKNode()
  private let shadow = SKShapeNode(ellipseOf: CGSize(width: 92, height: 17))
  private let companion = SKNode()
  private let body = SKNode()
  private let head = SKNode()
  private let coat = SKShapeNode()
  private let limbs = (0..<8).map { _ in SKShapeNode() }
  private let blade = SKShapeNode()
  private let scarf = SKShapeNode()
  private let guardArc = SKShapeNode()
  private let aura = SKShapeNode(ellipseOf: CGSize(width: 130, height: 210))
  private let slot: Int
  private var accent: UIColor { slot == 0 ? cyan : red }

  init(slot: Int) {
    self.slot = slot
    super.init()
    shadow.fillColor = .black.withAlphaComponent(0.55)
    shadow.strokeColor = .clear
    shadow.position.y = 0
    addChild(shadow)
    addChild(rig)
    rig.addChild(companion)
    rig.addChild(body)
    companion.zPosition = -2
    aura.position.y = 88
    aura.fillColor = .clear
    aura.strokeColor = accent
    aura.lineWidth = 2
    aura.glowWidth = 5
    body.addChild(aura)
    body.addChild(coat)
    for limb in limbs {
      limb.strokeColor = ink
      limb.lineWidth = 2.6
      body.addChild(limb)
    }
    let torso = polygon(
      points([(-22, 83), (-29, 139), (-12, 151), (18, 147), (28, 96), (17, 77)]),
      fill: slot == 0 ? ink : .white)
    body.addChild(torso)
    body.addChild(
      polygon(
        points([(-8, 145), (2, 119), (13, 148), (15, 86), (-6, 83)]),
        fill: slot == 0 ? .white : ink))
    body.addChild(polygon(points([(-18, 148), (-7, 122), (-13, 113), (-21, 143)]), fill: accent))
    body.addChild(polygon(points([(14, 147), (3, 117), (16, 121), (22, 139)]), fill: accent))
    if slot == 0 {
      body.addChild(polygon(points([(1, 134), (7, 132), (10, 92), (3, 86), (-1, 94)]), fill: red))
    }
    for y in stride(from: 95, through: 130, by: 12) {
      let button = SKShapeNode(circleOfRadius: 1.5)
      button.fillColor = gold
      button.position = CGPoint(x: -16, y: y)
      body.addChild(button)
    }
    let belt = polygon(points([(-22, 85), (21, 83), (21, 91), (-23, 94)]), fill: ink)
    body.addChild(belt)
    body.addChild(polygon(points([(-2, 85), (6, 85), (6, 93), (-2, 93)]), fill: gold))
    body.addChild(head)
    head.position = CGPoint(x: 1, y: 151)
    head.addChild(
      polygon(
        points([(-11, 1), (-14, 23), (-7, 34), (13, 34), (20, 20), (17, 4), (7, -3)]),
        fill: UIColor(red: 1, green: 0.82, blue: 0.65, alpha: 1)))
    let hairPoints =
      slot == 0
      ? [
        (-15.0, 14.0), (-22, 32), (-14, 31), (-18, 43), (-5, 39), (4, 49), (8, 41), (21, 41),
        (17, 34), (26, 28), (18, 20), (14, 30), (8, 20), (3, 31), (-6, 18), (-7, 30),
      ]
      : [
        (-16.0, -1.0), (-23, 20), (-22, 35), (-10, 44), (11, 44), (24, 34), (26, 17), (20, 5),
        (16, 27), (8, 22), (5, 34), (-8, 20), (-10, 1),
      ]
    head.addChild(
      polygon(points(hairPoints), fill: slot == 0 ? UIColor(white: 0.85, alpha: 1) : red))
    head.addChild(polygon(points([(-1, 18), (7, 17), (9, 20), (0, 21)]), fill: .white, width: 1))
    head.addChild(
      polygon(points([(11, 18), (17, 18), (18, 21), (12, 21)]), fill: .white, width: 1))
    head.addChild(polygon(points([(5, 18), (7, 18), (7, 20), (5, 20)]), fill: accent, width: 0))
    head.addChild(
      polygon(points([(15, 18), (17, 18), (17, 20), (15, 20)]), fill: accent, width: 0))
    if slot == 0 {
      head.addChild(
        polygon(
          points([(-3, 16), (8, 15), (10, 22), (-3, 23)]), fill: cyan.withAlphaComponent(0.3),
          width: 1))
      head.addChild(
        polygon(
          points([(11, 15), (19, 16), (20, 23), (11, 22)]), fill: cyan.withAlphaComponent(0.3),
          width: 1))
    } else {
      let ear = SKShapeNode(circleOfRadius: 7)
      ear.fillColor = gold
      ear.strokeColor = ink
      ear.lineWidth = 3
      ear.position = CGPoint(x: -13, y: 16)
      head.addChild(ear)
    }
    body.addChild(scarf)
    blade.fillColor = .white
    blade.strokeColor = accent
    blade.lineWidth = 2
    body.addChild(blade)
    guardArc.fillColor = accent.withAlphaComponent(0.12)
    guardArc.strokeColor = accent
    guardArc.lineWidth = 4
    guardArc.glowWidth = 7
    body.addChild(guardArc)
    buildCompanion()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func buildCompanion() {
    companion.position = CGPoint(x: -48, y: 24)
    let metal =
      slot == 0
      ? UIColor(red: 0.76, green: 0.94, blue: 1, alpha: 1)
      : UIColor(red: 1, green: 0.8, blue: 0.75, alpha: 1)
    for side in [-1.0, 1.0] {
      companion.addChild(
        polygon(
          points([
            (side * 15, 128), (side * 58, 175), (side * 85, 180),
            (side * 54, 126), (side * 92, 137), (side * 56, 96), (side * 24, 91),
          ]),
          fill: accent.withAlphaComponent(0.65), stroke: .white, width: 1.5))
      companion.addChild(
        polygon(
          points([
            (side * 12, 92), (side * 38, 65), (side * 31, 16),
            (side * 8, 1), (side * 14, 50), (side * 2, 73),
          ]), fill: metal))
      companion.addChild(
        polygon(
          points([
            (side * 25, 144), (side * 50, 142), (side * 63, 97),
            (side * 48, 76), (side * 35, 115), (side * 18, 114),
          ]), fill: metal))
    }
    companion.addChild(
      polygon(
        points([(-27, 145), (0, 165), (29, 145), (19, 98), (0, 78), (-18, 98)]), fill: ink,
        stroke: accent, width: 4))
    companion.addChild(
      polygon(
        points([(-22, 145), (0, 132), (23, 146), (10, 113), (0, 120), (-13, 111)]), fill: metal))
    companion.addChild(
      polygon(
        points([(-17, 174), (-12, 199), (0, 210), (15, 198), (18, 175), (0, 159)]), fill: metal))
    companion.addChild(polygon(points([(-15, 187), (16, 187), (8, 177), (-9, 177)]), fill: accent))
    companion.addChild(
      polygon(
        points([(-15, 195), (-29, 221), (-4, 204), (0, 227), (4, 204), (29, 221), (15, 195)]),
        fill: gold))
  }

  private func path(_ values: [(Double, Double)]) -> CGPath {
    let result = CGMutablePath()
    result.addLines(between: points(values))
    result.closeSubpath()
    return result
  }

  private func limb(
    _ node: SKShapeNode, _ start: CGPoint, _ end: CGPoint, _ width: Double, _ color: UIColor
  ) {
    let dx = Double(end.x - start.x)
    let dy = Double(end.y - start.y)
    let length = max(1, hypot(dx, dy))
    let nx = -dy / length * width
    let ny = dx / length * width
    node.path = path([
      (start.x + nx, start.y + ny), (end.x + nx * 0.7, end.y + ny * 0.7),
      (end.x - nx * 0.7, end.y - ny * 0.7), (start.x - nx, start.y - ny),
    ])
    node.fillColor = color
  }

  func pose(_ state: FighterState, time: Double) {
    let walking = abs(state.axis) > 0.1 && state.move.isEmpty && state.stun == 0 && !state.guard
    let stride = walking ? sin(time * 15) * 19 : sin(time * 3) * 2
    let phase = Double(state.frame)
    let attacking = !state.move.isEmpty
    let attackExtension = attacking ? sin(min(1, phase / 12) * .pi / 2) : 0
    let bob = state.y > 0 ? 0 : sin(time * (walking ? 30 : 5)) * 2
    rig.xScale = state.face
    rig.position.y = state.y * 0.75
    shadow.xScale = max(0.55, 1 - state.y / 600)
    body.position.y = bob
    body.zRotation = state.stun > 0 ? -0.16 : (attacking ? -0.04 : 0)
    head.zRotation = sin(time * 3) * 0.025
    let legLift = state.y > 0 ? 25.0 : 0
    let hipA = CGPoint(x: -12, y: 83)
    let hipB = CGPoint(x: 12, y: 83)
    let kneeA = CGPoint(x: -20 - stride * 0.6, y: 45 + legLift)
    let kneeB = CGPoint(x: 20 + stride * 0.6, y: 42 + legLift)
    let footA = CGPoint(x: -32 - stride, y: 6 + legLift)
    let footB = CGPoint(x: 34 + stride, y: 6 + legLift * 0.3)
    limb(limbs[0], hipA, kneeA, 10, ink)
    limb(limbs[1], kneeA, footA, 8, ink)
    limb(limbs[2], hipB, kneeB, 10, UIColor(white: 0.17, alpha: 1))
    limb(limbs[3], kneeB, footB, 8, ink)
    let handX = state.guard ? 29.0 : attacking ? 32 + 65 * attackExtension : 31.0
    let handY = state.guard ? 155.0 : attacking ? 124 + sin(phase * 0.15) * 10 : 101.0
    limb(limbs[4], CGPoint(x: -24, y: 137), CGPoint(x: -37, y: 114), 9, slot == 0 ? ink : .white)
    limb(
      limbs[5], CGPoint(x: -37, y: 114),
      CGPoint(x: state.guard ? 18 : -23, y: state.guard ? 147 : 99), 7, accent)
    limb(
      limbs[6], CGPoint(x: 21, y: 140), CGPoint(x: (handX + 20) / 2, y: handY - 10), 10,
      slot == 0 ? ink : .white)
    limb(limbs[7], CGPoint(x: (handX + 20) / 2, y: handY - 10), CGPoint(x: handX, y: handY), 8, ink)
    let flutter = sin(time * 7) * 8
    coat.path = path([
      (-24, 129), (-38, 79), (-51 - flutter, 43), (-16, 53), (0, 88),
      (22, 126), (27, 70), (10, 59), (7, 85),
    ])
    coat.fillColor = slot == 0 ? ink : .white
    coat.strokeColor = accent
    coat.lineWidth = 2
    if slot == 1 {
      scarf.path = path([
        (-12, 151), (-40, 155), (-72 - flutter, 139), (-53, 162), (-80, 167), (-43, 174), (6, 151),
      ])
      scarf.fillColor = red
      scarf.strokeColor = ink
    }
    if slot == 0 {
      let tipX = attacking ? handX + 85 : handX + 25
      let tipY = attacking ? handY + 8 : handY - 88
      blade.path = path([
        (handX - 3, handY + 2), (tipX, tipY), (tipX + 4, tipY + 8), (handX + 3, handY + 5),
      ])
    } else {
      blade.path = path([
        (handX - 6, handY - 7), (handX + 12, handY - 4), (handX + 14, handY + 6),
        (handX - 6, handY + 10),
      ])
      blade.fillColor = accent
    }
    guardArc.isHidden = !state.guard
    guardArc.path = CGPath(ellipseIn: CGRect(x: 5, y: 62, width: 74, height: 114), transform: nil)
    aura.isHidden = !state.awakened && state.invulnerable == 0
    aura.alpha = 0.5 + sin(time * 12) * 0.3
    companion.isHidden = state.companion == 0
    companion.alpha = min(0.88, Double(state.companion) / 10)
    companion.position = CGPoint(
      x: state.move == "super" ? 60 : -48 + attackExtension * 110, y: 20 + sin(time * 6) * 7)
    companion.zRotation = sin(time * 4) * 0.035
  }
}

final class ArenaScene: SKScene {
  private let world = SKNode()
  private var fighters: [FighterArt] = []
  private var latest: MatchState?
  private var lastEvent = 0
  private var shake = 0.0
  private var freezeUntil = 0.0
  private var built = false

  override init() {
    super.init(size: CGSize(width: 1000, height: 460))
    scaleMode = .resizeFill
    backgroundColor = ink
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func didMove(to view: SKView) {
    guard !built else { return }
    built = true
    size = CGSize(width: 1000, height: 460)
    scaleMode = .aspectFill
    addChild(world)
    let background = SKSpriteNode(imageNamed: "stage")
    background.size = size
    background.position = CGPoint(x: 500, y: 230)
    background.zPosition = -20
    world.addChild(background)
    let veil = SKSpriteNode(color: ink.withAlphaComponent(0.16), size: size)
    veil.position = background.position
    veil.zPosition = -19
    world.addChild(veil)
    for y in stride(from: 0, through: 460, by: 5) {
      let scan = SKSpriteNode(
        color: ink.withAlphaComponent(0.09), size: CGSize(width: 1000, height: 1))
      scan.position = CGPoint(x: 500, y: y)
      scan.zPosition = -18
      world.addChild(scan)
    }
    let floor = SKShapeNode(rect: CGRect(x: 0, y: 93, width: 1000, height: 2))
    floor.fillColor = gold
    floor.strokeColor = .clear
    world.addChild(floor)
    for slot in 0..<2 {
      let actor = FighterArt(slot: slot)
      actor.position = CGPoint(x: slot == 0 ? 295 : 705, y: 100)
      actor.zPosition = 1
      world.addChild(actor)
      fighters.append(actor)
    }
  }

  func apply(_ state: MatchState, localID: String) {
    latest = state
    for event in state.events where event.id > lastEvent {
      if ["hit", "block"].contains(event.kind) {
        impact(event, blocked: event.kind == "block")
        shake = event.kind == "block" ? 2 : 7
        freezeUntil = CACurrentMediaTime() + 0.055
      }
      if event.kind == "burst", let fighter = state.fighters.first(where: { $0.id == event.player })
      {
        ring(at: CGPoint(x: fighter.x, y: 188 + fighter.y * 0.75), color: cyan, radius: 145)
        shake = 10
      }
      if event.kind == "super", let fighter = state.fighters.first(where: { $0.id == event.player })
      {
        ring(at: CGPoint(x: fighter.x, y: 190), color: gold, radius: 260)
        banner("SIGNAL OVERDRIVE", color: gold)
      }
      if event.kind == "break" { banner("COMPANION BREAK", color: red) }
      if event.kind == "awakening" { banner("AWAKENING", color: cyan) }
      lastEvent = max(lastEvent, event.id)
    }
  }

  override func update(_ currentTime: TimeInterval) {
    guard let latest, fighters.count == 2 else { return }
    shake *= 0.87
    world.position = CGPoint(
      x: sin(currentTime * 117) * shake, y: cos(currentTime * 133) * shake * 0.5)
    for state in latest.fighters {
      let actor = fighters[state.slot]
      actor.position.x += (state.x - actor.position.x) * 0.35
      if CACurrentMediaTime() > freezeUntil { actor.pose(state, time: currentTime) }
    }
  }

  private func impact(_ event: CombatEvent, blocked: Bool) {
    let origin = CGPoint(x: event.x ?? 500, y: 100 + (event.y ?? 100) * 0.75)
    let color = blocked ? cyan : gold
    ring(at: origin, color: color, radius: blocked ? 55 : 75)
    for i in 0..<12 {
      let angle = Double(i) * .pi / 6 + Double(event.id % 4)
      let length = Double(25 + (i * 17) % 55)
      let spark = polygon(
        points([(0, -3), (length, 0), (0, 3), (-8, 0)]),
        fill: i % 3 == 0 ? .white : color, stroke: .clear, width: 0)
      spark.position = origin
      spark.zRotation = angle
      spark.zPosition = 8
      world.addChild(spark)
      spark.run(
        .sequence([
          .group([
            .moveBy(x: cos(angle) * 45, y: sin(angle) * 45, duration: 0.23),
            .fadeOut(withDuration: 0.25),
          ]), .removeFromParent(),
        ]))
    }
    if let combo = event.combo, combo > 1 && !blocked {
      banner("\(combo) HIT COMBO", color: .white)
    }
  }

  private func ring(at position: CGPoint, color: UIColor, radius: CGFloat) {
    let node = SKShapeNode(circleOfRadius: radius)
    node.position = position
    node.strokeColor = color
    node.lineWidth = 6
    node.glowWidth = 5
    node.fillColor = .clear
    node.zPosition = 7
    node.setScale(0.15)
    world.addChild(node)
    node.run(
      .sequence([
        .group([.scale(to: 1, duration: 0.28), .fadeOut(withDuration: 0.3)]), .removeFromParent(),
      ]))
  }

  private func banner(_ text: String, color: UIColor) {
    childNode(withName: "effectBanner")?.removeFromParent()
    let label = SKLabelNode(fontNamed: "AvenirNextCondensed-HeavyItalic")
    label.name = "effectBanner"
    label.text = text
    label.fontSize = 32
    label.fontColor = color
    label.position = CGPoint(x: 500, y: 308)
    label.zPosition = 30
    addChild(label)
    label.run(
      .sequence([
        .scale(to: 1.12, duration: 0.12), .wait(forDuration: 0.4), .fadeOut(withDuration: 0.15),
        .removeFromParent(),
      ]))
  }
}
