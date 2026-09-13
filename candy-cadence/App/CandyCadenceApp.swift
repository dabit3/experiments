import SwiftUI

@main
struct CandyCadenceApp: App {
  @StateObject private var client = GameClient()

  var body: some Scene {
    WindowGroup {
      RootView(client: client)
        .preferredColorScheme(.light)
        .onOpenURL { client.handleURL($0) }
    }
  }
}

struct RootView: View {
  @ObservedObject var client: GameClient
  @State private var showSettings = false

  var body: some View {
    ZStack {
      if client.state?.phase == "playing" {
        GameSurface(client: client).ignoresSafeArea()
        VStack {
          Spacer()
          HStack {
            Button("MENU") { showSettings = true }
              .font(.system(size: 11, weight: .heavy, design: .rounded))
              .padding(10)
              .background(.white.opacity(0.9), in: Capsule())
            Spacer()
          }
        }.padding(.leading, 18).padding(.bottom, 22)
      } else if client.state?.phase == "results" {
        ResultsView(client: client)
      } else {
        LobbyView(client: client, showSettings: $showSettings)
      }
    }
    .sheet(isPresented: $showSettings) {
      SettingsView(client: client)
    }
  }
}

struct CandyBackground: View {
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color(CandyPalette.cream)
        Canvas { context, size in
          for row in 0..<20 {
            for column in 0..<30 {
              let x = CGFloat(column * 48 + (row.isMultiple(of: 2) ? 0 : 24))
              let rect = CGRect(x: x, y: CGFloat(row * 48), width: 6, height: 6)
              context.fill(
                Path(ellipseIn: rect), with: .color(Color(CandyPalette.pink).opacity(0.15)))
            }
          }
        }
        RoundedRectangle(cornerRadius: 70)
          .fill(Color(CandyPalette.mint).opacity(0.2))
          .frame(width: geometry.size.width * 0.43, height: geometry.size.height * 1.7)
          .rotationEffect(.degrees(-14))
          .offset(x: -geometry.size.width * 0.35)
        RoundedRectangle(cornerRadius: 70)
          .fill(Color(CandyPalette.pink).opacity(0.09))
          .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 1.7)
          .rotationEffect(.degrees(16))
          .offset(x: geometry.size.width * 0.4)
      }
    }.ignoresSafeArea()
  }
}

struct CandyButtonStyle: ButtonStyle {
  var color = Color(CandyPalette.pink)

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 18, weight: .heavy, design: .rounded))
      .foregroundStyle(Color(CandyPalette.ink))
      .padding(.horizontal, 22).padding(.vertical, 14)
      .frame(maxWidth: .infinity)
      .background(color, in: RoundedRectangle(cornerRadius: 16))
      .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(CandyPalette.ink), lineWidth: 2.5))
      .shadow(color: Color(CandyPalette.ink), radius: 0, x: 0, y: configuration.isPressed ? 1 : 5)
      .offset(y: configuration.isPressed ? 4 : 0)
  }
}

struct CandyPanel<Content: View>: View {
  var color = Color.white
  @ViewBuilder let content: Content

  var body: some View {
    content.padding(22)
      .background(color, in: RoundedRectangle(cornerRadius: 24))
      .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(CandyPalette.ink), lineWidth: 2.5))
      .shadow(color: Color(CandyPalette.ink).opacity(0.13), radius: 0, x: 5, y: 6)
  }
}

struct LobbyView: View {
  @ObservedObject var client: GameClient
  @Binding var showSettings: Bool

  var body: some View {
    ZStack {
      CandyBackground()
      VStack(spacing: 18) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 0) {
            Text("THE NINE-BUTTON CANDY CLUB")
              .font(.system(size: 12, weight: .black, design: .rounded)).tracking(3)
            Text("Candy Cadence")
              .font(.system(size: 55, weight: .black, design: .rounded))
              .foregroundStyle(Color(CandyPalette.pink))
              .shadow(color: Color(CandyPalette.ink), radius: 0, x: 2, y: 3)
          }
          Spacer()
          Text("POP TOGETHER.\nSHINE TOGETHER.")
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .rotationEffect(.degrees(5)).padding(17)
            .background(Color(CandyPalette.yellow), in: RoundedRectangle(cornerRadius: 15))
            .overlay(
              RoundedRectangle(cornerRadius: 15).stroke(Color(CandyPalette.ink), lineWidth: 2)
                .rotationEffect(.degrees(5)))
          Button {
            showSettings = true
          } label: {
            Image(systemName: "slider.horizontal.3").font(.title2).padding(17)
          }.accessibilityLabel("Sound and timing settings")
        }
        HStack(alignment: .top, spacing: 22) {
          VStack(alignment: .leading, spacing: 14) {
            HStack {
              Text("01 / PICK YOUR JAM").font(.system(size: 20, weight: .black, design: .rounded))
              Spacer()
              Text("2 ORIGINAL TRACKS").font(.system(size: 10, weight: .heavy, design: .rounded))
            }
            ForEach(Song.catalog) { song in
              songCard(song)
            }
            CandyPanel(color: Color(CandyPalette.yellow).opacity(0.9)) {
              VStack(alignment: .leading, spacing: 8) {
                Text("HOW TO POP!").font(.system(size: 22, weight: .black, design: .rounded))
                Text(
                  "Tap the matching candy when its smiling note reaches the white line. Use both hands for chords!"
                )
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                HStack(spacing: 6) {
                  ForEach(0..<9) { lane in
                    ZStack {
                      Circle().fill(Color(CandyPalette.lanes[lane]))
                      Circle().stroke(Color(CandyPalette.ink), lineWidth: 2)
                      Text("\(lane + 1)").font(.system(size: 13, weight: .black))
                    }
                    .frame(width: 32, height: 32)
                    .offset(y: lane.isMultiple(of: 2) ? 10 : -5)
                  }
                }.frame(height: 50).frame(maxWidth: .infinity)
                Text(
                  "SWEET ±45ms  •  GREAT ±90ms  •  GOOD ±140ms\nBuild combos. Fill 70% groove to clear. Highest score wins."
                )
                .font(.system(size: 12, weight: .bold, design: .rounded))
              }.frame(maxWidth: .infinity, alignment: .leading)
            }
          }.frame(maxWidth: .infinity)
          VStack(alignment: .leading, spacing: 14) {
            Text("02 / BRING A FRIEND").font(.system(size: 20, weight: .black, design: .rounded))
            if let state = client.state {
              roomPanel(state)
            } else {
              connectPanel
            }
            HStack(spacing: 10) {
              Circle().fill(client.connected ? Color.green : Color.orange).frame(
                width: 9, height: 9)
              Text(client.status).font(.system(size: 13, weight: .semibold, design: .rounded))
            }.padding(.horizontal, 8)
            if client.automated {
              Text(
                "AUTOMATED INPUT DRIVER ENABLED\nBoth devices still send real lane inputs over WebSockets."
              )
              .font(.system(size: 12, weight: .heavy, design: .rounded))
              .padding(12).frame(maxWidth: .infinity)
              .background(Color(CandyPalette.yellow), in: RoundedRectangle(cornerRadius: 12))
            }
          }.frame(maxWidth: .infinity)
        }
        Spacer(minLength: 0)
        HStack {
          Text("NATIVE iPAD / REAL-TIME TWO-PLAYER COMPETITION")
          Spacer()
          Text("HEADPHONES RECOMMENDED  •  PLAY ON THE SAME Wi-Fi")
        }.font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(1)
      }.padding(.horizontal, 36).padding(.top, 22).padding(.bottom, 16)
    }.foregroundStyle(Color(CandyPalette.ink))
  }

  private func songCard(_ song: Song) -> some View {
    let selected = client.song.id == song.id
    return Button {
      if client.state != nil { client.send(Command(type: "select", songID: song.id)) }
    } label: {
      HStack(spacing: 16) {
        ZStack {
          RoundedRectangle(cornerRadius: 18).fill(
            song.id == "sugar" ? Color(CandyPalette.pink) : Color(CandyPalette.mint))
          Text(song.id == "sugar" ? "★" : "✦")
            .font(.system(size: 50, weight: .black, design: .rounded))
            .foregroundStyle(
              song.id == "sugar" ? Color(CandyPalette.yellow) : Color(CandyPalette.ink))
          Text("♪").font(.system(size: 30, weight: .heavy)).rotationEffect(.degrees(-20)).offset(
            x: 22, y: 15)
        }.frame(width: 85, height: 86)
        VStack(alignment: .leading, spacing: 5) {
          Text(song.genre).font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(2)
          Text(song.title).font(.system(size: 23, weight: .black, design: .rounded))
          Text(song.artist).font(.system(size: 9, weight: .bold, design: .rounded))
          Text("\(song.bpm) BPM   •   \(song.notes.count) NOTES   •   LEVEL \(song.level)")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
        }
        Spacer(minLength: 0)
        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
          .font(.title2).foregroundStyle(selected ? Color(CandyPalette.pink) : .gray)
      }.padding(15)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
        .overlay(
          RoundedRectangle(cornerRadius: 22).stroke(
            selected ? Color(CandyPalette.pink) : Color(CandyPalette.ink),
            lineWidth: selected ? 4 : 2))
    }
    .buttonStyle(.plain)
    .disabled(!client.isHost)
    .accessibilityLabel("Select \(song.title)")
  }

  private var connectPanel: some View {
    CandyPanel {
      VStack(alignment: .leading, spacing: 15) {
        Text("Your backstage pass").font(.system(size: 26, weight: .black, design: .rounded))
        Text("No accounts. Just a guest name and a room code.")
          .font(.system(size: 14, weight: .medium, design: .rounded))
        field("GUEST NAME", text: $client.guestName, placeholder: "Mallow")
        field("SERVER ADDRESS", text: $client.serverAddress, placeholder: "ws://192.168.1.20:8789")
        Button("CREATE A ROOM") { client.connect(create: true) }
          .buttonStyle(CandyButtonStyle(color: Color(CandyPalette.pink)))
        HStack {
          Rectangle().frame(height: 1)
          Text("OR JOIN YOUR FRIEND").font(.system(size: 10, weight: .heavy, design: .rounded))
            .fixedSize()
          Rectangle().frame(height: 1)
        }.foregroundStyle(Color(CandyPalette.ink).opacity(0.4)).padding(.top, 5)
        field("ROOM CODE", text: $client.roomCode, placeholder: "ABC123")
        Button("JOIN THE PARTY") { client.connect(create: false) }
          .buttonStyle(CandyButtonStyle(color: Color(CandyPalette.mint)))
      }
    }
  }

  private func field(_ title: String, text: Binding<String>, placeholder: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(title).font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(1)
      TextField(placeholder, text: text)
        .font(.system(size: 17, weight: .semibold, design: .rounded))
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .padding(11).background(Color(CandyPalette.cream), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
          RoundedRectangle(cornerRadius: 10).stroke(
            Color(CandyPalette.ink).opacity(0.4), lineWidth: 1)
        )
        .accessibilityLabel(title)
    }
  }

  private func roomPanel(_ state: RoomState) -> some View {
    CandyPanel {
      VStack(spacing: 17) {
        Text("YOUR ROOM CODE").font(.system(size: 12, weight: .heavy, design: .rounded)).tracking(3)
        Text(state.room).font(.system(size: 44, weight: .black, design: .monospaced))
          .foregroundStyle(Color(CandyPalette.pink)).textSelection(.enabled)
        Text(
          client.isHost
            ? "Pick a song, then both players tap READY."
            : "Your host picks the song. Tap READY when you're set."
        )
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        ForEach(state.players) { player in
          HStack {
            Circle().fill(player.connected ? Color(CandyPalette.mint) : .gray).frame(
              width: 14, height: 14)
            VStack(alignment: .leading, spacing: 3) {
              Text(player.name).font(.system(size: 20, weight: .heavy, design: .rounded))
              Text(player.id == client.playerID ? "YOU" : "CONNECTED PEER").font(
                .system(size: 9, weight: .bold, design: .rounded))
            }
            Spacer()
            Text(player.ready ? "READY!" : player.connected ? "GETTING SET" : "OFFLINE")
              .font(.system(size: 12, weight: .heavy, design: .rounded))
          }.padding(12).background(
            Color(CandyPalette.cream), in: RoundedRectangle(cornerRadius: 12))
        }
        if state.players.count < 2 {
          Text("Waiting for player two…\nShare the room code and server address.")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity).padding(18)
        }
        Button(client.me?.ready == true ? "READY! / TAP TO CANCEL" : "I'M READY — LET'S POP!") {
          client.send(Command(type: "ready"))
        }.buttonStyle(CandyButtonStyle(color: Color(CandyPalette.yellow)))
          .disabled(!client.connected)
        HStack {
          Button("Reconnect") { client.reconnect() }
          Spacer()
          Button("Leave room") { client.leave() }
        }.font(.system(size: 13, weight: .bold, design: .rounded))
      }
    }
  }
}

struct SettingsView: View {
  @ObservedObject var client: GameClient
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section("Sound") {
          Slider(value: $client.volume, in: 0...1) { Text("Music volume") }
          Text("Music volume: \(Int(client.volume * 100))%")
        }
        Section("Timing calibration") {
          Slider(value: $client.calibration, in: -100...100, step: 5) { Text("Input offset") }
          Text("Input offset: \(Int(client.calibration)) ms")
          Text(
            "Positive values judge your taps later. Start at 0 ms with wired audio. Bluetooth adds device-specific latency."
          )
        }
        Section("Connection") {
          Text(client.status)
          Text("Clock round trip: \(Int(client.clockRTT)) ms")
          if client.state != nil {
            Button("Reconnect to room") {
              client.reconnect()
              dismiss()
            }
            Button("Leave room", role: .destructive) {
              client.leave()
              dismiss()
            }
          }
        }
        Section("Fair play") {
          Text(
            "A live match keeps running while this menu is open. The server owns scores and missed notes."
          )
          Text(
            "Nine simultaneous touch controls. COOL 45 ms / GREAT 90 ms / GOOD 140 ms / BAD 180 ms."
          )
        }
      }
      .navigationTitle("Sound & timing")
      .toolbar { Button("Done") { dismiss() } }
    }.presentationDetents([.large])
  }
}

struct ResultsView: View {
  @ObservedObject var client: GameClient

  private var headline: String {
    guard let me = client.me, let rival = client.rival else { return "SONG COMPLETE!" }
    if me.score == rival.score { return "A SWEET TIE!" }
    return me.score > rival.score ? "YOU'RE THE CHERRY ON TOP!" : "THAT WAS A SWEET JAM!"
  }

  var body: some View {
    ZStack {
      CandyBackground()
      VStack(spacing: 20) {
        Text("CANDY CADENCE / RESULTS").font(.system(size: 14, weight: .black, design: .rounded))
          .tracking(4)
        Text(headline).font(.system(size: 40, weight: .black, design: .rounded))
          .foregroundStyle(Color(CandyPalette.pink))
        Text(client.song.title + "  •  ROOM " + client.roomCode)
          .font(.system(size: 18, weight: .heavy, design: .rounded))
        HStack(spacing: 25) {
          ForEach(client.state?.players ?? []) { player in
            resultCard(player)
          }
        }
        HStack(spacing: 24) {
          Button("REMATCH / PICK ANOTHER JAM") { client.send(Command(type: "rematch")) }
            .buttonStyle(CandyButtonStyle(color: Color(CandyPalette.yellow)))
          Button("LEAVE ROOM") { client.leave() }
            .buttonStyle(CandyButtonStyle(color: Color(CandyPalette.mint)))
        }.padding(.top, 5)
        Text(
          "Scores and outcome confirmed by the room server. Both players see the same final totals."
        )
        .font(.system(size: 12, weight: .semibold, design: .rounded))
      }.padding(40)
    }.foregroundStyle(Color(CandyPalette.ink))
  }

  private func resultCard(_ player: Peer) -> some View {
    CandyPanel {
      VStack(spacing: 14) {
        Text(player.id == client.playerID ? "\(player.name) / YOU" : "\(player.name) / RIVAL")
          .font(.system(size: 24, weight: .black, design: .rounded))
        Text(player.groove >= 70 ? "STAGE CLEAR!" : "SONG FINISHED")
          .font(.system(size: 16, weight: .black, design: .rounded))
          .padding(.horizontal, 20).padding(.vertical, 8)
          .background(
            Color(player.groove >= 70 ? CandyPalette.mint : CandyPalette.yellow), in: Capsule())
        Text(String(format: "%07d", player.score)).font(
          .system(size: 54, weight: .black, design: .rounded))
        HStack {
          stat("MAX COMBO", "\(player.maxCombo)")
          stat("GROOVE", "\(player.groove)%")
        }
        Divider()
        HStack {
          stat("SWEET", "\(player.counts.cool)")
          stat("GREAT", "\(player.counts.great)")
          stat("GOOD", "\(player.counts.good)")
          stat("BAD", "\(player.counts.bad)")
          stat("MISS", "\(player.counts.miss)")
        }
        Text(player.automated ? "AUTOMATED INPUT DRIVER" : "HUMAN TOUCH INPUT")
          .font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(1)
      }.frame(maxWidth: .infinity)
    }
  }

  private func stat(_ label: String, _ value: String) -> some View {
    VStack(spacing: 4) {
      Text(label).font(.system(size: 9, weight: .heavy, design: .rounded))
      Text(value).font(.system(size: 22, weight: .black, design: .rounded))
    }.frame(maxWidth: .infinity)
  }
}
