import SwiftUI

enum Ink {
  static let paper = Color(red: 0.955, green: 0.935, blue: 0.885)
  static let paperLight = Color(red: 0.985, green: 0.975, blue: 0.945)
  static let paperDeep = Color(red: 0.905, green: 0.88, blue: 0.82)
  static let navy = Color(red: 0.08, green: 0.16, blue: 0.22)
  static let navyDeep = Color(red: 0.045, green: 0.10, blue: 0.15)
  static let sea = Color(red: 0.11, green: 0.31, blue: 0.40)
  static let muted = Color(red: 0.42, green: 0.45, blue: 0.44)
  static let rule = Color(red: 0.82, green: 0.80, blue: 0.74)
  static let gold = Color(red: 0.80, green: 0.62, blue: 0.28)
  static let park = Color(red: 0.70, green: 0.76, blue: 0.60)
  static let routes: [Color] = [
    Color(red: 0.85, green: 0.30, blue: 0.20),
    Color(red: 0.07, green: 0.48, blue: 0.47),
    Color(red: 0.80, green: 0.58, blue: 0.12),
    Color(red: 0.42, green: 0.36, blue: 0.66),
  ]

  static let header = LinearGradient(
    colors: [navy, navyDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// Deterministic speckle overlay that gives every paper surface a printed, tactile grain.
struct PaperGrain: View {
  var density = 140.0

  var body: some View {
    Canvas { context, size in
      var generator = SeededGenerator(state: 11)
      let count = Int(size.width * size.height / density)
      for _ in 0..<count {
        let x = Double(generator.next() % 10_000) / 10_000 * size.width
        let y = Double(generator.next() % 10_000) / 10_000 * size.height
        let dark = generator.next() % 3 == 0
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: 1.3, height: 1.3)),
          with: .color(dark ? Ink.navy.opacity(0.07) : Color.white.opacity(0.4)))
      }
    }
    .allowsHitTesting(false)
  }
}

/// Paper sheet with grain and a soft desk shadow — the app's primary surface.
struct Sheet<Content: View>: View {
  var radius = 22.0
  var tint = Ink.paper
  @ViewBuilder let content: () -> Content

  var body: some View {
    content()
      .background(tint)
      .overlay(PaperGrain().clipShape(RoundedRectangle(cornerRadius: radius)))
      .clipShape(RoundedRectangle(cornerRadius: radius))
      .overlay(
        RoundedRectangle(cornerRadius: radius).strokeBorder(Color.white.opacity(0.7), lineWidth: 1)
      )
      .shadow(color: Ink.navyDeep.opacity(0.28), radius: 18, y: 10)
  }
}

/// Rounded ticket with side notches and a perforated rule.
struct TicketShape: Shape {
  var notch = 7.0
  var notchY = 0.62

  func path(in rect: CGRect) -> Path {
    var path = Path(roundedRect: rect, cornerRadius: 14)
    let y = rect.minY + rect.height * notchY
    var holes = Path()
    holes.addEllipse(
      in: CGRect(x: rect.minX - notch, y: y - notch, width: notch * 2, height: notch * 2))
    holes.addEllipse(
      in: CGRect(x: rect.maxX - notch, y: y - notch, width: notch * 2, height: notch * 2))
    path = path.subtracting(holes)
    return path
  }
}

struct Eyebrow: View {
  let text: String
  var tone = Ink.muted
  var size = 8.0

  init(_ text: String, tone: Color = Ink.muted, size: Double = 8) {
    self.text = text
    self.tone = tone
    self.size = size
  }

  var body: some View {
    Text(text).font(.system(size: size, weight: .semibold)).tracking(1.6).foregroundStyle(tone)
  }
}

struct PaperButton: ButtonStyle {
  enum Tone { case navy, coral, quiet }
  var tone = Tone.navy

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 15, weight: .semibold))
      .frame(maxWidth: .infinity, minHeight: 52)
      .background(background)
      .foregroundStyle(tone == .quiet ? Ink.navy : Ink.paperLight)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .strokeBorder(
            tone == .quiet ? Ink.rule : Color.white.opacity(0.18), lineWidth: 1)
      )
      .shadow(
        color: shadow, radius: configuration.isPressed ? 2 : 10, y: configuration.isPressed ? 1 : 5
      )
      .scaleEffect(configuration.isPressed ? 0.985 : 1)
      .animation(.spring(duration: 0.25), value: configuration.isPressed)
  }

  private var background: some ShapeStyle {
    switch tone {
    case .navy:
      LinearGradient(colors: [Ink.navy, Ink.navyDeep], startPoint: .top, endPoint: .bottom)
    case .coral:
      LinearGradient(
        colors: [Ink.routes[0], Color(red: 0.72, green: 0.22, blue: 0.15)], startPoint: .top,
        endPoint: .bottom)
    case .quiet:
      LinearGradient(colors: [Ink.paperLight, Ink.paper], startPoint: .top, endPoint: .bottom)
    }
  }

  private var shadow: Color {
    switch tone {
    case .navy: Ink.navyDeep.opacity(0.35)
    case .coral: Ink.routes[0].opacity(0.4)
    case .quiet: Ink.navyDeep.opacity(0.12)
    }
  }
}

/// Metro-signage roundel used for line numbers throughout the interface.
struct Roundel: View {
  let number: Int
  let color: Color
  var filled = true
  var size = 30.0

  var body: some View {
    ZStack {
      Circle().fill(filled ? color : Ink.paperLight)
      Circle().strokeBorder(color, lineWidth: filled ? 0 : 2.5)
      Text("\(number)")
        .font(.system(size: size * 0.48, weight: .bold, design: .rounded))
        .foregroundStyle(filled ? Ink.paperLight : color)
    }
    .frame(width: size, height: size)
  }
}

/// Small compass rose used as a recurring signature mark.
struct CompassRose: View {
  var color = Ink.navy
  var body: some View {
    Canvas { context, size in
      let c = CGPoint(x: size.width / 2, y: size.height / 2)
      let r = min(size.width, size.height) / 2
      context.stroke(
        Path(
          ellipseIn: CGRect(x: c.x - r * 0.62, y: c.y - r * 0.62, width: r * 1.24, height: r * 1.24)
        ),
        with: .color(color.opacity(0.5)), lineWidth: 0.8)
      var star = Path()
      for index in 0..<4 {
        let angle = Double(index) * .pi / 2 - .pi / 2
        let tip = CGPoint(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r)
        let left = CGPoint(
          x: c.x + cos(angle - 0.5) * r * 0.22, y: c.y + sin(angle - 0.5) * r * 0.22)
        let right = CGPoint(
          x: c.x + cos(angle + 0.5) * r * 0.22, y: c.y + sin(angle + 0.5) * r * 0.22)
        star.move(to: tip)
        star.addLine(to: left)
        star.addLine(to: right)
        star.closeSubpath()
      }
      context.fill(star, with: .color(color))
      var north = Path()
      north.move(to: CGPoint(x: c.x, y: c.y - r))
      north.addLine(
        to: CGPoint(
          x: c.x + cos(-.pi / 2 - 0.5) * r * 0.22, y: c.y + sin(-.pi / 2 - 0.5) * r * 0.22))
      north.addLine(
        to: CGPoint(
          x: c.x + cos(-.pi / 2 + 0.5) * r * 0.22, y: c.y + sin(-.pi / 2 + 0.5) * r * 0.22))
      north.closeSubpath()
      context.fill(north, with: .color(Ink.routes[0]))
    }
  }
}
