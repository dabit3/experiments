import SwiftUI

struct WorkshopPressStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .offset(y: configuration.isPressed ? 3 : 0)
      .brightness(configuration.isPressed ? -0.05 : 0)
      .animation(reduceMotion ? nil : .easeOut(duration: 0.13), value: configuration.isPressed)
  }
}

struct DominoMark: View {
  var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 3) {
        ForEach(0..<2) { index in
          VStack {
            Circle().frame(width: 3, height: 3)
            Rectangle().frame(height: 0.5).padding(.horizontal, 2)
            Circle().frame(width: 3, height: 3)
          }
          .padding(.vertical, 4)
          .frame(width: geometry.size.width * 0.35)
          .overlay(RoundedRectangle(cornerRadius: 2).stroke(lineWidth: 0.8))
          .rotationEffect(.degrees(index == 0 ? -14 : 10))
          .offset(y: index == 0 ? 2 : -2)
        }
      }
    }
    .accessibilityHidden(true)
  }
}

struct PieceGlyph: View {
  let kind: PieceKind
  var body: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let u = min(size.width, size.height) * 0.85
      for port in kind.basePorts {
        var path = Path()
        path.move(to: center)
        let end = CGPoint(
          x: center.x + CGFloat(port.dx) * u * 0.55,
          y: center.y + CGFloat(port.dy) * u * 0.45)
        if kind == .bridge {
          path.addQuadCurve(
            to: end, control: CGPoint(x: (center.x + end.x) / 2, y: center.y - u * 0.5))
        } else {
          path.addLine(to: end)
        }
        context.stroke(path, with: .foreground, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        context.fill(
          Path(ellipseIn: CGRect(x: end.x - 2, y: end.y - 2, width: 4, height: 4)),
          with: .foreground)
      }
      context.fill(
        Path(
          roundedRect: CGRect(x: center.x - 2, y: center.y - 5, width: 4, height: 10),
          cornerRadius: 1),
        with: .foreground)
    }
    .accessibilityHidden(true)
  }
}
