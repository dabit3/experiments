import Foundation

enum Course: Int, CaseIterable, Identifiable, Codable {
  case riviera, headland, sunset

  var id: Int { rawValue }
  var title: String {
    switch self {
    case .riviera: "Riviera Run"
    case .headland: "Headland Club"
    case .sunset: "Golden Hour"
    }
  }
  var subtitle: String {
    switch self {
    case .riviera: "THE COASTAL CLASSIC"
    case .headland: "THE WINDING ASCENT"
    case .sunset: "THE LAST LIGHT"
    }
  }
  var length: Double { [620, 780, 900][rawValue] }
  var rivalPace: Double { [13.3, 13.7, 14.0][rawValue] }
  var curveAmount: Double { [0.6, 1.0, 0.8][rawValue] }
  var obstacles: [RoadObstacle] {
    let positions: [Double] =
      switch self {
      case .riviera: [150, 315, 455]
      case .headland: [130, 270, 400, 535, 665]
      case .sunset: [165, 320, 460, 595, 720, 810]
      }
    return positions.enumerated().map {
      RoadObstacle(id: $0.offset, distance: $0.element, lane: ($0.offset + rawValue) % 3)
    }
  }
}

struct RoadObstacle: Identifiable {
  let id: Int
  let distance: Double
  let lane: Int
}

struct Rival: Identifiable {
  let id: Int
  var distance: Double
  var lane: Int
  let pace: Double
  var finishTime: Double?
}

struct RaceResult: Codable, Equatable {
  let course: Course
  let time: Double
  let rank: Int
  let gap: Double
  let draftSeconds: Double
  let attacks: Int
  let collisions: Int

  var timeLabel: String {
    String(format: "%02d:%05.2f", Int(time) / 60, time.truncatingRemainder(dividingBy: 60))
  }
  var gapLabel: String { String(format: "%+.2fs", gap) }
  var headline: String {
    switch rank {
    case 1: "Coast to glory."
    case 2: "A wheel away."
    case 3: "On the podium."
    default: "One more ride."
    }
  }
}

struct RaceState {
  let course: Course
  var distance: Double = 0
  var elapsed: Double = 0
  var energy: Double = 100
  var lane = 1
  var speed: Double = 12.5
  var sprintHeld = false
  var isSprinting = false
  var exhausted = false
  var draftSeconds: Double = 0
  var draftCharge: Double = 0
  var attackRemaining: Double = 0
  var attacks = 0
  var collisionRemaining: Double = 0
  var collisions = 0
  var passedObstacles: Set<Int> = []
  var rivals: [Rival]
  var result: RaceResult?

  init(course: Course) {
    self.course = course
    rivals = [
      Rival(id: 0, distance: 16, lane: 1, pace: course.rivalPace),
      Rival(id: 1, distance: 30, lane: 0, pace: course.rivalPace - 0.25),
      Rival(id: 2, distance: 44, lane: 2, pace: course.rivalPace - 0.45),
    ]
  }

  var drafting: Bool {
    !isSprinting && collisionRemaining <= 0
      && rivals.contains {
        $0.lane == lane && (4...42).contains($0.distance - distance)
      }
  }
  var attackReady: Bool { draftCharge >= 1.8 }
  var rank: Int { 1 + rivals.filter { $0.distance > distance }.count }
  var progress: Double { min(1, distance / course.length) }
  var remaining: Int { max(0, Int(ceil(course.length - distance))) }
  var curve: Double { sin(distance / 65) * course.curveAmount }
  var insideLane: Int { curve > 0 ? 2 : 0 }
  var isBend: Bool { abs(curve) > 0.52 }

  mutating func move(to newLane: Int) {
    guard result == nil, (0...2).contains(newLane), newLane != lane else { return }
    if attackReady {
      attackRemaining = 2.6
      attacks += 1
    }
    lane = newLane
    draftCharge = 0
  }

  mutating func step(_ delta: Double) {
    guard result == nil, delta > 0 else { return }
    let dt = min(delta, 0.1)
    let oldTime = elapsed
    let oldDistance = distance
    elapsed += dt
    attackRemaining = max(0, attackRemaining - dt)
    collisionRemaining = max(0, collisionRemaining - dt)
    if exhausted && energy >= 28 { exhausted = false }
    isSprinting = sprintHeld && !exhausted && energy > 0 && collisionRemaining == 0
    let inDraft = drafting
    if inDraft {
      draftSeconds += dt
      draftCharge = min(2, draftCharge + dt)
    } else {
      draftCharge = max(0, draftCharge - dt * 0.45)
    }
    energy = min(100, max(0, energy + dt * (isSprinting ? -18 : (inDraft ? 14 : 7))))
    if energy == 0 {
      exhausted = true
      isSprinting = false
    }
    speed = isSprinting ? 19.6 : (inDraft ? 13.7 : 12.5)
    if attackRemaining > 0 { speed += 4.3 }
    if isBend { speed += lane == insideLane ? 0.7 : -0.35 }
    if collisionRemaining > 0 { speed = 6.2 }
    distance += speed * dt
    for obstacle in course.obstacles where !passedObstacles.contains(obstacle.id) {
      if distance >= obstacle.distance {
        passedObstacles.insert(obstacle.id)
        if lane == obstacle.lane {
          collisions += 1
          collisionRemaining = 1.7
          energy = max(0, energy - 12)
          attackRemaining = 0
          draftCharge = 0
        }
      }
    }
    for index in rivals.indices {
      let previous = rivals[index].distance
      rivals[index].distance += rivals[index].pace * dt
      if let hazard = course.obstacles.first(where: {
        $0.lane == rivals[index].lane && (0...27).contains($0.distance - rivals[index].distance)
      }) {
        rivals[index].lane = (hazard.lane + 1 + index % 2) % 3
      }
      if previous < course.length && rivals[index].distance >= course.length {
        rivals[index].finishTime = oldTime + (course.length - previous) / rivals[index].pace
      }
    }
    if distance >= course.length {
      let time = oldTime + (course.length - oldDistance) / speed
      let finishes = rivals.map {
        $0.finishTime ?? (elapsed + (course.length - $0.distance) / $0.pace)
      }.sorted()
      let place = 1 + finishes.filter { $0 < time }.count
      let comparison = finishes[0]
      result = RaceResult(
        course: course, time: time, rank: place, gap: time - comparison,
        draftSeconds: draftSeconds, attacks: attacks, collisions: collisions
      )
      distance = course.length
      sprintHeld = false
    }
  }
}
