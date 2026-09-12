import SwiftUI

enum Ink {
  static let background = Color(red: 0.025, green: 0.065, blue: 0.070)
  static let deep = Color(red: 0.045, green: 0.13, blue: 0.13)
  static let jade = Color(red: 0.30, green: 0.64, blue: 0.51)
  static let gold = Color(red: 0.81, green: 0.72, blue: 0.47)
  static let pearl = Color(red: 0.94, green: 0.93, blue: 0.84)
  static let peach = Color(red: 0.97, green: 0.65, blue: 0.49)
  static let muted = Color(red: 0.57, green: 0.68, blue: 0.64)
}

struct PondArt: View {
  var time: Double = 0
  var hero = false
  var celebration = false
  var reducedMotion = false

  var body: some View {
    Canvas { context, size in
      let t = reducedMotion ? 0 : time
      let width = size.width
      let height = size.height
      context.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .linearGradient(
          Gradient(colors: [Ink.background, Ink.deep, Ink.background]),
          startPoint: .zero, endPoint: CGPoint(x: width, y: height)
        )
      )
      for index in 0..<55 {
        let x = CGFloat((index * 137 + 19) % 997) / 997 * width
        let y = CGFloat((index * 271 + 23) % 991) / 991 * height
        let shimmer = 0.12 + 0.15 * (sin(t * 0.6 + Double(index)) + 1) / 2
        let radius: CGFloat = index % 7 == 0 ? 1.4 : 0.7
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
          with: .color(Ink.gold.opacity(shimmer)))
      }
      let center = CGPoint(x: width * 0.5, y: height * (hero ? 0.40 : 0.47))
      for index in 0..<7 {
        let radius = width * (0.22 + Double(index) * 0.097)
        let shift = sin(t * 0.25 + Double(index)) * 4
        context.stroke(
          Path(
            ellipseIn: CGRect(
              x: center.x - radius, y: center.y - radius * 0.72 + shift,
              width: radius * 2, height: radius * 1.44)),
          with: .color(Ink.jade.opacity(index % 2 == 0 ? 0.075 : 0.035)), lineWidth: 0.8
        )
      }
      lily(
        context, at: CGPoint(x: width * 0.08, y: height * 0.62), radius: width * 0.16, angle: -20)
      lily(
        context, at: CGPoint(x: width * 0.91, y: height * 0.22), radius: width * 0.13, angle: 130)
      lily(context, at: CGPoint(x: width * 0.97, y: height * 0.73), radius: width * 0.09, angle: 40)
      if hero {
        moon(context, center: center, radius: width * 0.265)
        koi(
          context, at: CGPoint(x: width * 0.37 + sin(t * 0.3) * 9, y: center.y + width * 0.09),
          length: width * 0.36, angle: -41 + sin(t * 0.4) * 4, color: Ink.peach)
        koi(
          context, at: CGPoint(x: width * 0.65, y: center.y - width * 0.03 + sin(t * 0.3) * 7),
          length: width * 0.27, angle: 133, color: Ink.pearl)
        blossom(
          context, at: CGPoint(x: width * 0.81, y: center.y + width * 0.24), radius: width * 0.045)
      } else {
        let count = celebration ? 7 : 2
        for index in 0..<count {
          let angle = t * 0.09 + Double(index) * 2.4
          let x = width * (0.5 + 0.35 * cos(angle))
          let y = height * (0.49 + 0.24 * sin(angle))
          koi(
            context, at: CGPoint(x: x, y: y), length: width * (celebration ? 0.19 : 0.16),
            angle: angle * 180 / .pi + 90,
            color: index % 2 == 0 ? Ink.peach.opacity(0.66) : Ink.pearl.opacity(0.5))
        }
      }
    }
    .accessibilityHidden(true)
  }

  private func moon(_ source: GraphicsContext, center: CGPoint, radius: Double) {
    var context = source
    context.addFilter(.shadow(color: Ink.gold.opacity(0.12), radius: 22))
    context.stroke(
      Path(
        ellipseIn: CGRect(
          x: center.x - radius, y: center.y - radius,
          width: radius * 2, height: radius * 2)),
      with: .color(Ink.gold.opacity(0.75)), lineWidth: 0.8)
    context.stroke(
      Path(
        ellipseIn: CGRect(
          x: center.x - radius - 5, y: center.y - radius - 5,
          width: radius * 2 + 10, height: radius * 2 + 10)),
      with: .color(Ink.gold.opacity(0.14)), lineWidth: 0.6)
    for index in 0..<9 {
      let angle = Double(index) * 0.35 - 1.8
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: center.x + cos(angle) * radius - 1.5,
            y: center.y + sin(angle) * radius - 1.5, width: 3, height: 3)),
        with: .color(Ink.pearl.opacity(0.8)))
    }
  }

  private func lily(_ source: GraphicsContext, at point: CGPoint, radius: Double, angle: Double) {
    var context = source
    context.translateBy(x: point.x, y: point.y)
    context.rotate(by: .degrees(angle))
    var path = Path()
    path.move(to: .zero)
    path.addArc(
      center: .zero, radius: radius, startAngle: .degrees(18), endAngle: .degrees(342),
      clockwise: false)
    path.closeSubpath()
    context.fill(
      path,
      with: .linearGradient(
        Gradient(colors: [Ink.jade.opacity(0.30), Ink.deep]),
        startPoint: CGPoint(x: -radius, y: -radius),
        endPoint: CGPoint(x: radius, y: radius)))
    context.stroke(path, with: .color(Ink.jade.opacity(0.28)), lineWidth: 0.8)
    for index in 1...10 {
      let angle = Double(index) * 0.55
      var vein = Path()
      vein.move(to: .zero)
      vein.addQuadCurve(
        to: CGPoint(x: cos(angle) * radius * 0.9, y: sin(angle) * radius * 0.9),
        control: CGPoint(x: cos(angle + 0.2) * radius * 0.5, y: sin(angle + 0.2) * radius * 0.5))
      context.stroke(vein, with: .color(Ink.jade.opacity(0.11)), lineWidth: 0.5)
    }
  }

  private func koi(
    _ source: GraphicsContext, at point: CGPoint, length: Double, angle: Double, color: Color
  ) {
    var context = source
    context.translateBy(x: point.x, y: point.y)
    context.rotate(by: .degrees(angle))
    context.scaleBy(x: length / 100, y: length / 100)
    context.addFilter(.shadow(color: color.opacity(0.18), radius: 8))
    var body = Path()
    body.move(to: CGPoint(x: -45, y: 0))
    body.addCurve(
      to: CGPoint(x: 42, y: 0), control1: CGPoint(x: -4, y: -35), control2: CGPoint(x: 44, y: -20))
    body.addCurve(
      to: CGPoint(x: -45, y: 0), control1: CGPoint(x: 45, y: 21), control2: CGPoint(x: -10, y: 22))
    context.fill(
      body,
      with: .linearGradient(
        Gradient(colors: [color, color.opacity(0.45)]),
        startPoint: CGPoint(x: 0, y: -19), endPoint: CGPoint(x: 0, y: 21)))
    var tail = Path()
    tail.move(to: CGPoint(x: -40, y: 0))
    tail.addQuadCurve(to: CGPoint(x: -69, y: -22), control: CGPoint(x: -55, y: -4))
    tail.addQuadCurve(to: CGPoint(x: -60, y: 1), control: CGPoint(x: -58, y: -9))
    tail.addQuadCurve(to: CGPoint(x: -68, y: 22), control: CGPoint(x: -58, y: 8))
    tail.addQuadCurve(to: CGPoint(x: -40, y: 0), control: CGPoint(x: -46, y: 14))
    context.fill(tail, with: .color(color.opacity(0.66)))
    for sign in [-1.0, 1.0] {
      var fin = Path()
      fin.move(to: CGPoint(x: 13, y: 11 * sign))
      fin.addQuadCurve(to: CGPoint(x: -11, y: 32 * sign), control: CGPoint(x: 13, y: 30 * sign))
      fin.addQuadCurve(to: CGPoint(x: -4, y: 12 * sign), control: CGPoint(x: -10, y: 22 * sign))
      context.fill(fin, with: .color(color.opacity(0.5)))
    }
    for index in 0..<5 {
      var scale = Path()
      let x = Double(index) * 10 - 26
      scale.move(to: CGPoint(x: x, y: -9))
      scale.addQuadCurve(to: CGPoint(x: x + 1, y: 10), control: CGPoint(x: x + 9, y: 0))
      context.stroke(scale, with: .color(Ink.background.opacity(0.15)), lineWidth: 0.65)
    }
    context.fill(
      Path(ellipseIn: CGRect(x: 28, y: -7, width: 3.2, height: 3.2)), with: .color(Ink.background))
  }

  private func blossom(_ source: GraphicsContext, at point: CGPoint, radius: Double) {
    var context = source
    context.translateBy(x: point.x, y: point.y)
    for index in 0..<7 {
      var petal = context
      petal.rotate(by: .degrees(Double(index) * 360 / 7))
      petal.fill(
        Path(
          ellipseIn: CGRect(
            x: -radius * 0.38, y: -radius, width: radius * 0.76, height: radius * 1.4)),
        with: .color(Ink.pearl.opacity(0.8)))
    }
    context.fill(Path(ellipseIn: CGRect(x: -3, y: -3, width: 6, height: 6)), with: .color(Ink.gold))
  }
}

struct LilyTarget: View {
  let lane: Int
  let progress: Double?
  let active: Bool
  let flash: Bool
  let label: String
  let action: () -> Void
  private var ready: Bool { (progress ?? 0) >= 0.82 }

  var body: some View {
    Button(action: action) {
      ZStack {
        Circle().fill(Ink.background.opacity(0.80)).frame(width: 98, height: 98)
        Circle().stroke(
          Ink.gold.opacity(active ? 0.9 : 0.20),
          style: StrokeStyle(lineWidth: active ? 1.8 : 0.7, dash: active ? [] : [2, 5])
        )
        .frame(width: 100, height: 100)
        LilyShape()
          .fill(
            LinearGradient(
              colors: [Ink.jade.opacity(active ? 0.72 : 0.37), Ink.deep], startPoint: .topLeading,
              endPoint: .bottomTrailing)
          )
          .overlay(LilyShape().stroke(Ink.jade.opacity(0.5), lineWidth: 0.8))
          .frame(width: 66, height: 66)
          .rotationEffect(.degrees(Double(lane) * 120 - 25))
        if let progress {
          Circle().stroke(ready ? Ink.pearl : Ink.gold, lineWidth: ready ? 3 : 2)
            .frame(
              width: 12 + 88 * min(1.12, max(0, progress)),
              height: 12 + 88 * min(1.12, max(0, progress))
            )
            .shadow(color: Ink.gold.opacity(0.6), radius: ready ? 12 : 4)
        }
        VStack(spacing: 3) {
          Text(["I", "II", "III"][lane]).font(.system(size: 19, weight: .light, design: .serif))
          if ready { Text("TAP").font(.system(size: 8, weight: .bold)).tracking(2) }
        }
        .foregroundStyle(active ? Ink.pearl : Ink.muted)
        if flash {
          Circle().stroke(Ink.peach.opacity(0.7), lineWidth: 1).frame(width: 120, height: 120)
          ForEach(0..<8) { index in
            Circle().fill(Ink.gold).frame(width: 3, height: 3)
              .offset(x: cos(Double(index) * .pi / 4) * 63, y: sin(Double(index) * .pi / 4) * 63)
          }
        }
      }
      .frame(width: 124, height: 124)
      .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Lily \(lane + 1), \(label)")
    .accessibilityIdentifier("lily-\(lane)")
  }
}

struct LilyShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    path.move(to: center)
    path.addArc(
      center: center, radius: rect.width / 2, startAngle: .degrees(20), endAngle: .degrees(340),
      clockwise: false)
    path.closeSubpath()
    return path
  }
}
