import SwiftUI

enum HarborPalette {
  static let ink = Color(red: 0.13, green: 0.25, blue: 0.29)
  static let sky = Color(red: 0.73, green: 0.85, blue: 0.87)
  static let cream = Color(red: 0.98, green: 0.95, blue: 0.86)
  static let orange = Color(red: 0.91, green: 0.35, blue: 0.17)
  static let brass = Color(red: 0.78, green: 0.58, blue: 0.29)
  static let pale = Color(red: 0.87, green: 0.89, blue: 0.80)
}

struct HarborCanvas: View {
  let game: GameModel
  var decorative = false
  var reducedMotion = false

  var body: some View {
    Canvas { context, size in
      let scale = size.width / 390
      context.scaleBy(x: scale, y: scale)
      let height = size.height / scale
      let deck = height - 109
      let dock = height - 57
      let clock = reducedMotion ? 0 : game.clock
      HarborArt.background(&context, height: height, clock: clock)
      HarborArt.dock(&context, y: dock)
      let cargoStack =
        decorative
        ? [
          StackedCargo(id: 0, kind: .trunk, x: 251),
          StackedCargo(id: 1, kind: .clock, x: 255),
          StackedCargo(id: 2, kind: .piano, x: 250),
        ] : game.stack
      var ship = context
      let wobble = reducedMotion ? 0 : sin(clock * 9) * game.impact * 0.035
      ship.translateBy(x: DockRules.shipX, y: deck)
      ship.rotate(by: .radians((decorative ? -0.025 : game.balance * 0.12) + wobble))
      ship.translateBy(x: -DockRules.shipX, y: -deck)
      HarborArt.airship(&ship, x: DockRules.shipX, y: deck, clock: clock)
      for (index, item) in cargoStack.enumerated() {
        HarborArt.cargo(
          &ship, kind: item.kind, x: item.x, y: deck - Double(index + 1) * item.kind.height)
      }
      HarborArt.balanceGauge(&ship, x: DockRules.shipX, y: deck + 16, balance: game.balance)
      if decorative {
        HarborArt.cargo(&context, kind: .plant, x: DockRules.dockX, y: dock - 36)
        HarborArt.crane(
          &context, anchor: 106, hookX: 102 + sin(clock * 0.6) * 15,
          hookY: max(60, deck - 147), height: dock, loaded: false)
        HarborArt.label(&context, "THE LITTLE SHIP THAT COULD", x: 244, y: deck + 99, size: 8)
      } else {
        drawGame(&context, deck: deck, dock: dock)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      decorative
        ? "A brass airship carrying a piano, clock and trunk above a powder blue harbor"
        : "\(game.cargo.title). \(game.stack.count) treasures aboard. Ship balance \(Int(abs(game.balance) * 100)) percent of limit."
    )
  }

  private func drawGame(_ context: inout GraphicsContext, deck: Double, dock: Double) {
    let phase = game.phase
    let pickup = phase == .pickup || phase == .lowering
    let anchor = pickup ? DockRules.dockX : DockRules.shipX
    let targetY = deck - Double(game.stack.count + 1) * 36
    let suspensionY = max(65, min(94, targetY - 58))
    var x = game.hookX
    var y = suspensionY
    if phase == .lowering {
      x = game.actionX
      y += (dock - 39 - suspensionY) * min(1, game.phaseTime / 0.6)
    } else if phase == .hoisting {
      let t = min(1, game.phaseTime / 1.1)
      let smooth = t * t * (3 - 2 * t)
      x = game.actionX + (game.hookX - game.actionX) * smooth
      y = dock - 39 + (suspensionY - (dock - 39)) * smooth
    } else if phase == .falling {
      x = game.actionStartX
    }
    if pickup {
      HarborArt.cargo(&context, kind: game.cargo, x: DockRules.dockX, y: dock - 36)
      HarborArt.line(
        &context, from: CGPoint(x: 46, y: dock + 4), to: CGPoint(x: 120, y: dock + 4),
        color: HarborPalette.orange, width: 4)
    }
    if game.actionable {
      let target = pickup ? DockRules.dockX : game.targetX
      let width = pickup ? game.cargo.width + 20 : (game.stack.last?.kind.width ?? 150)
      let floor = pickup ? dock - 40 : targetY - 4
      let projected =
        pickup
        ? x
        : x + cos(game.clock * game.contract.swing) * game.contract.swing
          * (game.practice ? 30 : 44) * 0.12
      HarborArt.rounded(
        &context, rect: CGRect(x: target - width / 2, y: floor, width: width, height: 9),
        radius: 4, color: HarborPalette.orange.opacity(0.25))
      var guide = Path()
      guide.move(to: CGPoint(x: projected, y: y + (pickup ? 13 : 41)))
      guide.addLine(to: CGPoint(x: projected, y: floor))
      context.stroke(
        guide, with: .color(HarborPalette.ink.opacity(0.4)),
        style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
      HarborArt.ellipse(
        &context, CGRect(x: projected - 5, y: floor - 1, width: 10, height: 4),
        HarborPalette.orange)
    }
    HarborArt.crane(
      &context, anchor: anchor, hookX: x, hookY: y, height: dock,
      loaded: phase == .hoisting || phase == .release)
    if phase == .hoisting || phase == .release {
      HarborArt.cargo(&context, kind: game.cargo, x: x, y: y + 8)
    }
    if phase == .falling {
      let t = min(1, game.phaseTime / 0.7)
      let dropY = suspensionY + 8 + (targetY - suspensionY - 8) * t * t
      let dropX = game.actionStartX + (game.actionX - game.actionStartX) * t
      HarborArt.cargo(&context, kind: game.cargo, x: dropX, y: dropY)
    }
    if phase == .settling {
      for index in 0..<12 {
        let angle = Double(index) * .pi / 6
        let distance = game.phaseTime * 50
        let point = CGPoint(
          x: game.actionX + cos(angle) * distance,
          y: targetY + 25 + sin(angle) * distance)
        HarborArt.ellipse(
          &context, CGRect(x: point.x, y: point.y, width: 3, height: 3),
          HarborPalette.orange.opacity(max(0, 1 - game.phaseTime)))
      }
    }
    HarborArt.label(&context, "SALVAGE DOCK", x: 84, y: dock + 28, size: 8)
    HarborArt.label(&context, "S.S. SMALL WONDER", x: 258, y: deck + 98, size: 8)
  }
}

enum HarborArt {
  static func background(_ c: inout GraphicsContext, height: Double, clock: Double) {
    let p = HarborPalette.self
    c.fill(Path(CGRect(x: 0, y: 0, width: 390, height: height)), with: .color(p.sky))
    ellipse(&c, CGRect(x: 275, y: 20, width: 62, height: 62), p.cream.opacity(0.7))
    cloud(&c, x: 146 + sin(clock * 0.06) * 12, y: 63, scale: 0.8)
    cloud(&c, x: 328 + sin(clock * 0.04) * 9, y: 142, scale: 0.75)
    cloud(&c, x: 14, y: 171, scale: 0.6)
    let horizon = height - 42
    for index in 0..<13 {
      let x = Double(index) * 34 - 10
      let h = Double([40, 60, 46, 35, 81, 40, 55][index % 7])
      rounded(
        &c, rect: CGRect(x: x, y: horizon - h, width: 28, height: h), radius: 1,
        color: p.ink.opacity(0.085))
      if index % 3 == 0 {
        line(
          &c, from: CGPoint(x: x + 8, y: horizon - h),
          to: CGPoint(x: x + 8, y: horizon - h - 20), color: p.ink.opacity(0.09), width: 3)
      }
    }
    line(
      &c, from: CGPoint(x: 0, y: horizon), to: CGPoint(x: 390, y: horizon),
      color: p.ink.opacity(0.14))
    for index in 0..<16 {
      let x = Double((index * 67) % 390)
      let y = horizon + 8 + Double(index % 4) * 9
      line(
        &c, from: CGPoint(x: x, y: y), to: CGPoint(x: x + 14 + Double(index % 3) * 8, y: y),
        color: p.cream.opacity(0.5))
    }
    for index in 0..<3 {
      let x = Double(index) * 14 + 210
      let y = 123 - Double(index % 2) * 7
      var bird = Path()
      bird.move(to: CGPoint(x: x - 4, y: y))
      bird.addQuadCurve(to: CGPoint(x: x, y: y + 2), control: CGPoint(x: x - 1, y: y - 2))
      bird.addQuadCurve(to: CGPoint(x: x + 4, y: y), control: CGPoint(x: x + 1, y: y - 2))
      c.stroke(bird, with: .color(p.ink.opacity(0.4)), lineWidth: 1)
    }
  }

  static func cloud(_ c: inout GraphicsContext, x: Double, y: Double, scale: Double) {
    var local = c
    local.translateBy(x: x, y: y)
    local.scaleBy(x: scale, y: scale)
    for rect in [
      CGRect(x: -42, y: 0, width: 92, height: 17),
      CGRect(x: -20, y: -18, width: 38, height: 37),
      CGRect(x: 4, y: -9, width: 32, height: 27),
    ] { ellipse(&local, rect, HarborPalette.cream.opacity(0.7)) }
  }

  static func dock(_ c: inout GraphicsContext, y: Double) {
    let p = HarborPalette.self
    rounded(&c, rect: CGRect(x: 0, y: y, width: 134, height: 11), radius: 1, color: p.ink)
    rounded(
      &c, rect: CGRect(x: 0, y: y + 2, width: 134, height: 3), radius: 0, color: p.brass)
    for x in [18.0, 113.0] {
      rounded(
        &c, rect: CGRect(x: x, y: y + 11, width: 9, height: 70), radius: 0,
        color: p.ink.opacity(0.7))
    }
    line(
      &c, from: CGPoint(x: 23, y: y + 37), to: CGPoint(x: 117, y: y + 12),
      color: p.ink.opacity(0.45), width: 4)
  }

  static func crane(
    _ c: inout GraphicsContext, anchor: Double, hookX: Double, hookY: Double, height: Double,
    loaded: Bool
  ) {
    let p = HarborPalette.self
    for x in [18.0, 33.0] {
      line(
        &c, from: CGPoint(x: x, y: 19), to: CGPoint(x: x, y: height), color: p.ink, width: 2)
    }
    for index in 0..<Int(max(1, height / 36)) {
      let y = 24 + Double(index) * 36
      line(
        &c, from: CGPoint(x: 18, y: y), to: CGPoint(x: 33, y: y + 31),
        color: p.ink.opacity(0.6), width: 1)
    }
    rounded(&c, rect: CGRect(x: 11, y: 18, width: 357, height: 12), radius: 2, color: p.ink)
    line(
      &c, from: CGPoint(x: 18, y: 13), to: CGPoint(x: 355, y: 13),
      color: p.brass, width: 2)
    for index in 0..<18 {
      let x = 21 + Double(index) * 19
      line(
        &c, from: CGPoint(x: x, y: 20), to: CGPoint(x: x + 9, y: 28),
        color: p.sky.opacity(0.5))
    }
    rounded(
      &c, rect: CGRect(x: anchor - 16, y: 11, width: 32, height: 25), radius: 5, color: p.orange)
    ellipse(&c, CGRect(x: anchor - 9, y: 19, width: 7, height: 7), p.ink)
    ellipse(&c, CGRect(x: anchor + 2, y: 19, width: 7, height: 7), p.ink)
    line(
      &c, from: CGPoint(x: anchor, y: 35), to: CGPoint(x: hookX, y: hookY),
      color: p.ink, width: 1.4)
    rounded(
      &c, rect: CGRect(x: hookX - 5, y: hookY - 7, width: 10, height: 10), radius: 2,
      color: p.brass)
    var hook = Path()
    hook.move(to: CGPoint(x: hookX, y: hookY + 2))
    hook.addCurve(
      to: CGPoint(x: hookX + 5, y: hookY + 8),
      control1: CGPoint(x: hookX - 6, y: hookY + 17),
      control2: CGPoint(x: hookX + 10, y: hookY + 19))
    c.stroke(hook, with: .color(p.ink), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    if loaded {
      line(
        &c, from: CGPoint(x: hookX, y: hookY + 8),
        to: CGPoint(x: hookX - 26, y: hookY + 25), color: p.ink.opacity(0.7))
      line(
        &c, from: CGPoint(x: hookX, y: hookY + 8),
        to: CGPoint(x: hookX + 26, y: hookY + 25), color: p.ink.opacity(0.7))
    }
  }

  static func airship(_ c: inout GraphicsContext, x: Double, y: Double, clock: Double) {
    let p = HarborPalette.self
    var tail = Path()
    tail.move(to: CGPoint(x: x + 64, y: y + 40))
    tail.addLine(to: CGPoint(x: x + 111, y: y + 17))
    tail.addLine(to: CGPoint(x: x + 100, y: y + 55))
    tail.closeSubpath()
    c.fill(tail, with: .color(p.orange))
    c.stroke(tail, with: .color(p.ink), lineWidth: 1.5)
    let hull = CGRect(x: x - 91, y: y + 7, width: 181, height: 65)
    ellipse(&c, hull, p.brass)
    ellipse(&c, CGRect(x: x - 81, y: y + 9, width: 161, height: 44), p.cream)
    c.stroke(Path(ellipseIn: hull), with: .color(p.ink), lineWidth: 1.5)
    for offset in [-52.0, 0.0, 52.0] {
      var rib = Path()
      rib.move(to: CGPoint(x: x + offset * 0.7, y: y + 10))
      rib.addQuadCurve(
        to: CGPoint(x: x + offset * 0.7, y: y + 69),
        control: CGPoint(x: x + offset * 1.4, y: y + 39))
      c.stroke(rib, with: .color(p.brass), lineWidth: 1)
    }
    line(
      &c, from: CGPoint(x: x - 89, y: y + 40), to: CGPoint(x: x + 89, y: y + 40),
      color: p.ink.opacity(0.4))
    rounded(
      &c, rect: CGRect(x: x - 88, y: y - 1, width: 176, height: 10), radius: 3, color: p.ink)
    rounded(
      &c, rect: CGRect(x: x - 84, y: y, width: 168, height: 3), radius: 1, color: p.orange)
    for offset in [-71.0, 71.0] {
      line(
        &c, from: CGPoint(x: x + offset, y: y + 4),
        to: CGPoint(x: x + offset * 0.65, y: y + 69), color: p.ink, width: 1.2)
    }
    rounded(
      &c, rect: CGRect(x: x - 33, y: y + 61, width: 63, height: 22), radius: 8, color: p.ink)
    for offset in [-18.0, 0, 18] {
      ellipse(&c, CGRect(x: x + offset - 4, y: y + 67, width: 8, height: 8), p.sky)
    }
    line(
      &c, from: CGPoint(x: x + 31, y: y + 72), to: CGPoint(x: x + 53, y: y + 72),
      color: p.ink, width: 3)
    ellipse(
      &c, CGRect(x: x + 49, y: y + 59, width: 5, height: 26),
      p.ink.opacity(0.65 + sin(clock * 14) * 0.15))
  }

  static func balanceGauge(
    _ c: inout GraphicsContext, x: Double, y: Double, balance: Double
  ) {
    rounded(
      &c, rect: CGRect(x: x - 27, y: y, width: 54, height: 15), radius: 7,
      color: HarborPalette.ink)
    line(
      &c, from: CGPoint(x: x - 18, y: y + 7), to: CGPoint(x: x + 18, y: y + 7),
      color: HarborPalette.cream.opacity(0.6))
    ellipse(
      &c, CGRect(x: x - 4 + max(-1, min(1, balance)) * 18, y: y + 3, width: 8, height: 8),
      abs(balance) > 0.65 ? HarborPalette.orange : HarborPalette.cream)
  }

  static func cargo(_ c: inout GraphicsContext, kind: CargoKind, x: Double, y: Double) {
    let p = HarborPalette.self
    var local = c
    local.translateBy(x: x, y: y)
    switch kind {
    case .trunk:
      rounded(
        &local, rect: CGRect(x: -34, y: 5, width: 68, height: 31), radius: 4, color: p.orange)
      outline(&local, CGRect(x: -34, y: 5, width: 68, height: 31), radius: 4)
      for offset in [-22.0, 18] {
        rounded(
          &local, rect: CGRect(x: offset, y: 6, width: 5, height: 29), radius: 1, color: p.brass)
      }
      rounded(&local, rect: CGRect(x: -8, y: 0, width: 16, height: 7), radius: 3, color: p.ink)
      rounded(&local, rect: CGRect(x: -3, y: 15, width: 6, height: 8), radius: 1, color: p.cream)
      line(
        &local, from: CGPoint(x: -32, y: 14), to: CGPoint(x: 32, y: 14),
        color: p.ink.opacity(0.5))
      label(&local, "07", x: 10, y: 28, size: 6)
    case .clock:
      rounded(&local, rect: CGRect(x: -27, y: 28, width: 54, height: 8), radius: 2, color: p.ink)
      rounded(&local, rect: CGRect(x: -22, y: 0, width: 44, height: 34), radius: 15, color: p.brass)
      ellipse(&local, CGRect(x: -15, y: 3, width: 30, height: 29), p.cream)
      for index in 0..<12 {
        let a = Double(index) * .pi / 6
        line(
          &local, from: CGPoint(x: sin(a) * 11, y: 17 + cos(a) * 11),
          to: CGPoint(x: sin(a) * 12.5, y: 17 + cos(a) * 12.5), color: p.ink)
      }
      line(&local, from: CGPoint(x: 0, y: 17), to: CGPoint(x: 0, y: 8), color: p.ink, width: 1.5)
      line(&local, from: CGPoint(x: 0, y: 17), to: CGPoint(x: 7, y: 21), color: p.ink, width: 1.5)
    case .plant:
      rounded(
        &local, rect: CGRect(x: -32, y: 23, width: 64, height: 13), radius: 2, color: p.brass)
      for offset in [-20.0, 0, 20] {
        line(
          &local, from: CGPoint(x: offset, y: 24), to: CGPoint(x: offset, y: 4),
          color: p.ink, width: 1.3)
        ellipse(&local, CGRect(x: offset - 13, y: 3, width: 14, height: 8), p.ink.opacity(0.85))
        ellipse(&local, CGRect(x: offset, y: 9, width: 13, height: 8), p.ink.opacity(0.85))
        ellipse(&local, CGRect(x: offset - 5, y: -3, width: 10, height: 10), p.orange)
      }
      for offset in [-22.0, -7, 8, 23] {
        line(
          &local, from: CGPoint(x: offset, y: 25), to: CGPoint(x: offset, y: 35),
          color: p.cream.opacity(0.5))
      }
    case .piano:
      var lid = Path()
      lid.move(to: CGPoint(x: -41, y: 7))
      lid.addLine(to: CGPoint(x: 28, y: -8))
      lid.addQuadCurve(to: CGPoint(x: 40, y: 8), control: CGPoint(x: 46, y: -4))
      lid.addLine(to: CGPoint(x: -41, y: 10))
      lid.closeSubpath()
      local.fill(lid, with: .color(p.ink))
      line(
        &local, from: CGPoint(x: 20, y: -4), to: CGPoint(x: 20, y: 18), color: p.brass, width: 2)
      rounded(
        &local, rect: CGRect(x: -41, y: 13, width: 82, height: 14), radius: 3, color: p.ink)
      rounded(
        &local, rect: CGRect(x: -37, y: 16, width: 58, height: 8), radius: 1, color: p.cream)
      for index in 0..<13 {
        let keyX = -35 + Double(index) * 4
        line(
          &local, from: CGPoint(x: keyX, y: 17), to: CGPoint(x: keyX, y: 23),
          color: p.ink.opacity(0.5), width: 0.7)
        if index % 3 != 0 {
          rounded(
            &local, rect: CGRect(x: keyX + 1, y: 16, width: 2, height: 4), radius: 0, color: p.ink)
        }
      }
      for offset in [-33.0, 30] {
        line(
          &local, from: CGPoint(x: offset, y: 25), to: CGPoint(x: offset - 2, y: 34),
          color: p.ink, width: 3)
        ellipse(&local, CGRect(x: offset - 5, y: 32, width: 6, height: 4), p.brass)
      }
    case .telescope:
      for offset in [-24.0, 24] {
        line(
          &local, from: CGPoint(x: 0, y: 14), to: CGPoint(x: offset, y: 35),
          color: p.ink, width: 2)
      }
      local.rotate(by: .degrees(-12))
      rounded(
        &local, rect: CGRect(x: -33, y: 2, width: 58, height: 13), radius: 3, color: p.brass)
      rounded(
        &local, rect: CGRect(x: 18, y: -1, width: 12, height: 19), radius: 2, color: p.ink)
      rounded(&local, rect: CGRect(x: 26, y: 2, width: 4, height: 13), radius: 1, color: p.sky)
      rounded(
        &local, rect: CGRect(x: -33, y: 4, width: 8, height: 9), radius: 1, color: p.ink)
    }
  }

  static func rounded(
    _ c: inout GraphicsContext, rect: CGRect, radius: Double, color: Color
  ) {
    c.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
  }

  static func outline(_ c: inout GraphicsContext, _ rect: CGRect, radius: Double) {
    c.stroke(
      Path(roundedRect: rect, cornerRadius: radius), with: .color(HarborPalette.ink), lineWidth: 1)
  }

  static func ellipse(_ c: inout GraphicsContext, _ rect: CGRect, _ color: Color) {
    c.fill(Path(ellipseIn: rect), with: .color(color))
  }

  static func line(
    _ c: inout GraphicsContext, from: CGPoint, to: CGPoint, color: Color, width: Double = 1
  ) {
    var path = Path()
    path.move(to: from)
    path.addLine(to: to)
    c.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
  }

  static func label(
    _ c: inout GraphicsContext, _ text: String, x: Double, y: Double, size: Double
  ) {
    c.draw(
      Text(text).font(.system(size: size, weight: .bold, design: .monospaced))
        .foregroundStyle(HarborPalette.ink), at: CGPoint(x: x, y: y))
  }
}
