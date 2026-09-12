import SwiftUI

enum Palette {
  static let cream = Color(red: 0.98, green: 0.94, blue: 0.83)
  static let parchment = Color(red: 0.93, green: 0.86, blue: 0.70)
  static let honey = Color(red: 0.93, green: 0.74, blue: 0.40)
  static let brass = Color(red: 0.76, green: 0.58, blue: 0.30)
  static let ink = Color(red: 0.08, green: 0.20, blue: 0.18)
  static let pine = Color(red: 0.13, green: 0.30, blue: 0.26)
  static let coral = Color(red: 0.92, green: 0.55, blue: 0.43)
  static let moss = Color(red: 0.42, green: 0.58, blue: 0.36)
}

enum Type {
  static func display(_ size: CGFloat) -> Font { .custom("HoeflerText-Black", size: size) }
  static func serif(_ size: CGFloat) -> Font { .custom("HoeflerText-Regular", size: size) }
  static func italic(_ size: CGFloat) -> Font { .custom("Baskerville-Italic", size: size) }
  static func label(_ size: CGFloat) -> Font { .custom("AvenirNext-DemiBold", size: size) }
  static func body(_ size: CGFloat) -> Font { .custom("AvenirNext-Medium", size: size) }
}

/// A shirt button, the collectible of the woodland.
struct ButtonIcon: View {
  var size: CGFloat = 16

  var body: some View {
    ZStack {
      Circle().fill(
        LinearGradient(
          colors: [Palette.honey, Palette.brass], startPoint: .topLeading,
          endPoint: .bottomTrailing))
      Circle().stroke(Palette.cream.opacity(0.5), lineWidth: size * 0.06).padding(size * 0.2)
      ForEach(0..<4, id: \.self) { index in
        Circle().fill(Palette.ink.opacity(0.75))
          .frame(width: size * 0.13, height: size * 0.13)
          .offset(
            x: (index % 2 == 0 ? -1 : 1) * size * 0.14,
            y: (index < 2 ? -1 : 1) * size * 0.14)
      }
    }.frame(width: size, height: size)
  }
}

struct HeartShape: Shape {
  func path(in rect: CGRect) -> Path {
    let w = rect.width
    let h = rect.height
    var path = Path()
    path.move(to: CGPoint(x: w / 2, y: h))
    path.addCurve(
      to: CGPoint(x: 0, y: h * 0.32), control1: CGPoint(x: w * 0.1, y: h * 0.78),
      control2: CGPoint(x: 0, y: h * 0.58))
    path.addArc(
      center: CGPoint(x: w * 0.25, y: h * 0.28), radius: w * 0.25, startAngle: .degrees(180),
      endAngle: .degrees(0), clockwise: false)
    path.addArc(
      center: CGPoint(x: w * 0.75, y: h * 0.28), radius: w * 0.25, startAngle: .degrees(180),
      endAngle: .degrees(0), clockwise: false)
    path.addCurve(
      to: CGPoint(x: w / 2, y: h), control1: CGPoint(x: w, y: h * 0.58),
      control2: CGPoint(x: w * 0.9, y: h * 0.78))
    return path
  }
}

struct StarShape: Shape {
  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let outer = min(rect.width, rect.height) / 2
    var path = Path()
    for i in 0..<10 {
      let radius = i % 2 == 0 ? outer : outer * 0.45
      let angle = Double(i) * .pi / 5 - .pi / 2
      let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
      if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
  }
}

struct StarBadge: View {
  let earned: Bool
  var size: CGFloat = 30

  var body: some View {
    ZStack {
      if earned {
        StarShape().fill(Palette.honey.opacity(0.28)).frame(width: size * 1.7, height: size * 1.7)
          .blur(radius: 6)
      }
      StarShape()
        .fill(
          earned
            ? AnyShapeStyle(
              LinearGradient(
                colors: [Palette.cream, Palette.honey, Palette.brass], startPoint: .top,
                endPoint: .bottom))
            : AnyShapeStyle(Palette.ink.opacity(0.4))
        )
        .overlay(
          StarShape().stroke(earned ? Palette.brass : Palette.cream.opacity(0.28), lineWidth: 1.2)
        )
        .frame(width: size, height: size)
    }.frame(width: size * 1.7, height: size * 1.7)
  }
}

/// Thin rule with a pair of leaves at the centre; the signature divider.
struct Flourish: View {
  var width: CGFloat = 180
  var color = Palette.honey

  var body: some View {
    Canvas { context, size in
      let midY = size.height / 2
      let midX = size.width / 2
      var rule = Path()
      rule.move(to: CGPoint(x: 0, y: midY))
      rule.addLine(to: CGPoint(x: midX - 22, y: midY))
      rule.move(to: CGPoint(x: midX + 22, y: midY))
      rule.addLine(to: CGPoint(x: size.width, y: midY))
      context.stroke(rule, with: .color(color.opacity(0.7)), lineWidth: 1)
      for side in [-1.0, 1.0] {
        var leaf = Path()
        let tip = CGPoint(x: midX + side * 18, y: midY - 1)
        leaf.move(to: CGPoint(x: midX + side * 3, y: midY + 1))
        leaf.addQuadCurve(to: tip, control: CGPoint(x: midX + side * 9, y: midY - 8))
        leaf.addQuadCurve(
          to: CGPoint(x: midX + side * 3, y: midY + 1),
          control: CGPoint(x: midX + side * 11, y: midY + 6))
        context.fill(leaf, with: .color(color))
      }
      context.fill(
        Path(ellipseIn: CGRect(x: midX - 2, y: midY - 2, width: 4, height: 4)),
        with: .color(color))
    }.frame(width: width, height: 16)
  }
}

/// Dark, brass-bound plaque used for HUD groups and dialogs.
struct Plaque: ViewModifier {
  var radius: CGFloat = 18
  var rivets = false
  var fill: Double = 0.94

  func body(content: Content) -> some View {
    content
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(
              LinearGradient(
                colors: [Palette.pine.opacity(fill), Palette.ink.opacity(fill)],
                startPoint: .top, endPoint: .bottom))
          RoundedRectangle(cornerRadius: radius, style: .continuous)
            .stroke(Palette.brass.opacity(0.55), lineWidth: 1)
          RoundedRectangle(cornerRadius: max(4, radius - 5), style: .continuous)
            .stroke(Palette.cream.opacity(0.09), lineWidth: 1).padding(4)
          if rivets {
            ForEach(0..<4, id: \.self) { index in
              Circle().fill(Palette.brass).frame(width: 4, height: 4)
                .overlay(
                  Circle().fill(Palette.cream.opacity(0.45)).frame(width: 1.5, height: 1.5).offset(
                    x: -0.6, y: -0.6)
                )
                .frame(
                  maxWidth: .infinity, maxHeight: .infinity,
                  alignment: [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing][index]
                )
                .padding(9)
            }
          }
        }
      )
      .shadow(color: .black.opacity(0.28), radius: 14, y: 8)
  }
}

extension View {
  func plaque(radius: CGFloat = 18, rivets: Bool = false, fill: Double = 0.94) -> some View {
    modifier(Plaque(radius: radius, rivets: rivets, fill: fill))
  }
}

/// Honey brass button with a bevelled top light.
struct BrassButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(Palette.ink)
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(
              LinearGradient(
                colors: [Color(red: 0.99, green: 0.84, blue: 0.53), Palette.honey, Palette.brass],
                startPoint: .top, endPoint: .bottom))
          RoundedRectangle(cornerRadius: 15, style: .continuous)
            .stroke(Palette.cream.opacity(0.6), lineWidth: 1)
          RoundedRectangle(cornerRadius: 11, style: .continuous)
            .stroke(Palette.ink.opacity(0.18), lineWidth: 1).padding(3)
        }
      )
      .shadow(color: Palette.honey.opacity(configuration.isPressed ? 0.1 : 0.35), radius: 14, y: 6)
      .scaleEffect(configuration.isPressed ? 0.965 : 1)
      .animation(.spring(duration: 0.22), value: configuration.isPressed)
  }
}

struct GhostButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(Palette.cream.opacity(configuration.isPressed ? 0.6 : 0.9))
      .background(
        RoundedRectangle(cornerRadius: 15, style: .continuous)
          .stroke(Palette.brass.opacity(0.5), lineWidth: 1)
          .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Palette.cream.opacity(0.05))
          )
      )
      .scaleEffect(configuration.isPressed ? 0.965 : 1)
  }
}

/// Darkens screen edges so the HUD sits in a framed vignette.
struct Vignette: View {
  var body: some View {
    RadialGradient(
      colors: [.clear, .clear, Palette.ink.opacity(0.42)], center: .center, startRadius: 160,
      endRadius: 720
    ).ignoresSafeArea().allowsHitTesting(false)
  }
}
