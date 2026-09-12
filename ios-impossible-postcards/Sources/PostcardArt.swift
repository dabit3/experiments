import SwiftUI

struct PostcardPalette {
    let sky: Color
    let mist: Color
    let accent: Color
    let deep: Color
    let foliage: Color

    static let ink = Color(hex: 0x354B50)
    static let paper = Color(hex: 0xFAF6ED)
    static let ivory = Color(hex: 0xFFF8E8)

    static func chapter(_ index: Int) -> PostcardPalette {
        [
            PostcardPalette(
                sky: Color(hex: 0xE7EDE6), mist: Color(hex: 0xCBDDD5),
                accent: Color(hex: 0xBC7966), deep: Color(hex: 0x885B54), foliage: Color(hex: 0x739C8C)
            ),
            PostcardPalette(
                sky: Color(hex: 0xF3E6DB), mist: Color(hex: 0xE8D2C1),
                accent: Color(hex: 0xC17D64), deep: Color(hex: 0x945545), foliage: Color(hex: 0x8C9A80)
            ),
            PostcardPalette(
                sky: Color(hex: 0xE9E5F0), mist: Color(hex: 0xD0C8E1),
                accent: Color(hex: 0x9E8CB8), deep: Color(hex: 0x706689), foliage: Color(hex: 0x819EA1)
            ),
            PostcardPalette(
                sky: Color(hex: 0xE7E4E8), mist: Color(hex: 0xC8CAD8),
                accent: Color(hex: 0xB38583), deep: Color(hex: 0x696A89), foliage: Color(hex: 0x829D9C)
            ),
        ][index % 4]
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB, red: Double((hex >> 16) & 255) / 255,
            green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1
        )
    }
}

struct WorldProjection {
    let scale: Double
    let origin: CGPoint

    init(chapter: Chapter, size: CGSize) {
        let points = chapter.tiles.map { Self.raw($0.point) }
        let minX = (points.map(\.x).min() ?? 0) - 26
        let maxX = (points.map(\.x).max() ?? 0) + 26
        let minY = (points.map(\.y).min() ?? 0) - 62
        let maxY = (points.map(\.y).max() ?? 0) + 106
        scale = min((size.width - 22) / (maxX - minX), (size.height - 16) / (maxY - minY), 2.1)
        origin = CGPoint(
            x: size.width / 2 - (minX + maxX) / 2 * scale,
            y: size.height / 2 - (minY + maxY) / 2 * scale
        )
    }

    static func raw(_ point: WorldPoint) -> CGPoint {
        CGPoint(x: (point.x - point.y) * 25, y: (point.x + point.y) * 13 - point.z * 25)
    }

    func point(_ world: WorldPoint) -> CGPoint {
        let raw = Self.raw(world)
        return CGPoint(x: raw.x * scale + origin.x, y: raw.y * scale + origin.y)
    }
}

struct PostcardWorld: View {
    let chapter: Chapter
    let state: PuzzleState
    var interactive = false
    var onTile: (Int) -> Void = { _ in }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var angles = [Double]()

    var body: some View {
        GeometryReader { geometry in
            let projection = WorldProjection(chapter: chapter, size: geometry.size)
            let currentAngles = angles.isEmpty ? state.orientations.map { Double($0) * .pi / 2 } : angles
            ZStack {
                Architecture(
                    chapter: chapter, state: state, angle0: currentAngles[0],
                    angle1: currentAngles.count > 1 ? currentAngles[1] : 0
                )
                .accessibilityHidden(true)
                if interactive {
                    ForEach(chapter.tiles) { tile in
                        Button { onTile(tile.id) } label: {
                            Circle().fill(.clear).frame(width: 46, height: 46).contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(tile.name)
                        .accessibilityValue(accessibilityValue(tile))
                        .accessibilityHint("Walk here if the path is connected")
                        .position(projection.point(tile.point))
                    }
                }
                Traveler(accent: PostcardPalette.chapter(chapter.id).deep)
                    .frame(width: 21 * projection.scale, height: 32 * projection.scale)
                    .position(travelerPosition(projection))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.32), value: state.tile)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .onAppear { angles = state.orientations.map { Double($0) * .pi / 2 } }
        .onChange(of: state.orientations) { old, new in
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.48)) {
                if angles.count != new.count {
                    angles = new.map { Double($0) * .pi / 2 }
                } else {
                    for index in new.indices where old[index] != new[index] {
                        angles[index] += .pi / 2
                    }
                }
            }
        }
    }

    private func travelerPosition(_ projection: WorldProjection) -> CGPoint {
        var point = projection.point(chapter.tiles[state.tile].point)
        point.y -= 15 * projection.scale
        return point
    }

    private func accessibilityValue(_ tile: Tile) -> String {
        if tile.id == state.tile {
            return "Traveler is here"
        }
        if case let .switchTile(bit) = tile.kind, state.switches & (1 << bit) != 0 {
            return "Sun seal lit"
        }
        return chapter.path(to: tile.id, state: state) == nil ? "Not connected" : "Connected"
    }
}

struct Architecture: View, Animatable {
    let chapter: Chapter
    let state: PuzzleState
    nonisolated var angle0: Double
    nonisolated var angle1: Double

    nonisolated var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(angle0, angle1) }
        set { angle0 = newValue.first; angle1 = newValue.second }
    }

    var body: some View {
        Canvas { context, size in
            let projection = WorldProjection(chapter: chapter, size: size)
            let palette = PostcardPalette.chapter(chapter.id)
            var painter = WorldPainter(context: context, projection: projection, palette: palette)
            painter.atmosphere(size: size)
            let ordered = chapter.tiles.sorted { $0.point.x + $0.point.y < $1.point.x + $1.point.y }
            for tile in ordered {
                painter.shadow(tile.point)
            }
            for tile in ordered {
                painter.column(tile.point, pivot: isPivot(tile), goal: tile.id == chapter.destination)
            }
            for path in chapter.walkways {
                painter.bridge(chapter.tiles[path.from].point, chapter.tiles[path.to].point, moving: false)
            }
            for (index, mechanism) in chapter.mechanisms.enumerated() {
                let angle = index == 0 ? angle0 : angle1
                let center = chapter.tiles[mechanism.center].point
                for offset in [0, mechanism.elbow ? 1 : 2] {
                    let arm = angle + Double(offset) * .pi / 2
                    let orientation = arm / (.pi / 2)
                    let lower = Int(floor(orientation))
                    let fraction = orientation - floor(orientation)
                    let lowDock = chapter.tiles[mechanism.docks[(lower % 4 + 4) % 4]].point
                    let highDock = chapter.tiles[mechanism.docks[((lower + 1) % 4 + 4) % 4]].point
                    let endpoint = WorldPoint(
                        x: center.x + sin(arm) * 2, y: center.y - cos(arm) * 2,
                        z: lowDock.z * (1 - fraction) + highDock.z * fraction
                    )
                    painter.bridge(center, endpoint, moving: true)
                }
            }
            for tile in ordered {
                painter.surface(tile.point, pivot: isPivot(tile))
                switch tile.kind {
                case let .switchTile(bit):
                    painter.seal(tile.point, lit: state.switches & (1 << bit) != 0)
                case .destination:
                    painter.portal(tile.point, open: state.switches == chapter.requiredSwitches)
                case .pivot:
                    painter.pivot(tile.point)
                case .start:
                    painter.marker(tile.point, color: palette.accent)
                case .floor:
                    painter.marker(tile.point, color: palette.foliage.opacity(0.7))
                }
            }
            for tile in ordered where tile.kind == .floor && tile.id % 2 == 1 {
                painter.cypress(WorldPoint(x: tile.point.x - 0.29, y: tile.point.y - 0.3, z: tile.point.z))
            }
        }
    }

    private func isPivot(_ tile: Tile) -> Bool {
        if case .pivot = tile.kind {
            return true
        }
        return false
    }
}

struct WorldPainter {
    var context: GraphicsContext
    let projection: WorldProjection
    let palette: PostcardPalette
    private var scale: Double {
        projection.scale
    }

    mutating func atmosphere(size: CGSize) {
        let moon = CGRect(x: size.width * 0.72, y: size.height * 0.08, width: 36, height: 36)
        context.fill(Path(ellipseIn: moon), with: .color(PostcardPalette.ivory.opacity(0.8)))
        for index in 0 ..< 3 {
            let x = size.width * 0.19 + Double(index * 15)
            let y = size.height * 0.19 + Double(index % 2 * 7)
            var bird = Path()
            bird.move(to: CGPoint(x: x, y: y))
            bird.addQuadCurve(to: CGPoint(x: x + 5, y: y + 2), control: CGPoint(x: x + 3, y: y - 2))
            bird.addQuadCurve(to: CGPoint(x: x + 10, y: y), control: CGPoint(x: x + 6, y: y - 2))
            context.stroke(bird, with: .color(palette.deep.opacity(0.3)), lineWidth: 0.9)
        }
    }

    mutating func shadow(_ point: WorldPoint) {
        let ground = projection.point(WorldPoint(x: point.x + 0.45, y: point.y + 0.45, z: -1.4))
        context.fill(
            Path(ellipseIn: CGRect(
                x: ground.x - 24 * scale,
                y: ground.y - 7 * scale,
                width: 54 * scale,
                height: 16 * scale
            )),
            with: .color(palette.deep.opacity(0.08))
        )
    }

    mutating func column(_ point: WorldPoint, pivot: Bool, goal: Bool) {
        let width = pivot ? 0.56 : 0.48
        let top = corners(point, width: width)
        let bottom = corners(WorldPoint(x: point.x, y: point.y, z: -1.2), width: width)
        polygon([top[1], top[2], bottom[2], bottom[1]], color: goal ? palette.accent : Color(hex: 0xD5C9B3))
        polygon([top[2], top[3], bottom[3], bottom[2]], color: goal ? palette.deep : Color(hex: 0xB9BCA9))
        let p = projection.point(point)
        let base = projection.point(WorldPoint(x: point.x, y: point.y, z: -1.2))
        let height = base.y - p.y
        if height > 40 * scale {
            let rect = CGRect(
                x: p.x + 5 * scale,
                y: p.y + 23 * scale,
                width: 8 * scale,
                height: min(height - 25 * scale, 25 * scale)
            )
            context.fill(Path(roundedRect: rect, cornerRadius: 4 * scale), with: .color(palette.deep.opacity(0.24)))
            let line = CGRect(
                x: p.x - 13 * scale,
                y: p.y + 25 * scale,
                width: 2 * scale,
                height: max(height - 28 * scale, 2)
            )
            context.fill(Path(line), with: .color(PostcardPalette.ivory.opacity(0.3)))
        }
        polygon(top, color: PostcardPalette.ivory)
    }

    mutating func surface(_ point: WorldPoint, pivot: Bool) {
        polygon(corners(point, width: pivot ? 0.55 : 0.48), color: PostcardPalette.ivory)
        let path = polygonPath(corners(point, width: pivot ? 0.55 : 0.48))
        context.stroke(path, with: .color(.white.opacity(0.6)), lineWidth: 0.65 * scale)
    }

    mutating func bridge(_ from: WorldPoint, _ to: WorldPoint, moving: Bool) {
        let length = hypot(to.x - from.x, to.y - from.y)
        guard length > 0.01 else { return }
        let nx = -(to.y - from.y) / length * 0.27
        let ny = (to.x - from.x) / length * 0.27
        let worlds = [
            WorldPoint(x: from.x + nx, y: from.y + ny, z: from.z),
            WorldPoint(x: to.x + nx, y: to.y + ny, z: to.z),
            WorldPoint(x: to.x - nx, y: to.y - ny, z: to.z),
            WorldPoint(x: from.x - nx, y: from.y - ny, z: from.z),
        ]
        let top = worlds.map(projection.point)
        let bottom = worlds.map { projection.point(WorldPoint(x: $0.x, y: $0.y, z: $0.z - 0.2)) }
        polygon([top[0], top[1], bottom[1], bottom[0]], color: moving ? palette.deep : Color(hex: 0xB9BCA9))
        polygon([top[1], top[2], bottom[2], bottom[1]], color: moving ? palette.deep : Color(hex: 0xD5C9B3))
        polygon([top[2], top[3], bottom[3], bottom[2]], color: moving ? palette.deep : Color(hex: 0xD5C9B3))
        polygon(top, color: moving ? palette.accent : PostcardPalette.ivory)
        if abs(to.z - from.z) > 0.1 {
            for step in 1 ..< 9 {
                let t = Double(step) / 9
                let p = WorldPoint(
                    x: from.x + (to.x - from.x) * t,
                    y: from.y + (to.y - from.y) * t,
                    z: from.z + (to.z - from.z) * t
                )
                var line = Path()
                line.move(to: projection.point(WorldPoint(x: p.x + nx, y: p.y + ny, z: p.z)))
                line.addLine(to: projection.point(WorldPoint(x: p.x - nx, y: p.y - ny, z: p.z)))
                context.stroke(line, with: .color(palette.deep.opacity(0.35)), lineWidth: 0.75 * scale)
            }
        } else {
            var seam = Path()
            seam.move(to: projection.point(from))
            seam.addLine(to: projection.point(to))
            context.stroke(
                seam,
                with: .color(.white.opacity(0.24)),
                style: StrokeStyle(lineWidth: 0.7 * scale, dash: [2 * scale, 5 * scale])
            )
        }
    }

    mutating func seal(_ world: WorldPoint, lit: Bool) {
        let p = projection.point(world)
        let rect = CGRect(x: p.x - 10 * scale, y: p.y - 5 * scale, width: 20 * scale, height: 10 * scale)
        context.fill(Path(ellipseIn: rect), with: .color(lit ? Color(hex: 0xD6AC58) : palette.accent.opacity(0.32)))
        context.stroke(
            Path(ellipseIn: rect.insetBy(dx: 3 * scale, dy: 1.5 * scale)),
            with: .color(lit ? PostcardPalette.ivory : palette.deep),
            lineWidth: 0.8 * scale
        )
        for index in 0 ..< 8 {
            let angle = Double(index) * .pi / 4
            var ray = Path()
            ray.move(to: CGPoint(x: p.x + cos(angle) * 11 * scale, y: p.y + sin(angle) * 6 * scale))
            ray.addLine(to: CGPoint(x: p.x + cos(angle) * 14 * scale, y: p.y + sin(angle) * 8 * scale))
            context.stroke(ray, with: .color(lit ? Color(hex: 0xC09542) : palette.accent), lineWidth: scale)
        }
        if lit {
            let glow = CGRect(x: p.x - 16 * scale, y: p.y - 25 * scale, width: 32 * scale, height: 32 * scale)
            context.fill(Path(ellipseIn: glow), with: .radialGradient(
                Gradient(colors: [Color(hex: 0xEACB80).opacity(0.3), .clear]),
                center: CGPoint(x: p.x, y: p.y - 9 * scale), startRadius: 0, endRadius: 16 * scale
            ))
        }
    }

    mutating func pivot(_ world: WorldPoint) {
        let p = projection.point(world)
        let rect = CGRect(x: p.x - 11 * scale, y: p.y - 6 * scale, width: 22 * scale, height: 12 * scale)
        context.fill(Path(ellipseIn: rect), with: .color(palette.accent.opacity(0.16)))
        context.stroke(Path(ellipseIn: rect), with: .color(palette.accent), lineWidth: 1.3 * scale)
        marker(world, color: palette.deep)
    }

    mutating func marker(_ world: WorldPoint, color: Color) {
        let p = projection.point(world)
        context.fill(
            Path(ellipseIn: CGRect(x: p.x - 2.4 * scale, y: p.y - 1.5 * scale, width: 4.8 * scale, height: 3 * scale)),
            with: .color(color)
        )
    }

    mutating func portal(_ world: WorldPoint, open: Bool) {
        let p = projection.point(world)
        let rect = CGRect(x: p.x - 15 * scale, y: p.y - 45 * scale, width: 30 * scale, height: 47 * scale)
        let side = rect.offsetBy(dx: 6 * scale, dy: -3 * scale)
        context.fill(Path(roundedRect: side, cornerRadius: 15 * scale), with: .color(palette.accent))
        context.fill(Path(roundedRect: rect, cornerRadius: 15 * scale), with: .color(PostcardPalette.ivory))
        let opening = CGRect(x: p.x - 8 * scale, y: p.y - 34 * scale, width: 16 * scale, height: 37 * scale)
        context.fill(Path(roundedRect: opening, cornerRadius: 8 * scale), with: .linearGradient(
            Gradient(colors: [open ? Color(hex: 0xE6C779) : palette.deep, open ? Color(hex: 0xFFF5CC) : palette.mist]),
            startPoint: CGPoint(x: p.x, y: opening.minY), endPoint: CGPoint(x: p.x, y: opening.maxY)
        ))
        if !open {
            let bar = CGRect(x: opening.minX, y: p.y - 13 * scale, width: opening.width, height: 2 * scale)
            context.fill(Path(bar), with: .color(PostcardPalette.ivory.opacity(0.65)))
        }
        let gem = CGPoint(x: p.x, y: rect.minY + 7 * scale)
        polygon([
            CGPoint(x: gem.x, y: gem.y - 2 * scale), CGPoint(x: gem.x + 2 * scale, y: gem.y),
            CGPoint(x: gem.x, y: gem.y + 2 * scale), CGPoint(x: gem.x - 2 * scale, y: gem.y),
        ], color: palette.accent)
    }

    mutating func cypress(_ world: WorldPoint) {
        let p = projection.point(world)
        context.fill(
            Path(CGRect(x: p.x - scale, y: p.y - 10 * scale, width: 2 * scale, height: 11 * scale)),
            with: .color(palette.deep)
        )
        var shape = Path()
        shape.move(to: CGPoint(x: p.x, y: p.y - 28 * scale))
        shape.addCurve(
            to: CGPoint(x: p.x, y: p.y - 5 * scale),
            control1: CGPoint(x: p.x + 13 * scale, y: p.y - 9 * scale),
            control2: CGPoint(x: p.x + 6 * scale, y: p.y - 6 * scale)
        )
        shape.addCurve(
            to: CGPoint(x: p.x, y: p.y - 28 * scale),
            control1: CGPoint(x: p.x - 8 * scale, y: p.y - 4 * scale),
            control2: CGPoint(x: p.x - 8 * scale, y: p.y - 13 * scale)
        )
        context.fill(shape, with: .color(palette.foliage))
    }

    private func corners(_ point: WorldPoint, width: Double) -> [CGPoint] {
        [
            WorldPoint(x: point.x - width, y: point.y - width, z: point.z),
            WorldPoint(x: point.x + width, y: point.y - width, z: point.z),
            WorldPoint(x: point.x + width, y: point.y + width, z: point.z),
            WorldPoint(x: point.x - width, y: point.y + width, z: point.z),
        ].map(projection.point)
    }

    private func polygonPath(_ points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
    }

    private mutating func polygon(_ points: [CGPoint], color: Color) {
        context.fill(polygonPath(points), with: .color(color))
    }
}

struct Traveler: View {
    let accent: Color

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            context.fill(
                Path(ellipseIn: CGRect(x: w * 0.18, y: h * 0.88, width: w * 0.7, height: h * 0.1)),
                with: .color(.black.opacity(0.13))
            )
            var cloak = Path()
            cloak.move(to: CGPoint(x: w * 0.5, y: h * 0.1))
            cloak.addCurve(
                to: CGPoint(x: w * 0.88, y: h * 0.87),
                control1: CGPoint(x: w * 0.83, y: h * 0.2),
                control2: CGPoint(x: w * 0.67, y: h * 0.55)
            )
            cloak.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.87), control: CGPoint(x: w * 0.5, y: h))
            cloak.addCurve(
                to: CGPoint(x: w * 0.5, y: h * 0.1),
                control1: CGPoint(x: w * 0.3, y: h * 0.5),
                control2: CGPoint(x: w * 0.13, y: h * 0.25)
            )
            context.fill(
                cloak,
                with: .linearGradient(
                    Gradient(colors: [accent, PostcardPalette.ink]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: w, y: h)
                )
            )
            context.fill(
                Path(ellipseIn: CGRect(x: w * 0.35, y: h * 0.24, width: w * 0.33, height: h * 0.23)),
                with: .color(PostcardPalette.ivory)
            )
            context.fill(
                Path(ellipseIn: CGRect(x: w * 0.5, y: h * 0.32, width: w * 0.045, height: h * 0.04)),
                with: .color(PostcardPalette.ink)
            )
            context.fill(
                Path(CGRect(x: w * 0.4, y: h * 0.87, width: w * 0.06, height: h * 0.1)),
                with: .color(PostcardPalette.ink)
            )
            context.fill(
                Path(CGRect(x: w * 0.59, y: h * 0.87, width: w * 0.06, height: h * 0.1)),
                with: .color(PostcardPalette.ink)
            )
        }
    }
}
