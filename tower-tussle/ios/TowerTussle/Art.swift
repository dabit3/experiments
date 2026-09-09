import SwiftUI

/// Original vector artwork for Tower Tussle: characters, towers, icons and
/// shared drawing helpers. Everything is drawn procedurally in a Canvas so the
/// game ships no external image assets.
enum Art {
    // MARK: Palette

    static let skin = Color(red: 0.99, green: 0.83, blue: 0.68)
    static let skinShade = Color(red: 0.86, green: 0.62, blue: 0.48)
    static let steel = Color(red: 0.78, green: 0.82, blue: 0.88)
    static let steelDark = Color(red: 0.42, green: 0.47, blue: 0.56)
    static let gold = Color(red: 1.0, green: 0.80, blue: 0.25)
    static let goldDark = Color(red: 0.72, green: 0.48, blue: 0.08)
    static let wood = Color(red: 0.62, green: 0.42, blue: 0.22)
    static let woodDark = Color(red: 0.38, green: 0.24, blue: 0.11)
    static let stoneLight = Color(red: 0.80, green: 0.80, blue: 0.78)
    static let stone = Color(red: 0.60, green: 0.61, blue: 0.62)
    static let stoneDark = Color(red: 0.36, green: 0.37, blue: 0.40)
    static let outline = Color(red: 0.10, green: 0.08, blue: 0.14)
    static let leaf = Color(red: 0.22, green: 0.50, blue: 0.20)
    static let leafDark = Color(red: 0.14, green: 0.36, blue: 0.14)
    static let bone = Color(red: 0.96, green: 0.95, blue: 0.88)
    static let goblin = Color(red: 0.42, green: 0.72, blue: 0.28)
    static let dragon = Color(red: 0.32, green: 0.68, blue: 0.62)
    static let dragonBelly = Color(red: 0.92, green: 0.86, blue: 0.55)
    static let fire = Color(red: 1.0, green: 0.55, blue: 0.12)
    static let fireCore = Color(red: 1.0, green: 0.92, blue: 0.55)

    static func team(_ side: Side) -> Color { side == .player ? Theme.player : Theme.enemy }
    static func teamDark(_ side: Side) -> Color {
        side == .player ? Color(red: 0.10, green: 0.28, blue: 0.62) : Color(red: 0.58, green: 0.10, blue: 0.14)
    }
    static func teamLight(_ side: Side) -> Color {
        side == .player ? Color(red: 0.55, green: 0.78, blue: 1.0) : Color(red: 1.0, green: 0.58, blue: 0.55)
    }

    // MARK: Helpers

    static func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x, y: y, width: w, height: h)
    }

    static func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
    }

    static func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
    }

    static func rounded(_ r: CGRect, _ radius: CGFloat) -> Path {
        Path(roundedRect: r, cornerRadius: radius)
    }

    static func polygon(_ pts: [CGPoint]) -> Path {
        var p = Path()
        guard let first = pts.first else { return p }
        p.move(to: first)
        for pt in pts.dropFirst() { p.addLine(to: pt) }
        p.closeSubpath()
        return p
    }

    static func vertical(_ top: Color, _ bottom: Color, _ frame: CGRect) -> GraphicsContext.Shading {
        .linearGradient(Gradient(colors: [top, bottom]), startPoint: CGPoint(x: frame.midX, y: frame.minY),
                        endPoint: CGPoint(x: frame.midX, y: frame.maxY))
    }

    static func horizontal(_ left: Color, _ right: Color, _ frame: CGRect) -> GraphicsContext.Shading {
        .linearGradient(Gradient(colors: [left, right]), startPoint: CGPoint(x: frame.minX, y: frame.midY),
                        endPoint: CGPoint(x: frame.maxX, y: frame.midY))
    }

    /// Filled + outlined shape, the signature "cartoon" look used everywhere.
    static func shape(_ ctx: inout GraphicsContext, _ path: Path, fill: GraphicsContext.Shading, line: CGFloat, strokeColor: Color = outline) {
        ctx.fill(path, with: fill)
        if line > 0 { ctx.stroke(path, with: .color(strokeColor), lineWidth: line) }
    }

    /// Ball with a radial highlight, used for heads, shoulders, orbs.
    static func ball(_ ctx: inout GraphicsContext, cx: CGFloat, cy: CGFloat, r: CGFloat, color: Color, dark: Color, line: CGFloat) {
        let path = circle(cx, cy, r)
        let shading = GraphicsContext.Shading.radialGradient(
            Gradient(colors: [color, dark]),
            center: CGPoint(x: cx - r * 0.35, y: cy - r * 0.35), startRadius: 0, endRadius: r * 1.5)
        shape(&ctx, path, fill: shading, line: line)
    }

    static func softShadow(_ ctx: inout GraphicsContext, cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, alpha: Double = 0.35) {
        let shading = GraphicsContext.Shading.radialGradient(
            Gradient(colors: [Color.black.opacity(alpha), Color.black.opacity(0)]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: max(rx, ry))
        var c = ctx
        c.translateBy(x: cx, y: cy)
        c.scaleBy(x: 1, y: ry / max(rx, 0.001))
        c.fill(circle(0, 0, rx), with: shading)
    }

    static func healthBar(_ ctx: inout GraphicsContext, center: CGPoint, width: CGFloat, height: CGFloat,
                          fraction: Double, side: Side, label: String? = nil) {
        let frame = rect(center.x - width / 2, center.y - height / 2, width, height)
        ctx.fill(rounded(frame.insetBy(dx: -1.5, dy: -1.5), height), with: .color(outline.opacity(0.85)))
        ctx.fill(rounded(frame, height / 2), with: .color(Color(white: 0.16)))
        let f = CGFloat(max(0, min(1, fraction)))
        if f > 0 {
            let fill = rect(frame.minX, frame.minY, max(height, frame.width * f), frame.height)
            let hue: Color = f > 0.5 ? Color(red: 0.36, green: 0.86, blue: 0.30) : (f > 0.25 ? Color(red: 0.98, green: 0.80, blue: 0.22) : Color(red: 0.95, green: 0.28, blue: 0.22))
            var c = ctx
            c.clip(to: rounded(frame, height / 2))
            c.fill(Path(fill), with: vertical(hue.opacity(1), hue.opacity(0.7), fill))
            c.fill(Path(rect(fill.minX, fill.minY, fill.width, fill.height * 0.4)), with: .color(.white.opacity(0.3)))
        }
        ctx.stroke(rounded(frame, height / 2), with: .color(team(side)), lineWidth: 1)
        if let label {
            ctx.draw(Text(label).font(.system(size: height * 0.95, weight: .heavy, design: .rounded)).foregroundColor(.white),
                     at: CGPoint(x: center.x, y: center.y))
        }
    }

    static func outlinedText(_ ctx: inout GraphicsContext, _ text: String, at p: CGPoint, size: CGFloat, color: Color, weight: Font.Weight = .black) {
        let font = Font.system(size: size, weight: weight, design: .rounded)
        let d: CGFloat = max(1, size * 0.08)
        for (dx, dy) in [(-d, 0), (d, 0), (0, -d), (0, d), (-d, -d), (d, d), (-d, d), (d, -d)] {
            ctx.draw(Text(text).font(font).foregroundColor(outline), at: CGPoint(x: p.x + dx, y: p.y + dy))
        }
        ctx.draw(Text(text).font(font).foregroundColor(color), at: p)
    }

    // MARK: Icons

    static func crown(_ ctx: inout GraphicsContext, center: CGPoint, size: CGFloat, color: Color = gold, dim: Bool = false, line: CGFloat? = nil) {
        let s = size / 2
        let lineWidth = line ?? max(1, size * 0.07)
        let pts = [
            CGPoint(x: center.x - s, y: center.y + s * 0.6),
            CGPoint(x: center.x - s, y: center.y - s * 0.35),
            CGPoint(x: center.x - s * 0.5, y: center.y + s * 0.05),
            CGPoint(x: center.x, y: center.y - s * 0.75),
            CGPoint(x: center.x + s * 0.5, y: center.y + s * 0.05),
            CGPoint(x: center.x + s, y: center.y - s * 0.35),
            CGPoint(x: center.x + s, y: center.y + s * 0.6),
        ]
        let path = polygon(pts)
        let frame = path.boundingRect
        let base = dim ? Color(white: 0.35) : color
        let dark = dim ? Color(white: 0.2) : goldDark
        shape(&ctx, path, fill: vertical(base, dark, frame), line: lineWidth)
        ctx.fill(Path(rect(center.x - s, center.y + s * 0.3, 2 * s, s * 0.3)), with: .color(dark.opacity(0.6)))
        if !dim {
            for (i, jx) in [-0.55, 0.0, 0.55].enumerated() {
                let jewel: Color = [Color(red: 0.95, green: 0.25, blue: 0.35), Color(red: 0.25, green: 0.55, blue: 1.0), Color(red: 0.3, green: 0.85, blue: 0.4)][i]
                ctx.fill(circle(center.x + CGFloat(jx) * s, center.y + s * 0.42, s * 0.12), with: .color(jewel))
            }
            ctx.fill(circle(center.x, center.y - s * 0.72, s * 0.14), with: .color(fireCore))
        }
    }

    static func elixirDrop(_ ctx: inout GraphicsContext, center: CGPoint, size: CGFloat) {
        let s = size / 2
        var p = Path()
        p.move(to: CGPoint(x: center.x, y: center.y - s))
        p.addCurve(to: CGPoint(x: center.x, y: center.y + s * 0.95),
                   control1: CGPoint(x: center.x + s * 1.15, y: center.y - s * 0.1),
                   control2: CGPoint(x: center.x + s * 0.95, y: center.y + s * 0.95))
        p.addCurve(to: CGPoint(x: center.x, y: center.y - s),
                   control1: CGPoint(x: center.x - s * 0.95, y: center.y + s * 0.95),
                   control2: CGPoint(x: center.x - s * 1.15, y: center.y - s * 0.1))
        p.closeSubpath()
        let light = Color(red: 0.93, green: 0.55, blue: 1.0)
        let dark = Color(red: 0.45, green: 0.10, blue: 0.62)
        shape(&ctx, p, fill: .radialGradient(Gradient(colors: [light, Theme.elixir, dark]),
                                            center: CGPoint(x: center.x - s * 0.3, y: center.y + s * 0.1), startRadius: 0, endRadius: s * 1.3),
              line: max(1, size * 0.07))
        ctx.fill(ellipse(center.x - s * 0.3, center.y + s * 0.15, s * 0.16, s * 0.3), with: .color(.white.opacity(0.75)))
    }

    static func trophy(_ ctx: inout GraphicsContext, center: CGPoint, size: CGFloat) {
        let s = size / 2
        let cup = polygon([
            CGPoint(x: center.x - s * 0.7, y: center.y - s * 0.9),
            CGPoint(x: center.x + s * 0.7, y: center.y - s * 0.9),
            CGPoint(x: center.x + s * 0.45, y: center.y + s * 0.15),
            CGPoint(x: center.x - s * 0.45, y: center.y + s * 0.15),
        ])
        shape(&ctx, cup, fill: horizontal(gold, goldDark, cup.boundingRect), line: max(1, size * 0.07))
        ctx.stroke(ellipse(center.x - s * 0.8, center.y - s * 0.45, s * 0.25, s * 0.35), with: .color(goldDark), lineWidth: max(1, size * 0.1))
        ctx.stroke(ellipse(center.x + s * 0.8, center.y - s * 0.45, s * 0.25, s * 0.35), with: .color(goldDark), lineWidth: max(1, size * 0.1))
        ctx.fill(Path(rect(center.x - s * 0.12, center.y + s * 0.15, s * 0.24, s * 0.35)), with: .color(goldDark))
        shape(&ctx, rounded(rect(center.x - s * 0.5, center.y + s * 0.5, s, s * 0.4), s * 0.1), fill: .color(woodDark), line: max(1, size * 0.06))
        ctx.fill(ellipse(center.x - s * 0.3, center.y - s * 0.55, s * 0.1, s * 0.22), with: .color(.white.opacity(0.7)))
    }

    static func coin(_ ctx: inout GraphicsContext, center: CGPoint, size: CGFloat) {
        let r = size / 2
        ball(&ctx, cx: center.x, cy: center.y, r: r, color: gold, dark: goldDark, line: max(1, size * 0.08))
        ctx.stroke(circle(center.x, center.y, r * 0.65), with: .color(goldDark.opacity(0.8)), lineWidth: max(1, size * 0.06))
        ctx.fill(ellipse(center.x - r * 0.35, center.y - r * 0.35, r * 0.14, r * 0.26), with: .color(.white.opacity(0.7)))
    }

    static func sword(_ ctx: inout GraphicsContext, from a: CGPoint, to b: CGPoint, width: CGFloat) {
        var blade = Path()
        blade.move(to: a)
        blade.addLine(to: b)
        ctx.stroke(blade, with: .color(outline), style: StrokeStyle(lineWidth: width * 1.9, lineCap: .round))
        ctx.stroke(blade, with: .color(steel), style: StrokeStyle(lineWidth: width, lineCap: .round))
        let dir = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let l = max(0.001, hypot(dir.x, dir.y))
        let n = CGPoint(x: -dir.y / l, y: dir.x / l)
        let g = CGPoint(x: a.x + dir.x * 0.22, y: a.y + dir.y * 0.22)
        var guardLine = Path()
        guardLine.move(to: CGPoint(x: g.x + n.x * width * 1.6, y: g.y + n.y * width * 1.6))
        guardLine.addLine(to: CGPoint(x: g.x - n.x * width * 1.6, y: g.y - n.y * width * 1.6))
        ctx.stroke(guardLine, with: .color(outline), style: StrokeStyle(lineWidth: width * 1.6, lineCap: .round))
        ctx.stroke(guardLine, with: .color(gold), style: StrokeStyle(lineWidth: width * 0.8, lineCap: .round))
    }

    // MARK: Characters

    struct Pose {
        var phase: Double = 0
        var facing: CGFloat = 1
        var attack: Double = 0
        var flash = false
        var time: Double = 0
        var moving = false
    }

    /// Draws a character whose feet stand at `foot`, with base body radius `r`.
    static func character(_ ctx: inout GraphicsContext, id: String, side: Side, foot: CGPoint, r: CGFloat, pose: Pose) {
        var c = ctx
        c.translateBy(x: foot.x, y: foot.y)
        c.scaleBy(x: r * pose.facing, y: r)
        let line: CGFloat = 0.14
        switch id {
        case "knight": knight(&c, side: side, pose: pose, line: line)
        case "archers": archer(&c, side: side, pose: pose, line: line)
        case "giant": colossus(&c, side: side, pose: pose, line: line)
        case "duelist": duelist(&c, side: side, pose: pose, line: line)
        case "sharpshooter": sharpshooter(&c, side: side, pose: pose, line: line)
        case "gremlins": gremlin(&c, side: side, pose: pose, line: line)
        case "bones": skeleton(&c, side: side, pose: pose, line: line)
        case "whelp": whelp(&c, side: side, pose: pose, line: line)
        default: knight(&c, side: side, pose: pose, line: line)
        }
        if pose.flash {
            var f = ctx
            f.blendMode = .plusLighter
            f.fill(circle(foot.x, foot.y - r * 1.4, r * 1.9), with: .color(.white.opacity(0.55)))
        }
    }

    private static func legs(_ c: inout GraphicsContext, pose: Pose, color: Color, line: CGFloat, spread: CGFloat = 0.45, length: CGFloat = 0.9) {
        let swing = pose.moving ? CGFloat(sin(pose.phase)) * 0.35 : 0
        for (i, side) in [-spread, spread].enumerated() {
            let dx = side + (i == 0 ? swing : -swing)
            let leg = rounded(rect(dx - 0.28, -length, 0.56, length), 0.25)
            shape(&c, leg, fill: .color(color), line: line)
            shape(&c, rounded(rect(dx - 0.36, -0.3, 0.72, 0.36), 0.15), fill: .color(outline), line: 0)
        }
    }

    private static func torso(_ c: inout GraphicsContext, side: Side, line: CGFloat, width: CGFloat = 1.5, height: CGFloat = 1.5, bottom: CGFloat = -0.6, colorOverride: Color? = nil, darkOverride: Color? = nil) {
        let body = rounded(rect(-width / 2, bottom - height, width, height), width * 0.35)
        let base = colorOverride ?? team(side)
        let dark = darkOverride ?? teamDark(side)
        shape(&c, body, fill: vertical(base, dark, body.boundingRect), line: line)
        c.fill(rounded(rect(-width / 2 + 0.15, bottom - height + 0.12, width * 0.35, height * 0.5), 0.2), with: .color(.white.opacity(0.18)))
    }

    private static func head(_ c: inout GraphicsContext, cy: CGFloat, r: CGFloat, color: Color = skin, dark: Color = skinShade, line: CGFloat, eyes: Bool = true, eyeColor: Color = outline) {
        ball(&c, cx: 0, cy: cy, r: r, color: color, dark: dark, line: line)
        if eyes {
            c.fill(circle(r * 0.35, cy + r * 0.05, r * 0.14), with: .color(eyeColor))
            c.fill(circle(r * 0.72, cy + r * 0.05, r * 0.14), with: .color(eyeColor))
        }
    }

    private static func arm(_ c: inout GraphicsContext, at p: CGPoint, r: CGFloat, color: Color, dark: Color, line: CGFloat) {
        ball(&c, cx: p.x, cy: p.y, r: r, color: color, dark: dark, line: line)
    }

    private static func knight(_ c: inout GraphicsContext, side: Side, pose: Pose, line: CGFloat) {
        let bob = pose.moving ? CGFloat(abs(sin(pose.phase))) * 0.08 : 0
        legs(&c, pose: pose, color: steelDark, line: line)
        c.translateBy(x: 0, y: -bob)
        torso(&c, side: side, line: line, width: 1.7, height: 1.5)
        // belt
        c.fill(Path(rect(-0.85, -1.05, 1.7, 0.22)), with: .color(woodDark))
        c.fill(circle(0, -0.94, 0.14), with: .color(gold))
        // shield on back arm
        let shield = ellipse(-0.95, -1.35, 0.55, 0.7)
        shape(&c, shield, fill: .radialGradient(Gradient(colors: [teamLight(side), team(side), teamDark(side)]), center: CGPoint(x: -1.1, y: -1.55), startRadius: 0, endRadius: 0.9), line: line)
        c.stroke(ellipse(-0.95, -1.35, 0.36, 0.48), with: .color(gold), lineWidth: 0.1)
        c.fill(circle(-0.95, -1.35, 0.12), with: .color(gold))
        // sword arm
        let swing = CGFloat(pose.attack) * 2.2
        arm(&c, at: CGPoint(x: 0.95, y: -1.35 + swing * 0.1), r: 0.34, color: steel, dark: steelDark, line: line)
        sword(&c, from: CGPoint(x: 1.0, y: -1.3), to: CGPoint(x: 1.35 + swing * 0.5, y: -2.75 + swing * 0.9), width: 0.16)
        // head + helmet
        head(&c, cy: -2.55, r: 0.62, line: line)
        let helm = polygon([CGPoint(x: -0.7, y: -2.5), CGPoint(x: -0.66, y: -2.9), CGPoint(x: 0, y: -3.35), CGPoint(x: 0.66, y: -2.9), CGPoint(x: 0.7, y: -2.5)])
        shape(&c, helm, fill: vertical(steel, steelDark, helm.boundingRect), line: line)
        c.fill(Path(rect(0.05, -3.1, 0.14, 0.75)), with: .color(steelDark))
        c.fill(Path(rect(-0.7, -2.6, 1.4, 0.16)), with: .color(steelDark))
        c.fill(polygon([CGPoint(x: 0, y: -3.35), CGPoint(x: -0.1, y: -3.75), CGPoint(x: 0.35, y: -3.85), CGPoint(x: 0.25, y: -3.3)]), with: .color(team(side)))
    }

    private static func archer(_ c: inout GraphicsContext, side: Side, pose: Pose, line: CGFloat) {
        let bob = pose.moving ? CGFloat(abs(sin(pose.phase))) * 0.08 : 0
        legs(&c, pose: pose, color: woodDark, line: line, spread: 0.38, length: 0.85)
        c.translateBy(x: 0, y: -bob)
        // quiver
        shape(&c, rounded(rect(-1.0, -2.4, 0.4, 1.3), 0.15), fill: .color(wood), line: line)
        for i in 0..<3 {
            c.fill(Path(rect(-0.95 + CGFloat(i) * 0.12, -2.75, 0.06, 0.4)), with: .color(bone))
        }
        torso(&c, side: side, line: line, width: 1.35, height: 1.4, colorOverride: leaf, darkOverride: leafDark)
        c.fill(Path(rect(-0.68, -1.0, 1.35, 0.2)), with: .color(team(side)))
        // bow
        let draw = CGFloat(pose.attack) * 1.5
        var bow = Path()
        bow.move(to: CGPoint(x: 1.05, y: -2.7))
        bow.addQuadCurve(to: CGPoint(x: 1.05, y: -0.7), control: CGPoint(x: 1.9, y: -1.7))
        c.stroke(bow, with: .color(outline), style: StrokeStyle(lineWidth: 0.3, lineCap: .round))
        c.stroke(bow, with: .color(wood), style: StrokeStyle(lineWidth: 0.14, lineCap: .round))
        var string = Path()
        string.move(to: CGPoint(x: 1.05, y: -2.7))
        string.addLine(to: CGPoint(x: 1.05 - draw * 0.4, y: -1.7))
        string.addLine(to: CGPoint(x: 1.05, y: -0.7))
        c.stroke(string, with: .color(bone), lineWidth: 0.05)
        arm(&c, at: CGPoint(x: 0.85, y: -1.5), r: 0.28, color: skin, dark: skinShade, line: line)
        // head + hood
        head(&c, cy: -2.45, r: 0.58, line: line)
        let hood = polygon([CGPoint(x: -0.7, y: -2.35), CGPoint(x: -0.75, y: -2.9), CGPoint(x: 0, y: -3.4), CGPoint(x: 0.6, y: -3.05), CGPoint(x: 0.66, y: -2.5), CGPoint(x: 0.35, y: -2.6), CGPoint(x: -0.2, y: -2.75)])
        shape(&c, hood, fill: vertical(leaf, leafDark, hood.boundingRect), line: line)
        c.fill(Path(rect(-0.2, -3.6, 0.08, 0.7)), with: .color(Color(red: 0.9, green: 0.3, blue: 0.3)))
    }

    private static func colossus(_ c: inout GraphicsContext, side: Side, pose: Pose, line: CGFloat) {
        let bob = pose.moving ? CGFloat(abs(sin(pose.phase))) * 0.1 : 0
        let step = pose.moving ? CGFloat(sin(pose.phase)) * 0.3 : 0
        for (i, x) in [-0.85, 0.85].enumerated() {
            let dx = CGFloat(x) + (i == 0 ? step : -step)
            shape(&c, rounded(rect(dx - 0.5, -1.2, 1.0, 1.2), 0.35), fill: vertical(stone, stoneDark, rect(dx - 0.5, -1.2, 1.0, 1.2)), line: line)
        }
        c.translateBy(x: 0, y: -bob)
        // massive body: irregular rock
        let body = polygon([
            CGPoint(x: -1.7, y: -1.0), CGPoint(x: -1.95, y: -2.3), CGPoint(x: -1.4, y: -3.5), CGPoint(x: -0.5, y: -4.1),
            CGPoint(x: 0.7, y: -4.15), CGPoint(x: 1.6, y: -3.4), CGPoint(x: 1.95, y: -2.2), CGPoint(x: 1.6, y: -1.0),
        ])
        shape(&c, body, fill: .radialGradient(Gradient(colors: [stoneLight, stone, stoneDark]), center: CGPoint(x: -0.6, y: -3.2), startRadius: 0.2, endRadius: 3.2), line: line * 1.2)
        // cracks
        var cracks = Path()
        cracks.move(to: CGPoint(x: -0.9, y: -1.4)); cracks.addLine(to: CGPoint(x: -0.4, y: -2.1)); cracks.addLine(to: CGPoint(x: -0.7, y: -2.6))
        cracks.move(to: CGPoint(x: 1.1, y: -3.1)); cracks.addLine(to: CGPoint(x: 0.8, y: -2.4))
        c.stroke(cracks, with: .color(stoneDark), style: StrokeStyle(lineWidth: 0.1, lineCap: .round))
        // team runes
        c.fill(circle(0, -2.0, 0.32), with: .color(team(side)))
        c.fill(circle(0, -2.0, 0.16), with: .color(teamLight(side)))
        // glowing eyes
        for x in [-0.55, 0.45] {
            c.fill(ellipse(CGFloat(x) + 0.35, -3.35, 0.3, 0.16), with: .color(outline))
            c.fill(ellipse(CGFloat(x) + 0.35, -3.35, 0.2, 0.09), with: .color(team(side)))
        }
        // brow ridge + fists
        c.fill(rounded(rect(-1.05, -3.75, 2.1, 0.25), 0.1), with: .color(stoneDark))
        let punch = CGFloat(pose.attack) * 1.4
        shape(&c, circle(-1.9, -1.55, 0.55), fill: vertical(stone, stoneDark, rect(-2.45, -2.1, 1.1, 1.1)), line: line)
        shape(&c, circle(2.0 + punch * 0.3, -1.55 - punch * 0.4, 0.55), fill: vertical(stone, stoneDark, rect(1.45, -2.1, 1.1, 1.1)), line: line)
    }

    private static func duelist(_ c: inout GraphicsContext, side: Side, pose: Pose, line: CGFloat) {
        let bob = pose.moving ? CGFloat(abs(sin(pose.phase))) * 0.09 : 0
        legs(&c, pose: pose, color: outline, line: line, spread: 0.4, length: 0.95)
        c.translateBy(x: 0, y: -bob)
        // cape
        let cape = polygon([CGPoint(x: -0.6, y: -2.3), CGPoint(x: 0.3, y: -2.3), CGPoint(x: -0.3, y: -0.35), CGPoint(x: -1.35, y: -0.5)])
        shape(&c, cape, fill: vertical(team(side), teamDark(side), cape.boundingRect), line: line)
        torso(&c, side: side, line: line, width: 1.35, height: 1.5, colorOverride: Color(white: 0.92), darkOverride: Color(white: 0.7))
        c.fill(Path(rect(-0.68, -1.0, 1.35, 0.2)), with: .color(gold))
        c.fill(Path(rect(-0.1, -2.1, 0.2, 1.05)), with: .color(team(side)))
        // rapier lunge
        let lunge = CGFloat(pose.attack) * 3
        arm(&c, at: CGPoint(x: 0.8 + lunge * 0.15, y: -1.75), r: 0.28, color: skin, dark: skinShade, line: line)
        var blade = Path()
        blade.move(to: CGPoint(x: 0.9 + lunge * 0.15, y: -1.75))
        blade.addLine(to: CGPoint(x: 2.6 + lunge * 0.6, y: -1.8 - lunge * 0.05))
        c.stroke(blade, with: .color(outline), style: StrokeStyle(lineWidth: 0.22, lineCap: .round))
        c.stroke(blade, with: .color(steel), style: StrokeStyle(lineWidth: 0.09, lineCap: .round))
        c.fill(circle(1.15 + lunge * 0.15, -1.75, 0.16), with: .color(gold))
        // head + plumed helmet
        head(&c, cy: -2.5, r: 0.58, line: line)
        let helm = polygon([CGPoint(x: -0.66, y: -2.55), CGPoint(x: -0.6, y: -3.05), CGPoint(x: 0, y: -3.3), CGPoint(x: 0.6, y: -3.05), CGPoint(x: 0.66, y: -2.55)])
        shape(&c, helm, fill: vertical(steel, steelDark, helm.boundingRect), line: line)
        c.fill(Path(rect(-0.66, -2.62, 1.32, 0.12)), with: .color(steelDark))
        var plume = Path()
        plume.move(to: CGPoint(x: 0, y: -3.3))
        plume.addQuadCurve(to: CGPoint(x: -1.2, y: -3.3), control: CGPoint(x: -0.4, y: -4.2))
        plume.addQuadCurve(to: CGPoint(x: 0, y: -3.3), control: CGPoint(x: -0.5, y: -3.5))
        shape(&c, plume, fill: .color(Color(red: 0.9, green: 0.2, blue: 0.3)), line: line * 0.8)
    }

    private static func sharpshooter(_ c: inout GraphicsContext, side: Side, pose: Pose, line: CGFloat) {
        let bob = pose.moving ? CGFloat(abs(sin(pose.phase))) * 0.08 : 0
        legs(&c, pose: pose, color: woodDark, line: line, spread: 0.4, length: 0.9)
        c.translateBy(x: 0, y: -bob)
        torso(&c, side: side, line: line, width: 1.45, height: 1.5, colorOverride: Color(red: 0.36, green: 0.22, blue: 0.16), darkOverride: Color(red: 0.2, green: 0.12, blue: 0.08))
        c.fill(Path(rect(-0.7, -1.0, 1.4, 0.2)), with: .color(team(side)))
        c.fill(Path(rect(-0.4, -2.1, 0.8, 0.55)), with: .color(team(side)))
        // long rifle
        let recoil = CGFloat(pose.attack) * 1.2
        var barrel = Path()
        barrel.move(to: CGPoint(x: -0.5 - recoil * 0.2, y: -1.55))
        barrel.addLine(to: CGPoint(x: 2.5 - recoil * 0.2, y: -1.75))
        c.stroke(barrel, with: .color(outline), style: StrokeStyle(lineWidth: 0.34, lineCap: .round))
        c.stroke(barrel, with: .color(steelDark), style: StrokeStyle(lineWidth: 0.16, lineCap: .round))
        shape(&c, rounded(rect(-0.8 - recoil * 0.2, -1.65, 1.2, 0.3), 0.1), fill: .color(wood), line: line * 0.8)
        arm(&c, at: CGPoint(x: 0.85 - recoil * 0.2, y: -1.6), r: 0.27, color: skin, dark: skinShade, line: line)
        if pose.attack > 0.15 {
            c.fill(circle(2.65, -1.78, 0.28 + recoil * 0.1), with: .color(fireCore.opacity(0.9)))
        }
        head(&c, cy: -2.5, r: 0.58, line: line)
        // wide-brim hat
        let brim = ellipse(0.05, -2.9, 1.05, 0.28)
        shape(&c, brim, fill: .color(Color(red: 0.25, green: 0.15, blue: 0.1)), line: line)
        let top = rounded(rect(-0.5, -3.65, 1.0, 0.85), 0.2)
        shape(&c, top, fill: vertical(Color(red: 0.36, green: 0.22, blue: 0.16), Color(red: 0.22, green: 0.12, blue: 0.08), top.boundingRect), line: line)
        c.fill(Path(rect(-0.5, -3.05, 1.0, 0.16)), with: .color(gold))
        c.fill(polygon([CGPoint(x: 0.3, y: -3.55), CGPoint(x: 0.9, y: -4.1), CGPoint(x: 0.6, y: -3.4)]), with: .color(bone))
    }

    private static func gremlin(_ c: inout GraphicsContext, side: Side, pose: Pose, line: CGFloat) {
        let bob = pose.moving ? CGFloat(abs(sin(pose.phase * 1.5))) * 0.15 : 0
        legs(&c, pose: pose, color: goblin, line: line, spread: 0.35, length: 0.7)
        c.translateBy(x: 0, y: -bob)
        torso(&c, side: side, line: line, width: 1.2, height: 1.1, bottom: -0.5, colorOverride: goblin, darkOverride: Color(red: 0.22, green: 0.45, blue: 0.14))
        shape(&c, rounded(rect(-0.6, -1.15, 1.2, 0.35), 0.1), fill: .color(team(side)), line: line * 0.7)
        // dagger
        let stab = CGFloat(pose.attack) * 2.5
        var blade = Path()
        blade.move(to: CGPoint(x: 0.6 + stab * 0.2, y: -1.2))
        blade.addLine(to: CGPoint(x: 1.35 + stab * 0.3, y: -1.9))
        c.stroke(blade, with: .color(outline), style: StrokeStyle(lineWidth: 0.24, lineCap: .round))
        c.stroke(blade, with: .color(steel), style: StrokeStyle(lineWidth: 0.1, lineCap: .round))
        arm(&c, at: CGPoint(x: 0.65 + stab * 0.2, y: -1.15), r: 0.24, color: goblin, dark: Color(red: 0.22, green: 0.45, blue: 0.14), line: line)
        // big head + ears
        for x in [-1.0, 1.0] {
            let ear = polygon([CGPoint(x: CGFloat(x) * 0.5, y: -2.3), CGPoint(x: CGFloat(x) * 1.35, y: -2.95), CGPoint(x: CGFloat(x) * 0.55, y: -2.75)])
            shape(&c, ear, fill: .color(goblin), line: line)
        }
        head(&c, cy: -2.3, r: 0.7, color: goblin, dark: Color(red: 0.22, green: 0.45, blue: 0.14), line: line, eyes: false)
        for x in [0.15, 0.55] {
            c.fill(circle(CGFloat(x), -2.4, 0.19), with: .color(Color(red: 1.0, green: 0.9, blue: 0.3)))
            c.fill(circle(CGFloat(x) + 0.06, -2.4, 0.09), with: .color(outline))
        }
        var grin = Path()
        grin.move(to: CGPoint(x: 0.0, y: -1.95))
        grin.addQuadCurve(to: CGPoint(x: 0.6, y: -2.0), control: CGPoint(x: 0.3, y: -1.7))
        c.stroke(grin, with: .color(outline), lineWidth: 0.08)
        c.fill(polygon([CGPoint(x: 0.15, y: -1.85), CGPoint(x: 0.25, y: -1.6), CGPoint(x: 0.35, y: -1.85)]), with: .color(bone))
    }

    private static func skeleton(_ c: inout GraphicsContext, side: Side, pose: Pose, line: CGFloat) {
        let bob = pose.moving ? CGFloat(abs(sin(pose.phase * 1.4))) * 0.12 : 0
        legs(&c, pose: pose, color: bone, line: line, spread: 0.3, length: 0.8)
        c.translateBy(x: 0, y: -bob)
        // ribcage
        shape(&c, rounded(rect(-0.6, -2.05, 1.2, 1.35), 0.4), fill: .color(bone), line: line)
        for i in 0..<3 {
            c.fill(Path(rect(-0.45, -1.85 + CGFloat(i) * 0.35, 0.9, 0.14)), with: .color(outline.opacity(0.7)))
        }
        c.fill(rounded(rect(-0.62, -0.85, 1.24, 0.22), 0.05), with: .color(team(side)))
        let swing = CGFloat(pose.attack) * 2
        sword(&c, from: CGPoint(x: 0.75, y: -1.4), to: CGPoint(x: 1.1 + swing * 0.5, y: -2.5 + swing * 0.7), width: 0.12)
        arm(&c, at: CGPoint(x: 0.7, y: -1.45), r: 0.22, color: bone, dark: Color(white: 0.75), line: line)
        // skull
        head(&c, cy: -2.6, r: 0.6, color: bone, dark: Color(white: 0.72), line: line, eyes: false)
        c.fill(ellipse(0.12, -2.65, 0.19, 0.22), with: .color(outline))
        c.fill(ellipse(0.55, -2.65, 0.17, 0.2), with: .color(outline))
        c.fill(circle(0.15, -2.68, 0.06), with: .color(team(side)))
        c.fill(circle(0.57, -2.68, 0.05), with: .color(team(side)))
        for i in 0..<3 {
            c.fill(Path(rect(0.05 + CGFloat(i) * 0.18, -2.25, 0.08, 0.16)), with: .color(outline.opacity(0.6)))
        }
    }

    private static func whelp(_ c: inout GraphicsContext, side: Side, pose: Pose, line: CGFloat) {
        let flap = CGFloat(sin(pose.time * 9))
        let hover = -1.4 + CGFloat(sin(pose.time * 3)) * 0.15
        c.translateBy(x: 0, y: hover)
        let dark = Color(red: 0.16, green: 0.42, blue: 0.4)
        // wings
        for s in [-1.0, 1.0] {
            let sx = CGFloat(s)
            let wing = polygon([
                CGPoint(x: sx * 0.5, y: -1.9), CGPoint(x: sx * 1.7, y: -2.9 - flap * 0.5), CGPoint(x: sx * 2.5, y: -2.2 - flap * 0.6),
                CGPoint(x: sx * 2.05, y: -1.5 - flap * 0.3), CGPoint(x: sx * 1.4, y: -1.35),
            ])
            shape(&c, wing, fill: vertical(team(side), teamDark(side), wing.boundingRect), line: line)
            var veins = Path()
            veins.move(to: CGPoint(x: sx * 0.6, y: -1.85)); veins.addLine(to: CGPoint(x: sx * 1.7, y: -2.85 - flap * 0.5))
            veins.move(to: CGPoint(x: sx * 0.6, y: -1.8)); veins.addLine(to: CGPoint(x: sx * 2.45, y: -2.2 - flap * 0.6))
            c.stroke(veins, with: .color(teamDark(side)), lineWidth: 0.07)
        }
        // tail
        var tail = Path()
        tail.move(to: CGPoint(x: -0.7, y: -1.2))
        tail.addQuadCurve(to: CGPoint(x: -1.9, y: -0.4), control: CGPoint(x: -1.7, y: -1.5))
        c.stroke(tail, with: .color(outline), style: StrokeStyle(lineWidth: 0.44, lineCap: .round))
        c.stroke(tail, with: .color(dragon), style: StrokeStyle(lineWidth: 0.26, lineCap: .round))
        c.fill(polygon([CGPoint(x: -1.9, y: -0.15), CGPoint(x: -2.35, y: -0.55), CGPoint(x: -1.75, y: -0.7)]), with: .color(team(side)))
        // body + belly
        ball(&c, cx: 0, cy: -1.5, r: 1.0, color: dragon, dark: dark, line: line)
        c.fill(ellipse(0.2, -1.3, 0.55, 0.65), with: .color(dragonBelly))
        // feet
        for x in [-0.4, 0.4] { shape(&c, ellipse(CGFloat(x), -0.55, 0.3, 0.2), fill: .color(dragon), line: line) }
        // head
        ball(&c, cx: 0.75, cy: -2.55, r: 0.72, color: dragon, dark: dark, line: line)
        shape(&c, rounded(rect(1.0, -2.55, 0.85, 0.5), 0.2), fill: .color(dragon), line: line)
        c.fill(circle(1.7, -2.4, 0.06), with: .color(outline))
        c.fill(circle(0.95, -2.75, 0.2), with: .color(Color(red: 1.0, green: 0.85, blue: 0.3)))
        c.fill(circle(1.0, -2.75, 0.1), with: .color(outline))
        for x in [0.3, 0.6] {
            c.fill(polygon([CGPoint(x: CGFloat(x), y: -3.15), CGPoint(x: CGFloat(x) + 0.2, y: -3.65), CGPoint(x: CGFloat(x) + 0.35, y: -3.1)]), with: .color(team(side)))
        }
        if pose.attack > 0.1 {
            let f = CGFloat(pose.attack) * 4
            c.fill(ellipse(2.2 + f * 0.4, -2.3, 0.5 + f * 0.3, 0.3 + f * 0.15), with: .color(fire.opacity(0.9)))
            c.fill(ellipse(2.1 + f * 0.3, -2.3, 0.3 + f * 0.2, 0.18 + f * 0.1), with: .color(fireCore))
        }
    }

    // MARK: Towers

    static func tower(_ ctx: inout GraphicsContext, kind: TowerKind, side: Side, center: CGPoint, r: CGFloat, alive: Bool, activated: Bool, flash: Bool, time: Double) {
        var c = ctx
        c.translateBy(x: center.x, y: center.y)
        c.scaleBy(x: r, y: r)
        let line: CGFloat = 0.09
        if !alive {
            rubble(&c, kind: kind, side: side, line: line)
            return
        }
        let w: CGFloat = kind == .keep ? 1.9 : 1.5
        let h: CGFloat = kind == .keep ? 1.9 : 1.7
        let base = rect(-w / 2, -h * 0.55, w, h)
        softShadow(&c, cx: 0.15, cy: base.maxY - 0.1, rx: w * 0.75, ry: 0.35, alpha: 0.45)
        // side turrets for the keep
        if kind == .keep {
            for x in [-1.05, 1.05] {
                let tr = rect(CGFloat(x) - 0.32, -0.55, 0.64, 1.25)
                shape(&c, rounded(tr, 0.12), fill: horizontal(stoneLight, stoneDark, tr), line: line)
                let cone = polygon([CGPoint(x: tr.minX - 0.1, y: tr.minY), CGPoint(x: tr.midX, y: tr.minY - 0.7), CGPoint(x: tr.maxX + 0.1, y: tr.minY)])
                shape(&c, cone, fill: vertical(teamLight(side), teamDark(side), cone.boundingRect), line: line)
            }
        }
        // stone body with brick courses
        shape(&c, rounded(base, 0.12), fill: horizontal(stoneLight, stoneDark, base), line: line)
        var bricks = Path()
        var row = 0
        var y = base.minY + 0.25
        while y < base.maxY - 0.15 {
            bricks.move(to: CGPoint(x: base.minX, y: y)); bricks.addLine(to: CGPoint(x: base.maxX, y: y))
            let offset: CGFloat = row % 2 == 0 ? 0 : 0.25
            var x = base.minX + offset
            while x < base.maxX { bricks.move(to: CGPoint(x: x, y: y)); bricks.addLine(to: CGPoint(x: x, y: min(base.maxY, y + 0.25))); x += 0.5 }
            y += 0.25
            row += 1
        }
        c.stroke(bricks, with: .color(stoneDark.opacity(0.35)), lineWidth: 0.035)
        // door
        let door = rounded(rect(-0.28, base.maxY - 0.6, 0.56, 0.6), 0.25)
        shape(&c, door, fill: .color(woodDark), line: line * 0.8)
        // windows glow when awake
        let glow = activated ? (side == .player ? Color(red: 1.0, green: 0.85, blue: 0.4) : Color(red: 1.0, green: 0.6, blue: 0.3)) : Color(white: 0.15)
        for x in (kind == .keep ? [-0.42, 0.42] : [0.0]) {
            shape(&c, rounded(rect(CGFloat(x) - 0.14, base.minY + 0.55, 0.28, 0.42), 0.14), fill: .color(glow), line: line * 0.7)
        }
        // battlements
        let rim = rect(base.minX - 0.15, base.minY - 0.22, base.width + 0.3, 0.32)
        shape(&c, rounded(rim, 0.06), fill: vertical(stoneLight, stone, rim), line: line)
        let count = kind == .keep ? 5 : 4
        for i in 0..<count {
            let bx = rim.minX + rim.width * (CGFloat(i) + 0.5) / CGFloat(count)
            shape(&c, rounded(rect(bx - 0.12, rim.minY - 0.22, 0.24, 0.26), 0.04), fill: .color(stoneLight), line: line * 0.8)
        }
        // roof
        if kind == .keep {
            let dome = rect(-0.75, rim.minY - 1.1, 1.5, 1.2)
            var domePath = Path()
            let domeBase = dome.maxY - 0.1
            domePath.move(to: CGPoint(x: -0.75, y: domeBase))
            domePath.addCurve(to: CGPoint(x: 0.75, y: domeBase),
                              control1: CGPoint(x: -0.75, y: domeBase - 1.05),
                              control2: CGPoint(x: 0.75, y: domeBase - 1.05))
            domePath.closeSubpath()
            shape(&c, rounded(rect(-0.82, domeBase - 0.08, 1.64, 0.2), 0.05), fill: .color(stone), line: line)
            shape(&c, domePath, fill: .radialGradient(Gradient(colors: [teamLight(side), team(side), teamDark(side)]), center: CGPoint(x: -0.3, y: dome.minY + 0.4), startRadius: 0, endRadius: 1.2), line: line)
            crown(&c, center: CGPoint(x: 0, y: dome.minY - 0.05), size: 0.7, line: line * 0.8)
        } else {
            let cone = polygon([CGPoint(x: rim.minX + 0.05, y: rim.minY - 0.15), CGPoint(x: 0, y: rim.minY - 1.35), CGPoint(x: rim.maxX - 0.05, y: rim.minY - 0.15)])
            shape(&c, cone, fill: horizontal(teamLight(side), teamDark(side), cone.boundingRect), line: line)
            c.fill(polygon([CGPoint(x: -0.1, y: rim.minY - 0.15), CGPoint(x: 0, y: rim.minY - 1.35), CGPoint(x: 0.35, y: rim.minY - 0.15)]), with: .color(.white.opacity(0.18)))
            // pennant
            let top = CGPoint(x: 0, y: rim.minY - 1.35)
            c.stroke(Path { p in p.move(to: top); p.addLine(to: CGPoint(x: 0, y: top.y - 0.6)) }, with: .color(woodDark), lineWidth: 0.06)
            let wave = CGFloat(sin(time * 5 + Double(center.x)))
            let flag = polygon([CGPoint(x: 0, y: top.y - 0.6), CGPoint(x: 0.7, y: top.y - 0.5 + wave * 0.08), CGPoint(x: 0.02, y: top.y - 0.25)])
            shape(&c, flag, fill: .color(gold), line: line * 0.7)
        }
        if flash {
            c.blendMode = .plusLighter
            c.fill(rounded(base.insetBy(dx: -0.2, dy: -0.8), 0.3), with: .color(.white.opacity(0.35)))
        }
    }

    static func rubble(_ c: inout GraphicsContext, kind: TowerKind, side: Side, line: CGFloat) {
        let s: CGFloat = kind == .keep ? 1.2 : 1.0
        c.fill(ellipse(0, 0.35 * s, 1.25 * s, 0.55 * s), with: .color(Color(red: 0.16, green: 0.12, blue: 0.1).opacity(0.6)))
        let blocks: [(CGFloat, CGFloat, CGFloat, CGFloat, Double)] = [
            (-0.7, 0.15, 0.6, 0.45, -12), (0.1, 0.05, 0.75, 0.55, 8), (-0.25, -0.35, 0.55, 0.45, 20),
            (0.55, -0.15, 0.5, 0.4, -25), (-0.05, 0.3, 0.45, 0.35, 0),
        ]
        for (x, y, w, h, angle) in blocks {
            var b = c
            b.translateBy(x: x * s, y: y * s)
            b.rotate(by: .degrees(angle))
            let r = rect(-w * s / 2, -h * s / 2, w * s, h * s)
            shape(&b, rounded(r, 0.08), fill: vertical(stoneLight, stoneDark, r), line: line)
        }
        // fallen team banner
        let banner = polygon([CGPoint(x: -0.9 * s, y: -0.2 * s), CGPoint(x: -0.3 * s, y: -0.35 * s), CGPoint(x: -0.2 * s, y: 0.1 * s), CGPoint(x: -0.8 * s, y: 0.25 * s)])
        shape(&c, banner, fill: .color(teamDark(side)), line: line * 0.8)
    }
}

/// A card illustration: the character drawn on a themed vignette.
struct CardArtView: View {
    let card: CardDef
    var animated = false

    var body: some View {
        Canvas(rendersAsynchronously: false) { ctx, size in
            let w = size.width, h = size.height
            let bg = Art.rect(0, 0, w, h)
            let top: Color, bottom: Color
            switch card.kind {
            case .spell:
                top = Color(red: 0.55, green: 0.24, blue: 0.75); bottom = Color(red: 0.22, green: 0.07, blue: 0.4)
            case .troop:
                top = card.flying ? Color(red: 0.45, green: 0.72, blue: 0.95) : Color(red: 0.42, green: 0.65, blue: 0.32)
                bottom = card.flying ? Color(red: 0.16, green: 0.32, blue: 0.62) : Color(red: 0.16, green: 0.34, blue: 0.16)
            }
            ctx.fill(Path(bg), with: .radialGradient(Gradient(colors: [top, bottom]), center: CGPoint(x: w * 0.5, y: h * 0.35), startRadius: 0, endRadius: h * 0.9))
            // light rays
            var rays = ctx
            rays.opacity = 0.16
            for i in 0..<6 {
                let a = CGFloat(i) / 6 * .pi * 2
                let p = Art.polygon([CGPoint(x: w / 2, y: h * 0.4),
                                     CGPoint(x: w / 2 + cos(a) * h, y: h * 0.4 + sin(a) * h),
                                     CGPoint(x: w / 2 + cos(a + 0.25) * h, y: h * 0.4 + sin(a + 0.25) * h)])
                rays.fill(p, with: .color(.white))
            }
            if card.kind == .troop && !card.flying {
                ctx.fill(Art.ellipse(w / 2, h * 0.84, w * 0.55, h * 0.09), with: .color(Color(red: 0.2, green: 0.4, blue: 0.16)))
            }
            let r = min(w, h) * (card.count > 1 ? 0.14 : (card.id == "giant" ? 0.15 : 0.19))
            let foot = CGPoint(x: w / 2, y: card.flying ? h * 0.84 + r * 1.6 : h * 0.84)
            switch card.kind {
            case .spell:
                spellArt(&ctx, size: size)
            case .troop:
                if card.count > 1 {
                    let n = min(card.count, 3)
                    for i in 0..<n {
                        let dx = (CGFloat(i) - CGFloat(n - 1) / 2) * r * 2.4
                        Art.character(&ctx, id: card.id, side: .player, foot: CGPoint(x: foot.x + dx, y: foot.y - CGFloat(i % 2) * r * 0.9), r: r, pose: Art.Pose(phase: Double(i), facing: 1, attack: 0.6))
                    }
                } else {
                    Art.character(&ctx, id: card.id, side: .player, foot: foot, r: r, pose: Art.Pose(phase: 0, facing: 1, attack: 0.55))
                }
            }
        }
    }

    private func spellArt(_ ctx: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        if card.id == "meteor" {
            var trail = Path()
            trail.move(to: CGPoint(x: w * 0.85, y: h * 0.1))
            trail.addLine(to: CGPoint(x: w * 0.45, y: h * 0.58))
            ctx.stroke(trail, with: .color(Art.fire.opacity(0.5)), style: StrokeStyle(lineWidth: w * 0.22, lineCap: .round))
            ctx.stroke(trail, with: .color(Art.fireCore.opacity(0.8)), style: StrokeStyle(lineWidth: w * 0.1, lineCap: .round))
            Art.ball(&ctx, cx: w * 0.42, cy: h * 0.6, r: w * 0.2, color: Art.fireCore, dark: Art.fire, line: max(1, w * 0.03))
            ctx.fill(Art.circle(w * 0.36, h * 0.55, w * 0.05), with: .color(Color(red: 0.5, green: 0.2, blue: 0.1)))
            ctx.fill(Art.circle(w * 0.5, h * 0.66, w * 0.035), with: .color(Color(red: 0.5, green: 0.2, blue: 0.1)))
            ctx.fill(Art.ellipse(w * 0.45, h * 0.86, w * 0.35, h * 0.06), with: .color(Art.fire.opacity(0.45)))
        } else {
            for i in 0..<7 {
                let x = w * (0.15 + 0.12 * CGFloat(i))
                let y = h * (0.25 + 0.08 * CGFloat((i * 3) % 5))
                var a = Path()
                a.move(to: CGPoint(x: x + w * 0.06, y: y - h * 0.18))
                a.addLine(to: CGPoint(x: x, y: y + h * 0.2))
                ctx.stroke(a, with: .color(Art.outline), style: StrokeStyle(lineWidth: max(1.5, w * 0.03), lineCap: .round))
                ctx.stroke(a, with: .color(Art.wood), style: StrokeStyle(lineWidth: max(1, w * 0.015), lineCap: .round))
                ctx.fill(Art.polygon([CGPoint(x: x, y: y + h * 0.2), CGPoint(x: x - w * 0.035, y: y + h * 0.12), CGPoint(x: x + w * 0.035, y: y + h * 0.13)]), with: .color(Art.steel))
                ctx.fill(Art.polygon([CGPoint(x: x + w * 0.06, y: y - h * 0.18), CGPoint(x: x + w * 0.1, y: y - h * 0.14), CGPoint(x: x + w * 0.04, y: y - h * 0.11)]), with: .color(.white))
            }
            ctx.fill(Art.ellipse(w * 0.5, h * 0.86, w * 0.4, h * 0.06), with: .color(Color.cyan.opacity(0.35)))
        }
    }
}
