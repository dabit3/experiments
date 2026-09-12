import SwiftUI

/// Powderline's visual system: a warm paper cream against deep alpine ink,
/// amber sun light for rewards and one coral accent shared by the rider,
/// flags and personal-best stamps.
enum Palette {
  static let cream = Color(hex: 0xF6EFE1)
  static let paper = Color(hex: 0xEFE4D0)
  static let ink = Color(hex: 0x14263A)
  static let inkDeep = Color(hex: 0x0C1727)
  static let amber = Color(hex: 0xF2B15C)
  static let coral = Color(hex: 0xE8735A)
  static let mist = Color(hex: 0xC9D6E0)
}

enum Glyph {
  case peaks, tap, rotate, flow, leaf, snowflake, pause, play, sound, muted, close, gem, flag,
    arrow, share, rock
}

/// Hand-drawn line glyphs replace system symbols so every icon shares the
/// same 1.6pt stroke, rounded joins and alpine vocabulary.
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

/// The Powderline wordmark: spaced serif capitals over a single carved
/// trail line that dips, kicks and lets the sun rise through it.
struct Wordmark: View {
  var body: some View {
    VStack(spacing: 0) {
      Text("POWDERLINE")
        .font(.system(size: 41, weight: .semibold, design: .serif))
        .tracking(7)
        .minimumScaleFactor(0.72)
        .lineLimit(1)
        .shadow(color: Palette.inkDeep.opacity(0.28), radius: 14, y: 6)
      TrailLine()
        .frame(height: 30)
        .padding(.horizontal, 6)
        .padding(.top, 2)
    }
  }
}

struct TrailLine: View {
  var body: some View {
    Canvas { context, size in
      let midY = size.height * 0.5
      let sun = CGPoint(x: size.width * 0.5, y: midY + 3)
      context.fill(
        Path(ellipseIn: CGRect(x: sun.x - 12, y: sun.y - 12, width: 24, height: 24)),
        with: .linearGradient(
          Gradient(colors: [Color(hex: 0xFFF3DA), Palette.amber]),
          startPoint: CGPoint(x: sun.x, y: sun.y - 12), endPoint: CGPoint(x: sun.x, y: sun.y + 12)))
      var line = Path()
      line.move(to: CGPoint(x: 0, y: midY - 6))
      line.addCurve(
        to: CGPoint(x: size.width * 0.5, y: midY + 3),
        control1: CGPoint(x: size.width * 0.18, y: midY - 6),
        control2: CGPoint(x: size.width * 0.34, y: midY + 3))
      line.addCurve(
        to: CGPoint(x: size.width * 0.86, y: midY - 4),
        control1: CGPoint(x: size.width * 0.66, y: midY + 3),
        control2: CGPoint(x: size.width * 0.78, y: midY + 2))
      line.addQuadCurve(
        to: CGPoint(x: size.width, y: midY - 14),
        control: CGPoint(x: size.width * 0.95, y: midY - 5))
      context.stroke(
        line, with: .color(Palette.cream), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
      let rider = CGPoint(x: size.width * 0.86, y: midY - 4)
      context.fill(
        Path(ellipseIn: CGRect(x: rider.x - 2.4, y: rider.y - 9, width: 4.8, height: 4.8)),
        with: .color(Palette.coral))
      var body = Path()
      body.move(to: CGPoint(x: rider.x, y: rider.y - 5))
      body.addLine(to: CGPoint(x: rider.x - 1.5, y: rider.y - 1))
      context.stroke(
        body, with: .color(Palette.cream), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }
  }
}

/// A miniature ridge line printed along the top of paper cards.
struct RidgeBand: View {
  var body: some View {
    Canvas { context, size in
      for layer in 0..<3 {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        var x = 0.0
        while x <= size.width + 4 {
          let world = x / 34 + Double(layer) * 2.1
          let ridge = abs(sin(world)) * 0.6 + abs(sin(world * 2.3 + 1.1)) * 0.4
          let y = size.height * (0.32 + Double(layer) * 0.2) - ridge * size.height * 0.3
          path.addLine(to: CGPoint(x: x, y: y))
          x += 4
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        context.fill(path, with: .color(Palette.ink.opacity(0.10 + Double(layer) * 0.12)))
      }
      let sun = CGPoint(x: size.width * 0.78, y: size.height * 0.34)
      context.fill(
        Path(ellipseIn: CGRect(x: sun.x - 7, y: sun.y - 7, width: 14, height: 14)),
        with: .color(Palette.amber))
    }
  }
}

/// Rounded ticket stub: a paper card with a perforated notch line.
struct Perforation: View {
  var body: some View {
    HStack(spacing: 0) {
      Circle().fill(Palette.inkDeep.opacity(0.78)).frame(width: 16, height: 16)
        .offset(x: -8)
      Line().stroke(
        Palette.ink.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [3, 4])
      )
      .frame(height: 1)
      Circle().fill(Palette.inkDeep.opacity(0.78)).frame(width: 16, height: 16)
        .offset(x: 8)
    }
    .frame(height: 16)
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

struct StampBadge: View {
  let title: String

  var body: some View {
    Text(title)
      .font(.system(size: 9, weight: .bold))
      .tracking(2)
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.coral, lineWidth: 1.6))
      .overlay(
        RoundedRectangle(cornerRadius: 6).stroke(Palette.coral.opacity(0.5), lineWidth: 1)
          .padding(-3)
      )
      .foregroundStyle(Palette.coral)
      .rotationEffect(.degrees(-7))
  }
}

struct PressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.975 : 1)
      .opacity(configuration.isPressed ? 0.92 : 1)
      .animation(.spring(duration: 0.24, bounce: 0.2), value: configuration.isPressed)
  }
}
