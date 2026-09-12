import Foundation

enum RunPhase: String, Codable { case playing, shop, lost, won }

struct Run: Codable {
  static let targets = [250, 400, 600, 900, 1300, 1800, 2400, 3200, 4500]
  var phase: RunPhase = .playing
  var blind = 0
  var score = 0
  var totalScore = 0
  var bestHand = 0
  var hands = 4
  var discards = 3
  var money = 5
  var charms: [Charm] = [.ribbon]
  var hand: [Card] = []
  var deck: [Card] = []
  var offers: [Charm] = []
  var previous: HandKind?
  var generator: SeededGenerator
  var lastReward = 0
  var cleared = 0
  var target: Int { Self.targets[blind] }
  var ante: Int { blind / 3 + 1 }
  var blindName: String { ["Opening night", "High society", "The house"][blind % 3] }

  init(seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
    generator = SeededGenerator(state: seed)
    dealBlind()
  }

  mutating func dealBlind() {
    deck = Card.deck.shuffled(using: &generator)
    hand = []
    score = 0
    hands = 4
    discards = 3
    previous = nil
    draw()
  }

  mutating func draw() {
    while hand.count < 8 && !deck.isEmpty { hand.append(deck.removeLast()) }
    hand.sort { $0.rank == $1.rank ? $0.suit.rawValue < $1.suit.rawValue : $0.rank > $1.rank }
  }

  func selection(_ ids: Set<String>) -> [Card]? {
    let cards = hand.filter { ids.contains($0.id) }
    guard !cards.isEmpty, cards.count <= 5, cards.count == ids.count else { return nil }
    return cards
  }

  func preview(_ ids: Set<String>) -> Score? {
    guard let cards = selection(ids), phase == .playing else { return nil }
    return Scoring.score(cards, charms: charms, money: money, handsLeft: hands, previous: previous)
  }

  @discardableResult
  mutating func play(_ ids: Set<String>) -> Score? {
    guard phase == .playing, hands > 0, let result = preview(ids) else { return nil }
    hand.removeAll { ids.contains($0.id) }
    hands -= 1
    score += result.total
    totalScore += result.total
    bestHand = max(bestHand, result.total)
    previous = result.hand.kind
    if score >= target {
      cleared += 1
      lastReward = 5 + hands + ante
      money += lastReward
      if blind == Self.targets.count - 1 {
        phase = .won
      } else {
        phase = .shop
        offers = Charm.allCases.filter { !charms.contains($0) }.shuffled(using: &generator).prefix(
          3
        ).map { $0 }
      }
    } else if hands == 0 {
      phase = .lost
    } else {
      draw()
    }
    return result
  }

  @discardableResult
  mutating func discard(_ ids: Set<String>) -> Bool {
    guard phase == .playing, discards > 0, let cards = selection(ids), deck.count >= cards.count
    else { return false }
    discards -= 1
    hand.removeAll { ids.contains($0.id) }
    draw()
    return true
  }

  @discardableResult
  mutating func buy(_ charm: Charm) -> Bool {
    guard phase == .shop, offers.contains(charm), money >= charm.price, charms.count < 5 else {
      return false
    }
    money -= charm.price
    charms.append(charm)
    offers.removeAll { $0 == charm }
    return true
  }

  mutating func sell(_ charm: Charm) {
    guard phase == .shop, charms.contains(charm) else { return }
    charms.removeAll { $0 == charm }
    money += 2
  }

  mutating func reroll() {
    guard phase == .shop, money >= 2 else { return }
    money -= 2
    offers = Charm.allCases.filter { !charms.contains($0) }.shuffled(using: &generator).prefix(3)
      .map { $0 }
  }

  mutating func nextBlind() {
    guard phase == .shop, blind < Self.targets.count - 1 else { return }
    blind += 1
    phase = .playing
    dealBlind()
  }
}

struct Records: Codable {
  var bestScore = 0
  var bestHand = 0
  var wins = 0
  var runs = 0
  var mostBlinds = 0
}

struct SavedGame: Codable {
  var run: Run
  var records: Records
  var recordedResult: Bool
}
