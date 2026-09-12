import SpriteKit
import UIKit

enum OrchardArt {
  static let ink = UIColor(hex: 0x293E32)
  static var cache: [String: SKTexture] = [:]
  static var imageCache: [Fruit: UIImage] = [:]

  static func fruitImage(_ kind: Fruit) -> UIImage {
    if let cached = imageCache[kind] { return cached }
    let result = UIImage(cgImage: fruit(kind).cgImage())
    imageCache[kind] = result
    return result
  }

  static func image(size: CGSize, draw: (CGContext) -> Void) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 2
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

  static func fill(_ context: CGContext, _ path: UIBezierPath, _ color: UInt32, alpha: CGFloat = 1)
  {
    context.setFillColor(UIColor(hex: color).withAlphaComponent(alpha).cgColor)
    context.addPath(path.cgPath)
    context.fillPath()
  }

  static func line(
    _ context: CGContext, _ points: [CGPoint], color: UInt32, width: CGFloat, alpha: CGFloat = 1
  ) {
    guard let first = points.first else { return }
    context.setStrokeColor(UIColor(hex: color).withAlphaComponent(alpha).cgColor)
    context.setLineWidth(width)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.beginPath()
    context.move(to: first)
    for point in points.dropFirst() { context.addLine(to: point) }
    context.strokePath()
  }

  static func gradient(
    _ context: CGContext, rect: CGRect, stops: [(UInt32, CGFloat, CGFloat)], alpha: CGFloat = 1
  ) {
    let colors =
      stops.map { UIColor(hex: $0.0).withAlphaComponent($0.2 * alpha).cgColor } as CFArray
    guard
      let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
        locations: stops.map { $0.1 })
    else { return }
    context.saveGState()
    context.clip(to: rect)
    context.drawLinearGradient(
      gradient, start: CGPoint(x: rect.midX, y: rect.minY),
      end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
    context.restoreGState()
  }

  static func gradient(_ context: CGContext, rect: CGRect, top: UInt32, bottom: UInt32) {
    gradient(context, rect: rect, stops: [(top, 0, 1), (bottom, 1, 1)])
  }

  static func glow(
    _ context: CGContext, center: CGPoint, radius: CGFloat, color: UInt32, alpha: CGFloat,
    inner: CGFloat = 0
  ) {
    let tint = UIColor(hex: color)
    let colors =
      [tint.withAlphaComponent(alpha).cgColor, tint.withAlphaComponent(0).cgColor] as CFArray
    guard
      let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])
    else { return }
    context.drawRadialGradient(
      gradient, startCenter: center, startRadius: inner, endCenter: center, endRadius: radius,
      options: [])
  }

  static func hill(_ context: CGContext, baseY: CGFloat, peaks: [(CGFloat, CGFloat)], color: UInt32)
  {
    let path = UIBezierPath()
    path.move(to: CGPoint(x: -80, y: 700))
    path.addLine(to: CGPoint(x: -80, y: baseY))
    var previous = CGPoint(x: -80, y: baseY)
    for (x, y) in peaks {
      let point = CGPoint(x: x, y: baseY - y)
      let midX = (previous.x + point.x) / 2
      path.addCurve(
        to: point, controlPoint1: CGPoint(x: midX, y: previous.y),
        controlPoint2: CGPoint(x: midX, y: point.y))
      previous = point
    }
    path.addCurve(
      to: CGPoint(x: 1480, y: baseY), controlPoint1: CGPoint(x: previous.x + 90, y: previous.y),
      controlPoint2: CGPoint(x: 1400, y: baseY))
    path.addLine(to: CGPoint(x: 1480, y: 700))
    path.close()
    fill(context, path, color)
  }

  static func cloud(_ context: CGContext, x: CGFloat, y: CGFloat, scale: CGFloat) {
    let puffs: [(CGFloat, CGFloat, CGFloat)] = [
      (0, 0, 46), (44, -12, 58), (96, -4, 50), (140, 6, 38), (70, 14, 52), (22, 12, 40),
    ]
    for (dx, dy, size) in puffs {
      oval(
        context,
        CGRect(
          x: x + dx * scale, y: y + dy * scale + 6, width: size * scale, height: size * scale * 0.7),
        0xE8B8A6, alpha: 0.55)
    }
    for (dx, dy, size) in puffs {
      oval(
        context,
        CGRect(
          x: x + dx * scale, y: y + dy * scale, width: size * scale, height: size * scale * 0.7),
        0xFDF0DC, alpha: 0.92)
    }
  }

  static func background() -> SKTexture {
    texture("orchard", size: CGSize(width: 1400, height: 660)) { context in
      let canvas = CGRect(x: 0, y: 0, width: 1400, height: 660)
      gradient(
        context, rect: canvas,
        stops: [(0xC7A3B4, 0, 1), (0xE8BDA5, 0.28, 1), (0xF7D8AE, 0.55, 1), (0xFBE8C1, 0.8, 1)])
      glow(context, center: CGPoint(x: 1090, y: 262), radius: 420, color: 0xFFE7B0, alpha: 0.55)
      glow(context, center: CGPoint(x: 1090, y: 262), radius: 160, color: 0xFFF3CF, alpha: 0.75)
      for index in 0..<7 {
        let angle = CGFloat(index) * 0.46 + 2.7
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 1090, y: 262))
        path.addLine(
          to: CGPoint(x: 1090 + cos(angle - 0.05) * 700, y: 262 + sin(angle - 0.05) * 700))
        path.addLine(
          to: CGPoint(x: 1090 + cos(angle + 0.05) * 700, y: 262 + sin(angle + 0.05) * 700))
        path.close()
        fill(context, path, 0xFFF1CB, alpha: 0.09)
      }
      oval(context, CGRect(x: 1022, y: 194, width: 136, height: 136), 0xFFF7DE)
      oval(context, CGRect(x: 1028, y: 200, width: 124, height: 124), 0xFFFBEC)
      cloud(context, x: 120, y: 92, scale: 1.1)
      cloud(context, x: 520, y: 150, scale: 0.7)
      cloud(context, x: 860, y: 78, scale: 0.85)
      cloud(context, x: 1230, y: 160, scale: 0.6)
      for (x, y, size) in [
        (CGFloat(430), CGFloat(178), CGFloat(9)), (462, 166, 7), (486, 184, 6), (760, 126, 8),
        (788, 118, 6),
      ] {
        line(
          context,
          [
            CGPoint(x: x - size, y: y + size * 0.45), CGPoint(x: x, y: y),
            CGPoint(x: x + size, y: y + size * 0.45),
          ], color: 0x6B5563, width: 1.6, alpha: 0.6)
      }
      hill(
        context, baseY: 372,
        peaks: [(160, 30), (380, 74), (620, 40), (900, 96), (1180, 58), (1360, 78)],
        color: 0xC5B3B7)
      hill(
        context, baseY: 392,
        peaks: [(90, 22), (300, 48), (540, 26), (760, 70), (1010, 44), (1290, 60)],
        color: 0xADB59B)
      for index in 0..<30 {
        let x = CGFloat((index * 131 + 17) % 1450) - 20
        let y = CGFloat(352 + (index * 37) % 26)
        let radius = CGFloat(11 + (index * 7) % 9)
        oval(
          context, CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2.1),
          0x9CA88A, alpha: 0.9)
      }
      hill(
        context, baseY: 428,
        peaks: [(200, 36), (470, 20), (700, 52), (960, 34), (1200, 48)],
        color: 0x93A96F)
      for index in 0..<26 {
        let x = CGFloat((index * 97 + 41) % 1440) - 20
        let y = CGFloat(392 + (index * 53) % 20)
        let radius = CGFloat(15 + (index * 11) % 12)
        line(
          context, [CGPoint(x: x, y: y + radius + 12), CGPoint(x: x, y: y)],
          color: 0x5C6B44, width: 4)
        oval(
          context, CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2),
          index % 2 == 0 ? 0x7F9A5C : 0x8DA666)
        oval(
          context,
          CGRect(x: x - radius * 0.6, y: y - radius * 0.95, width: radius * 1.1, height: radius),
          0xA8BC72, alpha: 0.8)
      }
      gradient(
        context, rect: CGRect(x: 0, y: 418, width: 1400, height: 110),
        stops: [(0xB4C270, 0, 1), (0x9DB160, 0.5, 1), (0x86A054, 1, 1)])
      for index in 0..<11 {
        let x = CGFloat((index * 263 + 63) % 1420) - 30
        let y = CGFloat(420 + (index * 29) % 18)
        let radius = CGFloat(22 + (index * 13) % 16)
        let dark = index % 3 == 0
        oval(
          context,
          CGRect(
            x: x - radius * 2.6, y: y + radius * 0.75, width: radius * 3.3, height: radius * 0.55),
          0x3E5A2E, alpha: 0.16)
        line(
          context, [CGPoint(x: x, y: y + radius * 1.35), CGPoint(x: x + 3, y: y - radius * 0.2)],
          color: 0x5F4A36, width: 6)
        oval(
          context, CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 1.9),
          dark ? 0x5E7E44 : 0x6E8E4C)
        oval(
          context,
          CGRect(
            x: x - radius * 0.85, y: y - radius * 0.9, width: radius * 1.3, height: radius * 1.2),
          dark ? 0x7B9A56 : 0x8CAA60)
        oval(
          context,
          CGRect(
            x: x - radius * 0.35, y: y - radius * 0.85, width: radius * 0.9, height: radius * 0.7),
          0xB2C46D, alpha: 0.85)
        for fruitIndex in 0..<5 {
          let px = x - radius * 0.7 + CGFloat((fruitIndex * 37) % Int(radius * 1.4))
          let py = y - radius * 0.5 + CGFloat((fruitIndex * 23) % Int(radius))
          oval(context, CGRect(x: px, y: py, width: 6, height: 6), 0xE07A55)
          oval(context, CGRect(x: px + 1, y: py + 1, width: 2, height: 2), 0xFFD2A6)
        }
      }
      for index in 0..<29 {
        let x = CGFloat(index * 50 - 12)
        let top = CGFloat(452 + (index % 4 == 0 ? 0 : 5))
        let post = UIBezierPath()
        post.move(to: CGPoint(x: x - 5, y: 520))
        post.addLine(to: CGPoint(x: x - 5, y: top + 6))
        post.addLine(to: CGPoint(x: x, y: top))
        post.addLine(to: CGPoint(x: x + 5, y: top + 6))
        post.addLine(to: CGPoint(x: x + 5, y: 520))
        post.close()
        fill(context, post, 0xEEDDB4)
        line(
          context, [CGPoint(x: x + 3, y: top + 9), CGPoint(x: x + 3, y: 518)], color: 0xC7AE7E,
          width: 3)
      }
      for y in [CGFloat(470), 494] {
        context.setFillColor(UIColor(hex: 0xE6D2A6).cgColor)
        context.fill(CGRect(x: 0, y: y, width: 1400, height: 7))
        context.setFillColor(UIColor(hex: 0xC4A876).cgColor)
        context.fill(CGRect(x: 0, y: y + 6, width: 1400, height: 2))
      }
      tree(context, x: 60, y: 528, scale: 1.35)
      tree(context, x: 1372, y: 530, scale: 1.15)
      gradient(
        context, rect: CGRect(x: 0, y: 522, width: 1400, height: 140),
        stops: [(0xB58058, 0, 1), (0x9A6B4B, 0.35, 1), (0x6E4B3A, 1, 1)])
      context.setFillColor(UIColor(hex: 0xC99566).withAlphaComponent(0.35).cgColor)
      context.fill(CGRect(x: 0, y: 548, width: 1400, height: 22))
      for index in 0..<900 {
        let x = CGFloat((index * 137 + 43) % 1400)
        let y = CGFloat(536 + (index * 71) % 124)
        oval(
          context,
          CGRect(x: x, y: y, width: index % 5 == 0 ? 5 : 2.5, height: index % 5 == 0 ? 3 : 2),
          index % 2 == 0 ? 0xE9BE8A : 0x4A3A2E, alpha: index % 5 == 0 ? 0.35 : 0.2)
      }
      for index in 0..<7 {
        let x = CGFloat((index * 211 + 90) % 1400)
        let rock = UIBezierPath(
          roundedRect: CGRect(x: x, y: 560 + CGFloat(index % 3) * 26, width: 14, height: 8),
          cornerRadius: 4)
        fill(context, rock, 0xC4B29A, alpha: 0.7)
        fill(
          context,
          UIBezierPath(
            roundedRect: CGRect(x: x + 2, y: 561 + CGFloat(index % 3) * 26, width: 7, height: 3),
            cornerRadius: 2), 0xF0E5D2, alpha: 0.6)
      }
      context.setFillColor(UIColor(hex: 0x4F6B3A).cgColor)
      context.fill(CGRect(x: 0, y: 518, width: 1400, height: 9))
      context.setFillColor(UIColor(hex: 0x9FB55C).cgColor)
      context.fill(CGRect(x: 0, y: 517, width: 1400, height: 4))
      for index in 0..<160 {
        let x = CGFloat((index * 89 + 7) % 1400)
        let height = CGFloat(8 + (index * 13) % 9)
        line(
          context,
          [
            CGPoint(x: x, y: 526), CGPoint(x: x - 3, y: 522 - height),
          ], color: index % 2 == 0 ? 0x8CA64E : 0xB5C662, width: 2)
        line(
          context,
          [
            CGPoint(x: x + 3, y: 526), CGPoint(x: x + 6, y: 524 - height * 0.8),
          ], color: 0x6F8B45, width: 2)
      }
      for index in 0..<26 {
        let x = CGFloat((index * 157 + 31) % 1400)
        let y = CGFloat(506 + (index % 3) * 4)
        line(
          context, [CGPoint(x: x, y: 522), CGPoint(x: x, y: y + 4)], color: 0x6F8B45, width: 1.5)
        oval(
          context, CGRect(x: x - 3.5, y: y, width: 7, height: 7),
          [0xE0705A, 0xFFF1D6, 0xF2B85E][index % 3])
        oval(context, CGRect(x: x - 1, y: y + 2.5, width: 2, height: 2), 0x6B4A2C, alpha: 0.6)
      }
      for (x, y, radius) in [
        (CGFloat(360), CGFloat(470), CGFloat(140)), (760, 520, 180), (1180, 480, 120),
      ] {
        glow(context, center: CGPoint(x: x, y: y), radius: radius, color: 0xFFE8A8, alpha: 0.13)
      }
      let vignette = UIColor(hex: 0x5A3A2A)
      let colors =
        [vignette.withAlphaComponent(0).cgColor, vignette.withAlphaComponent(0.2).cgColor]
        as CFArray
      if let shade = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.55, 1])
      {
        context.drawRadialGradient(
          shade, startCenter: CGPoint(x: 700, y: 330), startRadius: 0,
          endCenter: CGPoint(x: 700, y: 330), endRadius: 880, options: [.drawsAfterEndLocation])
      }
    }
  }

  static func tree(_ context: CGContext, x: CGFloat, y: CGFloat, scale: CGFloat) {
    context.saveGState()
    context.translateBy(x: x, y: y)
    context.scaleBy(x: scale, y: scale)
    oval(context, CGRect(x: -180, y: -12, width: 230, height: 26), 0x3E5A2E, alpha: 0.18)
    let trunk = UIBezierPath()
    trunk.move(to: CGPoint(x: -20, y: 2))
    trunk.addCurve(
      to: CGPoint(x: -6, y: -170), controlPoint1: CGPoint(x: -12, y: -60),
      controlPoint2: CGPoint(x: -16, y: -120))
    trunk.addLine(to: CGPoint(x: 26, y: -250))
    trunk.addLine(to: CGPoint(x: 38, y: -244))
    trunk.addCurve(
      to: CGPoint(x: 22, y: 2), controlPoint1: CGPoint(x: 14, y: -160),
      controlPoint2: CGPoint(x: 16, y: -60))
    trunk.close()
    fill(context, trunk, 0x6B5340)
    line(context, [CGPoint(x: 6, y: -20), CGPoint(x: 2, y: -160)], color: 0x8A6E52, width: 5)
    line(context, [CGPoint(x: -8, y: -110), CGPoint(x: -70, y: -206)], color: 0x6B5340, width: 14)
    line(context, [CGPoint(x: 4, y: -140), CGPoint(x: 60, y: -200)], color: 0x6B5340, width: 11)
    for (dx, dy, radius, color) in [
      (CGFloat(0), CGFloat(-240), CGFloat(108), UInt32(0x516F3E)),
      (-80, -210, 78, 0x5A7A43), (84, -218, 74, 0x5A7A43), (-30, -300, 70, 0x6E8C4C),
      (48, -296, 66, 0x6E8C4C), (-98, -260, 52, 0x6E8C4C), (100, -270, 50, 0x6E8C4C),
      (0, -290, 60, 0x88A25A), (-56, -250, 48, 0x88A25A), (60, -246, 46, 0x88A25A),
      (10, -330, 40, 0xA6B96A), (-70, -300, 32, 0xA6B96A), (66, -304, 30, 0xA6B96A),
    ] {
      oval(
        context,
        CGRect(x: dx - radius, y: dy - radius * 0.86, width: radius * 2, height: radius * 1.72),
        color)
    }
    for index in 0..<18 {
      let px = CGFloat((index * 53) % 220 - 110)
      let py = CGFloat(-330 + (index * 41) % 170)
      oval(context, CGRect(x: px + 2, y: py + 3, width: 15, height: 16), 0x3E5A2E, alpha: 0.25)
      oval(context, CGRect(x: px, y: py, width: 15, height: 16), 0xDD7B52)
      oval(context, CGRect(x: px + 3, y: py + 2, width: 5, height: 5), 0xFFC896)
    }
    context.restoreGState()
  }

  static func fruit(_ kind: Fruit) -> SKTexture {
    texture(kind.rawValue, size: CGSize(width: 150, height: 166)) { context in
      let colors: (UInt32, UInt32, UInt32)
      switch kind {
      case .apple: colors = (0xFF9A66, 0xE0553E, 0x9E2F2B)
      case .plum: colors = (0xB6A6DF, 0x7B67A6, 0x473763)
      case .pear: colors = (0xE9E27E, 0xB8C25A, 0x77893C)
      }
      line(context, [CGPoint(x: 76, y: 36), CGPoint(x: 80, y: 12)], color: 0x5C4436, width: 8)
      line(context, [CGPoint(x: 78, y: 32), CGPoint(x: 81, y: 14)], color: 0x86694F, width: 3)
      let leaf = UIBezierPath()
      leaf.move(to: CGPoint(x: 80, y: 27))
      leaf.addQuadCurve(to: CGPoint(x: 122, y: 8), controlPoint: CGPoint(x: 84, y: -4))
      leaf.addQuadCurve(to: CGPoint(x: 80, y: 27), controlPoint: CGPoint(x: 120, y: 38))
      context.saveGState()
      context.addPath(leaf.cgPath)
      context.clip()
      gradient(
        context, rect: CGRect(x: 78, y: 0, width: 46, height: 40), top: 0x8FB35E, bottom: 0x3E6B3D)
      context.restoreGState()
      line(context, [CGPoint(x: 84, y: 25), CGPoint(x: 114, y: 13)], color: 0xC7DDA0, width: 1.6)
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
        context, rect: CGRect(x: 0, y: 20, width: 150, height: 146),
        stops: [(colors.0, 0, 1), (colors.1, 0.55, 1), (colors.2, 1, 1)])
      glow(context, center: CGPoint(x: 48, y: 62), radius: 70, color: colors.0, alpha: 0.9)
      glow(context, center: CGPoint(x: 90, y: 150), radius: 80, color: colors.2, alpha: 0.55)
      glow(context, center: CGPoint(x: 135, y: 80), radius: 40, color: 0xFFE7C0, alpha: 0.35)
      for index in 0..<90 {
        oval(
          context,
          CGRect(x: (index * 47) % 150, y: 30 + (index * 29) % 130, width: 2, height: 2),
          0xFFF5C8, alpha: 0.12)
      }
      context.saveGState()
      context.translateBy(x: 33, y: 64)
      context.rotate(by: 0.3)
      fill(
        context,
        UIBezierPath(roundedRect: CGRect(x: -9, y: -20, width: 18, height: 40), cornerRadius: 9),
        0xFFFFFF, alpha: 0.32)
      context.restoreGState()
      oval(context, CGRect(x: 46, y: 36, width: 8, height: 8), 0xFFFFFF, alpha: 0.28)
      context.restoreGState()
      context.setStrokeColor(UIColor(hex: colors.2).withAlphaComponent(0.7).cgColor)
      context.setLineWidth(2.5)
      context.addPath(body.cgPath)
      context.strokePath()
      for x in [53.0, 101.0] {
        oval(context, CGRect(x: x - 13, y: 82, width: 25, height: 29), 0x8E3F35, alpha: 0.18)
        oval(context, CGRect(x: x - 12, y: 81, width: 23, height: 27), 0xFFF9EA)
        oval(context, CGRect(x: x - 4, y: 88, width: 11, height: 14), 0x263A2F)
        oval(context, CGRect(x: x - 2, y: 89, width: 4, height: 5), 0xFFFFFF)
        oval(context, CGRect(x: x, y: 97, width: 2, height: 2), 0xFFFFFF, alpha: 0.7)
      }
      switch kind {
      case .apple:
        line(context, [CGPoint(x: 42, y: 74), CGPoint(x: 60, y: 70)], color: 0x4C2F2A, width: 4)
        line(context, [CGPoint(x: 94, y: 70), CGPoint(x: 112, y: 74)], color: 0x4C2F2A, width: 4)
      case .plum:
        line(context, [CGPoint(x: 42, y: 78), CGPoint(x: 60, y: 72)], color: 0x2F2440, width: 4)
        line(context, [CGPoint(x: 94, y: 64), CGPoint(x: 112, y: 70)], color: 0x2F2440, width: 4)
      case .pear:
        line(context, [CGPoint(x: 44, y: 72), CGPoint(x: 60, y: 74)], color: 0x4A4A28, width: 4)
        line(context, [CGPoint(x: 94, y: 74), CGPoint(x: 110, y: 72)], color: 0x4A4A28, width: 4)
      }
      oval(context, CGRect(x: 28, y: 108, width: 20, height: 9), 0xFFB08C, alpha: 0.45)
      oval(context, CGRect(x: 106, y: 108, width: 20, height: 9), 0xFFB08C, alpha: 0.45)
      let smile = UIBezierPath()
      smile.move(to: CGPoint(x: 66, y: 118))
      smile.addQuadCurve(to: CGPoint(x: 90, y: 118), controlPoint: CGPoint(x: 78, y: 136))
      smile.lineWidth = 3.4
      smile.lineCapStyle = .round
      UIColor(hex: 0x3D2A26).setStroke()
      smile.stroke()
    }
  }

  static func beetle() -> SKTexture {
    texture("beetle", size: CGSize(width: 120, height: 112)) { context in
      for (from, to) in [
        (CGPoint(x: 42, y: 30), CGPoint(x: 30, y: 8)),
        (CGPoint(x: 78, y: 30), CGPoint(x: 90, y: 8)),
      ] {
        line(context, [from, to], color: 0x2E4A40, width: 3.5)
        oval(context, CGRect(x: to.x - 5, y: to.y - 5, width: 10, height: 10), 0x2E4A40)
        oval(context, CGRect(x: to.x - 3, y: to.y - 3, width: 4, height: 4), 0x8EC0A2)
      }
      for index in 0..<3 {
        let y = CGFloat(66 + index * 12)
        line(
          context, [CGPoint(x: 18, y: y), CGPoint(x: 4, y: y + 14)], color: 0x2E4A40, width: 3.5)
        line(
          context, [CGPoint(x: 102, y: y), CGPoint(x: 116, y: y + 14)], color: 0x2E4A40, width: 3.5)
      }
      oval(context, CGRect(x: 12, y: 92, width: 96, height: 16), 0x1F3A30, alpha: 0.35)
      let shell = UIBezierPath(ovalIn: CGRect(x: 10, y: 22, width: 100, height: 80))
      context.saveGState()
      context.addPath(shell.cgPath)
      context.clip()
      gradient(
        context, rect: CGRect(x: 10, y: 22, width: 100, height: 80),
        stops: [(0x9CC7A3, 0, 1), (0x5E9377, 0.5, 1), (0x2F5D50, 1, 1)])
      glow(context, center: CGPoint(x: 40, y: 40), radius: 40, color: 0xD6F0D2, alpha: 0.5)
      context.setFillColor(UIColor(hex: 0x27443C).cgColor)
      context.fill(CGRect(x: 10, y: 22, width: 100, height: 26))
      line(context, [CGPoint(x: 60, y: 48), CGPoint(x: 60, y: 102)], color: 0x2F5D50, width: 3)
      for (x, y) in [(28.0, 62.0), (84.0, 58.0), (40.0, 84.0), (76.0, 86.0)] {
        oval(context, CGRect(x: x, y: y, width: 10, height: 12), 0x22463C, alpha: 0.55)
      }
      context.restoreGState()
      context.setStrokeColor(UIColor(hex: 0x1F3A30).cgColor)
      context.setLineWidth(2.5)
      context.addPath(shell.cgPath)
      context.strokePath()
      for x in [42.0, 78.0] {
        oval(context, CGRect(x: x - 12, y: 26, width: 26, height: 30), 0xFFF6DC)
        oval(context, CGRect(x: x - 2, y: 36, width: 11, height: 14), 0x1E2F29)
        oval(context, CGRect(x: x, y: 38, width: 4, height: 4), 0xFFFFFF)
      }
      line(context, [CGPoint(x: 34, y: 22), CGPoint(x: 50, y: 26)], color: 0x1E2F29, width: 3)
      line(context, [CGPoint(x: 86, y: 22), CGPoint(x: 70, y: 26)], color: 0x1E2F29, width: 3)
      let grin = UIBezierPath()
      grin.move(to: CGPoint(x: 48, y: 64))
      grin.addQuadCurve(to: CGPoint(x: 72, y: 64), controlPoint: CGPoint(x: 60, y: 76))
      grin.lineWidth = 3
      grin.lineCapStyle = .round
      UIColor(hex: 0x1E2F29).setStroke()
      grin.stroke()
      for x in [53.0, 62.0] {
        context.setFillColor(UIColor(hex: 0xFFF6DC).cgColor)
        context.fill(CGRect(x: x, y: 65, width: 5, height: 5))
      }
    }
  }

  static func leaf() -> SKTexture {
    texture("leaf", size: CGSize(width: 28, height: 16)) { context in
      let path = UIBezierPath()
      path.move(to: CGPoint(x: 1, y: 8))
      path.addQuadCurve(to: CGPoint(x: 27, y: 8), controlPoint: CGPoint(x: 14, y: -6))
      path.addQuadCurve(to: CGPoint(x: 1, y: 8), controlPoint: CGPoint(x: 14, y: 22))
      context.saveGState()
      context.addPath(path.cgPath)
      context.clip()
      gradient(
        context, rect: CGRect(x: 0, y: 0, width: 28, height: 16), top: 0xE9B95A, bottom: 0xC97F3D)
      context.restoreGState()
      line(context, [CGPoint(x: 3, y: 8), CGPoint(x: 25, y: 8)], color: 0xFFE3A6, width: 1)
    }
  }

  static func sling() -> SKTexture {
    texture("sling", size: CGSize(width: 70, height: 110)) { context in
      let branch = UIBezierPath()
      branch.move(to: CGPoint(x: 26, y: 110))
      branch.addCurve(
        to: CGPoint(x: 4, y: 8), controlPoint1: CGPoint(x: 28, y: 70),
        controlPoint2: CGPoint(x: 12, y: 40))
      branch.addLine(to: CGPoint(x: 18, y: 2))
      branch.addCurve(
        to: CGPoint(x: 35, y: 44), controlPoint1: CGPoint(x: 26, y: 20),
        controlPoint2: CGPoint(x: 32, y: 34))
      branch.addCurve(
        to: CGPoint(x: 52, y: 2), controlPoint1: CGPoint(x: 38, y: 34),
        controlPoint2: CGPoint(x: 44, y: 20))
      branch.addLine(to: CGPoint(x: 66, y: 8))
      branch.addCurve(
        to: CGPoint(x: 46, y: 110), controlPoint1: CGPoint(x: 58, y: 40),
        controlPoint2: CGPoint(x: 44, y: 70))
      branch.close()
      context.saveGState()
      context.addPath(branch.cgPath)
      context.clip()
      gradient(
        context, rect: CGRect(x: 0, y: 0, width: 70, height: 110),
        stops: [(0x8E6647, 0, 1), (0x6E4B35, 0.6, 1), (0x4E3526, 1, 1)])
      line(context, [CGPoint(x: 30, y: 100), CGPoint(x: 31, y: 50)], color: 0xA8805B, width: 3)
      line(context, [CGPoint(x: 28, y: 48), CGPoint(x: 14, y: 14)], color: 0xA8805B, width: 2)
      line(context, [CGPoint(x: 42, y: 48), CGPoint(x: 56, y: 14)], color: 0xA8805B, width: 2)
      line(context, [CGPoint(x: 38, y: 104), CGPoint(x: 40, y: 60)], color: 0x3B281C, width: 2)
      context.restoreGState()
      context.setStrokeColor(UIColor(hex: 0x3B281C).cgColor)
      context.setLineWidth(2)
      context.addPath(branch.cgPath)
      context.strokePath()
      for x in [CGFloat(11), 59] {
        for index in 0..<3 {
          line(
            context,
            [
              CGPoint(x: x - 5.5, y: 8 + CGFloat(index) * 3.5),
              CGPoint(x: x + 5.5, y: 9.5 + CGFloat(index) * 3.5),
            ],
            color: index % 2 == 0 ? 0xB8463A : 0x963A31, width: 2.5)
        }
      }
    }
  }

  static func block(_ material: Material, size: CGSize) -> SKTexture {
    let key = "\(material.rawValue)-\(size.width)-\(size.height)"
    return texture(key, size: size) { context in
      let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
      let radius: CGFloat = material == .stone ? 6 : material == .glass ? 2 : 3
      let shape = UIBezierPath(roundedRect: rect, cornerRadius: radius)
      context.saveGState()
      shape.addClip()
      let horizontal = size.width > size.height
      switch material {
      case .wood:
        gradient(
          context, rect: rect,
          stops: [(0xE3B074, 0, 1), (0xC98F55, 0.55, 1), (0xA36B40, 1, 1)])
        let planks = horizontal ? Int(size.height / 15) : Int(size.width / 15)
        for index in 0..<max(3, planks * 2) {
          let along = CGFloat(index + 1) / CGFloat(max(3, planks * 2) + 1)
          let offset = (horizontal ? size.height : size.width) * along
          let wobble = CGFloat(index % 2 == 0 ? 2 : -2)
          line(
            context,
            horizontal
              ? [
                CGPoint(x: 6, y: offset), CGPoint(x: size.width * 0.35, y: offset + wobble),
                CGPoint(x: size.width * 0.7, y: offset - wobble),
                CGPoint(x: size.width - 6, y: offset),
              ]
              : [
                CGPoint(x: offset, y: 6), CGPoint(x: offset + wobble, y: size.height * 0.35),
                CGPoint(x: offset - wobble, y: size.height * 0.7),
                CGPoint(x: offset, y: size.height - 6),
              ],
            color: 0x9A6A3F, width: 1.2, alpha: 0.7)
        }
        let knot = CGPoint(x: size.width * 0.68, y: size.height * 0.42)
        oval(
          context, CGRect(x: knot.x - 5, y: knot.y - 4, width: 10, height: 8), 0x8B5A34, alpha: 0.6)
        oval(context, CGRect(x: knot.x - 2, y: knot.y - 1.5, width: 4, height: 3), 0xB07C4E)
        gradient(
          context, rect: CGRect(x: 0, y: 0, width: size.width, height: 5),
          stops: [(0xFFE0A8, 0, 0.8), (0xFFE0A8, 1, 0)])
        gradient(
          context, rect: CGRect(x: 0, y: size.height - 7, width: size.width, height: 7),
          stops: [(0x5B3A22, 0, 0), (0x5B3A22, 1, 0.55)])
        for point in [CGPoint(x: 8, y: 8), CGPoint(x: size.width - 8, y: size.height - 8)] {
          oval(context, CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4), 0x4E3220)
          oval(context, CGRect(x: point.x - 1.5, y: point.y - 1.5, width: 2, height: 2), 0x8A6A4C)
        }
      case .glass:
        gradient(
          context, rect: rect,
          stops: [(0xE6F7EC, 0, 1), (0xA8D6CF, 0.5, 1), (0x6FA9A6, 1, 1)])
        let shine = UIBezierPath()
        shine.move(to: CGPoint(x: 2, y: size.height * 0.8))
        shine.addLine(to: CGPoint(x: size.width * 0.75, y: 2))
        shine.addLine(to: CGPoint(x: size.width * 0.95, y: 2))
        shine.addLine(to: CGPoint(x: 2, y: size.height))
        shine.close()
        fill(context, shine, 0xFFFFFF, alpha: 0.35)
        line(
          context,
          [
            CGPoint(x: size.width * 0.3, y: size.height - 3),
            CGPoint(x: size.width - 3, y: size.height * 0.3),
          ],
          color: 0xFFFFFF, width: 2, alpha: 0.5)
        context.setStrokeColor(UIColor(hex: 0xFFFFFF).withAlphaComponent(0.7).cgColor)
        context.setLineWidth(1.5)
        context.addPath(
          UIBezierPath(roundedRect: rect.insetBy(dx: 3, dy: 3), cornerRadius: 1).cgPath)
        context.strokePath()
      case .stone:
        gradient(
          context, rect: rect,
          stops: [(0xCFCBBC, 0, 1), (0xA9A897, 0.5, 1), (0x7C8377, 1, 1)])
        for index in 0..<Int(size.width * size.height / 120) {
          let x = CGFloat((index * 37) % Int(size.width))
          let y = CGFloat((index * 53) % Int(size.height))
          oval(
            context, CGRect(x: x, y: y, width: 3 + CGFloat(index % 3), height: 2),
            index % 2 == 0 ? 0x5F6B5E : 0xE8E4D4, alpha: 0.28)
        }
        line(
          context,
          [
            CGPoint(x: size.width * 0.15, y: size.height * 0.2),
            CGPoint(x: size.width * 0.32, y: size.height * 0.55),
            CGPoint(x: size.width * 0.28, y: size.height * 0.8),
          ], color: 0x5F6B5E, width: 1.2, alpha: 0.5)
        gradient(
          context, rect: CGRect(x: 0, y: 0, width: size.width, height: 6),
          stops: [(0xF3EFE2, 0, 0.7), (0xF3EFE2, 1, 0)])
        gradient(
          context, rect: CGRect(x: 0, y: size.height - 8, width: size.width, height: 8),
          stops: [(0x3F4A44, 0, 0), (0x3F4A44, 1, 0.5)])
      }
      context.restoreGState()
      UIColor(hex: material == .wood ? 0x6E4728 : material == .glass ? 0x5D9590 : 0x5A655C)
        .setStroke()
      shape.lineWidth = 2
      shape.stroke()
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
