import XCTest

@testable import DuskAngler

final class GameRulesTests: XCTestCase {
  func testCastMustLandNearASilhouette() {
    XCTAssertEqual(Casting.target(x: 0.24, y: 0.29), 0)
    XCTAssertEqual(Casting.target(x: 0.72, y: 0.50), 1)
    XCTAssertEqual(Casting.target(x: 0.40, y: 0.75), 2)
    XCTAssertNil(Casting.target(x: 0.98, y: 0.02))
  }

  func testHoldingThroughSurgeSnapsTheLine() {
    var duel = Duel(species: .moonKoi)
    for _ in 0..<300 { duel.step(seconds: 0.05, reeling: true) }
    XCTAssertEqual(duel.outcome, .snapped)
    XCTAssertLessThan(duel.landed, 1)
  }

  func testNeverReelingLosesFishToSlack() {
    var duel = Duel(species: .emberPerch)
    for _ in 0..<600 { duel.step(seconds: 0.05, reeling: false) }
    XCTAssertEqual(duel.outcome, .escaped)
  }

  func testEverySpeciesCanBeLandedByManagingTension() {
    for species in Species.allCases {
      var duel = Duel(species: species)
      for _ in 0..<900 where duel.outcome == .active {
        let reel = !duel.surging && duel.tension < 0.65
        duel.step(seconds: 0.05, reeling: reel)
      }
      XCTAssertEqual(duel.outcome, .caught, species.name)
      XCTAssertGreaterThan(duel.score, 100)
    }
  }

  func testWarningPrecedesSurgeAndTerminalStatesAreStable() {
    var duel = Duel(species: .ribbonTrout)
    duel.elapsed = 3.4
    XCTAssertTrue(duel.warning)
    XCTAssertFalse(duel.surging)
    duel.elapsed = 4.6
    XCTAssertTrue(duel.surging)
    duel.outcome = .snapped
    let tension = duel.tension
    duel.step(seconds: 0.05, reeling: true)
    XCTAssertEqual(duel.tension, tension)
  }

  func testProgressUnlocksLakeAndPreservesBestAcrossEncoding() throws {
    var progress = Progress()
    for score in [1200, 600, 900] {
      progress.add(
        CatchRecord(
          id: UUID(), species: .moonKoi, lake: .amber, length: 67, score: score, date: Date()))
    }
    let restored = try JSONDecoder().decode(Progress.self, from: JSONEncoder().encode(progress))
    XCTAssertTrue(restored.violetUnlocked)
    XCTAssertEqual(restored.best, 1200)
    XCTAssertEqual(restored.bait, 6)
    XCTAssertEqual(restored.total, 3)
  }

  @MainActor
  func testPauseFreezesBiteAndBaitIsOnlySpentOnValidCast() throws {
    let suite = "DuskAnglerTests-\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = GameStore(defaults: defaults)
    store.sound = false
    store.haptics = false
    store.progress.bait = 2
    store.begin()
    store.useBait = true
    store.aim = CGPoint(x: 1, y: 0)
    store.cast()
    XCTAssertEqual(store.progress.bait, 2)
    store.begin()
    store.cast()
    XCTAssertEqual(store.progress.bait, 0)
    XCTAssertEqual(store.duel.species, .moonKoi)
    store.pause()
    for _ in 0..<80 { store.tick(0.05) }
    XCTAssertEqual(store.phase, .waiting)
    store.paused = false
    for _ in 0..<31 { store.tick(0.05) }
    XCTAssertEqual(store.phase, .bite)
  }
}
