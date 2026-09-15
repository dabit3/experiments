import SwiftUI

enum FestivalPalette {
    static let ink = Color(red: 0.15, green: 0.14, blue: 0.21)
    static let coral = Color(red: 0.98, green: 0.29, blue: 0.26)
    static let blue = Color(red: 0.20, green: 0.73, blue: 0.80)
    static let cream = Color(red: 1, green: 0.96, blue: 0.83)
    static let gold = Color(red: 1, green: 0.78, blue: 0.25)
    static let mint = Color(red: 0.69, green: 0.88, blue: 0.79)
}

enum FestivalArt {
    static func ellipse(_ context: GraphicsContext, x: Double, y: Double, width: Double, height: Double, color: Color, line: Double = 0) {
        let path = Path(ellipseIn: CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height))
        context.fill(path, with: .color(color))
        if line > 0 { context.stroke(path, with: .color(FestivalPalette.ink), lineWidth: line) }
    }

    static func box(_ context: GraphicsContext, _ rect: CGRect, color: Color, radius: Double = 0, line: Double = 0) {
        let path = Path(roundedRect: rect, cornerRadius: radius)
        context.fill(path, with: .color(color))
        if line > 0 { context.stroke(path, with: .color(FestivalPalette.ink), lineWidth: line) }
    }

    static func text(_ context: GraphicsContext, _ value: String, x: Double, y: Double, size: Double, color: Color = FestivalPalette.ink) {
        context.draw(Text(value).font(.system(size: size, weight: .black, design: .rounded)).foregroundStyle(color), at: CGPoint(x: x, y: y))
    }

    static func line(_ context: GraphicsContext, _ points: [CGPoint], color: Color, width: Double) {
        guard let first = points.first else { return }
        var path = Path()
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    static func face(_ context: GraphicsContext, x: Double, y: Double, radius: Double, blue: Bool, big: Bool = false, happy: Bool = true) {
        let ink = FestivalPalette.ink
        ellipse(context, x: x, y: y, width: radius * 2, height: radius * 2, color: FestivalPalette.cream, line: max(2, radius * 0.065))
        ellipse(context, x: x, y: y, width: radius * 1.63, height: radius * 1.63, color: blue ? FestivalPalette.blue : FestivalPalette.coral)
        let eyeY = y - radius * 0.17
        for side in [-1.0, 1.0] {
            let eyeX = x + side * radius * 0.27
            if big {
                line(context, [CGPoint(x: eyeX - radius * 0.10, y: eyeY - radius * 0.12),
                               CGPoint(x: eyeX + radius * 0.09, y: eyeY)], color: ink, width: max(2, radius * 0.09))
            } else {
                ellipse(context, x: eyeX, y: eyeY, width: radius * 0.14, height: radius * 0.21, color: ink)
            }
        }
        var mouth = Path()
        mouth.move(to: CGPoint(x: x - radius * 0.28, y: y + radius * 0.11))
        mouth.addQuadCurve(to: CGPoint(x: x + radius * 0.28, y: y + radius * 0.11),
                           control: CGPoint(x: x, y: y + radius * (happy ? 0.68 : 0.26)))
        if happy {
            mouth.closeSubpath()
            context.fill(mouth, with: .color(ink))
            ellipse(context, x: x, y: y + radius * 0.33, width: radius * 0.22, height: radius * 0.12, color: .pink)
        } else {
            context.stroke(mouth, with: .color(ink), lineWidth: max(2, radius * 0.06))
        }
    }

    static func mascot(_ context: GraphicsContext, x: Double, y: Double, scale: Double, blue: Bool, time: Double) {
        var ctx = context
        ctx.translateBy(x: x, y: y + sin(time * 5) * 4 * scale)
        ctx.scaleBy(x: scale, y: scale)
        let body = blue ? FestivalPalette.blue : FestivalPalette.coral
        ellipse(ctx, x: 8, y: 70, width: 150, height: 20, color: FestivalPalette.ink.opacity(0.12))
        for side in [-1.0, 1.0] {
            let bounce = sin(time * 5 + side) * 8
            line(ctx, [CGPoint(x: side * 36, y: 38), CGPoint(x: side * 51, y: 63 - bounce)],
                 color: FestivalPalette.ink, width: 19)
            line(ctx, [CGPoint(x: side * 36, y: 38), CGPoint(x: side * 51, y: 63 - bounce)],
                 color: FestivalPalette.cream, width: 12)
            line(ctx, [CGPoint(x: side * 52, y: 0), CGPoint(x: side * 84, y: -15 + bounce)],
                 color: FestivalPalette.ink, width: 18)
            line(ctx, [CGPoint(x: side * 52, y: 0), CGPoint(x: side * 84, y: -15 + bounce)],
                 color: FestivalPalette.cream, width: 11)
        }
        ellipse(ctx, x: 17, y: 10, width: 127, height: 108, color: body.opacity(0.8), line: 4)
        face(ctx, x: -4, y: 0, radius: 59, blue: blue)
        box(ctx, CGRect(x: -62, y: -42, width: 117, height: 12), color: FestivalPalette.cream, radius: 4, line: 2)
        for x in stride(from: -54.0, through: 43.0, by: 19) {
            line(ctx, [CGPoint(x: x, y: -41), CGPoint(x: x + 10, y: -31)], color: blue ? FestivalPalette.blue : FestivalPalette.coral, width: 7)
        }
        ellipse(ctx, x: 55, y: -36, width: 20, height: 19, color: FestivalPalette.gold, line: 2)
        line(ctx, [CGPoint(x: 61, y: -31), CGPoint(x: 79, y: -11), CGPoint(x: 66, y: -16)],
             color: FestivalPalette.cream, width: 9)
    }

    static func flower(_ context: GraphicsContext, x: Double, y: Double, radius: Double, color: Color) {
        for petal in 0..<5 {
            let angle = Double(petal) * .pi * 2 / 5
            ellipse(context, x: x + cos(angle) * radius * 0.5, y: y + sin(angle) * radius * 0.5,
                    width: radius, height: radius, color: color)
        }
        ellipse(context, x: x, y: y, width: radius * 0.4, height: radius * 0.4, color: FestivalPalette.gold)
    }

    static func background(_ context: GraphicsContext, time: Double, night: Bool = false) {
        box(context, CGRect(x: 0, y: 0, width: 1000, height: 460), color: night ? Color(red: 0.20, green: 0.23, blue: 0.40) : FestivalPalette.mint)
        for row in 0..<7 {
            for col in 0..<16 {
                let x = Double(col) * 76 + (row % 2 == 0 ? 0 : 38)
                let y = Double(row) * 76
                for radius in [12.0, 23.0, 34.0] {
                    let path = Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    context.stroke(path, with: .color(.white.opacity(night ? 0.06 : 0.22)), lineWidth: 2)
                }
            }
        }
        var mountain = Path()
        mountain.move(to: CGPoint(x: 650, y: 460))
        mountain.addLine(to: CGPoint(x: 815, y: 275))
        mountain.addLine(to: CGPoint(x: 990, y: 460))
        mountain.closeSubpath()
        context.fill(mountain, with: .color(FestivalPalette.blue.opacity(0.18)))
        for index in 0..<7 {
            let x = Double(index) * 170 + 35
            let y = 360 + sin(Double(index)) * 55
            flower(context, x: x, y: y, radius: 18, color: .white.opacity(0.45))
        }
        line(context, [CGPoint(x: 0, y: 16), CGPoint(x: 250, y: 41), CGPoint(x: 500, y: 21),
                       CGPoint(x: 750, y: 41), CGPoint(x: 1000, y: 16)], color: FestivalPalette.ink.opacity(0.6), width: 2)
        for index in 0..<15 {
            let x = Double(index) * 74
            let y = 25 + sin(Double(index) / 2) * 9
            var pennant = Path()
            pennant.move(to: CGPoint(x: x, y: y))
            pennant.addLine(to: CGPoint(x: x + 32, y: y + 2))
            pennant.addLine(to: CGPoint(x: x + 15, y: y + 30))
            pennant.closeSubpath()
            context.fill(pennant, with: .color(index % 2 == 0 ? FestivalPalette.coral : FestivalPalette.cream))
        }
        for x in [25.0, 975.0] {
            line(context, [CGPoint(x: x, y: 0), CGPoint(x: x, y: 84)], color: FestivalPalette.ink, width: 2)
            ellipse(context, x: x, y: 100, width: 35, height: 51, color: FestivalPalette.coral, line: 2)
            for shift in [-12.0, 0.0, 12.0] {
                line(context, [CGPoint(x: x - 15, y: 100 + shift), CGPoint(x: x + 15, y: 100 + shift)], color: FestivalPalette.ink.opacity(0.22), width: 2)
            }
            text(context, "祭", x: x, y: 100, size: 23, color: FestivalPalette.cream)
        }
    }

    static func drum(_ context: GraphicsContext, x: Double, y: Double, flash: Double, kind: String, time: Double) {
        let active = time - flash < 0.13
        let scale = active ? 0.96 : 1.0
        var ctx = context
        ctx.translateBy(x: x, y: y)
        ctx.scaleBy(x: scale, y: scale)
        ellipse(ctx, x: 0, y: 67, width: 175, height: 24, color: FestivalPalette.ink.opacity(0.15))
        ellipse(ctx, x: 0, y: 14, width: 171, height: 145, color: Color(red: 0.69, green: 0.24, blue: 0.19), line: 4)
        ellipse(ctx, x: 0, y: 0, width: 176, height: 145, color: active && kind == "ka" ? .white : FestivalPalette.blue, line: 4)
        ellipse(ctx, x: 0, y: 0, width: 137, height: 112, color: active && kind == "don" ? FestivalPalette.gold : FestivalPalette.cream, line: 3)
        for index in 0..<12 {
            let angle = Double(index) / 12 * .pi * 2
            ellipse(ctx, x: cos(angle) * 78, y: sin(angle) * 63, width: 4, height: 4, color: FestivalPalette.cream)
        }
        text(ctx, "ドン", x: 0, y: -10, size: 27, color: FestivalPalette.coral)
        text(ctx, "DON", x: 0, y: 21, size: 17)
        text(ctx, "KA", x: 0, y: -63, size: 12)
        if active {
            for index in 0..<7 {
                let angle = Double(index) * .pi * 2 / 7
                line(ctx, [CGPoint(x: cos(angle) * 89, y: sin(angle) * 79),
                           CGPoint(x: cos(angle) * 103, y: sin(angle) * 92)], color: FestivalPalette.gold, width: 4)
            }
        }
    }
}

struct FestivalBackdrop: View {
    var night = false
    var body: some View {
        Canvas { context, _ in FestivalArt.background(context, time: Date().timeIntervalSince1970, night: night) }
    }
}

struct MascotView: View {
    var blue = false
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            Canvas { context, size in
                FestivalArt.mascot(context, x: size.width / 2, y: size.height / 2,
                                   scale: min(size.width / 200, size.height / 160), blue: blue, time: timeline.date.timeIntervalSince1970)
            }
        }
        .accessibilityHidden(true)
    }
}
