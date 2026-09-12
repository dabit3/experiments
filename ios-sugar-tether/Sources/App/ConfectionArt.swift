import SwiftUI

struct HeroArt: View {
  var body: some View {
    Canvas { context, size in
      let scale = min(size.width / 320, size.height / 305)
      context.translateBy(x: (size.width - 320 * scale) / 2, y: (size.height - 305 * scale) / 2)
      context.scaleBy(x: scale, y: scale)
      Art.ellipse(
        &context, CGRect(x: 31, y: 16, width: 258, height: 258),
        Color(red: 0.94, green: 0.89, blue: 0.77).opacity(0.5))
      var orbit = Path()
      orbit.addEllipse(in: CGRect(x: 19, y: 4, width: 282, height: 282))
      context.stroke(
        orbit, with: .color(Palette.gold.opacity(0.23)),
        style: StrokeStyle(lineWidth: 1, dash: [3, 7]))
      Art.thread(&context, anchor: V(x: 159, y: 9), end: V(x: 162, y: 97), cut: false)
      Art.star(&context, at: V(x: 73, y: 100), radius: 18, earned: false)
      Art.star(&context, at: V(x: 255, y: 120), radius: 14, earned: false)
      Art.star(&context, at: V(x: 255, y: 221), radius: 10, earned: false)
      Art.candy(&context, at: V(x: 162, y: 97), radius: 25, rotation: -0.2)
      Art.creature(
        &context, at: V(x: 162, y: 232), look: V(x: 162, y: 97), happy: false, scale: 1.5)
      Art.leaf(&context, at: V(x: 46, y: 239), angle: -0.5, scale: 0.7)
      Art.leaf(&context, at: V(x: 282, y: 270), angle: 0.6, scale: 0.55)
      Art.label(
        &context, "oh, sugar!", at: V(x: 236, y: 53), size: 12, color: Palette.muted, italic: true)
    }.accessibilityLabel("Pip, a little mint creature, waiting for a striped candy pearl")
  }
}

struct MiniPip: View {
  var happy = true
  var body: some View {
    Canvas { context, size in
      let scale = min(1.1, (size.height - 10) / 120)
      Art.creature(
        &context, at: V(x: size.width / 2, y: size.height * 0.56),
        look: V(x: size.width / 2, y: 20), happy: happy, scale: scale)
      if happy {
        Art.star(&context, at: V(x: size.width / 2 - 79, y: 25), radius: 10, earned: false)
        Art.star(&context, at: V(x: size.width / 2 + 75, y: 39), radius: 8, earned: false)
      }
    }.accessibilityHidden(true)
  }
}

struct GameArt: View {
  let game: PhysicsGame
  let trail: [V]
  let cutFlash: Double
  var body: some View {
    Canvas { context, size in
      context.scaleBy(x: size.width / 360, y: size.height / 560)
      var edge = Path()
      edge.addRoundedRect(
        in: CGRect(x: 10, y: 10, width: 340, height: 540), cornerSize: CGSize(width: 20, height: 20)
      )
      context.stroke(
        edge, with: .color(Palette.gold.opacity(0.15)),
        style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
      Art.ellipse(
        &context, CGRect(x: 20, y: 428, width: 320, height: 128),
        Color(red: 0.91, green: 0.87, blue: 0.72).opacity(0.23))
      Art.leaf(&context, at: V(x: 31, y: 520), angle: -0.6, scale: 0.65)
      Art.leaf(&context, at: V(x: 326, y: 520), angle: 0.5, scale: 0.7)
      for i in 0..<190 {
        let x = Double((i * 113) % 331) + 15
        let y = Double((i * 73) % 523) + 15
        Art.ellipse(&context, CGRect(x: x, y: y, width: 1, height: 1), Palette.ink.opacity(0.05))
      }
      for thread in game.threads {
        Art.thread(&context, anchor: thread.anchor, end: game.position, cut: thread.cut)
      }
      for (index, star) in game.puzzle.stars.enumerated() {
        if !game.collected.contains(index) {
          Art.star(&context, at: star, radius: 15, earned: false)
        } else {
          Art.star(&context, at: star, radius: 7, earned: true)
        }
      }
      for thorn in game.puzzle.thorns {
        Art.thorns(&context, at: thorn.position(at: game.time), width: thorn.width)
      }
      if let bubble = game.puzzle.bubble, game.bubbleAvailable {
        Art.bubble(&context, at: bubble)
      }
      Art.creature(&context, at: game.puzzle.goal, look: game.position, happy: game.outcome == .fed)
      Art.label(
        &context, "PIP", at: game.puzzle.goal + V(x: 0, y: 63), size: 8, color: Palette.muted)
      if game.outcome != .fed {
        if game.bubbleActive { Art.bubble(&context, at: game.position) }
        Art.candy(&context, at: game.position, radius: 16, rotation: game.position.x / 100)
      } else {
        for index in 0..<12 {
          let angle = Double(index) * .pi / 6
          let point = game.puzzle.goal + V(x: cos(angle) * 74, y: sin(angle) * 65)
          Art.star(&context, at: point, radius: index % 2 == 0 ? 7 : 4, earned: false)
        }
      }
      if trail.count > 1 {
        var path = Path()
        path.move(to: CGPoint(x: trail[0].x, y: trail[0].y))
        for point in trail.dropFirst() { path.addLine(to: CGPoint(x: point.x, y: point.y)) }
        context.stroke(
          path, with: .color(Palette.pink.opacity(0.75)),
          style: StrokeStyle(lineWidth: 3, lineCap: .round))
      }
      if cutFlash > 0 {
        Art.label(
          &context, "snip!", at: V(x: 305, y: 40), size: 14,
          color: Palette.pink.opacity(cutFlash), italic: true)
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

  static func star(_ context: inout GraphicsContext, at point: V, radius: Double, earned: Bool) {
    var shape = Path()
    for i in 0..<10 {
      let angle = Double(i) * .pi / 5 - .pi / 2
      let r = i % 2 == 0 ? radius : radius * 0.48
      let p = CGPoint(x: point.x + cos(angle) * r, y: point.y + sin(angle) * r)
      if i == 0 { shape.move(to: p) } else { shape.addLine(to: p) }
    }
    shape.closeSubpath()
    if earned {
      context.stroke(shape, with: .color(Palette.gold.opacity(0.3)), lineWidth: 1)
    } else {
      var shadow = context
      shadow.translateBy(x: 0, y: 2.5)
      shadow.fill(shape, with: .color(Color(red: 0.65, green: 0.43, blue: 0.16).opacity(0.35)))
      context.fill(
        shape,
        with: .linearGradient(
          Gradient(colors: [Color(red: 1, green: 0.86, blue: 0.43), Palette.gold]),
          startPoint: CGPoint(x: point.x, y: point.y - radius),
          endPoint: CGPoint(x: point.x, y: point.y + radius)))
      context.stroke(shape, with: .color(.white.opacity(0.55)), lineWidth: 0.8)
      ellipse(
        &context, CGRect(x: point.x - 3, y: point.y - 5, width: 3, height: 3), .white.opacity(0.65))
    }
  }

  static func thread(_ context: inout GraphicsContext, anchor: V, end: V, cut: Bool) {
    let terminal = cut ? anchor + (end - anchor) * (19 / max(19, anchor.distance(end))) : end
    var path = Path()
    path.move(to: CGPoint(x: anchor.x, y: anchor.y))
    path.addLine(to: CGPoint(x: terminal.x, y: terminal.y))
    var shadow = context
    shadow.translateBy(x: 1.5, y: 2)
    shadow.stroke(path, with: .color(Palette.ink.opacity(0.08)), lineWidth: 4)
    context.stroke(
      path, with: .color(Color(red: 0.63, green: 0.47, blue: 0.29)),
      style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
    context.stroke(
      path, with: .color(Color(red: 0.99, green: 0.89, blue: 0.66)),
      style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 3]))
    ellipse(
      &context, CGRect(x: anchor.x - 10, y: anchor.y - 8, width: 20, height: 20),
      Palette.ink.opacity(0.1))
    ellipse(
      &context, CGRect(x: anchor.x - 10, y: anchor.y - 10, width: 20, height: 20),
      Color(red: 0.83, green: 0.70, blue: 0.48))
    ellipse(
      &context, CGRect(x: anchor.x - 7, y: anchor.y - 7, width: 14, height: 14),
      Color(red: 0.97, green: 0.87, blue: 0.66))
    ellipse(
      &context, CGRect(x: anchor.x - 2.5, y: anchor.y - 2.5, width: 5, height: 5),
      Color(red: 0.57, green: 0.44, blue: 0.26))
  }

  static func candy(_ context: inout GraphicsContext, at point: V, radius: Double, rotation: Double)
  {
    var c = context
    c.translateBy(x: point.x, y: point.y)
    c.rotate(by: .radians(rotation))
    ellipse(
      &c, CGRect(x: -radius, y: -radius + 3, width: radius * 2, height: radius * 2),
      Palette.pink.opacity(0.2))
    let circle = Path(
      ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
    c.fill(
      circle,
      with: .linearGradient(
        Gradient(colors: [Color(red: 1, green: 0.69, blue: 0.62), Palette.pink]),
        startPoint: CGPoint(x: -radius, y: -radius), endPoint: CGPoint(x: radius, y: radius)))
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
        stripe, with: .color(Color(red: 1, green: 0.93, blue: 0.79)),
        style: StrokeStyle(lineWidth: radius * 0.29))
    }
    c.stroke(circle, with: .color(Palette.pink.opacity(0.7)), lineWidth: 1)
    ellipse(
      &c, CGRect(x: -radius * 0.58, y: -radius * 0.66, width: radius * 0.8, height: radius * 0.38),
      .white.opacity(0.65))
    ellipse(
      &c, CGRect(x: -radius * 0.68, y: -radius * 0.1, width: radius * 0.15, height: radius * 0.15),
      .white.opacity(0.8))
  }

  static func bubble(_ context: inout GraphicsContext, at point: V) {
    let rect = CGRect(x: point.x - 34, y: point.y - 34, width: 68, height: 68)
    let path = Path(ellipseIn: rect)
    context.fill(path, with: .color(Color(red: 0.64, green: 0.84, blue: 0.84).opacity(0.2)))
    context.stroke(
      path,
      with: .linearGradient(
        Gradient(colors: [
          .white, Color(red: 0.5, green: 0.76, blue: 0.76), Palette.pink.opacity(0.4),
        ]),
        startPoint: rect.origin, endPoint: CGPoint(x: rect.maxX, y: rect.maxY)), lineWidth: 2)
    var shine = Path()
    shine.addArc(
      center: CGPoint(x: point.x, y: point.y), radius: 28,
      startAngle: .degrees(200), endAngle: .degrees(253), clockwise: false)
    context.stroke(
      shine, with: .color(.white.opacity(0.9)),
      style: StrokeStyle(lineWidth: 3, lineCap: .round))
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
    c.fill(path, with: .color(Palette.mint.opacity(0.5)))
    var vein = Path()
    vein.move(to: .zero)
    vein.addLine(to: CGPoint(x: 0, y: -36))
    c.stroke(vein, with: .color(Palette.paper.opacity(0.6)), lineWidth: 1)
  }

  static func creature(
    _ context: inout GraphicsContext, at point: V, look: V, happy: Bool, scale: Double = 1
  ) {
    var c = context
    c.translateBy(x: point.x, y: point.y)
    c.scaleBy(x: scale, y: scale)
    ellipse(&c, CGRect(x: -54, y: 36, width: 108, height: 16), Palette.ink.opacity(0.1))
    ellipse(&c, CGRect(x: -38, y: 32, width: 29, height: 15), Palette.deepMint)
    ellipse(&c, CGRect(x: 10, y: 32, width: 29, height: 15), Palette.deepMint)
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
      with: .linearGradient(
        Gradient(colors: [Color(red: 0.64, green: 0.78, blue: 0.51), Palette.mint]),
        startPoint: CGPoint(x: -30, y: -50), endPoint: CGPoint(x: 35, y: 42)))
    c.stroke(body, with: .color(Palette.deepMint.opacity(0.6)), lineWidth: 1)
    var texture = c
    texture.clip(to: body)
    for index in 0..<230 {
      let x = Double((index * 37) % 113) - 56
      let y = Double((index * 53) % 105) - 60
      ellipse(&texture, CGRect(x: x, y: y, width: 1.2, height: 1.6), .white.opacity(0.15))
    }
    var stitch = c
    stitch.scaleBy(x: 0.89, y: 0.89)
    stitch.stroke(
      body, with: .color(Color.white.opacity(0.3)),
      style: StrokeStyle(lineWidth: 0.8, lineCap: .round, dash: [2, 4]))
    for side in [-1.0, 1.0] {
      ellipse(&c, CGRect(x: side * 21 - 13, y: -36, width: 26, height: 31), Palette.paper)
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
          &c, CGRect(x: side * 21 - 3 + offset, y: -23 + yOffset, width: 3, height: 4), .white)
      }
      ellipse(&c, CGRect(x: side * 38 - 9, y: -6, width: 18, height: 9), Palette.pink.opacity(0.42))
    }
    let mouth = Path(ellipseIn: CGRect(x: -22, y: -4, width: 44, height: happy ? 29 : 34))
    c.fill(mouth, with: .color(Palette.ink))
    var inside = c
    inside.clip(to: mouth)
    ellipse(&inside, CGRect(x: -14, y: 15, width: 30, height: 20), Palette.pink)
    inside.fill(
      Path(roundedRect: CGRect(x: -10, y: -7, width: 9, height: 11), cornerRadius: 2),
      with: .color(Palette.paper))
    inside.fill(
      Path(roundedRect: CGRect(x: 2, y: -7, width: 9, height: 11), cornerRadius: 2),
      with: .color(Palette.paper))
  }

  static func thorns(_ context: inout GraphicsContext, at point: V, width: Double) {
    let rect = CGRect(x: point.x - width / 2, y: point.y - 8, width: width, height: 16)
    context.fill(
      Path(roundedRect: rect.offsetBy(dx: 0, dy: 3), cornerRadius: 6),
      with: .color(Palette.ink.opacity(0.15)))
    context.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(Palette.pink))
    for index in 0..<Int(width / 13) {
      let x = rect.minX + 7 + Double(index) * 13
      var triangle = Path()
      triangle.move(to: CGPoint(x: x - 6, y: point.y - 5))
      triangle.addLine(to: CGPoint(x: x, y: point.y - 20))
      triangle.addLine(to: CGPoint(x: x + 6, y: point.y - 5))
      triangle.closeSubpath()
      context.fill(triangle, with: .color(Palette.pink))
      var glint = Path()
      glint.move(to: CGPoint(x: x - 3, y: point.y - 7))
      glint.addLine(to: CGPoint(x: x, y: point.y - 15))
      context.stroke(glint, with: .color(.white.opacity(0.4)), lineWidth: 1)
    }
  }
}
