import XCTest

@testable import PowderlineRules

final class RideEngineTests: XCTestCase {
  private func advance(_ ride: inout RideEngine, seconds: Double, rate: Int = 60) {
    for _ in 0..<Int(seconds * Double(rate)) { ride.advance(1 / Double(rate)) }
  }

  func testTapJumpsAndLandsWithoutAwardingAFlip() {
    var ride = RideEngine()
    ride.press()
    ride.release()
    advance(&ride, seconds: 0.5)
    XCTAssertFalse(ride.grounded)
    XCTAssertGreaterThan(ride.y, RideEngine.height(at: ride.x) + 50)
    advance(&ride, seconds: 1.1)
    XCTAssertEqual(ride.phase, .riding)
    XCTAssertTrue(ride.grounded)
    XCTAssertEqual(ride.flips, 0)
    XCTAssertEqual(ride.trickScore, 0)
  }

  func testCompleteBackflipsBuildAndExpireCombo() {
    var ride = RideEngine(mode: .practice)
    for _ in 0..<2 {
      ride.press()
      advance(&ride, seconds: 1.2)
      ride.release()
      advance(&ride, seconds: 0.6)
    }
    XCTAssertEqual(ride.flips, 2)
    XCTAssertEqual(ride.combo, 2)
    XCTAssertEqual(ride.trickScore, 450)
    XCTAssertEqual(ride.bestCombo, 2)
    advance(&ride, seconds: 6)
    XCTAssertEqual(ride.combo, 0)
  }

  func testHalfRotationCrashesInsteadOfGivingPoints() {
    var ride = RideEngine()
    ride.press()
    advance(&ride, seconds: 0.7)
    ride.release()
    advance(&ride, seconds: 1)
    XCTAssertEqual(ride.phase, .crashed)
    XCTAssertEqual(ride.flips, 0)
    XCTAssertEqual(ride.trickScore, 0)
    let frozen = ride.summary
    advance(&ride, seconds: 4)
    XCTAssertEqual(frozen, ride.summary)
  }

  func testRocksStopExpeditionAndPracticeRescues() {
    var expedition = RideEngine(seed: 22)
    advance(&expedition, seconds: 7)
    XCTAssertEqual(expedition.phase, .crashed)
    XCTAssertEqual(expedition.crashReason, "Found a hidden rock")
    var practice = RideEngine(mode: .practice, seed: 22)
    advance(&practice, seconds: 30)
    XCTAssertEqual(practice.phase, .riding)
    XCTAssertGreaterThan(practice.distance, expedition.distance)
    XCTAssertEqual(practice.flips, 0)
  }

  func testGenerationHasWarningRunwayAndJumpableGaps() {
    for seed in 1...100 {
      let ride = RideEngine(seed: UInt64(seed))
      let first = ride.hazard(0)
      XCTAssertGreaterThanOrEqual(first.x, 760)
      for index in 0..<80 {
        let hazard = ride.hazard(index)
        let next = ride.hazard(index + 1)
        XCTAssertGreaterThan(next.x - (hazard.x + hazard.width), 290)
        if hazard.kind == .chasm {
          XCTAssertLessThan(
            hazard.width, 145 * (RideEngine.jumpSpeed * 2 / RideEngine.gravity) - 50)
        }
        XCTAssertEqual(hazard.x, RideEngine(seed: UInt64(seed)).hazard(index).x)
      }
    }
  }

  func testFixedStepIsIndependentOfDisplayRate() {
    var slow = RideEngine(mode: .practice, seed: 9)
    var fast = slow
    slow.press()
    fast.press()
    advance(&slow, seconds: 1.2, rate: 30)
    advance(&fast, seconds: 1.2, rate: 120)
    slow.release()
    fast.release()
    advance(&slow, seconds: 3, rate: 30)
    advance(&fast, seconds: 3, rate: 120)
    XCTAssertEqual(slow.x, fast.x, accuracy: 0.01)
    XCTAssertEqual(slow.y, fast.y, accuracy: 0.01)
    XCTAssertEqual(slow.summary, fast.summary)
  }

  func testSlopeAwareLandingToleranceWrapsFullRotations() {
    XCTAssertTrue(RideEngine.isSafeLanding(rotation: 2 * .pi + 0.3, slope: 0.3))
    XCTAssertTrue(RideEngine.isSafeLanding(rotation: 4 * .pi - 0.2, slope: -0.2))
    XCTAssertFalse(RideEngine.isSafeLanding(rotation: .pi, slope: 0))
    XCTAssertFalse(RideEngine.isSafeLanding(rotation: 1.3, slope: 0.2))
  }

  func testPracticeCannotOverwriteExpeditionRecords() throws {
    var records = RideRecords()
    records.save(
      RideSummary(distance: 120, score: 320, coins: 2, flips: 1, bestCombo: 1, mode: .expedition))
    records.save(
      RideSummary(
        distance: 9000, score: 99999, coins: 900, flips: 90, bestCombo: 5, mode: .practice))
    records.save(
      RideSummary(distance: 80, score: 105, coins: 1, flips: 0, bestCombo: 0, mode: .expedition))
    let restored = try JSONDecoder().decode(RideRecords.self, from: JSONEncoder().encode(records))
    XCTAssertEqual(restored.bestScore, 320)
    XCTAssertEqual(restored.bestDistance, 120)
    XCTAssertEqual(restored.practiceDistance, 9000)
    XCTAssertEqual(restored.totalCoins, 3)
    XCTAssertEqual(restored.totalFlips, 1)
    XCTAssertEqual(restored.rides, 2)
  }
}
