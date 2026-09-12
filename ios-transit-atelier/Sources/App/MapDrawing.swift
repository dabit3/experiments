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
        in: rect, cornerSize: CGSize(width: rect.width * 0.08, height: rect.height * 0.08))
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

struct MapDrawing: View {
  let game: TransitSimulation
  let selected: Int
  var decorative = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    Canvas { context, size in
      grid(&context, size)
      water(&context, size)
      for route in game.routes where route.stops.count > 1 {
        var path = Path()
        for (index, stop) in route.stops.enumerated() {
          let point = position(game.stations[stop].point, size)
          if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        context.stroke(
          path, with: .color(Ink.paper),
          style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
        context.stroke(
          path,
          with: .color(Ink.routes[route.id].opacity(decorative || selected == route.id ? 1 : 0.78)),
          style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
      }
      for station in game.stations { drawStation(station, context: &context, size: size) }
      for train in game.trains { drawTrain(train, context: &context, size: size) }
      if decorative {
        context.draw(
          Text("T H E  C O A S T A L  C O L L E C T I O N")
            .font(.system(size: 7, weight: .medium))
            .foregroundStyle(Ink.muted),
          at: CGPoint(x: size.width / 2, y: size.height - 3))
      } else {
        context.draw(
          Text("N")
            .font(.system(size: 8, weight: .medium, design: .serif))
            .foregroundStyle(Ink.muted),
          at: CGPoint(x: size.width - 26, y: 25))
        var arrow = Path()
        arrow.move(to: CGPoint(x: size.width - 26, y: 33))
        arrow.addLine(to: CGPoint(x: size.width - 26, y: 46))
        context.stroke(arrow, with: .color(Ink.rule), lineWidth: 1)
      }
    }
  }

  private func position(_ point: MapPoint, _ size: CGSize) -> CGPoint {
    CGPoint(x: point.x * size.width, y: point.y * size.height)
  }

  private func grid(_ context: inout GraphicsContext, _ size: CGSize) {
    for x in stride(from: 8.0, through: size.width, by: 19) {
      for y in stride(from: 8.0, through: size.height, by: 19) {
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
          with: .color(Ink.rule.opacity(0.55)))
      }
    }
    let blocks: [CGRect] = [
      CGRect(
        x: size.width * 0.06, y: size.height * 0.09, width: size.width * 0.17,
        height: size.height * 0.09),
      CGRect(
        x: size.width * 0.68, y: size.height * 0.49, width: size.width * 0.23,
        height: size.height * 0.09),
      CGRect(
        x: size.width * 0.29, y: size.height * 0.64, width: size.width * 0.10,
        height: size.height * 0.15),
    ]
    for rect in blocks {
      context.fill(
        Path(roundedRect: rect, cornerRadius: 10),
        with: .color(Color(red: 0.84, green: 0.87, blue: 0.76).opacity(0.32)))
    }
  }

  private func water(_ context: inout GraphicsContext, _ size: CGSize) {
    var path = Path()
    for step in -2...102 {
      let y = Double(step) / 100
      let point = CGPoint(x: game.city.riverX(at: y) * size.width, y: y * size.height)
      if step == -2 { path.move(to: point) } else { path.addLine(to: point) }
    }
    context.stroke(path, with: .color(Ink.navy.opacity(0.09)), lineWidth: decorative ? 35 : 42)
    context.stroke(path, with: .color(Ink.navy), lineWidth: decorative ? 25 : 30)
    context.stroke(
      path, with: .color(Ink.paper.opacity(0.18)), style: StrokeStyle(lineWidth: 0.5, dash: [3, 8]))
    let label = position(MapPoint(x: game.city.riverX(at: 0.94), y: 0.94), size)
    context.draw(
      Text("R I V E R").font(.system(size: 6, weight: .medium)).foregroundStyle(
        Ink.paper.opacity(0.7)), at: label)
  }

  private func drawStation(_ station: Station, context: inout GraphicsContext, size: CGSize) {
    let center = position(station.point, size)
    let radius = decorative ? 7.0 : 9.0
    if station.arrivalGlow > 0, !reduceMotion {
      context.stroke(
        Path(ellipseIn: CGRect(x: center.x - 18, y: center.y - 18, width: 36, height: 36)),
        with: .color(Ink.routes[1].opacity(station.arrivalGlow * 0.4)), lineWidth: 2)
    }
    if station.waiting.count >= TransitSimulation.crowdLimit {
      let circle = Path(
        ellipseIn: CGRect(x: center.x - 17, y: center.y - 17, width: 34, height: 34))
      context.stroke(circle, with: .color(Ink.routes[0].opacity(0.2)), lineWidth: 3)
      var arc = Path()
      arc.addArc(
        center: center, radius: 17, startAngle: .degrees(-90),
        endAngle: .degrees(-90 + 360 * station.pressure / TransitSimulation.overloadDuration),
        clockwise: false)
      context.stroke(
        arc, with: .color(Ink.routes[0]), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    }
    let rect = CGRect(
      x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    let shape = StationGlyph(kind: station.kind).path(in: rect)
    context.fill(shape, with: .color(Ink.paper))
    context.stroke(
      shape, with: .color(Ink.navy), style: StrokeStyle(lineWidth: 2.3, lineJoin: .round))
    if !decorative {
      context.draw(
        Text(String(format: "%02d", station.id + 1)).font(
          .system(size: 7, weight: .medium, design: .monospaced)
        ).foregroundStyle(Ink.muted),
        at: CGPoint(x: center.x - 15, y: center.y + 18))
      let rightSpace = size.width - center.x
      let startX = rightSpace < 65 ? center.x - 45 : center.x + 16
      for (index, kind) in station.waiting.prefix(12).enumerated() {
        let glyph = CGRect(
          x: startX + Double(index % 4) * 7, y: center.y - 7 + Double(index / 4) * 8, width: 4.5,
          height: 4.5)
        context.fill(
          StationGlyph(kind: kind).path(in: glyph),
          with: .color(station.waiting.count >= 12 ? Ink.routes[0] : Ink.navy.opacity(0.8)))
      }
      if station.waiting.count > 12 {
        context.draw(
          Text("+\(station.waiting.count - 12)").font(.system(size: 7, weight: .bold))
            .foregroundStyle(Ink.routes[0]), at: CGPoint(x: startX + 10, y: center.y + 25))
      }
    }
  }

  private func drawTrain(_ train: Train, context: inout GraphicsContext, size: CGSize) {
    let route = game.routes[train.route]
    guard route.stops.count > 1 else { return }
    let center = position(game.trainPosition(train), size)
    let from = game.stations[route.stops[train.stopIndex]].point
    let nextIndex = train.stopIndex + train.direction
    guard route.stops.indices.contains(nextIndex) else { return }
    let to = game.stations[route.stops[nextIndex]].point
    let angle = atan2((to.y - from.y) * size.height, (to.x - from.x) * size.width)
    var layer = context
    layer.translateBy(x: center.x, y: center.y)
    layer.rotate(by: .radians(angle))
    let trainPath = Path(roundedRect: CGRect(x: -10, y: -5, width: 20, height: 10), cornerRadius: 3)
    layer.fill(trainPath, with: .color(Ink.routes[train.route]))
    layer.stroke(trainPath, with: .color(Ink.paper), lineWidth: 1.4)
    for index in 0..<min(3, max(1, train.passengers.count)) {
      let window = CGRect(x: -6 + Double(index) * 5, y: -2, width: 3, height: 4)
      layer.fill(
        Path(roundedRect: window, cornerRadius: 0.7),
        with: .color(Ink.paper.opacity(train.passengers.isEmpty ? 0.35 : 1)))
    }
  }
}
