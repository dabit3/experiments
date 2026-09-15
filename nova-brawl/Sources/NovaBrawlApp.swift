import SwiftUI

private let amber = Color(red: 1, green: 0.77, blue: 0.25)
private let cyan = Color(red: 0.32, green: 0.86, blue: 1)
private let ink = Color(red: 0.035, green: 0.07, blue: 0.13)

@main
struct NovaBrawlApp: App {
  @StateObject private var model = GameModel()
  @Environment(\.scenePhase) private var phase

  var body: some Scene {
    WindowGroup {
      ContentView(model: model)
        .preferredColorScheme(.dark)
        .onChange(of: phase) { _, next in
          if next != .active { model.resetControls() }
        }
    }
  }
}

struct ContentView: View {
  @ObservedObject var model: GameModel

  var body: some View {
    ZStack {
      ArenaView(renderer: model.arena).ignoresSafeArea()
      LinearGradient(
        colors: [ink.opacity(0.8), .clear, .clear, ink.opacity(0.95)],
        startPoint: .top, endPoint: .bottom
      ).ignoresSafeArea().allowsHitTesting(false)
      if let state = model.state {
        match(state)
      } else {
        lobby
      }
    }
    .sheet(isPresented: $model.help) { help }
  }

  private var masthead: some View {
    HStack(alignment: .center) {
      HStack(spacing: 2) {
        Text("NOVA").foregroundStyle(.white)
        Text("/").foregroundStyle(amber)
        Text("BRAWL").foregroundStyle(.white)
      }
      .font(.system(size: 18, weight: .black, design: .rounded)).italic()
      Spacer()
      Button {
        model.toggleMute()
      } label: {
        Image(systemName: model.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
          .frame(width: 35, height: 35)
      }
      .accessibilityLabel(model.muted ? "Unmute sound" : "Mute sound")
      Button {
        model.help = true
      } label: {
        Image(systemName: "questionmark.circle").frame(width: 35, height: 35)
      }.accessibilityLabel("Controls help")
    }
    .foregroundStyle(.white.opacity(0.85))
  }

  private var lobby: some View {
    VStack(alignment: .leading, spacing: 0) {
      masthead
      Text("SKYBREAK ARENA")
        .font(.system(size: 10, weight: .bold, design: .monospaced))
        .tracking(4).foregroundStyle(cyan).padding(.top, 4)
      Spacer(minLength: 12)
      HStack(spacing: 6) {
        Capsule().fill(amber).frame(width: 22, height: 3)
        Text("01 / FLARE").tracking(3).font(.system(size: 12, weight: .black, design: .monospaced))
      }.foregroundStyle(amber)
      Text("BREAK\nTHE LIMIT.")
        .font(.system(size: 44, weight: .black, design: .rounded))
        .italic().lineSpacing(-8).shadow(color: .black.opacity(0.4), radius: 8).padding(.top, 6)
      Text("Two fighters. One sky. No holding back.")
        .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8)).padding(
          .top, 8)
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("ONLINE DUEL").font(.system(size: 13, weight: .black)).tracking(2)
          Spacer()
          Circle().fill(model.connection == "LIVE" ? .green : cyan).frame(width: 5, height: 5)
          Text("GUEST PLAY").font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(cyan)
        }
        HStack(spacing: 10) {
          field("FIGHTER NAME", text: $model.guestName, id: "Guest name")
          field("ROOM CODE", text: $model.room, id: "Room code")
        }
        field("SERVER ADDRESS", text: $model.server, id: "Server address")
        if !model.error.isEmpty {
          Text(model.error).font(.system(size: 11, weight: .medium)).foregroundStyle(.orange)
            .accessibilityIdentifier("connectionError")
        }
        HStack(spacing: 10) {
          Button {
            model.connect(create: true)
          } label: {
            Label("CREATE ROOM", systemImage: "plus").frame(maxWidth: .infinity)
          }
          .buttonStyle(PrimaryStyle(tint: amber)).accessibilityIdentifier("createRoom")
          Button {
            model.connect(create: false)
          } label: {
            Label("JOIN", systemImage: "arrow.right").frame(maxWidth: .infinity)
          }
          .buttonStyle(PrimaryStyle(tint: cyan)).accessibilityIdentifier("joinRoom")
        }
        .disabled(model.connection == "CONNECTING")
        Text(
          model.connection == "CONNECTING"
            ? "Connecting to arena…" : "Start the local server, then share your room code."
        )
        .font(.system(size: 10)).foregroundStyle(.white.opacity(0.5))
      }
      .padding(18)
      .background(ink.opacity(0.92), in: RoundedRectangle(cornerRadius: 18))
      .overlay(RoundedRectangle(cornerRadius: 18).stroke(cyan.opacity(0.25), lineWidth: 1))
      .padding(.top, 22)
      Text("REAL-TIME PvP  /  NATIVE 3D  /  NO ACCOUNT")
        .font(.system(size: 8, weight: .semibold, design: .monospaced))
        .tracking(1.4).foregroundStyle(.white.opacity(0.5)).padding(.top, 12)
    }
    .padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 12)
    .frame(maxWidth: 500)
  }

  private func field(_ label: String, text: Binding<String>, id: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(label).font(.system(size: 8, weight: .bold, design: .monospaced))
        .tracking(1.5).foregroundStyle(.white.opacity(0.5))
      TextField("", text: text)
        .font(.system(size: 13, weight: .semibold, design: .monospaced))
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .padding(.horizontal, 10).frame(height: 37)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.1)))
        .accessibilityLabel(id)
    }
  }

  private func match(_ state: ArenaState) -> some View {
    VStack(spacing: 0) {
      masthead.padding(.horizontal, 18)
      HStack(spacing: 6) {
        Circle().fill(state.paused || model.reconnecting ? .orange : .green).frame(
          width: 5, height: 5)
        Text("\(state.code) • \(model.connection)").tracking(1.1)
        Spacer()
        Text("ROUND \(String(format: "%02d", state.round))").tracking(1)
      }
      .font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(cyan)
      .padding(.horizontal, 20).padding(.top, 3)
      if let me = model.local {
        VStack(spacing: 8) {
          healthBar(me, yours: true)
          if let enemy = model.opponent { healthBar(enemy, yours: false) }
        }.padding(.horizontal, 20).padding(.top, 16)
      }
      if ["playing", "countdown"].contains(state.phase) {
        HStack(alignment: .center) {
          Text("SKYBREAK\nHIGHLANDS").font(.system(size: 8, weight: .bold, design: .monospaced))
            .tracking(1.5).foregroundStyle(.white.opacity(0.75))
          Spacer()
          Text(String(format: "%03d", Int(ceil(state.time))))
            .font(.system(size: 29, weight: .black, design: .rounded)).italic()
          Spacer()
          Text(
            "\(Int(model.local?.pos.y ?? 0))m ALT\n\(model.local?.locked == true ? "LOCKED" : "FREE AIM")"
          )
          .font(.system(size: 8, weight: .bold, design: .monospaced))
          .multilineTextAlignment(.trailing).foregroundStyle(amber)
        }.padding(.horizontal, 22).padding(.top, 12)
      }
      Spacer()
      if state.phase == "lobby" {
        roomPanel(state)
      } else if state.phase == "countdown" {
        Text("\(max(1, Int(ceil(state.countdown))))")
          .font(.system(size: 96, weight: .black, design: .rounded)).italic()
          .foregroundStyle(amber).shadow(color: amber.opacity(0.6), radius: 24)
        Text("ENGAGE THE LIMIT").font(.system(size: 12, weight: .black)).tracking(3)
        Spacer()
      } else if state.phase == "result" {
        result(state)
      } else {
        HStack {
          Text(model.feedback).font(.system(size: 11, weight: .black, design: .monospaced))
            .tracking(1)
            .foregroundStyle(amber).shadow(color: .black, radius: 2)
          Spacer()
          if (model.local?.combo ?? 0) > 1 {
            Text("\(model.local?.combo ?? 0) HITS").font(.system(size: 20, weight: .black)).italic()
              .foregroundStyle(amber)
          }
        }.padding(.horizontal, 20).padding(.bottom, 12)
        controls.padding(.bottom, 6)
      }
      if !model.autoLabel.isEmpty {
        Text(model.autoLabel).font(.system(size: 8, weight: .bold, design: .monospaced))
          .tracking(1).foregroundStyle(amber)
          .frame(maxWidth: .infinity).padding(.vertical, 5).background(ink.opacity(0.85))
      }
    }
    .padding(.top, 4)
    .overlay {
      if state.paused || model.reconnecting {
        VStack(spacing: 14) {
          ProgressView().tint(amber)
          Text("RECONNECTING FIGHTER").font(.system(size: 17, weight: .black))
          Text("Match paused. Your room is held for 30 seconds.")
            .font(.system(size: 12)).multilineTextAlignment(.center)
          Button("LEAVE ROOM") { model.leave() }.buttonStyle(PrimaryStyle(tint: cyan))
        }
        .padding(28).background(ink.opacity(0.96), in: RoundedRectangle(cornerRadius: 18)).padding(
          24)
      }
    }
  }

  private func healthBar(_ fighter: FighterState, yours: Bool) -> some View {
    VStack(spacing: 4) {
      HStack(spacing: 7) {
        Text(fighter.slot == 0 ? "F" : "I")
          .font(.system(size: 14, weight: .black, design: .rounded)).italic()
          .frame(width: 25, height: 25).background(
            (yours ? amber : cyan).opacity(0.2), in: RoundedRectangle(cornerRadius: 5)
          )
          .overlay(RoundedRectangle(cornerRadius: 5).stroke((yours ? amber : cyan).opacity(0.6)))
        Text(fighter.name.uppercased()).font(.system(size: 11, weight: .black)).tracking(1)
        Text(yours ? "YOU" : "RIVAL").font(.system(size: 7, weight: .heavy)).foregroundStyle(
          yours ? amber : cyan)
        Spacer()
        Text("\(Int(fighter.hp)) / 300").font(.system(size: 10, weight: .bold, design: .monospaced))
      }
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Rectangle().fill(ink.opacity(0.8))
          Rectangle().fill(
            LinearGradient(
              colors: yours ? [Color.orange, amber] : [Color.blue, cyan], startPoint: .leading,
              endPoint: .trailing)
          )
          .frame(width: proxy.size.width * max(0, fighter.hp / 300))
        }
      }.frame(height: yours ? 9 : 6).clipShape(.rect(cornerRadius: 1))
      if yours {
        HStack(spacing: 5) {
          Text("ENERGY").font(.system(size: 7, weight: .bold)).foregroundStyle(cyan)
          GeometryReader { proxy in
            ZStack(alignment: .leading) {
              Rectangle().fill(ink.opacity(0.8))
              Rectangle().fill(cyan).frame(width: proxy.size.width * fighter.energy / 100)
            }
          }.frame(height: 3)
          Text("\(Int(fighter.energy))").font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(cyan)
        }
      }
    }
  }

  private func roomPanel(_ state: ArenaState) -> some View {
    VStack(spacing: 14) {
      Text("ARENA \(state.code)").font(.system(size: 24, weight: .black, design: .rounded)).italic()
      Text("Share this code with your rival on the same server.")
        .font(.system(size: 11)).foregroundStyle(.white.opacity(0.65))
      HStack {
        ForEach(state.players) { player in
          VStack(spacing: 5) {
            Circle().fill(player.slot == 0 ? amber : cyan).frame(width: 10, height: 10)
            Text(player.name).font(.system(size: 14, weight: .bold))
            Text(player.ready ? "READY" : "STANDING BY").font(
              .system(size: 8, weight: .bold, design: .monospaced)
            )
            .foregroundStyle(player.ready ? .green : .white.opacity(0.5))
          }.frame(maxWidth: .infinity)
        }
        if state.players.count < 2 {
          Text("Waiting for rival…").font(.system(size: 12)).foregroundStyle(cyan).frame(
            maxWidth: .infinity)
        }
      }.padding(.vertical, 12)
      Button(model.local?.ready == true ? "READY • WAITING FOR RIVAL" : "READY TO FIGHT") {
        model.ready()
      }
      .buttonStyle(PrimaryStyle(tint: amber)).disabled(model.local?.ready == true)
      .accessibilityIdentifier("readyButton")
      Button("LEAVE ROOM") { model.leave() }.font(.system(size: 10, weight: .bold)).foregroundStyle(
        .white.opacity(0.6))
    }
    .padding(24).frame(maxWidth: .infinity)
    .background(ink.opacity(0.95), in: RoundedRectangle(cornerRadius: 20)).padding(20)
  }

  private func result(_ state: ArenaState) -> some View {
    VStack(spacing: 14) {
      Text(state.reason).font(.system(size: 11, weight: .black, design: .monospaced)).tracking(4)
        .foregroundStyle(cyan)
      Text(state.winner.isEmpty ? "DRAW" : state.winner == model.playerID ? "VICTORY" : "DEFEAT")
        .font(.system(size: 46, weight: .black, design: .rounded)).italic().foregroundStyle(amber)
      Text(
        state.winner.isEmpty
          ? "A perfectly matched rivalry."
          : "\(state.players.first { $0.id == state.winner }?.name ?? "Rival") wins the sky."
      )
      .font(.system(size: 13)).foregroundStyle(.white.opacity(0.7))
      HStack {
        statistic("\(model.local?.damage ?? 0)", "DAMAGE")
        statistic("\(model.local?.hits ?? 0)", "HITS")
        statistic("\(model.local?.dodges ?? 0)", "DODGES")
      }.padding(.vertical, 8)
      Button(model.local?.ready == true ? "REMATCH REQUESTED" : "REMATCH") { model.ready() }
        .buttonStyle(PrimaryStyle(tint: amber)).disabled(model.local?.ready == true)
        .accessibilityIdentifier("rematchButton")
      Button("LEAVE ARENA") { model.leave() }.font(.system(size: 10, weight: .bold))
        .foregroundStyle(.white.opacity(0.6))
    }.padding(26).frame(maxWidth: .infinity)
      .background(ink.opacity(0.94), in: RoundedRectangle(cornerRadius: 20))
      .overlay(RoundedRectangle(cornerRadius: 20).stroke(amber.opacity(0.4)))
      .padding(20)
  }

  private func statistic(_ value: String, _ label: String) -> some View {
    VStack(spacing: 4) {
      Text(value).font(.system(size: 25, weight: .black, design: .rounded))
      Text(label).font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(cyan)
    }.frame(maxWidth: .infinity)
  }

  private var controls: some View {
    VStack(spacing: 12) {
      HStack {
        Button {
          model.action("lock")
        } label: {
          Label(model.local?.locked == true ? "LOCK ON" : "FREE AIM", systemImage: "scope")
        }.accessibilityLabel("Toggle target lock")
        Spacer()
        Button {
          model.action("flight")
        } label: {
          Label(model.local?.flying == true ? "LAND" : "FLIGHT", systemImage: "arrow.up.forward")
        }.accessibilityLabel("Toggle flight")
        Spacer()
        Button {
          model.leave()
        } label: {
          Image(systemName: "rectangle.portrait.and.arrow.right")
        }
        .accessibilityLabel("Leave match")
      }
      .font(.system(size: 9, weight: .black)).tracking(1)
      .foregroundStyle(cyan).padding(.horizontal, 5)
      HStack(alignment: .bottom, spacing: 9) {
        VStack(spacing: 6) {
          HStack(spacing: 8) {
            HoldControl(label: "↑", detail: "RISE", tint: cyan, width: 42) { down in
              model.lift = down ? 1 : 0
            }
            HoldControl(label: "↓", detail: "DIVE", tint: cyan, width: 42) { down in
              model.lift = down ? -1 : 0
            }
          }
          Joystick { x, z in
            model.moveX = x
            model.moveZ = z
          }.frame(width: 112, height: 112)
        }
        Spacer(minLength: 0)
        VStack(spacing: 8) {
          HStack(spacing: 9) {
            HoldControl(label: "bolt.fill", detail: "CHARGE", tint: amber, width: 50, symbol: true)
            { model.charge = $0 }
            fightButton("wind", "DODGE", "18", tint: cyan, size: 50) { model.action("dodge") }
            HoldControl(label: "forward.fill", detail: "BOOST", tint: cyan, width: 50, symbol: true)
            { model.boost = $0 }
          }
          HStack(spacing: 9) {
            fightButton("sparkle", "BLAST", "8", tint: amber, size: 50) { model.action("shot") }
            fightButton("burst.fill", "STRIKE", "", tint: amber, size: 58) { model.action("melee") }
            fightButton("hurricane", "BEAM", "42", tint: cyan, size: 50) { model.action("beam") }
          }
        }
      }
      Text("MOVE / STRAFE        HOLD CHARGE + BOOST  •  TAP ATTACKS")
        .font(.system(size: 6, weight: .bold, design: .monospaced))
        .tracking(0.8).foregroundStyle(.white.opacity(0.4))
    }
    .padding(.horizontal, 20).padding(.top, 15)
    .background(
      LinearGradient(colors: [.clear, ink.opacity(0.6)], startPoint: .top, endPoint: .bottom))
  }

  private func fightButton(
    _ icon: String, _ label: String, _ cost: String, tint: Color, size: CGFloat,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(spacing: 4) {
        ZStack {
          Circle().fill(ink.opacity(0.76))
          Circle().stroke(tint.opacity(0.7), lineWidth: 1.5)
          Image(systemName: icon).font(.system(size: size * 0.36, weight: .bold)).foregroundStyle(
            tint)
          if !cost.isEmpty {
            Text(cost).font(.system(size: 7, weight: .bold, design: .monospaced)).foregroundStyle(
              .white.opacity(0.65)
            )
            .offset(y: size * 0.31)
          }
        }.frame(width: size, height: size)
        Text(label).font(.system(size: 7, weight: .black)).tracking(0.4).foregroundStyle(.white)
      }
    }.buttonStyle(.plain).accessibilityLabel(label.capitalized).accessibilityIdentifier(
      label.lowercased())
  }

  private var help: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text("OWN THE SKY.").font(.system(size: 28, weight: .black)).italic().foregroundStyle(
            amber)
          Text(
            "Win by depleting your rival's 300 health. If 90 seconds expire, the healthier fighter wins. Both players must ready before each round."
          )
          helpRow(
            "MOVE & LOCK",
            "Drag the left stick to approach, retreat or strafe around your locked rival. Toggle LOCK ON to use forward-facing free aim."
          )
          helpRow(
            "FLIGHT / RISE / DIVE",
            "Tap FLIGHT to hover. Hold RISE or DIVE to change altitude. Tap LAND to return to ground. Altitude matters: attacks can miss above or below."
          )
          helpRow(
            "BOOST / DODGE",
            "Hold BOOST with movement to close gaps (13 energy/second). DODGE costs 18, grants brief invulnerability and shifts sideways. Time it against the beam's blue windup."
          )
          helpRow(
            "STRIKE / BLAST",
            "STRIKE within 3.7m. Three quick strikes form a combo; the third launches your rival. BLAST costs 8 and fires a traveling energy projectile."
          )
          helpRow(
            "CHARGE / BEAM",
            "Hold CHARGE while stationary to regain 25 energy/second. BEAM costs 42, locks aim at the start of a 0.8-second windup, then fires a massive piercing blast for 52 damage. Your rival can dodge it."
          )
          helpRow(
            "NETWORK PLAY",
            "Run the included Node server. Create a room on one device; join its code on a second. For a LAN server, edit the address on the title screen. A lost peer pauses play for up to 30 seconds."
          )
          Text(
            "Original characters and art. Inspired by the aerial arena battles of Dragon Ball Zenkai Battle Royale."
          )
          .font(.footnote).foregroundStyle(.secondary)
        }.padding(24)
      }.background(ink).navigationTitle("Field Manual")
        .toolbar {
          ToolbarItem(placement: .confirmationAction) { Button("Done") { model.help = false } }
        }
    }
  }

  private func helpRow(_ heading: String, _ text: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(heading).font(.system(size: 12, weight: .black)).tracking(1).foregroundStyle(cyan)
      Text(text).font(.system(size: 14)).foregroundStyle(.white.opacity(0.8))
    }
  }
}

private struct PrimaryStyle: ButtonStyle {
  var tint: Color
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 11, weight: .black)).tracking(1)
      .foregroundStyle(ink).padding(.horizontal, 14).frame(height: 44)
      .background(
        tint.opacity(configuration.isPressed ? 0.65 : 1), in: RoundedRectangle(cornerRadius: 6)
      )
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
  }
}

private struct HoldControl: View {
  let label: String
  let detail: String
  let tint: Color
  let width: CGFloat
  var symbol = false
  let hold: (Bool) -> Void
  @State private var active = false

  var body: some View {
    VStack(spacing: 4) {
      ZStack {
        Circle().fill(active ? tint.opacity(0.35) : ink.opacity(0.76))
        Circle().stroke(tint.opacity(0.65), lineWidth: 1)
        if symbol {
          Image(systemName: label).font(.system(size: width * 0.3, weight: .bold))
        } else {
          Text(label).font(.system(size: 19, weight: .bold))
        }
      }.frame(width: width, height: width).foregroundStyle(tint)
      Text(detail).font(.system(size: 7, weight: .black)).tracking(0.4)
    }
    .contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 0).onChanged { _ in
        if !active {
          active = true
          hold(true)
        }
      }.onEnded { _ in
        active = false
        hold(false)
      }
    )
    .onDisappear { hold(false) }
    .accessibilityLabel("Hold \(detail.lowercased())")
    .accessibilityAddTraits(.isButton)
  }
}

private struct Joystick: View {
  let move: (Double, Double) -> Void
  @State private var offset = CGSize.zero

  var body: some View {
    ZStack {
      Circle().fill(ink.opacity(0.52)).overlay(Circle().stroke(.white.opacity(0.25)))
      Circle().stroke(.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [3, 5])).padding(
        14)
      Image(systemName: "plus").font(.system(size: 55, weight: .ultraLight)).foregroundStyle(
        .white.opacity(0.18))
      Circle().fill(
        LinearGradient(
          colors: [.white.opacity(0.35), .white.opacity(0.1)], startPoint: .topLeading,
          endPoint: .bottomTrailing)
      )
      .overlay(Circle().stroke(.white.opacity(0.55))).frame(width: 43, height: 43).offset(offset)
    }
    .gesture(
      DragGesture(minimumDistance: 0).onChanged { value in
        let dx = value.location.x - 56
        let dy = value.location.y - 56
        let length = max(38, hypot(dx, dy))
        offset = CGSize(width: dx / length * 38, height: dy / length * 38)
        move(Double(dx / length), -Double(dy / length))
      }.onEnded { _ in
        offset = .zero
        move(0, 0)
      }
    )
    .accessibilityLabel("Movement joystick: drag to approach, retreat or strafe")
  }
}
