import SwiftUI

enum Ink {
  static let night = Color(red: 0.035, green: 0.11, blue: 0.14)
  static let lake = Color(red: 0.063, green: 0.176, blue: 0.208)
  static let cream = Color(red: 0.933, green: 0.941, blue: 0.906)
  static let gold = Color(red: 0.843, green: 0.718, blue: 0.478)
  static let mint = Color(red: 0.569, green: 0.792, blue: 0.733)
  static let coral = Color(red: 0.949, green: 0.459, blue: 0.396)
}

enum TypeStyle {
  static func display(_ size: CGFloat) -> Font {
    .custom("AvenirNextCondensed-DemiBold", size: size)
  }
  static func body(_ size: CGFloat) -> Font { .custom("AvenirNext-Regular", size: size) }
  static func label(_ size: CGFloat) -> Font { .custom("AvenirNext-DemiBold", size: size) }
  static func specimen(_ size: CGFloat) -> Font { .custom("Baskerville-Italic", size: size) }
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
            stops: [
              .init(color: Ink.night.opacity(0.58), location: 0),
              .init(color: .clear, location: 0.34),
              .init(color: Ink.night.opacity(0.1), location: 0.58),
              .init(color: Ink.night.opacity(0.96), location: 1),
            ], startPoint: .top, endPoint: .bottom)
        }
    }
    .ignoresSafeArea()
    .accessibilityHidden(true)
  }
}

struct FishArt: View {
  let species: Species
  var silhouette = false
  var body: some View {
    Image(species.rawValue)
      .renderingMode(silhouette ? .template : .original)
      .resizable()
      .scaledToFit()
      .foregroundStyle(Ink.night.opacity(0.9))
      .accessibilityHidden(true)
  }
}

struct AnglerSeal: View {
  var body: some View {
    Canvas { context, size in
      context.scaleBy(x: size.width / 60, y: size.height / 60)
      context.stroke(
        Path(ellipseIn: CGRect(x: 2, y: 2, width: 56, height: 56)),
        with: .foreground, lineWidth: 0.8)
      var sun = Path()
      sun.addArc(
        center: CGPoint(x: 30, y: 28), radius: 11,
        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
      context.stroke(sun, with: .foreground, lineWidth: 1)
      var water = Path()
      for row in 0..<3 {
        let inset = CGFloat(row * 5)
        water.move(to: CGPoint(x: 11 + inset, y: 31 + CGFloat(row * 6)))
        water.addLine(to: CGPoint(x: 49 - inset, y: 31 + CGFloat(row * 6)))
      }
      context.stroke(water, with: .foreground, lineWidth: 1)
      for index in 0..<5 {
        let angle = Double(index) * .pi / 4 + .pi
        var ray = Path()
        ray.move(to: CGPoint(x: 30 + cos(angle) * 16, y: 28 + sin(angle) * 16))
        ray.addLine(to: CGPoint(x: 30 + cos(angle) * 20, y: 28 + sin(angle) * 20))
        context.stroke(ray, with: .foreground, lineWidth: 1)
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

struct InstrumentSurface: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(18)
      .background(
        LinearGradient(
          colors: [Ink.lake, Ink.night], startPoint: .topLeading, endPoint: .bottomTrailing),
        in: RoundedRectangle(cornerRadius: 18)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 18).strokeBorder(Ink.gold.opacity(0.32), lineWidth: 0.8)
      }
      .shadow(color: .black.opacity(0.22), radius: 18, y: 8)
  }
}

struct PrimaryAction: View {
  let title: String
  var icon = "arrow.up.right"
  var dark = false
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 14) {
        Text(title).font(TypeStyle.label(16))
        Spacer(minLength: 4)
        Image(systemName: icon).font(.system(size: 16, weight: .medium))
          .frame(width: 30, height: 30)
          .overlay(
            Circle().strokeBorder((dark ? Ink.gold : Ink.night).opacity(0.25), lineWidth: 0.8))
      }
      .padding(.horizontal, 18)
      .frame(minHeight: 56)
      .foregroundStyle(dark ? Ink.cream : Ink.night)
      .background(
        LinearGradient(
          colors: dark
            ? [Ink.lake, Ink.night] : [Color(red: 0.91, green: 0.81, blue: 0.61), Ink.gold],
          startPoint: .topLeading, endPoint: .bottomTrailing),
        in: RoundedRectangle(cornerRadius: 9)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 9).strokeBorder(Ink.gold.opacity(0.4), lineWidth: 0.7))
    }
    .buttonStyle(PressedActionStyle())
    .accessibilityIdentifier(title)
  }
}

struct PressedActionStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .brightness(configuration.isPressed ? -0.08 : 0)
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
  }
}

struct Eyebrow: View {
  let text: String
  var color = Ink.cream
  var body: some View {
    Text(text.uppercased())
      .font(TypeStyle.label(10))
      .tracking(1.8)
      .foregroundStyle(color)
  }
}

struct ReelControl: View {
  @Binding var holding: Bool
  let tension: Double
  let elapsed: Double
  @State private var spoolAngle = 0.0
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ZStack {
      Canvas { context, size in
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 6
        for index in 0...40 {
          let fraction = Double(index) / 40
          let angle = (140 + fraction * 260) * .pi / 180
          let color = fraction > 0.8 ? Ink.coral : fraction < 0.15 ? Ink.gold : Ink.mint
          let inner = radius - (index % 5 == 0 ? 11 : 6)
          var tick = Path()
          tick.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
          tick.addLine(
            to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
          context.stroke(tick, with: .color(color.opacity(0.85)), lineWidth: index % 5 == 0 ? 2 : 1)
        }
        let angle = (140 + min(1, max(0, tension)) * 260) * .pi / 180
        let tip = CGPoint(
          x: center.x + cos(angle) * (radius + 3), y: center.y + sin(angle) * (radius + 3))
        var pointer = Path()
        pointer.move(to: tip)
        pointer.addLine(
          to: CGPoint(
            x: center.x + cos(angle - 0.055) * (radius - 15),
            y: center.y + sin(angle - 0.055) * (radius - 15)))
        pointer.addLine(
          to: CGPoint(
            x: center.x + cos(angle + 0.055) * (radius - 15),
            y: center.y + sin(angle + 0.055) * (radius - 15)))
        pointer.closeSubpath()
        context.fill(pointer, with: .color(Ink.cream))
      }
      .allowsHitTesting(false)
      ZStack {
        Circle()
          .fill(
            LinearGradient(
              colors: [Ink.gold, Ink.night, Ink.gold.opacity(0.7)],
              startPoint: .topLeading, endPoint: .bottomTrailing))
        Circle().fill(Ink.lake).padding(3)
        Circle().strokeBorder(Ink.gold.opacity(0.45), lineWidth: 0.6).padding(9)
        ZStack {
          ForEach(0..<8) { index in
            Capsule().fill(Ink.night)
              .frame(width: 5, height: 18).offset(y: -44)
              .rotationEffect(.degrees(Double(index) * 45))
          }
        }
        .rotationEffect(.degrees(reduceMotion ? 0 : spoolAngle))
        VStack(spacing: 1) {
          Text(holding ? "REELING" : "HOLD").font(TypeStyle.display(25)).tracking(1)
          Text(holding ? "FEEL THE LINE" : "TO REEL").font(TypeStyle.label(8)).tracking(1.7)
        }
        .foregroundStyle(holding ? Ink.gold : Ink.cream)
      }
      .frame(width: 128, height: 128)
      .scaleEffect(holding && !reduceMotion ? 0.97 : 1)
      .shadow(color: .black.opacity(0.4), radius: holding ? 2 : 8, y: holding ? 1 : 5)
      .contentShape(Circle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in holding = true }
          .onEnded { _ in holding = false }
      )
      .accessibilityLabel("Reel")
      .accessibilityValue(
        "\(holding ? "Reeling" : "Released"), tension \(Int(tension * 100)) percent"
      )
      .accessibilityHint("Double tap to toggle reeling. Release before a surge.")
      .accessibilityAddTraits(.isButton)
      .accessibilityIdentifier("reel")
      .accessibilityAction { holding.toggle() }
    }
    .frame(width: 178, height: 178)
    .onChange(of: elapsed) { old, new in
      if holding && !reduceMotion { spoolAngle += max(0, new - old) * 80 }
    }
  }
}

struct SpecimenRuler: View {
  var body: some View {
    Canvas { context, size in
      for index in 0...40 {
        let x = size.width * Double(index) / 40
        var tick = Path()
        tick.move(to: CGPoint(x: x, y: 0))
        tick.addLine(to: CGPoint(x: x, y: index % 5 == 0 ? 10 : 4))
        context.stroke(
          tick, with: .color(Ink.night.opacity(index % 5 == 0 ? 0.55 : 0.25)), lineWidth: 0.7)
      }
    }
    .frame(height: 10)
    .accessibilityHidden(true)
  }
}
