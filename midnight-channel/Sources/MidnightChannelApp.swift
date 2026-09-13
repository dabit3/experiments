import SpriteKit
import SwiftUI

private let yellow = Color(red: 1, green: 0.79, blue: 0)
private let black = Color(red: 0.035, green: 0.045, blue: 0.075)
private let blue = Color(red: 0.14, green: 0.9, blue: 1)
private let crimson = Color(red: 1, green: 0.16, blue: 0.26)

@main
struct MidnightChannelApp: App {
  var body: some Scene {
    WindowGroup {
      ChannelView()
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
  }
}

struct ChannelView: View {
  @StateObject private var client = MatchClient()
  @State private var showHelp = false
  var body: some View {
    GeometryReader { geometry in
      let scale = min(geometry.size.width / 1000, geometry.size.height / 460)
      ZStack {
        black.ignoresSafeArea()
        ZStack {
          SpriteView(scene: client.scene, options: [.ignoresSiblingOrder])
            .frame(width: 1000, height: 460)
          if let state = client.state {
            if state.phase == "lobby" {
              lobby(online: true)
            } else {
              battleHUD(state)
              if state.phase == "versus" { versus(state) }
              if state.phase == "roundEnd" { roundEnd(state) }
              if state.phase == "result" { result(state) }
              if state.paused { signalLost }
            }
          } else {
            lobby(online: false)
          }
          if showHelp { help }
        }
        .frame(width: 1000, height: 460)
        .scaleEffect(scale)
        .frame(width: geometry.size.width, height: geometry.size.height)
      }
    }
    .ignoresSafeArea()
    .onOpenURL { client.handleURL($0) }
    .onReceive(
      NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
    ) { _ in
      client.holdAxis(0)
      client.holdGuard(false)
    }
  }

  private func heading(_ text: String, size: CGFloat, color: Color = .white) -> some View {
    Text(text).font(.custom("AvenirNextCondensed-HeavyItalic", size: size)).foregroundStyle(color)
  }

  private func checker(height: CGFloat) -> some View {
    Canvas { context, size in
      for x in stride(from: 0, to: Int(size.width), by: 16) {
        for y in stride(from: 0, to: Int(size.height), by: 16) where (x / 16 + y / 16) % 2 == 0 {
          context.fill(Path(CGRect(x: x, y: y, width: 16, height: 16)), with: .color(black))
        }
      }
    }.frame(height: height).background(yellow)
  }

  private func panelButton(_ title: String, accent: Color = yellow, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      heading(title, size: 23, color: black)
        .frame(maxWidth: .infinity).frame(height: 44)
        .background(accent)
        .overlay(alignment: .trailing) { Text("▸").foregroundStyle(black).padding(.trailing, 12) }
    }.buttonStyle(.plain).accessibilityIdentifier(title)
  }

  private func lobby(online: Bool) -> some View {
    ZStack {
      black
      HStack(spacing: 0) {
        Image("rei-card").resizable().scaledToFill().frame(width: 330, height: 460).clipped()
        Image("mika-card").resizable().scaledToFill().frame(width: 330, height: 460).clipped()
        black.frame(width: 340)
      }
      LinearGradient(
        colors: [.clear, black.opacity(0.2), black], startPoint: .top, endPoint: .bottom)
      VStack(spacing: 0) {
        HStack(spacing: 12) {
          heading("MC", size: 34, color: black).padding(.horizontal, 10).background(.white)
            .rotationEffect(.degrees(-5))
          Text("THE AFTER-HOURS FIGHTING BROADCAST").font(
            .system(size: 12, weight: .black, design: .monospaced)
          ).foregroundStyle(black)
          Spacer()
          Text("01 / LOCAL NETWORK").font(.system(size: 12, weight: .black, design: .monospaced))
            .foregroundStyle(black)
        }.padding(.horizontal, 24).frame(height: 48).background(yellow)
        HStack(spacing: 24) {
          VStack(alignment: .leading, spacing: 0) {
            Text("NO SIGNAL. NO RULES.").font(
              .system(size: 13, weight: .black, design: .monospaced)
            ).foregroundStyle(yellow).padding(.top, 15)
            Spacer()
            heading("MIDNIGHT", size: 66, color: .white)
              .shadow(color: black, radius: 0, x: 5, y: 5)
            heading("CHANNEL", size: 76, color: yellow)
              .padding(.top, -23).shadow(color: black, radius: 0, x: 5, y: 5)
            HStack {
              Text("REI  /  ANTENNA").foregroundStyle(blue)
              Spacer()
              Text("MIKA  /  REDSHIFT").foregroundStyle(crimson)
            }.font(.system(size: 12, weight: .black, design: .monospaced))
            Text("Two rivals. Two signals. One frequency.")
              .font(.system(size: 14, weight: .semibold)).padding(.top, 8).padding(.bottom, 16)
          }.frame(width: 568)
          VStack(alignment: .leading, spacing: 10) {
            HStack {
              heading(online ? "ON THE AIR" : "TUNE IN", size: 35, color: yellow)
              Spacer()
              Circle().fill(online ? blue : crimson).frame(width: 9, height: 9)
            }
            if online {
              HStack {
                Text("ROOM").foregroundStyle(.gray)
                Text(client.roomCode).foregroundStyle(yellow)
              }.font(.system(size: 18, weight: .black, design: .monospaced))
              ForEach(0..<2) { slot in
                if let player = client.state?.fighters.first(where: { $0.slot == slot }) {
                  HStack {
                    Text("0\(slot + 1)").foregroundStyle(slot == 0 ? blue : crimson)
                    VStack(alignment: .leading, spacing: 2) {
                      Text(player.name).fontWeight(.bold)
                      Text("\(player.title) + \(player.spirit)").font(
                        .system(size: 10, weight: .bold))
                    }
                    Spacer()
                    Text(player.ready ? "READY" : "STANDBY").font(.system(size: 10, weight: .black))
                      .foregroundStyle(player.ready ? yellow : .gray)
                  }.padding(10).background(.white.opacity(0.07))
                } else {
                  Text("02   WAITING FOR SECOND SIGNAL…")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.gray).frame(height: 51)
                }
              }
              panelButton(client.me?.ready == true ? "WAITING FOR RIVAL" : "READY TO BROADCAST") {
                client.ready()
              }
              .disabled(client.me?.ready == true)
              Button("LEAVE ROOM") { client.leave() }.font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
            } else {
              entry("GUEST NAME", text: $client.guestName, id: "guestName")
              HStack(spacing: 10) {
                entry("ROOM CODE", text: $client.roomCode, id: "roomCode")
                VStack(alignment: .leading, spacing: 4) {
                  Text("PLAYERS").font(.system(size: 9, weight: .black)).foregroundStyle(.gray)
                  Text("1 vs 1").font(.system(size: 18, weight: .black)).frame(height: 32)
                }.frame(width: 65)
              }
              entry(
                "SERVER ADDRESS / EDIT FOR LAN", text: $client.serverAddress, id: "serverAddress")
              panelButton("CONNECT TO ROOM") { client.connect() }
              if !client.error.isEmpty {
                Text(client.error).font(.system(size: 10, weight: .bold)).foregroundStyle(crimson)
                  .lineLimit(2)
              } else {
                Text("Enter the same room on a second iPhone.")
                  .font(.system(size: 11)).foregroundStyle(.gray)
              }
            }
            HStack {
              Button("HOW TO PLAY") { showHelp = true }
              Spacer()
              Button(client.muted ? "SOUND OFF" : "SOUND ON") { client.toggleMute() }
            }.font(.system(size: 11, weight: .black)).foregroundStyle(yellow).padding(.top, 4)
          }.padding(18).frame(width: 330).background(black.opacity(0.96))
        }.padding(.horizontal, 24)
        Spacer(minLength: 0)
        checker(height: 12)
        HStack {
          Text("LIVE TWO-PLAYER FIGHTING • GUEST ROOMS • FIRST TO TWO ROUNDS")
          Spacer()
          Text(client.status)
        }.font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundStyle(yellow)
          .padding(.horizontal, 24).frame(height: 28).background(black)
      }
    }
  }

  private func entry(_ label: String, text: Binding<String>, id: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label).font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(.gray)
      TextField(label, text: text)
        .font(.system(size: 14, weight: .bold, design: .monospaced))
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .padding(.horizontal, 9).frame(height: 32).background(.white.opacity(0.09))
        .overlay(alignment: .bottom) { Rectangle().fill(yellow).frame(height: 1) }
        .accessibilityIdentifier(id)
    }
  }

  private func battleHUD(_ state: MatchState) -> some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: 10) {
        if state.fighters.count == 2 {
          lifePanel(state.fighters[0])
          VStack(spacing: -5) {
            heading(String(format: "%02d", Int(ceil(state.time))), size: 47, color: yellow)
            Text("ROUND \(state.round)").font(
              .system(size: 10, weight: .heavy, design: .monospaced))
          }.frame(width: 85, height: 65).background(black)
          lifePanel(state.fighters[1])
        }
      }.padding(.horizontal, 28).padding(.top, 10)
      HStack {
        Text("CH.\(client.roomCode)  •  \(client.me?.title ?? "GUEST") / \(client.guestName)")
        Spacer()
        Button(client.muted ? "SOUND OFF" : "SOUND ON") { client.toggleMute() }
        Button("EXIT") { client.leave() }.padding(.leading, 15)
      }.font(.system(size: 10, weight: .heavy, design: .monospaced))
        .foregroundStyle(.white).padding(.horizontal, 30).padding(.top, 6)
      Spacer()
      if client.automated {
        Text(client.automationStep).font(.system(size: 10, weight: .heavy, design: .monospaced))
          .padding(.horizontal, 12).padding(.vertical, 3).background(black.opacity(0.9))
          .foregroundStyle(yellow)
      }
      HStack(alignment: .bottom) {
        HStack(alignment: .bottom, spacing: 7) {
          HoldControl(
            label: "◀", subtitle: "LEFT", color: .white, diameter: 62,
            down: { client.holdAxis(-1) }, up: { client.holdAxis(0) })
          HoldControl(
            label: "▶", subtitle: "RIGHT", color: .white, diameter: 62,
            down: { client.holdAxis(1) }, up: { client.holdAxis(0) })
          actionControl("↑", subtitle: "JUMP", color: yellow, action: "jump", size: 54)
          HoldControl(
            label: "◇", subtitle: "GUARD", color: blue, diameter: 54,
            down: { client.holdGuard(true) }, up: { client.holdGuard(false) })
        }
        Spacer()
        VStack(spacing: 4) {
          Button {
            client.sendInput("super")
          } label: {
            heading(
              "OVERDRIVE  50 SP", size: 17, color: (client.me?.meter ?? 0) >= 50 ? black : .gray
            )
            .frame(width: 158, height: 29).background(
              (client.me?.meter ?? 0) >= 50 ? yellow : black)
          }.disabled((client.me?.meter ?? 0) < 50 || (client.me?.breakTicks ?? 0) > 0)
          Text(client.me?.awakened == true ? "AWAKENED / MAX 150" : "BUILD METER • STRIKE / GUARD")
            .font(.system(size: 8, weight: .black)).foregroundStyle(.white)
        }.padding(.bottom, 12)
        Spacer()
        HStack(alignment: .bottom, spacing: 8) {
          actionControl("✦", subtitle: "BURST", color: blue, action: "burst", size: 54)
            .opacity((client.me?.burst ?? 0) >= 100 ? 1 : 0.35)
          actionControl("A", subtitle: "LIGHT", color: .white, action: "light", size: 62)
          actionControl("B", subtitle: "HEAVY", color: crimson, action: "heavy", size: 62)
          actionControl("C", subtitle: "SUMMON", color: yellow, action: "summon", size: 68)
            .opacity((client.me?.breakTicks ?? 0) > 0 ? 0.35 : 1)
        }
      }.padding(.horizontal, 26).padding(.bottom, 8)
      HStack(spacing: 100) {
        ForEach(state.fighters) { player in
          HStack(spacing: 6) {
            Text("SP").font(.system(size: 12, weight: .black, design: .monospaced))
            GeometryReader { g in
              ZStack(alignment: .leading) {
                Rectangle().fill(black)
                Rectangle().fill(player.slot == 0 ? blue : crimson).frame(
                  width: g.size.width * min(1, player.meter / (player.awakened ? 150 : 100)))
              }.overlay(Rectangle().stroke(.white, lineWidth: 1))
            }.frame(height: 9)
            Text(String(format: "%03d", Int(player.meter))).font(
              .system(size: 14, weight: .heavy, design: .monospaced)
            ).foregroundStyle(yellow)
          }
        }
      }.padding(.horizontal, 28).padding(.bottom, 10).background(black.opacity(0.65))
    }
  }

  private func actionControl(
    _ label: String, subtitle: String, color: Color, action: String, size: CGFloat
  ) -> some View {
    Button {
      client.sendInput(action)
    } label: {
      ControlFace(label: label, subtitle: subtitle, color: color, diameter: size, pressed: false)
    }.buttonStyle(.plain).accessibilityLabel(subtitle).accessibilityIdentifier(subtitle)
  }

  private func lifePanel(_ player: FighterState) -> some View {
    VStack(alignment: player.slot == 0 ? .leading : .trailing, spacing: 3) {
      HStack(spacing: 6) {
        heading(player.title, size: 27, color: .white)
        Text(player.name.uppercased()).font(.system(size: 10, weight: .black, design: .monospaced))
          .foregroundStyle(yellow)
        Spacer()
        ForEach(0..<2) { index in
          Image(systemName: index < player.wins ? "diamond.fill" : "diamond")
            .font(.system(size: 12, weight: .black)).foregroundStyle(yellow)
        }
      }
      GeometryReader { geometry in
        ZStack(alignment: player.slot == 0 ? .trailing : .leading) {
          Rectangle().fill(crimson.opacity(0.7))
          Rectangle().fill(yellow).frame(width: geometry.size.width * Double(player.hp) / 1000)
        }.overlay(Rectangle().stroke(.white, lineWidth: 2))
      }.frame(height: 17).shadow(color: black, radius: 0, x: 3, y: 3)
      HStack(spacing: 4) {
        ForEach(0..<4) { index in
          ZStack {
            RoundedRectangle(cornerRadius: 1).fill(index < player.cards ? .white : black)
            Text(index < player.cards ? "✦" : "×").font(.system(size: 14, weight: .black))
              .foregroundStyle(index < player.cards ? black : crimson)
          }.frame(width: 16, height: 23).rotationEffect(.degrees(-8))
        }
        Text(
          player.breakTicks > 0
            ? "BREAK \(Int(ceil(Double(player.breakTicks) / 60)))" : player.spirit
        )
        .font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(
          player.breakTicks > 0 ? crimson : .white)
        Spacer()
        Text(player.burst >= 100 ? "BURST" : "B \(Int(player.burst))%")
          .font(.custom("AvenirNextCondensed-HeavyItalic", size: 17))
          .foregroundStyle(player.burst >= 100 ? blue : .gray)
        Text("\(player.hp)").font(.system(size: 9, weight: .bold, design: .monospaced))
      }
    }.padding(7).background(black.opacity(0.85))
  }

  private func versus(_ state: MatchState) -> some View {
    ZStack {
      HStack(spacing: 0) {
        Image("rei-card").resizable().scaledToFill().frame(width: 500, height: 460).clipped()
        Image("mika-card").resizable().scaledToFill().frame(width: 500, height: 460).clipped()
      }
      VStack(spacing: 0) {
        checker(height: 20)
        HStack {
          heading("TONIGHT'S MAIN EVENT", size: 24, color: black)
          Spacer()
          Text("CH.\(state.code) / ROUND \(state.round)").font(
            .system(size: 14, weight: .black, design: .monospaced)
          ).foregroundStyle(black)
        }.padding(.horizontal, 30).frame(height: 40).background(yellow)
        Spacer()
        HStack(alignment: .bottom) {
          VStack(alignment: .leading, spacing: -5) {
            heading("THE SILENT FREQUENCY", size: 20, color: blue)
            heading("REI", size: 80)
            heading("ANTENNA", size: 23, color: yellow)
          }
          Spacer()
          VStack(alignment: .trailing, spacing: -5) {
            heading("THE RED TRANSMISSION", size: 20, color: crimson)
            heading("MIKA", size: 80)
            heading("REDSHIFT", size: 23, color: yellow)
          }
        }.padding(30).background(
          LinearGradient(colors: [.clear, black], startPoint: .top, endPoint: .bottom))
        checker(height: 16)
      }
      heading("VS", size: 118, color: yellow).rotationEffect(.degrees(-12))
        .shadow(color: black, radius: 0, x: 8, y: 8)
      Text("BROADCAST IN \(max(1, Int(ceil(Double(state.phaseTicks) / 60))))")
        .font(.system(size: 13, weight: .black, design: .monospaced)).foregroundStyle(black)
        .padding(8).background(yellow).offset(y: 96)
    }
  }

  private func roundEnd(_ state: MatchState) -> some View {
    VStack(spacing: -8) {
      heading("SIGNAL LOST", size: 72, color: yellow).shadow(color: black, radius: 0, x: 5, y: 5)
      heading(
        state.winner.isEmpty
          ? "DRAW / REBROADCAST"
          : "\(state.fighters.first { $0.id == state.winner }?.title ?? "") TAKES THE ROUND",
        size: 27)
    }.padding(25).frame(maxWidth: .infinity).background(black.opacity(0.8))
  }

  private func result(_ state: MatchState) -> some View {
    ZStack {
      black.opacity(0.94)
      VStack(spacing: 12) {
        checker(height: 16)
        Text("BROADCAST COMPLETE / SHARED MATCH RESULT").font(
          .system(size: 12, weight: .black, design: .monospaced)
        ).foregroundStyle(yellow)
        heading(
          "\(state.fighters.first { $0.id == state.winner }?.title ?? "DRAW") WINS", size: 78,
          color: yellow)
        HStack(spacing: 70) {
          ForEach(state.fighters) { player in
            VStack(spacing: 3) {
              heading(player.title, size: 31, color: player.slot == 0 ? blue : crimson)
              Text(player.name).font(.system(size: 13, weight: .bold))
              heading("\(player.wins)", size: 52)
            }.frame(width: 150)
          }
        }
        HStack(spacing: 16) {
          panelButton(client.me?.ready == true ? "WAITING FOR RIVAL" : "REMATCH") { client.ready() }
            .disabled(client.me?.ready == true)
          panelButton("LEAVE ROOM", accent: .white) { client.leave() }
        }.frame(width: 480)
        if client.automated {
          Text(client.automationStep).font(.system(size: 10, weight: .black, design: .monospaced))
            .foregroundStyle(blue)
        }
        checker(height: 16)
      }
    }
  }

  private var signalLost: some View {
    VStack(spacing: 12) {
      heading("SIGNAL INTERRUPTED", size: 39, color: yellow)
      Text("Match paused. Waiting for your rival to reconnect.").font(
        .system(size: 15, weight: .bold))
      panelButton("RECONNECT MY SIGNAL") { client.reconnect() }.frame(width: 310)
    }.padding(30).background(black.opacity(0.95))
  }

  private var help: some View {
    ZStack {
      black.opacity(0.98)
      VStack(alignment: .leading, spacing: 13) {
        heading("HOW TO BROADCAST", size: 42, color: yellow)
        HStack(alignment: .top, spacing: 35) {
          VStack(alignment: .leading, spacing: 10) {
            helpLine(
              "MOVE / JUMP / GUARD",
              "Hold ◀ or ▶ to approach. Tap ↑ to jump.\nHold ◇ to block grounded attacks; chip damage remains."
            )
            helpLine(
              "A / B — NORMAL ATTACKS",
              "A is fast and short. B is slower with longer reach.\nChain pressure when close; whiffs leave you exposed."
            )
            helpLine(
              "C — SUMMON COMPANION",
              "Your companion appears and strikes farther away.\nBeing hit while it is visible breaks one of four cards."
            )
          }
          VStack(alignment: .leading, spacing: 10) {
            helpLine(
              "CARD BREAK",
              "Lose all four cards: companion, super and burst\nare sealed for ten seconds, then all cards return."
            )
            helpLine(
              "BURST / OVERDRIVE",
              "✦ escapes hitstun and pushes the rival away.\nBuild SP by fighting; Overdrive spends 50 SP."
            )
            helpLine(
              "ROUNDS / AWAKENING",
              "First to two rounds wins. 60 seconds per round.\nAt 35% health, gain 50 SP and raise capacity to 150."
            )
          }
        }
        Text(
          "NETWORK: Run the included server; enter its LAN address and the same room code on both devices. Each slot uses its own rival."
        ).font(.system(size: 12)).foregroundStyle(.gray)
        panelButton("BACK TO CHANNEL") { showHelp = false }.frame(width: 300)
      }.padding(35)
    }
  }

  private func helpLine(_ title: String, _ description: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      heading(title, size: 20, color: blue)
      Text(description).font(.system(size: 12, weight: .medium)).lineSpacing(3)
    }
  }
}

private struct ControlFace: View {
  let label: String
  let subtitle: String
  let color: Color
  let diameter: CGFloat
  let pressed: Bool
  var body: some View {
    VStack(spacing: 1) {
      Text(label).font(.custom("AvenirNextCondensed-HeavyItalic", size: diameter * 0.48))
      Text(subtitle).font(.system(size: 7, weight: .black, design: .monospaced))
    }.foregroundStyle(pressed ? black : color).frame(width: diameter, height: diameter)
      .background(pressed ? color : black.opacity(0.85), in: Circle())
      .overlay(Circle().stroke(color, lineWidth: 2))
      .shadow(color: black, radius: 0, x: 2, y: 3)
  }
}

private struct HoldControl: View {
  let label: String
  let subtitle: String
  let color: Color
  let diameter: CGFloat
  let down: () -> Void
  let up: () -> Void
  @State private var pressed = false
  var body: some View {
    ControlFace(
      label: label, subtitle: subtitle, color: color, diameter: diameter, pressed: pressed
    )
    .contentShape(Circle())
    .gesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          if !pressed {
            pressed = true
            down()
          }
        }
        .onEnded { _ in
          pressed = false
          up()
        }
    )
    .accessibilityLabel(subtitle)
    .accessibilityIdentifier(subtitle)
    .accessibilityAddTraits(.isButton)
    .accessibilityAction {
      down()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { up() }
    }
  }
}
