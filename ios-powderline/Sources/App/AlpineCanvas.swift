import SwiftUI

/// Powderline's alpine world. Everything is drawn from paths every frame:
/// a dawn-to-apricot sky with a ringed sun, five fog-softened ridge layers,
/// pine bands, glowing chalets, slope-shaded snow and the scarf-trailing rider.
struct AlpineCanvas: View {
  let engine: RideEngine
  let time: Double
  let isHome: Bool
  let reduceMotion: Bool
  let impactTime: Double

  private var travel: Double { isHome ? time * 64 : engine.x }
  private var sunset: Double { min(1, (isHome ? 0.35 : engine.elapsed / 320)) }

  var body: some View {
    Canvas { context, size in
      let scale = size.width / 480
      let baseline = size.height * 0.72
      let offset = travel - (isHome ? 60 : 124)
      sky(&context, size: size)
      ridges(&context, size: size, scale: scale)
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

  // MARK: Sky

  private func sky(_ context: inout GraphicsContext, size: CGSize) {
    let zenith = Color.mix(Color(hex: 0x10233F), Color(hex: 0x3A2E55), sunset)
    let dusk = Color.mix(Color(hex: 0x3F4C78), Color(hex: 0x7A5478), sunset)
    let rose = Color.mix(Color(hex: 0xB98A9A), Color(hex: 0xD98A85), sunset)
    let horizon = Color.mix(Color(hex: 0xE8B79E), Color(hex: 0xF8BE8A), sunset)
    context.fill(
      Path(CGRect(origin: .zero, size: size)),
      with: .linearGradient(
        Gradient(stops: [
          .init(color: zenith, location: 0), .init(color: dusk, location: 0.34),
          .init(color: rose, location: 0.58), .init(color: horizon, location: 0.76),
        ]),
        startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)
      )
    )

    let drift = reduceMotion ? 0 : time
    for index in 0..<46 {
      let x = fract(Double(index) * 0.7548 + 0.11) * size.width
      let y = fract(Double(index) * 0.5698 + 0.31) * size.height * 0.46
      let twinkle = 0.45 + 0.55 * abs(sin(drift * 0.9 + Double(index) * 1.7))
      let radius = index % 5 == 0 ? 1.3 : 0.8
      context.fill(
        Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
        with: .color(.white.opacity((0.18 + 0.5 * twinkle) * (1 - sunset * 0.6)))
      )
    }

    let sun = CGPoint(
      x: size.width * (isHome ? 0.71 : 0.76),
      y: size.height * (isHome ? 0.40 : 0.36)
    )
    let sunRadius = isHome ? 26.0 : 24.0
    for ring in 1...4 {
      let radius = sunRadius + Double(ring) * (isHome ? 34 : 30)
      context.stroke(
        Path(
          ellipseIn: CGRect(
            x: sun.x - radius, y: sun.y - radius, width: radius * 2, height: radius * 2)),
        with: .color(Color(hex: 0xFFE6BF).opacity(0.13 - Double(ring) * 0.022)),
        lineWidth: 1
      )
    }
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: sun.x - sunRadius * 5, y: sun.y - sunRadius * 5, width: sunRadius * 10,
          height: sunRadius * 10)),
      with: .radialGradient(
        Gradient(colors: [Color(hex: 0xFFD9A8).opacity(0.36), .clear]),
        center: sun, startRadius: sunRadius * 0.6, endRadius: sunRadius * 5
      )
    )
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: sun.x - sunRadius, y: sun.y - sunRadius, width: sunRadius * 2, height: sunRadius * 2)),
      with: .linearGradient(
        Gradient(colors: [Color(hex: 0xFFF4DC), Color(hex: 0xFFD79F)]),
        startPoint: CGPoint(x: sun.x, y: sun.y - sunRadius),
        endPoint: CGPoint(x: sun.x, y: sun.y + sunRadius)
      )
    )

    for index in 0..<5 {
      let width = 150.0 + Double(index % 3) * 70
      let x = fract(Double(index) * 0.29 + 0.07 - drift * (0.006 + Double(index) * 0.0015))
      let y = size.height * (0.24 + Double(index) * 0.075)
      let wisp = CGRect(
        x: x * (size.width + width) - width, y: y, width: width, height: 5 + Double(index % 2) * 3)
      context.fill(
        Path(roundedRect: wisp, cornerRadius: 4),
        with: .linearGradient(
          Gradient(colors: [.clear, .white.opacity(0.16), .clear]),
          startPoint: CGPoint(x: wisp.minX, y: 0), endPoint: CGPoint(x: wisp.maxX, y: 0)
        )
      )
    }
  }

  // MARK: Ridges

  private func ridgeHeight(_ x: Double, layer: Int) -> Double {
    let seed = Double(layer) * 3.7
    let a = abs(sin(x * 0.0071 + seed))
    let b = abs(sin(x * 0.0163 + seed * 1.9 + 1.3))
    let c = abs(sin(x * 0.041 + seed * 0.6 + 2.1))
    return pow(a, 1.6) * 0.62 + b * 0.28 + c * 0.10
  }

  private func ridges(_ context: inout GraphicsContext, size: CGSize, scale: CGFloat) {
    let fog = Color.mix(Color(hex: 0xB596A6), Color(hex: 0xE2A794), sunset)
    let layers: [(Double, Double, Double, UInt32)] = [
      (0.030, 0.560, 0.21, 0x7A7F9E),
      (0.055, 0.600, 0.19, 0x5E6A8C),
      (0.090, 0.640, 0.17, 0x475A79),
      (0.150, 0.690, 0.14, 0x364967),
      (0.230, 0.735, 0.11, 0x283A56),
    ]
    for (index, layer) in layers.enumerated() {
      let base = size.height * layer.1
      let amplitude = size.height * layer.2
      let shift = travel * layer.0
      var path = Path()
      var ridge = Path()
      path.move(to: CGPoint(x: 0, y: size.height))
      var x = 0.0
      var first = true
      while x <= size.width + 6 {
        let world = (x / scale + shift) * 1.0
        let y = base - amplitude * ridgeHeight(world, layer: index)
        let point = CGPoint(x: x, y: y)
        path.addLine(to: point)
        if first {
          ridge.move(to: point)
          first = false
        } else {
          ridge.addLine(to: point)
        }
        x += 5
      }
      path.addLine(to: CGPoint(x: size.width, y: size.height))
      path.closeSubpath()

      let depth = Double(layers.count - 1 - index) / Double(layers.count - 1)
      let body = Color.mix(Color(hex: layer.3), fog, depth * 0.55)
      let cap = Color.mix(Color(hex: 0xF2EEE6), fog, depth * 0.45)
      context.fill(
        path,
        with: .linearGradient(
          Gradient(stops: [
            .init(color: cap, location: 0), .init(color: body, location: 0.22),
            .init(color: Color.mix(body, fog, 0.35), location: 1),
          ]),
          startPoint: CGPoint(x: 0, y: base - amplitude),
          endPoint: CGPoint(x: 0, y: base + amplitude * 0.5)
        )
      )
      context.stroke(
        ridge, with: .color(Color(hex: 0xFFE2BE).opacity(0.22 + depth * 0.18)),
        style: StrokeStyle(lineWidth: 1, lineJoin: .round)
      )
      if index >= 2 {
        context.fill(
          Path(
            CGRect(x: 0, y: base - amplitude * 0.15, width: size.width, height: amplitude * 0.6)),
          with: .linearGradient(
            Gradient(colors: [.clear, fog.opacity(0.28), .clear]),
            startPoint: CGPoint(x: 0, y: base - amplitude * 0.15),
            endPoint: CGPoint(x: 0, y: base + amplitude * 0.45)
          )
        )
      }
    }
  }

  // MARK: Village

  private func village(
    _ context: inout GraphicsContext, size: CGSize, baseline: CGFloat, scale: CGFloat
  ) {
    let shift = travel * 0.42
    let span = 1500.0
    let start = Int(floor(shift / span))
    for cell in start...(start + 1) {
      let origin = (Double(cell) * span - shift) * scale
      for index in 0..<7 {
        let hash = Double((cell * 31 + index * 17) & 31)
        let x = origin + (Double(index) * 210 + hash * 4) * scale
        pine(
          &context, at: CGPoint(x: x, y: baseline - (16 + hash * 1.2) * scale),
          height: (54 + hash * 1.7) * scale, color: Color(hex: 0x1D2F47))
        pine(
          &context, at: CGPoint(x: x + 24 * scale, y: baseline - (10 + hash) * scale),
          height: (40 + hash) * scale, color: Color(hex: 0x24395A))
      }
      chalet(&context, at: CGPoint(x: origin + 470 * scale, y: baseline - 20 * scale), scale: scale)
      chalet(
        &context, at: CGPoint(x: origin + 1140 * scale, y: baseline - 27 * scale),
        scale: scale * 0.85)
    }
  }

  private func pine(
    _ context: inout GraphicsContext, at base: CGPoint, height: CGFloat, color: Color
  ) {
    var path = Path()
    let width = height * 0.46
    for tier in 0..<3 {
      let top = base.y - height + CGFloat(tier) * height * 0.26
      let half = width * (0.42 + CGFloat(tier) * 0.29) / 2
      path.move(to: CGPoint(x: base.x, y: top))
      path.addLine(to: CGPoint(x: base.x + half, y: top + height * 0.36))
      path.addLine(to: CGPoint(x: base.x - half, y: top + height * 0.36))
      path.closeSubpath()
    }
    context.fill(path, with: .color(color))
    context.fill(
      Path(
        CGRect(
          x: base.x - height * 0.03, y: base.y - height * 0.16, width: height * 0.06,
          height: height * 0.2)),
      with: .color(color))
    var light = Path()
    light.move(to: CGPoint(x: base.x, y: base.y - height))
    light.addLine(to: CGPoint(x: base.x + width * 0.21, y: base.y - height * 0.64))
    light.addLine(to: CGPoint(x: base.x + width * 0.06, y: base.y - height * 0.64))
    light.closeSubpath()
    context.fill(light, with: .color(Color(hex: 0xF7D7B4).opacity(0.28)))
  }

  private func chalet(_ context: inout GraphicsContext, at base: CGPoint, scale: CGFloat) {
    let width = 58 * scale
    let height = 30 * scale
    let roofTop = base.y - height - 30 * scale
    var body = Path()
    body.move(to: CGPoint(x: base.x - width / 2, y: base.y))
    body.addLine(to: CGPoint(x: base.x - width / 2, y: base.y - height))
    body.addLine(to: CGPoint(x: base.x + width / 2, y: base.y - height))
    body.addLine(to: CGPoint(x: base.x + width / 2, y: base.y))
    body.closeSubpath()
    context.fill(body, with: .color(Color(hex: 0x3B3540)))
    var roof = Path()
    roof.move(to: CGPoint(x: base.x - width * 0.62, y: base.y - height + 2 * scale))
    roof.addLine(to: CGPoint(x: base.x, y: roofTop))
    roof.addLine(to: CGPoint(x: base.x + width * 0.62, y: base.y - height + 2 * scale))
    roof.closeSubpath()
    context.fill(roof, with: .color(Color(hex: 0xE8EFEF)))
    var eave = Path()
    eave.move(to: CGPoint(x: base.x - width * 0.62, y: base.y - height + 2 * scale))
    eave.addLine(to: CGPoint(x: base.x, y: roofTop))
    eave.addLine(to: CGPoint(x: base.x + width * 0.62, y: base.y - height + 2 * scale))
    context.stroke(eave, with: .color(Color(hex: 0x2A2530)), lineWidth: 2.2 * scale)
    let glow = CGPoint(x: base.x, y: base.y - height * 0.5)
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: glow.x - 42 * scale, y: glow.y - 30 * scale, width: 84 * scale, height: 60 * scale)),
      with: .radialGradient(
        Gradient(colors: [Color(hex: 0xFFC978).opacity(0.28), .clear]), center: glow,
        startRadius: 0, endRadius: 42 * scale)
    )
    for column in 0..<3 {
      let x = base.x - width * 0.32 + CGFloat(column) * width * 0.32
      context.fill(
        Path(
          roundedRect: CGRect(
            x: x - 4 * scale, y: base.y - height * 0.72, width: 8 * scale, height: 11 * scale),
          cornerRadius: 1.5 * scale),
        with: .color(Color(hex: 0xFFD08A)))
    }
    let chimney = CGRect(
      x: base.x + width * 0.22, y: roofTop + 10 * scale, width: 7 * scale, height: 16 * scale)
    context.fill(Path(chimney), with: .color(Color(hex: 0x2A2530)))
    if !reduceMotion {
      for puff in 0..<3 {
        let phase = fract(time * 0.18 + Double(puff) * 0.33)
        let radius = (3 + phase * 6) * scale
        let point = CGPoint(
          x: chimney.midX + CGFloat(phase * 14) * scale,
          y: chimney.minY - CGFloat(phase * 34) * scale)
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
          with: .color(.white.opacity(0.22 * (1 - phase))))
      }
    }
  }

  // MARK: Terrain

  private func terrain(
    _ context: inout GraphicsContext, size: CGSize, baseline: CGFloat, scale: CGFloat,
    offset: Double
  ) {
    let step = 4.0
    var surface = Path()
    var top = Path()
    var samples: [(CGFloat, CGFloat, Double)] = []
    surface.move(to: CGPoint(x: 0, y: size.height))
    var screenX = 0.0
    while screenX <= size.width + step {
      let world = offset + screenX / scale
      let y = baseline - RideEngine.height(at: world) * scale
      samples.append((screenX, y, RideEngine.slope(at: world)))
      surface.addLine(to: CGPoint(x: screenX, y: y))
      if screenX == 0 {
        top.move(to: CGPoint(x: 0, y: y))
      } else {
        top.addLine(to: CGPoint(x: screenX, y: y))
      }
      screenX += step
    }
    surface.addLine(to: CGPoint(x: size.width, y: size.height))
    surface.closeSubpath()

    context.fill(
      surface,
      with: .linearGradient(
        Gradient(stops: [
          .init(color: Color(hex: 0xF8F4EC), location: 0),
          .init(color: Color(hex: 0xDCE5EA), location: 0.16),
          .init(color: Color(hex: 0xA9BFCF), location: 0.62),
          .init(color: Color(hex: 0x7C99B2), location: 1),
        ]),
        startPoint: CGPoint(x: 0, y: baseline - 60 * scale), endPoint: CGPoint(x: 0, y: size.height)
      )
    )

    // Slope shading: faces turned away from the low sun read a shade cooler.
    for index in stride(from: 0, to: samples.count - 3, by: 3) {
      let a = samples[index]
      let b = samples[min(samples.count - 1, index + 3)]
      let shade = max(0, min(1, (a.2 + b.2) * 1.9))
      guard shade > 0.02 else { continue }
      var band = Path()
      band.move(to: CGPoint(x: a.0, y: a.1))
      band.addLine(to: CGPoint(x: b.0, y: b.1))
      band.addLine(to: CGPoint(x: b.0, y: b.1 + 70 * scale))
      band.addLine(to: CGPoint(x: a.0, y: a.1 + 70 * scale))
      band.closeSubpath()
      context.fill(
        band,
        with: .linearGradient(
          Gradient(colors: [Color(hex: 0x9FB6C8).opacity(0.34 * shade), .clear]),
          startPoint: CGPoint(x: 0, y: a.1), endPoint: CGPoint(x: 0, y: a.1 + 70 * scale)
        )
      )
    }

    for depth in [34.0, 76.0, 128.0] {
      var contour = Path()
      for (index, sample) in samples.enumerated() where index % 2 == 0 {
        let point = CGPoint(
          x: sample.0, y: sample.1 + depth * scale + CGFloat(sin(sample.0 / 90 + depth)) * 3)
        if index == 0 { contour.move(to: point) } else { contour.addLine(to: point) }
      }
      context.stroke(
        contour, with: .color(Color(hex: 0x6D8CA8).opacity(depth == 34 ? 0.14 : 0.10)),
        style: StrokeStyle(lineWidth: 0.8, dash: [26, 14]))
    }

    context.stroke(
      top, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 5, lineJoin: .round))
    context.stroke(top, with: .color(.white), style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))

    for index in 0..<12 {
      let x = fract(Double(index) * 0.313 - offset / (size.width / scale)) * size.width
      let y =
        baseline - RideEngine.height(at: offset + x / scale) * scale + CGFloat(
          18 + (index % 4) * 20) * scale
      let glint = 0.5 + 0.5 * sin(time * 2.2 + Double(index))
      var star = Path()
      let radius = (1.4 + glint) * scale
      star.move(to: CGPoint(x: x - radius, y: y))
      star.addLine(to: CGPoint(x: x + radius, y: y))
      star.move(to: CGPoint(x: x, y: y - radius))
      star.addLine(to: CGPoint(x: x, y: y + radius))
      context.stroke(star, with: .color(.white.opacity(0.35 + 0.35 * glint)), lineWidth: 0.8)
    }
  }

  // MARK: Collectibles and obstacles

  private func collectibles(
    _ context: inout GraphicsContext, baseline: CGFloat, scale: CGFloat, offset: Double
  ) {
    for coin in engine.snowCoins(from: offset - 40, to: offset + 560) {
      let center = CGPoint(x: (coin.x - offset) * scale, y: baseline - coin.y * scale)
      let spin = abs(cos(time * 3.4 + coin.x * 0.05))
      let width = (3 + 6 * spin) * scale
      let height = 9 * scale
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: center.x - 20 * scale, y: center.y - 20 * scale, width: 40 * scale,
            height: 40 * scale)),
        with: .radialGradient(
          Gradient(colors: [Color(hex: 0xFFC46B).opacity(0.36), .clear]), center: center,
          startRadius: 0, endRadius: 20 * scale)
      )
      var gem = Path()
      gem.move(to: CGPoint(x: center.x, y: center.y - height))
      gem.addLine(to: CGPoint(x: center.x + width, y: center.y))
      gem.addLine(to: CGPoint(x: center.x, y: center.y + height))
      gem.addLine(to: CGPoint(x: center.x - width, y: center.y))
      gem.closeSubpath()
      context.fill(
        gem,
        with: .linearGradient(
          Gradient(colors: [Color(hex: 0xFFE7B0), Color(hex: 0xF2A950)]),
          startPoint: CGPoint(x: center.x - width, y: center.y - height),
          endPoint: CGPoint(x: center.x + width, y: center.y + height)
        )
      )
      var facet = Path()
      facet.move(to: CGPoint(x: center.x, y: center.y - height))
      facet.addLine(to: CGPoint(x: center.x + width, y: center.y))
      facet.addLine(to: CGPoint(x: center.x - width, y: center.y))
      facet.closeSubpath()
      context.fill(facet, with: .color(.white.opacity(0.35)))
    }
  }

  private func obstacles(
    _ context: inout GraphicsContext, baseline: CGFloat, scale: CGFloat, offset: Double
  ) {
    for hazard in engine.hazards(from: offset - 200, to: offset + 600) {
      let x = (hazard.x - offset) * scale
      let ground = baseline - RideEngine.height(at: hazard.x) * scale
      switch hazard.kind {
      case .rock:
        let width = hazard.width * scale
        let height = 22 * scale
        var boulder = Path()
        boulder.move(to: CGPoint(x: x - 3 * scale, y: ground + 4 * scale))
        boulder.addQuadCurve(
          to: CGPoint(x: x + width * 0.45, y: ground - height),
          control: CGPoint(x: x - 4 * scale, y: ground - height * 0.9))
        boulder.addQuadCurve(
          to: CGPoint(x: x + width + 3 * scale, y: ground + 4 * scale),
          control: CGPoint(x: x + width + 6 * scale, y: ground - height * 0.7))
        boulder.closeSubpath()
        context.fill(
          boulder,
          with: .linearGradient(
            Gradient(colors: [Color(hex: 0x5D6C82), Color(hex: 0x2B3A50)]),
            startPoint: CGPoint(x: x, y: ground - height),
            endPoint: CGPoint(x: x + width, y: ground)
          )
        )
        var snow = Path()
        snow.move(to: CGPoint(x: x + width * 0.08, y: ground - height * 0.62))
        snow.addQuadCurve(
          to: CGPoint(x: x + width * 0.82, y: ground - height * 0.66),
          control: CGPoint(x: x + width * 0.45, y: ground - height * 1.12))
        snow.addQuadCurve(
          to: CGPoint(x: x + width * 0.08, y: ground - height * 0.62),
          control: CGPoint(x: x + width * 0.45, y: ground - height * 0.5))
        context.fill(snow, with: .color(Color(hex: 0xF6F3EC)))
      case .chasm:
        let width = hazard.width * scale
        let far = baseline - RideEngine.height(at: hazard.x + hazard.width) * scale
        var gap = Path()
        gap.move(to: CGPoint(x: x, y: ground - 1))
        gap.addLine(to: CGPoint(x: x + width, y: far - 1))
        gap.addLine(to: CGPoint(x: x + width - 26 * scale, y: baseline + 400))
        gap.addLine(to: CGPoint(x: x + 20 * scale, y: baseline + 400))
        gap.closeSubpath()
        context.fill(
          gap,
          with: .linearGradient(
            Gradient(stops: [
              .init(color: Color(hex: 0x6E8BA6), location: 0),
              .init(color: Color(hex: 0x2E4360), location: 0.28),
              .init(color: Color(hex: 0x111C2C), location: 0.7),
            ]),
            startPoint: CGPoint(x: 0, y: min(ground, far)),
            endPoint: CGPoint(x: 0, y: baseline + 260)
          )
        )
        for layer in 1...5 {
          let depth = CGFloat(layer) * 30 * scale
          var strata = Path()
          strata.move(to: CGPoint(x: x + CGFloat(layer) * 3.6 * scale, y: ground + depth))
          strata.addLine(
            to: CGPoint(x: x + width - CGFloat(layer) * 4.6 * scale, y: far + depth * 0.94))
          context.stroke(
            strata, with: .color(Color(hex: 0x9FB8CF).opacity(0.22 - Double(layer) * 0.03)),
            lineWidth: 1)
        }
        var rim = Path()
        rim.move(to: CGPoint(x: x - 14 * scale, y: ground - 1))
        rim.addLine(to: CGPoint(x: x, y: ground - 1))
        rim.addLine(to: CGPoint(x: x + 20 * scale, y: ground + 26 * scale))
        rim.move(to: CGPoint(x: x + width + 14 * scale, y: far - 1))
        rim.addLine(to: CGPoint(x: x + width, y: far - 1))
        rim.addLine(to: CGPoint(x: x + width - 26 * scale, y: far + 28 * scale))
        context.stroke(
          rim, with: .color(Color(hex: 0xDFF0FA).opacity(0.7)),
          style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
        flag(&context, at: CGPoint(x: x - 10 * scale, y: ground), scale: scale)
        flag(&context, at: CGPoint(x: x + width + 10 * scale, y: far), scale: scale)
      }
    }
  }

  private func flag(_ context: inout GraphicsContext, at base: CGPoint, scale: CGFloat) {
    let height = 34 * scale
    var pole = Path()
    pole.move(to: base)
    pole.addLine(to: CGPoint(x: base.x, y: base.y - height))
    context.stroke(pole, with: .color(Color(hex: 0x2A3548)), lineWidth: 1.5 * scale)
    let wave = reduceMotion ? 0 : sin(time * 5 + base.x) * 2.5 * scale
    var cloth = Path()
    cloth.move(to: CGPoint(x: base.x, y: base.y - height))
    cloth.addQuadCurve(
      to: CGPoint(x: base.x + 15 * scale, y: base.y - height + 5.5 * scale + wave),
      control: CGPoint(x: base.x + 8 * scale, y: base.y - height + wave))
    cloth.addLine(to: CGPoint(x: base.x, y: base.y - height + 11 * scale))
    cloth.closeSubpath()
    context.fill(cloth, with: .color(Color(hex: 0xE8735A)))
  }

  // MARK: Rider

  private func rider(_ context: inout GraphicsContext, baseline: CGFloat, scale: CGFloat) {
    let screenX = (isHome ? 60.0 : 124.0) * scale
    let worldX = isHome ? travel : engine.x
    let groundHeight = RideEngine.height(at: worldX)
    let position = CGPoint(
      x: screenX, y: baseline - (isHome ? groundHeight : engine.y) * scale)
    let rotation = isHome ? atan(RideEngine.slope(at: worldX)) : engine.rotation
    let airborne = !isHome && !engine.grounded
    let crashing = impactTime > 0
    let groundY = baseline - groundHeight * scale
    let lift = max(0, groundY - position.y)

    // Contact shadow keeps the rider anchored to the slope.
    let shadowWidth = (30 - min(14, lift / 6)) * scale
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: position.x - shadowWidth / 2, y: groundY - 3 * scale, width: shadowWidth,
          height: 7 * scale)),
      with: .color(Color(hex: 0x4A6A88).opacity(0.28 - min(0.2, lift / 400))))

    // Carve groove and spray behind the board.
    if !crashing && (isHome || engine.grounded) {
      var groove = Path()
      for index in 0..<10 {
        let x = position.x - CGFloat(index) * 9 * scale
        let y = baseline - RideEngine.height(at: worldX - Double(index) * 9) * scale + 1.5 * scale
        if index == 0 {
          groove.move(to: CGPoint(x: x, y: y))
        } else {
          groove.addLine(to: CGPoint(x: x, y: y))
        }
      }
      context.stroke(
        groove, with: .color(Color(hex: 0xB9CCDA).opacity(0.7)),
        style: StrokeStyle(lineWidth: 2.4 * scale, lineCap: .round))
      for index in 0..<9 {
        let phase = fract(time * 2.6 + Double(index) * 0.11)
        let point = CGPoint(
          x: position.x - (6 + phase * 40) * scale + CGFloat(index % 3) * 5 * scale,
          y: position.y - CGFloat(phase * (18 + Double(index % 4) * 6)) * scale + 4 * scale)
        let radius = (1.2 + Double(index % 3) * 0.9) * (1 - phase * 0.4) * scale
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
          with: .color(.white.opacity(0.85 * (1 - phase))))
      }
    }

    var figure = context
    figure.translateBy(x: position.x, y: position.y)
    figure.rotate(by: .radians(-rotation + (crashing ? 1.9 * (1 - impactTime / 0.75) : 0)))
    figure.scaleBy(x: scale, y: scale)
    let ink = Color(hex: 0x1E2F45)
    let jacket = Color(hex: 0xE8735A)
    let scarf = Color(hex: 0xF7C489)

    // Board with kicked nose and tail.
    var board = Path()
    board.move(to: CGPoint(x: -21, y: -1))
    board.addQuadCurve(to: CGPoint(x: -14, y: 2), control: CGPoint(x: -22, y: 2))
    board.addLine(to: CGPoint(x: 15, y: 2))
    board.addQuadCurve(to: CGPoint(x: 22, y: -2), control: CGPoint(x: 23, y: 2))
    board.addQuadCurve(to: CGPoint(x: 15, y: -1.4), control: CGPoint(x: 20, y: -2.4))
    board.addLine(to: CGPoint(x: -14, y: -1.4))
    board.addQuadCurve(to: CGPoint(x: -21, y: -1), control: CGPoint(x: -19, y: -2.2))
    board.closeSubpath()
    figure.fill(board, with: .color(ink))
    var edge = Path()
    edge.move(to: CGPoint(x: -14, y: -0.4))
    edge.addLine(to: CGPoint(x: 15, y: -0.4))
    figure.stroke(edge, with: .color(Color(hex: 0xF3B58E).opacity(0.9)), lineWidth: 0.7)
    figure.fill(
      Path(roundedRect: CGRect(x: -9, y: -3.5, width: 5, height: 2.6), cornerRadius: 0.8),
      with: .color(ink))
    figure.fill(
      Path(roundedRect: CGRect(x: 4, y: -3.5, width: 5, height: 2.6), cornerRadius: 0.8),
      with: .color(ink))

    let crouch = airborne ? 0.0 : 2.0 + (isHome ? 0 : min(2.5, engine.speed / 120))
    // Legs bend into the landing.
    var legs = Path()
    legs.move(to: CGPoint(x: -6.5, y: -3))
    legs.addLine(to: CGPoint(x: -4.5, y: -12 + crouch))
    legs.addLine(to: CGPoint(x: -1, y: -19 + crouch))
    legs.move(to: CGPoint(x: 6.5, y: -3))
    legs.addLine(to: CGPoint(x: 5, y: -12 + crouch))
    legs.addLine(to: CGPoint(x: 1, y: -19 + crouch))
    figure.stroke(
      legs, with: .color(ink), style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round)
    )

    // Torso leans forward downhill; arms open on the air.
    var body = Path()
    body.move(to: CGPoint(x: -5, y: -18 + crouch))
    body.addLine(to: CGPoint(x: 5, y: -18 + crouch))
    body.addLine(to: CGPoint(x: airborne ? 5.5 : 8, y: -33 + crouch))
    body.addQuadCurve(
      to: CGPoint(x: airborne ? -4.5 : -2, y: -33 + crouch),
      control: CGPoint(x: airborne ? 0.5 : 3, y: -37.5 + crouch))
    body.closeSubpath()
    figure.fill(body, with: .color(jacket))
    var arms = Path()
    arms.move(to: CGPoint(x: -4, y: -28 + crouch))
    arms.addLine(to: CGPoint(x: -13, y: airborne ? -34 : -23 + crouch))
    arms.move(to: CGPoint(x: 4, y: -28 + crouch))
    arms.addLine(to: CGPoint(x: 12, y: airborne ? -35 : -24 + crouch))
    figure.stroke(arms, with: .color(jacket), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    figure.fill(
      Path(
        ellipseIn: CGRect(
          x: -12.6, y: (airborne ? -33 : -22 + crouch) - 1.6, width: 3.2, height: 3.2)),
      with: .color(scarf))
    figure.fill(
      Path(
        ellipseIn: CGRect(
          x: 10.4, y: (airborne ? -34 : -23 + crouch) - 1.6, width: 3.2, height: 3.2)),
      with: .color(scarf))

    // Scarf ribbon trails against the wind.
    var ribbon = Path()
    ribbon.move(to: CGPoint(x: -2, y: -32 + crouch))
    let flutter = reduceMotion ? 0 : sin(time * 9) * 2.2
    ribbon.addCurve(
      to: CGPoint(x: -24, y: -33 + crouch + flutter),
      control1: CGPoint(x: -9, y: -37 + crouch),
      control2: CGPoint(x: -16, y: -30 + crouch + flutter))
    ribbon.addCurve(
      to: CGPoint(x: -36, y: -30 + crouch - flutter * 0.6),
      control1: CGPoint(x: -29, y: -35 + crouch + flutter),
      control2: CGPoint(x: -33, y: -32 + crouch))
    figure.stroke(ribbon, with: .color(scarf), style: StrokeStyle(lineWidth: 3.1, lineCap: .round))
    figure.fill(
      Path(roundedRect: CGRect(x: -6, y: -36 + crouch, width: 12, height: 4.4), cornerRadius: 2.2),
      with: .color(scarf))

    // Head, beanie and pompom.
    figure.fill(
      Path(ellipseIn: CGRect(x: -4.6, y: -45.5 + crouch, width: 9.2, height: 9.6)),
      with: .color(Color(hex: 0xF2C9A4)))
    var beanie = Path()
    beanie.move(to: CGPoint(x: -5, y: -41 + crouch))
    beanie.addQuadCurve(to: CGPoint(x: 5, y: -41 + crouch), control: CGPoint(x: 0, y: -50 + crouch))
    beanie.closeSubpath()
    figure.fill(beanie, with: .color(ink))
    figure.fill(
      Path(
        roundedRect: CGRect(x: -5.4, y: -42.4 + crouch, width: 10.8, height: 2.4), cornerRadius: 1.2
      ), with: .color(scarf))
    figure.fill(
      Path(ellipseIn: CGRect(x: -1.6, y: -50.6 + crouch, width: 3.6, height: 3.6)),
      with: .color(scarf))
    var goggle = Path()
    goggle.move(to: CGPoint(x: 0.5, y: -39.4 + crouch))
    goggle.addLine(to: CGPoint(x: 4.8, y: -39.4 + crouch))
    figure.stroke(
      goggle, with: .color(ink.opacity(0.8)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))

    // Rotation halo while airborne so the level/rotate cue reads near the rider.
    if airborne && !crashing {
      let safe = RideEngine.isSafeLanding(
        rotation: engine.rotation, slope: RideEngine.slope(at: engine.x))
      var halo = context
      halo.translateBy(x: position.x, y: position.y)
      halo.scaleBy(x: scale, y: scale)
      let color = safe ? Color(hex: 0xC9F2D8) : Color(hex: 0xFFD3B0)
      halo.stroke(
        Path(ellipseIn: CGRect(x: -34, y: -34, width: 68, height: 68)),
        with: .color(color.opacity(0.42)), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
      let tick = CGPoint(
        x: 34 * cos(-engine.rotation - .pi / 2), y: 34 * sin(-engine.rotation - .pi / 2))
      halo.fill(
        Path(ellipseIn: CGRect(x: tick.x - 2.5, y: tick.y - 2.5, width: 5, height: 5)),
        with: .color(color))
      let label = Text(safe ? "LEVEL" : "ROTATE")
        .font(.system(size: 8, weight: .bold, design: .monospaced))
        .foregroundStyle(Color(hex: 0x1E2F45))
      let badge = Path(roundedRect: CGRect(x: -22, y: -60, width: 44, height: 14), cornerRadius: 7)
      halo.fill(badge, with: .color(color.opacity(0.94)))
      halo.draw(label, at: CGPoint(x: 0, y: -53))
    }
  }

  private func powder(_ context: inout GraphicsContext, size: CGSize) {
    let drift = reduceMotion ? 0 : time
    for index in 0..<34 {
      let x =
        fract(Double(index) * 0.618 - drift * (0.017 + Double(index % 3) * 0.004)) * size.width
      let y =
        fract(Double(index) * 0.417 + drift * (0.021 + Double(index % 2) * 0.006)) * size.height
      let radius = index % 4 == 0 ? 1.7 : index % 3 == 0 ? 1.1 : 0.7
      context.fill(
        Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
        with: .color(.white.opacity(index % 4 == 0 ? 0.42 : 0.22))
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
