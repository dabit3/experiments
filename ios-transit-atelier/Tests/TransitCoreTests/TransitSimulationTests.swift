import XCTest

@testable import TransitCore

final class TransitSimulationTests: XCTestCase {
  func testTrainDeliversToMatchingShapesAndConservesPassengers() {
    var game = TransitSimulation(city: .harbour, seed: 42)
    XCTAssertTrue(game.setRoute(0, stops: [0, 1, 2, 3]))
    game.stations[0].waiting = [.triangle, .square, .circle]
    game.generated = 3
    for _ in 0..<400 { game.tick(0.1) }
    XCTAssertGreaterThan(game.delivered, 1)
    XCTAssertEqual(game.generated, game.delivered + game.waitingCount + game.aboardCount)
  }

  func testRedrawingReturnsPassengersInsteadOfDeletingThem() {
    var game = TransitSimulation(city: .harbour, seed: 1)
    game.setRoute(0, stops: [0, 1, 2])
    game.stations[0].waiting = [.triangle, .square]
    game.generated = 2
    game.tick(1)
    XCTAssertEqual(game.aboardCount, 2)
    game.setRoute(0, stops: [0, 2])
    XCTAssertEqual(game.waitingCount + game.aboardCount, 2)
  }

  func testTunnelLimitRejectsAtomically() {
    var game = TransitSimulation(city: .harbour, seed: 1)
    game.tunnels = 0
    XCTAssertFalse(game.setRoute(0, stops: [0, 2]))
    XCTAssertEqual(game.routes[0].stops, [])
    XCTAssertTrue(game.setRoute(0, stops: [0, 1]))
  }

  func testPassengersCanTransferAcrossLines() {
    var game = TransitSimulation(city: .harbour, seed: 9)
    game.setRoute(0, stops: [0, 1])
    game.setRoute(1, stops: [1, 2])
    XCTAssertEqual(game.distance(from: 0, to: .square), 2)
    game.stations[0].waiting = [.square, .square, .square]
    game.generated = 3
    for _ in 0..<450 { game.tick(0.1) }
    XCTAssertGreaterThanOrEqual(game.delivered, 3)
    XCTAssertEqual(game.generated, game.delivered + game.waitingCount + game.aboardCount)
  }

  func testOvercrowdingEndsRunAndRetryStartsClean() {
    var game = TransitSimulation(city: .harbour, seed: 42)
    game.stations[0].waiting = Array(repeating: .square, count: 14)
    for _ in 0..<260 { game.tick(0.1) }
    XCTAssertTrue(game.isOver)
    XCTAssertFalse(game.completed)
    XCTAssertEqual(game.failedStation?.id, 0)
    let retry = TransitSimulation(city: game.city, seed: 42)
    XCTAssertFalse(retry.isOver)
    XCTAssertEqual(retry.delivered, 0)
    XCTAssertEqual(retry.stations.count, 4)
  }

  func testGrowthUpgradePauseAndChoice() {
    var game = TransitSimulation(city: .estuary, seed: 99)
    for _ in 0..<510 { game.tick(0.1) }
    XCTAssertEqual(game.stations.count, 5)
    XCTAssertTrue(game.upgradePending)
    let time = game.elapsed
    game.tick(1)
    XCTAssertEqual(game.elapsed, time)
    game.choose(.line)
    XCTAssertEqual(game.routes.count, 3)
    game.tick(1)
    XCTAssertGreaterThan(game.elapsed, time)
  }

  func testSaveRoundTripAndSeededDeterminism() throws {
    var first = TransitSimulation(city: .estuary, seed: 123)
    first.setRoute(0, stops: [0, 1, 2, 3])
    for _ in 0..<350 { first.tick(0.1) }
    let data = try JSONEncoder().encode(first)
    var restored = try JSONDecoder().decode(TransitSimulation.self, from: data)
    for _ in 0..<90 {
      first.tick(0.1)
      restored.tick(0.1)
    }
    XCTAssertEqual(first.delivered, restored.delivered)
    XCTAssertEqual(first.stations.map(\.waiting), restored.stations.map(\.waiting))
    XCTAssertEqual(first.trains.map(\.progress), restored.trains.map(\.progress))
  }

  func testBothMapsConservePassengersInLongSyntheticNetworks() {
    for city in City.allCases {
      var game = TransitSimulation(city: city, seed: 77)
      game.tunnels = 30
      var previousCount = 0
      for _ in 0..<3_100 {
        if game.stations.count != previousCount {
          previousCount = game.stations.count
          game.setRoute(0, stops: Array(0..<min(6, previousCount)))
          if previousCount > 5 {
            game.setRoute(1, stops: [1, 2] + Array(5..<previousCount))
          }
        }
        if game.upgradePending { game.choose(.carriage) }
        game.tick(0.1)
      }
      XCTAssertEqual(game.generated, game.delivered + game.waitingCount + game.aboardCount)
      XCTAssertTrue(game.isOver)
      XCTAssertGreaterThan(game.delivered, 20)
    }
  }

  func testInvalidRoutesAndRepeatedStopsAreRejected() {
    var game = TransitSimulation(city: .harbour, seed: 1)
    XCTAssertFalse(game.setRoute(0, stops: [0, 99]))
    XCTAssertFalse(game.setRoute(0, stops: [0, 0]))
    XCTAssertFalse(game.setRoute(99, stops: [0, 1]))
    XCTAssertTrue(game.trains.isEmpty)
  }
}
