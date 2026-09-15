import SpriteKit
import SwiftUI

struct MetalPanel: ViewModifier {
  var color: Color = Color.white.opacity(0.28)
  func body(content: Content) -> some View {
    content
      .background(
        LinearGradient(
          colors: [Color(hex: 0x26303E), Color(hex: 0x0B0E15)],
          startPoint: .topLeading, endPoint: .bottomTrailing)
      )
      .overlay(Rectangle().stroke(color, lineWidth: 1))
  }
}

struct ArcadeButton: ButtonStyle {
  var color = Color.titanGold
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.custom("AvenirNextCondensed-Heavy", size: 15))
      .tracking(1)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .foregroundStyle(configuration.isPressed ? .black : color)
      .background(configuration.isPressed ? color : Color(hex: 0x17202C))
      .overlay(Rectangle().stroke(color.opacity(0.8), lineWidth: 1))
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
  }
}

struct ContentView: View {
  @ObservedObject var game: GameModel
  var body: some View {
    GeometryReader { geo in
      let scale = min(geo.size.width / 1100, geo.size.height / 500)
      ZStack {
        Color.black.ignoresSafeArea()
        Group {
          if game.room?.phase == nil || game.room?.phase == "lobby" {
            lobby
          } else {
            battle
          }
        }
        .frame(width: 1100, height: 500)
        .scaleEffect(scale)
        .frame(width: geo.size.width, height: geo.size.height)
      }
    }
    .sheet(isPresented: $game.showGuide) { guide }
  }

  private var lobby: some View {
    ZStack {
      Image(uiImage: GameArt.image("arena")).resizable().scaledToFill().frame(
        width: 1100, height: 500
      ).clipped()
      LinearGradient(
        colors: [.black.opacity(0.7), Color(hex: 0x090D15).opacity(0.95)],
        startPoint: .top, endPoint: .bottom)
      VStack(spacing: 13) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 0) {
            Text("TITAN UPRISING").font(.custom("AvenirNextCondensed-Heavy", size: 40)).tracking(5)
              .foregroundStyle(
                LinearGradient(
                  colors: [.white, Color(hex: 0xA0B1BF)],
                  startPoint: .top, endPoint: .bottom))
            Text("THE MERIDIAN CONFLICT  /  THREE HEROES. ONE CHAMPION.")
              .font(.custom("AvenirNextCondensed-DemiBold", size: 12)).tracking(2).foregroundStyle(
                Color.titanGold)
          }
          Spacer()
          Button {
            game.showGuide = true
          } label: {
            Label("HOW TO PLAY", systemImage: "questionmark.circle")
          }
          .buttonStyle(ArcadeButton(color: .white))
          Button {
            game.toggleAudio()
          } label: {
            Image(systemName: game.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
          }
          .buttonStyle(ArcadeButton(color: .white)).accessibilityIdentifier("sound")
        }
        HStack(alignment: .top, spacing: 22) {
          VStack(alignment: .leading, spacing: 10) {
            HStack {
              Text("01").foregroundStyle(Color.titanGold)
              Text("ASSEMBLE YOUR TEAM").tracking(2)
              Spacer()
              Text("\(game.selected.count) / 3 SELECTED").foregroundStyle(Color.titanGold)
            }.font(.custom("AvenirNextCondensed-Bold", size: 16))
            HStack(spacing: 8) {
              ForEach(Hero.all) { hero in
                heroCard(hero)
              }
            }
            HStack(spacing: 10) {
              Image(systemName: "link").foregroundStyle(Color.titanGold)
              VStack(alignment: .leading, spacing: 2) {
                Text(synergyTitle).font(.custom("AvenirNextCondensed-Bold", size: 15)).tracking(1)
                Text("Three matching faction cards: +6% damage. Mixed teams are always legal.")
                  .font(.custom("AvenirNextCondensed-Regular", size: 13)).foregroundStyle(.gray)
              }
              Spacer()
            }.padding(12).modifier(MetalPanel(color: .titanGold.opacity(0.4)))
            HStack(spacing: 16) {
              Label("QUICK", systemImage: "bolt.fill").foregroundStyle(Color(hex: 0xF47273))
              Label("STRONG", systemImage: "burst.fill").foregroundStyle(Color(hex: 0x78B5FA))
              Label("HOLD BLOCK", systemImage: "shield.fill")
              Label("SPECIAL", systemImage: "sparkles").foregroundStyle(Color.titanGold)
            }.font(.custom("AvenirNextCondensed-Bold", size: 13)).frame(maxWidth: .infinity)
          }
          .frame(width: 720)
          connectionPanel
        }
        HStack {
          Circle().fill(game.connected ? .green : Color.titanGold).frame(width: 5, height: 5)
          Text(game.status).lineLimit(1).accessibilityIdentifier("connection-status")
          Spacer()
          Text("COLLECTION 001—006  /  ORIGINAL EDITION").foregroundStyle(.gray)
        }.font(.custom("AvenirNextCondensed-Medium", size: 12)).tracking(1)
      }
      .padding(.horizontal, 40)
      .padding(.vertical, 24)
    }
  }

  private var synergyTitle: String {
    if game.selected.count == 3 && game.selected.allSatisfy({ $0 < 3 }) {
      return "DAWN PACT  •  TEAM SYNERGY ACTIVE"
    }
    if game.selected.count == 3 && game.selected.allSatisfy({ $0 >= 3 }) {
      return "ECLIPSE ORDER  •  TEAM SYNERGY ACTIVE"
    }
    return "FORGE YOUR OWN ALLIANCE"
  }

  private func heroCard(_ hero: Hero) -> some View {
    let selected = game.selected.firstIndex(of: hero.id)
    return Button {
      game.choose(hero.id)
    } label: {
      VStack(spacing: 0) {
        ZStack(alignment: .topLeading) {
          LinearGradient(
            colors: [hero.color.opacity(0.26), .black], startPoint: .top, endPoint: .bottom)
          Image(uiImage: GameArt.image("heroes-\(hero.id)")).resizable().scaledToFit()
            .frame(width: 113, height: 182).scaleEffect(1.12).offset(y: 4)
          VStack(alignment: .leading) {
            HStack {
              Text(String(format: "%03d", hero.id + 1))
              Spacer()
              if let selected {
                Text("\(selected + 1)").foregroundStyle(.black).padding(4).background(hero.color)
              }
            }.font(.custom("AvenirNextCondensed-Bold", size: 11))
            Spacer()
            Text(hero.subtitle).font(.custom("AvenirNextCondensed-DemiBold", size: 8)).tracking(0.8)
          }.padding(7)
        }
        .frame(width: 113, height: 182).clipped()
        VStack(alignment: .leading, spacing: 3) {
          Text(hero.name).font(.custom("AvenirNextCondensed-Heavy", size: 17)).lineLimit(1)
            .minimumScaleFactor(0.7)
          Text(hero.id < 3 ? "DAWN  /  GOLD" : "ECLIPSE  /  GOLD")
            .font(.custom("AvenirNextCondensed-Medium", size: 8)).foregroundStyle(hero.color)
            .tracking(1)
          HStack(spacing: 2) {
            ForEach(0..<7) { i in
              Rectangle().fill(i < hero.hp / 22 ? hero.color : .white.opacity(0.1)).frame(height: 3)
            }
          }
          Text("HP \(hero.hp)").font(.custom("AvenirNextCondensed-DemiBold", size: 9))
            .foregroundStyle(.gray)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(7).background(
          Color(hex: 0x101620))
      }
      .frame(width: 113)
      .overlay(
        Rectangle().stroke(
          selected != nil ? hero.color : Color.white.opacity(0.25),
          lineWidth: selected != nil ? 2 : 1)
      )
      .opacity(game.selected.count == 3 && selected == nil ? 0.55 : 1)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      "\(hero.name), \(hero.trait), \(selected == nil ? "not selected" : "selected")"
    )
    .accessibilityIdentifier("hero-\(hero.id)")
  }

  private var connectionPanel: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("02").foregroundStyle(Color.titanGold)
        Text("ENTER THE ARENA").tracking(2)
      }.font(.custom("AvenirNextCondensed-Bold", size: 16))
      if let room = game.room {
        VStack(alignment: .leading, spacing: 4) {
          Text("ROOM CODE").font(.custom("AvenirNextCondensed-Bold", size: 12)).foregroundStyle(
            .gray)
          Text(room.code).font(.custom("AvenirNextCondensed-Heavy", size: 32)).tracking(6)
            .foregroundStyle(Color.titanGold).accessibilityIdentifier("room-code")
        }
        ForEach(room.players) { p in
          HStack {
            Circle().fill(p.connected ? Color.green : .red).frame(width: 6, height: 6)
            Text(p.name).lineLimit(1)
            Spacer()
            Text(p.ready ? "READY" : "SELECTING").foregroundStyle(p.ready ? .green : .gray)
          }.font(.custom("AvenirNextCondensed-Bold", size: 13))
        }
        if room.players.count == 1 {
          Text("Share this code with your rival.\nBoth devices use the same server.")
            .font(.custom("AvenirNextCondensed-Regular", size: 14)).foregroundStyle(.gray)
        }
        Spacer(minLength: 0)
        Button {
          game.sendInput("ready")
        } label: {
          Text(game.me?.ready == true ? "CANCEL READY" : "LOCK TEAM / READY").frame(
            maxWidth: .infinity)
        }.buttonStyle(ArcadeButton()).disabled(game.selected.count != 3)
          .accessibilityIdentifier("ready")
        Button {
          game.leave()
        } label: {
          Text("LEAVE ROOM").frame(maxWidth: .infinity)
        }
        .buttonStyle(ArcadeButton(color: .white.opacity(0.7))).accessibilityIdentifier("leave")
      } else {
        field("GUEST NAME", text: $game.guest, id: "guest")
        field("SERVER ADDRESS", text: $game.address, id: "server")
        HStack(spacing: 10) {
          field("ROOM CODE", text: $game.roomCode, id: "room-input")
          Button {
            game.connect(create: false)
          } label: {
            Text("JOIN")
          }
          .buttonStyle(ArcadeButton(color: .white))
          .disabled(game.roomCode.isEmpty || game.connecting || game.selected.count != 3)
          .accessibilityIdentifier("join")
        }
        Button {
          game.connect(create: true)
        } label: {
          Text(game.connecting ? "CONNECTING…" : "CREATE ROOM").frame(maxWidth: .infinity)
        }
        .buttonStyle(ArcadeButton()).disabled(game.connecting || game.selected.count != 3)
        .accessibilityIdentifier("create")
        Text("2 HUMAN PLAYERS  /  NO ACCOUNT REQUIRED")
          .font(.custom("AvenirNextCondensed-Medium", size: 10)).foregroundStyle(.gray).tracking(
            0.5)
      }
    }
    .padding(16)
    .frame(width: 278, height: 345)
    .modifier(MetalPanel())
  }

  private func field(_ label: String, text: Binding<String>, id: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label).font(.custom("AvenirNextCondensed-DemiBold", size: 10)).tracking(1)
        .foregroundStyle(.gray)
      TextField(label, text: text)
        .font(.custom("AvenirNextCondensed-Medium", size: 15))
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .padding(8).background(.black.opacity(0.5))
        .overlay(Rectangle().stroke(.white.opacity(0.15)))
        .accessibilityIdentifier(id)
    }
  }

  private var battle: some View {
    ZStack {
      SpriteView(scene: game.scene, preferredFramesPerSecond: 30, options: [.ignoresSiblingOrder])
      VStack(spacing: 0) {
        HStack(alignment: .top, spacing: 20) {
          if let p = game.room?.players.first { fighterHUD(p, right: false) }
          VStack(spacing: 0) {
            Text("TITAN").font(.custom("AvenirNextCondensed-Heavy", size: 13)).tracking(4)
            Text("\(Int(ceil(game.room?.remaining ?? 120)))")
              .font(.custom("AvenirNextCondensed-Heavy", size: 37)).monospacedDigit()
            Text("ROUND \(game.room?.round ?? 1)").font(
              .custom("AvenirNextCondensed-Bold", size: 10)
            ).tracking(1)
          }.frame(width: 100).foregroundStyle(.white)
          if let p = game.room?.players.last, game.room?.players.count == 2 {
            fighterHUD(p, right: true)
          }
        }
        .padding(.horizontal, 40).padding(.top, 17).padding(.bottom, 12)
        .background(
          LinearGradient(
            colors: [.black.opacity(0.95), .black.opacity(0)], startPoint: .top, endPoint: .bottom))
        HStack {
          Text("MERIDIAN CITY  /  THE ECLIPSE").tracking(2)
          Spacer()
          Text("ROOM \(game.roomCode)  •  \(game.playerID.prefix(8))").tracking(1)
        }.font(.custom("AvenirNextCondensed-DemiBold", size: 10)).foregroundStyle(
          .white.opacity(0.6)
        ).padding(.horizontal, 42)
        Spacer()
        if game.automated {
          Text("AUTOMATED INPUT DRIVER: \(game.driver.uppercased())  /  LIVE WEBSOCKET COMBAT")
            .font(.custom("AvenirNextCondensed-Bold", size: 10)).tracking(1)
            .foregroundStyle(Color.titanGold).padding(5).background(.black.opacity(0.75))
        }
        controls
      }
      if game.room?.phase == "countdown" { countdown }
      if game.room?.phase == "result" { results }
      if !game.connected || game.room?.players.contains(where: { !$0.connected }) == true {
        VStack(spacing: 16) {
          Text("CONNECTION INTERRUPTED").font(.custom("AvenirNextCondensed-Heavy", size: 30))
          Text("Match clock paused. Your team is reserved for 60 seconds.")
            .font(.custom("AvenirNextCondensed-Medium", size: 17))
          HStack {
            Button("RECONNECT") { game.reconnect() }.buttonStyle(ArcadeButton())
              .accessibilityIdentifier("reconnect")
            Button("RETURN TO COLLECTION") { game.leave() }.buttonStyle(ArcadeButton(color: .white))
          }
        }.padding(30).background(.black.opacity(0.96)).overlay(Rectangle().stroke(Color.titanGold))
      }
    }
  }

  private func fighterHUD(_ peer: Peer, right: Bool) -> some View {
    VStack(alignment: right ? .trailing : .leading, spacing: 4) {
      HStack {
        Text(peer.name.uppercased()).foregroundStyle(
          peer.id == game.playerID ? Color.titanGold : .white)
        if peer.id == game.playerID {
          Text("YOU").foregroundStyle(Color.titanGold).font(
            .custom("AvenirNextCondensed-Bold", size: 10))
        }
        Spacer()
        Text(peer.hero.name).foregroundStyle(peer.hero.color)
      }.font(.custom("AvenirNextCondensed-Heavy", size: 17)).tracking(1)
      GeometryReader { geometry in
        ZStack(alignment: right ? .trailing : .leading) {
          Rectangle().fill(.black.opacity(0.9))
          Rectangle().fill(
            LinearGradient(
              colors: [peer.hero.color, .white.opacity(0.9)], startPoint: .leading,
              endPoint: .trailing)
          )
          .frame(width: geometry.size.width * CGFloat(peer.hp[peer.active]) / CGFloat(peer.hero.hp))
          Text("\(peer.hp[peer.active]) / \(peer.hero.hp)").font(
            .custom("AvenirNextCondensed-Heavy", size: 11)
          )
          .foregroundStyle(.black).frame(maxWidth: .infinity)
        }.overlay(Rectangle().stroke(.white.opacity(0.6)))
      }.frame(height: 17)
      HStack(spacing: 3) {
        ForEach(0..<3) { meter in
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Rectangle().fill(Color(hex: 0x18222F))
              Rectangle().fill(peer.hero.color)
                .frame(
                  width: geo.size.width
                    * CGFloat(max(0, min(100, peer.power[peer.active] - meter * 100))) / 100)
            }.overlay(Rectangle().stroke(peer.hero.color.opacity(0.4)))
          }.frame(height: 5)
        }
      }
      HStack(spacing: 5) {
        ForEach(0..<3) { slot in
          let hero = Hero.all[peer.team[slot]]
          HStack(spacing: 3) {
            Image(uiImage: GameArt.image("heroes-\(hero.id)")).resizable().scaledToFill().frame(
              width: 28, height: 27
            )
            .clipped()
            VStack(alignment: .leading, spacing: 2) {
              Text(hero.name).font(.custom("AvenirNextCondensed-Bold", size: 9))
              Rectangle().fill(peer.hp[slot] > 0 ? hero.color : .gray).frame(
                width: max(0, 40 * CGFloat(peer.hp[slot]) / CGFloat(hero.hp)), height: 2)
            }
          }
          .frame(width: 93, height: 29)
          .background(peer.active == slot ? hero.color.opacity(0.25) : .black.opacity(0.65))
          .overlay(Rectangle().stroke(peer.active == slot ? hero.color : .white.opacity(0.2)))
          .opacity(peer.hp[slot] > 0 ? 1 : 0.3)
        }
        Spacer(minLength: 0)
      }
    }.frame(maxWidth: .infinity)
  }

  private var controls: some View {
    HStack(alignment: .bottom, spacing: 12) {
      VStack(alignment: .leading, spacing: 5) {
        Text("TAG TEAM  /  5s COOLDOWN").font(.custom("AvenirNextCondensed-Bold", size: 10))
          .tracking(1).foregroundStyle(.gray)
        HStack(spacing: 5) {
          if let me = game.me {
            ForEach(0..<3) { slot in
              let hero = Hero.all[me.team[slot]]
              Button {
                game.sendInput("tag", slot: slot)
              } label: {
                VStack(spacing: 0) {
                  Image(uiImage: GameArt.image("heroes-\(hero.id)")).resizable().scaledToFit()
                    .frame(width: 56, height: 44)
                  Text(hero.name).font(.custom("AvenirNextCondensed-Heavy", size: 9))
                }.frame(width: 75, height: 61)
                  .background(hero.color.opacity(slot == me.active ? 0.28 : 0.07))
                  .overlay(Rectangle().stroke(hero.color.opacity(me.hp[slot] > 0 ? 0.7 : 0.1)))
              }.buttonStyle(.plain)
                .disabled(
                  !game.fighting || slot == me.active || me.hp[slot] <= 0
                    || (game.room?.time ?? 0) - me.lastTag < 5000
                )
                .accessibilityIdentifier("tag-\(slot)")
            }
          }
        }
      }
      Spacer(minLength: 0)
      VStack(spacing: 5) {
        Text(game.me?.action.uppercased() ?? "READY").font(
          .custom("AvenirNextCondensed-Bold", size: 10)
        ).tracking(1)
          .foregroundStyle(Color.titanGold).accessibilityIdentifier("action-state")
        Button {
          game.showGuide = true
        } label: {
          Image(systemName: "questionmark.circle")
        }
        .buttonStyle(.plain).foregroundStyle(.gray)
        Button {
          game.toggleAudio()
        } label: {
          Image(systemName: game.soundEnabled ? "speaker.wave.2" : "speaker.slash")
        }
        .buttonStyle(.plain).foregroundStyle(.gray)
      }.frame(width: 45)
      control(
        "QUICK", detail: "FAST / INTERRUPT", icon: "bolt.fill", color: Color(hex: 0xFA696F),
        id: "quick"
      ) {
        game.sendInput("quick")
      }
      control(
        "STRONG", detail: "HEAVY / WINDUP", icon: "burst.fill", color: Color(hex: 0x69ACF4),
        id: "strong"
      ) {
        game.sendInput("strong")
      }
      VStack(spacing: 3) {
        Image(systemName: "shield.lefthalf.filled").font(.system(size: 24, weight: .bold))
        Text("BLOCK").font(.custom("AvenirNextCondensed-Heavy", size: 18)).tracking(1)
        Text("HOLD / TAP TO PARRY").font(.custom("AvenirNextCondensed-Medium", size: 8)).tracking(
          0.5)
      }
      .frame(width: 130, height: 76)
      .foregroundStyle(.white)
      .background(game.me?.blocking == true ? .white.opacity(0.35) : Color(hex: 0x202A36))
      .overlay(Rectangle().stroke(.white.opacity(0.7), lineWidth: 1))
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0).onChanged { _ in if game.fighting { game.block(true) } }
          .onEnded { _ in game.block(false) }
      )
      .accessibilityElement(children: .ignore).accessibilityLabel("Hold block")
      .accessibilityIdentifier("block")
      .accessibilityAddTraits(.isButton)
      .accessibilityAction {
        game.block(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { game.block(false) }
      }
      VStack(spacing: 3) {
        Button {
          game.sendInput("special")
        } label: {
          VStack(spacing: 3) {
            Image(systemName: "sparkles").font(.system(size: 22, weight: .bold))
            Text(game.me?.attack?.kind == "special" ? "AMPLIFY!" : "SPECIAL").font(
              .custom("AvenirNextCondensed-Heavy", size: 20)
            ).tracking(2)
            Text(specialDetail).font(.custom("AvenirNextCondensed-Bold", size: 9)).tracking(1)
          }.frame(width: 160, height: 76)
            .foregroundStyle(Color.titanGold)
            .background(
              LinearGradient(
                colors: [Color(hex: 0x544125), Color(hex: 0x171511)], startPoint: .top,
                endPoint: .bottom)
            )
            .overlay(Rectangle().stroke(Color.titanGold, lineWidth: 2))
        }.buttonStyle(.plain).disabled(!game.fighting).accessibilityIdentifier("special")
      }
    }
    .padding(.horizontal, 40).padding(.top, 15).padding(.bottom, 24)
    .background(
      LinearGradient(
        colors: [.black.opacity(0), .black.opacity(0.98)], startPoint: .top, endPoint: .bottom))
  }

  private var specialDetail: String {
    guard let me = game.me else { return "BUILD POWER" }
    if let attack = me.attack, attack.kind == "special" {
      return "BONUS \(attack.mash * 2)  /  KEEP TAPPING"
    }
    let tier = me.power[me.active] / 100
    return tier == 0 ? "BUILD POWER \(me.power[me.active]) / 100" : "TIER \(tier) READY"
  }

  private func control(
    _ title: String, detail: String, icon: String, color: Color, id: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(spacing: 3) {
        Image(systemName: icon).font(.system(size: 24, weight: .bold))
        Text(title).font(.custom("AvenirNextCondensed-Heavy", size: 18)).tracking(1)
        Text(detail).font(.custom("AvenirNextCondensed-Medium", size: 8)).tracking(0.5)
      }.frame(width: 130, height: 76).foregroundStyle(color)
        .background(
          LinearGradient(
            colors: [color.opacity(0.25), Color(hex: 0x10141B)], startPoint: .top, endPoint: .bottom
          )
        )
        .overlay(Rectangle().stroke(color, lineWidth: 1))
    }.buttonStyle(.plain).disabled(!game.fighting).accessibilityIdentifier(id)
  }

  private var countdown: some View {
    VStack(spacing: 8) {
      Text("THE CITY NEEDS A CHAMPION").font(.custom("AvenirNextCondensed-Heavy", size: 18))
        .tracking(3)
      Text("\(max(1, Int(ceil(((game.room?.startedAt ?? 0) - (game.room?.time ?? 0)) / 1000))))")
        .font(.custom("AvenirNextCondensed-HeavyItalic", size: 90)).foregroundStyle(Color.titanGold)
    }.shadow(color: .black, radius: 10)
  }

  private var results: some View {
    let won = game.room?.winner == game.playerID
    let draw = game.room?.winner == "draw"
    return ZStack {
      Color.black.opacity(0.76)
      HStack(spacing: 30) {
        if let me = game.me {
          HStack(spacing: -70) {
            ForEach(me.team, id: \.self) { hero in
              Image(uiImage: GameArt.image("heroes-\(hero)")).resizable().scaledToFit().frame(
                width: 200, height: 290
              )
              .shadow(color: Hero.all[hero].color.opacity(0.5), radius: 20)
            }
          }.frame(width: 390)
        }
        VStack(alignment: .leading, spacing: 12) {
          Text("MERIDIAN CITY / MATCH COMPLETE").font(.custom("AvenirNextCondensed-Bold", size: 12))
            .tracking(2).foregroundStyle(.gray)
          Text(draw ? "STALEMATE" : won ? "VICTORY" : "DEFEAT")
            .font(.custom("AvenirNextCondensed-HeavyItalic", size: 64)).tracking(4)
            .foregroundStyle(won ? Color.titanGold : .white).accessibilityIdentifier("result-title")
          Text(
            draw
              ? "THE CITY WAITS FOR ITS CHAMPION."
              : won ? "YOUR ALLIANCE STANDS ABOVE THE RUINS." : "EVERY LEGEND RISES AGAIN."
          )
          .font(.custom("AvenirNextCondensed-DemiBold", size: 14)).tracking(1)
          if let me = game.me {
            HStack(spacing: 26) {
              resultStat("\(me.damage)", "DAMAGE")
              resultStat("\(me.blocks)", "GUARDS")
              resultStat("\(me.specials)", "SPECIALS")
              resultStat("\(me.tags)", "TAGS")
            }.padding(.vertical, 10)
          }
          HStack {
            Button {
              game.sendInput("rematch")
            } label: {
              Text(game.me?.rematch == true ? "WAITING FOR RIVAL…" : "REMATCH")
            }.buttonStyle(ArcadeButton()).disabled(game.me?.rematch == true)
              .accessibilityIdentifier("rematch")
            Button {
              game.leave()
            } label: {
              Text("COLLECTION")
            }.buttonStyle(ArcadeButton(color: .white))
          }
          Text("Both players must accept. Teams are retained; all meters reset.")
            .font(.custom("AvenirNextCondensed-Regular", size: 12)).foregroundStyle(.gray)
          if game.automated {
            Text("AUTOMATED DRIVER • SHARED SERVER RESULT")
              .font(.custom("AvenirNextCondensed-Bold", size: 11)).foregroundStyle(Color.titanGold)
          }
        }
      }.padding(30).background(Color(hex: 0x0A0F17).opacity(0.85))
        .overlay(Rectangle().stroke(.white.opacity(0.2)))
    }
  }

  private func resultStat(_ value: String, _ title: String) -> some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(value).font(.custom("AvenirNextCondensed-Heavy", size: 28)).foregroundStyle(
        Color.titanGold)
      Text(title).font(.custom("AvenirNextCondensed-DemiBold", size: 10)).tracking(1)
        .foregroundStyle(.gray)
    }
  }

  private var guide: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        HStack {
          Text("COMBAT FIELD MANUAL").font(.custom("AvenirNextCondensed-Heavy", size: 30))
          Spacer()
          Button("DONE") { game.showGuide = false }.buttonStyle(ArcadeButton())
        }
        Text("Three cards. Two human players. One surviving team.").foregroundStyle(Color.titanGold)
        ForEach(
          [
            ("QUICK", "Fast startup, low damage. Interrupt a rival winding up a strong attack."),
            ("STRONG", "High damage with a visible windup. Wait for the rival's recovery."),
            (
              "BLOCK",
              "Hold to absorb most damage. Start within 200 ms of impact to parry a normal strike."
            ),
            (
              "SPECIAL",
              "Power fills when fighting. Spend 1–3 segments; tap repeatedly during the cinematic to amplify."
            ),
            (
              "TAG",
              "Tap a reserve portrait to switch. Five-second cooldown; each hero retains health and power."
            ),
            (
              "WIN",
              "Defeat all three rival heroes. At 120 seconds, the highest remaining team health fraction wins."
            ),
          ], id: \.0
        ) { title, body in
          HStack(alignment: .top) {
            Text(title).frame(width: 80, alignment: .leading).foregroundStyle(Color.titanGold)
              .bold()
            Text(body)
          }.font(.custom("AvenirNextCondensed-Medium", size: 17))
        }
        Text(
          "LAN PLAY: run the included server, enter ws://YOUR-MAC-IP:8793 on both devices, create a room and share its code. No AI opponent is substituted."
        )
        .font(.custom("AvenirNextCondensed-Medium", size: 14)).foregroundStyle(.gray)
      }.fixedSize(horizontal: false, vertical: true).padding(30)
    }.background(Color(hex: 0x101722))
  }
}
