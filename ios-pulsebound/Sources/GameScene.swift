import SpriteKit
import UIKit

final class GameScene: SKScene {
  weak var model: GameModel?
  private let world = SKNode()
  private let scenery = SKNode()
  private let player = SKNode()
  private let trail = SKNode()
  private let ground = 154.0
  private let anchor = 160.0
  private var previousTime: TimeInterval = 0
  private var lastPhase = RunPhase.ready
  private var trailClock = 0.0
  private var reducedMotion = false
  private let coral = UIColor(red: 1, green: 0.36, blue: 0.43, alpha: 1)
  private let cyan = UIColor(red: 0.35, green: 0.95, blue: 0.94, alpha: 1)

  init(model: GameModel) {
    self.model = model
    super.init(size: CGSize(width: 760, height: 620))
    scaleMode = .aspectFit
    backgroundColor = UIColor(red: 0.035, green: 0.025, blue: 0.09, alpha: 1)
  }

  required init?(coder aDecoder: NSCoder) { nil }

  override func didMove(to view: SKView) {
    guard children.isEmpty, let model else { return }
    reducedMotion = UIAccessibility.isReduceMotionEnabled
    addChild(scenery)
    addChild(trail)
    addChild(world)
    createScenery()
    for obstacle in model.stage.obstacles {
      let path = CGMutablePath()
      path.move(to: .zero)
      path.addLine(to: CGPoint(x: obstacle.width / 2, y: obstacle.height))
      path.addLine(to: CGPoint(x: obstacle.width, y: 0))
      path.closeSubpath()
      let shape = SKShapeNode(path: path)
      shape.fillColor = coral.withAlphaComponent(0.22)
      shape.strokeColor = coral
      shape.lineWidth = 3.4
      shape.glowWidth = 3
      shape.position = CGPoint(x: obstacle.x, y: ground)
      world.addChild(shape)
      let dot = SKShapeNode(circleOfRadius: 2.3)
      dot.fillColor = .white
      dot.strokeColor = .clear
      dot.position = CGPoint(x: obstacle.width / 2, y: obstacle.height - 9)
      shape.addChild(dot)
    }
    for marker in model.stage.checkpoints {
      let line = SKShapeNode(rectOf: CGSize(width: 1, height: 155))
      line.fillColor = cyan.withAlphaComponent(model.practice ? 0.5 : 0.08)
      line.strokeColor = .clear
      line.position = CGPoint(x: marker, y: ground + 77)
      world.addChild(line)
      if model.practice {
        let flag = SKLabelNode(fontNamed: "Menlo-Bold")
        flag.text = "◆"
        flag.fontColor = cyan
        flag.fontSize = 24
        flag.position = CGPoint(x: marker, y: ground + 164)
        world.addChild(flag)
      }
    }
    let finish = SKShapeNode(rectOf: CGSize(width: 8, height: 280), cornerRadius: 4)
    finish.fillColor = cyan
    finish.strokeColor = .white
    finish.glowWidth = 10
    finish.position = CGPoint(x: model.stage.length, y: ground + 140)
    world.addChild(finish)
    let aura = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 12)
    aura.strokeColor = cyan.withAlphaComponent(0.2)
    aura.lineWidth = 1.5
    player.addChild(aura)
    let body = SKShapeNode(rectOf: CGSize(width: 42, height: 42), cornerRadius: 7)
    body.fillColor = cyan
    body.strokeColor = UIColor.white.withAlphaComponent(0.9)
    body.lineWidth = 2
    body.glowWidth = 4
    player.addChild(body)
    let core = SKShapeNode(rectOf: CGSize(width: 16, height: 16), cornerRadius: 3)
    core.fillColor = backgroundColor
    core.strokeColor = backgroundColor
    player.addChild(core)
    let glint = SKShapeNode(rectOf: CGSize(width: 5, height: 5), cornerRadius: 1)
    glint.fillColor = .white
    glint.strokeColor = .clear
    glint.position = CGPoint(x: -10, y: 10)
    player.addChild(glint)
    addChild(player)
    positionWorld()
  }

  private func createScenery() {
    for index in 0..<25 {
      let star = SKShapeNode(circleOfRadius: index % 3 == 0 ? 1.7 : 0.9)
      star.fillColor = UIColor.white.withAlphaComponent(0.15 + Double(index % 3) * 0.1)
      star.strokeColor = .clear
      star.position = CGPoint(x: (index * 137) % 840, y: 210 + (index * 91) % 390)
      scenery.addChild(star)
    }
    for index in 0..<4 {
      let side = 135.0 + Double(index) * 59
      let ring = SKShapeNode(rectOf: CGSize(width: side, height: side), cornerRadius: 20)
      ring.strokeColor = (index == 0 ? coral : cyan).withAlphaComponent(index == 0 ? 0.35 : 0.09)
      ring.lineWidth = index == 0 ? 3 : 1
      ring.zRotation = .pi / 4
      ring.position = CGPoint(x: 555, y: 366)
      scenery.addChild(ring)
    }
    let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    label.text = String(format: "%02d", (model?.selection ?? 0) + 1)
    label.fontSize = 70
    label.fontColor = UIColor.white.withAlphaComponent(0.08)
    label.position = CGPoint(x: 554, y: 342)
    scenery.addChild(label)
    for index in 0..<18 {
      let height = Double(50 + (index * 47) % 160)
      let tower = SKShapeNode(rectOf: CGSize(width: 28, height: height))
      tower.fillColor = UIColor(red: 0.12, green: 0.08, blue: 0.22, alpha: 0.6)
      tower.strokeColor = UIColor(red: 0.29, green: 0.2, blue: 0.42, alpha: 0.4)
      tower.position = CGPoint(x: Double(index) * 65, y: ground + height / 2)
      tower.name = "tower.\(index)"
      scenery.addChild(tower)
    }
    let floor = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 760, height: ground))
    floor.fillColor = UIColor(red: 0.065, green: 0.045, blue: 0.13, alpha: 1)
    floor.strokeColor = .clear
    addChild(floor)
    for index in 0...15 {
      let path = CGMutablePath()
      path.move(to: CGPoint(x: Double(index) * 65 - 100, y: 0))
      path.addLine(to: CGPoint(x: Double(index) * 50, y: ground))
      let line = SKShapeNode(path: path)
      line.strokeColor = cyan.withAlphaComponent(0.075)
      addChild(line)
    }
    for y in [30.0, 79.0, 113.0, 137.0] {
      let line = SKShapeNode(rect: CGRect(x: 0, y: y, width: 760, height: 0.5))
      line.strokeColor = cyan.withAlphaComponent(0.10)
      addChild(line)
    }
    let horizon = SKShapeNode(rect: CGRect(x: 0, y: ground - 1, width: 760, height: 2))
    horizon.fillColor = cyan
    horizon.strokeColor = .clear
    horizon.glowWidth = 3
    addChild(horizon)
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { model?.tap() }

  override func update(_ currentTime: TimeInterval) {
    guard let model else { return }
    let dt = previousTime == 0 ? 0 : min(currentTime - previousTime, 0.1)
    previousTime = currentTime
    model.tick(dt)
    positionWorld()
    if model.engine.phase == .running {
      if !reducedMotion {
        trailClock += dt
        if trailClock > 0.035 {
          trailClock = 0
          addTrail()
        }
      }
      if !model.engine.grounded {
        player.zRotation -= dt * 4.5
      } else {
        player.zRotation = 0
      }
    }
    if model.engine.phase == .crashed && lastPhase != .crashed { burst() }
    player.isHidden = model.engine.phase == .crashed
    lastPhase = model.engine.phase
  }

  private func positionWorld() {
    guard let model else { return }
    world.position.x = anchor - model.engine.x
    player.position = CGPoint(x: anchor, y: ground + 19 + model.engine.y)
    for index in 0..<18 {
      scenery.childNode(withName: "tower.\(index)")?.position.x =
        (Double(index) * 65 - model.engine.x * 0.14)
        .truncatingRemainder(dividingBy: 1170)
        + (model.engine.x * 0.14 > Double(index) * 65 ? 1170 : 0)
    }
  }

  private func addTrail() {
    guard let model else { return }
    let node = SKShapeNode(rectOf: CGSize(width: 24, height: 24), cornerRadius: 4)
    node.fillColor = cyan.withAlphaComponent(0.22)
    node.strokeColor = .clear
    node.position = player.position
    node.zRotation = player.zRotation
    trail.addChild(node)
    node.run(
      .sequence([
        .group([
          .moveBy(x: -model.stage.speed * 0.3, y: 0, duration: 0.3),
          .fadeOut(withDuration: 0.3), .scale(to: 0.25, duration: 0.3),
        ]), .removeFromParent(),
      ]))
  }

  private func burst() {
    guard !reducedMotion else { return }
    for index in 0..<12 {
      let shard = SKShapeNode(rectOf: CGSize(width: 8, height: 8))
      shard.fillColor = index % 2 == 0 ? coral : cyan
      shard.strokeColor = .clear
      shard.position = player.position
      addChild(shard)
      let angle = Double(index) * .pi / 6
      shard.run(
        .sequence([
          .group([
            .moveBy(x: cos(angle) * 95, y: sin(angle) * 95, duration: 0.45),
            .fadeOut(withDuration: 0.5), .rotate(byAngle: 2, duration: 0.5),
          ]), .removeFromParent(),
        ]))
    }
  }
}
