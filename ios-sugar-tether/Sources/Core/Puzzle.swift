import Foundation

struct V: Equatable, Sendable {
  var x: Double
  var y: Double
  static let zero = V(x: 0, y: 0)
  static func + (a: V, b: V) -> V { V(x: a.x + b.x, y: a.y + b.y) }
  static func - (a: V, b: V) -> V { V(x: a.x - b.x, y: a.y - b.y) }
  static func * (a: V, b: Double) -> V { V(x: a.x * b, y: a.y * b) }
  var length: Double { sqrt(x * x + y * y) }
  func dot(_ other: V) -> Double { x * other.x + y * other.y }
  func distance(_ other: V) -> Double { (self - other).length }
}

struct Thorn: Sendable {
  var center: V
  var width: Double
  var travel: Double = 0
  var period: Double = 3
  func position(at time: Double) -> V {
    V(x: center.x + sin(time * 2 * .pi / period) * travel, y: center.y)
  }
}

struct Puzzle: Sendable {
  let title: String
  let subtitle: String
  let hint: String
  let candy: V
  let anchors: [V]
  let stars: [V]
  let goal: V
  var velocity: V = .zero
  var thorns: [Thorn] = []
  var puff = false
  var bubble: V?
  var startsInBubble = false

  static let all: [Puzzle] = [
    Puzzle(
      title: "A little snip", subtitle: "THE FIRST TASTE",
      hint: "Swipe across the silk. Pip will catch the pearl.",
      candy: V(x: 180, y: 142), anchors: [V(x: 180, y: 47)],
      stars: [V(x: 180, y: 235), V(x: 180, y: 320), V(x: 180, y: 405)],
      goal: V(x: 180, y: 483)),
    Puzzle(
      title: "Two to tango", subtitle: "DOUBLE THREAD",
      hint: "Two threads, one swipe. Or try cutting them one by one.",
      candy: V(x: 180, y: 165),
      anchors: [V(x: 95, y: 57), V(x: 265, y: 57)],
      stars: [V(x: 180, y: 252), V(x: 180, y: 337), V(x: 180, y: 415)],
      goal: V(x: 180, y: 483)),
    Puzzle(
      title: "Golden arc", subtitle: "FOLLOW THE SWING",
      hint: "Gather the stars. Snip as the pearl turns back from the right.",
      candy: V(x: 72, y: 186), anchors: [V(x: 180, y: 63)],
      stars: [V(x: 96, y: 204), V(x: 153, y: 223), V(x: 226, y: 221)],
      goal: V(x: 232, y: 483)),
    Puzzle(
      title: "A soft breeze", subtitle: "A LITTLE LIFT",
      hint: "Snip, then tap PUFF once to drift toward Pip.",
      candy: V(x: 98, y: 166), anchors: [V(x: 98, y: 57)],
      stars: [V(x: 128, y: 199), V(x: 176, y: 297), V(x: 222, y: 407)],
      goal: V(x: 253, y: 483), puff: true),
    Puzzle(
      title: "Up, up, sugar", subtitle: "BUBBLE TROUBLE",
      hint: "Snip to float up. Tap the bubble after the top star.",
      candy: V(x: 180, y: 336), anchors: [V(x: 80, y: 406)],
      stars: [V(x: 180, y: 276), V(x: 180, y: 204), V(x: 180, y: 130)],
      goal: V(x: 180, y: 483), startsInBubble: true),
    Puzzle(
      title: "Mind the thorns", subtitle: "CHOOSE YOUR MOMENT",
      hint: "The thorns glide past. Cut when the path below is clear.",
      candy: V(x: 180, y: 143), anchors: [V(x: 180, y: 48)],
      stars: [V(x: 180, y: 237), V(x: 180, y: 355), V(x: 180, y: 426)],
      goal: V(x: 180, y: 483),
      thorns: [Thorn(center: V(x: 180, y: 302), width: 62, travel: 114, period: 3.2)]),
    Puzzle(
      title: "Silk & soda", subtitle: "A DOUBLE DELIGHT",
      hint: "Free both threads, float to the stars, then pop.",
      candy: V(x: 180, y: 340),
      anchors: [V(x: 83, y: 410), V(x: 277, y: 410)],
      stars: [V(x: 180, y: 267), V(x: 180, y: 195), V(x: 180, y: 120)],
      goal: V(x: 180, y: 483),
      thorns: [
        Thorn(center: V(x: 59, y: 270), width: 55),
        Thorn(center: V(x: 301, y: 270), width: 55),
      ], startsInBubble: true),
    Puzzle(
      title: "The last bonbon", subtitle: "THE SWEET FINALE",
      hint: "Free the pearl. One puff, with a little timing, brings it home.",
      candy: V(x: 98, y: 165),
      anchors: [V(x: 43, y: 56), V(x: 153, y: 56)],
      stars: [V(x: 128, y: 198), V(x: 176, y: 296), V(x: 222, y: 406)],
      goal: V(x: 253, y: 483),
      thorns: [Thorn(center: V(x: 62, y: 335), width: 56, travel: 40, period: 3)],
      puff: true),
  ]
}

struct Thread: Sendable {
  let anchor: V
  let length: Double
  var cut = false
}

enum Outcome: Equatable, Sendable {
  case playing, fed, missed
}

struct PhysicsGame: Sendable {
  let puzzle: Puzzle
  var position: V
  var velocity: V
  var threads: [Thread]
  var collected: Set<Int> = []
  var outcome: Outcome = .playing
  var bubbleActive: Bool
  var bubbleAvailable: Bool
  var time: Double = 0
  var cuts = 0
  var puffs = 0
  var puffCooldown: Double = 0
  var remainder: Double = 0

  init(puzzle: Puzzle) {
    self.puzzle = puzzle
    position = puzzle.candy
    velocity = puzzle.velocity
    threads = puzzle.anchors.map {
      Thread(anchor: $0, length: $0.distance(puzzle.candy))
    }
    bubbleActive = puzzle.startsInBubble
    bubbleAvailable = puzzle.bubble != nil
  }

  mutating func advance(_ delta: Double) {
    guard outcome == .playing else { return }
    remainder += min(max(delta, 0), 0.05)
    while remainder >= 1.0 / 120, outcome == .playing {
      step(1.0 / 120)
      remainder -= 1.0 / 120
    }
  }

  private mutating func step(_ dt: Double) {
    time += dt
    puffCooldown = max(0, puffCooldown - dt)
    velocity.y += (bubbleActive ? -145 : 600) * dt
    velocity = velocity * (bubbleActive ? 0.994 : 0.9996)
    let prior = position
    position = position + velocity * dt
    for _ in 0..<8 {
      for thread in threads where !thread.cut {
        let offset = position - thread.anchor
        let distance = offset.length
        if distance > thread.length {
          let normal = offset * (1 / distance)
          position = thread.anchor + normal * thread.length
          let outward = velocity.dot(normal)
          if outward > 0 { velocity = velocity - normal * outward }
        }
      }
    }
    for (index, star) in puzzle.stars.enumerated() where !collected.contains(index) {
      if Self.distance(star, toSegment: prior, position) < 29 {
        collected.insert(index)
      }
    }
    if let bubble = puzzle.bubble, bubbleAvailable, position.distance(bubble) < 30 {
      bubbleAvailable = false
      bubbleActive = true
      velocity = velocity * 0.35
    }
    for thorn in puzzle.thorns {
      let point = thorn.position(at: time)
      if abs(position.y - point.y) < 23,
        abs(position.x - point.x) < thorn.width / 2 + 10
      {
        outcome = .missed
      }
    }
    if outcome == .playing, position.distance(puzzle.goal) < 37 {
      outcome = .fed
    }
    if position.y > 590 || position.y < -55 || position.x < -45 || position.x > 405 {
      outcome = .missed
    }
  }

  @discardableResult
  mutating func cut(from start: V, to end: V) -> Int {
    guard outcome == .playing else { return 0 }
    var count = 0
    for index in threads.indices where !threads[index].cut {
      if Self.intersects(start, end, threads[index].anchor, position) {
        threads[index].cut = true
        cuts += 1
        count += 1
      }
    }
    return count
  }

  mutating func puff() {
    guard puzzle.puff, outcome == .playing, puffCooldown == 0 else { return }
    velocity = velocity + V(x: 125, y: -55)
    puffCooldown = 0.8
    puffs += 1
  }

  @discardableResult
  mutating func pop(at point: V) -> Bool {
    guard bubbleActive, outcome == .playing, position.distance(point) < 58 else { return false }
    bubbleActive = false
    velocity = velocity * 0.3
    return true
  }

  static func distance(_ point: V, toSegment a: V, _ b: V) -> Double {
    let segment = b - a
    let square = segment.dot(segment)
    if square < 0.001 { return point.distance(a) }
    let t = max(0, min(1, (point - a).dot(segment) / square))
    return point.distance(a + segment * t)
  }

  static func intersects(_ a: V, _ b: V, _ c: V, _ d: V) -> Bool {
    func cross(_ p: V, _ q: V) -> Double { p.x * q.y - p.y * q.x }
    let r = b - a
    let s = d - c
    let denominator = cross(r, s)
    if abs(denominator) < 0.00001 {
      return distance(a, toSegment: c, d) < 4 || distance(b, toSegment: c, d) < 4
    }
    let t = cross(c - a, s) / denominator
    let u = cross(c - a, r) / denominator
    return t >= 0 && t <= 1 && u >= 0 && u <= 1
  }
}

struct Progress: Codable, Equatable {
  var stars = Array(repeating: -1, count: Puzzle.all.count)
  var totalStars: Int { stars.reduce(0) { $0 + max(0, $1) } }
  var completed: Int { stars.filter { $0 >= 0 }.count }
  func unlocked(_ index: Int) -> Bool { index == 0 || stars[index - 1] >= 0 }
  mutating func record(level: Int, stars count: Int) {
    guard stars.indices.contains(level), (0...3).contains(count) else { return }
    stars[level] = max(stars[level], count)
  }
}
