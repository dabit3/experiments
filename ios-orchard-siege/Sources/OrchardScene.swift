import SpriteKit
import UIKit

final class FortBody: SKSpriteNode {
  var health: CGFloat = 0
  var points = 0
  var isTarget = false
  var material: Material = .wood
}

final class OrchardScene: SKScene, SKPhysicsContactDelegate {
  weak var game: GameModel?
  private let world = SKNode()
  private let effects = SKNode()
  private let trajectory = SKNode()
  private let bands = SKShapeNode()
  private var blocks: [FortBody] = []
  private var beetles: [FortBody] = []
  private var projectile: SKSpriteNode?
  private var level: Level?
  private var fruitIndex = 0
  private var dragging = false
  private var flying = false
  private var burstUsed = false
  private var elapsed: TimeInterval = 0
  private var quietTime: TimeInterval = 0
  private var winDelay: TimeInterval = 0
  private var previousTime: TimeInterval = 0
  private var pending: [(FortBody, CGFloat)] = []
  private let anchor = CGPoint(x: 220, y: 230)
  private let gravity: CGFloat = -420
  private var lastTrail: TimeInterval = 0
  private var framedSize = CGSize.zero
  private var framedInsets = UIEdgeInsets.zero
  private var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

  override func didMove(to view: SKView) {
    view.preferredFramesPerSecond = 60
    framePlayfield()
  }

  private func framePlayfield() {
    guard let level, let view, game?.screen == .playing else { return }
    let insets = view.window?.safeAreaInsets ?? view.safeAreaInsets
    framedSize = view.bounds.size
    framedInsets = insets
    let viewportWidth = min(view.bounds.width, view.bounds.height * size.width / size.height)
    guard viewportWidth > 0 else { return }
    let sideMargin = (view.bounds.width - viewportWidth) / 2
    let left = max(0, insets.left - sideMargin) + 16
    let right = max(0, insets.right - sideMargin) + 16
    let usableWidth = max(0.5, 1 - (left + right) / viewportWidth)
    let minX = anchor.x - 115 - 29
    let maxX = max(
      level.blocks.map { $0.x + $0.width / 2 }.max() ?? anchor.x,
      level.targets.map { $0.x + 29 }.max() ?? anchor.x)
    let maxY = max(
      level.blocks.map { $0.y + $0.height / 2 }.max() ?? anchor.y,
      level.targets.map { $0.y + 29 }.max() ?? anchor.y)
    let scale = max(0.88, (maxX - minX) / usableWidth / size.width, (maxY + 100) / size.height)
    let framing = camera ?? SKCameraNode()
    if framing.parent == nil { addChild(framing) }
    framing.setScale(scale)
    framing.position = CGPoint(
      x: (minX + maxX) / 2 + (right - left) / viewportWidth * size.width * scale / 2,
      y: size.height * scale / 2)
    camera = framing
  }

  private func prepare() {
    removeAllChildren()
    camera = nil
    world.removeAllChildren()
    effects.removeAllChildren()
    trajectory.removeAllChildren()
    blocks = []
    beetles = []
    pending = []
    projectile = nil
    flying = false
    dragging = false
    previousTime = 0
    winDelay = 0
    backgroundColor = UIColor(hex: 0xF4DDBA)
    let backdrop = SKSpriteNode(texture: OrchardArt.background())
    backdrop.size = CGSize(width: size.width + 200, height: size.height)
    backdrop.position = CGPoint(x: size.width / 2, y: size.height / 2)
    backdrop.zPosition = -50
    addChild(backdrop)
    addChild(world)
    effects.zPosition = 40
    addChild(effects)
    trajectory.zPosition = 30
    addChild(trajectory)
    physicsWorld.gravity = CGVector(dx: 0, dy: -2.8)
    physicsWorld.contactDelegate = self
    let ground = SKNode()
    ground.position = CGPoint(x: 700, y: 121)
    ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 2800, height: 28))
    ground.physicsBody?.isDynamic = false
    ground.physicsBody?.friction = 0.8
    ground.physicsBody?.categoryBitMask = 1
    world.addChild(ground)
    if !reduceMotion {
      for index in 0..<5 {
        let start = CGPoint(x: 120 + CGFloat(index) * 260, y: 560 + CGFloat(index % 2) * 60)
        let leaf = SKSpriteNode(texture: OrchardArt.leaf())
        leaf.size = CGSize(width: 18, height: 10)
        leaf.position = start
        leaf.alpha = 0
        leaf.zPosition = -10
        addChild(leaf)
        let duration = 11.0 + Double(index) * 1.7
        let drift = SKAction.customAction(withDuration: duration) { node, time in
          let progress = time / CGFloat(duration)
          node.position = CGPoint(
            x: start.x + progress * 240 + sin(progress * 14) * 28,
            y: start.y - progress * 430)
          node.zRotation = sin(progress * 9) * 0.9
          node.alpha = min(1, progress * 6) * min(1, (1 - progress) * 8)
        }
        leaf.run(
          .repeatForever(.sequence([.wait(forDuration: Double(index) * 2.3), drift])))
      }
    }
  }

  private func dust(at point: CGPoint, spread: CGFloat, count: Int) {
    for index in 0..<(reduceMotion ? 1 : count) {
      let puff = SKShapeNode(circleOfRadius: 8 + CGFloat(index % 3) * 4)
      puff.fillColor = UIColor(hex: 0xEBCFA5).withAlphaComponent(0.55)
      puff.strokeColor = .clear
      puff.position = CGPoint(
        x: point.x + CGFloat(index - count / 2) * spread / CGFloat(max(1, count)),
        y: point.y + CGFloat(index % 2) * 6)
      puff.zPosition = 35
      effects.addChild(puff)
      puff.run(
        .sequence([
          .group([
            .scale(to: 2.4, duration: 0.55),
            .moveBy(x: CGFloat(index - count / 2) * 9, y: 18, duration: 0.55),
            .fadeOut(withDuration: 0.55),
          ]), .removeFromParent(),
        ]))
    }
  }

  private func shake(_ strength: CGFloat) {
    guard !reduceMotion, let camera, camera.action(forKey: "shake") == nil else { return }
    let amount = min(9, strength)
    camera.run(
      .sequence([
        .moveBy(x: -amount, y: amount * 0.6, duration: 0.04),
        .moveBy(x: amount * 2, y: -amount * 1.2, duration: 0.05),
        .moveBy(x: -amount * 1.4, y: amount * 0.8, duration: 0.05),
        .moveBy(x: amount * 0.4, y: -amount * 0.2, duration: 0.04),
      ]), withKey: "shake")
  }

  func showGarden() {
    level = nil
    prepare()
    for block in Level.tower(1080, glass: true) {
      let node = makeBlock(block)
      node.physicsBody = nil
    }
    let bug = SKSpriteNode(texture: OrchardArt.beetle())
    bug.size = CGSize(width: 77, height: 72)
    bug.position = CGPoint(x: 1080, y: 287)
    world.addChild(bug)
    if !reduceMotion {
      bug.run(
        .repeatForever(
          .sequence([
            .moveBy(x: 0, y: 6, duration: 0.5), .moveBy(x: 0, y: -6, duration: 0.5),
            .wait(forDuration: 1.6),
          ])))
    }
    for (kind, position, width) in [
      (Fruit.apple, CGPoint(x: 825, y: 230), CGFloat(184)),
      (Fruit.pear, CGPoint(x: 1235, y: 192), CGFloat(92)),
      (Fruit.plum, CGPoint(x: 714, y: 183), CGFloat(97)),
    ] {
      let shadow = SKShapeNode(ellipseOf: CGSize(width: width * 0.9, height: 16))
      shadow.fillColor = UIColor(hex: 0x455D39).withAlphaComponent(0.2)
      shadow.strokeColor = .clear
      shadow.position = CGPoint(x: position.x, y: 138)
      world.addChild(shadow)
      let fruit = SKSpriteNode(texture: OrchardArt.fruit(kind))
      fruit.size = CGSize(width: width, height: width * 1.107)
      fruit.position = position
      world.addChild(fruit)
      if !reduceMotion {
        fruit.run(
          .repeatForever(
            .sequence([
              .rotate(toAngle: -0.035, duration: 1.8), .rotate(toAngle: 0.035, duration: 1.8),
            ])))
      }
    }
  }

  func start(_ level: Level) {
    self.level = level
    prepare()
    framePlayfield()
    fruitIndex = 0
    for spec in level.blocks { blocks.append(makeBlock(spec)) }
    for target in level.targets {
      let node = FortBody(texture: OrchardArt.beetle())
      node.size = CGSize(width: 58, height: 54)
      node.position = CGPoint(x: target.x, y: target.y)
      node.zPosition = 3
      node.health = 3.8
      node.points = 1000
      node.isTarget = true
      let body = SKPhysicsBody(circleOfRadius: 23, center: CGPoint(x: 0, y: -2))
      body.mass = 0.32
      body.friction = 0.8
      body.restitution = 0.04
      body.linearDamping = 0.4
      body.categoryBitMask = 4
      body.contactTestBitMask = UInt32.max
      node.physicsBody = body
      world.addChild(node)
      beetles.append(node)
    }
    makeSling()
    loadFruit()
  }

  @discardableResult
  private func makeBlock(_ spec: Block) -> FortBody {
    let dimensions = CGSize(width: spec.width, height: spec.height)
    let node = FortBody(texture: OrchardArt.block(spec.material, size: dimensions))
    node.size = dimensions
    node.position = CGPoint(x: spec.x, y: spec.y)
    node.health = spec.material.strength
    node.material = spec.material
    node.points = spec.material == .stone ? 400 : spec.material == .glass ? 150 : 250
    node.zPosition = 2
    let body = SKPhysicsBody(rectangleOf: dimensions)
    body.mass = spec.width * spec.height / 7000 * (spec.material == .stone ? 2 : 1)
    body.friction = 0.62
    body.restitution = 0.02
    body.linearDamping = 0.18
    body.angularDamping = 0.25
    body.categoryBitMask = 2
    body.contactTestBitMask = UInt32.max
    node.physicsBody = body
    world.addChild(node)
    return node
  }

  private func makeSling() {
    let shadow = SKShapeNode(ellipseOf: CGSize(width: 74, height: 14))
    shadow.fillColor = UIColor(hex: 0x3E5A2E).withAlphaComponent(0.22)
    shadow.strokeColor = .clear
    shadow.position = CGPoint(x: 206, y: 137)
    shadow.zPosition = 1
    world.addChild(shadow)
    let fork = SKSpriteNode(texture: OrchardArt.sling())
    fork.size = CGSize(width: 62, height: 104)
    fork.position = CGPoint(x: 219.5, y: 188)
    fork.zPosition = 5
    world.addChild(fork)
    bands.strokeColor = UIColor(hex: 0x8A4A3C)
    bands.lineWidth = 6
    bands.lineCap = .round
    bands.zPosition = 6
    bands.removeFromParent()
    world.addChild(bands)
    drawBands(to: anchor)
  }

  private func drawBands(to point: CGPoint) {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 198, y: 235))
    path.addLine(to: point)
    path.addLine(to: CGPoint(x: 241, y: 235))
    bands.path = path
  }

  private func loadFruit() {
    guard let level, fruitIndex < level.fruit.count else { return }
    let kind = level.fruit[fruitIndex]
    let fruit = SKSpriteNode(texture: OrchardArt.fruit(kind))
    fruit.size = CGSize(width: 57, height: 63)
    fruit.position = anchor
    fruit.zPosition = 8
    world.addChild(fruit)
    projectile = fruit
    world.childNode(withName: "shadow")?.removeFromParent()
    let shadow = SKShapeNode(ellipseOf: CGSize(width: 44, height: 10))
    shadow.name = "shadow"
    shadow.fillColor = UIColor(hex: 0x3E5A2E).withAlphaComponent(0.2)
    shadow.strokeColor = .clear
    shadow.position = CGPoint(x: anchor.x, y: 137)
    shadow.zPosition = 1
    world.addChild(shadow)
    flying = false
    burstUsed = false
    game?.currentFruit = kind
    game?.inFlight = false
    game?.canBurst = false
    world.childNode(withName: "queue")?.removeFromParent()
    let queue = SKNode()
    queue.name = "queue"
    world.addChild(queue)
    for index in (fruitIndex + 1)..<level.fruit.count {
      let waiting = SKSpriteNode(texture: OrchardArt.fruit(level.fruit[index]))
      waiting.size = CGSize(width: 39, height: 43)
      waiting.position = CGPoint(x: 162 - CGFloat(index - fruitIndex - 1) * 42, y: 156)
      waiting.zPosition = 4
      queue.addChild(waiting)
    }
    drawBands(to: anchor)
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard game?.screen == .playing, game?.paused == false, game?.result == nil,
      let point = touches.first?.location(in: self)
    else { return }
    if flying {
      activateBurst()
    } else if hypot(point.x - anchor.x, point.y - anchor.y) < 115 {
      dragging = true
      aim(at: point)
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard dragging, let point = touches.first?.location(in: self) else { return }
    aim(at: point)
  }

  private func aim(at point: CGPoint) {
    let pull = Rules.clampedPull(dx: point.x - anchor.x, dy: point.y - anchor.y)
    let position = CGPoint(x: anchor.x + pull.x, y: anchor.y + pull.y)
    projectile?.position = position
    drawBands(to: position)
    trajectory.removeAllChildren()
    let velocity = CGVector(dx: -pull.x * 9.2, dy: -pull.y * 9.2)
    for index in 1...24 {
      let time = CGFloat(index) * 0.075
      let point = CGPoint(
        x: position.x + velocity.dx * time,
        y: position.y + velocity.dy * time + 0.5 * gravity * time * time)
      guard point.y > 136, point.x < 1370 else { break }
      let dot = SKShapeNode(circleOfRadius: max(2.5, 5.5 - CGFloat(index) * 0.1))
      dot.fillColor = UIColor(hex: 0xFFFBEA).withAlphaComponent(0.95 - CGFloat(index) * 0.03)
      dot.strokeColor = UIColor(hex: 0xC94D3A).withAlphaComponent(0.55 - CGFloat(index) * 0.018)
      dot.lineWidth = 1.5
      dot.position = point
      trajectory.addChild(dot)
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard dragging, let projectile, let level else { return }
    dragging = false
    trajectory.removeAllChildren()
    let dx = anchor.x - projectile.position.x
    let dy = anchor.y - projectile.position.y
    drawBands(to: anchor)
    guard hypot(dx, dy) > 14 else {
      projectile.position = anchor
      return
    }
    let kind = level.fruit[fruitIndex]
    let body = SKPhysicsBody(circleOfRadius: 24)
    body.mass = kind == .pear ? 1.8 : 0.9
    body.friction = 0.7
    body.restitution = 0.2
    body.linearDamping = 0.05
    body.angularDamping = 0.3
    body.categoryBitMask = 8
    body.contactTestBitMask = UInt32.max
    body.usesPreciseCollisionDetection = true
    projectile.physicsBody = body
    body.velocity = CGVector(dx: dx * 9.2, dy: dy * 9.2)
    body.angularVelocity = -2
    flying = true
    elapsed = 0
    quietTime = 0
    lastTrail = 0
    game?.fired(kind)
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    dragging = false
    trajectory.removeAllChildren()
    if !flying { projectile?.position = anchor }
    drawBands(to: anchor)
  }

  func activateBurst() {
    guard flying, !burstUsed, let level, level.fruit[fruitIndex] == .plum,
      let projectile, game?.result == nil, game?.paused == false
    else { return }
    burstUsed = true
    game?.canBurst = false
    let center = projectile.position
    for node in blocks + beetles where node.parent != nil {
      let dx = node.position.x - center.x
      let dy = node.position.y - center.y
      let distance = hypot(dx, dy)
      guard distance < 190 else { continue }
      let strength = (1 - distance / 220) * 75
      node.physicsBody?.applyImpulse(
        CGVector(
          dx: dx / max(distance, 1) * strength,
          dy: max(0.25, dy / max(distance, 1)) * strength))
      pending.append((node, (1 - distance / 220) * 12))
    }
    let ring = SKShapeNode(circleOfRadius: 25)
    ring.strokeColor = UIColor(hex: 0xF6E6FA)
    ring.lineWidth = 8
    ring.fillColor = UIColor(hex: 0xBCA4D5).withAlphaComponent(0.25)
    ring.position = center
    effects.addChild(ring)
    ring.run(
      .sequence([
        .group([.scale(to: 7.5, duration: 0.3), .fadeOut(withDuration: 0.35)]),
        .removeFromParent(),
      ]))
    particles(at: center, color: UIColor(hex: 0xB29ECB), count: 24)
    game?.feedback(.burst)
  }

  func didBegin(_ contact: SKPhysicsContact) {
    guard flying, elapsed > 0.02 else { return }
    for (body, other) in [(contact.bodyA, contact.bodyB), (contact.bodyB, contact.bodyA)] {
      if body.categoryBitMask == 8 && other.categoryBitMask == 1 {
        body.linearDamping = 1.4
        body.angularDamping = 1.8
      }
    }
    if contact.collisionImpulse > 0.5 { quietTime = 0 }
    if contact.collisionImpulse > 4 {
      dust(at: contact.contactPoint, spread: 30, count: 4)
      shake(contact.collisionImpulse / 4)
    }
    for (body, other) in [(contact.bodyA, contact.bodyB), (contact.bodyB, contact.bodyA)] {
      guard let node = body.node as? FortBody else { continue }
      var damage = contact.collisionImpulse
      if other.categoryBitMask == 8 {
        damage = max(damage, hypot(other.velocity.dx, other.velocity.dy) / 35)
      }
      if damage > 0.6 { pending.append((node, damage)) }
    }
  }

  override func update(_ currentTime: TimeInterval) {
    if let view,
      view.bounds.size != framedSize
        || (view.window?.safeAreaInsets ?? view.safeAreaInsets) != framedInsets
    {
      framePlayfield()
    }
    let delta = previousTime == 0 ? 0 : min(1.0 / 20, currentTime - previousTime)
    previousTime = currentTime
    guard level != nil, game?.result == nil, game?.paused == false else { return }
    for (node, amount) in pending where node.parent != nil {
      node.health -= amount
      if node.health <= 0 {
        destroy(node)
      } else if amount > 1 {
        node.color = UIColor(hex: 0x634D39)
        node.colorBlendFactor = min(0.35, node.colorBlendFactor + 0.1)
      }
    }
    pending.removeAll()
    for node in beetles where node.parent != nil {
      if node.position.y < 100 || node.position.x > 1390 || node.position.x < -50 { destroy(node) }
    }
    if let projectile, let shadow = world.childNode(withName: "shadow") {
      let height = max(0, projectile.position.y - 137)
      shadow.position.x = projectile.position.x
      shadow.setScale(max(0.35, 1 - height / 600))
      shadow.alpha = max(0.05, 0.22 - height / 2200)
    }
    guard flying else { return }
    elapsed += delta
    quietTime += delta
    if elapsed - lastTrail > 0.09, elapsed < 3, let projectile {
      lastTrail = elapsed
      let dot = SKShapeNode(circleOfRadius: 2.5)
      dot.position = projectile.position
      dot.fillColor = UIColor(hex: 0xFFF5D8).withAlphaComponent(0.6)
      dot.strokeColor = .clear
      effects.addChild(dot)
      dot.run(.sequence([.fadeOut(withDuration: 1.4), .removeFromParent()]))
    }
    if beetles.allSatisfy({ $0.parent == nil }) {
      winDelay += delta
      if winDelay > 1.4 { game?.finish(won: true) }
      return
    }
    let velocity = projectile?.physicsBody?.velocity ?? .zero
    let outOfBounds = (projectile?.position.x ?? 0) > 1500 || (projectile?.position.y ?? 0) < -50
    if Rules.shouldEndShot(
      elapsed: elapsed, speed: hypot(velocity.dx, velocity.dy),
      quietTime: quietTime) || (outOfBounds && quietTime > 1)
    {
      advanceShot()
    }
  }

  private func advanceShot() {
    projectile?.run(.sequence([.fadeOut(withDuration: 0.35), .removeFromParent()]))
    projectile?.physicsBody?.categoryBitMask = 16
    fruitIndex += 1
    flying = false
    guard let level else { return }
    if fruitIndex < level.fruit.count {
      loadFruit()
    } else {
      game?.finish(won: false)
    }
  }

  private func destroy(_ node: FortBody) {
    guard node.parent != nil else { return }
    let position = node.position
    node.removeFromParent()
    game?.addPoints(node.points)
    if node.isTarget { game?.targets = beetles.filter { $0.parent != nil }.count }
    particles(
      at: position,
      color: UIColor(
        hex: node.isTarget
          ? 0x91B48C
          : node.material == .glass ? 0xC0E5D9 : node.material == .stone ? 0xB9B5A4 : 0xD5A56E),
      count: node.isTarget ? 14 : 9)
    dust(at: position, spread: node.size.width, count: node.isTarget ? 3 : 5)
    let tag = SKNode()
    tag.position = position
    tag.zPosition = 50
    let points = SKLabelNode(fontNamed: "Georgia-Bold")
    points.text = "+\(node.points)"
    points.fontSize = node.isTarget ? 26 : 21
    points.fontColor = UIColor(hex: node.isTarget ? 0xC94D3A : 0x2F4A36)
    points.verticalAlignmentMode = .center
    let plate = SKShapeNode(
      rectOf: CGSize(width: points.frame.width + 18, height: points.fontSize + 10),
      cornerRadius: (points.fontSize + 10) / 2)
    plate.fillColor = UIColor(hex: 0xFFF8E6).withAlphaComponent(0.92)
    plate.strokeColor = .clear
    tag.addChild(plate)
    tag.addChild(points)
    tag.setScale(0.6)
    effects.addChild(tag)
    tag.run(
      .sequence([
        .group([
          .sequence([.scale(to: 1.08, duration: 0.14), .scale(to: 1, duration: 0.1)]),
          .moveBy(x: 0, y: 52, duration: 0.9),
          .sequence([.wait(forDuration: 0.45), .fadeOut(withDuration: 0.5)]),
        ]), .removeFromParent(),
      ]))
    if node.isTarget { shake(5) }
    game?.feedback(.impact)
  }

  private func particles(at point: CGPoint, color: UIColor, count: Int) {
    for index in 0..<(reduceMotion ? 3 : count) {
      let chip = SKShapeNode(rectOf: CGSize(width: 5 + index % 4, height: 4), cornerRadius: 1)
      chip.fillColor = color
      chip.strokeColor = .clear
      chip.position = point
      effects.addChild(chip)
      let angle = CGFloat(index) * 2.399
      let distance = CGFloat(25 + index * 7 % 75)
      chip.run(
        .sequence([
          .group([
            .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.55),
            .rotate(byAngle: angle, duration: 0.55), .fadeOut(withDuration: 0.65),
          ]), .removeFromParent(),
        ]))
    }
  }

}
