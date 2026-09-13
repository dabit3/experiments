import SwiftUI

@main
struct LaserOverdriveApp: App {
  @StateObject private var model = GameModel()

  var body: some Scene {
    WindowGroup {
      RootView(model: model)
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
  }
}

struct CutPanel: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: 12, y: 0))
      path.addLine(to: CGPoint(x: rect.width, y: 0))
      path.addLine(to: CGPoint(x: rect.width, y: rect.height - 12))
      path.addLine(to: CGPoint(x: rect.width - 12, y: rect.height))
      path.addLine(to: CGPoint(x: 0, y: rect.height))
      path.addLine(to: CGPoint(x: 0, y: 12))
      path.closeSubpath()
    }
  }
}

struct ArcadeButton: ButtonStyle {
  var color = Color(Neon.cyan)
  var filled = true

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 13, weight: .heavy, design: .monospaced))
      .tracking(1)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 17)
      .foregroundStyle(filled ? Color(Neon.ink) : color)
      .background(CutPanel().fill(filled ? color : color.opacity(0.07)))
      .overlay(CutPanel().stroke(color.opacity(0.8), lineWidth: 1))
      .opacity(configuration.isPressed ? 0.65 : 1)
  }
}

struct PhotonArtwork: View {
  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      ZStack {
        LinearGradient(
          colors: [Color(red: 0.08, green: 0.08, blue: 0.22), .black],
          startPoint: .topLeading, endPoint: .bottomTrailing)
        Canvas { context, size in
          for index in 0..<13 {
            var path = Path()
            path.move(to: CGPoint(x: size.width / 2, y: 20))
            path.addLine(to: CGPoint(x: CGFloat(index) * size.width / 12, y: size.height))
            context.stroke(
              path,
              with: .color(
                index < 6 ? Color(Neon.cyan).opacity(0.2) : Color(Neon.pink).opacity(0.2)))
          }
          for index in 0..<5 {
            let y = size.height * CGFloat(index) / 5
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(line, with: .color(.white.opacity(0.06)))
          }
        }
        ForEach(0..<4) { index in
          Rectangle()
            .stroke(
              index.isMultiple(of: 2) ? Color(Neon.cyan) : Color(Neon.pink),
              lineWidth: index == 0 ? 3 : 1
            )
            .frame(width: CGFloat(43 + index * 24), height: CGFloat(43 + index * 24))
            .rotationEffect(.degrees(45))
            .scaleEffect(x: 1, y: 0.7)
            .shadow(color: Color(Neon.pink).opacity(0.6), radius: 10)
        }
        Text("ION")
          .font(.system(size: width * 0.16, weight: .black, design: .rounded))
          .italic()
          .tracking(5)
          .shadow(color: .black, radius: 5)
        VStack {
          HStack {
            Text("ORIGINAL SOUND / 001")
            Spacer()
            Text("144 BPM")
          }
          Spacer()
          HStack {
            Text("AFTERBURN")
              .font(.system(size: 13, weight: .black, design: .monospaced))
              .tracking(3)
            Spacer()
            Text("EXH / 07").foregroundStyle(Color(Neon.gold))
          }
        }
        .font(.system(size: 8, weight: .medium, design: .monospaced))
        .foregroundStyle(Color(Neon.cyan))
        .padding(15)
      }
      .clipShape(CutPanel())
      .overlay(CutPanel().stroke(Color(Neon.muted).opacity(0.5)))
    }
  }
}

struct RootView: View {
  @ObservedObject var model: GameModel
  @State private var confirmLeave = false

  var body: some View {
    ZStack {
      Color(Neon.ink).ignoresSafeArea()
      if model.phase == "playing" {
        Highway(model: model).ignoresSafeArea()
        VStack {
          HStack {
            Button("EXIT") { confirmLeave = true }
              .accessibilityIdentifier("exitMatch")
            Spacer()
            if model.automationAvailable {
              Button(model.driver ? "AUTO ON" : "AUTO OFF") {
                model.releaseAll()
                model.driver.toggle()
                model.log("driver", detail: model.driver ? "enabled" : "disabled")
              }
              .foregroundStyle(Color(Neon.gold))
              .accessibilityIdentifier("toggleDriver")
            }
          }
          .font(.system(size: 8, weight: .bold, design: .monospaced))
          .foregroundStyle(Color(Neon.muted))
          .padding(.horizontal, 20)
          .padding(.top, 22)
          Spacer()
        }
        .ignoresSafeArea()
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 19) {
            brand
            if model.phase == "results" { results } else { lobby }
          }
          .padding(.horizontal, 24)
          .padding(.top, 10)
          .padding(.bottom, 28)
          .frame(maxWidth: 540)
          .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
      }
    }
    .confirmationDialog("Leave this match?", isPresented: $confirmLeave, titleVisibility: .visible)
    {
      Button("Leave room", role: .destructive) { model.leave() }
      Button("Keep playing", role: .cancel) {}
    }
    .sheet(isPresented: $model.showHelp) { help }
  }

  private var brand: some View {
    VStack(alignment: .leading, spacing: 3) {
      HStack {
        Text("L / O     RHYTHM SYSTEM")
        Spacer()
        Text("VOL. 01").foregroundStyle(Color(Neon.pink))
      }
      .font(.system(size: 9, weight: .bold, design: .monospaced))
      .tracking(2)
      .foregroundStyle(Color(Neon.cyan))
      .padding(.bottom, 12)
      Text("LASER")
        .font(.system(size: 30, weight: .black, design: .rounded))
        .italic()
        .tracking(8)
      Text("OVERDRIVE")
        .font(.system(size: 38, weight: .black, design: .rounded))
        .italic()
        .tracking(1)
      HStack(spacing: 0) {
        Rectangle().fill(Color(Neon.cyan)).frame(height: 3)
        Rectangle().fill(Color(Neon.pink)).frame(width: 64, height: 3)
      }
      .padding(.top, 10)
    }
  }

  private var lobby: some View {
    Group {
      PhotonArtwork().frame(height: model.connected ? 125 : 152)
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 4) {
          Text("ION / AFTERBURN")
            .font(.system(size: 16, weight: .heavy, design: .monospaced))
          Text("44 SEC  /  4 BT + 2 FX + DUAL LASER")
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .foregroundStyle(Color(Neon.muted))
        }
        Spacer()
        Text("DUEL")
          .font(.system(size: 10, weight: .black, design: .monospaced))
          .foregroundStyle(Color(Neon.pink))
      }
      if model.connected {
        VStack(alignment: .leading, spacing: 14) {
          HStack {
            caption("ROOM CODE")
            Spacer()
            Text(model.roomCode)
              .font(.system(size: 24, weight: .black, design: .monospaced))
              .tracking(4)
              .foregroundStyle(Color(Neon.cyan))
              .textSelection(.enabled)
          }
          ForEach(model.peers) { peer in
            HStack(spacing: 12) {
              Rectangle()
                .fill(peer.id == model.id ? Color(Neon.cyan) : Color(Neon.pink))
                .frame(width: 3, height: 35)
              VStack(alignment: .leading, spacing: 4) {
                Text(peer.name.uppercased())
                  .font(.system(size: 16, weight: .bold, design: .monospaced))
                Text(
                  peer.id == model.id
                    ? "YOU / \(peer.id.prefix(8))" : "RIVAL / \(peer.id.prefix(8))"
                )
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color(Neon.muted))
              }
              Spacer()
              Text(peer.ready ? "READY" : peer.connected ? "STANDBY" : "OFFLINE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(peer.ready ? Color(Neon.cyan) : Color(Neon.gold))
            }
          }
          if model.peers.count < 2 {
            Text("WAITING FOR A SECOND PLAYER…")
              .font(.system(size: 10, design: .monospaced))
              .foregroundStyle(Color(Neon.muted))
          }
        }
        .padding(16)
        .background(CutPanel().fill(.white.opacity(0.025)))
        .overlay(CutPanel().stroke(Color(Neon.muted).opacity(0.4)))
        Button(model.me?.ready == true ? "CANCEL READY" : "READY / ARM SYSTEM") { model.ready() }
          .buttonStyle(ArcadeButton())
          .accessibilityIdentifier("readyButton")
        Button("LEAVE ROOM") { model.leave() }
          .buttonStyle(ArcadeButton(color: Color(Neon.muted), filled: false))
      } else {
        VStack(alignment: .leading, spacing: 11) {
          field("GUEST CALLSIGN", text: $model.guestName, placeholder: "PHOTON", id: "guestName")
          field(
            "SERVER ADDRESS", text: $model.serverAddress, placeholder: "ws://192.168.1.10:8769",
            id: "serverAddress", caps: .never)
          field(
            "ROOM CODE / JOIN ONLY", text: $model.roomCode, placeholder: "6-CHARACTER CODE",
            id: "roomCode")
        }
        HStack(spacing: 12) {
          Button("CREATE ROOM") { model.connect(create: true) }
            .buttonStyle(ArcadeButton())
            .accessibilityIdentifier("createRoom")
          Button("JOIN ROOM") { model.connect(create: false) }
            .buttonStyle(ArcadeButton(color: Color(Neon.pink), filled: false))
            .accessibilityIdentifier("joinRoom")
        }
      }
      Text(model.status)
        .font(.system(size: 9, weight: .medium, design: .monospaced))
        .foregroundStyle(model.connected ? Color(Neon.cyan) : Color(Neon.muted))
        .fixedSize(horizontal: false, vertical: true)
      if let audioError = model.audio.error {
        Text("AUDIO: \(audioError)").font(.caption).foregroundStyle(Color(Neon.gold))
      }
      HStack {
        Text("NO ACCOUNT. TWO PLAYERS. ONE FREQUENCY.")
          .font(.system(size: 7, design: .monospaced))
          .foregroundStyle(Color(Neon.muted))
        Spacer()
        Button("HOW TO PLAY") { model.showHelp = true }
          .font(.system(size: 9, weight: .bold, design: .monospaced))
          .foregroundStyle(Color(Neon.cyan))
      }
    }
  }

  private var results: some View {
    let score = model.me?.score ?? 0
    let theirs = model.opponent?.score ?? 0
    let rank =
      score >= 9_800_000
      ? "S"
      : score >= 9_000_000 ? "AAA" : score >= 8_000_000 ? "AA" : score >= 7_000_000 ? "A" : "B"
    return VStack(spacing: 18) {
      HStack {
        caption("TRANSMISSION COMPLETE")
        Spacer()
        Text("ROUND \(model.epoch)").font(.system(size: 9, design: .monospaced)).foregroundStyle(
          Color(Neon.muted))
      }
      HStack {
        VStack(alignment: .leading, spacing: 6) {
          Text(score == theirs ? "DRAW" : score > theirs ? "YOU WIN" : "RIVAL WINS")
            .font(.system(size: 25, weight: .black, design: .monospaced))
          Text(
            (model.me?.gauge ?? 0) >= 70 ? "TRACK COMPLETE / CLEAR" : "TRACK COMPLETE / RATE FAILED"
          )
          .font(.system(size: 8, weight: .bold, design: .monospaced))
          .foregroundStyle(Color(Neon.cyan))
        }
        Spacer()
        Text(rank)
          .font(.system(size: 46, weight: .black, design: .rounded))
          .italic()
          .foregroundStyle(Color(Neon.gold))
          .shadow(color: Color(Neon.pink).opacity(0.5), radius: 10)
      }
      PhotonArtwork().frame(height: 92)
      ForEach(model.peers) { peer in
        HStack(alignment: .firstTextBaseline) {
          Text(peer.name.uppercased()).font(.system(size: 12, weight: .bold, design: .monospaced))
          Spacer()
          Text(String(format: "%08d", peer.score))
            .font(.system(size: 23, weight: .bold, design: .monospaced))
            .foregroundStyle(peer.id == model.id ? Color(Neon.cyan) : Color(Neon.pink))
        }
      }
      VStack(spacing: 10) {
        stat(
          "MAX CHAIN", "\(model.me?.maxCombo ?? 0)", "EFFECTIVE RATE",
          "\(Int(model.me?.gauge ?? 0))%")
        stat(
          "CRITICAL", "\(model.me?.critical ?? 0)", "NEAR / ERROR",
          "\(model.me?.near ?? 0) / \(model.me?.errors ?? 0)")
        stat(
          "LASER / SLAM", "\(model.me?.laserHits ?? 0) / \(model.me?.slamHits ?? 0)", "HOLD / FX",
          "\(model.me?.holdHits ?? 0) / \(model.me?.fxHits ?? 0)")
      }
      .padding(15)
      .background(CutPanel().fill(.white.opacity(0.035)))
      Button(model.me?.ready == true ? "WAITING FOR RIVAL / CANCEL" : "REMATCH / READY") {
        model.ready()
      }
      .buttonStyle(ArcadeButton())
      .accessibilityIdentifier("rematchButton")
      Button("RETURN TO LOBBY") { model.leave() }
        .buttonStyle(ArcadeButton(color: Color(Neon.muted), filled: false))
      Text("SERVER-VERIFIED RESULT  /  ROOM \(model.roomCode)")
        .font(.system(size: 8, design: .monospaced))
        .foregroundStyle(Color(Neon.muted))
    }
  }

  private func caption(_ text: String) -> some View {
    Text(text).font(.system(size: 9, weight: .bold, design: .monospaced))
      .tracking(1).foregroundStyle(Color(Neon.cyan))
  }

  private func field(
    _ title: String, text: Binding<String>, placeholder: String, id: String,
    caps: TextInputAutocapitalization = .characters
  ) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      caption(title)
      TextField(placeholder, text: text)
        .font(.system(size: 14, weight: .medium, design: .monospaced))
        .textInputAutocapitalization(caps)
        .autocorrectionDisabled()
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.045))
        .overlay(Rectangle().stroke(Color(Neon.muted).opacity(0.35)))
        .accessibilityIdentifier(id)
    }
  }

  private func stat(_ left: String, _ value: String, _ right: String, _ other: String) -> some View
  {
    HStack {
      VStack(alignment: .leading, spacing: 3) {
        caption(left)
        Text(value).font(.system(size: 16, weight: .bold, design: .monospaced))
      }
      Spacer()
      VStack(alignment: .trailing, spacing: 3) {
        caption(right)
        Text(other).font(.system(size: 16, weight: .bold, design: .monospaced))
      }
    }
  }

  private var help: some View {
    VStack(alignment: .leading, spacing: 23) {
      Text("CONTROL THE FREQUENCY")
        .font(.system(size: 24, weight: .black, design: .monospaced))
      Text("BT / WHITE").foregroundStyle(Color(Neon.cyan)).bold()
      Text(
        "Tap A–D as white plates meet the gold critical line. Keep your finger down for long notes; releasing early breaks the chain."
      )
      Text("FX / ORANGE").foregroundStyle(Color(Neon.gold)).bold()
      Text(
        "Orange notes span two lanes. Tap or hold FX-L and FX-R. They also distort and filter the soundtrack."
      )
      Text("VOL / CYAN + MAGENTA").foregroundStyle(Color(Neon.pink)).bold()
      Text(
        "Drag the left or right knob pad horizontally. Match its triangle to the moving laser at the critical line. Keep touching during straight sections. Swipe quickly at a sharp laser angle to score a SLAM."
      )
      Text(
        "Build the gauge to 70% to clear. The higher server-judged score wins. Both players ready up for a synchronized 4-second countdown."
      )
      .foregroundStyle(Color(Neon.muted))
      Button("LET'S PLAY") { model.showHelp = false }.buttonStyle(ArcadeButton())
    }
    .font(.system(size: 14, design: .monospaced))
    .padding(26)
    .presentationDragIndicator(.visible)
  }
}
