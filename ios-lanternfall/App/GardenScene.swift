import SpriteKit
import UIKit

enum GardenArt {
  static let gold = UIColor(red: 1, green: 0.79, blue: 0.39, alpha: 1)
  static let mint = UIColor(red: 0.38, green: 0.91, blue: 0.78, alpha: 1)
  static func texture(_ kind: String) -> SKTexture {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128)).image { context in
      let cg = context.cgContext
      func ellipse(_ rect: CGRect, _ color: UIColor) {
        color.setFill()
        UIBezierPath(ovalIn: rect).fill()
      }
      func path(_ points: [CGPoint], _ color: UIColor) {
        let shape = UIBezierPath()
        shape.move(to: points[0])
        for point in points.dropFirst() { shape.addLine(to: point) }
        shape.close()
        color.setFill()
        shape.fill()
      }
      if kind == "glow" {
        let colors = [gold.withAlphaComponent(0.25).cgColor, gold.withAlphaComponent(0).cgColor]
        if let gradient = CGGradient(
          colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])
        {
          cg.drawRadialGradient(
            gradient, startCenter: CGPoint(x: 64, y: 64), startRadius: 0,
            endCenter: CGPoint(x: 64, y: 64), endRadius: 64, options: [])
        }
      } else if kind == "keeper" {
        ellipse(CGRect(x: 28, y: 100, width: 73, height: 18), UIColor.black.withAlphaComponent(0.3))
        path(
          [
            CGPoint(x: 61, y: 39), CGPoint(x: 31, y: 104), CGPoint(x: 66, y: 97),
            CGPoint(x: 88, y: 108), CGPoint(x: 91, y: 69),
          ], UIColor(red: 0.12, green: 0.38, blue: 0.36, alpha: 1))
        path(
          [
            CGPoint(x: 67, y: 45), CGPoint(x: 43, y: 100), CGPoint(x: 64, y: 91),
            CGPoint(x: 77, y: 98),
          ], mint.withAlphaComponent(0.25))
        ellipse(
          CGRect(x: 42, y: 20, width: 43, height: 44),
          UIColor(red: 0.08, green: 0.2, blue: 0.22, alpha: 1))
        ellipse(
          CGRect(x: 51, y: 32, width: 27, height: 28),
          UIColor(red: 0.93, green: 0.78, blue: 0.55, alpha: 1))
        path(
          [CGPoint(x: 38, y: 39), CGPoint(x: 63, y: 11), CGPoint(x: 89, y: 40)],
          UIColor(red: 0.22, green: 0.49, blue: 0.43, alpha: 1))
        ellipse(
          CGRect(x: 65, y: 41, width: 4, height: 5),
          UIColor(red: 0.06, green: 0.12, blue: 0.14, alpha: 1))
        cg.setShadow(offset: .zero, blur: 15, color: gold.cgColor)
        gold.setFill()
        UIBezierPath(roundedRect: CGRect(x: 88, y: 55, width: 24, height: 32), cornerRadius: 6)
          .fill()
        cg.setShadow(offset: .zero, blur: 0)
        UIColor.white.withAlphaComponent(0.8).setFill()
        UIBezierPath(roundedRect: CGRect(x: 96, y: 60, width: 8, height: 20), cornerRadius: 3)
          .fill()
        gold.setStroke()
        let handle = UIBezierPath(ovalIn: CGRect(x: 93, y: 46, width: 14, height: 16))
        handle.lineWidth = 3
        handle.stroke()
      } else if kind == "shade" {
        cg.setShadow(
          offset: .zero, blur: 12, color: UIColor.systemTeal.withAlphaComponent(0.4).cgColor)
        path(
          [
            CGPoint(x: 24, y: 103), CGPoint(x: 32, y: 54), CGPoint(x: 48, y: 23),
            CGPoint(x: 76, y: 18), CGPoint(x: 96, y: 50), CGPoint(x: 109, y: 110),
            CGPoint(x: 82, y: 97), CGPoint(x: 67, y: 114), CGPoint(x: 51, y: 98),
          ], UIColor(red: 0.21, green: 0.39, blue: 0.44, alpha: 1))
        ellipse(
          CGRect(x: 41, y: 44, width: 46, height: 36),
          UIColor(red: 0.04, green: 0.1, blue: 0.16, alpha: 1))
        ellipse(CGRect(x: 49, y: 55, width: 8, height: 10), mint)
        ellipse(CGRect(x: 72, y: 55, width: 8, height: 10), mint)
      } else if kind == "moth" {
        for side in [-1.0, 1.0] {
          path(
            [
              CGPoint(x: 64, y: 53), CGPoint(x: 64 + side * 51, y: 21),
              CGPoint(x: 64 + side * 39, y: 77), CGPoint(x: 64 + side * 20, y: 102),
              CGPoint(x: 64, y: 75),
            ], UIColor(red: 0.59, green: 0.35, blue: 0.59, alpha: 1))
          ellipse(
            CGRect(x: 60 + side * 30, y: 48, width: 12, height: 15),
            UIColor(red: 0.95, green: 0.62, blue: 0.61, alpha: 1))
        }
        ellipse(
          CGRect(x: 56, y: 38, width: 16, height: 55),
          UIColor(red: 0.21, green: 0.15, blue: 0.32, alpha: 1))
        ellipse(CGRect(x: 58, y: 43, width: 5, height: 6), gold)
        ellipse(CGRect(x: 66, y: 43, width: 5, height: 6), gold)
      } else if kind == "thorn" || kind == "boss" {
        let boss = kind == "boss"
        path(
          [
            CGPoint(x: 27, y: 113), CGPoint(x: 31, y: 52), CGPoint(x: 9, y: 20),
            CGPoint(x: 39, y: 37), CGPoint(x: 48, y: 7), CGPoint(x: 62, y: 31),
            CGPoint(x: 88, y: 8), CGPoint(x: 84, y: 39), CGPoint(x: 121, y: 28),
            CGPoint(x: 98, y: 64), CGPoint(x: 107, y: 111), CGPoint(x: 70, y: 100),
          ], UIColor(red: boss ? 0.51 : 0.33, green: 0.35, blue: 0.38, alpha: 1))
        path(
          [
            CGPoint(x: 43, y: 46), CGPoint(x: 80, y: 42), CGPoint(x: 91, y: 87),
            CGPoint(x: 66, y: 100), CGPoint(x: 41, y: 81),
          ], UIColor(red: 0.12, green: 0.16, blue: 0.22, alpha: 1))
        ellipse(CGRect(x: 48, y: 61, width: 11, height: 7), boss ? gold : mint)
        ellipse(CGRect(x: 72, y: 61, width: 11, height: 7), boss ? gold : mint)
      } else if kind == "gem" {
        path(
          [
            CGPoint(x: 64, y: 16), CGPoint(x: 101, y: 61), CGPoint(x: 64, y: 113),
            CGPoint(x: 27, y: 61),
          ], mint)
        path(
          [CGPoint(x: 64, y: 16), CGPoint(x: 64, y: 113), CGPoint(x: 27, y: 61)],
          UIColor(red: 0.17, green: 0.57, blue: 0.59, alpha: 1))
        path(
          [
            CGPoint(x: 64, y: 16), CGPoint(x: 79, y: 61), CGPoint(x: 64, y: 81),
            CGPoint(x: 49, y: 61),
          ], UIColor.white.withAlphaComponent(0.7))
      }
    }
    return SKTexture(image: image)
  }
}

final class GardenScene: SKScene {
  var onFrame: ((Double) -> Void)?
  var model = GameModel(seed: 1)
  private let world = SKNode()
  private let cameraNode = SKCameraNode()
  private let keeper = SKSpriteNode(texture: GardenArt.texture("keeper"))
  private var entities: [Int: SKSpriteNode] = [:]
  private var terrain: [String: SKNode] = [:]
  private var textures: [String: SKTexture] = [:]
  private var previousTime: Double = 0
  private let nova = SKShapeNode(circleOfRadius: 180)
  private var orbitNodes: [SKShapeNode] = []
  private var previousCell = ""

  override func didMove(to view: SKView) {
    backgroundColor = UIColor(red: 0.025, green: 0.072, blue: 0.10, alpha: 1)
    guard world.parent == nil else { return }
    addChild(world)
    addChild(cameraNode)
    camera = cameraNode
    for kind in ["shade", "moth", "thorn", "boss", "gem", "glow"] {
      textures[kind] = GardenArt.texture(kind)
    }
    let glow = SKSpriteNode(texture: textures["glow"])
    glow.size = CGSize(width: 330, height: 330)
    glow.zPosition = -1
    keeper.addChild(glow)
    keeper.size = CGSize(width: 49, height: 49)
    keeper.zPosition = 20
    world.addChild(keeper)
    nova.strokeColor = GardenArt.gold
    nova.fillColor = GardenArt.gold.withAlphaComponent(0.035)
    nova.lineWidth = 2
    nova.zPosition = 16
    world.addChild(nova)
  }
  override func update(_ currentTime: TimeInterval) {
    let dt = previousTime == 0 ? 1 / 60.0 : min(0.05, currentTime - previousTime)
    previousTime = currentTime
    onFrame?(dt)
    render()
  }
  private func render() {
    let player = CGPoint(x: model.player.x, y: model.player.y)
    keeper.position = player
    keeper.alpha = model.hurtFlash > 0 ? 0.55 + 0.45 * abs(sin(model.elapsed * 35)) : 1
    keeper.zRotation = model.movement.length > 0.1 ? sin(model.elapsed * 12) * 0.045 : 0
    cameraNode.position = CGPoint(x: player.x, y: player.y + 65)
    refreshTerrain()
    var live = Set<Int>()
    for enemy in model.enemies {
      let name = ["shade", "moth", "thorn", "boss"][enemy.kind.rawValue]
      let node = entity(enemy.id, texture: textures[name], live: &live)
      let dimension: Double =
        enemy.kind == .boss ? 112 : enemy.kind == .thorn ? 51 : enemy.kind == .moth ? 42 : 41
      node.size = CGSize(width: dimension, height: dimension)
      node.position = CGPoint(x: enemy.position.x, y: enemy.position.y)
      node.zPosition = 12
      node.color = .white
      node.colorBlendFactor = enemy.flash > 0 ? 0.75 : 0
      node.zRotation = sin(model.elapsed * (enemy.kind == .moth ? 12 : 3) + Double(enemy.id)) * 0.08
    }
    for bolt in model.bolts {
      let node = entity(bolt.id, texture: nil, live: &live)
      node.color = GardenArt.gold
      node.size = CGSize(width: 15, height: 5)
      node.position = CGPoint(x: bolt.position.x, y: bolt.position.y)
      node.zRotation = atan2(bolt.velocity.y, bolt.velocity.x)
      node.zPosition = 18
    }
    for pickup in model.pickups {
      let node = entity(pickup.id, texture: textures["gem"], live: &live)
      node.size = CGSize(width: pickup.healing ? 22 : 14, height: pickup.healing ? 22 : 14)
      node.color = .systemPink
      node.colorBlendFactor = pickup.healing ? 0.8 : 0
      node.position = CGPoint(x: pickup.position.x, y: pickup.position.y)
      node.zPosition = 5
    }
    for spark in model.sparks {
      let node = entity(spark.id, texture: textures["glow"], live: &live)
      let dimension = 25 + (0.5 - spark.life) * 100
      node.size = CGSize(width: dimension, height: dimension)
      node.alpha = spark.life * 1.6
      node.position = CGPoint(x: spark.position.x, y: spark.position.y)
      node.zPosition = 15
    }
    for id in Array(entities.keys) where !live.contains(id) {
      entities.removeValue(forKey: id)?.removeFromParent()
    }
    nova.position = player
    nova.isHidden = model.novaFlash <= 0
    nova.setScale((1 - model.novaFlash / 0.6) * (1 + Double(model.rank(.nova)) * 15 / 180))
    nova.alpha = model.novaFlash / 0.6
    while orbitNodes.count < model.orbitCount {
      let blade = SKShapeNode(ellipseOf: CGSize(width: 13, height: 28))
      blade.strokeColor = .white
      blade.fillColor = GardenArt.mint
      blade.glowWidth = 3
      blade.zPosition = 19
      world.addChild(blade)
      orbitNodes.append(blade)
    }
    for (index, blade) in orbitNodes.enumerated() {
      blade.isHidden = index >= model.orbitCount
      let angle = model.elapsed * 2.4 + Double(index) * 2 * .pi / Double(max(1, model.orbitCount))
      blade.position = CGPoint(
        x: player.x + cos(angle) * model.orbitRadius, y: player.y + sin(angle) * model.orbitRadius)
      blade.zRotation = angle
    }
  }
  private func entity(_ id: Int, texture: SKTexture?, live: inout Set<Int>) -> SKSpriteNode {
    live.insert(id)
    if let node = entities[id] { return node }
    let node = SKSpriteNode(texture: texture)
    world.addChild(node)
    entities[id] = node
    return node
  }
  private func refreshTerrain() {
    let column = Int(floor(model.player.x / 150))
    let row = Int(floor(model.player.y / 150))
    let cell = "\(column),\(row)"
    guard previousCell != cell else { return }
    previousCell = cell
    var live = Set<String>()
    for x in (column - 4)...(column + 4) {
      for y in (row - 5)...(row + 5) {
        let key = "\(x),\(y)"
        live.insert(key)
        guard terrain[key] == nil else { continue }
        let tile = makeTile(x: x, y: y)
        tile.position = CGPoint(x: x * 150, y: y * 150)
        tile.zPosition = -10
        world.addChild(tile)
        terrain[key] = tile
      }
    }
    for key in Array(terrain.keys) where !live.contains(key) {
      terrain.removeValue(forKey: key)?.removeFromParent()
    }
  }
  private func makeTile(x: Int, y: Int) -> SKNode {
    let node = SKNode()
    var random = SeededRandom(state: UInt64(bitPattern: Int64(x &* 73_856_093 ^ y &* 19_349_663)))
    let paving = SKShapeNode(rectOf: CGSize(width: 142, height: 142), cornerRadius: 14)
    paving.strokeColor = UIColor(red: 0.14, green: 0.26, blue: 0.27, alpha: 0.25)
    paving.fillColor = UIColor(red: 0.045, green: 0.12, blue: 0.14, alpha: 0.45)
    paving.lineWidth = 1
    node.addChild(paving)
    for _ in 0..<7 {
      let px = random.next() * 146 - 73
      let py = random.next() * 146 - 73
      let leaf = SKShapeNode(
        ellipseOf: CGSize(width: 4 + random.next() * 8, height: 17 + random.next() * 15))
      leaf.position = CGPoint(x: px, y: py)
      leaf.zRotation = random.next() * 6
      leaf.strokeColor = .clear
      leaf.fillColor = UIColor(
        red: 0.10, green: 0.25 + random.next() * 0.09, blue: 0.26, alpha: 0.7)
      node.addChild(leaf)
    }
    if random.next() > 0.55 {
      let flower = SKShapeNode(circleOfRadius: 2)
      flower.fillColor = GardenArt.gold.withAlphaComponent(0.55)
      flower.strokeColor = .clear
      flower.position = CGPoint(x: random.next() * 120 - 60, y: random.next() * 120 - 60)
      node.addChild(flower)
    }
    return node
  }
}
