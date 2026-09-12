import SpriteKit
import UIKit

enum Ink {
  static let background = UIColor(red: 0.075, green: 0.035, blue: 0.11, alpha: 1)
  static let panel = UIColor(red: 0.14, green: 0.065, blue: 0.18, alpha: 1)
  static let brass = UIColor(red: 0.78, green: 0.64, blue: 0.40, alpha: 1)
  static let coral = UIColor(red: 1, green: 0.36, blue: 0.39, alpha: 1)
  static let cyan = UIColor(red: 0.39, green: 0.94, blue: 0.94, alpha: 1)
  static let cream = UIColor(red: 0.98, green: 0.94, blue: 0.83, alpha: 1)
}

@MainActor
final class VoltageScene: SKScene {
  weak var session: GameSession?
  private let ballNode = SKShapeNode(circleOfRadius: 8)
  private var leftNode = SKShapeNode()
  private var rightNode = SKShapeNode()
  private var districtRings: [SKShapeNode] = []
  private var windows: [SKShapeNode] = []
  private var trail: [SKShapeNode] = []
  private var lastTime = 0.0
  private var trailClock = 0
  private var lastCircuit = 0
  private var progressLabel = SKLabelNode()

  init(session: GameSession) {
    self.session = session
    super.init(size: CGSize(width: 390, height: 620))
    scaleMode = .aspectFit
    backgroundColor = Ink.background
    buildTable()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func line(_ points: [CGPoint], color: UIColor, width: CGFloat, glow: CGFloat = 0) {
    guard let first = points.first else { return }
    let path = CGMutablePath()
    path.move(to: first)
    for point in points.dropFirst() { path.addLine(to: point) }
    let shape = SKShapeNode(path: path)
    shape.strokeColor = color
    shape.lineWidth = width
    shape.glowWidth = glow
    shape.lineCap = .round
    addChild(shape)
  }

  @discardableResult
  private func label(
    _ text: String, x: Double, y: Double, size: CGFloat, color: UIColor,
    font: String = "AvenirNext-DemiBold"
  ) -> SKLabelNode {
    let node = SKLabelNode(fontNamed: font)
    node.text = text
    node.fontSize = size
    node.fontColor = color
    node.position = CGPoint(x: x, y: y)
    addChild(node)
    return node
  }

  private func buildTable() {
    let plate = SKShapeNode(rect: CGRect(x: 14, y: 35, width: 362, height: 568), cornerRadius: 90)
    plate.fillColor = Ink.panel
    plate.strokeColor = Ink.brass.withAlphaComponent(0.45)
    plate.lineWidth = 1
    addChild(plate)
    for x in stride(from: 36, through: 354, by: 18) {
      line(
        [CGPoint(x: x, y: 150), CGPoint(x: x, y: 536)],
        color: Ink.brass.withAlphaComponent(0.055), width: 0.5)
    }
    for y in stride(from: 150, through: 550, by: 18) {
      line(
        [CGPoint(x: 36, y: y), CGPoint(x: 354, y: y)],
        color: Ink.brass.withAlphaComponent(0.055), width: 0.5)
    }
    for radius in [75.0, 84.0, 92.0] {
      let circle = SKShapeNode(circleOfRadius: radius)
      circle.position = CGPoint(x: 195, y: 326)
      circle.strokeColor = Ink.brass.withAlphaComponent(radius == 84 ? 0.28 : 0.1)
      circle.lineWidth = 1
      addChild(circle)
    }
    for angle in stride(from: 0.0, to: 360.0, by: 15) {
      let a = angle * .pi / 180
      line(
        [
          CGPoint(x: 195 + cos(a) * 87, y: 326 + sin(a) * 87),
          CGPoint(x: 195 + cos(a) * 91, y: 326 + sin(a) * 91),
        ], color: Ink.brass.withAlphaComponent(0.35), width: 1)
    }
    buildCity()
    let route = [
      CGPoint(x: 98, y: 410), CGPoint(x: 98, y: 465),
      CGPoint(x: 195, y: 540), CGPoint(x: 292, y: 465), CGPoint(x: 292, y: 410),
    ]
    line(route, color: Ink.brass.withAlphaComponent(0.18), width: 8)
    line(route, color: Ink.cyan.withAlphaComponent(0.6), width: 1, glow: 1)
    for (index, center) in PinballEngine.districts.enumerated() {
      let shadow = SKShapeNode(circleOfRadius: 35)
      shadow.position = CGPoint(x: center.x, y: center.y - 4)
      shadow.fillColor = .black.withAlphaComponent(0.5)
      shadow.strokeColor = .clear
      addChild(shadow)
      let ring = SKShapeNode(circleOfRadius: 30)
      ring.position = CGPoint(x: center.x, y: center.y)
      ring.strokeColor = Ink.coral
      ring.lineWidth = 3
      ring.glowWidth = 2
      ring.fillColor = Ink.background
      addChild(ring)
      districtRings.append(ring)
      let inner = SKShapeNode(circleOfRadius: 24)
      inner.position = ring.position
      inner.strokeColor = Ink.brass.withAlphaComponent(0.65)
      inner.lineWidth = 0.6
      addChild(inner)
      label("0\(index + 1)", x: center.x, y: center.y - 7, size: 23, color: Ink.cream)
      label(
        ["ARCADE", "SPIRE", "RIVIERA"][index],
        x: center.x, y: center.y - 49, size: 11, color: Ink.cream)
    }
    label("V / V", x: 195, y: 335, size: 36, color: Ink.brass, font: "Didot")
    label("POWER THE NIGHT", x: 195, y: 307, size: 10, color: Ink.cream)
    progressLabel = label("0 / 3 DISTRICTS", x: 195, y: 281, size: 11, color: Ink.cyan)
    for rail in PinballEngine.rails {
      let points = [CGPoint(x: rail.a.x, y: rail.a.y), CGPoint(x: rail.b.x, y: rail.b.y)]
      line(points, color: .black.withAlphaComponent(0.5), width: 9)
      line(points, color: Ink.brass, width: 3, glow: 0.5)
      line(points, color: Ink.cream.withAlphaComponent(0.6), width: 0.8)
    }
    for left in [true, false] {
      let x = left ? 89.0 : 301.0
      line(
        [
          CGPoint(x: x, y: 225), CGPoint(x: left ? 98 : 292, y: 183),
          CGPoint(x: left ? 118 : 272, y: 168),
        ], color: Ink.coral, width: 2, glow: 2)
      label(left ? "L" : "R", x: left ? 65 : 325, y: 116, size: 9, color: Ink.brass)
    }
    label("VELVET VOLTAGE", x: 195, y: 209, size: 12, color: Ink.cream)
    label("E L E C T R I C   S O C I A L   C L U B", x: 195, y: 190, size: 6.7, color: Ink.brass)
    label("D R A I N", x: 195, y: 27, size: 8, color: Ink.brass.withAlphaComponent(0.65))
    leftNode = makeFlipper()
    rightNode = makeFlipper()
    for x in [114.0, 276.0] {
      let pivot = SKShapeNode(circleOfRadius: 4)
      pivot.position = CGPoint(x: x, y: 101)
      pivot.fillColor = Ink.cream
      pivot.strokeColor = .clear
      pivot.zPosition = 8
      addChild(pivot)
    }
    for index in 0..<12 {
      let dot = SKShapeNode(circleOfRadius: CGFloat(2 + Double(index) * 0.35))
      dot.fillColor = Ink.cyan
      dot.strokeColor = .clear
      dot.alpha = CGFloat(index) / 30
      dot.isHidden = true
      dot.zPosition = 9
      addChild(dot)
      trail.append(dot)
    }
    ballNode.fillColor = Ink.cream
    ballNode.strokeColor = Ink.cyan
    ballNode.lineWidth = 1.5
    ballNode.glowWidth = 4
    ballNode.zPosition = 10
    let shine = SKShapeNode(circleOfRadius: 2.2)
    shine.position = CGPoint(x: -2, y: 3)
    shine.fillColor = .white
    shine.strokeColor = .clear
    ballNode.addChild(shine)
    addChild(ballNode)
  }

  private func buildCity() {
    for index in 0..<19 {
      let x = 54.0 + Double(index) * 15
      let height = Double(
        [28, 43, 34, 65, 48, 76, 53, 66, 88, 108, 71, 82, 56, 70, 45, 62, 37, 46, 25][index])
      let building = SKShapeNode(rect: CGRect(x: x, y: 490, width: 12, height: height))
      building.fillColor = Ink.background
      building.strokeColor = Ink.brass.withAlphaComponent(0.65)
      building.lineWidth = 0.75
      addChild(building)
      for row in 0..<Int(height / 8 - 1) {
        for column in 0..<2 {
          let window = SKShapeNode(
            rect: CGRect(
              x: x + 3 + Double(column) * 4, y: 497 + Double(row) * 8, width: 1.7, height: 3))
          window.fillColor = (row + column + index) % 3 == 0 ? Ink.cyan : Ink.brass
          window.strokeColor = .clear
          window.alpha = 0.6
          addChild(window)
          windows.append(window)
        }
      }
    }
  }

  private func makeFlipper() -> SKShapeNode {
    let node = SKShapeNode()
    node.strokeColor = Ink.coral
    node.lineWidth = 15
    node.lineCap = .round
    node.glowWidth = 2
    node.zPosition = 7
    addChild(node)
    return node
  }

  private func drawFlipper(_ node: SKShapeNode, rail: Rail) {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: rail.a.x, y: rail.a.y))
    path.addLine(to: CGPoint(x: rail.b.x, y: rail.b.y))
    node.path = path
  }

  override func update(_ currentTime: TimeInterval) {
    guard let session else { return }
    let dt = lastTime == 0 ? 1 / 60 : min(currentTime - lastTime, 1 / 30)
    lastTime = currentTime
    if session.screen == .playing, !session.paused {
      let events = session.engine.advance(dt)
      for event in events {
        if case .bumper(let index, let completed) = event {
          burst(at: PinballEngine.districts[index], celebration: completed)
        }
      }
      session.consume(events)
    }
    let engine = session.engine
    progressLabel.text = "\(engine.score.nextDistrict) / 3 DISTRICTS"
    drawFlipper(leftNode, rail: engine.flipper(left: true))
    drawFlipper(rightNode, rail: engine.flipper(left: false))
    ballNode.position = CGPoint(x: engine.ball.x, y: engine.ball.y)
    ballNode.isHidden = session.screen == .home || session.screen == .tutorial
    if session.screen == .playing, !session.paused {
      trailClock += 1
      if trailClock % 2 == 0 {
        for index in 0..<trail.count - 1 { trail[index].position = trail[index + 1].position }
        trail[trail.count - 1].position = ballNode.position
      }
    }
    for dot in trail {
      dot.isHidden = !engine.inFlight || session.reducedMotion || session.screen != .playing
    }
    for (index, ring) in districtRings.enumerated() {
      let active = index == engine.score.nextDistrict
      ring.strokeColor =
        active
        ? Ink.cyan
        : (index < engine.score.nextDistrict ? Ink.brass : Ink.coral.withAlphaComponent(0.55))
      ring.glowWidth = active ? 3 : 0.5
    }
    if lastCircuit != engine.score.circuits {
      lastCircuit = engine.score.circuits
      for window in windows { window.alpha = lastCircuit > 0 ? 1 : 0.6 }
    }
  }

  private func burst(at position: Vector, celebration: Bool) {
    guard session?.reducedMotion != true else { return }
    let count = celebration ? 38 : 9
    for index in 0..<count {
      let angle = Double(index) / Double(count) * .pi * 2
      let spark = SKShapeNode(circleOfRadius: celebration ? 2.5 : 1.6)
      spark.position = CGPoint(x: position.x, y: position.y)
      spark.fillColor = index % 2 == 0 ? Ink.cyan : Ink.brass
      spark.strokeColor = .clear
      spark.glowWidth = 2
      spark.zPosition = 11
      addChild(spark)
      let distance = celebration ? 140.0 : 60.0
      spark.run(
        .sequence([
          .group([
            .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.5),
            .fadeOut(withDuration: 0.5),
          ]), .removeFromParent(),
        ]))
    }
  }
}
