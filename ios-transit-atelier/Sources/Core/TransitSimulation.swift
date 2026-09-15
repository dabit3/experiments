import Foundation

enum StationKind: Int, Codable, CaseIterable, Sendable {
  case circle, triangle, square, diamond

  var name: String {
    ["circle", "triangle", "square", "diamond"][rawValue]
  }
}

struct MapPoint: Codable, Equatable, Sendable {
  var x: Double
  var y: Double

  func distance(to other: MapPoint) -> Double {
    hypot(x - other.x, y - other.y)
  }
}

enum City: String, CaseIterable, Codable, Sendable {
  case harbour, estuary

  var title: String { self == .harbour ? "Pearl Harbour" : "Saffron Estuary" }
  var subtitle: String {
    self == .harbour ? "A city between two shores." : "One river. A thousand possibilities."
  }
  var number: String { self == .harbour ? "01" : "02" }
  var stations: [MapPoint] {
    switch self {
    case .harbour:
      [
        .init(x: 0.20, y: 0.24), .init(x: 0.37, y: 0.48),
        .init(x: 0.73, y: 0.35), .init(x: 0.78, y: 0.67),
        .init(x: 0.21, y: 0.73), .init(x: 0.54, y: 0.16),
        .init(x: 0.57, y: 0.83), .init(x: 0.85, y: 0.17),
        .init(x: 0.14, y: 0.46), .init(x: 0.57, y: 0.58),
        .init(x: 0.37, y: 0.89), .init(x: 0.88, y: 0.87),
      ]
    case .estuary:
      [
        .init(x: 0.18, y: 0.19), .init(x: 0.36, y: 0.41),
        .init(x: 0.74, y: 0.26), .init(x: 0.69, y: 0.67),
        .init(x: 0.18, y: 0.70), .init(x: 0.50, y: 0.15),
        .init(x: 0.40, y: 0.84), .init(x: 0.85, y: 0.47),
        .init(x: 0.14, y: 0.44), .init(x: 0.50, y: 0.60),
        .init(x: 0.85, y: 0.85), .init(x: 0.75, y: 0.10),
      ]
    }
  }

  func riverX(at y: Double) -> Double {
    self == .harbour ? 0.54 + 0.085 * sin(y * 7) : 0.55 + 0.12 * sin(y * 8 + 1.5)
  }

  func crossesRiver(_ a: MapPoint, _ b: MapPoint) -> Bool {
    let side = a.x - riverX(at: a.y)
    for step in 1...40 {
      let fraction = Double(step) / 40
      let point = MapPoint(x: a.x + (b.x - a.x) * fraction, y: a.y + (b.y - a.y) * fraction)
      if (point.x - riverX(at: point.y)) * side < 0 { return true }
    }
    return false
  }
}

struct Station: Identifiable, Codable, Sendable {
  let id: Int
  let point: MapPoint
  let kind: StationKind
  var waiting: [StationKind] = []
  var pressure: Double = 0
  var arrivalGlow: Double = 0
}

struct Route: Identifiable, Codable, Sendable {
  let id: Int
  var stops: [Int] = []
  var capacity = 6
}

struct Train: Identifiable, Codable, Sendable {
  let id: Int
  let route: Int
  var stopIndex = 0
  var direction = 1
  var progress: Double = 0
  var dwell: Double = 0.5
  var passengers: [StationKind] = []
}

struct SeededGenerator: RandomNumberGenerator, Codable, Sendable {
  var state: UInt64

  mutating func next() -> UInt64 {
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    return state
  }
}

enum Upgrade: String, CaseIterable, Sendable {
  case carriage, tunnel, line

  var title: String {
    switch self {
    case .carriage: "Longer trains"
    case .tunnel: "River works"
    case .line: "New route"
    }
  }
  var detail: String {
    switch self {
    case .carriage: "+3 seats on every train"
    case .tunnel: "+2 tunnel crossings"
    case .line: "+1 line & locomotive"
    }
  }
  var symbol: String {
    switch self {
    case .carriage: "tram.fill"
    case .tunnel: "water.waves"
    case .line: "point.topleft.down.to.point.bottomright.curvepath"
    }
  }
}

struct TransitSimulation: Codable, Sendable {
  static let duration: Double = 300
  static let crowdLimit = 12
  static let overloadDuration: Double = 24
  var city: City
  var stations: [Station]
  var routes: [Route] = [Route(id: 0), Route(id: 1)]
  var trains: [Train] = []
  var tunnels = 3
  var elapsed: Double = 0
  var delivered = 0
  var generated = 0
  var isOver = false
  var completed = false
  var upgradePending = false
  var notice = "Select a line, then connect the station shapes."
  private var nextSpawn: Double = 28
  private var nextPassenger: Double = 3
  private var nextUpgrade: Double = 50
  private var random: SeededGenerator

  init(city: City, seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
    self.city = city
    random = SeededGenerator(state: seed)
    stations = (0..<4).map { index in
      Station(id: index, point: city.stations[index], kind: Self.kind(for: index))
    }
  }

  static func kind(for index: Int) -> StationKind {
    let sequence: [StationKind] = [
      .circle, .triangle, .square, .circle, .square, .triangle,
      .diamond, .square, .triangle, .circle, .diamond, .triangle,
    ]
    return sequence[index % sequence.count]
  }

  var usedTunnels: Int { tunnelCount(routes) }
  var waitingCount: Int { stations.reduce(0) { $0 + $1.waiting.count } }
  var aboardCount: Int { trains.reduce(0) { $0 + $1.passengers.count } }
  var canAddLine: Bool { routes.count < 4 }
  var failedStation: Station? {
    guard isOver, !completed else { return nil }
    return stations.first { $0.pressure >= Self.overloadDuration }
  }

  func tunnelCount(_ proposed: [Route]) -> Int {
    proposed.reduce(0) { count, route in
      count
        + zip(route.stops, route.stops.dropFirst()).filter { a, b in
          city.crossesRiver(stations[a].point, stations[b].point)
        }.count
    }
  }

  @discardableResult
  mutating func setRoute(_ routeID: Int, stops: [Int]) -> Bool {
    guard routes.indices.contains(routeID), !isOver,
      stops.allSatisfy({ stations.indices.contains($0) }),
      Set(stops).count == stops.count
    else { return false }
    var proposed = routes
    proposed[routeID].stops = stops
    guard tunnelCount(proposed) <= tunnels else {
      notice = "No tunnels left. Choose River works at the next upgrade."
      return false
    }
    for train in trains where train.route == routeID {
      let oldRoute = routes[routeID]
      if oldRoute.stops.indices.contains(train.stopIndex) {
        let station = oldRoute.stops[train.stopIndex]
        stations[station].waiting += train.passengers
      }
    }
    trains.removeAll { $0.route == routeID }
    routes = proposed
    if stops.count > 1 {
      trains.append(Train(id: routeID, route: routeID))
      notice = "Line \(routeID + 1) is running. Match passengers to station shapes."
    }
    return true
  }

  @discardableResult
  mutating func append(_ station: Int, to route: Int) -> Bool {
    guard routes.indices.contains(route) else { return false }
    let stops = routes[route].stops
    if stops.last == station { return true }
    guard !stops.contains(station) else {
      notice = "Already on this line. Undo the last stop or redraw it."
      return false
    }
    return setRoute(route, stops: stops + [station])
  }

  mutating func choose(_ upgrade: Upgrade) {
    guard upgradePending else { return }
    switch upgrade {
    case .carriage:
      for index in routes.indices { routes[index].capacity += 3 }
    case .tunnel: tunnels += 2
    case .line:
      guard canAddLine else { return }
      routes.append(Route(id: routes.count, capacity: routes[0].capacity))
    }
    upgradePending = false
    notice = "\(upgrade.title) ready. Your city is moving."
  }

  func distance(from start: Int, to kind: StationKind) -> Int? {
    if stations[start].kind == kind { return 0 }
    var visited: Set<Int> = [start]
    var queue: [(Int, Int)] = [(start, 0)]
    var cursor = 0
    while cursor < queue.count {
      let (station, distance) = queue[cursor]
      cursor += 1
      for route in routes {
        for (a, b) in zip(route.stops, route.stops.dropFirst()) {
          let neighbor = a == station ? b : (b == station ? a : -1)
          guard neighbor >= 0, !visited.contains(neighbor) else { continue }
          if stations[neighbor].kind == kind { return distance + 1 }
          visited.insert(neighbor)
          queue.append((neighbor, distance + 1))
        }
      }
    }
    return nil
  }

  mutating func tick(_ delta: Double) {
    guard !isOver, !upgradePending, delta > 0 else { return }
    var remaining = min(delta, 2)
    while remaining > 0.0001, !isOver, !upgradePending {
      let step = min(remaining, 0.05)
      advance(step)
      remaining -= step
    }
  }

  private mutating func advance(_ delta: Double) {
    elapsed += delta
    if elapsed >= Self.duration {
      elapsed = Self.duration
      isOver = true
      completed = true
      return
    }
    if elapsed >= nextSpawn, stations.count < city.stations.count {
      let id = stations.count
      stations.append(Station(id: id, point: city.stations[id], kind: Self.kind(for: id)))
      nextSpawn += 28
      notice = "New \(Self.kind(for: id).name) station. Extend a line to welcome it."
    }
    if elapsed >= nextUpgrade {
      nextUpgrade += 50
      upgradePending = true
      return
    }
    if elapsed >= nextPassenger {
      nextPassenger += max(0.8, 2.4 - elapsed / 220)
      let index = Int(random.next() >> 32) % stations.count
      let choices = StationKind.allCases.filter { kind in
        kind != stations[index].kind && stations.contains { $0.kind == kind }
      }
      if !choices.isEmpty {
        let kind = choices[Int(random.next() >> 32) % choices.count]
        stations[index].waiting.append(kind)
        generated += 1
      }
    }
    for index in trains.indices { moveTrain(index, delta: delta) }
    for index in stations.indices {
      stations[index].arrivalGlow = max(0, stations[index].arrivalGlow - delta)
      if stations[index].waiting.count >= Self.crowdLimit {
        stations[index].pressure += delta
      } else {
        stations[index].pressure = max(0, stations[index].pressure - delta * 2)
      }
      if stations[index].pressure >= Self.overloadDuration {
        isOver = true
        notice = "A station became overcrowded."
      }
    }
  }

  private mutating func moveTrain(_ index: Int, delta: Double) {
    let route = routes[trains[index].route]
    guard route.stops.count > 1 else { return }
    if trains[index].dwell > 0 {
      trains[index].dwell -= delta
      if trains[index].dwell <= 0 { exchangePassengers(index) }
      return
    }
    let current = route.stops[trains[index].stopIndex]
    let nextIndex = trains[index].stopIndex + trains[index].direction
    guard route.stops.indices.contains(nextIndex) else { return }
    let next = route.stops[nextIndex]
    let distance = stations[current].point.distance(to: stations[next].point)
    trains[index].progress += delta * 0.105 / max(distance, 0.05)
    if trains[index].progress >= 1 {
      trains[index].stopIndex = nextIndex
      trains[index].progress = 0
      trains[index].dwell = 0.65
      if nextIndex == route.stops.count - 1 { trains[index].direction = -1 }
      if nextIndex == 0 { trains[index].direction = 1 }
    }
  }

  private mutating func exchangePassengers(_ index: Int) {
    let route = routes[trains[index].route]
    let stop = route.stops[trains[index].stopIndex]
    let next = route.stops[trains[index].stopIndex + trains[index].direction]
    let arrived = trains[index].passengers.filter { $0 == stations[stop].kind }.count
    delivered += arrived
    if arrived > 0 { stations[stop].arrivalGlow = 1.2 }
    var staying: [StationKind] = []
    for kind in trains[index].passengers where kind != stations[stop].kind {
      let here = distance(from: stop, to: kind) ?? Int.max
      let there = distance(from: next, to: kind) ?? Int.max
      if there < here {
        staying.append(kind)
      } else {
        stations[stop].waiting.append(kind)
      }
    }
    trains[index].passengers = staying
    var waiting: [StationKind] = []
    for kind in stations[stop].waiting {
      let here = distance(from: stop, to: kind) ?? Int.max
      let there = distance(from: next, to: kind) ?? Int.max
      if there < here, trains[index].passengers.count < route.capacity {
        trains[index].passengers.append(kind)
      } else {
        waiting.append(kind)
      }
    }
    stations[stop].waiting = waiting
  }

  func trainPosition(_ train: Train) -> MapPoint {
    let route = routes[train.route]
    let current = stations[route.stops[train.stopIndex]].point
    let nextIndex = train.stopIndex + train.direction
    guard route.stops.indices.contains(nextIndex) else { return current }
    let next = stations[route.stops[nextIndex]].point
    return MapPoint(
      x: current.x + (next.x - current.x) * train.progress,
      y: current.y + (next.y - current.y) * train.progress)
  }
}
