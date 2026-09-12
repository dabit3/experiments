import SwiftUI

enum HarborPalette {
  static let ink = Color(red: 0.025, green: 0.15, blue: 0.18)
  static let water = Color(red: 0.035, green: 0.29, blue: 0.33)
  static let deep = Color(red: 0.022, green: 0.20, blue: 0.24)
  static let foam = Color(red: 0.60, green: 0.84, blue: 0.80)
  static let ivory = Color(red: 0.98, green: 0.94, blue: 0.83)
  static let muted = Color(red: 0.63, green: 0.77, blue: 0.75)
  static let brass = Color(red: 0.90, green: 0.73, blue: 0.43)
  static let coral = Color(red: 0.97, green: 0.43, blue: 0.32)
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
    ctx.fill(
      Path(rect),
      with: .linearGradient(
        Gradient(colors: [HarborPalette.water, HarborPalette.deep, HarborPalette.ink]),
        startPoint: .zero, endPoint: CGPoint(x: 360, y: 540)))

    for row in 0..<32 {
      var wave = Path()
      for column in 0...24 {
        let x = Double(column) * 16 - 12
        let y = Double(row) * 18 + sin(x / 34 + Double(row) + time * 0.38) * 2.5
        if column == 0 {
          wave.move(to: CGPoint(x: x, y: y))
        } else {
          wave.addLine(to: CGPoint(x: x, y: y))
        }
      }
      ctx.stroke(
        wave, with: .color(HarborPalette.foam.opacity(row % 3 == 0 ? 0.075 : 0.035)),
        lineWidth: 0.65)
    }
    for x in stride(from: 20, through: 340, by: 40) {
      var meridian = Path()
      meridian.move(to: CGPoint(x: x, y: 0))
      meridian.addLine(to: CGPoint(x: x, y: 520))
      ctx.stroke(meridian, with: .color(HarborPalette.foam.opacity(0.035)), lineWidth: 0.5)
    }

    for current in chart.currents {
      for row in -2...2 {
        for column in -2...2 {
          let center = current.center + SeaPoint(x: Double(column * 26), y: Double(row * 25))
          if center.distance(to: current.center) < current.radius - 8 {
            var arrow = ctx
            arrow.translateBy(x: center.x, y: center.y)
            arrow.rotate(by: .radians(atan2(current.force.y, current.force.x)))
            let offset = sin(time + Double(row + column)) * 3
            var path = Path()
            path.move(to: CGPoint(x: -8 + offset, y: 0))
            path.addLine(to: CGPoint(x: 7 + offset, y: 0))
            path.move(to: CGPoint(x: 3 + offset, y: -3))
            path.addLine(to: CGPoint(x: 7 + offset, y: 0))
            path.addLine(to: CGPoint(x: 3 + offset, y: 3))
            arrow.stroke(path, with: .color(HarborPalette.foam.opacity(0.22)), lineWidth: 1)
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
    compass(at: SeaPoint(x: 302, y: 459), ctx: &ctx)
    label(
      "SOUNDINGS IN FATHOMS", at: .init(x: 177, y: 506), size: 6,
      color: HarborPalette.foam.opacity(0.34), ctx: &ctx)
    label(
      "04", at: .init(x: 39, y: 259), size: 8, color: HarborPalette.foam.opacity(0.28), ctx: &ctx)
    label(
      "12", at: .init(x: 290, y: 414), size: 8, color: HarborPalette.foam.opacity(0.28), ctx: &ctx)

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
        style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round, dash: [4, 5]))
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
      ctx.fill(circle(badge, 9.5), with: .color(HarborPalette.brass))
      label("\(index + 1)", at: badge, size: 11, color: HarborPalette.ink, ctx: &ctx)
    }
    var previous = model.tug
    for offset in model.convoy.indices {
      let point = model.towPosition(offset)
      var rope = Path()
      rope.move(to: previous.cg)
      rope.addQuadCurve(to: point.cg, control: ((previous + point) * 0.5 + SeaPoint(x: 2, y: 2)).cg)
      ctx.stroke(
        rope, with: .color(HarborPalette.brass),
        style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
      boat(at: point, angle: model.towHeading(offset), tug: false, ctx: &ctx)
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
    boat(at: model.tug, angle: model.heading, tug: true, ctx: &ctx)
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
    let points = (0..<11).map { index -> SeaPoint in
      let angle = Double(index) * 2 * .pi / 11
      let radius = r * (0.91 + Double((index * 7 + reef.id * 3) % 5) * 0.023)
      return center + SeaPoint(x: cos(angle), y: sin(angle)) * radius
    }
    let outline = polygon(points)
    var shore = ctx
    shore.addFilter(.shadow(color: HarborPalette.ink.opacity(0.7), radius: 3, x: 2, y: 7))
    shore.fill(outline, with: .color(Color(red: 0.48, green: 0.63, blue: 0.56)))
    ctx.stroke(
      outline, with: .color(HarborPalette.foam.opacity(0.07)),
      lineWidth: 21 + sin(time + Double(reef.id)) * 2)
    ctx.stroke(outline, with: .color(HarborPalette.foam.opacity(0.18)), lineWidth: 10)
    ctx.fill(outline, with: .color(HarborPalette.ivory))
    let inner = polygon(points.map { center + ($0 - center) * 0.79 + SeaPoint(x: -2, y: -2) })
    ctx.fill(
      inner,
      with: .linearGradient(
        Gradient(colors: [
          Color(red: 0.34, green: 0.49, blue: 0.39),
          Color(red: 0.15, green: 0.34, blue: 0.30),
        ]),
        startPoint: (center - SeaPoint(x: r, y: r)).cg, endPoint: (center + SeaPoint(x: r, y: r)).cg
      ))
    for index in 0..<5 {
      let angle = Double(index) * 2.1 + Double(reef.id)
      let p = center + SeaPoint(x: cos(angle), y: sin(angle)) * (r * 0.44)
      let stone = polygon([
        p + .init(x: -6, y: 3), p + .init(x: -2, y: -6),
        p + .init(x: 5, y: -3), p + .init(x: 7, y: 4),
      ])
      ctx.fill(stone, with: .color(HarborPalette.ivory.opacity(0.14)))
    }
    var foam = Path()
    foam.addArc(
      center: center.cg, radius: r + 6, startAngle: .degrees(28),
      endAngle: .degrees(116), clockwise: false)
    ctx.stroke(foam, with: .color(HarborPalette.ivory.opacity(0.65)), lineWidth: 1.2)
  }

  private func drawHarbor(time: Double, ctx: inout GraphicsContext) {
    let p = decorative ? HarborChart.campaign[0].home : model.chart.home
    let side = p.x > 180 ? 1.0 : -1.0
    let light = SeaPoint(x: p.x + side * 35, y: max(49, p.y - 32))
    var dock = Path()
    dock.move(to: CGPoint(x: p.x + side * 21, y: p.y + 19))
    dock.addLine(to: CGPoint(x: p.x + side * 41, y: p.y + 19))
    dock.addLine(to: CGPoint(x: p.x + side * 41, y: p.y - 24))
    ctx.stroke(dock, with: .color(HarborPalette.ink.opacity(0.8)), lineWidth: 13)
    ctx.stroke(
      dock, with: .color(HarborPalette.ivory), style: StrokeStyle(lineWidth: 8, lineJoin: .round))
    for index in 0..<5 {
      ctx.fill(
        circle(p + SeaPoint(x: side * 41, y: 15 - Double(index * 8)), 1.3),
        with: .color(HarborPalette.brass))
    }
    let lit = decorative || model.phase == .won || model.allRescued
    ctx.fill(circle(p, 29), with: .color(HarborPalette.brass.opacity(lit ? 0.18 : 0.06)))
    ctx.stroke(
      circle(p, 29), with: .color(HarborPalette.brass.opacity(0.78)),
      style: StrokeStyle(lineWidth: 1.4, dash: [3, 3]))
    label("HOME", at: p + SeaPoint(x: 0, y: 40), size: 8, color: HarborPalette.brass, ctx: &ctx)
    ctx.fill(circle(light + SeaPoint(x: 2, y: 5), 15), with: .color(HarborPalette.ink.opacity(0.5)))
    ctx.fill(circle(light, 13), with: .color(HarborPalette.ivory))
    ctx.fill(circle(light, 9), with: .color(HarborPalette.brass.opacity(0.7)))
    var tower = ctx
    tower.translateBy(x: light.x, y: light.y)
    let shape = polygon([
      .init(x: -7, y: 0), .init(x: -5, y: -27),
      .init(x: 5, y: -27), .init(x: 7, y: 0),
    ])
    tower.fill(shape, with: .color(HarborPalette.ivory))
    for y in [-20, -10] {
      tower.fill(
        Path(CGRect(x: -5.5, y: Double(y), width: 11, height: 5)),
        with: .color(HarborPalette.coral))
    }
    tower.fill(
      Path(roundedRect: CGRect(x: -8, y: -31, width: 16, height: 6), cornerRadius: 2),
      with: .color(HarborPalette.ink))
    tower.fill(
      Path(CGRect(x: -4, y: -36, width: 8, height: 6)),
      with: .color(lit ? HarborPalette.brass : HarborPalette.ivory))
    tower.fill(
      polygon([.init(x: -8, y: -37), .init(x: 0, y: -44), .init(x: 8, y: -37)]),
      with: .color(HarborPalette.coral))
    if lit {
      let source = light + SeaPoint(x: 0, y: -34)
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
    let rect = CGRect(x: x - 6, y: p.y - 15, width: 12, height: 46)
    ctx.fill(Path(rect.offsetBy(dx: 2, dy: 5)), with: .color(HarborPalette.ink.opacity(0.6)))
    ctx.fill(
      Path(roundedRect: rect, cornerRadius: 2),
      with: .color(Color(red: 0.62, green: 0.49, blue: 0.32)))
    for index in 0..<8 {
      let y = p.y - 13 + Double(index * 6)
      var line = Path()
      line.move(to: CGPoint(x: x - 5, y: y))
      line.addLine(to: CGPoint(x: x + 5, y: y))
      ctx.stroke(line, with: .color(HarborPalette.brass.opacity(0.6)), lineWidth: 1)
    }
    for y in [p.y - 13, p.y + 28] {
      ctx.fill(circle(.init(x: x, y: y), 2), with: .color(HarborPalette.ivory))
    }
  }

  private func boat(
    at point: SeaPoint, angle: Double, tug: Bool, scale: Double = 1,
    ctx: inout GraphicsContext
  ) {
    var boat = ctx
    boat.translateBy(x: point.x, y: point.y)
    boat.rotate(by: .radians(angle + .pi / 2))
    boat.scaleBy(x: scale, y: scale)
    let hull = Path { p in
      p.move(to: CGPoint(x: 0, y: -14))
      p.addCurve(
        to: CGPoint(x: 7.5, y: 2),
        control1: CGPoint(x: 6, y: -10), control2: CGPoint(x: 8, y: -4))
      p.addLine(to: CGPoint(x: 6, y: 11))
      p.addQuadCurve(to: CGPoint(x: -6, y: 11), control: CGPoint(x: 0, y: 14))
      p.addLine(to: CGPoint(x: -7.5, y: 2))
      p.addCurve(
        to: CGPoint(x: 0, y: -14),
        control1: CGPoint(x: -8, y: -4), control2: CGPoint(x: -6, y: -10))
      p.closeSubpath()
    }
    var shadow = boat
    shadow.addFilter(.shadow(color: HarborPalette.ink.opacity(0.85), radius: 2, x: 2, y: 4))
    shadow.fill(hull, with: .color(tug ? HarborPalette.coral : HarborPalette.ivory))
    boat.stroke(hull, with: .color(HarborPalette.ink), lineWidth: 1.1)
    boat.fill(
      Path(roundedRect: CGRect(x: -4.5, y: -5, width: 9, height: 12), cornerRadius: 2),
      with: .color(tug ? HarborPalette.ivory : Color(red: 0.32, green: 0.55, blue: 0.57)))
    boat.fill(
      Path(CGRect(x: -3.5, y: -4, width: 7, height: 3)),
      with: .color(HarborPalette.ink))
    boat.fill(
      Path(CGRect(x: -2, y: 2, width: 4, height: 3)),
      with: .color(tug ? HarborPalette.brass : HarborPalette.ivory))
    boat.fill(circle(.init(x: 0, y: 10), 1.8), with: .color(HarborPalette.ink))
    if tug {
      boat.fill(circle(.init(x: 0, y: -8), 1.4), with: .color(HarborPalette.brass))
      for x in [-8.0, 8.0] {
        boat.stroke(circle(.init(x: x, y: 4), 2.2), with: .color(HarborPalette.ink), lineWidth: 1.5)
      }
    }
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
