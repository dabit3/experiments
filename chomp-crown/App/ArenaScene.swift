import SpriteKit
import UIKit

final class ArenaScene: SKScene {
  private let mazeLayer = SKNode()
  private let pelletLayer = SKNode()
  private let actors = SKNode()
  private let effects = SKNode()
  private var builtMaze = false
  private var playerNodes: [String: SKNode] = [:]
  private var ghostNodes: [String: SKNode] = [:]
  private var dots: [String: SKShapeNode] = [:]
  private var latest: ArenaState?
  private var lastEvent = 0
  private var lastTime = 0.0
  private let tile: CGFloat = 20
  private let origin = CGPoint(x: 20, y: 442)
  private let colors: [UIColor] = [
    UIColor(red: 1, green: 0.84, blue: 0.17, alpha: 1),
    UIColor(red: 1, green: 0.31, blue: 0.65, alpha: 1),
    UIColor(red: 0.28, green: 0.87, blue: 1, alpha: 1),
    UIColor(red: 0.56, green: 1, blue: 0.37, alpha: 1),
  ]
  override init(size: CGSize) {
    super.init(size: size)
    scaleMode = .aspectFit
    backgroundColor = UIColor(red: 0.017, green: 0.025, blue: 0.065, alpha: 1)
    addChild(mazeLayer)
    addChild(pelletLayer)
    addChild(actors)
    addChild(effects)
  }
  required init?(coder: NSCoder) { fatalError("Use init(size:)") }
  private func point(_ x: Double, _ y: Double) -> CGPoint {
    CGPoint(x: origin.x + (CGFloat(x) + 0.5) * tile, y: origin.y - (CGFloat(y) + 0.5) * tile)
  }
  func present(_ state: ArenaState) {
    latest = state
    if !builtMaze {
      buildMaze(state.maze)
      builtMaze = true
    }
    let wanted = Set(state.pellets)
    for key in Array(dots.keys) where !wanted.contains(key) {
      dots[key]?.removeFromParent()
      dots.removeValue(forKey: key)
    }
    for key in wanted where dots[key] == nil {
      let xy = key.split(separator: ",").compactMap { Double($0) }
      guard xy.count == 2 else { continue }
      let dot = SKShapeNode(circleOfRadius: 1.7)
      dot.fillColor = UIColor(red: 1, green: 0.82, blue: 0.46, alpha: 1)
      dot.strokeColor = .clear
      dot.glowWidth = 1.4
      dot.position = point(xy[0], xy[1])
      pelletLayer.addChild(dot)
      dots[key] = dot
    }
    for child in pelletLayer.children where child.name == "power" || child.name == "fruit" {
      child.removeFromParent()
    }
    for power in state.powers where power.active {
      let orb = SKShapeNode(circleOfRadius: 5.8)
      orb.name = "power"
      orb.fillColor = colors[0]
      orb.strokeColor = .white
      orb.lineWidth = 1.2
      orb.glowWidth = 6
      orb.position = point(Double(power.x), Double(power.y))
      let ring = SKShapeNode(circleOfRadius: 8.5)
      ring.strokeColor = colors[0].withAlphaComponent(0.35)
      ring.lineWidth = 0.8
      orb.addChild(ring)
      pelletLayer.addChild(orb)
    }
    if state.fruit {
      let fruit = SKLabelNode(text: "◆")
      fruit.name = "fruit"
      fruit.fontColor = .systemPink
      fruit.fontSize = 23
      fruit.verticalAlignmentMode = .center
      fruit.position = point(9, 7)
      pelletLayer.addChild(fruit)
    }
    for player in state.players where playerNodes[player.id] == nil {
      let node = SKNode()
      node.position = point(player.x, player.y)
      node.zPosition = 10
      actors.addChild(node)
      playerNodes[player.id] = node
    }
    for ghost in state.ghosts where ghostNodes[ghost.id] == nil {
      let node = SKNode()
      node.position = point(ghost.x, ghost.y)
      actors.addChild(node)
      ghostNodes[ghost.id] = node
    }
    for id in Array(playerNodes.keys) where !state.players.contains(where: { $0.id == id }) {
      playerNodes[id]?.removeFromParent()
      playerNodes.removeValue(forKey: id)
    }
    for event in state.events where event.id > lastEvent {
      lastEvent = event.id
      if ["power", "eliminated", "ghostEaten", "bump"].contains(event.kind),
        let x = event.x, let y = event.y
      {
        let color =
          state.players.first(where: { $0.id == event.playerId }).map { colors[$0.color % 4] }
          ?? .cyan
        burst(at: point(x, y), color: color, large: event.kind == "eliminated")
      }
      if event.kind == "round" {
        for player in state.players { playerNodes[player.id]?.position = point(player.x, player.y) }
      }
    }
  }
  private func buildMaze(_ rows: [String]) {
    let grid = rows.map(Array.init)
    let fill = CGMutablePath()
    let edge = CGMutablePath()
    for y in grid.indices {
      for x in grid[y].indices where grid[y][x] == "#" {
        let left = origin.x + CGFloat(x) * tile
        let top = origin.y - CGFloat(y) * tile
        fill.addRect(CGRect(x: left, y: top - tile, width: tile, height: tile))
        let segments: [(Int, Int, CGPoint, CGPoint)] = [
          (0, -1, CGPoint(x: left, y: top), CGPoint(x: left + tile, y: top)),
          (1, 0, CGPoint(x: left + tile, y: top), CGPoint(x: left + tile, y: top - tile)),
          (0, 1, CGPoint(x: left, y: top - tile), CGPoint(x: left + tile, y: top - tile)),
          (-1, 0, CGPoint(x: left, y: top), CGPoint(x: left, y: top - tile)),
        ]
        for (dx, dy, a, b) in segments {
          let nx = x + dx
          let ny = y + dy
          if ny < 0 || ny >= grid.count || nx < 0 || nx >= grid[y].count || grid[ny][nx] != "#" {
            edge.move(to: a)
            edge.addLine(to: b)
          }
        }
      }
    }
    let floor = SKShapeNode(path: fill)
    floor.fillColor = UIColor(red: 0.024, green: 0.045, blue: 0.16, alpha: 1)
    floor.strokeColor = .clear
    mazeLayer.addChild(floor)
    let glow = SKShapeNode(path: edge)
    glow.strokeColor = UIColor(red: 0.02, green: 0.16, blue: 1, alpha: 1)
    glow.lineWidth = 3.6
    glow.glowWidth = 5
    glow.lineCap = .round
    mazeLayer.addChild(glow)
    let line = SKShapeNode(path: edge)
    line.strokeColor = UIColor(red: 0.22, green: 0.62, blue: 1, alpha: 1)
    line.lineWidth = 1.15
    line.lineCap = .round
    mazeLayer.addChild(line)
    let gate = SKShapeNode(rectOf: CGSize(width: 17, height: 2), cornerRadius: 1)
    gate.fillColor = .systemPink
    gate.strokeColor = .clear
    gate.glowWidth = 4
    gate.position = point(9, 8.4)
    mazeLayer.addChild(gate)
    let label = SKLabelNode(fontNamed: "Menlo-Bold")
    label.text = "AI"
    label.fontSize = 7
    label.fontColor = UIColor.white.withAlphaComponent(0.3)
    label.position = point(9, 10.5)
    mazeLayer.addChild(label)
  }
  override func update(_ currentTime: TimeInterval) {
    guard let state = latest else { return }
    let dt = min(0.05, lastTime == 0 ? 0.016 : currentTime - lastTime)
    lastTime = currentTime
    let chasing = state.players.contains { $0.alive && $0.power > 0 }
    for player in state.players {
      guard let node = playerNodes[player.id] else { continue }
      node.isHidden = !player.alive
      guard player.alive else { continue }
      interpolate(node, to: point(player.x, player.y), amount: CGFloat(min(1, dt * 18)))
      node.removeAllChildren()
      let powered = player.power > 0
      let vulnerable = chasing && !powered
      let color = colors[player.color % 4]
      let radius: CGFloat = powered ? 16.5 : 8.6
      if powered {
        let ring = SKShapeNode(circleOfRadius: radius + 3 + CGFloat(sin(currentTime * 6)) * 1.5)
        ring.strokeColor = color.withAlphaComponent(0.65)
        ring.lineWidth = 1.3
        ring.glowWidth = 6
        node.addChild(ring)
      }
      if player.shield > 0 {
        let ring = SKShapeNode(circleOfRadius: 12)
        ring.strokeColor = color.withAlphaComponent(0.4)
        ring.lineWidth = 0.8
        node.addChild(ring)
      }
      let angle = CGFloat(0.17 + (sin(currentTime * 18) + 1) * 0.25)
      let path = CGMutablePath()
      path.move(to: .zero)
      path.addArc(
        center: .zero, radius: radius, startAngle: angle, endAngle: .pi * 2 - angle,
        clockwise: false)
      path.closeSubpath()
      let body = SKShapeNode(path: path)
      body.fillColor = vulnerable ? UIColor(red: 0.08, green: 0.08, blue: 0.68, alpha: 1) : color
      body.strokeColor = vulnerable ? color : color.withAlphaComponent(0.85)
      body.lineWidth = vulnerable ? 1.7 : 0.8
      body.glowWidth = powered ? 5 : 2
      switch player.dir {
      case "up": body.zRotation = .pi / 2
      case "down": body.zRotation = -.pi / 2
      case "left": body.zRotation = .pi
      default: body.zRotation = 0
      }
      node.addChild(body)
      let shine = SKShapeNode(ellipseOf: CGSize(width: radius * 0.48, height: radius * 0.24))
      shine.fillColor = UIColor.white.withAlphaComponent(vulnerable ? 0.18 : 0.45)
      shine.strokeColor = .clear
      shine.position = CGPoint(x: -radius * 0.25, y: radius * 0.55)
      body.addChild(shine)
      let eye = SKShapeNode(circleOfRadius: max(1.25, radius * 0.115))
      eye.fillColor = vulnerable ? .white : UIColor(red: 0.11, green: 0.05, blue: 0.04, alpha: 1)
      eye.strokeColor = .clear
      eye.position = CGPoint(x: radius * 0.1, y: radius * 0.5)
      body.addChild(eye)
      if player.id == state.you {
        let arrow = SKLabelNode(fontNamed: "Menlo-Bold")
        arrow.text = "▼"
        arrow.fontSize = 7
        arrow.fontColor = color
        arrow.position = CGPoint(x: 0, y: radius + 6)
        node.addChild(arrow)
      }
    }
    for ghost in state.ghosts {
      guard let node = ghostNodes[ghost.id] else { continue }
      interpolate(node, to: point(ghost.x, ghost.y), amount: CGFloat(min(1, dt * 18)))
      node.alpha = ghost.respawn > 0 ? 0.45 : 1
      node.removeAllChildren()
      let path = CGMutablePath()
      path.move(to: CGPoint(x: -8, y: -6))
      path.addLine(to: CGPoint(x: -8, y: 1))
      path.addArc(
        center: CGPoint(x: 0, y: 1), radius: 8, startAngle: .pi, endAngle: 0, clockwise: true)
      path.addLine(to: CGPoint(x: 8, y: -7))
      for index in stride(from: 3, through: 0, by: -1) {
        path.addLine(
          to: CGPoint(x: CGFloat(index) * 4 - 6, y: -4 + CGFloat(sin(currentTime * 9)) * 1.1))
        path.addLine(to: CGPoint(x: CGFloat(index) * 4 - 8, y: -7))
      }
      path.closeSubpath()
      let body = SKShapeNode(path: path)
      body.fillColor =
        chasing
        ? UIColor(red: 0.19, green: 0.15, blue: 0.9, alpha: 1)
        : [UIColor.systemRed, UIColor.systemTeal, UIColor.systemPurple][ghost.color % 3]
      body.strokeColor = body.fillColor.withAlphaComponent(0.5)
      body.glowWidth = 3
      node.addChild(body)
      for x: CGFloat in [-3, 3] {
        let eye = SKShapeNode(ellipseOf: CGSize(width: 4.5, height: 5.5))
        eye.fillColor = .white
        eye.strokeColor = .clear
        eye.position = CGPoint(x: x, y: 2)
        let pupil = SKShapeNode(circleOfRadius: 1.25)
        pupil.fillColor = .blue
        pupil.strokeColor = .clear
        pupil.position = CGPoint(x: ghost.dir == "left" ? -0.7 : 0.7, y: ghost.dir == "up" ? 1 : 0)
        eye.addChild(pupil)
        body.addChild(eye)
      }
    }
    for node in pelletLayer.children where node.name == "power" {
      node.setScale(1 + CGFloat(sin(currentTime * 4)) * 0.13)
    }
  }
  private func interpolate(_ node: SKNode, to target: CGPoint, amount: CGFloat) {
    if hypot(node.position.x - target.x, node.position.y - target.y) > 65 {
      node.position = target
    } else {
      node.position.x += (target.x - node.position.x) * amount
      node.position.y += (target.y - node.position.y) * amount
    }
  }
  private func burst(at position: CGPoint, color: UIColor, large: Bool) {
    for index in 0..<(large ? 28 : 12) {
      let dot = SKShapeNode(circleOfRadius: large ? 2 : 1.5)
      dot.fillColor = color
      dot.strokeColor = .clear
      dot.glowWidth = 2
      dot.position = position
      effects.addChild(dot)
      let angle = CGFloat(index) * 2.399
      let distance: CGFloat = large ? 45 : 24
      dot.run(
        .sequence([
          .group([
            .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.65),
            .fadeOut(withDuration: 0.65), .scale(to: 0.1, duration: 0.65),
          ]),
          .removeFromParent(),
        ]))
    }
  }
}
