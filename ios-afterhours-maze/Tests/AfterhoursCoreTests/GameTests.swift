import XCTest

@testable import AfterhoursCore

final class GameTests: XCTestCase {
  func testBothMazesAreConnectedAndHaveReachablePowerOrbs() {
    for index in 0..<2 {
      let maze = Maze(index: index)
      XCTAssertTrue(maze.rows.allSatisfy { $0.count == 19 }, "Malformed row in \(maze.name)")
      XCTAssertEqual(maze.powers.count, 4)
      let reachable = maze.distanceMap(to: maze.spawn)
      XCTAssertEqual(Set(reachable.keys), maze.paths, "Disconnected path in \(maze.name)")
      XCTAssertTrue(maze.paths.contains(maze.home))
      XCTAssertNil(maze.neighbor(Tile(1, 1), .up))
    }
    XCTAssertNotEqual(Maze(index: 0).walls, Maze(index: 1).walls)
  }

  func testTunnelWrapsBothWays() {
    for index in 0..<2 {
      let maze = Maze(index: index)
      XCTAssertEqual(maze.neighbor(Tile(0, 10), .left), Tile(18, 10))
      XCTAssertEqual(maze.neighbor(Tile(18, 10), .right), Tile(0, 10))
    }
  }

  func testPelletsCannotScoreTwiceAndPowerResetsCombo() {
    var game = Game()
    game.player.tile = Tile(2, 1)
    game.collect()
    XCTAssertEqual(game.score, 10)
    game.collect()
    XCTAssertEqual(game.score, 10)
    game.combo = 3
    game.player.tile = Tile(1, 1)
    game.collect()
    XCTAssertEqual(game.score, 60)
    XCTAssertEqual(game.frightened, 10)
    XCTAssertEqual(game.combo, 0)
  }

  func testFourRivalComboAndReturningRivalsDoNotHurtPlayer() {
    var game = Game()
    game.frightened = 10
    game.grace = 0
    for index in game.rivals.indices {
      game.rivals[index].runner = Runner(tile: game.player.tile)
      game.rivals[index].release = 0
    }
    game.resolveCollisions()
    XCTAssertEqual(game.score, 3000)
    XCTAssertEqual(game.combo, 4)
    XCTAssertTrue(game.rivals.allSatisfy(\.returning))
    game.frightened = 0
    game.resolveCollisions()
    XCTAssertEqual(game.lives, 3)
  }

  func testDeathResetsSafelyAndEventuallyEndsRun() {
    var game = Game()
    for expected in [2, 1, 0] {
      game.grace = 0
      game.rivals[0].runner = Runner(tile: game.player.tile)
      game.rivals[0].release = 0
      game.resolveCollisions()
      XCTAssertEqual(game.lives, expected)
      if expected > 0 {
        XCTAssertEqual(game.phase, .lifeLost)
        XCTAssertEqual(game.player.tile, game.maze.spawn)
        XCTAssertTrue(game.rivals.allSatisfy { $0.release > 0 })
        XCTAssertGreaterThan(game.grace, 0)
      }
    }
    XCTAssertEqual(game.phase, .over)
  }

  func testQueuedTurnsAndInstantReversePreservePosition() {
    var game = Game()
    game.phase = .playing
    game.player.tile = Tile(3, 1)
    game.player.direction = .right
    game.steer(.down)
    game.update(1.0 / 60)
    XCTAssertEqual(game.player.next, Tile(4, 1))
    let before = game.player.position(width: 19)
    game.steer(.left)
    let after = game.player.position(width: 19)
    XCTAssertEqual(before.x, after.x, accuracy: 0.0001)
    XCTAssertEqual(before.y, after.y, accuracy: 0.0001)
    XCTAssertEqual(game.queued, .left)
  }

  func testPauseFreezesEveryClockAndResumesPriorPhase() {
    var game = Game()
    game.phase = .playing
    game.frightened = 5
    game.pause()
    for _ in 0..<600 { game.update(1.0 / 60) }
    XCTAssertEqual(game.elapsed, 0)
    XCTAssertEqual(game.frightened, 5)
    XCTAssertEqual(game.player.tile, game.maze.spawn)
    game.resume()
    game.update(1.0 / 60)
    XCTAssertGreaterThan(game.elapsed, 0)
    XCTAssertLessThan(game.frightened, 5)
  }

  func testClearAwardsBonusAndContinuesWithNextMazeAndExtraLife() {
    var game = Game()
    game.phase = .playing
    game.pellets = []
    game.powers = []
    game.score = 150
    game.update(1.0 / 60)
    XCTAssertEqual(game.phase, .cleared)
    XCTAssertEqual(game.score, 1150)
    game.nextLevel()
    XCTAssertEqual(game.level, 2)
    XCTAssertEqual(game.score, 1150)
    XCTAssertEqual(game.lives, 4)
    XCTAssertEqual(game.maze.name, "Velvet Circuit")
    XCTAssertGreaterThan(game.remaining, 100)
  }

  func testLongDeterministicSimulationNeverClipsWalls() {
    for level in 1...2 {
      var game = Game(level: level, seed: 77)
      var twin = game
      for frame in 0..<12_000 {
        if frame % 90 == 0 {
          let direction = Direction.allCases[(frame / 90) % 4]
          game.steer(direction)
          twin.steer(direction)
        }
        game.update(1.0 / 60)
        twin.update(1.0 / 60)
        XCTAssertTrue(game.maze.paths.contains(game.player.tile))
        for rival in game.rivals {
          XCTAssertTrue(game.maze.paths.contains(rival.runner.tile))
          if let next = rival.runner.next { XCTAssertTrue(game.maze.paths.contains(next)) }
        }
        XCTAssertEqual(game.score, twin.score)
        XCTAssertEqual(game.player.tile, twin.player.tile)
      }
    }
  }
}
