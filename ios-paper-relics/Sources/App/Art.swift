import SwiftUI

enum Ink {
  static let forest = Color(red: 0.055, green: 0.16, blue: 0.145)
  static let deep = Color(red: 0.025, green: 0.095, blue: 0.09)
  static let green = Color(red: 0.19, green: 0.34, blue: 0.27)
  static let moss = Color(red: 0.11, green: 0.25, blue: 0.21)
  static let paper = Color(red: 0.94, green: 0.90, blue: 0.79)
  static let cream = Color(red: 0.97, green: 0.94, blue: 0.86)
  static let parchment = Color(red: 0.86, green: 0.80, blue: 0.65)
  static let faded = Color(red: 0.69, green: 0.72, blue: 0.61)
  static let copper = Color(red: 0.82, green: 0.57, blue: 0.33)
  static let gilt = Color(red: 0.95, green: 0.78, blue: 0.52)
  static let bronze = Color(red: 0.55, green: 0.34, blue: 0.17)
  static let wine = Color(red: 0.43, green: 0.13, blue: 0.14)
  static let red = Color(red: 0.86, green: 0.41, blue: 0.33)

  static func display(_ size: CGFloat) -> Font { .custom("Didot", size: size) }
  static func serif(_ size: CGFloat) -> Font { .custom("Baskerville", size: size) }
  static func italic(_ size: CGFloat) -> Font { .custom("Baskerville-Italic", size: size) }
  static func bold(_ size: CGFloat) -> Font { .custom("Baskerville-SemiBold", size: size) }

  static let metal = LinearGradient(
    colors: [gilt, copper, bronze, copper], startPoint: .topLeading, endPoint: .bottomTrailing)
  static let sheet = LinearGradient(
    colors: [cream, paper, parchment], startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension Path {
  static func polyline(_ points: [CGPoint], closed: Bool = false) -> Path {
    var path = Path()
    guard let first = points.first else { return path }
    path.move(to: first)
    for point in points.dropFirst() { path.addLine(to: point) }
    if closed { path.closeSubpath() }
    return path
  }
}

extension GraphicsContext {
  func line(_ points: [CGPoint], _ color: Color, width: CGFloat = 1.2, dash: [CGFloat] = []) {
    stroke(
      Path.polyline(points), with: .color(color),
      style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))
  }
  func cut(_ points: [CGPoint], _ fill: Color, edge: Color = Ink.copper, width: CGFloat = 1) {
    let path = Path.polyline(points, closed: true)
    self.fill(path, with: .color(fill))
    stroke(path, with: .color(edge), lineWidth: width)
  }
  func disc(_ rect: CGRect, _ fill: Color) { self.fill(Path(ellipseIn: rect), with: .color(fill)) }
  func ring(_ rect: CGRect, _ color: Color, width: CGFloat = 1, dash: [CGFloat] = []) {
    stroke(
      Path(ellipseIn: rect), with: .color(color), style: StrokeStyle(lineWidth: width, dash: dash))
  }
}

struct PaperBackground: View {
  var ornaments = true
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Ink.forest, Ink.deep], startPoint: .top, endPoint: .bottom)
      RadialGradient(
        colors: [Ink.green.opacity(0.42), .clear], center: .init(x: 0.5, y: 0.22), startRadius: 10,
        endRadius: 420)
      Canvas { context, size in
        for index in 0..<1_300 {
          let x = CGFloat((index * 71 + 13) % 997) / 997 * size.width
          let y = CGFloat((index * 113 + 5) % 991) / 991 * size.height
          context.fill(
            Path(CGRect(x: x, y: y, width: 0.7, height: 1.4)),
            with: .color(Ink.paper.opacity(0.07)))
        }
        let inset = CGRect(x: 14, y: 10, width: size.width - 28, height: size.height - 20)
        context.stroke(
          Path(roundedRect: inset, cornerRadius: 26), with: .color(Ink.copper.opacity(0.22)),
          lineWidth: 0.8)
        context.stroke(
          Path(roundedRect: inset.insetBy(dx: 5, dy: 5), cornerRadius: 22),
          with: .color(Ink.copper.opacity(0.1)), lineWidth: 0.6)
        for (sx, sy) in [(1.0, 1.0), (-1.0, 1.0), (1.0, -1.0), (-1.0, -1.0)] where ornaments {
          var corner = context
          corner.translateBy(x: sx > 0 ? 24 : size.width - 24, y: sy > 0 ? 20 : size.height - 20)
          corner.scaleBy(x: sx, y: sy)
          Filigree.draw(in: &corner, color: Ink.copper.opacity(0.5))
        }
      }
      .accessibilityHidden(true)
      LinearGradient(
        colors: [.clear, .clear, Ink.deep.opacity(0.75)], startPoint: .top, endPoint: .bottom)
    }
    .ignoresSafeArea()
  }
}

enum Filigree {
  static func draw(in context: inout GraphicsContext, color: Color, scale: CGFloat = 1) {
    context.scaleBy(x: scale, y: scale)
    var vine = Path()
    vine.move(to: .zero)
    vine.addCurve(
      to: CGPoint(x: 46, y: 6), control1: CGPoint(x: 14, y: -4), control2: CGPoint(x: 30, y: 12))
    vine.move(to: .zero)
    vine.addCurve(
      to: CGPoint(x: 6, y: 46), control1: CGPoint(x: -4, y: 14), control2: CGPoint(x: 12, y: 30))
    vine.move(to: CGPoint(x: 10, y: 10))
    vine.addCurve(
      to: CGPoint(x: 30, y: 14), control1: CGPoint(x: 18, y: 6), control2: CGPoint(x: 26, y: 8))
    vine.move(to: CGPoint(x: 10, y: 10))
    vine.addCurve(
      to: CGPoint(x: 14, y: 30), control1: CGPoint(x: 6, y: 18), control2: CGPoint(x: 8, y: 26))
    context.stroke(
      vine, with: .color(color), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
    let leaf = Path.polyline(
      [
        CGPoint(x: 10, y: 10), CGPoint(x: 18, y: 12), CGPoint(x: 20, y: 20), CGPoint(x: 12, y: 18),
      ], closed: true)
    context.fill(leaf, with: .color(color))
    context.disc(CGRect(x: 44, y: 4, width: 4, height: 4), color)
    context.disc(CGRect(x: 4, y: 44, width: 4, height: 4), color)
    context.disc(CGRect(x: 29, y: 13, width: 3, height: 3), color)
    context.disc(CGRect(x: 13, y: 29, width: 3, height: 3), color)
  }
}

struct Flourish: View {
  var body: some View {
    HStack(spacing: 10) {
      LinearGradient(colors: [.clear, Ink.copper], startPoint: .leading, endPoint: .trailing)
        .frame(height: 0.7)
      Diamond().fill(Ink.copper).frame(width: 6, height: 6)
      Diamond().stroke(Ink.copper, lineWidth: 0.8).frame(width: 10, height: 10)
      Diamond().fill(Ink.copper).frame(width: 6, height: 6)
      LinearGradient(colors: [Ink.copper, .clear], startPoint: .leading, endPoint: .trailing)
        .frame(height: 0.7)
    }.frame(height: 10).accessibilityHidden(true)
  }
}

struct Diamond: Shape {
  func path(in rect: CGRect) -> Path {
    Path.polyline(
      [
        CGPoint(x: rect.midX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.midY),
        CGPoint(x: rect.midX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.midY),
      ], closed: true)
  }
}

struct Seal: View {
  var number: Int
  var size: CGFloat = 30
  var body: some View {
    ZStack {
      Circle().fill(
        RadialGradient(
          colors: [Ink.gilt, Ink.copper, Ink.bronze], center: .init(x: 0.35, y: 0.3),
          startRadius: 1, endRadius: size * 0.7))
      Circle().stroke(Ink.deep.opacity(0.35), lineWidth: 0.8).padding(size * 0.14)
      Circle().stroke(Ink.gilt.opacity(0.5), lineWidth: 0.6).padding(size * 0.06)
      Text("\(number)").font(Ink.display(size * 0.56)).foregroundStyle(Ink.deep)
        .offset(y: size * 0.02)
    }
    .frame(width: size, height: size)
    .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1.5)
  }
}

struct OrnateBar: View {
  var value: Int
  var max: Int
  var color: Color
  var height: CGFloat = 7
  var body: some View {
    GeometryReader { geometry in
      let fraction = CGFloat(Swift.max(0, value)) / CGFloat(Swift.max(1, max))
      ZStack(alignment: .leading) {
        Capsule().fill(Ink.deep.opacity(0.7))
        Capsule().stroke(Ink.copper.opacity(0.4), lineWidth: 0.7)
        Capsule()
          .fill(
            LinearGradient(
              colors: [color.opacity(0.75), color, color.opacity(0.85)], startPoint: .top,
              endPoint: .bottom)
          )
          .frame(width: Swift.max(fraction > 0 ? height : 0, geometry.size.width * fraction))
          .overlay(alignment: .top) {
            Capsule().fill(.white.opacity(0.35)).frame(height: 1).padding(.horizontal, 3)
              .padding(.top, 1.4)
          }
        HStack(spacing: 0) {
          ForEach(1..<4) { index in
            Spacer()
            Rectangle().fill(Ink.deep.opacity(0.5)).frame(width: 1)
              .accessibilityHidden(index == 0)
          }
          Spacer()
        }.padding(.vertical, 1.5)
      }
    }
    .frame(height: height)
    .overlay(alignment: .leading) { Diamond().fill(Ink.copper).frame(width: 7, height: 11) }
    .overlay(alignment: .trailing) { Diamond().fill(Ink.copper).frame(width: 7, height: 11) }
  }
}

struct IntentTag: View {
  var intent: Intent
  private var tone: Color {
    intent.damage == 0 ? Ink.paper : intent.weak > 0 ? Ink.wine : Ink.copper
  }
  private var textTone: Color { intent.weak > 0 ? Ink.paper : Ink.deep }
  var body: some View {
    VStack(spacing: 0) {
      Rectangle().fill(Ink.paper.opacity(0.5)).frame(width: 1, height: 14)
      HStack(spacing: 7) {
        Circle().fill(Ink.deep).frame(width: 6, height: 6)
          .overlay(Circle().stroke(Ink.deep.opacity(0.4), lineWidth: 1.5))
        Image(
          systemName: intent.damage == 0 ? "shield.fill" : intent.weak > 0 ? "eye" : "bolt.fill"
        )
        .font(.system(size: 11, weight: .semibold))
        Text(intent.label.uppercased()).font(Ink.bold(12)).tracking(1.4)
      }
      .foregroundStyle(textTone)
      .padding(.leading, 10).padding(.trailing, 14).padding(.vertical, 8)
      .background(TagShape().fill(tone))
      .overlay(TagShape().stroke(Ink.deep.opacity(0.25), lineWidth: 0.8))
      .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 3)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Enemy intent: \(intent.label)")
  }
}

struct TagShape: Shape {
  func path(in rect: CGRect) -> Path {
    let notch: CGFloat = 9
    return Path.polyline(
      [
        CGPoint(x: rect.minX + notch, y: rect.minY), CGPoint(x: rect.maxX - 4, y: rect.minY),
        CGPoint(x: rect.maxX, y: rect.minY + 4), CGPoint(x: rect.maxX, y: rect.maxY - 4),
        CGPoint(x: rect.maxX - 4, y: rect.maxY), CGPoint(x: rect.minX + notch, y: rect.maxY),
        CGPoint(x: rect.minX, y: rect.midY),
      ], closed: true)
  }
}

struct Proscenium: View {
  var kind: EnemyKind
  var body: some View {
    GeometryReader { geometry in
      let w = geometry.size.width
      let h = geometry.size.height
      ZStack {
        RoundedRectangle(cornerRadius: 18).fill(
          LinearGradient(
            colors: [Ink.moss, Ink.deep], startPoint: .top, endPoint: .bottom))
        RadialGradient(
          colors: [Ink.gilt.opacity(0.28), .clear], center: .init(x: 0.5, y: 0.45),
          startRadius: 4, endRadius: w * 0.5
        ).clipShape(RoundedRectangle(cornerRadius: 18))
        Canvas { context, size in
          let floor = size.height * 0.84
          for index in 0..<3 {
            let base = floor - CGFloat(index) * 12 - 6
            var hill = Path()
            hill.move(to: CGPoint(x: 0, y: base))
            let step = size.width / 6
            for column in 0..<6 {
              let x = CGFloat(column) * step
              let peak = base - CGFloat((column * 37 + index * 19) % 23) - 12
              hill.addQuadCurve(
                to: CGPoint(x: x + step, y: base - CGFloat((column * 53 + index * 7) % 11)),
                control: CGPoint(x: x + step / 2, y: peak))
            }
            hill.addLine(to: CGPoint(x: size.width, y: size.height))
            hill.addLine(to: CGPoint(x: 0, y: size.height))
            hill.closeSubpath()
            context.fill(hill, with: .color(Ink.deep.opacity(0.28 + Double(index) * 0.18)))
          }
          context.fill(
            Path(CGRect(x: 0, y: floor, width: size.width, height: size.height - floor)),
            with: .linearGradient(
              Gradient(colors: [Ink.bronze.opacity(0.55), Ink.deep]),
              startPoint: CGPoint(x: 0, y: floor), endPoint: CGPoint(x: 0, y: size.height)))
          for index in 0..<9 {
            let x = size.width / 8 * CGFloat(index)
            context.line(
              [
                CGPoint(x: x, y: floor),
                CGPoint(x: size.width / 2 + (x - size.width / 2) * 1.3, y: size.height),
              ],
              Ink.deep.opacity(0.35), width: 0.8)
          }
          for index in 0..<7 {
            let x = size.width / 7 * (CGFloat(index) + 0.5)
            context.disc(
              CGRect(x: x - 9, y: floor - 6, width: 18, height: 12), Ink.gilt.opacity(0.18))
            context.disc(CGRect(x: x - 2, y: floor - 2, width: 4, height: 4), Ink.gilt.opacity(0.9))
          }
          for sign: CGFloat in [-1, 1] {
            let edge = sign > 0 ? 0 : size.width
            var curtain = Path()
            curtain.move(to: CGPoint(x: edge, y: 0))
            curtain.addLine(to: CGPoint(x: edge + sign * 46, y: 0))
            curtain.addCurve(
              to: CGPoint(x: edge + sign * 18, y: size.height * 0.5),
              control1: CGPoint(x: edge + sign * 46, y: size.height * 0.2),
              control2: CGPoint(x: edge + sign * 10, y: size.height * 0.3))
            curtain.addCurve(
              to: CGPoint(x: edge + sign * 42, y: floor + 10),
              control1: CGPoint(x: edge + sign * 26, y: size.height * 0.7),
              control2: CGPoint(x: edge + sign * 48, y: size.height * 0.85))
            curtain.addLine(to: CGPoint(x: edge, y: floor + 10))
            curtain.closeSubpath()
            context.fill(
              curtain,
              with: .linearGradient(
                Gradient(colors: [Ink.wine, Ink.wine.opacity(0.75), Ink.deep]),
                startPoint: CGPoint(x: edge, y: 0), endPoint: CGPoint(x: edge + sign * 50, y: 0)))
            for fold in 1..<4 {
              let x = edge + sign * CGFloat(fold) * 11
              var line = Path()
              line.move(to: CGPoint(x: x, y: 0))
              line.addQuadCurve(
                to: CGPoint(x: x * 0.9 + edge * 0.1 + sign * 4, y: floor),
                control: CGPoint(x: edge + sign * (CGFloat(fold) * 6), y: size.height * 0.5))
              context.stroke(line, with: .color(.black.opacity(0.28)), lineWidth: 1.2)
            }
            let tie = CGPoint(x: edge + sign * 24, y: size.height * 0.5)
            context.disc(CGRect(x: tie.x - 5, y: tie.y - 4, width: 10, height: 8), Ink.copper)
          }
          var valance = Path()
          valance.move(to: CGPoint(x: 0, y: 0))
          valance.addLine(to: CGPoint(x: size.width, y: 0))
          valance.addLine(to: CGPoint(x: size.width, y: 22))
          let scallops = 9
          let width = size.width / CGFloat(scallops)
          for index in stride(from: scallops - 1, through: 0, by: -1) {
            let x = CGFloat(index) * width
            valance.addQuadCurve(
              to: CGPoint(x: x, y: 22), control: CGPoint(x: x + width / 2, y: 38))
          }
          valance.closeSubpath()
          context.fill(
            valance,
            with: .linearGradient(
              Gradient(colors: [Ink.wine, Ink.wine.opacity(0.85)]), startPoint: .zero,
              endPoint: CGPoint(x: 0, y: 36)))
          context.stroke(valance, with: .color(Ink.copper.opacity(0.9)), lineWidth: 1)
          for index in 0..<scallops {
            let x = CGFloat(index) * width + width / 2
            context.disc(CGRect(x: x - 2.5, y: 28, width: 5, height: 5), Ink.gilt)
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        EnemyArt(kind: kind)
          .frame(width: w * 0.62, height: h * 0.62)
          .offset(y: h * 0.06)
      }
      .overlay(
        RoundedRectangle(cornerRadius: 18).strokeBorder(
          LinearGradient(
            colors: [Ink.gilt, Ink.bronze, Ink.copper], startPoint: .topLeading,
            endPoint: .bottomTrailing), lineWidth: 2)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 15).stroke(Ink.deep.opacity(0.7), lineWidth: 1).padding(3)
      )
      .shadow(color: .black.opacity(0.45), radius: 14, x: 0, y: 10)
    }
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
        context.stroke(
          Path.polyline(points, closed: close), with: .color(color),
          style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
      }
      func shape(_ points: [CGPoint], fill: Color = Ink.paper) {
        let path = Path.polyline(points, closed: true)
        let box = path.boundingRect
        context.fill(
          path,
          with: .linearGradient(
            Gradient(colors: [fill, fill.opacity(0.78)]),
            startPoint: CGPoint(x: box.minX, y: box.minY),
            endPoint: CGPoint(x: box.maxX, y: box.maxY)))
        context.stroke(path, with: .color(Ink.bronze.opacity(0.9)), lineWidth: 1)
      }
      func ellipse(_ rect: CGRect, fill: Color) { context.disc(rect, fill) }
      let halo = CGRect(x: 59, y: 30, width: 182, height: 182)
      context.fill(
        Path(ellipseIn: halo),
        with: .radialGradient(
          Gradient(colors: [Ink.gilt.opacity(0.22), Ink.copper.opacity(0.02)]),
          center: CGPoint(x: 150, y: 121), startRadius: 10, endRadius: 100))
      context.ring(
        halo.insetBy(dx: -8, dy: -8), Ink.copper.opacity(0.35), width: 0.8, dash: [2, 5])
      for index in 0..<24 {
        let angle = Double(index) / 24 * .pi * 2
        let a = CGPoint(x: 150 + cos(angle) * 110, y: 121 + sin(angle) * 110)
        let b = CGPoint(x: 150 + cos(angle) * 116, y: 121 + sin(angle) * 116)
        stroke([a, b], color: Ink.copper.opacity(0.5))
      }
      ellipse(CGRect(x: 65, y: 233, width: 170, height: 12), fill: .black.opacity(0.32))
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
          ellipse(CGRect(x: 150 + sign * 68 - 2, y: 101, width: 4, height: 4), fill: Ink.cream)
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
        shape(
          [CGPoint(x: 60, y: 44), CGPoint(x: 74, y: 84), CGPoint(x: 96, y: 66)], fill: Ink.deep)
        shape(
          [CGPoint(x: 238, y: 44), CGPoint(x: 226, y: 84), CGPoint(x: 204, y: 66)], fill: Ink.deep)
        stroke([CGPoint(x: 88, y: 124), CGPoint(x: 125, y: 143)], color: Ink.deep, width: 5)
        stroke([CGPoint(x: 213, y: 124), CGPoint(x: 175, y: 143)], color: Ink.deep, width: 5)
        ellipse(CGRect(x: 104, y: 129, width: 5, height: 5), fill: Ink.gilt)
        ellipse(CGRect(x: 191, y: 129, width: 5, height: 5), fill: Ink.gilt)
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
        for index in 0..<4 {
          stroke(
            [
              CGPoint(x: 100 + index * 32, y: 178 + index % 2 * 8),
              CGPoint(x: 92 + index * 34, y: 237),
            ],
            color: Ink.deep.opacity(0.35))
        }
        stroke([CGPoint(x: 98, y: 110), CGPoint(x: 187, y: 95)], color: Ink.deep, width: 12)
        ellipse(CGRect(x: 118, y: 96, width: 6, height: 6), fill: Ink.gilt.opacity(0.8))
        ellipse(CGRect(x: 168, y: 88, width: 6, height: 6), fill: Ink.gilt.opacity(0.8))
        stroke([CGPoint(x: 147, y: 115), CGPoint(x: 155, y: 175)], color: Ink.copper, width: 3)
        stroke([CGPoint(x: 63, y: 64), CGPoint(x: 55, y: 235)], color: Ink.paper, width: 5)
        stroke([CGPoint(x: 37, y: 154), CGPoint(x: 79, y: 154)], width: 5)
        shape(
          [CGPoint(x: 63, y: 40), CGPoint(x: 72, y: 64), CGPoint(x: 54, y: 64)], fill: Ink.copper)
      case .twins:
        for sign: CGFloat in [-1, 1] {
          let x = 150 + sign * 52
          ellipse(CGRect(x: x - 27, y: 64, width: 54, height: 63), fill: Ink.paper)
          context.ring(CGRect(x: x - 27, y: 64, width: 54, height: 63), Ink.bronze, width: 1)
          shape(
            [CGPoint(x: x, y: 122), CGPoint(x: x + 36, y: 202), CGPoint(x: x - 36, y: 202)],
            fill: sign == 1 ? Ink.copper : Ink.green)
          stroke([CGPoint(x: x - 12, y: 89), CGPoint(x: x + 12, y: 89)], color: Ink.deep, width: 5)
          stroke([CGPoint(x: x - 6, y: 106), CGPoint(x: x + 6, y: 104)], color: Ink.deep, width: 2)
          stroke(
            [CGPoint(x: x, y: 151), CGPoint(x: 150 - sign * 80, y: 37)], color: Ink.paper, width: 4)
          stroke([CGPoint(x: x, y: 201), CGPoint(x: x + sign * 12, y: 232)], width: 3)
        }
        ellipse(CGRect(x: 144, y: 100, width: 12, height: 12), fill: Ink.copper)
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
          stroke([p(96, 60), p(118, 44)], width: 2)
          shape([p(40, 115), p(85, 106), p(54, 140)], fill: Ink.copper)
          stroke([p(17, 151), p(30, 144)], color: Ink.deep, width: 4)
          ellipse(CGRect(x: 150 + sign * 23 - 2, y: 145, width: 4, height: 4), fill: Ink.gilt)
        }
        shape(
          [CGPoint(x: 141, y: 205), CGPoint(x: 159, y: 205), CGPoint(x: 150, y: 218)],
          fill: Ink.deep)
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
        context.ring(CGRect(x: 123, y: 60, width: 54, height: 69), Ink.bronze, width: 1)
        shape(
          [
            CGPoint(x: 120, y: 68), CGPoint(x: 112, y: 29), CGPoint(x: 136, y: 47),
            CGPoint(x: 151, y: 15), CGPoint(x: 166, y: 47), CGPoint(x: 189, y: 29),
            CGPoint(x: 180, y: 68),
          ], fill: Ink.copper)
        ellipse(CGRect(x: 147, y: 22, width: 7, height: 7), fill: Ink.gilt)
        stroke([CGPoint(x: 133, y: 87), CGPoint(x: 142, y: 90)], color: Ink.deep, width: 3)
        stroke([CGPoint(x: 158, y: 90), CGPoint(x: 167, y: 87)], color: Ink.deep, width: 3)
        stroke([CGPoint(x: 145, y: 112), CGPoint(x: 155, y: 112)], color: Ink.wine, width: 2)
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

struct CardIllustration: View {
  var kind: CardKind
  var body: some View {
    Canvas { raw, size in
      var c = raw
      let scale = min(size.width / 100, size.height / 70)
      c.translateBy(x: (size.width - 100 * scale) / 2, y: (size.height - 70 * scale) / 2)
      c.scaleBy(x: scale, y: scale)
      let paper = Ink.cream
      let copper = Ink.copper
      let gilt = Ink.gilt
      let ink = Ink.deep
      func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
      switch kind {
      case .strike:
        c.cut([p(22, 14), p(78, 10), p(80, 58), p(20, 60)], paper, edge: Ink.bronze)
        c.line([p(30, 52), p(72, 16)], ink, width: 2.4)
        c.line([p(26, 50), p(35, 44)], copper, width: 1)
        c.line([p(60, 18), p(70, 12)], copper, width: 1)
        for index in 0..<5 {
          c.line(
            [
              p(34 + CGFloat(index) * 9, 48 - CGFloat(index) * 8),
              p(38 + CGFloat(index) * 9, 50 - CGFloat(index) * 8),
            ], Ink.wine, width: 1.2)
        }
      case .guardCard:
        c.cut(
          [p(50, 8), p(82, 20), p(78, 46), p(50, 64), p(22, 46), p(18, 20)], paper, edge: Ink.bronze
        )
        c.cut([p(50, 8), p(50, 64), p(22, 46), p(18, 20)], Ink.parchment, edge: Ink.bronze)
        c.line([p(50, 8), p(50, 64)], copper, width: 1.4)
        c.line([p(26, 26), p(50, 36), p(74, 26)], copper, width: 1)
      case .needle:
        c.line([p(18, 58), p(80, 12)], gilt, width: 3)
        c.line([p(18, 58), p(80, 12)], paper, width: 1)
        c.disc(CGRect(x: 72, y: 6, width: 10, height: 10), paper)
        c.ring(CGRect(x: 72, y: 6, width: 10, height: 10), copper, width: 1.2)
        var thread = Path()
        thread.move(to: p(78, 15))
        thread.addCurve(to: p(50, 62), control1: p(100, 30), control2: p(90, 66))
        thread.addCurve(to: p(20, 40), control1: p(30, 60), control2: p(8, 52))
        c.stroke(thread, with: .color(Ink.wine), lineWidth: 1.3)
      case .bastion:
        for row in 0..<3 {
          let y = 20 + CGFloat(row) * 14
          let offset = CGFloat(row % 2) * 12
          for column in 0..<3 {
            let x = 14 + offset + CGFloat(column) * 26
            c.cut(
              [p(x, y), p(x + 24, y), p(x + 24, y + 12), p(x, y + 12)],
              row == 1 ? Ink.parchment : paper, edge: Ink.bronze)
          }
        }
        for column in 0..<4 {
          c.cut(
            [
              p(16 + CGFloat(column) * 20, 12), p(26 + CGFloat(column) * 20, 12),
              p(26 + CGFloat(column) * 20, 20), p(16 + CGFloat(column) * 20, 20),
            ], copper, edge: Ink.bronze)
        }
      case .venom:
        c.cut(
          [p(38, 14), p(62, 14), p(62, 24), p(72, 34), p(72, 60), p(28, 60), p(28, 34), p(38, 24)],
          Ink.moss, edge: copper)
        c.cut([p(42, 8), p(58, 8), p(58, 14), p(42, 14)], copper, edge: Ink.bronze)
        c.disc(CGRect(x: 34, y: 36, width: 32, height: 20), ink.opacity(0.6))
        var drip = Path()
        drip.move(to: p(50, 56))
        drip.addCurve(to: p(50, 68), control1: p(43, 64), control2: p(57, 64))
        c.fill(drip, with: .color(Ink.green))
        c.disc(CGRect(x: 40, y: 22, width: 4, height: 8), paper.opacity(0.6))
      case .insight:
        c.cut([p(50, 18), p(84, 12), p(84, 58), p(50, 64)], paper, edge: Ink.bronze)
        c.cut([p(50, 18), p(16, 12), p(16, 58), p(50, 64)], Ink.parchment, edge: Ink.bronze)
        for row in 0..<4 {
          let y = 26 + CGFloat(row) * 9
          c.line([p(22, y + 1), p(44, y + 3)], ink.opacity(0.35), width: 0.9)
          c.line([p(56, y + 3), p(78, y + 1)], ink.opacity(0.35), width: 0.9)
        }
        c.disc(CGRect(x: 58, y: 32, width: 18, height: 10), copper)
        c.disc(CGRect(x: 64, y: 33, width: 7, height: 7), ink)
      case .echo:
        for sign: CGFloat in [-1, 1] {
          let x = 50 + sign * 14
          c.cut(
            [p(x, 8), p(x + sign * 8, 20), p(x + sign * 4, 48), p(x - sign * 2, 48)], paper,
            edge: Ink.bronze)
          c.line([p(x - sign * 8, 50), p(x + sign * 10, 50)], copper, width: 3)
          c.line([p(x, 50), p(x, 62)], Ink.bronze, width: 3)
        }
        c.ring(
          CGRect(x: 26, y: 12, width: 48, height: 48), gilt.opacity(0.4), width: 0.8, dash: [2, 3])
      case .mend:
        c.cut([p(14, 12), p(86, 12), p(86, 58), p(14, 58)], paper, edge: Ink.bronze)
        c.line([p(38, 12), p(52, 34), p(44, 58)], Ink.wine.opacity(0.7), width: 1.2)
        for index in 0..<5 {
          let y = 16 + CGFloat(index) * 9
          c.line([p(34, y), p(58, y + 5)], gilt, width: 1.6)
        }
        c.line([p(58, 14), p(70, 6)], gilt, width: 1.6)
        c.disc(CGRect(x: 68, y: 3, width: 5, height: 5), copper)
      case .kindle:
        c.line([p(24, 60), p(76, 46)], Ink.bronze, width: 3)
        c.line([p(26, 46), p(74, 60)], Ink.bronze, width: 3)
        var flame = Path()
        flame.move(to: p(50, 8))
        flame.addCurve(to: p(50, 50), control1: p(76, 26), control2: p(70, 52))
        flame.addCurve(to: p(50, 8), control1: p(30, 52), control2: p(28, 26))
        c.fill(
          flame,
          with: .linearGradient(
            Gradient(colors: [gilt, copper, Ink.wine]), startPoint: p(50, 10), endPoint: p(50, 50)))
        var core = Path()
        core.move(to: p(50, 26))
        core.addCurve(to: p(50, 48), control1: p(60, 36), control2: p(58, 50))
        core.addCurve(to: p(50, 26), control1: p(42, 50), control2: p(40, 36))
        c.fill(core, with: .color(paper))
      case .riposte:
        c.cut(
          [p(50, 8), p(80, 18), p(76, 44), p(50, 62), p(24, 44), p(20, 18)], Ink.moss, edge: copper)
        c.line([p(50, 8), p(50, 62)], copper, width: 1)
        c.line([p(16, 60), p(84, 12)], gilt, width: 3)
        c.line([p(16, 60), p(84, 12)], paper, width: 1)
        c.line([p(22, 48), p(34, 58)], Ink.bronze, width: 3)
      case .sever:
        c.line([p(50, 0), p(50, 30)], paper, width: 1.2)
        c.line([p(30, 0), p(44, 30)], paper.opacity(0.6), width: 0.8)
        c.line([p(70, 0), p(56, 30)], paper.opacity(0.6), width: 0.8)
        c.cut([p(50, 30), p(66, 62), p(34, 62)], copper, edge: Ink.bronze)
        c.disc(CGRect(x: 43, y: 18, width: 14, height: 16), paper)
        c.line([p(14, 20), p(48, 36)], ink, width: 2.2)
        c.line([p(14, 44), p(48, 28)], ink, width: 2.2)
        c.ring(CGRect(x: 6, y: 14, width: 12, height: 10), ink, width: 2)
        c.ring(CGRect(x: 6, y: 42, width: 12, height: 10), ink, width: 2)
        c.line([p(52, 16), p(60, 8)], gilt, width: 1.4)
      case .sanctuary:
        var arch = Path()
        arch.move(to: p(22, 64))
        arch.addLine(to: p(22, 30))
        arch.addArc(
          center: p(50, 30), radius: 28, startAngle: .degrees(180), endAngle: .degrees(0),
          clockwise: false)
        arch.addLine(to: p(78, 64))
        arch.closeSubpath()
        c.fill(arch, with: .color(paper))
        c.stroke(arch, with: .color(Ink.bronze), lineWidth: 1)
        var door = Path()
        door.move(to: p(34, 64))
        door.addLine(to: p(34, 34))
        door.addArc(
          center: p(50, 34), radius: 16, startAngle: .degrees(180), endAngle: .degrees(0),
          clockwise: false)
        door.addLine(to: p(66, 64))
        door.closeSubpath()
        c.fill(
          door,
          with: .linearGradient(
            Gradient(colors: [Ink.moss, ink]), startPoint: p(50, 20), endPoint: p(50, 64)))
        c.disc(CGRect(x: 45, y: 36, width: 10, height: 12), gilt)
        c.line([p(50, 30), p(50, 36)], copper, width: 1)
      case .harvest:
        var moon = Path()
        moon.addArc(
          center: p(50, 34), radius: 24, startAngle: .degrees(-70), endAngle: .degrees(110),
          clockwise: false)
        moon.addArc(
          center: p(60, 30), radius: 20, startAngle: .degrees(110), endAngle: .degrees(-70),
          clockwise: true)
        moon.closeSubpath()
        c.fill(moon, with: .color(paper))
        c.stroke(moon, with: .color(Ink.bronze), lineWidth: 1)
        for index in 0..<5 {
          let x = 58 + CGFloat(index) * 7
          c.line([p(x, 66), p(x + 2, 40 + CGFloat(index % 2) * 4)], copper, width: 1.4)
          c.disc(CGRect(x: x - 1, y: 36 + CGFloat(index % 2) * 4, width: 5, height: 8), gilt)
        }
      case .flourish:
        var quill = Path()
        quill.move(to: p(78, 8))
        quill.addCurve(to: p(28, 58), control1: p(80, 30), control2: p(50, 50))
        quill.addCurve(to: p(78, 8), control1: p(40, 30), control2: p(56, 6))
        c.fill(
          quill,
          with: .linearGradient(
            Gradient(colors: [paper, Ink.parchment]), startPoint: p(78, 8), endPoint: p(28, 58)))
        c.stroke(quill, with: .color(Ink.bronze), lineWidth: 1)
        c.line([p(78, 8), p(30, 56)], copper, width: 0.8)
        var swirl = Path()
        swirl.move(to: p(24, 62))
        swirl.addCurve(to: p(60, 64), control1: p(30, 72), control2: p(48, 70))
        swirl.addCurve(to: p(84, 60), control1: p(70, 60), control2: p(76, 68))
        c.stroke(swirl, with: .color(ink.opacity(0.7)), lineWidth: 1.3)
      case .eclipse:
        for index in 0..<16 {
          let angle = Double(index) / 16 * .pi * 2
          c.line(
            [
              p(50 + CGFloat(cos(angle)) * 26, 35 + CGFloat(sin(angle)) * 26),
              p(50 + CGFloat(cos(angle)) * 33, 35 + CGFloat(sin(angle)) * 33),
            ], gilt, width: 1.4)
        }
        c.disc(CGRect(x: 26, y: 11, width: 48, height: 48), gilt)
        c.disc(CGRect(x: 30, y: 13, width: 46, height: 46), ink)
        c.ring(CGRect(x: 30, y: 13, width: 46, height: 46), copper, width: 1)
      case .hourglass:
        c.cut(
          [p(30, 10), p(70, 10), p(52, 36), p(70, 62), p(30, 62), p(48, 36)], paper.opacity(0.85),
          edge: Ink.bronze)
        c.line([p(26, 9), p(74, 9)], copper, width: 3)
        c.line([p(26, 63), p(74, 63)], copper, width: 3)
        c.cut([p(38, 16), p(62, 16), p(50, 34)], Ink.parchment, edge: copper)
        c.cut([p(40, 60), p(60, 60), p(50, 50)], copper, edge: Ink.bronze)
        c.line([p(50, 34), p(50, 52)], copper, width: 1)
      case .thorn:
        c.cut(
          [p(20, 58), p(20, 26), p(36, 40), p(50, 14), p(64, 40), p(80, 26), p(80, 58)], copper,
          edge: Ink.bronze)
        c.line([p(20, 58), p(80, 58)], Ink.bronze, width: 2)
        for index in 0..<6 {
          let x = 24 + CGFloat(index) * 10.5
          c.line([p(x, 50), p(x + 3, 42), p(x + 6, 50)], Ink.wine, width: 1.6)
        }
        c.disc(CGRect(x: 47, y: 10, width: 6, height: 6), gilt)
        c.disc(CGRect(x: 17, y: 22, width: 6, height: 6), gilt)
        c.disc(CGRect(x: 77, y: 22, width: 6, height: 6), gilt)
      case .lantern:
        c.line([p(50, 2), p(50, 10)], copper, width: 1.4)
        c.cut([p(40, 10), p(60, 10), p(60, 15), p(40, 15)], Ink.bronze, edge: Ink.bronze)
        var body = Path()
        body.move(to: p(40, 15))
        body.addCurve(to: p(40, 58), control1: p(14, 24), control2: p(14, 50))
        body.addLine(to: p(60, 58))
        body.addCurve(to: p(60, 15), control1: p(86, 50), control2: p(86, 24))
        body.closeSubpath()
        c.fill(
          body,
          with: .radialGradient(
            Gradient(colors: [gilt, copper, Ink.wine.opacity(0.9)]), center: p(50, 34),
            startRadius: 2, endRadius: 30))
        c.stroke(body, with: .color(Ink.bronze), lineWidth: 1)
        for index in 1..<5 {
          c.line(
            [
              p(22 + CGFloat(index) * 2, 15 + CGFloat(index) * 9),
              p(78 - CGFloat(index) * 2, 15 + CGFloat(index) * 9),
            ], Ink.bronze.opacity(0.5), width: 0.7)
        }
        c.cut([p(40, 58), p(60, 58), p(60, 63), p(40, 63)], Ink.bronze, edge: Ink.bronze)
        c.line([p(50, 63), p(50, 68)], copper, width: 1.4)
      }
    }
    .accessibilityHidden(true)
  }
}

struct CardFace: View {
  var kind: CardKind
  var affordable = true
  var text: String?
  var width: CGFloat = 128
  private var accent: Color {
    kind.exhausts ? Ink.wine : kind.isDefense ? Ink.green : Ink.copper
  }
  var body: some View {
    let height = width * 1.6
    VStack(spacing: 0) {
      ZStack {
        RoundedRectangle(cornerRadius: 6).fill(
          LinearGradient(colors: [Ink.moss, Ink.deep], startPoint: .top, endPoint: .bottom))
        RadialGradient(
          colors: [Ink.gilt.opacity(0.28), .clear], center: .center, startRadius: 2,
          endRadius: width * 0.5
        ).clipShape(RoundedRectangle(cornerRadius: 6))
        CardIllustration(kind: kind).padding(6)
      }
      .frame(height: height * 0.36)
      .overlay(RoundedRectangle(cornerRadius: 6).stroke(Ink.bronze.opacity(0.9), lineWidth: 0.8))
      .padding(.top, 20)
      Text(kind.title).font(Ink.display(width * 0.118)).multilineTextAlignment(.center)
        .lineLimit(2).minimumScaleFactor(0.7)
        .frame(height: width * 0.3)
        .padding(.top, 4)
      HStack(spacing: 5) {
        Rectangle().fill(accent.opacity(0.7)).frame(height: 0.6)
        Diamond().fill(accent).frame(width: 5, height: 5)
        Rectangle().fill(accent.opacity(0.7)).frame(height: 0.6)
      }.padding(.horizontal, 6)
      Text(text ?? kind.text).font(Ink.serif(width * 0.098)).lineSpacing(1)
        .multilineTextAlignment(.center).frame(maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 2)
      Text(affordable ? kind.category : "NO ENERGY")
        .font(.system(size: width * 0.058, weight: .bold)).tracking(1.6)
        .foregroundStyle(affordable ? Ink.cream : Ink.paper)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(affordable ? accent : Ink.wine, in: Capsule())
        .padding(.bottom, 8)
    }
    .padding(.horizontal, 9)
    .frame(width: width, height: height)
    .foregroundStyle(Ink.forest)
    .background(
      ZStack {
        RoundedRectangle(cornerRadius: 11).fill(Ink.sheet)
        Canvas { context, size in
          for index in 0..<160 {
            let x = CGFloat((index * 61 + 7) % 199) / 199 * size.width
            let y = CGFloat((index * 97 + 3) % 211) / 211 * size.height
            context.fill(
              Path(CGRect(x: x, y: y, width: 0.6, height: 1.8)),
              with: .color(Ink.bronze.opacity(0.14)))
          }
        }.clipShape(RoundedRectangle(cornerRadius: 11))
      }
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8).stroke(accent.opacity(0.55), lineWidth: 0.8).padding(4)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 11).strokeBorder(
        LinearGradient(
          colors: [Ink.gilt.opacity(0.9), Ink.bronze.opacity(0.8)], startPoint: .topLeading,
          endPoint: .bottomTrailing), lineWidth: 1.2)
    )
    .overlay(alignment: .topLeading) {
      Seal(number: kind.cost, size: width * 0.24).offset(x: -width * 0.06, y: -width * 0.06)
    }
    .saturation(affordable ? 1 : 0.25)
    .opacity(affordable ? 1 : 0.84)
    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 6)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(kind.title), \(kind.cost) energy. \(text ?? kind.text)\(affordable ? "" : " Not enough energy.")"
    )
  }
}

struct RelicGlyph: View {
  var relic: Relic
  var body: some View {
    Canvas { raw, size in
      var c = raw
      let scale = min(size.width, size.height) / 60
      c.translateBy(x: (size.width - 60 * scale) / 2, y: (size.height - 60 * scale) / 2)
      c.scaleBy(x: scale, y: scale)
      func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
      c.disc(CGRect(x: 2, y: 2, width: 56, height: 56), Ink.copper.opacity(0.12))
      c.ring(
        CGRect(x: 2, y: 2, width: 56, height: 56), Ink.copper.opacity(0.6), width: 0.8,
        dash: [2, 3])
      switch relic {
      case .spool:
        c.cut([p(18, 14), p(42, 14), p(42, 46), p(18, 46)], Ink.copper, edge: Ink.bronze)
        for index in 0..<6 {
          c.line(
            [p(19, 18 + CGFloat(index) * 5), p(41, 20 + CGFloat(index) * 5)],
            Ink.bronze.opacity(0.7), width: 0.8)
        }
        c.cut([p(14, 10), p(46, 10), p(46, 14), p(14, 14)], Ink.parchment, edge: Ink.bronze)
        c.cut([p(14, 46), p(46, 46), p(46, 50), p(14, 50)], Ink.parchment, edge: Ink.bronze)
        c.line([p(42, 30), p(54, 20)], Ink.wine, width: 1.2)
      case .feather:
        var quill = Path()
        quill.move(to: p(48, 10))
        quill.addCurve(to: p(14, 50), control1: p(50, 30), control2: p(30, 44))
        quill.addCurve(to: p(48, 10), control1: p(24, 26), control2: p(34, 8))
        c.fill(
          quill,
          with: .linearGradient(
            Gradient(colors: [Ink.paper, Ink.copper]), startPoint: p(48, 10), endPoint: p(14, 50)))
        c.stroke(quill, with: .color(Ink.bronze), lineWidth: 1)
        c.line([p(48, 10), p(16, 48)], Ink.deep.opacity(0.5), width: 0.8)
      case .candle:
        c.cut([p(24, 30), p(36, 30), p(36, 52), p(24, 52)], Ink.paper, edge: Ink.bronze)
        var flame = Path()
        flame.move(to: p(30, 10))
        flame.addCurve(to: p(30, 30), control1: p(42, 20), control2: p(38, 30))
        flame.addCurve(to: p(30, 10), control1: p(22, 30), control2: p(18, 20))
        c.fill(
          flame,
          with: .linearGradient(
            Gradient(colors: [Ink.gilt, Ink.wine]), startPoint: p(30, 10), endPoint: p(30, 30)))
        c.disc(CGRect(x: 27, y: 20, width: 6, height: 8), Ink.paper)
      case .thimble:
        var cap = Path()
        cap.move(to: p(18, 50))
        cap.addLine(to: p(18, 28))
        cap.addArc(
          center: p(30, 28), radius: 12, startAngle: .degrees(180), endAngle: .degrees(0),
          clockwise: false)
        cap.addLine(to: p(42, 50))
        cap.closeSubpath()
        c.fill(
          cap,
          with: .linearGradient(
            Gradient(colors: [Ink.paper, Ink.parchment]), startPoint: p(18, 20), endPoint: p(42, 50)
          ))
        c.stroke(cap, with: .color(Ink.bronze), lineWidth: 1)
        for row in 0..<3 {
          for column in 0..<3 {
            c.disc(
              CGRect(x: 23 + CGFloat(column) * 6, y: 22 + CGFloat(row) * 6, width: 2, height: 2),
              Ink.bronze)
          }
        }
        c.line([p(18, 46), p(42, 46)], Ink.copper, width: 1.4)
      }
    }
    .accessibilityHidden(true)
  }
}

struct SceneGlyph: View {
  var symbol: String
  var body: some View {
    Canvas { raw, size in
      var c = raw
      let scale = min(size.width, size.height) / 60
      c.translateBy(x: (size.width - 60 * scale) / 2, y: (size.height - 60 * scale) / 2)
      c.scaleBy(x: scale, y: scale)
      func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
      switch symbol {
      case "leaf":
        var leaf = Path()
        leaf.move(to: p(30, 8))
        leaf.addCurve(to: p(30, 52), control1: p(56, 22), control2: p(50, 46))
        leaf.addCurve(to: p(30, 8), control1: p(10, 46), control2: p(4, 22))
        c.fill(
          leaf,
          with: .linearGradient(
            Gradient(colors: [Ink.green, Ink.moss]), startPoint: p(30, 8), endPoint: p(30, 52)))
        c.stroke(leaf, with: .color(Ink.copper), lineWidth: 1)
        c.line([p(30, 10), p(30, 50)], Ink.gilt, width: 0.9)
        for index in 0..<4 {
          c.line(
            [p(30, 18 + CGFloat(index) * 8), p(40 - CGFloat(index) * 2, 14 + CGFloat(index) * 8)],
            Ink.gilt.opacity(0.6), width: 0.7)
        }
      case "bag":
        c.cut([p(14, 52), p(46, 52), p(44, 34), p(16, 34)], Ink.wine, edge: Ink.copper)
        c.cut([p(12, 30), p(48, 30), p(46, 36), p(14, 36)], Ink.copper, edge: Ink.bronze)
        var handle = Path()
        handle.move(to: p(20, 30))
        handle.addCurve(to: p(40, 30), control1: p(20, 8), control2: p(40, 8))
        c.stroke(handle, with: .color(Ink.gilt), lineWidth: 2)
        c.disc(CGRect(x: 26, y: 40, width: 8, height: 8), Ink.gilt)
      default:
        c.disc(CGRect(x: 6, y: 6, width: 48, height: 48), Ink.copper.opacity(0.15))
      }
    }
    .accessibilityHidden(true)
  }
}
