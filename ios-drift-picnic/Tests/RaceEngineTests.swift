import XCTest

@testable import PicnicRules

final class RaceEngineTests: XCTestCase {
  func testCircuitIsClosedAndProjectionRoundTrips() {
    let circuit = Circuit()
    XCTAssertLessThan((circuit.points.first! - circuit.points.last!).length, 0.001)
    for distance in stride(from: 0.0, to: circuit.length, by: 3) {
      let p = circuit.at(distance, offset: 2)
      let projection = circuit.project(p.point)
      XCTAssertEqual(projection.offset, 2, accuracy: 0.08)
      let difference = abs(projection.distance - distance)
      XCTAssertLessThan(min(difference, circuit.length - difference), 0.15)
    }
  }

  func testOrderedCheckpointsPreventShortcutAndReverseLap() {
    var tracker = LapTracker(previous: 0)
    for distance in [100.0, 200, 299, 0] {
      XCTAssertFalse(tracker.update(distance: distance, onTrack: true, circuitLength: 300))
    }
    XCTAssertEqual(tracker.laps, 0)
    tracker = LapTracker(previous: 0)
    for distance in stride(from: 299.0, through: 0, by: -1) {
      _ = tracker.update(distance: distance, onTrack: true, circuitLength: 300)
    }
    XCTAssertEqual(tracker.laps, 0)
  }

  func testThreeFullLapsAndFinishFreeze() {
    var race = RaceEngine(mode: .trial)
    for _ in 0..<18000 {
      race.step(1.0 / 60)
      if race.finished { break }
    }
    XCTAssertTrue(race.finished)
    XCTAssertEqual(race.player.lapTimes.count, 3)
    let time = race.elapsed
    race.step(1)
    XCTAssertEqual(time, race.elapsed)
  }

  func testSteeringChangesTrajectoryAndBoundaryContainsKart() {
    var centered = RaceEngine(mode: .trial)
    var turning = centered
    turning.steering = 1
    for _ in 0..<600 {
      centered.step(1.0 / 60)
      turning.step(1.0 / 60)
    }
    XCTAssertGreaterThan((centered.player.point - turning.player.point).length, 3)
    XCTAssertLessThanOrEqual(abs(turning.circuit.project(turning.player.point).offset), 7.6)
  }

  func testPickupIsConsumedAndDriftMustBeEarned() {
    var race = RaceEngine(mode: .trial)
    race.releaseDrift()
    XCTAssertEqual(race.driftBoosts, 0)
    for _ in 0..<600 { race.step(1.0 / 60) }
    XCTAssertTrue(race.hasItem)
    race.useItem()
    XCTAssertFalse(race.hasItem)
    XCTAssertGreaterThan(race.player.boost, 2)
    race.drivers[0].driftCharge = 0.7
    race.releaseDrift()
    XCTAssertEqual(race.driftBoosts, 1)
  }

  func testSteeringMatchesChaseCameraDirectionsAroundCircuit() {
    for fraction in [0.0, 0.25, 0.5, 0.75] {
      var centered = RaceEngine(mode: .trial)
      let pose = centered.circuit.at(centered.circuit.length * fraction)
      centered.drivers[0].point = pose.point
      centered.drivers[0].heading = pose.heading
      centered.drivers[0].speed = 17
      var left = centered
      var right = centered
      left.steering = -1
      right.steering = 1
      for _ in 0..<30 {
        centered.step(1.0 / 60)
        left.step(1.0 / 60)
        right.step(1.0 / 60)
      }
      let screenRight = Point(x: -cos(pose.heading), z: sin(pose.heading))
      let rightShift = right.player.point - centered.player.point
      let leftShift = left.player.point - centered.player.point
      XCTAssertGreaterThan(rightShift.x * screenRight.x + rightShift.z * screenRight.z, 1)
      XCTAssertLessThan(leftShift.x * screenRight.x + leftShift.z * screenRight.z, -1)
    }
  }

  func testLargeTimeStepsDoNotTeleportOrSkipCheckpoints() {
    var race = RaceEngine()
    race.step(100)
    XCTAssertEqual(race.elapsed, 1.0 / 30, accuracy: 0.001)
    XCTAssertEqual(race.player.tracker.laps, 0)
  }
}
