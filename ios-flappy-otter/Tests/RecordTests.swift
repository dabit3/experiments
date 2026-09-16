import Foundation
import XCTest

@testable import FlappyOtterCore

final class RecordTests: XCTestCase {
  func testRecordsNeverLoseBestAndCountZeroScoreFlights() {
    var record = FlightRecord()
    record.complete(score: 12)
    record.complete(score: 0)
    record.complete(score: 4)
    record.complete(score: -1)
    XCTAssertEqual(record.best, 12)
    XCTAssertEqual(record.flights, 3)
    XCTAssertEqual(record.totalGates, 16)
  }

  func testProgressAndPreferencesSurviveReload() throws {
    let suite = "FlappyOtter.tests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let storage = RecordStorage(defaults: defaults)
    XCTAssertEqual(storage.load(), FlightRecord())
    var record = FlightRecord()
    record.complete(score: 17)
    record.sound = false
    record.haptics = false
    storage.save(record)
    let reloaded = RecordStorage(defaults: try XCTUnwrap(UserDefaults(suiteName: suite)))
    XCTAssertEqual(reloaded.load(), record)
  }

  func testMalformedSavedDataFallsBackToNewRecord() throws {
    let suite = "FlappyOtter.tests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(Data("not json".utf8), forKey: "flappy-otter.record.v1")
    XCTAssertEqual(RecordStorage(defaults: defaults).load(), FlightRecord())
  }

  func testBadgeThresholdsAndNextGoals() {
    let cases: [(Int, FlightMedal, Int?)] = [
      (0, .firstSplash, 5), (4, .firstSplash, 5), (5, .riverRookie, 15),
      (14, .riverRookie, 15), (15, .smoothSailor, 30), (29, .smoothSailor, 30),
      (30, .otterAce, 50), (49, .otterAce, 50), (50, .riverLegend, nil),
      (100, .riverLegend, nil),
    ]
    for (score, medal, next) in cases {
      XCTAssertEqual(FlightMedal(score: score), medal)
      XCTAssertEqual(medal.nextTarget, next)
    }
  }
}
