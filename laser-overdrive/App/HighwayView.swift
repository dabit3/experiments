import SwiftUI
import UIKit

enum Neon {
  static let cyan = UIColor(red: 0.12, green: 0.93, blue: 1, alpha: 1)
  static let pink = UIColor(red: 1, green: 0.12, blue: 0.68, alpha: 1)
  static let gold = UIColor(red: 1, green: 0.73, blue: 0.26, alpha: 1)
  static let muted = UIColor(red: 0.44, green: 0.55, blue: 0.7, alpha: 1)
  static let ink = UIColor(red: 0.025, green: 0.035, blue: 0.09, alpha: 1)
}

struct Highway: UIViewRepresentable {
  let model: GameModel

  func makeUIView(context: Context) -> HighwayCanvas { HighwayCanvas(model: model) }
  func updateUIView(_ view: HighwayCanvas, context: Context) {}
  static func dismantleUIView(_ view: HighwayCanvas, coordinator: Void) { view.stop() }
}

@MainActor
final class HighwayCanvas: UIView {
  let model: GameModel
  private var displayLink: CADisplayLink?
  private var touchesByID: [ObjectIdentifier: Int] = [:]
  private var lastTouchX: [ObjectIdentifier: CGFloat] = [:]
  private var knobTouchTime = [-10.0, -10.0]
  private var context: CGContext!
  private var height = 844.0
  private var hitY: Double { height - 250 }
  private let horizon = 248.0
  private let lookahead = 2.35

  init(model: GameModel) {
    self.model = model
    super.init(frame: .zero)
    isMultipleTouchEnabled = true
    isOpaque = true
    backgroundColor = Neon.ink
    accessibilityLabel =
      "Laser Overdrive rhythm highway. Four BT buttons, two FX buttons, two swipe knobs."
    let link = CADisplayLink(target: self, selector: #selector(updateFrame))
    link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  required init?(coder: NSCoder) { nil }

  func stop() {
    displayLink?.invalidate()
    displayLink = nil
  }

  @objc private func updateFrame() {
    model.frame()
    let time = model.songTime
    for color in 0..<2 where touchesByID.values.contains(6 + color) {
      if time - knobTouchTime[color] > 0.03 {
        model.laser(color, x: model.lasers[color])
        knobTouchTime[color] = time
      }
    }
    setNeedsDisplay()
  }

  override func draw(_ rect: CGRect) {
    guard let drawing = UIGraphicsGetCurrentContext() else { return }
    context = drawing
    let scale = bounds.width / 390
    height = bounds.height / scale
    context.scaleBy(x: scale, y: scale)
    let time = model.songTime
    background(time: time)
    road(time: time)
    notes(time: time)
    headsUp(time: time)
    controller(time: time)
    if time < 0 { countdown(time: time) }
    if !model.connected {
      panel(CGRect(x: 22, y: 318, width: 346, height: 80), color: Neon.gold)
      text("LINK RECOVERY", 195, 335, 23, .white, align: .center)
      text("REJOINING THE SAME MATCH", 195, 369, 10, Neon.gold, align: .center)
    }
  }

  private func background(time: Double) {
    let gradient = CGGradient(
      colorsSpace: CGColorSpaceCreateDeviceRGB(),
      colors: [
        Neon.ink.cgColor, UIColor(red: 0.07, green: 0.025, blue: 0.15, alpha: 1).cgColor,
        Neon.ink.cgColor,
      ] as CFArray, locations: [0, 0.57, 1])!
    context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 390, y: height), options: [])
    for index in 0..<46 {
      let x = Double((index * 137 + 31) % 390)
      let y =
        210
        + (Double(index * 97) + max(0, time) * (12 + Double(index % 5) * 9))
        .truncatingRemainder(dividingBy: max(1, hitY - 180))
      let color = index % 2 == 0 ? Neon.cyan : Neon.pink
      line([CGPoint(x: x, y: y), CGPoint(x: x + 2, y: y + 7)], color.withAlphaComponent(0.24), 1)
    }
    for side in [-1.0, 1.0] {
      for index in 0..<6 {
        let offset = Double(index) * 35
        let color = side < 0 ? Neon.cyan : Neon.pink
        line(
          [
            CGPoint(x: 195 + side * (34 + offset / 8), y: horizon),
            CGPoint(x: 195 + side * (142 + offset), y: hitY - 35),
            CGPoint(x: 195 + side * (155 + offset), y: hitY),
          ], color.withAlphaComponent(0.12 + Double(index % 2) * 0.1), index % 2 == 0 ? 2 : 1)
      }
    }
    let pulse = 0.45 + 0.25 * sin(time * 2 * .pi * 144 / 60)
    for ring in 0..<4 {
      let radius = Double(22 + ring * 15)
      let points = (0..<7).map { i in
        let angle = Double(i) * .pi / 3 + time * 0.15
        return CGPoint(x: 195 + cos(angle) * radius, y: 249 + sin(angle) * radius * 0.5)
      }
      line(
        points,
        (ring % 2 == 0 ? Neon.cyan : Neon.pink).withAlphaComponent(pulse / Double(ring + 1)), 1.4)
    }
  }

  private func projection(_ x: Double, _ delta: Double) -> CGPoint {
    let depth = max(0, min(1, 1 - delta / lookahead))
    let half = 23 + 147 * pow(depth, 1.32)
    return CGPoint(
      x: 195 + (x - 0.5) * 2 * half,
      y: horizon + (hitY - horizon) * pow(depth, 1.7))
  }

  private func road(time: Double) {
    polygon(
      [projection(0, lookahead), projection(1, lookahead), projection(1, 0), projection(0, 0)],
      fill: UIColor(red: 0.025, green: 0.035, blue: 0.065, alpha: 0.97))
    for lane in 0...4 {
      let color = lane == 0 ? Neon.cyan : lane == 4 ? Neon.pink : Neon.muted
      line(
        [projection(Double(lane) / 4, lookahead), projection(Double(lane) / 4, 0)],
        color.withAlphaComponent(lane == 0 || lane == 4 ? 0.8 : 0.28),
        lane == 0 || lane == 4 ? 2 : 0.8)
    }
    let beat = 60.0 / Double(model.chart.bpm)
    let first = Int(floor(time / beat))
    for index in first...(first + 8) {
      let delta = Double(index) * beat - time
      if delta >= 0 && delta < lookahead {
        line(
          [projection(0, delta), projection(1, delta)],
          UIColor.white.withAlphaComponent(index % 4 == 0 ? 0.24 : 0.09), 1)
      }
    }
    for laser in model.chart.lasers {
      guard laser.end > time - 0.08 && laser.start < time + lookahead else { continue }
      let color = laser.color == 0 ? Neon.cyan : Neon.pink
      var points: [CGPoint] = []
      let start = max(time, laser.start)
      let end = min(time + lookahead, laser.end)
      guard start <= end else { continue }
      // Keep the chart's right-angle vertices, even between sampling times.
      var times = stride(from: start, through: end, by: 0.025).map { $0 }
      times += laser.points.map(\.time).filter { $0 >= start && $0 <= end }
      times.append(end)
      times.sort()
      for sample in times { points.append(projection(laser.position(at: sample), sample - time)) }
      line(points, color.withAlphaComponent(0.12), 27, glow: 20)
      line(points, color.withAlphaComponent(0.38), 15, glow: 8)
      line(points, color, 6)
      line(points, UIColor.white.withAlphaComponent(0.9), 1.3)
      if time >= laser.start && time <= laser.end {
        let target = projection(laser.position(at: time), 0)
        let locked = abs(model.lasers[laser.color] - laser.position(at: time)) < 0.14
        circle(target, radius: locked ? 14 : 8, color: color.withAlphaComponent(0.35), fill: true)
        if locked {
          for index in 0..<12 {
            let a = Double(index) * .pi / 6 + time * 5
            let radius = 16 + Double(index % 3) * 8 + sin(time * 34) * 5
            line(
              [target, CGPoint(x: target.x + cos(a) * radius, y: target.y + sin(a) * radius)],
              color.withAlphaComponent(0.75), 1)
          }
        }
      }
    }
    line([CGPoint(x: 17, y: hitY), CGPoint(x: 373, y: hitY)], Neon.gold, 3, glow: 12)
    line([CGPoint(x: 18, y: hitY - 2), CGPoint(x: 372, y: hitY - 2)], .white, 1)
    for color in 0..<2 {
      let point = projection(model.lasers[color], 0)
      let tint = color == 0 ? Neon.cyan : Neon.pink
      polygon(
        [
          CGPoint(x: point.x - 10, y: point.y + 10), CGPoint(x: point.x, y: point.y - 5),
          CGPoint(x: point.x + 10, y: point.y + 10),
        ], fill: tint, stroke: .white)
      text(color == 0 ? "L" : "R", point.x, point.y + 10, 8, tint, align: .center)
    }
  }

  private func notes(time: Double) {
    for note in model.chart.notes {
      let delta = note.time - time
      let endDelta = note.time + note.duration - time
      guard endDelta >= -0.09 && delta <= lookahead else { continue }
      let fx = note.kind == "fx"
      let center = fx ? (note.lane == 4 ? 0.25 : 0.75) : (Double(note.lane) + 0.5) / 4
      let width = fx ? 0.46 : 0.21
      let color = fx ? Neon.gold : UIColor(red: 0.86, green: 0.94, blue: 1, alpha: 1)
      if note.duration > 0 && endDelta > 0 {
        let p = [
          projection(center - width / 2, max(0, delta)),
          projection(center + width / 2, max(0, delta)),
          projection(center + width / 2, min(lookahead, endDelta)),
          projection(center - width / 2, min(lookahead, endDelta)),
        ]
        polygon(p, fill: color.withAlphaComponent(0.26), stroke: color.withAlphaComponent(0.7))
        let a = projection(center, max(0, delta))
        let b = projection(center, min(lookahead, endDelta))
        line([a, b], color.withAlphaComponent(0.8), 2)
      }
      if delta >= -0.055 {
        let a = projection(center - width / 2, max(0, delta))
        let b = projection(center + width / 2, max(0, delta))
        let thickness = 3 + (1 - max(0, delta) / lookahead) * 7
        context.setShadow(offset: .zero, blur: fx ? 7 : 4, color: color.cgColor)
        polygon(
          [
            CGPoint(x: a.x, y: a.y - thickness), CGPoint(x: b.x, y: b.y - thickness),
            b, a,
          ], fill: color)
        context.setShadow(offset: .zero, blur: 0)
        line(
          [
            CGPoint(x: a.x + 2, y: a.y - thickness + 1),
            CGPoint(x: b.x - 2, y: b.y - thickness + 1),
          ], .white, 1)
        line([a, b], fx ? UIColor.brown : UIColor.systemBlue, 1.5)
      }
    }
    for lane in 0..<6 {
      let age = time - model.flashes[lane]
      guard age >= 0 && age < 0.22 else { continue }
      let x = lane < 4 ? (Double(lane) + 0.5) / 4 : lane == 4 ? 0.25 : 0.75
      let center = projection(x, 0)
      let tint = lane < 4 ? Neon.cyan : Neon.gold
      circle(
        center, radius: 10 + age * 170, color: tint.withAlphaComponent(1 - age / 0.22), fill: false)
    }
  }

  private func headsUp(time: Double) {
    text("LASER", 18, 57, 15, .white, weight: .black)
    text("OVERDRIVE", 18, 75, 23, .white, weight: .black)
    text("ONLINE DUEL", 370, 62, 10, Neon.cyan, align: .right)
    text("\(model.roomCode)  /  \(Int(model.rtt))ms", 370, 79, 9, Neon.muted, align: .right)
    line([CGPoint(x: 18, y: 104), CGPoint(x: 370, y: 104)], Neon.cyan.withAlphaComponent(0.5), 1)
    text("YOUR SCORE", 18, 115, 9, Neon.cyan)
    text(String(format: "%08d", model.me?.score ?? 0), 18, 128, 31, .white, weight: .bold)
    text((model.opponent?.name ?? "WAITING").uppercased(), 370, 115, 9, Neon.pink, align: .right)
    text(String(format: "%08d", model.opponent?.score ?? 0), 370, 133, 21, .white, align: .right)
    let difference = (model.me?.score ?? 0) - (model.opponent?.score ?? 0)
    text(
      String(format: "%+d", difference), 370, 158, 9, difference >= 0 ? Neon.cyan : Neon.pink,
      align: .right)
    panel(CGRect(x: 18, y: 181, width: 354, height: 51), color: Neon.muted.withAlphaComponent(0.5))
    diamond(CGPoint(x: 44, y: 207), radius: 17, color: Neon.cyan)
    diamond(CGPoint(x: 44, y: 207), radius: 10, color: Neon.pink)
    text("ION / AFTERBURN", 73, 188, 17, .white, weight: .heavy)
    text("OVERDRIVE SOUND SYSTEM", 73, 213, 8, Neon.muted)
    text("144", 357, 189, 17, Neon.gold, align: .right)
    text("BPM", 357, 213, 8, Neon.muted, align: .right)
    let progress = max(0, min(1, time / model.chart.duration))
    context.setFillColor(Neon.cyan.cgColor)
    context.fill(CGRect(x: 19, y: 231, width: 352 * progress, height: 2))
    let section =
      time < 15.3
      ? "01 / IGNITION"
      : time < 28.6 ? "02 / VOLTAGE" : time < 35.3 ? "03 / CROSSOVER" : "04 / OVERDRIVE"
    text(section, 195, 267, 8, Neon.muted, align: .center)
    let gauge = model.me?.gauge ?? 50
    let railY = 292.0
    let railHeight = hitY - railY - 39
    context.setFillColor(UIColor.white.withAlphaComponent(0.08).cgColor)
    context.fill(CGRect(x: 372, y: railY, width: 5, height: railHeight))
    context.setFillColor((gauge >= 70 ? Neon.pink : Neon.cyan).cgColor)
    context.fill(
      CGRect(
        x: 372, y: railY + railHeight * (1 - gauge / 100), width: 5,
        height: railHeight * gauge / 100))
    line(
      [CGPoint(x: 368, y: railY + railHeight * 0.3), CGPoint(x: 381, y: railY + railHeight * 0.3)],
      Neon.gold, 1)
    text("\(Int(gauge))", 378, hitY - 33, 11, .white, align: .right)
    text("RATE", 378, hitY - 20, 6, Neon.muted, align: .right)
    if time > 1.5 {
      let judgment = model.me?.judgment ?? "STANDBY"
      let age = time - (model.me?.judgmentAt ?? -10)
      if age < 0.6 {
        let tint = judgment == "ERROR" || judgment == "BREAK" ? Neon.pink : Neon.gold
        text(
          judgment, 195, hitY - 126, judgment == "SLAM!" ? 28 : 21, tint, align: .center,
          weight: .black)
      }
      text("CHAIN", 195, hitY - 91, 8, Neon.muted, align: .center)
      text(
        String(format: "%04d", model.me?.combo ?? 0), 195, hitY - 79, 37, .white, align: .center,
        weight: .light)
    }
    if model.automationAvailable {
      text(
        model.driver ? "AUTOMATED INPUT DRIVER" : "MANUAL TOUCH INPUT", 195, hitY - 25, 8,
        model.driver ? Neon.gold : Neon.cyan, align: .center)
    }
    text(
      String(format: "%02d:%02d", Int(max(0, time)) / 60, Int(max(0, time)) % 60),
      19, 271, 9, Neon.muted)
  }

  private func controller(time: Double) {
    let top = hitY + 24
    let labels = ["A", "B", "C", "D"]
    for lane in 0..<4 {
      let x = 20.0 + Double(lane) * 88
      let pressed = model.buttons[lane]
      let rect = CGRect(x: x, y: top, width: 80, height: 58)
      panel(
        rect, color: pressed ? Neon.cyan : Neon.muted,
        fill: pressed
          ? Neon.cyan.withAlphaComponent(0.3) : UIColor(red: 0.1, green: 0.13, blue: 0.2, alpha: 1))
      context.setFillColor((pressed ? UIColor.white : Neon.cyan.withAlphaComponent(0.5)).cgColor)
      context.fill(CGRect(x: x + 10, y: top + 1, width: 60, height: 2))
      text("BT", x + 12, top + 10, 8, Neon.muted)
      text(labels[lane], x + 40, top + 24, 20, .white, align: .center, weight: .bold)
    }
    for index in 0..<2 {
      let x = 20.0 + Double(index) * 176
      let pressed = model.buttons[index + 4]
      panel(
        CGRect(x: x, y: top + 67, width: 168, height: 33),
        color: Neon.gold.withAlphaComponent(pressed ? 1 : 0.55),
        fill: pressed
          ? Neon.gold.withAlphaComponent(0.38) : UIColor(red: 0.14, green: 0.1, blue: 0.1, alpha: 1)
      )
      text(
        index == 0 ? "FX - L   /   DRIVE" : "FX - R   /   FILTER",
        x + 84, top + 78, 10, Neon.gold, align: .center, weight: .bold)
    }
    for color in 0..<2 {
      let x = color == 0 ? 20.0 : 204.0
      let tint = color == 0 ? Neon.cyan : Neon.pink
      let center = CGPoint(x: x + 36, y: top + 146)
      panel(
        CGRect(x: x, y: top + 110, width: 166, height: 77), color: tint.withAlphaComponent(0.55))
      circle(center, radius: 25, color: tint.withAlphaComponent(0.15), fill: true)
      circle(center, radius: 25, color: tint, fill: false)
      circle(center, radius: 20, color: tint.withAlphaComponent(0.5), fill: false)
      for index in 0..<12 {
        let angle = Double(index) * .pi / 6 + model.lasers[color] * .pi * 2
        line(
          [
            CGPoint(x: center.x + cos(angle) * 22, y: center.y + sin(angle) * 22),
            CGPoint(x: center.x + cos(angle) * 26, y: center.y + sin(angle) * 26),
          ], tint, 1)
      }
      let angle = model.lasers[color] * .pi * 1.5 - .pi * 1.25
      line(
        [center, CGPoint(x: center.x + cos(angle) * 16, y: center.y + sin(angle) * 16)], .white, 3)
      text(color == 0 ? "VOL - L" : "VOL - R", x + 75, top + 124, 12, tint, weight: .bold)
      text("‹  SWIPE  ›", x + 75, top + 145, 10, Neon.muted)
      let barX = x + 75
      line(
        [CGPoint(x: barX, y: top + 167), CGPoint(x: x + 151, y: top + 167)],
        tint.withAlphaComponent(0.3), 2)
      circle(
        CGPoint(x: barX + model.lasers[color] * 76, y: top + 167), radius: 3, color: tint,
        fill: true)
    }
    text(
      "BT: TAP / HOLD     FX: ORANGE     VOL: FOLLOW THE LASER", 195, height - 24, 7, Neon.muted,
      align: .center)
  }

  private func countdown(time: Double) {
    panel(CGRect(x: 70, y: hitY - 218, width: 250, height: 128), color: Neon.cyan)
    text("LINK ESTABLISHED", 195, hitY - 198, 11, Neon.cyan, align: .center)
    text("\(max(1, Int(ceil(-time))))", 195, hitY - 175, 54, .white, align: .center, weight: .black)
    text("SHARED SONG START", 195, hitY - 110, 8, Neon.muted, align: .center)
  }

  private func text(
    _ value: String, _ x: Double, _ y: Double, _ size: CGFloat,
    _ color: UIColor, align: NSTextAlignment = .left, weight: UIFont.Weight = .medium
  ) {
    let font = UIFont.monospacedSystemFont(ofSize: size, weight: weight)
    let attributes: [NSAttributedString.Key: NSObject] = [.font: font, .foregroundColor: color]
    let string = value as NSString
    let width = string.size(withAttributes: attributes).width
    let left = align == .center ? x - width / 2 : align == .right ? x - width : x
    string.draw(at: CGPoint(x: left, y: y), withAttributes: attributes)
  }

  private func line(_ points: [CGPoint], _ color: UIColor, _ width: CGFloat, glow: CGFloat = 0) {
    guard let first = points.first else { return }
    context.saveGState()
    context.setStrokeColor(color.cgColor)
    context.setLineWidth(width)
    context.setLineJoin(.round)
    if glow > 0 { context.setShadow(offset: .zero, blur: glow, color: color.cgColor) }
    context.beginPath()
    context.move(to: first)
    for point in points.dropFirst() { context.addLine(to: point) }
    context.strokePath()
    context.restoreGState()
  }

  private func polygon(_ points: [CGPoint], fill: UIColor, stroke: UIColor? = nil) {
    guard let first = points.first else { return }
    context.beginPath()
    context.move(to: first)
    for point in points.dropFirst() { context.addLine(to: point) }
    context.closePath()
    context.setFillColor(fill.cgColor)
    if let stroke {
      context.setStrokeColor(stroke.cgColor)
      context.setLineWidth(1)
      context.drawPath(using: .fillStroke)
    } else {
      context.fillPath()
    }
  }

  private func panel(_ rect: CGRect, color: UIColor, fill: UIColor = Neon.ink) {
    let cut = 8.0
    polygon(
      [
        CGPoint(x: rect.minX + cut, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
        CGPoint(x: rect.maxX, y: rect.maxY - cut), CGPoint(x: rect.maxX - cut, y: rect.maxY),
        CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.minY + cut),
      ],
      fill: fill, stroke: color)
  }

  private func circle(_ center: CGPoint, radius: Double, color: UIColor, fill: Bool) {
    let rect = CGRect(
      x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    context.setFillColor(color.cgColor)
    context.setStrokeColor(color.cgColor)
    context.setLineWidth(1.5)
    if fill { context.fillEllipse(in: rect) } else { context.strokeEllipse(in: rect) }
  }

  private func diamond(_ center: CGPoint, radius: Double, color: UIColor) {
    polygon(
      [
        CGPoint(x: center.x, y: center.y - radius), CGPoint(x: center.x + radius, y: center.y),
        CGPoint(x: center.x, y: center.y + radius), CGPoint(x: center.x - radius, y: center.y),
      ],
      fill: color.withAlphaComponent(0.14), stroke: color)
  }

  private func control(at point: CGPoint) -> Int? {
    let scale = bounds.width / 390
    let x = point.x / scale
    let y = point.y / scale
    let top = hitY + 24
    if y >= top && y <= top + 58 && x >= 20 && x < 372 {
      return min(3, Int((x - 20) / 88))
    }
    if y >= top + 67 && y <= top + 100 && x >= 20 && x <= 372 {
      return x < 196 ? 4 : 5
    }
    if y >= top + 110 && y <= top + 187 && x >= 20 && x <= 372 {
      return x < 195 ? 6 : 7
    }
    return nil
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      let point = touch.location(in: self)
      guard let control = control(at: point) else { continue }
      let key = ObjectIdentifier(touch)
      touchesByID[key] = control
      lastTouchX[key] = point.x
      if control < 6 {
        model.button(control, down: true)
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
      } else {
        model.laser(control - 6, x: model.lasers[control - 6])
      }
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      let key = ObjectIdentifier(touch)
      guard let control = touchesByID[key], control >= 6 else { continue }
      let point = touch.location(in: self)
      let prior = lastTouchX[key] ?? point.x
      let delta = (point.x - prior) / (bounds.width / 390) / 115
      model.laser(control - 6, x: model.lasers[control - 6] + delta)
      lastTouchX[key] = point.x
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { finish(touches) }
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { finish(touches) }

  private func finish(_ touches: Set<UITouch>) {
    for touch in touches {
      let key = ObjectIdentifier(touch)
      guard let control = touchesByID.removeValue(forKey: key) else { continue }
      lastTouchX.removeValue(forKey: key)
      if control < 6 && !touchesByID.values.contains(control) { model.button(control, down: false) }
    }
  }
}
