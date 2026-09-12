import SwiftUI

enum Palette {
  static let cream = Color(red: 0.98, green: 0.95, blue: 0.87)
  static let paper = Color(red: 1, green: 0.98, blue: 0.92)
  static let ink = Color(red: 0.17, green: 0.29, blue: 0.28)
  static let gold = Color(red: 0.70, green: 0.45, blue: 0.16)
  static let orange = Color(red: 0.95, green: 0.53, blue: 0.20)
  static let teal = Color(red: 0.34, green: 0.66, blue: 0.66)
  static let green = Color(red: 0.27, green: 0.56, blue: 0.39)

  static func sky(for board: Int) -> Color {
    [
      Color(red: 0.88, green: 0.89, blue: 0.82),
      Color(red: 0.85, green: 0.85, blue: 0.93),
      Color(red: 0.94, green: 0.86, blue: 0.79),
      Color(red: 0.83, green: 0.89, blue: 0.92),
      Color(red: 0.83, green: 0.90, blue: 0.80),
      Color(red: 0.95, green: 0.86, blue: 0.68),
    ][board % 6]
  }
}

struct TheaterArt: View {
  let game: GameRules
  var sparks: [GameStore.Spark] = []
  var decorative = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    Canvas { context, size in
      let scale = min(size.width / 390, size.height / 560)
      context.translateBy(x: (size.width - 390 * scale) / 2, y: (size.height - 560 * scale) / 2)
      context.scaleBy(x: scale, y: scale)
      drawStage(&context)
      if game.phase == .aiming && !decorative {
        for (index, point) in game.preview().enumerated() where index % 2 == 0 {
          circle(&context, point.x, point.y, 2.6, Palette.ink.opacity(0.72 - Double(index) / 110))
        }
        for point in game.preview() where point.x == 20 || point.x == 370 {
          context.stroke(
            Path(ellipseIn: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12)),
            with: .color(Palette.gold), lineWidth: 1.6)
        }
        if let point = game.preview().last {
          context.stroke(
            Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)),
            with: .color(Palette.ink.opacity(0.6)), lineWidth: 1.3)
        }
      }
      for peg in game.pegs { drawPeg(&context, peg) }
      if !decorative {
        for (index, point) in game.trail.enumerated() {
          circle(
            &context, point.x, point.y, Double(index) / 7, Palette.ink.opacity(Double(index) / 105)
          )
        }
        if game.phase == .flying { drawBall(&context, game.ball) }
        for spark in sparks where !reduceMotion {
          let radius = 12 + spark.age * 44
          for i in 0..<8 {
            let a = Double(i) / 8 * .pi * 2
            circle(
              &context, spark.position.x + cos(a) * radius, spark.position.y + sin(a) * radius,
              max(0, 2.4 - spark.age * 3), Palette.gold.opacity(1 - spark.age))
          }
        }
      }
      drawLauncher(&context)
      drawBucket(&context)
      if let remaining = game.finaleRemaining {
        let progress = reduceMotion ? 0.7 : min(1, (1.8 - remaining) / 1.8)
        let radius = 24 + progress * 20
        context.stroke(
          Path(
            ellipseIn: CGRect(
              x: game.ball.x - radius, y: game.ball.y - radius,
              width: radius * 2, height: radius * 2)),
          with: .color(Palette.gold.opacity(0.8 - progress * 0.4)), lineWidth: 2)
        for i in 0..<32 {
          let a = Double(i) * 2.4
          let r = (60 + Double(i % 9) * 24) * (0.35 + progress)
          let y = 270 + sin(a) * r
          star(
            &context, 195 + cos(a) * r, y, 4 + Double(i % 3) * 2,
            Palette.gold.opacity(0.8 - progress * 0.3))
        }
      }
    }
    .accessibilityHidden(true)
  }

  private func drawStage(_ context: inout GraphicsContext) {
    let bounds = CGRect(x: 8, y: 6, width: 374, height: 546)
    let arch = Path(roundedRect: bounds, cornerRadius: 155)
    context.fill(
      arch,
      with: .linearGradient(
        Gradient(colors: [Palette.sky(for: game.board.id), Palette.paper]),
        startPoint: .init(x: 195, y: 0), endPoint: .init(x: 195, y: 560)))
    context.stroke(arch, with: .color(Palette.gold.opacity(0.35)), lineWidth: 1.2)
    let inner = Path(roundedRect: CGRect(x: 17, y: 15, width: 356, height: 528), cornerRadius: 145)
    context.stroke(inner, with: .color(Palette.gold.opacity(0.20)), lineWidth: 1)
    for i in 0..<30 {
      let x = 32 + Double((i * 71) % 326)
      let y = 92 + Double((i * 83) % 360)
      star(&context, x, y, i % 3 == 0 ? 3 : 1.5, Palette.gold.opacity(0.24))
    }
    circle(&context, 195, 272, 102, Palette.paper.opacity(0.30))
    context.draw(
      Text(Image(systemName: game.board.symbol))
        .font(.system(size: 125, weight: .ultraLight))
        .foregroundStyle(Palette.gold.opacity(0.10)),
      at: CGPoint(x: 195, y: 278))
    context.stroke(
      Path(ellipseIn: CGRect(x: 91, y: 168, width: 208, height: 208)),
      with: .color(Palette.gold.opacity(0.08)), lineWidth: 1)
    for i in 0..<12 {
      let a = Double(i) / 12 * .pi * 2
      var ray = Path()
      ray.move(to: .init(x: 195 + cos(a) * 85, y: 272 + sin(a) * 85))
      ray.addLine(to: .init(x: 195 + cos(a) * 98, y: 272 + sin(a) * 98))
      context.stroke(ray, with: .color(Palette.gold.opacity(0.10)), lineWidth: 1)
    }
    cloud(&context, x: -14, y: 477, scale: 1.15, color: Palette.sky(for: game.board.id))
    cloud(&context, x: 242, y: 477, scale: 1.15, color: Palette.sky(for: game.board.id))
    cloud(&context, x: -25, y: 498, scale: 1.2, color: Palette.paper)
    cloud(&context, x: 240, y: 498, scale: 1.2, color: Palette.paper)
    var floor = Path()
    floor.move(to: .init(x: 45, y: 540))
    floor.addLine(to: .init(x: 345, y: 540))
    context.stroke(floor, with: .color(Palette.gold.opacity(0.4)), lineWidth: 1)
    for x in stride(from: 58.0, through: 340, by: 17) {
      circle(&context, x, 545, 1.2, Palette.gold.opacity(0.45))
    }
  }

  private func drawPeg(_ context: inout GraphicsContext, _ peg: Peg) {
    let p = peg.position
    let color: Color =
      peg.kind == .gold ? Palette.orange : (peg.kind == .green ? Palette.green : Palette.teal)
    let radius = peg.hit ? 11.0 : peg.radius
    circle(&context, p.x, p.y + 2.5, radius + 1.2, Palette.ink.opacity(0.12))
    if peg.hit { circle(&context, p.x, p.y, 16, color.opacity(0.14)) }
    let path = Path(
      ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
    context.fill(
      path,
      with: .radialGradient(
        Gradient(colors: [peg.hit ? .white : color.opacity(0.42), color, color.opacity(0.8)]),
        center: .init(x: p.x - 3, y: p.y - 4), startRadius: 0, endRadius: radius * 1.7))
    context.stroke(path, with: .color(peg.hit ? Palette.paper : color), lineWidth: 1.3)
    circle(&context, p.x - 3, p.y - 4, 2.5, .white.opacity(0.66))
    if peg.kind == .gold {
      circle(&context, p.x, p.y, 3, Palette.paper.opacity(peg.hit ? 1 : 0.7))
    } else if peg.kind == .green {
      var plus = Path()
      plus.move(to: .init(x: p.x - 3.5, y: p.y))
      plus.addLine(to: .init(x: p.x + 3.5, y: p.y))
      plus.move(to: .init(x: p.x, y: p.y - 3.5))
      plus.addLine(to: .init(x: p.x, y: p.y + 3.5))
      context.stroke(
        plus, with: .color(Palette.paper), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
    }
  }

  private func drawLauncher(_ context: inout GraphicsContext) {
    var launcher = context
    launcher.translateBy(x: 195, y: 48)
    launcher.rotate(by: .radians(-game.angle))
    let barrel = Path(roundedRect: CGRect(x: -10, y: 0, width: 20, height: 37), cornerRadius: 6)
    launcher.fill(
      barrel,
      with: .linearGradient(
        Gradient(colors: [Palette.gold, Color(red: 1, green: 0.86, blue: 0.53), Palette.gold]),
        startPoint: .init(x: -10, y: 0), endPoint: .init(x: 10, y: 0)))
    launcher.stroke(barrel, with: .color(Palette.gold), lineWidth: 1)
    circle(&context, 195, 46, 20, Palette.gold.opacity(0.14))
    circle(&context, 195, 46, 14, Palette.gold)
    circle(&context, 195, 46, 10, Color(red: 0.98, green: 0.84, blue: 0.53))
    star(&context, 195, 46, 7, Palette.paper)
    if game.phase == .aiming {
      drawBall(&context, .init(x: 195 + sin(game.angle) * 34, y: 48 + cos(game.angle) * 34))
    }
  }

  private func drawBall(_ context: inout GraphicsContext, _ point: Vector) {
    circle(&context, point.x, point.y, 10, Palette.gold.opacity(0.2))
    let path = Path(ellipseIn: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12))
    context.fill(
      path,
      with: .radialGradient(
        Gradient(colors: [.white, Palette.paper, Palette.gold]),
        center: .init(x: point.x - 2, y: point.y - 2), startRadius: 0, endRadius: 10))
    context.stroke(path, with: .color(Palette.gold), lineWidth: 1.5)
  }

  private func drawBucket(_ context: inout GraphicsContext) {
    let x = decorative ? 195 : game.bucketX
    var bucket = Path()
    bucket.move(to: .init(x: x - 44, y: 513))
    bucket.addQuadCurve(to: .init(x: x - 28, y: 535), control: .init(x: x - 42, y: 535))
    bucket.addLine(to: .init(x: x + 28, y: 535))
    bucket.addQuadCurve(to: .init(x: x + 44, y: 513), control: .init(x: x + 42, y: 535))
    bucket.closeSubpath()
    context.fill(
      bucket,
      with: .linearGradient(
        Gradient(colors: [Palette.gold, Color(red: 0.99, green: 0.83, blue: 0.50), Palette.gold]),
        startPoint: .init(x: x - 44, y: 513), endPoint: .init(x: x + 44, y: 535)))
    context.stroke(bucket, with: .color(Palette.gold), lineWidth: 1.5)
    let lip = Path(roundedRect: CGRect(x: x - 46, y: 509, width: 92, height: 6), cornerRadius: 3)
    context.fill(lip, with: .color(Palette.paper))
    context.stroke(lip, with: .color(Palette.gold), lineWidth: 1.3)
    star(&context, x, 525, 6, Palette.paper)
  }
}

struct GardenThumbnail: View {
  let board: Board
  var body: some View {
    Canvas { context, size in
      for peg in board.pegs {
        let x = peg.position.x / 390 * size.width
        let y = (peg.position.y - 105) / 380 * size.height
        let color =
          peg.kind == .gold ? Palette.orange : (peg.kind == .green ? Palette.green : Palette.teal)
        circle(&context, x, y, 2.3, color)
      }
    }
    .padding(5).frame(width: 68, height: 70)
    .background(Palette.sky(for: board.id).opacity(0.5), in: RoundedRectangle(cornerRadius: 22))
    .accessibilityHidden(true)
  }
}

func circle(_ context: inout GraphicsContext, _ x: Double, _ y: Double, _ r: Double, _ color: Color)
{
  context.fill(
    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(color))
}

func star(_ context: inout GraphicsContext, _ x: Double, _ y: Double, _ r: Double, _ color: Color) {
  var path = Path()
  for i in 0..<8 {
    let a = Double(i) * .pi / 4 - .pi / 2
    let radius = i % 2 == 0 ? r : r * 0.3
    let point = CGPoint(x: x + cos(a) * radius, y: y + sin(a) * radius)
    if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
  }
  path.closeSubpath()
  context.fill(path, with: .color(color))
}

func cloud(_ context: inout GraphicsContext, x: Double, y: Double, scale: Double, color: Color) {
  for (dx, dy, r) in [(0.0, 8.0, 23.0), (28, -3, 34), (66, 4, 27), (96, 16, 20)] {
    circle(&context, x + dx * scale, y + dy * scale, r * scale, color)
  }
  context.fill(
    Path(
      roundedRect: CGRect(
        x: x - 20 * scale, y: y + 4 * scale, width: 136 * scale, height: 35 * scale),
      cornerRadius: 16),
    with: .color(color))
}
