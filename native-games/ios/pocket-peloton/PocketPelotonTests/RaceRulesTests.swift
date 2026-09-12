import XCTest

@testable import PocketPeloton

final class RaceRulesTests: XCTestCase {
  func testDraftRequiresCorrectLaneAndDistanceAndRecoversFaster() {
    var draft = RaceState(course: .riviera)
    draft.energy = 30
    var solo = draft
    solo.lane = 2
    solo.rivals = []
    for _ in 0..<30 {
      draft.step(1.0 / 30)
      solo.step(1.0 / 30)
    }
    XCTAssertTrue(draft.drafting)
    XCTAssertGreaterThan(draft.energy, solo.energy + 5)
    draft.rivals[0].distance = draft.distance + 43
    XCTAssertFalse(draft.drafting)
  }

  func testSprintDrainsEnergyAndExhaustionRequiresRecovery() {
    var race = RaceState(course: .riviera)
    race.rivals = []
    race.energy = 0.2
    race.sprintHeld = true
    race.step(0.1)
    XCTAssertEqual(race.energy, 0)
    XCTAssertTrue(race.exhausted)
    XCTAssertFalse(race.isSprinting)
    for _ in 0..<30 { race.step(0.1) }
    XCTAssertFalse(race.isSprinting)
    XCTAssertGreaterThan(race.energy, 0)
    XCTAssertLessThan(race.energy, 28)
    for _ in 0..<15 { race.step(0.1) }
    XCTAssertTrue(race.isSprinting)
  }

  func testChargedDraftSlingshotsOnlyAfterAValidLaneChange() {
    var race = RaceState(course: .riviera)
    for _ in 0..<60 { race.step(1.0 / 30) }
    XCTAssertTrue(race.attackReady)
    race.move(to: 1)
    XCTAssertEqual(race.attacks, 0)
    race.move(to: -1)
    XCTAssertEqual(race.lane, 1)
    race.move(to: 0)
    XCTAssertEqual(race.attacks, 1)
    XCTAssertGreaterThan(race.attackRemaining, 2)
    XCTAssertEqual(race.draftCharge, 0)
    race.move(to: 2)
    XCTAssertEqual(race.attacks, 1)
  }

  func testObstaclePenalizesOnlyItsLaneAndOnlyOnce() {
    var hit = RaceState(course: .riviera)
    hit.distance = 149.5
    hit.lane = 0
    var miss = hit
    miss.lane = 1
    hit.step(0.1)
    miss.step(0.1)
    XCTAssertEqual(hit.collisions, 1)
    XCTAssertEqual(miss.collisions, 0)
    XCTAssertGreaterThan(hit.collisionRemaining, 0)
    for _ in 0..<30 { hit.step(0.1) }
    XCTAssertEqual(hit.collisions, 1)
  }

  func testFrameRateIndependentFinishAndAccurateGap() throws {
    func finish(dt: Double) throws -> RaceResult {
      var race = RaceState(course: .riviera)
      race.lane = 1
      while race.result == nil { race.step(dt) }
      return try XCTUnwrap(race.result)
    }
    let fast = try finish(dt: 1.0 / 60)
    let slow = try finish(dt: 1.0 / 30)
    XCTAssertEqual(fast.rank, slow.rank)
    XCTAssertEqual(fast.time, slow.time, accuracy: 0.15)
    XCTAssertEqual(fast.gap, slow.gap, accuracy: 0.15)
    XCTAssertGreaterThan(fast.gap, 0)
  }

  func testAllCoursesHaveAchievableWinsWithSprintAndObstacleAvoidance() throws {
    for course in Course.allCases {
      var race = RaceState(course: course)
      var recovering = false
      for _ in 0..<6_000 where race.result == nil {
        if race.energy < 6 { recovering = true }
        if race.energy > 45 { recovering = false }
        race.sprintHeld = !recovering
        if let hazard = course.obstacles.first(where: {
          (0...20).contains($0.distance - race.distance) && $0.lane == race.lane
        }) {
          race.move(to: (hazard.lane + 1) % 3)
        }
        race.step(1.0 / 60)
      }
      let result = try XCTUnwrap(race.result)
      XCTAssertEqual(result.rank, 1, course.title)
      XCTAssertLessThan(result.gap, 0, course.title)
      XCTAssertEqual(result.collisions, 0)
      XCTAssertTrue((30...90).contains(result.time))
    }
  }

  func testCompletedRaceIsImmutableAndCannotOverflow() throws {
    var race = RaceState(course: .riviera)
    while race.result == nil { race.step(0.1) }
    let result = try XCTUnwrap(race.result)
    race.move(to: 0)
    race.step(5)
    XCTAssertEqual(result, race.result)
    XCTAssertEqual(race.progress, 1)
    XCTAssertEqual(race.remaining, 0)
    XCTAssertEqual(race.distance, race.course.length)
  }

  func testLargeFrameIsCappedAndNegativeTimeIgnored() {
    var race = RaceState(course: .riviera)
    race.step(-4)
    XCTAssertEqual(race.elapsed, 0)
    race.step(10)
    XCTAssertEqual(race.elapsed, 0.1)
    XCTAssertLessThan(race.distance, 3)
  }

  @MainActor
  func testPreferencesAndRaceBookSurviveNewStore() throws {
    let name = "PocketPelotonTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
    defer { defaults.removePersistentDomain(forName: name) }
    let store = GameStore(defaults: defaults)
    store.sound = false
    store.haptics = false
    store.coached = true
    store.start()
    var date = Date()
    store.tick(date)
    for _ in 0..<1_000 where store.screen == .racing {
      date = date.addingTimeInterval(0.1)
      store.tick(date)
    }
    XCTAssertEqual(store.results.count, 1)
    let restored = GameStore(defaults: defaults)
    XCTAssertFalse(restored.sound)
    XCTAssertFalse(restored.haptics)
    XCTAssertTrue(restored.coached)
    XCTAssertEqual(restored.results, store.results)
    XCTAssertNotNil(restored.best(for: .riviera))
  }

  @MainActor
  func testPauseStopsClockAndReleasesSprint() {
    let store = GameStore()
    store.coached = true
    store.start()
    store.race.sprintHeld = true
    store.pause()
    let distance = store.race.distance
    store.tick(Date())
    store.tick(Date().addingTimeInterval(30))
    XCTAssertEqual(store.race.distance, distance)
    XCTAssertFalse(store.race.sprintHeld)
  }
}
