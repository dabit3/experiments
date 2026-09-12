import SwiftUI

enum Palette {
  static let ink = Color(hex: 0x343D38)
  static let cream = Color(hex: 0xF5EFDF)
  static let muted = Color(hex: 0xAFB7A2)
  static let walnut = Color(hex: 0x3E342D)
  static let coral = Color(hex: 0xCF745E)
  static let sage = Color(hex: 0x7F9D87)
  static let brass = Color(hex: 0xBC914D)
  static let blue = Color(hex: 0x83ADB5)
}

extension Color {
  init(hex: UInt32) {
    self.init(
      .sRGB, red: Double((hex >> 16) & 255) / 255,
      green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
  }
}

struct WalnutBackground: View {
  var body: some View {
    GeometryReader { geometry in
      Canvas { context, size in
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Palette.walnut))
        for index in 0..<60 {
          let x = CGFloat(index) * size.width / 55
          var line = Path()
          line.move(to: CGPoint(x: x, y: 0))
          line.addCurve(
            to: CGPoint(x: x + 50, y: size.height),
            control1: CGPoint(x: x - 45, y: size.height * 0.35),
            control2: CGPoint(x: x + 60, y: size.height * 0.65))
          context.stroke(
            line, with: .color(.black.opacity(index.isMultiple(of: 3) ? 0.10 : 0.035)),
            lineWidth: index.isMultiple(of: 3) ? 2 : 0.6)
        }
      }
      .overlay(
        LinearGradient(
          colors: [.white.opacity(0.08), .clear, .black.opacity(0.18)],
          startPoint: .topLeading, endPoint: .bottomTrailing)
      )
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .ignoresSafeArea()
  }
}

struct TabletopView: View {
  let puzzle: Puzzle
  let pieces: [Cell: Piece]
  var selected: Cell?
  var result: ChainResult?
  var beat: Double = -1
  var guides = true
  var reduceMotion = false
  var interactive = true
  var tap: (Cell) -> Void = { _ in }

  var body: some View {
    GeometryReader { geometry in
      let layout = BoardLayout(size: geometry.size)
      ZStack {
        Canvas { context, size in
          TablePainter(
            puzzle: puzzle, pieces: pieces, selected: selected, result: result,
            beat: beat, guides: guides, reduceMotion: reduceMotion
          ).draw(context: &context, size: size)
        }
        if interactive {
          ForEach(0..<63, id: \.self) { index in
            let cell = Cell(x: index % 7, y: index / 7)
            let center = layout.point(cell)
            Button {
              tap(cell)
            } label: {
              Color.clear.contentShape(Rectangle())
            }
            .frame(width: layout.unit, height: layout.unit)
            .position(center)
            .accessibilityLabel(cellLabel(cell))
            .accessibilityIdentifier("cell-\(cell.x)-\(cell.y)")
            .accessibilityHint(puzzle.canEdit(cell) ? "Place or select a piece" : "Fixed scenery")
          }
        }
      }
    }
    .aspectRatio(0.84, contentMode: .fit)
  }

  private func cellLabel(_ cell: Cell) -> String {
    let coordinate = "\(String(UnicodeScalar(65 + cell.x)!))\(cell.y + 1)"
    if cell == puzzle.start { return "\(coordinate), start trigger" }
    if puzzle.targets.contains(cell) { return "\(coordinate), bell target" }
    if let piece = pieces[cell] {
      return
        "\(coordinate), \(piece.kind.title), rotation \(piece.rotation), \(puzzle.fixed[cell] == nil ? "editable" : "fixed")"
    }
    return "\(coordinate), \(puzzle.canEdit(cell) ? "empty socket" : "scenery")"
  }
}

struct BoardLayout {
  let size: CGSize
  var unit: CGFloat { min(size.width / 8.1, size.height / 10.2) }
  var origin: CGPoint {
    CGPoint(x: (size.width - unit * 6) / 2, y: (size.height - unit * 8) / 2)
  }
  func point(_ cell: Cell) -> CGPoint {
    CGPoint(x: origin.x + CGFloat(cell.x) * unit, y: origin.y + CGFloat(cell.y) * unit)
  }
}

struct TablePainter {
  let puzzle: Puzzle
  let pieces: [Cell: Piece]
  let selected: Cell?
  let result: ChainResult?
  let beat: Double
  let guides: Bool
  let reduceMotion: Bool

  func draw(context: inout GraphicsContext, size: CGSize) {
    let layout = BoardLayout(size: size)
    let u = layout.unit
    let rect = CGRect(x: 5, y: 5, width: size.width - 10, height: size.height - 16)
    rounded(
      &context, rect.offsetBy(dx: 0, dy: 7), radius: 22, color: Color(hex: 0x1F241E).opacity(0.3))
    rounded(&context, rect, radius: 22, color: Color(hex: 0xCECBB2))
    rounded(&context, rect.insetBy(dx: 5, dy: 5), radius: 18, color: Color(hex: 0xE0DDC9))
    context.stroke(
      Path(roundedRect: rect.insetBy(dx: 10, dy: 10), cornerRadius: 13),
      with: .color(Palette.ink.opacity(0.12)), lineWidth: 0.8)
    for row in 0..<9 {
      for column in 0..<7 {
        let cell = Cell(x: column, y: row)
        let p = layout.point(cell)
        circle(&context, p, radius: 1, color: Palette.sage.opacity(0.35))
      }
      text(
        &context, "\(row + 1)",
        at: CGPoint(x: layout.origin.x - u * 0.66, y: layout.point(Cell(x: 0, y: row)).y),
        size: u * 0.22, color: Palette.ink.opacity(0.68))
    }
    for column in 0..<7 {
      text(
        &context, String(UnicodeScalar(65 + column)!),
        at: CGPoint(
          x: layout.point(Cell(x: column, y: 0)).x,
          y: layout.origin.y - u * 0.65),
        size: u * 0.22, color: Palette.ink.opacity(0.68))
    }
    for water in puzzle.water {
      let p = layout.point(water)
      rounded(
        &context, CGRect(x: p.x - u * 0.47, y: p.y - u * 0.47, width: u * 0.94, height: u * 0.94),
        radius: u * 0.2, color: Palette.blue)
      for offset in [-0.22, 0.0, 0.22] {
        var wave = Path()
        wave.move(to: CGPoint(x: p.x - u * 0.32, y: p.y + offset * u))
        wave.addQuadCurve(
          to: CGPoint(x: p.x + u * 0.32, y: p.y + offset * u),
          control: CGPoint(x: p.x, y: p.y + (offset - 0.16) * u))
        context.stroke(wave, with: .color(Palette.cream.opacity(0.6)), lineWidth: 1)
      }
    }
    scenery(&context, layout: layout)
    if guides {
      for cell in puzzle.sockets where pieces[cell] == nil {
        let p = layout.point(cell)
        let slot = CGRect(x: p.x - u * 0.41, y: p.y - u * 0.41, width: u * 0.82, height: u * 0.82)
        context.stroke(
          Path(roundedRect: slot, cornerRadius: u * 0.14),
          with: .color(Palette.sage.opacity(0.8)), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
        text(&context, "+", at: p, size: u * 0.4, color: Palette.sage.opacity(0.7))
      }
    }
    for cell in pieces.keys.sorted(by: { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }) {
      guard let piece = pieces[cell] else { continue }
      let p = layout.point(cell)
      let event = result?.events.first { $0.cell == cell }
      let progress = event.map { max(0, min(1, beat - Double($0.beat))) } ?? 0
      drawPiece(
        &context, at: p, unit: u, piece: piece, editable: puzzle.fixed[cell] == nil,
        fall: reduceMotion ? (progress > 0.1 ? 1 : 0) : progress,
        direction: event?.direction ?? .east,
        bridgeExit: piece.ports.first { puzzle.water.contains(cell.moved($0)) } ?? piece.ports[1])
    }
    trigger(&context, at: layout.point(puzzle.start), u: u, active: beat >= 0)
    for (index, target) in puzzle.targets.enumerated() {
      let event = result?.events.first { $0.cell == target }
      let active = event.map { beat >= Double($0.beat) } ?? false
      bell(&context, at: layout.point(target), u: u, active: active, number: index + 1)
    }
    if let selected {
      let p = layout.point(selected)
      context.stroke(
        Path(
          roundedRect: CGRect(
            x: p.x - u * 0.46, y: p.y - u * 0.46, width: u * 0.92, height: u * 0.92),
          cornerRadius: u * 0.16),
        with: .color(Palette.brass), lineWidth: 2.5)
    }
    if let result, beat > Double(result.events.map(\.beat).max() ?? 0) + 0.6, !result.won {
      for cell in result.failures.keys where puzzle.contains(cell) {
        let p = layout.point(cell)
        circle(&context, p, radius: u * 0.46, color: Palette.coral.opacity(0.17))
        text(
          &context, "!", at: CGPoint(x: p.x + u * 0.32, y: p.y - u * 0.3),
          size: u * 0.32, color: Palette.coral)
      }
    }
  }

  private func drawPiece(
    _ context: inout GraphicsContext, at p: CGPoint, unit u: CGFloat,
    piece: Piece, editable: Bool, fall: Double, direction: Direction, bridgeExit: Direction
  ) {
    let tint: Color =
      piece.kind == .bridge
      ? Palette.blue
      : piece.kind == .fork
        ? Palette.coral
        : piece.kind == .turn ? Color(hex: 0xBCACBD) : Palette.sage
    let plate = CGRect(x: p.x - u * 0.39, y: p.y - u * 0.34, width: u * 0.78, height: u * 0.7)
    rounded(
      &context, plate.offsetBy(dx: u * 0.04, dy: u * 0.09), radius: u * 0.12,
      color: Palette.ink.opacity(0.15))
    rounded(&context, plate, radius: u * 0.12, color: tint.opacity(editable ? 0.80 : 0.32))
    context.stroke(
      Path(roundedRect: plate.insetBy(dx: 1.5, dy: 1.5), cornerRadius: u * 0.09),
      with: .color(Palette.cream.opacity(0.7)), lineWidth: 0.7)
    for port in piece.ports {
      let end = CGPoint(x: p.x + CGFloat(port.dx) * u * 0.49, y: p.y + CGFloat(port.dy) * u * 0.49)
      var rail = Path()
      rail.move(to: p)
      rail.addLine(to: end)
      context.stroke(
        rail, with: .color(tint.opacity(0.65)),
        style: StrokeStyle(lineWidth: u * 0.11, lineCap: .round))
      let dot = CGPoint(x: p.x + CGFloat(port.dx) * u * 0.35, y: p.y + CGFloat(port.dy) * u * 0.35)
      circle(&context, dot, radius: u * 0.035, color: Palette.cream)
    }
    if piece.kind == .bridge {
      var ramp = Path()
      let d = bridgeExit
      let end = CGPoint(x: p.x + CGFloat(d.dx) * u * 1.25, y: p.y + CGFloat(d.dy) * u * 1.25)
      ramp.move(to: p)
      ramp.addQuadCurve(
        to: end, control: CGPoint(x: (p.x + end.x) / 2 - u * 0.12, y: (p.y + end.y) / 2 - u * 0.36))
      context.stroke(
        ramp, with: .color(Palette.blue.opacity(0.8)),
        style: StrokeStyle(lineWidth: u * 0.22, lineCap: .round))
      context.stroke(
        ramp, with: .color(Palette.cream.opacity(0.65)),
        style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
    }
    var positions = [p]
    for port in piece.ports {
      positions.append(
        CGPoint(x: p.x + CGFloat(port.dx) * u * 0.24, y: p.y + CGFloat(port.dy) * u * 0.24))
    }
    for (index, point) in positions.enumerated() {
      let amount = max(0, min(1, (fall - Double(index) * 0.09) * 1.5))
      domino(&context, at: point, u: u, fall: amount, direction: direction, accent: editable)
    }
    if fall > 0 && fall < 0.95 && !reduceMotion {
      for index in 0..<5 {
        let angle = Double(index) * 1.256
        let radius = u * (0.2 + fall * 0.4)
        circle(
          &context, CGPoint(x: p.x + cos(angle) * radius, y: p.y + sin(angle) * radius),
          radius: u * 0.028, color: Palette.brass.opacity(1 - fall))
      }
    }
  }

  private func domino(
    _ context: inout GraphicsContext, at p: CGPoint, u: CGFloat,
    fall: Double, direction: Direction, accent: Bool
  ) {
    let width = u * 0.19
    let height = u * (0.39 - 0.22 * fall)
    let leanX = CGFloat(direction.dx) * u * 0.23 * fall
    let leanY = CGFloat(direction.dy) * u * 0.20 * fall
    let rect = CGRect(
      x: p.x - width / 2 + leanX, y: p.y - height + leanY, width: width, height: height)
    var shadow = Path()
    shadow.move(to: CGPoint(x: rect.minX, y: rect.maxY))
    shadow.addLine(to: CGPoint(x: rect.maxX + u * 0.28 * (1 - fall), y: rect.maxY + u * 0.18))
    shadow.addLine(to: CGPoint(x: rect.maxX + u * 0.42 * (1 - fall), y: rect.maxY + u * 0.18))
    shadow.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    shadow.closeSubpath()
    context.fill(shadow, with: .color(Palette.ink.opacity(0.16)))
    rounded(
      &context, rect.offsetBy(dx: u * 0.045, dy: u * 0.025), radius: u * 0.035,
      color: Color(hex: 0xC8C5B2))
    rounded(
      &context, rect, radius: u * 0.035, color: fall > 0.9 ? Color(hex: 0xEEE8D4) : Palette.cream)
    var line = Path()
    line.move(to: CGPoint(x: rect.minX + 1, y: rect.midY))
    line.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.midY))
    context.stroke(line, with: .color(Palette.ink.opacity(0.22)), lineWidth: 0.65)
    circle(
      &context, CGPoint(x: rect.midX, y: rect.minY + height * 0.25),
      radius: u * 0.021, color: accent ? Palette.coral : Palette.ink.opacity(0.55))
    circle(
      &context, CGPoint(x: rect.midX, y: rect.minY + height * 0.73),
      radius: u * 0.021, color: Palette.ink.opacity(0.55))
  }

  private func trigger(_ context: inout GraphicsContext, at p: CGPoint, u: CGFloat, active: Bool) {
    circle(
      &context, CGPoint(x: p.x + 2, y: p.y + 4), radius: u * 0.37, color: Palette.ink.opacity(0.2))
    circle(&context, p, radius: u * 0.37, color: Palette.coral)
    circle(&context, p, radius: u * 0.28, color: active ? Palette.brass : Color(hex: 0xEAA58B))
    var arrow = Path()
    arrow.move(to: CGPoint(x: p.x - u * 0.07, y: p.y - u * 0.12))
    arrow.addLine(to: CGPoint(x: p.x + u * 0.12, y: p.y))
    arrow.addLine(to: CGPoint(x: p.x - u * 0.07, y: p.y + u * 0.12))
    arrow.closeSubpath()
    context.fill(arrow, with: .color(Palette.cream))
    text(
      &context, "START", at: CGPoint(x: p.x, y: p.y + u * 0.51), size: u * 0.19,
      color: Color(hex: 0x98513F))
  }

  private func bell(
    _ context: inout GraphicsContext, at p: CGPoint, u: CGFloat, active: Bool, number: Int
  ) {
    if active {
      for index in 1...3 {
        context.stroke(
          Path(
            ellipseIn: CGRect(
              x: p.x - u * CGFloat(index) * 0.17,
              y: p.y - u * CGFloat(index) * 0.17,
              width: u * CGFloat(index) * 0.34,
              height: u * CGFloat(index) * 0.34)),
          with: .color(Palette.brass.opacity(0.5 / Double(index))), lineWidth: 1.5)
      }
    }
    circle(
      &context, CGPoint(x: p.x + 3, y: p.y + 4), radius: u * 0.31, color: Palette.ink.opacity(0.15))
    circle(&context, p, radius: u * 0.31, color: Color(hex: 0xAF8444))
    circle(
      &context, CGPoint(x: p.x - u * 0.035, y: p.y - u * 0.04), radius: u * 0.255,
      color: active ? Color(hex: 0xF0CF7E) : Color(hex: 0xDBB76D))
    circle(
      &context, CGPoint(x: p.x - u * 0.07, y: p.y - u * 0.12), radius: u * 0.07,
      color: Palette.cream.opacity(0.7))
    circle(&context, p, radius: u * 0.035, color: Palette.walnut)
    text(
      &context, active ? "RUNG" : "BELL \(number)", at: CGPoint(x: p.x, y: p.y + u * 0.5),
      size: u * 0.19, color: Palette.ink)
  }

  private func scenery(_ context: inout GraphicsContext, layout: BoardLayout) {
    let u = layout.unit
    let town = layout.point(puzzle.town)
    house(&context, at: CGPoint(x: town.x - u * 0.14, y: town.y), u: u * 0.95, color: Palette.coral)
    house(
      &context, at: CGPoint(x: town.x + u * 0.68, y: town.y + u * 0.22), u: u * 0.66,
      color: Palette.blue)
    tree(&context, at: CGPoint(x: town.x + u * 0.66, y: town.y - u * 0.64), u: u * 0.8)
    tree(&context, at: CGPoint(x: town.x - u * 0.78, y: town.y + u * 0.28), u: u * 0.65)
    let pot = layout.point(Cell(x: 0, y: 0))
    tree(&context, at: CGPoint(x: pot.x + 5, y: pot.y - 1), u: u * 0.7)
    text(
      &context, "DAYDREAM WORKSHOP", at: layout.point(Cell(x: 3, y: 0)),
      size: u * 0.17, color: Palette.ink.opacity(0.5))
    let bottom = layout.point(Cell(x: 3, y: 8))
    if puzzle.id == 0 {
      let baseline = layout.point(Cell(x: 3, y: 7))
      text(
        &context, "PLACE  ·  CONNECT  ·  NUDGE", at: baseline,
        size: u * 0.23, color: Palette.ink.opacity(0.62))
    }
    if puzzle.id != 5 {
      text(
        &context,
        puzzle.sandbox
          ? "MAKE SOMETHING WONDERFUL"
          : "A SMALL WORLD · Nº \(String(format: "%02d", puzzle.id + 1))",
        at: CGPoint(x: bottom.x, y: bottom.y + u * 0.25), size: u * 0.15,
        color: Palette.ink.opacity(0.38))
    }
  }

  private func house(_ context: inout GraphicsContext, at p: CGPoint, u: CGFloat, color: Color) {
    var shadow = Path()
    shadow.move(to: CGPoint(x: p.x - u * 0.28, y: p.y + u * 0.24))
    shadow.addLine(to: CGPoint(x: p.x + u * 0.8, y: p.y + u * 0.57))
    shadow.addLine(to: CGPoint(x: p.x + u * 1.02, y: p.y + u * 0.29))
    shadow.addLine(to: CGPoint(x: p.x + u * 0.1, y: p.y - u * 0.1))
    shadow.closeSubpath()
    context.fill(shadow, with: .color(Palette.ink.opacity(0.13)))
    rounded(
      &context, CGRect(x: p.x - u * 0.31, y: p.y - u * 0.2, width: u * 0.63, height: u * 0.53),
      radius: u * 0.05, color: Palette.cream)
    var roof = Path()
    roof.move(to: CGPoint(x: p.x - u * 0.4, y: p.y - u * 0.17))
    roof.addLine(to: CGPoint(x: p.x, y: p.y - u * 0.58))
    roof.addLine(to: CGPoint(x: p.x + u * 0.4, y: p.y - u * 0.17))
    roof.closeSubpath()
    context.fill(roof, with: .color(color))
    rounded(
      &context, CGRect(x: p.x - u * 0.08, y: p.y + u * 0.03, width: u * 0.16, height: u * 0.3),
      radius: u * 0.06, color: Palette.ink.opacity(0.7))
    for offset in [-0.21, 0.21] {
      rounded(
        &context,
        CGRect(x: p.x + offset * u - u * 0.05, y: p.y - u * 0.05, width: u * 0.1, height: u * 0.13),
        radius: 1, color: Palette.blue)
    }
  }

  private func tree(_ context: inout GraphicsContext, at p: CGPoint, u: CGFloat) {
    circle(
      &context, CGPoint(x: p.x + u * 0.25, y: p.y + u * 0.22), radius: u * 0.23,
      color: Palette.ink.opacity(0.1))
    circle(
      &context, CGPoint(x: p.x, y: p.y + u * 0.13), radius: u * 0.19,
      color: Palette.coral.opacity(0.75))
    for index in 0..<7 {
      let angle = Double(index) * .pi * 2 / 7
      let center = CGPoint(
        x: p.x + cos(angle) * u * 0.13, y: p.y + sin(angle) * u * 0.12 - u * 0.05)
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: center.x - u * 0.12, y: center.y - u * 0.23, width: u * 0.24, height: u * 0.4)),
        with: .color(index.isMultiple(of: 2) ? Palette.sage : Color(hex: 0x597C65)))
    }
    circle(
      &context, CGPoint(x: p.x - u * 0.035, y: p.y - u * 0.12), radius: u * 0.10,
      color: Color(hex: 0xAFBE8C))
  }

  private func rounded(
    _ context: inout GraphicsContext, _ rect: CGRect, radius: CGFloat, color: Color
  ) {
    context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
  }

  private func circle(
    _ context: inout GraphicsContext, _ point: CGPoint, radius: CGFloat, color: Color
  ) {
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
      with: .color(color))
  }

  private func text(
    _ context: inout GraphicsContext, _ value: String, at point: CGPoint, size: CGFloat,
    color: Color
  ) {
    context.draw(
      Text(value).font(.system(size: size, weight: .semibold, design: .monospaced)).foregroundColor(
        color),
      at: point)
  }
}
