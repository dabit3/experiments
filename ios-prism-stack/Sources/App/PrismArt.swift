import SwiftUI

enum PrismStyle {
  static let ink = Color(red: 0.025, green: 0.038, blue: 0.067)
  static let mist = Color(red: 0.55, green: 0.64, blue: 0.72)
  static let ice = Color(red: 0.61, green: 0.94, blue: 0.94)
  static let paper = Color(red: 0.91, green: 0.94, blue: 0.94)
}

extension Jewel {
  var color: Color {
    switch self {
    case .cyan: return Color(red: 0.19, green: 0.82, blue: 0.89)
    case .gold: return Color(red: 0.95, green: 0.79, blue: 0.28)
    case .violet: return Color(red: 0.65, green: 0.44, blue: 0.96)
    case .green: return Color(red: 0.27, green: 0.83, blue: 0.58)
    case .rose: return Color(red: 0.96, green: 0.35, blue: 0.53)
    case .blue: return Color(red: 0.30, green: 0.51, blue: 0.98)
    case .amber: return Color(red: 0.98, green: 0.55, blue: 0.25)
    }
  }
}

func drawGem(_ context: GraphicsContext, rect: CGRect, jewel: Jewel, ghost: Bool = false) {
  let inset = rect.insetBy(dx: 1.1, dy: 1.1)
  let path = Path(roundedRect: inset, cornerRadius: max(2, rect.width * 0.10))
  if ghost {
    context.fill(path, with: .color(jewel.color.opacity(0.11)))
    context.stroke(path, with: .color(jewel.color.opacity(0.85)), lineWidth: 1.4)
    return
  }
  context.fill(
    path,
    with: .linearGradient(
      Gradient(colors: [jewel.color.opacity(0.98), jewel.color.opacity(0.44)]),
      startPoint: inset.origin, endPoint: CGPoint(x: inset.maxX, y: inset.maxY)))
  context.stroke(path, with: .color(jewel.color.opacity(0.95)), lineWidth: 0.7)
  let inner = inset.insetBy(dx: rect.width * 0.12, dy: rect.width * 0.12)
  context.fill(
    Path(roundedRect: inner, cornerRadius: 1.5),
    with: .linearGradient(
      Gradient(colors: [.white.opacity(0.14), .clear, .black.opacity(0.16)]),
      startPoint: inner.origin, endPoint: CGPoint(x: inner.maxX, y: inner.maxY)))
  var highlight = Path()
  highlight.move(to: CGPoint(x: inset.minX + 3, y: inset.minY + 2))
  highlight.addLine(to: CGPoint(x: inset.maxX - 3, y: inset.minY + 2))
  context.stroke(highlight, with: .color(.white.opacity(0.5)), lineWidth: 0.8)
}

struct PiecePreview: View {
  let jewel: Jewel?

  var body: some View {
    Canvas { context, size in
      guard let jewel else {
        context.draw(
          Text("—").font(.system(size: 19, weight: .light)).foregroundStyle(PrismStyle.mist),
          at: CGPoint(x: size.width / 2, y: size.height / 2))
        return
      }
      let cells = jewel.cells
      let minX = cells.map(\.x).min() ?? 0
      let maxX = cells.map(\.x).max() ?? 3
      let unit = min(size.width / 4, size.height / 2)
      let offset = (size.width - CGFloat(maxX - minX + 1) * unit) / 2
      for cell in cells {
        drawGem(
          context,
          rect: CGRect(
            x: offset + CGFloat(cell.x - minX) * unit, y: CGFloat(cell.y) * unit,
            width: unit, height: unit), jewel: jewel)
      }
    }
    .accessibilityLabel(jewel.map { "\($0) piece" } ?? "Empty")
  }
}

struct PrismBackdrop: View {
  var body: some View {
    ZStack {
      PrismStyle.ink
      RadialGradient(
        colors: [Color(red: 0.08, green: 0.20, blue: 0.24).opacity(0.5), .clear],
        center: .topLeading, startRadius: 5, endRadius: 550)
      RadialGradient(
        colors: [Color.purple.opacity(0.055), .clear],
        center: .bottomTrailing, startRadius: 5, endRadius: 400)
    }.ignoresSafeArea()
  }
}

struct HeroPrism: View {
  var body: some View {
    Canvas { context, size in
      let unit = min(size.width / 7, size.height / 6)
      let pieces: [(Jewel, Int, Int)] = [
        (.cyan, 0, 4), (.amber, 3, 3), (.violet, 1, 1), (.gold, 3, 0),
      ]
      for (jewel, x, y) in pieces {
        for cell in jewel.cells {
          let rect = CGRect(
            x: CGFloat(cell.x + x) * unit, y: CGFloat(cell.y + y) * unit, width: unit,
            height: unit)
          drawGem(context, rect: rect, jewel: jewel)
        }
      }
    }
    .rotationEffect(.degrees(-10))
    .shadow(color: .cyan.opacity(0.08), radius: 28, y: 15)
    .accessibilityHidden(true)
  }
}

struct Eyebrow: View {
  let text: String
  var body: some View {
    Text(text).font(.system(size: 9, weight: .semibold, design: .monospaced))
      .tracking(2).foregroundStyle(PrismStyle.mist)
  }
}

struct PrismButton: View {
  let title: String
  var symbol: String? = nil
  var primary = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Text(title).tracking(0.4)
        if let symbol { Image(systemName: symbol) }
      }
      .font(.system(size: 15, weight: .semibold))
      .frame(maxWidth: .infinity).frame(height: 54)
      .foregroundStyle(primary ? PrismStyle.ink : PrismStyle.paper)
      .background(
        primary ? PrismStyle.ice : Color.white.opacity(0.045),
        in: RoundedRectangle(cornerRadius: 15)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 15)
          .strokeBorder(primary ? Color.white.opacity(0.2) : Color.white.opacity(0.09)))
    }.buttonStyle(.plain)
  }
}
