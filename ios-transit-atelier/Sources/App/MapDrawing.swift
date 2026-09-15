import SwiftUI

struct StationGlyph: Shape {
  let kind: StationKind
  func path(in rect: CGRect) -> Path {
    var path = Path()
    switch kind {
    case .circle:
      let step = rect.width / 4
      path.move(to: CGPoint(x: rect.minX + step, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX - step, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + step))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - step))
      path.addLine(to: CGPoint(x: rect.maxX - step, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX + step, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - step))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + step))
      path.closeSubpath()
    case .square:
      path.addRect(rect)
    case .triangle:
      path.move(to: CGPoint(x: rect.midX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
      path.closeSubpath()
    case .diamond:
      path.move(to: CGPoint(x: rect.midX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
      path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
      path.closeSubpath()
    }
    return path
  }
}

extension PixelFont {
  /// Bitmap text as a single path so Canvas code can stamp labels without SwiftUI views.
  static func path(_ text: String, scale: Double, at origin: CGPoint) -> Path {
    var path = Path()
    for (column, character) in text.enumerated() {
      for (y, bits) in glyph(character).enumerated() {
        for (x, bit) in bits.enumerated() where bit == "#" {
          path.addRect(
            CGRect(
              x: origin.x + (Double(column) * 6 + Double(x)) * scale,
              y: origin.y + Double(y) * scale, width: scale, height: scale))
        }
      }
    }
    return path
  }

  static func width(_ text: String, scale: Double) -> Double {
    Double(text.count) * 6 * scale - scale
  }
}

struct InteractiveMap: View {
  let game: TransitSimulation
  let selected: Int
  let tap: (Int) -> Void
  @State private var lastDraggedStation: Int?

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        MapDrawing(game: game, selected: selected)
          .accessibilityHidden(true)
        ForEach(game.stations) { station in
          Color.clear
            .frame(width: 44, height: 44)
            .contentShape(Circle())
            .position(
              x: station.point.x * geometry.size.width, y: station.point.y * geometry.size.height
            )
            .accessibilityElement()
            .accessibilityLabel(
              "Station \(station.id + 1), \(station.kind.name), \(station.waiting.count) waiting"
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { tap(station.id) }
        }
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            if let station = nearest(value.location, in: geometry.size),
              station != lastDraggedStation
            {
              lastDraggedStation = station
              tap(station)
            }
          }
          .onEnded { _ in lastDraggedStation = nil }
      )
    }
  }

  private func nearest(_ point: CGPoint, in size: CGSize) -> Int? {
    game.stations.min { a, b in
      hypot(a.point.x * size.width - point.x, a.point.y * size.height - point.y)
        < hypot(b.point.x * size.width - point.x, b.point.y * size.height - point.y)
    }.flatMap { station in
      let distance = hypot(
        station.point.x * size.width - point.x, station.point.y * size.height - point.y)
      return distance < 28 ? station.id : nil
    }
  }
}

/// Renders the city as an overworld tile map: checkered grass, a sandy-banked pixel river,
/// outlined octilinear rails, sprite stations and two-frame animated locomotives.
struct MapDrawing: View {
  let game: TransitSimulation
  let selected: Int
  var decorative = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Two-frame animation clock driven by simulation time so it pauses with the game.
  private var frame: Int { Int(game.elapsed * 2) % 2 }

  var body: some View {
    Canvas { context, size in
      land(&context, size)
      let river = riverPath(size)
      water(&context, river, size)
      let orderedRoutes = game.routes.sorted {
        ($0.id == selected ? game.routes.count : $0.id)
          < ($1.id == selected ? game.routes.count : $1.id)
      }
      for route in orderedRoutes where route.stops.count > 1 {
        let path = routePath(route, size)
        let emphasis = decorative || selected == route.id
        let width = decorative ? 4.0 : 6.0
        context.stroke(
          path, with: .color(Ink.outline),
          style: StrokeStyle(lineWidth: width + 4, lineCap: .butt, lineJoin: .miter))
        context.stroke(
          path, with: .color(Ink.routes[route.id]),
          style: StrokeStyle(lineWidth: width, lineCap: .butt, lineJoin: .miter))
        context.stroke(
          path, with: .color(emphasis ? Color.white.opacity(0.5) : Ink.routesDeep[route.id]),
          style: StrokeStyle(lineWidth: 1.5, lineCap: .butt, lineJoin: .miter, dash: [4, 4]))
        var tunnel = context
        tunnel.clip(to: river)
        tunnel.stroke(
          path, with: .color(Ink.outline),
          style: StrokeStyle(lineWidth: width + 4, lineCap: .butt, dash: [5, 5]))
        tunnel.stroke(
          path, with: .color(Ink.waterDeep),
          style: StrokeStyle(lineWidth: width, lineCap: .butt, dash: [5, 5]))
      }
      for station in game.stations { drawStation(station, context: &context, size: size) }
      for train in game.trains { drawTrain(train, context: &context, size: size) }
      if !decorative { furniture(&context, size) }
    }
  }

  // MARK: Geometry

  private func position(_ point: MapPoint, _ size: CGSize) -> CGPoint {
    CGPoint(x: snap(point.x * size.width), y: snap(point.y * size.height))
  }

  private func snap(_ value: Double) -> Double { (value / 2).rounded() * 2 }

  /// Octilinear polyline between two stations (a 45° run followed by an axis-aligned run),
  /// canonicalised on station order so shared segments align across lines.
  private func segmentPoints(_ route: Int, _ a: Int, _ b: Int, _ size: CGSize) -> [CGPoint] {
    let from = position(game.stations[min(a, b)].point, size)
    let to = position(game.stations[max(a, b)].point, size)
    let dx = to.x - from.x
    let dy = to.y - from.y
    let run = min(abs(dx), abs(dy))
    let diagonalFirst = CGPoint(
      x: from.x + run * (dx < 0 ? -1 : 1), y: from.y + run * (dy < 0 ? -1 : 1))
    let straightFirst = CGPoint(
      x: to.x - run * (dx < 0 ? -1 : 1), y: to.y - run * (dy < 0 ? -1 : 1))
    let direct = riverCrossings([from, to], size)
    let bend =
      riverCrossings([from, diagonalFirst, to], size) == direct
        || riverCrossings([from, straightFirst, to], size) != direct ? diagonalFirst : straightFirst
    var points = [from]
    for point in [bend, to] where hypot(point.x - points.last!.x, point.y - points.last!.y) > 1 {
      points.append(point)
    }
    let offset = segmentOffset(route, min(a, b), max(a, b), size)
    if offset != .zero, points.count >= 2 {
      let first = points[0]
      let firstNext = points[1]
      let last = points[points.count - 1]
      let lastPrev = points[points.count - 2]
      let lead1 = advance(first, toward: firstNext, by: min(14, distance(first, firstNext) / 2.2))
      let lead2 = advance(last, toward: lastPrev, by: min(14, distance(last, lastPrev) / 2.2))
      var shifted = Array(points.dropFirst().dropLast()).map {
        CGPoint(x: $0.x + offset.x, y: $0.y + offset.y)
      }
      shifted.insert(CGPoint(x: lead1.x + offset.x, y: lead1.y + offset.y), at: 0)
      shifted.append(CGPoint(x: lead2.x + offset.x, y: lead2.y + offset.y))
      points = [first] + shifted + [last]
    }
    return a <= b ? points : points.reversed()
  }

  private func riverCrossings(_ points: [CGPoint], _ size: CGSize) -> Int {
    var crossings = 0
    var side: Double?
    for (a, b) in zip(points, points.dropFirst()) {
      for step in 0...24 {
        let t = Double(step) / 24
        let x = a.x + (b.x - a.x) * t
        let y = a.y + (b.y - a.y) * t
        let current = x - game.city.riverX(at: y / size.height) * size.width
        if let previous = side, previous * current < 0 { crossings += 1 }
        side = current
      }
    }
    return crossings
  }

  private func distance(_ a: CGPoint, _ b: CGPoint) -> Double { hypot(a.x - b.x, a.y - b.y) }

  private func advance(_ point: CGPoint, toward target: CGPoint, by length: Double) -> CGPoint {
    let total = max(0.001, distance(point, target))
    return CGPoint(
      x: point.x + (target.x - point.x) / total * length,
      y: point.y + (target.y - point.y) / total * length)
  }

  private func routePath(_ route: Route, _ size: CGSize) -> Path {
    var points: [CGPoint] = []
    for (a, b) in zip(route.stops, route.stops.dropFirst()) {
      let segment = segmentPoints(route.id, a, b, size)
      points += points.isEmpty ? segment : Array(segment.dropFirst())
    }
    var path = Path()
    guard let first = points.first else { return path }
    path.move(to: first)
    for point in points.dropFirst() { path.addLine(to: point) }
    return path
  }

  private func segmentOffset(_ route: Int, _ a: Int, _ b: Int, _ size: CGSize) -> CGPoint {
    let shared = game.routes.filter {
      zip($0.stops, $0.stops.dropFirst()).contains { x, y in
        (x == a && y == b) || (x == b && y == a)
      }
    }.map(\.id)
    guard shared.count > 1, let index = shared.firstIndex(of: route) else { return .zero }
    let from = position(game.stations[a].point, size)
    let to = position(game.stations[b].point, size)
    let length = max(1, distance(from, to))
    let offset = (Double(index) - Double(shared.count - 1) / 2) * 8
    return CGPoint(x: -(to.y - from.y) / length * offset, y: (to.x - from.x) / length * offset)
  }

  private func pointAlong(_ points: [CGPoint], fraction: Double) -> (CGPoint, Double) {
    let lengths = zip(points, points.dropFirst()).map { distance($0, $1) }
    let total = lengths.reduce(0, +)
    var remaining = max(0, min(1, fraction)) * total
    for (index, length) in lengths.enumerated() {
      let a = points[index]
      let b = points[index + 1]
      if remaining <= length || index == lengths.count - 1 {
        let t = length > 0 ? remaining / length : 0
        return (
          CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t), atan2(b.y - a.y, b.x - a.x)
        )
      }
      remaining -= length
    }
    return (points.first ?? .zero, 0)
  }

  // MARK: Terrain

  private func land(_ context: inout GraphicsContext, _ size: CGSize) {
    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Ink.grass))
    let tile = decorative ? 8.0 : 12.0
    var checker = Path()
    let columns = Int(size.width / tile) + 1
    let rows = Int(size.height / tile) + 1
    for column in 0..<columns {
      for row in 0..<rows where (column + row) % 2 == 0 {
        checker.addRect(
          CGRect(x: Double(column) * tile, y: Double(row) * tile, width: tile, height: tile))
      }
    }
    context.fill(checker, with: .color(Ink.grassDeep.opacity(0.55)))
    var generator = SeededGenerator(state: game.city == .harbour ? 7 : 19)
    let stations = game.city.stations.map { position($0, size) }
    var tufts = Path()
    var flowers = Path()
    var trees: [CGPoint] = []
    for _ in 0..<(decorative ? 40 : 110) {
      let x = snap(Double(generator.next() % 1_000) / 1_000 * size.width)
      let y = snap(Double(generator.next() % 1_000) / 1_000 * size.height)
      let riverX = game.city.riverX(at: y / size.height) * size.width
      guard abs(x - riverX) > 34 else { continue }
      let clearance = stations.map { distance($0, CGPoint(x: x, y: y)) }.min() ?? 100
      switch generator.next() % 10 {
      case 0 where clearance > 40 && !decorative && trees.count < 9:
        trees.append(CGPoint(x: x, y: y))
      case 1, 2:
        flowers.addRect(CGRect(x: x, y: y, width: 2, height: 2))
      default:
        tufts.addRect(CGRect(x: x, y: y, width: 2, height: 2))
        tufts.addRect(CGRect(x: x + 4, y: y - 2, width: 2, height: 2))
        tufts.addRect(CGRect(x: x + 2, y: y + 2, width: 2, height: 2))
      }
    }
    context.fill(tufts, with: .color(Ink.leaf.opacity(0.55)))
    context.fill(flowers, with: .color(Ink.cream))
    for tree in trees {
      var canopy = Path()
      canopy.addRect(CGRect(x: tree.x - 6, y: tree.y - 10, width: 12, height: 10))
      canopy.addRect(CGRect(x: tree.x - 4, y: tree.y - 13, width: 8, height: 3))
      canopy.addRect(CGRect(x: tree.x - 2, y: tree.y - 15, width: 4, height: 2))
      context.fill(
        canopy.applying(CGAffineTransform(translationX: 0, y: 2)), with: .color(Ink.outline))
      context.fill(
        Path(CGRect(x: tree.x - 2, y: tree.y, width: 4, height: 4)), with: .color(Ink.outline))
      context.fill(canopy, with: .color(Ink.leaf))
      context.fill(
        Path(CGRect(x: tree.x - 4, y: tree.y - 11, width: 4, height: 2)), with: .color(Ink.grass))
    }
  }

  private func riverPath(_ size: CGSize) -> Path {
    let half = decorative ? 10.0 : 15.0
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    for step in stride(from: -3, through: 103, by: 2) {
      let y = Double(step) / 100
      let center = game.city.riverX(at: y) * size.width
      let width = half * (1 + 0.22 * sin(y * 9 + 0.8))
      left.append(CGPoint(x: snap(center - width), y: snap(y * size.height)))
      right.append(CGPoint(x: snap(center + width), y: snap(y * size.height)))
    }
    var path = Path()
    path.move(to: left[0])
    for point in left.dropFirst() { path.addLine(to: point) }
    for point in right.reversed() { path.addLine(to: point) }
    path.closeSubpath()
    return path
  }

  private func water(_ context: inout GraphicsContext, _ river: Path, _ size: CGSize) {
    context.stroke(river, with: .color(Ink.sand), lineWidth: decorative ? 8 : 12)
    context.stroke(river, with: .color(Ink.outline), lineWidth: 4)
    context.fill(river, with: .color(Ink.water))
    var deep = context
    deep.clip(to: river)
    var channel = Path()
    for step in stride(from: -2, through: 102, by: 2) {
      let y = Double(step) / 100
      let point = CGPoint(x: snap(game.city.riverX(at: y) * size.width), y: snap(y * size.height))
      if step == -2 { channel.move(to: point) } else { channel.addLine(to: point) }
    }
    deep.stroke(channel, with: .color(Ink.waterDeep), lineWidth: decorative ? 8 : 12)
    var waves = Path()
    let spacing = decorative ? 10.0 : 14.0
    var row = 0
    for y in stride(from: 0.0, through: size.height, by: spacing) {
      let phase = reduceMotion ? 0.0 : Double((frame + row) % 2) * 4
      let center = game.city.riverX(at: y / size.height) * size.width
      for lane in [-0.45, 0.4] {
        let x = snap(center + lane * (decorative ? 14 : 22) + phase)
        waves.addRect(CGRect(x: x, y: snap(y), width: 6, height: 2))
        waves.addRect(CGRect(x: x + 6, y: snap(y) - 2, width: 2, height: 2))
      }
      row += 1
    }
    deep.fill(waves, with: .color(Ink.white.opacity(0.85)))
    if !decorative {
      let label = position(MapPoint(x: game.city.riverX(at: 0.96), y: 0.96), size)
      let text = "RIVER"
      context.fill(
        PixelFont.path(
          text, scale: 1,
          at: CGPoint(x: label.x - PixelFont.width(text, scale: 1) / 2, y: label.y - 3)),
        with: .color(Ink.white))
    }
  }

  private func furniture(_ context: inout GraphicsContext, _ size: CGSize) {
    let origin = CGPoint(x: size.width - 34, y: 14)
    context.fill(
      Path(CGRect(x: origin.x - 4, y: origin.y - 4, width: 26, height: 30)),
      with: .color(Ink.cream.opacity(0.9)))
    context.stroke(
      Path(CGRect(x: origin.x - 4, y: origin.y - 4, width: 26, height: 30)),
      with: .color(Ink.outline), lineWidth: 2)
    var arrow = Path()
    arrow.addRect(CGRect(x: origin.x + 8, y: origin.y, width: 2, height: 4))
    arrow.addRect(CGRect(x: origin.x + 6, y: origin.y + 2, width: 6, height: 2))
    arrow.addRect(CGRect(x: origin.x + 4, y: origin.y + 4, width: 10, height: 2))
    arrow.addRect(CGRect(x: origin.x + 8, y: origin.y + 6, width: 2, height: 6))
    context.fill(arrow, with: .color(Ink.ember))
    context.fill(
      PixelFont.path("N", scale: 1.5, at: CGPoint(x: origin.x + 5, y: origin.y + 14)),
      with: .color(Ink.outline))
    let scaleY = size.height - 16.0
    var scale = Path()
    scale.addRect(CGRect(x: 16, y: scaleY, width: 48, height: 2))
    scale.addRect(CGRect(x: 16, y: scaleY - 4, width: 2, height: 10))
    scale.addRect(CGRect(x: 39, y: scaleY - 2, width: 2, height: 6))
    scale.addRect(CGRect(x: 62, y: scaleY - 4, width: 2, height: 10))
    context.fill(scale, with: .color(Ink.outline))
    context.fill(
      PixelFont.path("1KM", scale: 1, at: CGPoint(x: 32, y: scaleY - 13)), with: .color(Ink.outline)
    )
  }

  // MARK: Stations and trains

  private func drawStation(_ station: Station, context: inout GraphicsContext, size: CGSize) {
    let center = position(station.point, size)
    let radius = decorative ? 6.0 : 10.0
    let interchange = game.routes.filter { $0.stops.contains(station.id) }.count > 1
    let crowded = station.waiting.count >= TransitSimulation.crowdLimit
    if !decorative {
      if interchange {
        let plate = CGRect(x: center.x - 16, y: center.y - 16, width: 32, height: 32)
        context.fill(Path(plate), with: .color(Ink.cream))
        context.stroke(Path(plate), with: .color(Ink.outline), lineWidth: 2)
      }
      if game.routes[selected].stops.last == station.id {
        let reach = 20.0 + Double(frame) * 2
        let target = CGRect(
          x: center.x - reach, y: center.y - reach, width: reach * 2, height: reach * 2)
        context.stroke(
          Path(target), with: .color(Ink.routes[selected]),
          style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
      }
      if station.id >= 4, game.elapsed - Double(station.id - 3) * 28 < 9 {
        let bounce = reduceMotion ? 0.0 : Double(frame) * 3
        let text = "NEW!"
        let width = PixelFont.width(text, scale: 1.5) + 8
        let tag = CGRect(
          x: center.x - width / 2, y: center.y - 40 - bounce, width: width, height: 16)
        context.fill(Path(tag), with: .color(Ink.sun))
        context.stroke(Path(tag), with: .color(Ink.outline), lineWidth: 2)
        context.fill(
          PixelFont.path(text, scale: 1.5, at: CGPoint(x: tag.minX + 4, y: tag.minY + 3)),
          with: .color(Ink.outline))
        var pointer = Path()
        pointer.addRect(CGRect(x: center.x - 3, y: tag.maxY, width: 6, height: 2))
        pointer.addRect(CGRect(x: center.x - 1, y: tag.maxY + 2, width: 2, height: 2))
        context.fill(pointer, with: .color(Ink.outline))
      }
    }
    if station.arrivalGlow > 0, !reduceMotion {
      let spread = snap(16 + (1.2 - station.arrivalGlow) * 10)
      context.stroke(
        Path(
          CGRect(x: center.x - spread, y: center.y - spread, width: spread * 2, height: spread * 2)),
        with: .color(Ink.sun.opacity(min(1, station.arrivalGlow))), lineWidth: 2)
    }
    let rect = CGRect(
      x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    let shape = StationGlyph(kind: station.kind).path(in: rect)
    context.fill(
      shape.applying(CGAffineTransform(translationX: 0, y: 2)), with: .color(Ink.outline))
    context.fill(shape, with: .color(crowded && frame == 0 ? Ink.ember : Ink.white))
    context.stroke(
      shape, with: .color(Ink.outline),
      style: StrokeStyle(lineWidth: decorative ? 2 : 3, lineJoin: .miter))
    if decorative { return }
    if crowded {
      let bar = CGRect(x: center.x - 15, y: center.y + 13, width: 30, height: 7)
      context.fill(Path(bar), with: .color(Ink.outline))
      let fill = 26 * min(1, station.pressure / TransitSimulation.overloadDuration)
      context.fill(
        Path(CGRect(x: bar.minX + 2, y: bar.minY + 2, width: snap(fill), height: 3)),
        with: .color(Ink.ember))
    }
    let failed = game.failedStation?.id == station.id
    if failed {
      let text = "FULL!"
      let width = PixelFont.width(text, scale: 1.5) + 8
      let tag = CGRect(x: center.x - width / 2, y: center.y - 40, width: width, height: 16)
      context.fill(Path(tag), with: .color(Ink.ember))
      context.stroke(Path(tag), with: .color(Ink.outline), lineWidth: 2)
      context.fill(
        PixelFont.path(text, scale: 1.5, at: CGPoint(x: tag.minX + 4, y: tag.minY + 3)),
        with: .color(Ink.white))
    }
    if !crowded {
      let label = String(format: "%02d", station.id + 1)
      let plate = CGRect(x: center.x - 26, y: center.y + 12, width: 20, height: 11)
      context.fill(Path(plate), with: .color(Ink.cream))
      context.stroke(Path(plate), with: .color(Ink.outline), lineWidth: 1.5)
      context.fill(
        PixelFont.path(label, scale: 1, at: CGPoint(x: plate.minX + 4.5, y: plate.minY + 2)),
        with: .color(Ink.outline))
    }
    let rightSpace = size.width - center.x
    let startX = rightSpace < 65 ? center.x - 50 : center.x + 18
    if !station.waiting.isEmpty {
      let count = min(12, station.waiting.count)
      let rows = (count + 3) / 4
      let queue = CGRect(
        x: startX - 3, y: center.y - 12,
        width: Double(min(4, count)) * 8 + 4,
        height: Double(rows) * 9 + (station.waiting.count > 12 ? 13 : 3))
      context.fill(Path(queue), with: .color(Ink.cream))
      context.stroke(Path(queue), with: .color(Ink.outline), lineWidth: 1.5)
    }
    for (index, kind) in station.waiting.prefix(12).enumerated() {
      let glyph = CGRect(
        x: startX + Double(index % 4) * 8, y: center.y - 9 + Double(index / 4) * 9, width: 6,
        height: 6)
      let sprite = StationGlyph(kind: kind).path(in: glyph)
      context.stroke(
        sprite, with: .color(Ink.outline), style: StrokeStyle(lineWidth: 2, lineJoin: .miter))
      context.fill(sprite, with: .color(crowded ? Ink.ember : Ink.routes[kind.rawValue % 4]))
    }
    if station.waiting.count > 12 {
      context.fill(
        PixelFont.path(
          "+\(station.waiting.count - 12)", scale: 1, at: CGPoint(x: startX, y: center.y + 17)),
        with: .color(Ink.ember))
    }
  }

  private func drawTrain(_ train: Train, context: inout GraphicsContext, size: CGSize) {
    let route = game.routes[train.route]
    guard route.stops.count > 1 else { return }
    let nextIndex = train.stopIndex + train.direction
    guard route.stops.indices.contains(nextIndex) else { return }
    let points = segmentPoints(
      train.route, route.stops[train.stopIndex], route.stops[nextIndex], size)
    let (exact, angle) = pointAlong(points, fraction: train.progress)
    let center = CGPoint(x: snap(exact.x), y: snap(exact.y))
    let color = Ink.routes[train.route]
    let scale = decorative ? 0.7 : 1.0
    var layer = context
    layer.translateBy(x: center.x, y: center.y)
    layer.rotate(by: .radians(angle))
    layer.scaleBy(x: scale, y: scale)
    let body = CGRect(x: -12, y: -6, width: 24, height: 12)
    layer.fill(
      Path(body.offsetBy(dx: 0, dy: 3)).applying(.identity), with: .color(Ink.outline.opacity(0.35))
    )
    var wheels = Path()
    let bob = Double(frame)
    wheels.addRect(CGRect(x: -9, y: 5 + bob, width: 5, height: 4))
    wheels.addRect(CGRect(x: 4, y: 5 + bob, width: 5, height: 4))
    layer.fill(wheels, with: .color(Ink.outline))
    layer.fill(Path(body), with: .color(Ink.outline))
    layer.fill(Path(body.insetBy(dx: 2, dy: 2)), with: .color(color))
    layer.fill(
      Path(CGRect(x: -10, y: -4, width: 20, height: 2)), with: .color(Color.white.opacity(0.4)))
    layer.fill(Path(CGRect(x: 6, y: -4, width: 4, height: 8)), with: .color(Ink.outline))
    layer.fill(Path(CGRect(x: 10, y: -2, width: 2, height: 4)), with: .color(Ink.sun))
    for index in 0..<3 {
      let window = CGRect(x: -9 + Double(index) * 5, y: -2, width: 3, height: 4)
      let lit =
        index
        < Int((Double(train.passengers.count) / Double(max(1, route.capacity)) * 3).rounded(.up))
      layer.fill(Path(window), with: .color(lit ? Ink.sun : Ink.water))
    }
  }
}
