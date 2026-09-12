import SwiftUI

enum Palette {
  static let ink = Color(red: 0.025, green: 0.12, blue: 0.10)
  static let green = Color(red: 0.04, green: 0.24, blue: 0.19)
  static let gold = Color(red: 0.88, green: 0.73, blue: 0.43)
  static let cream = Color(red: 0.97, green: 0.93, blue: 0.82)
  static let muted = Color(red: 0.71, green: 0.81, blue: 0.73)
  static let ruby = Color(red: 0.64, green: 0.19, blue: 0.25)
}

struct VelvetBackground: View {
  var body: some View {
    ZStack {
      RadialGradient(
        colors: [Palette.green, Palette.ink, Color(red: 0.015, green: 0.065, blue: 0.06)],
        center: .top, startRadius: 30, endRadius: 900)
      Canvas { context, size in
        for x in stride(from: 0.0, through: size.width, by: 22) {
          for y in stride(from: 0.0, through: size.height, by: 22) {
            let diamond = Path { p in
              p.move(to: CGPoint(x: x, y: y - 2))
              p.addLine(to: CGPoint(x: x + 1.5, y: y))
              p.addLine(to: CGPoint(x: x, y: y + 2))
              p.addLine(to: CGPoint(x: x - 1.5, y: y))
              p.closeSubpath()
            }
            context.fill(diamond, with: .color(Palette.gold.opacity(0.09)))
          }
        }
      }
      .allowsHitTesting(false)
    }.ignoresSafeArea()
  }
}

struct Eyebrow: View {
  let text: String
  var body: some View {
    Text(text.uppercased()).font(.system(size: 11, weight: .bold, design: .rounded))
      .tracking(1.8).foregroundStyle(Palette.gold)
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
        Text(title).font(.system(size: 16, weight: .bold, design: .rounded))
        Spacer()
        Image(systemName: icon).font(.system(size: 15, weight: .semibold))
      }
      .padding(.horizontal, 20).frame(minHeight: 54)
      .foregroundStyle(Palette.ink)
      .background(
        LinearGradient(
          colors: [Palette.cream, Palette.gold], startPoint: .topLeading, endPoint: .bottomTrailing),
        in: RoundedRectangle(cornerRadius: 15)
      )
      .opacity(disabled ? 0.35 : 1)
    }.disabled(disabled).buttonStyle(.plain)
  }
}

struct QuietButton: View {
  let title: String
  var icon = ""
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if !icon.isEmpty { Image(systemName: icon) }
        Text(title).fontWeight(.semibold)
      }.font(.system(size: 13)).frame(minHeight: 44).frame(maxWidth: .infinity)
        .foregroundStyle(Palette.cream)
        .background(Palette.cream.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.gold.opacity(0.2)))
    }.buttonStyle(.plain)
  }
}

struct Panel<Content: View>: View {
  @ViewBuilder var content: Content
  var body: some View {
    content.padding(18).frame(maxWidth: .infinity)
      .background(Palette.ink.opacity(0.65), in: RoundedRectangle(cornerRadius: 22))
      .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.gold.opacity(0.20)))
  }
}

struct PlayingCard: View {
  let card: Card
  var selected = false
  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      ZStack {
        RoundedRectangle(cornerRadius: 9)
          .fill(
            LinearGradient(
              colors: [Color.white, Palette.cream], startPoint: .topLeading,
              endPoint: .bottomTrailing))
        RoundedRectangle(cornerRadius: 6).stroke(Palette.gold.opacity(0.4)).padding(4)
        VStack(spacing: 0) {
          HStack(alignment: .top) {
            VStack(spacing: -3) {
              Text(card.label).font(.system(size: width * 0.28, weight: .bold, design: .serif))
              Text(card.suit.symbol).font(.system(size: width * 0.20))
            }
            Spacer(minLength: 0)
            if selected {
              Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14)).foregroundStyle(Palette.green)
            }
          }
          Spacer(minLength: 0)
          Text(card.suit.symbol).font(.system(size: width * 0.43))
          Spacer(minLength: 0)
          HStack {
            Spacer()
            Text(card.label).font(.system(size: width * 0.17, weight: .bold, design: .serif))
          }
        }.padding(8).foregroundStyle(card.suit.isRed ? Palette.ruby : Palette.ink)
      }
      .overlay(
        RoundedRectangle(cornerRadius: 9).stroke(selected ? Palette.gold : .clear, lineWidth: 3)
      )
      .shadow(color: .black.opacity(0.3), radius: 5, y: 4)
    }.aspectRatio(0.70, contentMode: .fit)
  }
}

struct CharmArt: View {
  let charm: Charm
  var body: some View {
    Canvas { context, size in
      let scale = min(size.width, size.height) / 100
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
      oval(CGRect(x: 8, y: 8, width: 84, height: 84), color: gold.opacity(0.08))
      context.stroke(
        Path(ellipseIn: CGRect(x: 12, y: 12, width: 76, height: 76)),
        with: .color(gold.opacity(0.3)), lineWidth: 1)
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
            color: n % 2 == 0 ? Palette.ruby : Color(red: 0.82, green: 0.35, blue: 0.39))
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
      for (x, y) in [(15.0, 20.0), (82.0, 79.0)] {
        line([.init(x: x - 3, y: y), .init(x: x + 3, y: y)], width: 1)
        line([.init(x: x, y: y - 3), .init(x: x, y: y + 3)], width: 1)
      }
    }.aspectRatio(1, contentMode: .fit).accessibilityHidden(true)
  }
}
