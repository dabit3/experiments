import SpriteKit
import SwiftUI

private let ink = Color(red: 0.045, green: 0.045, blue: 0.08)
private let gold = Color(red: 1, green: 0.80, blue: 0.25)
private let cyan = Color(red: 0.26, green: 0.94, blue: 1)

@main
struct SkylinePulseApp: App {
  @StateObject private var session = Session()
  var body: some Scene {
    WindowGroup {
      RootView(session: session)
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
  }
}

struct ArcadeButton: View {
  let title: String
  var light = false
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 15, weight: .heavy, design: .rounded))
        .tracking(1.3)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .foregroundStyle(light ? ink : gold)
        .background(light ? gold : Color.white.opacity(0.07))
        .overlay(Rectangle().stroke(gold.opacity(light ? 1 : 0.5), lineWidth: 1))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(title)
  }
}

struct RootView: View {
  @ObservedObject var session: Session
  @State private var scene = HighwayScene(size: CGSize(width: 1200, height: 800))
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        ink.ignoresSafeArea()
        if session.state?.phase == "playing" {
          SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
            .onAppear {
              scene.session = session
              session.scene = scene
            }
          matchHUD(size: geometry.size)
        } else if session.state?.phase == "results" {
          results
        } else {
          lobby
        }
        if session.guide { guide }
      }
    }
    .onAppear {
      if Launch.has("create") {
        session.connect(create: true)
      } else if Launch.value("room") != nil {
        session.connect(create: false)
      }
    }
  }

  private var brand: some View {
    HStack(spacing: 12) {
      Image(systemName: "waveform.path").font(.system(size: 27, weight: .heavy)).foregroundStyle(
        gold)
      VStack(alignment: .leading, spacing: 2) {
        Text("SKYLINE PULSE").font(.system(size: 25, weight: .black, design: .rounded)).tracking(3)
        Text("REACH BEYOND THE RHYTHM").font(.system(size: 9, weight: .bold)).tracking(3)
          .foregroundStyle(gold)
      }
    }
  }

  private var lobby: some View {
    GeometryReader { geo in
      HStack(spacing: 0) {
        ZStack(alignment: .bottomLeading) {
          Image("aria.png").resizable().scaledToFill()
            .frame(width: geo.size.width * 0.32, height: geo.size.height).clipped()
          LinearGradient(colors: [.clear, ink], startPoint: .center, endPoint: .bottom)
          VStack(alignment: .leading, spacing: 12) {
            Text("SKY COURIER / 01").font(.system(size: 11, weight: .bold)).tracking(3)
              .foregroundStyle(gold)
            Text("ARIA").font(.system(size: 55, weight: .ultraLight)).tracking(9)
            Text("The city is listening.\nGive it a new heartbeat.").font(.system(size: 16))
              .foregroundStyle(.white.opacity(0.8))
            HStack {
              Text("TAP").foregroundStyle(.pink)
              Text("HOLD").foregroundStyle(gold)
              Text("SLIDE").foregroundStyle(cyan)
              Text("AIR ↑").foregroundStyle(.green)
            }.font(.system(size: 10, weight: .heavy)).padding(.top, 12)
          }.padding(26)
        }.frame(width: geo.size.width * 0.32)
        VStack(alignment: .leading, spacing: 17) {
          HStack {
            brand
            Spacer()
            Button("HOW TO PLAY") { session.guide = true }
              .font(.system(size: 10, weight: .heavy)).foregroundStyle(gold)
          }
          HStack {
            Text("01").foregroundStyle(gold)
            Text("SELECT YOUR FREQUENCY").tracking(2)
            Spacer()
            Text("ORIGINAL TRACKS").foregroundStyle(.gray).font(.system(size: 9, weight: .bold))
          }.font(.system(size: 12, weight: .heavy))
          HStack(spacing: 14) {
            ForEach(Chart.all) { chart in
              songCard(chart)
            }
          }
          HStack {
            Text("02").foregroundStyle(gold)
            Text("CONNECT & COMPETE").tracking(2)
            Spacer()
            Text(session.status).foregroundStyle(session.status == "CONNECTED" ? cyan : .gray)
          }.font(.system(size: 12, weight: .heavy))
          if session.state == nil { connectionForm } else { roomPanel }
          if !session.error.isEmpty {
            Text(session.error).foregroundStyle(.pink).font(.system(size: 12))
              .accessibilityIdentifier("connectionError")
          }
          Spacer(minLength: 0)
          HStack {
            Text("16-SEGMENT TOUCH SURFACE  /  TWO-PLAYER SCORE BATTLE")
            Spacer()
            Text("VOL. 01")
          }.font(.system(size: 8, weight: .medium)).tracking(1).foregroundStyle(.gray)
        }.padding(26)
      }
    }.ignoresSafeArea()
  }

  private func songCard(_ chart: Chart) -> some View {
    let chosen = session.selectedSong == chart.id
    return Button {
      session.select(chart.id)
    } label: {
      VStack(alignment: .leading, spacing: 0) {
        ZStack(alignment: .bottomLeading) {
          Image("aria.png").resizable().scaledToFill()
            .frame(height: 140).clipped()
            .hueRotation(.degrees(chart.id == "neon" ? 0 : 85))
          LinearGradient(
            colors: [.clear, .black.opacity(0.9)], startPoint: .top, endPoint: .bottom)
          VStack(alignment: .leading, spacing: 4) {
            Text(chart.id == "neon" ? "SKYLINE / NIGHTFALL" : "SKYLINE / DAYBREAK").font(
              .system(size: 8, weight: .heavy)
            ).tracking(2)
            Text(chart.title).font(.system(size: 23, weight: .black, design: .rounded)).italic()
          }.padding(12)
          VStack {
            HStack {
              Spacer()
              Text(chosen ? "SELECTED" : "ORIGINAL").font(.system(size: 8, weight: .heavy))
                .padding(6).background(chosen ? gold : Color.black).foregroundStyle(
                  chosen ? ink : .white)
            }
            Spacer()
          }.padding(7)
        }
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 4) {
            Text(chart.id == "neon" ? "ADVANCED" : "EXPERT").font(.system(size: 11, weight: .black))
              .tracking(1.2)
            Text("\(Int(chart.bpm)) BPM  •  \(Int(chart.duration)) SEC").font(
              .system(size: 10, weight: .semibold))
          }
          Spacer()
          Text(chart.level).font(.system(size: 32, weight: .black, design: .rounded))
        }.foregroundStyle(ink).padding(12).background(chosen ? gold : Color.white)
      }
      .overlay(
        Rectangle().stroke(chosen ? gold : Color.white.opacity(0.3), lineWidth: chosen ? 3 : 1))
    }
    .buttonStyle(.plain)
    .disabled(session.state != nil && session.state?.host != session.playerID)
    .accessibilityIdentifier(chart.id)
  }

  private var connectionForm: some View {
    VStack(spacing: 11) {
      HStack(spacing: 12) {
        field("GUEST NAME", text: $session.name, id: "guestName")
        field("SERVER ADDRESS", text: $session.address, id: "serverAddress")
      }
      HStack(spacing: 12) {
        ArcadeButton(title: "CREATE ROOM", light: true) { session.connect(create: true) }
        TextField("ROOM CODE", text: $session.roomCode)
          .textInputAutocapitalization(.characters).autocorrectionDisabled()
          .font(.system(size: 15, weight: .bold, design: .monospaced))
          .padding(14).background(Color.white.opacity(0.07)).frame(maxWidth: 155)
          .accessibilityIdentifier("roomCode")
        ArcadeButton(title: "JOIN ROOM") { session.connect(create: false) }
      }
      Text("Run the local server, then share the six-character room code with a second iPad.")
        .font(.system(size: 11)).foregroundStyle(.gray).frame(
          maxWidth: .infinity, alignment: .leading)
    }
  }

  private func field(_ title: String, text: Binding<String>, id: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(title).font(.system(size: 9, weight: .heavy)).tracking(1).foregroundStyle(.gray)
      TextField(title, text: text).textInputAutocapitalization(.never).autocorrectionDisabled()
        .font(.system(size: 14, weight: .medium, design: .monospaced)).padding(10)
        .background(Color.white.opacity(0.06)).overlay(Rectangle().stroke(.white.opacity(0.2)))
        .accessibilityIdentifier(id)
    }
  }

  private var roomPanel: some View {
    VStack(spacing: 10) {
      HStack {
        Text("ROOM").foregroundStyle(.gray).font(.system(size: 10, weight: .bold))
        Text(session.roomCode).font(.system(size: 24, weight: .heavy, design: .monospaced))
          .tracking(4).foregroundStyle(gold)
          .accessibilityIdentifier("activeRoom")
        Spacer()
        Text("CLOCK SYNC  \(Int(session.rtt)) ms").foregroundStyle(cyan).font(
          .system(size: 10, weight: .bold))
      }
      HStack(spacing: 12) {
        ForEach(session.state?.players ?? []) { player in
          HStack {
            Circle().fill(player.connected ? cyan : .gray).frame(width: 6, height: 6)
            Text(player.name).lineLimit(1)
            Spacer()
            Text(player.ready ? "READY" : "WAITING").foregroundStyle(player.ready ? gold : .gray)
          }.font(.system(size: 11, weight: .bold)).padding(12).background(.white.opacity(0.06))
        }
        if session.opponent == nil {
          Text("Waiting for a second player…").font(.system(size: 12)).foregroundStyle(.gray)
        }
      }
      HStack(spacing: 12) {
        ArcadeButton(
          title: session.me?.ready == true ? "CANCEL READY" : "READY TO FLY", light: true
        ) { session.ready() }
        .disabled(!session.clockReady)
        ArcadeButton(title: "LEAVE") { session.leave() }
      }
      if session.demo {
        Text("AUTOMATED INPUT DRIVER • Sends normal finger events through the live network")
          .font(.system(size: 9, weight: .heavy)).foregroundStyle(cyan)
      }
    }
  }

  private func matchHUD(size: CGSize) -> some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: 10) {
        VStack(alignment: .leading, spacing: 7) {
          Text("SKYLINE PULSE").font(.system(size: 16, weight: .black)).tracking(1)
          Text(session.name).font(.system(size: 12, weight: .heavy)).foregroundStyle(gold)
          Text("ROOM \(session.roomCode) · ROUND \(session.state?.round ?? 1)")
            .font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(
              .white.opacity(0.7))
        }.frame(width: size.width * 0.25, alignment: .leading)
        VStack(spacing: 5) {
          HStack {
            Text("SCORE").font(.system(size: 10, weight: .heavy))
            Text(String(format: "%07d", session.me?.score ?? 0)).font(
              .system(size: 33, weight: .black, design: .rounded)
            ).monospacedDigit()
            Spacer()
            VStack(alignment: .trailing) {
              Text("ACCURACY").font(.system(size: 8, weight: .heavy))
              Text(String(format: "%.2f%%", session.me?.accuracy ?? 100)).font(
                .system(size: 16, weight: .black)
              ).monospacedDigit()
            }
          }.foregroundStyle(ink)
          GeometryReader { bar in
            ZStack(alignment: .leading) {
              Rectangle().fill(ink.opacity(0.25))
              Rectangle().fill(ink).frame(
                width: bar.size.width * min(1, CGFloat(session.me?.score ?? 0) / 1_000_000))
            }
          }.frame(height: 5)
        }.padding(.horizontal, 15).padding(.vertical, 8).background(gold)
        VStack(alignment: .leading, spacing: 5) {
          Text(session.chart?.title ?? "").font(.system(size: 15, weight: .black)).italic()
          Text("\(Int(session.chart?.bpm ?? 0)) BPM  /  LV \(session.chart?.level ?? "")").font(
            .system(size: 10, weight: .heavy)
          ).foregroundStyle(gold)
          Text(
            session.status == "CONNECTED"
              ? "LIVE BATTLE  •  \(Int(session.rtt)) ms" : session.status
          )
          .font(.system(size: 9, weight: .bold)).foregroundStyle(cyan)
        }.frame(width: size.width * 0.20, alignment: .leading).padding(8).background(
          ink.opacity(0.9))
      }.padding(.horizontal, 17).padding(.top, 12)
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 8) {
          Text("OPPONENT").font(.system(size: 9, weight: .heavy)).tracking(2).foregroundStyle(gold)
          Text(session.opponent?.name ?? "WAITING").font(.system(size: 18, weight: .black))
          Text(String(format: "%07d", session.opponent?.score ?? 0)).font(
            .system(size: 26, weight: .heavy, design: .monospaced)
          ).foregroundStyle(cyan)
          Text(
            "\(session.opponent?.combo ?? 0) COMBO   ·   \(session.opponent?.connected == true ? "ONLINE" : "RECONNECTING")"
          )
          .font(.system(size: 9, weight: .heavy))
          Rectangle().fill(gold.opacity(0.6)).frame(height: 1)
          Text("ARIA / SKY COURIER").font(.system(size: 9, weight: .bold)).tracking(1)
          Spacer()
          if session.demo {
            Text("AUTOMATED\nINPUT DRIVER").font(.system(size: 13, weight: .black)).foregroundStyle(
              cyan)
            Text("Real touch-event path\nLive WebSocket peers").font(.system(size: 9))
              .foregroundStyle(.white)
          }
          Text("TAP  •  HOLD\nSLIDE  •  SWIPE UP ↑")
            .font(.system(size: 11, weight: .heavy)).foregroundStyle(gold).lineSpacing(6)
        }
        .padding(14).frame(width: size.width * 0.23, alignment: .leading)
        .background(
          LinearGradient(
            colors: [ink.opacity(0.95), ink.opacity(0.15), ink.opacity(0.9)], startPoint: .top,
            endPoint: .bottom))
        Spacer()
      }.padding(.top, 12).padding(.leading, 14).padding(.bottom, 34)
      Text("SLIDER ACTIVE  /  TOUCH ANYWHERE BELOW THE GOLD LINE  /  AIR: SWIPE UP")
        .font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(gold).padding(.bottom, 7)
    }.allowsHitTesting(false)
  }

  private var results: some View {
    ZStack {
      Image("aria.png").resizable().scaledToFill().ignoresSafeArea().opacity(0.24)
      ink.opacity(0.55).ignoresSafeArea()
      VStack(spacing: 17) {
        brand
        Text("TRACK COMPLETE").font(.system(size: 12, weight: .heavy)).tracking(5).foregroundStyle(
          gold)
        Text(resultTitle).font(.system(size: 51, weight: .black, design: .rounded)).italic()
        Text(
          "\(session.chart?.title ?? "")   /   ROOM \(session.roomCode)   /   ROUND \(session.state?.round ?? 0)"
        )
        .font(.system(size: 11, weight: .heavy)).tracking(1).foregroundStyle(gold)
        HStack(spacing: 18) {
          ForEach(session.state?.players ?? []) { player in resultCard(player) }
        }.frame(maxWidth: 800)
        HStack(spacing: 15) {
          ArcadeButton(title: session.me?.ready == true ? "CANCEL REMATCH" : "REMATCH", light: true)
          { session.ready() }
          ArcadeButton(title: "RECONNECT") { session.reconnect() }
          ArcadeButton(title: "LEAVE ROOM") { session.leave() }
        }.frame(maxWidth: 800)
        Text(
          session.me?.ready == true
            ? "READY — waiting for your opponent"
            : "Both players choose REMATCH to play the same chart again."
        )
        .font(.system(size: 12)).foregroundStyle(cyan)
        if session.demo {
          Text("AUTOMATED INPUT DRIVER • NETWORK-VERIFIED RESULTS").font(
            .system(size: 10, weight: .heavy)
          ).foregroundStyle(gold)
        }
      }.padding(24)
    }
  }

  private var resultTitle: String {
    guard let me = session.me, let opponent = session.opponent else { return "BATTLE COMPLETE" }
    if me.score == opponent.score { return "PERFECT SYMMETRY" }
    return me.score > opponent.score ? "YOU TAKE THE SKY" : "REACH EVEN HIGHER"
  }

  private func resultCard(_ player: Player) -> some View {
    VStack(spacing: 10) {
      HStack {
        Text(player.name).font(.system(size: 19, weight: .black))
        Spacer()
        Text(player.id == session.playerID ? "YOU" : "RIVAL").font(
          .system(size: 10, weight: .heavy)
        ).foregroundStyle(gold)
      }
      Text(String(format: "%07d", player.score)).font(
        .system(size: 43, weight: .black, design: .rounded)
      ).foregroundStyle(gold).monospacedDigit()
      HStack {
        Text(String(format: "%.2f%% ACCURACY", player.accuracy))
        Spacer()
        Text("\(player.maxCombo) MAX COMBO")
      }.font(.system(size: 10, weight: .heavy))
      Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
      resultRow("JUSTICE CRITICAL", player.counts.critical, gold)
      resultRow("JUSTICE", player.counts.justice, .yellow)
      resultRow("ATTACK", player.counts.attack, cyan)
      resultRow("MISS", player.counts.miss, .pink)
    }.padding(20).background(ink.opacity(0.94)).overlay(Rectangle().stroke(gold, lineWidth: 1))
  }

  private func resultRow(_ title: String, _ value: Int, _ color: Color) -> some View {
    HStack {
      Text(title)
      Spacer()
      Text("\(value)").monospacedDigit()
    }
    .font(.system(size: 11, weight: .bold)).foregroundStyle(color)
  }

  private var guide: some View {
    ZStack {
      ink.opacity(0.98).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 22) {
        Text("YOUR HANDS. THE SKY.").font(.system(size: 34, weight: .black)).foregroundStyle(gold)
        Text(
          "Play on the sixteen-segment slider below the gold line.\nMatch the notes as they reach the line, in time with the music."
        ).font(.system(size: 17))
        guideRow("TAP", "Touch anywhere across the red note's width.", .pink)
        guideRow(
          "HOLD",
          "Keep a finger down through the gold ribbon. Releasing loses ticks; reholding recovers.",
          gold)
        guideRow(
          "SLIDE", "Keep touching and follow the cyan ribbon horizontally across the slider.", cyan)
        guideRow(
          "AIR ↑",
          "Start on the slider, then swipe upward by at least 9% of the screen in under half a second.",
          .green)
        HStack {
          Text("INPUT TIMING OFFSET").font(.system(size: 12, weight: .heavy))
          Slider(value: $session.timingOffset, in: -150...150, step: 5)
            .tint(gold).onChange(of: session.timingOffset) { _, value in
              UserDefaults.standard.set(value, forKey: "timingOffset")
            }
          Text("\(Int(session.timingOffset)) ms").font(.system(size: 13, design: .monospaced))
            .frame(width: 75)
        }
        Text(
          "Critical ±45ms · Justice ±90ms · Attack ±160ms · Air window ±200ms\nPositive offset shifts your input later. Music is scheduled to the shared room clock."
        )
        .font(.system(size: 12)).foregroundStyle(.gray)
        ArcadeButton(title: "LET'S FLY", light: true) { session.guide = false }
      }.padding(35).frame(maxWidth: 900)
    }
  }

  private func guideRow(_ title: String, _ detail: String, _ color: Color) -> some View {
    HStack(alignment: .top, spacing: 18) {
      Text(title).font(.system(size: 18, weight: .black)).foregroundStyle(color).frame(
        width: 95, alignment: .leading)
      Text(detail).font(.system(size: 15))
    }
  }
}
