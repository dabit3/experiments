import SwiftUI
import SpriteKit

struct Gear: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2
            for index in 0..<48 {
                let angle = CGFloat(index) * .pi / 24
                let tooth: CGFloat = index % 4 < 2 ? 1 : 0.83
                let point = CGPoint(x: center.x + cos(angle) * radius * tooth,
                                    y: center.y + sin(angle) * radius * tooth)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }
}

struct BattleView: View {
    @ObservedObject var client: DuelClient
    @State private var scene: ArenaScene = {
        let scene = ArenaScene(size: CGSize(width: 1100, height: 520))
        scene.scaleMode = .aspectFill
        return scene
    }()
    @State private var menu = false
    @State private var muted = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SpriteView(scene: scene).ignoresSafeArea()
                VStack(spacing: 0) {
                    hud
                    HStack {
                        Text("THE CATHEDRAL ENGINE")
                        Spacer()
                        Text("ROOM \(client.code) • \(client.connected ? "LIVE" : "RECONNECTING") • P\(slot + 1)")
                    }.font(.system(size: 7, weight: .bold, design: .monospaced))
                        .tracking(1).foregroundStyle(Palette.cream.opacity(0.8))
                        .padding(.horizontal, 24).padding(.top, 1)
                    if client.automated {
                        Text("AUTOMATED INPUT DRIVER • \(client.driverStep)")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 10).padding(.vertical, 3)
                            .background(Palette.black.opacity(0.85)).foregroundStyle(Palette.gold)
                    }
                    Spacer()
                    controls
                    meters
                }
                .padding(.horizontal, max(10, geometry.safeAreaInsets.leading - 12))
                .padding(.top, 8)
                .padding(.bottom, 7)
                if let state = client.state {
                    if state.paused || !client.connected {
                        centerPlate(title: "SIGNAL LOST", subtitle: "Duel paused • reconnecting guest • 30s grace")
                    } else if state.phase == "countdown" {
                        centerPlate(title: "DUEL \(state.round)",
                                    subtitle: state.countdown > 60 ? "HEAVEN'S GATES ARE OPEN" : "DRAW YOUR WEAPON")
                    } else if state.phase == "roundEnd" {
                        centerPlate(title: "ROUND \(state.round) COMPLETE",
                                    subtitle: winnerName(state.roundWinner) + " TAKES THE ROUND")
                    } else if state.phase == "result" {
                        result(state)
                    }
                }
                if menu {
                    VStack(spacing: 12) {
                        Text("DUEL OPTIONS").font(.custom("AvenirNextCondensed-Heavy", size: 25))
                        Text("An online match continues while this menu is open.").font(.system(size: 10))
                        Button(muted ? "ENABLE SOUND" : "MUTE SOUND") {
                            muted.toggle(); Sound.shared.muted = muted
                        }
                        Button("RECONNECT") { client.reconnect(); menu = false }
                        Button("RETURN TO DUEL") { menu = false }
                        Button("LEAVE ROOM") { client.leave() }
                    }.buttonStyle(MetalButton()).padding(25).background(Palette.black)
                        .overlay(Rectangle().stroke(Palette.gold, lineWidth: 1))
                }
            }
            .onAppear { scene.match = client.state }
            .onChange(of: client.state?.tick) { _, _ in scene.match = client.state }
        }.ignoresSafeArea()
    }

    private var slot: Int { client.me?.slot ?? 0 }

    private var hud: some View {
        HStack(spacing: 0) {
            if let first = client.state?.players.first { playerHUD(first, mirror: false) }
            ZStack {
                Gear().fill(Palette.black)
                Gear().stroke(Palette.gold, lineWidth: 2)
                Circle().stroke(Palette.cream.opacity(0.55), lineWidth: 1).padding(10)
                VStack(spacing: -6) {
                    Text("\(Int(ceil(client.state?.seconds ?? 60)))")
                        .font(.custom("AvenirNextCondensed-HeavyItalic", size: 42)).foregroundStyle(Palette.red)
                    Text("DUEL \(client.state?.round ?? 1)")
                        .font(.system(size: 7, weight: .heavy, design: .monospaced))
                }
            }.frame(width: 78, height: 66)
            if let last = client.state?.players.last { playerHUD(last, mirror: true) }
        }
    }

    private func playerHUD(_ player: Duelist, mirror: Bool) -> some View {
        VStack(alignment: mirror ? .trailing : .leading, spacing: 2) {
            HStack(spacing: 6) {
                if mirror { Spacer() }
                Text(player.style.uppercased())
                    .font(.custom("AvenirNextCondensed-HeavyItalic", size: 22))
                    .shadow(color: Palette.red, radius: 0, x: 2, y: 1)
                Text(player.name).font(.system(size: 9, weight: .bold)).lineLimit(1)
                if player.id == client.playerID {
                    Text("YOU").font(.system(size: 7, weight: .heavy))
                        .padding(.horizontal, 4).background(Palette.red)
                }
                if !mirror { Spacer() }
            }
            GeometryReader { geo in
                ZStack(alignment: mirror ? .trailing : .leading) {
                    BladePanel().fill(Palette.black)
                    BladePanel().fill(Palette.red.opacity(0.4))
                    BladePanel().fill(LinearGradient(colors: [Palette.red, .orange, Palette.gold],
                                                    startPoint: .bottom, endPoint: .top))
                        .frame(width: max(0, geo.size.width * player.hp / 100))
                    BladePanel().stroke(Palette.cream, lineWidth: 1.5)
                    HStack(spacing: 0) {
                        ForEach(0..<10) { _ in
                            Rectangle().fill(.black.opacity(0.3)).frame(width: 1)
                            Spacer(minLength: 0)
                        }
                    }.padding(.horizontal, 9)
                }
            }.frame(height: 17)
            HStack(spacing: 6) {
                if mirror { Spacer() }
                ForEach(0..<2) { index in
                    Image(systemName: index < player.wins ? "diamond.fill" : "diamond")
                        .font(.system(size: 9)).foregroundStyle(Palette.gold)
                }
                Text("\(Int(player.hp)) / 100").font(.system(size: 8, weight: .bold, design: .monospaced))
                if !mirror { Spacer() }
            }
        }.padding(.horizontal, 5)
    }

    private var controls: some View {
        HStack(alignment: .bottom, spacing: 8) {
            HStack(alignment: .bottom, spacing: 5) {
                HoldControl(title: "◀", subtitle: "MOVE", tint: Palette.black) { down in
                    client.action("move", value: down ? -1 : 0)
                }.accessibilityIdentifier("move-left")
                VStack(spacing: 3) {
                    actionButton("↑", subtitle: "JUMP", action: "jump", tint: Palette.black, width: 44)
                    actionButton("»", subtitle: "DASH", action: "dash", tint: Palette.black, width: 44)
                }
                HoldControl(title: "▶", subtitle: "MOVE", tint: Palette.black) { down in
                    client.action("move", value: down ? 1 : 0)
                }.accessibilityIdentifier("move-right")
            }
            Spacer(minLength: 0)
            VStack(spacing: 5) {
                Button { menu = true } label: {
                    Image(systemName: "line.3.horizontal").font(.system(size: 14)).padding(8)
                        .background(Palette.black.opacity(0.7)).clipShape(Circle())
                }.accessibilityIdentifier("duel-menu")
                Text(client.me?.style == "vesper" ? "CRESCENT REAPER" : "ENGINE CLEAVER")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8).padding(.vertical, 2).background(.black.opacity(0.75))
            }
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 5) {
                HoldControl(title: "◇", subtitle: "GUARD", tint: Palette.black) { down in
                    client.action("guard", value: down ? 1 : 0)
                }.accessibilityIdentifier("guard")
                actionButton("RC", subtitle: "CANCEL", action: "cancel", tint: Color.purple.opacity(0.8), width: 47)
                VStack(spacing: 3) {
                    actionButton("SP", subtitle: "SPECIAL", action: "special", tint: Palette.black, width: 50)
                    actionButton("S", subtitle: "SLASH", action: "slash", tint: Palette.red, width: 50)
                }
                actionButton("H", subtitle: "HEAVY", action: "heavy", tint: Palette.red, width: 52)
            }
        }
        .foregroundStyle(Palette.cream)
        .disabled(client.state?.phase != "fight" || client.state?.paused == true || !client.connected)
    }

    private func actionButton(_ title: String, subtitle: String, action: String, tint: Color, width: CGFloat) -> some View {
        Button { client.action(action) } label: {
            ControlFace(title: title, subtitle: subtitle, tint: tint).frame(width: width)
        }.buttonStyle(.plain).accessibilityLabel(subtitle).accessibilityIdentifier(action)
    }

    private var meters: some View {
        HStack(spacing: 100) {
            ForEach(client.state?.players ?? []) { player in
                VStack(alignment: player.slot == 0 ? .leading : .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("TENSION")
                        Text("\(Int(player.meter))%").foregroundStyle(Palette.gold)
                        Spacer()
                        Text(player.meter >= 50 ? "RED RC READY" : player.meter >= 25 ? "YELLOW RC READY" : "BUILD METER")
                    }.font(.system(size: 7, weight: .heavy, design: .monospaced))
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            BladePanel().fill(Palette.black)
                            BladePanel().fill(player.meter >= 50 ? Palette.red : Palette.gold)
                                .frame(width: geometry.size.width * player.meter / 100)
                            BladePanel().stroke(Palette.gold, lineWidth: 1)
                            HStack {
                                Spacer()
                                Rectangle().fill(Palette.cream).frame(width: 1)
                                Spacer()
                            }
                        }
                    }.frame(height: 8)
                }
            }
        }.padding(.horizontal, 5).padding(.top, 5)
    }

    private func centerPlate(title: String, subtitle: String) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.custom("AvenirNextCondensed-HeavyItalic", size: 42))
            Text(subtitle).font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(2)
        }
        .foregroundStyle(Palette.cream)
        .padding(.horizontal, 60).padding(.vertical, 16)
        .background(BladePanel().fill(Palette.black.opacity(0.9)))
        .overlay(BladePanel().stroke(Palette.gold, lineWidth: 1))
        .allowsHitTesting(false)
    }

    private func result(_ state: MatchState) -> some View {
        VStack(spacing: 7) {
            Text("THE REQUIEM IS WRITTEN").font(.system(size: 9, weight: .heavy, design: .monospaced)).tracking(3)
            Text(winnerName(state.winner) + " WINS")
                .font(.custom("AvenirNextCondensed-HeavyItalic", size: 40)).foregroundStyle(Palette.gold)
            Text(state.players.map { "\($0.style.uppercased())  \($0.wins)" }.joined(separator: "   :   "))
                .font(.system(size: 16, weight: .bold, design: .monospaced))
            HStack {
                Button(client.me?.rematch == true ? "REMATCH VOTED" : "REMATCH") { client.rematch() }
                    .disabled(client.me?.rematch == true).accessibilityIdentifier("rematch")
                Button("LEAVE ROOM") { client.leave() }
            }.buttonStyle(MetalButton(red: true))
            Text("Both duelists must accept • no score carries into a rematch.")
                .font(.system(size: 9))
        }
        .padding(22).background(Palette.black.opacity(0.95))
        .overlay(BladePanel().stroke(Palette.gold, lineWidth: 2))
        .accessibilityIdentifier("match-result")
    }

    private func winnerName(_ id: String) -> String {
        client.state?.players.first(where: { $0.id == id })?.style.uppercased() ?? "DRAW"
    }
}

struct ControlFace: View {
    let title: String
    let subtitle: String
    let tint: Color
    var body: some View {
        VStack(spacing: -3) {
            Text(title).font(.custom("AvenirNextCondensed-HeavyItalic", size: 23))
            Text(subtitle).font(.system(size: 6, weight: .heavy, design: .monospaced)).tracking(0.5)
        }.frame(maxWidth: .infinity).frame(height: 39)
            .background(BladePanel().fill(tint.opacity(0.88)))
            .overlay(BladePanel().stroke(Palette.cream.opacity(0.7), lineWidth: 1))
            .contentShape(Rectangle())
    }
}

struct HoldControl: View {
    let title: String
    let subtitle: String
    let tint: Color
    let changed: (Bool) -> Void
    @State private var down = false
    var body: some View {
        ControlFace(title: title, subtitle: subtitle, tint: down ? Palette.red : tint)
            .frame(width: 47)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in if !down { down = true; changed(true) } }
                .onEnded { _ in down = false; changed(false) })
            .onDisappear { if down { changed(false) } }
            .accessibilityLabel(subtitle)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { changed(true); DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { changed(false) } }
    }
}
