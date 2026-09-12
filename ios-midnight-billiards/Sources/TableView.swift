import SwiftUI

enum Club {
    static let ink = Color(red: 0.035, green: 0.075, blue: 0.10)
    static let panel = Color(red: 0.065, green: 0.12, blue: 0.145)
    static let gold = Color(red: 0.84, green: 0.70, blue: 0.45)
    static let ivory = Color(red: 0.96, green: 0.94, blue: 0.86)
    static let muted = Color(red: 0.56, green: 0.67, blue: 0.69)
    static let teal = Color(red: 0.31, green: 0.78, blue: 0.74)
    static func ballColor(_ id: Int) -> Color {
        switch id > 8 ? id - 8 : id {
        case 1: return Color(red: 0.98, green: 0.73, blue: 0.18)
        case 2: return Color(red: 0.14, green: 0.43, blue: 0.82)
        case 3: return Color(red: 0.82, green: 0.19, blue: 0.21)
        case 4: return Color(red: 0.52, green: 0.28, blue: 0.72)
        case 5: return Color(red: 1.0, green: 0.42, blue: 0.14)
        case 6: return Color(red: 0.10, green: 0.55, blue: 0.42)
        case 7: return Color(red: 0.49, green: 0.16, blue: 0.23)
        case 8: return Color(red: 0.07, green: 0.09, blue: 0.13)
        default: return Club.ivory
        }
    }
}

struct TableView: View {
    let table: Table
    var angle = 0.0
    var power = 0.5
    var aiming = false
    var ballInHand = false
    var kitchen = false
    var calledPocket: Int?
    var requireCall = false
    var onTouch: ((Vector) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 660, geometry.size.height / 360)
            let offset = CGPoint(
                x: (geometry.size.width - 660 * scale) / 2,
                y: (geometry.size.height - 360 * scale) / 2)
            Canvas { context, _ in
                context.translateBy(x: offset.x, y: offset.y)
                context.scaleBy(x: scale, y: scale)
                drawTable(&context)
                context.translateBy(x: 30, y: 30)
                if kitchen && ballInHand {
                    context.fill(
                        Path(CGRect(x: 10, y: 10, width: 140, height: 280)),
                        with: .color(Club.gold.opacity(0.12)))
                }
                if aiming && !table.cue.pocketed { drawAim(&context) }
                for ball in table.balls where !ball.pocketed {
                    drawBall(&context, ball: ball)
                }
                if ballInHand {
                    let center = point(table.cue.position)
                    context.stroke(
                        Path(ellipseIn: CGRect(x: center.x - 16, y: center.y - 16, width: 32, height: 32)),
                        with: .color(Club.gold), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let location = Vector(
                            x: (value.location.x - offset.x) / scale - 30,
                            y: (value.location.y - offset.y) / scale - 30)
                        onTouch?(location)
                    }
            )
            .accessibilityLabel("Billiards table")
            .accessibilityValue(
                "\(table.balls.filter { !$0.pocketed && $0.id != 0 }.count) object balls. \(ballInHand ? "Ball in hand. Tap to place." : "Tap or drag to aim.")"
            )
            .accessibilityIdentifier("billiardsTable")
        }
        .aspectRatio(660 / 360, contentMode: .fit)
    }

    private func point(_ vector: Vector) -> CGPoint { CGPoint(x: vector.x, y: vector.y) }

    private func drawTable(_ context: inout GraphicsContext) {
        let outer = Path(roundedRect: CGRect(x: 1, y: 1, width: 658, height: 358), cornerRadius: 30)
        var railContext = context
        railContext.addFilter(.shadow(color: .black.opacity(0.55), radius: 10, x: 0, y: 8))
        railContext.fill(
            outer,
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.35, green: 0.22, blue: 0.15), Color(red: 0.15, green: 0.095, blue: 0.075),
                ]),
                startPoint: .zero, endPoint: CGPoint(x: 200, y: 360)))
        context.stroke(outer, with: .color(Club.gold.opacity(0.65)), lineWidth: 1)
        for inset in [6.0, 10.0, 14.0] {
            context.stroke(
                Path(
                    roundedRect: CGRect(x: inset, y: inset, width: 660 - inset * 2, height: 360 - inset * 2),
                    cornerRadius: 24),
                with: .color(.black.opacity(0.18)), lineWidth: 0.7)
        }
        context.fill(
            Path(roundedRect: CGRect(x: 23, y: 23, width: 614, height: 314), cornerRadius: 12),
            with: .color(Color(red: 0.035, green: 0.18, blue: 0.21)))
        context.fill(
            Path(CGRect(x: 30, y: 30, width: 600, height: 300)),
            with: .radialGradient(
                Gradient(colors: [
                    Color(red: 0.085, green: 0.34, blue: 0.38), Color(red: 0.035, green: 0.22, blue: 0.27),
                ]),
                center: CGPoint(x: 340, y: 160), startRadius: 30, endRadius: 380))
        for index in 0..<130 {
            let x = Double((index * 127) % 596) + 32
            let y = Double((index * 71) % 294) + 33
            context.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: 0.7, height: 0.7)),
                with: .color(.white.opacity(0.08)))
        }
        var headstring = Path()
        headstring.move(to: CGPoint(x: 180, y: 46))
        headstring.addLine(to: CGPoint(x: 180, y: 314))
        context.stroke(
            headstring, with: .color(.white.opacity(0.12)), style: StrokeStyle(lineWidth: 0.7, dash: [4, 5]))
        context.fill(
            Path(ellipseIn: CGRect(x: 178, y: 178, width: 4, height: 4)), with: .color(.white.opacity(0.3)))
        context.fill(
            Path(ellipseIn: CGRect(x: 455, y: 178, width: 4, height: 4)), with: .color(.white.opacity(0.25)))
        for x in [105.0, 180, 255, 405, 480, 555] {
            for y in [15.0, 345] { diamond(&context, at: CGPoint(x: x, y: y)) }
        }
        for y in [105.0, 180, 255] {
            for x in [15.0, 645] { diamond(&context, at: CGPoint(x: x, y: y)) }
        }
        for (index, pocket) in Table.pockets.enumerated() {
            let center = CGPoint(x: pocket.x + 30, y: pocket.y + 30)
            let rect = CGRect(x: center.x - 18, y: center.y - 18, width: 36, height: 36)
            context.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.045, green: 0.07, blue: 0.07)))
            context.stroke(Path(ellipseIn: rect), with: .color(Club.gold.opacity(0.6)), lineWidth: 2)
            context.fill(
                Path(ellipseIn: rect.insetBy(dx: 3, dy: 3)),
                with: .radialGradient(
                    Gradient(colors: [.black, Color(red: 0.025, green: 0.04, blue: 0.05)]),
                    center: center, startRadius: 4, endRadius: 15))
            if calledPocket == index {
                context.stroke(
                    Path(ellipseIn: rect.insetBy(dx: -5, dy: -5)), with: .color(Club.gold), lineWidth: 2.5)
            } else if requireCall {
                context.stroke(
                    Path(ellipseIn: rect.insetBy(dx: -4, dy: -4)), with: .color(Club.gold.opacity(0.7)),
                    style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        context.draw(
            Text("M I D N I G H T").font(.system(size: 8, weight: .medium, design: .serif)).foregroundColor(
                Club.gold.opacity(0.65)),
            at: CGPoint(x: 330, y: 346))
    }

    private func diamond(_ context: inout GraphicsContext, at center: CGPoint) {
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - 3))
        path.addLine(to: CGPoint(x: center.x + 2, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + 3))
        path.addLine(to: CGPoint(x: center.x - 2, y: center.y))
        path.closeSubpath()
        context.fill(path, with: .color(Club.gold.opacity(0.8)))
    }

    private func drawBall(_ context: inout GraphicsContext, ball: Ball) {
        let x = ball.position.x
        let y = ball.position.y
        let radius = Table.radius
        let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect.offsetBy(dx: 2, dy: 3)), with: .color(.black.opacity(0.33)))
        let base = ball.id > 8 ? Club.ivory : Club.ballColor(ball.id)
        context.fill(Path(ellipseIn: rect), with: .color(base))
        if ball.id > 8 {
            var stripe = context
            stripe.clip(to: Path(ellipseIn: rect))
            stripe.fill(
                Path(CGRect(x: x - radius, y: y - 4.8, width: radius * 2, height: 9.6)),
                with: .color(Club.ballColor(ball.id)))
        }
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: .white.opacity(0.48), location: 0),
                    .init(color: .white.opacity(0.03), location: 0.43),
                    .init(color: .black.opacity(0.50), location: 1),
                ]), center: CGPoint(x: x - 3, y: y - 4), startRadius: 0, endRadius: 17))
        if ball.id != 0 {
            context.fill(
                Path(ellipseIn: CGRect(x: x - 4.4, y: y - 4.4, width: 8.8, height: 8.8)),
                with: .color(Club.ivory))
            context.draw(
                Text("\(ball.id)").font(.system(size: ball.id > 9 ? 5.5 : 6.5, weight: .bold))
                    .foregroundColor(Club.ink),
                at: CGPoint(x: x, y: y + 0.2))
        } else {
            context.fill(
                Path(ellipseIn: CGRect(x: x - 3.8, y: y - 4.8, width: 4, height: 2)),
                with: .color(.white.opacity(0.7)))
        }
    }

    private func drawAim(_ context: inout GraphicsContext) {
        let trace = table.trace(angle: angle)
        let direction = Vector.direction(angle)
        let cue = table.cue.position
        var guide = Path()
        guide.move(to: point(cue + direction * 12))
        guide.addLine(to: point(trace.end))
        context.stroke(
            guide, with: .color(Club.ivory.opacity(0.55)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 5]))
        context.stroke(
            Path(ellipseIn: CGRect(x: trace.end.x - 8.5, y: trace.end.y - 8.5, width: 17, height: 17)),
            with: .color(Club.ivory.opacity(0.65)), lineWidth: 1)
        if let id = trace.ball, let ball = table.balls.first(where: { $0.id == id }),
            let outgoing = trace.outgoing
        {
            var path = Path()
            path.move(to: point(ball.position))
            path.addLine(to: point(ball.position + outgoing * 58))
            context.stroke(path, with: .color(Club.gold.opacity(0.8)), lineWidth: 1.5)
        } else if let bank = trace.bank {
            var path = Path()
            path.move(to: point(trace.end))
            path.addLine(to: point(trace.end + bank * 60))
            context.stroke(
                path, with: .color(Club.gold.opacity(0.55)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
        }
        var stick = Path()
        let start = cue - direction * (20 + power * 15)
        stick.move(to: point(start))
        stick.addLine(to: point(start - direction * 65))
        context.stroke(
            stick, with: .color(Color(red: 0.73, green: 0.51, blue: 0.29)),
            style: StrokeStyle(lineWidth: 4, lineCap: .round))
        var tip = Path()
        tip.move(to: point(start))
        tip.addLine(to: point(start - direction * 4))
        context.stroke(tip, with: .color(Club.teal), lineWidth: 4)
    }
}

struct BallBadge: View {
    let number: Int
    var size = 21.0
    var body: some View {
        ZStack {
            Circle().fill(number > 8 ? Club.ivory : Club.ballColor(number))
            if number > 8 {
                Rectangle().fill(Club.ballColor(number)).frame(height: size * 0.57).clipShape(Circle())
            }
            Circle().fill(
                RadialGradient(
                    colors: [.white.opacity(0.5), .clear, .black.opacity(0.5)], center: .topLeading,
                    startRadius: 0, endRadius: size))
            if number != 0 {
                Circle().fill(Club.ivory).frame(width: size * 0.52, height: size * 0.52)
                Text("\(number)").font(.system(size: size * 0.32, weight: .bold)).foregroundStyle(Club.ink)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
        .accessibilityLabel(number == 0 ? "Cue ball" : "Ball \(number)")
    }
}
