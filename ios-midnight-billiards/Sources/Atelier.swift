import SwiftUI

/// Shared material language: brass, walnut, lamp light and deco framing.
enum Brass {
    static let light = Color(red: 0.96, green: 0.85, blue: 0.60)
    static let mid = Color(red: 0.84, green: 0.70, blue: 0.45)
    static let deep = Color(red: 0.58, green: 0.43, blue: 0.22)
    static let walnut = Color(red: 0.30, green: 0.18, blue: 0.12)
    static let walnutDeep = Color(red: 0.14, green: 0.085, blue: 0.06)
    static let leather = Color(red: 0.16, green: 0.09, blue: 0.065)

    static var gradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: light, location: 0), .init(color: mid, location: 0.42),
                .init(color: deep, location: 0.8), .init(color: mid, location: 1),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var hairline: LinearGradient {
        LinearGradient(
            colors: [deep.opacity(0.2), light.opacity(0.9), deep.opacity(0.2)],
            startPoint: .leading, endPoint: .trailing)
    }
    static var walnutGradient: LinearGradient {
        LinearGradient(colors: [walnut, walnutDeep], startPoint: .top, endPoint: .bottom)
    }
}

/// Lamp-lit room behind every screen: a warm pool of light on a petrol night.
struct RoomBackdrop: View {
    var lampX = 0.5
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.10, blue: 0.13), Club.ink,
                    Color(red: 0.02, green: 0.04, blue: 0.055),
                ],
                startPoint: .top, endPoint: .bottom)
            GeometryReader { geometry in
                let size = geometry.size
                RadialGradient(
                    colors: [Color(red: 0.95, green: 0.78, blue: 0.48).opacity(0.17), .clear],
                    center: UnitPoint(x: lampX, y: -0.15), startRadius: 0, endRadius: size.width * 0.62)
                RadialGradient(
                    colors: [Club.teal.opacity(0.07), .clear], center: UnitPoint(x: 0.95, y: 1.05),
                    startRadius: 0, endRadius: size.width * 0.5)
                Canvas { context, canvasSize in
                    for index in 0..<19 {
                        let angle = (Double(index) - 9) * 0.06 - .pi / 2
                        var ray = Path()
                        let origin = CGPoint(x: canvasSize.width * lampX, y: -40)
                        ray.move(to: origin)
                        let length = canvasSize.height * 1.9
                        ray.addLine(
                            to: CGPoint(x: origin.x + cos(angle) * length, y: origin.y - sin(angle) * length))
                        context.stroke(ray, with: .color(Brass.light.opacity(0.022)), lineWidth: 5)
                    }
                }
                LinearGradient(
                    colors: [.clear, .black.opacity(0.35)], startPoint: .center, endPoint: .bottom)
            }
        }
        .ignoresSafeArea()
    }
}

/// Framed panel with double brass hairline and deco corner marks.
struct DecoFrame: ViewModifier {
    var radius = 18.0
    var strength = 1.0
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.085, green: 0.15, blue: 0.18), Club.panel, Club.ink],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius).strokeBorder(
                    LinearGradient(
                        colors: [Brass.light.opacity(0.7 * strength), Brass.deep.opacity(0.35 * strength)],
                        startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius - 4).strokeBorder(
                    Brass.mid.opacity(0.14 * strength), lineWidth: 1
                ).padding(4)
            )
            .overlay(CornerMarks().stroke(Brass.mid.opacity(0.75 * strength), lineWidth: 1).padding(9))
            .shadow(color: .black.opacity(0.5), radius: 22, y: 14)
    }
}

struct CornerMarks: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arm = 9.0
        for (x, dx) in [(rect.minX, 1.0), (rect.maxX, -1.0)] {
            for (y, dy) in [(rect.minY, 1.0), (rect.maxY, -1.0)] {
                path.move(to: CGPoint(x: x + dx * arm, y: y))
                path.addLine(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: y + dy * arm))
            }
        }
        return path
    }
}

extension View {
    func decoFrame(radius: Double = 18, strength: Double = 1) -> some View {
        modifier(DecoFrame(radius: radius, strength: strength))
    }
}

/// Small brass rule with a central diamond, used as a section divider.
struct BrassRule: View {
    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(Brass.hairline).frame(height: 1)
            Diamond().fill(Brass.mid).frame(width: 5, height: 7)
            Rectangle().fill(Brass.hairline).frame(height: 1)
        }
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

/// Segmented brass power gauge. Drag or tap anywhere along it.
struct PowerGauge: View {
    @Binding var power: Double
    var enabled = true
    private let segments = 24

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let step = width / Double(segments)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [.black.opacity(0.55), Club.ink.opacity(0.4)], startPoint: .top,
                            endPoint: .bottom))
                RoundedRectangle(cornerRadius: 6).strokeBorder(Brass.deep.opacity(0.45), lineWidth: 1)
                HStack(spacing: 0) {
                    ForEach(0..<segments, id: \.self) { index in
                        let fraction = Double(index + 1) / Double(segments)
                        let lit = fraction <= power + 0.001
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(
                                lit
                                    ? LinearGradient(
                                        colors: [
                                            segmentColor(fraction).opacity(0.95),
                                            segmentColor(fraction).opacity(0.6),
                                        ],
                                        startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(
                                        colors: [Club.ivory.opacity(0.07), Club.ivory.opacity(0.04)],
                                        startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: max(1, step - 2.4), height: 8 + fraction * 10)
                            .frame(width: step, height: 20, alignment: .bottom)
                    }
                }
                .padding(.horizontal, 3)
                .frame(height: 26, alignment: .bottom)
                Capsule()
                    .fill(Brass.gradient)
                    .frame(width: 5, height: 30)
                    .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                    .offset(x: min(max(power, 0.05), 1) * (width - 5))
            }
            .frame(height: 30)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { value in
                    guard enabled else { return }
                    power = min(1, max(0.05, value.location.x / width))
                })
        }
        .frame(height: 30)
        .opacity(enabled ? 1 : 0.55)
        .accessibilityElement()
        .accessibilityLabel("Shot power")
        .accessibilityValue("\(Int(power * 100)) percent")
        .accessibilityAdjustableAction { direction in
            let delta = direction == .increment ? 0.05 : -0.05
            power = min(1, max(0.05, power + delta))
        }
    }

    private func segmentColor(_ fraction: Double) -> Color {
        fraction < 0.5 ? Club.teal : fraction < 0.82 ? Brass.mid : Color(red: 1, green: 0.55, blue: 0.36)
    }
}

/// Cue-ball spin dial: a shaded ball with a chalk mark at the strike point.
struct SpinDial: View {
    let spin: Double
    var size = 40.0
    var body: some View {
        ZStack {
            Circle().fill(Club.ivory)
            Circle().fill(
                RadialGradient(
                    colors: [.white.opacity(0.7), .clear, .black.opacity(0.45)],
                    center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.75))
            Path { path in
                path.move(to: CGPoint(x: size / 2, y: size * 0.16))
                path.addLine(to: CGPoint(x: size / 2, y: size * 0.84))
            }.stroke(Club.ink.opacity(0.18), style: StrokeStyle(lineWidth: 0.8, dash: [2, 2]))
            Circle().stroke(Brass.mid.opacity(0.6), lineWidth: 1).padding(-3)
            Circle().fill(Club.teal).frame(width: size * 0.2, height: size * 0.2)
                .overlay(Circle().stroke(Club.ink.opacity(0.5), lineWidth: 0.8))
                .offset(y: -spin * size * 0.3)
                .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.4), radius: 3, y: 3)
    }
}

/// Gold gradient text for scores and headline numerals.
struct BrassText: View {
    let text: String
    var size = 30.0
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .regular, design: .serif))
            .monospacedDigit()
            .foregroundStyle(
                LinearGradient(
                    colors: [Brass.light, Brass.mid, Brass.deep], startPoint: .top, endPoint: .bottom)
            )
            .shadow(color: Brass.mid.opacity(0.35), radius: 8)
    }
}
