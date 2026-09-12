import Foundation

enum CardKind: String, Codable, CaseIterable {
  case strike, guardCard, needle, bastion, venom, insight, echo, mend, kindle
  case riposte, sever, sanctuary, harvest, flourish, eclipse, hourglass, thorn, lantern

  var title: String {
    switch self {
    case .strike: "Paper Cut"
    case .guardCard: "Fold"
    case .needle: "Silver Needle"
    case .bastion: "Paper Bastion"
    case .venom: "Bitter Ink"
    case .insight: "Read Ahead"
    case .echo: "Echo Blade"
    case .mend: "Golden Stitch"
    case .kindle: "Kindling"
    case .riposte: "Riposte"
    case .sever: "Sever the String"
    case .sanctuary: "Sanctuary"
    case .harvest: "Night Harvest"
    case .flourish: "Flourish"
    case .eclipse: "Eclipse"
    case .hourglass: "Stolen Moment"
    case .thorn: "Thorn Crown"
    case .lantern: "Lantern"
    }
  }

  var cost: Int {
    switch self {
    case .needle, .kindle: 0
    case .bastion, .sever, .sanctuary, .eclipse: 2
    default: 1
    }
  }

  var text: String {
    switch self {
    case .strike: "Deal 7 damage."
    case .guardCard: "Gain 6 block."
    case .needle: "Deal 4 damage.\nDraw 1 card."
    case .bastion: "Gain 17 block."
    case .venom: "Apply 5 poison."
    case .insight: "Draw 3 cards."
    case .echo: "Deal 5 damage\ntwice."
    case .mend: "Heal 8 health.\nExhaust."
    case .kindle: "Gain 2 energy.\nExhaust."
    case .riposte: "Gain 5 block.\nDeal 6 damage."
    case .sever: "Deal 18 damage.\nApply 2 weak."
    case .sanctuary: "Gain 12 block.\nHeal 4 health."
    case .harvest: "Deal 10 damage.\nHeal 3 health."
    case .flourish: "Deal 8 damage.\nDraw 2 cards."
    case .eclipse: "Deal 25 damage.\nExhaust."
    case .hourglass: "Apply 3 weak.\nDraw 1 card."
    case .thorn: "Gain 2 strength.\nExhaust."
    case .lantern: "Gain 1 energy.\nDraw 2 cards."
    }
  }

  var symbol: String {
    switch self {
    case .strike, .echo, .sever, .eclipse: "scissors"
    case .guardCard, .bastion, .sanctuary: "shield.lefthalf.filled"
    case .needle, .riposte: "arrow.up.right"
    case .venom, .harvest: "drop.fill"
    case .insight, .flourish: "book.closed"
    case .mend: "sparkles"
    case .kindle, .lantern: "flame"
    case .hourglass: "hourglass"
    case .thorn: "crown"
    }
  }

  var isDefense: Bool { [.guardCard, .bastion, .sanctuary, .mend].contains(self) }
  var exhausts: Bool { [.mend, .kindle, .eclipse, .thorn].contains(self) }
  var category: String { exhausts ? "EXHAUST" : isDefense ? "WARD" : "ART" }
  var attack: Int? {
    switch self {
    case .strike: 7
    case .needle: 4
    case .echo: 5
    case .riposte: 6
    case .sever: 18
    case .harvest: 10
    case .flourish: 8
    case .eclipse: 25
    default: nil
    }
  }
}

struct Card: Codable, Identifiable, Equatable {
  var id: Int
  var kind: CardKind
}

enum Relic: String, Codable, CaseIterable {
  case spool, feather, candle, thimble
  var title: String {
    switch self {
    case .spool: "Copper Spool"
    case .feather: "Raven Quill"
    case .candle: "Everflame"
    case .thimble: "Silver Thimble"
    }
  }
  var text: String {
    switch self {
    case .spool: "Heal 4 after every battle."
    case .feather: "Draw 1 extra card each turn."
    case .candle: "Start each battle with +1 energy."
    case .thimble: "Gain 3 block each turn."
    }
  }
  var symbol: String {
    switch self {
    case .spool: "circle.hexagongrid"
    case .feather: "pencil.tip.crop.circle"
    case .candle: "flame"
    case .thimble: "shield"
    }
  }
}

enum EnemyKind: String, Codable, CaseIterable {
  case moth, fox, knight, twins, stag, queen
  var title: String {
    switch self {
    case .moth: "The Ink Moth"
    case .fox: "Velvet Fox"
    case .knight: "Hollow Knight"
    case .twins: "Scissor Twins"
    case .stag: "The Briar Stag"
    case .queen: "The String Queen"
    }
  }
  var health: Int {
    switch self {
    case .moth: 30
    case .fox: 38
    case .knight: 47
    case .twins: 44
    case .stag: 60
    case .queen: 100
    }
  }
}

struct Intent: Codable, Equatable {
  var damage: Int
  var block: Int = 0
  var weak: Int = 0
  var label: String {
    if damage == 0 { return "Fortify · \(block) block" }
    return weak > 0 ? "Hex · \(damage) + weak" : "Attack · \(damage)"
  }
}

struct Enemy: Codable {
  var kind: EnemyKind
  var hp: Int
  var maxHP: Int
  var block = 0
  var poison = 0
  var weak = 0
  var turn = 0

  var intent: Intent {
    let phase = turn % 3
    let base: Intent
    switch kind {
    case .moth:
      base = [Intent(damage: 6), Intent(damage: 0, block: 6), Intent(damage: 9)][phase]
    case .fox:
      base = [Intent(damage: 8), Intent(damage: 5, weak: 2), Intent(damage: 12)][phase]
    case .knight:
      base = [Intent(damage: 0, block: 12), Intent(damage: 14), Intent(damage: 9)][phase]
    case .twins:
      base = [Intent(damage: 10), Intent(damage: 12), Intent(damage: 0, block: 8)][phase]
    case .stag:
      base = [Intent(damage: 10), Intent(damage: 0, block: 10), Intent(damage: 19)][phase]
    case .queen:
      base = [Intent(damage: 13, weak: 2), Intent(damage: 0, block: 15), Intent(damage: 22)][phase]
    }
    return Intent(
      damage: weak > 0 ? base.damage * 3 / 4 : base.damage, block: base.block, weak: base.weak)
  }
}

enum Stage: String, Codable {
  case map, battle, reward, rest, shop, victory, defeat
}

struct Route: Identifiable {
  var id: Int
  var title: String
  var subtitle: String
  var symbol: String
  var enemy: EnemyKind?
  var stage: Stage
}

struct RandomSource: RandomNumberGenerator, Codable {
  var state: UInt64
  mutating func next() -> UInt64 {
    state &+= 0x9e37_79b9_7f4a_7c15
    var value = state
    value = (value ^ (value >> 30)) &* 0xbf58_476d_1ce4_e5b9
    value = (value ^ (value >> 27)) &* 0x94d0_49bb_1331_11eb
    return value ^ (value >> 31)
  }
}

struct Run: Codable {
  var stage: Stage = .map
  var hp = 70
  var maxHP = 70
  var block = 0
  var weak = 0
  var strength = 0
  var energy = 3
  var step = 0
  var gold = 35
  var turns = 0
  var battles = 0
  var damageDealt = 0
  var deck: [Card] = []
  var drawPile: [Card] = []
  var hand: [Card] = []
  var discard: [Card] = []
  var exhaust: [Card] = []
  var relics: [Relic] = [.spool]
  var enemy: Enemy?
  var rewards: [CardKind] = []
  var offeredRelic: Relic?
  var lastMessage = "The curtain rises."
  var routeHistory: [String] = []
  var rng: RandomSource
  var nextID = 0
  var score: Int { battles * 100 + hp * 5 + gold + (stage == .victory ? 500 : 0) }

  init(seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
    rng = RandomSource(state: seed)
    for kind: CardKind in [
      .strike, .strike, .strike, .strike, .guardCard, .guardCard, .guardCard,
      .needle, .venom, .riposte,
    ] {
      addCard(kind)
    }
  }

  var routes: [Route] {
    switch step {
    case 0:
      [
        Route(
          id: 0, title: "The Lantern Gate", subtitle: "A gentle first duel", symbol: "sparkle",
          enemy: .moth, stage: .battle)
      ]
    case 1:
      [
        Route(
          id: 0, title: "Velvet Alley", subtitle: "A trickster in the ink", symbol: "moon",
          enemy: .fox, stage: .battle),
        Route(
          id: 1, title: "The Quiet Watch", subtitle: "Pierce a patient guard", symbol: "shield",
          enemy: .knight, stage: .battle),
      ]
    case 2:
      [
        Route(
          id: 0, title: "The Bindery", subtitle: "Rest · recover 24 health", symbol: "leaf",
          enemy: nil, stage: .rest),
        Route(
          id: 1, title: "The Night Market", subtitle: "Trade gold for rare arts", symbol: "bag",
          enemy: nil, stage: .shop),
      ]
    case 3:
      [
        Route(
          id: 0, title: "The Cutting Room", subtitle: "Face the Scissor Twins", symbol: "scissors",
          enemy: .twins, stage: .battle),
        Route(
          id: 1, title: "Briar Court", subtitle: "Elite · earn a relic", symbol: "crown",
          enemy: .stag, stage: .battle),
      ]
    case 4:
      [
        Route(
          id: 0, title: "The Last Watch", subtitle: "A knight guards the stage", symbol: "shield",
          enemy: .knight, stage: .battle),
        Route(
          id: 1, title: "Thorn Gallery", subtitle: "Elite · earn a relic", symbol: "crown",
          enemy: .stag, stage: .battle),
      ]
    case 5:
      [
        Route(
          id: 0, title: "The Green Room", subtitle: "Rest before the finale", symbol: "leaf",
          enemy: nil, stage: .rest),
        Route(
          id: 1, title: "The Curio Cart", subtitle: "Spend your final coins", symbol: "bag",
          enemy: nil, stage: .shop),
      ]
    default:
      [
        Route(
          id: 0, title: "The Final Curtain", subtitle: "Boss · The String Queen", symbol: "crown",
          enemy: .queen, stage: .battle)
      ]
    }
  }

  mutating func addCard(_ kind: CardKind) {
    deck.append(Card(id: nextID, kind: kind))
    nextID += 1
  }

  mutating func chooseRoute(_ id: Int) {
    guard stage == .map, let route = routes.first(where: { $0.id == id }) else { return }
    routeHistory.append(route.title)
    if let kind = route.enemy {
      startBattle(kind)
    } else {
      stage = route.stage
      lastMessage = "A moment between chapters."
    }
  }

  mutating func startBattle(_ kind: EnemyKind) {
    stage = .battle
    enemy = Enemy(kind: kind, hp: kind.health, maxHP: kind.health)
    block = 0
    weak = 0
    strength = 0
    energy = relics.contains(.candle) ? 4 : 3
    drawPile = deck.shuffled(using: &rng)
    hand = []
    discard = []
    exhaust = []
    if relics.contains(.thimble) { block = 3 }
    draw(relics.contains(.feather) ? 6 : 5)
    lastMessage = "Read the intent. Choose your art."
  }

  mutating func draw(_ count: Int) {
    for _ in 0..<count {
      guard hand.count < 10 else { return }
      if drawPile.isEmpty {
        drawPile = discard.shuffled(using: &rng)
        discard = []
      }
      if let card = drawPile.popLast() { hand.append(card) }
    }
  }

  func attackDamage(_ amount: Int) -> Int {
    weak > 0 ? (amount + strength) * 3 / 4 : amount + strength
  }

  func cardText(_ kind: CardKind) -> String {
    guard let base = kind.attack else { return kind.text }
    return kind.text.replacingOccurrences(
      of: "\(base) damage", with: "\(attackDamage(base)) damage")
  }

  mutating func hit(_ amount: Int) {
    guard var foe = enemy else { return }
    let damage = attackDamage(amount)
    let absorbed = min(foe.block, damage)
    foe.block -= absorbed
    let inflicted = min(foe.hp, damage - absorbed)
    foe.hp -= inflicted
    damageDealt += inflicted
    enemy = foe
  }

  @discardableResult
  mutating func play(_ id: Int) -> Bool {
    guard stage == .battle, let index = hand.firstIndex(where: { $0.id == id }) else {
      return false
    }
    let card = hand[index]
    guard energy >= card.kind.cost else {
      lastMessage = "Not enough energy. End your turn to refill."
      return false
    }
    hand.remove(at: index)
    energy -= card.kind.cost
    switch card.kind {
    case .strike: hit(7)
    case .guardCard: block += 6
    case .needle:
      hit(4)
      draw(1)
    case .bastion: block += 17
    case .venom: enemy?.poison += 5
    case .insight: draw(3)
    case .echo:
      hit(5)
      hit(5)
    case .mend: hp = min(maxHP, hp + 8)
    case .kindle: energy += 2
    case .riposte:
      block += 5
      hit(6)
    case .sever:
      hit(18)
      enemy?.weak += 2
    case .sanctuary:
      block += 12
      hp = min(maxHP, hp + 4)
    case .harvest:
      hit(10)
      hp = min(maxHP, hp + 3)
    case .flourish:
      hit(8)
      draw(2)
    case .eclipse: hit(25)
    case .hourglass:
      enemy?.weak += 3
      draw(1)
    case .thorn: strength += 2
    case .lantern:
      energy += 1
      draw(2)
    }
    if card.kind.exhausts { exhaust.append(card) } else { discard.append(card) }
    lastMessage = "\(card.kind.title) · \(card.kind.text.replacingOccurrences(of: "\n", with: " "))"
    checkVictory()
    return true
  }

  mutating func endTurn() {
    guard stage == .battle, var foe = enemy else { return }
    turns += 1
    if foe.poison > 0 {
      let inflicted = min(foe.hp, foe.poison)
      foe.hp -= inflicted
      damageDealt += inflicted
      foe.poison -= 1
    }
    enemy = foe
    checkVictory()
    guard stage == .battle else { return }
    let intent = foe.intent
    let damage = max(0, intent.damage - block)
    hp = max(0, hp - damage)
    weak = max(0, weak - 1)
    weak += intent.weak
    foe.block = intent.block
    foe.weak = max(0, foe.weak - 1)
    foe.turn += 1
    enemy = foe
    if hp == 0 {
      stage = .defeat
      lastMessage = "Even torn pages can begin again."
      return
    }
    block = relics.contains(.thimble) ? 3 : 0
    energy = 3
    discard.append(contentsOf: hand)
    hand = []
    draw(relics.contains(.feather) ? 6 : 5)
    lastMessage =
      damage > 0 ? "The ink strikes. Lost \(damage) health." : "A perfect fold. No health lost."
  }

  mutating func checkVictory() {
    guard stage == .battle, let foe = enemy, foe.hp <= 0 else { return }
    battles += 1
    gold += foe.kind == .stag ? 40 : 25
    if relics.contains(.spool) { hp = min(maxHP, hp + 4) }
    if foe.kind == .queen {
      stage = .victory
      lastMessage = "You have rewritten the ending."
      return
    }
    offeredRelic = nil
    if foe.kind == .stag || step == 0 {
      offeredRelic = Relic.allCases.first { !relics.contains($0) }
    }
    rewards = Array(
      CardKind.allCases.filter { ![.strike, .guardCard].contains($0) }.shuffled(using: &rng).prefix(
        3))
    stage = .reward
    lastMessage = "The stage is yours. Take one new art."
  }

  mutating func claimReward(_ kind: CardKind?) {
    guard stage == .reward else { return }
    if let kind {
      guard rewards.contains(kind) else { return }
      addCard(kind)
    }
    if let relic = offeredRelic, !relics.contains(relic) { relics.append(relic) }
    offeredRelic = nil
    advance()
  }

  mutating func rest(mend: Bool) {
    guard stage == .rest else { return }
    if mend {
      hp = min(maxHP, hp + 24)
    } else {
      maxHP += 8
      hp = min(maxHP, hp + 8)
    }
    advance()
  }

  mutating func buy(_ kind: CardKind) {
    guard stage == .shop, [.sever, .sanctuary, .eclipse].contains(kind), gold >= 45 else { return }
    gold -= 45
    addCard(kind)
    lastMessage = "\(kind.title) added to your deck."
  }

  mutating func leaveShop() {
    guard stage == .shop else { return }
    advance()
  }

  mutating func advance() {
    step += 1
    stage = .map
    rewards = []
    lastMessage = "Choose where your story goes."
  }
}

struct Archive: Codable {
  var run: Run?
  var best = 0
  var wins = 0
  var attempts = 0
  var sound = true
  var hasReadRules = false
  var recordedResult = false

  mutating func start(seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
    run = Run(seed: seed)
    attempts += 1
    recordedResult = false
  }

  mutating func recordResult() {
    guard !recordedResult, let run, run.stage == .victory || run.stage == .defeat else { return }
    best = max(best, run.score)
    if run.stage == .victory { wins += 1 }
    recordedResult = true
  }
}
