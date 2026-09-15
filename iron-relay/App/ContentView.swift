import SwiftUI

private let relayRed = Color(red: 0.94, green: 0.13, blue: 0.22)
private let ice = Color(red: 0.69, green: 0.83, blue: 0.92)

struct CutPanel: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: 10, y: 0))
      path.addLine(to: CGPoint(x: rect.maxX, y: 0))
      path.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.maxY))
      path.addLine(to: CGPoint(x: 0, y: rect.maxY))
      path.closeSubpath()
    }
  }
}

struct ContentView: View {
  @ObservedObject var client: GameClient
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        ArenaView(client: client).ignoresSafeArea()
        LinearGradient(
          colors: [.black.opacity(0.55), .clear, .black.opacity(0.75)],
          startPoint: .top, endPoint: .bottom
        ).ignoresSafeArea().allowsHitTesting(false)
        if let world = client.state, world.phase != "lobby", world.players.count == 2 {
          combat(world, size: geometry.size)
        } else {
          lobby(size: geometry.size)
        }
        if client.showGuide { guide }
      }
      .foregroundStyle(.white)
      .font(.system(size: 12, weight: .semibold, design: .rounded))
    }
  }

  private func lobby(size: CGSize) -> some View {
    HStack(alignment: .top, spacing: 24) {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Rectangle().fill(relayRed).frame(width: 28, height: 3)
          Text("THE FOUNDRY   /   TAG COMBAT").font(.system(size: 9, weight: .heavy)).tracking(3)
        }.foregroundStyle(ice)
        Text("IRON RELAY").font(.system(size: 42, weight: .black, design: .rounded)).italic()
          .tracking(-2)
        Text("TWO FIGHTERS. ONE CHANCE.").font(.system(size: 10, weight: .bold)).tracking(2)
          .foregroundStyle(.white.opacity(0.55))
        Spacer()
        Text(FighterStyle.all[client.team[0]].discipline).font(.system(size: 9, weight: .heavy))
          .tracking(3)
          .foregroundStyle(Color(uiColor: FighterStyle.all[client.team[0]].color))
        Text(FighterStyle.all[client.team[0]].name).font(.system(size: 30, weight: .black)).italic()
        Text(FighterStyle.all[client.team[0]].description).font(.system(size: 10)).foregroundStyle(
          ice)
        HStack(spacing: 6) {
          ForEach(0..<4) { index in
            Button {
              guard !client.connected else { return }
              if client.team[1] == index {
                client.team.swapAt(0, 1)
              } else {
                client.team[0] = index
              }
            } label: {
              VStack(spacing: 3) {
                Text(String(FighterStyle.all[index].name.prefix(1)))
                  .font(.system(size: 18, weight: .black)).italic()
                Text(FighterStyle.all[index].name).font(.system(size: 8, weight: .heavy))
              }
              .frame(width: 61, height: 49)
              .background(
                client.team[0] == index
                  ? Color(uiColor: FighterStyle.all[index].color) : .black.opacity(0.6)
              )
              .clipShape(CutPanel())
              .overlay(CutPanel().stroke(.white.opacity(client.team[0] == index ? 0.8 : 0.2)))
            }.accessibilityIdentifier("fighter-\(index)")
          }
        }.buttonStyle(.plain)
        Text("SELECT YOUR POINT FIGHTER").font(.system(size: 8, weight: .bold)).tracking(2)
          .foregroundStyle(.gray)
      }
      Spacer(minLength: 0)
      VStack(alignment: .leading, spacing: 11) {
        HStack {
          Text(client.connected ? "ARENA LOBBY" : "ENTER THE ARENA").font(
            .system(size: 18, weight: .black)
          ).italic()
          Spacer()
          Button {
            client.showGuide = true
          } label: {
            Image(systemName: "questionmark.circle")
          }
          .accessibilityLabel("Controls")
        }
        Rectangle().fill(relayRed).frame(height: 2)
        if client.connected {
          Text("ROOM  \(client.room.uppercased())").font(
            .system(size: 25, weight: .black, design: .monospaced))
          ForEach(client.state?.players ?? []) { player in
            HStack {
              Circle().fill(player.online ? Color.green : .orange).frame(width: 6, height: 6)
              VStack(alignment: .leading, spacing: 2) {
                Text(player.name.uppercased()).font(.system(size: 13, weight: .black))
                Text(player.team.map { FighterStyle.all[$0].name }.joined(separator: " / "))
                  .font(.system(size: 9)).foregroundStyle(ice)
              }
              Spacer()
              Text(player.ready ? "READY" : "WAITING").font(.system(size: 9, weight: .bold))
                .foregroundStyle(player.ready ? .green : .gray)
            }.padding(.vertical, 5)
          }
          if (client.state?.players.count ?? 0) < 2 {
            Text(
              "Share this code with a second device.\nBoth players must connect to the same host."
            )
            .font(.system(size: 11)).foregroundStyle(ice)
          }
          Spacer(minLength: 0)
          primaryButton(
            client.me?.ready == true ? "READY • WAITING FOR OPPONENT" : "READY TO FIGHT",
            id: "ready"
          ) { client.ready() }
          Button("LEAVE ROOM") { client.leave() }.font(.system(size: 9, weight: .bold))
        } else {
          field("GUEST NAME", text: $client.guest, id: "guest")
          HStack(spacing: 10) {
            field("ROOM CODE", text: $client.room, id: "room")
            VStack(alignment: .leading, spacing: 3) {
              Text("RESERVE").font(.system(size: 8, weight: .heavy)).foregroundStyle(ice)
              Menu {
                ForEach(0..<4) { index in
                  if index != client.team[0] {
                    Button(FighterStyle.all[index].name) { client.team[1] = index }
                  }
                }
              } label: {
                HStack {
                  Text(FighterStyle.all[client.team[1]].name)
                  Image(systemName: "chevron.down")
                }.frame(height: 29)
              }.accessibilityIdentifier("reserve")
            }
          }
          field("SERVER ADDRESS", text: $client.serverAddress, id: "server")
          primaryButton(client.connecting ? "CONNECTING…" : "JOIN / CREATE ROOM", id: "connect") {
            client.connect()
          }
          Text(client.status).font(.system(size: 9, weight: .medium)).foregroundStyle(ice)
            .lineLimit(2)
        }
      }
      .padding(18)
      .frame(width: min(320, size.width * 0.40))
      .background(Color(red: 0.04, green: 0.055, blue: 0.085).opacity(0.94))
      .overlay(Rectangle().stroke(.white.opacity(0.15)))
    }.padding(.horizontal, 28).padding(.vertical, 16)
  }

  private func field(_ title: String, text: Binding<String>, id: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(title).font(.system(size: 8, weight: .heavy)).tracking(1.5).foregroundStyle(ice)
      TextField(title, text: text).textInputAutocapitalization(.never).autocorrectionDisabled()
        .font(.system(size: 12, weight: .semibold, design: .monospaced))
        .padding(.horizontal, 8).frame(height: 29).background(.white.opacity(0.07))
        .overlay(Rectangle().stroke(.white.opacity(0.15))).accessibilityIdentifier(id)
    }
  }

  private func primaryButton(_ title: String, id: String, action: @escaping () -> Void) -> some View
  {
    Button(action: action) {
      Text(title).font(.system(size: 12, weight: .black)).tracking(1)
        .frame(maxWidth: .infinity).frame(height: 36)
        .background(relayRed.gradient).clipShape(CutPanel())
    }.buttonStyle(.plain).accessibilityIdentifier(id)
  }

  private func combat(_ world: ArenaState, size: CGSize) -> some View {
    ZStack {
      VStack(spacing: 0) {
        HStack(alignment: .top, spacing: 12) {
          health(world.players[0], right: false)
          VStack(spacing: 0) {
            Text("\(max(0, Int(ceil(Double(world.remaining) / 60))))")
              .font(.system(size: 38, weight: .black, design: .rounded)).italic()
              .monospacedDigit().shadow(color: .black, radius: 6)
            Text("FIRST TO 2").font(.system(size: 7, weight: .heavy)).tracking(1.5).foregroundStyle(
              ice)
          }.frame(width: 72)
          health(world.players[1], right: true)
        }
        .padding(.horizontal, 24).padding(.top, 9)
        HStack {
          Text("THE FOUNDRY").tracking(2)
          Spacer()
          Text(
            "ROOM \(world.code)  •  \(client.connected ? "LIVE" : "OFFLINE")  •  \(client.identity.prefix(6))"
          )
          .accessibilityIdentifier("peer-status")
        }
        .font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(
          ice.opacity(0.7)
        )
        .padding(.horizontal, 30).padding(.top, 5)
        Spacer()
        HStack(alignment: .bottom) {
          movementPad
          VStack(alignment: .leading, spacing: 4) {
            if let me = client.me, me.combo > 1 {
              Text("\(me.combo) HIT COMBO").font(.system(size: 20, weight: .black)).italic()
                .foregroundStyle(.orange)
              Text("\(me.comboDamage) DAMAGE").font(.system(size: 10, weight: .heavy))
                .foregroundStyle(ice)
            }
            Spacer(minLength: 0)
            HStack(spacing: 14) {
              Button {
                client.leave()
              } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
              }
              .accessibilityLabel("Leave arena")
              Button {
                client.muted.toggle()
                client.audio.mute(client.muted)
              } label: {
                Image(systemName: client.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
              }.accessibilityLabel("Toggle audio")
              Button {
                client.showGuide = true
              } label: {
                Image(systemName: "questionmark.circle")
              }
              .accessibilityLabel("Controls")
            }.foregroundStyle(ice).font(.system(size: 15))
          }.frame(height: 84).padding(.leading, 8)
          Spacer()
          actionPad
        }
        .padding(.horizontal, 24).padding(.bottom, client.automation.isEmpty ? 12 : 26)
      }
      if world.phase == "countdown" {
        cinematic(
          world.countdown > 55 ? "ROUND \(world.round)" : "FIGHT",
          subtitle: "IRON RELAY • TAG TO SURVIVE"
        )
        .allowsHitTesting(false)
      } else if world.phase == "roundEnd" {
        cinematic(
          "K.O.",
          subtitle: world.roundWinner == "draw"
            ? "DRAW ROUND"
            : "\(world.players.first { $0.id == world.roundWinner }?.name.uppercased() ?? "") TAKES THE ROUND"
        )
        .allowsHitTesting(false)
      } else if world.phase == "result" {
        result(world)
      }
      if world.paused {
        VStack(spacing: 10) {
          Text("CONNECTION PAUSED").font(.system(size: 22, weight: .black)).italic()
          Text("Your opponent has 60 seconds to reconnect.").font(.system(size: 12))
          if !client.connected {
            Button("RECONNECT") { client.connect() }.accessibilityIdentifier("reconnect")
          }
        }.padding(24).background(.black.opacity(0.88))
      } else if !client.connected {
        Button("CONNECTION LOST • RECONNECT") { client.connect() }
          .padding(20).background(.black.opacity(0.9)).accessibilityIdentifier("reconnect")
      }
      if !client.automation.isEmpty {
        VStack {
          Spacer()
          Text("AUTOMATED INPUT • \(client.automation.uppercased())     \(client.demoStep)")
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .frame(maxWidth: .infinity).padding(5).background(.black.opacity(0.85)).foregroundStyle(
              .yellow)
        }.allowsHitTesting(false)
      }
    }
  }

  private func health(_ player: FighterState, right: Bool) -> some View {
    VStack(alignment: right ? .trailing : .leading, spacing: 3) {
      HStack(spacing: 8) {
        if right { Spacer() }
        Text(FighterStyle.all[player.team[player.active]].name)
          .font(.system(size: 15, weight: .black)).italic()
        Text(player.name.uppercased()).font(.system(size: 8, weight: .bold)).foregroundStyle(ice)
        if !right { Spacer() }
        ForEach(0..<2) { index in
          Circle().fill(index < player.wins ? relayRed : .white.opacity(0.15)).frame(
            width: 8, height: 8
          )
          .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 1))
        }
      }
      gauge(
        health: player.health[player.active], red: player.red[player.active], right: right,
        active: true
      )
      .frame(height: 15)
      HStack(spacing: 6) {
        if right {
          Text(FighterStyle.all[player.team[1 - player.active]].name).font(
            .system(size: 8, weight: .heavy))
        }
        gauge(
          health: player.health[1 - player.active], red: player.red[1 - player.active],
          right: right, active: false
        )
        .frame(height: 6)
        if !right {
          Text(FighterStyle.all[player.team[1 - player.active]].name).font(
            .system(size: 8, weight: .heavy))
        }
      }.foregroundStyle(ice)
    }
  }

  private func gauge(health: Double, red: Double, right: Bool, active: Bool) -> some View {
    GeometryReader { geometry in
      ZStack(alignment: right ? .trailing : .leading) {
        Color.black.opacity(0.7)
        relayRed.opacity(0.8).frame(width: geometry.size.width * max(0, red) / 150)
        LinearGradient(
          colors: active
            ? [Color(red: 0.98, green: 0.85, blue: 0.54), .white] : [ice, .white.opacity(0.7)],
          startPoint: .bottom, endPoint: .top
        )
        .frame(width: geometry.size.width * max(0, health) / 150)
      }.clipShape(CutPanel())
        .overlay(CutPanel().stroke(.white.opacity(0.7), lineWidth: 0.8))
    }
  }

  private var movementPad: some View {
    VStack(spacing: 2) {
      HoldButton(
        symbol: "chevron.up", caption: "STEP", id: "step-up", size: 36,
        down: { client.move(x: 0, z: -1) }, up: { client.move(x: 0, z: 0) })
      HStack(spacing: 4) {
        HoldButton(
          symbol: "chevron.left", caption: "", id: "move-left", size: 42,
          down: { client.move(x: -1, z: 0) }, up: { client.move(x: 0, z: 0) })
        Image(systemName: "scope").font(.system(size: 18)).foregroundStyle(.white.opacity(0.25))
          .frame(width: 32)
        HoldButton(
          symbol: "chevron.right", caption: "", id: "move-right", size: 42,
          down: { client.move(x: 1, z: 0) }, up: { client.move(x: 0, z: 0) })
      }
      HoldButton(
        symbol: "chevron.down", caption: "STEP", id: "step-down", size: 36,
        down: { client.move(x: 0, z: 1) }, up: { client.move(x: 0, z: 0) })
    }
  }

  private var actionPad: some View {
    HStack(alignment: .bottom, spacing: 12) {
      VStack(spacing: 8) {
        let cooldown = client.me?.tagCooldown ?? 0
        Button {
          client.action("tag")
        } label: {
          VStack(spacing: 2) {
            Image(systemName: "arrow.triangle.swap")
            Text(cooldown > 0 ? "\(Int(ceil(Double(cooldown) / 60)))s" : "TAG").font(
              .system(size: 9, weight: .black))
          }.frame(width: 50, height: 43).background(relayRed.opacity(0.4)).clipShape(CutPanel())
            .overlay(CutPanel().stroke(relayRed))
        }.accessibilityIdentifier("tag")
        HoldButton(
          symbol: "shield.fill", caption: "GUARD", id: "guard", size: 48,
          down: { client.guardDown(true) }, up: { client.guardDown(false) })
      }
      VStack(spacing: 7) {
        attackButton(
          "RISE", sub: "LAUNCH", action: "launch", color: Color(red: 0.59, green: 0.41, blue: 0.84),
          size: 48)
        HStack(spacing: 11) {
          attackButton("P", sub: "PUNCH", action: "punch", color: relayRed, size: 55)
          attackButton(
            "K", sub: "KICK", action: "kick", color: Color(red: 0.17, green: 0.51, blue: 0.69),
            size: 55)
        }
      }
    }.buttonStyle(.plain)
  }

  private func attackButton(
    _ title: String, sub: String, action: String, color: Color, size: CGFloat
  ) -> some View {
    Button {
      client.action(action)
    } label: {
      VStack(spacing: 0) {
        Text(title).font(.system(size: title.count > 1 ? 11 : 24, weight: .black)).italic()
        Text(sub).font(.system(size: 7, weight: .black))
      }
      .frame(width: size, height: size)
      .background(color.opacity(0.40).gradient).clipShape(Circle())
      .overlay(Circle().stroke(color.opacity(0.9), lineWidth: 2))
      .shadow(color: color.opacity(0.25), radius: 8)
    }.accessibilityIdentifier(action).accessibilityLabel(sub.capitalized)
  }

  private func cinematic(_ title: String, subtitle: String) -> some View {
    VStack(spacing: 1) {
      Text(title).font(.system(size: 65, weight: .black, design: .rounded)).italic().tracking(-2)
        .foregroundStyle(
          LinearGradient(
            colors: [.white, Color(red: 1, green: 0.50, blue: 0.31), relayRed],
            startPoint: .top, endPoint: .bottom)
        )
        .shadow(color: .black, radius: 2, x: 3, y: 4).shadow(
          color: relayRed.opacity(0.8), radius: 20)
      Text(subtitle).font(.system(size: 9, weight: .black)).tracking(3).shadow(
        color: .black, radius: 4)
    }.offset(y: -3)
  }

  private func result(_ world: ArenaState) -> some View {
    VStack(spacing: 9) {
      Text("MATCH COMPLETE").font(.system(size: 9, weight: .heavy)).tracking(4).foregroundStyle(ice)
      Text(world.winner == client.identity ? "YOU WIN" : "DEFEAT")
        .font(.system(size: 48, weight: .black)).italic().foregroundStyle(
          world.winner == client.identity ? .white : relayRed)
      Text(
        "\(world.players.first { $0.id == world.winner }?.name.uppercased() ?? "WINNER") • VICTORIOUS"
      )
      .font(.system(size: 12, weight: .black)).tracking(2)
      Text(world.players.map { "\($0.name): \($0.wins)" }.joined(separator: "   /   "))
        .font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(ice)
      primaryButton(
        client.me?.rematch == true ? "REMATCH REQUESTED • WAITING" : "REMATCH", id: "rematch"
      ) { client.rematch() }
      Button("RETURN TO LOBBY") { client.leave() }.font(.system(size: 9, weight: .bold))
    }.padding(22).frame(width: 340).background(.black.opacity(0.87))
      .overlay(Rectangle().stroke(relayRed.opacity(0.6)))
  }

  private var guide: some View {
    ZStack {
      Color.black.opacity(0.7).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("THE RELAY PLAYBOOK").font(.system(size: 20, weight: .black)).italic()
          Spacer()
          Button {
            client.showGuide = false
          } label: {
            Image(systemName: "xmark.circle.fill")
          }.accessibilityLabel("Close controls")
        }
        Text(
          "← →  Move in / out     ↑ ↓  Sidestep linear attacks\nHold GUARD to block. Release before attacking."
        )
        Text(
          "P → P → K    Jab, cross, finishing kick\nRISE → TAG → P    Launch, relay, aerial follow-up\nK covers a wider sidestep lane. Whiffs leave you open."
        )
        Text(
          "Reserve red health recovers. TAG has a 4s cooldown.\nEither fighter's knockout loses the round. First to 2 wins."
        )
        Text(
          "Connect two devices to the same server and room code.\nNo AI opponents. Room codes identify two guest players."
        )
        .foregroundStyle(ice)
      }.font(.system(size: 12, weight: .medium)).lineSpacing(4).padding(24).frame(width: 490)
        .background(Color(red: 0.045, green: 0.06, blue: 0.09))
        .overlay(Rectangle().stroke(relayRed))
    }
  }
}

struct HoldButton: View {
  let symbol: String
  let caption: String
  let id: String
  let size: CGFloat
  let down: () -> Void
  let up: () -> Void
  @State private var held = false
  var body: some View {
    VStack(spacing: 1) {
      Image(systemName: symbol).font(.system(size: 15, weight: .bold))
      if !caption.isEmpty { Text(caption).font(.system(size: 6, weight: .black)) }
    }
    .frame(width: size, height: size)
    .background(held ? .white.opacity(0.30) : .black.opacity(0.50)).clipShape(Circle())
    .overlay(Circle().stroke(.white.opacity(held ? 0.9 : 0.35)))
    .contentShape(Circle())
    .gesture(
      DragGesture(minimumDistance: 0).onChanged { _ in
        if !held {
          held = true
          down()
        }
      }.onEnded { _ in
        held = false
        up()
      }
    )
    .accessibilityElement().accessibilityLabel(caption.isEmpty ? id : caption)
    .accessibilityIdentifier(id).accessibilityAddTraits(.isButton)
    .accessibilityAction {
      down()
      Task {
        try? await Task.sleep(for: .milliseconds(150))
        up()
      }
    }
    .onDisappear {
      if held {
        up()
        held = false
      }
    }
  }
}
