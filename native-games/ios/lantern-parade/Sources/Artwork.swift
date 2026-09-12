import SwiftUI

enum Ink {
  static let night = Color(red: 0.045, green: 0.068, blue: 0.16)
  static let panel = Color(red: 0.09, green: 0.12, blue: 0.22)
  static let gold = Color(red: 0.98, green: 0.77, blue: 0.42)
  static let cream = Color(red: 1, green: 0.93, blue: 0.79)
  static let muted = Color(red: 0.61, green: 0.66, blue: 0.77)
  static let rose = Color(red: 0.99, green: 0.57, blue: 0.61)
  static let jade = Color(red: 0.47, green: 0.83, blue: 0.72)
}

extension LanternColor {
  var ink: Color { [Ink.gold, Ink.rose, Ink.jade][rawValue] }
}

struct NightBackground: View {
  var body: some View {
    ZStack {
      Ink.night
      RadialGradient(
        colors: [Color(red: 0.16, green: 0.19, blue: 0.31), .clear],
        center: .init(x: 0.85, y: 0.24), startRadius: 0, endRadius: 480)
      Canvas { context, size in
        for index in 0..<75 {
          let x = CGFloat((index * 137 + 19) % 997) / 997 * size.width
          let y = CGFloat((index * 71 + 11) % 991) / 991 * size.height
          let radius: CGFloat = index % 7 == 0 ? 1.3 : 0.7
          context.fill(
            Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
            with: .color(Ink.cream.opacity(index % 3 == 0 ? 0.28 : 0.1)))
        }
      }
    }.ignoresSafeArea().accessibilityHidden(true)
  }
}

struct PaperLantern: View {
  var color: Color = Ink.gold
  var size: CGFloat = 34
  var body: some View {
    Canvas { context, bounds in
      Art.lantern(
        &context, at: CGPoint(x: bounds.width / 2, y: bounds.height / 2), radius: size / 2,
        color: color)
    }
    .frame(width: size * 1.8, height: size * 1.9)
    .accessibilityHidden(true)
  }
}

enum Art {
  static func line(
    _ context: inout GraphicsContext, from: CGPoint, to: CGPoint, color: Color, width: CGFloat = 1
  ) {
    var path = Path()
    path.move(to: from)
    path.addLine(to: to)
    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
  }

  static func lantern(
    _ context: inout GraphicsContext, at p: CGPoint, radius r: CGFloat, color: Color
  ) {
    context.fill(
      Path(ellipseIn: CGRect(x: p.x - r * 2.3, y: p.y - r * 2.3, width: r * 4.6, height: r * 4.6)),
      with: .radialGradient(
        Gradient(colors: [color.opacity(0.25), color.opacity(0)]),
        center: p, startRadius: r * 0.3, endRadius: r * 2.3))
    let rect = CGRect(x: p.x - r, y: p.y - r * 1.13, width: r * 2, height: r * 2.26)
    context.fill(
      Path(ellipseIn: rect),
      with: .linearGradient(
        Gradient(colors: [color, Ink.cream, color]), startPoint: CGPoint(x: rect.minX, y: p.y),
        endPoint: CGPoint(x: rect.maxX, y: p.y)))
    for offset in [-0.55, -0.28, 0.28, 0.55] {
      context.stroke(
        Path(ellipseIn: rect.insetBy(dx: r * abs(offset), dy: 0)),
        with: .color(Ink.night.opacity(0.15)), lineWidth: 0.65)
    }
    for y in [-1.12, 1.12] {
      let cap = CGRect(x: p.x - r * 0.42, y: p.y + r * y - 1.5, width: r * 0.84, height: 3)
      context.fill(Path(roundedRect: cap, cornerRadius: 1), with: .color(color))
    }
    line(
      &context, from: CGPoint(x: p.x, y: p.y + r * 1.2),
      to: CGPoint(x: p.x, y: p.y + r * 1.65), color: color.opacity(0.8), width: 1.4)
  }

  static func roof(_ context: inout GraphicsContext, rect: CGRect, seed: Int, lit: Bool) {
    let p = CGPoint(x: rect.midX, y: rect.midY)
    let body = CGRect(
      x: rect.minX + 3, y: rect.midY - 1, width: rect.width - 6, height: rect.height * 0.45)
    context.fill(
      Path(roundedRect: body, cornerRadius: 2),
      with: .color(Color(red: 0.18, green: 0.18, blue: 0.26)))
    var roof = Path()
    roof.move(to: CGPoint(x: rect.minX - 2, y: p.y + 2))
    roof.addLine(to: CGPoint(x: rect.minX + 5, y: rect.minY + 3))
    roof.addLine(to: CGPoint(x: rect.maxX - 6, y: rect.minY + 3))
    roof.addLine(to: CGPoint(x: rect.maxX + 2, y: p.y + 2))
    roof.closeSubpath()
    context.fill(
      roof, with: .color(Color(red: 0.31 + Double(seed % 3) * 0.025, green: 0.23, blue: 0.27)))
    context.stroke(roof, with: .color(Ink.rose.opacity(0.14)), lineWidth: 1)
    for i in 1...3 {
      let y = rect.minY + 3 + CGFloat(i) * rect.height * 0.105
      line(
        &context, from: CGPoint(x: rect.minX + 5 - CGFloat(i), y: y),
        to: CGPoint(x: rect.maxX - 6 + CGFloat(i), y: y), color: Ink.night.opacity(0.32))
    }
    for x in [-0.2, 0.2] {
      let window = CGRect(x: p.x + rect.width * x - 2, y: p.y + 5, width: 4, height: 5)
      context.fill(
        Path(window), with: .color(lit ? Ink.gold.opacity(0.85) : Ink.muted.opacity(0.23)))
    }
  }

  static func blossom(_ context: inout GraphicsContext, at p: CGPoint, scale: CGFloat) {
    line(
      &context, from: CGPoint(x: p.x, y: p.y + scale * 1.5),
      to: CGPoint(x: p.x - 2, y: p.y), color: Color(red: 0.39, green: 0.28, blue: 0.32), width: 2)
    for index in 0..<7 {
      let angle = Double(index) * 2.4
      let x = p.x + cos(angle) * scale * 0.6
      let y = p.y + sin(angle) * scale * 0.5
      context.fill(
        Path(
          ellipseIn: CGRect(x: x - scale * 0.5, y: y - scale * 0.5, width: scale, height: scale)),
        with: .color(Ink.rose.opacity(0.2 + Double(index % 3) * 0.1)))
    }
  }
}

struct BoardGeometry {
  let side: CGFloat
  let count: Int
  var inset: CGFloat { side * 0.09 }
  var step: CGFloat { (side - inset * 2) / CGFloat(count - 1) }
  func point(_ tile: Tile) -> CGPoint {
    CGPoint(x: inset + CGFloat(tile.x) * step, y: inset + CGFloat(tile.y) * step)
  }
  func tile(at point: CGPoint) -> Tile? {
    let x = Int(((point.x - inset) / step).rounded())
    let y = Int(((point.y - inset) / step).rounded())
    guard (0..<count).contains(x), (0..<count).contains(y) else { return nil }
    let tile = Tile(x: x, y: y)
    let center = self.point(tile)
    guard hypot(center.x - point.x, center.y - point.y) <= step * 0.48 else { return nil }
    return tile
  }
}

struct TownMap: View {
  let puzzle: Puzzle
  let route: [Tile]
  var celebrating = false
  var procession: Double = 0
  var hint = false
  var decorative = false
  var nextSteps: Set<Tile> = []

  var body: some View {
    Canvas { context, size in
      let geo = BoardGeometry(side: size.width, count: puzzle.size)
      let step = geo.step
      let lit = celebrating || decorative
      for y in 0..<puzzle.size - 1 {
        for x in 0..<puzzle.size - 1 {
          let p = geo.point(Tile(x: x, y: y))
          let seed = x * 13 + y * 7
          let narrow = seed % 3 == 1
          Art.roof(
            &context,
            rect: CGRect(
              x: p.x + step * (narrow ? 0.31 : 0.2), y: p.y + step * (seed % 2 == 0 ? 0.22 : 0.32),
              width: step * (narrow ? 0.4 : 0.58), height: step * (narrow ? 0.57 : 0.4)),
            seed: seed, lit: lit || (route.contains(Tile(x: x, y: y)) && seed % 2 == 0))
          if seed % 4 == 1 {
            Art.line(
              &context, from: CGPoint(x: p.x + step * 0.22, y: p.y + step * 0.74),
              to: CGPoint(x: p.x + step * 0.72, y: p.y + step * 0.74),
              color: Ink.gold.opacity(0.25), width: 1)
            for i in 0..<3 {
              context.fill(
                Path(
                  CGRect(
                    x: p.x + step * (0.25 + Double(i) * 0.18), y: p.y + step * 0.76, width: 3,
                    height: 4)),
                with: .color([Ink.gold, Ink.rose, Ink.jade][i].opacity(0.45)))
            }
          }
          if seed % 3 == 0 {
            Art.blossom(
              &context, at: CGPoint(x: p.x + step * 0.8, y: p.y + step * 0.72), scale: step * 0.16)
          }
        }
      }
      for y in 0..<puzzle.size {
        for x in 0..<puzzle.size {
          let tile = Tile(x: x, y: y)
          let p = geo.point(tile)
          if puzzle.blocked.contains(tile) {
            Art.blossom(&context, at: p, scale: step * 0.18)
            continue
          }
          for next in [Tile(x: x + 1, y: y), Tile(x: x, y: y + 1)]
          where next.x < puzzle.size && next.y < puzzle.size && !puzzle.blocked.contains(next) {
            Art.line(
              &context, from: p, to: geo.point(next), color: Ink.muted.opacity(0.12), width: 9)
            Art.line(
              &context, from: p, to: geo.point(next), color: Ink.muted.opacity(0.13), width: 1)
          }
          context.fill(
            Path(ellipseIn: CGRect(x: p.x - 3.5, y: p.y - 3.5, width: 7, height: 7)),
            with: .color(Ink.muted.opacity(0.4)))
          if nextSteps.contains(tile) {
            context.stroke(
              Path(ellipseIn: CGRect(x: p.x - 8, y: p.y - 8, width: 16, height: 16)),
              with: .color(Ink.gold.opacity(0.55)), lineWidth: 1)
            context.fill(
              Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)),
              with: .color(Ink.gold.opacity(0.8)))
          }
        }
      }
      if hint {
        strokeRoute(
          &context, route: puzzle.solution, geometry: geo, color: Ink.cream.opacity(0.45), width: 2,
          dash: [3, 7])
      }
      strokeRoute(&context, route: route, geometry: geo, color: Ink.gold.opacity(0.10), width: 18)
      strokeRoute(&context, route: route, geometry: geo, color: Ink.gold.opacity(0.22), width: 9)
      strokeRoute(&context, route: route, geometry: geo, color: Ink.gold, width: 3.5)

      let finish = geo.point(puzzle.finish)
      let r = step * 0.24
      context.fill(
        Path(
          ellipseIn: CGRect(x: finish.x - r * 2, y: finish.y - r * 2, width: r * 4, height: r * 4)),
        with: .radialGradient(
          Gradient(colors: [Ink.gold.opacity(lit ? 0.6 : 0.12), .clear]),
          center: finish, startRadius: 0, endRadius: r * 2))
      let square = CGRect(x: finish.x - r, y: finish.y - r, width: r * 2, height: r * 2)
      context.fill(Path(roundedRect: square, cornerRadius: 5), with: .color(Ink.panel))
      context.stroke(
        Path(roundedRect: square, cornerRadius: 5), with: .color(Ink.gold.opacity(0.75)),
        lineWidth: 1.5)
      context.draw(
        Text(Image(systemName: "sparkles")).font(.system(size: step * 0.29)).foregroundColor(
          Ink.gold),
        at: finish)

      let start = geo.point(puzzle.start)
      context.fill(
        Path(ellipseIn: CGRect(x: start.x - 10, y: start.y - 10, width: 20, height: 20)),
        with: .color(Ink.gold))
      context.draw(
        Text(Image(systemName: "flag.fill")).font(.system(size: 10)).foregroundColor(Ink.night),
        at: start)
      for (tile, gate) in puzzle.gates {
        let p = geo.point(tile)
        let open = route.compactMap { puzzle.lanterns[$0] }.contains(gate)
        let color = gate.ink.opacity(open ? 0.75 : 1)
        for x in [-1.0, 1.0] {
          Art.line(
            &context, from: CGPoint(x: p.x + x * (open ? 14 : 10), y: p.y - 9),
            to: CGPoint(x: p.x + x * (open ? 14 : 10), y: p.y + 10), color: color, width: 3)
        }
        Art.line(
          &context, from: CGPoint(x: p.x - 18, y: p.y - (open ? 16 : 10)),
          to: CGPoint(x: p.x + 18, y: p.y - (open ? 16 : 10)), color: color, width: 4)
        context.draw(
          Text(Image(systemName: open ? "checkmark" : gate.symbol)).font(.system(size: 9))
            .foregroundColor(color),
          at: CGPoint(x: p.x, y: p.y + (open ? -25 : 1)))
      }
      for (tile, lantern) in puzzle.lanterns {
        let p = geo.point(tile)
        Art.lantern(&context, at: p, radius: step * 0.17, color: lantern.ink)
        context.draw(
          Text("\(lantern.rawValue + 1)").font(.system(size: 10, weight: .heavy)).foregroundColor(
            Ink.night),
          at: p)
        if route.contains(tile) {
          context.stroke(
            Path(ellipseIn: CGRect(x: p.x - 16, y: p.y - 17, width: 32, height: 34)),
            with: .color(lantern.ink.opacity(0.6)), lineWidth: 1)
        }
      }
      if let head = route.last, !celebrating, !decorative {
        let p = geo.point(head)
        context.stroke(
          Path(ellipseIn: CGRect(x: p.x - 20, y: p.y - 20, width: 40, height: 40)),
          with: .color(Ink.cream.opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
      }
      if celebrating || decorative {
        for index in 0..<min(route.count, 9) {
          let progress = max(
            0,
            min(
              Double(route.count - 1), procession * Double(route.count + 3) - Double(index) * 0.52))
          let low = Int(progress)
          let high = min(low + 1, route.count - 1)
          let fraction = progress - Double(low)
          let a = geo.point(route[low])
          let b = geo.point(route[high])
          let p = CGPoint(x: a.x + (b.x - a.x) * fraction, y: a.y + (b.y - a.y) * fraction)
          context.fill(
            Path(ellipseIn: CGRect(x: p.x - 3, y: p.y + 2, width: 6, height: 8)),
            with: .color([Ink.rose, Ink.jade, Ink.gold][index % 3]))
          context.fill(
            Path(ellipseIn: CGRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4)),
            with: .color(Ink.cream))
          Art.lantern(&context, at: CGPoint(x: p.x + 5, y: p.y - 6), radius: 3.3, color: Ink.gold)
        }
        if celebrating {
          for index in 0..<30 {
            let phase = procession * 4 + Double(index) * 0.31
            let p = CGPoint(
              x: finish.x + sin(Double(index) * 4.1) * step
                * (0.4 + phase.truncatingRemainder(dividingBy: 1)),
              y: finish.y - phase.truncatingRemainder(dividingBy: 1) * step * 1.8)
            context.fill(
              Path(ellipseIn: CGRect(x: p.x, y: p.y, width: 2.5, height: 2.5)),
              with: .color(Ink.gold.opacity(0.65)))
          }
        }
      }
    }.aspectRatio(1, contentMode: .fit).accessibilityHidden(true)
  }

  private func strokeRoute(
    _ context: inout GraphicsContext, route: [Tile], geometry: BoardGeometry, color: Color,
    width: CGFloat, dash: [CGFloat] = []
  ) {
    guard let first = route.first else { return }
    var path = Path()
    path.move(to: geometry.point(first))
    for tile in route.dropFirst() { path.addLine(to: geometry.point(tile)) }
    context.stroke(
      path, with: .color(color),
      style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))
  }
}

struct GoldButtonStyle: ButtonStyle {
  var secondary = false
  @Environment(\.isEnabled) private var isEnabled
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 16, weight: .semibold))
      .frame(maxWidth: .infinity, minHeight: 54)
      .foregroundStyle(secondary ? Ink.cream : Ink.night)
      .background(secondary ? Ink.panel : Ink.gold, in: RoundedRectangle(cornerRadius: 18))
      .overlay(
        RoundedRectangle(cornerRadius: 18).stroke(
          Ink.gold.opacity(secondary ? 0.2 : 0), lineWidth: 1)
      )
      .opacity(!isEnabled ? 0.35 : configuration.isPressed ? 0.7 : 1)
  }
}

struct FestivalVignette: View {
  var body: some View {
    Canvas { context, size in
      let w = size.width
      let h = size.height
      var river = Path()
      river.move(to: CGPoint(x: -20, y: h * 0.84))
      river.addCurve(
        to: CGPoint(x: w + 20, y: h * 0.3),
        control1: CGPoint(x: w * 0.4, y: h * 0.7),
        control2: CGPoint(x: w * 0.55, y: h * 0.38))
      context.stroke(river, with: .color(Ink.jade.opacity(0.045)), lineWidth: 42)
      context.stroke(river, with: .color(Ink.jade.opacity(0.1)), lineWidth: 1)
      for index in 0..<27 {
        let row = index / 7
        let col = index % 7
        let x = CGFloat(col) * w * 0.14 + CGFloat(row % 2) * 17 - 5
        let y = h * 0.25 + CGFloat(row) * h * 0.155 + sin(Double(col) * 0.8) * 12
        let width = w * (index % 3 == 0 ? 0.13 : 0.11)
        Art.roof(
          &context, rect: CGRect(x: x, y: y, width: width, height: width * 0.86), seed: index,
          lit: index % 3 == 0)
        if index % 4 == 0 {
          Art.blossom(&context, at: CGPoint(x: x + width, y: y + width * 0.8), scale: 10)
        }
      }
      var ribbon = Path()
      ribbon.move(to: CGPoint(x: w * 0.1, y: h * 0.88))
      ribbon.addCurve(
        to: CGPoint(x: w * 0.87, y: h * 0.5),
        control1: CGPoint(x: w * 0.13, y: h * 0.51),
        control2: CGPoint(x: w * 0.65, y: h * 0.96))
      context.stroke(ribbon, with: .color(Ink.gold.opacity(0.13)), lineWidth: 14)
      context.stroke(
        ribbon, with: .color(Ink.gold.opacity(0.85)),
        style: StrokeStyle(lineWidth: 2, lineCap: .round))
      for strand in 0..<2 {
        var wire = Path()
        wire.move(to: CGPoint(x: -15, y: h * (0.06 + Double(strand) * 0.11)))
        wire.addQuadCurve(
          to: CGPoint(x: w + 15, y: h * (0.03 + Double(strand) * 0.09)),
          control: CGPoint(x: w * 0.55, y: h * (0.3 + Double(strand) * 0.13)))
        context.stroke(wire, with: .color(Ink.gold.opacity(0.25)), lineWidth: 1)
        for i in 0..<6 {
          let t = Double(i + 1) / 7
          let y =
            pow(1 - t, 2) * h * (0.06 + Double(strand) * 0.11)
            + 2 * (1 - t) * t * h * (0.3 + Double(strand) * 0.13)
            + t * t * h * (0.03 + Double(strand) * 0.09)
          Art.lantern(
            &context, at: CGPoint(x: t * (w + 30) - 15, y: y + 8),
            radius: strand == 0 ? 6 : 4, color: [Ink.gold, Ink.rose, Ink.gold][i % 3])
        }
      }
    }.accessibilityHidden(true)
  }
}

struct Eyebrow: View {
  let text: String
  var body: some View {
    Text(text.uppercased()).font(.system(size: 10, weight: .semibold, design: .monospaced))
      .tracking(2.5).foregroundStyle(Ink.gold)
  }
}

struct Stars: View {
  let count: Int
  var body: some View {
    HStack(spacing: 5) {
      ForEach(0..<3) { index in
        Image(systemName: index < count ? "star.fill" : "star")
          .foregroundStyle(index < count ? Ink.gold : Ink.muted.opacity(0.4))
      }
    }.accessibilityLabel("\(count) of 3 stars")
  }
}
