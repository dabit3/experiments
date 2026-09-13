import AfterhoursCore
import SwiftUI

enum Sprite {
  static let size = 13

  static let ghostBody: [[String]] = [
    [
      "0000111110000",
      "0011111111100",
      "0111111111110",
      "0111111111110",
      "1111111111111",
      "1111111111111",
      "1111111111111",
      "1111111111111",
      "1111111111111",
      "1111111111111",
      "1111111111111",
      "1101111011011",
      "1000110001001",
    ],
    [
      "0000111110000",
      "0011111111100",
      "0111111111110",
      "0111111111110",
      "1111111111111",
      "1111111111111",
      "1111111111111",
      "1111111111111",
      "1111111111111",
      "1111111111111",
      "1111111111111",
      "1011101110111",
      "0001000100010",
    ],
  ]

  static let cometFrames = 3

  static func comet(open: Int) -> [[Bool]] {
    (0..<size).map { y in
      (0..<size).map { x in
        let dx = Double(x) - 6
        let dy = Double(y) - 6
        guard dx * dx + dy * dy <= 6.6 * 6.6 else { return false }
        guard open > 0, dx > 0 else { return true }
        return open == 1 ? abs(dy) > dx * 0.55 - 0.4 : abs(dy) > dx * 0.95 - 0.5
      }
    }
  }

  static func fill(_ context: GraphicsContext, bits: [[Bool]], px: CGFloat, color: Color) {
    var path = Path()
    for (y, row) in bits.enumerated() {
      for (x, on) in row.enumerated() where on {
        path.addRect(CGRect(x: CGFloat(x) * px, y: CGFloat(y) * px, width: px, height: px))
      }
    }
    context.fill(path, with: .color(color))
  }

  static func fill(_ context: GraphicsContext, rows: [String], px: CGFloat, color: Color) {
    fill(context, bits: rows.map { $0.map { $0 == "1" } }, px: px, color: color)
  }
}

struct CometShape: Shape {
  var mouth: Double
  func path(in rect: CGRect) -> Path {
    let px = rect.width / CGFloat(Sprite.size)
    var path = Path()
    let open = mouth < 0.3 ? 0 : mouth < 0.6 ? 1 : 2
    for (y, row) in Sprite.comet(open: open).enumerated() {
      for (x, on) in row.enumerated() where on {
        path.addRect(
          CGRect(
            x: rect.minX + CGFloat(x) * px, y: rect.minY + CGFloat(y) * px, width: px, height: px
          ))
      }
    }
    return path
  }
}

struct SpiritShape: Shape {
  let identity: Int
  func path(in rect: CGRect) -> Path {
    let px = rect.width / CGFloat(Sprite.size)
    var path = Path()
    for (y, row) in Sprite.ghostBody[identity % 2].enumerated() {
      for (x, bit) in row.enumerated() where bit == "1" {
        path.addRect(
          CGRect(
            x: rect.minX + CGFloat(x) * px, y: rect.minY + CGFloat(y) * px, width: px, height: px
          ))
      }
    }
    return path
  }
}

struct MazeBoard: View {
  let game: Game
  let reducedMotion: Bool
  var attract = false

  var body: some View {
    Canvas(rendersAsynchronously: false) { context, size in
      let cell = size.width / CGFloat(game.maze.width)
      let px = cell / 14
      let bounds = CGRect(origin: .zero, size: size)
      let frame = Int(game.elapsed * 8)
      context.fill(Path(bounds), with: .color(Palette.ink))

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
      let clearing = game.phase == .cleared && !reducedMotion && frame % 2 == 0
      let wallColor = clearing ? Palette.white : Palette.blue
      let thick = cell * 0.56
      let line = max(2, (px * 2).rounded())
      context.stroke(
        walls, with: .color(wallColor),
        style: StrokeStyle(lineWidth: thick, lineCap: .square, lineJoin: .miter))
      context.stroke(
        walls, with: .color(Palette.ink),
        style: StrokeStyle(lineWidth: thick - line * 2, lineCap: .square, lineJoin: .miter))

      let tunnelY = (CGFloat(10) + 0.5) * cell
      var tunnel = Path()
      tunnel.addRect(CGRect(x: 0, y: tunnelY - cell / 2, width: cell * 0.55, height: cell))
      tunnel.addRect(
        CGRect(x: size.width - cell * 0.55, y: tunnelY - cell / 2, width: cell * 0.55, height: cell)
      )
      context.fill(tunnel, with: .color(Palette.ink))

      var pellets = Path()
      for tile in game.pellets {
        let point = center(tile, cell)
        pellets.addRect(CGRect(x: point.x - px, y: point.y - px, width: px * 2, height: px * 2))
      }
      context.fill(pellets, with: .color(Palette.peach))

      if reducedMotion || frame % 3 != 2 {
        var powers = Path()
        for tile in game.powers {
          let point = center(tile, cell)
          let radius = px * 4
          powers.addRect(
            CGRect(x: point.x - radius, y: point.y - radius + px, width: radius * 2, height: px * 6)
          )
          powers.addRect(
            CGRect(x: point.x - radius + px, y: point.y - radius, width: px * 6, height: radius * 2)
          )
        }
        context.fill(powers, with: .color(Palette.peach))
      }

      let home = center(game.maze.home, cell)
      context.fill(
        Path(CGRect(x: home.x - cell * 0.5, y: home.y - cell * 0.5, width: cell, height: px)),
        with: .color(Palette.pink))

      for rival in game.hitTime > 0.4 ? game.impactRivals : game.rivals {
        drawRival(context, rival, cell: cell, px: px, frame: frame)
      }

      let visiblePlayer = game.hitTime > 0.4 ? (game.lastHit ?? game.player) : game.player
      let position = visiblePlayer.position(width: game.maze.width)
      var point = CGPoint(x: (position.x + 0.5) * cell, y: (position.y + 0.5) * cell)
      if point.x < 0 { point.x += size.width }
      if point.x > size.width { point.x -= size.width }
      for shift in [0, size.width, -size.width] as [CGFloat] {
        let shifted = CGPoint(x: point.x + shift, y: point.y)
        if shifted.x > -cell && shifted.x < size.width + cell {
          drawComet(context, at: shifted, cell: cell, px: px, runner: visiblePlayer, frame: frame)
        }
      }

      if game.bonusTime > 1.6 {
        let label = "\(game.lastBonus)"
        let scale = max(1, px.rounded())
        let width = PixelFont.size(of: label, scale: scale).width
        let y = max(cell * 0.4, point.y - cell * 1.1)
        PixelFont.draw(
          label, in: context, at: CGPoint(x: point.x - width / 2, y: y), scale: scale,
          color: Palette.cyan)
      }

      if attract {
        context.fill(Path(bounds), with: .color(Palette.ink.opacity(0.25)))
      }
    }
    .clipShape(Rectangle())
  }

  private func center(_ tile: Tile, _ cell: CGFloat) -> CGPoint {
    CGPoint(x: (CGFloat(tile.x) + 0.5) * cell, y: (CGFloat(tile.y) + 0.5) * cell)
  }

  private func snap(_ value: CGFloat, _ px: CGFloat) -> CGFloat {
    (value / px).rounded() * px
  }

  private func drawComet(
    _ context: GraphicsContext, at point: CGPoint, cell: CGFloat, px: CGFloat, runner: Runner,
    frame: Int
  ) {
    var context = context
    let half = px * CGFloat(Sprite.size) / 2
    context.translateBy(x: snap(point.x, px), y: snap(point.y, px))
    context.rotate(by: .radians(runner.direction.angle))
    context.translateBy(x: -half, y: -half)
    if game.hitTime > 0 && game.hitTime <= 0.4 { return }
    if game.hitTime > 0.4 {
      let progress = min(1, (1.1 - game.hitTime) / 0.7)
      let bits = Sprite.comet(open: 0).enumerated().map { y, row in
        row.enumerated().map { x, on in
          let angle = atan2(Double(y) - 6, Double(x) - 6)
          return on && abs(angle) > progress * .pi
        }
      }
      Sprite.fill(context, bits: bits, px: px, color: Palette.yellow)
      return
    }
    let open: Int
    if runner.next == nil || reducedMotion {
      open = 1
    } else {
      open = [0, 1, 2, 1][frame % 4]
    }
    if game.grace > 0 && game.phase == .playing && frame % 2 == 0 && !reducedMotion {
      Sprite.fill(context, bits: Sprite.comet(open: open), px: px, color: Palette.white)
    } else {
      Sprite.fill(context, bits: Sprite.comet(open: open), px: px, color: Palette.yellow)
    }
  }

  private func drawRival(
    _ context: GraphicsContext, _ rival: Rival, cell: CGFloat, px: CGFloat, frame: Int
  ) {
    let position = rival.runner.position(width: game.maze.width)
    var context = context
    let half = px * CGFloat(Sprite.size) / 2
    context.translateBy(
      x: snap((position.x + 0.5) * cell, px) - half, y: snap((position.y + 0.5) * cell, px) - half)
    let frightened = game.frightened > 0 && !rival.returning
    let flashing = game.frightened < 2 && frame % 2 == 0 && !reducedMotion
    let wobble = reducedMotion ? 0 : (frame / 2 + rival.identity) % 2
    if !rival.returning {
      let color =
        frightened ? (flashing ? Palette.white : Palette.blue) : Palette.rivals[rival.identity]
      if frightened {
        for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] as [(CGFloat, CGFloat)] {
          var outline = context
          outline.translateBy(x: dx * px, y: dy * px)
          Sprite.fill(outline, rows: Sprite.ghostBody[wobble], px: px, color: Palette.peach)
        }
      }
      Sprite.fill(context, rows: Sprite.ghostBody[wobble], px: px, color: color)
      if rival.identity == 1 {
        context.fill(
          Path(CGRect(x: px * 4, y: 0, width: px * 2, height: px)), with: .color(Palette.white))
        context.fill(
          Path(CGRect(x: px * 7, y: 0, width: px * 2, height: px)), with: .color(Palette.white))
      }
      if rival.identity == 2 {
        context.fill(
          Path(CGRect(x: px * 6, y: -px, width: px, height: px * 2)), with: .color(Palette.white))
      }
    }
    if frightened {
      let face = flashing ? Palette.red : Palette.peach
      var eyes = Path()
      eyes.addRect(CGRect(x: px * 3, y: px * 4, width: px * 2, height: px * 2))
      eyes.addRect(CGRect(x: px * 8, y: px * 4, width: px * 2, height: px * 2))
      for index in 0..<9 {
        eyes.addRect(
          CGRect(
            x: px * CGFloat(2 + index), y: px * CGFloat(index % 2 == 0 ? 9 : 8), width: px,
            height: px))
      }
      context.fill(eyes, with: .color(face))
    } else {
      let dx = CGFloat(rival.runner.direction.dx)
      let dy = CGFloat(rival.runner.direction.dy)
      var whites = Path()
      var pupils = Path()
      for x in [2, 7] as [CGFloat] {
        whites.addRect(CGRect(x: px * (x + dx), y: px * (3 + dy), width: px * 4, height: px * 5))
        pupils.addRect(
          CGRect(x: px * (x + 1 + dx * 2), y: px * (4 + dy * 2), width: px * 2, height: px * 2))
      }
      context.fill(whites, with: .color(Palette.white))
      context.fill(pupils, with: .color(Palette.navy))
    }
  }
}

struct MazeThumbnail: View {
  let index: Int
  var body: some View {
    Canvas { context, size in
      let maze = Maze(index: index)
      let cell = size.width / CGFloat(maze.width)
      var path = Path()
      for tile in maze.walls {
        path.addRect(
          CGRect(
            x: CGFloat(tile.x) * cell, y: CGFloat(tile.y) * cell, width: cell, height: cell))
      }
      context.fill(path, with: .color(index == 0 ? Palette.blue : Palette.pink))
    }
  }
}
