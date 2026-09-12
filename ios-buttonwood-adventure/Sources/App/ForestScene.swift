import SpriteKit
import UIKit

@MainActor
final class ForestScene: SKScene {
  var game = Game(levelIndex: 0)
  var onChange: ((Game, [GameEvent]) -> Void)?
  var running = false
  var showcase = true
  private let world = SKNode()
  private let far = SKNode()
  private let middle = SKNode()
  private let foreground = SKNode()
  private let cameraNode = SKCameraNode()
  private var hero = SKNode()
  private var shieldRing = SKShapeNode()
  private var checkpointNode = SKNode()
  private var ledgeNodes: [SKNode] = []
  private var coinNodes: [SKNode] = []
  private var bugNodes: [SKNode] = []
  private var powerupNode = SKNode()
  private var previousTime = 0.0
  private var accumulator = 0.0
  private var hudClock = 0.0
  private var sky = SKSpriteNode()
  private var motes: [SKShapeNode] = []

  override init() {
    super.init(size: CGSize(width: 1100, height: 500))
    scaleMode = .aspectFill
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func didMove(to view: SKView) {
    view.preferredFramesPerSecond = 60
    resize(view.bounds.size)
  }

  func resize(_ viewSize: CGSize) {
    guard viewSize.height > 0 else { return }
    size = CGSize(width: viewSize.width / viewSize.height * 500, height: 500)
  }

  func load(_ index: Int, showcase: Bool = false) {
    self.showcase = showcase
    running = !showcase
    game = Game(levelIndex: index)
    previousTime = 0
    accumulator = 0
    hudClock = 0
    removeAllChildren()
    world.removeAllChildren()
    far.removeAllChildren()
    middle.removeAllChildren()
    foreground.removeAllChildren()
    cameraNode.removeAllChildren()
    ledgeNodes = []
    coinNodes = []
    bugNodes = []
    motes = []
    camera = cameraNode
    addChild(cameraNode)
    buildBackdrop()
    world.zPosition = 5
    addChild(world)
    for ledge in game.level.ledges {
      let node = ForestArt.platform(ledge)
      node.position = CGPoint(x: ledge.x, y: ledge.y)
      world.addChild(node)
      ledgeNodes.append(node)
    }
    for (index, point) in game.level.coins.enumerated() {
      let node = ForestArt.coin()
      node.position = CGPoint(x: point.x, y: point.y)
      node.userData = ["phase": Double(index)]
      world.addChild(node)
      coinNodes.append(node)
    }
    for bug in game.level.bugs {
      let node = ForestArt.beetle()
      node.position = CGPoint(x: bug.x, y: bug.y)
      world.addChild(node)
      bugNodes.append(node)
    }
    powerupNode = ForestArt.acorn()
    powerupNode.position = CGPoint(x: game.level.powerup.x, y: game.level.powerup.y)
    world.addChild(powerupNode)
    checkpointNode = ForestArt.lantern()
    checkpointNode.position = CGPoint(x: game.level.checkpoint.x, y: game.level.checkpoint.y)
    world.addChild(checkpointNode)
    let goal = ForestArt.door()
    goal.position = CGPoint(x: game.level.goal.x, y: game.level.goal.y)
    world.addChild(goal)
    addSign("LANTERN REST", at: game.level.checkpoint, offset: 122)
    addSign("HOMEWARD", at: game.level.goal, offset: 198)
    hero = ForestArt.explorer()
    hero.zPosition = 15
    world.addChild(hero)
    shieldRing = ForestArt.oval(61, 83, 0xFFF1A3, y: 37)
    shieldRing.fillColor = .clear
    shieldRing.strokeColor = UIColor(hex: 0xF6D783, alpha: 0.7)
    shieldRing.lineWidth = 2
    hero.addChild(shieldRing)
    if showcase {
      hero.position = CGPoint(x: size.width * 0.74, y: 132)
      hero.setScale(2.7)
      let plinth = ForestArt.platform(Ledge(x: 0, y: 0, width: 360, depth: 180))
      plinth.position = CGPoint(x: size.width * 0.74 - 170, y: 130)
      plinth.zPosition = 6
      world.addChild(plinth)
      hero.zPosition = 15
      for (x, scale) in [(0.61, 1.7), (0.87, 1.4), (0.89, 0.8)] {
        let flower = ForestArt.flower(x: size.width * x, y: 133, color: 0xF8DCAA, scale: scale)
        flower.zPosition = 14
        world.addChild(flower)
      }
      let lamp = ForestArt.lantern(active: true)
      lamp.position = CGPoint(x: size.width * 0.86, y: 130)
      lamp.setScale(1.35)
      lamp.zPosition = 12
      world.addChild(lamp)
      for coin in coinNodes { coin.isHidden = true }
      for bug in bugNodes { bug.isHidden = true }
    }
    cameraNode.position = CGPoint(x: size.width / 2, y: 215)
    sync()
  }

  private func addSign(_ text: String, at point: Point, offset: CGFloat) {
    let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    label.text = text
    label.fontSize = 10
    label.fontColor = UIColor(hex: 0xF3E4B6)
    label.position = CGPoint(x: point.x, y: point.y + offset)
    world.addChild(label)
  }

  private func buildBackdrop() {
    let night = game.level.palette == 2
    let palette: [UInt32] =
      night
      ? [0x142F39, 0x426B6A, 0xACAD87]
      : (game.level.palette == 1
        ? [0x244C4C, 0x81A491, 0xD6D4A2] : [0x2C6158, 0x9BB995, 0xE5DBA6])
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 500))
    let image = renderer.image { context in
      let colors = palette.map { UIColor(hex: $0).cgColor }
      if let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors as CFArray, locations: [0, 0.62, 1])
      {
        context.cgContext.drawLinearGradient(
          gradient, start: .zero, end: CGPoint(x: 0, y: 500), options: [])
      }
    }
    sky = SKSpriteNode(texture: SKTexture(image: image), size: CGSize(width: 3000, height: 750))
    sky.position = CGPoint(x: size.width / 2, y: 230)
    sky.zPosition = -40
    addChild(sky)
    far.zPosition = -30
    middle.zPosition = -20
    foreground.zPosition = 25
    addChild(far)
    addChild(middle)
    addChild(foreground)
    let sun = ForestArt.oval(105, 105, night ? 0xE6DCA7 : 0xFFF2C4, x: 790, y: 365)
    sun.alpha = 0.8
    far.addChild(sun)
    for radius in [130.0, 180, 245] {
      let glow = ForestArt.oval(radius, radius, 0xFFEAB3, x: 790, y: 365)
      glow.alpha = 0.055
      far.addChild(glow)
    }
    for i in -2..<25 {
      let x = CGFloat(i) * 167
      let hill = ForestArt.oval(
        550, 210 + CGFloat(i % 3) * 30, night ? 0x3A6665 : 0x92AA7E,
        x: x + 100, y: 95)
      far.addChild(hill)
      let tree = ForestArt.tree(
        x: x, height: 325 + CGFloat((i + 6) % 4) * 45,
        color: night ? 0x315557 : 0x6F947B,
        foliage: night ? 0x2D5456 : 0x749A77)
      tree.alpha = 0.7
      far.addChild(tree)
    }
    for i in -1..<20 {
      let tree = ForestArt.tree(
        x: CGFloat(i) * 247 + 130,
        height: 365 + CGFloat((i + 4) % 3) * 55,
        color: night ? 0x254949 : 0x486F5D,
        foliage: night ? 0x264F4B : 0x477459)
      middle.addChild(tree)
    }
    for i in 0..<5 {
      let ray = ForestArt.path(
        [
          CGPoint(x: 640 + i * 77, y: 520), CGPoint(x: 695 + i * 77, y: 520),
          CGPoint(x: 370 + i * 57, y: 0), CGPoint(x: 200 + i * 57, y: 0),
        ], 0xFFF0B3)
      ray.alpha = night ? 0.02 : 0.045
      middle.addChild(ray)
    }
    for i in -1..<28 {
      let fern = ForestArt.fern(
        x: CGFloat(i) * 185, y: -32,
        scale: 2.5 + CGFloat((i + 2) % 3) * 0.5,
        color: night ? 0x153A38 : 0x244E3E)
      foreground.addChild(fern)
    }
    for i in 0..<26 {
      let mote = ForestArt.oval(i % 4 == 0 ? 4 : 2.5, i % 4 == 0 ? 4 : 2.5, 0xFAE7A0)
      mote.alpha = 0.55
      mote.position = CGPoint(x: CGFloat(i * 83 % 1200), y: CGFloat(120 + i * 59 % 280))
      mote.zPosition = 1
      cameraNode.addChild(mote)
      motes.append(mote)
    }
  }

  override func update(_ currentTime: TimeInterval) {
    let delta = previousTime == 0 ? 0 : min(currentTime - previousTime, 0.05)
    previousTime = currentTime
    var emitted: [GameEvent] = []
    if running, !showcase {
      accumulator += delta
      while accumulator >= 1.0 / 120 {
        game.step(1.0 / 120)
        emitted += game.events
        accumulator -= 1.0 / 120
      }
      hudClock += delta
      if hudClock > 0.10 || !emitted.isEmpty || game.phase != .playing {
        onChange?(game, emitted)
        hudClock = 0
      }
    }
    sync()
    if !UIAccessibility.isReduceMotionEnabled {
      let clock = running || showcase ? currentTime : game.time
      for (index, mote) in motes.enumerated() {
        mote.position = CGPoint(
          x: CGFloat(index * 83 % 1200) - size.width / 2
            + sin(clock * 0.25 + Double(index)) * 12,
          y: CGFloat(index * 59 % 350) - 90 + sin(clock * 0.4 + Double(index)) * 9)
        mote.alpha = 0.3 + (sin(clock + Double(index)) + 1) * 0.22
      }
      if showcase {
        hero.yScale = 2.7 + sin(currentTime * 2) * 0.022
        hero.childNode(withName: "scarf")?.zRotation = sin(currentTime * 2) * 0.07
      }
    }
  }

  private func sync() {
    if !showcase {
      hero.position = CGPoint(x: game.player.x, y: game.player.y)
      hero.xScale = game.facing
      hero.yScale = game.grounded ? 1 : (game.velocity.y > 0 ? 1.05 : 0.96)
      hero.alpha = game.invincible > 0 && Int(game.time * 10) % 2 == 0 ? 0.45 : 1
      let pace = game.grounded ? sin(game.time * 22) * min(abs(game.velocity.x) / 250, 1) : 0
      hero.childNode(withName: "leftFoot")?.position.x = -7 + pace * 4
      hero.childNode(withName: "rightFoot")?.position.x = 7 - pace * 4
      hero.childNode(withName: "scarf")?.zRotation = -abs(game.velocity.x) / 1300
      let target = min(
        max(size.width / 2, game.player.x + size.width * 0.15),
        game.level.length - size.width / 2 + 100)
      cameraNode.position.x += (target - cameraNode.position.x) * 0.12
      for (index, ledge) in game.level.ledges.enumerated() {
        ledgeNodes[index].position.x = ledge.x + ledge.offset(at: game.time)
        for gear in ledgeNodes[index].children where gear.name == "gear" {
          gear.zRotation = -game.time
        }
      }
      for (index, node) in coinNodes.enumerated() {
        node.isHidden = game.collected.contains(index)
        node.position.y = game.level.coins[index].y + sin(game.time * 2 + Double(index)) * 3
        node.xScale = 0.85 + sin(game.time * 2 + Double(index)) * 0.15
      }
      for (index, node) in bugNodes.enumerated() {
        node.isHidden = game.stomped.contains(index)
        let point = game.bugPosition(index)
        node.position = CGPoint(x: point.x, y: point.y)
        node.xScale = cos(game.time * 1.2 + game.level.bugs[index].phase) > 0 ? 1 : -1
        node.yScale = 1 + sin(game.time * 9) * 0.045
      }
    }
    shieldRing.isHidden = !game.shield || showcase
    powerupNode.isHidden = game.powerupTaken || showcase
    if let glass = checkpointNode.childNode(withName: "glass") as? SKShapeNode {
      glass.fillColor = UIColor(hex: game.checkpointActive ? 0xFFE8A1 : 0x8C9C77)
    }
    checkpointNode.childNode(withName: "glow")?.alpha = game.checkpointActive ? 0.25 : 0.03
    far.position.x = cameraNode.position.x * 0.84
    middle.position.x = cameraNode.position.x * 0.62
    foreground.position.x = -cameraNode.position.x * 0.08
    sky.position.x = cameraNode.position.x
  }

  func burst(_ event: GameEvent) {
    guard !UIAccessibility.isReduceMotionEnabled else { return }
    let color: UInt32 = event == .hurt ? 0xD98770 : 0xF4D786
    for i in 0..<10 {
      let spark = ForestArt.oval(4, 4, color, x: game.player.x, y: game.player.y + 30)
      spark.zPosition = 30
      world.addChild(spark)
      let angle = Double(i) * .pi / 5
      spark.run(
        .sequence([
          .group([
            .moveBy(x: cos(angle) * 42, y: sin(angle) * 42, duration: 0.42),
            .fadeOut(withDuration: 0.42),
          ]), .removeFromParent(),
        ]))
    }
  }
}
