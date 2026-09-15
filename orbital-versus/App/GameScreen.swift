import SwiftUI

private let cyan = Color(red: 0.25, green: 0.88, blue: 1)
private let orange = Color(red: 1, green: 0.42, blue: 0.29)
private let navy = Color(red: 0.035, green: 0.085, blue: 0.14)

struct CutPanel: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      let cut = min(12, rect.height * 0.2, rect.width * 0.1)
      path.move(to: CGPoint(x: cut, y: 0))
      path.addLine(to: CGPoint(x: rect.width, y: 0))
      path.addLine(to: CGPoint(x: rect.width, y: rect.height - cut))
      path.addLine(to: CGPoint(x: rect.width - cut, y: rect.height))
      path.addLine(to: CGPoint(x: 0, y: rect.height))
      path.addLine(to: CGPoint(x: 0, y: cut))
      path.closeSubpath()
    }
  }
}

struct GameScreen: View {
  @ObservedObject var client: GameClient
  @State private var help = false
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        ArenaView(renderer: client.renderer).ignoresSafeArea()
        if client.state?.phase == "lobby" || client.state == nil {
          lobby(size: geometry.size)
        } else {
          combatHUD(size: geometry.size, insets: geometry.safeAreaInsets)
        }
        if client.hitFlash { Color.red.opacity(0.18).ignoresSafeArea().allowsHitTesting(false) }
        if client.state?.phase == "countdown" {
          VStack(spacing: 0) {
            Text("ALL SYSTEMS ONLINE").font(.system(size: 13, weight: .heavy, design: .monospaced))
              .tracking(5)
            Text("\(max(1, Int(ceil(client.state?.countdown ?? 3))))")
              .font(.system(size: 90, weight: .black, design: .rounded)).italic()
            Text("ROUND \(client.state?.round ?? 1) / LAUNCH SEQUENCE").font(
              .system(size: 12, weight: .bold, design: .monospaced)
            ).tracking(2)
          }
          .foregroundStyle(.white).shadow(color: cyan, radius: 15)
          .allowsHitTesting(false)
        }
        if client.state?.phase == "result" { results }
        if !client.error.isEmpty {
          VStack {
            Spacer()
            HStack {
              Text(client.error).font(.system(size: 12, weight: .bold)).lineLimit(2)
              Button("RECONNECT") { client.reconnect() }.accessibilityIdentifier("RECONNECT")
              Button("DISMISS") { client.error = "" }
            }
            .padding(12).background(navy.opacity(0.97)).overlay(
              Rectangle().stroke(orange, lineWidth: 1))
          }.padding(18)
        }
        if help { helpOverlay }
      }
      .font(.system(size: 12, weight: .semibold, design: .monospaced))
      .foregroundStyle(.white)
    }
  }

  private func lobby(size: CGSize) -> some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Rectangle().fill(cyan).frame(width: 25, height: 3)
          Text("A S T R A L  /  C O M B A T  S Y S T E M S").font(.system(size: 8, weight: .bold))
        }
        VStack(alignment: .leading, spacing: -4) {
          Text("ORBITAL").font(.system(size: 38, weight: .black, design: .rounded)).italic()
          Text("VERSUS").font(.system(size: 38, weight: .black, design: .rounded)).italic()
            .foregroundStyle(cyan)
        }
        Text("2 v 2   /   ORBITAL LAUNCH COMPLEX").font(.system(size: 10, weight: .heavy)).tracking(
          1
        )
        .foregroundStyle(.white.opacity(0.65))
        if client.connected, let state = client.state {
          HStack {
            Text("ROOM").foregroundStyle(cyan)
            Text(client.code).font(.system(size: 21, weight: .black, design: .monospaced))
              .accessibilityIdentifier("roomCode")
            Spacer()
            Text("\(state.units.filter { !$0.ai }.count)/2 PILOTS")
          }.padding(.top, 4)
          ForEach(state.units.filter { !$0.ai }) { pilot in
            HStack {
              Circle().fill(pilot.team == 0 ? cyan : orange).frame(width: 7, height: 7)
              Text(pilot.name).lineLimit(1)
              Spacer()
              Text(state.ready.contains(pilot.id) ? "READY" : "STANDBY").foregroundStyle(
                state.ready.contains(pilot.id) ? cyan : .gray)
            }
          }
          HStack {
            primary(
              state.ready.contains(client.playerID) ? "READY · WAITING" : "READY / SORTIE",
              id: "READY"
            ) { client.ready() }
            Button("LEAVE") { client.leave() }.padding(10)
          }
          Text(
            "Each pilot commands a team with one AI wingman.\nBoth humans must ready before launch."
          )
          .font(.system(size: 10)).foregroundStyle(.white.opacity(0.6))
        } else {
          HStack(spacing: 10) {
            field("CALLSIGN", value: $client.name, id: "pilotName")
            field("ROOM · BLANK = NEW", value: $client.code, id: "roomInput")
          }
          field("SERVER ADDRESS", value: $client.address, id: "serverAddress")
          primary(client.connecting ? "CONNECTING…" : "CONNECT / ENTER HANGAR", id: "CONNECT") {
            client.connect()
          }
          .disabled(client.connecting)
        }
        HStack(spacing: 20) {
          Button("PILOT GUIDE") { help = true }.accessibilityIdentifier("GUIDE")
          Button(client.muted ? "AUDIO OFF" : "AUDIO ON") { client.toggleMute() }
        }.font(.system(size: 10, weight: .bold)).foregroundStyle(cyan)
      }
      .padding(.vertical, 18).padding(.leading, max(28, size.width * 0.055)).padding(.trailing, 24)
      .frame(width: min(size.width * 0.49, 470))
      .frame(maxHeight: .infinity)
      .background(
        LinearGradient(
          colors: [navy.opacity(0.98), navy.opacity(0.91), navy.opacity(0.4)], startPoint: .leading,
          endPoint: .trailing))
      Spacer()
      VStack(alignment: .trailing) {
        Text("OV / 02").font(.system(size: 32, weight: .ultraLight, design: .monospaced))
          .foregroundStyle(.white.opacity(0.5))
        Text("ASTER FRAME").font(.system(size: 10, weight: .black)).tracking(3)
        Spacer()
        Text("MULTIROLE INTERCEPTOR").font(.system(size: 10, weight: .heavy)).tracking(1)
        Text("COST 2000  /  ARMOR 520").foregroundStyle(cyan)
        Text("BEAM RIFLE • PLASMA SABER • PHASE STEP")
          .font(.system(size: 8, weight: .bold)).foregroundStyle(.white.opacity(0.55))
      }.padding(30)
    }
  }

  private func field(_ title: String, value: Binding<String>, id: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(title).font(.system(size: 8, weight: .bold)).foregroundStyle(cyan.opacity(0.85))
      TextField(title, text: value).textInputAutocapitalization(.never).autocorrectionDisabled()
        .font(.system(size: 13, weight: .medium, design: .monospaced))
        .padding(.horizontal, 10).frame(height: 33).background(.black.opacity(0.4))
        .overlay(Rectangle().stroke(.white.opacity(0.2), lineWidth: 1))
        .accessibilityIdentifier(id)
    }
  }
  private func primary(_ title: String, id: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack {
        Text(title).font(.system(size: 12, weight: .black, design: .monospaced)).tracking(1)
        Spacer()
        Image(systemName: "arrow.up.right")
      }.padding(13).foregroundStyle(navy).background(cyan).clipShape(CutPanel())
    }.accessibilityIdentifier(id)
  }

  private func combatHUD(size: CGSize, insets: EdgeInsets) -> some View {
    ZStack {
      VStack {
        HStack(alignment: .top, spacing: 10) {
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text("ORBITAL / VERSUS").font(.system(size: 11, weight: .black)).italic()
              Text("R\(client.state?.round ?? 1)").font(.system(size: 8)).foregroundStyle(cyan)
            }
            costGauge("TEAM", cost: client.state?.costs[client.me?.team ?? 0] ?? 6000, color: cyan)
            costGauge(
              "ENEMY", cost: client.state?.costs[1 - (client.me?.team ?? 0)] ?? 6000, color: orange)
            HStack(spacing: 5) {
              Circle().fill(client.connected ? cyan : orange).frame(width: 5, height: 5)
              Text("\(client.code) / \(client.ping)ms / \(client.state?.tick ?? 0)")
                .font(.system(size: 8, weight: .bold))
              Button {
                client.toggleMute()
              } label: {
                Image(systemName: client.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
              }
            }.foregroundStyle(.white.opacity(0.7))
          }.frame(width: 248)
          Spacer()
          if client.automation {
            VStack(spacing: 3) {
              Text("AUTOMATED INPUT DRIVER").font(.system(size: 8, weight: .black)).foregroundStyle(
                .yellow)
              Text(client.automationStep).font(.system(size: 9, weight: .bold))
              Button("TAKE CONTROL") { client.toggleAutomation() }.font(
                .system(size: 8, weight: .bold)
              )
              .foregroundStyle(cyan).accessibilityIdentifier("TAKE CONTROL")
            }.padding(6).background(navy.opacity(0.85))
          }
          Spacer()
          VStack(alignment: .trailing, spacing: 1) {
            Text(String(format: "%03d", Int(ceil(client.state?.time ?? 90))))
              .font(.system(size: 38, weight: .black, design: .rounded)).italic()
            Text("TIME REMAINING").font(.system(size: 7, weight: .heavy)).tracking(1)
          }
          radar.frame(width: 74, height: 74)
        }
        Spacer()
      }.padding(.top, 13).padding(.horizontal, 30).allowsHitTesting(true)

      if let target = client.target, target.hp > 0, client.state?.phase == "playing" {
        let range = distanceToTarget
        let color = range < 18 ? Color.pink : range < 65 ? orange : Color.green
        ZStack {
          Circle().stroke(color.opacity(0.75), lineWidth: 1).frame(width: 65, height: 65)
          Circle().trim(from: 0.03, to: 0.20).stroke(color, style: StrokeStyle(lineWidth: 3))
            .frame(width: 72, height: 72)
          Image(systemName: "scope").font(.system(size: 45, weight: .ultraLight)).foregroundStyle(
            color)
        }
        .overlay(alignment: .top) {
          VStack(spacing: 2) {
            Text(target.name).font(.system(size: 9, weight: .black)).padding(3).background(
              navy.opacity(0.8))
            Text("\(Int(range))m / \(Int(target.hp)) AP").font(.system(size: 8, weight: .bold))
          }
          .fixedSize().offset(y: 76)
        }
        .position(x: client.reticle.x - insets.leading, y: client.reticle.y - insets.top)
        .allowsHitTesting(false)
      }

      VStack(alignment: .leading, spacing: 3) {
        if client.incoming {
          Text("▲ ENEMY LOCK").font(.system(size: 8, weight: .black)).foregroundStyle(.yellow)
        }
        Text(client.me?.name ?? "PILOT").font(.system(size: 10, weight: .heavy)).tracking(2)
        HStack(alignment: .lastTextBaseline, spacing: 3) {
          Text("\(Int(client.me?.hp ?? 520))").font(
            .system(size: 45, weight: .black, design: .rounded)
          ).italic()
          Text("AP").foregroundStyle(cyan).font(.system(size: 10, weight: .black))
        }
        segmentedGauge(value: (client.me?.hp ?? 520) / 520, color: cyan).frame(
          width: 135, height: 6)
        Text("\(client.wing?.name ?? "AI WING")  \(Int(client.wing?.hp ?? 360))").font(
          .system(size: 8, weight: .bold)
        ).foregroundStyle(cyan)
      }
      .padding(8).background(navy.opacity(0.72)).clipShape(CutPanel())
      .position(x: 100, y: size.height - 197).allowsHitTesting(false)

      Joystick(value: $client.move).frame(width: 122, height: 122)
        .position(x: 115, y: size.height - 80).accessibilityIdentifier("JOYSTICK")
      VStack(spacing: 4) {
        HStack(spacing: 5) {
          Text(
            client.me?.overheated == true
              ? "OVERHEAT / LAND"
              : client.me?.y ?? 0 > 0.3 ? "BOOST / AIRBORNE" : "BOOST / GROUNDED"
          )
          .font(.system(size: 8, weight: .black)).tracking(1)
          Spacer()
          Text("\(Int(client.me?.boost ?? 100))%").font(.system(size: 9, weight: .bold))
        }
        segmentedGauge(
          value: (client.me?.boost ?? 100) / 100,
          color: client.me?.overheated == true ? orange : cyan
        )
        .frame(height: 9)
        HStack {
          Text(client.me?.overdrive ?? 0 > 0 ? "OVERDRIVE ACTIVE" : "EX / OVERDRIVE")
          Spacer()
          Text("\(Int(client.me?.burst ?? 0))%")
        }.font(.system(size: 8, weight: .black)).foregroundStyle(.pink)
        segmentedGauge(value: (client.me?.burst ?? 0) / 100, color: .pink).frame(height: 5)
      }
      .padding(9).background(navy.opacity(0.84)).clipShape(CutPanel())
      .frame(width: max(180, min(280, size.width - 540)))
      .position(x: size.width * 0.48, y: size.height - 44).allowsHitTesting(false)

      VStack(spacing: 7) {
        HStack(spacing: 7) {
          actionButton("LOCK", icon: "scope", color: cyan) { client.press("lock") }
          actionButton("STEP", icon: "arrow.left.and.right", color: cyan) { client.press("dodge") }
          actionButton("EX", icon: "bolt.shield.fill", color: .pink) { client.press("burst") }
        }
        HStack(spacing: 7) {
          HoldControl(
            title: "GUARD", icon: "shield.lefthalf.filled", color: cyan, held: $client.guarding)
          actionButton("SABER", icon: "bolt.slash.fill", color: .pink) { client.press("melee") }
          actionButton(
            "FIRE \(client.me?.ammo ?? 7)", icon: "location.north.fill", color: orange, id: "FIRE"
          ) { client.press("fire") }
        }
        HStack(spacing: 7) {
          HoldControl(title: "BOOST", icon: "flame.fill", color: cyan, held: $client.boosting)
          Text("HOLD TO FLY\nLAND TO RECHARGE").font(.system(size: 7, weight: .bold))
            .foregroundStyle(.white.opacity(0.65))
            .frame(width: 135)
        }
      }
      .position(x: size.width - 141, y: size.height - 104)
      if client.me?.hp == 0 && client.state?.phase == "playing" {
        VStack {
          Text("FRAME LOST").font(.system(size: 29, weight: .black)).italic().foregroundStyle(
            orange)
          Text("REDEPLOY IN \(Int(ceil(client.me?.respawn ?? 0))) · −2000 TEAM COST").font(
            .system(size: 11, weight: .heavy))
        }.padding(18).background(navy.opacity(0.9)).allowsHitTesting(false)
      }
    }
  }
  private var distanceToTarget: Float {
    guard let me = client.me, let target = client.target else { return 0 }
    return sqrt(pow(target.x - me.x, 2) + pow(target.y - me.y, 2) + pow(target.z - me.z, 2))
  }
  private func actionButton(
    _ title: String, icon: String, color: Color, id: String? = nil,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) { controlLabel(title, icon: icon, color: color) }
      .accessibilityIdentifier(id ?? title).accessibilityLabel(id ?? title)
  }
  private func costGauge(_ title: String, cost: Int, color: Color) -> some View {
    HStack(spacing: 5) {
      Text(title).font(.system(size: 8, weight: .heavy)).frame(width: 35, alignment: .leading)
      segmentedGauge(value: Double(cost) / 6000, color: color).frame(height: 9)
      Text(String(cost)).font(.system(size: 11, weight: .black, design: .rounded))
        .monospacedDigit().lineLimit(1).fixedSize().frame(width: 36)
    }.padding(3).background(navy.opacity(0.82)).clipShape(CutPanel())
  }
  private func segmentedGauge(value: Double, color: Color) -> some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Color.black.opacity(0.7)
        color.frame(width: geometry.size.width * max(0, min(1, value)))
        HStack(spacing: 0) {
          ForEach(0..<8) { _ in
            Spacer()
            Rectangle().fill(navy).frame(width: 2)
          }
        }
      }.clipShape(CutPanel())
    }
  }
  private var radar: some View {
    Canvas { context, size in
      let circle = Path(ellipseIn: CGRect(origin: .zero, size: size))
      context.fill(circle, with: .color(navy.opacity(0.9)))
      context.stroke(circle, with: .color(cyan.opacity(0.6)), lineWidth: 1)
      var cross = Path()
      cross.move(to: CGPoint(x: size.width / 2, y: 0))
      cross.addLine(to: CGPoint(x: size.width / 2, y: size.height))
      cross.move(to: CGPoint(x: 0, y: size.height / 2))
      cross.addLine(to: CGPoint(x: size.width, y: size.height / 2))
      context.stroke(cross, with: .color(cyan.opacity(0.2)), lineWidth: 1)
      for unit in client.state?.units ?? [] where unit.hp > 0 {
        let point = CGPoint(
          x: CGFloat(unit.x) / 100 * size.width + size.width / 2,
          y: CGFloat(unit.z) / 100 * size.height + size.height / 2)
        let dot = Path(ellipseIn: CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5))
        context.fill(
          dot,
          with: .color(
            unit.id == client.playerID ? .white : unit.team == client.me?.team ? cyan : orange))
      }
    }.allowsHitTesting(false)
  }
  private var results: some View {
    ZStack {
      navy.opacity(0.78)
      VStack(spacing: 10) {
        Text("BATTLE RECORD / ROUND \(client.state?.round ?? 1)").font(
          .system(size: 9, weight: .bold)
        ).tracking(3)
        Text(
          client.state?.winner == -1
            ? "DRAW" : client.state?.winner == client.me?.team ? "VICTORY" : "DEFEAT"
        )
        .font(.system(size: 48, weight: .black, design: .rounded)).italic()
        .foregroundStyle(client.state?.winner == client.me?.team ? cyan : orange)
        .accessibilityIdentifier("OUTCOME")
        Text(client.state?.reason ?? "").font(.system(size: 10, weight: .heavy)).foregroundStyle(
          .white.opacity(0.65))
        HStack {
          Text("PILOT / FRAME")
          Spacer()
          Text("DAMAGE     KOs     COST")
        }.font(.system(size: 9, weight: .bold)).foregroundStyle(cyan)
        ForEach(client.state?.units ?? []) { unit in
          HStack {
            Text(unit.name + (unit.ai ? " [AI]" : " [HUMAN]")).foregroundStyle(
              unit.team == 0 ? cyan : orange)
            Spacer()
            Text(String(format: "%5d      %d     %4d", unit.damage, unit.kills, unit.cost))
          }.font(.system(size: 11, weight: .bold))
        }
        HStack {
          primary(
            client.state?.rematch.contains(client.playerID) == true
              ? "VOTED / WAITING" : "REMATCH / LAUNCH AGAIN", id: "REMATCH"
          ) { client.rematch() }
          Button("HANGAR") { client.leave() }.padding(12).accessibilityIdentifier("HANGAR")
        }.padding(.top, 5)
        Text("ROOM \(client.code) · BOTH PILOTS MUST VOTE").font(.system(size: 8, weight: .heavy))
          .foregroundStyle(.gray)
      }
      .padding(22).frame(width: 475).background(navy.opacity(0.96)).overlay(
        CutPanel().stroke(cyan.opacity(0.5), lineWidth: 1))
    }
  }
  private var helpOverlay: some View {
    ZStack {
      navy.opacity(0.95)
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("PILOT / FIELD MANUAL").font(.system(size: 22, weight: .black)).italic()
          Spacer()
          Button("CLOSE") { help = false }.foregroundStyle(cyan)
        }
        Text("DESTROY THE ENEMY TEAM'S 6000 COST").foregroundStyle(cyan)
        Text(
          "Left stick: move relative to your target. BOOST: hold to fly and dash.\nRelease boost to land and rapidly refill. Empty gauge causes overheat."
        )
        Text(
          "FIRE: beam rifle, 7 rounds with automatic reload. SABER: lunge within\n19m; chain three strikes. STEP: evasive dash, cancels attack recovery."
        )
        Text(
          "LOCK: switch between opponents. GUARD: hold to reduce incoming damage.\nEX: activate at 50% charge for 7 seconds of enhanced damage and speed."
        )
        Text(
          "Each human has an AI wingman. Lost frames cost 2000 (AI: 1500).\nAt 0 team cost you lose. Timeout compares remaining cost plus armor."
        )
        Text(
          "Native networking • Room codes • No account required\nOnly connect to servers you trust. Use the host's LAN IP on real devices."
        )
        .foregroundStyle(.gray)
      }
      .font(.system(size: 12, weight: .medium, design: .monospaced))
      .padding(28).frame(maxWidth: 720)
    }
  }
}

private func controlLabel(_ title: String, icon: String, color: Color) -> some View {
  VStack(spacing: 4) {
    Image(systemName: icon).font(.system(size: 18, weight: .bold))
    Text(title).font(.system(size: 8, weight: .black, design: .monospaced))
  }
  .foregroundStyle(color).frame(width: 64, height: 51)
  .background(navy.opacity(0.87)).clipShape(CutPanel())
  .overlay(CutPanel().stroke(color.opacity(0.65), lineWidth: 1))
}

struct HoldControl: View {
  let title: String
  let icon: String
  let color: Color
  @Binding var held: Bool
  var body: some View {
    controlLabel(title, icon: icon, color: held ? .white : color)
      .background(held ? color.opacity(0.5) : .clear)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0).onChanged { _ in held = true }.onEnded { _ in held = false }
      )
      .accessibilityElement().accessibilityLabel(title).accessibilityIdentifier(title)
      .accessibilityAddTraits(.isButton)
  }
}

struct Joystick: View {
  @Binding var value: CGSize
  var body: some View {
    ZStack {
      Circle().fill(navy.opacity(0.48))
      Circle().stroke(cyan.opacity(0.42), lineWidth: 1)
      Circle().stroke(.white.opacity(0.1), lineWidth: 1).padding(17)
      Image(systemName: "plus").font(.system(size: 63, weight: .ultraLight)).foregroundStyle(
        cyan.opacity(0.25))
      Circle().fill(cyan.opacity(0.18)).frame(width: 49, height: 49)
        .overlay(Circle().stroke(cyan.opacity(0.75), lineWidth: 1))
        .offset(x: value.width * 36, y: value.height * 36)
    }
    .contentShape(Circle())
    .gesture(
      DragGesture(minimumDistance: 0).onChanged { gesture in
        let dx = gesture.location.x - 61
        let dy = gesture.location.y - 61
        let length = max(36, hypot(dx, dy))
        value = CGSize(width: dx / length, height: dy / length)
      }.onEnded { _ in value = .zero }
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Movement joystick")
    .accessibilityHint("Drag to strafe or approach the locked target")
  }
}
