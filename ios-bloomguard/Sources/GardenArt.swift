import SwiftUI

extension Color {
  static let ink = Color(red: 0.14, green: 0.25, blue: 0.20)
  static let cream = Color(red: 0.98, green: 0.95, blue: 0.85)
  static let gold = Color(red: 0.98, green: 0.74, blue: 0.25)
  static let moss = Color(red: 0.31, green: 0.43, blue: 0.29)
}

struct GardenArt: View {
  var seed: Seed
  var body: some View {
    Canvas { context, size in
      let scale = min(size.width, size.height) / 100
      context.scaleBy(x: scale, y: scale)
      func oval(_ x: Double, _ y: Double, _ width: Double, _ height: Double, _ color: Color) {
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: width, height: height)), with: .color(color))
      }
      func line(_ points: [CGPoint], _ color: Color, _ width: Double) {
        var path = Path()
        path.addLines(points)
        context.stroke(
          path, with: .color(color),
          style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
      }
      oval(16, 84, 68, 10, .black.opacity(0.13))
      line(
        [CGPoint(x: 50, y: 83), CGPoint(x: 50, y: 45)], .init(red: 0.24, green: 0.42, blue: 0.22), 8
      )
      oval(23, 68, 27, 13, .init(red: 0.38, green: 0.57, blue: 0.28))
      oval(50, 73, 30, 12, .init(red: 0.27, green: 0.46, blue: 0.24))
      switch seed {
      case .marigold:
        for index in 0..<10 {
          let angle = Double(index) * .pi / 5
          oval(40 + cos(angle) * 23, 30 + sin(angle) * 23, 22, 27, index % 2 == 0 ? .gold : .orange)
        }
        oval(30, 25, 43, 43, .init(red: 0.48, green: 0.28, blue: 0.16))
        oval(34, 28, 35, 34, .init(red: 0.67, green: 0.40, blue: 0.20))
        oval(39, 38, 5, 7, .ink)
        oval(57, 38, 5, 7, .ink)
        line([CGPoint(x: 46, y: 51), CGPoint(x: 51, y: 54), CGPoint(x: 56, y: 51)], .cream, 2)
      case .peashooter:
        oval(22, 22, 56, 47, .init(red: 0.54, green: 0.70, blue: 0.35))
        oval(29, 25, 40, 21, .init(red: 0.68, green: 0.80, blue: 0.44))
        oval(60, 36, 30, 25, .init(red: 0.43, green: 0.61, blue: 0.28))
        oval(76, 39, 12, 19, .init(red: 0.21, green: 0.35, blue: 0.20))
        oval(39, 34, 7, 10, .ink)
        oval(42, 35, 2, 3, .white)
        oval(29, 49, 10, 5, .pink.opacity(0.4))
        line([CGPoint(x: 33, y: 25), CGPoint(x: 27, y: 13), CGPoint(x: 39, y: 17)], .moss, 4)
      case .bramble:
        var shield = Path()
        shield.move(to: CGPoint(x: 50, y: 12))
        shield.addQuadCurve(to: CGPoint(x: 82, y: 42), control: CGPoint(x: 85, y: 12))
        shield.addQuadCurve(to: CGPoint(x: 51, y: 86), control: CGPoint(x: 83, y: 78))
        shield.addQuadCurve(to: CGPoint(x: 18, y: 42), control: CGPoint(x: 14, y: 76))
        shield.addQuadCurve(to: CGPoint(x: 50, y: 12), control: CGPoint(x: 13, y: 13))
        context.fill(shield, with: .color(.init(red: 0.65, green: 0.43, blue: 0.25)))
        context.stroke(
          shield, with: .color(.init(red: 0.42, green: 0.29, blue: 0.18)), lineWidth: 3)
        line([CGPoint(x: 30, y: 26), CGPoint(x: 34, y: 69)], .cream.opacity(0.22), 3)
        line([CGPoint(x: 64, y: 24), CGPoint(x: 67, y: 68)], .ink.opacity(0.2), 3)
        oval(32, 40, 7, 9, .ink)
        oval(60, 40, 7, 9, .ink)
        line([CGPoint(x: 43, y: 60), CGPoint(x: 56, y: 60)], .ink, 3)
        oval(28, 10, 27, 13, .moss)
        oval(48, 6, 24, 14, .init(red: 0.47, green: 0.59, blue: 0.32))
      case .ember:
        oval(23, 30, 57, 48, .init(red: 0.86, green: 0.32, blue: 0.24))
        oval(28, 33, 44, 24, .init(red: 0.98, green: 0.46, blue: 0.28))
        line([CGPoint(x: 51, y: 35), CGPoint(x: 59, y: 20), CGPoint(x: 69, y: 16)], .ink, 4)
        oval(65, 9, 10, 12, .gold)
        oval(35, 43, 7, 10, .ink)
        oval(60, 43, 7, 10, .ink)
        line([CGPoint(x: 46, y: 61), CGPoint(x: 51, y: 64), CGPoint(x: 55, y: 61)], .cream, 2)
      case .frost:
        for index in 0..<6 {
          let angle = Double(index) * .pi / 3
          oval(
            37 + cos(angle) * 18, 28 + sin(angle) * 18, 26, 30,
            .init(red: 0.66, green: 0.81, blue: 0.88))
        }
        oval(30, 28, 40, 39, .init(red: 0.40, green: 0.62, blue: 0.75))
        oval(35, 35, 6, 9, .ink)
        oval(56, 35, 6, 9, .ink)
        oval(43, 49, 13, 8, .init(red: 0.23, green: 0.43, blue: 0.55))
        line([CGPoint(x: 49, y: 14), CGPoint(x: 49, y: 3)], .white, 3)
        line([CGPoint(x: 43, y: 8), CGPoint(x: 55, y: 8)], .white, 2)
      }
    }
    .accessibilityHidden(true)
  }
}

struct PestArt: View {
  var kind: PestKind
  var slowed = false
  var body: some View {
    Canvas { context, size in
      context.scaleBy(x: size.width / 100, y: size.height / 100)
      func oval(_ rect: CGRect, _ color: Color) {
        context.fill(Path(ellipseIn: rect), with: .color(color))
      }
      func stroke(_ a: CGPoint, _ b: CGPoint, _ color: Color, _ width: Double) {
        var path = Path()
        path.move(to: a)
        path.addLine(to: b)
        context.stroke(
          path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
      }
      let copper = Color(red: 0.70, green: 0.42, blue: 0.26)
      let metal = slowed ? Color.cyan.opacity(0.8) : Color(red: 0.32, green: 0.38, blue: 0.36)
      oval(CGRect(x: 8, y: 78, width: 79, height: 12), .black.opacity(0.17))
      for index in 0..<3 {
        let x = Double(index * 19 + 30)
        stroke(CGPoint(x: x, y: 60), CGPoint(x: x + 9, y: 83), metal, 5)
        stroke(CGPoint(x: x, y: 79), CGPoint(x: x + 12, y: 81), .ink, 4)
      }
      let body = CGRect(
        x: 29, y: kind == .kettle ? 16 : 32, width: 57, height: kind == .kettle ? 57 : 40)
      oval(body, kind == .beetle ? copper : metal)
      oval(CGRect(x: 38, y: 36, width: 37, height: 15), .cream.opacity(0.20))
      stroke(CGPoint(x: 57, y: 37), CGPoint(x: 58, y: 70), .ink.opacity(0.35), 2)
      oval(CGRect(x: 8, y: 42, width: 34, height: 30), metal)
      oval(CGRect(x: 11, y: 47, width: 12, height: 12), .cream)
      oval(CGRect(x: 11, y: 50, width: 5, height: 6), .ink)
      stroke(CGPoint(x: 22, y: 45), CGPoint(x: 14, y: 29), copper, 3)
      oval(CGRect(x: 9, y: 24, width: 9, height: 9), .gold)
      if kind == .kettle {
        let lid = CGRect(x: 40, y: 11, width: 37, height: 9)
        context.fill(Path(roundedRect: lid, cornerRadius: 4), with: .color(copper))
        oval(CGRect(x: 53, y: 5, width: 11, height: 10), .ink)
        stroke(CGPoint(x: 83, y: 38), CGPoint(x: 96, y: 25), copper, 8)
        oval(CGRect(x: 62, y: 49, width: 9, height: 9), .gold)
      }
      if kind == .skitter {
        stroke(CGPoint(x: 53, y: 33), CGPoint(x: 73, y: 17), copper, 3)
        stroke(CGPoint(x: 61, y: 33), CGPoint(x: 81, y: 21), copper, 3)
      }
    }
    .accessibilityHidden(true)
  }
}

struct Cottage: View {
  var body: some View {
    Canvas { context, size in
      context.scaleBy(x: size.width / 300, y: size.height / 200)
      func rect(
        _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: Color, radius: Double = 0
      ) {
        context.fill(
          Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius),
          with: .color(color))
      }
      for index in 0..<14 {
        let x = Double(index) * 24
        context.fill(
          Path(ellipseIn: CGRect(x: x - 12, y: 80 + Double(index % 3) * 9, width: 53, height: 76)),
          with: .color(index % 2 == 0 ? .moss : .init(red: 0.43, green: 0.56, blue: 0.34)))
      }
      rect(66, 66, 173, 109, .cream, radius: 4)
      rect(204, 24, 19, 50, .init(red: 0.64, green: 0.37, blue: 0.26))
      var roof = Path()
      roof.addLines([CGPoint(x: 48, y: 75), CGPoint(x: 149, y: 6), CGPoint(x: 255, y: 75)])
      roof.closeSubpath()
      context.fill(roof, with: .color(.init(red: 0.65, green: 0.36, blue: 0.25)))
      for index in 0..<3 {
        rect(
          94 + Double(index) * 17, 41 - Double(index) * 7, 31, 3, .cream.opacity(0.16), radius: 1)
      }
      rect(131, 107, 43, 70, .ink, radius: 20)
      rect(139, 113, 27, 64, .moss, radius: 13)
      rect(160, 144, 4, 4, .gold, radius: 2)
      for x in [83.0, 192.0] {
        rect(x, 96, 28, 30, .init(red: 0.69, green: 0.79, blue: 0.71), radius: 3)
        rect(x + 12, 96, 3, 30, .cream)
        rect(x, 109, 28, 3, .cream)
        rect(x - 3, 129, 34, 9, .init(red: 0.66, green: 0.38, blue: 0.25), radius: 2)
      }
      for index in 0..<32 {
        let x = Double((index * 43) % 280 + 10)
        let y = Double(158 + (index * 7) % 35)
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: 4, height: 7)),
          with: .color(index % 2 == 0 ? .gold : .cream))
      }
    }
    .accessibilityHidden(true)
  }
}

struct PaperBackground: View {
  var dark = false
  var body: some View {
    ZStack {
      (dark ? Color.ink : Color.cream)
      Canvas { context, size in
        for index in 0..<500 {
          let x = Double((index * 137) % 997) / 997 * size.width
          let y = Double((index * 73) % 499) / 499 * size.height
          context.fill(
            Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
            with: .color((dark ? Color.cream : .ink).opacity(0.09)))
        }
      }
    }.ignoresSafeArea()
  }
}

struct ShovelArt: View {
  var body: some View {
    Canvas { context, size in
      context.scaleBy(x: size.width / 30, y: size.height / 30)
      var handle = Path()
      handle.move(to: CGPoint(x: 15, y: 4))
      handle.addLine(to: CGPoint(x: 15, y: 19))
      context.stroke(
        handle, with: .color(.init(red: 0.70, green: 0.46, blue: 0.27)),
        style: StrokeStyle(lineWidth: 4, lineCap: .round))
      context.stroke(
        Path(roundedRect: CGRect(x: 10, y: 1, width: 10, height: 7), cornerRadius: 2),
        with: .color(.gold), lineWidth: 3)
      var blade = Path()
      blade.move(to: CGPoint(x: 8, y: 16))
      blade.addLine(to: CGPoint(x: 22, y: 16))
      blade.addQuadCurve(to: CGPoint(x: 15, y: 29), control: CGPoint(x: 25, y: 26))
      blade.addQuadCurve(to: CGPoint(x: 8, y: 16), control: CGPoint(x: 5, y: 26))
      context.fill(blade, with: .color(.init(red: 0.71, green: 0.81, blue: 0.76)))
      var seam = Path()
      seam.move(to: CGPoint(x: 15, y: 18))
      seam.addLine(to: CGPoint(x: 15, y: 25))
      context.stroke(seam, with: .color(.ink.opacity(0.3)), lineWidth: 1)
    }.rotationEffect(.degrees(30)).accessibilityHidden(true)
  }
}
