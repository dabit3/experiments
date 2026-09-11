import SwiftUI

struct SunDial: View {
  let day: SunDay
  let place: Place
  let date: Date
  let onScrub: (Double) -> Void

  private func point(_ position: SunPosition, size: CGSize) -> CGPoint {
    let radius = min(size.width, size.height) * 0.39
    let distance = radius * (1 - position.altitude / 90)
    let angle = (position.azimuth - 90) * .pi / 180
    return CGPoint(
      x: size.width / 2 + cos(angle) * distance, y: size.height / 2 + sin(angle) * distance)
  }

  var body: some View {
    GeometryReader { geometry in
      Canvas { context, size in
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * 0.39
        let outer = radius * 1.14
        let circle = CGRect(
          x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(
          Path(ellipseIn: circle),
          with: .radialGradient(
            Gradient(colors: [
              Palette.copper.opacity(0.20), Color(red: 0.17, green: 0.17, blue: 0.25).opacity(0.4),
            ]),
            center: CGPoint(x: center.x, y: center.y + radius * 0.65), startRadius: 0,
            endRadius: radius * 1.7))
        for ratio in [0.33, 0.66, 1.0] {
          let r = radius * ratio
          context.stroke(
            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
            with: .color(Palette.cream.opacity(ratio == 1 ? 0.4 : 0.1)), lineWidth: 0.7)
        }
        for degree in stride(from: 0, to: 360, by: 5) {
          let angle = (Double(degree) - 90) * .pi / 180
          let long = degree % 30 == 0
          var tick = Path()
          tick.move(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
          tick.addLine(
            to: CGPoint(
              x: center.x + cos(angle) * (outer - (long ? 8 : 3)),
              y: center.y + sin(angle) * (outer - (long ? 8 : 3))))
          context.stroke(
            tick, with: .color(Palette.cream.opacity(long ? 0.55 : 0.2)), lineWidth: 0.8)
        }
        for (index, label) in ["N", "E", "S", "W"].enumerated() {
          let angle = (Double(index * 90) - 90) * .pi / 180
          context.draw(
            Text(label).font(.system(size: 10, weight: .medium, design: .monospaced))
              .foregroundColor(Palette.cream),
            at: CGPoint(
              x: center.x + cos(angle) * (outer + 12), y: center.y + sin(angle) * (outer + 12)))
        }
        var cross = Path()
        cross.move(to: CGPoint(x: center.x - 5, y: center.y))
        cross.addLine(to: CGPoint(x: center.x + 5, y: center.y))
        cross.move(to: CGPoint(x: center.x, y: center.y - 5))
        cross.addLine(to: CGPoint(x: center.x, y: center.y + 5))
        context.stroke(cross, with: .color(Palette.cream.opacity(0.25)), lineWidth: 0.7)
        context.draw(
          Text("ZENITH").font(.system(size: 8, design: .monospaced)).foregroundColor(
            Palette.muted.opacity(0.7)), at: CGPoint(x: center.x, y: center.y + 16))

        let clipRadius = radius * 1.04
        context.clip(
          to: Path(
            ellipseIn: CGRect(
              x: center.x - clipRadius, y: center.y - clipRadius, width: clipRadius * 2,
              height: clipRadius * 2)))
        for index in 1..<day.samples.count {
          let a = day.samples[index - 1]
          let b = day.samples[index]
          var segment = Path()
          segment.move(to: point(a.position, size: size))
          segment.addLine(to: point(b.position, size: size))
          let golden = (-4...6).contains(b.position.altitude)
          context.stroke(
            segment,
            with: .color(
              golden ? Palette.cream : Palette.copper.opacity(b.position.altitude >= 0 ? 0.8 : 0.2)),
            style: StrokeStyle(lineWidth: golden ? 3 : 1.5, lineCap: .round))
        }
        let sun = Solar.position(at: date, place: place)
        let p = point(sun, size: size)
        for r in [20.0, 12.0, 6.0] {
          context.fill(
            Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
            with: .color(Palette.copper.opacity(r == 6 ? 1 : r == 12 ? 0.15 : 0.05)))
        }
      }
      .gesture(
        DragGesture(minimumDistance: 0).onChanged { value in
          let closest = day.samples.min {
            let a = point($0.position, size: geometry.size)
            let b = point($1.position, size: geometry.size)
            return hypot(a.x - value.location.x, a.y - value.location.y)
              < hypot(b.x - value.location.x, b.y - value.location.y)
          }
          if let closest { onScrub(day.fraction(at: closest.date)) }
        })
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Interactive sun path, compass sky projection")
    .accessibilityValue(
      "\(Solar.time(date, in: place)), altitude \(Int(Solar.position(at: date, place: place).altitude)) degrees"
    )
    .accessibilityHint(
      "Swipe up or down to move fifteen minutes. The time slider also controls this diagram."
    )
    .accessibilityAdjustableAction { direction in
      onScrub(day.fraction(at: date) + (direction == .increment ? 900 : -900) / day.duration)
    }
  }
}
