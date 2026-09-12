import SwiftUI

enum Ink {
  static let navy = Color(red: 0.08, green: 0.17, blue: 0.19)
  static let cream = Color(red: 0.98, green: 0.95, blue: 0.87)
  static let sea = Color(red: 0.25, green: 0.62, blue: 0.59)
  static let lightSea = Color(red: 0.57, green: 0.79, blue: 0.69)
  static let red = Color(red: 0.83, green: 0.23, blue: 0.13)
  static let butter = Color(red: 0.97, green: 0.80, blue: 0.41)
  static let road = Color(red: 0.25, green: 0.32, blue: 0.33)
  static let land = Color(red: 0.74, green: 0.77, blue: 0.59)
  static let stone = Color(red: 0.87, green: 0.81, blue: 0.65)
}

struct CoastArtwork: View {
  var race: RaceState
  var hero = false
  var reducedMotion = false
  var riderLane: Double = 1

  var body: some View {
    Canvas { context, size in
      let w = size.width
      let h = size.height
      let playerY = h * (hero ? 0.61 : 0.59)
      let scale = hero ? 4.5 : 5.0
      let travelled = hero ? 35.0 : race.distance
      func world(_ y: Double) -> Double { travelled + (playerY - y) / scale }
      func center(_ y: Double) -> Double {
        w * (hero ? 0.59 : 0.54)
          + sin(world(y) / 65) * w * 0.085 * race.course.curveAmount
      }
      func roadWidth(_ y: Double) -> Double { w * (0.40 + 0.24 * y / h) }
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
      context.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .linearGradient(
          Gradient(colors: [Ink.sea, Ink.lightSea]),
          startPoint: .zero, endPoint: CGPoint(x: w, y: h)))
      context.fill(band(-0.88, 3), with: .color(Ink.lightSea.opacity(0.42)))
      context.fill(band(-0.76, 3), with: .color(Ink.lightSea))
      context.fill(band(-0.70, 3), with: .color(Ink.cream.opacity(0.8)))
      context.fill(band(-0.66, 3), with: .color(Ink.stone))
      context.fill(band(-0.59, 3), with: .color(Ink.land))
      context.fill(band(-0.57, 0.57), with: .color(Ink.cream))
      context.fill(band(-0.52, 0.54), with: .color(Ink.navy.opacity(0.28)))
      context.fill(band(-0.5, 0.5), with: .color(Ink.road))
      context.fill(band(-0.475, -0.468), with: .color(Ink.cream.opacity(0.8)))
      context.fill(band(0.468, 0.475), with: .color(Ink.cream.opacity(0.8)))
      for fleck in 0..<450 {
        let seed = (fleck * 73_856_093) ^ 19_349_663
        let depth = Double(seed % 1009) / 1009
        let fraction = Double((seed / 1009) % 997) / 997 - 0.5
        let y = (depth * h + travelled * scale).truncatingRemainder(dividingBy: h)
        let x = center(y) + fraction * roadWidth(y) * 0.9
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1.5)),
          with: .color(Ink.cream.opacity(0.07)))
      }

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
              line, with: .color(Ink.butter.opacity(0.8)),
              style: StrokeStyle(lineWidth: 2, lineCap: .round))
          }
          let sceneryY = y + 25
          let shoreX = center(sceneryY) - roadWidth(sceneryY) * 0.84
          if marker.isMultiple(of: 7) {
            boat(&context, at: CGPoint(x: max(12, shoreX - 26), y: sceneryY), angle: -0.3)
          }
          rock(
            &context, at: CGPoint(x: center(y) - roadWidth(y) * 0.68, y: y + 42),
            variant: abs(marker) % 3)
          for side in [-0.535, 0.535] {
            let x = center(y) + roadWidth(y) * side
            context.fill(
              Path(CGRect(x: x - 2, y: y - 5, width: 7, height: 14)),
              with: .color(Ink.navy.opacity(0.12)))
            context.fill(
              Path(roundedRect: CGRect(x: x - 2, y: y - 8, width: 4, height: 9), cornerRadius: 1),
              with: .color(Ink.cream))
          }
          let right = center(sceneryY) + roadWidth(sceneryY) * 0.67
          if marker.isMultiple(of: 4) {
            house(&context, at: CGPoint(x: right + 8, y: sceneryY))
            tree(&context, at: CGPoint(x: right + 47, y: sceneryY + 24))
          } else {
            tree(&context, at: CGPoint(x: right + Double(abs(marker) % 2) * 21, y: sceneryY))
          }
          var ripple = Path()
          ripple.move(to: CGPoint(x: shoreX - 45, y: y + 30))
          ripple.addQuadCurve(
            to: CGPoint(x: shoreX - 4, y: y + 26), control: CGPoint(x: shoreX - 20, y: y + 34))
          context.stroke(ripple, with: .color(Ink.cream.opacity(0.35)), lineWidth: 1)
        }
      }
      if !hero {
        for remaining in stride(from: 100, through: Int(race.course.length), by: 100) {
          let y = playerY - (race.course.length - Double(remaining) - travelled) * scale
          if y > -40 && y < h + 40 {
            context.draw(
              Text("\(remaining) M")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .tracking(4).foregroundColor(Ink.cream.opacity(0.2)),
              at: CGPoint(x: center(y), y: y))
          }
        }
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
              .foregroundColor(Ink.cream),
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
          let crowded = riders.contains {
            $0.id != rival.id && $0.lane == rival.lane && abs($0.distance - rival.distance) < 12
          }
          let nearPlayer =
            !hero && rival.lane == race.lane
            && abs(rival.distance - travelled) < 14
          let offset = nearPlayer ? 24.0 : (crowded ? 18.0 : 0)
          let x = laneX(rival.lane, y) + (rival.id.isMultiple(of: 2) ? -offset : offset)
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
            asset: ["RiderTeal", "RiderYellow", "RiderIvory"][rival.id], phase: travelled,
            player: false)
        }
      }
      let visualLane = hero ? 1 : (reducedMotion ? Double(race.lane) : riderLane)
      let x = center(playerY) + (visualLane - 1) * roadWidth(playerY) * 0.29
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
        &context, at: CGPoint(x: x, y: playerY), asset: "RiderRed", phase: travelled, player: true)
      if !hero {
        context.fill(
          Path(
            roundedRect: CGRect(x: x - 16, y: playerY + 49, width: 32, height: 16), cornerRadius: 8),
          with: .color(Ink.cream))
        context.draw(
          Text("YOU").font(.system(size: 9, weight: .black, design: .rounded)).foregroundColor(
            Ink.navy),
          at: CGPoint(x: x, y: playerY + 57)
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
    _ ctx: inout GraphicsContext, at p: CGPoint, asset: String, phase: Double, player: Bool
  ) {
    var c = ctx
    c.translateBy(x: p.x, y: p.y)
    if player {
      c.stroke(
        Path(ellipseIn: CGRect(x: -19, y: -46, width: 38, height: 92)),
        with: .color(Ink.butter.opacity(0.6)), lineWidth: 1)
    }
    if !reducedMotion { c.rotate(by: .degrees(sin(phase * 1.8) * 1.4)) }
    c.addFilter(.shadow(color: .black.opacity(0.32), radius: 1.2, x: 5, y: 7))
    c.draw(Image(asset), in: CGRect(x: -13, y: -44, width: 26, height: 88))
  }

  private func tree(_ ctx: inout GraphicsContext, at p: CGPoint) {
    scenery(&ctx, asset: "ScenicPine", at: p, size: CGSize(width: 80, height: 78))
  }

  private func rock(_ ctx: inout GraphicsContext, at p: CGPoint, variant: Int) {
    var c = ctx
    c.translateBy(x: p.x, y: p.y)
    c.rotate(by: .degrees(Double(variant * 31)))
    let scale = 0.7 + Double(variant) * 0.2
    c.scaleBy(x: scale, y: scale)
    scenery(&c, asset: "ScenicRocks", at: .zero, size: CGSize(width: 40, height: 40))
  }

  private func house(_ ctx: inout GraphicsContext, at p: CGPoint) {
    scenery(&ctx, asset: "ScenicVilla", at: p, size: CGSize(width: 70, height: 80))
  }

  private func boat(_ ctx: inout GraphicsContext, at p: CGPoint, angle: Double) {
    var c = ctx
    c.translateBy(x: p.x, y: p.y)
    c.rotate(by: .radians(angle))
    var wake = Path()
    wake.move(to: CGPoint(x: -7, y: 5))
    wake.addQuadCurve(to: CGPoint(x: -13, y: 43), control: CGPoint(x: -8, y: 30))
    wake.move(to: CGPoint(x: 7, y: 5))
    wake.addQuadCurve(to: CGPoint(x: 13, y: 43), control: CGPoint(x: 8, y: 30))
    c.stroke(wake, with: .color(Ink.cream.opacity(0.3)), lineWidth: 1)
    scenery(&c, asset: "ScenicBoat", at: .zero, size: CGSize(width: 31, height: 57))
  }

  private func scenery(
    _ context: inout GraphicsContext, asset: String, at point: CGPoint, size: CGSize
  ) {
    var shadowed = context
    shadowed.addFilter(.shadow(color: Ink.navy.opacity(0.23), radius: 2, x: 8, y: 12))
    shadowed.draw(
      Image(asset),
      in: CGRect(
        x: point.x - size.width / 2, y: point.y - size.height / 2,
        width: size.width, height: size.height))
  }
}
