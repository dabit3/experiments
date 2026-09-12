import SwiftUI

enum Ink {
  static let night = Color(red: 0.10, green: 0.09, blue: 0.19)
  static let cream = Color(red: 0.98, green: 0.91, blue: 0.79)
  static let gold = Color(red: 1.0, green: 0.73, blue: 0.48)
  static let mint = Color(red: 0.56, green: 0.85, blue: 0.76)
  static let coral = Color(red: 1.0, green: 0.42, blue: 0.43)
}

struct LakeBackdrop: View {
  var violet = false
  var body: some View {
    GeometryReader { geometry in
      Image("Lake")
        .resizable()
        .scaledToFill()
        .frame(width: geometry.size.width, height: geometry.size.height)
        .clipped()
        .overlay(violet ? Color.indigo.opacity(0.24) : Color.clear)
        .overlay {
          LinearGradient(
            colors: [.black.opacity(0.12), .clear, Ink.night.opacity(0.1), Ink.night.opacity(0.7)],
            startPoint: .top, endPoint: .bottom)
        }
    }
    .ignoresSafeArea()
    .accessibilityHidden(true)
  }
}

struct FishArt: View {
  var species: Species
  var silhouette = false

  var color: Color {
    switch species {
    case .emberPerch: return Color(red: 0.91, green: 0.44, blue: 0.32)
    case .ribbonTrout: return Color(red: 0.40, green: 0.67, blue: 0.63)
    case .moonKoi: return Color(red: 0.75, green: 0.60, blue: 0.87)
    case .glassChar: return Color(red: 0.36, green: 0.64, blue: 0.81)
    }
  }

  var body: some View {
    Canvas { context, size in
      context.scaleBy(x: size.width / 300, y: size.height / 160)
      let body = Path { p in
        p.move(to: CGPoint(x: 251, y: 72))
        p.addCurve(
          to: CGPoint(x: 79, y: 57), control1: CGPoint(x: 211, y: 30),
          control2: CGPoint(x: 132, y: 31))
        p.addQuadCurve(to: CGPoint(x: 57, y: 76), control: CGPoint(x: 65, y: 65))
        p.addCurve(
          to: CGPoint(x: 17, y: 41), control1: CGPoint(x: 42, y: 54),
          control2: CGPoint(x: 29, y: 47))
        p.addQuadCurve(to: CGPoint(x: 23, y: 85), control: CGPoint(x: 29, y: 68))
        p.addQuadCurve(to: CGPoint(x: 15, y: 128), control: CGPoint(x: 27, y: 111))
        p.addCurve(
          to: CGPoint(x: 58, y: 94), control1: CGPoint(x: 40, y: 119),
          control2: CGPoint(x: 46, y: 104))
        p.addCurve(
          to: CGPoint(x: 247, y: 91), control1: CGPoint(x: 131, y: 141),
          control2: CGPoint(x: 210, y: 123))
        p.addQuadCurve(to: CGPoint(x: 277, y: 80), control: CGPoint(x: 264, y: 79))
        p.addQuadCurve(to: CGPoint(x: 251, y: 72), control: CGPoint(x: 265, y: 75))
        p.closeSubpath()
      }
      let dorsal = Path { p in
        p.move(to: CGPoint(x: 105, y: 48))
        p.addQuadCurve(to: CGPoint(x: 167, y: 14), control: CGPoint(x: 137, y: 12))
        p.addQuadCurve(to: CGPoint(x: 194, y: 48), control: CGPoint(x: 170, y: 33))
        p.closeSubpath()
      }
      let fin = Path { p in
        p.move(to: CGPoint(x: 130, y: 112))
        p.addQuadCurve(to: CGPoint(x: 172, y: 149), control: CGPoint(x: 144, y: 143))
        p.addQuadCurve(to: CGPoint(x: 175, y: 106), control: CGPoint(x: 179, y: 126))
        p.closeSubpath()
      }
      let fill = silhouette ? Ink.night.opacity(0.85) : color
      context.fill(dorsal, with: .color(fill.opacity(0.85)))
      context.fill(fin, with: .color(fill.opacity(0.75)))
      context.fill(
        body,
        with: .linearGradient(
          Gradient(colors: silhouette ? [fill, fill] : [color, Ink.cream, color.opacity(0.8)]),
          startPoint: CGPoint(x: 150, y: 36), endPoint: CGPoint(x: 150, y: 140)))
      if !silhouette {
        context.stroke(body, with: .color(color.opacity(0.75)), lineWidth: 1.5)
        for row in 0..<4 {
          for column in 0..<12 {
            let x = Double(80 + column * 12 + (row % 2) * 5)
            let y = Double(58 + row * 13)
            let dot = CGRect(x: x, y: y, width: species.rare ? 3 : 2, height: 2)
            context.fill(Path(ellipseIn: dot), with: .color(color.opacity(0.6)))
          }
        }
        let gill = Path { p in
          p.move(to: CGPoint(x: 220, y: 57))
          p.addQuadCurve(to: CGPoint(x: 211, y: 107), control: CGPoint(x: 190, y: 76))
        }
        context.stroke(gill, with: .color(color.opacity(0.7)), lineWidth: 2)
        context.fill(
          Path(ellipseIn: CGRect(x: 238, y: 65, width: 10, height: 10)), with: .color(Ink.night))
        context.fill(
          Path(ellipseIn: CGRect(x: 243, y: 66, width: 3, height: 3)), with: .color(.white))
        for index in 0..<7 {
          let ray = Path { p in
            p.move(to: CGPoint(x: 59, y: 85))
            p.addLine(to: CGPoint(x: 24, y: 53 + index * 10))
          }
          context.stroke(ray, with: .color(Ink.cream.opacity(0.45)), lineWidth: 1)
        }
        let sideFin = Path { p in
          p.move(to: CGPoint(x: 199, y: 92))
          p.addQuadCurve(to: CGPoint(x: 165, y: 126), control: CGPoint(x: 180, y: 128))
          p.addQuadCurve(to: CGPoint(x: 175, y: 92), control: CGPoint(x: 169, y: 103))
        }
        context.fill(sideFin, with: .color(color.opacity(0.7)))
      }
    }
    .accessibilityHidden(true)
  }
}

struct WaterSparkles: View {
  let time: Double
  var body: some View {
    Canvas { context, size in
      for i in 0..<25 {
        let x = (Double(i * 37 % 101) / 101) * size.width
        let y = (Double(i * 17 % 97) / 97) * size.height
        let opacity = 0.1 + 0.4 * abs(sin(time * 0.6 + Double(i)))
        let length = 3 + 8 * abs(sin(time + Double(i)))
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: length, height: 1.2)),
          with: .color(Ink.cream.opacity(opacity)))
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}

struct CapsuleAction: View {
  let title: String
  var icon = "arrow.up.right"
  var dark = false
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack {
        Text(title).font(.system(size: 16, weight: .semibold))
        Spacer()
        Image(systemName: icon).font(.system(size: 16, weight: .medium))
      }
      .padding(.horizontal, 24)
      .frame(minHeight: 58)
      .background(dark ? Ink.night : Ink.cream, in: Capsule())
      .foregroundStyle(dark ? Ink.cream : Ink.night)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(title)
  }
}

struct Eyebrow: View {
  let text: String
  var color = Ink.cream
  var body: some View {
    Text(text.uppercased())
      .font(.system(size: 11, weight: .semibold, design: .monospaced))
      .tracking(2.4)
      .foregroundStyle(color)
  }
}
