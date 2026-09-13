import SwiftUI

struct GameStage: View {
    @ObservedObject var game: GameClient

    var body: some View {
        ZStack {
            FestivalBackdrop(night: game.chart.id == "moon")
            Canvas { context, _ in drawStage(context) }
                .accessibilityHidden(true)
            VStack(spacing: 0) {
                HStack {
                    Button { game.leave() } label: { Label("Leave", systemImage: "arrow.left") }
                    Spacer()
                    Text(game.chart.title).font(.system(size: 22, weight: .black, design: .rounded))
                    Text("• \(game.chart.bpm) BPM").font(.system(size: 13, weight: .bold))
                    Spacer()
                    Text("ROOM \(game.code)").font(.system(size: 13, weight: .black, design: .monospaced))
                    Circle().fill(game.connection == "ONLINE" ? .green : .orange).frame(width: 9, height: 9)
                    Button { game.reconnect() } label: { Image(systemName: "arrow.clockwise") }
                        .accessibilityLabel("Reconnect").accessibilityIdentifier("reconnect")
                }
                .padding(.horizontal, 50).frame(height: 52).background(FestivalPalette.cream)
                Spacer()
            }
            scoreBadge
                .position(x: 105, y: 90)
            VStack(spacing: 1) {
                Text("RIVAL  \(game.rival?.name ?? "Waiting")")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                Text("\(game.rival?.score ?? 0)")
                    .font(.system(size: 23, weight: .black, design: .rounded)).monospacedDigit()
                    .accessibilityIdentifier("rival-score")
            }.foregroundStyle(FestivalPalette.ink).position(x: 835, y: 87)
            Text("COMBO").font(.system(size: 10, weight: .heavy)).position(x: 105, y: 193)
            Text("\(game.local?.combo ?? 0)").font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(FestivalPalette.gold).shadow(color: FestivalPalette.ink, radius: 1, x: 2, y: 2)
                .position(x: 105, y: 157).accessibilityIdentifier("combo")
            DrumTouchView { kind, hand in game.hit(kind, hand: hand) }
                .frame(width: 460, height: 168).position(x: 530, y: 362)
            VStack(spacing: 6) {
                Text("ひびけ！").font(.system(size: 20, weight: .black))
                Text("LET JOY\nMAKE NOISE").font(.system(size: 12, weight: .black, design: .rounded)).multilineTextAlignment(.center)
                Text("\(game.local?.rolls ?? 0) roll hits").font(.system(size: 13, weight: .bold))
            }.foregroundStyle(FestivalPalette.ink).position(x: 853, y: 349)
            VStack(spacing: 3) {
                Text("DON • CENTER    /    KA • BLUE RIM").font(.system(size: 11, weight: .black, design: .rounded))
                Text("Big faces: both hands together   •   Yellow: roll!").font(.system(size: 10, weight: .semibold))
            }.foregroundStyle(FestivalPalette.ink).position(x: 530, y: 442)
            if game.automated {
                Button {
                    game.automationPaused.toggle()
                } label: {
                    Text(game.automationPaused ? "DRIVER PAUSED • touch drums" : "AUTOMATED INPUT DRIVER • tap to pause")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(FestivalPalette.ink).foregroundStyle(.white).clipShape(Capsule())
                }
                .accessibilityIdentifier("automation-toggle")
                .position(x: 500, y: 64)
            }
            if game.elapsed < 0 { countdown }
            if game.connection != "ONLINE" {
                Text("Reconnecting… your room and score are reserved")
                    .font(.system(size: 14, weight: .bold)).padding(10)
                    .background(FestivalPalette.gold).clipShape(Capsule()).position(x: 500, y: 295)
            } else if game.rival?.connected == false {
                Text("Your rival disconnected • waiting for rejoin")
                    .font(.system(size: 13, weight: .bold)).padding(8)
                    .background(FestivalPalette.gold).clipShape(Capsule()).position(x: 500, y: 295)
            }
        }
        .foregroundStyle(FestivalPalette.ink)
    }

    private var scoreBadge: some View {
        VStack(spacing: 0) {
            Text("YOU • \(game.local?.name ?? game.name)").font(.system(size: 11, weight: .black, design: .rounded))
            Text("\(game.local?.score ?? 0)")
                .font(.system(size: 28, weight: .black, design: .rounded)).monospacedDigit()
                .accessibilityIdentifier("local-score")
        }
    }

    private var countdown: some View {
        VStack(spacing: 4) {
            Text("DRUMMERS, READY?").font(.system(size: 16, weight: .black, design: .rounded))
            Text("\(max(1, Int(ceil(-game.elapsed / 1000))))")
                .font(.system(size: 86, weight: .black, design: .rounded)).foregroundStyle(FestivalPalette.coral)
            Text("Listen to the count-in").font(.system(size: 13, weight: .bold))
        }
        .frame(width: 270, height: 172).background(FestivalPalette.cream)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(FestivalPalette.ink, lineWidth: 3))
        .position(x: 500, y: 230)
    }

    private func drawStage(_ context: GraphicsContext) {
        let time = game.now / 1000
        let elapsed = game.elapsed
        FestivalArt.box(context, CGRect(x: 45, y: 121, width: 909, height: 94), color: FestivalPalette.coral, radius: 10, line: 3)
        FestivalArt.box(context, CGRect(x: 158, y: 121, width: 797, height: 94), color: Color(red: 0.25, green: 0.14, blue: 0.19))
        FestivalArt.box(context, CGRect(x: 45, y: 227, width: 909, height: 49), color: FestivalPalette.blue, radius: 8, line: 2)
        FestivalArt.box(context, CGRect(x: 158, y: 227, width: 797, height: 49), color: Color(red: 0.14, green: 0.22, blue: 0.30))
        FestivalArt.text(context, "2P", x: 104, y: 250, size: 23)
        drawLane(context, elapsed: elapsed, y: 165, radius: 23, player: game.local, mini: false)
        drawLane(context, elapsed: elapsed, y: 250, radius: 13, player: game.rival, mini: true)
        drawGauge(context)
        let recent = Date().timeIntervalSince1970 - game.judgmentAt
        if recent < 0.55, let judgment = game.local?.judgment, !judgment.isEmpty {
            let good = judgment == "GOOD" || judgment == "BIG!" || judgment == "ROLL!"
            if good {
                FestivalArt.flower(context, x: 204, y: 166, radius: 28 + recent * 18, color: FestivalPalette.gold.opacity(0.5 - recent * 0.7))
            }
            FestivalArt.text(context, judgment, x: 280, y: 112, size: 23, color: good ? Color(red: 0.70, green: 0.26, blue: 0.04) : FestivalPalette.ink)
            if judgment == "GOOD" || judgment == "OK" {
                FestivalArt.text(context, "\(game.local?.delta ?? 0) ms", x: 360, y: 109, size: 10)
            }
        }
        FestivalArt.mascot(context, x: 145, y: 350, scale: 0.88, blue: false, time: time)
        FestivalArt.drum(context, x: 410, y: 362, flash: game.leftFlash, kind: game.flashKind, time: Date().timeIntervalSince1970)
        FestivalArt.drum(context, x: 650, y: 362, flash: game.rightFlash, kind: game.flashKind, time: Date().timeIntervalSince1970)
        let progress = min(1, max(0, elapsed / game.chart.duration))
        FestivalArt.box(context, CGRect(x: 45, y: 282, width: 909, height: 4), color: FestivalPalette.ink.opacity(0.1), radius: 2)
        FestivalArt.box(context, CGRect(x: 45, y: 282, width: 909 * progress, height: 4), color: FestivalPalette.coral, radius: 2)
    }

    private func drawGauge(_ context: GraphicsContext) {
        let gauge = game.local?.gauge ?? 0
        for segment in 0..<40 {
            let active = Double(segment) < gauge * 0.4
            let color: Color = segment < 28 ? FestivalPalette.gold : FestivalPalette.coral
            FestivalArt.box(context, CGRect(x: 417 + Double(segment) * 8.0, y: 88, width: 6, height: 15),
                            color: active ? color : FestivalPalette.ink.opacity(0.12), radius: 1)
        }
        FestivalArt.text(context, "SOUL", x: 392, y: 95, size: 10)
        FestivalArt.text(context, "CLEAR", x: 658, y: 80, size: 8)
        FestivalArt.line(context, [CGPoint(x: 641, y: 85), CGPoint(x: 641, y: 106)], color: FestivalPalette.ink, width: 1)
    }

    private func drawLane(_ context: GraphicsContext, elapsed: Double, y: Double, radius: Double, player: Drummer?, mini: Bool) {
        var ctx = context
        ctx.clip(to: Path(CGRect(x: 158, y: y - radius - 16, width: 794, height: radius * 2 + 41)))
        let target = 204.0
        let speed = 0.27
        let beatMS = 60000 / Double(game.chart.bpm)
        let beatIndex = Int(floor((elapsed - 2000) / beatMS))
        for beat in beatIndex...(beatIndex + 8) {
            let x = target + (Double(beat) * beatMS + 2000 - elapsed) * speed
            FestivalArt.line(ctx, [CGPoint(x: x, y: y - radius - 10), CGPoint(x: x, y: y + radius + 30)], color: .white.opacity(0.10), width: 1)
        }
        FestivalArt.ellipse(ctx, x: target, y: y, width: radius * 2 + 12, height: radius * 2 + 12, color: .white.opacity(0.08))
        let targetPath = Path(ellipseIn: CGRect(x: target - radius - 5, y: y - radius - 5, width: radius * 2 + 10, height: radius * 2 + 10))
        ctx.stroke(targetPath, with: .color(FestivalPalette.cream.opacity(0.85)), lineWidth: 3)
        let consumed = Set(player?.consumed ?? [])
        for note in game.chart.notes where !consumed.contains(note.id) {
            let x = target + (note.at - elapsed) * speed
            let end = x + note.duration * speed
            guard end > 140 && x < 1000 else { continue }
            if note.kind == "roll" {
                FestivalArt.box(ctx, CGRect(x: x, y: y - radius * 0.72, width: max(20, note.duration * speed), height: radius * 1.44),
                                color: FestivalPalette.gold, radius: radius * 0.65, line: 2)
                FestivalArt.ellipse(ctx, x: x, y: y, width: radius * 1.8, height: radius * 1.8, color: FestivalPalette.gold, line: 2)
                FestivalArt.text(ctx, "≋", x: x, y: y, size: radius)
                if !mini { FestivalArt.text(ctx, "ROLL!", x: x + note.duration * speed / 2, y: y + radius + 16, size: 10, color: FestivalPalette.gold) }
            } else {
                FestivalArt.face(ctx, x: x, y: y, radius: radius * (note.big ? 1.35 : 1), blue: note.kind == "ka", big: note.big, happy: false)
                if !mini { FestivalArt.text(ctx, note.big ? "BOTH!" : note.kind.uppercased(), x: x, y: y + radius + 16, size: 10, color: .white) }
            }
        }
    }
}
