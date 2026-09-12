import SwiftUI

struct HeroArt: View {
  var phase = 0.0
  var body: some View {
    Canvas { context, size in
      let scale = min(size.width / 320, size.height / 305)
      context.translateBy(x: (size.width - 320 * scale) / 2, y: (size.height - 305 * scale) / 2)
      context.scaleBy(x: scale, y: scale)
      let sway = sin(phase) * 0.16
      let bob = sin(phase * 2) * 2
      context.fill(
        Path(ellipseIn: CGRect(x: 26, y: 18, width: 268, height: 268)),
        with: .radialGradient(
          Gradient(colors: [Palette.honey.opacity(0.42), Palette.honey.opacity(0)]),
          center: CGPoint(x: 160, y: 152), startRadius: 20, endRadius: 150))
      var orbit = Path()
      orbit.addEllipse(in: CGRect(x: 19, y: 4, width: 282, height: 282))
      context.stroke(
        orbit, with: .color(Palette.caramel.opacity(0.28)),
        style: StrokeStyle(lineWidth: 1, dash: [1, 6]))
      Art.hill(&context, rect: CGRect(x: 34, y: 236, width: 252, height: 70), tone: 0)
      Art.hill(&context, rect: CGRect(x: 70, y: 256, width: 190, height: 52), tone: 1)
      let candy = V(x: 160 + sin(sway) * 90, y: 9 + cos(sway) * 90)
      Art.thread(&context, anchor: V(x: 160, y: 9), end: candy, cut: false)
      Art.star(&context, at: V(x: 68, y: 104 + bob), radius: 18)
      Art.star(&context, at: V(x: 258, y: 118 - bob), radius: 14)
      Art.star(&context, at: V(x: 250, y: 212 + bob * 0.6), radius: 10)
      Art.candy(&context, at: candy, radius: 25, rotation: -0.2 + sway)
      Art.creature(
        &context, at: V(x: 160, y: 232 + bob * 0.4), look: candy, happy: false, scale: 1.5)
      Art.leaf(&context, at: V(x: 42, y: 246), angle: -0.5, scale: 0.7)
      Art.leaf(&context, at: V(x: 286, y: 276), angle: 0.6, scale: 0.55)
      Art.tag(&context, "oh, sugar!", at: V(x: 246, y: 50), tilt: 0.12)
    }.accessibilityLabel("Pip, a little mint creature, waiting for a striped candy pearl")
  }
}

struct MiniPip: View {
  var happy = true
  var body: some View {
    Canvas { context, size in
      let scale = min(1.1, (size.height - 10) / 120)
      let base = V(x: size.width / 2, y: size.height * 0.56)
      Art.hill(
        &context,
        rect: CGRect(
          x: base.x - 92 * scale, y: base.y + 26 * scale, width: 184 * scale, height: 30),
        tone: 1)
      Art.creature(
        &context, at: base, look: V(x: size.width / 2, y: 20), happy: happy, scale: scale)
      if happy {
        Art.star(&context, at: V(x: size.width / 2 - 79, y: 25), radius: 10)
        Art.star(&context, at: V(x: size.width / 2 + 75, y: 39), radius: 8)
        Art.star(&context, at: V(x: size.width / 2 + 60, y: 6), radius: 5)
      }
    }.accessibilityHidden(true)
  }
}

struct GameArt: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let game: PhysicsGame
  let trail: [V]
  let cutFlash: Double
  let puffFlash: Double
  let sparkles: [Int: Double]
  let hasBegun: Bool
  var body: some View {
    Canvas { context, size in
      context.scaleBy(x: size.width / 360, y: size.height / 560)
      Art.scene(&context)
      if !hasBegun || (game.bubbleActive && game.collected.count == 3) {
        Art.ribbon(
          &context, hasBegun ? "TAP THE BUBBLE" : "TAP TO BEGIN  ·  SWIPE TO SNIP",
          center: CGPoint(x: 180, y: 30), width: hasBegun ? 150 : 214)
      }
      for thread in game.threads {
        Art.thread(&context, anchor: thread.anchor, end: game.position, cut: thread.cut)
      }
      for (index, star) in game.puzzle.stars.enumerated() where !game.collected.contains(index) {
        Art.halo(&context, at: star, radius: 26)
        Art.star(&context, at: star, radius: 15)
      }
      for (index, life) in sparkles {
        let star = game.puzzle.stars[index]
        var glow = context
        glow.opacity = life
        for ray in 0..<8 {
          let angle = Double(ray) * .pi / 4 + (1 - life) * 0.6
          let radius = reduceMotion ? 22 : 17 + (1 - life) * 30
          let point = star + V(x: cos(angle) * radius, y: sin(angle) * radius)
          let dot = ray % 2 == 0 ? 2.6 : 1.6
          Art.ellipse(
            &glow, CGRect(x: point.x - dot, y: point.y - dot, width: dot * 2, height: dot * 2),
            ray % 2 == 0 ? Palette.gold : Palette.pink)
        }
      }
      for thorn in game.puzzle.thorns {
        Art.thorns(&context, at: thorn.position(at: game.time), width: thorn.width)
      }
      if let bubble = game.puzzle.bubble, game.bubbleAvailable {
        Art.bubble(&context, at: bubble)
      }
      Art.creature(&context, at: game.puzzle.goal, look: game.position, happy: game.outcome == .fed)
      if game.outcome != .fed {
        if game.bubbleActive { Art.bubble(&context, at: game.position) }
        Art.candy(&context, at: game.position, radius: 16, rotation: game.position.x / 100)
      } else {
        for index in 0..<12 {
          let angle = Double(index) * .pi / 6
          let point = game.puzzle.goal + V(x: cos(angle) * 74, y: sin(angle) * 65)
          Art.star(&context, at: point, radius: index % 2 == 0 ? 7 : 4)
        }
      }
      if trail.count > 1 {
        var path = Path()
        path.move(to: CGPoint(x: trail[0].x, y: trail[0].y))
        for point in trail.dropFirst() { path.addLine(to: CGPoint(x: point.x, y: point.y)) }
        context.stroke(
          path, with: .color(.white.opacity(0.9)),
          style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
        context.stroke(
          path, with: .color(Palette.pink.opacity(0.85)),
          style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
      }
      if cutFlash > 0 {
        var flash = context
        flash.opacity = cutFlash
        Art.tag(&flash, "snip!", at: V(x: 300, y: 46), tilt: -0.14)
      }
      if puffFlash > 0 {
        let offset = reduceMotion ? 0 : (1 - puffFlash) * 70
        for index in 0..<4 {
          let y = 334.0 + Double(index) * 18
          var wind = Path()
          wind.move(to: CGPoint(x: 32 + offset, y: y))
          wind.addQuadCurve(
            to: CGPoint(x: 111 + offset, y: y - 22),
            control: CGPoint(x: 86 + offset, y: y + 2))
          context.stroke(
            wind, with: .color(.white.opacity(puffFlash * 0.9)),
            style: StrokeStyle(lineWidth: 4, lineCap: .round))
          context.stroke(
            wind, with: .color(Palette.deepMint.opacity(puffFlash * 0.7)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
      }
    }
  }
}

enum Art {
  static func ellipse(_ context: inout GraphicsContext, _ rect: CGRect, _ color: Color) {
    context.fill(Path(ellipseIn: rect), with: .color(color))
  }

  static func label(
    _ context: inout GraphicsContext, _ string: String, at point: V,
    size: Double, color: Color, italic: Bool = false
  ) {
    let text = Text(string).font(.system(size: size, weight: .medium, design: .serif))
      .italic(italic).foregroundStyle(color)
    context.draw(text, at: CGPoint(x: point.x, y: point.y))
  }

  /// A tilted paper tag with an italic serif note, used for tiny bits of personality.
  static func tag(_ context: inout GraphicsContext, _ string: String, at point: V, tilt: Double) {
    var c = context
    c.translateBy(x: point.x, y: point.y)
    c.rotate(by: .radians(tilt))
    let width = Double(string.count) * 6.6 + 18
    let rect = CGRect(x: -width / 2, y: -11, width: width, height: 22)
    c.fill(
      Path(roundedRect: rect.offsetBy(dx: 0, dy: 2), cornerRadius: 6),
      with: .color(Palette.caramel.opacity(0.18)))
    c.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(.white))
    c.stroke(
      Path(roundedRect: rect.insetBy(dx: 3, dy: 3), cornerRadius: 4),
      with: .color(Palette.honey.opacity(0.9)),
      style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
    label(&c, string, at: .zero, size: 12, color: Palette.caramel, italic: true)
  }

  /// A stitched felt ribbon carrying a short instruction.
  static func ribbon(
    _ context: inout GraphicsContext, _ string: String, center: CGPoint, width: Double
  ) {
    let rect = CGRect(x: center.x - width / 2, y: center.y - 14, width: width, height: 28)
    for side in [-1.0, 1.0] {
      var tail = Path()
      let x = side > 0 ? rect.maxX : rect.minX
      tail.move(to: CGPoint(x: x, y: rect.minY + 5))
      tail.addLine(to: CGPoint(x: x + side * 12, y: rect.minY + 8))
      tail.addLine(to: CGPoint(x: x + side * 8, y: rect.midY + 4))
      tail.addLine(to: CGPoint(x: x + side * 12, y: rect.maxY))
      tail.addLine(to: CGPoint(x: x, y: rect.maxY - 5))
      tail.closeSubpath()
      context.fill(tail, with: .color(Palette.deepMint))
    }
    context.fill(
      Path(roundedRect: rect.offsetBy(dx: 0, dy: 3), cornerRadius: 6),
      with: .color(Palette.ink.opacity(0.22)))
    context.fill(
      Path(roundedRect: rect, cornerRadius: 6),
      with: .linearGradient(
        Gradient(colors: [Palette.mint, Palette.deepMint]),
        startPoint: CGPoint(x: rect.midX, y: rect.minY),
        endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
    context.stroke(
      Path(roundedRect: rect.insetBy(dx: 4, dy: 4), cornerRadius: 3),
      with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
    context.draw(
      Text(string).font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.2)
        .foregroundStyle(Palette.cream),
      at: center)
  }

  /// The layered playfield: sky wash, paper clouds, felt hills and a stitched frame.
  static func scene(_ context: inout GraphicsContext) {
    let frame = CGRect(x: 0, y: 0, width: 360, height: 560)
    let sky = Path(roundedRect: frame, cornerRadius: 30)
    context.fill(
      sky,
      with: .linearGradient(
        Gradient(colors: [Palette.cream, Color(red: 0.99, green: 0.93, blue: 0.86)]),
        startPoint: CGPoint(x: 180, y: 0), endPoint: CGPoint(x: 180, y: 560)))
    context.fill(
      sky,
      with: .radialGradient(
        Gradient(colors: [Palette.honey.opacity(0.3), Palette.honey.opacity(0)]),
        center: CGPoint(x: 250, y: 90), startRadius: 0, endRadius: 210))
    cloud(&context, at: CGPoint(x: 62, y: 118), scale: 1)
    cloud(&context, at: CGPoint(x: 300, y: 204), scale: 0.72)
    cloud(&context, at: CGPoint(x: 48, y: 318), scale: 0.6)
    var inner = context
    inner.clip(to: sky)
    hill(&inner, rect: CGRect(x: -40, y: 508, width: 260, height: 90), tone: 0)
    hill(&inner, rect: CGRect(x: 150, y: 500, width: 280, height: 100), tone: 0)
    hill(&inner, rect: CGRect(x: -20, y: 528, width: 420, height: 80), tone: 1)
    for i in 0..<160 {
      let x = Double((i * 113) % 331) + 15
      let y = Double((i * 73) % 523) + 15
      ellipse(&context, CGRect(x: x, y: y, width: 1, height: 1), Palette.ink.opacity(0.05))
    }
    context.stroke(
      Path(roundedRect: frame.insetBy(dx: 4, dy: 4), cornerRadius: 26),
      with: .color(Palette.mint), lineWidth: 8)
    context.stroke(
      Path(roundedRect: frame.insetBy(dx: 4, dy: 4), cornerRadius: 26),
      with: .color(Palette.cream.opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
    context.stroke(
      Path(roundedRect: frame.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 30),
      with: .color(Palette.deepMint.opacity(0.55)), lineWidth: 1)
    for corner in [
      CGPoint(x: 18, y: 18), CGPoint(x: 342, y: 18), CGPoint(x: 18, y: 542),
      CGPoint(x: 342, y: 542),
    ] {
      ellipse(&context, CGRect(x: corner.x - 4, y: corner.y - 4, width: 8, height: 8), Palette.gold)
      ellipse(
        &context, CGRect(x: corner.x - 2, y: corner.y - 2.5, width: 3, height: 3),
        .white.opacity(0.8))
    }
  }

  static func cloud(_ context: inout GraphicsContext, at point: CGPoint, scale: Double) {
    var c = context
    c.translateBy(x: point.x, y: point.y)
    c.scaleBy(x: scale, y: scale)
    var path = Path()
    path.addEllipse(in: CGRect(x: -40, y: -12, width: 44, height: 30))
    path.addEllipse(in: CGRect(x: -20, y: -26, width: 50, height: 44))
    path.addEllipse(in: CGRect(x: 8, y: -14, width: 40, height: 32))
    path.addRect(CGRect(x: -36, y: 2, width: 80, height: 16))
    c.fill(path, with: .color(.white.opacity(0.55)))
    c.translateBy(x: 0, y: 3)
    c.fill(path, with: .color(.white.opacity(0.35)))
  }

  /// A soft felt hill with a stitched crest.
  static func hill(_ context: inout GraphicsContext, rect: CGRect, tone: Int) {
    let path = Path(ellipseIn: rect)
    let colors =
      tone == 0
      ? [Color(red: 0.76, green: 0.87, blue: 0.72), Color(red: 0.62, green: 0.78, blue: 0.58)]
      : [Color(red: 0.62, green: 0.78, blue: 0.58), Palette.mint]
    context.fill(
      path,
      with: .linearGradient(
        Gradient(colors: colors), startPoint: CGPoint(x: rect.midX, y: rect.minY),
        endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
    var stitch = context
    stitch.clip(to: path)
    stitch.stroke(
      Path(ellipseIn: rect.insetBy(dx: 6, dy: 5)), with: .color(.white.opacity(0.5)),
      style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
  }

  static func halo(_ context: inout GraphicsContext, at point: V, radius: Double) {
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
      with: .radialGradient(
        Gradient(colors: [Palette.honey.opacity(0.45), Palette.honey.opacity(0)]),
        center: CGPoint(x: point.x, y: point.y), startRadius: 2, endRadius: radius))
  }

  static func starPath(at point: V, radius: Double) -> Path {
    var shape = Path()
    for i in 0..<10 {
      let angle = Double(i) * .pi / 5 - .pi / 2
      let r = i % 2 == 0 ? radius : radius * 0.48
      let p = CGPoint(x: point.x + cos(angle) * r, y: point.y + sin(angle) * r)
      if i == 0 { shape.move(to: p) } else { shape.addLine(to: p) }
    }
    shape.closeSubpath()
    return shape
  }

  /// A bevelled candy-glass star: caramel base, gold body, pale inner facet and a glint.
  static func star(_ context: inout GraphicsContext, at point: V, radius: Double) {
    let shape = starPath(at: point, radius: radius)
    var shadow = context
    shadow.translateBy(x: 0, y: radius * 0.16)
    shadow.fill(shape, with: .color(Palette.caramel.opacity(0.9)))
    context.fill(
      shape,
      with: .linearGradient(
        Gradient(colors: [Color(red: 1, green: 0.9, blue: 0.5), Palette.gold]),
        startPoint: CGPoint(x: point.x, y: point.y - radius),
        endPoint: CGPoint(x: point.x, y: point.y + radius)))
    context.fill(
      starPath(at: point + V(x: 0, y: radius * 0.04), radius: radius * 0.58),
      with: .color(Color(red: 1, green: 0.95, blue: 0.72).opacity(0.75)))
    context.stroke(shape, with: .color(Palette.caramel.opacity(0.35)), lineWidth: 0.7)
    ellipse(
      &context,
      CGRect(
        x: point.x - radius * 0.3, y: point.y - radius * 0.42, width: radius * 0.22,
        height: radius * 0.22),
      .white.opacity(0.9))
  }

  /// A twisted silk thread hung from a brass button anchor.
  static func thread(_ context: inout GraphicsContext, anchor: V, end: V, cut: Bool) {
    let terminal = cut ? anchor + (end - anchor) * (19 / max(19, anchor.distance(end))) : end
    var path = Path()
    path.move(to: CGPoint(x: anchor.x, y: anchor.y))
    path.addLine(to: CGPoint(x: terminal.x, y: terminal.y))
    var shadow = context
    shadow.translateBy(x: 1.5, y: 2.5)
    shadow.stroke(path, with: .color(Palette.ink.opacity(0.12)), lineWidth: 4)
    context.stroke(
      path, with: .color(Color(red: 0.56, green: 0.40, blue: 0.24)),
      style: StrokeStyle(lineWidth: 4, lineCap: .round))
    context.stroke(
      path, with: .color(Color(red: 0.78, green: 0.60, blue: 0.38)),
      style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
    context.stroke(
      path, with: .color(Color(red: 1, green: 0.92, blue: 0.72)),
      style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [2.5, 3.5]))
    if cut {
      for i in 0..<3 {
        let t =
          terminal + (terminal - anchor)
          * (Double(i + 1) * 0.12 / max(1, anchor.distance(end) / 19))
        let wobble = V(x: Double(i % 2 == 0 ? 3 : -3), y: 0)
        ellipse(
          &context, CGRect(x: t.x + wobble.x - 1, y: t.y - 1, width: 2, height: 2), Palette.caramel)
      }
    }
    ellipse(
      &context, CGRect(x: anchor.x - 11, y: anchor.y - 8, width: 22, height: 22),
      Palette.ink.opacity(0.14))
    context.fill(
      Path(ellipseIn: CGRect(x: anchor.x - 11, y: anchor.y - 11, width: 22, height: 22)),
      with: .linearGradient(
        Gradient(colors: [Color(red: 0.98, green: 0.86, blue: 0.56), Palette.caramel]),
        startPoint: CGPoint(x: anchor.x - 8, y: anchor.y - 10),
        endPoint: CGPoint(x: anchor.x + 8, y: anchor.y + 10)))
    context.stroke(
      Path(ellipseIn: CGRect(x: anchor.x - 7.5, y: anchor.y - 7.5, width: 15, height: 15)),
      with: .color(Color(red: 0.55, green: 0.38, blue: 0.2).opacity(0.5)), lineWidth: 1)
    for side in [-1.0, 1.0] {
      ellipse(
        &context,
        CGRect(x: anchor.x + side * 3.4 - 1.6, y: anchor.y - 1.6, width: 3.2, height: 3.2),
        Color(red: 0.45, green: 0.31, blue: 0.16))
    }
    ellipse(
      &context, CGRect(x: anchor.x - 6, y: anchor.y - 8, width: 5, height: 2.6), .white.opacity(0.7)
    )
  }

  static func candy(_ context: inout GraphicsContext, at point: V, radius: Double, rotation: Double)
  {
    var c = context
    c.translateBy(x: point.x, y: point.y)
    c.rotate(by: .radians(rotation))
    ellipse(
      &c, CGRect(x: -radius, y: -radius + 4, width: radius * 2, height: radius * 2),
      Palette.caramel.opacity(0.22))
    let circle = Path(
      ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
    c.fill(
      circle,
      with: .radialGradient(
        Gradient(colors: [Color(red: 1, green: 0.78, blue: 0.72), Palette.pink, Palette.plum]),
        center: CGPoint(x: -radius * 0.35, y: -radius * 0.4), startRadius: 0,
        endRadius: radius * 1.5))
    var stripeContext = c
    stripeContext.clip(to: circle)
    for i in -2...2 {
      var stripe = Path()
      stripe.move(to: CGPoint(x: Double(i) * radius * 0.7 - radius, y: -radius))
      stripe.addCurve(
        to: CGPoint(x: Double(i) * radius * 0.7 + radius, y: radius),
        control1: CGPoint(x: Double(i) * radius * 0.7 + radius * 0.6, y: -radius),
        control2: CGPoint(x: Double(i) * radius * 0.7 - radius * 0.6, y: radius))
      stripeContext.stroke(
        stripe, with: .color(Color(red: 1, green: 0.95, blue: 0.85)),
        style: StrokeStyle(lineWidth: radius * 0.27))
    }
    stripeContext.fill(
      circle,
      with: .radialGradient(
        Gradient(colors: [.clear, Palette.plum.opacity(0.35)]),
        center: CGPoint(x: -radius * 0.3, y: -radius * 0.3), startRadius: radius * 0.5,
        endRadius: radius * 1.25))
    c.stroke(circle, with: .color(Palette.plum.opacity(0.55)), lineWidth: 1)
    ellipse(
      &c, CGRect(x: -radius * 0.6, y: -radius * 0.7, width: radius * 0.8, height: radius * 0.4),
      .white.opacity(0.75))
    ellipse(
      &c, CGRect(x: -radius * 0.7, y: -radius * 0.1, width: radius * 0.16, height: radius * 0.16),
      .white.opacity(0.85))
    ellipse(
      &c, CGRect(x: radius * 0.28, y: radius * 0.45, width: radius * 0.42, height: radius * 0.2),
      .white.opacity(0.28))
  }

  static func bubble(_ context: inout GraphicsContext, at point: V) {
    let rect = CGRect(x: point.x - 34, y: point.y - 34, width: 68, height: 68)
    let path = Path(ellipseIn: rect)
    context.fill(
      path,
      with: .radialGradient(
        Gradient(colors: [
          .white.opacity(0.05), Color(red: 0.64, green: 0.86, blue: 0.86).opacity(0.18),
          Color(red: 0.75, green: 0.9, blue: 0.9).opacity(0.5),
        ]),
        center: CGPoint(x: point.x, y: point.y), startRadius: 8, endRadius: 34))
    context.stroke(
      path,
      with: .linearGradient(
        Gradient(colors: [
          .white, Color(red: 0.5, green: 0.78, blue: 0.78), Palette.pink.opacity(0.55),
          Palette.honey.opacity(0.7),
        ]),
        startPoint: rect.origin, endPoint: CGPoint(x: rect.maxX, y: rect.maxY)), lineWidth: 2.2)
    var shine = Path()
    shine.addArc(
      center: CGPoint(x: point.x, y: point.y), radius: 27,
      startAngle: .degrees(200), endAngle: .degrees(253), clockwise: false)
    context.stroke(
      shine, with: .color(.white.opacity(0.95)),
      style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
    ellipse(
      &context, CGRect(x: point.x + 14, y: point.y + 12, width: 7, height: 5), .white.opacity(0.6))
  }

  static func leaf(_ context: inout GraphicsContext, at point: V, angle: Double, scale: Double) {
    var c = context
    c.translateBy(x: point.x, y: point.y)
    c.rotate(by: .radians(angle))
    c.scaleBy(x: scale, y: scale)
    var path = Path()
    path.move(to: CGPoint(x: 0, y: 0))
    path.addQuadCurve(to: CGPoint(x: 0, y: -47), control: CGPoint(x: -27, y: -31))
    path.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: 23, y: -30))
    c.fill(
      path,
      with: .linearGradient(
        Gradient(colors: [Palette.mint.opacity(0.75), Palette.deepMint.opacity(0.7)]),
        startPoint: CGPoint(x: 0, y: -47), endPoint: CGPoint(x: 0, y: 0)))
    var vein = Path()
    vein.move(to: .zero)
    vein.addLine(to: CGPoint(x: 0, y: -36))
    c.stroke(vein, with: .color(Palette.cream.opacity(0.7)), lineWidth: 1)
  }

  static func creature(
    _ context: inout GraphicsContext, at point: V, look: V, happy: Bool, scale: Double = 1
  ) {
    var c = context
    c.translateBy(x: point.x, y: point.y)
    c.scaleBy(x: scale, y: scale)
    ellipse(&c, CGRect(x: -54, y: 36, width: 108, height: 16), Palette.ink.opacity(0.12))
    ellipse(&c, CGRect(x: -38, y: 32, width: 29, height: 15), Palette.deepMint)
    ellipse(&c, CGRect(x: 10, y: 32, width: 29, height: 15), Palette.deepMint)
    ellipse(&c, CGRect(x: -34, y: 33, width: 18, height: 6), Palette.mint.opacity(0.7))
    ellipse(&c, CGRect(x: 14, y: 33, width: 18, height: 6), Palette.mint.opacity(0.7))
    leaf(&c, at: V(x: -23, y: -33), angle: -0.6, scale: 0.75)
    leaf(&c, at: V(x: 24, y: -34), angle: 0.6, scale: 0.65)
    var body = Path()
    body.move(to: CGPoint(x: 0, y: -58))
    body.addCurve(
      to: CGPoint(x: 54, y: 12), control1: CGPoint(x: 39, y: -61), control2: CGPoint(x: 57, y: -21))
    body.addCurve(
      to: CGPoint(x: 0, y: 42), control1: CGPoint(x: 53, y: 40), control2: CGPoint(x: 28, y: 43))
    body.addCurve(
      to: CGPoint(x: -54, y: 12), control1: CGPoint(x: -29, y: 44), control2: CGPoint(x: -55, y: 38)
    )
    body.addCurve(
      to: CGPoint(x: 0, y: -58), control1: CGPoint(x: -59, y: -24),
      control2: CGPoint(x: -34, y: -61))
    c.fill(
      body,
      with: .radialGradient(
        Gradient(colors: [
          Color(red: 0.72, green: 0.85, blue: 0.58), Palette.mint, Palette.deepMint,
        ]),
        center: CGPoint(x: -18, y: -30), startRadius: 4, endRadius: 96))
    var belly = c
    belly.clip(to: body)
    belly.fill(
      Path(ellipseIn: CGRect(x: -30, y: 4, width: 60, height: 44)),
      with: .color(Color(red: 0.80, green: 0.90, blue: 0.68).opacity(0.5)))
    c.stroke(body, with: .color(Palette.deepMint.opacity(0.75)), lineWidth: 1.2)
    var texture = c
    texture.clip(to: body)
    for index in 0..<230 {
      let x = Double((index * 37) % 113) - 56
      let y = Double((index * 53) % 105) - 60
      ellipse(&texture, CGRect(x: x, y: y, width: 1.2, height: 1.6), .white.opacity(0.16))
    }
    var stitch = c
    stitch.scaleBy(x: 0.9, y: 0.9)
    stitch.stroke(
      body, with: .color(Palette.cream.opacity(0.55)),
      style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [2.5, 4]))
    for side in [-1.0, 1.0] {
      ellipse(
        &c, CGRect(x: side * 21 - 13, y: -35, width: 26, height: 31), Palette.ink.opacity(0.12))
      ellipse(&c, CGRect(x: side * 21 - 13, y: -36, width: 26, height: 31), Palette.cream)
      let offset = max(-3, min(3, (look.x - point.x) / 50))
      let yOffset = max(-3, min(2, (look.y - point.y) / 100))
      if happy {
        var eye = Path()
        eye.move(to: CGPoint(x: side * 21 - 6, y: -20))
        eye.addQuadCurve(
          to: CGPoint(x: side * 21 + 6, y: -20),
          control: CGPoint(x: side * 21, y: -28))
        c.stroke(
          eye, with: .color(Palette.ink), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
      } else {
        ellipse(
          &c, CGRect(x: side * 21 - 5 + offset, y: -24 + yOffset, width: 10, height: 14),
          Palette.ink)
        ellipse(
          &c, CGRect(x: side * 21 - 3 + offset, y: -23 + yOffset, width: 3.4, height: 4.4), .white)
        ellipse(
          &c, CGRect(x: side * 21 + 1 + offset, y: -14 + yOffset, width: 1.6, height: 1.6),
          .white.opacity(0.7))
      }
      ellipse(&c, CGRect(x: side * 38 - 9, y: -6, width: 18, height: 9), Palette.pink.opacity(0.45))
    }
    let mouth = Path(ellipseIn: CGRect(x: -22, y: -4, width: 44, height: happy ? 29 : 34))
    c.fill(mouth, with: .color(Palette.ink))
    var inside = c
    inside.clip(to: mouth)
    ellipse(&inside, CGRect(x: -14, y: 15, width: 30, height: 20), Palette.pink)
    inside.fill(
      Path(roundedRect: CGRect(x: -10, y: -7, width: 9, height: 11), cornerRadius: 2),
      with: .color(Palette.cream))
    inside.fill(
      Path(roundedRect: CGRect(x: 2, y: -7, width: 9, height: 11), cornerRadius: 2),
      with: .color(Palette.cream))
  }

  static func thorns(_ context: inout GraphicsContext, at point: V, width: Double) {
    let rect = CGRect(x: point.x - width / 2, y: point.y - 8, width: width, height: 16)
    context.fill(
      Path(roundedRect: rect.offsetBy(dx: 0, dy: 3), cornerRadius: 6),
      with: .color(Palette.ink.opacity(0.18)))
    context.fill(
      Path(roundedRect: rect, cornerRadius: 6),
      with: .linearGradient(
        Gradient(colors: [Color(red: 0.93, green: 0.52, blue: 0.5), Palette.plum]),
        startPoint: CGPoint(x: rect.midX, y: rect.minY),
        endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
    context.stroke(
      Path(roundedRect: rect.insetBy(dx: 3, dy: 3), cornerRadius: 3),
      with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
    for index in 0..<Int(width / 13) {
      let x = rect.minX + 7 + Double(index) * 13
      var triangle = Path()
      triangle.move(to: CGPoint(x: x - 6, y: point.y - 5))
      triangle.addLine(to: CGPoint(x: x, y: point.y - 20))
      triangle.addLine(to: CGPoint(x: x + 6, y: point.y - 5))
      triangle.closeSubpath()
      context.fill(
        triangle,
        with: .linearGradient(
          Gradient(colors: [Color(red: 0.93, green: 0.52, blue: 0.5), Palette.plum]),
          startPoint: CGPoint(x: x, y: point.y - 20), endPoint: CGPoint(x: x, y: point.y - 5)))
      var glint = Path()
      glint.move(to: CGPoint(x: x - 3, y: point.y - 7))
      glint.addLine(to: CGPoint(x: x, y: point.y - 15))
      context.stroke(glint, with: .color(.white.opacity(0.55)), lineWidth: 1)
    }
  }
}
