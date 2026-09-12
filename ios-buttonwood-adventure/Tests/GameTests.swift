import XCTest

@testable import ButtonwoodCore

final class GameTests: XCTestCase {
  func tick(_ game: inout Game, seconds: Double) {
    for _ in 0..<Int(seconds * 120) { game.step(1.0 / 120) }
  }

  func testVariableJumpAndCoyoteTime() {
    var held = Game(levelIndex: 0)
    held.pressJump()
    tick(&held, seconds: 0.22)
    var short = held
    short.releaseJump()
    tick(&held, seconds: 0.2)
    tick(&short, seconds: 0.2)
    XCTAssertGreaterThan(held.player.y, short.player.y + 25)
    var coyote = Game(levelIndex: 0)
    coyote.player = Point(x: 810, y: 90)
    coyote.grounded = false
    coyote.support = nil
    coyote.coyote = 0.08
    coyote.pressJump()
    coyote.step(1.0 / 120)
    XCTAssertGreaterThan(coyote.velocity.y, 500)
    coyote.pressJump()
    coyote.coyote = 0
    coyote.velocity.y = -30
    coyote.step(1.0 / 120)
    XCTAssertLessThan(coyote.velocity.y, 0, "No midair double jump")
  }

  func testCoinsCannotBeFarmedAfterCheckpointRespawn() {
    var game = Game(levelIndex: 0)
    let coin = game.level.coins[0]
    game.player = Point(x: coin.x, y: coin.y - 24)
    game.step(1.0 / 120)
    XCTAssertEqual(game.coinCount, 1)
    XCTAssertEqual(game.score, 50)
    game.hurt()
    game.respawn()
    game.player = Point(x: coin.x, y: coin.y - 24)
    game.step(1.0 / 120)
    XCTAssertEqual(game.coinCount, 1)
    XCTAssertEqual(game.score, 50)
  }

  func testStompVersusSideCollision() {
    var stomp = Game(levelIndex: 0)
    let bug = stomp.bugPosition(0)
    stomp.player = Point(x: bug.x, y: bug.y + 28)
    stomp.velocity.y = -200
    stomp.grounded = false
    stomp.support = nil
    tick(&stomp, seconds: 0.04)
    XCTAssertTrue(stomp.stomped.contains(0))
    XCTAssertEqual(stomp.score, 125)
    XCTAssertGreaterThan(stomp.velocity.y, 0)
    var side = Game(levelIndex: 0)
    side.player = Point(x: bug.x, y: bug.y)
    side.step(1.0 / 120)
    XCTAssertEqual(side.phase, .hurt)
    XCTAssertEqual(side.lives, 2)
  }

  func testShieldAbsorbsOneHitAndCheckpointRespawns() {
    var game = Game(levelIndex: 0)
    game.player = Point(x: game.level.powerup.x, y: game.level.powerup.y - 23)
    game.step(1.0 / 120)
    XCTAssertTrue(game.shield)
    game.player = game.bugPosition(0)
    game.step(1.0 / 120)
    XCTAssertFalse(game.shield)
    XCTAssertEqual(game.lives, 3)
    game.player = game.level.checkpoint
    game.step(1.0 / 120)
    XCTAssertTrue(game.checkpointActive)
    game.hurt()
    game.respawn()
    XCTAssertEqual(game.player, game.level.checkpoint)
    XCTAssertEqual(game.lives, 2)
  }

  func testMovingPlatformCarriesPlayer() {
    var game = Game(levelIndex: 0)
    let index = 8
    let ledge = game.level.ledges[index]
    game.player = Point(x: ledge.x + 40, y: ledge.y)
    game.support = index
    game.grounded = true
    let old = game.player.x
    tick(&game, seconds: 0.25)
    XCTAssertGreaterThan(game.player.x, old + 10)
    XCTAssertEqual(game.player.y, ledge.y, accuracy: 0.01)
  }

  func testGameOverAndCompletionAreTerminal() {
    var game = Game(levelIndex: 0)
    for _ in 0..<3 {
      game.hurt()
      game.respawn()
    }
    XCTAssertEqual(game.phase, .gameOver)
    let time = game.time
    game.step(1.0 / 60)
    XCTAssertEqual(game.time, time)
    var win = Game(levelIndex: 1)
    win.player = win.level.goal
    win.step(1.0 / 120)
    XCTAssertEqual(win.phase, .completed)
    let score = win.score
    win.step(1.0 / 60)
    XCTAssertEqual(win.score, score)
    XCTAssertEqual(win.stars, 2)
  }

  func testAllLevelsHaveReachableGroundGapsAndMeaningfulContent() {
    XCTAssertEqual(Level.all.count, 3)
    for level in Level.all {
      let ground = level.ledges.filter { $0.depth > 100 }
      for index in 1..<ground.count {
        let gap = ground[index].x - (ground[index - 1].x + ground[index - 1].width)
        XCTAssertLessThanOrEqual(gap, 195, level.name)
      }
      XCTAssertGreaterThanOrEqual(level.coins.count, 25)
      XCTAssertGreaterThanOrEqual(level.bugs.count, 4)
      XCTAssertTrue(level.ledges.contains { $0.travel > 0 })
    }
  }
}
