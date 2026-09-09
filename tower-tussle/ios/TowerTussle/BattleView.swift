import SwiftUI

struct BattleView: View {
    @ObservedObject var engine: BattleEngine
    let onFinished: (MatchResult) -> Void
    let onQuit: () -> Void
    @State private var showQuitConfirm = false
    @State private var finishedHandled = false

    var body: some View {
        ZStack {
            SceneryBackdrop(dim: 0.55)
            VStack(spacing: 6) {
                hud
                GeometryReader { geo in
                    let scale = min(geo.size.width / Arena.width, geo.size.height / Arena.height)
                    let arenaSize = CGSize(width: Arena.width * scale, height: Arena.height * scale)
                    ZStack {
                        ArenaCanvas(engine: engine, scale: scale)
                            .frame(width: arenaSize.width, height: arenaSize.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Art.outline, lineWidth: 3))
                            .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
                            .contentShape(Rectangle())
                            .onTapGesture(coordinateSpace: .local) { point in
                                engine.deployAtTap(Vec(x: point.x / scale, y: point.y / scale))
                            }
                            .accessibilityIdentifier("arena")
                            .accessibilityLabel("Arena")
                        if let text = engine.announcement {
                            Text(text)
                                .font(.system(.headline, design: .rounded).weight(.black))
                                .foregroundStyle(LinearGradient.goldText)
                                .shadow(color: .black, radius: 0, x: 1, y: 1)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 9)
                                .panel(cornerRadius: 22)
                                .transition(.scale.combined(with: .opacity))
                                .accessibilityIdentifier("announcement")
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                handBar
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
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
                DisplayText(text: r.outcome.rawValue, size: 58,
                            fill: r.outcome == .victory ? .goldText : (r.outcome == .defeat ? .redText : .whiteText))
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
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(ChunkyButtonStyle(style: .red))
            .frame(width: 38, height: 38)
            .accessibilityIdentifier("quitButton")
            .accessibilityLabel("Quit battle")

            Spacer()
            HStack(spacing: 10) {
                CrownRow(count: engine.crowns(for: .enemy), color: Theme.enemy)
                    .accessibilityIdentifier("enemyCrowns")
                Text(timerText)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(engine.isOvertime ? LinearGradient.redText : (engine.isDoubleElixir ? LinearGradient(colors: [Color(red: 0.95, green: 0.65, blue: 1.0), Theme.elixir], startPoint: .top, endPoint: .bottom) : LinearGradient.whiteText))
                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                    .frame(minWidth: 70)
                    .accessibilityIdentifier("timer")
                CrownRow(count: engine.crowns(for: .player), color: Theme.player)
                    .accessibilityIdentifier("playerCrowns")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .panel(cornerRadius: 20)
            Spacer()
            Text(engine.isOvertime ? "OT" : (engine.isDoubleElixir ? "2×" : ""))
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 38, height: 30)
                .background {
                    if engine.isDoubleElixir {
                        Capsule().fill(LinearGradient(colors: [Color(red: 0.95, green: 0.6, blue: 1.0), Color(red: 0.5, green: 0.12, blue: 0.7)], startPoint: .top, endPoint: .bottom))
                            .overlay(Capsule().stroke(Art.outline, lineWidth: 2))
                    }
                }
        }
        .foregroundStyle(.white)
        .padding(.top, 4)
    }

    private var timerText: String {
        let s = engine.remainingSeconds
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private var handBar: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                VStack(spacing: 2) {
                    Text("NEXT").font(.system(size: 9, weight: .black, design: .rounded)).foregroundStyle(.white.opacity(0.7))
                    CardFrame(card: Cards.byId(engine.nextCard), showName: false, compact: true)
                        .frame(width: 46)
                        .accessibilityIdentifier("nextCard")
                }
                ForEach(Array(engine.hand.enumerated()), id: \.offset) { index, id in
                    let card = Cards.byId(id)
                    CardFrame(card: card, selected: engine.selectedHandIndex == index, affordable: engine.canAfford(card))
                        .id("\(index)-\(id)")
                        .offset(y: engine.selectedHandIndex == index ? -12 : 0)
                        .animation(.spring(duration: 0.2), value: engine.selectedHandIndex == index)
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
        .panel(cornerRadius: 18)
    }
}
