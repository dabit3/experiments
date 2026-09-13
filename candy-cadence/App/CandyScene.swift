import SpriteKit
import UIKit

enum CandyPalette {
  static let ink = UIColor(red: 0.16, green: 0.08, blue: 0.27, alpha: 1)
  static let pink = UIColor(red: 1, green: 0.22, blue: 0.53, alpha: 1)
  static let cream = UIColor(red: 1, green: 0.97, blue: 0.86, alpha: 1)
  static let mint = UIColor(red: 0.32, green: 0.91, blue: 0.73, alpha: 1)
  static let yellow = UIColor(red: 1, green: 0.86, blue: 0.24, alpha: 1)
  static let lanes: [UIColor] = [
    .white, yellow, UIColor(red: 0.34, green: 0.87, blue: 0.45, alpha: 1),
    UIColor(red: 0.23, green: 0.65, blue: 1, alpha: 1), pink,
    UIColor(red: 0.23, green: 0.65, blue: 1, alpha: 1),
    UIColor(red: 0.34, green: 0.87, blue: 0.45, alpha: 1), yellow, .white,
  ]
}

@MainActor
final class CandyScene: SKScene {
  let client: GameClient
  private let notesLayer = SKNode()
  private let particles = SKNode()
  private let hud = SKNode()
  private var noteNodes: [Int: SKNode] = [:]
  private var buttons: [SKNode] = []
  private var dancerLeft = SKNode()
  private var dancerRight = SKNode()
  private var score = SKLabelNode()
  private var rivalScore = SKLabelNode()
  private var combo = SKLabelNode()
  private var judgment = SKLabelNode()
  private var timing = SKLabelNode()
  private var countdown = SKLabelNode()
  private var grooveLabel = SKLabelNode()
  private var rivalName = SKLabelNode()
  private var connection = SKLabelNode()
  private var progress = SKShapeNode()
  private var gauge: [SKShapeNode] = []
  private var lastEvent = -1
  private var match = -1
  private var observer: NSObjectProtocol?
  static let canvas = CGSize(width: 1200, height: 840)

  init(client: GameClient) {
    self.client = client
    super.init(size: Self.canvas)
    scaleMode = .aspectFit
    backgroundColor = CandyPalette.cream
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  static func buttonPoint(_ lane: Int) -> CGPoint {
    CGPoint(x: 360 + lane * 60, y: lane.isMultiple(of: 2) ? 89 : 147)
  }

  override func didMove(to view: SKView) {
    guard children.isEmpty else { return }
    buildStage()
    observer = NotificationCenter.default.addObserver(forName: .candyHit, object: nil, queue: .main)
    { [weak self] notification in
      guard let lane = notification.object as? Int else { return }
      MainActor.assumeIsolated { self?.flash(lane) }
    }
  }

  override func willMove(from view: SKView) {
    if let observer { NotificationCenter.default.removeObserver(observer) }
  }

  @discardableResult
  private func box(
    _ parent: SKNode, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat,
    _ fill: UIColor, radius: CGFloat = 18, stroke: UIColor = CandyPalette.ink, line: CGFloat = 3
  ) -> SKShapeNode {
    let shape = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: radius)
    shape.position = CGPoint(x: x, y: y)
    shape.fillColor = fill
    shape.strokeColor = stroke
    shape.lineWidth = line
    parent.addChild(shape)
    return shape
  }

  @discardableResult
  private func oval(
    _ parent: SKNode, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat,
    _ fill: UIColor, stroke: UIColor = CandyPalette.ink, line: CGFloat = 3
  ) -> SKShapeNode {
    let shape = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
    shape.position = CGPoint(x: x, y: y)
    shape.fillColor = fill
    shape.strokeColor = stroke
    shape.lineWidth = line
    parent.addChild(shape)
    return shape
  }

  @discardableResult
  private func text(
    _ parent: SKNode, _ words: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat,
    _ color: UIColor = CandyPalette.ink, font: String = "AvenirNext-Heavy"
  ) -> SKLabelNode {
    let label = SKLabelNode(fontNamed: font)
    label.text = words
    label.fontSize = size
    label.fontColor = color
    label.verticalAlignmentMode = .center
    label.position = CGPoint(x: x, y: y)
    parent.addChild(label)
    return label
  }

  private func star(
    _ parent: SKNode, _ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ fill: UIColor
  ) -> SKShapeNode {
    let path = CGMutablePath()
    for index in 0..<10 {
      let angle = CGFloat(index) * .pi / 5 + .pi / 2
      let length = index.isMultiple(of: 2) ? radius : radius * 0.45
      let point = CGPoint(x: cos(angle) * length, y: sin(angle) * length)
      if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    let node = SKShapeNode(path: path)
    node.position = CGPoint(x: x, y: y)
    node.fillColor = fill
    node.strokeColor = CandyPalette.ink
    node.lineWidth = 2
    parent.addChild(node)
    return node
  }

  private func buildStage() {
    for row in 0..<14 {
      for column in 0..<21 {
        let x = CGFloat(column * 62 + (row.isMultiple(of: 2) ? 0 : 31))
        oval(
          self, x, CGFloat(row * 64), 9, 9, CandyPalette.pink.withAlphaComponent(0.13),
          stroke: .clear)
      }
    }
    let stripe = box(
      self, 130, 400, 230, 960, CandyPalette.mint.withAlphaComponent(0.3), radius: 0, stroke: .clear
    )
    stripe.zRotation = -0.16
    let rightStripe = box(
      self, 1080, 400, 220, 960, CandyPalette.pink.withAlphaComponent(0.12), radius: 0,
      stroke: .clear)
    rightStripe.zRotation = 0.16
    for index in 0..<20 {
      let x = CGFloat((index * 197 + 24) % 1200)
      let y = CGFloat((index * 139 + 60) % 730)
      if x < 285 || x > 920 {
        let decoration = star(
          self, x, y, CGFloat(9 + index % 12),
          index.isMultiple(of: 2) ? CandyPalette.yellow : CandyPalette.pink)
        decoration.zRotation = CGFloat(index)
      }
    }
    box(self, 600, 795, 1168, 66, CandyPalette.pink, radius: 20)
    text(self, "CANDY CADENCE", 255, 798, 33, .white)
    text(self, "9 BUTTONS.  TWO FRIENDS.  ONE SWEET BEAT.", 824, 798, 17, .white)
    box(self, 600, 738, 1110, 34, CandyPalette.yellow, radius: 10)
    text(self, client.song.title.uppercased(), 600, 738, 20)
    text(self, "\(client.song.bpm) BPM  /  LV \(client.song.level)", 150, 738, 16)
    text(self, "ROOM \(client.roomCode)", 1060, 738, 16)

    box(self, 605, 463, 580, 524, CandyPalette.pink, radius: 20)
    box(self, 600, 467, 570, 518, CandyPalette.ink, radius: 18, stroke: .white, line: 5)
    for lane in 0..<9 {
      let x = CGFloat(360 + lane * 60)
      box(
        self, x, 474, 58, 470, CandyPalette.lanes[lane].withAlphaComponent(0.10), radius: 0,
        stroke: .clear)
      box(self, x + 29, 474, 1, 470, .white.withAlphaComponent(0.12), radius: 0, stroke: .clear)
      text(self, "\(lane + 1)", x, 690, 13, CandyPalette.lanes[lane].withAlphaComponent(0.5))
      oval(self, x, 240, 46, 19, CandyPalette.lanes[lane], stroke: .white, line: 2)
    }
    box(self, 600, 254, 540, 3, .white, radius: 0, stroke: .clear)
    text(self, "HIT HERE!", 600, 216, 12, .white)
    addChild(notesLayer)
    addChild(particles)
    addChild(hud)
    for lane in 0..<9 {
      let node = SKNode()
      node.position = Self.buttonPoint(lane)
      oval(node, 0, -7, 72, 72, CandyPalette.ink, stroke: .clear)
      oval(node, 0, 0, 70, 70, CandyPalette.lanes[lane])
      oval(
        node, 0, 3, 56, 52, CandyPalette.lanes[lane], stroke: .white.withAlphaComponent(0.7),
        line: 2)
      oval(node, -12, 15, 18, 8, .white.withAlphaComponent(0.8), stroke: .clear)
      text(node, "\(lane + 1)", 0, -5, 18)
      addChild(node)
      buttons.append(node)
    }
    text(self, "LOW ROW  1 · 3 · 5 · 7 · 9", 454, 32, 12)
    text(self, "HIGH ROW  2 · 4 · 6 · 8", 746, 32, 12)

    box(self, 159, 639, 246, 125, .white, radius: 20)
    text(self, "YOU / \(client.guestName.uppercased())", 159, 678, 16, CandyPalette.pink)
    score = text(self, "0000000", 159, 632, 35)
    text(self, "SWEET SCORE", 159, 600, 12)
    box(self, 1041, 639, 246, 125, .white, radius: 20)
    rivalName = text(self, "RIVAL", 1041, 678, 16, UIColor.systemBlue)
    rivalScore = text(self, "0000000", 1041, 632, 35)
    text(self, "LIVE / REAL PLAYER", 1041, 600, 12)

    oval(self, 155, 301, 207, 34, CandyPalette.ink.withAlphaComponent(0.15), stroke: .clear)
    oval(self, 1045, 301, 207, 34, CandyPalette.ink.withAlphaComponent(0.15), stroke: .clear)
    dancerLeft = mascot(isRabbit: true)
    dancerLeft.position = CGPoint(x: 156, y: 388)
    addChild(dancerLeft)
    dancerRight = mascot(isRabbit: false)
    dancerRight.position = CGPoint(x: 1044, y: 388)
    addChild(dancerRight)
    box(self, 157, 275, 190, 37, CandyPalette.mint, radius: 12)
    text(self, "MALLOW", 157, 275, 21)
    box(self, 1043, 275, 190, 37, CandyPalette.yellow, radius: 12)
    text(self, "FIZZY", 1043, 275, 21)
    text(self, "MARSHMALLOW MIXER", 157, 246, 11)
    text(self, "COSMIC SODA CLUB", 1043, 246, 11)

    box(self, 156, 158, 242, 134, CandyPalette.yellow, radius: 22)
    text(self, "COMBO", 156, 195, 15)
    combo = text(self, "0", 156, 145, 53)
    text(self, "KEEP THE CANDY FLOWING", 156, 112, 10)
    box(self, 1044, 158, 242, 134, CandyPalette.mint, radius: 22)
    grooveLabel = text(self, "GROOVE 30%", 1044, 195, 18)
    for index in 0..<20 {
      let cell = box(
        self, CGFloat(951 + index * 10), 153, 7, 35,
        .white, radius: 2, stroke: .clear)
      gauge.append(cell)
    }
    text(self, "70% TO CLEAR / 100% FEVER", 1044, 114, 11)
    judgment = text(hud, "", 600, 372, 48, CandyPalette.yellow)
    timing = text(hud, "", 600, 332, 17, .white)
    countdown = text(hud, "", 600, 494, 68, .white)
    connection = text(self, "", 600, 10, 10)
    progress = box(self, 332, 707, 1, 4, CandyPalette.yellow, radius: 0, stroke: .clear)
  }

  private func mascot(isRabbit: Bool) -> SKNode {
    let root = SKNode()
    let fur = isRabbit ? UIColor.white : CandyPalette.yellow
    let accent = isRabbit ? CandyPalette.pink : UIColor.systemIndigo
    let leftArm = box(root, -63, -2, 76, 25, fur, radius: 13)
    leftArm.zRotation = 0.65
    let rightArm = box(root, 63, 0, 76, 25, fur, radius: 13)
    rightArm.zRotation = -0.65
    leftArm.run(
      .repeatForever(
        .sequence([.rotate(byAngle: 0.35, duration: 0.25), .rotate(byAngle: -0.35, duration: 0.25)])
      ))
    rightArm.run(
      .repeatForever(
        .sequence([.rotate(byAngle: -0.4, duration: 0.25), .rotate(byAngle: 0.4, duration: 0.25)])))
    oval(root, -84, 24, 28, 30, fur)
    oval(root, 84, 24, 28, 30, fur)
    box(root, -25, -61, 27, 43, CandyPalette.ink, radius: 10)
    box(root, 27, -61, 27, 43, CandyPalette.ink, radius: 10)
    oval(root, -30, -82, 58, 28, accent)
    oval(root, 32, -82, 58, 28, accent)
    if !isRabbit {
      for x in [-47, -15, 16, 48] {
        oval(root, CGFloat(x), -98, 13, 13, CandyPalette.mint)
      }
    }
    box(root, 0, -15, 91, 85, accent, radius: 25)
    box(root, 0, -35, 90, 15, CandyPalette.mint, radius: 3)
    _ = star(root, 0, -8, 19, CandyPalette.yellow)
    if isRabbit {
      let ear1 = oval(root, -31, 111, 33, 104, fur)
      ear1.zRotation = 0.23
      let ear2 = oval(root, 30, 110, 33, 107, fur)
      ear2.zRotation = -0.2
      let inner1 = oval(
        root, -32, 117, 13, 70, CandyPalette.pink.withAlphaComponent(0.5), stroke: .clear)
      inner1.zRotation = 0.23
      let inner2 = oval(
        root, 32, 117, 13, 70, CandyPalette.pink.withAlphaComponent(0.5), stroke: .clear)
      inner2.zRotation = -0.2
    } else {
      for side: CGFloat in [-1, 1] {
        let ear = star(root, side * 42, 98, 39, fur)
        ear.zRotation = side * 0.3
      }
    }
    oval(root, 0, 54, 124, 108, fur, line: 4)
    oval(root, -49, 66, 32, 53, accent, line: 4)
    oval(root, 49, 66, 32, 53, accent, line: 4)
    box(root, 0, 102, 87, 15, accent, radius: 7)
    oval(root, -23, 60, 14, 22, CandyPalette.ink, stroke: .clear)
    oval(root, 23, 60, 14, 22, CandyPalette.ink, stroke: .clear)
    oval(root, -25, 65, 5, 6, .white, stroke: .clear)
    oval(root, 21, 65, 5, 6, .white, stroke: .clear)
    oval(root, -36, 40, 21, 11, CandyPalette.pink.withAlphaComponent(0.5), stroke: .clear)
    oval(root, 36, 40, 21, 11, CandyPalette.pink.withAlphaComponent(0.5), stroke: .clear)
    oval(root, 0, 35, 26, 23, CandyPalette.ink, stroke: .clear)
    oval(root, 0, 29, 16, 9, CandyPalette.pink, stroke: .clear)
    oval(root, 0, 49, 9, 7, accent, stroke: .clear)
    if !isRabbit {
      let cap = box(root, 0, 98, 86, 24, CandyPalette.mint, radius: 10)
      cap.zRotation = 0.1
      box(root, 31, 87, 52, 10, CandyPalette.mint, radius: 5)
      _ = star(root, -13, 100, 10, .white)
    }
    return root
  }

  private func pop(_ note: PopNote) -> SKNode {
    let node = SKNode()
    box(node, 0, -3, 48, 23, .black.withAlphaComponent(0.4), radius: 10, stroke: .clear)
    box(node, 0, 0, 48, 23, CandyPalette.lanes[note.lane], radius: 10, stroke: .white, line: 1.5)
    oval(node, -9, 2, 4, 6, CandyPalette.ink, stroke: .clear)
    oval(node, 9, 2, 4, 6, CandyPalette.ink, stroke: .clear)
    box(node, 0, -4, 7, 2, CandyPalette.ink, radius: 1, stroke: .clear)
    box(node, -9, 7, 13, 2, .white.withAlphaComponent(0.6), radius: 1, stroke: .clear)
    return node
  }

  func flash(_ lane: Int) {
    guard buttons.indices.contains(lane) else { return }
    let node = buttons[lane]
    node.removeAllActions()
    node.setScale(0.88)
    node.run(.sequence([.scale(to: 1.1, duration: 0.06), .scale(to: 1, duration: 0.12)]))
    let glow = oval(
      particles, CGFloat(360 + lane * 60), 240, 58, 28,
      CandyPalette.lanes[lane].withAlphaComponent(0.5), stroke: .white)
    glow.run(
      .sequence([
        .group([.scale(to: 1.8, duration: 0.2), .fadeOut(withDuration: 0.2)]), .removeFromParent(),
      ]))
  }

  override func update(_ currentTime: TimeInterval) {
    client.tick()
    guard let state = client.state, let me = client.me else { return }
    let elapsed = client.elapsed
    if match != state.match {
      match = state.match
      notesLayer.removeAllChildren()
      noteNodes.removeAll()
      lastEvent = -1
    }
    let beat = elapsed / (60000 / Double(client.song.bpm))
    dancerLeft.position.y = 388 + abs(sin(beat * .pi)) * 13
    dancerLeft.zRotation = sin(beat * .pi) * 0.055
    dancerRight.position.y = 388 + abs(cos(beat * .pi)) * 13
    dancerRight.zRotation = -sin(beat * .pi) * 0.065
    let judged = Set(me.judged)
    for note in client.song.notes {
      let until = note.at - elapsed
      let visible = until < 2200 && until > -190 && !judged.contains(note.id)
      if visible {
        let node: SKNode
        if let existing = noteNodes[note.id] {
          node = existing
        } else {
          node = pop(note)
          noteNodes[note.id] = node
          notesLayer.addChild(node)
        }
        let noteX = CGFloat(360 + note.lane * 60)
        let noteY = CGFloat(254 + until / 2200 * 426)
        node.position = CGPoint(x: noteX, y: noteY)
      } else if let node = noteNodes.removeValue(forKey: note.id) {
        node.removeFromParent()
      }
    }
    score.text = String(format: "%07d", me.score)
    rivalScore.text = String(format: "%07d", client.rival?.score ?? 0)
    rivalName.text = "RIVAL / \(client.rival?.name.uppercased() ?? "WAITING")"
    combo.text = "\(me.combo)"
    grooveLabel.text = me.groove == 100 ? "FEVER! 100%" : "GROOVE \(me.groove)%"
    for (index, cell) in gauge.enumerated() {
      cell.fillColor =
        index < me.groove / 5 ? (index >= 14 ? CandyPalette.pink : CandyPalette.ink) : .white
    }
    progress.xScale = max(1, min(536, elapsed / client.song.duration * 536))
    progress.position.x = 332 + progress.xScale / 2
    countdown.text =
      elapsed < 0 ? "\(Int(ceil(-elapsed / 1000)))" : elapsed < 1000 ? "LET'S POP!" : ""
    if me.event != lastEvent {
      lastEvent = me.event
      judgment.text = me.verdict == "COOL" ? "SWEET!" : me.verdict
      judgment.fontColor = me.verdict == "MISS" ? CandyPalette.pink : CandyPalette.yellow
      timing.text =
        me.verdict == "MISS"
        ? "KEEP GOING!" : me.delta < -45 ? "EARLY" : me.delta > 45 ? "LATE" : "RIGHT ON THE BEAT"
      judgment.removeAllActions()
      timing.removeAllActions()
      judgment.alpha = 1
      timing.alpha = 1
      judgment.setScale(1.12)
      judgment.run(
        .sequence([
          .scale(to: 1, duration: 0.12), .wait(forDuration: 0.35), .fadeOut(withDuration: 0.15),
        ]))
      timing.run(.sequence([.wait(forDuration: 0.47), .fadeOut(withDuration: 0.15)]))
      if me.verdict != "MISS" && me.lane >= 0 {
        for index in 0..<5 {
          let sparkle = star(
            particles, CGFloat(360 + me.lane * 60), 261, 6, CandyPalette.lanes[me.lane])
          sparkle.run(
            .sequence([
              .group([
                .moveBy(x: CGFloat(index - 2) * 18, y: CGFloat(40 + index % 3 * 19), duration: 0.3),
                .fadeOut(withDuration: 0.3), .rotate(byAngle: 2, duration: 0.3),
              ]), .removeFromParent(),
            ]))
        }
      }
    }
    let network =
      client.connected
      ? "LIVE • \(Int(client.clockRTT))ms • \(me.judged.count)/\(client.song.notes.count) notes"
      : "RECONNECTING — MATCH CLOCK CONTINUES"
    connection.text =
      "\(client.automated ? "AUTOMATED INPUT DRIVER • " : "TOUCH CONTROLS • ")\(network)"
  }
}
