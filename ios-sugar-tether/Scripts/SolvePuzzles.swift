import Foundation

@main
struct SolutionExplorer {
  static func main() {
    for releaseFrame in stride(from: 0, to: 480, by: 6) {
      var game = PhysicsGame(puzzle: Puzzle.all[2])
      for frame in 0..<1200 {
        if frame == releaseFrame {
          game.cut(from: V(x: 20, y: 125), to: V(x: 340, y: 125))
        }
        game.advance(1.0 / 120)
        if game.outcome != .playing { break }
      }
      if game.outcome == .fed && game.collected.count == 3 {
        print(
          "Golden arc: release at \(Double(releaseFrame) / 120)s; \(game.collected.count) stars")
      }
    }
  }
}
