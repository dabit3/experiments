import XCTest

@testable import MidnightRules

final class RulesTests: XCTestCase {
    func testRackHasNoOverlapsAndEightCentered() {
        let table = Table()
        XCTAssertEqual(Set(table.balls.map(\.id)), Set(0...15))
        XCTAssertEqual(table.balls.first { $0.id == 8 }?.position.y, 150)
        for first in table.balls {
            for second in table.balls where first.id != second.id {
                XCTAssertGreaterThanOrEqual(
                    (first.position - second.position).length, Table.radius * 2)
            }
        }
    }

    func testHeadOnCollisionTransfersMomentum() {
        var table = Table()
        table.balls = [
            Ball(id: 0, position: Vector(x: 100, y: 150), velocity: Vector(x: 300, y: 0)),
            Ball(id: 1, position: Vector(x: 118, y: 150)),
        ]
        for _ in 0..<5 { table.step(1 / 240) }
        XCTAssertEqual(table.events.firstContact, 1)
        XCTAssertGreaterThan(table.balls[1].velocity.x, 270)
        XCTAssertLessThan(abs(table.cue.velocity.x), 15)
    }

    func testCushionReflectsAndLosesEnergy() {
        var table = Table()
        table.balls = [Ball(id: 0, position: Vector(x: 20, y: 120), velocity: Vector(x: -300, y: 0))]
        for _ in 0..<15 { table.step(1 / 240) }
        XCTAssertGreaterThan(table.cue.velocity.x, 0)
        XCTAssertLessThan(table.cue.velocity.x, 260)
        XCTAssertTrue(table.events.railBalls.contains(0))
    }

    func testPocketCapturesOnlyOnce() {
        var table = Table()
        table.balls = [Ball(id: 0, position: Vector(x: 300, y: 25), velocity: Vector(x: 0, y: -100))]
        for _ in 0..<120 { table.step(1 / 240) }
        XCTAssertTrue(table.cue.pocketed)
        XCTAssertEqual(table.events.pots.count, 1)
        XCTAssertTrue(table.events.scratch)
        XCTAssertFalse(table.moving)
    }

    func testBreakProducesRealInteractionsAndSettles() {
        var game = GameEngine(mode: .match)
        game.shoot(angle: 0, power: 0.95)
        for _ in 0..<2400 where game.shooting { game.tick(1 / 120) }
        XCTAssertFalse(game.shooting)
        XCTAssertEqual(game.table.events.firstContact, 1)
        XCTAssertGreaterThan(game.table.events.railBalls.count, 3)
        XCTAssertFalse(game.isBreak)
        XCTAssertFalse(game.finished)
    }

    func testBallInHandRejectsOverlapAndKitchenViolations() {
        let table = Table()
        XCTAssertFalse(table.canPlace(Vector(x: 427, y: 150)))
        XCTAssertFalse(table.canPlace(Vector(x: 200, y: 50), kitchen: true))
        XCTAssertTrue(table.canPlace(Vector(x: 70, y: 50), kitchen: true))
        XCTAssertFalse(table.canPlace(Vector(x: 5, y: 5)))
    }

    func testScratchSwitchesTurnAndRestoresCue() {
        var game = preparedMatch()
        game.table.events.firstContact = 1
        game.table.events.pots = [(0, 0)]
        game.table.balls[0].pocketed = true
        game.resolveShot()
        XCTAssertEqual(game.turn, 1)
        XCTAssertTrue(game.ballInHand)
        XCTAssertFalse(game.table.cue.pocketed)
        XCTAssertTrue(game.table.canPlace(game.table.cue.position))
    }

    func testWrongFirstContactIsFoulEvenWhenOwnBallPotted() {
        var game = preparedMatch()
        game.humanGroup = .solids
        game.legalAtStart = Set(1...7)
        game.table.events.firstContact = 10
        game.table.events.pots = [(1, 0)]
        game.resolveShot()
        XCTAssertEqual(game.turn, 1)
        XCTAssertTrue(game.ballInHand)
    }

    func testNoRailAfterContactIsFoul() {
        var game = preparedMatch()
        game.table.events.firstContact = 1
        game.resolveShot()
        XCTAssertTrue(game.ballInHand)
        XCTAssertEqual(game.turn, 1)
    }

    func testLegalMissSwitchesTurnWithoutFoul() {
        var game = preparedMatch()
        game.table.events.firstContact = 1
        game.table.events.railAfterContact = true
        game.resolveShot()
        XCTAssertFalse(game.ballInHand)
        XCTAssertEqual(game.turn, 1)
    }

    func testAssignmentAndRetainedTurn() {
        var game = preparedMatch()
        game.table.events.firstContact = 10
        game.table.events.pots = [(10, 1)]
        game.resolveShot()
        XCTAssertEqual(game.humanGroup, .stripes)
        XCTAssertEqual(game.turn, 0)
    }

    func testBreakDoesNotAssignGroupAndRespotsEight() {
        var game = GameEngine(mode: .match)
        game.shoot(angle: 0, power: 0.9)
        game.table.events.firstContact = 1
        game.table.events.pots = [(8, 1), (3, 2)]
        let index = game.table.balls.firstIndex { $0.id == 8 }!
        game.table.balls[index].pocketed = true
        game.resolveShot()
        XCTAssertNil(game.humanGroup)
        XCTAssertFalse(game.finished)
        XCTAssertFalse(game.table.balls[index].pocketed)
    }

    func testEarlyEightLoses() {
        var game = preparedMatch()
        game.table.events.firstContact = 1
        game.table.events.pots = [(8, 1)]
        game.resolveShot()
        XCTAssertTrue(game.finished)
        XCTAssertFalse(game.humanWon)
    }

    func testCalledEightWinsAndWrongPocketLoses() {
        for pocket in [1, 2] {
            var game = preparedMatch()
            game.legalAtStart = [8]
            game.calledPocket = 1
            game.table.events.firstContact = 8
            game.table.events.pots = [(8, pocket)]
            game.resolveShot()
            XCTAssertTrue(game.finished)
            XCTAssertEqual(game.humanWon, pocket == 1)
        }
    }

    func testScratchOnCalledEightLoses() {
        var game = preparedMatch()
        game.legalAtStart = [8]
        game.calledPocket = 1
        game.table.events.firstContact = 8
        game.table.events.pots = [(8, 1), (0, 3)]
        game.resolveShot()
        XCTAssertTrue(game.finished)
        XCTAssertFalse(game.humanWon)
    }

    func testSoloStreakAndScratchPenalty() {
        var game = GameEngine(mode: .challenge)
        game.table.events.pots = [(1, 0)]
        game.resolveShot()
        XCTAssertEqual(game.score, 100)
        game.table.events.pots = [(2, 1), (3, 2)]
        game.resolveShot()
        XCTAssertEqual(game.score, 500)
        XCTAssertEqual(game.longestStreak, 2)
        game.table.events.pots = [(0, 0)]
        game.resolveShot()
        XCTAssertEqual(game.score, 450)
        XCTAssertEqual(game.streak, 0)
        XCTAssertTrue(game.ballInHand)
    }

    func testClockFinishesAfterCurrentShotSettles() {
        var game = GameEngine(mode: .challenge)
        game.secondsRemaining = 0.02
        game.shoot(angle: 0, power: 0.8)
        game.tick(0.04)
        XCTAssertFalse(game.finished)
        XCTAssertEqual(game.secondsRemaining, 0)
        for _ in 0..<2400 where !game.finished { game.tick(1 / 120) }
        XCTAssertTrue(game.finished)
        XCTAssertFalse(game.shooting)
    }

    func testAICanPotAnUnobstructedShotUsingPhysics() {
        var game = GameEngine(mode: .challenge)
        game.isBreak = false
        game.table.balls = [
            Ball(id: 0, position: Vector(x: 180, y: 150)),
            Ball(id: 1, position: Vector(x: 300, y: 85)),
            Ball(id: 2, position: Vector(x: 490, y: 220)),
        ]
        let shot = game.bestShot()
        XCTAssertGreaterThan(shot.quality, 0)
        game.shoot(angle: shot.angle, power: shot.power)
        for _ in 0..<2400 where game.shooting { game.tick(1 / 120) }
        XCTAssertGreaterThan(game.pots, 0)
        XCTAssertGreaterThan(game.score, 0)
    }

    func testAimTracePredictsFirstBall() {
        let table = Table()
        let trace = table.trace(angle: 0)
        XCTAssertEqual(trace.ball, 1)
        XCTAssertEqual(trace.end.x, 410, accuracy: 0.01)
    }

    private func preparedMatch() -> GameEngine {
        var game = GameEngine(mode: .match)
        game.isBreak = false
        game.shoot(angle: 0, power: 0.5)
        return game
    }
}
