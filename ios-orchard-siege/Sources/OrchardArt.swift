import SpriteKit
import UIKit

enum OrchardArt {
  static let ink = UIColor(hex: 0x293E32)
  static var cache: [String: SKTexture] = [:]

  static func image(size: CGSize, draw: (CGContext) -> Void) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.5
    return UIGraphicsImageRenderer(size: size, format: format).image { draw($0.cgContext) }
  }

  static func texture(_ key: String, size: CGSize, draw: (CGContext) -> Void) -> SKTexture {
    if let cached = cache[key] { return cached }
    let result = SKTexture(image: image(size: size, draw: draw))
    cache[key] = result
    return result
  }

  static func oval(_ context: CGContext, _ rect: CGRect, _ color: UInt32, alpha: CGFloat = 1) {
    context.setFillColor(UIColor(hex: color).withAlphaComponent(alpha).cgColor)
    context.fillEllipse(in: rect)
  }

  static func line(_ context: CGContext, _ points: [CGPoint], color: UInt32, width: CGFloat) {
    guard let first = points.first else { return }
    context.setStrokeColor(UIColor(hex: color).cgColor)
    context.setLineWidth(width)
    context.setLineCap(.round)
    context.beginPath()
    context.move(to: first)
    for point in points.dropFirst() { context.addLine(to: point) }
    context.strokePath()
  }

  static func gradient(_ context: CGContext, rect: CGRect, top: UInt32, bottom: UInt32) {
    let colors = [UIColor(hex: top).cgColor, UIColor(hex: bottom).cgColor] as CFArray
    guard
      let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors, locations: [0, 1])
    else { return }
    context.saveGState()
    context.clip(to: rect)
    context.drawLinearGradient(
      gradient, start: CGPoint(x: rect.midX, y: rect.minY),
      end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
    context.restoreGState()
  }

  static func background() -> SKTexture {
    texture("orchard", size: CGSize(width: 1400, height: 660)) { context in
      gradient(
        context, rect: CGRect(x: 0, y: 0, width: 1400, height: 660),
        top: 0xF6DFBA, bottom: 0xFAEACB)
      for radius in stride(from: 180, through: 80, by: -20) {
        oval(
          context,
          CGRect(
            x: 1080 - radius, y: 190 - radius, width: radius * 2,
            height: radius * 2), 0xFFF4C7, alpha: 0.1)
      }
      oval(context, CGRect(x: 1020, y: 120, width: 122, height: 122), 0xFFF5D7)
      for index in 0..<4 {
        let y = CGFloat(315 + index * 47)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -60, y: y))
        path.addCurve(
          to: CGPoint(x: 1450, y: y - 15),
          controlPoint1: CGPoint(x: 450, y: y - 150),
          controlPoint2: CGPoint(x: 860, y: y + 130))
        path.addLine(to: CGPoint(x: 1450, y: 660))
        path.addLine(to: CGPoint(x: -60, y: 660))
        UIColor(hex: [0xD3D6AC, 0xB3C393, 0x92A77B, 0x819565][index]).setFill()
        path.fill()
      }
      for index in 0..<24 {
        let x = CGFloat(index * 73 - 60)
        let y = CGFloat(355 + (index % 3) * 19)
        line(
          context, [CGPoint(x: x, y: y + 85), CGPoint(x: x + 7, y: y)],
          color: 0x80936B, width: 9)
        oval(
          context, CGRect(x: x - 31, y: y - 30, width: 85, height: 75),
          0x839C71, alpha: 0.7)
        oval(
          context, CGRect(x: x - 20, y: y - 47, width: 69, height: 65),
          0xA2B384, alpha: 0.8)
      }
      for index in 0..<32 {
        let x = CGFloat(index * 50)
        line(
          context, [CGPoint(x: x, y: 445), CGPoint(x: x, y: 501)],
          color: 0xC1BB8D, width: 8)
      }
      line(context, [CGPoint(x: 0, y: 460), CGPoint(x: 1400, y: 460)], color: 0xBCB584, width: 6)
      line(context, [CGPoint(x: 0, y: 485), CGPoint(x: 1400, y: 485)], color: 0xBCB584, width: 6)
      tree(context, x: 45, y: 510, scale: 1.3)
      tree(context, x: 1370, y: 517, scale: 1.1)
      gradient(
        context, rect: CGRect(x: 0, y: 525, width: 1400, height: 135),
        top: 0xAA7651, bottom: 0x755541)
      context.setFillColor(UIColor(hex: 0x5C794A).cgColor)
      context.fill(CGRect(x: 0, y: 518, width: 1400, height: 10))
      context.setFillColor(UIColor(hex: 0xB1C07F).cgColor)
      context.fill(CGRect(x: 0, y: 518, width: 1400, height: 3))
      for index in 0..<700 {
        let x = CGFloat((index * 137 + 43) % 1400)
        let y = CGFloat(535 + (index * 71) % 130)
        oval(
          context, CGRect(x: x, y: y, width: index % 3 == 0 ? 4 : 2, height: 2),
          index % 2 == 0 ? 0xEDC591 : 0x4B4536, alpha: 0.22)
      }
      for index in 0..<90 {
        let x = CGFloat((index * 137) % 1400)
        line(
          context,
          [
            CGPoint(x: x, y: 523), CGPoint(x: x - 4, y: 513),
            CGPoint(x: x + 4, y: 520),
          ], color: 0x849953, width: 2)
      }
      for index in 0..<12 {
        let x = CGFloat(340 + index * 73)
        oval(
          context, CGRect(x: x, y: 500 + CGFloat(index % 3) * 5, width: 4, height: 9),
          0xF2D08E)
      }
    }
  }

  static func tree(_ context: CGContext, x: CGFloat, y: CGFloat, scale: CGFloat) {
    context.saveGState()
    context.translateBy(x: x, y: y)
    context.scaleBy(x: scale, y: scale)
    line(
      context,
      [
        CGPoint(x: 0, y: 0), CGPoint(x: -8, y: -170),
        CGPoint(x: 24, y: -252),
      ], color: 0x75644B, width: 25)
    line(
      context, [CGPoint(x: -6, y: -110), CGPoint(x: -67, y: -206)],
      color: 0x75644B, width: 13)
    for index in 0..<24 {
      let angle = CGFloat(index) * 2.399
      let radius = CGFloat(26 + (index * 19) % 104)
      let px = cos(angle) * radius
      let py = -230 + sin(angle) * radius * 0.7
      oval(
        context, CGRect(x: px - 47, y: py - 37, width: 94, height: 77),
        [0x718348, 0x8F9B51, 0xA5AD63, 0xBDC27A][index % 4])
    }
    for index in 0..<16 {
      let px = CGFloat((index * 47) % 215 - 107)
      let py = CGFloat(-290 + (index * 37) % 143)
      oval(context, CGRect(x: px, y: py, width: 13, height: 15), 0xD8814B)
      oval(context, CGRect(x: px + 2, y: py + 1, width: 4, height: 5), 0xF5B871)
    }
    context.restoreGState()
  }

  static func fruit(_ kind: Fruit) -> SKTexture {
    texture(kind.rawValue, size: CGSize(width: 150, height: 166)) { context in
      let colors: (UInt32, UInt32)
      switch kind {
      case .apple: colors = (0xF68056, 0xBE4135)
      case .plum: colors = (0xA79DD3, 0x584877)
      case .pear: colors = (0xDCD66E, 0x8B9D43)
      }
      line(
        context, [CGPoint(x: 76, y: 34), CGPoint(x: 79, y: 14)],
        color: 0x675342, width: 7)
      let leaf = UIBezierPath()
      leaf.move(to: CGPoint(x: 78, y: 27))
      leaf.addQuadCurve(to: CGPoint(x: 115, y: 9), controlPoint: CGPoint(x: 82, y: -2))
      leaf.addQuadCurve(to: CGPoint(x: 78, y: 27), controlPoint: CGPoint(x: 113, y: 36))
      UIColor(hex: 0x426D44).setFill()
      leaf.fill()
      line(context, [CGPoint(x: 82, y: 24), CGPoint(x: 106, y: 14)], color: 0x88A966, width: 2)
      let body = UIBezierPath()
      if kind == .pear {
        body.move(to: CGPoint(x: 72, y: 28))
        body.addCurve(
          to: CGPoint(x: 141, y: 115), controlPoint1: CGPoint(x: 103, y: 18),
          controlPoint2: CGPoint(x: 98, y: 61))
        body.addCurve(
          to: CGPoint(x: 18, y: 126), controlPoint1: CGPoint(x: 161, y: 172),
          controlPoint2: CGPoint(x: -5, y: 175))
        body.addCurve(
          to: CGPoint(x: 72, y: 28), controlPoint1: CGPoint(x: 5, y: 87),
          controlPoint2: CGPoint(x: 49, y: 62))
      } else {
        body.move(to: CGPoint(x: 74, y: 40))
        body.addCurve(
          to: CGPoint(x: 139, y: 72), controlPoint1: CGPoint(x: 117, y: 14),
          controlPoint2: CGPoint(x: 142, y: 39))
        body.addCurve(
          to: CGPoint(x: 77, y: 155), controlPoint1: CGPoint(x: 156, y: 121),
          controlPoint2: CGPoint(x: 111, y: 168))
        body.addCurve(
          to: CGPoint(x: 13, y: 74), controlPoint1: CGPoint(x: 28, y: 166),
          controlPoint2: CGPoint(x: -2, y: 115))
        body.addCurve(
          to: CGPoint(x: 74, y: 40), controlPoint1: CGPoint(x: 9, y: 31),
          controlPoint2: CGPoint(x: 45, y: 24))
      }
      body.close()
      context.saveGState()
      body.addClip()
      gradient(
        context, rect: CGRect(x: 0, y: 25, width: 150, height: 140),
        top: colors.0, bottom: colors.1)
      for index in 0..<70 {
        oval(
          context,
          CGRect(
            x: (index * 47) % 150, y: 38 + (index * 29) % 120,
            width: 2, height: 2), 0xFFF5C8, alpha: 0.12)
      }
      oval(context, CGRect(x: 22, y: 45, width: 21, height: 42), 0xFFFFFF, alpha: 0.21)
      context.restoreGState()
      context.setStrokeColor(UIColor(hex: colors.1).cgColor)
      context.setLineWidth(2)
      context.addPath(body.cgPath)
      context.strokePath()
      for x in [53.0, 101.0] {
        oval(context, CGRect(x: x - 12, y: 83, width: 23, height: 27), 0xFFF7E1)
        oval(context, CGRect(x: x - 4, y: 91, width: 10, height: 13), 0x293B30)
        oval(context, CGRect(x: x - 2, y: 92, width: 3, height: 4), 0xFFFFFF)
      }
      line(context, [CGPoint(x: 43, y: 78), CGPoint(x: 58, y: 76)], color: 0x563D35, width: 4)
      line(context, [CGPoint(x: 94, y: 76), CGPoint(x: 109, y: 79)], color: 0x563D35, width: 4)
      oval(context, CGRect(x: 30, y: 110, width: 18, height: 8), 0xFFCF9A, alpha: 0.37)
      oval(context, CGRect(x: 111, y: 110, width: 18, height: 8), 0xFFCF9A, alpha: 0.37)
      let smile = UIBezierPath()
      smile.move(to: CGPoint(x: 67, y: 119))
      smile.addQuadCurve(to: CGPoint(x: 88, y: 119), controlPoint: CGPoint(x: 78, y: 136))
      smile.lineWidth = 3
      UIColor(hex: 0x4C392D).setStroke()
      smile.stroke()
    }
  }

  static func beetle() -> SKTexture {
    texture("beetle", size: CGSize(width: 120, height: 112)) { context in
      line(
        context, [CGPoint(x: 41, y: 29), CGPoint(x: 32, y: 11)],
        color: 0x314D43, width: 4)
      line(
        context, [CGPoint(x: 78, y: 28), CGPoint(x: 87, y: 10)],
        color: 0x314D43, width: 4)
      oval(context, CGRect(x: 26, y: 8, width: 9, height: 9), 0x486D56)
      oval(context, CGRect(x: 83, y: 7, width: 9, height: 9), 0x486D56)
      oval(context, CGRect(x: 9, y: 85, width: 100, height: 24), 0x314D43)
      context.saveGState()
      context.addEllipse(in: CGRect(x: 10, y: 23, width: 100, height: 78))
      context.clip()
      gradient(
        context, rect: CGRect(x: 10, y: 23, width: 100, height: 80),
        top: 0x92B99D, bottom: 0x416E60)
      line(context, [CGPoint(x: 63, y: 23), CGPoint(x: 63, y: 100)], color: 0x54856B, width: 3)
      for x in [23.0, 90.0] {
        oval(context, CGRect(x: x, y: 45, width: 10, height: 13), 0xC2C690, alpha: 0.55)
      }
      context.restoreGState()
      for x in [40.0, 77.0] {
        oval(context, CGRect(x: x - 11, y: 44, width: 25, height: 30), 0xFFF4D6)
        oval(context, CGRect(x: x - 1, y: 52, width: 10, height: 14), 0x273F35)
        oval(context, CGRect(x: x, y: 53, width: 3, height: 4), 0xFFFFFF)
      }
      oval(context, CGRect(x: 52, y: 78, width: 18, height: 10), 0x2D4F40)
    }
  }

  static func block(_ material: Material, size: CGSize) -> SKTexture {
    let key = "\(material.rawValue)-\(size.width)-\(size.height)"
    return texture(key, size: size) { context in
      let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
      let shape = UIBezierPath(roundedRect: rect, cornerRadius: material == .stone ? 5 : 3)
      context.saveGState()
      shape.addClip()
      let colors: (UInt32, UInt32)
      switch material {
      case .wood: colors = (0xD9A461, 0xA26C40)
      case .glass: colors = (0xD4EFDC, 0x84B6AE)
      case .stone: colors = (0xBBB8A8, 0x848D80)
      }
      gradient(context, rect: rect, top: colors.0, bottom: colors.1)
      if material == .wood {
        let horizontal = size.width > size.height
        for index in 0..<4 {
          let offset = CGFloat(index + 1) * (horizontal ? size.height : size.width) / 5
          line(
            context,
            horizontal
              ? [
                CGPoint(x: 7, y: offset), CGPoint(x: size.width * 0.4, y: offset + 2),
                CGPoint(x: size.width - 7, y: offset - 1),
              ]
              : [
                CGPoint(x: offset, y: 6), CGPoint(x: offset + 2, y: size.height * 0.4),
                CGPoint(x: offset - 1, y: size.height - 6),
              ],
            color: 0xB6804C, width: 1)
        }
        for point in [CGPoint(x: 7, y: 7), CGPoint(x: size.width - 7, y: size.height - 7)] {
          oval(
            context, CGRect(x: point.x - 1.5, y: point.y - 1.5, width: 3, height: 3),
            0x714C34)
        }
      } else if material == .glass {
        line(
          context,
          [
            CGPoint(x: 3, y: size.height * 0.65),
            CGPoint(x: size.width * 0.65, y: 3),
          ], color: 0xEDF8DF, width: 4)
        line(
          context,
          [
            CGPoint(x: size.width * 0.4, y: size.height - 2),
            CGPoint(x: size.width - 3, y: size.height * 0.35),
          ],
          color: 0xBEE0D1, width: 2)
      } else {
        for index in 0..<22 {
          oval(
            context,
            CGRect(
              x: CGFloat(index * 17).truncatingRemainder(dividingBy: size.width),
              y: CGFloat(index * 23).truncatingRemainder(dividingBy: size.height),
              width: 3, height: 2), 0x627563, alpha: 0.2)
        }
      }
      context.restoreGState()
      UIColor(hex: material == .wood ? 0x91663F : material == .glass ? 0x6E9B93 : 0x717D6B)
        .setStroke()
      shape.lineWidth = 2
      shape.stroke()
      line(
        context, [CGPoint(x: 4, y: 3), CGPoint(x: size.width - 4, y: 3)],
        color: material == .wood ? 0xF0C78A : 0xDFE7CE, width: 1)
    }
  }
}

extension UIColor {
  convenience init(hex: UInt32) {
    self.init(
      red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
      blue: CGFloat(hex & 255) / 255, alpha: 1)
  }
}
