import Foundation
import Testing

@testable import PaperRelicsRules

@Test func energyAndUnavailableCardsAreGuarded() {
  var run = Run(seed: 1)
  run.startBattle(.moth)
  let card = Card(id: 100, kind: .sever)
  run.hand = [card]
  run.energy = 1
  let unaffordable = run.play(100)
  #expect(!unaffordable)
  #expect(run.hand == [card])
  #expect(run.enemy?.hp == 30)
  let unavailable = run.play(999)
  #expect(!unavailable)
  run.energy = 2
  let played = run.play(100)
  #expect(played)
  #expect(run.energy == 0)
  #expect(run.enemy?.hp == 12)
  #expect(run.enemy?.intent.damage == 4)
}

@Test func poisonKillsBeforeEnemyCanAttackAndAwardsOnlyOnce() {
  var run = Run(seed: 2)
  run.startBattle(.moth)
  run.enemy?.hp = 3
  run.enemy?.poison = 5
  run.enemy?.block = 100
  run.hp = 40
  run.endTurn()
  #expect(run.stage == .reward)
  #expect(run.hp == 44)
  #expect(run.battles == 1)
  run.endTurn()
  run.checkVictory()
  #expect(run.gold == 60)
  #expect(run.battles == 1)
}

@Test func adjustedDamageMatchesPreviewAndAnnouncement() {
  for weak in [0, 1] {
    for strength in [0, 2] {
      var run = Run(seed: 7)
      run.startBattle(.queen)
      run.weak = weak
      run.strength = strength
      run.hand = [Card(id: 100, kind: .echo)]
      let preview = run.cardText(.echo)
      let damage = weak > 0 ? (5 + strength) * 3 / 4 : 5 + strength
      let health = run.enemy?.hp
      let played = run.play(100)
      #expect(played)
      #expect(run.damageDealt == damage * 2)
      #expect(run.enemy?.hp == health.map { $0 - damage * 2 })
      #expect(preview.contains("\(damage) damage"))
      #expect(run.lastMessage.contains(preview.replacingOccurrences(of: "\n", with: " ")))
    }
  }
}

@Test func pilesConserveCardsAndExhaustNeverReshuffles() {
  var run = Run(seed: 3)
  run.addCard(.kindle)
  run.startBattle(.queen)
  run.hand = run.deck.filter { $0.kind == .kindle }
  run.drawPile = []
  run.discard = run.deck.filter { $0.kind != .kindle }
  let played = run.play(run.hand[0].id)
  #expect(played)
  #expect(run.exhaust.count == 1)
  for _ in 0..<3 {
    run.endTurn()
    let ids = (run.hand + run.drawPile + run.discard + run.exhaust).map(\.id)
    #expect(Set(ids).count == run.deck.count)
    #expect(ids.count == run.deck.count)
    #expect(!run.hand.contains { $0.kind == .kindle })
  }
}

@Test func blockAndWeakExpireAtCorrectBoundaries() {
  var run = Run(seed: 4)
  run.startBattle(.moth)
  run.block = 10
  run.endTurn()
  #expect(run.hp == 70)
  #expect(run.block == 0)
  #expect(run.enemy?.intent.damage == 0)
  run.enemy?.weak = 2
  run.endTurn()
  #expect(run.enemy?.weak == 1)
  #expect(run.enemy?.intent.damage == 6)
}

@Test func routesRewardsShopAndRestHaveTransactionalGuards() {
  var run = Run(seed: 5)
  run.claimReward(.eclipse)
  #expect(run.deck.count == 10)
  run.chooseRoute(99)
  #expect(run.stage == .map)
  run.step = 2
  run.chooseRoute(1)
  #expect(run.stage == .shop)
  run.buy(.eclipse)
  #expect(run.deck.count == 10)
  run.gold = 100
  run.buy(.eclipse)
  #expect(run.gold == 55)
  #expect(run.deck.count == 11)
  run.buy(.strike)
  #expect(run.gold == 55)
  run.leaveShop()
  #expect(run.step == 3)
  run.leaveShop()
  #expect(run.step == 3)
  run.stage = .rest
  run.hp = 68
  run.rest(mend: true)
  #expect(run.hp == 70)
  #expect(run.step == 4)
}

@Test func archiveRoundTripPreservesExactRunAndResultIsIdempotent() throws {
  var archive = Archive()
  archive.start(seed: 88)
  archive.run?.chooseRoute(0)
  archive.run?.endTurn()
  let decoded = try JSONDecoder().decode(Archive.self, from: JSONEncoder().encode(archive))
  #expect(decoded.run?.hand == archive.run?.hand)
  #expect(decoded.run?.rng.state == archive.run?.rng.state)
  #expect(decoded.run?.enemy?.turn == 1)
  archive.run?.stage = .victory
  archive.recordResult()
  archive.recordResult()
  #expect(archive.wins == 1)
  #expect(archive.best == archive.run?.score)
}

@Test func passiveRelicsAndStatusCardsHaveRealEffects() {
  var run = Run(seed: 8)
  run.relics = Relic.allCases
  run.startBattle(.queen)
  #expect(run.hand.count == 6)
  #expect(run.energy == 4)
  #expect(run.block == 3)
  run.hand = [Card(id: 100, kind: .thorn), Card(id: 101, kind: .echo)]
  run.play(100)
  run.play(101)
  #expect(run.enemy?.hp == 86)
  #expect(run.exhaust.count == 1)
  run.endTurn()
  #expect(run.energy == 3)
  #expect(run.block == 3)
}

@Test func lossStopsInputAndPreservesZeroHealth() {
  var run = Run(seed: 10)
  run.startBattle(.queen)
  run.hp = 1
  run.endTurn()
  #expect(run.stage == .defeat)
  #expect(run.hp == 0)
  let energy = run.energy
  if let card = run.hand.first {
    let played = run.play(card.id)
    #expect(!played)
  }
  #expect(run.energy == energy)
}

@Test func balancedNormalRulesCanWinFullSevenChapterRuns() {
  var wins = 0
  for seed in 1...30 {
    var run = Run(seed: UInt64(seed))
    var actions = 0
    while run.stage != .victory && run.stage != .defeat && actions < 800 {
      actions += 1
      switch run.stage {
      case .map: run.chooseRoute(run.step == 3 ? 1 : 0)
      case .rest: run.rest(mend: true)
      case .shop: run.leaveShop()
      case .reward:
        let priority: [CardKind] = [
          .harvest, .sever, .venom, .sanctuary, .eclipse, .flourish, .riposte, .thorn, .needle,
          .bastion, .mend, .echo, .lantern, .kindle, .hourglass, .insight,
        ]
        run.claimReward(priority.first { run.rewards.contains($0) })
      case .battle:
        let incoming = run.enemy?.intent.damage ?? 0
        let playable = run.hand.filter { $0.kind.cost <= run.energy }
        let preferred = playable.max { a, b in
          priority(a.kind, run: run, incoming: incoming)
            < priority(b.kind, run: run, incoming: incoming)
        }
        if let preferred, priority(preferred.kind, run: run, incoming: incoming) > 0 {
          run.play(preferred.id)
        } else {
          run.endTurn()
        }
      default: break
      }
    }
    #expect(actions < 800)
    if run.stage == .victory {
      wins += 1
      #expect(run.step == 6)
      #expect(run.battles == 5)
      #expect(run.routeHistory.count == 7)
    }
  }
  print("Balance simulation: \(wins)/30 seeded full runs won using ordinary actions.")
  #expect(wins >= 20)
}

private func priority(_ kind: CardKind, run: Run, incoming: Int) -> Int {
  switch kind {
  case .kindle, .lantern: 110
  case .mend: run.hp < run.maxHP - 6 ? 100 : 0
  case .thorn: 99
  case .venom: (run.enemy?.hp ?? 0) > 15 ? 95 : 15
  case .sever, .eclipse, .harvest: 90
  case .riposte: incoming > run.block ? 85 : 60
  case .sanctuary: incoming > run.block ? 90 : 45
  case .bastion: incoming - run.block > 8 ? 91 : 0
  case .guardCard: incoming > run.block ? 80 : 0
  case .hourglass: incoming > 10 ? 80 : 10
  case .flourish, .needle: 75
  case .echo, .strike: 65
  case .insight: run.energy > 1 ? 40 : 0
  }
}
