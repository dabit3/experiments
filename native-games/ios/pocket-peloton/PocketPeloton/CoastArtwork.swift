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
        let depth = Double((fleck * 173) % 1009) / 1009
        let fraction = Double((fleck * 71) % 997) / 997 - 0.5
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
            jersey: [Ink.sea, Ink.butter, Color.white][rival.id], phase: travelled, player: false)
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
        &context, at: CGPoint(x: x, y: playerY), jersey: Ink.red, phase: travelled, player: true)
      if !hero {
        context.fill(
          Path(
            roundedRect: CGRect(x: x - 16, y: playerY + 32, width: 32, height: 16), cornerRadius: 8),
          with: .color(Ink.cream))
        context.draw(
          Text("YOU").font(.system(size: 9, weight: .black, design: .rounded)).foregroundColor(
            Ink.navy),
          at: CGPoint(x: x, y: playerY + 40)
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
    c.scaleBy(x: 0.78, y: 0.78)
    if player {
      c.fill(
        Path(ellipseIn: CGRect(x: -19, y: -38, width: 38, height: 76)),
        with: .color(Ink.cream.opacity(0.72)))
    }
    c.fill(
      Path(ellipseIn: CGRect(x: -9, y: -23, width: 25, height: 61)),
      with: .color(.black.opacity(0.28)))
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
    var c = ctx
    c.translateBy(x: p.x, y: p.y)
    c.fill(
      Path(ellipseIn: CGRect(x: -8, y: -4, width: 46, height: 55)),
      with: .color(Ink.navy.opacity(0.13)))
    var trunk = Path()
    trunk.move(to: CGPoint(x: 3, y: 22))
    trunk.addLine(to: CGPoint(x: 0, y: -5))
    trunk.move(to: CGPoint(x: 1, y: 11))
    trunk.addLine(to: CGPoint(x: -11, y: -3))
    trunk.move(to: CGPoint(x: 1, y: 6))
    trunk.addLine(to: CGPoint(x: 14, y: -7))
    c.stroke(
      trunk, with: .color(Ink.navy.opacity(0.65)),
      style: StrokeStyle(lineWidth: 3, lineCap: .round))
    for i in 0..<7 {
      let a = Double(i) / 7 * .pi * 2
      let x = cos(a) * 13
      let y = sin(a) * 10 - 11
      c.fill(
        Path(ellipseIn: CGRect(x: x - 12, y: y - 8, width: 25, height: 19)),
        with: .color(Ink.navy.opacity(0.7)))
      c.fill(
        Path(ellipseIn: CGRect(x: x - 12, y: y - 11, width: 23, height: 17)),
        with: .color(
          i.isMultiple(of: 2)
            ? Color(red: 0.40, green: 0.51, blue: 0.34) : Color(red: 0.49, green: 0.59, blue: 0.40))
      )
      c.fill(
        Path(ellipseIn: CGRect(x: x - 8, y: y - 9, width: 8, height: 3)),
        with: .color(Ink.butter.opacity(0.13)))
    }
  }

  private func rock(_ ctx: inout GraphicsContext, at p: CGPoint, variant: Int) {
    var c = ctx
    c.translateBy(x: p.x, y: p.y)
    c.rotate(by: .degrees(Double(variant * 31)))
    let scale = 0.7 + Double(variant) * 0.2
    c.scaleBy(x: scale, y: scale)
    c.fill(
      Path(ellipseIn: CGRect(x: -18, y: -21, width: 33, height: 49)),
      with: .color(Ink.cream.opacity(0.45)))
    var stone = Path()
    stone.move(to: CGPoint(x: -12, y: -14))
    stone.addLine(to: CGPoint(x: 5, y: -19))
    stone.addLine(to: CGPoint(x: 14, y: -2))
    stone.addLine(to: CGPoint(x: 9, y: 18))
    stone.addLine(to: CGPoint(x: -10, y: 21))
    stone.addLine(to: CGPoint(x: -17, y: 5))
    stone.closeSubpath()
    c.fill(stone, with: .color(Ink.stone))
    var face = Path()
    face.move(to: CGPoint(x: -12, y: -14))
    face.addLine(to: CGPoint(x: 5, y: -19))
    face.addLine(to: CGPoint(x: 7, y: 1))
    face.addLine(to: CGPoint(x: -10, y: 9))
    face.addLine(to: CGPoint(x: -17, y: 5))
    face.closeSubpath()
    c.fill(face, with: .color(Ink.cream))
  }

  private func house(_ ctx: inout GraphicsContext, at p: CGPoint) {
    var c = ctx
    c.translateBy(x: p.x, y: p.y)
    c.fill(
      Path(roundedRect: CGRect(x: -23, y: -26, width: 54, height: 70), cornerRadius: 4),
      with: .color(Ink.cream.opacity(0.4)))
    c.fill(
      Path(CGRect(x: -10, y: -7, width: 45, height: 49)),
      with: .color(Ink.navy.opacity(0.17)))
    c.fill(Path(CGRect(x: -20, y: -25, width: 38, height: 51)), with: .color(Ink.stone))
    c.fill(Path(CGRect(x: -20, y: -25, width: 33, height: 45)), with: .color(Ink.cream))
    c.fill(
      Path(CGRect(x: -24, y: -27, width: 44, height: 34)),
      with: .color(Ink.red.opacity(0.75)))
    c.fill(
      Path(CGRect(x: -24, y: -27, width: 22, height: 34)),
      with: .color(Ink.butter.opacity(0.22)))
    for row in 0..<7 {
      var tile = Path()
      let y = -24.0 + Double(row) * 4.5
      tile.move(to: CGPoint(x: -24, y: y))
      tile.addLine(to: CGPoint(x: 20, y: y))
      c.stroke(tile, with: .color(Ink.cream.opacity(0.25)), lineWidth: 0.7)
    }
    for column in 0..<9 {
      var tile = Path()
      let x = -22.0 + Double(column) * 5
      tile.move(to: CGPoint(x: x, y: -27))
      tile.addLine(to: CGPoint(x: x, y: 7))
      c.stroke(tile, with: .color(Ink.navy.opacity(0.13)), lineWidth: 0.7)
    }
    c.fill(Path(CGRect(x: -3, y: -29, width: 2, height: 38)), with: .color(Ink.cream.opacity(0.4)))
    c.fill(Path(CGRect(x: -16, y: -32, width: 6, height: 9)), with: .color(Ink.cream))
    for x in [-13.0, 5] {
      c.fill(Path(CGRect(x: x, y: 11, width: 5, height: 7)), with: .color(Ink.navy))
      c.fill(Path(CGRect(x: x - 2, y: 11, width: 2, height: 7)), with: .color(Ink.sea))
    }
    c.fill(
      Path(roundedRect: CGRect(x: -4, y: 12, width: 7, height: 11), cornerRadius: 3),
      with: .color(Ink.navy.opacity(0.7)))
  }

  private func boat(_ ctx: inout GraphicsContext, at p: CGPoint, angle: Double) {
    var c = ctx
    c.translateBy(x: p.x, y: p.y)
    c.rotate(by: .radians(angle))
    c.fill(
      Path(ellipseIn: CGRect(x: -1, y: -12, width: 19, height: 40)),
      with: .color(Ink.navy.opacity(0.15)))
    var wake = Path()
    wake.move(to: CGPoint(x: -7, y: 5))
    wake.addQuadCurve(to: CGPoint(x: -13, y: 43), control: CGPoint(x: -8, y: 30))
    wake.move(to: CGPoint(x: 7, y: 5))
    wake.addQuadCurve(to: CGPoint(x: 13, y: 43), control: CGPoint(x: 8, y: 30))
    c.stroke(wake, with: .color(Ink.cream.opacity(0.3)), lineWidth: 1)
    c.fill(Path(ellipseIn: CGRect(x: -6, y: -16, width: 12, height: 35)), with: .color(Ink.cream))
    c.fill(Path(ellipseIn: CGRect(x: -3, y: -9, width: 6, height: 20)), with: .color(Ink.stone))
    var sail = Path()
    sail.move(to: CGPoint(x: 0, y: -24))
    sail.addQuadCurve(to: CGPoint(x: 20, y: 9), control: CGPoint(x: 14, y: -13))
    sail.addLine(to: CGPoint(x: 0, y: 12))
    sail.closeSubpath()
    c.fill(sail, with: .color(Ink.cream))
    var jib = Path()
    jib.move(to: CGPoint(x: -2, y: -18))
    jib.addLine(to: CGPoint(x: -2, y: 7))
    jib.addLine(to: CGPoint(x: -13, y: 7))
    jib.closeSubpath()
    c.fill(jib, with: .color(Ink.butter))
    c.stroke(
      Path {
        $0.move(to: CGPoint(x: 0, y: -23))
        $0.addLine(to: CGPoint(x: 0, y: 13))
      }, with: .color(Ink.navy), lineWidth: 1)
  }
}
