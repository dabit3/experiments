import SwiftUI

struct CardsView: View {
    @EnvironmentObject var profile: PlayerProfile
    let onBack: () -> Void
    @State private var selectedDeckCard: String? = nil
    @State private var detailCard: CardDef? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        ZStack {
            SceneryBackdrop(dim: 0.45)
            VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Label("Home", systemImage: "chevron.left")
                        .font(.system(.subheadline, design: .rounded).weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                }
                .buttonStyle(ChunkyButtonStyle(style: .slate))
                .accessibilityIdentifier("backButton")
                Spacer()
                DisplayText(text: "CARDS", size: 30, fill: .goldText)
                Spacer()
                Button {
                    profile.resetDeck(); selectedDeckCard = nil
                } label: {
                    Text("Reset")
                        .font(.system(.subheadline, design: .rounded).weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                }
                .buttonStyle(ChunkyButtonStyle(style: .slate))
                .accessibilityIdentifier("resetDeckButton")
            }
            .foregroundStyle(.white)
            .padding(.horizontal)
            .padding(.vertical, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("BATTLE DECK")
                            .font(.system(.headline, design: .rounded).weight(.black))
                            .shadow(color: .black.opacity(0.8), radius: 0, x: 1, y: 1)
                        Spacer()
                        HStack(spacing: 4) {
                            IconView(kind: .elixir, size: 16)
                            Text(String(format: "Avg %.1f", profile.averageElixir))
                        }
                        .font(.system(.caption, design: .rounded).weight(.black))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .panel(cornerRadius: 14)
                        .accessibilityIdentifier("avgElixir")
                        .accessibilityLabel(String(format: "Avg elixir %.1f", profile.averageElixir))
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
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 1, y: 1)
                        .padding(.top, 2)

                    Text("COLLECTION")
                        .font(.system(.headline, design: .rounded).weight(.black))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 1, y: 1)
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
        CardFrame(card: card, selected: selected)
            .padding(.top, 6)
            .padding(.leading, 6)
            .opacity(dimmed ? 0.8 : 1)
            .scaleEffect(selected ? 1.06 : 1)
        .animation(.spring(duration: 0.2), value: selected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.name), \(card.cost) elixir")
        .accessibilityAddTraits(.isButton)
    }
}

struct CardDetailSheet: View {
    let card: CardDef

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                CardFrame(card: card, showName: false)
                    .frame(width: 84)
                    .padding(.leading, 8)
                VStack(alignment: .leading, spacing: 2) {
                    DisplayText(text: card.name, size: 28, fill: .goldText)
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
        .background(LinearGradient(colors: [Theme.panel, Theme.background], startPoint: .top, endPoint: .bottom))
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
