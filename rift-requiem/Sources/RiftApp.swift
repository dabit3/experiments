import SwiftUI
import SpriteKit

enum Palette {
    static let cream = Color(uiColor: Ink.cream)
    static let red = Color(uiColor: Ink.red)
    static let gold = Color(uiColor: Ink.gold)
    static let black = Color(uiColor: Ink.black)
}

struct BladePanel: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 10, y: 0))
            path.addLines([CGPoint(x: rect.maxX, y: 0),
                           CGPoint(x: rect.maxX - 10, y: rect.maxY),
                           CGPoint(x: 0, y: rect.maxY)])
            path.closeSubpath()
        }
    }
}

struct MetalButton: ButtonStyle {
    var red = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("AvenirNextCondensed-Heavy", size: 15))
            .tracking(1)
            .padding(.horizontal, 18).padding(.vertical, 9)
            .foregroundStyle(Palette.cream)
            .background(BladePanel().fill(red ? Palette.red : Palette.black.opacity(0.9)))
            .overlay(BladePanel().stroke(Palette.gold, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

@main
struct RiftApp: App {
    @StateObject private var client = DuelClient()
    var body: some Scene {
        WindowGroup {
            RootView(client: client)
                .preferredColorScheme(.dark)
                .onOpenURL { client.open($0) }
                .onAppear {
                    Sound.shared.start()
                    if Launch.value("connect") == "1" { client.connect() }
                }
        }
    }
}

struct RootView: View {
    @ObservedObject var client: DuelClient
    @State private var muted = false
    @State private var showGuide = false

    var body: some View {
        ZStack {
            Palette.black.ignoresSafeArea()
            if let state = client.state, state.phase != "lobby" {
                BattleView(client: client)
            } else {
                lobby
            }
            if !client.error.isEmpty {
                VStack(spacing: 12) {
                    Text("SIGNAL INTERRUPTED").font(.title2.bold())
                    Text(client.error).multilineTextAlignment(.center)
                    Button("DISMISS") { client.error = "" }.buttonStyle(MetalButton(red: true))
                }
                .padding(28).frame(maxWidth: 430)
                .background(Palette.black).overlay(Rectangle().stroke(Palette.red, lineWidth: 2))
            }
            if showGuide {
                guide
            }
        }
        .foregroundStyle(Palette.cream)
        .statusBarHidden()
    }

    private var lobby: some View {
        GeometryReader { geometry in
            ZStack {
                Image("cathedral").resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                LinearGradient(colors: [.black.opacity(0.88), .black.opacity(0.3), .black.opacity(0.88)],
                               startPoint: .leading, endPoint: .trailing)
                HStack(spacing: 25) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("CATHEDRAL ENGINE / NETWORK DUEL").font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(2).foregroundStyle(Palette.gold)
                        Text("RIFT\nREQUIEM")
                            .font(.custom("AvenirNextCondensed-HeavyItalic", size: min(geometry.size.height * 0.15, 64)))
                            .lineSpacing(-17).shadow(color: .black, radius: 0, x: 4, y: 4)
                        Rectangle().fill(Palette.red).frame(width: 170, height: 4).padding(.vertical, 8)
                        Text("BREAK THE CLOCK.\nWRITE YOUR REQUIEM.")
                            .font(.custom("AvenirNextCondensed-DemiBold", size: 14)).tracking(2)
                        Spacer(minLength: 10)
                        HStack {
                            Button("HOW TO FIGHT") { showGuide = true }
                            Button(muted ? "SOUND OFF" : "SOUND ON") {
                                muted.toggle(); Sound.shared.muted = muted
                            }
                        }.buttonStyle(MetalButton())
                        Text("ORIGINAL FIGHTERS • REAL-TIME TWO-PLAYER")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(Palette.gold)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: 9) {
                        if client.connected {
                            roomLobby
                        } else {
                            connectionForm
                        }
                    }
                    .padding(18).frame(width: min(geometry.size.width * 0.47, 410))
                    .background(Palette.black.opacity(0.93))
                    .overlay(BladePanel().stroke(Palette.gold.opacity(0.7), lineWidth: 1))
                }
                .padding(.horizontal, max(30, geometry.safeAreaInsets.leading))
                .padding(.vertical, 24)
            }
        }.ignoresSafeArea()
    }

    private var connectionForm: some View {
        Group {
            Text("SELECT YOUR DUELIST").font(.custom("AvenirNextCondensed-Heavy", size: 21)).tracking(2)
            HStack(spacing: 10) {
                selection("rook", title: "ROOK", subtitle: "ENGINE CLEAVER")
                selection("vesper", title: "VESPER", subtitle: "CRESCENT REAPER")
            }
            HStack(spacing: 10) {
                field("GUEST NAME", text: $client.name, prompt: "Guest")
                field("ROOM CODE", text: $client.roomCode, prompt: "NEW ROOM")
            }
            field("SERVER ADDRESS", text: $client.address, prompt: "ws://host:8787")
            Button(client.roomCode.isEmpty ? "CREATE DUEL ROOM  →" : "JOIN DUEL ROOM  →") { client.connect() }
                .buttonStyle(MetalButton(red: true)).accessibilityIdentifier("connect")
            Text(client.status).font(.system(size: 8, design: .monospaced)).foregroundStyle(Palette.gold)
        }
    }

    private var roomLobby: some View {
        Group {
            Text("DUEL ROOM").font(.custom("AvenirNextCondensed-DemiBold", size: 16)).tracking(3)
            Text(client.code).font(.system(size: 35, weight: .black, design: .monospaced))
                .foregroundStyle(Palette.gold).accessibilityIdentifier("roomCode")
            Text("Share this code with the second device.").font(.system(size: 11))
            Divider().overlay(Palette.gold)
            ForEach(client.state?.players ?? []) { player in
                HStack {
                    Text(player.style.uppercased()).font(.custom("AvenirNextCondensed-Heavy", size: 19))
                    Text(player.name).font(.system(size: 11))
                    Spacer()
                    Text(player.ready ? "READY" : "STANDBY").font(.system(size: 10, weight: .bold))
                        .foregroundStyle(player.ready ? Palette.gold : .gray)
                }
            }
            if client.state?.players.count == 1 {
                Text("02 / WAITING FOR A CHALLENGER").font(.system(size: 11, design: .monospaced)).padding(.vertical, 10)
            }
            Button(client.me?.ready == true ? "READY — WAITING" : "READY / DRAW WEAPONS") { client.ready() }
                .buttonStyle(MetalButton(red: true)).accessibilityIdentifier("ready")
                .disabled(client.me?.ready == true)
            Button("LEAVE ROOM") { client.leave() }.buttonStyle(MetalButton())
            Text(client.status).font(.system(size: 8, design: .monospaced)).foregroundStyle(Palette.gold)
        }
    }

    private func selection(_ style: String, title: String, subtitle: String) -> some View {
        Button { client.style = style } label: {
            VStack(spacing: 0) {
                FighterPreview(style: style).frame(height: 79).clipped().allowsHitTesting(false)
                Text(title).font(.custom("AvenirNextCondensed-HeavyItalic", size: 18))
                Text(subtitle).font(.system(size: 7, weight: .bold, design: .monospaced)).padding(.bottom, 5)
            }.frame(maxWidth: .infinity)
                .background(client.style == style ? Palette.red.opacity(0.65) : .black)
                .overlay(Rectangle().stroke(client.style == style ? Palette.gold : .gray.opacity(0.3), lineWidth: 1))
        }.buttonStyle(.plain).accessibilityIdentifier("select-\(style)")
    }

    private func field(_ label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(Palette.gold)
            TextField(prompt, text: text)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .font(.system(size: 12, design: .monospaced))
                .padding(7).background(.white.opacity(0.07))
                .accessibilityIdentifier(label)
        }
    }

    private var guide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THE DUELIST'S CODE").font(.custom("AvenirNextCondensed-HeavyItalic", size: 30))
            Text("MOVE / Hold ◀ or ▶. JUMP / Tap ↑. DASH / Tap » on the ground or once in air.")
            Text("S / Quick slash. H / Heavy weapon: longer reach, more recovery. SP / Travelling special.")
            Text("GUARD / Hold to block facing attacks. Chip still hurts. Release before attacking.")
            Text("RC / Requiem Cancel: 25 meter neutral; 50 during an attack. Ends recovery and slows your rival.")
            Text("Build meter by advancing and trading hits. Chain a hit → RC → weapon for a combo.")
            Text("Best of three • 60 seconds per round • both players must vote for a rematch.")
            Text("Rook: engine cleaver / Vesper: longer-reaching crescent scythe.")
            Button("RETURN TO THE RIFT") { showGuide = false }.buttonStyle(MetalButton(red: true))
        }
        .font(.system(size: 12)).padding(25).frame(maxWidth: 660)
        .background(Palette.black).overlay(Rectangle().stroke(Palette.gold, lineWidth: 1))
    }
}

struct FighterPreview: View {
    let style: String
    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
    }
    private var scene: SKScene {
        let scene = SKScene(size: CGSize(width: 230, height: 160))
        scene.backgroundColor = .clear
        scene.scaleMode = .aspectFill
        let art = FighterArt(style: style)
        art.position = CGPoint(x: 110, y: -90)
        art.setScale(0.92)
        art.animate(pose: "idle", frame: 0, time: 0, facing: 1, stunned: false)
        scene.addChild(art)
        return scene
    }
}
