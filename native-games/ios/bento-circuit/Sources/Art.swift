import SwiftUI

enum Palette {
  static let paper = Color(red: 0.97, green: 0.95, blue: 0.89)
  static let ink = Color(red: 0.17, green: 0.23, blue: 0.20)
  static let muted = Color(red: 0.43, green: 0.47, blue: 0.40)
  static let orange = Color(red: 0.84, green: 0.28, blue: 0.14)
  static let sage = Color(red: 0.70, green: 0.76, blue: 0.62)
  static let wood = Color(red: 0.79, green: 0.56, blue: 0.35)
  static let line = Color(red: 0.82, green: 0.81, blue: 0.73)
}

struct PaperBackground: View {
  var body: some View {
    Palette.paper.overlay {
      Canvas { context, size in
        for index in 0..<1800 {
          let x = CGFloat((index * 137 + 17) % 997) / 997 * size.width
          let y = CGFloat((index * 263 + 31) % 991) / 991 * size.height
          context.fill(
            Path(ellipseIn: CGRect(x: x, y: y, width: 0.9, height: 0.9)),
            with: .color(Palette.ink.opacity(index.isMultiple(of: 3) ? 0.10 : 0.04))
          )
        }
      }
      .allowsHitTesting(false)
    }
    .ignoresSafeArea()
  }
}

struct FoodArt: View {
  let ingredient: Ingredient
  var seed = 0

  var body: some View {
    Canvas { context, size in
      let side = min(size.width, size.height)
      let box = CGRect(x: side * 0.07, y: side * 0.07, width: side * 0.86, height: side * 0.86)
      func rounded(_ rect: CGRect, _ radius: CGFloat, _ color: Color) {
        context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
      }
      func stroke(_ points: [CGPoint], _ color: Color, _ width: CGFloat) {
        var path = Path()
        guard let first = points.first else { return }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        context.stroke(
          path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
      }
      rounded(box.offsetBy(dx: 0, dy: side * 0.035), side * 0.21, .black.opacity(0.12))
      switch ingredient {
      case .salmon:
        rounded(box, side * 0.20, Color(red: 1, green: 0.98, blue: 0.88))
        let fish = box.insetBy(dx: side * 0.045, dy: side * 0.11)
        rounded(fish, side * 0.15, Color(red: 0.96, green: 0.48, blue: 0.32))
        for index in 0..<4 {
          let x = side * (0.20 + Double(index) * 0.17)
          stroke(
            [
              CGPoint(x: x, y: side * 0.25), CGPoint(x: x - side * 0.08, y: side * 0.48),
              CGPoint(x: x + side * 0.05, y: side * 0.73),
            ],
            Color(red: 1, green: 0.80, blue: 0.61), side * 0.033
          )
        }
        rounded(
          CGRect(x: side * 0.44, y: side * 0.15, width: side * 0.17, height: side * 0.70),
          side * 0.02, Palette.ink)
        stroke(
          [CGPoint(x: side * 0.48, y: side * 0.22), CGPoint(x: side * 0.48, y: side * 0.77)],
          .white.opacity(0.13), side * 0.018)
      case .tamago:
        rounded(
          box.insetBy(dx: side * 0.025, dy: side * 0.075), side * 0.14,
          Color(red: 0.98, green: 0.77, blue: 0.30))
        for index in 0..<4 {
          let y = side * (0.27 + Double(index) * 0.15)
          stroke(
            [CGPoint(x: side * 0.19, y: y), CGPoint(x: side * 0.80, y: y + side * 0.035)],
            Color(red: 0.80, green: 0.50, blue: 0.18).opacity(0.50), side * 0.025)
        }
        rounded(
          CGRect(x: side * 0.45, y: side * 0.13, width: side * 0.18, height: side * 0.74),
          side * 0.025, Palette.ink)
      case .onigiri:
        var triangle = Path()
        triangle.move(to: CGPoint(x: side * 0.50, y: side * 0.11))
        triangle.addQuadCurve(
          to: CGPoint(x: side * 0.88, y: side * 0.76),
          control: CGPoint(x: side * 0.91, y: side * 0.49))
        triangle.addQuadCurve(
          to: CGPoint(x: side * 0.12, y: side * 0.76),
          control: CGPoint(x: side * 0.50, y: side * 1.00))
        triangle.addQuadCurve(
          to: CGPoint(x: side * 0.50, y: side * 0.11),
          control: CGPoint(x: side * 0.07, y: side * 0.49))
        context.fill(triangle, with: .color(Color(red: 1, green: 0.99, blue: 0.91)))
        context.stroke(triangle, with: .color(Palette.line), lineWidth: side * 0.018)
        rounded(
          CGRect(x: side * 0.36, y: side * 0.58, width: side * 0.28, height: side * 0.29),
          side * 0.025, Palette.ink)
        for index in 0..<13 {
          let x = side * (0.31 + Double((index * 7 + seed) % 11) * 0.032)
          let y = side * (0.34 + Double((index * 3) % 8) * 0.028)
          rounded(
            CGRect(x: x, y: y, width: side * 0.026, height: side * 0.015), 1,
            Palette.wood.opacity(0.5))
        }
      case .citrus:
        let circle = CGRect(x: side * 0.11, y: side * 0.11, width: side * 0.78, height: side * 0.78)
        context.fill(
          Path(ellipseIn: circle), with: .color(Color(red: 0.96, green: 0.55, blue: 0.16)))
        context.stroke(
          Path(ellipseIn: circle.insetBy(dx: side * 0.045, dy: side * 0.045)),
          with: .color(Color(red: 1, green: 0.85, blue: 0.51)), lineWidth: side * 0.04)
        for index in 0..<8 {
          let angle = Double(index) * .pi / 4
          stroke(
            [
              CGPoint(x: side * 0.5, y: side * 0.5),
              CGPoint(x: side * (0.5 + cos(angle) * 0.31), y: side * (0.5 + sin(angle) * 0.31)),
            ],
            Color(red: 1, green: 0.90, blue: 0.63), side * 0.023
          )
        }
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: side * 0.46, y: side * 0.45, width: side * 0.08, height: side * 0.09)),
          with: .color(Palette.paper))
      case .strawberry:
        var berry = Path()
        berry.move(to: CGPoint(x: side * 0.50, y: side * 0.88))
        berry.addCurve(
          to: CGPoint(x: side * 0.18, y: side * 0.28),
          control1: CGPoint(x: side * 0.24, y: side * 0.76),
          control2: CGPoint(x: side * 0.06, y: side * 0.45))
        berry.addQuadCurve(
          to: CGPoint(x: side * 0.82, y: side * 0.28),
          control: CGPoint(x: side * 0.50, y: side * 0.02))
        berry.addCurve(
          to: CGPoint(x: side * 0.50, y: side * 0.88),
          control1: CGPoint(x: side * 0.94, y: side * 0.45),
          control2: CGPoint(x: side * 0.76, y: side * 0.76))
        context.fill(berry, with: .color(Color(red: 0.82, green: 0.25, blue: 0.20)))
        for index in 0..<10 {
          let x = side * (0.30 + Double(index % 3) * 0.17)
          let y = side * (0.32 + Double(index / 3) * 0.12)
          rounded(
            CGRect(x: x, y: y, width: side * 0.025, height: side * 0.045),
            side * 0.015, Color(red: 1, green: 0.83, blue: 0.48))
        }
        for index in 0..<3 {
          let leaf = CGRect(
            x: side * (0.29 + Double(index) * 0.10), y: side * 0.12,
            width: side * 0.19, height: side * 0.17)
          context.fill(Path(ellipseIn: leaf), with: .color(Palette.ink))
        }
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .accessibilityHidden(true)
  }
}

struct PolyominoArt: View {
  let piece: FoodPiece
  var turns = 0
  let cellSize: CGFloat
  var selected = false
  var showLetter = false

  var body: some View {
    let cells = piece.rotated(turns)
    let width = (cells.map(\.x).max() ?? 0) + 1
    let height = (cells.map(\.y).max() ?? 0) + 1
    ZStack(alignment: .topLeading) {
      ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
        RoundedRectangle(cornerRadius: cellSize * 0.16)
          .fill(piece.ingredient.isSweet ? Color(red: 0.91, green: 0.80, blue: 0.57) : Palette.sage)
          .frame(width: cellSize - 1, height: cellSize - 1)
          .overlay {
            FoodArt(ingredient: piece.ingredient, seed: index).padding(cellSize * 0.02)
          }
          .position(x: (CGFloat(cell.x) + 0.5) * cellSize, y: (CGFloat(cell.y) + 0.5) * cellSize)
      }
      Canvas { context, _ in
        let set = Set(cells)
        var path = Path()
        for cell in cells {
          let x = CGFloat(cell.x) * cellSize
          let y = CGFloat(cell.y) * cellSize
          let edges: [(Cell, CGPoint, CGPoint)] = [
            (Cell(x: cell.x, y: cell.y - 1), CGPoint(x: x, y: y), CGPoint(x: x + cellSize, y: y)),
            (
              Cell(x: cell.x + 1, y: cell.y), CGPoint(x: x + cellSize, y: y),
              CGPoint(x: x + cellSize, y: y + cellSize)
            ),
            (
              Cell(x: cell.x, y: cell.y + 1), CGPoint(x: x + cellSize, y: y + cellSize),
              CGPoint(x: x, y: y + cellSize)
            ),
            (Cell(x: cell.x - 1, y: cell.y), CGPoint(x: x, y: y + cellSize), CGPoint(x: x, y: y)),
          ]
          for (neighbor, start, end) in edges where !set.contains(neighbor) {
            path.move(to: start)
            path.addLine(to: end)
          }
        }
        context.stroke(
          path, with: .color(selected ? Palette.orange : Palette.ink.opacity(0.40)),
          style: StrokeStyle(lineWidth: selected ? 3 : 1.5, lineCap: .round, lineJoin: .round))
      }
      if showLetter {
        Text(piece.id).font(
          .system(size: max(9, cellSize * 0.20), weight: .bold, design: .monospaced)
        )
        .foregroundStyle(Palette.paper).padding(3)
        .background(Palette.ink, in: Circle())
        .offset(x: 3, y: 3)
      }
    }
    .frame(width: CGFloat(width) * cellSize, height: CGFloat(height) * cellSize)
    .shadow(color: Palette.ink.opacity(0.10), radius: 2, y: 3)
    .accessibilityHidden(true)
  }
}

struct LunchIllustration: View {
  var ribbon = false
  var body: some View {
    let lunch = LunchBook.all[2]
    GeometryReader { geometry in
      let cell = geometry.size.width / 5.5
      ZStack {
        RoundedRectangle(cornerRadius: 26).fill(Palette.ink)
        RoundedRectangle(cornerRadius: 20).fill(Palette.wood).padding(7)
        RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.90, green: 0.80, blue: 0.62)).padding(
          13)
        ZStack(alignment: .topLeading) {
          ForEach(lunch.pieces) { piece in
            PolyominoArt(piece: piece, cellSize: cell)
              .offset(x: CGFloat(piece.solution.x) * cell, y: CGFloat(piece.solution.y) * cell)
          }
          Rectangle().fill(Palette.ink).frame(width: 5, height: cell * 4)
            .offset(x: cell * 3 - 2.5)
        }
        .frame(width: cell * 5, height: cell * 4, alignment: .topLeading)
        if ribbon {
          Rectangle().fill(Palette.orange).frame(width: 26)
          Rectangle().fill(Palette.orange).frame(height: 22)
          Image(systemName: "infinity").font(.system(size: 72, weight: .regular))
            .foregroundStyle(Palette.paper).rotationEffect(.degrees(-20))
        }
      }
    }
    .aspectRatio(1.25, contentMode: .fit)
    .shadow(color: Palette.ink.opacity(0.17), radius: 12, x: 4, y: 15)
    .accessibilityHidden(true)
  }
}

struct PrimaryButton: ButtonStyle {
  var light = false
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 16, weight: .semibold))
      .frame(maxWidth: .infinity).frame(minHeight: 54)
      .foregroundStyle(light ? Palette.ink : Palette.paper)
      .background(
        light ? Palette.sage.opacity(0.35) : Palette.ink, in: RoundedRectangle(cornerRadius: 16)
      )
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .opacity(configuration.isPressed ? 0.85 : 1)
  }
}

struct IconButton: View {
  let symbol: String
  let label: String
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      Image(systemName: symbol).font(.system(size: 17, weight: .medium))
        .frame(width: 44, height: 44)
        .background(Palette.paper.opacity(0.85), in: Circle())
        .overlay(Circle().stroke(Palette.line, lineWidth: 1))
    }
    .foregroundStyle(Palette.ink)
    .accessibilityLabel(label).accessibilityIdentifier(label)
  }
}
