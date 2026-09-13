import SwiftUI

@main
struct FestivalDonApp: App {
    var body: some Scene {
        WindowGroup {
            FestivalRoot()
                .statusBarHidden()
                .preferredColorScheme(.light)
        }
    }
}

struct FestivalRoot: View {
    @StateObject private var game = GameClient()

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 1000, geometry.size.height / 460)
            ZStack {
                FestivalPalette.ink.ignoresSafeArea()
                ZStack {
                    switch game.phase {
                    case "playing": GameStage(game: game)
                    case "results": ResultScreen(game: game)
                    case "lobby": LobbyScreen(game: game)
                    default: WelcomeScreen(game: game)
                    }
                    if game.showCalibration { CalibrationScreen(game: game) }
                    if !game.error.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(game.error).font(.system(size: 13, weight: .semibold))
                                Button("Dismiss") { game.error = "" }.font(.system(size: 13, weight: .bold))
                            }.padding(13).background(FestivalPalette.gold).clipShape(Capsule())
                                .padding(.bottom, 10)
                        }
                    }
                }
                .frame(width: 1000, height: 460)
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .font(.system(.body, design: .rounded))
            .foregroundStyle(FestivalPalette.ink)
        }
        .ignoresSafeArea()
    }
}

struct FestivalButton: ButtonStyle {
    var color = FestivalPalette.coral
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .black, design: .rounded))
            .padding(.horizontal, 18).padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .foregroundStyle(color == FestivalPalette.cream ? FestivalPalette.ink : .white)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(FestivalPalette.ink, lineWidth: 2))
            .shadow(color: FestivalPalette.ink, radius: 0, x: 0, y: configuration.isPressed ? 1 : 4)
            .offset(y: configuration.isPressed ? 3 : 0)
    }
}

struct FestivalPanel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(20).background(FestivalPalette.cream)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(FestivalPalette.ink, lineWidth: 2.5))
            .shadow(color: FestivalPalette.ink.opacity(0.12), radius: 0, x: 5, y: 6)
    }
}

struct WelcomeScreen: View {
    @ObservedObject var game: GameClient

    var body: some View {
        ZStack {
            FestivalBackdrop()
            VStack(alignment: .leading, spacing: 4) {
                Text("おまつりリズム • TWO-PLAYER DRUM DUEL")
                    .font(.system(size: 12, weight: .black, design: .rounded)).tracking(2)
                Text("Festival\nDon")
                    .font(.system(size: 78, weight: .black, design: .rounded))
                    .tracking(-4).lineSpacing(-14)
                    .foregroundStyle(FestivalPalette.coral)
                    .shadow(color: FestivalPalette.cream, radius: 0, x: 3, y: 3)
                Text("Two drums. One beat. A whole lot of joy.")
                    .font(.system(size: 14, weight: .heavy, design: .rounded)).padding(.top, 9)
                HStack(spacing: -10) {
                    MascotView().frame(width: 194, height: 160)
                    MascotView(blue: true).frame(width: 164, height: 155)
                }
            }.position(x: 283, y: 243)
            FestivalPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Meet at the festival").font(.system(size: 25, weight: .black, design: .rounded))
                    Text("Connect two iPhones to the same local server.")
                        .font(.system(size: 12, weight: .semibold))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("YOUR DRUMMER NAME").font(.system(size: 10, weight: .heavy)).tracking(1)
                        TextField("Guest name", text: $game.name).textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled().accessibilityIdentifier("guest-name")
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SERVER ADDRESS").font(.system(size: 10, weight: .heavy)).tracking(1)
                        TextField("ws://192.168.1.8:8786", text: $game.address).textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .font(.system(size: 13, design: .monospaced)).accessibilityIdentifier("server-address")
                    }
                    Button("Create a room  →") { game.createRoom() }
                        .buttonStyle(FestivalButton()).accessibilityIdentifier("create-room")
                    HStack(spacing: 12) {
                        TextField("ROOM CODE", text: $game.code).textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.characters).autocorrectionDisabled()
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .accessibilityIdentifier("room-code-entry")
                        Button("Join") { game.joinRoom() }.buttonStyle(FestivalButton(color: FestivalPalette.blue))
                            .frame(width: 100).accessibilityIdentifier("join-room")
                    }
                    Button { game.showCalibration = true } label: {
                        Label("Timing & how to play", systemImage: "slider.horizontal.3")
                            .font(.system(size: 12, weight: .heavy))
                    }.frame(maxWidth: .infinity).padding(.top, 3).accessibilityIdentifier("calibration")
                }
            }.frame(width: 373).position(x: 739, y: 238)
            Text("ORIGINAL MUSIC  /  LOCAL MULTIPLAYER  /  NO ACCOUNT NEEDED")
                .font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(1)
                .position(x: 500, y: 439)
        }
    }
}

struct LobbyScreen: View {
    @ObservedObject var game: GameClient

    var body: some View {
        ZStack {
            FestivalBackdrop()
            HStack {
                Button { game.leave() } label: { Label("Leave room", systemImage: "arrow.left") }
                Spacer()
                Text("CHOOSE YOUR FESTIVAL").font(.system(size: 21, weight: .black, design: .rounded)).tracking(1)
                Spacer()
                Button { game.showCalibration = true } label: { Label("Timing", systemImage: "slider.horizontal.3") }
            }.font(.system(size: 13, weight: .bold)).padding(.horizontal, 50).frame(height: 55)
                .background(FestivalPalette.cream).position(x: 500, y: 27.5)
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Text("THE SET LIST").font(.system(size: 12, weight: .black)).tracking(2)
                    Spacer()
                    Text(game.isHost ? "Host chooses the song" : "Waiting for host selection")
                        .font(.system(size: 11, weight: .semibold))
                }
                songCard("lantern", index: "01", icon: "sun.max.fill", color: FestivalPalette.coral)
                songCard("moon", index: "02", icon: "moon.stars.fill", color: Color(red: 0.36, green: 0.37, blue: 0.65))
                HStack {
                    ForEach(["easy", "festival"], id: \.self) { difficulty in
                        Button {
                            game.select(game.chart.id, difficulty: difficulty)
                        } label: {
                            Text(difficulty == "easy" ? "EASY  ★★" : "FESTIVAL  ★★★★")
                                .font(.system(size: 12, weight: .black)).frame(maxWidth: .infinity).padding(11)
                                .background(game.chart.difficulty == difficulty ? FestivalPalette.gold : FestivalPalette.cream)
                                .clipShape(Capsule()).overlay(Capsule().stroke(FestivalPalette.ink, lineWidth: 2))
                        }.disabled(!game.isHost).accessibilityIdentifier("difficulty-\(difficulty)")
                    }
                }
                HStack {
                    Button {
                        game.togglePreview()
                    } label: {
                        Label(game.previewing ? "Stop preview" : "Listen to the song", systemImage: game.previewing ? "stop.fill" : "play.fill")
                    }
                    Spacer()
                    Text("\(game.chart.notes.filter { $0.kind != "roll" }.count) notes • \(Int(game.chart.duration / 1000)) sec")
                }.font(.system(size: 12, weight: .heavy)).padding(.horizontal, 3)
            }.frame(width: 508).position(x: 306, y: 254)
            FestivalPanel {
                VStack(spacing: 11) {
                    Text("YOUR MEETING SPOT").font(.system(size: 10, weight: .black)).tracking(2)
                    Text(game.code).font(.system(size: 39, weight: .black, design: .monospaced)).tracking(4)
                        .accessibilityIdentifier("room-code")
                    Text("Share this code with your rival").font(.system(size: 11, weight: .semibold))
                    Rectangle().fill(FestivalPalette.ink.opacity(0.12)).frame(height: 1)
                    peerRow(game.local, fallback: game.name, blue: false)
                    peerRow(game.rival, fallback: "Waiting for a drummer…", blue: true)
                    Button(game.local?.ready == true ? "Ready!  •  Cancel" : "Ready to drum  →") { game.ready() }
                        .buttonStyle(FestivalButton()).accessibilityIdentifier("ready")
                    HStack(spacing: 4) {
                        Circle().fill(game.connection == "ONLINE" ? .green : .orange).frame(width: 7, height: 7)
                        Text("\(game.connection)  •  \(Int(game.rtt))ms  •  synced \(game.clockSamples)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                }
            }.frame(width: 321).position(x: 765, y: 250)
        }
    }

    private func peerRow(_ player: Drummer?, fallback: String, blue: Bool) -> some View {
        HStack(spacing: 8) {
            MascotView(blue: blue).frame(width: 57, height: 51)
            VStack(alignment: .leading, spacing: 3) {
                Text(player?.name ?? fallback).font(.system(size: 14, weight: .black))
                Text(player == nil ? "Send them the room code" : player?.connected == true ? "Connected guest" : "Disconnected")
                    .font(.system(size: 9, weight: .semibold))
            }
            Spacer()
            if player?.ready == true {
                Text("READY").font(.system(size: 10, weight: .black)).foregroundStyle(Color(red: 0.13, green: 0.46, blue: 0.34))
            }
        }
    }

    private func songCard(_ id: String, index: String, icon: String, color: Color) -> some View {
        let chart = SongChart.load(id)
        let selected = game.chart.id == id
        return Button {
            game.select(id)
        } label: {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13).fill(color)
                    Image(systemName: icon).font(.system(size: 33, weight: .black)).foregroundStyle(FestivalPalette.cream)
                }.frame(width: 74, height: 73)
                VStack(alignment: .leading, spacing: 4) {
                    Text("ORIGINAL  /  \(index)").font(.system(size: 9, weight: .black)).tracking(1)
                    Text(chart.title).font(.system(size: 25, weight: .black, design: .rounded))
                    Text(chart.subtitle).font(.system(size: 11, weight: .semibold))
                }
                Spacer()
                VStack(spacing: 5) {
                    Text("\(chart.bpm)").font(.system(size: 20, weight: .black))
                    Text("BPM").font(.system(size: 9, weight: .black))
                    if selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(color) }
                }
            }
            .padding(13).background(selected ? .white : FestivalPalette.cream)
            .clipShape(RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(selected ? color : FestivalPalette.ink, lineWidth: selected ? 4 : 2))
            .shadow(color: FestivalPalette.ink.opacity(0.13), radius: 0, x: 3, y: 4)
        }.disabled(!game.isHost).accessibilityIdentifier("song-\(id)")
    }
}
