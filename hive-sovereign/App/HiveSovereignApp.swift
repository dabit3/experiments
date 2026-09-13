import SpriteKit
import SwiftUI

@main
struct HiveSovereignApp: App {
  @StateObject private var game = GameConnection()
  var body: some Scene {
    WindowGroup {
      ContentView(game: game)
        .preferredColorScheme(.dark)
        .onOpenURL { game.handleURL($0) }
    }
  }
}

struct ContentView: View {
  @ObservedObject var game: GameConnection
  @Environment(\.scenePhase) private var scenePhase
  @State private var showHelp = false
  private let gold = Color(uiColor: PixelArt.gold)
  private let ink = Color(uiColor: PixelArt.ink)

  var body: some View {
    ZStack {
      ink.ignoresSafeArea()
      SpriteView(scene: game.scene).ignoresSafeArea()
        .accessibilityLabel("Shared Hive arena")
      if game.state == nil {
        lobby
      } else if game.state?.phase == "lobby" {
        waiting
      } else {
        playOverlay
      }
      if showHelp { help }
    }
    .font(.system(.body, design: .monospaced))
    .onChange(of: scenePhase) { _, phase in
      if phase != .active { game.input = GameInput() }
    }
  }

  private var lobby: some View {
    ZStack {
      ink.opacity(0.92).ignoresSafeArea()
      HStack(spacing: 32) {
        VStack(alignment: .leading, spacing: 10) {
          Text("A FIVE-ON-FIVE HIVE WAR")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .tracking(3).foregroundStyle(gold)
          Text("HIVE\nSOVEREIGN")
            .font(.system(size: 39, weight: .black, design: .monospaced))
            .tracking(-2).lineSpacing(-6)
            .foregroundStyle(.white)
          Rectangle().fill(gold).frame(width: 42, height: 3)
          Text("Two captains. Three ways to win.")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.7))
          HStack(spacing: 16) {
            objective("crown.fill", "MILITARY", "3 queen defeats")
            objective("leaf.fill", "ECONOMY", "12 hive berries")
            objective("tortoise.fill", "SNAIL", "Ride to your net")
          }.padding(.top, 8)
          Button("FIELD MANUAL  ↗") { showHelp = true }
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(gold).padding(.top, 4)
            .accessibilityIdentifier("help")
        }
        .frame(maxWidth: 380, alignment: .leading)
        VStack(alignment: .leading, spacing: 10) {
          HStack {
            Text("ENTER THE HIVE").font(.system(size: 15, weight: .bold))
            Spacer()
            Circle().fill(game.connection == "CONNECTING" ? gold : .green).frame(
              width: 5, height: 5)
            Text("LAN").font(.system(size: 9)).foregroundStyle(.secondary)
          }
          inputField("GUEST NAME", placeholder: "Captain", text: $game.name, id: "guestName")
          inputField(
            "HOST ADDRESS", placeholder: "ws://192.168.1.10:8789", text: $game.address,
            id: "serverAddress")
          Button {
            game.connect(create: true)
          } label: {
            Text(game.connection == "CONNECTING" ? "CONNECTING…" : "CREATE ROOM  →").frame(
              maxWidth: .infinity)
          }
          .buttonStyle(HiveButtonStyle(color: gold))
          .disabled(game.connection == "CONNECTING")
          HStack(spacing: 8) {
            TextField("ROOM CODE", text: $game.roomCode)
              .textInputAutocapitalization(.characters).autocorrectionDisabled()
              .font(.system(size: 12, weight: .bold, design: .monospaced))
              .padding(10).background(.white.opacity(0.07))
              .accessibilityIdentifier("roomCode")
            Button("JOIN") { game.connect() }
              .buttonStyle(HiveButtonStyle(color: Color(uiColor: PixelArt.blue)))
              .accessibilityIdentifier("joinRoom")
          }
          if !game.error.isEmpty {
            Text(game.error).font(.system(size: 10)).foregroundStyle(.red).fixedSize(
              horizontal: false, vertical: true)
          } else {
            Text("Guest rooms • Real-time WebSockets\nOne human + four marked AI per faction")
              .font(.system(size: 9)).foregroundStyle(.secondary).lineSpacing(3)
          }
        }
        .padding(20)
        .frame(width: 305)
        .background(Color.white.opacity(0.035))
        .overlay(Rectangle().stroke(gold.opacity(0.25), lineWidth: 1))
      }
      .padding(.horizontal, 20)
    }
  }

  private func objective(_ image: String, _ title: String, _ subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Image(systemName: image).font(.system(size: 18)).foregroundStyle(gold)
      Text(title).font(.system(size: 9, weight: .bold, design: .monospaced))
      Text(subtitle).font(.system(size: 8)).foregroundStyle(.secondary)
    }
  }

  private func inputField(_ label: String, placeholder: String, text: Binding<String>, id: String)
    -> some View
  {
    VStack(alignment: .leading, spacing: 4) {
      Text(label).font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(1)
        .foregroundStyle(.secondary)
      TextField(placeholder, text: text)
        .font(.system(size: 12, design: .monospaced))
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .padding(9).background(.white.opacity(0.07))
        .accessibilityIdentifier(id)
    }
  }

  private var waiting: some View {
    ZStack {
      ink.opacity(0.78).ignoresSafeArea()
      VStack(spacing: 14) {
        Text("CAPTAINS ASSEMBLE").font(.system(size: 12, weight: .bold)).tracking(3)
          .foregroundStyle(gold)
        HStack(spacing: 18) {
          Text("ROOM").font(.system(size: 12)).foregroundStyle(.secondary)
          Text(game.roomCode).font(.system(size: 34, weight: .black, design: .monospaced)).tracking(
            7
          )
          .accessibilityIdentifier("displayedRoomCode")
        }
        HStack(spacing: 40) {
          peerCard(team: 0)
          Text("VS").font(.system(size: 15, weight: .black)).foregroundStyle(.secondary)
          peerCard(team: 1)
        }
        Text("Captain any of your five units. Unselected teammates are AI.")
          .font(.system(size: 10)).foregroundStyle(.secondary)
        HStack(spacing: 12) {
          Button("LEAVE") { game.disconnect() }.buttonStyle(HiveButtonStyle(color: .gray))
          Button(game.me?.ready == true ? "READY — WAITING" : "READY TO FLY") { game.ready() }
            .buttonStyle(HiveButtonStyle(color: gold)).accessibilityIdentifier("ready")
        }
        if game.autoPilot {
          Text("AUTOMATED CAPTAIN ENABLED • NORMAL INPUT PATH").font(.system(size: 9))
            .foregroundStyle(.orange)
        }
      }
      .padding(24).background(ink)
      .overlay(Rectangle().stroke(gold.opacity(0.6), lineWidth: 1))
    }
  }

  private func peerCard(team: Int) -> some View {
    let peer = game.state?.peers?.first { $0.team == team }
    return VStack(spacing: 6) {
      Text(team == 0 ? "AZURE" : "AMBER").font(.system(size: 11, weight: .bold)).tracking(3)
        .foregroundStyle(Color(uiColor: PixelArt.team(team)))
      Text(peer?.name ?? "Awaiting captain…").font(.system(size: 18, weight: .bold))
      Text(peer == nil ? "SHARE ROOM CODE" : (peer?.ready == true ? "READY" : "CONNECTED"))
        .font(.system(size: 9)).foregroundStyle(.secondary)
    }.frame(width: 180)
  }

  private var playOverlay: some View {
    ZStack {
      VStack {
        HStack {
          Button {
            game.disconnect()
          } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
          }
          .accessibilityLabel("Leave room")
          Button {
            game.toggleAudio()
          } label: {
            Image(systemName: game.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
          }
          .accessibilityLabel("Toggle sound")
          Spacer()
          Button {
            showHelp = true
          } label: {
            Image(systemName: "questionmark.circle")
          }
          .accessibilityLabel("Field manual")
        }
        .font(.system(size: 13)).foregroundStyle(.white)
        .padding(.horizontal, 6).padding(.top, 5)
        Spacer()
        controls
      }
      if game.state?.phase == "countdown" {
        VStack(spacing: 3) {
          Text("\(game.state?.countdown ?? 3)").font(
            .system(size: 65, weight: .black, design: .monospaced))
          Text("THREE WAYS TO WIN").font(.system(size: 13, weight: .bold)).tracking(2)
        }
        .foregroundStyle(gold).padding(25).background(ink.opacity(0.92))
      }
      if game.state?.paused == true || game.connection == "RECONNECTING" {
        VStack(spacing: 8) {
          Text("MATCH PAUSED").font(.system(size: 24, weight: .black))
          Text("Waiting for the other captain to reconnect.").font(.system(size: 11))
          Button("RECONNECT NOW") { game.connect(resume: true) }
            .buttonStyle(HiveButtonStyle(color: gold))
        }.padding(24).background(ink).foregroundStyle(.white)
      }
      if game.state?.phase == "result", let match = game.state?.game {
        result(match)
      }
    }
  }

  private var controls: some View {
    HStack(alignment: .bottom, spacing: 12) {
      HStack(spacing: 8) {
        HoldControl(title: "◀", caption: "LEFT", accessibility: "Move left") { held in
          game.autoPilot = false
          game.input.move = held ? -1 : 0
        }
        HoldControl(title: "▶", caption: "RIGHT", accessibility: "Move right") { held in
          game.autoPilot = false
          game.input.move = held ? 1 : 0
        }
      }
      Spacer(minLength: 6)
      VStack(spacing: 5) {
        if game.autoPilot {
          Text("AUTOMATED CAPTAIN").font(.system(size: 8, weight: .heavy))
            .foregroundStyle(.orange)
        }
        HStack(spacing: 4) {
          ForEach(["economy", "snail", "military"], id: \.self) { order in
            Button(order.uppercased()) { game.order(order) }
              .font(.system(size: 8, weight: .bold, design: .monospaced))
              .padding(.horizontal, 7).padding(.vertical, 6)
              .background(game.state?.game?.orders[game.team] == order ? gold : ink)
              .foregroundStyle(game.state?.game?.orders[game.team] == order ? ink : .white)
              .overlay(Rectangle().stroke(gold.opacity(0.3), lineWidth: 1))
              .accessibilityLabel("\(order) team order")
          }
        }
        HStack(spacing: 4) {
          Text("PILOT").font(.system(size: 8, weight: .bold)).foregroundStyle(.white.opacity(0.7))
          ForEach(0..<5) { slot in
            Button(slot == 0 ? "Q" : "\(slot)") {
              game.autoPilot = false
              game.select(slot: slot)
            }
            .font(.system(size: 10, weight: .bold)).frame(width: 26, height: 24)
            .background(game.me?.slot == slot ? Color(uiColor: PixelArt.team(game.team)) : ink)
            .foregroundStyle(game.me?.slot == slot ? ink : .white)
            .accessibilityLabel(slot == 0 ? "Pilot queen" : "Pilot worker \(slot)")
          }
        }
      }
      .padding(7).background(ink.opacity(0.88))
      Spacer(minLength: 6)
      HStack(spacing: 8) {
        HoldControl(
          title: game.controlled?.role == "queen" ? "↓" : "◆",
          caption: game.controlled?.role == "queen" ? "DIVE" : "USE",
          accessibility: "Use gate or ride snail or dive"
        ) { held in
          game.autoPilot = false
          game.input.action = held
          game.input.dive = held
        }
        HoldControl(title: "↑", caption: "JUMP", accessibility: "Jump or flap") { held in
          game.autoPilot = false
          game.input.jump = held
        }
      }
    }
    .padding(.bottom, 5).padding(.horizontal, 4)
  }

  private func result(_ match: GameState) -> some View {
    VStack(spacing: 8) {
      Text(match.winner == game.team ? "YOUR HIVE REIGNS" : "THE RIVAL HIVE REIGNS")
        .font(.system(size: 10, weight: .bold)).tracking(3)
      Text("\(match.winner == 0 ? "AZURE" : "AMBER") VICTORY")
        .font(.system(size: 29, weight: .black, design: .monospaced)).foregroundStyle(
          Color(uiColor: PixelArt.team(match.winner)))
      Text("\(match.victory) • \(Int(match.time)) SECONDS")
        .font(.system(size: 12, weight: .bold)).tracking(2)
      HStack(spacing: 25) {
        Text("BERRIES  \(match.score[0]) : \(match.score[1])")
        Text("QUEEN EGGS  \(match.lives[0]) : \(match.lives[1])")
      }.font(.system(size: 10)).foregroundStyle(.secondary)
      HStack(spacing: 12) {
        Button("LEAVE") { game.disconnect() }.buttonStyle(HiveButtonStyle(color: .gray))
        Button(game.me?.ready == true ? "REMATCH READY" : "REMATCH  →") { game.ready() }
          .buttonStyle(HiveButtonStyle(color: gold)).accessibilityIdentifier("rematch")
      }.padding(.top, 7)
    }
    .padding(24).frame(minWidth: 420)
    .background(ink.opacity(0.97))
    .overlay(Rectangle().stroke(Color(uiColor: PixelArt.team(match.winner)), lineWidth: 2))
    .accessibilityIdentifier("matchResult")
  }

  private var help: some View {
    ZStack {
      ink.opacity(0.95).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 11) {
        HStack {
          Text("FIELD MANUAL").font(.system(size: 22, weight: .black)).foregroundStyle(gold)
          Spacer()
          Button("CLOSE  ×") { showHelp = false }.foregroundStyle(gold)
        }
        Text(
          "You captain one insect at a time. PILOT Q / 1–4 swaps control.\nAll other insects on your team have visible AI labels."
        )
        .font(.system(size: 12)).lineSpacing(4)
        HStack(alignment: .top, spacing: 25) {
          manualColumn(
            "WORKER",
            "Run ◀ ▶ and JUMP between platforms. Touch a magenta berry to carry it. Jump into your hive's white-outlined hole above center to deposit. Fill 12 holes to win."
          )
          manualColumn(
            "WARRIOR / QUEEN",
            "Hold USE at a white or friendly wing gate with a berry for 1 second. Warriors flap with JUMP. Higher swords win jousts. Queens claim gates and DIVE. Three queen defeats lose."
          )
          manualColumn(
            "SNAIL / ORDERS",
            "Workers hold USE next to the snail to ride toward their colored net. Release or jump to dismount. Speed gates cost one berry. Team orders guide your four AI allies."
          )
        }
        Text(
          "All three objectives run at once. Protect your queen, interrupt enemy carriers,\nand contest the snail. Progress and results are shared over the local host."
        )
        .font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(4)
      }
      .padding(25).frame(maxWidth: 780)
    }
  }

  private func manualColumn(_ title: String, _ text: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.system(size: 11, weight: .bold)).foregroundStyle(gold)
      Text(text).font(.system(size: 11)).foregroundStyle(.white.opacity(0.85)).lineSpacing(4)
    }.frame(maxWidth: .infinity, alignment: .topLeading)
  }
}

struct HiveButtonStyle: ButtonStyle {
  var color: Color
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 11, weight: .heavy, design: .monospaced))
      .padding(.horizontal, 15).padding(.vertical, 12)
      .foregroundStyle(Color(uiColor: PixelArt.ink))
      .background(color.opacity(configuration.isPressed ? 0.6 : 1))
  }
}

struct HoldControl: View {
  let title: String
  let caption: String
  let accessibility: String
  let change: (Bool) -> Void
  @State private var held = false
  var body: some View {
    VStack(spacing: 0) {
      Text(title).font(.system(size: 24, weight: .heavy))
      Text(caption).font(.system(size: 8, weight: .bold, design: .monospaced))
    }
    .frame(width: 54, height: 52)
    .foregroundStyle(held ? Color(uiColor: PixelArt.ink) : Color(uiColor: PixelArt.gold))
    .background(held ? Color(uiColor: PixelArt.gold) : Color(uiColor: PixelArt.ink).opacity(0.9))
    .overlay(
      RoundedRectangle(cornerRadius: 6).stroke(
        Color(uiColor: PixelArt.gold).opacity(0.55), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          if !held {
            held = true
            change(true)
          }
        }
        .onEnded { _ in
          held = false
          change(false)
        }
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibility)
    .accessibilityAddTraits(.isButton)
    .accessibilityAction {
      change(true)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { change(false) }
    }
    .onDisappear {
      if held {
        change(false)
        held = false
      }
    }
  }
}
