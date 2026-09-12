import SwiftUI

enum Palette {
  static let background = Color(red: 0.035, green: 0.042, blue: 0.048)
  static let cream = Color(red: 0.94, green: 0.90, blue: 0.81)
  static let muted = Color(red: 0.60, green: 0.63, blue: 0.61)
  static let ember = Color(red: 1, green: 0.40, blue: 0.20)
  static let mint = Color(red: 0.46, green: 0.90, blue: 0.80)
}

struct VesselShape: Shape {
  var profile: [Double]

  func path(in rect: CGRect) -> Path {
    guard profile.count >= 2 else { return Path() }
    let center = rect.midX
    let unit = rect.width * 0.48
    let top = rect.minY + rect.height * 0.09
    let height = rect.height * 0.79
    let step = height / Double(profile.count - 1)
    var path = Path()
    path.move(to: CGPoint(x: center + profile[0] * unit, y: top))
    for index in 1..<profile.count {
      let previousY = top + Double(index - 1) * step
      let y = top + Double(index) * step
      path.addCurve(
        to: CGPoint(x: center + profile[index] * unit, y: y),
        control1: CGPoint(x: center + profile[index - 1] * unit, y: previousY + step * 0.5),
        control2: CGPoint(x: center + profile[index] * unit, y: y - step * 0.5)
      )
    }
    let last = profile[profile.count - 1] * unit
    path.addQuadCurve(
      to: CGPoint(x: center - last, y: top + height),
      control: CGPoint(x: center, y: rect.maxY)
    )
    for index in (0..<(profile.count - 1)).reversed() {
      let y = top + Double(index) * step
      path.addCurve(
        to: CGPoint(x: center - profile[index] * unit, y: y),
        control1: CGPoint(x: center - profile[index + 1] * unit, y: y + step * 0.5),
        control2: CGPoint(x: center - profile[index] * unit, y: y + step * 0.5)
      )
    }
    path.addQuadCurve(
      to: CGPoint(x: center + profile[0] * unit, y: top),
      control: CGPoint(x: center, y: top + 10)
    )
    path.closeSubpath()
    return path
  }
}

struct VesselArt: View {
  var profile: [Double]
  var molten = false
  var phase = 0.0
  var commission: Commission = .tide

  private var colors: [Color] {
    if molten {
      return [
        Color(red: 0.20, green: 0.025, blue: 0.015), .orange,
        Color(red: 1, green: 0.82, blue: 0.41), Palette.ember,
        Color(red: 0.37, green: 0.025, blue: 0.08),
      ]
    }
    switch commission {
    case .tide:
      return [
        Color(red: 0.01, green: 0.11, blue: 0.15), .cyan.opacity(0.72),
        Palette.mint.opacity(0.60), Color(red: 0.19, green: 0.20, blue: 0.55),
        Color(red: 0.03, green: 0.09, blue: 0.11),
      ]
    case .bloom:
      return [.purple.opacity(0.3), .pink.opacity(0.75), .orange.opacity(0.7), .purple, .indigo]
    case .spire:
      return [.brown, .orange, .yellow.opacity(0.8), .red.opacity(0.7), .purple.opacity(0.4)]
    }
  }

  var body: some View {
    GeometryReader { geometry in
      let size = geometry.size
      let vessel = VesselShape(profile: profile)
      ZStack {
        vessel
          .fill(
            LinearGradient(
              colors: colors, startPoint: .leading, endPoint: .trailing
            )
          )
        vessel.fill(
          LinearGradient(
            colors: [.white.opacity(0.04), .clear, .black.opacity(0.55)],
            startPoint: .top, endPoint: .bottom
          )
        )
        Canvas { context, canvas in
          context.clip(to: vessel.path(in: CGRect(origin: .zero, size: canvas)))
          for line in 0..<34 {
            let y = canvas.height * (0.1 + Double(line) * 0.024)
            var wave = Path()
            wave.move(to: CGPoint(x: 0, y: y))
            wave.addCurve(
              to: CGPoint(x: canvas.width, y: y + 28 * sin(Double(line) * 0.35 + phase)),
              control1: CGPoint(x: canvas.width * 0.30, y: y + 35),
              control2: CGPoint(x: canvas.width * 0.65, y: y - 25)
            )
            context.stroke(
              wave, with: .color((line % 3 == 0 ? Palette.cream : Palette.mint).opacity(0.15)),
              lineWidth: line % 3 == 0 ? 1.7 : 0.6
            )
          }
          for fleck in 0..<52 {
            let x = canvas.width * Double((fleck * 73 + 19) % 100) / 100
            let y = canvas.height * Double((fleck * 31 + 7) % 100) / 100
            context.fill(
              Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
              with: .color(.white.opacity(0.25))
            )
          }
        }
        HStack(spacing: size.width * 0.035) {
          Capsule().fill(.white.opacity(0.12)).frame(width: size.width * 0.065)
          Capsule().fill(.white.opacity(0.70)).frame(width: size.width * 0.012)
          Spacer()
          Capsule().fill(.white.opacity(0.12)).frame(width: size.width * 0.05)
        }
        .padding(.horizontal, size.width * 0.23)
        .padding(.vertical, size.height * 0.18)
        .blur(radius: 3)
        .offset(x: sin(phase) * size.width * 0.045)
        .mask(vessel)
        vessel.stroke(
          LinearGradient(
            colors: [
              Palette.cream.opacity(0.85), .white.opacity(0.10), Palette.mint.opacity(0.55),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
          ), lineWidth: 1.2
        )
        let lipWidth = size.width * 0.96 * (profile.first ?? 0.4)
        Ellipse()
          .fill(Color.black.opacity(0.6))
          .overlay(Ellipse().stroke(Palette.cream.opacity(0.8), lineWidth: 1.5))
          .frame(width: lipWidth, height: max(5, lipWidth * 0.095))
          .position(x: size.width / 2, y: size.height * 0.09)
      }
      .shadow(color: (molten ? Palette.ember : Palette.mint).opacity(0.20), radius: 26)
    }
    .accessibilityHidden(true)
  }
}

struct StudioBackdrop: View {
  var warm = false

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Palette.background
        RadialGradient(
          colors: [
            (warm ? Palette.ember : Palette.mint).opacity(warm ? 0.20 : 0.08), .clear,
          ],
          center: UnitPoint(x: 0.5, y: 0.43), startRadius: 10,
          endRadius: geometry.size.width * 0.85
        )
        Canvas { context, size in
          for index in 0..<55 {
            let x = Double((index * 47 + 9) % 100) / 100 * size.width
            let y = Double((index * 29 + 3) % 100) / 100 * size.height
            context.fill(
              Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
              with: .color(Palette.cream.opacity(0.12))
            )
          }
          let rect = CGRect(
            x: size.width * 0.07, y: size.height * 0.19,
            width: size.width * 0.86, height: size.width * 1.10
          )
          context.stroke(
            Path(roundedRect: rect, cornerRadius: size.width * 0.43),
            with: .color(Palette.cream.opacity(0.065)), lineWidth: 1
          )
        }
      }
    }
    .ignoresSafeArea()
    .accessibilityHidden(true)
  }
}

struct Plinth: View {
  var body: some View {
    ZStack {
      Ellipse()
        .fill(.black.opacity(0.7))
        .frame(height: 32)
        .blur(radius: 12)
        .offset(y: 22)
      RoundedRectangle(cornerRadius: 5)
        .fill(
          LinearGradient(
            colors: [Color(white: 0.16), Color(white: 0.045)], startPoint: .top, endPoint: .bottom)
        )
        .frame(height: 26)
        .offset(y: 10)
      Ellipse()
        .fill(
          LinearGradient(
            colors: [Color(white: 0.22), Color(white: 0.075)], startPoint: .top, endPoint: .bottom)
        )
        .overlay(Ellipse().stroke(.white.opacity(0.18), lineWidth: 0.8))
        .frame(height: 24)
    }
    .frame(height: 40)
    .accessibilityHidden(true)
  }
}
