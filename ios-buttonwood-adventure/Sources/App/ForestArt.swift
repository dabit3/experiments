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

  /// Gives a shape a soft storybook ink line.
  @discardableResult
  static func inked(_ node: SKShapeNode, _ color: UInt32 = 0x2B2A28, width: CGFloat = 1.4)
    -> SKShapeNode
  {
    node.strokeColor = UIColor(hex: color, alpha: 0.85)
    node.lineWidth = width
    node.lineJoin = .round
    return node
  }

  static func explorer() -> SKNode {
    let node = SKNode()
    let shadow = oval(38, 9, 0x173F36, x: 0, y: 1)
    shadow.alpha = 0.7
    node.addChild(shadow)
    let left = inked(rect(12, 12, 0x4A3327, x: -7, y: 7, radius: 4))
    left.name = "leftFoot"
    let right = inked(rect(14, 11, 0x4A3327, x: 7, y: 7, radius: 4))
    right.name = "rightFoot"
    node.addChild(left)
    node.addChild(right)
    node.addChild(rect(6, 3, 0x9C7A4C, x: -7, y: 11, radius: 1))
    node.addChild(rect(6, 3, 0x9C7A4C, x: 7, y: 10, radius: 1))
    node.addChild(inked(rect(15, 24, 0x6B4A34, x: -13, y: 26, radius: 5)))
    node.addChild(rect(5, 18, 0xC29A62, x: -19, y: 28, radius: 2))
    node.addChild(oval(6, 6, 0xB98B57, x: -19, y: 19))
    let coat = inked(oval(29, 32, 0xCF6A3E, x: 0, y: 24))
    node.addChild(coat)
    node.addChild(oval(12, 26, 0xE28553, x: -5, y: 25))
    node.addChild(rect(23, 4, 0xE7AF68, x: 1, y: 19, radius: 1))
    node.addChild(inked(oval(6, 6, 0xF7DB92, x: 2, y: 19), 0x8A6A3E, width: 1))
    node.addChild(oval(7, 7, 0xF7DB92, x: 2, y: 29))
    node.addChild(oval(2, 2, 0x8A6A3E, x: 2, y: 29))
    node.addChild(inked(oval(10, 13, 0xF4CA94, x: 12, y: 29)))
    node.addChild(inked(oval(32, 29, 0xF6D8A7, x: 0, y: 45)))
    node.addChild(oval(8, 11, 0xE7B784, x: -14, y: 45))
    node.addChild(oval(9, 5, 0xE9A38C, x: 9, y: 40))
    node.addChild(oval(7, 4, 0xE9A38C, x: -6, y: 40))
    node.addChild(oval(4, 6, 0x283D32, x: 5, y: 47))
    node.addChild(oval(2, 2, 0xFFF7DF, x: 6, y: 48.5))
    node.addChild(oval(3, 4.5, 0x283D32, x: -6, y: 47))
    node.addChild(oval(1.5, 1.5, 0xFFF7DF, x: -5.3, y: 48.5))
    let smile = CGMutablePath()
    smile.addArc(
      center: CGPoint(x: 1, y: 41), radius: 4, startAngle: .pi * 1.15, endAngle: .pi * 1.85,
      clockwise: false)
    let mouth = SKShapeNode(path: smile)
    mouth.strokeColor = UIColor(hex: 0x9C6A53)
    mouth.lineWidth = 1.5
    mouth.lineCap = .round
    node.addChild(mouth)
    node.addChild(inked(oval(48, 9, 0x6E8E52, x: 1, y: 56)))
    node.addChild(inked(oval(37, 21, 0x476F4B, x: -3, y: 62)))
    node.addChild(oval(20, 8, 0x5C8A58, x: -6, y: 69))
    node.addChild(rect(31, 4, 0xDDBD74, x: -2, y: 59, radius: 2))
    node.addChild(oval(4, 4, 0xF0CC75, x: 8, y: 59))
    let feather = inked(oval(8, 27, 0xEDB264, x: -9, y: 78), 0x9A6A3A, width: 1)
    feather.zRotation = -0.4
    node.addChild(feather)
    node.addChild(line([CGPoint(x: -5, y: 63), CGPoint(x: -12, y: 87)], 0x986645, width: 1.4))
    let scarf = inked(
      path(
        [CGPoint(x: -11, y: 35), CGPoint(x: -28, y: 29), CGPoint(x: -21, y: 41)],
        0xE6B65E))
    scarf.name = "scarf"
    node.addChild(scarf)
    node.addChild(oval(4, 4, 0xC98C3A, x: -25, y: 30))
    return node
  }

  static func beetle() -> SKNode {
    let node = SKNode()
    let shadow = oval(44, 8, 0x173F36, y: 1)
    shadow.alpha = 0.55
    node.addChild(shadow)
    for x in [-13.0, -1, 11] {
      node.addChild(
        line(
          [CGPoint(x: x, y: 12), CGPoint(x: x - 3, y: 5), CGPoint(x: x - 6, y: 2)],
          0x2E2A2F, width: 2.2))
    }
    node.addChild(inked(oval(42, 28, 0x463A57, y: 16)))
    node.addChild(oval(34, 24, 0x8F6379, x: -3, y: 19))
    node.addChild(oval(20, 11, 0xBF8A93, x: -6, y: 25))
    node.addChild(oval(9, 4, 0xE8C3C2, x: -9, y: 28))
    node.addChild(line([CGPoint(x: -2, y: 8), CGPoint(x: -2, y: 30)], 0x4E3752, width: 2))
    for (x, y) in [(-11.0, 22.0), (7, 20), (-5, 14), (3, 26)] {
      node.addChild(inked(oval(4.5, 4.5, 0xF2D39B, x: x, y: y), 0x4E3752, width: 0.8))
    }
    node.addChild(inked(oval(17, 18, 0x463A57, x: 17, y: 13)))
    node.addChild(oval(6, 7.5, 0xFBEBBD, x: 21, y: 17))
    node.addChild(oval(2.5, 4, 0x253A37, x: 22.5, y: 17))
    node.addChild(oval(1, 1, 0xFFFFFF, x: 23, y: 18.5))
    node.addChild(oval(5, 3, 0xD9899A, x: 16, y: 11))
    for side in [-1.0, 1] {
      node.addChild(
        line(
          [CGPoint(x: 20 + side * 2, y: 21), CGPoint(x: 24 + side * 5, y: 33)],
          0x463A57, width: 1.8))
      node.addChild(oval(5, 5, 0xE0AB60, x: 24 + side * 5, y: 33))
    }
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
    let width = ledge.width
    if ledge.travel > 0 {
      return movingPlatform(width: width, depth: depth)
    }
    node.addChild(
      inked(
        rect(width, depth, 0x5E4B37, x: width / 2, y: -depth / 2, radius: 10), 0x2E241A, width: 1.6)
    )
    node.addChild(rect(width - 8, 9, 0x4A3B2C, x: width / 2, y: -14, radius: 4))
    if depth > 100 {
      for y in stride(from: 40, to: Int(depth) - 20, by: 34) {
        let strata = line(
          [CGPoint(x: 14, y: -CGFloat(y)), CGPoint(x: width - 14, y: -CGFloat(y) - 3)],
          0x53412D, width: 2)
        strata.alpha = 0.7
        node.addChild(strata)
      }
      for i in stride(from: 30, to: Int(width) - 20, by: 70) {
        let xx = Double(i)
        let wobble = Double(i % 3) * 6
        let root = line(
          [
            CGPoint(x: xx, y: -30), CGPoint(x: xx + 5 + wobble, y: -58),
            CGPoint(x: xx - 2 + wobble, y: -84), CGPoint(x: xx + 9, y: -112),
          ], 0x7A6448, width: 2.5)
        root.alpha = 0.45
        node.addChild(root)
        node.addChild(oval(11, 7, 0x8A7550, x: xx + 26, y: -46 - wobble))
        node.addChild(oval(7, 5, 0x6E5B40, x: xx + 38, y: -88 + wobble))
      }
    } else {
      for i in stride(from: 15, to: Int(width), by: 30) {
        node.addChild(oval(5, 4, 0xA9905F, x: CGFloat(i), y: -18))
      }
      for i in stride(from: 8, to: Int(width), by: 55) {
        node.addChild(
          line(
            [CGPoint(x: CGFloat(i), y: -depth + 2), CGPoint(x: CGFloat(i) + 4, y: -depth - 9)],
            0x53412D, width: 2))
      }
    }
    node.addChild(
      inked(rect(width + 6, 13, 0x5F8646, x: width / 2, y: -2, radius: 6), 0x2E4A24, width: 1.4))
    node.addChild(rect(width, 3, 0xB9D07E, x: width / 2, y: 3, radius: 1))
    for i in stride(from: 6, to: Int(width) - 4, by: 11) {
      let xx = CGFloat(i)
      let blade = line(
        [CGPoint(x: xx, y: -4), CGPoint(x: xx + (i % 2 == 0 ? 3 : -3), y: 6 + CGFloat(i % 3) * 2)],
        i % 3 == 0 ? 0xB9D07E : 0x7FA657, width: 2)
      blade.alpha = 0.9
      node.addChild(blade)
      if i % 4 == 0 {
        let drip = oval(6, 9, 0x5F8646, x: xx + 4, y: -9)
        node.addChild(drip)
      }
    }
    for i in stride(from: 27, to: Int(width) - 10, by: 85) {
      node.addChild(fern(x: CGFloat(i), y: 2, scale: 0.55))
      if i % 3 == 0 {
        node.addChild(flower(x: CGFloat(i + 18), y: 3, color: 0xF3D99A, scale: 0.65))
      }
      if i % 2 == 0 {
        node.addChild(oval(7, 5, 0x8B8779, x: CGFloat(i - 12), y: 5))
      }
    }
    return node
  }

  static func movingPlatform(width: CGFloat, depth: CGFloat) -> SKNode {
    let node = SKNode()
    node.addChild(
      inked(
        rect(width, depth, 0x8A6A44, x: width / 2, y: -depth / 2, radius: 6), 0x3B2A18, width: 1.6))
    for i in stride(from: 26, to: Int(width) - 10, by: 26) {
      node.addChild(
        line(
          [CGPoint(x: CGFloat(i), y: -3), CGPoint(x: CGFloat(i), y: -depth + 3)],
          0x6A4E2F, width: 1.5))
    }
    node.addChild(rect(width - 10, 3, 0xB58D5A, x: width / 2, y: -5, radius: 1))
    node.addChild(
      inked(rect(width + 6, 9, 0xD3AF65, x: width / 2, y: -1, radius: 4), 0x6C4E22, width: 1.2))
    node.addChild(rect(width, 2, 0xF2D58C, x: width / 2, y: 2, radius: 1))
    node.addChild(
      inked(
        rect(width + 6, 7, 0xC59B52, x: width / 2, y: -depth + 3, radius: 3), 0x6C4E22, width: 1.2))
    for x in stride(from: 8.0, through: Double(width), by: max(24, Double(width) / 4)) {
      node.addChild(oval(4, 4, 0xF6DE9C, x: x, y: -1))
      node.addChild(oval(4, 4, 0xF6DE9C, x: x, y: -depth + 3))
    }
    for x in [16.0, width - 16] {
      let gear = self.gear(radius: 12)
      gear.position = CGPoint(x: x, y: -depth / 2 - 4)
      gear.name = "gear"
      node.addChild(gear)
    }
    let lamp = oval(8, 8, 0xFFE8A1, x: width / 2, y: -depth / 2)
    lamp.alpha = 0.8
    node.addChild(lamp)
    return node
  }

  static func gear(radius: CGFloat) -> SKNode {
    let node = SKNode()
    for i in 0..<10 {
      let angle = CGFloat(i) * .pi / 5
      let tooth = inked(
        rect(
          radius * 0.45, radius * 0.55, 0xBA914D,
          x: cos(angle) * radius * 0.86, y: sin(angle) * radius * 0.86, radius: 1),
        0x6C4E22, width: 1)
      tooth.zRotation = angle
      node.addChild(tooth)
    }
    node.addChild(inked(oval(radius * 1.8, radius * 1.8, 0xD5B371), 0x6C4E22, width: 1))
    node.addChild(oval(radius * 1.25, radius * 1.25, 0x776345))
    for i in 0..<4 {
      let angle = CGFloat(i) * .pi / 2 + .pi / 4
      node.addChild(
        line(
          [
            CGPoint(x: cos(angle) * radius * 0.3, y: sin(angle) * radius * 0.3),
            CGPoint(x: cos(angle) * radius * 0.6, y: sin(angle) * radius * 0.6),
          ], 0xD5B371, width: radius * 0.16))
    }
    node.addChild(oval(radius * 0.6, radius * 0.6, 0xD5B371))
    node.addChild(oval(radius * 0.22, radius * 0.22, 0x776345))
    let shine = oval(radius * 0.5, radius * 0.22, 0xFBEFC7, x: -radius * 0.45, y: radius * 0.6)
    shine.zRotation = 0.6
    shine.alpha = 0.7
    node.addChild(shine)
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
    let halo = oval(32, 34, 0xFFE9A8)
    halo.alpha = 0.16
    node.addChild(halo)
    node.addChild(inked(oval(21, 23, 0xBD863D), 0x6C4E22, width: 1.2))
    node.addChild(oval(17, 19, 0xF0CC75, y: 1))
    let shine = oval(7, 3, 0xFFF4CF, x: -3, y: 7)
    shine.zRotation = 0.5
    node.addChild(shine)
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
    node.addChild(inked(oval(22, 29, 0xDAA359, y: -2), 0x6C4E22, width: 1.2))
    node.addChild(inked(oval(26, 13, 0x7E6846, y: 8), 0x3F3222, width: 1.2))
    for x in [-7.0, 0, 7] {
      node.addChild(oval(3, 3, 0x9A8358, x: x, y: 8))
    }
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
    node.addChild(inked(rect(23, 30, 0xBD914B, x: 24, y: 75, radius: 4), 0x4A3A22, width: 1.2))
    let glass = rect(15, 22, active ? 0xFFE8A1 : 0x8C9C77, x: 24, y: 75, radius: 2)
    glass.name = "glass"
    node.addChild(glass)
    node.addChild(line([CGPoint(x: 24, y: 64), CGPoint(x: 24, y: 86)], 0xBD914B, width: 1.5))
    node.addChild(inked(rect(31, 5, 0x6C5942, x: 24, y: 91, radius: 2), 0x3F3222, width: 1))
    node.addChild(oval(7, 5, 0x6C5942, x: 24, y: 95))
    node.addChild(rect(27, 4, 0x6C5942, x: 24, y: 59, radius: 2))
    node.addChild(oval(14, 6, 0x5E4B37, y: 0))
    node.addChild(rect(11, 6, 0x6C5942, y: 3, radius: 2))
    return node
  }

  static func door() -> SKNode {
    let node = SKNode()
    node.addChild(oval(172, 176, 0x405E45, y: 58))
    node.addChild(oval(120, 80, 0x4A6A4C, x: -40, y: 130))
    node.addChild(oval(110, 70, 0x4A6A4C, x: 45, y: 125))
    node.addChild(inked(rect(145, 180, 0x876E49, y: 72, radius: 68), 0x3B2A18, width: 1.8))
    for y in stride(from: 10, to: 150, by: 22) {
      node.addChild(
        line(
          [CGPoint(x: -66, y: CGFloat(y)), CGPoint(x: 66, y: CGFloat(y) + 2)],
          0x76603F, width: 1.5))
    }
    node.addChild(inked(rect(112, 155, 0xB69A68, y: 64, radius: 54), 0x6C4E22, width: 1.4))
    node.addChild(rect(94, 143, 0x324E3E, y: 61, radius: 46))
    node.addChild(inked(rect(72, 130, 0xE8BB6F, y: 60, radius: 36), 0x9A6A2E, width: 1.4))
    for x in [-24.0, -8, 8, 24] {
      node.addChild(line([CGPoint(x: x, y: 5), CGPoint(x: x, y: 115)], 0xC09454, width: 2))
    }
    node.addChild(rect(72, 4, 0xC09454, y: 92, radius: 1))
    node.addChild(rect(72, 4, 0xC09454, y: 30, radius: 1))
    node.addChild(inked(oval(9, 9, 0x694F32, x: 20, y: 57), 0x3F3222, width: 1))
    for (x, y) in [(-46.0, 20.0), (46, 20), (-46, 110), (46, 110)] {
      node.addChild(inked(oval(7, 7, 0xD5B371, x: x, y: y), 0x6C4E22, width: 1))
    }
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
          CGPoint(x: -44, y: -30), CGPoint(x: -26, y: -8), CGPoint(x: -12, y: height * 0.7),
          CGPoint(x: -20, y: height), CGPoint(x: 15, y: height + 10),
          CGPoint(x: 17, y: height * 0.7), CGPoint(x: 40, y: -6), CGPoint(x: 66, y: -30),
        ], color))
    for i in 0..<4 {
      let yy = 40 + CGFloat(i) * height * 0.16
      let groove = line(
        [
          CGPoint(x: -6 + CGFloat(i % 2) * 8, y: yy),
          CGPoint(x: -2 + CGFloat(i % 2) * 8, y: yy + 40),
        ],
        foliage, width: 2)
      groove.alpha = 0.35
      node.addChild(groove)
    }
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
    for i in 0..<4 {
      let xx = CGFloat(i) * 62 - 90
      let crown = oval(96, 60, foliage, x: xx, y: height + 38 - abs(xx) * 0.12)
      node.addChild(crown)
      let light = oval(70, 26, 0xFFFFFF, x: xx - 6, y: height + 52 - abs(xx) * 0.12)
      light.alpha = 0.07
      node.addChild(light)
    }
    return node
  }
}
