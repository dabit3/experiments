import XCTest

@testable import VelvetVoltage

final class VoltageTests: XCTestCase {
  func testOrderedCircuitAndMultiplierScoring() {
    var score = ScoreCard()
    XCTAssertFalse(score.hit(2))
    XCTAssertEqual(score.nextDistrict, 0)
    XCTAssertFalse(score.hit(0))
    XCTAssertFalse(score.hit(1))
    XCTAssertTrue(score.hit(2))
    XCTAssertEqual(score.points, 2650)
    XCTAssertEqual(score.circuits, 1)
    XCTAssertEqual(score.multiplier, 2)
    XCTAssertEqual(score.nextDistrict, 0)
    for _ in 0..<8 { for district in 0..<3 { _ = score.hit(district) } }
    XCTAssertEqual(score.multiplier, 5)
  }

  func testSegmentProjectionClampsToEndpoints() {
    let rail = Rail(a: Vector(x: 0, y: 0), b: Vector(x: 10, y: 0))
    XCTAssertEqual(rail.closest(to: Vector(x: 5, y: 10)), Vector(x: 5, y: 0))
    XCTAssertEqual(rail.closest(to: Vector(x: 20, y: -5)), Vector(x: 10, y: 0))
    XCTAssertEqual(rail.closest(to: Vector(x: -20, y: 5)), .zero)
  }

  func testThreeBallGameTerminatesAndCannotRelaunch() {
    let engine = PinballEngine()
    for ball in 1...3 {
      engine.launch()
      engine.launch()
      XCTAssertEqual(engine.ballsUsed, ball)
      for _ in 0..<18000 where engine.inFlight { _ = engine.advance(1 / 120) }
      XCTAssertFalse(engine.inFlight, "Ball must eventually drain without input")
    }
    XCTAssertTrue(engine.finished)
    engine.launch()
    XCTAssertFalse(engine.inFlight)
    XCTAssertEqual(engine.ballsRemaining, 0)
  }

  func testPhysicsIsStableAndFixedStepRepeatable() {
    let a = PinballEngine()
    let b = PinballEngine()
    a.launch()
    b.launch()
    for frame in 0..<2400 {
      let flip = frame % 90 < 45
      a.leftPressed = flip
      b.leftPressed = flip
      a.rightPressed = !flip
      b.rightPressed = !flip
      _ = a.advance(1 / 120)
      _ = b.advance(1 / 120)
      XCTAssertTrue(a.ball.x.isFinite && a.ball.y.isFinite)
      XCTAssertLessThanOrEqual(a.velocity.length, 1100.001)
      XCTAssertEqual(a.ball, b.ball)
    }
    XCTAssertGreaterThan(a.score.points, 0)
  }

  func testFlipperMovesUpwardAndReleases() {
    let engine = PinballEngine()
    let initial = engine.flipper(left: true).b.y
    engine.leftPressed = true
    for _ in 0..<30 { _ = engine.advance(1 / 120) }
    XCTAssertGreaterThan(engine.flipper(left: true).b.y, initial + 40)
    engine.leftPressed = false
    for _ in 0..<50 { _ = engine.advance(1 / 120) }
    XCTAssertEqual(engine.flipper(left: true).b.y, initial, accuracy: 0.1)
  }

  @MainActor
  func testRecordsAndSettingsSurviveNewSession() {
    let suite = "voltage-tests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(12500, forKey: "best")
    defaults.set(4, forKey: "circuits")
    let session = GameSession(defaults: defaults)
    session.sound = false
    session.haptics = false
    let restored = GameSession(defaults: defaults)
    XCTAssertEqual(restored.best, 12500)
    XCTAssertEqual(restored.lifetimeCircuits, 4)
    XCTAssertFalse(restored.sound)
    XCTAssertFalse(restored.haptics)
    restored.newGame()
    XCTAssertEqual(restored.best, 12500)
    XCTAssertEqual(restored.score.points, 0)
  }
}
