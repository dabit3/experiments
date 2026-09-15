import XCTest

@testable import BoardwalkRules

final class RunnerEngineTests: XCTestCase {
  func testNoTimePassesBeforeStarting() {
    var game = RunnerEngine(seed: 42)
    game.advance(0.1)
    game.move(.left)
    XCTAssertEqual(game.distance, 0)
    XCTAssertEqual(game.lane, 1)
  }

  func testLaneClampsAndAnimates() {
    var game = started()
    game.move(.left)
    XCTAssertEqual(game.lanePosition, 1)
    game.advance(0.02)
    XCTAssertGreaterThan(game.lanePosition, 0)
    XCTAssertLessThan(game.lanePosition, 1)
    game.move(.left)
    XCTAssertEqual(game.lane, 0)
    for _ in 0..<5 { game.move(.right) }
    XCTAssertEqual(game.lane, 2)
  }

  func testPauseFreezesAllStateAndIgnoresControls() {
    var game = started()
    game.move(.jump)
    game.advance(0.1)
    game.pause()
    let before = (game.distance, game.jumpTime, game.lane)
    game.advance(30)
    game.move(.left)
    XCTAssertEqual(game.distance, before.0)
    XCTAssertEqual(game.jumpTime, before.1)
    XCTAssertEqual(game.lane, before.2)
    game.resume()
    game.advance(0.1)
    XCTAssertGreaterThan(game.distance, before.0)
  }

  func testObstacleRulesDiffer() {
    XCTAssertTrue(RunnerEngine.clears(.barrier, height: 1.2, sliding: false))
    XCTAssertFalse(RunnerEngine.clears(.barrier, height: 0, sliding: true))
    XCTAssertTrue(RunnerEngine.clears(.sign, height: 0, sliding: true))
    XCTAssertFalse(RunnerEngine.clears(.sign, height: 2.3, sliding: false))
    XCTAssertFalse(RunnerEngine.clears(.cart, height: 2.3, sliding: true))
  }

  func testFirstBarrierEndsUnattendedRun() {
    var game = started()
    for _ in 0..<600 { game.advance(1.0 / 60) }
    XCTAssertEqual(game.phase, .finished)
    XCTAssertEqual(game.collision, .barrier)
    XCTAssertEqual(game.distance, 42, accuracy: 1)
    let distance = game.distance
    game.advance(0.1)
    XCTAssertEqual(distance, game.distance)
  }

  func testJumpClearsBarrierAndSlideClearsSign() {
    var game = started()
    var jumped = false
    var slid = false
    for _ in 0..<1000 {
      if let obstacle = game.nearestObstacles.first {
        if obstacle.kind == .barrier && obstacle.distance < 6 && !jumped {
          game.move(.jump)
          jumped = true
        }
        if obstacle.kind == .sign && obstacle.distance < 7 && !slid {
          game.move(.slide)
          slid = true
        }
      }
      game.advance(1.0 / 60)
      if game.distance > 90 { break }
    }
    XCTAssertTrue(jumped && slid)
    XCTAssertEqual(game.phase, .running)
    XCTAssertGreaterThanOrEqual(game.obstaclesCleared, 2)
    XCTAssertGreaterThan(game.coins, 0)
  }

  func testJumpCannotBeRepeatedInMidair() {
    var game = started()
    game.move(.jump)
    game.advance(0.1)
    let time = game.jumpTime
    game.move(.jump)
    game.move(.slide)
    XCTAssertEqual(game.jumpTime, time)
    XCTAssertFalse(game.isSliding)
  }

  func testShieldPickupAbsorbsOneHit() {
    var game = started()
    for _ in 0..<10000 {
      if game.distance < 90 {
        if let obstacle = game.nearestObstacles.first, obstacle.distance < 6 {
          game.move(obstacle.kind == .barrier ? .jump : .slide)
        }
      }
      game.advance(1.0 / 120)
      if game.isShielded { break }
    }
    XCTAssertEqual(game.shieldsCollected, 1)
    XCTAssertTrue(game.isShielded)
    var intercepted = false
    for _ in 0..<10000 {
      if let target = game.nearestObstacles.first, target.distance < 25 {
        while game.lane > target.lane { game.move(.left) }
        while game.lane < target.lane { game.move(.right) }
      }
      game.advance(1.0 / 120)
      if game.graceTime > 0 {
        intercepted = true
        break
      }
    }
    XCTAssertTrue(intercepted)
    XCTAssertFalse(game.isShielded)
    XCTAssertEqual(game.phase, .running)
  }

  func testSeedReproducesLayout() {
    var first = started()
    var second = started()
    for _ in 0..<40 {
      first.advance(0.016)
      second.advance(0.016)
    }
    XCTAssertEqual(first.obstacles.map(\.lane), second.obstacles.map(\.lane))
    XCTAssertEqual(first.obstacles.map(\.kind), second.obstacles.map(\.kind))
    XCTAssertEqual(first.obstacles.map(\.distance), second.obstacles.map(\.distance))
  }

  func testThousandsOfGeneratedRowsHaveOpenReachableLanes() {
    for seed in 1...20 {
      var game = RunnerEngine(seed: UInt64(seed))
      game.start()
      for _ in 0..<15000 {
        let row = game.nearestObstacles
        XCTAssertLessThan(Set(row.map(\.lane)).count, 3)
        if let obstacle = row.first, obstacle.distance < 25 {
          let open = (0...2).first { lane in !row.contains { $0.lane == lane } }!
          if game.lane > open { game.move(.left) }
          if game.lane < open { game.move(.right) }
        }
        game.advance(0.05)
        if game.phase == .finished {
          XCTFail("Unreachable row for seed \(seed)")
          break
        }
      }
      XCTAssertGreaterThan(game.distance, 12000)
      XCTAssertLessThanOrEqual(game.speed, 23)
      XCTAssertLessThan(game.obstacles.count, 15)
      XCTAssertLessThan(game.pickups.count, 30)
    }
  }

  func testInvalidAndHugeDeltasDoNotTeleport() {
    var game = started()
    game.advance(.nan)
    game.advance(.infinity)
    game.advance(-10)
    XCTAssertEqual(game.distance, 0)
    game.advance(1000)
    XCTAssertLessThan(game.distance, 2)
  }

  func testRecordsRoundTripWithoutLosingBest() throws {
    let original = RunSnapshot(bestDistance: 812, totalCoins: 93, runs: 4)
    let data = try JSONEncoder().encode(original)
    XCTAssertEqual(try JSONDecoder().decode(RunSnapshot.self, from: data), original)
  }

  private func started() -> RunnerEngine {
    var game = RunnerEngine(seed: 42)
    game.start()
    return game
  }
}
