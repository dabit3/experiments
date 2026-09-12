import Foundation

enum Seed: String, CaseIterable, Codable, Sendable {
  case marigold, peashooter, bramble, ember, frost

  var name: String {
    switch self {
    case .marigold: "Sunbell"
    case .peashooter: "Peapiper"
    case .bramble: "Bramble"
    case .ember: "Emberbud"
    case .frost: "Frostbell"
    }
  }
  var detail: String {
    switch self {
    case .marigold: "Grows 25 sunshine"
    case .peashooter: "Steady lane shots"
    case .bramble: "A sturdy shield"
    case .ember: "Bursts after 1.5s"
    case .frost: "Slows clockworks"
    }
  }
  var cost: Int {
    switch self {
    case .marigold: 50
    case .peashooter: 100
    case .bramble: 75
    case .ember: 125
    case .frost: 125
    }
  }
  var cooldown: Double {
    switch self {
    case .marigold: 4
    case .peashooter: 2
    case .bramble: 6
    case .ember: 12
    case .frost: 4
    }
  }
  var health: Double { self == .bramble ? 650 : 140 }
}

enum PestKind: Int, Sendable {
  case beetle, skitter, kettle
  var health: Double {
    switch self {
    case .beetle: 105
    case .skitter: 70
    case .kettle: 300
    }
  }
  var speed: Double {
    switch self {
    case .beetle: 0.15
    case .skitter: 0.25
    case .kettle: 0.105
    }
  }
  var points: Int { self == .kettle ? 90 : (self == .skitter ? 35 : 25) }
}

struct Defender: Identifiable, Sendable {
  let id: Int
  let seed: Seed
  let lane: Int
  let column: Int
  var health: Double
  var timer: Double = 0
}
struct Pest: Identifiable, Sendable {
  let id: Int
  let kind: PestKind
  let lane: Int
  var x: Double = 7.4
  var health: Double
  var slow: Double = 0
  var bite: Double = 0
}
struct Shot: Identifiable, Sendable {
  let id: Int
  let lane: Int
  var x: Double
  let icy: Bool
}
struct Sunshine: Identifiable, Sendable {
  let id: Int
  let lane: Int
  let x: Double
  var lifetime: Double = 14
  let amount: Int
}
struct Burst: Identifiable, Sendable {
  let id: Int
  let lane: Int
  let x: Double
  var life: Double = 0.65
  let fiery: Bool
}
struct Spawn: Sendable {
  let time: Double
  let lane: Int
  let kind: PestKind
}

enum GardenPhase: Sendable { case playing, paused, won, lost }

struct Chapter: Sendable {
  let title: String
  let subtitle: String
  let lesson: String
  static let all: [Chapter] = [
    Chapter(
      title: "Morning light", subtitle: "THE COTTAGE",
      lesson: "Sunbells build your economy. Cover all five lanes."),
    Chapter(
      title: "Copper parade", subtitle: "THE ORCHARD",
      lesson: "Quick skitters arrive. Brambles buy you time."),
    Chapter(
      title: "Kettle trouble", subtitle: "THE GREENHOUSE",
      lesson: "Armored kettles are tough. Frostbells slow them down."),
    Chapter(
      title: "Moonlit siege", subtitle: "THE OLD GATE",
      lesson: "Mix your defenders. Emberbuds clear nearby crowds."),
  ]
}

struct Garden: Sendable {
  static let columns = 7
  static let lanes = 5
  var level: Int
  var endless: Bool
  var phase: GardenPhase = .playing
  var sunshine = 250
  var score = 0
  var wave = 1
  var wavesCleared = 0
  var elapsed = 0.0
  var waveTime = 0.0
  var nextWave = 0.0
  var skyTime = 2.0
  var plants: [Defender] = []
  var pests: [Pest] = []
  var shots: [Shot] = []
  var drops: [Sunshine] = []
  var bursts: [Burst] = []
  var cooldowns: [Seed: Double] = [:]
  var schedule: [Spawn] = []
  var rescuers: Set<Int> = Set(0..<5)
  var notice = "Plant Sunbells, then Peapipers in every lane."
  var noticeTime = 6.0
  private var serial = 0
  private var seed: Int

  init(level: Int = 0, endless: Bool = false, seed: Int = Int.random(in: 0..<1000)) {
    self.level = min(3, max(0, level))
    self.endless = endless
    self.seed = seed
    scheduleWave()
  }

  mutating func nextID() -> Int {
    serial += 1
    return serial
  }
  var title: String { endless ? "The wild garden" : Chapter.all[level].title }
  var finished: Bool { phase == .won || phase == .lost }
  var waveLabel: String { endless ? "WAVE \(wave)" : "WAVE \(wave) / 3" }

  func unavailable(_ type: Seed, lane: Int, column: Int) -> String? {
    if phase != .playing { return "Resume your garden first." }
    if !(0..<5).contains(lane) || !(0..<7).contains(column) { return "Plant inside the garden." }
    if plants.contains(where: { $0.lane == lane && $0.column == column }) {
      return "This plot is planted. Use the shovel to clear it."
    }
    if sunshine < type.cost {
      return "Need \(type.cost - sunshine) more sunshine for \(type.name)."
    }
    if (cooldowns[type] ?? 0) > 0 {
      return "\(type.name) is resting for \(Int(ceil(cooldowns[type] ?? 0)))s."
    }
    return nil
  }

  @discardableResult
  mutating func plant(_ type: Seed, lane: Int, column: Int) -> Bool {
    if let reason = unavailable(type, lane: lane, column: column) {
      notify(reason)
      return false
    }
    sunshine -= type.cost
    cooldowns[type] = type.cooldown
    plants.append(
      Defender(id: nextID(), seed: type, lane: lane, column: column, health: type.health))
    return true
  }

  mutating func remove(lane: Int, column: Int) {
    guard phase == .playing else { return }
    guard let index = plants.firstIndex(where: { $0.lane == lane && $0.column == column }) else {
      notify("Choose a planted plot to compost it.")
      return
    }
    let refund = plants[index].seed.cost / 2
    sunshine += refund
    plants.remove(at: index)
    notify("Composted · \(refund) sunshine returned")
  }

  mutating func collect(_ id: Int? = nil) {
    guard phase == .playing else { return }
    let gathered = drops.filter { id == nil || $0.id == id }
    sunshine += gathered.reduce(0) { $0 + $1.amount }
    drops.removeAll { id == nil || $0.id == id }
  }

  mutating func notify(_ text: String) {
    notice = text
    noticeTime = 4
  }
  mutating func togglePause() {
    if phase == .playing { phase = .paused } else if phase == .paused { phase = .playing }
  }

  mutating func scheduleWave() {
    waveTime = 0
    let intensity = endless ? min(wave - 1, 18) : level * 2 + wave - 1
    let count = 5 + min(10, intensity)
    let spacing = max(1.8, 5.3 - Double(intensity) * 0.28)
    let lead = wave == 1 ? 17.0 : 7.0
    schedule = (0..<count).map { index in
      let lane = (index * 3 + seed + wave) % 5
      let kind: PestKind
      if intensity >= 4 && index % 4 == 3 {
        kind = .kettle
      } else if intensity >= 2 && index % 3 == 2 {
        kind = .skitter
      } else {
        kind = .beetle
      }
      return Spawn(time: lead + Double(index) * spacing, lane: lane, kind: kind)
    }
  }

  mutating func tick(_ delta: Double) {
    guard phase == .playing, delta > 0 else { return }
    let dt = min(delta, 0.1)
    elapsed += dt
    waveTime += dt
    noticeTime = max(0, noticeTime - dt)
    for type in Seed.allCases { cooldowns[type] = max(0, (cooldowns[type] ?? 0) - dt) }
    skyTime -= dt
    if skyTime <= 0 {
      skyTime = 6.5
      drops.append(
        Sunshine(
          id: nextID(), lane: (serial + seed) % 5, x: Double((serial * 3) % 6) + 0.45, amount: 50))
    }
    for index in drops.indices { drops[index].lifetime -= dt }
    drops.removeAll { $0.lifetime <= 0 }
    for index in bursts.indices { bursts[index].life -= dt }
    bursts.removeAll { $0.life <= 0 }
    while let spawn = schedule.first, spawn.time <= waveTime {
      schedule.removeFirst()
      pests.append(
        Pest(id: nextID(), kind: spawn.kind, lane: spawn.lane, health: spawn.kind.health))
    }

    for index in plants.indices {
      plants[index].timer += dt
      let plant = plants[index]
      switch plant.seed {
      case .marigold:
        if plant.timer >= 10 {
          plants[index].timer = 0
          drops.append(
            Sunshine(id: nextID(), lane: plant.lane, x: Double(plant.column) + 0.6, amount: 25))
        }
      case .peashooter, .frost:
        let interval = plant.seed == .frost ? 2.2 : 1.4
        if plant.timer >= interval
          && pests.contains(where: { $0.lane == plant.lane && $0.x > Double(plant.column) })
        {
          plants[index].timer = 0
          shots.append(
            Shot(
              id: nextID(), lane: plant.lane, x: Double(plant.column) + 0.85,
              icy: plant.seed == .frost))
        }
      case .ember:
        if plant.timer >= 1.5 {
          for enemy in pests.indices
          where abs(pests[enemy].lane - plant.lane) <= 1
            && abs(pests[enemy].x - Double(plant.column) - 0.5) < 2
          {
            pests[enemy].health -= 360
          }
          bursts.append(
            Burst(id: nextID(), lane: plant.lane, x: Double(plant.column) + 0.5, fiery: true))
          plants[index].health = 0
        }
      case .bramble: break
      }
    }
    for index in shots.indices {
      let oldX = shots[index].x
      shots[index].x += dt * 5.5
      let shot = shots[index]
      if let target = pests.indices.filter({
        pests[$0].health > 0 && pests[$0].lane == shot.lane && pests[$0].x >= oldX - 0.35
          && pests[$0].x <= shot.x + 0.3
      }).min(by: { pests[$0].x < pests[$1].x }) {
        pests[target].health -= shot.icy ? 20 : 30
        if shot.icy { pests[target].slow = 3.5 }
        shots[index].x = 100
        bursts.append(Burst(id: nextID(), lane: shot.lane, x: pests[target].x, fiery: false))
      }
    }
    shots.removeAll { $0.x > 8 }
    for index in pests.indices where pests[index].health > 0 {
      pests[index].slow = max(0, pests[index].slow - dt)
      let pest = pests[index]
      if let victim = plants.indices.filter({
        plants[$0].health > 0 && plants[$0].lane == pest.lane
          && pest.x - Double(plants[$0].column) - 0.5 < 0.55 && pest.x >= Double(plants[$0].column)
      }).max(by: { plants[$0].column < plants[$1].column }) {
        plants[victim].health -= dt * (pest.kind == .kettle ? 38 : 26)
        pests[index].bite += dt
      } else {
        pests[index].x -= dt * pest.kind.speed * (pest.slow > 0 ? 0.45 : 1)
      }
      if pests[index].x < -0.1 {
        if rescuers.contains(pest.lane) {
          rescuers.remove(pest.lane)
          for other in pests.indices where pests[other].lane == pest.lane {
            pests[other].health = 0
          }
          notify("Lane \(pest.lane + 1)'s last-chance robin swept the pests away!")
        } else {
          phase = .lost
        }
      }
    }
    for pest in pests where pest.health <= 0 { score += pest.kind.points }
    pests.removeAll { $0.health <= 0 }
    plants.removeAll { $0.health <= 0 }
    guard phase == .playing else { return }
    if schedule.isEmpty && pests.isEmpty {
      if nextWave == 0 {
        wavesCleared += 1
        score += 100 + rescuers.count * 20
        if !endless && wave >= 3 {
          phase = .won
          return
        }
        nextWave = 5
        sunshine += 75
        notify("Wave secured! +75 sunshine · a moment to replant")
      } else {
        nextWave -= dt
        if nextWave <= 0 {
          nextWave = 0
          wave += 1
          scheduleWave()
        }
      }
    }
  }
}
