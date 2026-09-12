import SwiftUI

struct AlpineCanvas: View {
  let engine: RideEngine
  let time: Double
  let isHome: Bool
  let reduceMotion: Bool

  private let ink = Color(hex: 0x17394A)
  private var travel: Double { isHome ? time * 8 : engine.x }
  private var sunset: Double { isHome ? 0.16 : min(1, engine.x / 19000) }

  var body: some View {
    Canvas { context, size in
      let scale = size.width / 480
      let baseline = size.height * 0.72
      let offset = travel - (isHome ? 60 : 124)
      sky(&context, size: size)
      mountains(&context, size: size, scale: scale)
      village(&context, size: size, baseline: baseline, scale: scale)
      terrain(&context, size: size, baseline: baseline, scale: scale, offset: offset)
      if !isHome {
        collectibles(&context, baseline: baseline, scale: scale, offset: offset)
        obstacles(&context, baseline: baseline, scale: scale, offset: offset)
      }
      rider(&context, baseline: baseline, scale: scale)
      powder(&context, size: size)
    }
    .accessibilityHidden(true)
    .ignoresSafeArea()
  }

  private func sky(_ context: inout GraphicsContext, size: CGSize) {
    let upper = Color.mix(Color(hex: 0x193B58), Color(hex: 0x654C70), sunset)
    let lower = Color.mix(Color(hex: 0xD4A89F), Color(hex: 0xFFBE8D), sunset)
    context.fill(
      Path(CGRect(origin: .zero, size: size)),
      with: .linearGradient(
        Gradient(colors: [upper, Color(hex: 0x75879E), lower]),
        startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height * 0.74)
      )
    )
    let sun = CGPoint(x: size.width * 0.77, y: size.height * (isHome ? 0.42 : 0.35))
    context.fill(
      Path(ellipseIn: CGRect(x: sun.x - 67, y: sun.y - 67, width: 134, height: 134)),
      with: .radialGradient(
        Gradient(colors: [Color(hex: 0xFFE1B4).opacity(0.22), .clear]),
        center: sun, startRadius: 10, endRadius: 67
      )
    )
    context.fill(
      Path(ellipseIn: CGRect(x: sun.x - 22, y: sun.y - 22, width: 44, height: 44)),
      with: .color(Color(hex: 0xFFEAC5).opacity(0.92))
    )
    for index in 0..<24 {
      let x = fract(Double(index) * 0.618 + 0.13) * size.width
      let y = fract(Double(index) * 0.381 + 0.04) * size.height * 0.32
      context.fill(
        Path(ellipseIn: CGRect(x: x, y: y, width: index % 4 == 0 ? 2 : 1, height: 1.5)),
        with: .color(.white.opacity(0.38 * (1 - sunset)))
      )
    }
    for index in 0..<4 {
      let x = fract(Double(index) * 0.319 + 0.06 - travel / 37000) * size.width
      let y = size.height * (0.33 + Double(index % 3) * 0.068)
      var cloud = Path()
      cloud.move(to: CGPoint(x: x - 72, y: y))
      cloud.addQuadCurve(
        to: CGPoint(x: x + 88, y: y - 1), control: CGPoint(x: x + 5, y: y - 12)
      )
      context.stroke(cloud, with: .color(.white.opacity(0.12)), lineWidth: 3)
    }
  }

  private func mountains(_ context: inout GraphicsContext, size: CGSize, scale: Double) {
    let colors: [Color] = [
      Color(hex: 0x8993AA), Color(hex: 0x71849C), Color(hex: 0x4D718B),
      Color(hex: 0x365D77), Color(hex: 0x294E64),
    ]
    for layer in 0..<5 {
      let spacing = (layer < 2 ? 320.0 : 240.0) * scale
      let shift = travel * (0.025 + Double(layer) * 0.027) * scale
      let start = Int(shift / spacing) - 2
      let base = size.height * (0.69 + Double(layer) * 0.030)
      let mountainHeight = (210 - Double(layer) * 27) * scale
      for index in start...(start + 7) {
        let x = Double(index) * spacing - shift
        let peakX = x + spacing * (0.40 + 0.10 * sin(Double(index) * 7))
        let peakY = base - mountainHeight * (0.80 + 0.20 * cos(Double(index) * 3))
        var mountain = Path()
        mountain.move(to: CGPoint(x: x - spacing * 0.30, y: base))
        mountain.addLine(to: CGPoint(x: peakX - spacing * 0.16, y: peakY + 39 * scale))
        mountain.addLine(to: CGPoint(x: peakX, y: peakY))
        mountain.addLine(to: CGPoint(x: peakX + spacing * 0.12, y: peakY + 30 * scale))
        mountain.addLine(to: CGPoint(x: x + spacing * 1.27, y: base))
        mountain.closeSubpath()
        context.fill(mountain, with: .color(colors[layer]))
        var facet = Path()
        facet.move(to: CGPoint(x: peakX, y: peakY))
        facet.addLine(to: CGPoint(x: peakX + spacing * 0.12, y: peakY + 30 * scale))
        facet.addLine(to: CGPoint(x: x + spacing * 1.27, y: base))
        facet.addLine(to: CGPoint(x: peakX + spacing * 0.20, y: base))
        facet.addLine(to: CGPoint(x: peakX - spacing * 0.01, y: peakY + 45 * scale))
        facet.closeSubpath()
        context.fill(facet, with: .color(Color(hex: 0x173E5C).opacity(0.20)))
        if layer < 3 {
          var cap = Path()
          cap.move(to: CGPoint(x: peakX - spacing * 0.16, y: peakY + 39 * scale))
          cap.addLine(to: CGPoint(x: peakX, y: peakY))
          cap.addLine(to: CGPoint(x: peakX + spacing * 0.18, y: peakY + 42 * scale))
          cap.addLine(to: CGPoint(x: peakX + spacing * 0.04, y: peakY + 28 * scale))
          cap.addLine(to: CGPoint(x: peakX + spacing * 0.015, y: peakY + 43 * scale))
          cap.addLine(to: CGPoint(x: peakX - spacing * 0.07, y: peakY + 31 * scale))
          cap.closeSubpath()
          context.fill(cap, with: .color(Color(hex: 0xDCE6EA).opacity(0.66 - Double(layer) * 0.13)))
        }
      }
    }
    var mist = Path()
    mist.addRect(CGRect(x: 0, y: size.height * 0.65, width: size.width, height: size.height * 0.28))
    context.fill(
      mist,
      with: .linearGradient(
        Gradient(colors: [.clear, Color(hex: 0xC5CFD1).opacity(0.17), .clear]),
        startPoint: CGPoint(x: 0, y: size.height * 0.65),
        endPoint: CGPoint(x: 0, y: size.height * 0.90)
      )
    )
  }

  private func village(
    _ context: inout GraphicsContext, size: CGSize, baseline: Double, scale: Double
  ) {
    let shift = travel * 0.42
    let first = Int(shift / 110) - 2
    for index in first...(first + 17) {
      let worldX = Double(index) * 110
      let x = (worldX - shift) * scale
      let y = baseline - (45 + 18 * sin(worldX / 191)) * scale
      let height = (44 + 25 * abs(sin(Double(index) * 13.4))) * scale
      pine(&context, at: CGPoint(x: x, y: y), height: height, color: ink.opacity(0.67))
      pine(
        &context, at: CGPoint(x: x + 19 * scale, y: y + 6 * scale),
        height: height * 0.68, color: ink.opacity(0.57)
      )
      if index % 7 == 2 {
        chalet(&context, at: CGPoint(x: x + 52 * scale, y: y + 9 * scale), scale: scale)
      }
    }
  }

  private func terrain(
    _ context: inout GraphicsContext, size: CGSize, baseline: Double,
    scale: Double, offset: Double
  ) {
    let hazards = isHome ? [] : engine.hazards(from: offset - 100, to: offset + 620)
    let chasms = hazards.filter { $0.kind == .chasm }
    let start = offset - 12
    let finish = offset + 492
    var spans: [(Double, Double)] = []
    var cursor = start
    for gap in chasms {
      if gap.x > cursor { spans.append((cursor, min(finish, gap.x))) }
      cursor = max(cursor, gap.x + gap.width)
    }
    if cursor < finish { spans.append((cursor, finish)) }
    for (left, right) in spans where left < right {
      var top = Path()
      var fill = Path()
      let firstY = baseline - RideEngine.height(at: left) * scale
      top.move(to: CGPoint(x: (left - offset) * scale, y: firstY))
      fill.move(to: CGPoint(x: (left - offset) * scale, y: size.height + 5))
      fill.addLine(to: CGPoint(x: (left - offset) * scale, y: firstY))
      for worldX in stride(from: left, through: right, by: 3) {
        let point = CGPoint(
          x: (worldX - offset) * scale,
          y: baseline - RideEngine.height(at: worldX) * scale
        )
        top.addLine(to: point)
        fill.addLine(to: point)
      }
      let edge = CGPoint(
        x: (right - offset) * scale, y: baseline - RideEngine.height(at: right) * scale)
      top.addLine(to: edge)
      fill.addLine(to: edge)
      fill.addLine(to: CGPoint(x: edge.x, y: size.height + 5))
      fill.closeSubpath()
      context.fill(
        fill,
        with: .linearGradient(
          Gradient(colors: [Color(hex: 0xE6F0EC), Color(hex: 0xAFC8D2), Color(hex: 0x6F95AF)]),
          startPoint: CGPoint(x: 0, y: baseline - 45),
          endPoint: CGPoint(x: 0, y: size.height)
        )
      )
      context.stroke(
        top, with: .color(Color(hex: 0xF4F5E8)),
        style: StrokeStyle(lineWidth: 5 * scale, lineCap: .round))
    }
    for gap in chasms {
      let x = (gap.x - offset) * scale
      let y = baseline - RideEngine.height(at: gap.x) * scale
      var wall = Path()
      wall.move(to: CGPoint(x: x, y: y + 3))
      wall.addLine(to: CGPoint(x: x - 19 * scale, y: y + 34 * scale))
      wall.addLine(to: CGPoint(x: x - 7 * scale, y: y + 76 * scale))
      wall.addLine(to: CGPoint(x: x - 24 * scale, y: size.height))
      wall.addLine(to: CGPoint(x: x, y: size.height))
      wall.closeSubpath()
      context.fill(wall, with: .color(Color(hex: 0x496D87)))
    }
    for index in 0..<9 {
      let x = fract(Double(index) * 0.271 - travel / 2300) * size.width
      let y = baseline + 55 + fract(Double(index) * 0.717) * 130
      var glint = Path()
      glint.move(to: CGPoint(x: x, y: y))
      glint.addLine(to: CGPoint(x: x + 10 + Double(index % 3) * 10, y: y - 2))
      context.stroke(glint, with: .color(.white.opacity(0.16)), lineWidth: 1)
    }
  }

  private func collectibles(
    _ context: inout GraphicsContext, baseline: Double, scale: Double, offset: Double
  ) {
    for coin in engine.snowCoins(from: offset - 20, to: offset + 520) {
      let center = CGPoint(x: (coin.x - offset) * scale, y: baseline - coin.y * scale)
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: center.x - 10 * scale, y: center.y - 10 * scale, width: 20 * scale,
            height: 20 * scale)),
        with: .radialGradient(
          Gradient(colors: [Color(hex: 0xFFD99B).opacity(0.5), .clear]),
          center: center, startRadius: 2 * scale, endRadius: 10 * scale
        )
      )
      let circle = Path(
        ellipseIn: CGRect(
          x: center.x - 4 * scale, y: center.y - 4 * scale, width: 8 * scale, height: 8 * scale))
      context.fill(circle, with: .color(Color(hex: 0xFFE7A9)))
      context.stroke(circle, with: .color(Color(hex: 0xD09B55)), lineWidth: scale)
    }
  }

  private func obstacles(
    _ context: inout GraphicsContext, baseline: Double, scale: Double, offset: Double
  ) {
    for hazard in engine.hazards(from: offset - 150, to: offset + 560) {
      let x = (hazard.x - offset) * scale
      let y = baseline - RideEngine.height(at: hazard.x) * scale
      if hazard.kind == .rock {
        let points: [CGPoint] = [
          CGPoint(x: x - 2 * scale, y: y), CGPoint(x: x + 3 * scale, y: y - 21 * scale),
          CGPoint(x: x + 15 * scale, y: y - 28 * scale),
          CGPoint(x: x + 24 * scale, y: y - 22 * scale),
          CGPoint(x: x + 34 * scale, y: y),
        ]
        var rock = Path()
        rock.addLines(points)
        rock.closeSubpath()
        context.fill(rock, with: .color(Color(hex: 0x405C72)))
        var snow = Path()
        snow.addLines(Array(points[1...3]))
        context.stroke(
          snow, with: .color(Color(hex: 0xF7EEE0)),
          style: StrokeStyle(lineWidth: 4 * scale, lineCap: .round, lineJoin: .round))
        var facet = Path()
        facet.move(to: points[2])
        facet.addLine(to: CGPoint(x: x + 20 * scale, y: y - 3 * scale))
        facet.addLine(to: points[4])
        context.fill(facet, with: .color(Color(hex: 0x243F53)))
      } else {
        for position in [hazard.x - 44, hazard.x + hazard.width + 20] {
          let flagX = (position - offset) * scale
          let flagY = baseline - RideEngine.height(at: position) * scale
          var pole = Path()
          pole.move(to: CGPoint(x: flagX, y: flagY))
          pole.addLine(to: CGPoint(x: flagX, y: flagY - 42 * scale))
          context.stroke(pole, with: .color(ink), lineWidth: 2 * scale)
          var flag = Path()
          flag.move(to: CGPoint(x: flagX, y: flagY - 42 * scale))
          flag.addLine(to: CGPoint(x: flagX + 19 * scale, y: flagY - 34 * scale))
          flag.addLine(to: CGPoint(x: flagX, y: flagY - 29 * scale))
          context.fill(flag, with: .color(Color(hex: 0xDF8669)))
        }
      }
    }
  }

  private func rider(_ context: inout GraphicsContext, baseline: Double, scale: Double) {
    let riderY = isHome ? RideEngine.height(at: travel) : engine.y
    let angle = isHome ? atan(RideEngine.slope(at: travel)) : engine.rotation
    let center = CGPoint(x: (isHome ? 60 : 124) * scale, y: baseline - riderY * scale)
    if !isHome && engine.rescueTime > 0 {
      context.opacity = 0.55 + 0.35 * sin(time * 14)
    }
    if isHome || engine.grounded {
      for index in 0..<11 {
        let t = fract(Double(index) / 11 + time * 1.4)
        let px = center.x - (9 + t * 56) * scale
        let py = center.y - (3 + sin(t * .pi) * 12) * scale + t * 8
        context.fill(
          Path(ellipseIn: CGRect(x: px, y: py, width: (3 - t * 2) * scale, height: 2 * scale)),
          with: .color(.white.opacity((1 - t) * 0.7))
        )
      }
    }
    let riderScale = scale * 1.22
    var rider = context
    rider.translateBy(x: center.x, y: center.y - 10 * riderScale)
    rider.rotate(by: .radians(-angle))
    rider.scaleBy(x: riderScale, y: riderScale)
    var scarf = Path()
    scarf.move(to: CGPoint(x: 1, y: -16))
    scarf.addQuadCurve(
      to: CGPoint(x: -30, y: -15 + sin(time * 9) * 3), control: CGPoint(x: -13, y: -24))
    rider.stroke(
      scarf, with: .color(Color(hex: 0xFFD297)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    var legs = Path()
    legs.move(to: CGPoint(x: -7, y: 8))
    legs.addLine(to: CGPoint(x: -5, y: -1))
    legs.addLine(to: CGPoint(x: 3, y: -7))
    legs.addLine(to: CGPoint(x: 9, y: 1))
    legs.addLine(to: CGPoint(x: 6, y: 8))
    rider.stroke(
      legs, with: .color(Color(hex: 0x1A3349)),
      style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
    var jacket = Path()
    jacket.move(to: CGPoint(x: -3, y: -5))
    jacket.addLine(to: CGPoint(x: 2, y: -18))
    jacket.addLine(to: CGPoint(x: 10, y: -16))
    jacket.addLine(to: CGPoint(x: 8, y: -6))
    jacket.closeSubpath()
    rider.fill(jacket, with: .color(Color(hex: 0xE98970)))
    var arm = Path()
    arm.move(to: CGPoint(x: 5, y: -14))
    arm.addLine(to: CGPoint(x: 11, y: -8))
    arm.addLine(to: CGPoint(x: 16, y: -10))
    rider.stroke(
      arm, with: .color(Color(hex: 0xF3A184)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    rider.fill(
      Path(ellipseIn: CGRect(x: 2, y: -28, width: 11, height: 12)),
      with: .color(Color(hex: 0x203B4D)))
    rider.fill(
      Path(roundedRect: CGRect(x: 7, y: -24, width: 8, height: 4), cornerRadius: 2),
      with: .color(Color(hex: 0xF8D6A5)))
    var board = Path()
    board.move(to: CGPoint(x: -18, y: 7))
    board.addQuadCurve(to: CGPoint(x: 20, y: 6), control: CGPoint(x: 2, y: 15))
    rider.stroke(
      board, with: .color(Color(hex: 0x23465B)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    rider.stroke(
      board, with: .color(Color(hex: 0xF2B886)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
    )
    if !isHome && !engine.grounded && engine.airtime > 0.25 {
      let level = RideEngine.isSafeLanding(
        rotation: engine.rotation, slope: RideEngine.slope(at: engine.x))
      let cue = CGPoint(x: center.x + 68 * scale, y: center.y - 47 * scale)
      context.fill(
        Path(
          roundedRect: CGRect(
            x: cue.x - 31 * scale, y: cue.y - 12 * scale,
            width: 62 * scale, height: 24 * scale),
          cornerRadius: 12 * scale),
        with: .color(level ? Color(hex: 0xF5EEDD) : ink.opacity(0.85)))
      context.draw(
        Text(level ? "LEVEL" : "ROTATE")
          .font(.system(size: 9 * scale, weight: .bold, design: .monospaced))
          .tracking(0.8)
          .foregroundColor(level ? ink : Color(hex: 0xF5EEDD)),
        at: cue)
    }
  }

  private func pine(
    _ context: inout GraphicsContext, at point: CGPoint, height: Double, color: Color
  ) {
    var tree = Path()
    tree.move(to: CGPoint(x: point.x, y: point.y - height))
    tree.addLine(to: CGPoint(x: point.x + height * 0.17, y: point.y - height * 0.53))
    tree.addLine(to: CGPoint(x: point.x + height * 0.09, y: point.y - height * 0.56))
    tree.addLine(to: CGPoint(x: point.x + height * 0.25, y: point.y - height * 0.13))
    tree.addLine(to: CGPoint(x: point.x + 2, y: point.y - height * 0.20))
    tree.addLine(to: CGPoint(x: point.x + 2, y: point.y + 2))
    tree.addLine(to: CGPoint(x: point.x - 2, y: point.y + 2))
    tree.addLine(to: CGPoint(x: point.x - 2, y: point.y - height * 0.20))
    tree.addLine(to: CGPoint(x: point.x - height * 0.25, y: point.y - height * 0.13))
    tree.addLine(to: CGPoint(x: point.x - height * 0.09, y: point.y - height * 0.56))
    tree.addLine(to: CGPoint(x: point.x - height * 0.17, y: point.y - height * 0.53))
    tree.closeSubpath()
    context.fill(tree, with: .color(color))
  }

  private func chalet(_ context: inout GraphicsContext, at point: CGPoint, scale: Double) {
    var local = context
    local.translateBy(x: point.x, y: point.y)
    local.scaleBy(x: scale, y: scale)
    local.fill(
      Path(CGRect(x: -19, y: -22, width: 38, height: 23)), with: .color(Color(hex: 0x284858)))
    var roof = Path()
    roof.addLines([CGPoint(x: -25, y: -22), CGPoint(x: 0, y: -39), CGPoint(x: 26, y: -22)])
    roof.closeSubpath()
    local.fill(roof, with: .color(Color(hex: 0xDAE5E0)))
    for x in [-12.0, 6.0] {
      local.fill(
        Path(CGRect(x: x, y: -15, width: 7, height: 9)), with: .color(Color(hex: 0xFFD68C)))
    }
    var smoke = Path()
    smoke.move(to: CGPoint(x: 12, y: -32))
    smoke.addCurve(
      to: CGPoint(x: 5, y: -63), control1: CGPoint(x: 26, y: -49),
      control2: CGPoint(x: -3, y: -46)
    )
    local.stroke(smoke, with: .color(Color(hex: 0xE0DBD2).opacity(0.23)), lineWidth: 4)
  }

  private func powder(_ context: inout GraphicsContext, size: CGSize) {
    let drift = reduceMotion ? 0 : time
    for index in 0..<32 {
      let x = fract(Double(index) * 0.618 - drift * 0.017) * size.width
      let y = fract(Double(index) * 0.417 + drift * 0.023) * size.height
      let radius = index % 3 == 0 ? 1.5 : 0.7
      context.fill(
        Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
        with: .color(.white.opacity(index % 3 == 0 ? 0.40 : 0.23))
      )
    }
  }

  private func fract(_ value: Double) -> Double { value - floor(value) }
}

extension Color {
  init(hex: UInt32) {
    self.init(
      .sRGB, red: Double((hex >> 16) & 255) / 255,
      green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1
    )
  }

  static func mix(_ first: Color, _ second: Color, _ amount: Double) -> Color {
    let a = UIColor(first)
    let b = UIColor(second)
    var ar: CGFloat = 0
    var ag: CGFloat = 0
    var ab: CGFloat = 0
    var aa: CGFloat = 0
    var br: CGFloat = 0
    var bg: CGFloat = 0
    var bb: CGFloat = 0
    var ba: CGFloat = 0
    a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
    b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
    return Color(
      red: ar + (br - ar) * amount,
      green: ag + (bg - ag) * amount, blue: ab + (bb - ab) * amount
    )
  }
}
