import SwiftUI

enum HarborPalette {
  static let ink = Color(red: 0.025, green: 0.10, blue: 0.13)
  static let water = Color(red: 0.045, green: 0.31, blue: 0.33)
  static let deep = Color(red: 0.025, green: 0.20, blue: 0.24)
  static let foam = Color(red: 0.62, green: 0.85, blue: 0.80)
  static let ivory = Color(red: 0.97, green: 0.94, blue: 0.85)
  static let muted = Color(red: 0.61, green: 0.72, blue: 0.71)
  static let brass = Color(red: 0.83, green: 0.68, blue: 0.44)
  static let coral = Color(red: 0.91, green: 0.38, blue: 0.25)
}

struct HarborSea: View {
  @ObservedObject var model: HarborModel
  var decorative = false
  var postcard = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || postcard)) {
      timeline in
      Canvas { context, size in
        let time = reduceMotion || postcard ? 0 : timeline.date.timeIntervalSinceReferenceDate
        context.scaleBy(x: size.width / 360, y: size.height / 520)
        drawSea(&context, time: time)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "Harbor chart. \(model.convoy.count) of \(model.chart.boats.count) boats rescued. "
        + "Draw from the coral tug through the numbered boats to the HOME ring."
    )
    .accessibilityIdentifier("harborChart")
  }
}

extension HarborSea {
  private func drawSea(_ ctx: inout GraphicsContext, time: Double) {
    let chart = decorative ? HarborChart.campaign[0] : model.chart
    let rect = CGRect(x: 0, y: 0, width: 360, height: 520)
    ctx.draw(Image("SeaSurface"), in: rect)
    ctx.fill(
      Path(rect),
      with: .linearGradient(
        Gradient(colors: [
          HarborPalette.water.opacity(0.12), HarborPalette.deep.opacity(0.32),
          HarborPalette.ink.opacity(0.5),
        ]),
        startPoint: .zero, endPoint: CGPoint(x: 360, y: 540)))

    for index in 0..<24 {
      var wave = Path()
      let x = Double((index * 137) % 360)
      let y = Double((index * 89) % 520) + sin(time * 0.28 + Double(index)) * 2
      let length = 9.0 + Double(index % 5) * 4
      wave.move(to: CGPoint(x: x, y: y))
      wave.addQuadCurve(
        to: CGPoint(x: x + length, y: y - 2),
        control: CGPoint(x: x + length * 0.5, y: y - 5))
      ctx.stroke(
        wave, with: .color(HarborPalette.foam.opacity(0.05)),
        lineWidth: 0.65)
    }
    for index in 0..<110 {
      let x = Double((index * 137) % 360)
      let y = Double((index * 79) % 520)
      let shimmer = max(0, sin(time * 0.55 + Double(index) * 2.7))
      let point = SeaPoint(x: x + sin(time * 0.2 + y) * 2, y: y)
      ctx.fill(
        circle(point, index % 5 == 0 ? 0.7 : 0.35),
        with: .color(HarborPalette.ivory.opacity(shimmer * 0.22)))
    }
    for y in stride(from: 20, through: 500, by: 10) {
      let major = y % 50 == 0
      for x in [0.0, 360.0] {
        ctx.stroke(
          routePath([
            .init(x: x, y: Double(y)),
            .init(x: x + (x == 0 ? 1 : -1) * (major ? 6 : 3), y: Double(y)),
          ]), with: .color(HarborPalette.brass.opacity(major ? 0.4 : 0.2)), lineWidth: 0.5)
      }
    }

    for current in chart.currents {
      let active = model.inCurrent && model.tug.distance(to: current.center) < current.radius
      for row in -1...1 {
        for column in -1...1 {
          let center = current.center + SeaPoint(x: Double(column * 29), y: Double(row * 28))
          if center.distance(to: current.center) < current.radius - 8 {
            var arrow = ctx
            arrow.translateBy(x: center.x, y: center.y)
            arrow.rotate(by: .radians(atan2(current.force.y, current.force.x)))
            let offset = sin(time + Double(row + column)) * 3
            var path = Path()
            path.move(to: CGPoint(x: -16 + offset, y: 2))
            path.addQuadCurve(
              to: CGPoint(x: 7 + offset, y: 0),
              control: CGPoint(x: -3 + offset, y: -4))
            path.move(to: CGPoint(x: 3 + offset, y: -3))
            path.addLine(to: CGPoint(x: 7 + offset, y: 0))
            path.addLine(to: CGPoint(x: 3 + offset, y: 3))
            arrow.stroke(
              path,
              with: .color(
                active ? HarborPalette.brass.opacity(0.7) : HarborPalette.foam.opacity(0.3)),
              lineWidth: active ? 1.4 : 1)
          }
        }
      }
      label(
        "TIDAL DRIFT", at: current.center + SeaPoint(x: 0, y: current.radius - 4),
        size: 7, color: HarborPalette.foam.opacity(0.65), ctx: &ctx)
    }

    for reef in chart.reefs { drawReef(reef, time: time, ctx: &ctx) }
    drawHarbor(time: time, ctx: &ctx)
    if !decorative { drawJetty(ctx: &ctx) }
    compass(at: SeaPoint(x: 305, y: 466), ctx: &ctx)
    label(
      "BREAKWATER  /  COASTAL RESCUE", at: .init(x: 177, y: 510), size: 5.5,
      color: HarborPalette.foam.opacity(0.45), ctx: &ctx)

    if decorative {
      drawHomeFleet(time: time, ctx: &ctx)
      return
    }
    if model.showGuide && model.phase == .plotting {
      let guide = routePath(chart.guide)
      ctx.stroke(guide, with: .color(HarborPalette.ink.opacity(0.4)), lineWidth: 5)
      ctx.stroke(
        guide, with: .color(HarborPalette.ivory.opacity(0.65)),
        style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [2, 6]))
    }
    if model.route.count > 1 && !decorative {
      let path = routePath(model.route)
      ctx.stroke(path, with: .color(HarborPalette.ink.opacity(0.28)), lineWidth: 6)
      ctx.stroke(
        path,
        with: .color(model.routeFits ? HarborPalette.brass.opacity(0.88) : HarborPalette.coral),
        style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round, dash: [3, 4]))
      if let end = model.route.last {
        ctx.stroke(circle(end, 4), with: .color(HarborPalette.ivory), lineWidth: 1.5)
      }
    }
    if model.track.count > 1 {
      ctx.stroke(
        routePath(model.track), with: .color(HarborPalette.foam.opacity(0.24)),
        style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
      ctx.stroke(
        routePath(model.track), with: .color(HarborPalette.foam.opacity(0.3)),
        style: StrokeStyle(lineWidth: 1, dash: [1, 6]))
    }
    for (index, point) in chart.boats.enumerated()
    where !model.convoy.contains(where: { $0.index == index }) {
      let pulse = 1 + sin(time * 1.6 + Double(index)) * 0.07
      ctx.stroke(
        circle(point, 22 * pulse), with: .color(HarborPalette.brass.opacity(0.27)),
        style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
      boat(
        at: point, angle: -.pi / 2 + sin(time * 0.8 + Double(index)) * 0.06,
        tug: false, ctx: &ctx)
      let badge = point + SeaPoint(x: 17, y: -19)
      ctx.fill(circle(badge, 9.5), with: .color(HarborPalette.ink))
      ctx.stroke(circle(badge, 9.5), with: .color(HarborPalette.brass), lineWidth: 0.8)
      label("\(index + 1)", at: badge, size: 10, color: HarborPalette.ivory, ctx: &ctx)
    }
    var previous = model.tug
    for offset in model.convoy.indices {
      let point = model.towPosition(offset)
      var rope = Path()
      rope.move(to: previous.cg)
      rope.addQuadCurve(to: point.cg, control: ((previous + point) * 0.5 + SeaPoint(x: 2, y: 2)).cg)
      if model.phase != .won {
        ctx.stroke(rope, with: .color(HarborPalette.ink.opacity(0.5)), lineWidth: 3.5)
        ctx.stroke(
          rope, with: .color(HarborPalette.brass),
          style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
      }
      let dockScale = model.phase == .won ? 1 - 0.28 * model.harborArrival : 1
      boat(at: point, angle: model.towHeading(offset), tug: false, scale: dockScale, ctx: &ctx)
      previous = point
    }
    if model.phase == .plotting || decorative {
      ctx.stroke(
        circle(model.tug, 23 + sin(time * 2) * 2),
        with: .color(HarborPalette.coral.opacity(0.4)), lineWidth: 1)
      label(
        "TUG", at: model.tug + SeaPoint(x: 0, y: 31), size: 8,
        color: HarborPalette.ivory.opacity(0.7), ctx: &ctx)
    }
    let tug =
      model.phase == .won
      ? model.tug + (chart.home + SeaPoint(x: 0, y: 32) - model.tug)
        * min(1, model.harborArrival * 2)
      : model.tug
    boat(at: tug, angle: model.phase == .won ? -Double.pi / 2 : model.heading, tug: true, ctx: &ctx)
    if model.pickupFlash > 0 {
      let progress = 1 - model.pickupFlash
      ctx.stroke(
        circle(model.tug, 15 + progress * 40),
        with: .color(HarborPalette.brass.opacity(model.pickupFlash)), lineWidth: 2)
      for index in 0..<10 {
        let angle = Double(index) * .pi / 5
        let point = model.tug + SeaPoint(x: cos(angle), y: sin(angle)) * (20 + progress * 40)
        ctx.fill(circle(point, 1.5), with: .color(HarborPalette.ivory.opacity(model.pickupFlash)))
      }
    }
  }

  private func drawHomeFleet(time: Double, ctx: inout GraphicsContext) {
    let course: [SeaPoint] = [
      .init(x: 73, y: 372), .init(x: 121, y: 355),
      .init(x: 166, y: 333), .init(x: 206, y: 299), .init(x: 231, y: 254),
    ]
    let wake = routePath(course)
    ctx.stroke(
      wake, with: .color(HarborPalette.foam.opacity(0.07)),
      style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
    ctx.stroke(
      wake, with: .color(HarborPalette.foam.opacity(0.3)),
      style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [2, 5]))
    let bob = sin(time * 0.7) * 1.2
    let fleet: [SeaPoint] = [
      .init(x: 231, y: 254 + bob), .init(x: 215, y: 284 + bob),
      .init(x: 191, y: 313 + bob), .init(x: 160, y: 335 + bob),
    ]
    ctx.stroke(
      routePath(fleet), with: .color(HarborPalette.brass),
      style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
    for index in fleet.indices.reversed() {
      let angle = index < 2 ? -1.08 : -0.67
      boat(at: fleet[index], angle: angle, tug: index == 0, scale: 1.3, ctx: &ctx)
    }
    label(
      "THE LITTLE FLEET", at: .init(x: 190, y: 380), size: 8,
      color: HarborPalette.brass.opacity(0.7), ctx: &ctx)
  }

  private func drawReef(_ reef: Reef, time: Double, ctx: inout GraphicsContext) {
    let center = reef.center
    let r = reef.radius
    let bounds = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
    let artwork = Image(islandArtwork(for: reef))
    var surf = ctx
    surf.addFilter(
      .shadow(
        color: HarborPalette.foam.opacity(0.75),
        radius: 3 + sin(time * 0.65 + Double(reef.id)) * 0.8))
    surf.draw(artwork, in: bounds)
    var island = ctx
    island.addFilter(.shadow(color: HarborPalette.ink.opacity(0.6), radius: 2, x: 2, y: 3))
    island.draw(artwork, in: bounds)
  }

  private func drawHarbor(time: Double, ctx: inout GraphicsContext) {
    let p = decorative ? HarborChart.campaign[0].home : model.chart.home
    let side = p.x > 180 ? 1.0 : -1.0
    let light = SeaPoint(x: p.x + side * 35, y: max(58, p.y - 20))
    var dock = ctx
    dock.addFilter(.shadow(color: HarborPalette.ink.opacity(0.6), radius: 2, x: 2, y: 3))
    dock.draw(
      Image("StoneQuay"),
      in: CGRect(x: p.x + side * 41 - 6, y: p.y - 29, width: 12, height: 54))
    var foot = dock
    foot.translateBy(x: p.x + side * 31, y: p.y + 20)
    foot.rotate(by: .degrees(90))
    foot.draw(Image("StoneQuay"), in: CGRect(x: -4, y: -12, width: 8, height: 24))
    let lit = decorative || model.phase == .won || model.allRescued
    ctx.fill(circle(p, 29), with: .color(HarborPalette.brass.opacity(lit ? 0.13 : 0.04)))
    ctx.stroke(
      circle(p, 29), with: .color(HarborPalette.brass.opacity(0.78)),
      style: StrokeStyle(lineWidth: 0.9, dash: [8, 4]))
    label("HOME", at: p + SeaPoint(x: 0, y: 40), size: 7, color: HarborPalette.ivory, ctx: &ctx)
    var tower = ctx
    tower.addFilter(.shadow(color: HarborPalette.ink.opacity(0.6), radius: 2, x: 3, y: 3))
    tower.draw(
      Image("HarborLight"),
      in: CGRect(x: light.x - 11, y: light.y - 55, width: 23, height: 60))
    if lit {
      let source = light + SeaPoint(x: 0, y: -43)
      let angle = time * 0.24 + 2.4
      let rays = polygon([
        source,
        source + SeaPoint(x: cos(angle - 0.18), y: sin(angle - 0.18)) * 350,
        source + SeaPoint(x: cos(angle + 0.18), y: sin(angle + 0.18)) * 350,
      ])
      ctx.fill(
        rays,
        with: .linearGradient(
          Gradient(colors: [HarborPalette.brass.opacity(0.28), HarborPalette.brass.opacity(0)]),
          startPoint: source.cg,
          endPoint: (source + SeaPoint(x: cos(angle), y: sin(angle)) * 300).cg))
    }
  }

  private func drawJetty(ctx: inout GraphicsContext) {
    let p = model.chart.start
    let left = p.x < 180
    let x = p.x + (left ? -31.0 : 31.0)
    var jetty = ctx
    jetty.addFilter(.shadow(color: HarborPalette.ink.opacity(0.6), radius: 2, x: 2, y: 3))
    jetty.draw(Image("StoneQuay"), in: CGRect(x: x - 6, y: p.y - 15, width: 12, height: 46))
  }

  private func boat(
    at point: SeaPoint, angle: Double, tug: Bool, scale: Double = 1,
    ctx: inout GraphicsContext
  ) {
    var boat = ctx
    boat.translateBy(x: point.x, y: point.y)
    boat.rotate(by: .radians(angle + .pi / 2))
    boat.scaleBy(x: scale, y: scale)
    boat.addFilter(.shadow(color: HarborPalette.ink.opacity(0.75), radius: 2, x: 2, y: 3))
    let width = tug ? 18.0 : 12.0
    let height = tug ? 36.0 : 30.0
    boat.draw(
      Image(tug ? "RescueTug" : "RescueLaunch"),
      in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
  }

  private func compass(at point: SeaPoint, ctx: inout GraphicsContext) {
    ctx.stroke(circle(point, 19), with: .color(HarborPalette.brass.opacity(0.24)), lineWidth: 0.6)
    for index in 0..<4 {
      let angle = Double(index) * .pi / 2
      let tip = point + SeaPoint(x: sin(angle), y: -cos(angle)) * 17
      let side = SeaPoint(x: cos(angle), y: sin(angle)) * 3
      ctx.fill(
        polygon([tip, point + side, point - side]),
        with: .color(HarborPalette.brass.opacity(index == 0 ? 0.75 : 0.24)))
    }
    label(
      "N", at: point + SeaPoint(x: 0, y: -27), size: 7,
      color: HarborPalette.brass.opacity(0.6), ctx: &ctx)
  }

  private func label(
    _ text: String, at point: SeaPoint, size: Double, color: Color,
    ctx: inout GraphicsContext
  ) {
    ctx.draw(
      Text(text).font(.system(size: size, weight: .semibold, design: .monospaced))
        .foregroundColor(color), at: point.cg)
  }

  private func circle(_ point: SeaPoint, _ radius: Double) -> Path {
    Path(
      ellipseIn: CGRect(
        x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
  }

  private func polygon(_ points: [SeaPoint]) -> Path {
    var path = routePath(points)
    path.closeSubpath()
    return path
  }

  private func routePath(_ points: [SeaPoint]) -> Path {
    var path = Path()
    if let first = points.first {
      path.move(to: first.cg)
      for point in points.dropFirst() { path.addLine(to: point.cg) }
    }
    return path
  }
}

extension SeaPoint {
  var cg: CGPoint { CGPoint(x: x, y: y) }
}

struct RescueSeal: View {
  var body: some View {
    Canvas { context, size in
      context.scaleBy(x: size.width / 60, y: size.height / 60)
      for inset in [1.0, 5.0] {
        context.stroke(
          Path(
            ellipseIn: CGRect(x: inset, y: inset, width: 60 - inset * 2, height: 60 - inset * 2)),
          with: .foreground, lineWidth: 0.7)
      }
      for angle in stride(from: 0.0, to: .pi * 2, by: .pi / 6) {
        var tick = Path()
        tick.move(to: CGPoint(x: 30 + sin(angle) * 27, y: 30 + cos(angle) * 27))
        tick.addLine(to: CGPoint(x: 30 + sin(angle) * 29, y: 30 + cos(angle) * 29))
        context.stroke(tick, with: .foreground, lineWidth: 0.6)
      }
      var tower = Path()
      tower.move(to: CGPoint(x: 26, y: 38))
      tower.addLine(to: CGPoint(x: 28, y: 22))
      tower.addLine(to: CGPoint(x: 32, y: 22))
      tower.addLine(to: CGPoint(x: 34, y: 38))
      tower.closeSubpath()
      context.fill(tower, with: .foreground)
      context.fill(Path(CGRect(x: 26, y: 18, width: 8, height: 3)), with: .foreground)
      context.fill(Path(ellipseIn: CGRect(x: 28, y: 13, width: 4, height: 4)), with: .foreground)
      for y in [40.0, 44.0] {
        var wave = Path()
        wave.move(to: CGPoint(x: 17, y: y))
        wave.addQuadCurve(to: CGPoint(x: 30, y: y), control: CGPoint(x: 23, y: y - 4))
        wave.addQuadCurve(to: CGPoint(x: 43, y: y), control: CGPoint(x: 36, y: y + 4))
        context.stroke(wave, with: .foreground, lineWidth: 1)
      }
      for side in [-1.0, 1.0] {
        var ray = Path()
        ray.move(to: CGPoint(x: 30 + side * 8, y: 18))
        ray.addLine(to: CGPoint(x: 30 + side * 15, y: 15))
        context.stroke(ray, with: .foreground, lineWidth: 1)
      }
    }
    .accessibilityHidden(true)
  }
}

struct HarborAtmosphere: View {
  @Environment(\.accessibilityReduceMotion) private var reducedMotion

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reducedMotion)) { timeline in
      Canvas { context, size in
        let time = reducedMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
        for index in 0..<65 {
          let x = Double((index * 137) % 997) / 997 * size.width
          let y = (0.3 + Double((index * 71) % 997) / 997 * 0.5) * size.height
          let glow = max(0, sin(time * 0.6 + Double(index) * 0.73))
          let radius = index % 7 == 0 ? 1.0 : 0.5
          context.fill(
            Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
            with: .color(HarborPalette.ivory.opacity(glow * 0.5)))
        }
      }
    }
    .accessibilityHidden(true)
  }
}

struct ChartPreview: View {
  let chart: HarborChart

  var body: some View {
    Canvas { context, size in
      context.scaleBy(x: size.width / 360, y: size.height / 520)
      context.draw(Image("SeaSurface"), in: CGRect(x: 0, y: 0, width: 360, height: 520))
      for reef in chart.reefs {
        context.draw(
          Image(islandArtwork(for: reef)),
          in: CGRect(
            x: reef.center.x - reef.radius, y: reef.center.y - reef.radius,
            width: reef.radius * 2, height: reef.radius * 2))
      }
      var route = Path()
      route.move(to: chart.start.cg)
      for point in chart.guide { route.addLine(to: point.cg) }
      context.stroke(
        route, with: .color(HarborPalette.brass),
        style: StrokeStyle(lineWidth: 4, dash: [9, 12]))
      for point in chart.boats {
        context.fill(
          Path(ellipseIn: CGRect(x: point.x - 7, y: point.y - 7, width: 14, height: 14)),
          with: .color(HarborPalette.ivory))
      }
      context.draw(
        Image("HarborLight"),
        in: CGRect(x: chart.home.x - 9, y: chart.home.y - 35, width: 18, height: 48))
    }
  }
}

struct StitchRule: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.minX, y: rect.midY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    }
  }
}

private func islandArtwork(for reef: Reef) -> String {
  if reef.radius < 26 { return "RockyReef" }
  return reef.id.isMultiple(of: 2) ? "CoastalIsland" : "PineIsland"
}

struct HarborPressStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reducedMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.83 : 1)
      .scaleEffect(configuration.isPressed && !reducedMotion ? 0.985 : 1)
      .animation(reducedMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
  }
}
