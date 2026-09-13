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

private enum FighterPose: Int {
  case idle, walkLeft, walkRight, guardUp, jump, light, windup, heavy
  case summon, overdrive, hurt, burst

  static func current(_ state: FighterState, time: Double) -> FighterPose {
    if state.stun > 0 { return .hurt }
    switch state.move {
    case "light": return state.frame < 5 || state.frame > 13 ? .idle : .light
    case "heavy": return state.frame < 13 ? .windup : .heavy
    case "summon": return .summon
    case "super": return state.frame < 15 ? .overdrive : .summon
    case "burst": return .burst
    default:
      if state.y > 0 { return .jump }
      if state.guard { return .guardUp }
      if abs(state.axis) > 0.1 {
        return Int(time * 9) % 2 == 0 ? .walkLeft : .walkRight
      }
      return .idle
    }
  }
}

final class FighterArt: SKNode {
  private static let atlas = SKTextureAtlas(named: "Fighters")
  private let rig = SKNode()
  private let body = SKNode()
  private let sprite = SKSpriteNode()
  private let companion = SKSpriteNode()
  private let companionGlow = SKSpriteNode()
  private let afterimage = SKSpriteNode()
  private let shadow = SKShapeNode(ellipseOf: CGSize(width: 94, height: 15))
  private let guardArc = SKShapeNode()
  private let slash = SKShapeNode()
  private let aura = SKShapeNode(ellipseOf: CGSize(width: 128, height: 214))
  private let textures: [SKTexture]
  private let spiritTextures: [SKTexture]
  private let slot: Int
  private var accent: UIColor { slot == 0 ? cyan : red }

  init(slot: Int) {
    self.slot = slot
    let name = slot == 0 ? "rei" : "mika"
    let spirit = slot == 0 ? "antenna" : "redshift"
    textures = (0..<12).map { Self.atlas.textureNamed("\(name)-\($0)") }
    spiritTextures = (0..<4).map { Self.atlas.textureNamed("\(spirit)-\($0)") }
    super.init()
    for texture in textures + spiritTextures { texture.filteringMode = .linear }
    shadow.fillColor = .black.withAlphaComponent(0.6)
    shadow.strokeColor = .clear
    addChild(shadow)
    addChild(rig)
    rig.addChild(companionGlow)
    rig.addChild(companion)
    rig.addChild(body)
    companion.zPosition = -2
    companionGlow.zPosition = -3
    for node in [sprite, companion, companionGlow, afterimage] {
      node.size = textures[0].size()
      node.setScale(0.48)
      node.anchorPoint = CGPoint(x: 384.0 / 896, y: 40.0 / 640)
    }
    body.addChild(afterimage)
    body.addChild(sprite)
    afterimage.zPosition = -1
    afterimage.color = accent
    afterimage.colorBlendFactor = 0.8
    afterimage.blendMode = .add
    companionGlow.color = accent
    companionGlow.colorBlendFactor = 1
    companionGlow.blendMode = .add
    aura.position.y = 98
    aura.fillColor = .clear
    aura.strokeColor = accent
    aura.lineWidth = 2
    aura.glowWidth = 5
    body.addChild(aura)
    guardArc.fillColor = accent.withAlphaComponent(0.1)
    guardArc.strokeColor = accent
    guardArc.lineWidth = 3
    guardArc.glowWidth = 6
    guardArc.zPosition = 2
    body.addChild(guardArc)
    slash.strokeColor = accent
    slash.lineWidth = slot == 0 ? 3 : 7
    slash.glowWidth = 4
    slash.blendMode = .add
    slash.zPosition = 2
    body.addChild(slash)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  func pose(_ state: FighterState, time: Double) {
    let frame = Double(state.frame)
    let pose = FighterPose.current(state, time: time)
    let walking = pose == .walkLeft || pose == .walkRight
    let striking = pose == .light || pose == .heavy
    let startup = state.move == "heavy" ? 13.0 : 5.0
    let strike = striking ? max(0, 1 - abs(frame - startup - 3) / 12) : 0
    rig.xScale = state.face
    rig.position.y = state.y * 0.75
    shadow.xScale = max(0.55, 1 - state.y / 600)
    sprite.texture = textures[pose.rawValue]
    body.position = CGPoint(
      x: state.stun > 0 ? -7 : strike * 9,
      y: walking ? abs(sin(time * 14)) * 2 : 0)
    body.yScale = pose == .idle ? 1 + sin(time * 4) * 0.006 : 1
    body.zRotation =
      state.stun > 0 ? 0.055 : walking ? -state.axis * state.face * 0.018 : -strike * 0.025
    sprite.color = .white
    sprite.colorBlendFactor = state.invulnerable > 0 ? 0.15 + sin(time * 35) * 0.1 : 0
    afterimage.texture = sprite.texture
    afterimage.position = CGPoint(x: -15 * strike, y: 2)
    afterimage.alpha = strike * 0.18
    guardArc.isHidden = !state.guard
    guardArc.path = CGPath(ellipseIn: CGRect(x: 2, y: 40, width: 79, height: 126), transform: nil)
    aura.isHidden = !state.awakened && state.invulnerable == 0
    aura.alpha = 0.45 + sin(time * 12) * 0.22
    slash.isHidden = strike < 0.3
    slash.alpha = strike * 0.7
    let arc = CGMutablePath()
    if pose == .heavy && slot == 0 {
      arc.move(to: CGPoint(x: 8, y: 232))
      arc.addQuadCurve(to: CGPoint(x: 166, y: 36), control: CGPoint(x: 219, y: 149))
    } else {
      arc.move(to: CGPoint(x: 31, y: 112))
      arc.addQuadCurve(
        to: CGPoint(x: slot == 0 ? 176 : 112, y: 119), control: CGPoint(x: 111, y: 130))
    }
    slash.path = arc
    let spiritFrame: Int
    if state.move == "super" {
      spiritFrame = frame < 15 ? 0 : frame < 34 ? 2 : 3
    } else if state.move == "summon" {
      spiritFrame = frame < 18 ? 0 : frame < 29 ? 1 : 3
    } else {
      spiritFrame = 3
    }
    companion.texture = spiritTextures[spiritFrame]
    companion.isHidden = state.companion == 0
    companion.alpha = min(0.82, Double(state.companion) / 12)
    let reaching = spiritFrame == 1 || spiritFrame == 2
    let windup = state.move == "super" ? 15.0 : 18.0
    let approach = min(1, frame / windup)
    let destination = reaching ? 110.0 : spiritFrame == 0 ? -44 + approach * 154 : -44.0
    companion.position.x += (destination - companion.position.x) * 0.28
    companion.position.y = 16 + sin(time * 6) * 4
    companion.zRotation = reaching ? -0.025 : sin(time * 4) * 0.012
    companionGlow.texture = companion.texture
    companionGlow.isHidden = companion.isHidden
    companionGlow.position = CGPoint(x: companion.position.x - 4, y: companion.position.y + 2)
    companionGlow.zRotation = companion.zRotation
    companionGlow.alpha = companion.alpha * 0.3
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
