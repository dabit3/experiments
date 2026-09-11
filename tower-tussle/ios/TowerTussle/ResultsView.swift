import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var profile: PlayerProfile
    let result: MatchResult
    let onHome: () -> Void
    let onRematch: () -> Void
    @State private var revealed = false

    private var titleFill: LinearGradient {
        switch result.outcome {
        case .victory: return .goldText
        case .defeat: return .redText
        case .draw: return .whiteText
        }
    }

    var body: some View {
        ZStack {
            SceneryBackdrop(dim: result.outcome == .defeat ? 0.6 : 0.2)
            VStack(spacing: 22) {
                Spacer()
                RenderedImage(name: "emblem")
                    .saturation(result.outcome == .defeat ? 0.2 : 1)
                    .rotationEffect(.degrees(result.outcome == .defeat ? -12 : 0))
                    .frame(width: 180, height: 180)
                    .shadow(color: (result.outcome == .defeat ? Theme.enemy : Theme.accent).opacity(0.22), radius: 28)
                    .scaleEffect(revealed ? 1 : 0.4)
                    .opacity(revealed ? 1 : 0)
                DisplayText(text: result.outcome.rawValue, size: 56, fill: titleFill)
                    .accessibilityIdentifier("resultTitle")
                    .scaleEffect(revealed ? 1 : 1.6)
                    .opacity(revealed ? 1 : 0)

                HStack(spacing: 30) {
                    crownColumn("You", result.playerCrowns, Theme.player)
                    Text("VS").font(.system(.title3, design: .rounded).weight(.black)).foregroundStyle(.white.opacity(0.5))
                    crownColumn("Enemy", result.enemyCrowns, Theme.enemy)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .panel(cornerRadius: 22)

                VStack(spacing: 12) {
                    rewardRow(.trophy, "Trophies", result.trophyDelta, total: profile.trophies)
                    rewardRow(.coin, "Gold", result.goldDelta, total: profile.gold)
                    HStack(spacing: 10) {
                        IconView(kind: .clock, size: 24)
                        Text("Battle time")
                        Spacer()
                        Text(String(format: "%d:%02d", result.durationSeconds / 60, result.durationSeconds % 60)).monospacedDigit()
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                }
                .padding(16)
                .panel()
                .padding(.horizontal, 28)
                .foregroundStyle(.white)

                Spacer()

                VStack(spacing: 12) {
                    ChunkyButton(title: "REMATCH", icon: .swords, style: .gold, height: 58, fontSize: 24, action: onRematch)
                        .accessibilityIdentifier("rematchButton")
                    ChunkyButton(title: "HOME", style: .slate, height: 48, fontSize: 19, action: onHome)
                        .accessibilityIdentifier("homeButton")
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            ArcadeAudio.play(result.outcome == .victory ? .victory : (result.outcome == .defeat ? .defeat : .tap))
            withAnimation(.spring(duration: 0.6, bounce: 0.35)) { revealed = true }
        }
    }

    private func crownColumn(_ label: String, _ count: Int, _ color: Color) -> some View {
        VStack(spacing: 6) {
            CrownRow(count: count, color: color, size: 28)
            Text(label.uppercased()).font(.system(.caption, design: .rounded).weight(.black)).foregroundStyle(.white.opacity(0.75))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(count) crowns")
    }

    private func rewardRow(_ icon: IconKind, _ label: String, _ delta: Int, total: Int) -> some View {
        HStack(spacing: 10) {
            IconView(kind: icon, size: 24)
            Text(label)
            Spacer()
            Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                .foregroundStyle(delta > 0 ? Color(red: 0.45, green: 0.9, blue: 0.4) : (delta < 0 ? Theme.enemy : .white.opacity(0.6)))
                .monospacedDigit()
            Text("(\(total))")
                .foregroundStyle(.white.opacity(0.5))
                .monospacedDigit()
        }
        .font(.system(.subheadline, design: .rounded).weight(.bold))
    }
}

/// Large result badge: a trophy on a sunburst for victory, rubble for defeat, crossed swords for a draw.
struct ResultEmblem: View {
    let outcome: MatchOutcome

    var body: some View {
        Canvas(rendersAsynchronously: false) { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let d = min(size.width, size.height)
            let ray: Color = outcome == .victory ? Art.gold : (outcome == .defeat ? Theme.enemy : Color.white)
            var burst = ctx
            burst.opacity = 0.35
            for i in 0..<12 {
                let a = Double(i) / 12 * .pi * 2
                let b = a + .pi / 24
                let p = Art.polygon([c, CGPoint(x: c.x + cos(a) * d * 0.5, y: c.y + sin(a) * d * 0.5), CGPoint(x: c.x + cos(b) * d * 0.5, y: c.y + sin(b) * d * 0.5)])
                burst.fill(p, with: .color(ray))
            }
            Art.ball(&ctx, cx: c.x, cy: c.y, r: d * 0.3, color: Theme.panel, dark: Theme.background, line: 3)
            ctx.stroke(Art.circle(c.x, c.y, d * 0.3 - 4), with: .color(ray.opacity(0.7)), lineWidth: 2)
            switch outcome {
            case .victory:
                Art.trophy(&ctx, center: CGPoint(x: c.x, y: c.y + d * 0.02), size: d * 0.36)
            case .defeat:
                var r = ctx
                r.translateBy(x: c.x, y: c.y + d * 0.06)
                r.scaleBy(x: d * 0.26, y: d * 0.26)
                Art.rubble(&r, kind: .keep, side: .player, line: 0.09)
                Art.crown(&ctx, center: CGPoint(x: c.x + d * 0.04, y: c.y - d * 0.06), size: d * 0.18, color: Color(white: 0.6), dim: true)
            case .draw:
                Art.sword(&ctx, from: CGPoint(x: c.x - d * 0.16, y: c.y + d * 0.16), to: CGPoint(x: c.x + d * 0.16, y: c.y - d * 0.16), width: d * 0.045)
                Art.sword(&ctx, from: CGPoint(x: c.x + d * 0.16, y: c.y + d * 0.16), to: CGPoint(x: c.x - d * 0.16, y: c.y - d * 0.16), width: d * 0.045)
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
        .accessibilityHidden(true)
    }
}
