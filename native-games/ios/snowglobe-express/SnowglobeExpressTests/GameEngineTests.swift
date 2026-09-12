import XCTest

@testable import SnowglobeExpress

final class GameEngineTests: XCTestCase {
  func testPushCostsFuelAndUndoRestoresTheWholeTurn() {
    var game = Journey(puzzle: .routes[0])
    let initial = game.position
    let preview = game.preview(.north)
    XCTAssertEqual(preview.depth, 1)
    XCTAssertEqual(preview.cost, 2)
    XCTAssertTrue(game.move(.north))
    XCTAssertEqual(game.position.snow[Square(column: 1, row: 2).index], 0)
    XCTAssertEqual(game.position.snow[Square(column: 1, row: 1).index], 1)
    XCTAssertEqual(game.position.fuelUsed, 2)
    game.undo()
    XCTAssertEqual(game.position, initial)
    XCTAssertTrue(game.history.isEmpty)
  }

  func testBlockedTreeAndOverflowMovesAreAtomic() {
    var game = Journey(puzzle: .routes[0])
    XCTAssertFalse(game.move(.west))
    XCTAssertEqual(game.position.fuelUsed, 0)
    game.position.snow[Square(column: 1, row: 2).index] = 2
    game.position.snow[Square(column: 1, row: 1).index] = 2
    let before = game
    XCTAssertFalse(game.move(.north))
    XCTAssertEqual(game, before)
  }

  func testSnowSpillsAtBoundaryAndCannotBePushedIntoTrees() {
    var game = Journey(puzzle: .routes[0])
    game.position.van = Square(column: 1, row: 1)
    game.position.snow[Square(column: 1, row: 0).index] = 3
    XCTAssertTrue(game.move(.north))
    XCTAssertEqual(game.position.snow[Square(column: 1, row: 0).index], 0)
    XCTAssertEqual(game.position.fuelUsed, 4)
    game.position.van = Square(column: 1, row: 3)
    game.position.snow[Square(column: 1, row: 2).index] = 1
    game.position.van = Square(column: 0, row: 2)
    XCTAssertFalse(game.preview(.east).allowed)
  }

  func testPriorityHomeMustBeDeliveredBeforeOtherHomes() {
    var game = Journey(puzzle: .routes[0])
    XCTAssertTrue(game.move(.east))
    XCTAssertTrue(game.move(.east))
    XCTAssertTrue(game.position.delivered.isEmpty)
    game.position.van = Square(column: 1, row: 0)
    XCTAssertTrue(game.move(.south))
    XCTAssertEqual(game.position.delivered.count, 1)
    game.position.van = Square(column: 3, row: 2)
    XCTAssertTrue(game.move(.south))
    XCTAssertEqual(game.position.delivered.count, 2)
  }

  func testEveryAuthoredRouteHasAnAchievableThreeStarSolution() {
    for puzzle in Puzzle.routes {
      var game = Journey(puzzle: puzzle)
      let routes: [[Direction]] = [
        [.north, .north, .east, .east, .south, .south],
        [.north, .north, .east, .east, .south, .south],
        [.north, .north, .east, .east, .north, .south, .south, .south],
        [.north, .north, .east, .east, .south, .south, .west, .west, .south],
        [.north, .north, .west, .east, .east, .east, .south, .south],
        [.north, .north, .east, .east, .east, .south, .south, .west],
      ]
      let solution = routes[puzzle.number - 1].map { direction in
        guard puzzle.number.isMultiple(of: 2) else { return direction }
        return direction == .east ? Direction.west : direction == .west ? .east : direction
      }
      for direction in solution {
        XCTAssertTrue(game.move(direction), "Route \(puzzle.number): \(direction)")
      }
      XCTAssertTrue(game.won, "Route \(puzzle.number)")
      XCTAssertEqual(game.stars, 3, "Route \(puzzle.number), fuel \(game.position.fuelUsed)")
      XCTAssertGreaterThan(game.score, 0)
      XCTAssertFalse(game.move(.north))
    }
  }

  func testAffordableMovesAndWinOnLastFuel() {
    let route = Puzzle.routes[0]
    let exact = Puzzle(
      id: "exact", number: 1, name: "Exact", subtitle: "", start: route.start,
      homes: route.homes, trees: route.trees, snow: route.snow, fuel: 8, par: 8)
    var game = Journey(puzzle: exact)
    for direction in [Direction.north, .north, .east, .east, .south, .south] {
      XCTAssertTrue(game.move(direction))
    }
    XCTAssertEqual(game.fuelLeft, 0)
    XCTAssertTrue(game.won)
    XCTAssertFalse(game.stranded)
    var failure = Journey(puzzle: exact)
    failure.position.fuelUsed = 8
    XCTAssertTrue(failure.stranded)
    let before = failure
    XCTAssertFalse(failure.move(.north))
    XCTAssertEqual(failure, before)
  }

  func testDailySeedIsStableAcrossTimeOfDayAndUsesUTC() {
    let start = Date(timeIntervalSince1970: 1_789_171_200)
    let first = Puzzle.daily(on: start)
    XCTAssertEqual(first, Puzzle.daily(on: start.addingTimeInterval(3_600)))
    XCTAssertNotEqual(first.id, Puzzle.daily(on: start.addingTimeInterval(86_400)).id)
    XCTAssertEqual(first.snow.count, 25)
  }

  func testPersistenceResumesUndoAndKeepsPersonalBest() throws {
    let suite = "SnowglobeTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = LocalStore(defaults: defaults)
    var game = Journey(puzzle: .routes[0])
    XCTAssertTrue(game.move(.north))
    store.save(game)
    var loaded = try XCTUnwrap(LocalStore(defaults: defaults).resume())
    XCTAssertEqual(loaded, game)
    loaded.undo()
    XCTAssertEqual(loaded.position, Journey(puzzle: .routes[0]).position)
    for direction in [Direction.north, .east, .east, .south, .south] {
      XCTAssertTrue(game.move(direction))
    }
    store.record(game)
    XCTAssertEqual(store.loadProgress()["route-1"]?.stars, 3)
    let score = game.score
    game.position.fuelUsed += 6
    store.record(game)
    XCTAssertEqual(store.loadProgress()["route-1"]?.score, score)
    XCTAssertEqual(store.loadProgress()["route-1"]?.stars, 3)
    store.save(nil)
    XCTAssertNil(store.resume())
  }

  func testCorruptSaveFallsBackToFreshHome() throws {
    let suite = "SnowglobeTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(Data("not-json".utf8), forKey: "village.journey")
    XCTAssertNil(LocalStore(defaults: defaults).resume())
  }
}
