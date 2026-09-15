import Foundation

enum RunPhase: Equatable { case ready, running, paused, finished }
enum Move: String { case left, right, jump, slide }
enum ObstacleKind: String, CaseIterable { case barrier, sign, cart }
enum PickupKind { case coin, shield }

struct Obstacle: Identifiable {
  let id: Int
  let lane: Int
  let kind: ObstacleKind
  var distance: Double
  var resolved = false
}

struct Pickup: Identifiable {
  let id: Int
  let lane: Int
  let kind: PickupKind
  var distance: Double
  var collected = false
}

struct SeededRandom {
  var state: UInt64
  mutating func next(_ upper: Int) -> Int {
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    return Int((state >> 32) % UInt64(upper))
  }
}

struct RunSnapshot: Codable, Equatable {
  var bestDistance = 0
  var totalCoins = 0
  var runs = 0
}

struct RunnerEngine {
  private(set) var phase: RunPhase = .ready
  private(set) var distance = 0.0
  private(set) var coins = 0
  private(set) var lane = 1
  private(set) var lanePosition = 1.0
  private(set) var jumpTime = 0.0
  private(set) var slideTime = 0.0
  private(set) var shieldTime = 0.0
  private(set) var graceTime = 0.0
  private(set) var obstacles: [Obstacle] = []
  private(set) var pickups: [Pickup] = []
  private(set) var collision: ObstacleKind?
  private(set) var shieldsCollected = 0
  private(set) var obstaclesCleared = 0
  private var random: SeededRandom
  private var nextRow = 42.0
  private var rowIndex = 0
  private var nextID = 0

  static let jumpDuration = 1.05
  static let slideDuration = 1.15
  var speed: Double { min(23, 12 + distance / 220) }
  var jumpHeight: Double {
    guard jumpTime > 0 else { return 0 }
    return sin(.pi * (1 - jumpTime / Self.jumpDuration)) * 2.3
  }
  var isSliding: Bool { slideTime > 0 }
  var isShielded: Bool { shieldTime > 0 }
  var nearestObstacles: [Obstacle] {
    let ahead = obstacles.filter { !$0.resolved && $0.distance > 0 }
    guard let nearest = ahead.map(\.distance).min() else { return [] }
    return ahead.filter { abs($0.distance - nearest) < 0.1 }
  }
  var routeDescription: String {
    let names = ["left", "center", "right"]
    let row = nearestObstacles
    guard let first = row.first else { return "Lane \(names[lane]). Clear boardwalk." }
    let lanes = (0...2).map { lane in
      "\(names[lane]) \(row.first(where: { $0.lane == lane })?.kind.rawValue ?? "clear")"
    }.joined(separator: ", ")
    return "Lane \(names[lane]). Ahead \(Int(first.distance)) metres: \(lanes)."
  }

  init(seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
    random = SeededRandom(state: seed)
  }

  mutating func start() {
    guard phase == .ready else { return }
    phase = .running
    populate()
  }

  mutating func pause() {
    if phase == .running { phase = .paused }
  }

  mutating func resume() {
    if phase == .paused { phase = .running }
  }

  mutating func move(_ move: Move) {
    guard phase == .running else { return }
    switch move {
    case .left: lane = max(0, lane - 1)
    case .right: lane = min(2, lane + 1)
    case .jump:
      if jumpTime == 0 {
        jumpTime = Self.jumpDuration
        slideTime = 0
      }
    case .slide:
      if jumpTime == 0 { slideTime = Self.slideDuration }
    }
  }

  mutating func advance(_ elapsed: Double) {
    guard phase == .running, elapsed.isFinite, elapsed > 0 else { return }
    var remaining = min(elapsed, 0.1)
    while remaining > 0, phase == .running {
      let delta = min(remaining, 1.0 / 120)
      step(delta)
      remaining -= delta
    }
  }

  private mutating func step(_ delta: Double) {
    let travel = speed * delta
    distance += travel
    lanePosition += (Double(lane) - lanePosition) * min(1, delta * 14)
    jumpTime = max(0, jumpTime - delta)
    slideTime = max(0, slideTime - delta)
    shieldTime = max(0, shieldTime - delta)
    graceTime = max(0, graceTime - delta)
    for index in pickups.indices {
      pickups[index].distance -= travel
      if !pickups[index].collected, abs(pickups[index].distance) < 0.9,
        abs(Double(pickups[index].lane) - lanePosition) < 0.4
      {
        pickups[index].collected = true
        if pickups[index].kind == .coin {
          coins += 1
        } else {
          shieldTime = 10
          shieldsCollected += 1
        }
      }
    }
    for index in obstacles.indices {
      obstacles[index].distance -= travel
      guard !obstacles[index].resolved, obstacles[index].distance <= 0.35 else { continue }
      obstacles[index].resolved = true
      let obstacle = obstacles[index]
      let inLane = abs(Double(obstacle.lane) - lanePosition) < 0.63
      let cleared = !inLane || Self.clears(obstacle.kind, height: jumpHeight, sliding: isSliding)
      if cleared {
        obstaclesCleared += 1
      } else if isShielded || graceTime > 0 {
        shieldTime = 0
        graceTime = 0.8
      } else {
        collision = obstacle.kind
        phase = .finished
      }
    }
    obstacles.removeAll { $0.distance < -12 }
    pickups.removeAll { $0.distance < -12 || $0.collected }
    populate()
  }

  static func clears(_ kind: ObstacleKind, height: Double, sliding: Bool) -> Bool {
    switch kind {
    case .barrier: return height > 0.75
    case .sign: return sliding
    case .cart: return false
    }
  }

  private mutating func populate() {
    while nextRow < distance + 115 {
      let relative = nextRow - distance
      if rowIndex == 0 {
        addObstacle(lane: 1, kind: .barrier, distance: relative)
        addCoins(lane: 1, distance: relative - 6)
      } else if rowIndex == 1 {
        addObstacle(lane: 1, kind: .sign, distance: relative)
        addCoins(lane: 1, distance: relative - 6)
      } else if rowIndex == 2 {
        addPickup(lane: 1, kind: .shield, distance: relative)
        addCoins(lane: 1, distance: relative - 7)
      } else {
        let safeLane = random.next(3)
        for lane in 0...2 where lane != safeLane {
          if random.next(4) != 0 {
            let kind = ObstacleKind.allCases[random.next(3)]
            addObstacle(lane: lane, kind: kind, distance: relative)
          }
        }
        addCoins(lane: safeLane, distance: relative - 5)
        if rowIndex % 6 == 2 {
          addPickup(lane: safeLane, kind: .shield, distance: relative + 7)
        }
      }
      rowIndex += 1
      nextRow += 32 + Double(random.next(9))
    }
  }

  private mutating func addObstacle(lane: Int, kind: ObstacleKind, distance: Double) {
    nextID += 1
    obstacles.append(Obstacle(id: nextID, lane: lane, kind: kind, distance: distance))
  }

  private mutating func addPickup(lane: Int, kind: PickupKind, distance: Double) {
    nextID += 1
    pickups.append(Pickup(id: nextID, lane: lane, kind: kind, distance: distance))
  }

  private mutating func addCoins(lane: Int, distance: Double) {
    for offset in 0..<4 {
      addPickup(lane: lane, kind: .coin, distance: distance - Double(offset) * 2.5)
    }
  }
}
