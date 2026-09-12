import Foundation

struct Square: Codable, Hashable {
  let column: Int
  let row: Int

  var isInside: Bool { (0..<5).contains(column) && (0..<5).contains(row) }
  var index: Int { row * 5 + column }

  func next(_ direction: Direction) -> Square {
    Square(column: column + direction.dx, row: row + direction.dy)
  }
}

enum Direction: String, CaseIterable, Codable {
  case north, east, south, west

  var dx: Int { self == .east ? 1 : self == .west ? -1 : 0 }
  var dy: Int { self == .south ? 1 : self == .north ? -1 : 0 }
  var symbol: String {
    switch self {
    case .north: "arrow.up"
    case .east: "arrow.right"
    case .south: "arrow.down"
    case .west: "arrow.left"
    }
  }
  var title: String { rawValue.capitalized }
}

struct Home: Codable, Hashable {
  let square: Square
  let name: String
  let priority: Bool
}

struct Puzzle: Codable, Equatable, Identifiable {
  let id: String
  let number: Int
  let name: String
  let subtitle: String
  let start: Square
  let homes: [Home]
  let trees: Set<Square>
  let snow: [Int]
  let fuel: Int
  let par: Int

  static let routes: [Puzzle] = [
    make(1, "First snowfall", "A little warmth goes a long way.", fuel: 15, par: 8),
    make(2, "Cranberry lane", "A deeper drift. A brighter evening.", fuel: 16, par: 10),
    make(3, "The long way home", "The shortest road isn't always the clearest.", fuel: 20, par: 14),
    make(4, "Midwinter mail", "Save a little fuel for the last light.", fuel: 23, par: 17),
    make(5, "Blue hour", "Three doorsteps before the stars arrive.", fuel: 23, par: 17),
    make(6, "Lantern night", "One last round through the winter hush.", fuel: 22, par: 16),
  ]

  private static func make(_ number: Int, _ name: String, _ subtitle: String, fuel: Int, par: Int)
    -> Puzzle
  {
    var snow = Array(repeating: 0, count: 25)
    snow[Square(column: 1, row: 2).index] = number > 1 ? 2 : 1
    if number >= 3 { snow[Square(column: 2, row: 1).index] = 1 }
    if number >= 4 { snow[Square(column: 3, row: 2).index] = 1 }
    if number >= 5 { snow[Square(column: 3, row: 3).index] = 1 }
    if number == 6 { snow[Square(column: 2, row: 3).index] = 2 }
    let reflected = number.isMultiple(of: 2)
    func point(_ column: Int, _ row: Int) -> Square {
      Square(column: reflected ? 4 - column : column, row: row)
    }
    if reflected {
      snow = (0..<25).map { snow[($0 / 5) * 5 + (4 - $0 % 5)] }
    }
    return Puzzle(
      id: "route-\(number)", number: number, name: name, subtitle: subtitle,
      start: point(1, 3),
      homes: [
        Home(square: point(number == 5 ? 0 : 1, 1), name: "The bakery", priority: true),
        Home(
          square: point(number == 6 ? 4 : 3, number == 3 ? 0 : number == 6 ? 2 : 1),
          name: "Post cottage", priority: false),
        Home(
          square: point(number == 4 ? 1 : 3, number == 4 ? 4 : 3),
          name: "Lantern house", priority: false),
      ],
      trees: [point(0, 0), point(4, 0), point(2, 2), point(0, 3), point(4, 4)],
      snow: snow, fuel: fuel, par: par)
  }

  static func daily(on date: Date = Date()) -> Puzzle {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd"
    let key = formatter.string(from: date)
    let seed = key.utf8.reduce(0) { ($0 * 31 + Int($1)) % 100_003 }
    let route = routes[seed % routes.count]
    return Puzzle(
      id: "daily-\(key)", number: route.number, name: "Daily dispatch",
      subtitle:
        "One village. Your most efficient route. \(key.prefix(4))·\(key.dropFirst(4).prefix(2))·\(key.suffix(2)) UTC",
      start: route.start, homes: route.homes, trees: route.trees, snow: route.snow,
      fuel: route.fuel, par: route.par)
  }
}

struct Position: Codable, Equatable {
  var van: Square
  var snow: [Int]
  var delivered: Set<Square> = []
  var fuelUsed = 0
  var moves = 0
}

struct MovePreview: Equatable {
  let direction: Direction
  let destination: Square
  let cost: Int
  let depth: Int
  let reason: String?
  var allowed: Bool { reason == nil }
}

struct Journey: Codable, Equatable {
  let puzzle: Puzzle
  var position: Position
  var history: [Position] = []

  init(puzzle: Puzzle) {
    self.puzzle = puzzle
    position = Position(van: puzzle.start, snow: puzzle.snow)
  }

  var fuelLeft: Int { puzzle.fuel - position.fuelUsed }
  var won: Bool { position.delivered.count == puzzle.homes.count }
  var stranded: Bool { !won && Direction.allCases.allSatisfy { !preview($0).allowed } }
  var stars: Int {
    guard won else { return 0 }
    return position.fuelUsed <= puzzle.par ? 3 : position.fuelUsed <= puzzle.par + 4 ? 2 : 1
  }
  var score: Int { won ? max(100, 1500 - position.fuelUsed * 50) : 0 }

  func preview(_ direction: Direction) -> MovePreview {
    let destination = position.van.next(direction)
    let depth = destination.isInside ? position.snow[destination.index] : 0
    let cost = 1 + depth
    var reason: String?
    if won {
      reason = "Every parcel is home."
    } else if !destination.isInside {
      reason = "The glass ends here. Try another lane."
    } else if puzzle.trees.contains(destination) {
      reason = "A little fir grove blocks this lane."
    } else if depth > 0 {
      let bank = destination.next(direction)
      if bank.isInside && puzzle.trees.contains(bank) {
        reason = "No room to push snow into the fir grove."
      } else if bank.isInside && position.snow[bank.index] + depth > 3 {
        reason = "That drift is full. Approach from another side."
      }
    }
    if reason == nil && cost > fuelLeft { reason = "Not enough fuel. Undo or try a new route." }
    return MovePreview(
      direction: direction, destination: destination, cost: cost, depth: depth, reason: reason)
  }

  @discardableResult
  mutating func move(_ direction: Direction) -> Bool {
    let move = preview(direction)
    guard move.allowed else { return false }
    history.append(position)
    let bank = move.destination.next(direction)
    if move.depth > 0 {
      position.snow[move.destination.index] = 0
      if bank.isInside { position.snow[bank.index] += move.depth }
    }
    position.van = move.destination
    position.fuelUsed += move.cost
    position.moves += 1
    if let home = puzzle.homes.first(where: { $0.square == move.destination }) {
      let priorityDelivered = puzzle.homes.filter(\.priority).allSatisfy {
        position.delivered.contains($0.square)
      }
      if home.priority || priorityDelivered { position.delivered.insert(home.square) }
    }
    return true
  }

  mutating func undo() {
    guard let previous = history.popLast() else { return }
    position = previous
  }
}

struct ProgressRecord: Codable, Equatable {
  var stars = 0
  var score = 0
}

final class LocalStore {
  private let defaults: UserDefaults
  init(defaults: UserDefaults = .standard) { self.defaults = defaults }

  func loadProgress() -> [String: ProgressRecord] {
    guard let data = defaults.data(forKey: "village.progress"),
      let value = try? JSONDecoder().decode([String: ProgressRecord].self, from: data)
    else { return [:] }
    return value
  }

  func record(_ journey: Journey) {
    guard journey.won else { return }
    var progress = loadProgress()
    let old = progress[journey.puzzle.id] ?? ProgressRecord()
    progress[journey.puzzle.id] = ProgressRecord(
      stars: max(old.stars, journey.stars), score: max(old.score, journey.score))
    if let data = try? JSONEncoder().encode(progress) {
      defaults.set(data, forKey: "village.progress")
    }
  }

  func save(_ journey: Journey?) {
    if let journey, let data = try? JSONEncoder().encode(journey) {
      defaults.set(data, forKey: "village.journey")
    } else {
      defaults.removeObject(forKey: "village.journey")
    }
  }

  func resume() -> Journey? {
    guard let data = defaults.data(forKey: "village.journey"),
      let journey = try? JSONDecoder().decode(Journey.self, from: data),
      journey.position.snow.count == 25, journey.position.van.isInside,
      journey.position.snow.allSatisfy({ (0...3).contains($0) }),
      journey.fuelLeft >= 0
    else { return nil }
    return journey
  }
}
