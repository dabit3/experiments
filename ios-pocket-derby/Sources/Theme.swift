import SwiftUI

enum Theme {
    static let ink = Color(hex: 0x06141E)
    static let cream = Color(hex: 0xF7F3E7)
    static let cyan = Color(hex: 0x5FE3FF)
    static let coral = Color(hex: 0xFF7A55)
    static let gold = Color(hex: 0xFFD166)
    static let muted = Color(hex: 0x93ADB7)
    static let panelTop = Color(hex: 0x17323F)
    static let panelBottom = Color(hex: 0x0B1F2B)

    static func display(_ size: CGFloat, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func label(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

/// Frosted night-glass panel with a lit top edge; the app's single surface style.
struct GlassPanel: ViewModifier {
    var radius: CGFloat = 26
    var tint: Color = .white
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [Theme.panelTop.opacity(0.96), Theme.panelBottom.opacity(0.96)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [tint.opacity(0.35), .white.opacity(0.04), tint.opacity(0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.38), radius: 26, y: 14)
    }
}

extension View {
    func glass(radius: CGFloat = 26, tint: Color = .white) -> some View {
        modifier(GlassPanel(radius: radius, tint: tint))
    }
}

/// Chunky arcade button: gradient face, lit rim, coloured drop glow, springy press.
struct ArcadeButtonStyle: ButtonStyle {
    var tint = Theme.cyan
    var primary = true
    var radius: CGFloat = 16
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(primary ? Theme.ink : Theme.cream)
            .background {
                if primary {
                    LinearGradient(
                        colors: [tint.mixed(.white, 0.28), tint, tint.mixed(.black, 0.12)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    Color.white.opacity(configuration.isPressed ? 0.14 : 0.08)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(primary ? 0.7 : 0.22), .white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: primary ? tint.opacity(0.45) : .black.opacity(0.25), radius: primary ? 14 : 8, y: 6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Brand motif: three tapered speed slashes.
struct SpeedLines: View {
    var color = Theme.cyan
    var height: CGFloat = 22
    var body: some View {
        HStack(spacing: height * 0.16) {
            ForEach(0 ..< 3, id: \.self) { index in
                Parallelogram()
                    .fill(color.opacity(1 - Double(index) * 0.3))
                    .frame(width: height * (0.42 - CGFloat(index) * 0.08), height: height)
            }
        }
        .accessibilityHidden(true)
    }
}

struct Parallelogram: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let skew = rect.height * 0.32
        path.move(to: CGPoint(x: rect.minX + skew, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - skew, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Small circular team crest used across scoreboard and results.
struct TeamCrest: View {
    var color: Color
    var number: String
    var size: CGFloat = 26
    var body: some View {
        ZStack {
            Circle().fill(
                LinearGradient(
                    colors: [color.mixed(.white, 0.25), color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1)
            Text(number).font(.system(size: size * 0.36, weight: .black, design: .rounded)).foregroundStyle(Theme.ink)
        }
        .frame(width: size, height: size)
        .shadow(color: color.opacity(0.5), radius: 6, y: 2)
    }
}

/// Night skyline behind the rooftop: gradient sky, moon, stars and two layers of lit towers.
struct CityBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0x081328), location: 0),
                    .init(color: Color(hex: 0x0F3448), location: 0.55),
                    .init(color: Color(hex: 0x0A1F2C), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            Canvas { context, size in
                var seed: UInt32 = 9137
                func random() -> CGFloat {
                    seed = seed &* 1_664_525 &+ 1_013_904_223
                    return CGFloat(seed >> 8) / CGFloat(1 << 24)
                }
                for _ in 0 ..< 90 {
                    let point = CGPoint(x: random() * size.width, y: random() * size.height * 0.55)
                    let radius = 0.5 + random() * 1.1
                    context.fill(
                        Path(ellipseIn: CGRect(x: point.x, y: point.y, width: radius * 2, height: radius * 2)),
                        with: .color(.white.opacity(0.25 + random() * 0.5))
                    )
                }
                let moon = CGPoint(x: size.width * 0.385, y: size.height * 0.085)
                context.fill(
                    Path(ellipseIn: CGRect(x: moon.x - 120, y: moon.y - 120, width: 240, height: 240)),
                    with: .radialGradient(
                        Gradient(colors: [Color(hex: 0xBFEFFF).opacity(0.22), .clear]),
                        center: moon, startRadius: 0, endRadius: 120
                    )
                )
                context.fill(
                    Path(ellipseIn: CGRect(x: moon.x - 11, y: moon.y - 11, width: 22, height: 22)),
                    with: .color(Color(hex: 0xEAF8FF).opacity(0.75))
                )
                for layer in 0 ..< 2 {
                    let base = size.height * (layer == 0 ? 0.66 : 0.78)
                    let fill = layer == 0 ? Color(hex: 0x0C2634).opacity(0.85) : Color(hex: 0x071A25)
                    var x: CGFloat = -20
                    while x < size.width + 40 {
                        let width = 34 + random() * 70
                        let height = 24 + random() * (layer == 0 ? 96 : 60)
                        let rect = CGRect(x: x, y: base - height, width: width, height: size.height - base + height)
                        context.fill(Path(rect), with: .color(fill))
                        if random() > 0.6 {
                            let cap = CGRect(x: rect.midX - 2, y: rect.minY - 14, width: 4, height: 14)
                            context.fill(Path(cap), with: .color(fill))
                        }
                        var wy = rect.minY + 10
                        while wy < base + 8 {
                            var wx = rect.minX + 7
                            while wx < rect.maxX - 8 {
                                if random() > 0.55 {
                                    let warm = random() > 0.35
                                    context.fill(
                                        Path(CGRect(x: wx, y: wy, width: 4, height: 6)),
                                        with: .color((warm ? Color(hex: 0xFFD89A) : Color(hex: 0x9CEBFF))
                                            .opacity(layer == 0 ? 0.42 : 0.22))
                                    )
                                }
                                wx += 11
                            }
                            wy += 13
                        }
                        x += width + 6 + random() * 12
                    }
                }
                context.fill(
                    Path(CGRect(x: 0, y: size.height * 0.5, width: size.width, height: size.height * 0.5)),
                    with: .linearGradient(
                        Gradient(colors: [.clear, Color(hex: 0x061520).opacity(0.85)]),
                        startPoint: CGPoint(x: 0, y: size.height * 0.5), endPoint: CGPoint(x: 0, y: size.height)
                    )
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension Color {
    func mixed(_ other: Color, _ amount: CGFloat) -> Color {
        Color(uiColor: UIColor(self).mixed(with: UIColor(other), amount))
    }
}
