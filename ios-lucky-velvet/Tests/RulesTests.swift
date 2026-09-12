import Foundation
import Testing

@testable import LuckyVelvetRules

func card(_ rank: Int, _ suit: Suit = .spades) -> Card { Card(rank: rank, suit: suit) }

@Test func recognizesPokerCategoriesAndWheel() {
  let cases: [([Card], HandKind)] = [
    ([card(14), card(2), card(3), card(4), card(5)], .straightFlush),
    ([card(14), card(2, .hearts), card(3), card(4), card(5)], .straight),
    ([card(9), card(9, .hearts), card(9, .clubs), card(9, .diamonds), card(4)], .four),
    ([card(9), card(9, .hearts), card(9, .clubs), card(4), card(4, .clubs)], .fullHouse),
    ([card(2), card(4), card(7), card(9), card(13)], .flush),
    ([card(2), card(2, .clubs), card(7), card(7, .clubs), card(13)], .twoPair),
    ([card(2), card(2, .clubs), card(2, .hearts), card(7), card(13)], .three),
    ([card(2), card(2, .clubs), card(7), card(9), card(13)], .pair),
  ]
  for (cards, expected) in cases { #expect(PokerHand.evaluate(cards)?.kind == expected) }
  #expect(PokerHand.evaluate([]) == nil)
  #expect(PokerHand.evaluate([card(2), card(2)]) == nil)
}

@Test func onlyScoringCardsContributeAndMultipliersCompose() throws {
  let cards = [card(10, .hearts), card(10, .diamonds), card(14)]
  let score = try #require(
    Scoring.score(
      cards, charms: [.ribbon, .ruby, .velvet, .echo],
      money: 5, handsLeft: 4, previous: .pair))
  #expect(score.chips == 30)
  #expect(score.mult == 27)
  #expect(score.total == 810)
  #expect(score.hand.scoringCards.count == 2)
}

@Test func allCharmsHaveDistinctMeaningfulTriggers() throws {
  let redPair = [card(12, .hearts), card(12, .diamonds)]
  let blackPair = [card(12), card(12, .clubs)]
  let straight = (6...10).map { card($0, .hearts) }
  for charm in Charm.allCases {
    let cards =
      [.moon].contains(charm) ? blackPair : [.compass, .rose].contains(charm) ? straight : redPair
    let base = try #require(
      Scoring.score(cards, charms: [], money: 12, handsLeft: 1, previous: .pair))
    let modified = try #require(
      Scoring.score(cards, charms: [charm], money: 12, handsLeft: 1, previous: .pair))
    #expect(modified.total > base.total, "\(charm.name) must activate")
  }
}

@Test func noDuplicateCardsAndNoInvalidActions() {
  for seed: UInt64 in 1...100 {
    var run = Run(seed: seed)
    #expect(Set(run.hand + run.deck).count == 52)
    #expect(run.hand.count == 8)
    #expect(run.play(["fake"]) == nil)
    #expect(run.hands == 4)
    let invalidDiscard = run.discard([])
    #expect(!invalidDiscard)
    let ids = Set(run.hand.prefix(5).map(\.id))
    let discarded = run.discard(ids)
    #expect(discarded)
    #expect(run.discards == 2)
    #expect(run.deck.count == 39)
    #expect(run.hand.allSatisfy { !ids.contains($0.id) })
  }
}

@Test func blindCompletionEconomyProgressionAndLoss() throws {
  var run = Run(seed: 44)
  run.hand = (10...14).map { card($0) }
  let played = run.play(Set(run.hand.map(\.id)))
  let result = try #require(played)
  #expect(result.total > run.target)
  #expect(run.phase == .shop)
  #expect(run.cleared == 1)
  #expect(run.money == 14)
  let offer = try #require(run.offers.first)
  let bought = run.buy(offer)
  let boughtAgain = run.buy(offer)
  #expect(bought)
  #expect(!boughtAgain)
  #expect(run.charms.contains(offer))
  run.nextBlind()
  #expect(run.blind == 1)
  #expect(run.hands == 4)
  #expect(run.discards == 3)
  run.hands = 1
  run.hand = [card(2)]
  run.charms = []
  run.play(Set(run.hand.map(\.id)))
  #expect(run.phase == .lost)
  #expect(run.play(Set(run.hand.map(\.id))) == nil)
}

@Test func threeAntesEndInVictoryAndSaveRoundTrips() throws {
  var run = Run(seed: 9)
  run.blind = 8
  run.charms = [.ribbon, .compass, .velvet, .rose, .echo]
  run.previous = .straightFlush
  run.hand = (10...14).map { card($0, .hearts) }
  run.play(Set(run.hand.map(\.id)))
  #expect(run.phase == .won)
  let snapshot = SavedGame(run: run, records: Records(), recordedResult: true)
  let decoded = try JSONDecoder().decode(SavedGame.self, from: JSONEncoder().encode(snapshot))
  #expect(decoded.run.totalScore == run.totalScore)
  #expect(decoded.run.charms == run.charms)
  #expect(decoded.recordedResult)
}

@Test func fractionalProductsRoundDownOnceAfterAllModifiers() throws {
  let score = try #require(
    Scoring.score([card(4)], charms: [.ribbon, .echo], money: 0, handsLeft: 3, previous: .highCard))
  #expect(score.chips == 9)
  #expect(score.mult == 7.5)
  #expect(score.rawTotal == 67.5)
  #expect(score.total == 67)
  #expect(score.isRounded)
}

@Test func shopCapacityAndExhaustedDiscardsRespectLimits() {
  var run = Run(seed: 17)
  for _ in 0..<3 {
    let discarded = run.discard([run.hand[0].id])
    #expect(discarded)
  }
  let deckCount = run.deck.count
  let exhausted = run.discard([run.hand[0].id])
  #expect(!exhausted)
  #expect(run.deck.count == deckCount)
  run.phase = .shop
  run.charms = [.ribbon, .ruby, .moon, .crown, .twins]
  run.offers = [.velvet]
  run.money = 10
  let full = run.buy(.velvet)
  #expect(!full)
  #expect(run.money == 10)
  run.sell(.ribbon)
  let bought = run.buy(.velvet)
  #expect(bought)
  #expect(run.money == 4)
  #expect(run.charms.count == 5)
}
