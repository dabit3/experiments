import SwiftUI

struct HomeView: View {
    @EnvironmentObject var profile: PlayerProfile
    let onBattle: () -> Void
    let onCards: () -> Void
    @State private var floating = false

    var body: some View {
        ZStack {
            SceneryBackdrop()
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    StatPill(icon: .trophy, value: "\(profile.trophies)", label: "Trophies")
                    StatPill(icon: .coin, value: "\(profile.gold)", label: "Gold")
                }
                .padding(.horizontal)
                .padding(.top, 8)

                VStack(spacing: -8) {
                    Text("THE SKY IS YOUR BATTLEFIELD")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.cyan.opacity(0.8))
                        .padding(.bottom, 16)
                    DisplayText(text: "TOWER", size: 52, fill: .whiteText)
                    DisplayText(text: "TUSSLE", size: 62, fill: .goldText)
                }
                .padding(.top, 24)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Tower Tussle")

                GeometryReader { geo in
                    RenderedImage(name: "hero")
                        .frame(width: geo.size.width + 18, height: geo.size.height + 22)
                        .offset(x: -9, y: floating ? -6 : 2)
                        .shadow(color: .cyan.opacity(0.15), radius: 24, y: 10)
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 4)

                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Circle().fill(.cyan).frame(width: 5, height: 5)
                        Text("SKYBOUND ARENA").tracking(2.5)
                        Circle().fill(.cyan).frame(width: 5, height: 5)
                    }
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 4)
                    ChunkyButton(title: "BATTLE", icon: .swords, style: .gold, height: 62, fontSize: 25, action: onBattle)
                        .accessibilityIdentifier("battleButton")
                    ChunkyButton(title: "CARDS", icon: .cards, style: .slate, height: 48, fontSize: 18, action: onCards)
                        .accessibilityIdentifier("cardsButton")

                    Text("\(profile.wins)W · \(profile.losses)L · \(profile.draws)D")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.75))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 1, y: 1)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { floating = true }
        }
    }
}

/// Hero illustration: the player's keep flanked by guard towers on a grassy mound.
struct LogoView: View {
    var body: some View {
        Canvas(rendersAsynchronously: false) { ctx, size in
            let w = size.width, h = size.height
            let unit = w / 6
            // mound
            ctx.fill(Art.ellipse(w / 2, h * 0.86, w * 0.5, h * 0.13), with: .color(.black.opacity(0.35)))
            ctx.fill(Art.ellipse(w / 2, h * 0.82, w * 0.48, h * 0.12), with: .linearGradient(Gradient(colors: [Color(red: 0.4, green: 0.7, blue: 0.3), Color(red: 0.2, green: 0.45, blue: 0.2)]), startPoint: CGPoint(x: 0, y: h * 0.7), endPoint: CGPoint(x: 0, y: h * 0.95)))
            Art.tower(&ctx, kind: .guardTower, side: .player, center: CGPoint(x: w * 0.2, y: h * 0.62), r: unit * 0.8, alive: true, activated: true, flash: false, time: 0)
            Art.tower(&ctx, kind: .guardTower, side: .player, center: CGPoint(x: w * 0.8, y: h * 0.62), r: unit * 0.8, alive: true, activated: true, flash: false, time: 0.6)
            Art.tower(&ctx, kind: .keep, side: .player, center: CGPoint(x: w * 0.5, y: h * 0.6), r: unit * 1.0, alive: true, activated: true, flash: false, time: 0)
            var knight = Art.Pose(); knight.facing = 1; knight.phase = 0.5; knight.moving = true
            var archer = Art.Pose(); archer.facing = -1
            Art.character(&ctx, id: "knight", side: .player, foot: CGPoint(x: w * 0.36, y: h * 0.92), r: unit * 0.5, pose: knight)
            Art.character(&ctx, id: "archers", side: .player, foot: CGPoint(x: w * 0.64, y: h * 0.92), r: unit * 0.45, pose: archer)
        }
        .shadow(color: .black.opacity(0.5), radius: 10, y: 8)
        .accessibilityHidden(true)
    }
}
