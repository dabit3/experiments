import XCTest

@testable import VelvetRally

final class GameEngineTests: XCTestCase {
  func testServePauseAndResumePreservePhysics() {
    var game = GameEngine(settings: MatchSettings())
    game.serve()
    _ = game.tick(delta: 1.0 / 60)
    game.pause()
    let ball = game.ball
    for _ in 0..<120 { XCTAssertEqual(game.tick(delta: 1.0 / 60), .none) }
    XCTAssertEqual(game.ball, ball)
    game.movePlayer(to: 0.1)
    XCTAssertEqual(game.playerX, 0.5)
    game.resume()
    _ = game.tick(delta: 1.0 / 60)
    XCTAssertNotEqual(game.ball, ball)
  }

  func testSideWallReflectsInward() {
    var game = GameEngine(settings: MatchSettings())
    game.serve()
    game.ball = BallPoint(x: 0.02, y: 0.5)
    game.velocity = BallPoint(x: -0.6, y: 0.2)
    XCTAssertEqual(game.tick(delta: 1.0 / 30), .wall)
    XCTAssertGreaterThan(game.velocity.x, 0)
    XCTAssertGreaterThanOrEqual(game.ball.x, GameEngine.radius)
  }

  func testSweptPaddleCollisionReturnsBallAndCountsRally() {
    var game = GameEngine(settings: MatchSettings())
    game.serve()
    game.ball = BallPoint(x: 0.53, y: 0.84)
    game.velocity = BallPoint(x: 0, y: 1.1)
    XCTAssertEqual(game.tick(delta: 1.0 / 30), .paddle)
    XCTAssertLessThan(game.velocity.y, 0)
    XCTAssertGreaterThan(game.velocity.x, 0)
    XCTAssertEqual(game.returns, 1)
    XCTAssertEqual(game.bestRally, 1)
  }

  func testPaddleMissAwardsExactlyOnePoint() {
    var game = GameEngine(settings: MatchSettings())
    game.serve()
    game.ball = BallPoint(x: 0.9, y: 1.04)
    game.velocity = BallPoint(x: 0, y: 1)
    XCTAssertEqual(game.tick(delta: 1.0 / 30), .opponentPoint)
    for _ in 0..<100 { _ = game.tick(delta: 1.0 / 60) }
    XCTAssertEqual(game.opponentScore, 1)
    XCTAssertEqual(game.phase, .point)
  }

  func testClassicAndSprintFinishAtTargetAndCannotContinue() {
    for target in [3, 7] {
      var settings = MatchSettings()
      settings.target = target
      var game = GameEngine(settings: settings)
      for score in 1...target {
        game.serve()
        game.ball = BallPoint(x: 0.1, y: -0.04)
        game.velocity = BallPoint(x: 0, y: -1)
        XCTAssertEqual(game.tick(delta: 1.0 / 30), .playerPoint)
        XCTAssertEqual(game.playerScore, score)
      }
      XCTAssertEqual(game.phase, .finished)
      game.serve()
      XCTAssertEqual(game.phase, .finished)
      XCTAssertTrue(game.record().won)
    }
  }

  func testDifficultyBoundsAndInvalidInputs() {
    XCTAssertLessThan(Difficulty.easy.aiSpeed, Difficulty.club.aiSpeed)
    XCTAssertLessThan(Difficulty.club.aiSpeed, Difficulty.pro.aiSpeed)
    XCTAssertGreaterThan(Difficulty.easy.paddleWidth, Difficulty.pro.paddleWidth)
    for difficulty in Difficulty.allCases {
      var settings = MatchSettings()
      settings.difficulty = difficulty
      settings.target = -1
      var game = GameEngine(settings: settings)
      XCTAssertEqual(game.target, 7)
      game.movePlayer(to: -20)
      XCTAssertEqual(game.playerX, game.paddleWidth / 2)
      game.movePlayer(to: 20)
      XCTAssertEqual(game.playerX, 1 - game.paddleWidth / 2)
      game.movePlayer(to: .nan)
      XCTAssertTrue(game.playerX.isFinite)
      game.serve()
      let ball = game.ball
      _ = game.tick(delta: .infinity)
      _ = game.tick(delta: -1)
      XCTAssertEqual(game.ball, ball)
      _ = game.tick(delta: 300)
      XCTAssertLessThan(abs(game.ball.y - ball.y), 0.04)
    }
  }

  func testOpponentSpeedIsBoundedAndNotTeleporting() {
    var game = GameEngine(settings: MatchSettings())
    game.serve()
    game.ball = BallPoint(x: 0.9, y: 0.5)
    let before = game.opponentX
    _ = game.tick(delta: 1.0 / 60)
    XCTAssertLessThanOrEqual(abs(game.opponentX - before), Difficulty.easy.aiSpeed / 60 + 0.0001)
  }

  @MainActor
  func testPersistenceSettingsRecordsAndClear() throws {
    let suite = "VelvetRallyTests.\(UUID())"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = RallyStore(defaults: defaults)
    store.settings.court = .clay
    store.settings.target = 3
    let record = MatchRecord(
      id: UUID(), date: Date(), playerScore: 3, opponentScore: 1,
      bestRally: 8, returns: 6, difficulty: .club, court: .clay, target: 3)
    store.add(record)
    store.add(record)
    let restored = RallyStore(defaults: defaults)
    XCTAssertEqual(restored.settings.court, .clay)
    XCTAssertEqual(restored.settings.target, 3)
    XCTAssertEqual(restored.records.count, 1)
    XCTAssertEqual(restored.records.first?.bestRally, 8)
    restored.clearRecords()
    XCTAssertTrue(RallyStore(defaults: defaults).records.isEmpty)
  }
}
