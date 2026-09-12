import XCTest

@testable import OrchardSiege

final class OrchardRulesTests: XCTestCase {
  func testStarsRequireVictoryAndRewardShotEfficiency() {
    XCTAssertEqual(Rules.stars(won: false, shotsUsed: 0, par: 2), 0)
    XCTAssertEqual(Rules.stars(won: true, shotsUsed: 1, par: 2), 3)
    XCTAssertEqual(Rules.stars(won: true, shotsUsed: 2, par: 2), 2)
    XCTAssertEqual(Rules.stars(won: true, shotsUsed: 3, par: 2), 1)
  }

  func testUnusedFruitBonusIsOnlyGrantedOnVictory() {
    XCTAssertEqual(Rules.finalScore(destruction: 2450, shotsRemaining: 2, won: true), 5450)
    XCTAssertEqual(Rules.finalScore(destruction: 2450, shotsRemaining: 2, won: false), 2450)
    XCTAssertEqual(Rules.finalScore(destruction: 2450, shotsRemaining: -1, won: true), 2450)
  }

  func testElasticPullCannotExceedItsRadius() {
    for x in stride(from: -500.0, through: 500, by: 25) {
      for y in stride(from: -500.0, through: 500, by: 25) {
        let pull = Rules.clampedPull(dx: x, dy: y)
        XCTAssertLessThanOrEqual(hypot(pull.x, pull.y), 115.0001)
        XCTAssertLessThanOrEqual(pull.x, 12)
        XCTAssertLessThanOrEqual(pull.y, 55)
        XCTAssertGreaterThanOrEqual(pull.y, -110)
      }
    }
  }

  func testShotHasGuaranteedTimeoutEvenWhenPhysicsNeverSleeps() {
    XCTAssertFalse(Rules.shouldEndShot(elapsed: 1, speed: 0, quietTime: 10))
    XCTAssertFalse(Rules.shouldEndShot(elapsed: 3, speed: 0, quietTime: 0.2))
    XCTAssertTrue(Rules.shouldEndShot(elapsed: 3, speed: 10, quietTime: 1.5))
    XCTAssertTrue(Rules.shouldEndShot(elapsed: 9, speed: 950, quietTime: 0))
  }

  func testAllAuthoredFortsArePlayableAndHaveDistinctLayouts() {
    XCTAssertEqual(Level.all.count, 6)
    XCTAssertEqual(Set(Level.all.map(\.name)).count, 6)
    for level in Level.all {
      XCTAssertFalse(level.targets.isEmpty)
      XCTAssertGreaterThanOrEqual(level.fruit.count, level.par)
      XCTAssertGreaterThanOrEqual(level.par, 2)
      XCTAssertFalse(level.blocks.isEmpty)
      for block in level.blocks {
        XCTAssertGreaterThanOrEqual(block.y - block.height / 2, 135)
        XCTAssertLessThan(block.x + block.width / 2, 1350)
        XCTAssertGreaterThan(block.width, 0)
        XCTAssertGreaterThan(block.height, 0)
      }
      for target in level.targets {
        XCTAssertGreaterThan(target.x, 700)
        XCTAssertLessThan(target.y, 550)
      }
    }
  }

  func testCampaignIntroducesEveryFruitAndMaterial() {
    XCTAssertEqual(Set(Level.all.flatMap(\.fruit)), [.apple, .plum, .pear])
    XCTAssertEqual(Set(Level.all.flatMap(\.blocks).map(\.material)), [.wood, .glass, .stone])
    XCTAssertEqual(Level.all[2].fruit.first, .plum)
  }

  func testPestsDoNotStartEmbeddedInRigidBodies() {
    for level in Level.all {
      for target in level.targets {
        for block in level.blocks {
          let dx = max(0, abs(target.x - block.x) - block.width / 2)
          let dy = max(0, abs(target.y - 2 - block.y) - block.height / 2)
          XCTAssertGreaterThanOrEqual(hypot(dx, dy), 22.99, level.name)
        }
      }
    }
  }
}
