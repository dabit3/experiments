import UIKit

@MainActor
final class DeckView: UIView {
  let session: Session
  var onExit: (() -> Void)?
  var pressed: Set<Int> = []
  private var touchLanes: [ObjectIdentifier: Int] = [:]
  private var scratchPosition: [ObjectIdentifier: CGPoint] = [:]
  private var flashes = [Double](repeating: 0, count: 8)
  private var scratchAngle = 0.0
  private let cyan = UIColor(red: 0.2, green: 0.82, blue: 1, alpha: 1)
  private let blue = UIColor(red: 0.08, green: 0.32, blue: 0.98, alpha: 1)
  private let red = UIColor(red: 1, green: 0.24, blue: 0.39, alpha: 1)
  private let dim = UIColor(red: 0.35, green: 0.47, blue: 0.6, alpha: 1)
  private let ink = UIColor(red: 0.025, green: 0.04, blue: 0.07, alpha: 1)
  private let field = CGRect(x: 194, y: 75, width: 574, height: 255)
  private let widths: [CGFloat] = [70, 72, 72, 72, 72, 72, 72, 72]

  init(session: Session) {
    self.session = session
    super.init(frame: CGRect(x: 0, y: 0, width: 1000, height: 440))
    isMultipleTouchEnabled = true
    backgroundColor = ink
    isAccessibilityElement = false
    session.onHit = { [weak self] lane, down in
      guard let self else { return }
      if down {
        self.pressed.insert(lane)
        self.flashes[lane] = CACurrentMediaTime()
        if lane == 0 { self.scratchAngle += 0.45 }
      } else {
        self.pressed.remove(lane)
      }
    }
  }

  required init?(coder: NSCoder) { nil }
  override var canBecomeFirstResponder: Bool { true }

  private func box(_ rect: CGRect, _ color: UIColor, radius: CGFloat = 0) {
    color.setFill()
    UIBezierPath(roundedRect: rect, cornerRadius: radius).fill()
  }

  private func line(_ a: CGPoint, _ b: CGPoint, _ color: UIColor, width: CGFloat = 1) {
    let path = UIBezierPath()
    path.move(to: a)
    path.addLine(to: b)
    path.lineWidth = width
    color.setStroke()
    path.stroke()
  }

  private func text(
    _ value: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat = 12,
    color: UIColor? = nil, bold: Bool = false, width: CGFloat = 600
  ) {
    let font =
      bold
      ? UIFont.monospacedSystemFont(ofSize: size, weight: .bold)
      : UIFont.monospacedSystemFont(ofSize: size, weight: .medium)
    (value as NSString).draw(
      in: CGRect(x: x, y: y, width: width, height: size * 2.8),
      withAttributes: [.font: font, .foregroundColor: color ?? .white])
  }

  private func gradient(_ rect: CGRect, colors: [UIColor]) {
    guard let context = UIGraphicsGetCurrentContext(),
      let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors.map(\.cgColor) as CFArray, locations: nil)
    else { return }
    context.saveGState()
    context.clip(to: rect)
    context.drawLinearGradient(
      gradient, start: CGPoint(x: rect.midX, y: rect.minY),
      end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
    context.restoreGState()
  }

  private func laneRect(_ lane: Int) -> CGRect {
    CGRect(
      x: field.minX + widths.prefix(lane).reduce(0, +), y: field.minY,
      width: widths[lane], height: field.height)
  }

  func animate() {
    session.tick()
    setNeedsDisplay()
  }

  override func draw(_ rect: CGRect) {
    let t = CACurrentMediaTime()
    gradient(bounds, colors: [UIColor(red: 0.06, green: 0.085, blue: 0.13, alpha: 1), ink])
    for y in stride(from: 0, to: 440, by: 4) {
      line(CGPoint(x: 0, y: y), CGPoint(x: 1000, y: y), UIColor.white.withAlphaComponent(0.018))
    }
    box(CGRect(x: 0, y: 0, width: 1000, height: 3), cyan)
    text("MIDNIGHT", 20, 16, size: 21, bold: true)
    text("D E C K S", 21, 40, size: 12, color: cyan)
    text("AFTERIMAGE", 196, 13, size: 25, bold: true)
    text("03:17 / MIDNIGHT SYSTEM", 196, 44, size: 11, color: dim)
    text("128", 569, 14, size: 25, color: cyan, bold: true)
    text("BPM", 572, 43, size: 10, color: dim)
    box(CGRect(x: 641, y: 17, width: 126, height: 33), blue.withAlphaComponent(0.2), radius: 3)
    text("NORMAL 04", 651, 25, size: 15, color: cyan, bold: true)
    text(
      session.auto ? "AUTO INPUT DRIVER" : "7 KEY + SCRATCH", 791, 18, size: 12,
      color: session.auto ? .systemYellow : dim)
    let online = session.connected ? "● LINK \(Int(session.rtt))ms" : "○ LOCAL DECK"
    text(online, 791, 41, size: 11, color: session.connected ? cyan : dim)
    drawLanes(t)
    drawMetrics()
    drawWheel(t)
    drawVisualizer(t)
    drawGauge()
    if let state = session.state {
      if state.phase == "playing" && session.songTime < 0 {
        drawCountdown()
      }
      if state.phase == "result" { drawResult() }
      if !session.connected {
        box(
          CGRect(x: 240, y: 160, width: 520, height: 120), ink.withAlphaComponent(0.98), radius: 8)
        text("LINK LOST", 392, 180, size: 25, color: red, bold: true)
        text("TAP HERE TO RECONNECT", 346, 226, size: 17, color: cyan)
      }
    }
  }

  private func drawLanes(_ time: Double) {
    box(field.insetBy(dx: -4, dy: -4), UIColor(red: 0.16, green: 0.24, blue: 0.33, alpha: 1))
    let songTime = session.songTime
    for lane in 0...7 {
      let laneBox = laneRect(lane)
      let lit = pressed.contains(lane) || time - flashes[lane] < 0.1
      let base: UIColor =
        lane == 0
        ? UIColor(red: 0.13, green: 0.055, blue: 0.085, alpha: 1)
        : lane % 2 == 0
          ? UIColor(red: 0.02, green: 0.035, blue: 0.065, alpha: 1)
          : UIColor(red: 0.09, green: 0.115, blue: 0.15, alpha: 1)
      box(laneBox, base)
      if lit {
        gradient(laneBox, colors: [.clear, (lane == 0 ? red : cyan).withAlphaComponent(0.4)])
      }
      line(
        CGPoint(x: laneBox.minX, y: laneBox.minY), CGPoint(x: laneBox.minX, y: 420),
        dim.withAlphaComponent(0.3))
      let key = CGRect(
        x: laneBox.minX + 4, y: 344 + (lane > 0 && lane % 2 == 0 ? -5 : 0),
        width: laneBox.width - 8, height: lane > 0 && lane % 2 == 0 ? 56 : 67)
      if lane == 0 {
        text("SCR", key.minX + 10, 367, size: 17, color: red, bold: true)
        text("SWIPE", key.minX + 7, 394, size: 10, color: dim)
      } else {
        gradient(
          key,
          colors: lit
            ? [cyan, blue]
            : lane % 2 == 0
              ? [UIColor(white: 0.21, alpha: 1), UIColor(white: 0.05, alpha: 1)]
              : [UIColor(white: 0.88, alpha: 1), UIColor(white: 0.47, alpha: 1)])
        box(
          CGRect(x: key.minX + 4, y: key.minY + 5, width: key.width - 8, height: 3),
          lane % 2 == 0 ? cyan : .white)
        text(
          "\(lane)", key.midX - 5, key.minY + 22, size: 16,
          color: lane % 2 == 0 ? cyan : ink, bold: true)
        text(
          ["", "S", "D", "F", "SPACE", "J", "K", "L"][lane],
          key.minX + 5, key.maxY - 15, size: 9, color: lane % 2 == 0 ? dim : ink)
      }
    }
    let pxPerMS = 0.12 * session.speed
    if session.state?.phase == "playing" {
      let beatMS = 60000.0 / Double(session.chart.bpm)
      for beat in -8...140 where beat % 4 == 0 {
        let y = 329 - (2000 + Double(beat) * beatMS - songTime) * pxPerMS
        if y >= 75 && y < 330 {
          line(CGPoint(x: 194, y: y), CGPoint(x: 768, y: y), cyan.withAlphaComponent(0.11))
          text(String(format: "%02d", max(0, beat / 4 + 1)), 195, y + 2, size: 8, color: dim)
        }
      }
      for note in session.chart.notes {
        let y = 329 - (note.time - songTime) * pxPerMS
        let end = y - note.duration * pxPerMS
        if y < 72 || end > 335 { continue }
        let r = laneRect(note.lane)
        let done = (session.me?.stats.heads[note.id] ?? 0) != 0
        let tailDone = (session.me?.stats.tails[note.id] ?? 0) != 0
        if done && (note.duration == 0 || tailDone) { continue }
        let color: UIColor =
          note.lane == 0
          ? red
          : note.duration > 0
            ? UIColor.systemPurple
            : note.lane % 2 == 0 ? cyan : .white
        if note.duration > 0 {
          let top = max(75, end)
          let bottom = min(329, y)
          if bottom > top {
            gradient(
              CGRect(x: r.minX + 16, y: top, width: r.width - 32, height: bottom - top),
              colors: [color.withAlphaComponent(0.3), color.withAlphaComponent(done ? 0.8 : 0.5)])
            line(CGPoint(x: r.midX, y: top), CGPoint(x: r.midX, y: bottom), color, width: 2)
          }
          if end >= 75 {
            box(CGRect(x: r.minX + 5, y: end, width: r.width - 10, height: 7), color)
          }
        }
        if !done && y <= 335 {
          box(
            CGRect(x: r.minX + 4, y: y - 6, width: r.width - 8, height: 9),
            color.withAlphaComponent(0.18))
          box(CGRect(x: r.minX + 5, y: y - 5, width: r.width - 10, height: 5), color)
          box(CGRect(x: r.minX + 7, y: y - 5, width: r.width - 14, height: 1), .white)
        }
      }
    } else {
      for lane in 1...7 {
        let r = laneRect(lane)
        let y = 120 + CGFloat(lane % 3) * 38
        box(
          CGRect(x: r.minX + 5, y: y, width: r.width - 10, height: 5),
          (lane % 2 == 0 ? cyan : .white).withAlphaComponent(0.3))
      }
    }
    box(CGRect(x: 194, y: 327, width: 574, height: 3), red)
    box(CGRect(x: 194, y: 330, width: 574, height: 3), red.withAlphaComponent(0.2))
    if let stats = session.me?.stats, stats.last.serial > 0, session.state?.phase == "playing" {
      let label = stats.last.text
      let color = label == "POOR" || label == "BAD" ? red : cyan
      let fontSize: CGFloat = label.count > 8 ? 23 : 30
      text(label, 287, 228, size: fontSize, color: color, bold: true, width: 450)
      text(String(format: "%04d", stats.combo), 416, 257, size: 36, color: .white, bold: true)
      if label != "POOR" {
        text(
          "\(stats.last.delta < 0 ? "FAST" : "SLOW") \(abs(stats.last.delta))ms", 434, 302,
          size: 10, color: dim)
      }
    }
  }

  private func drawMetrics() {
    let me = session.me
    text("PLAYER 01", 20, 80, size: 10, color: cyan)
    text(me?.name.uppercased() ?? "NOVA", 20, 97, size: 18, bold: true, width: 166)
    text("EX SCORE", 20, 130, size: 11, color: dim)
    text(String(format: "%04d", me?.stats.score ?? 0), 16, 144, size: 43, color: cyan, bold: true)
    line(CGPoint(x: 20, y: 197), CGPoint(x: 170, y: 197), dim.withAlphaComponent(0.4))
    text("MAX COMBO", 20, 208, size: 10, color: dim)
    text(String(format: "%04d", me?.stats.maxCombo ?? 0), 115, 205, size: 16, bold: true)
    text("HI-SPEED \(String(format: "%.1f", session.speed))", 20, 383, size: 11, color: dim)
    text("EXIT ROOM", 20, 419, size: 10, color: dim)
  }

  private func drawWheel(_ time: Double) {
    let center = CGPoint(x: 93, y: 302)
    let spinning = pressed.contains(0)
    let angle = scratchAngle + (session.state?.phase == "playing" ? time * 0.65 : time * 0.12)
    for radius in stride(from: CGFloat(69), through: 24, by: -3) {
      let path = UIBezierPath(
        ovalIn: CGRect(
          x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
      let intensity: CGFloat =
        radius > 65 ? 0.7 : 0.06 + (radius.truncatingRemainder(dividingBy: 6) == 0 ? 0.08 : 0)
      (spinning ? red : cyan).withAlphaComponent(intensity).setStroke()
      path.lineWidth = radius > 65 ? 2 : 1
      path.stroke()
    }
    for tick in 0..<48 {
      let a = Double(tick) * Double.pi / 24 + angle
      line(
        CGPoint(x: center.x + cos(a) * 62, y: center.y + sin(a) * 62),
        CGPoint(x: center.x + cos(a) * 64, y: center.y + sin(a) * 64),
        tick % 4 == 0 ? cyan : dim, width: 2)
    }
    let disc = UIBezierPath(ovalIn: CGRect(x: 65, y: 274, width: 56, height: 56))
    UIColor(red: 0.12, green: 0.2, blue: 0.29, alpha: 1).setFill()
    disc.fill()
    text("M / D", 72, 295, size: 12, color: cyan, bold: true)
    line(
      center, CGPoint(x: center.x + cos(angle) * 52, y: center.y + sin(angle) * 52), red, width: 3)
    text("TOUCH + SPIN", 46, 361, size: 10, color: dim)
  }

  private func drawVisualizer(_ time: Double) {
    let playing = session.state?.phase == "playing"
    let beat = max(0, session.songTime) / (60000 / 128)
    let pulse = playing ? 1 - beat.truncatingRemainder(dividingBy: 1) : 0.2
    let clip = CGRect(x: 787, y: 74, width: 194, height: 245)
    box(clip, UIColor(red: 0.025, green: 0.06, blue: 0.105, alpha: 1))
    guard let context = UIGraphicsGetCurrentContext() else { return }
    context.saveGState()
    context.clip(to: clip)
    let center = CGPoint(x: 884, y: 180)
    for index in 0..<10 {
      let size = Double(index) * 18 + 18 + pulse * 8
      context.saveGState()
      context.translateBy(x: center.x, y: center.y)
      context.rotate(by: time * 0.07 + Double(index) * 0.18)
      let path = UIBezierPath(rect: CGRect(x: -size / 2, y: -size / 2, width: size, height: size))
      path.lineWidth = index % 3 == 0 ? 2 : 0.6
      cyan.withAlphaComponent(CGFloat(0.35 - Double(index) * 0.018)).setStroke()
      path.stroke()
      context.restoreGState()
    }
    for index in 0..<24 {
      let height = 7 + abs(sin(time * 3 + Double(index) * 1.4)) * (18 + pulse * 20)
      gradient(
        CGRect(x: 792 + Double(index) * 7.8, y: 310 - height, width: 4, height: height),
        colors: [cyan, blue.withAlphaComponent(0.2)])
    }
    context.restoreGState()
    let section = min(7, max(0, Int((session.songTime - 2000) / 7500)))
    text(
      playing ? session.chart.sections[section] : "OPTICAL FREQUENCIES", 796, 84, size: 10,
      color: cyan, width: 190)
    text("MD—0317", 842, 243, size: 10, color: dim)
    let remaining = max(0, Int((session.chart.duration - max(0, session.songTime)) / 1000))
    text(
      String(format: "%02d:%02d", remaining / 60, remaining % 60), 847, 263, size: 19, bold: true)
    text("LIVE RIVAL", 789, 337, size: 10, color: dim)
    text(
      session.opponent?.name.uppercased() ?? "WAITING…", 789, 354, size: 14, color: .white,
      bold: true, width: 130)
    text(
      String(format: "%04d", session.opponent?.stats.score ?? 0), 914, 349, size: 22, color: cyan,
      bold: true)
    let diff = (session.me?.stats.score ?? 0) - (session.opponent?.stats.score ?? 0)
    text(
      "\(diff >= 0 ? "+" : "")\(diff) EX", 790, 382, size: 15, color: diff >= 0 ? cyan : red,
      bold: true)
    text(session.opponent?.online == true ? "● ONLINE" : "○ OFFLINE", 908, 387, size: 9, color: dim)
    let total = session.chart.notes.reduce(0) { $0 + ($1.duration > 0 ? 4 : 2) }
    box(CGRect(x: 789, y: 411, width: 190, height: 3), dim.withAlphaComponent(0.3))
    box(
      CGRect(
        x: 789, y: 411, width: 190 * Double(session.me?.stats.score ?? 0) / Double(total), height: 3
      ), cyan)
  }

  private func drawGauge() {
    let gauge = session.me?.stats.gauge ?? 22
    text("GROOVE GAUGE", 792, 425, size: 10, color: dim)
    text("\(Int(gauge))%", 944, 423, size: 13, color: gauge >= 80 ? red : cyan, bold: true)
    for index in 0..<50 {
      let color = index >= 40 ? red : cyan
      box(
        CGRect(x: 194 + Double(index) * 11.48, y: 423, width: 9.4, height: 12),
        color.withAlphaComponent(Double(index) * 2 < gauge ? 1 : 0.15))
    }
    box(CGRect(x: 653, y: 420, width: 1.5, height: 18), .white)
  }

  private func drawCountdown() {
    box(CGRect(x: 268, y: 130, width: 420, height: 155), ink.withAlphaComponent(0.92), radius: 5)
    text("SYNCHRONIZED BATTLE", 320, 154, size: 18, color: cyan, bold: true)
    text("\(Int(ceil(-session.songTime / 1000)))", 458, 190, size: 58, bold: true)
    text("BOTH DECKS / ONE CLOCK", 367, 257, size: 11, color: dim)
  }

  private func drawResult() {
    guard let state = session.state, let me = session.me else { return }
    box(bounds, ink.withAlphaComponent(0.84))
    let card = CGRect(x: 225, y: 49, width: 550, height: 355)
    gradient(card, colors: [UIColor(red: 0.08, green: 0.14, blue: 0.22, alpha: 1), ink])
    box(CGRect(x: 225, y: 49, width: 550, height: 3), cyan)
    let verdict =
      state.winner == "draw" ? "DRAW" : state.winner == me.id ? "BATTLE WON" : "BATTLE LOST"
    text(verdict, 305, 72, size: 37, color: cyan, bold: true)
    text(
      "AFTERIMAGE  /  ROUND \(state.round)  /  ROOM \(state.room)", 276, 119, size: 12, color: dim)
    for (index, player) in state.players.enumerated() {
      let x: CGFloat = index == 0 ? 270 : 538
      text(player.name.uppercased(), x, 153, size: 17, bold: true, width: 225)
      text(String(format: "%04d", player.stats.score), x, 178, size: 45, color: cyan, bold: true)
      text("EX SCORE  •  \(player.stats.maxCombo) COMBO", x, 231, size: 10, color: dim)
      text(
        player.stats.gauge >= 80 ? "GROOVE CLEAR" : "GROOVE FAILED", x, 253, size: 14,
        color: player.stats.gauge >= 80 ? cyan : red, bold: true)
      text(
        "P \(player.stats.counts.perfect)   G \(player.stats.counts.great)   MISS \(player.stats.counts.poor)",
        x, 277, size: 10, color: dim)
    }
    box(
      CGRect(x: 270, y: 315, width: 460, height: 43),
      me.ready ? blue.withAlphaComponent(0.3) : cyan, radius: 3)
    text(
      me.ready ? "READY — WAITING FOR RIVAL" : "REMATCH / READY BOTH DECKS",
      330, 329, size: 15, color: me.ready ? cyan : ink, bold: true)
    text("EXIT TO LOBBY", 438, 377, size: 11, color: dim)
  }

  private func control(at point: CGPoint) -> Int? {
    if hypot(point.x - 93, point.y - 302) < 75 { return 0 }
    if point.y >= 332 && point.x >= field.minX && point.x < field.maxX {
      return (0...7).first { laneRect($0).contains(CGPoint(x: point.x, y: 100)) }
    }
    return nil
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    becomeFirstResponder()
    for touch in touches {
      let point = touch.location(in: self)
      if !session.connected && session.state != nil {
        session.connect(create: false)
        continue
      }
      if session.state?.phase == "result" {
        if point.y >= 315 && point.y <= 360 { session.ready() }
        if point.y > 365 { onExit?() }
        continue
      }
      if point.x < 180 && point.y > 410 {
        onExit?()
        continue
      }
      if let lane = control(at: point) {
        touchLanes[ObjectIdentifier(touch)] = lane
        if lane == 0 {
          scratchPosition[ObjectIdentifier(touch)] = point
        } else {
          session.input(lane: lane, down: true)
        }
      }
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      let id = ObjectIdentifier(touch)
      let point = touch.location(in: self)
      if touchLanes[id] == 0, let previous = scratchPosition[id] {
        if hypot(point.x - previous.x, point.y - previous.y) >= 6 {
          session.input(lane: 0, down: true)
          session.input(lane: 0, down: false)
          scratchPosition[id] = point
        }
      }
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { release(touches) }
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { release(touches) }

  private func release(_ touches: Set<UITouch>) {
    for touch in touches {
      let id = ObjectIdentifier(touch)
      if let lane = touchLanes.removeValue(forKey: id), !touchLanes.values.contains(lane) {
        session.input(lane: lane, down: false)
      }
      scratchPosition.removeValue(forKey: id)
    }
  }

  private func lane(for press: UIPress) -> Int? {
    guard let key = press.key else { return nil }
    let mapping: [UIKeyboardHIDUsage: Int] = [
      .keyboardS: 1, .keyboardD: 2, .keyboardF: 3,
      .keyboardSpacebar: 4, .keyboardJ: 5, .keyboardK: 6, .keyboardL: 7,
      .keyboardLeftShift: 0, .keyboardRightShift: 0,
    ]
    return mapping[key.keyCode]
  }

  override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    for press in presses {
      if let lane = lane(for: press), !pressed.contains(lane) {
        session.input(lane: lane, down: true)
      }
    }
  }

  override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    for press in presses {
      if let lane = lane(for: press) { session.input(lane: lane, down: false) }
    }
  }

  override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    pressesEnded(presses, with: event)
  }
}
