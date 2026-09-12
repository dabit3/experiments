import AfterhoursCore
import SwiftUI

struct CometShape: Shape {
  var mouth: Double
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    path.move(to: center)
    path.addArc(
      center: center, radius: rect.width / 2, startAngle: .radians(mouth),
      endAngle: .radians(2 * .pi - mouth), clockwise: false)
    path.closeSubpath()
    return path
  }
}

struct SpiritShape: Shape {
  let identity: Int
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let w = rect.width
    let h = rect.height
    path.move(to: CGPoint(x: rect.minX, y: rect.minY + h))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.45))
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.45),
      control: CGPoint(x: rect.midX, y: rect.minY - h * 0.43))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    for index in stride(from: 5, through: 0, by: -1) {
      let offset = index % 2 == identity % 2 ? 0.16 : 0.0
      path.addLine(to: CGPoint(x: rect.minX + w * CGFloat(index) / 6, y: rect.maxY - h * offset))
    }
    path.closeSubpath()
    return path
  }
}

struct MazeBoard: View {
  let game: Game
  let reducedMotion: Bool
  var attract = false

  var body: some View {
    Canvas { context, size in
      let cell = size.width / CGFloat(game.maze.width)
      let bounds = CGRect(origin: .zero, size: size)
      context.fill(
        Path(roundedRect: bounds, cornerRadius: 15),
        with: .linearGradient(
          Gradient(colors: [Palette.panel.opacity(0.55), Palette.ink]),
          startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
      var lanes = Path()
      for y in 0..<game.maze.height {
        for x in 0..<game.maze.width where !game.maze.walls.contains(Tile(x, y)) {
          lanes.addRect(
            CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell, width: cell, height: cell))
        }
      }
      context.fill(lanes, with: .color(Palette.blue.opacity(0.045)))
      var walls = Path()
      for tile in game.maze.walls {
        let point = center(tile, cell)
        walls.move(to: point)
        walls.addLine(to: CGPoint(x: point.x + 0.01, y: point.y))
        for direction in [Direction.right, .down] {
          let next = Tile(tile.x + direction.dx, tile.y + direction.dy)
          if game.maze.walls.contains(next) {
            walls.move(to: point)
            walls.addLine(to: center(next, cell))
          }
        }
      }
      let chase = game.frightened > 0
      let wallTint = chase ? Palette.mint : Palette.blue
      context.drawLayer { glow in
        glow.addFilter(.shadow(color: wallTint.opacity(0.55), radius: 9))
        glow.stroke(
          walls, with: .color(wallTint.opacity(0.16)),
          style: StrokeStyle(lineWidth: cell * 0.66, lineCap: .round, lineJoin: .round))
      }
      context.stroke(
        walls,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.09, green: 0.16, blue: 0.40), Color(red: 0.045, green: 0.09, blue: 0.24),
          ]),
          startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)),
        style: StrokeStyle(lineWidth: cell * 0.66, lineCap: .round, lineJoin: .round))
      context.stroke(
        walls, with: .color(Palette.ink.opacity(0.9)),
        style: StrokeStyle(lineWidth: cell * 0.30, lineCap: .round, lineJoin: .round))
      context.stroke(
        walls, with: .color(wallTint.opacity(chase ? 0.9 : 0.82)),
        style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
      let tunnelY = (CGFloat(10) + 0.5) * cell
      for x in [cell * 0.5, size.width - cell * 0.5] {
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: x - cell * 0.6, y: tunnelY - cell * 0.6, width: cell * 1.2, height: cell * 1.2)),
          with: .radialGradient(
            Gradient(colors: [Palette.violet.opacity(0.35), .clear]),
            center: CGPoint(x: x, y: tunnelY), startRadius: 0, endRadius: cell * 0.6))
      }
      let twinkle = reducedMotion ? 1.0 : 0.85 + sin(game.elapsed * 2.2) * 0.15
      for tile in game.pellets {
        let point = center(tile, cell)
        context.fill(
          Path(ellipseIn: CGRect(x: point.x - 3.5, y: point.y - 3.5, width: 7, height: 7)),
          with: .color(Palette.gold.opacity(0.14 * twinkle)))
        context.fill(
          Path(ellipseIn: CGRect(x: point.x - 1.6, y: point.y - 1.6, width: 3.2, height: 3.2)),
          with: .color(Palette.pearl.opacity(0.95)))
      }
      for tile in game.powers {
        let point = center(tile, cell)
        let pulse = reducedMotion ? 1 : 0.88 + sin(game.elapsed * 5) * 0.12
        let radius = cell * 0.27 * pulse
        context.drawLayer { glow in
          glow.addFilter(.shadow(color: Palette.pearl.opacity(0.8), radius: 8))
          glow.fill(
            Path(
              ellipseIn: CGRect(
                x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
            with: .color(Palette.pearl))
        }
        context.stroke(
          Path(
            ellipseIn: CGRect(
              x: point.x - cell * 0.4, y: point.y - cell * 0.4, width: cell * 0.8,
              height: cell * 0.8)),
          with: .color(Palette.pearl.opacity(0.25)), lineWidth: 1)
      }
      let home = center(game.maze.home, cell)
      context.stroke(
        Path(
          ellipseIn: CGRect(
            x: home.x - cell * 0.42, y: home.y - cell * 0.42, width: cell * 0.84,
            height: cell * 0.84
          )),
        with: .color(Palette.violet.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
      context.draw(
        Text("✦").font(.system(size: cell * 0.5)).foregroundStyle(Palette.violet.opacity(0.5)),
        at: home)
      drawTail(context, cell: cell, width: size.width)
      for rival in game.hitTime > 0.4 ? game.impactRivals : game.rivals {
        drawRival(context, rival, cell: cell)
      }
      let visiblePlayer = game.hitTime > 0.4 ? (game.lastHit ?? game.player) : game.player
      let position = visiblePlayer.position(width: game.maze.width)
      var point = CGPoint(x: (position.x + 0.5) * cell, y: (position.y + 0.5) * cell)
      if point.x < 0 { point.x += size.width }
      if point.x > size.width { point.x -= size.width }
      drawComet(context, at: point, cell: cell, runner: visiblePlayer)
      if point.x < cell {
        drawComet(
          context, at: CGPoint(x: point.x + size.width, y: point.y), cell: cell,
          runner: visiblePlayer)
      }
      if point.x > size.width - cell {
        drawComet(
          context, at: CGPoint(x: point.x - size.width, y: point.y), cell: cell,
          runner: visiblePlayer)
      }
      if game.bonusTime > 1.6 {
        let rise = (2.8 - game.bonusTime) * cell * 0.6
        context.drawLayer { label in
          label.addFilter(.shadow(color: Palette.mint.opacity(0.8), radius: 6))
          label.draw(
            Text("+\(game.lastBonus)").font(
              .system(size: cell * 0.78, weight: .black, design: .rounded)
            )
            .foregroundStyle(Palette.mint),
            at: CGPoint(x: point.x, y: max(cell * 0.6, point.y - cell - rise)))
        }
      }
      if attract {
        context.fill(
          Path(roundedRect: bounds, cornerRadius: 15), with: .color(Palette.ink.opacity(0.18)))
      }
      if game.hitTime > 0, let hit = game.lastHit {
        let position = hit.position(width: game.maze.width)
        let origin = CGPoint(x: (position.x + 0.5) * cell, y: (position.y + 0.5) * cell)
        let progress = 1 - game.hitTime / 1.1
        let radius = cell * (0.5 + progress * 2.5)
        context.fill(
          Path(roundedRect: bounds, cornerRadius: 15),
          with: .color(Palette.rivals[0].opacity(game.hitTime * 0.07)))
        context.stroke(
          Path(
            ellipseIn: CGRect(
              x: origin.x - radius, y: origin.y - radius,
              width: radius * 2, height: radius * 2)),
          with: .color(Palette.rivals[0].opacity(game.hitTime)),
          lineWidth: 2)
        for index in 0..<8 {
          let angle = Double(index) * .pi / 4
          let point = CGPoint(x: origin.x + cos(angle) * radius, y: origin.y + sin(angle) * radius)
          context.fill(
            Path(ellipseIn: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)),
            with: .color(Palette.pearl.opacity(game.hitTime)))
        }
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.rim, lineWidth: 1))
    .shadow(color: Palette.blue.opacity(attract ? 0 : 0.2), radius: 26, y: 8)
  }

  private func center(_ tile: Tile, _ cell: CGFloat) -> CGPoint {
    CGPoint(x: (CGFloat(tile.x) + 0.5) * cell, y: (CGFloat(tile.y) + 0.5) * cell)
  }

  private func drawTail(_ context: GraphicsContext, cell: CGFloat, width: CGFloat) {
    guard game.phase == .playing, game.player.next != nil else { return }
    let position = game.player.position(width: game.maze.width)
    let direction = game.player.direction
    for index in 1...4 {
      let lag = Double(index) * 0.32
      var x = (position.x + 0.5 - Double(direction.dx) * lag) * cell
      let y = (position.y + 0.5 - Double(direction.dy) * lag) * cell
      if x < 0 { x += width }
      if x > width { x -= width }
      let radius = cell * (0.30 - Double(index) * 0.055)
      context.fill(
        Path(
          ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
        with: .color(Palette.gold.opacity(0.28 - Double(index) * 0.06)))
    }
  }

  private func drawComet(
    _ context: GraphicsContext, at point: CGPoint, cell: CGFloat, runner: Runner
  ) {
    var context = context
    context.translateBy(x: point.x, y: point.y)
    context.rotate(by: .radians(runner.direction.angle))
    let mouth =
      runner.next == nil || reducedMotion ? 0.40 : 0.20 + abs(sin(game.elapsed * 16)) * 0.50
    if game.grace > 0 && game.hitTime <= 0.4 {
      context.stroke(
        Path(
          ellipseIn: CGRect(x: -cell * 0.55, y: -cell * 0.55, width: cell * 1.1, height: cell * 1.1)
        ),
        with: .color(Palette.pearl.opacity(0.5)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
    }
    context.addFilter(.shadow(color: Palette.gold.opacity(0.7), radius: 6))
    context.fill(
      CometShape(mouth: mouth).path(
        in: CGRect(x: -cell * 0.41, y: -cell * 0.41, width: cell * 0.82, height: cell * 0.82)),
      with: .radialGradient(
        Gradient(colors: [Color(red: 1, green: 0.98, blue: 0.92), Palette.pearl, Palette.gold]),
        center: CGPoint(x: -cell * 0.1, y: -cell * 0.12), startRadius: 0, endRadius: cell * 0.5))
    context.fill(
      Path(
        ellipseIn: CGRect(x: -cell * 0.08, y: -cell * 0.26, width: cell * 0.10, height: cell * 0.10)
      ),
      with: .color(Palette.ink))
  }

  private func drawRival(_ context: GraphicsContext, _ rival: Rival, cell: CGFloat) {
    let position = rival.runner.position(width: game.maze.width)
    var context = context
    context.translateBy(x: (position.x + 0.5) * cell, y: (position.y + 0.5) * cell)
    let frightened = game.frightened > 0 && !rival.returning
    let flashing = game.frightened < 2 && Int(game.elapsed * 6) % 2 == 0 && !reducedMotion
    let color =
      frightened ? (flashing ? Palette.pearl : Palette.mint) : Palette.rivals[rival.identity]
    if !rival.returning {
      let frame = CGRect(x: -cell * 0.39, y: -cell * 0.40, width: cell * 0.78, height: cell * 0.82)
      context.drawLayer { body in
        body.addFilter(.shadow(color: color.opacity(0.5), radius: 5))
        body.fill(
          SpiritShape(identity: rival.identity).path(in: frame),
          with: .linearGradient(
            Gradient(colors: [color.opacity(1), color.opacity(0.62)]),
            startPoint: CGPoint(x: 0, y: frame.minY), endPoint: CGPoint(x: 0, y: frame.maxY)))
      }
      context.stroke(
        SpiritShape(identity: rival.identity).path(in: frame),
        with: .color(.white.opacity(0.22)), lineWidth: 0.8)
      if rival.identity == 1 {
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: -cell * 0.08, y: -cell * 0.44, width: cell * 0.16, height: cell * 0.16)),
          with: .color(Palette.pearl))
      }
    }
    for x in [-0.16, 0.16] {
      let eye = CGRect(
        x: cell * x - cell * 0.105, y: -cell * 0.12, width: cell * 0.21, height: cell * 0.25)
      context.fill(Path(ellipseIn: eye), with: .color(frightened ? Palette.ink : .white))
      if !frightened {
        context.fill(
          Path(
            ellipseIn: eye.offsetBy(
              dx: CGFloat(rival.runner.direction.dx) * cell * 0.035,
              dy: CGFloat(rival.runner.direction.dy) * cell * 0.035
            ).insetBy(dx: cell * 0.06, dy: cell * 0.07)),
          with: .color(Palette.ink))
      }
    }
    if frightened {
      var mouth = Path()
      mouth.move(to: CGPoint(x: -cell * 0.2, y: cell * 0.23))
      for index in 1...4 {
        mouth.addLine(
          to: CGPoint(
            x: -cell * 0.2 + Double(index) * cell * 0.1, y: cell * (index % 2 == 0 ? 0.23 : 0.16)))
      }
      context.stroke(mouth, with: .color(Palette.ink), lineWidth: 1)
    }
  }
}

struct MazeThumbnail: View {
  let index: Int
  var body: some View {
    Canvas { context, size in
      let maze = Maze(index: index)
      let cell = size.width / CGFloat(maze.width)
      for tile in maze.walls {
        context.fill(
          Path(
            roundedRect: CGRect(
              x: CGFloat(tile.x) * cell, y: CGFloat(tile.y) * cell,
              width: cell * 0.8, height: cell * 0.8), cornerRadius: 0.4),
          with: .color(index == 0 ? Palette.blue : Palette.rivals[1]))
      }
    }
  }
}
