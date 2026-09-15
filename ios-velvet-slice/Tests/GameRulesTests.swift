@testable import VelvetRules
import XCTest

final class GameRulesTests: XCTestCase {
    func testSweptSliceCatchesFruitBetweenTouchSamples() {
        XCTAssertTrue(SliceGeometry.intersects(from: .init(x: 0, y: 0), to: .init(x: 200, y: 0), center: .init(x: 100, y: 15), radius: 20))
        XCTAssertFalse(SliceGeometry.intersects(from: .init(x: 0, y: 0), to: .init(x: 40, y: 0), center: .init(x: 100, y: 0), radius: 20))
        XCTAssertFalse(SliceGeometry.intersects(from: .init(x: 0, y: 0), to: .init(x: 0, y: 0), center: .init(x: 0, y: 0), radius: 20))
    }

    func testComboAndPenaltiesNeverMakeNegativeScore() {
        var round = RoundRules(mode: .arcade)
        for _ in 0 ..< 4 {
            round.slice()
        }
        XCTAssertEqual(round.combo(4), 20)
        XCTAssertEqual(round.score, 60)
        round.hitBomb()
        round.miss()
        XCTAssertEqual(round.score, 33)
        round.hitBomb()
        round.hitBomb()
        XCTAssertTrue(round.finished)
        XCTAssertEqual(round.score, 0)
        round.slice()
        XCTAssertEqual(round.sliced, 4)
    }

    func testTimedRoundStopsAndPracticeDoesNot() {
        var arcade = RoundRules(mode: .arcade)
        arcade.advance(59)
        XCTAssertFalse(arcade.finished)
        arcade.advance(2)
        XCTAssertTrue(arcade.finished)
        XCTAssertEqual(arcade.remaining, 0)
        var practice = RoundRules(mode: .practice)
        practice.advance(900)
        practice.slice()
        practice.miss()
        practice.hitBomb()
        XCTAssertFalse(practice.finished)
        XCTAssertEqual(practice.score, 10)
        XCTAssertEqual(practice.bombs, 0)
        practice.finish()
        XCTAssertTrue(practice.finished)
    }

    func testWaveProgressionKeepsOnboardingSafeAndCapsDensity() {
        for wave in 0 ..< 100 {
            let arcade = WavePlan(wave: wave, mode: .arcade)
            XCTAssertTrue((3 ... 5).contains(arcade.fruitCount))
            XCTAssertGreaterThanOrEqual(arcade.interval, 1.8)
            if wave < 3 {
                XCTAssertNil(arcade.bombLane)
            }
            XCTAssertNil(WavePlan(wave: wave, mode: .practice).bombLane)
        }
    }
}
