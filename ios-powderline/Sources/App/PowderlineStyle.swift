import SwiftUI

/// Powderline's arcade cabinet palette: a deep violet ink for panels,
/// electric yellow for score and calls to action, hot pink for tricks and
/// danger, and a cold cyan for controls and secondary information.
enum Palette {
  static let cream = Color(hex: 0xFFF7EA)
  static let paper = Color(hex: 0xFFE7BF)
  static let ink = Color(hex: 0x1B0F3D)
  static let inkDeep = Color(hex: 0x0D0726)
  static let amber = Color(hex: 0xFFC61A)
  static let orange = Color(hex: 0xFF7A1F)
  static let coral = Color(hex: 0xFF3D7F)
  static let mist = Color(hex: 0x5CE7FF)
  static let violet = Color(hex: 0x6A2FD6)
  static let lime = Color(hex: 0x9CFF57)
}

enum Glyph {
  case peaks, tap, rotate, flow, leaf, snowflake, pause, play, sound, muted, close, gem, flag,
    arrow, share, rock, bolt, star, chevrons
}

/// Hand-drawn line glyphs replace system symbols so every icon shares the
/// same stroke, rounded joins and alpine vocabulary.
struct GlyphShape: Shape {
  let glyph: Glyph

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let w = rect.width
    let h = rect.height
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
    }
    switch glyph {
    case .peaks:
      path.move(to: point(0, 0.86))
      path.addLine(to: point(0.3, 0.2))
      path.addLine(to: point(0.48, 0.56))
      path.addLine(to: point(0.64, 0.3))
      path.addLine(to: point(1, 0.86))
      path.move(to: point(0.22, 0.36))
      path.addLine(to: point(0.3, 0.46))
      path.addLine(to: point(0.38, 0.36))
    case .tap:
      path.addEllipse(
        in: CGRect(
          x: point(0.5, 0.62).x - w * 0.11, y: point(0.5, 0.62).y - h * 0.11,
          width: w * 0.22, height: h * 0.22))
      path.move(to: point(0.18, 0.5))
      path.addQuadCurve(to: point(0.82, 0.5), control: point(0.5, 0.02))
      path.move(to: point(0.5, 0.74))
      path.addLine(to: point(0.5, 0.95))
    case .rotate:
      path.addArc(
        center: point(0.5, 0.5), radius: w * 0.36, startAngle: .degrees(-60),
        endAngle: .degrees(220), clockwise: false)
      path.move(to: point(0.84, 0.16))
      path.addLine(to: point(0.86, 0.4))
      path.addLine(to: point(0.63, 0.35))
    case .flow:
      for (index, height) in [0.42, 0.62, 0.86].enumerated() {
        let x = 0.2 + CGFloat(index) * 0.3
        path.move(to: point(x, 0.9))
        path.addLine(to: point(x, 0.9 - height))
      }
      path.move(to: point(0.2, 0.48))
      path.addLine(to: point(0.5, 0.28))
      path.addLine(to: point(0.8, 0.04))
    case .leaf:
      path.move(to: point(0.16, 0.86))
      path.addQuadCurve(to: point(0.86, 0.14), control: point(0.14, 0.14))
      path.addQuadCurve(to: point(0.16, 0.86), control: point(0.86, 0.86))
      path.move(to: point(0.2, 0.82))
      path.addLine(to: point(0.72, 0.28))
    case .snowflake:
      for index in 0..<3 {
        let angle = Double(index) * .pi / 3
        let dx = CGFloat(cos(angle)) * 0.46
        let dy = CGFloat(sin(angle)) * 0.46
        path.move(to: point(0.5 - dx, 0.5 - dy))
        path.addLine(to: point(0.5 + dx, 0.5 + dy))
        for sign in [-1.0, 1.0] {
          let tipX = 0.5 + dx * CGFloat(sign) * 0.62
          let tipY = 0.5 + dy * CGFloat(sign) * 0.62
          let branch = angle + .pi / 6 * sign
          path.move(to: point(tipX, tipY))
          path.addLine(
            to: point(
              tipX + CGFloat(cos(branch)) * 0.14 * CGFloat(sign),
              tipY + CGFloat(sin(branch)) * 0.14 * CGFloat(sign)))
          let other = angle - .pi / 6 * sign
          path.move(to: point(tipX, tipY))
          path.addLine(
            to: point(
              tipX + CGFloat(cos(other)) * 0.14 * CGFloat(sign),
              tipY + CGFloat(sin(other)) * 0.14 * CGFloat(sign)))
        }
      }
    case .pause:
      path.move(to: point(0.34, 0.18))
      path.addLine(to: point(0.34, 0.82))
      path.move(to: point(0.66, 0.18))
      path.addLine(to: point(0.66, 0.82))
    case .play:
      path.move(to: point(0.3, 0.14))
      path.addLine(to: point(0.84, 0.5))
      path.addLine(to: point(0.3, 0.86))
      path.closeSubpath()
    case .sound, .muted:
      path.move(to: point(0.14, 0.38))
      path.addLine(to: point(0.3, 0.38))
      path.addLine(to: point(0.52, 0.18))
      path.addLine(to: point(0.52, 0.82))
      path.addLine(to: point(0.3, 0.62))
      path.addLine(to: point(0.14, 0.62))
      path.closeSubpath()
      if glyph == .sound {
        path.move(to: point(0.66, 0.36))
        path.addQuadCurve(to: point(0.66, 0.64), control: point(0.78, 0.5))
        path.move(to: point(0.76, 0.24))
        path.addQuadCurve(to: point(0.76, 0.76), control: point(0.98, 0.5))
      } else {
        path.move(to: point(0.66, 0.38))
        path.addLine(to: point(0.9, 0.62))
        path.move(to: point(0.9, 0.38))
        path.addLine(to: point(0.66, 0.62))
      }
    case .close:
      path.move(to: point(0.22, 0.22))
      path.addLine(to: point(0.78, 0.78))
      path.move(to: point(0.78, 0.22))
      path.addLine(to: point(0.22, 0.78))
    case .gem:
      path.move(to: point(0.5, 0.06))
      path.addLine(to: point(0.86, 0.5))
      path.addLine(to: point(0.5, 0.94))
      path.addLine(to: point(0.14, 0.5))
      path.closeSubpath()
      path.move(to: point(0.14, 0.5))
      path.addLine(to: point(0.86, 0.5))
    case .flag:
      path.move(to: point(0.26, 0.94))
      path.addLine(to: point(0.26, 0.08))
      path.addLine(to: point(0.8, 0.26))
      path.addLine(to: point(0.26, 0.48))
    case .arrow:
      path.move(to: point(0.1, 0.5))
      path.addLine(to: point(0.9, 0.5))
      path.move(to: point(0.6, 0.2))
      path.addLine(to: point(0.9, 0.5))
      path.addLine(to: point(0.6, 0.8))
    case .share:
      path.move(to: point(0.5, 0.64))
      path.addLine(to: point(0.5, 0.06))
      path.move(to: point(0.3, 0.26))
      path.addLine(to: point(0.5, 0.06))
      path.addLine(to: point(0.7, 0.26))
      path.move(to: point(0.34, 0.44))
      path.addLine(to: point(0.16, 0.44))
      path.addLine(to: point(0.16, 0.92))
      path.addLine(to: point(0.84, 0.92))
      path.addLine(to: point(0.84, 0.44))
      path.addLine(to: point(0.66, 0.44))
    case .rock:
      path.move(to: point(0.08, 0.86))
      path.addQuadCurve(to: point(0.46, 0.14), control: point(0.1, 0.24))
      path.addQuadCurve(to: point(0.92, 0.86), control: point(0.96, 0.3))
      path.closeSubpath()
    case .bolt:
      path.move(to: point(0.58, 0.04))
      path.addLine(to: point(0.22, 0.56))
      path.addLine(to: point(0.48, 0.56))
      path.addLine(to: point(0.4, 0.96))
      path.addLine(to: point(0.78, 0.42))
      path.addLine(to: point(0.52, 0.42))
      path.closeSubpath()
    case .star:
      for index in 0..<10 {
        let angle = -Double.pi / 2 + Double(index) * .pi / 5
        let radius = index % 2 == 0 ? 0.48 : 0.2
        let vertex = point(0.5 + CGFloat(cos(angle) * radius), 0.5 + CGFloat(sin(angle) * radius))
        if index == 0 { path.move(to: vertex) } else { path.addLine(to: vertex) }
      }
      path.closeSubpath()
    case .chevrons:
      for offset in [0.0, 0.34] {
        path.move(to: point(0.14 + offset, 0.14))
        path.addLine(to: point(0.5 + offset, 0.5))
        path.addLine(to: point(0.14 + offset, 0.86))
      }
    }
    return path
  }
}

struct GlyphView: View {
  let glyph: Glyph
  var size: CGFloat = 16
  var weight: CGFloat = 1.6

  var body: some View {
    GlyphShape(glyph: glyph)
      .stroke(style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))
      .frame(width: size, height: size)
  }
}

/// Cabinet-marquee lettering: heavy rounded capitals with a hard outline and
/// a stacked extrusion so numbers and titles read from across the room.
struct ArcadeText: View {
  let text: String
  var size: CGFloat = 32
  var fill: [Color] = [Palette.cream, Palette.amber]
  var outline: Color = Palette.ink
  var depth: CGFloat = 4
  var tracking: CGFloat = 0

  private var base: Text {
    Text(text).font(.system(size: size, weight: .black, design: .rounded)).tracking(tracking)
  }

  var body: some View {
    ZStack {
      ForEach(0..<max(1, Int(depth)), id: \.self) { step in
        base.foregroundStyle(outline).offset(y: CGFloat(step) + 1)
      }
      ForEach(0..<8, id: \.self) { index in
        let angle = Double(index) * .pi / 4
        base.foregroundStyle(outline)
          .offset(x: CGFloat(cos(angle)) * 1.6, y: CGFloat(sin(angle)) * 1.6)
      }
      base.foregroundStyle(LinearGradient(colors: fill, startPoint: .top, endPoint: .bottom))
    }
    .lineLimit(1)
    .minimumScaleFactor(0.5)
    .padding(.bottom, depth)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(text)
  }
}

/// The Powderline wordmark: two stacked marquee lines with a snowboard
/// swoosh cutting under the letters and a sun rising at the tail.
struct Wordmark: View {
  var body: some View {
    VStack(spacing: -6) {
      ArcadeText(
        text: "POWDER", size: 62, fill: [Color(hex: 0xFFF6C8), Palette.amber, Palette.orange],
        outline: Palette.ink, depth: 7, tracking: 1)
      ArcadeText(
        text: "LINE", size: 62, fill: [Color(hex: 0xFFD7EA), Palette.coral, Color(hex: 0xC8177A)],
        outline: Palette.ink, depth: 7, tracking: 9)
      TrailLine()
        .frame(height: 30)
        .padding(.horizontal, 10)
        .padding(.top, 10)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Powderline")
  }
}

struct TrailLine: View {
  var body: some View {
    Canvas { context, size in
      let midY = size.height * 0.5
      var line = Path()
      line.move(to: CGPoint(x: 0, y: midY - 6))
      line.addCurve(
        to: CGPoint(x: size.width * 0.5, y: midY + 4),
        control1: CGPoint(x: size.width * 0.18, y: midY - 6),
        control2: CGPoint(x: size.width * 0.34, y: midY + 4))
      line.addCurve(
        to: CGPoint(x: size.width * 0.86, y: midY - 4),
        control1: CGPoint(x: size.width * 0.66, y: midY + 4),
        control2: CGPoint(x: size.width * 0.78, y: midY + 2))
      line.addQuadCurve(
        to: CGPoint(x: size.width, y: midY - 14),
        control: CGPoint(x: size.width * 0.95, y: midY - 5))
      context.stroke(
        line, with: .color(Palette.ink), style: StrokeStyle(lineWidth: 7, lineCap: .round))
      context.stroke(
        line, with: .color(Palette.mist), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
      let rider = CGPoint(x: size.width * 0.86, y: midY - 4)
      context.fill(
        Path(ellipseIn: CGRect(x: rider.x - 5, y: rider.y - 15, width: 10, height: 10)),
        with: .color(Palette.ink))
      context.fill(
        Path(ellipseIn: CGRect(x: rider.x - 3.4, y: rider.y - 13.4, width: 6.8, height: 6.8)),
        with: .color(Palette.coral))
    }
  }
}

/// Radiating cabinet rays that sit behind titles and rank badges.
struct Starburst: Shape {
  var rays = 18

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = max(rect.width, rect.height)
    for index in 0..<rays {
      let start = Double(index) / Double(rays) * 2 * .pi
      let end = start + .pi / Double(rays)
      path.move(to: center)
      path.addLine(
        to: CGPoint(
          x: center.x + CGFloat(cos(start)) * radius, y: center.y + CGFloat(sin(start)) * radius))
      path.addLine(
        to: CGPoint(
          x: center.x + CGFloat(cos(end)) * radius, y: center.y + CGFloat(sin(end)) * radius))
      path.closeSubpath()
    }
    return path
  }
}

/// Angled speed stripes for panels and tickers.
struct Stripes: Shape {
  var spacing: CGFloat = 14

  func path(in rect: CGRect) -> Path {
    var path = Path()
    var x = rect.minX - rect.height
    while x < rect.maxX {
      path.move(to: CGPoint(x: x, y: rect.maxY))
      path.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
      x += spacing
    }
    return path
  }
}

struct Line: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    return path
  }
}

/// A diagonal sticker used for NEW RECORD and mode tags.
struct StampBadge: View {
  let title: String
  var color: Color = Palette.coral

  var body: some View {
    Text(title)
      .font(.system(size: 11, weight: .black, design: .rounded))
      .tracking(1.6)
      .foregroundStyle(Palette.ink)
      .padding(.horizontal, 12)
      .padding(.vertical, 7)
      .background(color, in: RoundedRectangle(cornerRadius: 6))
      .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.ink, lineWidth: 2))
      .rotationEffect(.degrees(-6))
      .shadow(color: Palette.inkDeep.opacity(0.4), radius: 0, x: 0, y: 3)
  }
}

/// Chunky cabinet button: a bright face standing on a dark plinth. Pressing
/// pushes the face down onto the plinth like a real arcade button.
struct ArcadeButtonStyle: ButtonStyle {
  var face: [Color] = [Color(hex: 0xFFE27A), Palette.amber, Palette.orange]
  var plinth: Color = Color(hex: 0x8A3B00)
  var text: Color = Palette.ink
  var height: CGFloat = 62
  var depth: CGFloat = 7

  func makeBody(configuration: Configuration) -> some View {
    let pressed = configuration.isPressed
    let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    return ZStack {
      shape.fill(plinth).offset(y: depth)
      shape.fill(LinearGradient(colors: face, startPoint: .top, endPoint: .bottom))
        .overlay(
          shape.inset(by: 3).trim(from: 0.53, to: 0.72)
            .stroke(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        )
        .overlay(shape.stroke(Palette.ink, lineWidth: 2.5))
        .overlay(
          configuration.label
            .font(.system(size: 19, weight: .black, design: .rounded))
            .foregroundStyle(text)
        )
        .offset(y: pressed ? depth - 1 : 0)
    }
    .frame(height: height)
    .padding(.bottom, depth)
    .shadow(color: Palette.inkDeep.opacity(pressed ? 0.15 : 0.45), radius: 12, y: 10)
    .animation(.spring(duration: 0.18, bounce: 0.25), value: pressed)
  }
}

/// Outlined chip for secondary actions.
struct ChipButtonStyle: ButtonStyle {
  var tint: Color = Palette.mist

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 13, weight: .black, design: .rounded))
      .foregroundStyle(tint)
      .frame(maxWidth: .infinity, minHeight: 48)
      .background(Palette.ink.opacity(configuration.isPressed ? 0.98 : 0.88), in: Capsule())
      .overlay(Capsule().stroke(tint, lineWidth: 2))
      .scaleEffect(configuration.isPressed ? 0.96 : 1)
      .animation(.spring(duration: 0.2, bounce: 0.3), value: configuration.isPressed)
  }
}

struct PressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.94 : 1)
      .opacity(configuration.isPressed ? 0.92 : 1)
      .animation(.spring(duration: 0.24, bounce: 0.2), value: configuration.isPressed)
  }
}
