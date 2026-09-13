import SceneKit
import SwiftUI

private let navy = Color(red: 0.055, green: 0.07, blue: 0.17)
private let yellow = Color(red: 1, green: 0.84, blue: 0.22)

@main
struct StarcapCircuitApp: App {
  var body: some Scene {
    WindowGroup { CircuitView().preferredColorScheme(.dark).statusBarHidden() }
  }
}

struct CircuitView: View {
  @StateObject private var client = RaceClient()
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        SceneView(
          scene: client.world.scene, pointOfView: client.world.cameraNode,
          options: [.rendersContinuously], preferredFramesPerSecond: 60,
          antialiasingMode: .multisampling4X
        )
        .ignoresSafeArea()
        if client.racing {
          RaceHUD(client: client)
        } else if client.state?.phase == "results" {
          ResultsPanel(client: client, width: geometry.size.width)
        } else {
          LobbyPanel(client: client, width: geometry.size.width)
        }
        if !client.connected && client.state != nil {
          navy.opacity(0.87).ignoresSafeArea()
          VStack(spacing: 16) {
            Image(systemName: "wifi.slash").font(.system(size: 42))
            Text("PIT STOP — CONNECTION LOST").font(
              .system(size: 24, weight: .black, design: .rounded))
            Text(client.status).font(.system(size: 15))
            HStack {
              ArcadeButton("RECONNECT", tint: yellow) { client.join() }
              ArcadeButton("LEAVE ROOM", tint: .white) { client.leave() }
            }
          }.padding(30)
        }
      }
    }
    .onReceive(
      NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
    ) { _ in
      client.throttle = false
      client.brake = true
      client.drift = false
      client.steer = 0
    }
  }
}

struct OutlinedText: View {
  let text: String
  var size: CGFloat = 36
  var color: Color = .white
  var body: some View {
    Text(text)
      .font(.system(size: size, weight: .black, design: .rounded).italic())
      .foregroundStyle(color)
      .shadow(color: navy, radius: 0, x: 2, y: 2)
      .shadow(color: navy, radius: 0, x: -2, y: -2)
      .shadow(color: navy, radius: 0, x: -2, y: 2)
      .shadow(color: navy, radius: 0, x: 2, y: -2)
      .shadow(color: navy.opacity(0.7), radius: 0, x: 0, y: 5)
      .fixedSize()
  }
}

struct ArcadeButton: View {
  let title: String
  var tint: Color = yellow
  let action: () -> Void
  init(_ title: String, tint: Color = yellow, action: @escaping () -> Void) {
    self.title = title
    self.tint = tint
    self.action = action
  }
  var body: some View {
    Button(action: action) {
      Text(title).font(.system(size: 14, weight: .black, design: .rounded))
        .tracking(0.5).foregroundStyle(navy).padding(.horizontal, 20).padding(.vertical, 13)
        .frame(maxWidth: .infinity)
        .background(tint, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.6), lineWidth: 2))
        .shadow(color: navy.opacity(0.6), radius: 0, y: 4)
    }.buttonStyle(.plain)
  }
}

struct LobbyPanel: View {
  @ObservedObject var client: RaceClient
  let width: CGFloat
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [navy.opacity(0.94), navy.opacity(0.75), navy.opacity(0.35)], startPoint: .leading,
        endPoint: .trailing
      ).ignoresSafeArea()
      VStack(spacing: 12) {
        HStack(alignment: .top) {
          HStack(spacing: 10) {
            Image(systemName: "star.circle.fill").font(.system(size: 36, weight: .black))
              .foregroundStyle(yellow)
            VStack(alignment: .leading, spacing: -5) {
              OutlinedText(text: "STARCAP", size: 25)
              Text("C I R C U I T").font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(yellow)
            }
          }
          Spacer()
          Label("2 RACERS • LIVE MULTIPLAYER", systemImage: "wifi")
            .font(.system(size: 10, weight: .heavy, design: .rounded)).padding(9)
            .background(.white.opacity(0.12), in: Capsule())
          Button {
            client.toggleMute()
          } label: {
            Image(systemName: client.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
              .font(.system(size: 18)).frame(width: 40, height: 36)
          }.accessibilityLabel("Toggle sound").buttonStyle(.plain)
        }
        HStack(alignment: .top, spacing: 24) {
          VStack(alignment: .leading, spacing: 9) {
            Text(client.connected ? "YOUR STARTING GRID" : "SMALL KARTS.\nBIG ENERGY.")
              .font(
                .system(size: client.connected ? 25 : 31, weight: .black, design: .rounded).italic()
              )
              .lineSpacing(-2).fixedSize(horizontal: false, vertical: true)
            if client.connected {
              connectedRoom
            } else {
              Text("Pick a room code. Bring your rival.").font(.system(size: 12)).foregroundStyle(
                .white.opacity(0.7))
              HStack(spacing: 8) {
                entry("GUEST NAME", text: $client.name)
                entry("ROOM CODE", text: $client.code)
              }
              entry("SERVER ADDRESS", text: $client.address)
              ArcadeButton("JOIN THE GRID  →") { client.join() }
              Text(client.status).font(.system(size: 10, weight: .medium)).foregroundStyle(
                .white.opacity(0.7)
              ).lineLimit(2)
            }
          }.frame(width: min(315, width * 0.4), alignment: .leading)
          VStack(alignment: .leading, spacing: 10) {
            HStack {
              Text("01").foregroundStyle(yellow)
              Text("CHOOSE YOUR RACER")
              Spacer()
              Text("ALL HEART. ALL HORSEPOWER.").font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
            }.font(.system(size: 11, weight: .black, design: .rounded))
            HStack(spacing: 9) {
              ForEach(Racer.all) { racer in
                Button {
                  client.racer = racer.id
                } label: {
                  VStack(spacing: 3) {
                    RacerPortrait(racer: racer.id).frame(height: 53)
                    Text(racer.name).font(.system(size: 12, weight: .black, design: .rounded))
                    Text(racer.subtitle).font(.system(size: 8, weight: .medium))
                  }.frame(maxWidth: .infinity).padding(.vertical, 7)
                    .background(
                      client.racer == racer.id ? racer.color.opacity(0.32) : .white.opacity(0.08),
                      in: RoundedRectangle(cornerRadius: 13)
                    )
                    .overlay(
                      RoundedRectangle(cornerRadius: 13).stroke(
                        client.racer == racer.id ? racer.color : .white.opacity(0.15),
                        lineWidth: client.racer == racer.id ? 2.5 : 1))
                }.buttonStyle(.plain).disabled(client.connected).accessibilityLabel(
                  "Select \(racer.name)")
              }
            }
            HStack {
              Text("02").foregroundStyle(yellow)
              Text("PICK YOUR PLAYGROUND")
            }.font(.system(size: 11, weight: .black, design: .rounded))
            HStack(spacing: 10) {
              ForEach(0..<2) { track in
                Button {
                  client.setTrack(track)
                } label: {
                  TrackCard(track: track, selected: (client.state?.track ?? client.track) == track)
                }.buttonStyle(.plain).disabled(client.connected).accessibilityLabel(
                  "Select \(Course.names[track])")
              }
            }
            Text("HOLD GAS • STEER • HOLD DRIFT IN TURNS • RELEASE TO BOOST")
              .font(.system(size: 8, weight: .bold, design: .rounded)).foregroundStyle(
                .white.opacity(0.6))
          }.frame(maxWidth: .infinity)
        }
        Spacer(minLength: 0)
      }.padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 8)
    }
  }

  private func entry(_ label: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(label).font(.system(size: 8, weight: .black)).tracking(1).foregroundStyle(
        .white.opacity(0.55))
      TextField(label, text: text)
        .font(.system(size: 13, weight: .semibold, design: .rounded)).textInputAutocapitalization(
          .never
        )
        .autocorrectionDisabled().padding(.horizontal, 10).padding(.vertical, 9)
        .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(.white.opacity(0.13)))
        .accessibilityLabel(label)
    }
  }

  private var connectedRoom: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("ROOM \(client.code)").font(.system(size: 20, weight: .black, design: .monospaced))
          .foregroundStyle(yellow)
        Spacer()
        Text("\(client.state?.players.count ?? 1)/2").font(.system(size: 13, weight: .bold))
      }
      ForEach(client.state?.players ?? []) { player in
        HStack {
          Circle().fill(Racer.all[player.racer].color).frame(width: 11, height: 11)
          Text(player.name).font(.system(size: 14, weight: .bold))
          Spacer()
          Text(player.ready ? "READY" : "IN THE PITS").font(.system(size: 9, weight: .black))
            .foregroundStyle(player.ready ? .mint : .white.opacity(0.6))
        }
      }
      if client.state?.players.count == 1 {
        Text("Waiting for a friend to join this code…").font(.system(size: 11)).foregroundStyle(
          .white.opacity(0.65))
      }
      ArcadeButton(
        client.me?.ready == true ? "WAITING FOR THE OTHER RACER…" : "READY TO RACE!",
        tint: client.me?.ready == true ? .mint : yellow
      ) { client.ready() }
      .disabled(client.me?.ready == true)
      HStack {
        Button("LEAVE ROOM") { client.leave() }
        Spacer()
        Button(client.autoDrive ? "AUTO DRIVER: ON" : "AUTO DRIVER: OFF") {
          client.autoDrive.toggle()
        }
        .accessibilityLabel("Toggle automated driver")
      }.font(.system(size: 9, weight: .heavy)).buttonStyle(.plain)
      Text("Both racers must be ready. Two laps. One star.").font(.system(size: 10))
        .foregroundStyle(.white.opacity(0.65))
    }
  }
}

struct RacerPortrait: View {
  let racer: Int
  var body: some View {
    GeometryReader { geo in
      let color = Racer.all[racer].color
      ZStack {
        Ellipse().fill(color.opacity(0.2)).frame(width: 65, height: 42).offset(y: 7)
        ForEach([-1, 1], id: \.self) { side in
          Capsule().fill(color).frame(width: racer == 1 ? 11 : 16, height: racer == 1 ? 28 : 17)
            .rotationEffect(.degrees(Double(side * 12))).offset(x: CGFloat(side * 18), y: -19)
        }
        RoundedRectangle(cornerRadius: racer == 2 ? 12 : 24).fill(color).frame(
          width: 52, height: 43)
        RoundedRectangle(cornerRadius: 14).fill(
          racer == 2 ? navy : Color(red: 1, green: 0.91, blue: 0.79)
        )
        .frame(width: 41, height: 22).offset(y: 7)
        HStack(spacing: 13) {
          Capsule().fill(racer == 2 ? .cyan : navy).frame(width: 5, height: 9)
          Capsule().fill(racer == 2 ? .cyan : navy).frame(width: 5, height: 9)
        }.offset(y: 5)
        Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(.white).offset(
          y: -10)
      }.frame(width: geo.size.width, height: geo.size.height)
    }
  }
}

struct TrackCard: View {
  let track: Int
  let selected: Bool
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      ZStack {
        LinearGradient(
          colors: track == 0 ? [.cyan, .blue] : [.purple, .pink], startPoint: .topLeading,
          endPoint: .bottomTrailing)
        HStack {
          Image(systemName: track == 0 ? "sun.max.fill" : "moon.stars.fill").font(.system(size: 25))
            .foregroundStyle(yellow).padding(.leading, 10)
          Spacer()
          MiniMap(state: nil, playerID: "", track: track).frame(width: 72, height: 45).padding(
            .trailing, 8)
        }
        if selected {
          VStack {
            HStack {
              Spacer()
              Image(systemName: "checkmark.seal.fill").foregroundStyle(yellow).padding(5)
            }
            Spacer()
          }
        }
      }.frame(height: 53).clipShape(RoundedRectangle(cornerRadius: 9))
      Text(Course.names[track]).font(.system(size: 10, weight: .black, design: .rounded))
      Text(track == 0 ? "BREEZY • 2 LAPS" : "TWISTY • 2 LAPS").font(.system(size: 8, weight: .bold))
        .foregroundStyle(.white.opacity(0.6))
    }.padding(7).frame(maxWidth: .infinity, alignment: .leading)
      .background(navy.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
      .overlay(
        RoundedRectangle(cornerRadius: 12).stroke(
          selected ? yellow : .white.opacity(0.15), lineWidth: selected ? 2 : 1))
  }
}

struct MiniMap: View {
  let state: RaceState?
  let playerID: String
  let track: Int
  var body: some View {
    Canvas { context, size in
      func point(_ x: Double, _ z: Double) -> CGPoint {
        CGPoint(x: size.width * (0.5 + x / 200), y: size.height * (0.5 + z / 180))
      }
      var road = Path()
      for index in 0...240 {
        let p = Course.point(track, Double(index))
        if index == 0 { road.move(to: point(p.x, p.z)) } else { road.addLine(to: point(p.x, p.z)) }
      }
      context.stroke(road, with: .color(navy), lineWidth: 9)
      context.stroke(road, with: .color(.white.opacity(0.9)), lineWidth: 5)
      for p in state?.players ?? [] {
        let at = point(p.x, p.z)
        let radius: CGFloat = p.id == playerID ? 5 : 4
        let dot = Path(
          ellipseIn: CGRect(
            x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2))
        context.fill(dot, with: .color(Racer.all[p.racer].color))
        context.stroke(dot, with: .color(navy), lineWidth: 2)
      }
    }
  }
}

struct RaceHUD: View {
  @ObservedObject var client: RaceClient
  var body: some View {
    ZStack {
      VStack {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 1) {
            Text(Course.names[client.state?.track ?? 0]).font(
              .system(size: 11, weight: .black, design: .rounded)
            ).shadow(color: navy, radius: 3)
            OutlinedText(
              text: String(
                format: "%05.1f", max(0, (client.serverNow - (client.state?.startAt ?? 0)) / 1000)),
              size: 32)
            HStack(spacing: 5) {
              Circle().fill(.mint).frame(width: 5, height: 5)
              Text("\(client.code)  •  \(client.name)").font(.system(size: 9, weight: .bold))
            }.padding(6).background(navy.opacity(0.65), in: Capsule())
          }
          Spacer()
          itemButton
          Spacer()
          VStack(alignment: .trailing, spacing: 0) {
            OutlinedText(
              text: client.me?.rank == 1 ? "1st" : "2nd", size: 47,
              color: client.me?.rank == 1 ? yellow : .white)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
              Text("LAP").font(.system(size: 12, weight: .black))
              OutlinedText(text: "\(client.me?.lap ?? 1)/2", size: 27, color: .mint)
            }
          }.frame(width: 118, alignment: .trailing)
        }
        HStack {
          if client.autoDrive {
            Button {
              client.autoDrive = false
              client.throttle = false
              client.steer = 0
              client.drift = false
            } label: {
              Label("AUTOMATED DRIVER • TAP TO TAKE OVER", systemImage: "steeringwheel")
                .font(.system(size: 8, weight: .black)).foregroundStyle(navy).padding(8).background(
                  yellow, in: Capsule())
            }.buttonStyle(.plain).accessibilityLabel("Disable automated driver")
          } else {
            Button {
              client.autoDrive = true
            } label: {
              Text("AUTO DRIVER: OFF").font(.system(size: 8, weight: .black)).padding(7).background(
                navy.opacity(0.55), in: Capsule())
            }.buttonStyle(.plain).accessibilityLabel("Enable automated driver")
          }
          Spacer()
        }
        Spacer()
        HStack(alignment: .bottom) {
          steering
          Spacer()
          VStack(spacing: 3) {
            if let me = client.me, me.charge > 0 {
              ProgressView(value: me.charge / 2.3).tint(me.charge > 1.5 ? .orange : .cyan).frame(
                width: 95)
              Text("RELEASE DRIFT → TURBO").font(.system(size: 7, weight: .black))
            }
            OutlinedText(text: "\(Int((client.me?.speed ?? 0) * 3.6))", size: 29)
            Text("KM/H").font(.system(size: 8, weight: .black)).tracking(1)
          }.padding(.bottom, 5)
          Spacer()
          pedals
        }
      }.padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 13)
      VStack {
        Spacer()
        HStack {
          Spacer()
          MiniMap(state: client.state, playerID: client.playerID, track: client.state?.track ?? 0)
            .frame(width: 85, height: 78).padding(8).background(
              navy.opacity(0.35), in: RoundedRectangle(cornerRadius: 17))
        }
        Spacer().frame(height: 102)
      }.padding(.trailing, 25).allowsHitTesting(false)
      if client.countdown > 0 {
        VStack(spacing: 4) {
          OutlinedText(text: "\(client.countdown)", size: 100, color: yellow)
          Text("HOLD GAS. GET READY.").font(.system(size: 13, weight: .black, design: .rounded))
            .shadow(color: navy, radius: 3)
        }.allowsHitTesting(false)
      } else if !client.toast.isEmpty {
        VStack {
          Spacer().frame(height: 122)
          OutlinedText(text: client.toast, size: 19, color: yellow)
          Spacer()
        }.allowsHitTesting(false)
      }
      if (client.me?.finish ?? 0) > 0 && client.state?.phase == "racing" {
        VStack(spacing: 5) {
          OutlinedText(text: "FINISH!", size: 55, color: yellow)
          Text("Waiting for your rival…").font(.system(size: 14, weight: .bold))
            .padding(9).background(navy.opacity(0.7), in: Capsule())
        }
      }
    }
  }

  private var itemButton: some View {
    let roulette = (client.me?.roulette ?? 0) > 0
    let item =
      roulette
      ? ["zap", "comet", "gum", "bubble"][Int(client.clock * 12) % 4] : client.me?.item ?? ""
    let symbol =
      ["zap": "bolt.fill", "comet": "flame.fill", "gum": "drop.fill", "bubble": "shield.fill"][item]
      ?? "questionmark"
    return Button {
      client.item()
    } label: {
      VStack(spacing: 2) {
        Image(systemName: symbol).font(.system(size: 26, weight: .black)).foregroundStyle(
          item.isEmpty ? .white.opacity(0.35) : yellow
        )
        .frame(width: 57, height: 44)
        Text(roulette ? "ROLLING!" : item.isEmpty ? "ITEM" : item.uppercased()).font(
          .system(size: 8, weight: .black))
      }.padding(5).background(navy.opacity(0.84), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
          RoundedRectangle(cornerRadius: 16).stroke(
            roulette || !item.isEmpty ? yellow : .white.opacity(0.7), lineWidth: 3)
        )
        .shadow(color: navy.opacity(0.5), radius: 0, y: 4)
    }.buttonStyle(.plain).accessibilityLabel("Use item")
  }

  private var steering: some View {
    HStack(spacing: 10) {
      HoldControl(
        symbol: "arrowtriangle.left.fill", label: "LEFT", color: .white, size: 63,
        active: client.steer < -0.1
      ) { down in
        client.autoDrive = false
        client.steer = down ? -1 : 0
      }
      HoldControl(
        symbol: "arrowtriangle.right.fill", label: "RIGHT", color: .white, size: 63,
        active: client.steer > 0.1
      ) { down in
        client.autoDrive = false
        client.steer = down ? 1 : 0
      }
    }
  }

  private var pedals: some View {
    HStack(alignment: .bottom, spacing: 9) {
      HoldControl(symbol: "stop.fill", label: "BRAKE", color: .pink, size: 48, active: client.brake)
      { down in
        client.autoDrive = false
        client.brake = down
      }
      HoldControl(symbol: "wind", label: "DRIFT", color: .cyan, size: 60, active: client.drift) {
        down in
        client.autoDrive = false
        client.drift = down
      }
      HoldControl(
        symbol: "chevron.up.2", label: "GAS", color: yellow, size: 73, active: client.throttle
      ) { down in
        client.autoDrive = false
        client.throttle = down
      }
    }
  }
}

struct HoldControl: View {
  let symbol: String
  let label: String
  let color: Color
  let size: CGFloat
  let active: Bool
  let action: (Bool) -> Void
  @State private var held = false
  var body: some View {
    VStack(spacing: 3) {
      Image(systemName: symbol).font(.system(size: size * 0.29, weight: .black))
      Text(label).font(.system(size: 8, weight: .black, design: .rounded))
    }.foregroundStyle(active ? navy : color)
      .frame(width: size, height: size)
      .background(active ? color : navy.opacity(0.65), in: Circle())
      .overlay(Circle().stroke(color.opacity(0.9), lineWidth: 2.5))
      .shadow(color: navy.opacity(0.4), radius: 0, y: 4)
      .contentShape(Circle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in
            if !held {
              held = true
              action(true)
            }
          }
          .onEnded { _ in
            held = false
            action(false)
          }
      )
      .accessibilityLabel(label)
      .accessibilityAddTraits(.isButton)
      .accessibilityAction {
        action(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { action(false) }
      }
  }
}

struct ResultsPanel: View {
  @ObservedObject var client: RaceClient
  let width: CGFloat
  var body: some View {
    ZStack {
      navy.opacity(0.76).ignoresSafeArea()
      HStack(spacing: 20) {
        VStack(spacing: 10) {
          Image(systemName: "trophy.fill").font(.system(size: 60)).foregroundStyle(yellow)
          OutlinedText(
            text: client.me?.rank == 1 ? "SUPERSTAR!" : "NICE RACING!", size: 30, color: yellow)
          Text(Course.names[client.state?.track ?? 0]).font(
            .system(size: 11, weight: .black, design: .rounded))
          Text("TWO LAPS. ALL HEART.").font(.system(size: 10, weight: .bold)).foregroundStyle(
            .white.opacity(0.6))
          OutlinedText(text: client.me?.rank == 1 ? "1st" : "2nd", size: 61)
        }.frame(width: width * 0.30)
        VStack(alignment: .leading, spacing: 13) {
          HStack {
            Text("THE FINISH LINE").font(.system(size: 20, weight: .black, design: .rounded))
            Spacer()
            Text("ROOM \(client.code)").font(.system(size: 10, weight: .bold)).foregroundStyle(
              yellow)
          }
          ForEach((client.state?.players ?? []).sorted { $0.rank < $1.rank }) { p in
            VStack(alignment: .leading, spacing: 5) {
              HStack(spacing: 9) {
                Text("\(p.rank)").font(.system(size: 26, weight: .black, design: .rounded))
                  .foregroundStyle(p.rank == 1 ? yellow : .white)
                RacerPortrait(racer: p.racer).frame(width: 38, height: 38)
                Text(p.name).font(.system(size: 16, weight: .black, design: .rounded))
                  .lineLimit(1).minimumScaleFactor(0.65)
                  .frame(maxWidth: .infinity, alignment: .leading)
                Text(p.finish > 0 ? String(format: "%.2fs", p.finish / 1000) : "DNF")
                  .font(.system(size: 17, weight: .black, design: .monospaced)).foregroundStyle(
                    p.rank == 1 ? yellow : .white
                  )
                  .fixedSize()
              }
              Text("\(p.shots) ITEMS • \(p.drifts) TURBOS • \(p.hits) HITS")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.65)).lineLimit(1).minimumScaleFactor(0.8)
            }.padding(10).background(
              .white.opacity(p.id == client.playerID ? 0.13 : 0.06),
              in: RoundedRectangle(cornerRadius: 15))
          }
          ArcadeButton("REMATCH → \(Course.names[(client.state?.track ?? 0) == 0 ? 1 : 0])") {
            client.rematch()
          }
          Button("BACK TO GARAGE") { client.leave() }
            .font(.system(size: 11, weight: .black)).frame(maxWidth: .infinity).buttonStyle(.plain)
            .padding(6)
          Text("Same rivals. Fresh track. Both racers ready up again.")
            .font(.system(size: 10)).foregroundStyle(.white.opacity(0.6))
        }.frame(maxWidth: .infinity).padding(20)
          .background(navy.opacity(0.75), in: RoundedRectangle(cornerRadius: 24))
          .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.17)))
      }.padding(.horizontal, 24).padding(.vertical, 20)
    }
  }
}
