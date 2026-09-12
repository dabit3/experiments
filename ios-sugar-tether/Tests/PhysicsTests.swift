import Foundation
import Testing

@testable import SugarTetherRules

@Test func threadIntersectionRespectsFiniteSegments() {
  #expect(
    PhysicsGame.intersects(
      V(x: 0, y: 20), V(x: 30, y: 20),
      V(x: 15, y: 0), V(x: 15, y: 40)))
  #expect(
    !PhysicsGame.intersects(
      V(x: 0, y: 20), V(x: 10, y: 20),
      V(x: 15, y: 0), V(x: 15, y: 40)))
}

@Test func intactThreadHoldsCandy() {
  var game = PhysicsGame(puzzle: Puzzle.all[0])
  for _ in 0..<600 { game.advance(1.0 / 60) }
  #expect(game.position.distance(Puzzle.all[0].candy) < 0.1)
  #expect(game.outcome == .playing)
}

@Test func progressionNeverLosesEarnedStars() {
  var progress = Progress()
  #expect(!progress.unlocked(1))
  progress.record(level: 0, stars: 3)
  progress.record(level: 0, stars: 1)
  #expect(progress.totalStars == 3)
  #expect(progress.unlocked(1))
  let data = try! JSONEncoder().encode(progress)
  #expect(try! JSONDecoder().decode(Progress.self, from: data) == progress)
}

@Test func eachPuzzleHasAnInputOnlyThreeStarSolution() {
  for index in Puzzle.all.indices {
    let game = solve(index)
    #expect(game.outcome == .fed, "Puzzle \(index + 1): \(game.position)")
    #expect(game.collected.count == 3, "Puzzle \(index + 1): \(game.collected)")
  }
}

func solve(_ index: Int) -> PhysicsGame {
  var game = PhysicsGame(puzzle: Puzzle.all[index])
  for frame in 0..<1200 {
    let time = Double(frame) / 120
    switch index {
    case 0, 1, 5:
      if frame == 0 { game.cut(from: V(x: 30, y: 100), to: V(x: 330, y: 100)) }
    case 2:
      if time >= 1.85 && game.cuts == 0 {
        game.cut(from: V(x: 40, y: 125), to: V(x: 320, y: 125))
      }
    case 3, 7:
      if frame == 0 {
        game.cut(from: V(x: 20, y: 100), to: V(x: 210, y: 100))
        game.puff()
      }
    case 4, 6:
      if frame == 0 { game.cut(from: V(x: 30, y: 370), to: V(x: 330, y: 370)) }
      if game.position.y < 119 { game.pop(at: game.position) }
    default: break
    }
    game.advance(1.0 / 120)
    if game.outcome != .playing { break }
  }
  return game
}

@Test func hazardAndOutOfBoundsLose() {
  var game = PhysicsGame(puzzle: Puzzle.all[5])
  for _ in 0..<96 { game.advance(1.0 / 120) }
  game.cut(from: V(x: 30, y: 100), to: V(x: 330, y: 100))
  for _ in 0..<240 { game.advance(1.0 / 120) }
  #expect(game.outcome == .missed)
}

@Test func longFrameDoesNotTeleportAndFinishedGamesFreeze() {
  var game = solve(0)
  let point = game.position
  game.advance(20)
  #expect(game.position == point)
  var suspended = PhysicsGame(puzzle: Puzzle.all[0])
  suspended.cut(from: V(x: 30, y: 100), to: V(x: 330, y: 100))
  suspended.advance(20)
  #expect(suspended.position.y < 150)
}

@Test func lossFeedbackDistinguishesThornsFromEscapingBubbles() {
  var bubble = PhysicsGame(puzzle: Puzzle.all[4])
  bubble.cut(from: V(x: 30, y: 370), to: V(x: 330, y: 370))
  for _ in 0..<1200 { bubble.advance(1.0 / 120) }
  #expect(bubble.outcome == .missed)
  #expect(bubble.lossReason == .bubbleEscaped)
  let reason = bubble.lossReason
  bubble.advance(20)
  #expect(bubble.lossReason == reason)

  var hazard = PhysicsGame(puzzle: Puzzle.all[5])
  for _ in 0..<96 { hazard.advance(1.0 / 120) }
  hazard.cut(from: V(x: 30, y: 100), to: V(x: 330, y: 100))
  for _ in 0..<240 { hazard.advance(1.0 / 120) }
  #expect(hazard.outcome == .missed)
  #expect(hazard.lossReason == .thorn)
  #expect(solve(4).lossReason == nil)
}
