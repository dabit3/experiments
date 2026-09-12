import SwiftUI

enum Ink {
  static let navy = Color(red: 0.08, green: 0.20, blue: 0.25)
  static let cream = Color(red: 0.98, green: 0.96, blue: 0.88)
  static let sea = Color(red: 0.47, green: 0.73, blue: 0.67)
  static let lightSea = Color(red: 0.63, green: 0.82, blue: 0.72)
  static let red = Color(red: 0.88, green: 0.24, blue: 0.14)
  static let butter = Color(red: 0.98, green: 0.84, blue: 0.38)
  static let road = Color(red: 0.82, green: 0.84, blue: 0.75)
  static let land = Color(red: 0.85, green: 0.87, blue: 0.69)
}

struct CoastArtwork: View {
  var race: RaceState
  var hero = false
  var reducedMotion = false

  var body: some View {
    Canvas { context, size in
      let w = size.width
      let h = size.height
      let playerY = h * (hero ? 0.65 : 0.68)
      let scale = hero ? 4.5 : 5.0
      let travelled = hero ? 35.0 : race.distance
      func world(_ y: Double) -> Double { travelled + (playerY - y) / scale }
      func center(_ y: Double) -> Double {
        w * (hero ? 0.59 : 0.54)
          + sin(world(y) / 65) * w * 0.065 * race.course.curveAmount
      }
      func roadWidth(_ y: Double) -> Double { w * (0.48 + 0.12 * y / h) }
      func laneX(_ lane: Int, _ y: Double) -> Double {
        center(y) + Double(lane - 1) * roadWidth(y) * 0.29
      }
      func band(_ left: Double, _ right: Double) -> Path {
        var p = Path()
        for step in 0...60 {
          let y = h * Double(step) / 60
          let pt = CGPoint(x: center(y) + roadWidth(y) * left, y: y)
          if step == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        for step in (0...60).reversed() {
          let y = h * Double(step) / 60
          p.addLine(to: CGPoint(x: center(y) + roadWidth(y) * right, y: y))
        }
        p.closeSubpath()
        return p
      }
      context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Ink.sea))
      var land = band(-0.69, 3)
      context.fill(land, with: .color(Ink.lightSea))
      land = band(-0.62, 3)
      context.fill(land, with: .color(Ink.cream))
      context.fill(band(-0.57, 3), with: .color(Ink.land))
      context.fill(band(-0.5, 0.5), with: .color(Ink.road))
      context.fill(band(-0.492, -0.477), with: .color(Ink.cream))
      context.fill(band(0.477, 0.492), with: .color(Ink.cream))

      let first = Int(world(h) / 14) - 1
      let last = Int(world(0) / 14) + 1
      if first <= last {
        for marker in first...last {
          let y = playerY - (Double(marker) * 14 - travelled) * scale
          for fraction in [-0.155, 0.155] {
            var line = Path()
            line.move(to: CGPoint(x: center(y) + roadWidth(y) * fraction, y: y))
            line.addLine(to: CGPoint(x: center(y + 19) + roadWidth(y + 19) * fraction, y: y + 19))
            context.stroke(
              line, with: .color(Ink.butter), style: StrokeStyle(lineWidth: 3, lineCap: .round))
          }
          let sceneryY = y + 25
          let shoreX = center(sceneryY) - roadWidth(sceneryY) * 0.84
          if marker.isMultiple(of: 4) {
            boat(&context, at: CGPoint(x: max(12, shoreX - 20), y: sceneryY), angle: -0.2)
          }
          let right = center(sceneryY) + roadWidth(sceneryY) * 0.67
          if marker.isMultiple(of: 3) {
            house(&context, at: CGPoint(x: right + 8, y: sceneryY))
          } else {
            tree(&context, at: CGPoint(x: right + Double(abs(marker) % 2) * 21, y: sceneryY))
          }
          var ripple = Path()
          ripple.move(to: CGPoint(x: shoreX - 45, y: y + 30))
          ripple.addQuadCurve(
            to: CGPoint(x: shoreX - 4, y: y + 26), control: CGPoint(x: shoreX - 20, y: y + 34))
          context.stroke(ripple, with: .color(Ink.cream.opacity(0.3)), lineWidth: 1.5)
        }
      }
      if !hero {
        let finishY = playerY - (race.course.length - travelled) * scale
        if finishY > -80 && finishY < h + 80 {
          let width = roadWidth(finishY)
          for row in 0..<3 {
            for col in 0..<12 {
              let rect = CGRect(
                x: center(finishY) - width * 0.47 + Double(col) * width * 0.94 / 12,
                y: finishY + Double(row) * 10, width: width * 0.94 / 12 + 0.5, height: 10
              )
              context.fill(
                Path(rect), with: .color((row + col).isMultiple(of: 2) ? Ink.navy : Ink.cream))
            }
          }
          context.draw(
            Text("FINISH").font(.system(size: 15, weight: .black, design: .rounded))
              .foregroundColor(Ink.navy),
            at: CGPoint(x: center(finishY), y: finishY - 18)
          )
        }
        for obstacle in race.course.obstacles {
          let y = playerY - (obstacle.distance - travelled) * scale
          if y > -40 && y < h + 40 {
            let x = laneX(obstacle.lane, y)
            context.fill(
              Path(ellipseIn: CGRect(x: x - 20, y: y - 13, width: 40, height: 26)),
              with: .color(Ink.navy.opacity(0.12)))
            context.fill(
              Path(
                roundedRect: CGRect(x: x - 22, y: y - 7, width: 44, height: 13), cornerRadius: 4),
              with: .color(Ink.red))
            for offset in [-13.0, 0, 13] {
              context.fill(
                Path(CGRect(x: x + offset - 3, y: y - 7, width: 6, height: 13)),
                with: .color(Ink.cream))
            }
            context.draw(
              Text("!").font(.system(size: 13, weight: .black)).foregroundColor(Ink.red),
              at: CGPoint(x: x, y: y - 26))
          }
        }
      }
      let riders =
        hero
        ? [
          Rival(id: 0, distance: travelled + 29, lane: 1, pace: 0),
          Rival(id: 1, distance: travelled + 50, lane: 0, pace: 0),
          Rival(id: 2, distance: travelled + 61, lane: 2, pace: 0),
        ]
        : race.rivals
      for rival in riders {
        let y = playerY - (rival.distance - travelled) * scale
        if y > -80 && y < h + 80 {
          let x = laneX(rival.lane, y)
          var slip = Path()
          slip.move(to: CGPoint(x: x - 8, y: y + 22))
          slip.addLine(to: CGPoint(x: x - 25, y: y + 110))
          slip.addQuadCurve(to: CGPoint(x: x + 25, y: y + 110), control: CGPoint(x: x, y: y + 120))
          slip.addLine(to: CGPoint(x: x + 8, y: y + 22))
          slip.closeSubpath()
          context.fill(
            slip,
            with: .linearGradient(
              Gradient(colors: [Ink.cream.opacity(0.50), Ink.cream.opacity(0.04)]),
              startPoint: CGPoint(x: x, y: y + 22), endPoint: CGPoint(x: x, y: y + 120)
            ))
          rider(
            &context, at: CGPoint(x: x, y: y),
            jersey: [Ink.navy, Ink.butter, Color.white][rival.id], phase: travelled, player: false)
        }
      }
      let x = laneX(hero ? 1 : race.lane, playerY)
      if !hero && (race.isSprinting || race.attackRemaining > 0) && !reducedMotion {
        for i in 0..<8 {
          let side = i.isMultiple(of: 2) ? -1.0 : 1.0
          let offset = Double(i / 2) * 11
          let yy =
            playerY + 25 + (travelled * 12 + Double(i) * 13).truncatingRemainder(dividingBy: 75)
          var streak = Path()
          streak.move(to: CGPoint(x: x + side * (18 + offset), y: yy))
          streak.addLine(to: CGPoint(x: x + side * (19 + offset), y: yy + 24))
          context.stroke(
            streak, with: .color(Ink.cream.opacity(0.75)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
      }
      rider(
        &context, at: CGPoint(x: x, y: playerY), jersey: Ink.red, phase: travelled, player: true)
      if !hero {
        context.draw(
          Text("YOU").font(.system(size: 9, weight: .black, design: .rounded)).foregroundColor(
            Ink.navy),
          at: CGPoint(x: x, y: playerY + 48)
        )
      }
    }
    .accessibilityLabel(
      hero
        ? "Illustrated coastal cycling road"
        : "Coastal road. You are in lane \(race.lane + 1) of 3."
    )
    .accessibilityIdentifier("coastalPlayfield")
  }

  private func rider(
    _ ctx: inout GraphicsContext, at p: CGPoint, jersey: Color, phase: Double, player: Bool
  ) {
    var c = ctx
    c.translateBy(x: p.x, y: p.y)
    c.fill(
      Path(ellipseIn: CGRect(x: -9, y: -23, width: 25, height: 61)),
      with: .color(Ink.navy.opacity(0.14)))
    for y in [-24.0, 20] {
      c.fill(
        Path(roundedRect: CGRect(x: -3, y: y - 9, width: 6, height: 20), cornerRadius: 3),
        with: .color(Ink.navy))
      c.fill(Path(CGRect(x: -0.6, y: y - 7, width: 1.2, height: 16)), with: .color(Ink.cream))
    }
    var frame = Path()
    frame.move(to: CGPoint(x: 0, y: -17))
    frame.addLine(to: CGPoint(x: 0, y: 20))
    frame.move(to: CGPoint(x: -12, y: -15))
    frame.addQuadCurve(to: CGPoint(x: 12, y: -15), control: CGPoint(x: 0, y: -21))
    c.stroke(
      frame, with: .color(player ? Ink.red : Ink.navy),
      style: StrokeStyle(lineWidth: 3, lineCap: .round))
    let pedal = reducedMotion ? 0 : sin(phase * 1.8) * 4
    for side in [-1.0, 1] {
      let leg = CGRect(x: side < 0 ? -9 : 3, y: 10 + pedal * side, width: 6, height: 12)
      c.fill(Path(roundedRect: leg, cornerRadius: 3), with: .color(Ink.navy))
      let arm = CGRect(x: side < 0 ? -14 : 8, y: -14, width: 6, height: 13)
      c.fill(Path(roundedRect: arm, cornerRadius: 3), with: .color(Ink.cream))
    }
    c.fill(
      Path(roundedRect: CGRect(x: -10, y: -12, width: 20, height: 27), cornerRadius: 8),
      with: .color(jersey))
    c.fill(
      Path(CGRect(x: -10, y: 3, width: 20, height: 4)), with: .color(player ? Ink.butter : Ink.sea))
    c.fill(Path(ellipseIn: CGRect(x: -7, y: -23, width: 14, height: 17)), with: .color(Ink.cream))
    for xx in [-3.0, 1] {
      c.fill(
        Path(roundedRect: CGRect(x: xx, y: -21, width: 2, height: 11), cornerRadius: 1),
        with: .color(jersey))
    }
  }

  private func tree(_ ctx: inout GraphicsContext, at p: CGPoint) {
    ctx.fill(
      Path(ellipseIn: CGRect(x: p.x - 5, y: p.y - 8, width: 32, height: 37)),
      with: .color(Ink.navy.opacity(0.10)))
    ctx.stroke(
      Path {
        $0.move(to: p)
        $0.addLine(to: CGPoint(x: p.x + 3, y: p.y + 24))
      }, with: .color(Ink.navy), lineWidth: 3)
    for i in 0..<5 {
      var leaf = Path()
      let a = Double(i) / 5 * .pi * 2
      let end = CGPoint(x: p.x + cos(a) * 23, y: p.y + sin(a) * 21)
      leaf.move(to: p)
      leaf.addQuadCurve(
        to: end, control: CGPoint(x: p.x + cos(a + 0.7) * 25, y: p.y + sin(a + 0.7) * 23))
      leaf.addQuadCurve(to: p, control: CGPoint(x: p.x + cos(a) * 11, y: p.y + sin(a) * 11))
      ctx.fill(leaf, with: .color(i.isMultiple(of: 2) ? Ink.sea : Ink.navy.opacity(0.7)))
    }
  }

  private func house(_ ctx: inout GraphicsContext, at p: CGPoint) {
    ctx.fill(
      Path(roundedRect: CGRect(x: p.x - 13, y: p.y - 17, width: 36, height: 46), cornerRadius: 3),
      with: .color(Ink.navy.opacity(0.12)))
    ctx.fill(Path(CGRect(x: p.x - 20, y: p.y - 25, width: 34, height: 44)), with: .color(Ink.cream))
    ctx.fill(
      Path(CGRect(x: p.x - 23, y: p.y - 21, width: 40, height: 28)),
      with: .color(Ink.red.opacity(0.8)))
    ctx.stroke(
      Path {
        $0.move(to: CGPoint(x: p.x - 23, y: p.y - 7))
        $0.addLine(to: CGPoint(x: p.x + 17, y: p.y - 7))
      }, with: .color(Ink.cream.opacity(0.5)), lineWidth: 1)
    ctx.fill(Path(CGRect(x: p.x - 7, y: p.y + 10, width: 8, height: 9)), with: .color(Ink.navy))
  }

  private func boat(_ ctx: inout GraphicsContext, at p: CGPoint, angle: Double) {
    var c = ctx
    c.translateBy(x: p.x, y: p.y)
    c.rotate(by: .radians(angle))
    c.fill(Path(ellipseIn: CGRect(x: -6, y: -16, width: 12, height: 35)), with: .color(Ink.cream))
    var sail = Path()
    sail.move(to: CGPoint(x: 0, y: -22))
    sail.addLine(to: CGPoint(x: 0, y: 10))
    sail.addLine(to: CGPoint(x: 20, y: 10))
    sail.closeSubpath()
    c.fill(sail, with: .color(Ink.butter))
    c.stroke(
      Path {
        $0.move(to: CGPoint(x: 0, y: -23))
        $0.addLine(to: CGPoint(x: 0, y: 13))
      }, with: .color(Ink.navy), lineWidth: 1)
  }
}
