import SwiftUI

enum Palette {
  static let ink = Color(red: 0.045, green: 0.09, blue: 0.15)
  static let panel = Color(red: 0.09, green: 0.15, blue: 0.21)
  static let cream = Color(red: 0.97, green: 0.93, blue: 0.83)
  static let orange = Color(red: 1, green: 0.65, blue: 0.34)
  static let mint = Color(red: 0.65, green: 0.9, blue: 0.79)
  static let muted = Color(red: 0.58, green: 0.68, blue: 0.73)
}

struct ProduceArt: View {
  let kind: Int
  var body: some View {
    Canvas { context, size in
      let scale = min(size.width, size.height) / 80
      context.scaleBy(x: scale, y: scale)
      func ellipse(_ rect: CGRect, _ color: Color) {
        context.fill(Path(ellipseIn: rect), with: .color(color))
      }
      ellipse(CGRect(x: 12, y: 65, width: 56, height: 8), .black.opacity(0.12))
      switch kind {
      case 0:
        var pear = Path()
        pear.move(to: CGPoint(x: 40, y: 17))
        pear.addCurve(
          to: CGPoint(x: 16, y: 53), control1: CGPoint(x: 24, y: 20),
          control2: CGPoint(x: 32, y: 31))
        pear.addCurve(
          to: CGPoint(x: 63, y: 55), control1: CGPoint(x: 1, y: 76), control2: CGPoint(x: 65, y: 80)
        )
        pear.addCurve(
          to: CGPoint(x: 40, y: 17), control1: CGPoint(x: 64, y: 35),
          control2: CGPoint(x: 49, y: 35))
        context.fill(
          pear,
          with: .linearGradient(
            Gradient(colors: [Palette.mint, Color(red: 0.2, green: 0.58, blue: 0.51)]),
            startPoint: .init(x: 20, y: 20), endPoint: .init(x: 62, y: 68)))
        ellipse(CGRect(x: 25, y: 43, width: 8, height: 18), .white.opacity(0.35))
        var leaf = Path()
        leaf.move(to: .init(x: 40, y: 21))
        leaf.addQuadCurve(to: .init(x: 62, y: 8), control: .init(x: 42, y: 0))
        leaf.addQuadCurve(to: .init(x: 40, y: 21), control: .init(x: 64, y: 24))
        context.fill(leaf, with: .color(Palette.orange))
      case 1:
        let stem = Path(roundedRect: CGRect(x: 30, y: 35, width: 22, height: 33), cornerRadius: 8)
        context.fill(stem, with: .color(Color(red: 0.92, green: 0.84, blue: 0.76)))
        var cap = Path()
        cap.move(to: .init(x: 8, y: 43))
        cap.addCurve(
          to: .init(x: 72, y: 43), control1: .init(x: 13, y: -5), control2: .init(x: 63, y: -5))
        cap.addQuadCurve(to: .init(x: 8, y: 43), control: .init(x: 40, y: 58))
        context.fill(
          cap,
          with: .linearGradient(
            Gradient(colors: [
              Color(red: 0.79, green: 0.69, blue: 0.98), Color(red: 0.42, green: 0.35, blue: 0.68),
            ]), startPoint: .init(x: 25, y: 12), endPoint: .init(x: 58, y: 48)))
        for point in [
          CGPoint(x: 27, y: 24), .init(x: 48, y: 18), .init(x: 56, y: 34), .init(x: 19, y: 37),
        ] {
          ellipse(CGRect(x: point.x, y: point.y, width: 5, height: 5), Palette.cream)
        }
      default:
        var root = Path()
        root.move(to: .init(x: 25, y: 25))
        root.addCurve(
          to: .init(x: 49, y: 70), control1: .init(x: 8, y: 46), control2: .init(x: 43, y: 63))
        root.addCurve(
          to: .init(x: 59, y: 28), control1: .init(x: 62, y: 49), control2: .init(x: 74, y: 31))
        root.closeSubpath()
        context.fill(
          root,
          with: .linearGradient(
            Gradient(colors: [Palette.orange, Color(red: 0.81, green: 0.32, blue: 0.21)]),
            startPoint: .init(x: 27, y: 22), endPoint: .init(x: 55, y: 69)))
        for index in 0..<3 {
          var leaf = Path()
          leaf.move(to: .init(x: 43, y: 29))
          leaf.addQuadCurve(
            to: .init(x: 23 + index * 18, y: 3), control: .init(x: 14 + index * 17, y: 8))
          leaf.addQuadCurve(to: .init(x: 43, y: 29), control: .init(x: 53, y: 15))
          context.fill(leaf, with: .color(Palette.mint.opacity(0.7 + Double(index) * 0.1)))
        }
        for index in 0..<3 {
          let line = Path(
            roundedRect: CGRect(
              x: 30 + index * 4, y: 38 + index * 9, width: 13 - index * 2, height: 2),
            cornerRadius: 1)
          context.fill(line, with: .color(Palette.cream.opacity(0.5)))
        }
      }
    }
    .accessibilityHidden(true)
  }
}

struct BazaarScene: View {
  var flourishing = false
  var celebrating = false
  @Environment(\.accessibilityReduceMotion) private var reducedMotion

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 24, paused: reducedMotion)) { timeline in
      let time = reducedMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
      Canvas { context, size in
        context.scaleBy(x: size.width / 360, y: size.height / 225)
        draw(context: &context, time: time)
      }
    }
    .accessibilityHidden(true)
  }

  private func draw(context: inout GraphicsContext, time: Double) {
    func ellipse(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: Color) {
      context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
    }
    func rect(
      _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: Color, radius: Double = 0
    ) {
      context.fill(
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius),
        with: .color(color))
    }
    func line(_ points: [CGPoint], _ color: Color, _ width: Double) {
      var path = Path()
      path.addLines(points)
      context.stroke(
        path, with: .color(color),
        style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
    for index in 0..<42 {
      let x = Double((index * 67 + 21) % 350)
      let y = Double((index * 37 + 7) % 143)
      let shimmer = 0.3 + (sin(time * 0.8 + Double(index)) + 1) * 0.25
      ellipse(
        x, y, index % 5 == 0 ? 2.4 : 1.2, index % 5 == 0 ? 2.4 : 1.2, Palette.cream.opacity(shimmer)
      )
    }
    ellipse(252, 9, 64, 64, Palette.mint.opacity(0.035))
    ellipse(259, 16, 50, 50, Palette.mint.opacity(0.08))
    ellipse(266, 23, 36, 36, Color(red: 0.78, green: 0.85, blue: 0.81))
    ellipse(275, 30, 8, 8, Palette.ink.opacity(0.09))
    ellipse(286, 44, 10, 7, Palette.ink.opacity(0.08))
    ellipse(-80, 152, 530, 130, Color(red: 0.18, green: 0.26, blue: 0.3))
    ellipse(-75, 176, 530, 100, Color(red: 0.29, green: 0.37, blue: 0.38))
    for index in 0..<14 {
      ellipse(
        Double((index * 47 + 5) % 360), Double(183 + (index * 11) % 38), Double(6 + index % 12), 2,
        Palette.ink.opacity(0.16))
    }
    // Distant domes and antennae.
    ellipse(10, 133, 63, 45, Palette.panel)
    rect(10, 158, 63, 20, Palette.panel)
    rect(38, 124, 2, 17, Palette.muted)
    ellipse(35, 122, 7, 7, Palette.orange)
    rect(23, 151, 12, 7, Palette.orange.opacity(0.7), radius: 2)
    rect(46, 151, 12, 7, Palette.mint.opacity(0.5), radius: 2)
    ellipse(296, 145, 50, 33, Palette.panel)
    rect(296, 165, 50, 13, Palette.panel)
    rect(309, 157, 21, 6, Palette.mint.opacity(0.45), radius: 2)
    ellipse(90, 190, 182, 21, Palette.ink.opacity(0.32))
    ellipse(72, 137, 216, 70, Palette.orange.opacity(flourishing ? 0.08 : 0.035))
    let canopyY = flourishing ? 62.0 : 78.0
    line(
      [.init(x: 109, y: canopyY), .init(x: 109, y: 186)], Color(red: 0.7, green: 0.44, blue: 0.28),
      5)
    line(
      [.init(x: 246, y: canopyY), .init(x: 246, y: 186)], Color(red: 0.7, green: 0.44, blue: 0.28),
      5)
    var roof = Path()
    roof.addLines([
      .init(x: 94, y: canopyY + 28), .init(x: 120, y: canopyY), .init(x: 235, y: canopyY),
      .init(x: 259, y: canopyY + 28),
    ])
    roof.closeSubpath()
    context.fill(roof, with: .color(Palette.orange))
    for index in 0..<7 {
      let x = 94.0 + Double(index) * 23.6
      rect(
        x, canopyY + 26, 23.6, 15,
        index % 2 == 0 ? Palette.cream : Color(red: 0.88, green: 0.41, blue: 0.27), radius: 5)
    }
    rect(143, canopyY + 34, 66, 20, Palette.ink, radius: 4)
    context.draw(
      Text("L U N E").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(
        Palette.cream), at: .init(x: 176, y: canopyY + 44))
    // The merchant peeks out between the crates.
    alien(
      context: &context, x: 169, y: 123, color: Palette.mint, bounce: sin(time * 1.7) * 1.5,
      small: true)
    rect(105, 163, 145, 31, Color(red: 0.62, green: 0.32, blue: 0.24), radius: 3)
    rect(101, 157, 154, 9, Color(red: 0.88, green: 0.6, blue: 0.39), radius: 2)
    for index in 0..<3 {
      let x = 111.0 + Double(index) * 45
      rect(x, 143, 39, 14, Color(red: 0.42, green: 0.25, blue: 0.24), radius: 2)
      for fruit in 0..<3 {
        ellipse(
          x + 3 + Double(fruit) * 10, 133 + Double(fruit % 2) * 3, 12, 13,
          [Palette.mint, Color(red: 0.72, green: 0.61, blue: 0.87), Palette.orange][index])
      }
      rect(x + 10, 151, 22, 12, Palette.mint, radius: 2)
      context.draw(
        Text(["7", "10", "13"][index]).font(.system(size: 7, weight: .bold, design: .monospaced))
          .foregroundColor(Palette.ink), at: .init(x: x + 21, y: 157))
    }
    for x in [117.0, 237.0] {
      line([.init(x: x, y: canopyY + 40), .init(x: x, y: canopyY + 58)], Palette.cream, 1)
      ellipse(x - 13, canopyY + 50, 26, 30, Palette.orange.opacity(0.08))
      ellipse(x - 8, canopyY + 55, 16, 20, Palette.orange)
      rect(x - 2, canopyY + 58, 4, 13, Palette.cream.opacity(0.6), radius: 2)
    }
    ellipse(117, 187, 17, 17, Palette.ink)
    ellipse(221, 187, 17, 17, Palette.ink)
    ellipse(123, 193, 5, 5, Palette.muted)
    ellipse(227, 193, 5, 5, Palette.muted)
    let count = celebrating ? 5 : (flourishing ? 3 : 2)
    for index in 0..<count {
      let x = [63.0, 275, 31, 306, 337][index]
      let y = [166.0, 174, 180, 158, 183][index]
      alien(
        context: &context, x: x, y: y,
        color: [Palette.mint, Color(red: 0.77, green: 0.69, blue: 0.88), Palette.orange][index % 3],
        bounce: sin(time * 2.8 + Double(index)) * (celebrating ? 4 : 1.2), small: false)
    }
    if flourishing {
      var garland = Path()
      garland.move(to: .init(x: 85, y: 62))
      garland.addQuadCurve(to: .init(x: 267, y: 62), control: .init(x: 176, y: 90))
      context.stroke(garland, with: .color(Palette.muted), lineWidth: 1)
      for index in 0..<10 {
        let x = 87.0 + Double(index) * 20
        let y = 62 + sin(Double(index) / 9 * .pi) * 13
        ellipse(x - 2, y, 5, 7, index % 2 == 0 ? Palette.orange : Palette.mint)
      }
    }
    if celebrating {
      for index in 0..<18 {
        let phase = (time * 0.3 + Double(index) * 0.17).truncatingRemainder(dividingBy: 1)
        let x = Double((index * 41 + 29) % 340)
        let y = 190 - phase * 130
        ellipse(
          x, y, 3, 3, [Palette.orange, Palette.mint, Palette.cream][index % 3].opacity(1 - phase))
      }
    }
  }

  private func alien(
    context: inout GraphicsContext, x: Double, y: Double, color: Color, bounce: Double, small: Bool
  ) {
    let y = y + bounce
    let width = small ? 24.0 : 27.0
    context.fill(
      Path(ellipseIn: CGRect(x: x - 2, y: y + 26, width: width + 4, height: 6)),
      with: .color(Palette.ink.opacity(0.24)))
    let body = Path(roundedRect: CGRect(x: x, y: y, width: width, height: 29), cornerRadius: 13)
    context.fill(body, with: .color(color))
    for offset in [7.0, 17] {
      context.fill(
        Path(ellipseIn: CGRect(x: x + offset, y: y + 10, width: 4, height: 6)),
        with: .color(Palette.ink))
      context.fill(
        Path(ellipseIn: CGRect(x: x + offset + 1, y: y + 11, width: 1.3, height: 1.5)),
        with: .color(.white))
    }
    var antenna = Path()
    antenna.move(to: .init(x: x + 13, y: y + 2))
    antenna.addLine(to: .init(x: x + 16, y: y - 7))
    context.stroke(antenna, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    context.fill(
      Path(ellipseIn: CGRect(x: x + 13, y: y - 10, width: 6, height: 6)),
      with: .color(Palette.orange))
    var smile = Path()
    smile.move(to: .init(x: x + 10, y: y + 20))
    smile.addQuadCurve(to: .init(x: x + 17, y: y + 20), control: .init(x: x + 14, y: y + 24))
    context.stroke(smile, with: .color(Palette.ink.opacity(0.6)), lineWidth: 1)
  }
}
