import SwiftUI

@main
struct OrbitEncoreApp: App {
    @StateObject private var client = GameClient()

    var body: some Scene {
        WindowGroup {
            ContentView(client: client)
                .preferredColorScheme(.dark)
                .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        }
    }
}

private let pink = Color(UIColor.orbitPink)
private let cyan = Color(UIColor.orbitCyan)
private let gold = Color(UIColor.orbitGold)
private let ink = Color(UIColor.orbitInk)

struct ContentView: View {
    @ObservedObject var client: GameClient
    @State private var showHelp = false
    @State private var showSettings = false
    @State private var previewing = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [Color(red: 0.10, green: 0.05, blue: 0.26), ink, Color(red: 0.03, green: 0.13, blue: 0.24)],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    if client.phase == "connect" {
                        connection
                    } else if client.phase == "lobby" {
                        lobby
                    } else if client.phase == "results" {
                        results
                    } else {
                        game(width: geometry.size.width)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 2)
                if !client.error.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Text(client.error).font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Button("Dismiss") { client.error = "" }
                        }
                        .padding(16).background(Color(red: 0.43, green: 0.07, blue: 0.20), in: RoundedRectangle(cornerRadius: 18))
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showHelp) { help }
        .sheet(isPresented: $showSettings) { settings }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                Text("ORBIT").font(.system(size: 28, weight: .black, design: .rounded)).tracking(4)
                Text("E N C O R E").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(cyan)
            }
            Spacer()
            if client.phase != "connect" {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(client.snapshot?.room ?? "").font(.system(size: 14, weight: .black, design: .monospaced)).foregroundStyle(gold)
                    Text(client.connected ? "● LIVE / \(Int(client.clockRTT))ms" : "RECONNECTING")
                        .font(.system(size: 9, weight: .bold)).foregroundStyle(client.connected ? cyan : pink)
                }
            }
            Button { showHelp = true } label: {
                Image(systemName: "questionmark.circle").font(.system(size: 22)).foregroundStyle(.white.opacity(0.8)).frame(width: 38, height: 44)
            }.accessibilityLabel("How to play")
            if client.phase != "playing" {
                Button { showSettings = true } label: {
                    Image(systemName: "slider.horizontal.3").font(.system(size: 20)).foregroundStyle(.white.opacity(0.8)).frame(width: 32, height: 44)
                }.accessibilityLabel("Audio and connection settings")
            }
        }
        .padding(.bottom, 14)
    }

    private var connection: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack(alignment: .bottom) {
                    Image("cosmic-bunny").resizable().scaledToFill().frame(height: 235).clipped()
                    LinearGradient(colors: [.clear, ink], startPoint: .center, endPoint: .bottom)
                    VStack(spacing: 6) {
                        Text("YOUR NEXT").font(.system(size: 12, weight: .heavy)).tracking(4).foregroundStyle(cyan)
                        Text("COSMIC ENCORE").font(.system(size: 25, weight: .black, design: .rounded))
                    }.padding(.bottom, 14)
                }.clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(pink.opacity(0.45), lineWidth: 1))
                HStack(spacing: 10) {
                    capsule("8 TOUCH", color: pink)
                    capsule("2 PLAYERS", color: cyan)
                    capsule("ORIGINAL MUSIC", color: gold)
                }
                VStack(alignment: .leading, spacing: 11) {
                    Text("STEP INTO THE ORBIT").font(.system(size: 13, weight: .black)).tracking(1.5)
                    field("GUEST NAME", text: $client.guestName, placeholder: "Your stage name", id: "guestName")
                    field("SERVER ADDRESS", text: $client.serverAddress, placeholder: "ws://192.168.1.10:8788", id: "serverAddress")
                    field("ROOM CODE  ·  LEAVE EMPTY TO HOST", text: $client.roomCode, placeholder: "Six-letter code", id: "roomCode")
                    primary(client.connecting ? "CONNECTING…" : (client.roomCode.isEmpty ? "CREATE A STAGE" : "JOIN THE STAGE"),
                            icon: "sparkles") { client.connect() }
                        .disabled(client.connecting)
                }.padding(16).background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 20))
                Text(client.status).font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.6))
                Text("HEADPHONES ON. WORLD OFF.").font(.system(size: 10, weight: .bold)).tracking(2).foregroundStyle(pink)
            }.padding(.bottom, 18)
        }.scrollIndicators(.hidden)
    }

    private var lobby: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("THE STAGE IS YOURS").font(.system(size: 20, weight: .black, design: .rounded))
                        Text("Share code \(client.roomCode) with your rival.").font(.system(size: 12)).foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    Button { UIPasteboard.general.string = client.roomCode } label: {
                        Image(systemName: "square.on.square").foregroundStyle(cyan).frame(width: 44, height: 44)
                    }.accessibilityLabel("Copy room code")
                }
                HStack(spacing: 10) {
                    peerCard(client.me, title: "YOU", color: pink)
                    peerCard(client.rival, title: "RIVAL", color: cyan)
                }
                HStack {
                    Text("SELECT YOUR TRACK").font(.system(size: 11, weight: .black)).tracking(2)
                    Spacer()
                    Text(client.isHost ? "HOST SELECTS" : "HOST IS SELECTING").font(.system(size: 9, weight: .bold)).foregroundStyle(gold)
                }.padding(.top, 7)
                ForEach(client.charts) { chart in
                    Button { client.select(chart) } label: {
                        HStack(spacing: 12) {
                            Image("cosmic-bunny").resizable().scaledToFill().frame(width: 83, height: 83)
                                .hueRotation(.degrees(chart.id == "neon" ? 80 : 0)).clipped().clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(chart.title).font(.system(size: 19, weight: .black, design: .rounded))
                                Text(chart.artist).font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(.white.opacity(0.5))
                                Text("\(chart.bpm) BPM  /  \(Int(chart.duration)) SEC").font(.system(size: 11, weight: .bold)).foregroundStyle(cyan)
                                Text("\(chart.difficulty)  \(chart.level)").font(.system(size: 10, weight: .black))
                                    .foregroundStyle(chart.id == "neon" ? pink : gold)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: client.chart?.id == chart.id ? "checkmark.circle.fill" : "circle").foregroundStyle(cyan)
                        }
                        .padding(12).background(client.chart?.id == chart.id ? cyan.opacity(0.10) : .white.opacity(0.035),
                                                in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .stroke(client.chart?.id == chart.id ? cyan : .white.opacity(0.1), lineWidth: 1))
                    }.buttonStyle(.plain).disabled(!client.isHost)
                }
                HStack {
                    Button {
                        previewing.toggle()
                        if previewing {
                            _ = client.audio.play(song: client.chart?.id ?? "sugar", startAt: client.serverNow, now: client.serverNow)
                        } else { client.audio.stop() }
                    } label: {
                        Label(previewing ? "Stop preview" : "Listen to track", systemImage: previewing ? "stop.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold)).foregroundStyle(cyan).padding(.vertical, 12)
                    }
                    Spacer()
                    Text("\(client.chart?.notes.count ?? 0) NOTES").font(.system(size: 10, weight: .black)).foregroundStyle(.white.opacity(0.5))
                }
                primary(client.me?.ready == true ? "READY · TAP TO CANCEL" : "READY TO ORBIT", icon: "bolt.fill") {
                    previewing = false
                    client.audio.stop()
                    client.ready()
                }.disabled(client.rival == nil || !client.clockReady)
                Text(client.rival == nil ? "Waiting for a second player to join…" : "Both players ready → five-second countdown.")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
                Button("Leave stage") { client.leave() }.font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
                    .frame(height: 44)
            }.padding(.bottom, 20)
        }.scrollIndicators(.hidden)
    }

    private func game(width: CGFloat) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.chart?.title ?? "").font(.system(size: 21, weight: .black, design: .rounded))
                    Text("\(client.chart?.bpm ?? 0) BPM   •   \(client.chart?.difficulty ?? "") \(client.chart?.level ?? 0)")
                        .font(.system(size: 10, weight: .bold)).foregroundStyle(gold)
                }
                Spacer()
                Image("cosmic-bunny").resizable().scaledToFill().frame(width: 44, height: 44).clipped().clipShape(RoundedRectangle(cornerRadius: 10))
            }
            HStack(spacing: 10) {
                scoreCard(client.me, title: "YOU", color: pink)
                scoreCard(client.rival, title: "RIVAL", color: cyan)
            }.padding(.top, 4)
            if !client.automation.isEmpty {
                Text("AUTOMATED INPUT  /  \(client.automation.uppercased())")
                    .font(.system(size: 9, weight: .black)).tracking(1.2).foregroundStyle(gold)
                    .frame(maxWidth: .infinity).padding(.vertical, 5).background(gold.opacity(0.08), in: Capsule())
            } else {
                Text("TOUCH THE RING. TRACE THE STARS.").font(.system(size: 9, weight: .bold)).tracking(1.4).foregroundStyle(.white.opacity(0.5))
            }
            ZStack {
                ArenaView(client: client)
                TimelineView(.animation(minimumInterval: 0.1)) { _ in
                    if client.songTime < 0 {
                        VStack(spacing: 2) {
                            Text("GET READY").font(.system(size: 14, weight: .black)).tracking(3)
                            Text("\(max(1, Int(ceil(-client.songTime))))").font(.system(size: 82, weight: .black, design: .rounded)).foregroundStyle(gold)
                            Text("TWO PLAYERS · ONE ORBIT").font(.system(size: 9, weight: .bold)).foregroundStyle(cyan)
                        }.padding(20).background(ink.opacity(0.86), in: RoundedRectangle(cornerRadius: 25))
                    }
                }.allowsHitTesting(false)
            }.frame(width: width - 8, height: width - 8).padding(.horizontal, -14)
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(format: "%.2f%%", client.me?.accuracy ?? 0))
                        .font(.system(size: 31, weight: .black, design: .rounded)).foregroundStyle(cyan).monospacedDigit()
                    Text("ACHIEVEMENT").font(.system(size: 9, weight: .black)).tracking(2).foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(client.me?.combo ?? 0)").font(.system(size: 38, weight: .black, design: .rounded)).foregroundStyle(gold).monospacedDigit()
                    Text("COMBO").font(.system(size: 9, weight: .black)).tracking(2).foregroundStyle(.white.opacity(0.45))
                }
            }
            TimelineView(.animation(minimumInterval: 0.1)) { _ in
                VStack(spacing: 7) {
                    ProgressView(value: max(0, min(1, client.songTime / (client.chart?.duration ?? 1)))).tint(pink)
                    HStack {
                        Text(client.songTime < 0 ? "SYNCED START" : "LIVE SCORE BATTLE")
                        Spacer()
                        Text("\(max(0, Int((client.chart?.duration ?? 0) - client.songTime)))s")
                    }.font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.5))
                }
            }
            HStack(spacing: 14) {
                legend("● TAP", pink)
                legend("━ HOLD", pink)
                legend("★ SLIDE", cyan)
                legend("✦ BREAK", gold)
            }.padding(.top, 4)
            Spacer(minLength: 0)
            if !client.connected {
                Button("Reconnect to stage") { client.reconnect() }.foregroundStyle(gold)
            }
        }
    }

    private var results: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("STAGE COMPLETE").font(.system(size: 12, weight: .black)).tracking(4).foregroundStyle(cyan)
                ZStack {
                    Image("cosmic-bunny").resizable().scaledToFill().frame(height: 185).clipped().opacity(0.5)
                    LinearGradient(colors: [ink.opacity(0.1), ink], startPoint: .top, endPoint: .bottom)
                    VStack(spacing: 3) {
                        Text(resultTitle).font(.system(size: 42, weight: .black, design: .rounded)).foregroundStyle(gold)
                        Text(client.chart?.title ?? "").font(.system(size: 16, weight: .bold))
                        Text("SHARED RESULT  /  MATCH \(client.snapshot?.matchID ?? 0)")
                            .font(.system(size: 9, weight: .black)).tracking(1).foregroundStyle(cyan)
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 22))
                HStack(spacing: 10) {
                    scoreCard(client.me, title: "YOU", color: pink)
                    scoreCard(client.rival, title: "RIVAL", color: cyan)
                }
                HStack {
                    stat(String(format: "%.2f%%", client.me?.accuracy ?? 0), label: "ACHIEVEMENT", color: cyan)
                    Spacer()
                    stat("\(client.me?.maxCombo ?? 0)", label: "MAX COMBO", color: gold)
                    Spacer()
                    stat(rank, label: "RANK", color: pink)
                }.padding(16).background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
                VStack(spacing: 12) {
                    ForEach(["PERFECT", "GREAT", "GOOD", "MISS"], id: \.self) { grade in
                        HStack {
                            Text(grade).font(.system(size: 12, weight: .black)).foregroundStyle(grade == "MISS" ? pink : cyan)
                            Spacer()
                            Text("\(client.me?.counts[grade] ?? 0)").font(.system(size: 17, weight: .black, design: .monospaced))
                            Text("/ \(client.rival?.counts[grade] ?? 0)").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }.padding(18).background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
                primary(client.me?.ready == true ? "WAITING FOR RIVAL…" : "ONE MORE ENCORE", icon: "arrow.clockwise") { client.rematch() }
                    .disabled(client.me?.ready == true)
                Text("Both choose encore to return to track selection.").font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
                Button("Leave stage") { client.leave() }.foregroundStyle(.white.opacity(0.6)).font(.system(size: 13, weight: .bold)).frame(height: 44)
            }.padding(.bottom, 20)
        }.scrollIndicators(.hidden)
    }

    private var resultTitle: String {
        let own = client.me?.score ?? 0
        let other = client.rival?.score ?? 0
        return own == other ? "DRAW!" : own > other ? "YOU WIN!" : "NICE PLAY!"
    }

    private var rank: String {
        let accuracy = client.me?.accuracy ?? 0
        return accuracy >= 98 ? "SS" : accuracy >= 90 ? "S" : accuracy >= 80 ? "A" : accuracy >= 65 ? "B" : "C"
    }

    private func primary(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title).tracking(1)
                Spacer()
                Image(systemName: "arrow.right")
            }.font(.system(size: 13, weight: .black)).foregroundStyle(ink)
                .padding(.horizontal, 20).frame(height: 53)
                .background(LinearGradient(colors: [cyan, Color(red: 0.66, green: 1, blue: 0.92)], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 15))
        }.buttonStyle(.plain)
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 8, weight: .black)).tracking(1.2).foregroundStyle(.white.opacity(0.5))
            TextField(placeholder, text: text).font(.system(size: 14, weight: .semibold, design: .rounded))
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .padding(11).background(ink, in: RoundedRectangle(cornerRadius: 9)).accessibilityIdentifier(id)
        }
    }

    private func capsule(_ label: String, color: Color) -> some View {
        Text(label).font(.system(size: 8, weight: .black)).tracking(0.6).foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 8).background(color.opacity(0.10), in: Capsule())
    }

    private func peerCard(_ player: Player?, title: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 9, weight: .black)).tracking(2).foregroundStyle(color)
            Text(player?.name ?? "Open slot").font(.system(size: 18, weight: .black, design: .rounded)).lineLimit(1)
            Text(player == nil ? "WAITING FOR RIVAL" : player?.ready == true ? "● READY" : "● CONNECTED")
                .font(.system(size: 9, weight: .bold)).foregroundStyle(player?.ready == true ? gold : .white.opacity(0.5))
        }.frame(maxWidth: .infinity, alignment: .leading).padding(15)
            .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }

    private func scoreCard(_ player: Player?, title: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title).foregroundStyle(color)
                Spacer()
                Text(player?.name ?? "Rival").lineLimit(1)
            }.font(.system(size: 9, weight: .black))
            Text(String(format: "%07d", player?.score ?? 0)).font(.system(size: 24, weight: .black, design: .rounded)).monospacedDigit()
            HStack {
                Text(player?.connected == true ? "● ONLINE" : "○ OFFLINE")
                Spacer()
                Text("\(player?.combo ?? 0) COMBO")
            }.font(.system(size: 8, weight: .bold)).foregroundStyle(color.opacity(0.8))
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.065), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(color.opacity(0.32), lineWidth: 1))
    }

    private func legend(_ text: String, _ color: Color) -> some View {
        Text(text).font(.system(size: 9, weight: .black)).foregroundStyle(color)
    }

    private func stat(_ value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value).font(.system(size: 23, weight: .black, design: .rounded)).foregroundStyle(color)
            Text(label).font(.system(size: 8, weight: .black)).tracking(1)
        }
    }

    private var help: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("FIND YOUR ORBIT").font(.system(size: 28, weight: .black, design: .rounded)).foregroundStyle(cyan)
                    helpRow("01", "Tap the outer ring",
                            "Pink rings travel from the center. Touch the matching numbered target when a ring reaches it. "
                            + "Every lane accepts a fingertip-sized area.", pink)
                    helpRow("02", "Hold the long notes",
                            "Keep your finger on the target until the pink tail reaches the rim. "
                            + "Letting go early or moving away breaks the hold.", pink)
                    helpRow("03", "Follow the star",
                            "Tap the blue star head on time, then trace each cyan arrow in order. "
                            + "Finish at the far endpoint with the moving star. Teleporting to the end won't clear the path.", cyan)
                    helpRow("04", "Make it a duet",
                            "Yellow pairs require two fingers. Sparkling gold break notes are worth five taps. A miss resets your combo.", gold)
                    helpRow("05", "Battle together",
                            "Create a stage, share its code, join from another phone and both tap Ready. "
                            + "Both play the same song on a shared clock; highest achievement wins.", cyan)
                    Text("PERFECT ±50ms  ·  GREAT ±105ms  ·  GOOD ±160ms\n"
                         + "Use wired audio for best timing. Adjust audio offset in settings.")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.6))
                }.padding(24)
            }.background(ink).toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showHelp = false } } }
        }
    }

    private func helpRow(_ number: String, _ title: String, _ detail: String, _ color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 17, weight: .heavy))
                Text(detail).font(.system(size: 14)).foregroundStyle(.white.opacity(0.65)).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var settings: some View {
        NavigationStack {
            Form {
                Section("Audio") {
                    HStack { Text("Music volume"); Spacer(); Text("\(Int(client.musicVolume * 100))%") }
                    Slider(value: $client.musicVolume, in: 0...1).tint(cyan)
                    HStack { Text("Audio delay"); Spacer(); Text("\(Int(client.audioOffset * 1000))ms") }
                    Slider(value: $client.audioOffset, in: -0.2...0.2, step: 0.005).tint(pink)
                    Text("Positive values play audio later. Applied at the next song start; scoring and the shared chart clock remain unchanged.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Connection") {
                    Text(client.serverAddress).font(.caption.monospaced())
                    Text("Clock sample RTT: \(Int(client.clockRTT))ms").font(.caption)
                    if client.connected { Button("Reconnect this player") { client.reconnect(); showSettings = false } }
                }
                Section("Credits") {
                    Text("Original art and music: Orbit Sound System\nReference-inspired arcade rhythm game. Not affiliated with SEGA.")
                        .font(.caption)
                }
            }.navigationTitle("Stage settings").toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { showSettings = false } }
            }
        }
    }
}
