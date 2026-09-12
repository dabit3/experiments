import SpriteKit
import UIKit

extension UIColor {
  convenience init(hex: UInt32, alpha: CGFloat = 1) {
    self.init(
      red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
      blue: CGFloat(hex & 255) / 255, alpha: alpha)
  }
}

@MainActor
enum ForestArt {
  static func oval(
    _ width: CGFloat, _ height: CGFloat, _ color: UInt32,
    x: CGFloat = 0, y: CGFloat = 0
  ) -> SKShapeNode {
    let node = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
    node.fillColor = UIColor(hex: color)
    node.strokeColor = .clear
    node.position = CGPoint(x: x, y: y)
    return node
  }

  static func rect(
    _ width: CGFloat, _ height: CGFloat, _ color: UInt32,
    x: CGFloat = 0, y: CGFloat = 0, radius: CGFloat = 0
  ) -> SKShapeNode {
    let node = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: radius)
    node.fillColor = UIColor(hex: color)
    node.strokeColor = .clear
    node.position = CGPoint(x: x, y: y)
    return node
  }

  static func path(_ points: [CGPoint], _ color: UInt32) -> SKShapeNode {
    let path = CGMutablePath()
    guard let first = points.first else { return SKShapeNode() }
    path.move(to: first)
    for point in points.dropFirst() { path.addLine(to: point) }
    path.closeSubpath()
    let node = SKShapeNode(path: path)
    node.fillColor = UIColor(hex: color)
    node.strokeColor = .clear
    return node
  }

  static func line(_ points: [CGPoint], _ color: UInt32, width: CGFloat) -> SKShapeNode {
    let path = CGMutablePath()
    guard let first = points.first else { return SKShapeNode() }
    path.move(to: first)
    for point in points.dropFirst() { path.addLine(to: point) }
    let node = SKShapeNode(path: path)
    node.strokeColor = UIColor(hex: color)
    node.lineWidth = width
    node.lineCap = .round
    return node
  }

  static func explorer() -> SKNode {
    let node = SKNode()
    node.addChild(oval(35, 9, 0x173F36, x: 0, y: 1))
    let left = rect(11, 12, 0x503D30, x: -7, y: 7, radius: 4)
    left.name = "leftFoot"
    let right = rect(13, 11, 0x503D30, x: 7, y: 7, radius: 4)
    right.name = "rightFoot"
    node.addChild(left)
    node.addChild(right)
    node.addChild(rect(15, 24, 0x704F38, x: -13, y: 26, radius: 5))
    node.addChild(rect(5, 18, 0xC29A62, x: -19, y: 28, radius: 2))
    node.addChild(oval(28, 31, 0xCC6B41, x: 0, y: 24))
    node.addChild(rect(22, 4, 0xE7AF68, x: 1, y: 19, radius: 1))
    node.addChild(oval(5, 5, 0xF7DB92, x: 2, y: 29))
    node.addChild(oval(10, 13, 0xF4CA94, x: 12, y: 29))
    node.addChild(oval(31, 28, 0xF6D8A7, x: 0, y: 45))
    node.addChild(oval(8, 11, 0xE7B784, x: -14, y: 45))
    node.addChild(oval(9, 5, 0xDA9378, x: 9, y: 40))
    node.addChild(oval(3.7, 5.5, 0x283D32, x: 5, y: 47))
    node.addChild(oval(2, 2, 0xFFF7DF, x: 5.5, y: 48))
    node.addChild(
      line(
        [CGPoint(x: 4, y: 37), CGPoint(x: 8, y: 36), CGPoint(x: 11, y: 38)],
        0x9C6A53, width: 1.5))
    node.addChild(oval(36, 20, 0x456D4A, x: -3, y: 58))
    node.addChild(oval(47, 8, 0x76945A, x: 1, y: 52))
    node.addChild(rect(30, 4, 0xDDBD74, x: -2, y: 55, radius: 2))
    let feather = oval(8, 26, 0xEDB264, x: -9, y: 74)
    feather.zRotation = -0.4
    node.addChild(feather)
    node.addChild(line([CGPoint(x: -5, y: 59), CGPoint(x: -12, y: 82)], 0x986645, width: 1.4))
    let scarf = path(
      [CGPoint(x: -11, y: 35), CGPoint(x: -27, y: 29), CGPoint(x: -20, y: 40)],
      0xE6B65E)
    scarf.name = "scarf"
    node.addChild(scarf)
    return node
  }

  static func beetle() -> SKNode {
    let node = SKNode()
    for x in [-12.0, 0, 12] {
      node.addChild(oval(9, 6, 0x322F30, x: x, y: 3))
    }
    node.addChild(oval(40, 27, 0x4A3E57, y: 16))
    node.addChild(oval(33, 24, 0x8D6578, x: -3, y: 19))
    node.addChild(oval(21, 12, 0xB8838B, x: -5, y: 25))
    node.addChild(line([CGPoint(x: -2, y: 10), CGPoint(x: -2, y: 30)], 0x64465F, width: 2))
    for x in [-10.0, 8] {
      node.addChild(oval(4, 4, 0xE5BB91, x: x, y: 21))
    }
    node.addChild(oval(16, 18, 0x4A3E57, x: 17, y: 13))
    node.addChild(oval(5, 7, 0xFBEBBD, x: 21, y: 17))
    node.addChild(oval(2, 4, 0x253A37, x: 22, y: 17))
    node.addChild(line([CGPoint(x: 19, y: 21), CGPoint(x: 24, y: 32)], 0x4A3E57, width: 2))
    node.addChild(oval(5, 5, 0xD8A566, x: 24, y: 32))
    return node
  }

  static func flower(x: CGFloat, y: CGFloat, color: UInt32, scale: CGFloat = 1) -> SKNode {
    let node = SKNode()
    node.position = CGPoint(x: x, y: y)
    node.setScale(scale)
    node.addChild(line([.zero, CGPoint(x: -3, y: 16), CGPoint(x: 0, y: 25)], 0x608153, width: 2))
    let leaf = oval(12, 5, 0x92AB64, x: 4, y: 10)
    leaf.zRotation = 0.4
    node.addChild(leaf)
    for i in 0..<5 {
      let angle = CGFloat(i) * .pi * 2 / 5
      node.addChild(oval(7, 7, color, x: cos(angle) * 5, y: 25 + sin(angle) * 5))
    }
    node.addChild(oval(5, 5, 0xF6CB6A, y: 25))
    return node
  }

  static func fern(x: CGFloat, y: CGFloat, scale: CGFloat = 1, color: UInt32 = 0x749760) -> SKNode {
    let node = SKNode()
    node.position = CGPoint(x: x, y: y)
    node.setScale(scale)
    for side in [-1.0, 1] {
      for i in 0..<5 {
        let leaf = oval(
          20 - Double(i) * 2, 6, color,
          x: side * (5 + Double(i) * 3), y: 6 + Double(i) * 7)
        leaf.zRotation = side * 0.6
        node.addChild(leaf)
      }
    }
    return node
  }

  static func platform(_ ledge: Ledge) -> SKNode {
    let node = SKNode()
    let depth = ledge.depth
    let moving = ledge.travel > 0
    node.addChild(
      rect(
        ledge.width, depth, moving ? 0x776448 : 0x65553F,
        x: ledge.width / 2, y: -depth / 2, radius: 10))
    node.addChild(rect(ledge.width - 8, 10, 0x483F36, x: ledge.width / 2, y: -15, radius: 4))
    if depth > 100 {
      for i in stride(from: 20, to: Int(ledge.width), by: 45) {
        let xx = Double(i)
        node.addChild(
          line(
            [
              CGPoint(x: xx, y: -35), CGPoint(x: xx + 8, y: -67),
              CGPoint(x: xx - 3, y: -110),
            ], 0x796A4C, width: 2))
        node.addChild(oval(12, 7, 0x85754E, x: xx + 9, y: -46))
      }
    } else {
      for i in stride(from: 15, to: Int(ledge.width), by: 30) {
        node.addChild(oval(5, 5, 0xB9A06C, x: CGFloat(i), y: -19))
      }
    }
    node.addChild(
      rect(
        ledge.width + 6, 12, moving ? 0xD3AF65 : 0x678A4D,
        x: ledge.width / 2, y: -2, radius: 6))
    node.addChild(
      rect(
        ledge.width, 3, moving ? 0xF2D58C : 0xBDCE85,
        x: ledge.width / 2, y: 3, radius: 1))
    if moving {
      for x in [18.0, ledge.width - 18] {
        let gear = self.gear(radius: 12)
        gear.position = CGPoint(x: x, y: -16)
        gear.name = "gear"
        node.addChild(gear)
      }
    } else {
      for i in stride(from: 27, to: Int(ledge.width) - 10, by: 85) {
        node.addChild(fern(x: CGFloat(i), y: 2, scale: 0.55))
        if i % 3 == 0 {
          node.addChild(flower(x: CGFloat(i + 18), y: 3, color: 0xF3D99A, scale: 0.65))
        }
      }
    }
    return node
  }

  static func gear(radius: CGFloat) -> SKNode {
    let node = SKNode()
    for i in 0..<10 {
      let angle = CGFloat(i) * .pi / 5
      let tooth = rect(
        radius * 0.45, radius * 0.55, 0xBA914D,
        x: cos(angle) * radius * 0.86, y: sin(angle) * radius * 0.86, radius: 1)
      tooth.zRotation = angle
      node.addChild(tooth)
    }
    node.addChild(oval(radius * 1.8, radius * 1.8, 0xD5B371))
    node.addChild(oval(radius * 1.25, radius * 1.25, 0x776345))
    node.addChild(oval(radius * 0.6, radius * 0.6, 0xD5B371))
    return node
  }

  static func waterwheel(radius: CGFloat) -> SKNode {
    let node = SKNode()
    let rim = oval(radius * 2, radius * 2, 0x567B73)
    rim.fillColor = .clear
    rim.strokeColor = UIColor(hex: 0x698C7C)
    rim.lineWidth = 9
    node.addChild(rim)
    for i in 0..<8 {
      let angle = CGFloat(i) * .pi / 4
      node.addChild(
        line(
          [.zero, CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)],
          0x547A70, width: 7))
      let paddle = rect(
        23, 9, 0x7C9680,
        x: cos(angle) * radius, y: sin(angle) * radius, radius: 2)
      paddle.zRotation = angle + .pi / 2
      node.addChild(paddle)
    }
    node.addChild(oval(24, 24, 0x658475))
    node.addChild(oval(9, 9, 0x3D625D))
    return node
  }

  static func coin() -> SKNode {
    let node = SKNode()
    node.addChild(oval(21, 23, 0xBD863D))
    node.addChild(oval(17, 19, 0xF0CC75, y: 1))
    let stitch = oval(10, 12, 0xF0CC75, y: 1)
    stitch.strokeColor = UIColor(hex: 0xD7A04D)
    stitch.lineWidth = 1
    node.addChild(stitch)
    for x in [-2.5, 2.5] {
      for y in [-1.5, 3.5] {
        node.addChild(oval(2.5, 2.5, 0x9F783D, x: x, y: y))
      }
    }
    return node
  }

  static func acorn() -> SKNode {
    let node = SKNode()
    let ring = oval(44, 44, 0xEACD7C)
    ring.alpha = 0.14
    node.addChild(ring)
    node.addChild(oval(22, 29, 0xDAA359, y: -2))
    node.addChild(oval(26, 13, 0x7E6846, y: 8))
    node.addChild(rect(4, 9, 0xB8945A, x: 2, y: 17, radius: 2))
    node.addChild(oval(5, 10, 0xF6D78B, x: -4, y: -1))
    return node
  }

  static func lantern(active: Bool = false) -> SKNode {
    let node = SKNode()
    node.addChild(rect(7, 90, 0x796347, y: 45, radius: 3))
    node.addChild(
      line(
        [
          CGPoint(x: 0, y: 88), CGPoint(x: 0, y: 104), CGPoint(x: 23, y: 104),
          CGPoint(x: 25, y: 93),
        ], 0x796347, width: 5))
    let light = oval(62, 65, 0xFFE296, x: 24, y: 73)
    light.alpha = active ? 0.18 : 0.03
    light.name = "glow"
    node.addChild(light)
    node.addChild(rect(23, 30, 0xBD914B, x: 24, y: 75, radius: 4))
    let glass = rect(15, 22, active ? 0xFFE8A1 : 0x8C9C77, x: 24, y: 75, radius: 2)
    glass.name = "glass"
    node.addChild(glass)
    node.addChild(rect(31, 5, 0x6C5942, x: 24, y: 91, radius: 2))
    return node
  }

  static func door() -> SKNode {
    let node = SKNode()
    node.addChild(oval(172, 176, 0x405E45, y: 58))
    node.addChild(rect(145, 180, 0x876E49, y: 72, radius: 68))
    node.addChild(rect(112, 155, 0xB69A68, y: 64, radius: 54))
    node.addChild(rect(94, 143, 0x324E3E, y: 61, radius: 46))
    node.addChild(rect(72, 130, 0xE8BB6F, y: 60, radius: 36))
    for x in [-24.0, -8, 8, 24] {
      node.addChild(line([CGPoint(x: x, y: 5), CGPoint(x: x, y: 115)], 0xC09454, width: 2))
    }
    node.addChild(oval(8, 8, 0x694F32, x: 20, y: 57))
    let gear = gear(radius: 25)
    gear.position.y = 148
    node.addChild(gear)
    node.addChild(fern(x: -67, y: 0, scale: 1.1))
    node.addChild(flower(x: 69, y: 0, color: 0xF2D799, scale: 1.4))
    return node
  }

  static func tree(x: CGFloat, height: CGFloat, color: UInt32, foliage: UInt32) -> SKNode {
    let node = SKNode()
    node.position.x = x
    node.addChild(
      path(
        [
          CGPoint(x: -28, y: -30), CGPoint(x: -12, y: height * 0.7),
          CGPoint(x: -20, y: height), CGPoint(x: 15, y: height + 10),
          CGPoint(x: 17, y: height * 0.7), CGPoint(x: 47, y: -30),
        ], color))
    node.addChild(
      line(
        [
          CGPoint(x: 0, y: height * 0.52), CGPoint(x: -70, y: height * 0.7),
          CGPoint(x: -107, y: height * 0.9),
        ], color, width: 16))
    node.addChild(
      line(
        [CGPoint(x: 5, y: height * 0.65), CGPoint(x: 80, y: height * 0.88)],
        color, width: 15))
    node.addChild(
      line(
        [CGPoint(x: 5, y: 5), CGPoint(x: 1, y: height * 0.62)],
        foliage, width: 3))
    for i in 0..<6 {
      let xx = CGFloat(i - 3) * 47
      node.addChild(oval(150, 96, foliage, x: xx, y: height - abs(xx) * 0.22))
    }
    return node
  }
}
