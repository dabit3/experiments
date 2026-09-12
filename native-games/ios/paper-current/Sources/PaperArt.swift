import SwiftUI

enum Ink {
  static let night = Color(red: 0.08, green: 0.19, blue: 0.24)
  static let blue = Color(red: 0.15, green: 0.31, blue: 0.37)
  static let water = Color(red: 0.27, green: 0.49, blue: 0.55)
  static let foam = Color(red: 0.66, green: 0.83, blue: 0.80)
  static let paper = Color(red: 0.95, green: 0.91, blue: 0.81)
  static let cream = Color(red: 1, green: 0.97, blue: 0.88)
  static let red = Color(red: 0.77, green: 0.23, blue: 0.16)
  static let gold = Color(red: 0.96, green: 0.70, blue: 0.34)
  static let muted = Color(red: 0.68, green: 0.77, blue: 0.75)

  static func title(_ size: CGFloat) -> Font { .custom("Georgia", size: size) }
}

func polygon(_ points: [CGPoint]) -> Path {
  Path { path in
    guard let first = points.first else { return }
    path.move(to: first)
    for point in points.dropFirst() { path.addLine(to: point) }
    path.closeSubpath()
  }
}

struct PaperBoat: View {
  var body: some View {
    Canvas { context, size in
      let w = size.width
      let h = size.height
      func shape(_ points: [(CGFloat, CGFloat)], _ color: Color) {
        context.fill(
          polygon(points.map { CGPoint(x: $0.0 * w, y: $0.1 * h) }), with: .color(color))
      }
      context.fill(
        Path(ellipseIn: CGRect(x: w * 0.08, y: h * 0.77, width: w * 0.84, height: h * 0.14)),
        with: .color(Ink.night.opacity(0.2)))
      shape([(0.08, 0.40), (0.43, 0.04), (0.47, 0.51)], Ink.cream)
      shape([(0.43, 0.04), (0.82, 0.47), (0.47, 0.51)], Ink.paper)
      shape([(0, 0.42), (0.47, 0.57), (1, 0.34), (0.75, 0.82), (0.26, 0.82)], Ink.cream)
      shape(
        [(0.47, 0.57), (1, 0.34), (0.75, 0.82), (0.47, 0.72)],
        Color(red: 0.82, green: 0.78, blue: 0.67))
      shape([(0.42, 0.48), (0.58, 0.45), (0.59, 0.58), (0.43, 0.61)], Ink.red)
      var crease = Path()
      crease.move(to: CGPoint(x: w * 0.26, y: h * 0.82))
      crease.addLine(to: CGPoint(x: w * 0.47, y: h * 0.57))
      context.stroke(crease, with: .color(Ink.blue.opacity(0.3)), lineWidth: 0.8)
    }
    .accessibilityHidden(true)
  }
}

struct TownArt: View {
  var animated = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    TimelineView(.animation(minimumInterval: 0.08, paused: !animated || reduceMotion)) { timeline in
      let time = animated && !reduceMotion ? timeline.date.timeIntervalSinceReferenceDate : 0
      Canvas { context, size in
        context.scaleBy(x: size.width / 400, y: size.height / 380)
        drawTown(&context, time: time)
      }
      .overlay(alignment: .bottom) {
        PaperBoat().frame(width: 89, height: 65)
          .rotationEffect(.degrees(-8))
          .offset(x: -16, y: -27 + (reduceMotion ? 0 : sin(time * 1.5) * 3))
      }
    }
    .accessibilityHidden(true)
  }

  private func drawTown(_ context: inout GraphicsContext, time: Double) {
    let island = polygon([
      CGPoint(x: 5, y: 182), CGPoint(x: 80, y: 98), CGPoint(x: 191, y: 129),
      CGPoint(x: 230, y: 66), CGPoint(x: 369, y: 114), CGPoint(x: 400, y: 232),
      CGPoint(x: 341, y: 314), CGPoint(x: 228, y: 347), CGPoint(x: 59, y: 302),
    ])
    var shadow = context
    shadow.translateBy(x: 0, y: 13)
    shadow.fill(island, with: .color(Ink.night.opacity(0.9)))
    context.fill(island, with: .color(Ink.paper))
    context.stroke(island, with: .color(Ink.cream), lineWidth: 3)
    var river = Path()
    river.move(to: CGPoint(x: 154, y: 337))
    river.addCurve(
      to: CGPoint(x: 248, y: 264), control1: CGPoint(x: 141, y: 279),
      control2: CGPoint(x: 249, y: 321))
    river.addCurve(
      to: CGPoint(x: 177, y: 206), control1: CGPoint(x: 250, y: 224),
      control2: CGPoint(x: 170, y: 255))
    river.addCurve(
      to: CGPoint(x: 279, y: 143), control1: CGPoint(x: 173, y: 161),
      control2: CGPoint(x: 288, y: 197))
    river.addLine(to: CGPoint(x: 268, y: 83))
    context.stroke(
      river, with: .color(Color(red: 0.69, green: 0.67, blue: 0.58)),
      style: StrokeStyle(lineWidth: 54, lineCap: .butt))
    context.stroke(river, with: .color(Ink.blue), style: StrokeStyle(lineWidth: 46, lineCap: .butt))
    context.stroke(
      river, with: .color(Ink.water), style: StrokeStyle(lineWidth: 35, lineCap: .butt))
    context.stroke(
      river, with: .color(Ink.foam.opacity(0.5)),
      style: StrokeStyle(lineWidth: 1, dash: [10, 15], dashPhase: time * 6))
    for house in [
      (56.0, 151.0, 42.0, 58.0, false), (101, 141, 38, 81, true),
      (150, 157, 32, 57, false), (213, 119, 30, 66, false),
      (302, 151, 41, 87, true), (346, 191, 32, 55, false),
      (69, 245, 39, 70, true), (115, 265, 37, 64, false),
      (298, 261, 43, 72, false), (342, 253, 26, 46, true),
      (213, 295, 28, 47, true),
    ] {
      drawHouse(&context, x: house.0, y: house.1, width: house.2, height: house.3, red: house.4)
    }
    for i in 0..<11 {
      let x = CGFloat((i * 79 + 32) % 360) + 20
      let y = CGFloat((i * 43 + 210) % 165) + 154
      context.fill(
        Path(ellipseIn: CGRect(x: x, y: y, width: 10, height: 4)),
        with: .color(Ink.blue.opacity(0.12)))
    }
    for i in 0..<40 {
      let x = CGFloat((i * 73 + 19) % 400)
      let y = (CGFloat((i * 47) % 380) + time.truncatingRemainder(dividingBy: 20) * 11)
        .truncatingRemainder(dividingBy: 380)
      var rain = Path()
      rain.move(to: CGPoint(x: x, y: y))
      rain.addLine(to: CGPoint(x: x - 2, y: y + 7))
      context.stroke(rain, with: .color(Ink.foam.opacity(0.25)), lineWidth: 1)
    }
    drawBridge(&context, x: 190, y: 196)
  }
}

func drawHouse(
  _ context: inout GraphicsContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat,
  red: Bool
) {
  let wall =
    red ? Color(red: 0.73, green: 0.39, blue: 0.28) : Color(red: 0.67, green: 0.74, blue: 0.69)
  let face = CGRect(x: x, y: y - height, width: width, height: height)
  context.fill(
    polygon([
      CGPoint(x: x, y: y), CGPoint(x: x + 14, y: y + 9),
      CGPoint(x: x + width + 18, y: y + 4), CGPoint(x: x + width, y: y - 7),
    ]), with: .color(Ink.night.opacity(0.16)))
  context.fill(Path(face), with: .color(wall))
  context.fill(
    polygon([
      CGPoint(x: x + width, y: y - height), CGPoint(x: x + width + 9, y: y - height + 7),
      CGPoint(x: x + width + 9, y: y - 5), CGPoint(x: x + width, y: y),
    ]), with: .color(Ink.blue.opacity(0.65)))
  context.fill(
    polygon([
      CGPoint(x: x - 3, y: y - height + 1), CGPoint(x: x + width / 2, y: y - height - 19),
      CGPoint(x: x + width + 4, y: y - height + 1),
    ]), with: .color(red ? Ink.red : Ink.blue))
  var fold = Path()
  fold.move(to: CGPoint(x: x + width / 2, y: y - height - 17))
  fold.addLine(to: CGPoint(x: x + width / 2, y: y - height))
  context.stroke(fold, with: .color(Ink.cream.opacity(0.5)), lineWidth: 1)
  for row in 0..<max(1, Int(height / 23)) {
    for col in 0..<2 {
      let rect = CGRect(
        x: x + 7 + CGFloat(col) * (width - 19), y: y - height + 10 + CGFloat(row) * 18, width: 6,
        height: 9)
      context.fill(Path(rect.insetBy(dx: -1, dy: -1)), with: .color(Ink.blue.opacity(0.6)))
      context.fill(Path(rect), with: .color(Ink.gold))
      context.fill(
        Path(CGRect(x: rect.midX, y: rect.minY, width: 0.8, height: rect.height)),
        with: .color(wall))
    }
  }
}

private func drawBridge(_ context: inout GraphicsContext, x: CGFloat, y: CGFloat) {
  let deck = CGRect(x: x, y: y, width: 52, height: 20)
  context.fill(Path(deck.offsetBy(dx: 3, dy: 5)), with: .color(Ink.night.opacity(0.25)))
  context.fill(Path(deck), with: .color(Ink.cream))
  for i in 0..<7 {
    let xx = x + CGFloat(i) * 8
    var line = Path()
    line.move(to: CGPoint(x: xx, y: y))
    line.addLine(to: CGPoint(x: xx, y: y + 20))
    context.stroke(line, with: .color(Ink.blue.opacity(0.25)), lineWidth: 1)
  }
  context.fill(Path(CGRect(x: x - 2, y: y - 4, width: 56, height: 4)), with: .color(Ink.red))
  context.fill(Path(CGRect(x: x - 2, y: y + 18, width: 56, height: 4)), with: .color(Ink.red))
}

struct PaperTexture: View {
  var body: some View {
    Canvas { context, size in
      for i in 0..<450 {
        let x = CGFloat((i * 127 + 31) % 997) / 997 * size.width
        let y = CGFloat((i * 193 + 71) % 991) / 991 * size.height
        context.fill(
          Path(CGRect(x: x, y: y, width: 1, height: 1)), with: .color(Ink.blue.opacity(0.07)))
      }
    }.allowsHitTesting(false).accessibilityHidden(true)
  }
}

struct CanalDrawing: View {
  let canal: Canal
  let lit: Bool

  var body: some View {
    Canvas { context, size in
      let w = size.width
      let h = size.height
      let center = CGPoint(x: w / 2, y: h / 2)
      func point(_ direction: Direction) -> CGPoint {
        switch direction {
        case .north: return CGPoint(x: w / 2, y: -2)
        case .east: return CGPoint(x: w + 2, y: h / 2)
        case .south: return CGPoint(x: w / 2, y: h + 2)
        case .west: return CGPoint(x: -2, y: h / 2)
        }
      }
      var water = Path()
      water.move(to: point(canal.ports[0]))
      water.addLine(to: center)
      water.addLine(to: point(canal.ports[1]))
      context.stroke(
        water, with: .color(Ink.night.opacity(0.17)),
        style: StrokeStyle(lineWidth: w * 0.40, lineJoin: .round))
      context.stroke(
        water, with: .color(Ink.blue), style: StrokeStyle(lineWidth: w * 0.33, lineJoin: .round))
      context.stroke(
        water, with: .color(lit ? Ink.foam : Ink.water),
        style: StrokeStyle(lineWidth: w * 0.23, lineJoin: .round))
      context.stroke(
        water, with: .color(Ink.cream.opacity(lit ? 0.8 : 0.4)),
        style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
      if canal.isCurrent {
        let direction = canal.ports[1]
        var arrowContext = context
        arrowContext.translateBy(x: w / 2, y: h / 2)
        arrowContext.rotate(by: .degrees(Double(direction.rawValue) * 90))
        let arrow = polygon([
          CGPoint(x: 0, y: -10), CGPoint(x: 6, y: 0), CGPoint(x: 2, y: 0),
          CGPoint(x: 2, y: 8), CGPoint(x: -2, y: 8), CGPoint(x: -2, y: 0),
          CGPoint(x: -6, y: 0),
        ])
        arrowContext.fill(arrow, with: .color(Ink.cream))
      }
      if canal.isLock {
        let rect = CGRect(x: w * 0.2, y: h * 0.43, width: w * 0.6, height: h * 0.14)
        context.fill(Path(rect), with: .color(canal.open ? Ink.gold.opacity(0.5) : Ink.red))
        for i in 0..<5 {
          let x = rect.minX + CGFloat(i) * w * 0.12
          var line = Path()
          line.move(to: CGPoint(x: x, y: rect.minY))
          line.addLine(to: CGPoint(x: x + 4, y: rect.maxY))
          context.stroke(line, with: .color(Ink.paper), lineWidth: 2)
        }
      }
    }
  }
}
