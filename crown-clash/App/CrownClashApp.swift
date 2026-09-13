import SpriteKit
import SwiftUI

@main
struct CrownClashApp: App {
  @StateObject private var client = GameClient()

  var body: some Scene {
    WindowGroup {
      RootView(client: client)
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
  }
}

struct RootView: View {
  @ObservedObject var client: GameClient
  @State private var arena: ArenaScene?

  var body: some View {
    ZStack {
      if client.inArena {
        if let arena {
          SpriteView(scene: arena, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
        }
        if client.state?.phase == "result" {
          resultOverlay
        }
      } else {
        LobbyView(client: client)
      }
      if !client.connected && client.inArena {
        VStack(spacing: 12) {
          Text("CONNECTION PAUSED").font(.title2.bold().italic())
          Text(client.error).font(.caption)
          Button("RECONNECT SAME FIGHTER") { client.reconnect() }
            .buttonStyle(TournamentButton())
          Button("RETURN TO LOBBY") { client.leave() }.font(.caption)
        }
        .padding(30)
        .background(.black.opacity(0.9))
      }
    }
    .onAppear {
      arena = ArenaScene(client: client)
    }
    .onChange(of: client.inArena) { _, inArena in
      if inArena { arena = ArenaScene(client: client) }
    }
    .onChange(of: client.muted) { _, value in client.audio.muted = value }
    .onReceive(
      NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
    ) { _ in
      client.input = InputState()
    }
  }

  private var resultOverlay: some View {
    ZStack {
      Color.black.opacity(0.65).ignoresSafeArea()
      VStack(spacing: 9) {
        Text("CROWN CIRCUIT / TOURNAMENT RESULT")
          .font(.system(size: 12, weight: .bold, design: .monospaced))
          .tracking(4).foregroundStyle(.cyan)
        Text(winnerTitle)
          .font(.system(size: 46, weight: .black, design: .rounded).italic())
          .foregroundStyle(.white)
        Text(
          client.state?.winner == client.id
            ? "THE CROWN BELONGS TO YOUR TEAM" : "THE CIRCUIT AWAITS YOUR RETURN"
        )
        .font(.system(size: 12, weight: .bold)).tracking(3).foregroundStyle(.orange)
        HStack(spacing: 28) {
          ForEach(client.state?.peers ?? [], id: \.id) { peer in
            VStack(spacing: 5) {
              Text(peer.name.uppercased()).font(.headline)
              HStack(spacing: 3) {
                ForEach(Array(peer.roster.enumerated()), id: \.offset) { _, member in
                  Image(uiImage: UIImage(named: "\(member.fighter)-portrait.jpg")!)
                    .resizable().scaledToFill().frame(width: 53, height: 48).clipped()
                    .saturation(member.hp == 0 ? 0 : 1).opacity(member.hp == 0 ? 0.4 : 1)
                }
              }
              Text("\(peer.knockouts) KOs   /   \(peer.damage) DAMAGE")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.gray)
            }
          }
        }
        HStack(spacing: 16) {
          Button(client.localPeer?.rematch == true ? "WAITING FOR RIVAL…" : "REMATCH / RUN IT BACK")
          { client.rematch() }
          .buttonStyle(TournamentButton())
          .disabled(client.localPeer?.rematch == true)
          Button("LOBBY") { client.leave() }.font(.caption.bold()).foregroundStyle(.white)
        }
        Text(
          "ROOM \(client.roomCode)   •   MATCH \(client.state?.match ?? 1)   •   SHARED SERVER RESULT"
        )
        .font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundStyle(.gray)
      }
    }
  }

  private var winnerTitle: String {
    guard let state = client.state else { return "TEAM VICTORY" }
    if state.winner == "draw" { return "DOUBLE KNOCKOUT" }
    return "\(state.peers.first { $0.id == state.winner }?.name.uppercased() ?? "TEAM") WINS"
  }
}

struct TournamentButton: ButtonStyle {
  var secondary = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 12, weight: .black)).tracking(1)
      .foregroundStyle(secondary ? Color.white : Color.black)
      .padding(.horizontal, 18).padding(.vertical, 13)
      .background(secondary ? Color.white.opacity(0.1) : Color(red: 1, green: 0.72, blue: 0.2))
      .overlay(Rectangle().stroke(.white.opacity(0.22), lineWidth: 1))
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
  }
}

struct LobbyView: View {
  @ObservedObject var client: GameClient
  @State private var showGuide = false

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Image(uiImage: UIImage(named: "festival.png")!).resizable().scaledToFill()
          .frame(width: geometry.size.width, height: geometry.size.height).clipped()
        LinearGradient(
          colors: [.black.opacity(0.65), Color(red: 0.025, green: 0.05, blue: 0.1).opacity(0.83)],
          startPoint: .topLeading, endPoint: .bottomTrailing)
        VStack(alignment: .leading, spacing: 9) {
          header
          HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
              Text("01 / SELECT YOUR THREE")
                .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2)
                .foregroundStyle(.cyan)
              rosterGrid(width: geometry.size.width * 0.44)
              HStack {
                Text("ORDER").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray)
                ForEach(Array(client.roster.enumerated()), id: \.offset) { index, id in
                  Text("\(index + 1) \(id.uppercased())")
                    .font(.system(size: 9, weight: .black)).foregroundStyle(.white)
                }
                Spacer(minLength: 0)
                Button("ROTATE") { client.rotateOrder() }
                  .font(.system(size: 9, weight: .black)).foregroundStyle(.orange)
                  .disabled(client.localPeer?.ready == true)
              }
            }
            .frame(width: geometry.size.width * 0.44)
            networkPanel
          }
          HStack {
            Text(
              client.automationLabel.isEmpty
                ? "3 FIGHTERS. ONE CROWN. NO SECOND CHANCES." : client.automationLabel
            )
            .font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.gray)
            Spacer()
            Button("HOW TO PLAY") { showGuide = true }
              .font(.system(size: 10, weight: .black)).foregroundStyle(.cyan)
            Button(client.muted ? "SOUND OFF" : "SOUND ON") { client.muted.toggle() }
              .font(.system(size: 10, weight: .black)).foregroundStyle(.gray)
          }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
      }
    }
    .sheet(isPresented: $showGuide) { guide }
  }

  private var header: some View {
    HStack(alignment: .lastTextBaseline) {
      Text("CROWN / CLASH")
        .font(.system(size: 32, weight: .black, design: .rounded).italic())
        .tracking(-1).foregroundStyle(.white)
      Text("NIGHTFALL CIRCUIT")
        .font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(3).foregroundStyle(
          .orange)
      Spacer()
      Text("3 × 3").font(.system(size: 23, weight: .black).italic()).foregroundStyle(.cyan)
    }
    .padding(.bottom, 2)
    .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.2)).frame(height: 1) }
  }

  private func rosterGrid(width: CGFloat) -> some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
      ForEach(Fighter.all) { fighter in
        Button {
          client.select(fighter.id)
        } label: {
          ZStack(alignment: .bottomLeading) {
            Image(uiImage: UIImage(named: "\(fighter.id)-portrait.jpg")!).resizable().scaledToFill()
              .frame(width: (width - 12) / 3, height: 89).clipped()
            LinearGradient(
              colors: [.clear, .black.opacity(0.9)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 1) {
              Text(fighter.title).font(.system(size: 13, weight: .black).italic())
              Text(fighter.style).font(.system(size: 6, weight: .bold)).tracking(1)
            }.padding(6)
            if let index = client.roster.firstIndex(of: fighter.id) {
              Text("0\(index + 1)")
                .font(.system(size: 14, weight: .black).italic())
                .padding(4).background(.orange).foregroundStyle(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
          }
          .frame(height: 89)
          .overlay(
            Rectangle().stroke(
              client.roster.contains(fighter.id) ? .orange : .white.opacity(0.22), lineWidth: 2)
          )
          .saturation(client.roster.contains(fighter.id) ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(fighter.title)")
        .disabled(client.localPeer?.ready == true)
      }
    }
  }

  private var networkPanel: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(client.connected ? "02 / ROOM \(client.roomCode)" : "02 / ENTER THE CIRCUIT")
        .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2).foregroundStyle(
          .cyan)
      if client.connected {
        ForEach(client.state?.peers ?? [], id: \.id) { peer in
          HStack {
            Circle().fill(peer.connected ? .green : .red).frame(width: 6, height: 6)
            Text(peer.name.uppercased()).font(.system(size: 12, weight: .black))
            Spacer()
            Text(peer.ready ? "READY" : "SELECTING").font(.system(size: 9, weight: .bold))
              .foregroundStyle(peer.ready ? .green : .orange)
          }.padding(10).background(.white.opacity(0.05))
        }
        if client.state?.peers.count == 1 {
          Text("Share the room code. Waiting for a second guest…")
            .font(.system(size: 11)).foregroundStyle(.gray).padding(.vertical, 6)
        }
        Button(client.localPeer?.ready == true ? "TEAM LOCKED / WAITING" : "LOCK TEAM & READY") {
          client.ready()
        }
        .buttonStyle(TournamentButton())
        .disabled(client.roster.count != 3 || client.localPeer?.ready == true)
        Button("LEAVE ROOM") { client.leave() }.font(.system(size: 9, weight: .bold))
          .foregroundStyle(.gray)
      } else {
        HStack {
          field("GUEST", text: $client.guestName)
          field("ROOM CODE", text: $client.roomCode)
        }
        field("SERVER ADDRESS / LAN HOST", text: $client.serverAddress)
        HStack(spacing: 7) {
          Button(client.connecting ? "CONNECTING…" : "HOST ROOM") { client.connect(create: true) }
            .buttonStyle(TournamentButton()).disabled(client.connecting)
          Button("JOIN ROOM") { client.connect(create: false) }
            .buttonStyle(TournamentButton(secondary: true)).disabled(client.connecting)
        }
        Text("Two guests • Real WebSockets • No account required")
          .font(.system(size: 9)).foregroundStyle(.gray)
      }
      if !client.error.isEmpty {
        Text(client.error).font(.system(size: 10, weight: .medium)).foregroundStyle(.red)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func field(_ label: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(label).font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(.gray)
      TextField(label, text: text)
        .font(.system(size: 12, design: .monospaced))
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .padding(9).background(.white.opacity(0.07))
        .overlay(Rectangle().stroke(.white.opacity(0.15), lineWidth: 1))
        .accessibilityLabel(label)
    }
  }

  private var guide: some View {
    VStack(alignment: .leading, spacing: 13) {
      Text("FIGHT FOR THE CROWN").font(.title.bold().italic())
      Text(
        "Pick three fighters in the order you want them to enter. Win by knocking out every fighter on the opposing team. Your power carries across the team."
      )
      Text(
        "MOVE: hold ◀ / ▶. Double tap a direction to run. HOP is short and fast; JUMP is high. Hold LOW to crouch. Hold GUARD to block; LOW + GUARD blocks low attacks, but airborne attacks break low guard."
      )
      Text(
        "A / B: light punch / kick. C / D: heavy punch / kick. SP: character special (wave, rush or uppercut). A hit normal can cancel into SP. SUPER costs two power stocks; SP can cancel into SUPER on hit. ROLL evades attacks; guard cancel roll costs one stock."
      )
      Text(
        "Guard pressure depletes the blue guard gauge. A broken guard leaves you vulnerable. At 60 seconds, the lower-health active fighter loses. Surviving fighters regain 12 health between bouts."
      )
      Button("GOT IT") { showGuide = false }.buttonStyle(TournamentButton())
    }.font(.system(size: 13)).padding(24)
  }
}
