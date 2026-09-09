import SwiftUI

struct BattleView: View {
    @ObservedObject var engine: BattleEngine
    let onFinished: (MatchResult) -> Void
    let onQuit: () -> Void
    @State private var showQuitConfirm = false
    @State private var finishedHandled = false

    var body: some View {
        VStack(spacing: 6) {
            hud
            GeometryReader { geo in
                let scale = min(geo.size.width / Arena.width, geo.size.height / Arena.height)
                let arenaSize = CGSize(width: Arena.width * scale, height: Arena.height * scale)
                ZStack {
                    ArenaCanvas(engine: engine, scale: scale)
                        .frame(width: arenaSize.width, height: arenaSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.15), lineWidth: 2))
                        .contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { point in
                            engine.deployAtTap(Vec(x: point.x / scale, y: point.y / scale))
                        }
                        .accessibilityIdentifier("arena")
                        .accessibilityLabel("Arena")
                    if let text = engine.announcement {
                        Text(text)
                            .font(.system(.headline, design: .rounded).weight(.black))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.65))
                            .foregroundStyle(Theme.accent)
                            .clipShape(Capsule())
                            .transition(.opacity)
                            .accessibilityIdentifier("announcement")
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            handBar
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
        .onAppear { engine.start() }
        .onDisappear { engine.stop() }
        .onChange(of: engine.result?.outcome) { _, newValue in
            if newValue != nil, !finishedHandled, let r = engine.result {
                finishedHandled = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onFinished(r) }
            }
        }
        .confirmationDialog("Leave the battle?", isPresented: $showQuitConfirm, titleVisibility: .visible) {
            Button("Surrender", role: .destructive, action: onQuit)
            Button("Keep fighting", role: .cancel) {}
        }
        .overlay {
            if let r = engine.result {
                Text(r.outcome.rawValue)
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .foregroundStyle(r.outcome == .victory ? Theme.accent : (r.outcome == .defeat ? Theme.enemy : .white))
                    .shadow(color: .black, radius: 0, x: 3, y: 3)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var hud: some View {
        HStack {
            Button {
                showQuitConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .padding(8)
                    .background(Theme.panel)
                    .clipShape(Circle())
            }
            .accessibilityIdentifier("quitButton")
            .accessibilityLabel("Quit battle")

            Spacer()
            CrownRow(count: engine.crowns(for: .enemy), color: Theme.enemy)
                .accessibilityIdentifier("enemyCrowns")
            Text(timerText)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(engine.isOvertime ? Theme.enemy : (engine.isDoubleElixir ? Theme.elixir : .white))
                .frame(minWidth: 80)
                .accessibilityIdentifier("timer")
            CrownRow(count: engine.crowns(for: .player), color: Theme.player)
                .accessibilityIdentifier("playerCrowns")
            Spacer()
            Text(engine.isOvertime ? "OT" : (engine.isDoubleElixir ? "2×" : ""))
                .font(.caption.weight(.black))
                .foregroundStyle(Theme.elixir)
                .frame(width: 34)
        }
        .foregroundStyle(.white)
        .padding(.top, 4)
    }

    private var timerText: String {
        let s = engine.remainingSeconds
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private var handBar: some View {
        VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 8) {
                VStack(spacing: 2) {
                    Text("Next").font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.6))
                    HandCard(card: Cards.byId(engine.nextCard), selected: false, affordable: true, small: true)
                        .frame(width: 44)
                        .accessibilityIdentifier("nextCard")
                }
                ForEach(Array(engine.hand.enumerated()), id: \.offset) { index, id in
                    let card = Cards.byId(id)
                    HandCard(card: card, selected: engine.selectedHandIndex == index, affordable: engine.canAfford(card), small: false)
                        .onTapGesture { engine.selectHand(index) }
                        .accessibilityIdentifier("hand-\(index)")
                        .accessibilityLabel("\(card.name), \(card.cost) elixir")
                        .accessibilityAddTraits(.isButton)
                }
            }
            ElixirBar(value: engine.playerElixir, max: Arena.maxElixir)
                .accessibilityIdentifier("elixirBar")
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.panel))
    }
}

struct CrownRow: View {
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(i < count ? color : .white.opacity(0.2))
            }
        }
        .accessibilityLabel("\(count) crowns")
    }
}

struct HandCard: View {
    let card: CardDef
    let selected: Bool
    let affordable: Bool
    let small: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(card.kind == .spell
                      ? LinearGradient(colors: [Color(red: 0.55, green: 0.25, blue: 0.75), Color(red: 0.3, green: 0.1, blue: 0.5)], startPoint: .top, endPoint: .bottom)
                      : LinearGradient(colors: [Color(red: 0.25, green: 0.45, blue: 0.85), Color(red: 0.12, green: 0.25, blue: 0.55)], startPoint: .top, endPoint: .bottom))
            VStack(spacing: 2) {
                Text(card.emoji).font(.system(size: small ? 18 : 30))
                if !small {
                    Text(card.name)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 2)
            ElixirBadge(cost: card.cost, size: small ? 16 : 22)
                .offset(x: -3, y: -3)
        }
        .aspectRatio(0.8, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(selected ? Theme.accent : .white.opacity(0.2), lineWidth: selected ? 3 : 1))
        .saturation(affordable ? 1 : 0.2)
        .opacity(affordable ? 1 : 0.55)
        .offset(y: selected ? -10 : 0)
        .animation(.spring(duration: 0.2), value: selected)
    }
}

struct ElixirBar: View {
    let value: Double
    let max: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.5))
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [Theme.elixir, Color(red: 0.6, green: 0.15, blue: 0.8)], startPoint: .top, endPoint: .bottom))
                    .frame(width: geo.size.width * CGFloat(value / max))
                HStack(spacing: 0) {
                    ForEach(1..<Int(max), id: \.self) { _ in
                        Spacer()
                        Rectangle().fill(.black.opacity(0.35)).frame(width: 1)
                    }
                    Spacer()
                }
                Text("\(Int(value))")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 1)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 20)
        .accessibilityLabel("Elixir \(Int(value)) of \(Int(max))")
        .accessibilityValue("\(Int(value))")
    }
}
