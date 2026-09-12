import SwiftUI

enum Dream {
    static let ink = Color(red: 0.055, green: 0.058, blue: 0.13)
    static let velvet = Color(red: 0.15, green: 0.13, blue: 0.25)
    static let lavender = Color(red: 0.71, green: 0.65, blue: 0.85)
    static let peach = Color(red: 1, green: 0.73, blue: 0.61)
    static let cream = Color(red: 0.98, green: 0.91, blue: 0.8)
    static let mint = Color(red: 0.64, green: 0.96, blue: 0.91)
    static let muted = Color(red: 0.62, green: 0.61, blue: 0.73)
}

struct LaneProjection {
    let size: CGSize
    func scale(_ y: Double) -> Double { 1 / (1 + max(-0.5, y) * 0.22) }
    func point(_ x: Double, _ y: Double) -> CGPoint {
        let s = scale(y)
        return CGPoint(
            x: size.width * 0.5 + x * size.width * 0.4 * s,
            y: size.height * (0.84 - 0.86 * (1 - s)))
    }
}

struct LaneArtwork: View {
    @ObservedObject var model: GameModel
    var hero = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Canvas { context, size in
            let p = LaneProjection(size: size)
            let full = CGRect(origin: .zero, size: size)
            context.fill(
                Path(full),
                with: .linearGradient(
                    Gradient(colors: [Dream.ink, Dream.velvet, Dream.ink]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            let glow = CGRect(
                x: size.width * 0.12, y: size.height * 0.18,
                width: size.width * 0.76, height: size.width * 0.76)
            context.fill(
                Path(ellipseIn: glow),
                with: .radialGradient(
                    Gradient(colors: [Dream.lavender.opacity(0.22), .clear]),
                    center: CGPoint(x: glow.midX, y: glow.midY), startRadius: 0, endRadius: glow.width / 2))
            for index in 0..<30 {
                let x = Double((index * 73 + 17) % 101) / 101 * size.width
                let y = Double((index * 37 + 11) % 101) / 101 * size.height * 0.44
                let r = index % 4 == 0 ? 1.5 : 0.7
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color(Dream.cream.opacity(0.35)))
            }
            for depth in [10.0, 7.7, 5.0, 1.2] {
                arch(
                    &context, p: p, y: depth, center: 0, width: 2.65,
                    color: depth == 5 ? Dream.peach.opacity(0.68) : Dream.lavender.opacity(0.32),
                    solid: false)
            }
            let floor = polygon([p.point(-1, 0), p.point(-1, 9.2), p.point(1, 9.2), p.point(1, 0)])
            context.fill(
                floor,
                with: .linearGradient(
                    Gradient(colors: [Dream.lavender.opacity(0.5), Dream.lavender.opacity(0.9), Dream.velvet]),
                    startPoint: p.point(0, 9), endPoint: p.point(0, -0.2)))
            for x in [-0.96, -0.75, -0.50, -0.25, 0, 0.25, 0.50, 0.75, 0.96] {
                line(
                    &context, from: p.point(x, 0), to: p.point(x, 9),
                    color: Dream.cream.opacity(x == -0.96 || x == 0.96 ? 0.65 : 0.12), width: 1)
            }
            for y in stride(from: 0.5, through: 9.0, by: 0.7) {
                line(
                    &context, from: p.point(-1, y), to: p.point(1, y),
                    color: Dream.ink.opacity(0.15), width: 0.8)
            }
            for i in 0..<310 {
                let x = Double((i * 71 + 23) % 997) / 997 * 1.9 - 0.95
                let y = Double((i * 193 + 17) % 991) / 991 * 9
                let point = p.point(x, y)
                let radius = Double(i % 3 + 1) * p.scale(y)
                let chip = polygon([
                    point, CGPoint(x: point.x + radius * 2, y: point.y + radius),
                    CGPoint(x: point.x - radius, y: point.y + radius * 2),
                ])
                context.fill(chip, with: .color((i % 3 == 0 ? Dream.peach : Dream.ink).opacity(0.24)))
            }
            for side in [-1.0, 1.0] {
                let rail = polygon([
                    p.point(side * 1.02, 0), p.point(side * 1.02, 9.2),
                    p.point(side * 1.15, 9.2), p.point(side * 1.15, 0),
                ])
                context.fill(
                    rail,
                    with: .linearGradient(
                        Gradient(colors: [Dream.ink, Dream.lavender, Dream.ink]),
                        startPoint: p.point(side * 1.02, 0), endPoint: p.point(side * 1.15, 0)))
                line(
                    &context, from: p.point(side * 1.03, 0), to: p.point(side * 1.03, 9.2),
                    color: model.lane.bumper || hero ? Dream.mint.opacity(0.8) : Dream.peach.opacity(0.8), width: 2)
                for y in [1.0, 3.0, 5.0, 7.0] {
                    let spot = p.point(side * 1.20, y)
                    context.fill(
                        Path(ellipseIn: CGRect(x: spot.x - 3, y: spot.y - 2, width: 6, height: 4)),
                        with: .color(Dream.peach))
                }
            }
            for x in [-0.48, -0.24, 0, 0.24, 0.48] {
                let q = p.point(x, 2)
                context.fill(
                    polygon([
                        CGPoint(x: q.x, y: q.y - 5), CGPoint(x: q.x - 3, y: q.y + 3),
                        CGPoint(x: q.x + 3, y: q.y + 3),
                    ]), with: .color(Dream.cream.opacity(0.75)))
            }
            let pins = hero ? BowlingPhysics.rack() : model.physics.pins
            for pin in pins.sorted(by: { $0.y > $1.y }) { drawPin(&context, p: p, pin: pin) }
            for gate in model.lane.gates.sorted(by: { $0.y > $1.y }) where !hero {
                let opening = gate.opening(at: model.time)
                arch(
                    &context, p: p, y: gate.y, center: (opening.lowerBound + opening.upperBound) / 2,
                    width: gate.width, color: Dream.peach, solid: true)
            }
            if model.phase == "ready" && !hero {
                var path = Path()
                let vx = model.aim * 1.7
                let vy = 3.5 + model.power * 3
                for i in 0..<26 {
                    let t = Double(i) / 26 * 0.75
                    let q = p.point(vx * t + model.curve * 0.26 * t * t, 0.35 + vy * t)
                    if i == 0 { path.move(to: q) } else { path.addLine(to: q) }
                }
                context.stroke(
                    path, with: .color(Dream.mint.opacity(0.7)),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 7]))
            }
            if !reduceMotion && !hero {
                for (i, item) in model.physics.trail.enumerated() {
                    let q = p.point(item.0, item.1)
                    let r = 10 * p.scale(item.1)
                    context.fill(
                        Path(ellipseIn: CGRect(x: q.x - r, y: q.y - r, width: r * 2, height: r)),
                        with: .color(Dream.mint.opacity(Double(i) / 120)))
                }
            }
            let ball = hero ? Ball(x: 0.15, y: 1.1) : model.physics.ball
            if ball.y < 10 {
                let q = p.point(ball.x, ball.y)
                let r = size.width * 0.065 * p.scale(ball.y)
                let reflection = CGRect(x: q.x - r, y: q.y + 2, width: r * 2, height: r * 1.4)
                context.fill(
                    Path(ellipseIn: reflection),
                    with: .linearGradient(
                        Gradient(colors: [Dream.mint.opacity(0.25), .clear]),
                        startPoint: q, endPoint: CGPoint(x: q.x, y: q.y + r * 1.5)))
                context.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: q.x - r * 1.6, y: q.y - r * 1.5,
                            width: r * 3.2, height: r * 3.2)),
                    with: .radialGradient(
                        Gradient(colors: [Dream.mint.opacity(0.22), .clear]),
                        center: q, startRadius: 0, endRadius: r * 1.6))
                let rect = CGRect(x: q.x - r, y: q.y - r * 1.45, width: r * 2, height: r * 2)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        Gradient(colors: [
                            Dream.cream, Dream.mint, Color(red: 0.12, green: 0.48, blue: 0.54), Dream.ink,
                        ]),
                        center: CGPoint(x: q.x - r * 0.4, y: q.y - r * 0.9), startRadius: 0, endRadius: r * 2))
                for offset in [CGPoint(x: -0.20, y: -0.75), CGPoint(x: 0.18, y: -0.62), CGPoint(x: -0.1, y: -0.32)] {
                    context.fill(
                        Path(
                            ellipseIn: CGRect(
                                x: q.x + offset.x * r, y: q.y + offset.y * r,
                                width: r * 0.18, height: r * 0.24)),
                        with: .color(Dream.ink.opacity(0.8)))
                }
            }
            if model.phase == "settling" && !reduceMotion {
                for i in 0..<26 {
                    let angle = Double(i) * 2.4
                    let radius = 20 + Double(i % 8) * 13
                    let center = p.point(0, 7.4)
                    let q = CGPoint(
                        x: center.x + cos(angle + model.time) * radius,
                        y: center.y + sin(angle) * radius * 0.65)
                    context.fill(
                        Path(ellipseIn: CGRect(x: q.x, y: q.y, width: 2, height: 3)),
                        with: .color(Dream.cream.opacity(0.7)))
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func drawPin(_ context: inout GraphicsContext, p: LaneProjection, pin: Pin) {
        let point = p.point(pin.x, pin.y)
        let s = p.scale(pin.y) * p.size.width / 390
        var local = context
        local.translateBy(x: point.x, y: point.y)
        local.scaleBy(x: s, y: s)
        local.fill(
            Path(ellipseIn: CGRect(x: -12, y: -1, width: 27, height: 9)),
            with: .color(Dream.ink.opacity(0.3)))
        if pin.down { local.rotate(by: .degrees((pin.vx < 0 ? -1 : 1) * pin.fall * 78)) }
        var shape = Path()
        shape.move(to: CGPoint(x: -9, y: 0))
        shape.addCurve(to: CGPoint(x: -6, y: -27), control1: CGPoint(x: -16, y: -13), control2: CGPoint(x: -7, y: -18))
        shape.addCurve(to: CGPoint(x: -7, y: -39), control1: CGPoint(x: -5, y: -31), control2: CGPoint(x: -8, y: -34))
        shape.addCurve(to: CGPoint(x: 7, y: -39), control1: CGPoint(x: -7, y: -50), control2: CGPoint(x: 7, y: -50))
        shape.addCurve(to: CGPoint(x: 6, y: -27), control1: CGPoint(x: 8, y: -34), control2: CGPoint(x: 5, y: -31))
        shape.addCurve(to: CGPoint(x: 9, y: 0), control1: CGPoint(x: 7, y: -18), control2: CGPoint(x: 16, y: -13))
        shape.closeSubpath()
        local.fill(
            shape,
            with: .linearGradient(
                Gradient(colors: [Dream.lavender, Dream.cream, .white, Dream.lavender]),
                startPoint: CGPoint(x: -12, y: 0), endPoint: CGPoint(x: 14, y: 0)))
        local.fill(Path(CGRect(x: -6, y: -30, width: 12, height: 3)), with: .color(Dream.peach))
        local.fill(Path(CGRect(x: -6, y: -35, width: 12, height: 2)), with: .color(Dream.peach))
    }

    private func arch(
        _ context: inout GraphicsContext, p: LaneProjection, y: Double,
        center: Double, width: Double, color: Color, solid: Bool
    ) {
        let left = p.point(center - width / 2, y)
        let right = p.point(center + width / 2, y)
        let height = (right.x - left.x) * 1.3
        let top = left.y - height
        var path = Path()
        path.move(to: left)
        path.addLine(to: CGPoint(x: left.x, y: top + (right.x - left.x) / 2))
        path.addCurve(
            to: CGPoint(x: right.x, y: top + (right.x - left.x) / 2),
            control1: CGPoint(x: left.x, y: top - height * 0.12),
            control2: CGPoint(x: right.x, y: top - height * 0.12))
        path.addLine(to: right)
        context.stroke(
            path, with: .color(Dream.ink.opacity(0.4)),
            style: StrokeStyle(lineWidth: solid ? 16 : 12, lineCap: .round))
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [color, Dream.cream.opacity(0.8), color]),
                startPoint: left, endPoint: right),
            style: StrokeStyle(lineWidth: solid ? 9 : 4, lineCap: .round))
        if solid {
            for side in [-1.0, 1.0] {
                let outside = p.point(side, y)
                let inside = side < 0 ? left : right
                line(&context, from: outside, to: inside, color: color.opacity(0.8), width: 8)
            }
        }
    }

    private func polygon(_ points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
            path.closeSubpath()
        }
    }

    private func line(_ context: inout GraphicsContext, from: CGPoint, to: CGPoint, color: Color, width: Double) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(path, with: .color(color), lineWidth: width)
    }
}
