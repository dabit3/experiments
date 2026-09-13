import SpriteKit
import SwiftUI

@main
struct HollowAfterdarkApp: App {
  var body: some Scene {
    WindowGroup {
      DuelView()
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }
  }
}

struct DuelView: View {
  @StateObject private var connection = DuelConnection()
  @State private var scene = DuelScene(size: CGSize(width: 1200, height: 560))
  @State private var name = ""
  @State private var room = ""
  @State private var server = ""
  @State private var help = false
  @Environment(\.scenePhase) private var scenePhase
  private let ink = Color(red: 0.055, green: 0.045, blue: 0.10)
  private let crimson = Color(red: 1, green: 0.22, blue: 0.36)

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color.black.ignoresSafeArea()
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
          .ignoresSafeArea()
        if !connection.inRoom || connection.state?.phase == "lobby" {
          lobby(geometry: geometry)
        }
        if connection.state?.phase == "result" {
          result
        }
        if connection.inRoom && connection.state?.phase != "lobby" {
          VStack {
            Spacer()
            HStack {
              Spacer()
              Button("ROOM") { connection.leave() }
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .padding(7)
                .background(ink.opacity(0.8))
                .accessibilityIdentifier("leaveRoom")
              Spacer()
            }
          }
        }
        if !connection.connected && connection.inRoom {
          VStack {
            Text(connection.status).font(.caption.monospaced())
            Button("RECONNECT") { connection.reconnect() }.buttonStyle(NightButton())
          }
          .padding(20).background(ink.opacity(0.95))
        }
      }
      .sheet(isPresented: $help) { guide }
      .onAppear {
        scene.connection = connection
        name = connection.guest
        room = connection.room
        server = connection.server
      }
      .onChange(of: scenePhase) { _, phase in
        if phase != .active { connection.clearInput() }
      }
    }
  }

  private func lobby(geometry: GeometryProxy) -> some View {
    HStack(spacing: 25) {
      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: 7) {
          Rectangle().fill(crimson).frame(width: 22, height: 3)
          Text("THE CITY SLEEPS. THE HOLLOW WAKES.")
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .tracking(1)
        }
        Text("HOLLOW")
          .font(.system(size: 45, weight: .black, design: .rounded))
          .tracking(-2)
        Text("AFTERDARK")
          .font(.system(size: 27, weight: .light))
          .tracking(7)
        Rectangle().fill(crimson).frame(width: 95, height: 2).padding(.vertical, 9)
        Text("A DUEL BETWEEN MIDNIGHT AND DAWN")
          .font(.system(size: 8, weight: .medium, design: .monospaced))
          .foregroundStyle(.white.opacity(0.7))
        Spacer(minLength: 18)
        Text("REN  /  RIFTBLADE     ×     AYA  /  MOONWIRE")
          .font(.system(size: 9, weight: .semibold, design: .monospaced))
        Text("Two guests. One city. Control the Undertow.")
          .font(.system(size: 10))
          .foregroundStyle(.white.opacity(0.75))
        HStack {
          Button("HOW TO DUEL") { help = true }
          Button(connection.muted ? "AUDIO OFF" : "AUDIO ON") { connection.toggleAudio() }
        }
        .font(.system(size: 8, weight: .semibold, design: .monospaced))
        .buttonStyle(.bordered)
        .tint(.white)
        Text("NATIVE DUEL  /  ORIGINAL CHARACTERS  /  REAL NETWORK")
          .font(.system(size: 6, design: .monospaced))
          .foregroundStyle(.white.opacity(0.5))
      }
      .padding(.vertical, 10)
      .frame(maxWidth: .infinity, alignment: .leading)
      VStack(alignment: .leading, spacing: 9) {
        HStack {
          Text("NIGHT SIGNAL")
            .font(.system(size: 17, weight: .semibold))
            .tracking(2)
          Spacer()
          Circle().fill(connection.connected ? Color.green : crimson).frame(width: 5, height: 5)
        }
        Text(connection.status)
          .font(.system(size: 8, design: .monospaced))
          .foregroundStyle(.white.opacity(0.65))
          .lineLimit(2)
        if !connection.inRoom {
          field("GUEST NAME", value: $name, identifier: "guestName")
          HStack(spacing: 10) {
            field("ROOM CODE", value: $room, identifier: "roomCode")
            VStack(alignment: .leading, spacing: 5) {
              Text("CAPACITY").font(.system(size: 7, design: .monospaced))
              Text("02  DUELISTS").font(.system(size: 10, design: .monospaced)).frame(height: 27)
            }
          }
          field("SERVER / EDIT FOR LAN PLAY", value: $server, identifier: "serverAddress")
          Button {
            connection.guest = name
            connection.room = room
            connection.server = server
            connection.join()
          } label: {
            HStack {
              Text("ENTER THE HOLLOW")
              Spacer()
              Text("↗")
            }
          }
          .buttonStyle(NightButton()).accessibilityIdentifier("joinRoom")
          Text(
            "Enter the same code on the other iPhone.\nThe first guest opens the room. No account required."
          )
          .font(.system(size: 8))
          .foregroundStyle(.white.opacity(0.5))
        } else {
          Text(connection.room.uppercased())
            .font(.system(size: 35, weight: .light, design: .monospaced)).tracking(7)
          ForEach(connection.state?.players ?? []) { player in
            HStack {
              Text(player.slot == 0 ? "01 / REN" : "02 / AYA").foregroundStyle(
                player.slot == 0 ? crimson : .cyan)
              Text(player.name).lineLimit(1)
              Spacer()
              Text(player.ready ? "READY" : "WAIT")
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .padding(.vertical, 6)
          }
          if connection.state?.players.count != 2 {
            Text("Waiting for a second real device…")
              .font(.system(size: 10)).foregroundStyle(.white.opacity(0.6))
          }
          Button(connection.local?.ready == true ? "READY / WAITING FOR PEER" : "READY TO DUEL") {
            connection.ready()
          }
          .buttonStyle(NightButton())
          .disabled(connection.local?.ready == true)
          .accessibilityIdentifier("readyButton")
          Button("LEAVE ROOM") { connection.leave() }
            .font(.system(size: 8, design: .monospaced))
          Text(
            connection.automation
              ? "AUTOMATED INPUT DRIVER / \(connection.driverRole.uppercased())"
              : "TOUCH INPUT / HUMAN PLAYER"
          )
          .font(.system(size: 7, design: .monospaced)).foregroundStyle(.white.opacity(0.5))
        }
      }
      .padding(18)
      .frame(width: min(300, geometry.size.width * 0.39))
      .background(ink.opacity(0.94))
      .overlay(alignment: .top) { Rectangle().fill(crimson).frame(height: 2) }
    }
    .padding(.horizontal, max(35, geometry.safeAreaInsets.leading + 15))
    .padding(.vertical, 16)
    .background(
      LinearGradient(
        colors: [ink.opacity(0.55), .clear], startPoint: .leading, endPoint: .trailing))
  }

  private func field(_ title: String, value: Binding<String>, identifier: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.system(size: 7, weight: .medium, design: .monospaced)).foregroundStyle(
        .white.opacity(0.55))
      TextField("", text: value)
        .font(.system(size: 11, design: .monospaced))
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding(.horizontal, 9)
        .frame(height: 29)
        .background(.white.opacity(0.06))
        .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.2)).frame(height: 1) }
        .accessibilityLabel(title)
        .accessibilityIdentifier(identifier)
    }
  }

  private var result: some View {
    VStack(spacing: 9) {
      Text("THE NIGHT HAS AN ANSWER")
        .font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(3)
        .foregroundStyle(crimson)
      Text(connection.state?.message ?? "")
        .font(.system(size: 29, weight: .black)).italic()
      HStack(spacing: 25) {
        ForEach(connection.state?.players ?? []) { player in
          VStack(spacing: 4) {
            Text(player.name.uppercased()).font(.system(size: 12, weight: .bold))
            Text("\(player.wins)").font(.system(size: 38, weight: .light))
            Text("\(player.stats.hits) HITS  /  \(player.stats.shields) SHIELDS")
              .font(.system(size: 7, design: .monospaced))
          }
        }
      }
      HStack {
        Button(connection.local?.ready == true ? "WAITING FOR PEER" : "REMATCH") {
          connection.ready()
        }
        .buttonStyle(NightButton()).disabled(connection.local?.ready == true)
        .accessibilityIdentifier("rematchButton")
        Button("LEAVE") { connection.leave() }
          .buttonStyle(NightButton())
      }
      Text(
        connection.automation && connection.state?.matchNumber == 1
          ? "AUTOMATED DRIVER / REMATCH AFTER 7 SECONDS" : "BOTH DUELISTS MUST ACCEPT THE REMATCH"
      )
      .font(.system(size: 7, design: .monospaced))
    }
    .padding(25).frame(width: 370)
    .background(ink.opacity(0.96))
    .overlay(alignment: .top) { Rectangle().fill(crimson).frame(height: 3) }
  }

  private var guide: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 17) {
          Text("CONTROL THE UNDERTOW").font(.title2.bold())
          Text(
            "Move with ‹ / › and jump with ↑. Hold G to guard. Hold D to shield: it stops chip damage and steals advantage, but consumes EXS and loses to throws."
          )
          Text(
            "A is a fast close strike. B has longer reach. Cancel a connected A into B, then into C. C spends 25 EXS on a moving rift projectile. EX spends 100 for a powerful close-range weapon burst."
          )
          Text(
            "T throws nearby grounded opponents and breaks a shield. Tap T immediately when thrown to break free. Jump to evade throws and approach from above."
          )
          Text(
            "The twelve opposing diamonds show advantage. Advance, strike and defend to fill your side. Retreat and damage drain it. Every 12 seconds the leader receives ASCEND: +10% damage. Tap S while Ascended to SHIFT: cancel recovery, convert advantage into EXS and extend a chain."
          )
          Text(
            "First to two round wins takes the match. A round lasts 75 seconds; the healthier duelist wins at timeout. Both players must accept a rematch."
          )
          Text("NETWORK").font(.headline)
          Text(
            "Run the included local server. Use the same server address and room code on two devices. On simulators on this Mac use ws://127.0.0.1:8787. On physical devices use your Mac's LAN address. Guest identities are retained for reconnect. A disconnected duel pauses for 60 seconds before forfeit."
          )
          Text("AUTOMATION").font(.headline)
          Text(
            "The ▷ AUTO control toggles the visible input driver. It sends ordinary network inputs for the local player only; it never supplies a remote opponent. Tap it again for touch control. The ♪ control mutes music and effects."
          )
        }
        .font(.body).padding(24)
      }
      .background(ink)
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("DONE") { help = false } } }
    }
  }
}

struct NightButton: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 10, weight: .bold, design: .monospaced))
      .foregroundStyle(.white)
      .padding(.horizontal, 13)
      .padding(.vertical, 12)
      .background(
        Color(red: 0.69, green: 0.10, blue: 0.24).opacity(configuration.isPressed ? 0.6 : 1))
  }
}
