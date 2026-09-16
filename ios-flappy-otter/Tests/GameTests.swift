import Foundation
import XCTest

@testable import FlappyOtterCore

final class GameTests: XCTestCase {
  func testReadyWaitsForFirstTapAndTapLiftsOtter() {
    var game = GameModel(seed: 4)
    game.advance(0.1)
    XCTAssertEqual(game.phase, .ready)
    XCTAssertEqual(game.elapsed, 0)
    let initialY = game.y
    game.flap()
    XCTAssertEqual(game.phase, .playing)
    XCTAssertEqual(game.velocity, GameModel.flapVelocity)
    game.advance(0.1)
    XCTAssertLessThan(game.y, initialY)
  }

  func testGravityEndsAnUnattendedFlightAtWater() {
    var game = GameModel(seed: 4)
    game.flap()
    for _ in 0..<300 { game.advance(GameModel.step) }
    XCTAssertEqual(game.phase, .finished)
    XCTAssertEqual(game.y, GameModel.waterline - GameModel.radius)
    XCTAssertEqual(game.score, 0)
    let elapsed = game.elapsed
    game.flap()
    game.advance(0.1)
    XCTAssertEqual(game.elapsed, elapsed)
    XCTAssertEqual(game.phase, .finished)
  }

  func testRepeatedFlapsCannotEscapeThroughCeiling() {
    var game = GameModel(seed: 4)
    for _ in 0..<400 {
      game.flap()
      game.advance(GameModel.step)
    }
    XCTAssertEqual(game.phase, .finished)
    XCTAssertEqual(game.y, GameModel.ceiling + GameModel.radius)
  }

  func testPauseFreezesPhysicsObstaclesAndScoring() {
    var game = GameModel(seed: 4)
    game.flap()
    game.advance(0.1)
    game.pause()
    let paused = game
    for _ in 0..<100 {
      game.flap()
      game.advance(0.1)
    }
    XCTAssertEqual(game.phase, .paused)
    XCTAssertEqual(game.y, paused.y)
    XCTAssertEqual(game.gates, paused.gates)
    XCTAssertEqual(game.score, paused.score)
    XCTAssertEqual(game.elapsed, paused.elapsed)
    game.resume()
    game.advance(GameModel.step)
    XCTAssertEqual(game.phase, .playing)
    XCTAssertGreaterThan(game.elapsed, paused.elapsed)
  }

  func testPauseAndResumeDoNotStartAReadyOrFinishedGame() {
    var game = GameModel(seed: 4)
    game.pause()
    game.resume()
    XCTAssertEqual(game.phase, .ready)
    game.flap()
    for _ in 0..<100 { game.advance(0.1) }
    game.pause()
    game.resume()
    XCTAssertEqual(game.phase, .finished)
  }

  func testFixedStepMatchesAcrossDisplayRefreshRates() {
    var fast = GameModel(seed: 42)
    var slow = fast
    for frame in 0..<240 {
      if frame % 15 == 0 {
        fast.flap()
        slow.flap()
      }
      for _ in 0..<4 { fast.advance(1.0 / 120) }
      slow.advance(1.0 / 30)
      XCTAssertEqual(fast.y, slow.y, accuracy: 0.000_001)
      XCTAssertEqual(fast.distance, slow.distance, accuracy: 0.000_001)
      XCTAssertEqual(fast.phase, slow.phase)
      XCTAssertEqual(fast.score, slow.score)
    }
  }

  func testInvalidAndLongFrameDeltasCannotTeleportPlayer() {
    var game = GameModel(seed: 4)
    game.flap()
    let initialY = game.y
    for delta in [Double.nan, .infinity, -.infinity, -1, 0] { game.advance(delta) }
    XCTAssertEqual(game.y, initialY)
    game.advance(8)
    XCTAssertEqual(game.elapsed, 0.1, accuracy: 0.000_001)
    XCTAssertEqual(game.phase, .playing)
  }

  func testCircleCollisionRespectsGapAndRoundedCorners() {
    let game = GameModel(seed: 4)
    let x = GameModel.playerX
    let y = game.y
    XCTAssertFalse(game.collides(with: RiverGate(id: 0, x: x, center: y, gap: 100)))
    XCTAssertTrue(game.collides(with: RiverGate(id: 0, x: x, center: y + 75, gap: 100)))
    XCTAssertTrue(game.collides(with: RiverGate(id: 0, x: x, center: y - 75, gap: 100)))
    XCTAssertFalse(
      game.collides(with: RiverGate(id: 0, x: x + 100, center: y + 100, gap: 100)))
    XCTAssertFalse(
      game.collides(with: RiverGate(id: 0, x: x + 20, center: y + 35, gap: 100)))
    XCTAssertTrue(
      game.collides(with: RiverGate(id: 0, x: x + 10, center: y + 35, gap: 100)))
  }

  func testDeterministicCourseAndDifferentSeeds() {
    XCTAssertEqual(GameModel(seed: 47).gates, GameModel(seed: 47).gates)
    XCTAssertNotEqual(GameModel(seed: 47).gates, GameModel(seed: 48).gates)
    XCTAssertNotEqual(GameModel(seed: 0).gates[0].center, GameModel(seed: 0).gates[1].center)
  }

  func testLongFlightsHaveFairGapsBoundedObjectsAndOnePointPerGate() {
    for seed: UInt64 in [0, 1, 42, 400, UInt64.max] {
      var game = GameModel(seed: seed)
      var seen: [Int: RiverGate] = [:]
      var crossings = 0
      for _ in 0..<40_000 {
        pilot(&game)
        let before = game.gates
        game.advance(GameModel.step)
        for old in before where !old.passed {
          if game.gates.first(where: { $0.id == old.id })?.passed == true { crossings += 1 }
        }
        XCTAssertEqual(game.score, crossings)
        XCTAssertLessThanOrEqual(game.gates.count, 4)
        for gate in game.gates {
          seen[gate.id] = gate
          XCTAssertGreaterThanOrEqual(gate.gap, 188)
          XCTAssertGreaterThan(gate.top, GameModel.ceiling + GameModel.radius)
          XCTAssertLessThan(gate.bottom, GameModel.waterline - GameModel.radius)
        }
        if game.score >= 100 || game.phase == .finished { break }
      }
      XCTAssertEqual(game.phase, .playing, "Seed \(seed)")
      XCTAssertEqual(game.score, 100, "Seed \(seed)")
      XCTAssertLessThanOrEqual(game.speed, 180)
      let ordered = seen.values.sorted { $0.id < $1.id }
      for pair in zip(ordered, ordered.dropFirst()) {
        XCTAssertLessThanOrEqual(abs(pair.0.center - pair.1.center), 78)
      }
    }
  }

  func testActualGateCollisionEndsFlightWithoutGrantingPoint() {
    var game = GameModel(seed: 42)
    for _ in 0..<2_000 {
      if game.phase == .ready || (game.y > 210 && game.velocity >= 0) { game.flap() }
      game.advance(GameModel.step)
      if game.phase == .finished { break }
    }
    XCTAssertEqual(game.phase, .finished)
    XCTAssertEqual(game.score, 0)
    XCTAssertGreaterThan(game.y, GameModel.ceiling + GameModel.radius)
    XCTAssertLessThan(game.y, GameModel.waterline - GameModel.radius)
    XCTAssertTrue(game.gates.contains(where: { game.collides(with: $0) }))
  }

  func testRestartCreatesCleanRunWithoutReusingCourse() {
    var game = GameModel(seed: 42)
    game.flap()
    for _ in 0..<100 { game.advance(0.1) }
    game = GameModel(seed: 12)
    XCTAssertEqual(game.phase, .ready)
    XCTAssertEqual(game.score, 0)
    XCTAssertEqual(game.elapsed, 0)
    XCTAssertEqual(game.distance, 0)
    XCTAssertTrue(game.gates.allSatisfy { !$0.passed })
    XCTAssertEqual(game.gates.first?.x, 460)
  }

  private func pilot(_ game: inout GameModel) {
    let target =
      game.gates.first {
        $0.x + GameModel.gateWidth >= GameModel.playerX - GameModel.radius
      }?.center ?? 397
    if game.phase == .ready || (game.y > target + 12 && game.velocity >= 0) { game.flap() }
  }
}
