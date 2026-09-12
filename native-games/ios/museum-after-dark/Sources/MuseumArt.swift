import SwiftUI

enum Palette {
  static let ink = Color(red: 0.035, green: 0.075, blue: 0.095)
  static let stone = Color(red: 0.13, green: 0.20, blue: 0.22)
  static let gold = Color(red: 0.83, green: 0.70, blue: 0.46)
  static let paper = Color(red: 0.96, green: 0.92, blue: 0.83)
  static let muted = Color(red: 0.57, green: 0.66, blue: 0.65)
  static let ruby = Color(red: 1, green: 0.18, blue: 0.32)
  static let mint = Color(red: 0.48, green: 0.86, blue: 0.75)
  static let amber = Color(red: 1, green: 0.69, blue: 0.27)
}

struct Diamond: Shape {
  func path(in rect: CGRect) -> Path {
    Path { p in
      p.move(to: CGPoint(x: rect.midX, y: rect.minY))
      p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
      p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
      p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
      p.closeSubpath()
    }
  }
}

struct Jewel: View {
  var size: CGFloat = 100
  var color: Color = Palette.ruby
  var body: some View {
    ZStack {
      Circle().fill(color.opacity(0.12)).blur(radius: size * 0.2)
      Diamond().fill(
        LinearGradient(
          colors: [color, color.opacity(0.35), Palette.ink], startPoint: .topLeading,
          endPoint: .bottomTrailing)
      )
      .overlay(Diamond().stroke(Palette.paper.opacity(0.7), lineWidth: 1))
      .frame(width: size * 0.62, height: size * 0.88)
      Diamond().stroke(Palette.paper.opacity(0.35), lineWidth: 0.7)
        .frame(width: size * 0.3, height: size * 0.88)
      Rectangle().fill(Palette.paper.opacity(0.5)).frame(width: size * 0.62, height: 0.6)
      Circle().fill(Palette.paper).frame(width: 4, height: 4).offset(
        x: -size * 0.15, y: -size * 0.22)
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

struct MuseumBoard: View {
  let room: Room
  let state: HeistState
  var interactive = true
  var showForecast = true
  var tap: (Tile) -> Void = { _ in }
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { geometry in
      let cell = min(
        geometry.size.width / CGFloat(room.width), geometry.size.height / CGFloat(room.height))
      let boardSize = CGSize(width: cell * CGFloat(room.width), height: cell * CGFloat(room.height))
      ZStack(alignment: .topLeading) {
        Canvas { context, _ in
          drawMuseum(context: context, cell: cell)
        }
        .accessibilityHidden(true)
        if interactive {
          ForEach(
            room.tiles.filter {
              room.walkable($0) || room.nodes.contains($0) || room.mirrors.contains($0)
            }, id: \.self
          ) { tile in
            Button {
              tap(tile)
            } label: {
              Color.clear.contentShape(Rectangle())
            }
            .frame(width: cell, height: cell)
            .position(center(tile, cell))
            .accessibilityLabel(label(tile))
            .accessibilityIdentifier("tile-\(tile.x)-\(tile.y)")
            .accessibilityHint(
              state.player.distance(to: tile) == 1
                ? "Double tap to use this tile" : "Move to a neighboring tile first")
          }
        }
        ThiefFigure()
          .frame(width: cell * 0.72, height: cell * 0.80)
          .position(center(state.player, cell))
          .shadow(color: .black.opacity(0.8), radius: 5, x: 3, y: 5)
          .animation(
            reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.78), value: state.player
          )
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      }
      .frame(width: boardSize.width, height: boardSize.height)
      .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
    .aspectRatio(CGFloat(room.width) / CGFloat(room.height), contentMode: .fit)
  }

  private func center(_ tile: Tile, _ cell: CGFloat) -> CGPoint {
    CGPoint(x: (CGFloat(tile.x) + 0.5) * cell, y: (CGFloat(tile.y) + 0.5) * cell)
  }

  private func label(_ tile: Tile) -> String {
    let position = "column \(tile.x + 1), row \(tile.y + 1)"
    if tile == state.player { return "You, \(position)" }
    if room.nodes.contains(tile) { return "Power node \(room.circuit(at: tile) + 1), \(position)" }
    if room.mirrors.contains(tile) { return "Rotate mirror, \(position)" }
    if tile == room.artifact && !state.hasArtifact { return "\(room.artifactName), \(position)" }
    if tile == room.start { return "Exit, \(position)" }
    if HeistEngine.field(room, state).danger.contains(tile) { return "Danger, \(position)" }
    if HeistEngine.field(room, state, nextTurn: true).danger.contains(tile) {
      return "Next sweep, \(position)"
    }
    return "Step to \(position)"
  }

  private func drawMuseum(context: GraphicsContext, cell: CGFloat) {
    let field = HeistEngine.field(room, state)
    let next = HeistEngine.field(room, state, nextTurn: true)
    for tile in room.tiles {
      let rect = CGRect(
        x: CGFloat(tile.x) * cell, y: CGFloat(tile.y) * cell, width: cell, height: cell)
      let c = center(tile, cell)
      if room.mark(tile) == "#" {
        context.fill(Path(rect), with: .color(Palette.ink))
        if tile.x > 0 && tile.x < room.width - 1 && tile.y > 0 && tile.y < room.height - 1 {
          context.fill(
            Path(rect.insetBy(dx: 1, dy: 1)),
            with: .color(Color(red: 0.24, green: 0.29, blue: 0.28)))
          context.stroke(
            Path(rect.insetBy(dx: 4, dy: 4)), with: .color(Palette.gold.opacity(0.2)), lineWidth: 1)
        } else if tile.y == 0 || tile.y == room.height - 1 {
          let line = CGRect(
            x: rect.minX + 3, y: tile.y == 0 ? rect.maxY - 9 : rect.minY + 8, width: cell - 6,
            height: 1)
          context.fill(Path(line), with: .color(Palette.gold.opacity(0.65)))
          if tile.x == 2 || tile.x == 4 {
            let art = CGRect(
              x: c.x - cell * 0.27, y: c.y - cell * 0.15, width: cell * 0.54, height: cell * 0.3)
            context.fill(Path(art), with: .color(Color(red: 0.26, green: 0.06, blue: 0.11)))
            context.stroke(
              Path(art.insetBy(dx: -2, dy: -2)), with: .color(Palette.gold.opacity(0.7)),
              lineWidth: 1)
            context.fill(
              Diamond().path(in: art.insetBy(dx: 8, dy: 2)), with: .color(Palette.gold.opacity(0.5))
            )
          }
        } else {
          let pillar = CGRect(x: c.x - 6, y: c.y - cell * 0.37, width: 12, height: cell * 0.74)
          context.fill(
            Path(roundedRect: pillar, cornerRadius: 2),
            with: .linearGradient(
              Gradient(colors: [Palette.stone, Palette.ink]),
              startPoint: CGPoint(x: pillar.minX, y: c.y), endPoint: CGPoint(x: pillar.maxX, y: c.y)
            ))
          context.fill(
            Path(CGRect(x: c.x - 8, y: pillar.minY, width: 16, height: 3)),
            with: .color(Palette.gold.opacity(0.4)))
        }
        continue
      }
      context.fill(
        Path(rect.insetBy(dx: 0.5, dy: 0.5)),
        with: .color(
          (tile.x + tile.y).isMultiple(of: 2) ? Palette.stone : Palette.stone.opacity(0.78)))
      var vein = Path()
      vein.move(to: CGPoint(x: rect.minX, y: rect.minY + cell * 0.3))
      vein.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cell * 0.23))
      context.stroke(vein, with: .color(Palette.paper.opacity(0.025)), lineWidth: 1)
      if tile.x == 3 {
        context.fill(
          Path(rect.insetBy(dx: cell * 0.16, dy: 0)),
          with: .color(Color(red: 0.26, green: 0.075, blue: 0.12).opacity(0.8)))
        context.fill(
          Path(CGRect(x: rect.minX + cell * 0.16, y: rect.minY, width: 1, height: cell)),
          with: .color(Palette.gold.opacity(0.25)))
        context.fill(
          Path(CGRect(x: rect.maxX - cell * 0.16, y: rect.minY, width: 1, height: cell)),
          with: .color(Palette.gold.opacity(0.25)))
      }
      if showForecast && next.danger.contains(tile) && !field.danger.contains(tile) {
        context.stroke(
          Path(roundedRect: rect.insetBy(dx: 5, dy: 5), cornerRadius: 4),
          with: .color(Palette.amber.opacity(0.8)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
      }
      if interactive && state.outcome == .playing && state.player.distance(to: tile) == 1
        && room.walkable(tile)
      {
        context.stroke(
          Path(roundedRect: rect.insetBy(dx: 3, dy: 3), cornerRadius: 5),
          with: .color(Palette.mint.opacity(0.55)), lineWidth: 1.2)
        context.fill(
          Path(ellipseIn: CGRect(x: c.x - 2, y: c.y - 2, width: 4, height: 4)),
          with: .color(Palette.mint))
      }
    }
    for segment in field.segments {
      let from = center(segment.from, cell)
      let to = center(segment.to, cell)
      var path = Path()
      path.move(to: from)
      path.addLine(to: to)
      let color = segment.searchlight ? Palette.amber : Palette.ruby
      context.drawLayer { glow in
        glow.addFilter(.blur(radius: segment.searchlight ? 6 : 4))
        glow.stroke(
          path, with: .color(color.opacity(0.5)), lineWidth: segment.searchlight ? cell * 0.47 : 7)
      }
      context.stroke(
        path, with: .color(color.opacity(segment.searchlight ? 0.22 : 0.95)),
        style: StrokeStyle(lineWidth: segment.searchlight ? cell * 0.3 : 2, lineCap: .round))
      if !segment.searchlight {
        context.stroke(path, with: .color(Palette.paper.opacity(0.8)), lineWidth: 0.6)
      }
    }
    for tile in room.tiles {
      let c = center(tile, cell)
      let rect = CGRect(
        x: c.x - cell * 0.28, y: c.y - cell * 0.28, width: cell * 0.56, height: cell * 0.56)
      if tile == room.start {
        context.stroke(
          Path(roundedRect: rect, cornerRadius: 5), with: .color(Palette.mint.opacity(0.8)),
          style: StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
        context.draw(
          Text("EXIT").font(.system(size: cell * 0.15, weight: .bold, design: .monospaced))
            .foregroundColor(Palette.mint), at: CGPoint(x: c.x, y: c.y + cell * 0.38))
      }
      if tile == room.artifact {
        context.drawLayer { light in
          light.addFilter(.blur(radius: 12))
          light.fill(
            Path(ellipseIn: rect.insetBy(dx: -cell * 0.4, dy: -cell * 0.4)),
            with: .color(Palette.gold.opacity(0.3)))
        }
        context.fill(
          Path(ellipseIn: rect.offsetBy(dx: 3, dy: cell * 0.12)), with: .color(.black.opacity(0.4)))
        context.fill(
          Path(ellipseIn: rect),
          with: .linearGradient(
            Gradient(colors: [Palette.paper.opacity(0.65), Palette.stone]),
            startPoint: CGPoint(x: c.x, y: rect.minY), endPoint: CGPoint(x: c.x, y: rect.maxY)))
        if !state.hasArtifact {
          let jewel = rect.insetBy(dx: cell * 0.1, dy: cell * 0.04).offsetBy(
            dx: 0, dy: -cell * 0.08)
          context.fill(
            Diamond().path(in: jewel),
            with: .linearGradient(
              Gradient(colors: [Palette.paper, Palette.ruby, Palette.ruby.opacity(0.4)]),
              startPoint: CGPoint(x: jewel.minX, y: jewel.minY),
              endPoint: CGPoint(x: jewel.maxX, y: jewel.maxY)))
          context.stroke(
            Diamond().path(in: jewel), with: .color(Palette.paper.opacity(0.7)), lineWidth: 0.7)
        }
      }
      if let index = room.mirrors.firstIndex(of: tile) {
        let slash = (room.mark(tile) == "/") != (state.mirrorBits & (1 << index) != 0)
        context.fill(
          Path(ellipseIn: rect.offsetBy(dx: 3, dy: 4)), with: .color(.black.opacity(0.5)))
        context.fill(Path(ellipseIn: rect), with: .color(Palette.ink))
        context.stroke(Path(ellipseIn: rect), with: .color(Palette.gold), lineWidth: 1)
        var line = Path()
        line.move(to: CGPoint(x: rect.minX + 4, y: slash ? rect.maxY - 4 : rect.minY + 4))
        line.addLine(to: CGPoint(x: rect.maxX - 4, y: slash ? rect.minY + 4 : rect.maxY - 4))
        context.stroke(
          line, with: .color(Palette.mint), style: StrokeStyle(lineWidth: 4, lineCap: .round))
      }
      if room.nodes.contains(tile) {
        let active = state.power & (1 << room.circuit(at: tile)) != 0
        context.fill(
          Path(roundedRect: rect.offsetBy(dx: 2, dy: 3), cornerRadius: 5),
          with: .color(.black.opacity(0.6)))
        context.fill(Path(roundedRect: rect, cornerRadius: 5), with: .color(Palette.ink))
        context.stroke(
          Path(roundedRect: rect, cornerRadius: 5),
          with: .color(active ? Palette.gold : Palette.mint), lineWidth: 1.5)
        context.draw(
          Text(room.circuit(at: tile) == 0 ? "I" : "II").font(
            .system(size: cell * 0.26, weight: .semibold, design: .serif)
          ).foregroundColor(active ? Palette.gold : Palette.mint), at: c)
        context.fill(
          Path(ellipseIn: CGRect(x: c.x - 2, y: rect.maxY - 6, width: 4, height: 4)),
          with: .color(active ? Palette.ruby : Palette.mint))
      }
      if let emitter = room.emitters.first(where: { $0.tile == tile }) {
        let active = state.power & (1 << emitter.circuit) != 0
        context.fill(
          Path(roundedRect: rect.insetBy(dx: 3, dy: 3), cornerRadius: 5), with: .color(Palette.ink))
        context.stroke(
          Path(roundedRect: rect.insetBy(dx: 3, dy: 3), cornerRadius: 5),
          with: .color(Palette.gold.opacity(0.5)), lineWidth: 1)
        context.fill(
          Path(ellipseIn: rect.insetBy(dx: 10, dy: 10)),
          with: .color(active ? Palette.ruby : Palette.muted))
      }
      if let sentry = room.sentries.first(where: { $0.tile == tile }) {
        let direction = Direction(rawValue: (sentry.facing.rawValue + state.turn) % 4)!
        context.fill(Path(ellipseIn: rect), with: .color(Palette.ink))
        context.stroke(Path(ellipseIn: rect), with: .color(Palette.amber), lineWidth: 1)
        context.draw(
          Text(Image(systemName: direction.symbol)).font(
            .system(size: cell * 0.27, weight: .medium)
          ).foregroundColor(Palette.amber), at: c)
      }
    }
  }
}

struct ThiefFigure: View {
  var body: some View {
    GeometryReader { geo in
      let w = geo.size.width
      let h = geo.size.height
      ZStack {
        Ellipse().fill(.black.opacity(0.5)).frame(width: w * 0.8, height: h * 0.25).offset(
          y: h * 0.3)
        Capsule().fill(Color(red: 0.045, green: 0.065, blue: 0.075)).frame(
          width: w * 0.55, height: h * 0.62
        ).offset(y: h * 0.13)
        Capsule().fill(Palette.gold).frame(width: w * 0.12, height: h * 0.38).rotationEffect(
          .degrees(-22)
        ).offset(x: w * 0.2, y: h * 0.1)
        Ellipse().fill(Palette.paper).frame(width: w * 0.39, height: h * 0.32).offset(y: -h * 0.07)
        Capsule().fill(Palette.ink).frame(width: w * 0.4, height: h * 0.085).offset(y: -h * 0.04)
        Ellipse().fill(Palette.ink).overlay(
          Ellipse().stroke(Palette.gold.opacity(0.8), lineWidth: 1)
        )
        .frame(width: w * 0.86, height: h * 0.23).rotationEffect(.degrees(-12)).offset(y: -h * 0.2)
        RoundedRectangle(cornerRadius: 4).fill(Palette.ink).overlay(
          RoundedRectangle(cornerRadius: 4).stroke(Palette.gold.opacity(0.5), lineWidth: 0.8)
        )
        .frame(width: w * 0.5, height: h * 0.28).rotationEffect(.degrees(-12)).offset(y: -h * 0.3)
      }
      .frame(width: w, height: h)
    }
  }
}
