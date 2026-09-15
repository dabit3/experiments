import Foundation

enum RideMode: String, Codable, CaseIterable {
  case expedition
  case practice
}

enum RidePhase: Equatable {
  case riding
  case crashed
}

enum RideEvent: Equatable {
  case jump
  case coin
  case landing(Int)
  case crash
  case rescued
}

enum HazardKind: String {
  case rock
  case chasm
}

struct Hazard: Identifiable {
  let id: Int
  let x: Double
  let kind: HazardKind
  let width: Double
}

struct SnowCoin: Identifiable {
  let id: Int
  let x: Double
  let y: Double
}

struct RideSummary: Codable, Equatable {
  let distance: Int
  let score: Int
  let coins: Int
  let flips: Int
  let bestCombo: Int
  let mode: RideMode
}

struct RideEngine {
  static let gravity = 430.0
  static let jumpSpeed = 315.0
  static let flipSpeed = 5.8
  let mode: RideMode
  let seed: UInt64
  private(set) var phase = RidePhase.riding
  private(set) var x = 0.0
  private(set) var y = 0.0
  private(set) var velocityY = 0.0
  private(set) var speed = 163.0
  private(set) var rotation = 0.0
  private(set) var grounded = true
  private(set) var holding = false
  private(set) var airtime = 0.0
  private(set) var elapsed = 0.0
  private(set) var coins = 0
  private(set) var flips = 0
  private(set) var trickScore = 0
  private(set) var combo = 0
  private(set) var bestCombo = 0
  private(set) var comboTime = 0.0
  private(set) var crashReason = ""
  private(set) var event: RideEvent?
  private(set) var collected: Set<Int> = []
  private(set) var rescueTime = 0.0
  private var jumpRotation = 0.0
  private var accumulator = 0.0
  private var maxAirRotation = 0.0

  init(mode: RideMode = .expedition, seed: UInt64 = 1) {
    self.mode = mode
    self.seed = seed
    y = Self.height(at: 0)
    rotation = atan(Self.slope(at: 0))
  }

  var distance: Int { Int(x / 4) }
  var score: Int { distance + coins * 25 + trickScore }
  var summary: RideSummary {
    RideSummary(
      distance: distance, score: score, coins: coins, flips: flips,
      bestCombo: bestCombo, mode: mode
    )
  }

  static func height(at x: Double) -> Double {
    29 * sin(x / 290) + 18 * sin(x / 137) + 7 * sin(x / 73)
  }

  static func slope(at x: Double) -> Double {
    29 / 290 * cos(x / 290) + 18 / 137 * cos(x / 137) + 7 / 73 * cos(x / 73)
  }

  static func uprightDifference(rotation: Double, slope: Double) -> Double {
    let difference = rotation - atan(slope)
    return atan2(sin(difference), cos(difference))
  }

  static func isSafeLanding(rotation: Double, slope: Double) -> Bool {
    abs(uprightDifference(rotation: rotation, slope: slope)) < 0.80
  }

  func hazard(_ index: Int) -> Hazard {
    let hash = Self.hash(UInt64(max(0, index)) &+ seed)
    let spacing = 490.0
    let location = 760 + Double(index) * spacing + Double(hash % 65)
    let chasm = index > 1 && index % 3 == 2
    return Hazard(
      id: index, x: location, kind: chasm ? .chasm : .rock,
      width: chasm ? 105 + Double(hash % 28) : 29
    )
  }

  func hazards(from lower: Double, to upper: Double) -> [Hazard] {
    let start = max(0, Int((lower - 900) / 490))
    let end = max(start, Int((upper - 650) / 490) + 1)
    return (start...end).map(hazard).filter {
      $0.x + $0.width > lower && $0.x < upper
    }
  }

  var nextHazard: Hazard {
    let start = max(0, Int((x - 900) / 490))
    return (start...(start + 3)).map(hazard).first { $0.x + $0.width > x + 12 }
      ?? hazard(start + 4)
  }

  func snowCoins(from lower: Double, to upper: Double) -> [SnowCoin] {
    let first = max(0, Int((lower - 400) / 490))
    let last = max(first, Int(upper / 490) + 1)
    return (first...last).flatMap { cluster in
      (0..<5).map { offset in
        let coinX = 330 + Double(cluster) * 490 + Double(offset) * 31
        return SnowCoin(
          id: cluster * 5 + offset, x: coinX,
          y: Self.height(at: coinX) + 34 + sin(Double(offset) * .pi / 4) * 35
        )
      }
    }.filter { $0.x > lower && $0.x < upper && !collected.contains($0.id) }
  }

  mutating func press() {
    guard phase == .riding else { return }
    holding = true
    guard grounded else { return }
    grounded = false
    velocityY = Self.jumpSpeed + min(25, speed * Self.slope(at: x) * 0.25)
    airtime = 0
    maxAirRotation = 0
    jumpRotation = rotation
    event = .jump
  }

  mutating func release() {
    holding = false
  }

  mutating func advance(_ delta: Double) {
    guard phase == .riding else { return }
    event = nil
    accumulator += max(0, min(delta, 0.1))
    while accumulator >= 1.0 / 120, phase == .riding {
      tick(1.0 / 120)
      accumulator -= 1.0 / 120
    }
  }

  private mutating func tick(_ delta: Double) {
    elapsed += delta
    comboTime = max(0, comboTime - delta)
    rescueTime = max(0, rescueTime - delta)
    if comboTime == 0 { combo = 0 }
    let targetSpeed =
      (mode == .practice ? 145.0 : 163.0 + min(48, x / 500))
      - Self.slope(at: x) * 24
    speed += (targetSpeed - speed) * delta * 2
    x += speed * delta
    let floor = Self.height(at: x)
    let obstacles = hazards(from: x - 150, to: x + 35)
    let inChasm = obstacles.contains {
      $0.kind == .chasm && x > $0.x && x < $0.x + $0.width
    }
    if grounded && inChasm {
      grounded = false
      velocityY = 0
      airtime = 0
      jumpRotation = rotation
      maxAirRotation = 0
    }
    if grounded {
      y = floor
      rotation = atan(Self.slope(at: x))
    } else {
      airtime += delta
      velocityY -= Self.gravity * delta
      y += velocityY * delta
      if holding && airtime > 0.16 {
        rotation += Self.flipSpeed * delta
        maxAirRotation = max(maxAirRotation, rotation - jumpRotation)
      } else if !holding {
        let upright = Self.uprightDifference(
          rotation: rotation, slope: Self.slope(at: x)
        )
        if abs(upright) < 0.72 { rotation -= upright * min(1, delta * 12) }
      }
      if y <= floor && !inChasm && velocityY < 0 {
        if y < floor - 28 {
          fail("Lost in the ravine")
        } else if Self.isSafeLanding(rotation: rotation, slope: Self.slope(at: x)) {
          land(floor: floor)
        } else {
          fail("A little over-rotated")
        }
      }
    }
    for hazard in obstacles where hazard.kind == .rock {
      if x > hazard.x - 12 && x < hazard.x + hazard.width + 8
        && y < Self.height(at: hazard.x) + 27 && rescueTime == 0
      {
        fail("Found a hidden rock")
      }
    }
    if y < floor - 155 { fail("Lost in the ravine") }
    for coin in snowCoins(from: x - 24, to: x + 24) {
      if abs(y + 18 - coin.y) < 38 {
        collected.insert(coin.id)
        coins += 1
        if event == nil { event = .coin }
      }
    }
    if collected.count > 80 {
      collected = collected.filter { Double($0 / 5) * 490 + 500 > x - 500 }
    }
  }

  private mutating func land(floor: Double) {
    let completedFlips = max(0, Int((maxAirRotation + 0.65) / (2 * .pi)))
    if completedFlips > 0 {
      combo = comboTime > 0 ? min(5, combo + 1) : 1
      comboTime = 5.5
      bestCombo = max(bestCombo, combo)
      flips += completedFlips
      trickScore += completedFlips * 150 * combo
      event = .landing(completedFlips)
    }
    grounded = true
    holding = false
    rotation = atan(Self.slope(at: x))
    y = floor
    velocityY = 0
    airtime = 0
  }

  private mutating func fail(_ reason: String) {
    guard rescueTime == 0 else { return }
    holding = false
    combo = 0
    comboTime = 0
    if mode == .practice {
      rescueTime = 2
      let hazard = nextHazard
      if hazard.kind == .chasm && x > hazard.x - 15 {
        x = hazard.x + hazard.width + 20
      }
      y = Self.height(at: x) + 20
      velocityY = 50
      rotation = atan(Self.slope(at: x))
      grounded = false
      maxAirRotation = 0
      event = .rescued
    } else {
      phase = .crashed
      crashReason = reason
      event = .crash
    }
  }

  private static func hash(_ input: UInt64) -> UInt64 {
    var value = input &+ 0x9e37_79b9_7f4a_7c15
    value = (value ^ (value >> 30)) &* 0xbf58_476d_1ce4_e5b9
    value = (value ^ (value >> 27)) &* 0x94d0_49bb_1331_11eb
    return value ^ (value >> 31)
  }
}
