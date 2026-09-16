import Foundation

enum FlightPhase: Equatable {
  case ready, playing, paused, finished
}

struct RiverGate: Equatable, Identifiable {
  let id: Int
  var x: Double
  let center: Double
  let gap: Double
  var passed = false

  var top: Double { center - gap / 2 }
  var bottom: Double { center + gap / 2 }
}

struct RiverRandom {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func unit() -> Double {
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    return Double(state >> 11) / Double(UInt64(1) << 53)
  }
}

struct GameModel {
  static let width = 390.0
  static let height = 844.0
  static let ceiling = 104.0
  static let waterline = 726.0
  static let playerX = 112.0
  static let radius = 21.0
  static let gateWidth = 72.0
  static let step = 1.0 / 120.0
  static let gravity = 1_030.0
  static let flapVelocity = -338.0
  static let spacing = 238.0

  private(set) var phase = FlightPhase.ready
  private(set) var y = 397.0
  private(set) var velocity = 0.0
  private(set) var score = 0
  private(set) var elapsed = 0.0
  private(set) var distance = 0.0
  private(set) var gates: [RiverGate] = []
  private var remainder = 0.0
  private var nextID = 0
  private var previousCenter = 397.0
  private var random: RiverRandom

  init(seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
    random = RiverRandom(seed: seed)
    appendGate(at: 460)
    appendGate(at: 460 + Self.spacing)
    appendGate(at: 460 + Self.spacing * 2)
  }

  var speed: Double { min(180, 143 + Double(score) * 1.25) }
  var gap: Double { max(188, 224 - Double(score) * 1.2) }
  var tilt: Double { min(65, max(-24, velocity * 0.1)) }

  mutating func flap() {
    guard phase == .ready || phase == .playing else { return }
    phase = .playing
    velocity = Self.flapVelocity
  }

  mutating func pause() {
    guard phase == .playing else { return }
    phase = .paused
    remainder = 0
  }

  mutating func resume() {
    guard phase == .paused else { return }
    phase = .playing
  }

  mutating func advance(_ delta: Double) {
    guard phase == .playing, delta.isFinite, delta > 0 else { return }
    remainder += min(delta, 0.1)
    while remainder + 0.000_000_001 >= Self.step && phase == .playing {
      remainder -= Self.step
      tick()
    }
  }

  private mutating func tick() {
    elapsed += Self.step
    velocity += Self.gravity * Self.step
    y += velocity * Self.step
    let movement = speed * Self.step
    distance += movement
    for index in gates.indices { gates[index].x -= movement }

    if y - Self.radius <= Self.ceiling || y + Self.radius >= Self.waterline {
      y = min(Self.waterline - Self.radius, max(Self.ceiling + Self.radius, y))
      phase = .finished
      return
    }
    for gate in gates where collides(with: gate) {
      phase = .finished
      return
    }
    for index in gates.indices {
      if !gates[index].passed
        && gates[index].x + Self.gateWidth < Self.playerX - Self.radius
      {
        gates[index].passed = true
        score += 1
      }
    }
    gates.removeAll { $0.x + Self.gateWidth < -30 }
    if let last = gates.last, last.x < Self.width {
      appendGate(at: last.x + Self.spacing)
    }
  }

  func collides(with gate: RiverGate) -> Bool {
    let nearestX = min(gate.x + Self.gateWidth, max(gate.x, Self.playerX))
    let dx = Self.playerX - nearestX
    let upperDY = max(0, y - gate.top)
    let lowerDY = max(0, gate.bottom - y)
    return dx * dx + upperDY * upperDY <= Self.radius * Self.radius
      || dx * dx + lowerDY * lowerDY <= Self.radius * Self.radius
  }

  private mutating func appendGate(at x: Double) {
    let proposed = previousCenter + (random.unit() - 0.5) * 156
    let center = min(526, max(290, proposed))
    gates.append(RiverGate(id: nextID, x: x, center: center, gap: gap))
    previousCenter = center
    nextID += 1
  }
}
