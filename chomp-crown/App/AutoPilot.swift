import Foundation

enum AutoPilot {
  static let directions = [("up", 0, -1), ("right", 1, 0), ("down", 0, 1), ("left", -1, 0)]
  static func direction(_ state: ArenaState, player: PlayerState, style: String) -> String? {
    let x = Int(player.x.rounded())
    let y = Int(player.y.rounded())
    var target: (Int, Int)?
    let enemies = state.players.filter { $0.id != player.id && $0.alive && $0.power <= 0 }
    if player.power > 1 && style == "hunter",
      let enemy = enemies.min(by: {
        hypot($0.x - player.x, $0.y - player.y) < hypot($1.x - player.x, $1.y - player.y)
      })
    {
      target = (Int(enemy.x.rounded()), Int(enemy.y.rounded()))
    } else if player.power < 1,
      let power = state.powers.filter(\.active).sorted(by: {
        let lhs = abs($0.x - x) + abs($0.y - y)
        let rhs = abs($1.x - x) + abs($1.y - y)
        return style == "runner" ? lhs > rhs : lhs < rhs
      }).first
    {
      target = (power.x, power.y)
    } else {
      target = state.pellets.compactMap { key -> (Int, Int)? in
        let values = key.split(separator: ",").compactMap { Int($0) }
        return values.count == 2 ? (values[0], values[1]) : nil
      }.filter { $0.0 != x || $0.1 != y }.min {
        abs($0.0 - x) + abs($0.1 - y) < abs($1.0 - x) + abs($1.1 - y)
      }
    }
    guard let target else { return nil }
    let maze = state.maze.map(Array.init)
    var queue: [(Int, Int, String?)] = [(x, y, nil)]
    var seen: Set<String> = ["\(x),\(y)"]
    var index = 0
    while index < queue.count {
      let (cx, cy, first) = queue[index]
      index += 1
      if cx == target.0 && cy == target.1 { return first }
      for (dir, dx, dy) in directions {
        let nx = cx + dx
        let ny = cy + dy
        let key = "\(nx),\(ny)"
        if ny < 0 || ny >= maze.count || nx < 0 || nx >= maze[ny].count
          || maze[ny][nx] == "#" || seen.contains(key)
        {
          continue
        }
        seen.insert(key)
        queue.append((nx, ny, first ?? dir))
      }
    }
    return nil
  }
}
