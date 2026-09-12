import SwiftUI

struct StationGlyph: Shape {
  let kind: StationKind
  func path(in rect: CGRect) -> Path {
    var path = Path()
    switch kind {
    case .circle:
      path.addEllipse(in: rect)
    case .square:
      path.addRoundedRect(
        in: rect, cornerSize: CGSize(width: rect.width * 0.12, height: rect.height * 0.12))
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

/// Renders the city as a printed transit diagram: octilinear routes with rounded bends,
/// a layered estuary with dashed tunnel sections, and cartographic furniture.
struct MapDrawing: View {
  let game: TransitSimulation
  let selected: Int
  var decorative = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        context.stroke(
          path.applying(CGAffineTransform(translationX: 0, y: 2)),
          with: .color(Ink.navyDeep.opacity(emphasis ? 0.16 : 0.08)),
          style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
        context.stroke(
          path, with: .color(Ink.paperLight),
          style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
        context.stroke(
          path, with: .color(Ink.routes[route.id].opacity(emphasis ? 1 : 0.72)),
          style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round))
        var tunnel = context
        tunnel.clip(to: river)
        tunnel.stroke(
          path, with: .color(Ink.paperLight.opacity(0.85)),
          style: StrokeStyle(lineWidth: 1.8, lineCap: .butt, dash: [3.5, 4.5]))
      }
      for station in game.stations { drawStation(station, context: &context, size: size) }
      for train in game.trains { drawTrain(train, context: &context, size: size) }
      if !decorative { furniture(&context, size) }
    }
  }

  // MARK: Geometry

  private func position(_ point: MapPoint, _ size: CGSize) -> CGPoint {
    CGPoint(x: point.x * size.width, y: point.y * size.height)
  }

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
    return roundedPath(points, radius: 11)
  }

  private func roundedPath(_ points: [CGPoint], radius: Double) -> Path {
    var path = Path()
    guard let first = points.first else { return path }
    path.move(to: first)
    guard points.count > 2 else {
      for point in points.dropFirst() { path.addLine(to: point) }
      return path
    }
    for index in 1..<(points.count - 1) {
      let previous = points[index - 1]
      let corner = points[index]
      let next = points[index + 1]
      let r = min(radius, distance(previous, corner) / 2, distance(corner, next) / 2)
      path.addLine(to: advance(corner, toward: previous, by: r))
      path.addQuadCurve(to: advance(corner, toward: next, by: r), control: corner)
    }
    path.addLine(to: points[points.count - 1])
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
    let offset = (Double(index) - Double(shared.count - 1) / 2) * 7.5
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
    for x in stride(from: 9.0, through: size.width, by: 18) {
      for y in stride(from: 9.0, through: size.height, by: 18) {
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: 1.1, height: 1.1)),
          with: .color(Ink.navy.opacity(0.13)))
      }
    }
    for (index, phase) in [0.0, 1.9, 3.7].enumerated() {
      var contour = Path()
      for step in 0...40 {
        let t = Double(step) / 40
        let point = CGPoint(
          x: t * size.width,
          y: size.height * (0.18 + 0.28 * Double(index)) + sin(t * 5 + phase) * size.height * 0.05)
        if step == 0 { contour.move(to: point) } else { contour.addLine(to: point) }
      }
      context.stroke(contour, with: .color(Ink.navy.opacity(0.06)), lineWidth: 0.8)
    }
    let parks: [CGRect] = [
      CGRect(
        x: size.width * 0.05, y: size.height * 0.08, width: size.width * 0.16,
        height: size.height * 0.10),
      CGRect(
        x: size.width * 0.66, y: size.height * 0.49, width: size.width * 0.22,
        height: size.height * 0.09),
      CGRect(
        x: size.width * 0.28, y: size.height * 0.63, width: size.width * 0.11,
        height: size.height * 0.15),
    ]
    for rect in parks {
      let park = Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) * 0.45)
      context.fill(park, with: .color(Ink.park.opacity(0.35)))
      context.stroke(
        park, with: .color(Ink.park.opacity(0.9)),
        style: StrokeStyle(lineWidth: 0.8, dash: [1.5, 3]))
    }
  }

  private func riverPath(_ size: CGSize) -> Path {
    let half = decorative ? 12.0 : 16.0
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    for step in -3...103 {
      let y = Double(step) / 100
      let center = game.city.riverX(at: y) * size.width
      let width = half * (1 + 0.22 * sin(y * 9 + 0.8))
      left.append(CGPoint(x: center - width, y: y * size.height))
      right.append(CGPoint(x: center + width, y: y * size.height))
    }
    var path = Path()
    path.move(to: left[0])
    for point in left.dropFirst() { path.addLine(to: point) }
    for point in right.reversed() { path.addLine(to: point) }
    path.closeSubpath()
    return path
  }

  private func water(_ context: inout GraphicsContext, _ river: Path, _ size: CGSize) {
    context.stroke(river, with: .color(Ink.sea.opacity(0.10)), lineWidth: 16)
    context.stroke(river, with: .color(Ink.sea.opacity(0.14)), lineWidth: 6)
    context.fill(
      river,
      with: .linearGradient(
        Gradient(colors: [Ink.sea, Ink.navy]), startPoint: .zero,
        endPoint: CGPoint(x: size.width * 0.3, y: size.height)))
    context.stroke(river, with: .color(Ink.paperLight), lineWidth: 1.2)
    var channel = Path()
    for step in -2...102 {
      let y = Double(step) / 100
      let point = CGPoint(x: game.city.riverX(at: y) * size.width, y: y * size.height)
      if step == -2 { channel.move(to: point) } else { channel.addLine(to: point) }
    }
    context.stroke(
      channel, with: .color(Ink.paperLight.opacity(0.22)),
      style: StrokeStyle(lineWidth: 0.7, dash: [4, 7]))
    var waves = context
    waves.clip(to: river)
    for lane in [-0.55, 0.5] {
      var ripple = Path()
      for step in -2...102 {
        let y = Double(step) / 100
        let point = CGPoint(
          x: (game.city.riverX(at: y) + lane * 0.035) * size.width + sin(y * 40) * 1.5,
          y: y * size.height)
        if step == -2 { ripple.move(to: point) } else { ripple.addLine(to: point) }
      }
      waves.stroke(ripple, with: .color(Ink.paperLight.opacity(0.12)), lineWidth: 0.8)
    }
    if !decorative {
      let label = position(MapPoint(x: game.city.riverX(at: 0.955), y: 0.955), size)
      context.draw(
        Text("R I V E R").font(.system(size: 6, weight: .semibold)).foregroundStyle(
          Ink.paperLight.opacity(0.75)), at: label)
    }
  }

  private func furniture(_ context: inout GraphicsContext, _ size: CGSize) {
    let compass = CGPoint(x: size.width - 26, y: 30)
    context.stroke(
      Path(ellipseIn: CGRect(x: compass.x - 11, y: compass.y - 11, width: 22, height: 22)),
      with: .color(Ink.navy.opacity(0.35)), lineWidth: 0.8)
    var star = Path()
    for index in 0..<4 {
      let angle = Double(index) * .pi / 2 - .pi / 2
      star.move(to: CGPoint(x: compass.x + cos(angle) * 15, y: compass.y + sin(angle) * 15))
      star.addLine(
        to: CGPoint(x: compass.x + cos(angle - 0.55) * 3.2, y: compass.y + sin(angle - 0.55) * 3.2))
      star.addLine(
        to: CGPoint(x: compass.x + cos(angle + 0.55) * 3.2, y: compass.y + sin(angle + 0.55) * 3.2))
      star.closeSubpath()
    }
    context.fill(star, with: .color(Ink.navy.opacity(0.7)))
    var north = Path()
    north.move(to: CGPoint(x: compass.x, y: compass.y - 15))
    north.addLine(
      to: CGPoint(
        x: compass.x + cos(-.pi / 2 - 0.55) * 3.2, y: compass.y + sin(-.pi / 2 - 0.55) * 3.2))
    north.addLine(
      to: CGPoint(
        x: compass.x + cos(-.pi / 2 + 0.55) * 3.2, y: compass.y + sin(-.pi / 2 + 0.55) * 3.2))
    north.closeSubpath()
    context.fill(north, with: .color(Ink.routes[0]))
    context.draw(
      Text("N").font(.system(size: 7, weight: .semibold, design: .serif)).foregroundStyle(
        Ink.navy.opacity(0.7)),
      at: CGPoint(x: compass.x, y: compass.y - 22))
    let scaleY = size.height - 14.0
    var scale = Path()
    scale.move(to: CGPoint(x: 18, y: scaleY))
    scale.addLine(to: CGPoint(x: 62, y: scaleY))
    for x in [18.0, 40, 62] {
      scale.move(to: CGPoint(x: x, y: scaleY - 3))
      scale.addLine(to: CGPoint(x: x, y: scaleY + 3))
    }
    context.stroke(scale, with: .color(Ink.navy.opacity(0.5)), lineWidth: 1)
    context.draw(
      Text("1 KM").font(.system(size: 6, weight: .semibold)).foregroundStyle(
        Ink.navy.opacity(0.5)),
      at: CGPoint(x: 40, y: scaleY - 8))
  }

  // MARK: Stations and trains

  private func drawStation(_ station: Station, context: inout GraphicsContext, size: CGSize) {
    let center = position(station.point, size)
    let radius = decorative ? 6.5 : 10.0
    let interchange = game.routes.filter { $0.stops.contains(station.id) }.count > 1
    if !decorative {
      if interchange {
        let ring = Path(
          ellipseIn: CGRect(x: center.x - 15, y: center.y - 15, width: 30, height: 30))
        context.fill(ring, with: .color(Ink.paperLight))
        context.stroke(ring, with: .color(Ink.navy.opacity(0.55)), lineWidth: 1.2)
      }
      if game.routes[selected].stops.last == station.id {
        context.stroke(
          Path(ellipseIn: CGRect(x: center.x - 19, y: center.y - 19, width: 38, height: 38)),
          with: .color(Ink.routes[selected].opacity(0.55)),
          style: StrokeStyle(lineWidth: 1.5, dash: [2, 4]))
      }
      if station.id >= 4, game.elapsed - Double(station.id - 3) * 28 < 9 {
        let opacity = reduceMotion ? 0.6 : 0.4 + 0.2 * sin(game.elapsed * 3)
        context.stroke(
          Path(ellipseIn: CGRect(x: center.x - 22, y: center.y - 22, width: 44, height: 44)),
          with: .color(Ink.routes[0].opacity(opacity)), lineWidth: 2)
        let tag = CGRect(x: center.x - 15, y: center.y - 38, width: 30, height: 13)
        context.fill(Path(roundedRect: tag, cornerRadius: 6.5), with: .color(Ink.routes[0]))
        context.draw(
          Text("NEW").font(.system(size: 7, weight: .bold)).foregroundStyle(Ink.paperLight),
          at: CGPoint(x: center.x, y: center.y - 31.5))
      }
    }
    if station.arrivalGlow > 0, !reduceMotion {
      let spread = 18 + (1.2 - station.arrivalGlow) * 8
      context.stroke(
        Path(
          ellipseIn: CGRect(
            x: center.x - spread, y: center.y - spread, width: spread * 2, height: spread * 2)),
        with: .color(Ink.gold.opacity(station.arrivalGlow * 0.55)), lineWidth: 2)
    }
    if station.waiting.count >= TransitSimulation.crowdLimit {
      let circle = Path(
        ellipseIn: CGRect(x: center.x - 17, y: center.y - 17, width: 34, height: 34))
      context.stroke(circle, with: .color(Ink.routes[0].opacity(0.2)), lineWidth: 3.5)
      var arc = Path()
      arc.addArc(
        center: center, radius: 17, startAngle: .degrees(-90),
        endAngle: .degrees(-90 + 360 * station.pressure / TransitSimulation.overloadDuration),
        clockwise: false)
      context.stroke(
        arc, with: .color(Ink.routes[0]), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
    }
    let rect = CGRect(
      x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    let shape = StationGlyph(kind: station.kind).path(in: rect)
    context.fill(
      shape.applying(CGAffineTransform(translationX: 0, y: 1.5)),
      with: .color(Ink.navyDeep.opacity(0.18)))
    context.fill(shape, with: .color(Ink.paperLight))
    context.stroke(
      shape, with: .color(Ink.navy),
      style: StrokeStyle(lineWidth: decorative ? 2 : 2.6, lineJoin: .round))
    if decorative { return }
    let failed = game.failedStation?.id == station.id
    if failed {
      let label = CGRect(x: center.x - 27, y: center.y - 38, width: 54, height: 15)
      context.fill(Path(roundedRect: label, cornerRadius: 7.5), with: .color(Ink.routes[0]))
      context.draw(
        Text("CROWDED").font(.system(size: 7, weight: .bold)).foregroundStyle(Ink.paperLight),
        at: CGPoint(x: center.x, y: center.y - 30.5))
    }
    let idLabel = CGRect(x: center.x - 27, y: center.y + 12, width: 23, height: 13)
    context.fill(Path(roundedRect: idLabel, cornerRadius: 3), with: .color(Ink.paperLight))
    context.stroke(
      Path(roundedRect: idLabel, cornerRadius: 3), with: .color(Ink.rule), lineWidth: 0.6)
    context.draw(
      Text(String(format: "%02d", station.id + 1)).font(
        .system(size: 9.5, weight: .bold, design: .monospaced)
      ).foregroundStyle(failed ? Ink.routes[0] : Ink.navy.opacity(0.8)),
      at: CGPoint(x: center.x - 15.5, y: center.y + 18.5))
    let rightSpace = size.width - center.x
    let startX = rightSpace < 65 ? center.x - 48 : center.x + 19
    if !station.waiting.isEmpty {
      let count = min(12, station.waiting.count)
      let rows = (count + 3) / 4
      let queue = CGRect(
        x: startX - 3, y: center.y - 11,
        width: Double(min(4, count)) * 8 + 4,
        height: Double(rows) * 9 + (station.waiting.count > 12 ? 15 : 3))
      let backing = Path(roundedRect: queue, cornerRadius: 4)
      context.fill(backing, with: .color(Ink.paperLight))
      context.stroke(backing, with: .color(Ink.rule), lineWidth: 0.6)
    }
    for (index, kind) in station.waiting.prefix(12).enumerated() {
      let glyph = CGRect(
        x: startX + Double(index % 4) * 8, y: center.y - 8 + Double(index / 4) * 9, width: 6,
        height: 6)
      context.fill(
        StationGlyph(kind: kind).path(in: glyph),
        with: .color(station.waiting.count >= 12 ? Ink.routes[0] : Ink.navy.opacity(0.85)))
    }
    if station.waiting.count > 12 {
      context.draw(
        Text("+\(station.waiting.count - 12)").font(.system(size: 7, weight: .bold))
          .foregroundStyle(Ink.routes[0]), at: CGPoint(x: startX + 10, y: center.y + 25))
    }
  }

  private func drawTrain(_ train: Train, context: inout GraphicsContext, size: CGSize) {
    let route = game.routes[train.route]
    guard route.stops.count > 1 else { return }
    let nextIndex = train.stopIndex + train.direction
    guard route.stops.indices.contains(nextIndex) else { return }
    let points = segmentPoints(
      train.route, route.stops[train.stopIndex], route.stops[nextIndex], size)
    let (center, angle) = pointAlong(points, fraction: train.progress)
    let color = Ink.routes[train.route]
    let scale = decorative ? 0.8 : 1.0
    var layer = context
    layer.translateBy(x: center.x, y: center.y)
    layer.rotate(by: .radians(angle))
    layer.scaleBy(x: scale, y: scale)
    var body = Path()
    body.move(to: CGPoint(x: -11, y: -5.5))
    body.addLine(to: CGPoint(x: 7, y: -5.5))
    body.addQuadCurve(to: CGPoint(x: 12, y: 0), control: CGPoint(x: 12, y: -5.5))
    body.addQuadCurve(to: CGPoint(x: 7, y: 5.5), control: CGPoint(x: 12, y: 5.5))
    body.addLine(to: CGPoint(x: -11, y: 5.5))
    body.addQuadCurve(to: CGPoint(x: -11, y: -5.5), control: CGPoint(x: -14, y: 0))
    body.closeSubpath()
    layer.fill(
      body.applying(CGAffineTransform(translationX: 0, y: 2.2)),
      with: .color(Ink.navyDeep.opacity(0.28)))
    layer.fill(body, with: .color(color))
    layer.fill(
      Path(roundedRect: CGRect(x: -10, y: -4.5, width: 20, height: 3.5), cornerRadius: 1.5),
      with: .color(Color.white.opacity(0.22)))
    layer.stroke(body, with: .color(Ink.paperLight), lineWidth: 1.4)
    for index in 0..<3 {
      let window = CGRect(x: -7.5 + Double(index) * 5, y: -2, width: 3.2, height: 4)
      let lit = index < train.passengers.count || !train.passengers.isEmpty && index == 0
      layer.fill(
        Path(roundedRect: window, cornerRadius: 0.8),
        with: .color(lit ? Ink.paperLight : Ink.paperLight.opacity(0.35)))
    }
    layer.fill(
      Path(ellipseIn: CGRect(x: 8.5, y: -1.2, width: 2.4, height: 2.4)),
      with: .color(Ink.gold))
  }
}
