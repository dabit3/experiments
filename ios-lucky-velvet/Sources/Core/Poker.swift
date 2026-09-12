import Foundation

enum Suit: String, CaseIterable, Codable, Sendable {
  case clubs, diamonds, hearts, spades
  var symbol: String {
    switch self {
    case .clubs: "♣"
    case .diamonds: "♦"
    case .hearts: "♥"
    case .spades: "♠"
    }
  }
  var isRed: Bool { self == .hearts || self == .diamonds }
}

struct Card: Identifiable, Codable, Hashable, Sendable {
  let rank: Int
  let suit: Suit
  var id: String { "\(rank)-\(suit.rawValue)" }
  var label: String {
    switch rank {
    case 11: "J"
    case 12: "Q"
    case 13: "K"
    case 14: "A"
    default: String(rank)
    }
  }
  var chips: Int { rank == 14 ? 11 : min(rank, 10) }
  var name: String { "\(label) of \(suit.rawValue)" }
  static var deck: [Card] {
    Suit.allCases.flatMap { suit in (2...14).map { Card(rank: $0, suit: suit) } }
  }
}

enum HandKind: Int, CaseIterable, Codable, Sendable {
  case highCard, pair, twoPair, three, straight, flush, fullHouse, four, straightFlush
  var name: String {
    [
      "High card", "Pair", "Two pair", "Three of a kind", "Straight", "Flush", "Full house",
      "Four of a kind", "Straight flush",
    ][rawValue]
  }
  var chips: Int { [5, 10, 20, 30, 30, 35, 40, 60, 100][rawValue] }
  var mult: Int { [1, 2, 2, 3, 4, 4, 4, 7, 8][rawValue] }
  var guide: String {
    [
      "Your highest card", "Two matching ranks", "Two different pairs", "Three matching ranks",
      "Five consecutive ranks", "Five of the same suit", "Three of a kind + a pair",
      "Four matching ranks", "A straight, all one suit",
    ][rawValue]
  }
}

struct PokerHand: Sendable {
  let kind: HandKind
  let scoringCards: [Card]

  static func evaluate(_ cards: [Card]) -> PokerHand? {
    guard !cards.isEmpty, cards.count <= 5, Set(cards).count == cards.count else { return nil }
    let groups = Dictionary(grouping: cards, by: \.rank)
    let ranks = groups.keys.sorted()
    let flush = cards.count == 5 && Set(cards.map(\.suit)).count == 1
    let straight =
      cards.count == 5 && ranks.count == 5
      && (ranks.last! - ranks.first! == 4 || ranks == [2, 3, 4, 5, 14])
    let counts = groups.values.map(\.count).sorted(by: >)
    let kind: HandKind
    if straight && flush {
      kind = .straightFlush
    } else if counts.first == 4 {
      kind = .four
    } else if counts == [3, 2] {
      kind = .fullHouse
    } else if flush {
      kind = .flush
    } else if straight {
      kind = .straight
    } else if counts.first == 3 {
      kind = .three
    } else if counts.filter({ $0 == 2 }).count == 2 {
      kind = .twoPair
    } else if counts.first == 2 {
      kind = .pair
    } else {
      kind = .highCard
    }
    let scoring: [Card]
    switch kind {
    case .highCard: scoring = [cards.max { $0.rank < $1.rank }!]
    case .pair, .twoPair, .three, .four: scoring = cards.filter { groups[$0.rank]!.count > 1 }
    default: scoring = cards
    }
    return PokerHand(kind: kind, scoringCards: scoring)
  }
}

enum Charm: String, CaseIterable, Codable, Identifiable, Sendable {
  case ribbon, ruby, moon, crown, twins, lantern, feather, coin, compass, rose, echo, velvet
  var id: String { rawValue }
  var name: String {
    switch self {
    case .ribbon: "Silk Ribbon"
    case .ruby: "Ruby Heart"
    case .moon: "Midnight Moon"
    case .crown: "Paper Crown"
    case .twins: "Kindred Cats"
    case .lantern: "Last Lantern"
    case .feather: "Golden Feather"
    case .coin: "Lucky Penny"
    case .compass: "North Star"
    case .rose: "Wild Rose"
    case .echo: "Encore Bell"
    case .velvet: "Velvet Fox"
    }
  }
  var detail: String {
    switch self {
    case .ribbon: "+4 Mult on every hand."
    case .ruby: "+3 Mult per scoring red card."
    case .moon: "+15 Chips per scoring black card."
    case .crown: "+25 Chips per scoring J, Q or K."
    case .twins: "+8 Mult on Pair or Two pair."
    case .lantern: "×2 Mult on your last hand."
    case .feather: "+50 Chips with 3 or fewer cards played."
    case .coin: "+2 Mult for every $3 held (up to +20)."
    case .compass: "×2 Mult on a Straight or Straight flush."
    case .rose: "+12 Mult on a Flush or Straight flush."
    case .echo: "×1.5 Mult when repeating your last hand type."
    case .velvet: "×1.5 Mult on every hand."
    }
  }
  var price: Int {
    switch self {
    case .velvet, .echo: 8
    case .compass, .lantern: 6
    default: 5
    }
  }
}

struct ScoreLine: Identifiable, Equatable, Sendable {
  let name: String
  let effect: String
  var id: String { name }
}

struct Score: Sendable {
  let hand: PokerHand
  let chips: Int
  let mult: Double
  let total: Int
  let lines: [ScoreLine]
  var rawTotal: Double { Double(chips) * mult }
  var isRounded: Bool { rawTotal != Double(total) }
}

enum Scoring {
  static func score(
    _ cards: [Card], charms: [Charm], money: Int, handsLeft: Int, previous: HandKind?
  ) -> Score? {
    guard let hand = PokerHand.evaluate(cards) else { return nil }
    var chips = hand.kind.chips + hand.scoringCards.reduce(0) { $0 + $1.chips }
    var mult = Double(hand.kind.mult)
    var factors: [(Charm, Double)] = []
    var lines = [
      ScoreLine(name: hand.kind.name, effect: "\(hand.kind.chips) Chips · \(hand.kind.mult) Mult"),
      ScoreLine(name: "Scoring cards", effect: "+\(chips - hand.kind.chips) Chips"),
    ]
    for charm in charms {
      var extraChips = 0
      var extraMult = 0
      switch charm {
      case .ribbon: extraMult = 4
      case .ruby: extraMult = hand.scoringCards.filter(\.suit.isRed).count * 3
      case .moon: extraChips = hand.scoringCards.filter { !$0.suit.isRed }.count * 15
      case .crown: extraChips = hand.scoringCards.filter { (11...13).contains($0.rank) }.count * 25
      case .twins: extraMult = [.pair, .twoPair].contains(hand.kind) ? 8 : 0
      case .lantern: if handsLeft == 1 { factors.append((charm, 2)) }
      case .feather: extraChips = cards.count <= 3 ? 50 : 0
      case .coin: extraMult = min(20, (money / 3) * 2)
      case .compass:
        if [.straight, .straightFlush].contains(hand.kind) { factors.append((charm, 2)) }
      case .rose: extraMult = [.flush, .straightFlush].contains(hand.kind) ? 12 : 0
      case .echo: if previous == hand.kind { factors.append((charm, 1.5)) }
      case .velvet: factors.append((charm, 1.5))
      }
      chips += extraChips
      mult += Double(extraMult)
      if extraChips > 0 {
        lines.append(ScoreLine(name: charm.name, effect: "+\(extraChips) Chips"))
      }
      if extraMult > 0 { lines.append(ScoreLine(name: charm.name, effect: "+\(extraMult) Mult")) }
    }
    for (charm, factor) in factors {
      mult *= factor
      lines.append(ScoreLine(name: charm.name, effect: "×\(factor.formatted()) Mult"))
    }
    return Score(
      hand: hand, chips: chips, mult: mult, total: Int((Double(chips) * mult).rounded(.down)),
      lines: lines)
  }
}

struct SeededGenerator: RandomNumberGenerator, Codable, Sendable {
  var state: UInt64
  mutating func next() -> UInt64 {
    state &+= 0x9e37_79b9_7f4a_7c15
    var value = state
    value = (value ^ (value >> 30)) &* 0xbf58_476d_1ce4_e5b9
    value = (value ^ (value >> 27)) &* 0x94d0_49bb_1331_11eb
    return value ^ (value >> 31)
  }
}
