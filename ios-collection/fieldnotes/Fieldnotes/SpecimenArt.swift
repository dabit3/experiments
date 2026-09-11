import SwiftUI

enum FieldStyle {
  static let paper = Color(red: 0.96, green: 0.94, blue: 0.88)
  static let ink = Color(red: 0.20, green: 0.25, blue: 0.17)
  static let muted = Color(red: 0.39, green: 0.42, blue: 0.33)
  static let rust = Color(red: 0.65, green: 0.26, blue: 0.13)
  static let rule = Color(red: 0.77, green: 0.77, blue: 0.67)
  static let wash = Color(red: 0.90, green: 0.90, blue: 0.80)
  static func serif(_ size: CGFloat) -> Font { .system(size: size, design: .serif) }
}

struct Paper: View {
  var body: some View {
    FieldStyle.paper.overlay {
      Canvas { context, size in
        for index in 0..<1600 {
          let x = CGFloat((index * 73) % 991) / 991 * size.width
          let y = CGFloat((index * 193) % 997) / 997 * size.height
          context.fill(
            Path(ellipseIn: CGRect(x: x, y: y, width: 0.8, height: 0.8)),
            with: .color(FieldStyle.ink.opacity(0.07)))
        }
      }.allowsHitTesting(false).accessibilityHidden(true)
    }.ignoresSafeArea()
  }
}

struct SpecimenArt: View {
  var kind: String
  var body: some View {
    Canvas { raw, size in
      var c = raw
      let scale = min(size.width / 320, size.height / 300)
      c.translateBy(x: (size.width - 320 * scale) / 2, y: (size.height - 300 * scale) / 2)
      c.scaleBy(x: scale, y: scale)
      switch kind {
      case "robin", "tit": bird(&c, tit: kind == "tit")
      case "butterfly": butterfly(&c)
      case "ladybird": ladybird(&c)
      case "snail": snail(&c)
      case "mushroom", "turkey": fungi(&c, bracket: kind == "turkey")
      case "daisy", "dandelion", "clover": flower(&c, kind: kind)
      default: foliage(&c, oak: kind == "oak")
      }
    }.accessibilityHidden(true)
  }

  private func line(
    _ c: inout GraphicsContext, _ points: [CGPoint], color: Color = FieldStyle.ink,
    width: CGFloat = 1
  ) {
    var path = Path()
    path.addLines(points)
    c.stroke(
      path, with: .color(color),
      style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
  }

  private func ellipse(_ c: inout GraphicsContext, _ rect: CGRect, _ color: Color) {
    c.fill(Path(ellipseIn: rect), with: .color(color))
  }

  private func leaf(
    _ c: inout GraphicsContext, from a: CGPoint, to b: CGPoint, width: CGFloat, shade: Double
  ) {
    let dx = b.x - a.x
    let dy = b.y - a.y
    let distance = max(1, hypot(dx, dy))
    let normal = CGPoint(x: -dy / distance * width, y: dx / distance * width)
    let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    var p = Path()
    p.move(to: a)
    p.addQuadCurve(to: b, control: CGPoint(x: mid.x + normal.x, y: mid.y + normal.y))
    p.addQuadCurve(to: a, control: CGPoint(x: mid.x - normal.x, y: mid.y - normal.y))
    c.fill(p, with: .color(Color(red: 0.29 + shade, green: 0.39 + shade, blue: 0.21 + shade)))
    c.stroke(p, with: .color(FieldStyle.ink.opacity(0.65)), lineWidth: 0.6)
    line(&c, [a, b], color: FieldStyle.paper.opacity(0.65), width: 0.6)
    for i in 1...5 {
      let t = CGFloat(i) / 7
      let start = CGPoint(x: a.x + dx * t, y: a.y + dy * t)
      for side in [-1.0, 1.0] {
        line(
          &c,
          [
            start,
            CGPoint(
              x: start.x + dx * 0.13 + normal.x * side * 0.34,
              y: start.y + dy * 0.13 + normal.y * side * 0.34),
          ], color: FieldStyle.paper.opacity(0.38), width: 0.5)
      }
    }
  }

  private func foliage(_ c: inout GraphicsContext, oak: Bool) {
    for stalk in 0..<3 {
      var f = c
      f.translateBy(x: 160, y: 277)
      f.rotate(by: .degrees(Double(stalk - 1) * 28))
      line(&f, [.zero, CGPoint(x: 0, y: -246)], width: 1.8)
      let count = oak ? 6 : 17
      for i in 0..<count {
        let t = CGFloat(i) / CGFloat(count)
        let y = -24 - t * 208
        let length = (1 - t) * (oak ? 68 : 75) + 7
        for side in [-1.0, 1.0] {
          leaf(
            &f, from: CGPoint(x: 0, y: y), to: CGPoint(x: side * length, y: y - (oak ? 30 : 24)),
            width: oak ? 30 : 12 - 6 * t, shade: Double(stalk) * 0.035 + Double(i % 3) * 0.025)
        }
      }
    }
  }

  private func flower(_ c: inout GraphicsContext, kind: String) {
    for i in 0..<3 {
      let x = CGFloat(95 + i * 66)
      let y = CGFloat(i == 1 ? 65 : 116)
      line(&c, [CGPoint(x: 151, y: 280), CGPoint(x: x, y: y)], color: FieldStyle.muted, width: 2)
      leaf(
        &c, from: CGPoint(x: x + (151 - x) * 0.55, y: y + (280 - y) * 0.55),
        to: CGPoint(x: x + (i == 0 ? -38 : 46), y: 174), width: 23, shade: 0.04)
      let petals = kind == "clover" ? 24 : (kind == "dandelion" ? 42 : 16)
      for p in 0..<petals {
        var f = c
        f.translateBy(x: x, y: y)
        f.rotate(by: .degrees(Double(p) * 360 / Double(petals)))
        let color =
          kind == "daisy"
          ? Color(red: 1, green: 0.99, blue: 0.94)
          : (kind == "clover"
            ? Color(red: 0.68, green: 0.39, blue: 0.49) : Color(red: 0.88, green: 0.65, blue: 0.16))
        let rect = CGRect(x: -5, y: -39, width: 10, height: 32)
        ellipse(&f, rect, color)
        f.stroke(Path(ellipseIn: rect), with: .color(FieldStyle.ink.opacity(0.18)), lineWidth: 0.7)
      }
      ellipse(
        &c, CGRect(x: x - 12, y: y - 12, width: 24, height: 24),
        kind == "clover" ? FieldStyle.rust.opacity(0.7) : Color(red: 0.76, green: 0.52, blue: 0.13))
      for dot in 0..<32 {
        let angle = Double(dot) * 2.4
        let radius = sqrt(Double(dot)) * 1.7
        ellipse(
          &c,
          CGRect(
            x: x + cos(angle) * radius - 1, y: y + sin(angle) * radius - 1, width: 2, height: 2),
          FieldStyle.paper.opacity(0.5))
      }
    }
  }

  private func bird(_ c: inout GraphicsContext, tit: Bool) {
    line(
      &c, [CGPoint(x: 30, y: 247), CGPoint(x: 295, y: 227)], color: .brown.opacity(0.7), width: 5)
    leaf(&c, from: CGPoint(x: 65, y: 242), to: CGPoint(x: 26, y: 203), width: 15, shade: 0.1)
    var tail = Path()
    tail.addLines([
      CGPoint(x: 117, y: 176), CGPoint(x: 42, y: 216), CGPoint(x: 58, y: 224),
      CGPoint(x: 162, y: 193),
    ])
    c.fill(tail, with: .color(FieldStyle.ink))
    ellipse(
      &c, CGRect(x: 106, y: 96, width: 123, height: 111), Color(red: 0.40, green: 0.42, blue: 0.33))
    ellipse(
      &c, CGRect(x: 154, y: 116, width: 77, height: 90),
      tit ? Color(red: 0.76, green: 0.66, blue: 0.27) : Color(red: 0.72, green: 0.33, blue: 0.19))
    ellipse(&c, CGRect(x: 182, y: 64, width: 65, height: 68), FieldStyle.ink)
    if tit { ellipse(&c, CGRect(x: 210, y: 91, width: 29, height: 26), FieldStyle.paper) }
    leaf(&c, from: CGPoint(x: 187, y: 125), to: CGPoint(x: 103, y: 187), width: 49, shade: 0.08)
    for i in 0..<8 {
      line(
        &c, [CGPoint(x: 186 - i * 4, y: 133), CGPoint(x: 112 + i * 4, y: 183)],
        color: FieldStyle.paper.opacity(0.3), width: 1)
    }
    var beak = Path()
    beak.addLines([CGPoint(x: 244, y: 92), CGPoint(x: 267, y: 101), CGPoint(x: 242, y: 108)])
    c.fill(beak, with: .color(Color(red: 0.72, green: 0.55, blue: 0.22)))
    ellipse(&c, CGRect(x: 226, y: 86, width: 7, height: 7), .black)
    ellipse(&c, CGRect(x: 227, y: 86, width: 2, height: 2), .white)
    for x in [171.0, 200.0] {
      line(
        &c, [CGPoint(x: x, y: 202), CGPoint(x: x - 4, y: 235), CGPoint(x: x + 7, y: 235)], width: 2)
    }
  }

  private func butterfly(_ c: inout GraphicsContext) {
    for side in [-1.0, 1.0] {
      var f = c
      f.translateBy(x: 160, y: 144)
      f.scaleBy(x: side, y: 1)
      var wing = Path()
      wing.move(to: .zero)
      wing.addCurve(
        to: CGPoint(x: 109, y: -99), control1: CGPoint(x: 22, y: -84),
        control2: CGPoint(x: 130, y: -127))
      wing.addCurve(
        to: CGPoint(x: 62, y: 91), control1: CGPoint(x: 147, y: 54),
        control2: CGPoint(x: 119, y: 120))
      wing.addQuadCurve(to: .zero, control: CGPoint(x: 5, y: 87))
      f.fill(wing, with: .color(FieldStyle.rust))
      f.stroke(
        wing, with: .color(FieldStyle.ink), style: StrokeStyle(lineWidth: 8, lineJoin: .round))
      for p in 0..<8 {
        let angle = Double(p) * 0.28 - 1.05
        line(&f, [.zero, CGPoint(x: 104 * cos(angle), y: 96 * sin(angle))], width: 2.5)
        ellipse(
          &f, CGRect(x: 103 * cos(angle) - 3, y: 96 * sin(angle) - 3, width: 6, height: 6),
          FieldStyle.paper)
      }
    }
    ellipse(&c, CGRect(x: 153, y: 93, width: 14, height: 112), FieldStyle.ink)
    line(&c, [CGPoint(x: 159, y: 106), CGPoint(x: 143, y: 69)], width: 1.5)
    line(&c, [CGPoint(x: 161, y: 106), CGPoint(x: 180, y: 69)], width: 1.5)
  }

  private func ladybird(_ c: inout GraphicsContext) {
    leaf(&c, from: CGPoint(x: 51, y: 268), to: CGPoint(x: 269, y: 35), width: 132, shade: 0.17)
    for i in 0..<3 {
      let y = CGFloat(118 + i * 32)
      line(
        &c, [CGPoint(x: 133, y: y), CGPoint(x: 104, y: y - 11), CGPoint(x: 99, y: y - 28)], width: 3
      )
      line(
        &c, [CGPoint(x: 187, y: y), CGPoint(x: 212, y: y + 8), CGPoint(x: 223, y: y - 6)], width: 3)
    }
    ellipse(&c, CGRect(x: 137, y: 76, width: 47, height: 50), FieldStyle.ink)
    ellipse(&c, CGRect(x: 115, y: 102, width: 91, height: 111), FieldStyle.rust)
    line(&c, [CGPoint(x: 160, y: 102), CGPoint(x: 160, y: 211)], width: 2)
    for p in [
      CGPoint(x: 156, y: 112), CGPoint(x: 130, y: 135), CGPoint(x: 177, y: 135),
      CGPoint(x: 128, y: 165), CGPoint(x: 182, y: 165), CGPoint(x: 140, y: 189),
      CGPoint(x: 173, y: 189),
    ] {
      ellipse(&c, CGRect(x: p.x - 7, y: p.y - 7, width: 14, height: 14), FieldStyle.ink)
    }
  }

  private func snail(_ c: inout GraphicsContext) {
    leaf(&c, from: CGPoint(x: 25, y: 253), to: CGPoint(x: 291, y: 217), width: 73, shade: 0.13)
    var body = Path()
    body.move(to: CGPoint(x: 57, y: 218))
    body.addQuadCurve(to: CGPoint(x: 248, y: 171), control: CGPoint(x: 184, y: 224))
    body.addQuadCurve(to: CGPoint(x: 277, y: 220), control: CGPoint(x: 276, y: 179))
    body.addQuadCurve(to: CGPoint(x: 57, y: 218), control: CGPoint(x: 167, y: 249))
    c.fill(body, with: .color(Color(red: 0.55, green: 0.52, blue: 0.37)))
    ellipse(
      &c, CGRect(x: 82, y: 87, width: 130, height: 130), Color(red: 0.65, green: 0.46, blue: 0.27))
    var spiral = Path()
    for i in 0..<200 {
      let angle = Double(i) * 0.08
      let radius = Double(i) * 0.29
      let p = CGPoint(x: 146 + cos(angle) * radius, y: 151 + sin(angle) * radius)
      if i == 0 { spiral.move(to: p) } else { spiral.addLine(to: p) }
    }
    c.stroke(spiral, with: .color(FieldStyle.ink.opacity(0.8)), lineWidth: 3)
    for x in [246.0, 260.0] {
      line(&c, [CGPoint(x: x, y: 186), CGPoint(x: x + 6, y: 150)], width: 2)
      ellipse(&c, CGRect(x: x + 3, y: 147, width: 5, height: 5), FieldStyle.ink)
    }
  }

  private func fungi(_ c: inout GraphicsContext, bracket: Bool) {
    if bracket {
      line(
        &c, [CGPoint(x: 80, y: 279), CGPoint(x: 194, y: 62)], color: .brown.opacity(0.5), width: 23)
      for i in 0..<4 {
        var f = c
        f.translateBy(x: CGFloat(117 + i * 19), y: CGFloat(233 - i * 45))
        f.rotate(by: .degrees(-24))
        for band in (0..<6).reversed() {
          let radius = CGFloat(22 + band * 10)
          var p = Path()
          p.move(to: .zero)
          p.addArc(
            center: .zero, radius: radius, startAngle: .degrees(190), endAngle: .degrees(350),
            clockwise: false)
          p.closeSubpath()
          f.fill(
            p,
            with: .color(
              [FieldStyle.ink, FieldStyle.rust, FieldStyle.muted, FieldStyle.paper][band % 4]))
        }
      }
    } else {
      for i in 0..<2 {
        var f = c
        f.translateBy(x: CGFloat(i == 0 ? 179 : 84), y: CGFloat(i == 0 ? 261 : 274))
        let scale = i == 0 ? 1.0 : 0.6
        f.scaleBy(x: scale, y: scale)
        var stem = Path()
        stem.addRoundedRect(
          in: CGRect(x: -12, y: -141, width: 27, height: 143),
          cornerSize: CGSize(width: 10, height: 10))
        f.fill(stem, with: .color(Color(red: 0.85, green: 0.82, blue: 0.67)))
        line(
          &f, [CGPoint(x: 4, y: -124), CGPoint(x: 4, y: -12)], color: FieldStyle.muted.opacity(0.5),
          width: 1)
        ellipse(&f, CGRect(x: -82, y: -157, width: 164, height: 31), FieldStyle.wash)
        var cap = Path()
        cap.move(to: CGPoint(x: -87, y: -145))
        cap.addQuadCurve(to: CGPoint(x: 87, y: -145), control: CGPoint(x: 0, y: -293))
        cap.addQuadCurve(to: CGPoint(x: -87, y: -145), control: CGPoint(x: 0, y: -117))
        f.fill(cap, with: .color(FieldStyle.rust))
        for dot in 0..<20 {
          let x = CGFloat((dot * 37) % 125) - 62
          let y = -148 - CGFloat((dot * 13) % 38)
          ellipse(&f, CGRect(x: x, y: y, width: 6, height: 4), FieldStyle.paper.opacity(0.9))
        }
      }
    }
  }
}
