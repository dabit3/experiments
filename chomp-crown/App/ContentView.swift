import SpriteKit
import SwiftUI

struct Chomper: Shape {
  var opening: Double = 0.7
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    path.move(to: center)
    path.addArc(
      center: center, radius: min(rect.width, rect.height) / 2,
      startAngle: .radians(opening), endAngle: .radians(2 * .pi - opening), clockwise: false)
    path.closeSubpath()
    return path
  }
}

struct ContentView: View {
  @ObservedObject var client: GameClient
  @State private var help = false
  @State private var scene = ArenaScene(size: CGSize(width: 420, height: 464))
  private var game: ArenaState? { client.state }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Palette.ink.ignoresSafeArea()
        LinearGradient(
          colors: [Color.blue.opacity(0.1), .clear, Color.purple.opacity(0.08)],
          startPoint: .topLeading, endPoint: .bottomTrailing
        ).ignoresSafeArea()
        if let game {
          VStack(spacing: 0) {
            topBar
            if game.phase == "lobby" { roomLobby(game) } else { arena(game, geometry: geometry) }
          }
        } else {
          welcome
        }
      }
      .sheet(isPresented: $help) { instructions }
      .onChange(of: client.state?.tick) { _, _ in
        if let state = client.state { scene.present(state) }
      }
    }
  }
  private var topBar: some View {
    HStack {
      HStack(spacing: 5) {
        Image(systemName: "crown.fill").foregroundStyle(Palette.gold)
        Text("CHOMP CROWN").font(.system(size: 15, weight: .black, design: .rounded))
      }
      Spacer()
      Text(client.room).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(
        Palette.cyan)
      Button {
        client.toggleSound()
      } label: {
        Image(systemName: client.sound ? "speaker.wave.2.fill" : "speaker.slash.fill")
      }.accessibilityLabel("Toggle sound")
      Button {
        help = true
      } label: {
        Image(systemName: "questionmark.circle")
      }.accessibilityLabel("How to play")
      Button {
        client.leave()
      } label: {
        Image(systemName: "rectangle.portrait.and.arrow.right")
      }.accessibilityLabel("Leave room")
    }
    .font(.system(size: 15)).foregroundStyle(.white.opacity(0.7))
    .padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 14)
  }
  private var welcome: some View {
    ScrollView {
      VStack(spacing: 22) {
        HStack(spacing: 7) {
          Circle().fill(Palette.cyan).frame(width: 6, height: 6)
          Text("MULTIPLAYER  /  NEON ARCADE").tracking(2).font(
            .system(size: 9, weight: .bold, design: .monospaced))
        }.foregroundStyle(Palette.cyan).padding(.top, 30)
        VStack(spacing: -4) {
          Text("CHOMP").foregroundStyle(Palette.gold)
          Text("CROWN").foregroundStyle(.white)
        }.font(.system(size: 62, weight: .black, design: .rounded)).tracking(-3)
          .shadow(color: Palette.gold.opacity(0.18), radius: 18)
        TimelineView(.animation) { context in
          let time = context.date.timeIntervalSinceReferenceDate
          ZStack {
            RoundedRectangle(cornerRadius: 28).stroke(Color.blue.opacity(0.35), lineWidth: 1).frame(
              height: 126)
            HStack(spacing: 22) {
              Chomper(opening: 0.28 + (sin(time * 8) + 1) * 0.24)
                .fill(Palette.gold.gradient).frame(width: 72, height: 72)
                .shadow(color: Palette.gold.opacity(0.45), radius: 18)
                .overlay(alignment: .top) {
                  Image(systemName: "crown.fill").font(.system(size: 24)).foregroundStyle(
                    Palette.gold
                  ).offset(y: -22)
                }
              ForEach(0..<3) { _ in Circle().fill(Palette.gold).frame(width: 4, height: 4) }
              Chomper(opening: 0.6).fill(Color.indigo).frame(width: 36, height: 36)
                .overlay(Chomper(opening: 0.6).stroke(Palette.colors[1], lineWidth: 2))
                .rotationEffect(.degrees(180))
            }
          }
        }.frame(height: 134).accessibilityHidden(true)
        VStack(spacing: 6) {
          Text("EAT. OUTLAST. REIGN.").font(.system(size: 13, weight: .heavy, design: .monospaced))
            .tracking(2)
          Text("A maze. Your friends. One crown.").font(.system(size: 13)).foregroundStyle(
            .white.opacity(0.5))
        }
        VStack(spacing: 14) {
          fieldLabel("YOUR GUEST NAME")
          TextField("Guest name", text: $client.name).textFieldStyle(ArcadeField())
            .accessibilityIdentifier("guest-name")
          fieldLabel("ROOM SERVER")
          TextField("ws://192.168.1.5:8873", text: $client.address)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            .keyboardType(.URL).textFieldStyle(ArcadeField()).accessibilityIdentifier(
              "server-address")
          Button {
            client.connect(create: true)
          } label: {
            HStack {
              Image(systemName: "plus")
              Text("CREATE A ROOM")
              Spacer()
              Image(systemName: "arrow.right")
            }
          }.buttonStyle(ArcadeButton()).disabled(client.connecting).accessibilityIdentifier(
            "create-room")
          HStack(spacing: 10) {
            TextField("ROOM CODE", text: $client.room)
              .textInputAutocapitalization(.characters).autocorrectionDisabled()
              .textFieldStyle(ArcadeField()).accessibilityIdentifier("room-code")
            Button("JOIN") { client.connect() }
              .buttonStyle(ArcadeButton(color: Palette.cyan)).disabled(
                client.connecting || client.room.isEmpty
              )
              .accessibilityIdentifier("join-room")
          }
          if client.connecting { ProgressView("Connecting…").font(.caption) }
          errorMessage
        }
        Text("2–4 PLAYERS   •   FIRST TO 2 CROWNS").font(
          .system(size: 10, weight: .bold, design: .monospaced)
        )
        .tracking(1).foregroundStyle(.white.opacity(0.35))
        Button("HOW TO PLAY") { help = true }.font(
          .system(size: 11, weight: .bold, design: .monospaced)
        )
        .foregroundStyle(Palette.cyan)
      }.padding(.horizontal, 30).padding(.bottom, 30)
    }
  }
  private func fieldLabel(_ text: String) -> some View {
    Text(text).font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1.5)
      .foregroundStyle(.white.opacity(0.4)).frame(maxWidth: .infinity, alignment: .leading)
  }
  private var errorMessage: some View {
    Group {
      if !client.error.isEmpty {
        Text(client.error).font(.system(size: 12)).foregroundStyle(.pink).multilineTextAlignment(
          .center)
      }
    }
  }
  private func roomLobby(_ state: ArenaState) -> some View {
    ScrollView {
      VStack(spacing: 25) {
        Text("THE TABLE IS YOURS").font(.system(size: 11, weight: .bold, design: .monospaced))
          .tracking(2).foregroundStyle(Palette.cyan).padding(.top, 36)
        VStack(spacing: 10) {
          Text(state.code).font(.system(size: 64, weight: .black, design: .monospaced)).tracking(8)
          Text("SHARE THIS ROOM CODE").font(.system(size: 10, weight: .bold, design: .monospaced))
            .tracking(2).foregroundStyle(.white.opacity(0.45))
        }
        VStack(spacing: 10) {
          ForEach(state.players) { player in
            HStack(spacing: 14) {
              Chomper().fill(Palette.player(player.color)).frame(width: 30, height: 30)
              Text(player.name).font(.system(size: 17, weight: .bold, design: .rounded))
              if player.id == state.you {
                Text("YOU").font(.system(size: 9, weight: .bold, design: .monospaced))
                  .foregroundStyle(Palette.cyan)
              }
              Spacer()
              Text(player.ready ? "READY" : "JOINED")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(player.ready ? Palette.gold : .white.opacity(0.4))
            }.padding(18).background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
              .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(Palette.player(player.color).opacity(0.3))
              )
          }
          if state.players.count < 2 {
            HStack {
              ProgressView()
              Text("Waiting for a challenger…").font(.system(size: 13))
            }
            .foregroundStyle(.white.opacity(0.5)).padding(24)
          }
        }
        VStack(alignment: .leading, spacing: 15) {
          rule("01", "CHASE THE GLOW", "Power pellets turn you giant for 7 seconds.")
          rule("02", "EAT YOUR RIVALS", "Blue rivals are vulnerable. Ghosts are AI.")
          rule("03", "CLAIM THE CROWN", "Last one standing wins. First to two reigns.")
        }.padding(20).background(Color.blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
        Button(client.me?.ready == true ? "WAITING FOR CHALLENGERS" : "READY TO CHOMP") {
          client.ready()
        }
        .buttonStyle(ArcadeButton()).disabled(client.me?.ready == true)
        .accessibilityIdentifier("ready-button")
        networkFooter
        errorMessage
      }.padding(.horizontal, 26)
    }
  }
  private func arena(_ state: ArenaState, geometry: GeometryProxy) -> some View {
    let mazeHeight = min(geometry.size.width * 464 / 420, geometry.size.height - 414)
    return VStack(spacing: 0) {
      HStack(spacing: 8) {
        ForEach(state.players) { player in scoreCard(player, you: state.you) }
      }.padding(.horizontal, 18)
      HStack {
        Text("ROUND \(state.round)").foregroundStyle(Palette.cyan)
        Spacer()
        Text(state.remaining <= 15 ? "GHOST RUSH" : "LAST CHOMPER STANDING")
          .foregroundStyle(.white.opacity(0.4)).font(
            .system(size: 8, weight: .bold, design: .monospaced))
        Spacer()
        Text(String(format: "%02d", Int(ceil(state.remaining)))).foregroundStyle(
          state.remaining <= 15 ? .pink : .white)
      }.font(.system(size: 10, weight: .heavy, design: .monospaced)).tracking(1.5)
        .padding(.horizontal, 26).padding(.top, 13).padding(.bottom, 2)
      ZStack {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
          .frame(height: mazeHeight)
          .gesture(
            DragGesture(minimumDistance: 12).onEnded { value in
              let dx = value.translation.width
              let dy = value.translation.height
              client.direction(
                abs(dx) > abs(dy) ? (dx > 0 ? "right" : "left") : (dy > 0 ? "down" : "up"))
            }
          )
          .accessibilityLabel("Neon maze. Swipe to steer your chomper.")
        if state.phase == "countdown" {
          VStack(spacing: 8) {
            Text("GET READY").font(.system(size: 13, weight: .black, design: .monospaced)).tracking(
              3)
            Text("\(max(1, Int(ceil(state.countdown))))").font(
              .system(size: 72, weight: .black, design: .rounded))
          }.foregroundStyle(Palette.gold).shadow(color: .black, radius: 10)
        }
        if state.phase == "roundOver" || state.phase == "matchOver" { result(state) }
        if !state.pauseReason.isEmpty || client.status == "DISCONNECTED" {
          VStack(spacing: 12) {
            ProgressView()
            Text(state.pauseReason.isEmpty ? "Connection interrupted" : state.pauseReason)
              .font(.system(size: 14, weight: .bold)).multilineTextAlignment(.center)
            Text("Match paused · 30s reconnect window").font(.caption).foregroundStyle(.secondary)
            Button("RECONNECT") { client.connect() }.buttonStyle(ArcadeButton(color: Palette.cyan))
          }.padding(24).background(
            Palette.ink.opacity(0.96), in: RoundedRectangle(cornerRadius: 20)
          ).padding(30)
        }
      }
      powerBar
      HStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 6) {
          Text("STEER").font(.system(size: 10, weight: .heavy, design: .monospaced)).tracking(2)
            .foregroundStyle(.white.opacity(0.4))
          Text(client.lastInput).font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(Palette.cyan)
            .accessibilityIdentifier("last-input")
          Text("Tap arrows\nor swipe maze").font(.system(size: 10)).foregroundStyle(
            .white.opacity(0.3))
        }.frame(maxWidth: .infinity, alignment: .leading)
        dpad
        VStack(alignment: .trailing, spacing: 6) {
          Text("● \(client.status)").font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(Palette.cyan)
          Text("2 CROWNS\nTO WIN").font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.35)).multilineTextAlignment(.trailing)
        }.frame(maxWidth: .infinity, alignment: .trailing)
      }.padding(.horizontal, 26).padding(.top, 7)
      if !client.automation.isEmpty {
        Text("AUTOMATED INPUT DRIVER • \(client.automation.uppercased())")
          .font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.orange)
          .padding(.top, 4)
      }
      Text(
        "\(state.phase) | round \(state.round) | \(state.players.map { "\($0.name):\($0.score):\($0.crowns)" }.joined(separator: " "))"
      )
      .font(.system(size: 1)).foregroundStyle(Palette.ink)
      .accessibilityIdentifier("match-status")
      Spacer(minLength: 0)
    }
  }
  private func scoreCard(_ player: PlayerState, you: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Chomper().fill(Palette.player(player.color)).frame(width: 15, height: 15)
        Text(player.name.uppercased()).lineLimit(1).font(
          .system(size: 10, weight: .bold, design: .monospaced))
        if player.id == you {
          Text("YOU").font(.system(size: 7, weight: .bold)).foregroundStyle(.white.opacity(0.35))
        }
        Spacer(minLength: 0)
      }
      HStack {
        Text(String(format: "%05d", player.score))
          .font(.system(size: 23, weight: .heavy, design: .monospaced)).minimumScaleFactor(0.6)
        Spacer(minLength: 3)
        HStack(spacing: 3) {
          ForEach(0..<2) { index in
            Image(systemName: "crown.fill").font(.system(size: 10))
              .foregroundStyle(index < player.crowns ? Palette.gold : .white.opacity(0.12))
          }
        }
      }.foregroundStyle(player.alive ? Palette.player(player.color) : .white.opacity(0.25))
    }.padding(12).frame(maxWidth: .infinity)
      .background(
        Palette.player(player.color).opacity(0.055), in: RoundedRectangle(cornerRadius: 12)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12).stroke(
          Palette.player(player.color).opacity(player.alive ? 0.3 : 0.1)))
  }
  private var powerBar: some View {
    HStack(spacing: 8) {
      let power = client.me?.power ?? 0
      Image(systemName: power > 0 ? "bolt.fill" : "circle.fill").font(.system(size: 9))
      Text(
        power > 0
          ? "GIANT CHOMP"
          : client.me?.alive == false ? "ELIMINATED · NEXT ROUND SOON" : "FIND A POWER PELLET"
      )
      .font(.system(size: 9, weight: .heavy, design: .monospaced)).tracking(1)
      if power > 0 {
        GeometryReader { proxy in
          Capsule().fill(Palette.gold.opacity(0.12))
            .overlay(alignment: .leading) {
              Capsule().fill(Palette.gold).frame(width: proxy.size.width * power / 7)
            }
        }.frame(height: 4)
        Text(String(format: "%.1fs", power)).font(
          .system(size: 10, weight: .bold, design: .monospaced))
      }
    }.foregroundStyle(Palette.gold).frame(height: 18).padding(.horizontal, 28)
  }
  private var dpad: some View {
    VStack(spacing: 3) {
      arrow("up", symbol: "chevron.up")
      HStack(spacing: 3) {
        arrow("left", symbol: "chevron.left")
        ZStack {
          RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.07)).frame(
            width: 46, height: 42)
          Circle().stroke(Palette.cyan.opacity(0.3), lineWidth: 1).frame(width: 16, height: 16)
          Circle().fill(Palette.cyan.opacity(0.6)).frame(width: 4, height: 4)
        }
        arrow("right", symbol: "chevron.right")
      }
      arrow("down", symbol: "chevron.down")
    }
  }
  private func arrow(_ direction: String, symbol: String) -> some View {
    Button {
      client.direction(direction)
    } label: {
      Image(systemName: symbol).font(.system(size: 19, weight: .bold)).foregroundStyle(Palette.cyan)
        .frame(width: 46, height: 42)
        .background(
          Color(red: 0.06, green: 0.1, blue: 0.22), in: RoundedRectangle(cornerRadius: 11)
        )
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Palette.cyan.opacity(0.23)))
    }.buttonStyle(.plain).accessibilityLabel("Move \(direction)").accessibilityIdentifier(
      "move-\(direction)")
  }
  private func result(_ state: ArenaState) -> some View {
    let final = state.phase == "matchOver"
    let winner = state.players.first { $0.id == (final ? state.winnerId : state.roundWinnerId) }
    return VStack(spacing: 12) {
      Image(systemName: "crown.fill").font(.system(size: 34)).foregroundStyle(Palette.gold)
        .shadow(color: Palette.gold.opacity(0.6), radius: 15)
      Text(final ? "CROWN CLAIMED" : "ROUND \(state.round) COMPLETE")
        .font(.system(size: 11, weight: .heavy, design: .monospaced)).tracking(2).foregroundStyle(
          Palette.gold)
      Text(winner?.name.uppercased() ?? "DRAW")
        .font(.system(size: 32, weight: .black, design: .rounded)).foregroundStyle(
          winner.map { Palette.player($0.color) } ?? .white)
      Text(final ? "THE NEON THRONE IS YOURS" : "Next round in \(Int(ceil(state.countdown)))")
        .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(
          .white.opacity(0.5))
      if final {
        Button(client.me?.ready == true ? "WAITING FOR RIVAL…" : "REMATCH") { client.ready() }
          .buttonStyle(ArcadeButton()).disabled(client.me?.ready == true).accessibilityIdentifier(
            "rematch-button")
        Text("Both players must ready up.").font(.system(size: 10)).foregroundStyle(
          .white.opacity(0.4))
      }
    }.padding(26).frame(maxWidth: 310)
      .background(Palette.ink.opacity(0.97), in: RoundedRectangle(cornerRadius: 20))
      .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.gold.opacity(0.4)))
      .shadow(color: .black.opacity(0.7), radius: 20)
  }
  private var networkFooter: some View {
    VStack(spacing: 7) {
      Text("● \(client.status)   •   GUEST \(client.playerID.prefix(8))")
        .font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(Palette.cyan)
      if !client.automation.isEmpty {
        Text("AUTOMATED INPUT DRIVER • \(client.automation.uppercased())")
          .font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.orange)
      }
    }
  }
  private func rule(_ number: String, _ title: String, _ detail: String) -> some View {
    HStack(alignment: .top, spacing: 14) {
      Text(number).foregroundStyle(Palette.gold).font(
        .system(size: 15, weight: .bold, design: .monospaced))
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.system(size: 11, weight: .heavy, design: .monospaced))
        Text(detail).font(.system(size: 12)).foregroundStyle(.white.opacity(0.45))
      }
    }
  }
  private var instructions: some View {
    VStack(alignment: .leading, spacing: 26) {
      Text("RULE THE MAZE").font(.system(size: 30, weight: .black, design: .rounded))
        .foregroundStyle(Palette.gold)
      rule(
        "01", "DIRECTIONAL CONTROL",
        "Tap the arrows or swipe the maze. Turns are buffered until the next open junction. Movement continues automatically."
      )
      rule(
        "02", "POWER IS EVERYTHING",
        "Large glowing pellets make you giant for 7 seconds. Eat blue rivals for 500 points and ghosts for 200. Equal-strength rivals bounce apart."
      )
      rule(
        "03", "SURVIVE THE GHOSTS",
        "The three ghosts are AI. They leave the pen, chase humans, and flee powered players. Touch one without power and you are eliminated."
      )
      rule(
        "04", "TWO CROWNS TO WIN",
        "The last survivor wins a crown. At 45 seconds, total score breaks ties. Ghosts accelerate for the last 15 seconds. Two crowns win the match."
      )
      rule(
        "05", "KEEP IT LOCAL",
        "Run the room server on a computer. Both phones use that computer’s LAN WebSocket address. No account needed. Rejoin within 30 seconds after a disconnect."
      )
      Button("LET'S CHOMP") { help = false }.buttonStyle(ArcadeButton())
    }.padding(28).presentationDetents([.large]).background(Palette.ink)
  }
}

struct ArcadeField: TextFieldStyle {
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration.font(.system(size: 14, weight: .medium, design: .monospaced))
      .padding(15).background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 11))
      .overlay(RoundedRectangle(cornerRadius: 11).stroke(.white.opacity(0.12)))
  }
}

struct ArcadeButton: ButtonStyle {
  var color: Color = Palette.gold
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.font(.system(size: 12, weight: .black, design: .monospaced)).tracking(1)
      .frame(maxWidth: .infinity).padding(.vertical, 17).padding(.horizontal, 18)
      .foregroundStyle(Palette.ink).background(color, in: RoundedRectangle(cornerRadius: 12))
      .opacity(configuration.isPressed ? 0.7 : 1).scaleEffect(configuration.isPressed ? 0.98 : 1)
  }
}
