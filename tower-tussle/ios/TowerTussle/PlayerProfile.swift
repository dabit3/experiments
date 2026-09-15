import Foundation
import Combine

final class PlayerProfile: ObservableObject {
    private enum Keys {
        static let trophies = "tt.trophies"
        static let gold = "tt.gold"
        static let wins = "tt.wins"
        static let losses = "tt.losses"
        static let draws = "tt.draws"
        static let deck = "tt.deck"
    }

    private let defaults: UserDefaults

    @Published private(set) var trophies: Int
    @Published private(set) var gold: Int
    @Published private(set) var wins: Int
    @Published private(set) var losses: Int
    @Published private(set) var draws: Int
    @Published private(set) var deck: [String]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        trophies = defaults.integer(forKey: Keys.trophies)
        gold = defaults.object(forKey: Keys.gold) as? Int ?? 100
        wins = defaults.integer(forKey: Keys.wins)
        losses = defaults.integer(forKey: Keys.losses)
        draws = defaults.integer(forKey: Keys.draws)
        let saved = defaults.stringArray(forKey: Keys.deck) ?? []
        deck = saved.count == 8 && saved.allSatisfy({ id in Cards.all.contains { $0.id == id } }) ? saved : Cards.defaultDeck
    }

    var collection: [String] { Cards.all.map(\.id).filter { !deck.contains($0) } }

    var averageElixir: Double {
        Double(deck.map { Cards.byId($0).cost }.reduce(0, +)) / Double(max(deck.count, 1))
    }

    func apply(_ result: MatchResult) {
        trophies = max(0, trophies + result.trophyDelta)
        gold += result.goldDelta
        switch result.outcome {
        case .victory: wins += 1
        case .defeat: losses += 1
        case .draw: draws += 1
        }
        save()
    }

    func swap(deckCard: String, with collectionCard: String) {
        guard let i = deck.firstIndex(of: deckCard), collection.contains(collectionCard) else { return }
        deck[i] = collectionCard
        save()
    }

    func resetDeck() {
        deck = Cards.defaultDeck
        save()
    }

    private func save() {
        defaults.set(trophies, forKey: Keys.trophies)
        defaults.set(gold, forKey: Keys.gold)
        defaults.set(wins, forKey: Keys.wins)
        defaults.set(losses, forKey: Keys.losses)
        defaults.set(draws, forKey: Keys.draws)
        defaults.set(deck, forKey: Keys.deck)
    }
}
