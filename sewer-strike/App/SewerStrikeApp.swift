import SwiftUI

@main
struct SewerStrikeApp: App {
  var body: some Scene {
    WindowGroup { GameScreen().preferredColorScheme(.dark) }
  }
}

struct GameScreen: View {
  @StateObject private var client = GameClient()
  @State private var menu = false
  @State private var help = false
  @State private var muted = false
  private let lime = Color(red: 0.74, green: 1, blue: 0.25)
  var body: some View {
    GeometryReader { geo in
      ZStack {
        WorldView(world: client.world).ignoresSafeArea().accessibilityHidden(true)
        if client.state == nil {
          LinearGradient(
            colors: [.black.opacity(0.85), .black.opacity(0.15), .black.opacity(0.75)],
            startPoint: .leading, endPoint: .trailing
          ).ignoresSafeArea()
          entry(width: geo.size.width)
        } else {
          gameHUD
          if client.state?.phase == "lobby" { lobby }
          if client.state?.phase == "countdown" { countdown }
          if ["clear", "gameover"].contains(client.state?.phase ?? "") { result }
        }
        if menu { menuPanel }
        if help { helpPanel }
        if !client.error.isEmpty {
          VStack {
            Spacer()
            HStack {
              Image(systemName: "wifi.exclamationmark")
              Text(client.error).font(.system(size: 12, weight: .semibold))
              Button("RETRY") { client.retry() }.font(.system(size: 12, weight: .heavy))
              Button {
                client.error = ""
              } label: {
                Image(systemName: "xmark")
              }
            }
            .padding(12).background(Color(red: 0.42, green: 0.06, blue: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 30).padding(.bottom, 4)
          }
        }
      }
      .foregroundStyle(.white)
    }
    .statusBarHidden()
  }
  private func entry(width: CGFloat) -> some View {
    HStack(spacing: 24) {
      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: 7) {
          Capsule().fill(lime).frame(width: 20, height: 3)
          Text("A CO-OP ARCADE ORIGINAL").font(
            .system(size: 10, weight: .heavy, design: .monospaced)
          ).tracking(2)
        }.foregroundStyle(lime)
        Text("SEWER").font(.custom("AvenirNext-HeavyItalic", size: 45)).tracking(-2).lineSpacing(
          -10)
        Text("STRIKE").font(.custom("AvenirNext-HeavyItalic", size: 57)).foregroundStyle(lime)
          .tracking(-3).padding(.top, -20)
          .shadow(color: lime.opacity(0.3), radius: 15, x: 0, y: 3)
        Text("FOUR HEROES. ONE UNDERGROUND.").font(.system(size: 10, weight: .heavy)).tracking(1)
          .foregroundStyle(.white.opacity(0.7))
        HStack(spacing: 7) {
          ForEach(0..<4) { index in
            Button {
              client.hero = index
            } label: {
              VStack(spacing: 3) {
                HeroPortrait(hero: index).frame(width: 43, height: 43)
                  .padding(3)
                  .background(Hero.all[index].color.opacity(client.hero == index ? 0.45 : 0.07))
                  .clipShape(Circle())
                  .overlay(
                    Circle().stroke(
                      client.hero == index ? Hero.all[index].color : .clear, lineWidth: 2))
                Text(Hero.all[index].name).font(.system(size: 8, weight: .heavy))
              }.opacity(client.hero == index ? 1 : 0.5)
            }.buttonStyle(.plain).accessibilityLabel("Select \(Hero.all[index].name)")
          }
        }.padding(.top, 9)
        Text(Hero.all[client.hero].weapon).font(.system(size: 12, weight: .black)).foregroundStyle(
          Hero.all[client.hero].color
        )
        .padding(.top, 5)
        Text(Hero.all[client.hero].role).font(.system(size: 10, weight: .medium)).foregroundStyle(
          .white.opacity(0.7))
        Button("HOW TO PLAY  ↗") { help = true }.font(.system(size: 10, weight: .heavy))
          .foregroundStyle(lime).padding(.top, 7)
      }.frame(maxWidth: .infinity, alignment: .leading)
      VStack(alignment: .leading, spacing: 9) {
        Text("ASSEMBLE YOUR CREW").font(.custom("AvenirNext-HeavyItalic", size: 20))
        Text("2–4 players • real-time LAN co-op").font(.system(size: 10)).foregroundStyle(
          .white.opacity(0.6))
        field("GUEST NAME", text: $client.guest, placeholder: "Your callsign")
        field("SERVER ADDRESS", text: $client.address, placeholder: "ws://192.168.1.5:8767")
        field("ROOM CODE", text: $client.room, placeholder: "Blank creates a new code")
        HStack(spacing: 8) {
          Button {
            client.connect(create: true)
          } label: {
            Text(client.connecting ? "CONNECTING…" : "HOST ROOM").frame(maxWidth: .infinity)
          }.buttonStyle(ArcadeButton(color: lime, darkText: true)).disabled(client.connecting)
            .accessibilityIdentifier("hostRoom")
          Button {
            client.connect(create: false)
          } label: {
            Text("JOIN").frame(maxWidth: .infinity)
          }.buttonStyle(ArcadeButton(color: Color.white.opacity(0.15), darkText: false))
            .disabled(client.connecting || client.room.isEmpty).accessibilityIdentifier("joinRoom")
        }
        Text(
          "Run the included server on your Mac.\nBoth devices use its LAN address and the same room."
        )
        .font(.system(size: 9)).foregroundStyle(.white.opacity(0.45)).lineSpacing(2)
      }
      .padding(18)
      .background(Color(red: 0.035, green: 0.07, blue: 0.12).opacity(0.94))
      .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.14)))
      .clipShape(RoundedRectangle(cornerRadius: 15))
      .frame(width: min(300, width * 0.43))
    }
    .padding(.horizontal, 20).padding(.vertical, 10)
  }
  private func field(_ title: String, text: Binding<String>, placeholder: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(title).font(.system(size: 8, weight: .heavy)).tracking(1).foregroundStyle(
        .white.opacity(0.45))
      TextField(placeholder, text: text)
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(.white.opacity(0.055)).clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel(title)
    }
  }
  private var gameHUD: some View {
    VStack(spacing: 4) {
      HStack(spacing: 5) {
        ForEach(0..<4) { index in
          TeamCard(
            hero: index, player: client.state?.players.first { $0.hero == index },
            localID: client.playerID)
        }
      }.padding(.top, 3)
      HStack(spacing: 9) {
        Text("SEWER STRIKE").font(.custom("AvenirNext-HeavyItalic", size: 10)).foregroundStyle(lime)
        Text("ROOM \(client.room)").font(.system(size: 9, weight: .black, design: .monospaced))
        Circle().fill(client.connected ? lime : .red).frame(width: 4, height: 4)
        Text(client.connected ? "LIVE" : "OFFLINE").font(.system(size: 8, weight: .bold))
          .foregroundStyle(lime)
        Spacer()
        Text("\((client.state?.sector ?? 0) + 1) / 3  \(client.state?.sectorName ?? "")")
          .font(.system(size: 9, weight: .heavy))
        Button {
          menu = true
        } label: {
          Image(systemName: "pause.fill").font(.system(size: 11))
        }
        .accessibilityLabel("Game menu").padding(.leading, 7)
      }
      .padding(.horizontal, 10).padding(.vertical, 6)
      .background(.black.opacity(0.75)).clipShape(Capsule())
      if let boss = client.state?.enemies.first(where: { $0.kind == "boss" }) {
        HStack(spacing: 8) {
          Text("IRON MAW").font(.custom("AvenirNext-HeavyItalic", size: 11))
          Meter(value: Double(boss.hp) / Double(boss.maxHP), color: .red)
            .frame(width: 220, height: 7)
          Text("JUMP THE RED RING").font(.system(size: 8, weight: .black)).foregroundStyle(.orange)
        }.padding(6).background(.black.opacity(0.55)).clipShape(Capsule())
      }
      Spacer()
      if client.state?.phase == "playing" {
        if client.state?.waveClear == true {
          Text("AREA CLEAR   •   MOVE RIGHT  →").font(.custom("AvenirNext-HeavyItalic", size: 18))
            .foregroundStyle(lime).shadow(color: .black, radius: 3)
        }
        if client.me?.hp == 0 {
          Text("DOWN! TEAMMATE: STAY CLOSE TO REVIVE").font(.system(size: 13, weight: .heavy))
            .padding(8).background(.red.opacity(0.8)).clipShape(Capsule())
        }
        controls
      }
      if client.testMode {
        HStack(spacing: 10) {
          Text(client.automation ? client.driverStep : "MANUAL TOUCH • INPUTS \(client.sentInputs)")
            .font(.system(size: 8, weight: .bold, design: .monospaced))
          Spacer()
          if let me = client.me {
            Text(
              "A\(me.stats.attacks) J\(me.stats.jumps) S\(me.stats.specials) D\(me.stats.damage)"
            )
            .font(.system(size: 8, weight: .bold, design: .monospaced)).accessibilityIdentifier(
              "inputStats")
          }
          Button(client.automation ? "TAKE CONTROL" : "AUTO DRIVER") { client.toggleAutomation() }
            .font(.system(size: 8, weight: .black)).foregroundStyle(lime).accessibilityIdentifier(
              "autoToggle")
        }
        .padding(.horizontal, 10).padding(.vertical, 4)
        .background(.black.opacity(0.85)).clipShape(Capsule())
      }
    }
    .padding(.horizontal, 7).padding(.bottom, 5)
  }
  private var controls: some View {
    HStack(alignment: .bottom) {
      DirectionPad { vector in client.move(vector) }
        .opacity(client.automation ? 0.5 : 1)
      Spacer()
      VStack(spacing: 4) {
        Text("\(client.state?.defeated ?? 0) KOs  •  \(Int(client.state?.elapsed ?? 0))s")
          .font(.system(size: 10, weight: .heavy, design: .monospaced))
        Text("ENEMIES: SERVER AI").font(.system(size: 7, weight: .heavy)).foregroundStyle(
          .white.opacity(0.65))
        Text("COMBO • COMBO • FINISHER").font(.system(size: 8, weight: .bold)).foregroundStyle(lime)
      }.padding(.bottom, 8).shadow(color: .black, radius: 3)
      Spacer()
      HStack(alignment: .bottom, spacing: 8) {
        actionButton("JUMP", icon: "arrow.up", color: .white, diameter: 52) {
          client.action("jump")
        }
        .padding(.bottom, 10).accessibilityIdentifier("jump")
        actionButton(
          "STRIKE", icon: "burst.fill", color: Hero.all[client.me?.hero ?? client.hero].color,
          diameter: 70
        ) {
          client.action("attack")
        }.accessibilityIdentifier("strike")
        actionButton("POWER", icon: "bolt.fill", color: lime, diameter: 59) {
          client.action("special")
        }
        .opacity((client.me?.power ?? 0) >= 50 ? 1 : 0.35)
        .overlay(alignment: .top) {
          Text("\(client.me?.power ?? 0)%").font(.system(size: 8, weight: .black)).offset(y: -12)
        }
        .padding(.bottom, 17).accessibilityIdentifier("special")
      }.opacity(client.automation ? 0.65 : 1)
    }
  }
  private func actionButton(
    _ title: String, icon: String, color: Color, diameter: CGFloat,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(spacing: 2) {
        Image(systemName: icon).font(.system(size: diameter / 3.5, weight: .black))
        Text(title).font(.system(size: 8, weight: .black)).tracking(0.5)
      }
      .foregroundStyle(color)
      .frame(width: diameter, height: diameter)
      .background(Color.black.opacity(0.6))
      .background(color.opacity(0.2))
      .clipShape(Circle())
      .overlay(Circle().stroke(color.opacity(0.8), lineWidth: 2))
      .shadow(color: color.opacity(0.25), radius: 9)
    }.buttonStyle(.plain).accessibilityLabel(title)
  }
  private var lobby: some View {
    VStack(spacing: 8) {
      Text("CREW CHECK").font(.custom("AvenirNext-HeavyItalic", size: 31)).foregroundStyle(lime)
      Text("ROOM  \(client.room)").font(.system(size: 18, weight: .black, design: .monospaced))
        .tracking(5)
      Text("Share this code. Pick a different hero on the second device.")
        .font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
      HStack(spacing: 18) {
        ForEach(client.state?.players ?? []) { player in
          HStack(spacing: 6) {
            Circle().fill(player.ready ? lime : .orange).frame(width: 6, height: 6)
            Text("\(player.name)  \(player.ready ? "READY" : "WAITING")")
              .font(.system(size: 11, weight: .heavy)).foregroundStyle(Hero.all[player.hero].color)
          }
        }
      }
      Button(client.me?.ready == true ? "READY • TAP TO CANCEL" : "READY UP") { client.ready() }
        .buttonStyle(ArcadeButton(color: lime, darkText: true)).accessibilityIdentifier("ready")
      Text("Match starts when at least two connected heroes are ready.")
        .font(.system(size: 9)).foregroundStyle(.white.opacity(0.5))
    }.padding(22).background(.black.opacity(0.87)).clipShape(RoundedRectangle(cornerRadius: 20))
      .overlay(RoundedRectangle(cornerRadius: 20).stroke(lime.opacity(0.35)))
      .padding(.top, 70)
  }
  private var countdown: some View {
    VStack(spacing: 0) {
      Text("CREW ASSEMBLED").font(.custom("AvenirNext-HeavyItalic", size: 24)).foregroundStyle(lime)
      Text(
        "\(max(1, Int(ceil(Double((client.state?.startAt ?? 0) - (client.state?.tick ?? 0)) / 30))))"
      )
      .font(.custom("AvenirNext-HeavyItalic", size: 90))
      Text("LET'S CLEAN THESE STREETS.").font(.system(size: 12, weight: .heavy))
    }.shadow(color: .black, radius: 5)
  }
  private var result: some View {
    VStack(spacing: 8) {
      Text(client.state?.phase == "clear" ? "STAGE CLEAR!" : "CREW DOWN")
        .font(.custom("AvenirNext-HeavyItalic", size: 37))
        .foregroundStyle(client.state?.phase == "clear" ? lime : .red)
        .accessibilityIdentifier("resultTitle")
      Text(
        client.state?.phase == "clear"
          ? "IRON MAW IS SCRAP. THE CITY IS YOURS." : "REGROUP. RECHARGE. STRIKE AGAIN."
      )
      .font(.system(size: 10, weight: .heavy)).tracking(1)
      HStack(spacing: 20) {
        ForEach(client.state?.players ?? []) { p in
          VStack(spacing: 3) {
            HeroPortrait(hero: p.hero).frame(width: 42, height: 42)
            Text(p.name.uppercased()).font(.system(size: 11, weight: .black)).foregroundStyle(
              Hero.all[p.hero].color)
            Text("\(p.score)").font(.custom("AvenirNext-HeavyItalic", size: 22))
            Text("\(p.stats.damage) DAMAGE • \(p.hits) HITS").font(.system(size: 8, weight: .heavy))
          }
        }
      }
      Text(
        "\(client.state?.defeated ?? 0) ENEMIES DEFEATED  •  \(Int(client.state?.elapsed ?? 0)) SECONDS"
      )
      .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(
        .white.opacity(0.7))
      HStack {
        Button(client.me?.rematch == true ? "WAITING FOR CREW…" : "REMATCH") { client.rematch() }
          .buttonStyle(ArcadeButton(color: lime, darkText: true)).accessibilityIdentifier("rematch")
        Button("LEAVE") { client.leave() }.buttonStyle(
          ArcadeButton(color: .white.opacity(0.15), darkText: false))
      }
    }.padding(20).background(Color(red: 0.035, green: 0.065, blue: 0.10).opacity(0.97))
      .clipShape(RoundedRectangle(cornerRadius: 20))
      .overlay(RoundedRectangle(cornerRadius: 20).stroke(lime.opacity(0.5)))
      .padding(.top, 55)
  }
  private var menuPanel: some View {
    ZStack {
      Color.black.opacity(0.7).ignoresSafeArea()
      VStack(spacing: 12) {
        Text("CREW CHANNEL").font(.custom("AvenirNext-HeavyItalic", size: 26)).foregroundStyle(lime)
        Text("The network match keeps running.").font(.system(size: 11))
        Button("BACK TO ACTION") { menu = false }.buttonStyle(
          ArcadeButton(color: lime, darkText: true))
        Button(muted ? "SOUND: OFF" : "SOUND: ON") {
          muted.toggle()
          client.audio.muted = muted
        }
        Button("RECONNECT SAME HERO") {
          menu = false
          client.reconnectTest()
        }.accessibilityIdentifier("reconnect")
        Button("HOW TO PLAY") {
          menu = false
          help = true
        }
        Button("LEAVE ROOM") {
          menu = false
          client.leave()
        }
      }.font(.system(size: 12, weight: .heavy)).padding(25).background(
        Color(red: 0.04, green: 0.09, blue: 0.14)
      )
      .clipShape(RoundedRectangle(cornerRadius: 18))
    }
  }
  private var helpPanel: some View {
    ZStack {
      Color.black.opacity(0.9).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 9) {
        Text("STREET RULES").font(.custom("AvenirNext-HeavyItalic", size: 29)).foregroundStyle(lime)
        Text("MOVE   Hold the arrows to move along the street or switch lanes.")
        Text("STRIKE   Face an enemy. Chain three attacks for a heavy finisher.")
        Text("JUMP   Dodge ground slams. Strike in the air for a diving attack.")
        Text("POWER   Spend 50 charge for an invincible area attack. Hits recharge it.")
        Text("TEAM UP   Stay near a fallen friend for 2.5s to revive. Collect slices to heal.")
        Text("ADVANCE   Both heroes move right after each wave. Defeat Iron Maw to win.")
        Text("Four heroes: balanced sabers / fast batons / long staff / heavy prongs.")
          .foregroundStyle(lime)
        Button("GOT IT") { help = false }.buttonStyle(ArcadeButton(color: lime, darkText: true))
      }.font(.system(size: 12, weight: .semibold)).padding(20)
    }
  }
}

struct ArcadeButton: ButtonStyle {
  let color: Color
  let darkText: Bool
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.font(.system(size: 11, weight: .black))
      .padding(.horizontal, 17).padding(.vertical, 11)
      .foregroundStyle(darkText ? Color.black : .white)
      .background(color).clipShape(RoundedRectangle(cornerRadius: 7))
      .scaleEffect(configuration.isPressed ? 0.96 : 1)
  }
}

struct TeamCard: View {
  let hero: Int
  let player: PlayerState?
  let localID: String
  var body: some View {
    let color = Hero.all[hero].color
    HStack(spacing: 4) {
      HeroPortrait(hero: hero)
        .frame(width: 43, height: 48)
        .overlay(alignment: .bottom) {
          if player?.id == localID {
            Text("YOU").font(.system(size: 7, weight: .black)).padding(.horizontal, 4)
              .background(color).foregroundStyle(.black).clipShape(Capsule()).offset(y: 3)
          }
        }
      VStack(alignment: .leading, spacing: 2) {
        Text(Hero.all[hero].name).font(.custom("AvenirNext-HeavyItalic", size: 12))
          .minimumScaleFactor(0.7).lineLimit(1)
        if let player {
          HStack {
            Text("\(player.score)").font(.system(size: 10, weight: .heavy, design: .monospaced))
            Spacer(minLength: 0)
            if player.hits > 0 {
              Text("\(player.hits) HITS").font(.system(size: 7, weight: .black)).foregroundStyle(
                color)
            }
          }
          HStack(spacing: 2) {
            Text("+").font(.system(size: 11, weight: .black))
            Meter(value: Double(player.hp) / 100, color: .red).frame(height: 7)
          }
          Meter(value: Double(player.power) / 100, color: Color(red: 0.62, green: 1, blue: 0.15))
            .frame(height: 5)
          Text(
            player.connected
              ? player.hp == 0 ? "REVIVE \(Int(player.revive / 2.5 * 100))%" : "STRIKE POWER"
              : "RECONNECTING"
          )
          .font(.system(size: 6, weight: .heavy)).foregroundStyle(color)
        } else {
          Text("OPEN SLOT").font(.system(size: 9, weight: .black)).foregroundStyle(color)
          Text("JOIN THE CREW").font(.system(size: 6, weight: .heavy)).foregroundStyle(
            .white.opacity(0.5))
          Rectangle().fill(.white.opacity(0.15)).frame(height: 5)
        }
      }
    }
    .padding(.horizontal, 5).padding(.vertical, 5)
    .frame(maxWidth: .infinity, minHeight: 60)
    .background(
      LinearGradient(
        colors: [color.opacity(0.5), Color.black.opacity(0.92)], startPoint: .topLeading,
        endPoint: .bottomTrailing)
    )
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .overlay(
      RoundedRectangle(cornerRadius: 10).stroke(
        color.opacity(player == nil ? 0.3 : 0.9), lineWidth: 1)
    )
    .opacity(player == nil ? 0.55 : 1)
  }
}

struct Meter: View {
  let value: Double
  let color: Color
  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule().fill(.black.opacity(0.8))
        Capsule().fill(
          LinearGradient(colors: [color.opacity(0.65), color], startPoint: .bottom, endPoint: .top)
        )
        .frame(width: max(0, geo.size.width * min(1, value)))
        Capsule().stroke(.white.opacity(0.35), lineWidth: 0.6)
      }
    }
  }
}

struct HeroPortrait: View {
  let hero: Int
  var body: some View {
    GeometryReader { geo in
      let size = geo.size.width
      ZStack {
        Circle().fill(Hero.all[hero].color.opacity(0.25))
        Ellipse().fill(Color(red: 0.30, green: 0.60, blue: 0.17))
          .frame(width: size * 0.8, height: size * 0.88)
        Ellipse().fill(Color(red: 0.44, green: 0.76, blue: 0.22))
          .frame(width: size * 0.76, height: size * 0.48).offset(y: size * 0.16)
        RoundedRectangle(cornerRadius: size * 0.1).fill(Hero.all[hero].color)
          .frame(width: size * 0.88, height: size * 0.24).rotationEffect(.degrees(-7)).offset(
            y: -size * 0.06)
        HStack(spacing: size * 0.12) {
          ForEach(0..<2) { index in
            ZStack {
              Ellipse().fill(.white).frame(width: size * 0.18, height: size * 0.12)
              Ellipse().fill(.black).frame(width: size * 0.065, height: size * 0.10).offset(
                x: size * 0.025)
            }.rotationEffect(.degrees(index == 0 ? -12 : 8))
          }
        }.offset(y: -size * 0.06)
        RoundedRectangle(cornerRadius: 3).fill(.white).frame(
          width: size * 0.36, height: size * 0.06
        )
        .rotationEffect(.degrees(-9)).offset(x: size * 0.05, y: size * 0.21)
      }
    }
  }
}

struct DirectionPad: View {
  let changed: (CGVector) -> Void
  @State private var vector = CGVector.zero
  var body: some View {
    ZStack {
      Circle().fill(.black.opacity(0.48)).frame(width: 100, height: 100)
        .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 1))
      Image(systemName: "circle.fill").font(.system(size: 18)).foregroundStyle(.white.opacity(0.2))
      arrow("chevron.left", "Move left", x: -33, y: 0, vector: CGVector(dx: -1, dy: 0))
      arrow("chevron.right", "Move right", x: 33, y: 0, vector: CGVector(dx: 1, dy: 0))
      arrow("chevron.up", "Move up", x: 0, y: -33, vector: CGVector(dx: 0, dy: -1))
      arrow("chevron.down", "Move down", x: 0, y: 33, vector: CGVector(dx: 0, dy: 1))
    }.frame(width: 108, height: 108)
  }
  private func arrow(_ symbol: String, _ name: String, x: CGFloat, y: CGFloat, vector: CGVector)
    -> some View
  {
    Image(systemName: symbol).font(.system(size: 19, weight: .heavy)).foregroundStyle(
      .white.opacity(0.8)
    )
    .frame(width: 37, height: 37).background(.white.opacity(self.vector == vector ? 0.25 : 0.04))
    .clipShape(RoundedRectangle(cornerRadius: 8)).contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 0).onChanged { _ in
        self.vector = vector
        changed(vector)
      }
      .onEnded { _ in
        self.vector = .zero
        changed(.zero)
      }
    )
    .accessibilityElement().accessibilityLabel(name).accessibilityAddTraits(.isButton)
    .accessibilityAction {
      changed(vector)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { changed(.zero) }
    }
    .offset(x: x, y: y)
  }
}
