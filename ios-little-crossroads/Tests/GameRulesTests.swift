@testable import CrossroadsRules
import XCTest

final class GameRulesTests: XCTestCase {
    private func advance(_ game: GameRules, seconds: Double) {
        for _ in 0 ..< Int(ceil(seconds * 120)) {
            game.step(1.0 / 120)
        }
    }

    func testOneHopAwardsOneRowAndOneCoinOnlyOnce() {
        let game = GameRules(seed: 42)
        game.start()
        XCTAssertTrue(game.move(.forward))
        XCTAssertFalse(game.move(.forward))
        advance(game, seconds: 0.2)
        XCTAssertEqual(game.furthest, 1)
        XCTAssertEqual(game.coins, 1)
        game.move(.backward)
        advance(game, seconds: 0.2)
        game.move(.forward)
        advance(game, seconds: 0.2)
        XCTAssertEqual(game.furthest, 1)
        XCTAssertEqual(game.coins, 1)
    }

    func testPausedWorldDoesNotMoveOrAcceptInput() {
        let game = GameRules(seed: 1)
        game.start()
        game.move(.forward)
        advance(game, seconds: 0.05)
        game.pause()
        let time = game.time
        let position = game.visibleRow
        advance(game, seconds: 10)
        XCTAssertEqual(game.time, time)
        XCTAssertEqual(game.visibleRow, position)
        XCTAssertFalse(game.move(.left))
        game.resume()
        advance(game, seconds: 0.2)
        XCTAssertEqual(game.row, 1)
    }

    func testBoundsRejectSidewaysEscapeAndNegativeRows() {
        let game = GameRules(seed: 3)
        game.start()
        XCTAssertFalse(game.move(.backward))
        for _ in 0 ..< 3 {
            XCTAssertTrue(game.move(.left))
            advance(game, seconds: 0.2)
        }
        XCTAssertFalse(game.move(.left))
        XCTAssertEqual(game.x, -3)
    }

    func testCarsHaveSafeGapsAndEventuallyHitStationaryDuck() {
        let game = GameRules(seed: 12)
        game.start()
        game.move(.forward)
        advance(game, seconds: 0.2)
        game.move(.forward)
        advance(game, seconds: 0.2)
        XCTAssertEqual(game.state, .playing)
        XCTAssertEqual(game.row, 2)
        advance(game, seconds: 12)
        XCTAssertEqual(game.state, .finished)
        XCTAssertEqual(game.endReason, "A little traffic trouble")
        XCTAssertFalse(game.move(.forward))
    }

    func testRiverSupportMatchesLogExtentsAndMovesWithFlow() {
        let river = Lane(row: 6, kind: .river, speed: 0.5, phase: 0, coinColumn: nil)
        XCTAssertTrue(river.supports(0, at: 0))
        XCTAssertFalse(river.supports(2.1, at: 0))
        XCTAssertTrue(river.supports(1, at: 2))
        XCTAssertFalse(river.supports(3.1, at: 2))
        XCTAssertEqual(river.centers(at: 2)[3] - river.centers(at: 0)[3], 1, accuracy: 0.001)
    }

    func testCourseIsRepeatableAndAlwaysProvidesRestLanes() {
        for seed in 1 ... 200 {
            let first = Course(seed: UInt64(seed))
            let second = Course(seed: UInt64(seed))
            var danger = 0
            for row in 0 ... 250 {
                let lane = first.lane(row)
                XCTAssertEqual(lane.kind, second.lane(row).kind)
                XCTAssertEqual(lane.speed, second.lane(row).speed)
                danger = lane.kind == .meadow ? 0 : danger + 1
                XCTAssertLessThanOrEqual(danger, 2)
                if lane.kind == .river {
                    XCTAssertGreaterThan(lane.objectLength, 3)
                    XCTAssertLessThan(abs(lane.speed), 0.6)
                }
                if lane.kind == .road {
                    XCTAssertGreaterThan(lane.spacing - lane.objectLength, 4)
                    XCTAssertLessThan(abs(lane.speed), 1.8)
                }
                if let column = lane.coinColumn {
                    XCTAssertEqual(lane.kind, .meadow)
                    XCTAssertLessThanOrEqual(abs(column), 2)
                }
            }
        }
    }

    func testThreeCosmeticsUnlockThroughEitherProgressPath() {
        XCTAssertEqual(Plumage.allCases.count, 4)
        for plumage in Plumage.allCases where plumage != .sunshine {
            XCTAssertFalse(plumage.unlocked(coins: 0, best: 0))
            XCTAssertTrue(plumage.unlocked(coins: plumage.price, best: 0))
            XCTAssertTrue(plumage.unlocked(coins: 0, best: plumage.milestone))
        }
    }
}
