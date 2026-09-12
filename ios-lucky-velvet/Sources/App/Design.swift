import SwiftUI

enum Palette {
  static let ink = Color(red: 0.020, green: 0.095, blue: 0.082)
  static let green = Color(red: 0.045, green: 0.245, blue: 0.190)
  static let felt = Color(red: 0.070, green: 0.330, blue: 0.245)
  static let gold = Color(red: 0.89, green: 0.74, blue: 0.44)
  static let brass = Color(red: 0.66, green: 0.50, blue: 0.24)
  static let cream = Color(red: 0.975, green: 0.94, blue: 0.85)
  static let ivory = Color(red: 0.995, green: 0.985, blue: 0.95)
  static let muted = Color(red: 0.72, green: 0.82, blue: 0.74)
  static let ruby = Color(red: 0.66, green: 0.17, blue: 0.24)
  static let rose = Color(red: 0.84, green: 0.36, blue: 0.40)

  static let foil = LinearGradient(
    colors: [Color(red: 0.99, green: 0.93, blue: 0.75), gold, brass, gold],
    startPoint: .topLeading, endPoint: .bottomTrailing)
  static let foilStroke = LinearGradient(
    colors: [Color(red: 0.99, green: 0.92, blue: 0.72), brass, gold],
    startPoint: .top, endPoint: .bottom)
}

extension Text {
  func deco(_ size: CGFloat, weight: Font.Weight = .semibold, tracking: CGFloat = 2.4) -> Text {
    font(.system(size: size, weight: weight, design: .serif)).tracking(tracking)
  }
}

struct VelvetBackground: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Palette.felt, Palette.green, Palette.ink], startPoint: .top, endPoint: .bottom)
      RadialGradient(
        colors: [Palette.gold.opacity(0.22), .clear], center: UnitPoint(x: 0.5, y: -0.1),
        startRadius: 0, endRadius: 520)
      Canvas { context, size in
        var weave = Path()
        for x in stride(from: -size.height, through: size.width, by: 7) {
          weave.move(to: CGPoint(x: x, y: 0))
          weave.addLine(to: CGPoint(x: x + size.height, y: size.height))
        }
        context.stroke(weave, with: .color(.black.opacity(0.09)), lineWidth: 0.6)
        for x in stride(from: 0.0, through: size.width, by: 26) {
          for y in stride(from: 0.0, through: size.height, by: 26) {
            let diamond = Path { p in
              p.move(to: CGPoint(x: x, y: y - 2.2))
              p.addLine(to: CGPoint(x: x + 1.6, y: y))
              p.addLine(to: CGPoint(x: x, y: y + 2.2))
              p.addLine(to: CGPoint(x: x - 1.6, y: y))
              p.closeSubpath()
            }
            context.fill(diamond, with: .color(Palette.gold.opacity(0.10)))
          }
        }
      }
      RadialGradient(
        colors: [.clear, .black.opacity(0.55)], center: .center, startRadius: 180,
        endRadius: 620)
    }.ignoresSafeArea().allowsHitTesting(false)
  }
}

struct Sunburst: View {
  var rays = 36
  var body: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let radius = max(size.width, size.height)
      for n in 0..<rays where n % 2 == 0 {
        let a = Double(n) / Double(rays) * .pi * 2
        let b = Double(n + 1) / Double(rays) * .pi * 2
        let ray = Path { p in
          p.move(to: center)
          p.addLine(to: CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius))
          p.addLine(to: CGPoint(x: center.x + cos(b) * radius, y: center.y + sin(b) * radius))
          p.closeSubpath()
        }
        context.fill(ray, with: .color(Palette.gold.opacity(0.055)))
      }
    }
    .mask(
      RadialGradient(
        colors: [.white, .white.opacity(0)], center: .center, startRadius: 40, endRadius: 230)
    )
    .allowsHitTesting(false)
  }
}

struct Eyebrow: View {
  let text: String
  var color = Palette.gold
  var body: some View {
    Text(text.uppercased()).deco(10.5, tracking: 2.6).foregroundStyle(color)
  }
}

struct Ornament: View {
  var text = ""
  var body: some View {
    HStack(spacing: 10) {
      rule(.leading)
      if text.isEmpty {
        Text("✦").font(.system(size: 9)).foregroundStyle(Palette.gold)
      } else {
        Eyebrow(text: text).fixedSize()
      }
      rule(.trailing)
    }
  }
  private func rule(_ fade: UnitPoint) -> some View {
    LinearGradient(
      colors: [Palette.gold.opacity(0), Palette.gold.opacity(0.6)], startPoint: fade,
      endPoint: fade == .leading ? .trailing : .leading
    )
    .frame(height: 1).frame(maxWidth: .infinity)
  }
}

struct DecoFrame: ViewModifier {
  var radius: CGFloat = 20
  var fill = Palette.ink.opacity(0.72)
  var strength = 0.55
  func body(content: Content) -> some View {
    content
      .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .strokeBorder(Palette.foilStroke, lineWidth: 1).opacity(strength)
      )
      .overlay(
        RoundedRectangle(cornerRadius: max(4, radius - 5), style: .continuous)
          .strokeBorder(Palette.gold.opacity(0.18 * strength), lineWidth: 0.7).padding(5)
      )
      .overlay(alignment: .top) {
        LinearGradient(
          colors: [Palette.cream.opacity(0.10), .clear], startPoint: .top, endPoint: .bottom
        )
        .frame(height: 28).clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .allowsHitTesting(false)
      }
      .shadow(color: .black.opacity(0.28), radius: 14, y: 8)
  }
}

extension View {
  func decoFrame(
    radius: CGFloat = 20, fill: Color = Palette.ink.opacity(0.72), strength: Double = 0.55
  )
    -> some View
  {
    modifier(DecoFrame(radius: radius, fill: fill, strength: strength))
  }
}

struct Panel<Content: View>: View {
  var inset: CGFloat = 18
  @ViewBuilder var content: Content
  var body: some View {
    content.padding(inset).frame(maxWidth: .infinity).decoFrame(radius: 22)
  }
}

struct PressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .brightness(configuration.isPressed ? -0.05 : 0)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

struct GoldButton: View {
  let title: String
  var icon = "arrow.right"
  var disabled = false
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack {
        Text(title).font(.system(size: 16, weight: .semibold, design: .serif))
        Spacer()
        Image(systemName: icon).font(.system(size: 14, weight: .semibold))
      }
      .padding(.horizontal, 22).frame(minHeight: 54)
      .foregroundStyle(Palette.ink)
      .background(Palette.foil, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(Color.white.opacity(0.55), lineWidth: 1).padding(1.5)
          .blendMode(.overlay)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(Palette.brass.opacity(0.9), lineWidth: 1)
      )
      .shadow(color: Palette.gold.opacity(disabled ? 0 : 0.30), radius: 16, y: 6)
      .opacity(disabled ? 0.35 : 1)
    }.disabled(disabled).buttonStyle(PressStyle())
  }
}

struct QuietButton: View {
  let title: String
  var icon = ""
  var height: CGFloat = 44
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if !icon.isEmpty { Image(systemName: icon).font(.system(size: 12, weight: .semibold)) }
        Text(title).font(.system(size: 14, weight: .semibold, design: .serif))
      }.frame(minHeight: height).frame(maxWidth: .infinity)
        .foregroundStyle(Palette.cream)
        .background(
          Palette.cream.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Palette.foilStroke, lineWidth: 1).opacity(0.5))
    }.buttonStyle(PressStyle())
  }
}

struct CountUp: View, @preconcurrency Animatable {
  var value: Double
  nonisolated var animatableData: Double {
    get { value }
    set { value = newValue }
  }
  var body: some View {
    Text("+\(Int(value.rounded(.down)).formatted())")
  }
}

struct Monogram: View {
  var size: CGFloat = 34
  var body: some View {
    ZStack {
      Circle().fill(Palette.ink)
      Circle().strokeBorder(Palette.foilStroke, lineWidth: 1.2)
      Circle().strokeBorder(Palette.gold.opacity(0.35), lineWidth: 0.6).padding(3)
      Text("LV").font(.system(size: size * 0.40, weight: .medium, design: .serif))
        .tracking(-1).foregroundStyle(Palette.gold)
    }.frame(width: size, height: size).accessibilityHidden(true)
  }
}

struct PlayingCard: View {
  let card: Card
  var selected = false
  private var tint: Color { card.suit.isRed ? Palette.ruby : Palette.ink }
  var body: some View {
    GeometryReader { geometry in
      let w = geometry.size.width
      let h = geometry.size.height
      ZStack {
        RoundedRectangle(cornerRadius: w * 0.10, style: .continuous)
          .fill(
            LinearGradient(
              colors: [Palette.ivory, Palette.cream], startPoint: .top, endPoint: .bottom))
        RoundedRectangle(cornerRadius: w * 0.10, style: .continuous)
          .strokeBorder(Palette.brass.opacity(0.55), lineWidth: 0.8)
        RoundedRectangle(cornerRadius: w * 0.05, style: .continuous)
          .strokeBorder(Palette.gold.opacity(0.7), lineWidth: 0.7).padding(w * 0.075)
        face(w: w, h: h)
        index(w: w)
        index(w: w).rotationEffect(.degrees(180))
      }
      .overlay(
        RoundedRectangle(cornerRadius: w * 0.10, style: .continuous)
          .strokeBorder(Palette.gold, lineWidth: selected ? 2.5 : 0)
      )
      .shadow(color: .black.opacity(0.32), radius: selected ? 10 : 5, y: selected ? 8 : 4)
      .shadow(color: Palette.gold.opacity(selected ? 0.45 : 0), radius: 14)
    }.aspectRatio(0.70, contentMode: .fit)
  }

  private func index(w: CGFloat) -> some View {
    VStack(spacing: -w * 0.03) {
      Text(card.label).font(.system(size: w * 0.24, weight: .semibold, design: .serif))
      Text(card.suit.symbol).font(.system(size: w * 0.15))
    }
    .foregroundStyle(tint)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(.leading, w * 0.10).padding(.top, w * 0.07)
  }

  @ViewBuilder
  private func face(w: CGFloat, h: CGFloat) -> some View {
    let inner = CGRect(x: w * 0.27, y: h * 0.17, width: w * 0.46, height: h * 0.66)
    switch card.rank {
    case 14:
      ZStack {
        Circle().strokeBorder(Palette.gold.opacity(0.6), lineWidth: 0.8).frame(width: w * 0.58)
        Text(card.suit.symbol).font(.system(size: w * 0.40)).foregroundStyle(tint)
      }
    case 11, 12, 13:
      ZStack {
        RoundedRectangle(cornerRadius: w * 0.04)
          .fill(tint.opacity(0.08)).frame(width: inner.width, height: inner.height)
        RoundedRectangle(cornerRadius: w * 0.04)
          .strokeBorder(Palette.gold.opacity(0.8), lineWidth: 0.8)
          .frame(width: inner.width, height: inner.height)
        VStack(spacing: w * 0.02) {
          Text(card.rank == 13 ? "♚" : card.rank == 12 ? "♛" : "⚜")
            .font(.system(size: w * 0.22)).foregroundStyle(Palette.brass)
          Text(card.label).font(.system(size: w * 0.30, weight: .medium, design: .serif))
            .foregroundStyle(tint)
          Text(card.suit.symbol).font(.system(size: w * 0.15)).foregroundStyle(tint)
        }
      }
    default:
      Canvas { context, size in
        for point in Self.pips[card.rank] ?? [] {
          let flipped = point.y > 0.5
          let pip = context.resolve(
            Text(card.suit.symbol).font(.system(size: w * 0.19)).foregroundStyle(tint))
          var ctx = context
          let at = CGPoint(x: size.width * point.x, y: size.height * point.y)
          if flipped {
            ctx.translateBy(x: at.x, y: at.y)
            ctx.rotate(by: .degrees(180))
            ctx.draw(pip, at: .zero)
          } else {
            ctx.draw(pip, at: at)
          }
        }
      }.frame(width: inner.width, height: inner.height)
    }
  }

  private static let pips: [Int: [CGPoint]] = {
    let l = 0.22
    let r = 0.78
    let c = 0.5
    var map: [Int: [CGPoint]] = [:]
    map[2] = [(c, 0.12), (c, 0.88)].map { CGPoint(x: $0, y: $1) }
    map[3] = [(c, 0.12), (c, 0.5), (c, 0.88)].map { CGPoint(x: $0, y: $1) }
    let corners = [(l, 0.12), (r, 0.12), (l, 0.88), (r, 0.88)]
    map[4] = corners.map { CGPoint(x: $0, y: $1) }
    map[5] = (corners + [(c, 0.5)]).map { CGPoint(x: $0, y: $1) }
    let six = corners + [(l, 0.5), (r, 0.5)]
    map[6] = six.map { CGPoint(x: $0, y: $1) }
    map[7] = (six + [(c, 0.31)]).map { CGPoint(x: $0, y: $1) }
    map[8] = (six + [(c, 0.31), (c, 0.69)]).map { CGPoint(x: $0, y: $1) }
    let nine = [
      (l, 0.12), (r, 0.12), (l, 0.37), (r, 0.37), (l, 0.63), (r, 0.63), (l, 0.88), (r, 0.88),
    ]
    map[9] = (nine + [(c, 0.5)]).map { CGPoint(x: $0, y: $1) }
    map[10] = (nine + [(c, 0.245), (c, 0.755)]).map { CGPoint(x: $0, y: $1) }
    return map
  }()
}

struct CharmTile: View {
  let charm: Charm
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.ink)
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Palette.foilStroke, lineWidth: 1).opacity(0.7)
      CharmArt(charm: charm).padding(4)
    }
  }
}

struct CharmArt: View {
  let charm: Charm
  var body: some View {
    Canvas { context, size in
      let scale = min(size.width, size.height) / 100
      context.translateBy(
        x: (size.width - 100 * scale) / 2, y: (size.height - 100 * scale) / 2)
      context.scaleBy(x: scale, y: scale)
      let gold = Palette.gold
      func line(_ points: [CGPoint], color: Color = Palette.gold, width: CGFloat = 3) {
        let path = Path { p in
          guard let first = points.first else { return }
          p.move(to: first)
          for point in points.dropFirst() { p.addLine(to: point) }
        }
        context.stroke(
          path, with: .color(color),
          style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
      }
      func oval(_ rect: CGRect, color: Color) {
        context.fill(Path(ellipseIn: rect), with: .color(color))
      }
      func polygon(_ points: [CGPoint], color: Color) {
        context.fill(
          Path { p in
            p.addLines(points)
            p.closeSubpath()
          }, with: .color(color))
      }
      context.fill(
        Path(ellipseIn: CGRect(x: 6, y: 6, width: 88, height: 88)),
        with: .radialGradient(
          Gradient(colors: [Palette.green.opacity(0.9), Palette.ink]),
          center: CGPoint(x: 50, y: 40), startRadius: 0, endRadius: 50))
      context.stroke(
        Path(ellipseIn: CGRect(x: 9, y: 9, width: 82, height: 82)),
        with: .color(gold.opacity(0.75)), lineWidth: 1.2)
      context.stroke(
        Path(ellipseIn: CGRect(x: 14, y: 14, width: 72, height: 72)),
        with: .color(gold.opacity(0.28)), lineWidth: 0.8)
      switch charm {
      case .ribbon:
        polygon(
          [.init(x: 49, y: 49), .init(x: 22, y: 26), .init(x: 23, y: 65)], color: Palette.ruby)
        polygon(
          [.init(x: 51, y: 49), .init(x: 78, y: 26), .init(x: 77, y: 65)], color: Palette.ruby)
        polygon(
          [.init(x: 45, y: 50), .init(x: 30, y: 84), .init(x: 46, y: 76), .init(x: 50, y: 53)],
          color: gold)
        polygon(
          [.init(x: 55, y: 50), .init(x: 70, y: 84), .init(x: 54, y: 76), .init(x: 50, y: 53)],
          color: gold)
        oval(CGRect(x: 43, y: 40, width: 14, height: 18), color: Palette.cream)
      case .ruby, .rose:
        for n in 0..<5 {
          let angle = Double(n) * .pi * 2 / 5
          oval(
            CGRect(x: 35 + cos(angle) * 15, y: 33 + sin(angle) * 15, width: 30, height: 30),
            color: n % 2 == 0 ? Palette.ruby : Palette.rose)
        }
        polygon(
          [.init(x: 50, y: 30), .init(x: 64, y: 48), .init(x: 50, y: 68), .init(x: 36, y: 48)],
          color: gold)
        line([.init(x: 50, y: 71), .init(x: 50, y: 86)])
      case .moon:
        oval(CGRect(x: 25, y: 22, width: 51, height: 56), color: gold)
        oval(CGRect(x: 43, y: 16, width: 40, height: 48), color: Palette.ink)
        line([.init(x: 67, y: 48), .init(x: 67, y: 67)])
        line([.init(x: 58, y: 58), .init(x: 76, y: 58)])
      case .crown:
        polygon(
          [
            .init(x: 22, y: 37), .init(x: 35, y: 48), .init(x: 50, y: 25), .init(x: 65, y: 48),
            .init(x: 78, y: 37), .init(x: 69, y: 73), .init(x: 31, y: 73),
          ], color: gold)
        for x in [38, 50, 62] {
          oval(CGRect(x: x - 3, y: 58, width: 6, height: 8), color: Palette.ruby)
        }
      case .twins, .velvet:
        for offset in charm == .twins ? [-15.0, 15.0] : [0.0] {
          polygon(
            [
              .init(x: 26 + offset, y: 24), .init(x: 50 + offset, y: 37),
              .init(x: 74 + offset, y: 24),
              .init(x: 68 + offset, y: 61), .init(x: 50 + offset, y: 78),
              .init(x: 32 + offset, y: 61),
            ],
            color: offset < 0 ? Palette.muted : gold)
          line(
            [.init(x: 37 + offset, y: 51), .init(x: 43 + offset, y: 53)], color: Palette.ink,
            width: 2)
          line(
            [.init(x: 57 + offset, y: 53), .init(x: 63 + offset, y: 51)], color: Palette.ink,
            width: 2)
          oval(CGRect(x: 47 + offset, y: 65, width: 6, height: 4), color: Palette.ink)
        }
      case .lantern, .echo:
        line([.init(x: 43, y: 25), .init(x: 43, y: 19), .init(x: 57, y: 19), .init(x: 57, y: 25)])
        polygon(
          [.init(x: 34, y: 32), .init(x: 66, y: 32), .init(x: 75, y: 73), .init(x: 25, y: 73)],
          color: gold)
        oval(CGRect(x: 41, y: 41, width: 18, height: 25), color: Palette.cream)
        line([.init(x: 43, y: 80), .init(x: 57, y: 80)])
      case .feather:
        polygon(
          [
            .init(x: 31, y: 72), .init(x: 33, y: 43), .init(x: 67, y: 19), .init(x: 76, y: 29),
            .init(x: 62, y: 62),
          ], color: gold)
        line([.init(x: 26, y: 83), .init(x: 66, y: 32)], color: Palette.cream, width: 2)
        for n in 0..<4 {
          line(
            [.init(x: 37 + n * 6, y: 66 - n * 8), .init(x: 58 + n * 4, y: 62 - n * 8)],
            color: Palette.ink, width: 1)
        }
      case .coin:
        oval(CGRect(x: 23, y: 23, width: 54, height: 54), color: gold)
        context.stroke(
          Path(ellipseIn: CGRect(x: 29, y: 29, width: 42, height: 42)), with: .color(Palette.ink),
          lineWidth: 2)
        context.draw(
          Text("V").font(.system(size: 32, weight: .bold, design: .serif)).foregroundStyle(
            Palette.ink),
          at: CGPoint(x: 50, y: 50))
      case .compass:
        polygon(
          [
            .init(x: 50, y: 16), .init(x: 58, y: 42), .init(x: 84, y: 50), .init(x: 58, y: 58),
            .init(x: 50, y: 84), .init(x: 42, y: 58), .init(x: 16, y: 50), .init(x: 42, y: 42),
          ], color: gold)
        oval(CGRect(x: 43, y: 43, width: 14, height: 14), color: Palette.cream)
      }
    }.aspectRatio(1, contentMode: .fit).accessibilityHidden(true)
  }
}
