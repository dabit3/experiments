import Foundation

public struct Tile: Hashable, Sendable {
  public var x: Int
  public var y: Int
  public init(_ x: Int, _ y: Int) {
    self.x = x
    self.y = y
  }
  public func distance(to other: Tile) -> Int { abs(x - other.x) + abs(y - other.y) }
}

public enum Direction: Int, CaseIterable, Sendable {
  case left, up, right, down
  public var dx: Int { self == .left ? -1 : self == .right ? 1 : 0 }
  public var dy: Int { self == .up ? -1 : self == .down ? 1 : 0 }
  public var opposite: Direction { Direction(rawValue: (rawValue + 2) % 4)! }
  public var angle: Double { Double(rawValue - 2) * .pi / 2 }
}

public struct Maze: Sendable {
  public let rows: [String]
  public let name: String
  public let subtitle: String
  public var width: Int { 19 }
  public var height: Int { rows.count }
  public let spawn = Tile(9, 17)
  public let home = Tile(9, 9)
  public let tunnelRow = 10
  public let walls: Set<Tile>
  public let pellets: Set<Tile>
  public let powers: Set<Tile>
  public let paths: Set<Tile>

  public init(index: Int) {
    name = index % 2 == 0 ? "The Blue Hour" : "Velvet Circuit"
    subtitle = index % 2 == 0 ? "A little light in the dark." : "Take the long way home."
    let blue = [
      "###################",
      "#o.......#.......o#",
      "#.##.###.#.###.##.#",
      "#.................#",
      "#.##.#.#####.#.##.#",
      "#....#...#...#....#",
      "####.###.#.###.####",
      "#....#.......#....#",
      "#.##.#.##.##.#.##.#",
      "#......   ......#.#",
      "....##.   .##......",
      "#.#....   ....#.#.#",
      "#.#.##.###.##.#.#.#",
      "#.......#.#.......#",
      "#.###.#.#.#.#.###.#",
      "#.....#.....#.....#",
      "#.###.###.###.###.#",
      "#o....... .......o#",
      "#.##.#.#####.#.##.#",
      "#....#.......#....#",
      "###################",
    ]
    let velvet = [
      "###################",
      "#o.......#.......o#",
      "#.###.##.#.##.###.#",
      "#.....#.....#.....#",
      "#.##..#.###.#..##.#",
      "#..#....#.#....#..#",
      "##.####.#.#.####.##",
      "#.......#.#.......#",
      "#.##.##.....##.##.#",
      "#....#.   .#......#",
      "...#...   ...#.....",
      "#....#.   .#....#.#",
      "#.##.#.###.#.##.#.#",
      "#....#.....#......#",
      "###.###.#.###.###.#",
      "#.......#.........#",
      "#.##.##.#.##.##.#.#",
      "#o....... .......o#",
      "#.###.#.###.#.###.#",
      "#.....#.....#.....#",
      "###################",
    ]
    rows = index % 2 == 0 ? blue : velvet
    var walls = Set<Tile>()
    var pellets = Set<Tile>()
    var powers = Set<Tile>()
    var paths = Set<Tile>()
    for (y, row) in rows.enumerated() {
      for (x, glyph) in row.enumerated() {
        let tile = Tile(x, y)
        if glyph == "#" { walls.insert(tile) } else { paths.insert(tile) }
        if glyph == "." { pellets.insert(tile) }
        if glyph == "o" { powers.insert(tile) }
      }
    }
    self.walls = walls
    self.pellets = pellets
    self.powers = powers
    self.paths = paths
  }

  public func neighbor(_ tile: Tile, _ direction: Direction) -> Tile? {
    var next = Tile(tile.x + direction.dx, tile.y + direction.dy)
    if next.y == tunnelRow {
      next.x = (next.x + width) % width
    }
    return paths.contains(next) ? next : nil
  }

  public func distanceMap(to target: Tile) -> [Tile: Int] {
    let target = paths.min {
      let lhs = $0.distance(to: target)
      let rhs = $1.distance(to: target)
      return lhs == rhs ? ($0.y * width + $0.x < $1.y * width + $1.x) : lhs < rhs
    }!
    var distances = [target: 0]
    var queue = [target]
    var index = 0
    while index < queue.count {
      let tile = queue[index]
      index += 1
      for direction in Direction.allCases {
        if let next = neighbor(tile, direction), distances[next] == nil {
          distances[next] = distances[tile]! + 1
          queue.append(next)
        }
      }
    }
    return distances
  }
}
