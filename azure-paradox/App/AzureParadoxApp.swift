import SpriteKit
import SwiftUI

@main
struct AzureParadoxApp: App {
  @StateObject private var client = DuelClient()

  var body: some Scene {
    WindowGroup {
      DuelView(client: client)
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .onOpenURL { client.handle($0) }
    }
  }
}

private let gold = Color(red: 0.91, green: 0.76, blue: 0.43)
private let ice = Color(red: 0.35, green: 0.88, blue: 1)
private let ink = Color(red: 0.025, green: 0.045, blue: 0.12)

struct DuelView: View {
  @ObservedObject var client: DuelClient
  @State private var muted = false

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        if client.inArena {
          SpriteView(scene: client.scene, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
          arenaControls
          if client.state?.phase == "result" { result }
        } else {
          Image("celestial-stage").resizable().scaledToFill()
            .frame(width: geometry.size.width, height: geometry.size.height).clipped()
            .overlay(ink.opacity(0.73)).ignoresSafeArea()
          selection
        }
        VStack {
          Spacer()
          if client.automated {
            Text("AUTOMATED INPUT DRIVER  ·  \(client.driverStep)")
              .font(.system(size: 9, weight: .bold, design: .monospaced))
              .foregroundStyle(ice).padding(.horizontal, 9).padding(.vertical, 4)
              .background(ink.opacity(0.9))
              .accessibilityIdentifier("automationStatus")
          }
        }.allowsHitTesting(false)
      }
    }
    .sheet(isPresented: $client.showGuide) { guide }
  }

  private var selection: some View {
    HStack(spacing: 25) {
      VStack(alignment: .leading, spacing: 9) {
        Text("A CELESTIAL FIGHTING CHRONICLE")
          .font(.system(size: 9, weight: .semibold)).tracking(3).foregroundStyle(ice)
        Text("AZURE\nPARADOX")
          .font(.custom("Georgia-BoldItalic", size: 43)).lineSpacing(-8)
          .foregroundStyle(.white).shadow(color: ice.opacity(0.5), radius: 14)
        Rectangle().fill(gold).frame(height: 1)
        Text(
          client.connected
            ? "ROOM \(client.roomCode)  •  \(client.state?.players.count ?? 1) / 2"
            : "GUEST DUEL  /  LOCAL OR LAN"
        )
        .font(.system(size: 12, weight: .bold)).tracking(1).foregroundStyle(gold)
        if client.connected {
          ForEach(client.state?.players ?? []) { player in
            HStack {
              Circle().fill(player.connected ? ice : .red).frame(width: 6, height: 6)
              Text("\(player.name) · \(player.character.capitalized)")
              Spacer()
              Text(player.ready ? "READY" : "SELECTING").foregroundStyle(player.ready ? ice : gold)
            }.font(.system(size: 11, weight: .semibold))
          }
          Button(client.me?.ready == true ? "CANCEL READY" : "READY TO DUEL") { client.ready() }
            .buttonStyle(ArcaneButton()).accessibilityIdentifier("readyButton")
          Text("First to two rounds. Both guests must ready.")
            .font(.system(size: 10)).foregroundStyle(.white.opacity(0.6))
          Button("LEAVE ROOM") { client.leave() }.font(.system(size: 10)).foregroundStyle(gold)
        } else {
          HStack {
            entry("GUEST", text: $client.guestName, id: "guestField")
            entry("ROOM CODE", text: $client.roomCode, id: "roomField")
          }
          entry("SERVER ADDRESS", text: $client.serverAddress, id: "serverField")
          HStack {
            Button("HOST ROOM") { client.connect(create: true) }
              .buttonStyle(ArcaneButton()).accessibilityIdentifier("hostButton")
            Button("JOIN") { client.connect(create: false) }
              .buttonStyle(ArcaneButton()).accessibilityIdentifier("joinButton")
          }
        }
        Text(client.status).font(.system(size: 10, weight: .medium)).foregroundStyle(ice)
          .accessibilityIdentifier("connectionStatus")
        HStack(spacing: 22) {
          Button("HOW TO PLAY") { client.showGuide = true }
          Button(muted ? "SOUND OFF" : "SOUND ON") {
            muted.toggle()
            AudioEngine.shared.muted = muted
          }
        }.font(.system(size: 10, weight: .bold)).foregroundStyle(gold)
      }.frame(maxWidth: 340)
      VStack(spacing: 10) {
        Text("SELECT YOUR DESTINY")
          .font(.custom("Georgia", size: 20)).tracking(3).foregroundStyle(gold)
        HStack(spacing: 12) {
          characterCard(
            "seraph", title: "SERAPH", subtitle: "THE RIFTBORN", detail: "Rift Drive · life steal",
            color: .red)
          characterCard(
            "lyra", title: "LYRA", subtitle: "THE FROST REGENT",
            detail: "Frost Drive · crystal bind", color: ice)
        }
        Text("LIGHT → MEDIUM → HEAVY → DRIVE  ·  50 HEAT: DISTORTION")
          .font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.75))
      }
    }.padding(.horizontal, 34).padding(.vertical, 15)
  }

  private func entry(_ label: String, text: Binding<String>, id: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(label).font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(gold)
      TextField(label, text: text)
        .font(.system(size: 12)).textInputAutocapitalization(.never).autocorrectionDisabled()
        .padding(8).background(ink.opacity(0.9))
        .overlay(Rectangle().stroke(gold.opacity(0.5), lineWidth: 1))
        .accessibilityIdentifier(id)
    }
  }

  private func characterCard(
    _ id: String, title: String, subtitle: String, detail: String, color: Color
  ) -> some View {
    Button {
      client.select(id)
    } label: {
      VStack(spacing: 3) {
        ZStack(alignment: .bottom) {
          LinearGradient(
            colors: [color.opacity(0.12), ink, color.opacity(0.25)], startPoint: .top,
            endPoint: .bottom)
          Circle().stroke(gold.opacity(0.3), lineWidth: 1).padding(20)
          Image("\(id)-0").resizable().scaledToFit().padding(.top, 4)
        }.frame(height: 205)
        Text(title).font(.custom("Georgia-Bold", size: 22)).foregroundStyle(.white)
        Text(subtitle).font(.system(size: 8, weight: .bold)).tracking(1.5).foregroundStyle(gold)
        Text(detail).font(.system(size: 9)).foregroundStyle(ice).padding(.bottom, 9)
      }
      .frame(maxWidth: 200)
      .background(ink.opacity(0.7))
      .overlay(
        Rectangle().stroke(
          client.character == id ? gold : gold.opacity(0.25),
          lineWidth: client.character == id ? 2 : 1)
      )
      .overlay(alignment: .topLeading) {
        if client.character == id {
          Text("SELECTED").font(.system(size: 8, weight: .heavy))
            .foregroundStyle(ink).padding(5).background(gold)
        }
      }
    }.buttonStyle(.plain).accessibilityIdentifier("\(id)Card")
  }

  private var arenaControls: some View {
    VStack {
      HStack {
        Spacer()
        if !client.connected {
          Button("RECONNECT") { client.connect(create: false) }
            .font(.system(size: 10, weight: .bold)).padding(8).background(ink)
            .foregroundStyle(gold).accessibilityIdentifier("reconnectButton")
        }
      }.padding(.top, 70)
      Spacer()
      HStack(alignment: .bottom) {
        VStack(spacing: 3) {
          HStack(spacing: 7) {
            actionButton("↑", detail: "JUMP", action: "jump", tint: ice, size: 45)
            actionButton("»", detail: "DASH", action: "dash", tint: gold, size: 45)
          }
          HStack(spacing: 7) {
            HoldControl(label: "◀", detail: "MOVE", color: ice, size: 47) {
              client.move($0 ? -1 : 0)
            }
            .accessibilityIdentifier("moveLeft")
            HoldControl(label: "▶", detail: "MOVE", color: ice, size: 47) {
              client.move($0 ? 1 : 0)
            }
            .accessibilityIdentifier("moveRight")
          }
        }
        HoldControl(label: "◇", detail: "BARRIER", color: ice, size: 44) { client.barrier($0) }
          .accessibilityIdentifier("barrierButton").padding(.leading, 7)
        Spacer()
        VStack(spacing: 5) {
          Text(client.lastAction).font(.system(size: 9, weight: .bold)).foregroundStyle(ice).frame(
            height: 10)
          HStack(spacing: 14) {
            Button("MOVES") { client.showGuide = true }.accessibilityIdentifier("movesButton")
            Button(muted ? "UNMUTE" : "MUTE") {
              muted.toggle()
              AudioEngine.shared.muted = muted
            }.accessibilityIdentifier("muteButton")
          }.font(.system(size: 9, weight: .bold)).foregroundStyle(gold)
        }.padding(.bottom, 18)
        Spacer()
        VStack(spacing: 4) {
          HStack(spacing: 7) {
            actionButton("C", detail: "HEAVY", action: "heavy", tint: gold, size: 47)
            actionButton("D", detail: "DRIVE", action: "drive", tint: ice, size: 47)
            actionButton("✧", detail: "SUPER 50", action: "super", tint: .purple, size: 47)
              .opacity((client.me?.heat ?? 0) >= 50 ? 1 : 0.55)
          }
          HStack(spacing: 9) {
            actionButton("A", detail: "LIGHT", action: "light", tint: .red, size: 47)
            actionButton("B", detail: "MEDIUM", action: "medium", tint: .green, size: 47)
          }.padding(.leading, 15)
        }
      }.padding(.horizontal, 16).padding(.bottom, client.automated ? 22 : 8)
    }
  }

  private func actionButton(
    _ label: String, detail: String, action: String, tint: Color, size: CGFloat
  ) -> some View {
    Button {
      client.action(action)
    } label: {
      ControlFace(label: label, detail: detail, color: tint, size: size, pressed: false)
    }.buttonStyle(.plain).accessibilityLabel(detail).accessibilityIdentifier("\(action)Button")
  }

  private var result: some View {
    ZStack {
      ink.opacity(0.62).ignoresSafeArea()
      VStack(spacing: 10) {
        Text("THE WHEEL OF FATE TURNS").font(.system(size: 11, weight: .bold)).tracking(3)
          .foregroundStyle(ice)
        Text(client.state?.winner == client.playerID ? "VICTORY" : "DEFEAT")
          .font(.custom("Georgia-BoldItalic", size: 50)).foregroundStyle(gold)
        HStack(spacing: 40) {
          ForEach(client.state?.players ?? []) { player in
            VStack(spacing: 3) {
              Text(player.name.uppercased()).font(.custom("Georgia-Bold", size: 20))
              Text("\(player.wins) ROUNDS").font(.system(size: 12, weight: .bold)).foregroundStyle(
                ice)
            }
          }
        }
        Text("SHARED MATCH \(client.state?.match ?? 1) RESULT  •  ROOM \(client.roomCode)")
          .font(.system(size: 10, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
        HStack {
          Button(client.me?.rematch == true ? "WAITING FOR PEER…" : "REMATCH") { client.rematch() }
            .buttonStyle(ArcaneButton()).accessibilityIdentifier("rematchButton")
            .disabled(client.me?.rematch == true)
          Button("LEAVE") { client.leave() }.buttonStyle(ArcaneButton()).accessibilityIdentifier(
            "leaveButton")
        }.frame(width: 350)
      }.padding(25).background(ink.opacity(0.94))
        .overlay(Rectangle().stroke(gold, lineWidth: 1))
    }
  }

  private var guide: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("COMBAT GRIMOIRE").font(.custom("Georgia-Bold", size: 25)).foregroundStyle(gold)
          Spacer()
          Button("CLOSE") { client.showGuide = false }.accessibilityIdentifier("closeGuide")
        }
        Text(
          "Hold ◀ / ▶ to move. Holding back guards grounded attacks with chip damage. Tap ↑ twice to double jump; » dashes on the ground or once in the air."
        )
        Text(
          "A / B / C: light, medium and heavy. Chain confirmed hits in ascending strength into D. Heavy launches for air follow-ups. Whiffed attacks cannot cancel. Range, startup and recovery matter."
        )
        Text(
          "D · Seraph: Rift Drive strikes in front and restores 48 life on hit. Lyra: Frost Drive fires a crystal that briefly freezes the opponent. Airborne shots retain their height."
        )
        Text(
          "Hold ◇ for barrier guard, including in the air. Barrier prevents chip but consumes its own gauge. Empty barrier triggers Danger: increased damage until recovery."
        )
        Text(
          "✧ · Distortion costs 50 heat. Heat builds on contact. Seraph's Eclipse Requiem and Lyra's Celestial Zero strike a wide area; they can be guarded or escaped."
        )
        Text(
          "Win two 90-second rounds. Both guests must confirm rematch. A lost connection pauses the duel for 30 seconds; tap Reconnect to recover the same guest. Rooms are ephemeral."
        )
        Toggle(
          "Automated input driver (clearly labeled)",
          isOn: Binding(
            get: { client.automated }, set: { client.setAutomation($0) })
        )
        .accessibilityIdentifier("automationToggle")
        Text(
          "The optional driver sends the same movement/action messages as these touch controls. It cannot set health, score or outcome."
        )
        .font(.footnote).foregroundStyle(.secondary)
      }.padding(25)
    }.background(ink).foregroundStyle(.white).presentationDetents([.large])
  }
}

struct ArcaneButton: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.font(.system(size: 12, weight: .bold)).tracking(1)
      .frame(maxWidth: .infinity).padding(.vertical, 11)
      .foregroundStyle(configuration.isPressed ? .white : gold)
      .background(
        LinearGradient(colors: [Color.blue.opacity(0.3), ink], startPoint: .top, endPoint: .bottom)
      )
      .overlay(Rectangle().stroke(gold.opacity(configuration.isPressed ? 1 : 0.6), lineWidth: 1))
  }
}

struct ControlFace: View {
  let label: String
  let detail: String
  let color: Color
  let size: CGFloat
  let pressed: Bool
  var body: some View {
    VStack(spacing: 0) {
      Text(label).font(.custom("Georgia-Bold", size: size * 0.46))
      Text(detail).font(.system(size: 6, weight: .heavy)).tracking(0.4)
    }
    .foregroundStyle(.white).frame(width: size, height: size)
    .background(
      Circle().fill(
        LinearGradient(
          colors: [color.opacity(pressed ? 0.8 : 0.45), ink.opacity(0.85)], startPoint: .topLeading,
          endPoint: .bottomTrailing))
    )
    .overlay(Circle().stroke(gold.opacity(0.85), lineWidth: 1))
    .overlay(Circle().stroke(color.opacity(0.5), lineWidth: 1).padding(3))
    .shadow(color: color.opacity(0.25), radius: 4)
  }
}

struct HoldControl: View {
  let label: String
  let detail: String
  let color: Color
  let size: CGFloat
  let changed: (Bool) -> Void
  @State private var pressed = false

  var body: some View {
    ControlFace(label: label, detail: detail, color: color, size: size, pressed: pressed)
      .contentShape(Circle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in
            if !pressed {
              pressed = true
              changed(true)
            }
          }
          .onEnded { _ in
            pressed = false
            changed(false)
          }
      )
      .onDisappear { if pressed { changed(false) } }
      .accessibilityElement().accessibilityLabel(detail == "MOVE" ? "\(detail) \(label)" : detail)
      .accessibilityAddTraits(.isButton)
      .accessibilityAction {
        changed(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { changed(false) }
      }
  }
}
