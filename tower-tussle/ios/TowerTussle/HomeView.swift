import SwiftUI

struct HomeView: View {
    @EnvironmentObject var profile: PlayerProfile
    let onBattle: () -> Void
    let onCards: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                StatPill(icon: "🏆", value: "\(profile.trophies)", label: "Trophies")
                StatPill(icon: "🪙", value: "\(profile.gold)", label: "Gold")
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()

            VStack(spacing: 6) {
                Text("🏰")
                    .font(.system(size: 84))
                    .shadow(color: .black.opacity(0.5), radius: 8, y: 6)
                Text("TOWER")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.accent)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 3, y: 3)
                Text("TUSSLE")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 3, y: 3)
                    .padding(.top, -18)
                Text("Real-time tower defense duels")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Tower Tussle")

            Spacer()

            VStack(spacing: 14) {
                Button(action: onBattle) {
                    HStack {
                        Text("⚔️")
                        Text("BATTLE")
                    }
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(colors: [Theme.accent, Color(red: 0.95, green: 0.5, blue: 0.1)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .foregroundStyle(Color(red: 0.25, green: 0.12, blue: 0.0))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 4)
                }
                .accessibilityIdentifier("battleButton")

                Button(action: onCards) {
                    HStack {
                        Text("🃏")
                        Text("CARDS")
                    }
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.panel)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.15), lineWidth: 1))
                }
                .accessibilityIdentifier("cardsButton")

                Text("\(profile.wins)W · \(profile.losses)L · \(profile.draws)D")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Text(icon).font(.title3)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .monospacedDigit()
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.panel)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
