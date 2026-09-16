import SwiftUI

enum RiverPalette {
  static let ink = Color(red: 0.10, green: 0.24, blue: 0.23)
  static let muted = Color(red: 0.36, green: 0.47, blue: 0.42)
  static let cream = Color(red: 1, green: 0.97, blue: 0.88)
  static let orange = Color(red: 1, green: 0.52, blue: 0.29)
  static let gold = Color(red: 1, green: 0.73, blue: 0.30)
  static let teal = Color(red: 0.28, green: 0.61, blue: 0.56)
}

struct RiverScene: View {
  let game: GameModel
  let home: Bool

  var body: some View {
    Canvas { context, size in
      context.scaleBy(x: size.width / GameModel.width, y: size.height / GameModel.height)
      drawLandscape(in: &context)
      if !home {
        for gate in game.gates { drawGate(gate, in: &context) }
        drawOtter(in: &context)
      }
      drawWater(in: &context)
    }
    .accessibilityHidden(true)
    .ignoresSafeArea()
  }

  private func drawLandscape(in context: inout GraphicsContext) {
    let frame = CGRect(x: 0, y: 0, width: 390, height: 844)
    context.fill(
      Path(frame),
      with: .linearGradient(
        Gradient(colors: [
          Color(red: 0.82, green: 0.91, blue: 0.86), RiverPalette.cream,
          Color(red: 0.95, green: 0.91, blue: 0.73),
        ]), startPoint: .zero, endPoint: CGPoint(x: 40, y: 700)))
    ellipse(CGRect(x: 242, y: 274, width: 114, height: 114), .white.opacity(0.22), in: &context)
    ellipse(CGRect(x: 255, y: 287, width: 88, height: 88), .white.opacity(0.26), in: &context)
    for index in 0..<7 {
      let x = wrapped(Double(index) * 88 - game.distance * 0.07, period: 580) - 100
      let y = 210 + Double((index * 53) % 180)
      ellipse(CGRect(x: x, y: y, width: 75, height: 16), .white.opacity(0.32), in: &context)
      ellipse(
        CGRect(x: x + 24, y: y - 10, width: 38, height: 24), .white.opacity(0.32), in: &context)
    }
    for layer in 0..<3 {
      let base = 557.0 + Double(layer) * 46
      var hills = Path()
      hills.move(to: CGPoint(x: -80, y: 844))
      hills.addLine(to: CGPoint(x: -80, y: base))
      for index in 0..<7 {
        let x = Double(index) * 94 - 80
        hills.addQuadCurve(
          to: CGPoint(x: x + 94, y: base + Double(index % 2) * 24),
          control: CGPoint(x: x + 47, y: base - 90 + Double((index * 23) % 48)))
      }
      hills.addLine(to: CGPoint(x: 580, y: 844))
      hills.closeSubpath()
      let colors: [Color] = [
        Color(red: 0.67, green: 0.77, blue: 0.57),
        Color(red: 0.47, green: 0.65, blue: 0.49),
        Color(red: 0.25, green: 0.49, blue: 0.41),
      ]
      context.fill(hills, with: .color(colors[layer]))
    }
    for index in 0..<15 {
      let x = wrapped(Double(index) * 39 - game.distance * 0.2, period: 520) - 60
      let height = 54 + Double((index * 17) % 70)
      var tree = Path()
      tree.move(to: CGPoint(x: x - 24, y: 674))
      tree.addQuadCurve(
        to: CGPoint(x: x, y: 674 - height),
        control: CGPoint(x: x - 27, y: 674 - height * 0.65))
      tree.addQuadCurve(
        to: CGPoint(x: x + 25, y: 674),
        control: CGPoint(x: x + 34, y: 674 - height * 0.4))
      context.fill(tree, with: .color(RiverPalette.ink.opacity(0.12)))
    }
    for index in 0..<7 {
      let x = wrapped(Double(index) * 68 + 25 - game.distance * 0.25, period: 430) - 20
      let y = 420 + Double((index * 37) % 190)
      ellipse(
        CGRect(x: x, y: y, width: 4, height: 4), RiverPalette.cream.opacity(0.8), in: &context)
    }
  }

  private func drawGate(_ gate: RiverGate, in context: inout GraphicsContext) {
    for upper in [true, false] {
      let edge = upper ? gate.top : gate.bottom
      let rect = CGRect(
        x: gate.x, y: upper ? -20 : edge, width: GameModel.gateWidth,
        height: upper ? edge + 20 : 844 - edge)
      let rock = Path(roundedRect: rect, cornerRadius: 13)
      context.fill(
        rock,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.62, green: 0.68, blue: 0.48),
            Color(red: 0.77, green: 0.76, blue: 0.56),
            Color(red: 0.53, green: 0.61, blue: 0.42),
          ]), startPoint: CGPoint(x: gate.x, y: 0),
          endPoint: CGPoint(x: gate.x + GameModel.gateWidth, y: 0)))
      context.stroke(rock, with: .color(RiverPalette.ink.opacity(0.30)), lineWidth: 2)
      let moss = CGRect(x: gate.x - 2, y: upper ? edge - 18 : edge, width: 76, height: 18)
      context.fill(
        Path(roundedRect: moss, cornerRadius: 9),
        with: .color(Color(red: 0.27, green: 0.48, blue: 0.35)))
      for index in 0..<3 {
        ellipse(
          CGRect(x: gate.x + 10 + Double(index) * 20, y: moss.minY + 2, width: 14, height: 7),
          Color(red: 0.53, green: 0.68, blue: 0.38), in: &context)
      }
      for index in 0..<5 {
        let y = upper ? edge - 60 - Double(index) * 76 : edge + 45 + Double(index) * 76
        let stripe = CGRect(x: gate.x + 13, y: y, width: 22 + Double(index % 2) * 18, height: 4)
        context.fill(
          Path(roundedRect: stripe, cornerRadius: 2), with: .color(RiverPalette.ink.opacity(0.13)))
      }
    }
    if !gate.passed {
      var ring = Path()
      ring.addEllipse(in: CGRect(x: gate.x + 26, y: gate.center - 10, width: 20, height: 20))
      context.stroke(ring, with: .color(RiverPalette.gold.opacity(0.65)), lineWidth: 2)
      ellipse(
        CGRect(x: gate.x + 33, y: gate.center - 3, width: 6, height: 6),
        RiverPalette.gold, in: &context)
    }
  }

  private func drawOtter(in context: inout GraphicsContext) {
    let y = game.y
    for index in 0..<3 {
      let size = 6.0 - Double(index)
      ellipse(
        CGRect(
          x: GameModel.playerX - 38 - Double(index) * 15,
          y: y + 8 + Double(index) * 5, width: size, height: size),
        .white.opacity(0.6 - Double(index) * 0.15), in: &context)
    }
    var otterContext = context
    otterContext.translateBy(x: GameModel.playerX, y: y)
    otterContext.rotate(by: .degrees(game.tilt))
    otterContext.draw(
      Image("Otter"), in: CGRect(x: -32, y: -29, width: 64, height: 58.6))
  }

  private func drawWater(in context: inout GraphicsContext) {
    var water = Path()
    water.move(to: CGPoint(x: 0, y: 844))
    water.addLine(to: CGPoint(x: 0, y: GameModel.waterline))
    for x in stride(from: 0.0, through: 390, by: 5) {
      water.addLine(
        to: CGPoint(x: x, y: GameModel.waterline + sin(x / 25 + game.distance / 70) * 3))
    }
    water.addLine(to: CGPoint(x: 390, y: 844))
    water.closeSubpath()
    context.fill(
      water,
      with: .linearGradient(
        Gradient(colors: [
          Color(red: 0.38, green: 0.69, blue: 0.62),
          Color(red: 0.19, green: 0.49, blue: 0.47),
        ]), startPoint: CGPoint(x: 0, y: 726), endPoint: CGPoint(x: 0, y: 844)))
    for index in 0..<18 {
      let x = wrapped(Double(index) * 43 - game.distance * 0.5, period: 440) - 30
      let y = 741 + Double((index * 17) % 86)
      let line = CGRect(x: x, y: y, width: 14 + Double(index % 4) * 9, height: 2)
      context.fill(Path(roundedRect: line, cornerRadius: 1), with: .color(.white.opacity(0.23)))
    }
    for side in [0.0, 380.0] {
      for index in 0..<6 {
        let x = side + Double(index) * 7 - 15
        let y = 762.0 + Double(index % 3) * 16
        var reed = Path()
        reed.move(to: CGPoint(x: x, y: 844))
        reed.addQuadCurve(
          to: CGPoint(x: x - 14, y: y - 35),
          control: CGPoint(x: x + 8, y: y + 10))
        context.stroke(reed, with: .color(RiverPalette.ink.opacity(0.65)), lineWidth: 3)
        ellipse(
          CGRect(x: x - 19, y: y - 39, width: 9, height: 25),
          RiverPalette.ink.opacity(0.65), in: &context)
      }
    }
  }

  private func ellipse(_ rect: CGRect, _ color: Color, in context: inout GraphicsContext) {
    context.fill(Path(ellipseIn: rect), with: .color(color))
  }

  private func wrapped(_ value: Double, period: Double) -> Double {
    let result = value.truncatingRemainder(dividingBy: period)
    return result < 0 ? result + period : result
  }
}
