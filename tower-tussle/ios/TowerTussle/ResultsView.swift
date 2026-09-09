import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var profile: PlayerProfile
    let result: MatchResult
    let onHome: () -> Void
    let onRematch: () -> Void

    private var titleColor: Color {
        switch result.outcome {
        case .victory: return Theme.accent
        case .defeat: return Theme.enemy
        case .draw: return .white
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(result.outcome == .victory ? "🎉" : (result.outcome == .defeat ? "💀" : "🤝"))
                .font(.system(size: 72))
            Text(result.outcome.rawValue)
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundStyle(titleColor)
                .shadow(color: .black.opacity(0.7), radius: 0, x: 3, y: 3)
                .accessibilityIdentifier("resultTitle")

            HStack(spacing: 30) {
                crownColumn("You", result.playerCrowns, Theme.player)
                Text("—").font(.title).foregroundStyle(.white.opacity(0.4))
                crownColumn("Enemy", result.enemyCrowns, Theme.enemy)
            }

            VStack(spacing: 10) {
                rewardRow("🏆", "Trophies", result.trophyDelta, total: profile.trophies)
                rewardRow("🪙", "Gold", result.goldDelta, total: profile.gold)
                HStack {
                    Text("⏱️")
                    Text("Battle time")
                    Spacer()
                    Text(String(format: "%d:%02d", result.durationSeconds / 60, result.durationSeconds % 60)).monospacedDigit()
                }
                .font(.subheadline.weight(.semibold))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.panel))
            .padding(.horizontal, 28)
            .foregroundStyle(.white)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onRematch) {
                    Text("REMATCH")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent)
                        .foregroundStyle(Color(red: 0.25, green: 0.12, blue: 0.0))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .accessibilityIdentifier("rematchButton")
                Button(action: onHome) {
                    Text("HOME")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.panel)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .accessibilityIdentifier("homeButton")
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
    }

    private func crownColumn(_ label: String, _ count: Int, _ color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundStyle(i < count ? color : .white.opacity(0.2))
                }
            }
            Text(label).font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(count) crowns")
    }

    private func rewardRow(_ icon: String, _ label: String, _ delta: Int, total: Int) -> some View {
        HStack {
            Text(icon)
            Text(label)
            Spacer()
            Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                .foregroundStyle(delta > 0 ? .green : (delta < 0 ? Theme.enemy : .white.opacity(0.6)))
                .monospacedDigit()
            Text("(\(total))")
                .foregroundStyle(.white.opacity(0.5))
                .monospacedDigit()
        }
        .font(.subheadline.weight(.semibold))
    }
}
