import SwiftUI

struct ResultScreen: View {
    @ObservedObject var game: GameClient
    @State private var appeared = false

    private var title: String {
        if game.room?.winner == "draw" { return "A perfect pair!" }
        return game.room?.winner == game.playerID ? "You lit up the festival!" : "What a joyful duel!"
    }

    var body: some View {
        ZStack {
            FestivalBackdrop()
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                Canvas { context, _ in
                    let time = timeline.date.timeIntervalSince1970
                    for index in 0..<55 {
                        let x = Double((index * 137) % 1000)
                        let y = (Double(index * 67) + time * (25 + Double(index % 4) * 6)).truncatingRemainder(dividingBy: 490) - 15
                        var ctx = context
                        ctx.translateBy(x: x + sin(time + Double(index)) * 12, y: y)
                        ctx.rotate(by: .radians(time + Double(index)))
                        FestivalArt.box(ctx, CGRect(x: -3, y: -5, width: 7, height: 11),
                                        color: [FestivalPalette.coral, FestivalPalette.gold, FestivalPalette.blue, .white][index % 4], radius: 2)
                    }
                }
            }.allowsHitTesting(false)
            VStack(spacing: 4) {
                Text("演奏終了 • FESTIVAL RESULTS").font(.system(size: 11, weight: .black)).tracking(3)
                Text(title).font(.system(size: 34, weight: .black, design: .rounded))
                Text("\(game.chart.title)  •  \(game.chart.difficulty.uppercased())  •  ROUND \(game.room?.round ?? 1)")
                    .font(.system(size: 12, weight: .bold))
            }.position(x: 500, y: 58).accessibilityIdentifier("results-title")
            HStack(spacing: 22) {
                resultCard(game.local, blue: false)
                resultCard(game.rival, blue: true)
            }.frame(width: 788).position(x: 500, y: 240)
                .scaleEffect(appeared ? 1 : 0.85).opacity(appeared ? 1 : 0)
            HStack(spacing: 17) {
                Button("Leave festival") { game.leave() }
                    .buttonStyle(FestivalButton(color: FestivalPalette.cream)).frame(width: 194)
                Button(game.local?.ready == true ? "Waiting for rival…" : "One more song!  ↻") { game.ready() }
                    .buttonStyle(FestivalButton()).frame(width: 283).accessibilityIdentifier("rematch")
                Button("Song select") { game.send(ClientMessage(type: "songs")) }
                    .buttonStyle(FestivalButton(color: FestivalPalette.blue)).frame(width: 194)
                    .disabled(!game.isHost).opacity(game.isHost ? 1 : 0.55).accessibilityIdentifier("song-select")
            }.position(x: 500, y: 420)
            Text("Shared result • \(game.room?.code ?? "") • \(game.connection)")
                .font(.system(size: 9, weight: .semibold, design: .monospaced)).position(x: 500, y: 453)
        }
        .onAppear { withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) { appeared = true } }
    }

    private func resultCard(_ player: Drummer?, blue: Bool) -> some View {
        FestivalPanel {
            VStack(spacing: 7) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player?.name ?? "Guest").font(.system(size: 21, weight: .black))
                        Text(game.room?.winner == player?.id ? "WINNER • FESTIVAL STAR" : game.room?.winner == "draw" ? "TIED DUEL" : "THANKS FOR THE RHYTHM")
                            .font(.system(size: 9, weight: .black)).foregroundStyle(blue ? FestivalPalette.blue : FestivalPalette.coral)
                    }
                    Spacer()
                    MascotView(blue: blue).frame(width: 88, height: 72)
                }
                Text("\(player?.score ?? 0)").font(.system(size: 45, weight: .black, design: .rounded)).monospacedDigit()
                    .accessibilityIdentifier(blue ? "result-rival-score" : "result-local-score")
                Text(player?.bad == 0 ? "FULL COMBO!" : (player?.gauge ?? 0) >= 70 ? "FESTIVAL CLEAR!" : "KEEP THE BEAT!")
                    .font(.system(size: 11, weight: .black)).padding(.horizontal, 17).padding(.vertical, 4)
                    .background(FestivalPalette.gold).clipShape(Capsule())
                HStack {
                    stat("GOOD", "\(player?.good ?? 0)", FestivalPalette.coral)
                    stat("OK", "\(player?.ok ?? 0)", FestivalPalette.blue)
                    stat("MISS / BAD", "\(player?.bad ?? 0)", FestivalPalette.ink)
                }.padding(.top, 4)
                HStack {
                    Text("Best combo  \(player?.maxCombo ?? 0)")
                    Spacer()
                    Text("Rolls  \(player?.rolls ?? 0)  •  Big  \(player?.bigHits ?? 0)")
                }.font(.system(size: 10, weight: .heavy))
            }
        }
    }

    private func stat(_ name: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 22, weight: .black)).foregroundStyle(color)
            Text(name).font(.system(size: 8, weight: .black))
        }.frame(maxWidth: .infinity)
    }
}
