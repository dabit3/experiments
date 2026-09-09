import SwiftUI

struct CardsView: View {
    @EnvironmentObject var profile: PlayerProfile
    let onBack: () -> Void
    @State private var selectedDeckCard: String? = nil
    @State private var detailCard: CardDef? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Label("Home", systemImage: "chevron.left")
                        .font(.headline.weight(.bold))
                }
                .accessibilityIdentifier("backButton")
                Spacer()
                Text("CARDS")
                    .font(.system(.title2, design: .rounded).weight(.black))
                Spacer()
                Button("Reset") { profile.resetDeck(); selectedDeckCard = nil }
                    .font(.subheadline.weight(.semibold))
                    .accessibilityIdentifier("resetDeckButton")
            }
            .foregroundStyle(.white)
            .padding(.horizontal)
            .padding(.vertical, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Battle Deck")
                            .font(.headline.weight(.bold))
                        Spacer()
                        Text(String(format: "Avg elixir %.1f", profile.averageElixir))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.elixir)
                            .accessibilityIdentifier("avgElixir")
                    }
                    .foregroundStyle(.white)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(profile.deck, id: \.self) { id in
                            CardTile(card: Cards.byId(id), selected: selectedDeckCard == id, dimmed: false)
                                .onTapGesture {
                                    if selectedDeckCard == id { detailCard = Cards.byId(id) } else { selectedDeckCard = id }
                                }
                                .accessibilityIdentifier("deck-\(id)")
                        }
                    }

                    Text(selectedDeckCard == nil
                         ? "Tap a deck card, then a collection card to swap. Tap a selected card again for details."
                         : "Now tap a collection card to swap it into your deck.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 2)

                    Text("Collection")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(profile.collection, id: \.self) { id in
                            CardTile(card: Cards.byId(id), selected: false, dimmed: selectedDeckCard == nil)
                                .onTapGesture {
                                    if let deckCard = selectedDeckCard {
                                        withAnimation(.spring(duration: 0.3)) {
                                            profile.swap(deckCard: deckCard, with: id)
                                        }
                                        selectedDeckCard = nil
                                    } else {
                                        detailCard = Cards.byId(id)
                                    }
                                }
                                .accessibilityIdentifier("collection-\(id)")
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .sheet(item: $detailCard) { card in
            CardDetailSheet(card: card)
                .presentationDetents([.medium])
        }
    }
}

struct CardTile: View {
    let card: CardDef
    let selected: Bool
    let dimmed: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(card.kind == .spell
                          ? LinearGradient(colors: [Color(red: 0.55, green: 0.25, blue: 0.75), Color(red: 0.3, green: 0.1, blue: 0.5)], startPoint: .top, endPoint: .bottom)
                          : LinearGradient(colors: [Color(red: 0.25, green: 0.45, blue: 0.85), Color(red: 0.12, green: 0.25, blue: 0.55)], startPoint: .top, endPoint: .bottom))
                Text(card.emoji)
                    .font(.system(size: 34))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                ElixirBadge(cost: card.cost)
                    .offset(x: -4, y: -4)
            }
            .aspectRatio(0.82, contentMode: .fit)
            Text(card.name)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.white)
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.panel))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Theme.accent : .white.opacity(0.1), lineWidth: selected ? 3 : 1))
        .opacity(dimmed ? 0.75 : 1)
        .scaleEffect(selected ? 1.05 : 1)
        .animation(.spring(duration: 0.2), value: selected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.name), \(card.cost) elixir")
        .accessibilityAddTraits(.isButton)
    }
}

struct ElixirBadge: View {
    let cost: Int
    var size: CGFloat = 22

    var body: some View {
        Text("\(cost)")
            .font(.system(size: size * 0.6, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(Theme.elixir))
            .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
    }
}

struct CardDetailSheet: View {
    let card: CardDef

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Text(card.emoji).font(.system(size: 56))
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.name).font(.system(.title, design: .rounded).weight(.black))
                    Text(card.kind == .spell ? "Spell" : (card.flying ? "Flying troop" : "Ground troop"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                ElixirBadge(cost: card.cost, size: 40)
            }
            Text(card.description)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
            Divider().overlay(.white.opacity(0.2))
            if card.kind == .troop {
                statRow("Hitpoints", "\(Int(card.hp))" + (card.count > 1 ? " ×\(card.count)" : ""))
                statRow("Damage", "\(Int(card.damage))")
                statRow("Hit speed", String(format: "%.1fs", card.hitSpeed))
                statRow("Range", card.range <= 1.2 ? "Melee" : String(format: "%.1f", card.range))
                statRow("Speed", card.speed >= 3.4 ? "Very fast" : card.speed >= 2.8 ? "Fast" : card.speed >= 1.8 ? "Medium" : "Slow")
                if card.buildingsOnly { statRow("Targets", "Buildings only") }
            } else {
                statRow("Damage", "\(Int(card.damage))")
                statRow("Tower damage", "\(Int(card.damage * Arena.towerSpellFactor))")
                statRow("Radius", String(format: "%.1f", card.radius))
            }
            Spacer()
        }
        .padding(24)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.background)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value).font(.body.weight(.bold)).monospacedDigit()
        }
        .font(.subheadline)
    }
}
