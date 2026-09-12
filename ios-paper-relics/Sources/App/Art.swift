import SwiftUI

enum Ink {
  static let forest = Color(red: 0.055, green: 0.16, blue: 0.145)
  static let deep = Color(red: 0.025, green: 0.095, blue: 0.09)
  static let green = Color(red: 0.19, green: 0.34, blue: 0.27)
  static let paper = Color(red: 0.94, green: 0.90, blue: 0.79)
  static let faded = Color(red: 0.69, green: 0.72, blue: 0.61)
  static let copper = Color(red: 0.82, green: 0.57, blue: 0.33)
  static let red = Color(red: 0.86, green: 0.41, blue: 0.33)
  static func serif(_ size: CGFloat) -> Font { .custom("Georgia", size: size) }
}

struct PaperBackground: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Ink.forest, Ink.deep], startPoint: .topLeading, endPoint: .bottomTrailing)
      Canvas { context, size in
        for index in 0..<1_000 {
          let x = CGFloat((index * 71 + 13) % 997) / 997 * size.width
          let y = CGFloat((index * 113 + 5) % 991) / 991 * size.height
          context.fill(
            Path(CGRect(x: x, y: y, width: 0.7, height: 1.1)),
            with: .color(Ink.paper.opacity(0.065)))
        }
        let border = CGRect(x: 12, y: 8, width: size.width - 24, height: size.height - 16)
        context.stroke(
          Path(roundedRect: border, cornerRadius: 22), with: .color(Ink.copper.opacity(0.15)),
          lineWidth: 0.8)
      }
      .accessibilityHidden(true)
    }
    .ignoresSafeArea()
  }
}

struct EnemyArt: View {
  var kind: EnemyKind
  var body: some View {
    Canvas { raw, size in
      var context = raw
      let scale = min(size.width / 300, size.height / 260)
      context.translateBy(x: (size.width - 300 * scale) / 2, y: (size.height - 260 * scale) / 2)
      context.scaleBy(x: scale, y: scale)
      func stroke(
        _ points: [CGPoint], color: Color = Ink.copper, width: CGFloat = 1.2, close: Bool = false
      ) {
        guard let first = points.first else { return }
        var path = Path()
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        if close { path.closeSubpath() }
        context.stroke(
          path, with: .color(color),
          style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
      }
      func shape(_ points: [CGPoint], fill: Color = Ink.paper) {
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        context.fill(path, with: .color(fill))
        context.stroke(path, with: .color(Ink.copper), lineWidth: 1)
      }
      func ellipse(_ rect: CGRect, fill: Color) {
        context.fill(Path(ellipseIn: rect), with: .color(fill))
      }
      let halo = CGRect(x: 59, y: 30, width: 182, height: 182)
      ellipse(halo, fill: Ink.copper.opacity(0.09))
      context.stroke(
        Path(ellipseIn: halo.insetBy(dx: -8, dy: -8)), with: .color(Ink.copper.opacity(0.28)),
        style: StrokeStyle(lineWidth: 0.8, dash: [2, 5]))
      for index in 0..<24 {
        let angle = Double(index) / 24 * .pi * 2
        let a = CGPoint(x: 150 + cos(angle) * 110, y: 121 + sin(angle) * 110)
        let b = CGPoint(x: 150 + cos(angle) * 116, y: 121 + sin(angle) * 116)
        stroke([a, b], color: Ink.copper.opacity(0.45))
      }
      ellipse(CGRect(x: 65, y: 233, width: 170, height: 12), fill: .black.opacity(0.22))
      switch kind {
      case .moth:
        for sign: CGFloat in [-1, 1] {
          func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: 150 + x * sign, y: y) }
          shape([p(2, 113), p(57, 55), p(119, 68), p(98, 139), p(35, 150)], fill: Ink.paper)
          shape([p(4, 140), p(50, 151), p(85, 199), p(25, 219), p(10, 168)], fill: Ink.copper)
          for index in 0..<6 {
            stroke(
              [p(8, 124), p(CGFloat(45 + index * 12), CGFloat(66 + index * 10))],
              color: Ink.forest.opacity(0.5))
          }
          ellipse(CGRect(x: 150 + sign * 65 - 15, y: 95, width: 30, height: 30), fill: Ink.forest)
          ellipse(CGRect(x: 150 + sign * 65 - 6, y: 103, width: 12, height: 12), fill: Ink.copper)
          stroke([p(0, 113), p(17, 76), p(28, 68)], width: 2)
        }
        shape([
          CGPoint(x: 150, y: 100), CGPoint(x: 161, y: 137), CGPoint(x: 150, y: 196),
          CGPoint(x: 139, y: 137),
        ])
      case .fox:
        shape(
          [
            CGPoint(x: 84, y: 195), CGPoint(x: 76, y: 83), CGPoint(x: 48, y: 33),
            CGPoint(x: 122, y: 73), CGPoint(x: 173, y: 72), CGPoint(x: 249, y: 34),
            CGPoint(x: 221, y: 127), CGPoint(x: 150, y: 222),
          ], fill: Ink.copper)
        shape(
          [CGPoint(x: 79, y: 103), CGPoint(x: 139, y: 143), CGPoint(x: 150, y: 214)],
          fill: Ink.paper)
        shape(
          [CGPoint(x: 222, y: 102), CGPoint(x: 161, y: 143), CGPoint(x: 150, y: 214)],
          fill: Ink.paper)
        stroke([CGPoint(x: 88, y: 124), CGPoint(x: 125, y: 143)], color: Ink.deep, width: 5)
        stroke([CGPoint(x: 213, y: 124), CGPoint(x: 175, y: 143)], color: Ink.deep, width: 5)
        shape(
          [CGPoint(x: 141, y: 190), CGPoint(x: 159, y: 190), CGPoint(x: 150, y: 203)],
          fill: Ink.deep)
      case .knight:
        shape([
          CGPoint(x: 90, y: 98), CGPoint(x: 104, y: 61), CGPoint(x: 172, y: 43),
          CGPoint(x: 202, y: 91), CGPoint(x: 190, y: 169), CGPoint(x: 150, y: 195),
          CGPoint(x: 104, y: 164),
        ])
        shape(
          [
            CGPoint(x: 78, y: 237), CGPoint(x: 97, y: 171), CGPoint(x: 147, y: 195),
            CGPoint(x: 204, y: 164), CGPoint(x: 230, y: 237),
          ], fill: Ink.green)
        stroke([CGPoint(x: 98, y: 110), CGPoint(x: 187, y: 95)], color: Ink.deep, width: 12)
        stroke([CGPoint(x: 147, y: 115), CGPoint(x: 155, y: 175)], color: Ink.copper, width: 3)
        stroke([CGPoint(x: 63, y: 64), CGPoint(x: 55, y: 235)], color: Ink.paper, width: 5)
        stroke([CGPoint(x: 37, y: 154), CGPoint(x: 79, y: 154)], width: 5)
      case .twins:
        for sign: CGFloat in [-1, 1] {
          let x = 150 + sign * 52
          ellipse(CGRect(x: x - 27, y: 64, width: 54, height: 63), fill: Ink.paper)
          shape(
            [CGPoint(x: x, y: 122), CGPoint(x: x + 36, y: 202), CGPoint(x: x - 36, y: 202)],
            fill: sign == 1 ? Ink.copper : Ink.green)
          stroke([CGPoint(x: x - 12, y: 89), CGPoint(x: x + 12, y: 89)], color: Ink.deep, width: 5)
          stroke(
            [CGPoint(x: x, y: 151), CGPoint(x: 150 - sign * 80, y: 37)], color: Ink.paper, width: 4)
          stroke([CGPoint(x: x, y: 201), CGPoint(x: x + sign * 12, y: 232)], width: 3)
        }
      case .stag:
        shape([
          CGPoint(x: 103, y: 105), CGPoint(x: 197, y: 105), CGPoint(x: 176, y: 185),
          CGPoint(x: 150, y: 223), CGPoint(x: 124, y: 185),
        ])
        for sign: CGFloat in [-1, 1] {
          func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: 150 + sign * x, y: y) }
          stroke([p(32, 113), p(68, 74), p(75, 22)], width: 5)
          stroke([p(65, 78), p(106, 51), p(110, 24)], width: 3)
          stroke([p(74, 50), p(45, 29), p(47, 9)], width: 3)
          shape([p(40, 115), p(85, 106), p(54, 140)], fill: Ink.copper)
          stroke([p(17, 151), p(30, 144)], color: Ink.deep, width: 4)
        }
      case .queen:
        for x in stride(from: 68, through: 232, by: 41) {
          stroke(
            [CGPoint(x: x, y: 0), CGPoint(x: 150 + (x - 150) / 2, y: 170)],
            color: Ink.paper.opacity(0.4), width: 0.8)
        }
        shape(
          [CGPoint(x: 150, y: 111), CGPoint(x: 231, y: 228), CGPoint(x: 69, y: 228)],
          fill: Ink.copper)
        for index in 0..<8 {
          stroke(
            [CGPoint(x: 150, y: 119), CGPoint(x: 78 + index * 20, y: 225)],
            color: Ink.deep.opacity(0.35))
        }
        ellipse(CGRect(x: 123, y: 60, width: 54, height: 69), fill: Ink.paper)
        shape(
          [
            CGPoint(x: 120, y: 68), CGPoint(x: 112, y: 29), CGPoint(x: 136, y: 47),
            CGPoint(x: 151, y: 15), CGPoint(x: 166, y: 47), CGPoint(x: 189, y: 29),
            CGPoint(x: 180, y: 68),
          ], fill: Ink.copper)
        stroke([CGPoint(x: 133, y: 87), CGPoint(x: 142, y: 90)], color: Ink.deep, width: 3)
        stroke([CGPoint(x: 158, y: 90), CGPoint(x: 167, y: 87)], color: Ink.deep, width: 3)
        stroke(
          [CGPoint(x: 136, y: 141), CGPoint(x: 80, y: 155), CGPoint(x: 61, y: 129)],
          color: Ink.paper, width: 4)
        stroke(
          [CGPoint(x: 164, y: 141), CGPoint(x: 220, y: 155), CGPoint(x: 240, y: 129)],
          color: Ink.paper, width: 4)
      }
      for index in 0..<40 {
        let x = CGFloat((index * 79) % 200 + 50)
        let y = CGFloat((index * 43) % 180 + 38)
        stroke(
          [CGPoint(x: x, y: y), CGPoint(x: x + 2, y: y + 1)], color: Ink.deep.opacity(0.18),
          width: 0.7)
      }
    }
    .accessibilityLabel("Original ink illustration of \(kind.title)")
  }
}

struct Flourish: View {
  var body: some View {
    HStack(spacing: 10) {
      Rectangle().frame(height: 0.5)
      Text("✦").font(.system(size: 12))
      Rectangle().frame(height: 0.5)
    }.foregroundStyle(Ink.copper.opacity(0.6))
  }
}

struct CardFace: View {
  var kind: CardKind
  var affordable = true
  var text: String?
  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Text("\(kind.cost)").font(.system(size: 16, weight: .bold, design: .serif))
          .frame(width: 26, height: 26).background(Ink.forest, in: Circle()).foregroundStyle(
            Ink.paper)
        Spacer()
        Text(affordable ? kind.category : "NO ENERGY").font(.system(size: 8, weight: .bold))
          .tracking(0.5)
      }
      Image(systemName: kind.symbol).font(.system(size: 29, weight: .ultraLight))
        .frame(height: 38)
        .frame(maxWidth: .infinity)
        .background(
          Circle().stroke(Ink.copper.opacity(0.6), lineWidth: 0.6).frame(width: 48, height: 48))
      Text(kind.title).font(Ink.serif(15)).multilineTextAlignment(.center).frame(height: 36)
        .minimumScaleFactor(0.8)
      Rectangle().fill(Ink.copper.opacity(0.5)).frame(height: 0.5)
      Text(text ?? kind.text).font(.system(size: 12, weight: .medium)).lineSpacing(2)
        .multilineTextAlignment(.center).frame(maxHeight: .infinity, alignment: .top)
    }
    .padding(10)
    .frame(width: 126, height: 202)
    .foregroundStyle(Ink.forest)
    .background(
      LinearGradient(
        colors: [Ink.paper, Color(red: 0.85, green: 0.79, blue: 0.64)], startPoint: .topLeading,
        endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 11)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8).stroke(Ink.copper.opacity(0.5), lineWidth: 0.8).padding(4)
    )
    .saturation(affordable ? 1 : 0.3)
    .opacity(affordable ? 1 : 0.82)
    .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 4)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(kind.title), \(kind.cost) energy. \(text ?? kind.text)\(affordable ? "" : " Not enough energy.")"
    )
  }
}
