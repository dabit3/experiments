import SwiftUI

enum Winter {
  static let midnight = Color(red: 0.055, green: 0.15, blue: 0.22)
  static let ink = Color(red: 0.12, green: 0.26, blue: 0.34)
  static let powder = Color(red: 0.79, green: 0.89, blue: 0.94)
  static let cream = Color(red: 0.98, green: 0.96, blue: 0.88)
  static let amber = Color(red: 1, green: 0.76, blue: 0.38)
  static let cranberry = Color(red: 0.66, green: 0.16, blue: 0.26)
}

struct WinterBackdrop: View {
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        LinearGradient(
          colors: [Winter.midnight, Color(red: 0.13, green: 0.30, blue: 0.39)],
          startPoint: .topLeading, endPoint: .bottomTrailing)
        Canvas { context, size in
          for index in 0..<70 {
            let x = CGFloat((index * 97 + 21) % 997) / 997 * size.width
            let y = CGFloat((index * 137 + 49) % 991) / 991 * size.height
            let radius: CGFloat = index.isMultiple(of: 5) ? 1.8 : 0.8
            context.fill(
              Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
              with: .color(Winter.powder.opacity(index.isMultiple(of: 3) ? 0.3 : 0.12)))
          }
        }
        Ellipse()
          .fill(Winter.powder.opacity(0.035))
          .frame(width: geometry.size.width * 1.8, height: 400)
          .offset(y: geometry.size.height * 0.5)
      }
    }
    .ignoresSafeArea()
  }
}

struct VillageArt: View, Animatable {
  let journey: Journey
  var selected: Direction?
  var illuminated = false
  var animate = true
  var vanColumn: Double
  var vanRow: Double
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  init(
    journey: Journey, selected: Direction? = nil, illuminated: Bool = false, animate: Bool = true
  ) {
    self.journey = journey
    self.selected = selected
    self.illuminated = illuminated
    self.animate = animate
    vanColumn = Double(journey.position.van.column)
    vanRow = Double(journey.position.van.row)
  }

  var animatableData: AnimatablePair<Double, Double> {
    get { AnimatablePair(vanColumn, vanRow) }
    set {
      vanColumn = newValue.first
      vanRow = newValue.second
    }
  }

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 24, paused: reduceMotion || !animate)) {
      timeline in
      Canvas { context, size in
        draw(
          context: &context, width: size.width,
          time: reduceMotion || !animate ? 0 : timeline.date.timeIntervalSinceReferenceDate)
      }
    }
    .aspectRatio(1.06, contentMode: .fit)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "Snow globe village. Van at column \(journey.position.van.column + 1), row \(journey.position.van.row + 1). \(journey.position.delivered.count) of 3 homes lit."
    )
  }

  private func draw(context: inout GraphicsContext, width: CGFloat, time: Double) {
    let w = width
    let glass = CGRect(x: w * 0.045, y: w * 0.015, width: w * 0.91, height: w * 0.86)
    let globe = Path(ellipseIn: glass)
    context.fill(
      globe,
      with: .linearGradient(
        Gradient(colors: [Winter.powder.opacity(0.14), Winter.powder.opacity(0.025)]),
        startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: w, y: w)))
    context.stroke(globe, with: .color(Winter.powder.opacity(0.45)), lineWidth: 1)
    let halo = Path(ellipseIn: glass.insetBy(dx: 7, dy: 7))
    context.stroke(halo, with: .color(.white.opacity(0.08)), lineWidth: 3)
    var glint = Path()
    glint.addArc(
      center: CGPoint(x: w * 0.5, y: w * 0.445), radius: w * 0.414,
      startAngle: .degrees(202), endAngle: .degrees(247), clockwise: false)
    context.stroke(
      glint, with: .color(.white.opacity(0.58)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    let ground = CGRect(x: w * 0.09, y: w * 0.43, width: w * 0.82, height: w * 0.32)
    context.fill(
      Path(ellipseIn: ground.offsetBy(dx: 0, dy: 12)), with: .color(.black.opacity(0.13)))
    context.fill(
      Path(ellipseIn: ground),
      with: .linearGradient(
        Gradient(colors: [Winter.cream, Winter.powder]),
        startPoint: .zero, endPoint: CGPoint(x: 0, y: w)))
    let sx = w * 0.080
    let sy = w * 0.051
    func point(_ square: Square) -> CGPoint {
      CGPoint(
        x: w * 0.5 + CGFloat(square.column - square.row) * sx,
        y: w * 0.28 + CGFloat(square.column + square.row) * sy)
    }
    for diagonal in 0...8 {
      for row in 0..<5 {
        let column = diagonal - row
        guard (0..<5).contains(column) else { continue }
        let square = Square(column: column, row: row)
        let p = point(square)
        let depth = journey.position.snow[square.index]
        let tile = diamond(p, x: sx - 1.5, y: sy - 1)
        context.fill(
          tile.offsetBy(dx: 0, dy: 4), with: .color(Color(red: 0.50, green: 0.68, blue: 0.77)))
        let tileColor = depth > 0 ? Winter.cream : Color(red: 0.61, green: 0.77, blue: 0.83)
        context.fill(tile, with: .color(tileColor))
        context.stroke(tile, with: .color(.white.opacity(0.48)), lineWidth: 0.6)
        if let selected, journey.position.van.next(selected) == square {
          context.fill(tile, with: .color(Winter.amber.opacity(0.55)))
          context.stroke(tile, with: .color(Winter.amber), lineWidth: 2)
        }
        if depth == 0 && !journey.puzzle.trees.contains(square) {
          var track = Path()
          track.move(to: CGPoint(x: p.x - sx * 0.54, y: p.y))
          track.addLine(to: CGPoint(x: p.x + sx * 0.54, y: p.y))
          context.stroke(
            track, with: .color(.white.opacity(0.25)),
            style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
        }
        if depth > 0 {
          for layer in 0..<depth {
            let drift = CGRect(
              x: p.x - sx * 0.65, y: p.y - 6 - CGFloat(layer) * 4,
              width: sx * 1.3, height: sy * 0.65)
            context.fill(
              Path(ellipseIn: drift),
              with: .color(layer == depth - 1 ? .white : Winter.powder))
          }
        }
        if journey.puzzle.trees.contains(square) {
          drawTree(p, scale: w / 420, context: &context)
        }
        if let home = journey.puzzle.homes.first(where: { $0.square == square }) {
          drawHouse(
            p, scale: w / 410, index: journey.puzzle.homes.firstIndex(of: home) ?? 0,
            lit: illuminated || journey.position.delivered.contains(square),
            context: &context)
        }
      }
    }
    let doorstep =
      journey.puzzle.homes.map { home in
        max(0, 1 - hypot(vanColumn - Double(home.square.column), vanRow - Double(home.square.row)))
      }.max() ?? 0
    let van = CGPoint(
      x: w * 0.5 + CGFloat(vanColumn - vanRow) * sx - CGFloat(doorstep) * w * 0.02,
      y: w * 0.28 + CGFloat(vanColumn + vanRow) * sy + CGFloat(doorstep) * w * 0.05)
    drawVan(van, scale: w / 400, context: &context)
    for (index, home) in journey.puzzle.homes.enumerated() {
      let p = point(home.square)
      let s = w / 400
      let lit = illuminated || journey.position.delivered.contains(home.square)
      let badge = CGPoint(x: p.x - 25 * s, y: p.y - 12 * s)
      context.fill(
        Path(
          ellipseIn: CGRect(x: badge.x - 9 * s, y: badge.y - 9 * s, width: 18 * s, height: 18 * s)),
        with: .color(lit ? Winter.amber : home.priority ? Winter.cranberry : Winter.ink))
      context.stroke(
        Path(
          ellipseIn: CGRect(x: badge.x - 9 * s, y: badge.y - 9 * s, width: 18 * s, height: 18 * s)),
        with: .color(Winter.cream), lineWidth: 1)
      drawText(
        lit ? "✓" : "\(index + 1)", at: badge, size: 11 * s,
        color: lit ? Winter.ink : .white, context: &context, weight: .bold)
    }
    for index in 0..<25 where journey.position.snow[index] > 0 {
      let p = point(Square(column: index % 5, row: index / 5))
      let s = w / 400
      let center = CGPoint(x: p.x, y: p.y + sy * 0.72)
      context.fill(
        Path(
          roundedRect: CGRect(
            x: center.x - 12 * s, y: center.y - 6 * s, width: 24 * s, height: 12 * s),
          cornerRadius: 6 * s),
        with: .color(Winter.ink))
      var snowflake = Path()
      for arm in 0..<3 {
        let angle = Double(arm) * .pi / 3
        let dx = cos(angle) * 3 * s
        let dy = sin(angle) * 3 * s
        snowflake.move(to: CGPoint(x: center.x - 5 * s - dx, y: center.y - dy))
        snowflake.addLine(to: CGPoint(x: center.x - 5 * s + dx, y: center.y + dy))
      }
      context.stroke(snowflake, with: .color(Winter.powder), lineWidth: 1)
      drawText(
        "\(journey.position.snow[index])", at: CGPoint(x: center.x + 5 * s, y: center.y),
        size: 9 * s, color: .white, context: &context, weight: .bold)
    }
    if illuminated {
      for index in 0..<12 {
        let angle = Double(index) * .pi / 6 + time * 0.06
        let x = w * 0.5 + CGFloat(cos(angle)) * w * 0.37
        let y = w * 0.43 + CGFloat(sin(angle)) * w * 0.31
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 3)),
          with: .color(Winter.amber.opacity(0.65)))
      }
    }
    for index in 0..<34 {
      let speed = Double(7 + index % 9)
      let x = w * (0.13 + CGFloat((index * 73) % 100) / 135)
      let y =
        w * 0.10
        + CGFloat(
          (Double((index * 31) % 210) + time * speed).truncatingRemainder(
            dividingBy: Double(w * 0.60)))
      let radius: CGFloat = index.isMultiple(of: 4) ? 2 : 1
      let flake = Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius))
      context.fill(flake, with: .color(.white.opacity(0.5)))
    }
    let base = CGRect(x: w * 0.19, y: w * 0.795, width: w * 0.62, height: w * 0.072)
    context.fill(
      Path(roundedRect: base.offsetBy(dx: 0, dy: 8), cornerRadius: 8),
      with: .color(.black.opacity(0.18)))
    context.fill(
      Path(roundedRect: base, cornerRadius: 8),
      with: .linearGradient(
        Gradient(colors: [
          Color(red: 0.78, green: 0.60, blue: 0.38), Color(red: 0.43, green: 0.31, blue: 0.22),
        ]),
        startPoint: CGPoint(x: 0, y: base.minY), endPoint: CGPoint(x: 0, y: base.maxY)))
    context.fill(
      Path(
        roundedRect: CGRect(x: w * 0.18, y: w * 0.777, width: w * 0.64, height: w * 0.027),
        cornerRadius: 4),
      with: .color(Winter.cream))
    drawText(
      "S N O W G L O B E   E X P R E S S",
      at: CGPoint(x: w * 0.5, y: w * 0.834), size: max(7, w * 0.023),
      color: Winter.cream, context: &context, weight: .semibold)
  }

  private func diamond(_ p: CGPoint, x: CGFloat, y: CGFloat) -> Path {
    polygon([
      CGPoint(x: p.x, y: p.y - y), CGPoint(x: p.x + x, y: p.y),
      CGPoint(x: p.x, y: p.y + y), CGPoint(x: p.x - x, y: p.y),
    ])
  }

  private func polygon(_ points: [CGPoint]) -> Path {
    Path { path in
      path.addLines(points)
      path.closeSubpath()
    }
  }

  private func drawHouse(
    _ p: CGPoint, scale: CGFloat, index: Int, lit: Bool,
    context: inout GraphicsContext
  ) {
    let s = scale
    let x = p.x
    let y = p.y - 5 * s
    if lit {
      context.fill(
        Path(ellipseIn: CGRect(x: x - 27 * s, y: y - 22 * s, width: 54 * s, height: 48 * s)),
        with: .radialGradient(
          Gradient(colors: [Winter.amber.opacity(0.45), .clear]), center: p,
          startRadius: 0, endRadius: 30 * s))
    }
    let wall = CGRect(x: x - 17 * s, y: y - 22 * s, width: 34 * s, height: 28 * s)
    context.fill(
      Path(roundedRect: wall, cornerRadius: 2 * s),
      with: .color(index == 1 ? Winter.powder : Winter.cream))
    context.fill(
      Path(CGRect(x: x + 7 * s, y: y - 22 * s, width: 10 * s, height: 28 * s)),
      with: .color(Winter.ink.opacity(0.14)))
    let roof = polygon([
      CGPoint(x: x - 22 * s, y: y - 21 * s), CGPoint(x: x - 5 * s, y: y - 43 * s),
      CGPoint(x: x + 7 * s, y: y - 43 * s), CGPoint(x: x + 22 * s, y: y - 21 * s),
    ])
    context.fill(roof, with: .color(index == 0 ? Winter.cranberry : Winter.ink))
    let snowcap = polygon([
      CGPoint(x: x - 23 * s, y: y - 22 * s), CGPoint(x: x - 5 * s, y: y - 45 * s),
      CGPoint(x: x + 7 * s, y: y - 45 * s), CGPoint(x: x + 24 * s, y: y - 22 * s),
      CGPoint(x: x + 12 * s, y: y - 25 * s), CGPoint(x: x + 1 * s, y: y - 39 * s),
      CGPoint(x: x - 10 * s, y: y - 26 * s),
    ])
    context.fill(snowcap, with: .color(.white))
    context.fill(
      Path(CGRect(x: x + 8 * s, y: y - 44 * s, width: 5 * s, height: 10 * s)),
      with: .color(Winter.cream))
    for offset: CGFloat in [-10, 7] {
      let window = CGRect(x: x + offset * s, y: y - 16 * s, width: 7 * s, height: 9 * s)
      context.fill(
        Path(roundedRect: window, cornerRadius: 1.5),
        with: .color(lit ? Winter.amber : Winter.ink.opacity(0.65)))
      if lit {
        context.stroke(Path(window), with: .color(.white.opacity(0.55)), lineWidth: 0.7)
      }
    }
    context.fill(
      Path(
        roundedRect: CGRect(x: x - 2 * s, y: y - 8 * s, width: 6 * s, height: 14 * s),
        cornerRadius: 2),
      with: .color(Winter.cranberry))
  }

  private func drawTree(_ p: CGPoint, scale s: CGFloat, context: inout GraphicsContext) {
    context.fill(
      Path(CGRect(x: p.x - 2 * s, y: p.y - 9 * s, width: 4 * s, height: 14 * s)),
      with: .color(Color(red: 0.42, green: 0.37, blue: 0.30)))
    for layer in 0..<3 {
      let y = p.y - CGFloat(layer * 9) * s
      let span = CGFloat(15 - layer * 3) * s
      let triangle = polygon([
        CGPoint(x: p.x - span, y: y), CGPoint(x: p.x, y: y - 23 * s),
        CGPoint(x: p.x + span, y: y),
      ])
      context.fill(
        triangle, with: .color(layer == 1 ? Color(red: 0.23, green: 0.44, blue: 0.45) : Winter.ink))
      let cap = polygon([
        CGPoint(x: p.x - span * 0.7, y: y - 7 * s),
        CGPoint(x: p.x, y: y - 24 * s), CGPoint(x: p.x + span * 0.7, y: y - 7 * s),
        CGPoint(x: p.x + 3 * s, y: y - 10 * s), CGPoint(x: p.x - 3 * s, y: y - 6 * s),
      ])
      context.fill(cap, with: .color(Winter.cream))
    }
  }

  private func drawVan(_ p: CGPoint, scale s: CGFloat, context: inout GraphicsContext) {
    let y = p.y + 1 * s
    context.fill(
      Path(ellipseIn: CGRect(x: p.x - 23 * s, y: y - 3 * s, width: 47 * s, height: 16 * s)),
      with: .color(Winter.ink.opacity(0.23)))
    for offset: CGFloat in [-11, 13] {
      context.fill(
        Path(ellipseIn: CGRect(x: p.x + offset * s - 4 * s, y: y, width: 8 * s, height: 9 * s)),
        with: .color(Winter.midnight))
    }
    let body = CGRect(x: p.x - 20 * s, y: y - 20 * s, width: 40 * s, height: 25 * s)
    context.fill(Path(roundedRect: body, cornerRadius: 6 * s), with: .color(Winter.cranberry))
    context.fill(
      Path(
        roundedRect: CGRect(x: p.x - 20 * s, y: y - 21 * s, width: 29 * s, height: 5 * s),
        cornerRadius: 3),
      with: .color(Winter.cream))
    context.fill(
      Path(
        roundedRect: CGRect(x: p.x + 6 * s, y: y - 16 * s, width: 11 * s, height: 10 * s),
        cornerRadius: 2),
      with: .color(Winter.powder))
    context.fill(
      Path(CGRect(x: p.x - 9 * s, y: y - 10 * s, width: 9 * s, height: 8 * s)),
      with: .color(Winter.cream))
    context.stroke(
      Path(CGRect(x: p.x - 5 * s, y: y - 10 * s, width: 1, height: 8 * s)),
      with: .color(Winter.cranberry), lineWidth: 1)
    context.fill(
      Path(
        roundedRect: CGRect(x: p.x + 20 * s, y: y - 4 * s, width: 7 * s, height: 13 * s),
        cornerRadius: 2),
      with: .color(Winter.powder))
    context.fill(
      Path(ellipseIn: CGRect(x: p.x + 15 * s, y: y - 2 * s, width: 5 * s, height: 4 * s)),
      with: .color(Winter.amber))
  }

  private func drawText(
    _ text: String, at point: CGPoint, size: CGFloat, color: Color,
    context: inout GraphicsContext, weight: Font.Weight = .regular
  ) {
    context.draw(
      Text(text).font(.system(size: size, weight: weight, design: .rounded)).foregroundColor(color),
      at: point)
  }
}
