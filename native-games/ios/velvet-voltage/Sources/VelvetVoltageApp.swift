import SpriteKit
import SwiftUI
import UIKit

@main
struct VelvetVoltageApp: App {
  var body: some Scene {
    WindowGroup { VoltageView().preferredColorScheme(.dark) }
  }
}

struct VoltageView: View {
  @StateObject private var game = GameSession()
  @State private var scene: VoltageScene?
  @State private var settings = false
  @State private var shareItem: SharePoster?
  @State private var confirmRestart = false
  @Environment(\.scenePhase) private var phase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        RadialGradient(
          colors: [Color(Ink.panel), Color(Ink.background)],
          center: .top, startRadius: 40, endRadius: 650
        ).ignoresSafeArea()
        if game.screen == .results {
          results
        } else {
          VStack(spacing: 0) {
            if game.screen == .playing { scoreboard } else { masthead }
            ZStack {
              if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                  .aspectRatio(390 / 620, contentMode: .fit)
                  .accessibilityLabel(
                    "Pinball table. The glowing target is district \(game.score.nextDistrict + 1)."
                  )
                  .accessibilityIdentifier("pinballTable")
              }
              if game.screen == .tutorial { tutorial }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if game.screen == .playing { controls } else if game.screen == .home { homeFooter }
          }
          .padding(.horizontal, geometry.size.width < 380 ? 16 : 22)
          .padding(.top, 10)
          .padding(.bottom, 8)
        }
        if game.paused, game.screen == .playing { pauseOverlay }
      }
    }
    .tint(Color(Ink.brass))
    .onAppear {
      scene = VoltageScene(session: game)
      game.reducedMotion = reduceMotion
    }
    .onChange(of: reduceMotion) { _, value in game.reducedMotion = value }
    .onChange(of: phase) { _, value in if value != .active { game.pause() } }
    .sheet(isPresented: $settings) { settingsView }
    .sheet(item: $shareItem) { item in
      ShareSheet(image: item.image, text: item.text)
    }
    .alert("Restart this three-ball game?", isPresented: $confirmRestart) {
      Button("Restart game", role: .destructive) { game.newGame() }
      Button("Cancel", role: .cancel) {}
    }
  }

  private var masthead: some View {
    VStack(spacing: 0) {
      HStack {
        eyebrow("No. 01  /  ELECTRIC PINBALL")
        Spacer()
        Button {
          settings = true
        } label: {
          Image(systemName: "slider.horizontal.3").font(.system(size: 16)).frame(
            width: 44, height: 44)
        }.accessibilityLabel("Settings").accessibilityIdentifier("settingsButton")
      }
      BrandLockup().frame(height: 82)
      DecoRule().frame(height: 10).padding(.top, 6)
    }
  }

  private var homeFooter: some View {
    VStack(spacing: 10) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          eyebrow("HOUSE RECORD")
          Text("\(game.best.formatted()) V")
            .font(.custom("AvenirNextCondensed-DemiBold", size: 19))
            .foregroundStyle(Color(Ink.cream))
        }
        Spacer()
        Text("THREE BALLS.\nONE CITY TO WAKE.")
          .font(.custom("AvenirNextCondensed-DemiBold", size: 11)).tracking(1.2)
          .multilineTextAlignment(.trailing).foregroundStyle(Color(Ink.brass))
      }
      primary("LIGHT UP THE NIGHT", icon: "arrow.up.right", identifier: "playButton") {
        game.start()
      }
      Text("A LITTLE CITY. A LOT OF ELECTRICITY.")
        .font(.custom("AvenirNextCondensed-Medium", size: 9)).tracking(1.8)
        .foregroundStyle(Color(Ink.brass)).padding(.top, 2)
    }
  }

  private var scoreboard: some View {
    VStack(spacing: 9) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 8) {
          eyebrow("PLAYER 01  /  VOLTAGE")
          DotMatrixScore(value: game.score.points, color: Color(Ink.cream))
            .frame(height: 31)
            .accessibilityIdentifier("scoreValue")
        }
        VStack(spacing: 4) {
          Text("\(game.score.multiplier)×").font(.custom("Baskerville-Italic", size: 25))
            .foregroundStyle(Color(Ink.cyan))
          HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { ball in
              Circle().fill(
                ball >= game.ballNumber ? Color(Ink.cream) : Color(Ink.brass).opacity(0.25)
              )
              .frame(width: 5, height: 5)
            }
          }
          Text("BALL \(game.ballNumber)/3").font(
            .system(size: 8, weight: .medium, design: .monospaced)
          )
          .foregroundStyle(Color(Ink.brass)).accessibilityIdentifier("ballCount")
        }
        Button {
          game.pause()
        } label: {
          Image(systemName: "pause.fill").font(.system(size: 14)).frame(width: 44, height: 44)
            .background(Color(Ink.brass).opacity(0.08), in: Circle())
        }.accessibilityLabel("Pause game").accessibilityIdentifier("pauseButton")
      }
      .padding(13)
      .background(
        LinearGradient(
          colors: [Color.black.opacity(0.8), Color(Ink.panel)], startPoint: .top, endPoint: .bottom),
        in: RoundedRectangle(cornerRadius: 9)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 9).stroke(Color(Ink.brass).opacity(0.55), lineWidth: 0.7))
      HStack {
        Image(systemName: "bolt.fill").font(.system(size: 9))
        Text(game.banner).font(.custom("AvenirNextCondensed-DemiBold", size: 12)).tracking(1.1)
          .foregroundStyle(Color(Ink.cyan)).lineLimit(1).minimumScaleFactor(0.7)
        Spacer()
      }.foregroundStyle(Color(Ink.cyan)).padding(.horizontal, 4)
    }
  }

  private var controls: some View {
    VStack(spacing: 8) {
      if !game.inFlight {
        Button {
          game.launch()
        } label: {
          HStack {
            Text(game.ballNumber == 1 ? "LAUNCH BALL" : "LAUNCH BALL \(game.ballNumber)")
            Spacer()
            Image(systemName: "arrow.up.forward")
          }
          .font(.custom("AvenirNextCondensed-Bold", size: 14)).tracking(2)
          .padding(.horizontal, 20).frame(height: 42)
        }.buttonStyle(MachineButtonStyle(color: Color(Ink.cyan))).accessibilityIdentifier(
          "launchButton")
      } else {
        Text("TAP OR HOLD A SIDE TO FLIP")
          .font(.custom("AvenirNextCondensed-Medium", size: 10)).tracking(1.4)
          .foregroundStyle(Color(Ink.brass)).frame(height: 42)
      }
      HStack(spacing: 12) {
        FlipperControl(left: true, game: game)
        FlipperControl(left: false, game: game)
      }
    }
  }

  private var tutorial: some View {
    VStack(alignment: .leading, spacing: 19) {
      eyebrow("A QUICK WORD FROM THE HOUSE")
      Text("Make the\ncity hum.").font(.custom("Baskerville-Italic", size: 43)).foregroundStyle(
        Color(Ink.cream))
      DecoRule().frame(height: 8)
      lesson(
        "01", title: "Launch. Then play both sides.",
        text: "Tap the coral pads to flip. Hold a pad to keep its flipper raised.")
      lesson(
        "02", title: "Follow the cyan light.",
        text:
          "Hit Arcade → Spire → Riviera. A full circuit lights the skyline and raises your multiplier."
      )
      lesson(
        "03", title: "Three balls. Make them count.",
        text: "A ball below the flippers is lost. Keep your circuit progress and launch the next.")
      primary("LET’S PLAY", icon: "arrow.right", identifier: "tutorialStart") { game.newGame() }
    }
    .padding(24)
    .background(Color(Ink.background).opacity(0.98), in: RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(Ink.brass).opacity(0.8), lineWidth: 1))
    .shadow(color: .black, radius: 25, y: 12)
  }

  private func lesson(_ number: String, title: String, text: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Text(number).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundStyle(
        Color(Ink.cyan))
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.system(size: 14, weight: .semibold))
        Text(text).font(.system(size: 12)).foregroundStyle(Color(Ink.cream).opacity(0.7)).fixedSize(
          horizontal: false, vertical: true)
      }.foregroundStyle(Color(Ink.cream))
    }
  }

  private var pauseOverlay: some View {
    ZStack {
      Color(Ink.background).opacity(0.94).ignoresSafeArea()
      VStack(spacing: 21) {
        eyebrow("TAKE A BREATHER")
        DecoRule().frame(height: 10)
        Text("The night\ncan wait.").font(.custom("Baskerville-Italic", size: 51))
          .multilineTextAlignment(
            .center)
        primary("RESUME", icon: "play.fill", identifier: "resumeButton") { game.paused = false }
        Button("Restart game") { confirmRestart = true }.frame(minHeight: 44)
          .accessibilityIdentifier("restartButton")
        Button("Settings") { settings = true }.frame(minHeight: 44)
        Button("Return to club") {
          game.screen = .home
          game.paused = false
        }.frame(minHeight: 44)
      }.padding(36).foregroundStyle(Color(Ink.cream))
    }
  }

  private var results: some View {
    VStack(spacing: 16) {
      ScorePoster(score: game.score, best: game.best, newRecord: game.newRecord)
        .frame(maxHeight: .infinity)
      VStack(spacing: 10) {
        primary("ONE MORE NIGHT", icon: "arrow.clockwise", identifier: "replayButton") {
          game.newGame()
        }
        HStack {
          Button {
            share()
          } label: {
            Label("SHARE POSTER", systemImage: "square.and.arrow.up")
              .font(.system(size: 11, weight: .semibold, design: .monospaced)).frame(
                maxWidth: .infinity, minHeight: 44)
          }.accessibilityIdentifier("shareButton")
          Button {
            game.screen = .home
          } label: {
            Image(systemName: "house").frame(width: 48, height: 44)
          }.accessibilityLabel("Return home").accessibilityIdentifier("homeButton")
        }.foregroundStyle(Color(Ink.brass))
      }
    }.padding(24)
  }

  private func share() {
    let renderer = ImageRenderer(
      content: ScorePoster(score: game.score, best: game.best, newRecord: game.newRecord).frame(
        width: 390, height: 620))
    renderer.scale = 3
    guard let image = renderer.uiImage else { return }
    shareItem = SharePoster(
      image: image,
      text:
        "I powered the night: \(game.score.points.formatted()) volts and \(game.score.circuits) \(game.score.circuits == 1 ? "circuit" : "circuits") in Velvet Voltage."
    )
  }

  private var settingsView: some View {
    NavigationStack {
      Form {
        Section("The atmosphere") {
          Toggle("Arcade audio", isOn: $game.sound).accessibilityIdentifier("soundToggle")
          Toggle("Haptic feedback", isOn: $game.haptics).accessibilityIdentifier("hapticsToggle")
        }
        Section("Your club record · on this iPhone") {
          LabeledContent("Personal best", value: "\(game.best.formatted()) V")
          LabeledContent("Completed circuits", value: "\(game.lifetimeCircuits)")
          LabeledContent("Finished games", value: "\(game.gamesPlayed)")
        }
        Section {
          Text(
            "Hit the cyan district in order: Arcade, Spire, Riviera. Bumpers earn 100 × multiplier; ordered hits add 250 ×. A circuit adds 1,500 × and raises the multiplier up to 5×. Three balls per game."
          )
          .font(.footnote)
          Text(
            "Progress saves automatically. An interrupted game pauses while the app stays open; relaunch returns to the club with your records intact."
          ).font(.footnote)
        } header: {
          Text("House rules")
        }
      }
      .tint(Color(Ink.coral))
      .navigationTitle("Club settings")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) { Button("Done") { settings = false } }
      }
    }.presentationDetents([.large])
  }

  private func eyebrow(_ text: String) -> some View {
    Text(text).font(.custom("AvenirNextCondensed-DemiBold", size: 10)).tracking(1.5)
      .foregroundStyle(Color(Ink.brass))
  }

  private func primary(
    _ text: String, icon: String, identifier: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack {
        Text(text).tracking(2)
        Spacer()
        Image(systemName: icon)
      }
      .font(.custom("AvenirNextCondensed-Bold", size: 15))
      .padding(.horizontal, 22).frame(height: 54)
    }.buttonStyle(MachineButtonStyle(color: Color(Ink.coral))).accessibilityIdentifier(identifier)
  }
}

struct FlipperControl: View {
  let left: Bool
  @ObservedObject var game: GameSession
  @State private var pressed = false
  var body: some View {
    HStack(spacing: 9) {
      Image(systemName: left ? "arrow.up.left" : "arrow.up.right")
        .font(.system(size: 13, weight: .semibold))
      Text(left ? "LEFT FLIPPER" : "RIGHT FLIPPER")
        .font(.custom("AvenirNextCondensed-DemiBold", size: 12)).tracking(1.2)
    }
    .frame(maxWidth: .infinity).frame(height: 56)
    .foregroundStyle(pressed ? Color(Ink.background) : Color(Ink.cream))
    .background(
      LinearGradient(
        colors: pressed
          ? [Color(Ink.coral), Color(Ink.coral)] : [Color(Ink.panel), Color(Ink.background)],
        startPoint: .top, endPoint: .bottom
      ), in: RoundedRectangle(cornerRadius: 10)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 10).stroke(Color(Ink.brass).opacity(0.65), lineWidth: 1)
    )
    .overlay(alignment: .bottom) {
      Capsule().fill(Color(Ink.coral)).frame(width: 30, height: 2).padding(.bottom, 7)
    }
    .offset(y: pressed ? 2 : 0)
    .contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 0).onChanged { _ in
        pressed = true
        game.setFlipper(left: left, pressed: true)
      }.onEnded { _ in
        pressed = false
        game.setFlipper(left: left, pressed: false)
      }
    )
    .onChange(of: game.paused) { _, _ in pressed = false }
    .onChange(of: game.inFlight) { _, value in if !value { pressed = false } }
    .accessibilityElement()
    .accessibilityLabel(left ? "Left flipper" : "Right flipper")
    .accessibilityAddTraits(.isButton)
    .accessibilityIdentifier(left ? "leftFlipper" : "rightFlipper")
    .accessibilityAction {
      game.setFlipper(left: left, pressed: true)
      Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(200))
        game.setFlipper(left: left, pressed: false)
      }
    }
  }
}

struct BrandLockup: View {
  var body: some View {
    VStack(spacing: -5) {
      Text("Velvet").font(.custom("Baskerville-Italic", size: 58))
      HStack(spacing: 10) {
        Rectangle().frame(width: 21, height: 0.7)
        Text("VOLTAGE").font(.custom("AvenirNextCondensed-DemiBold", size: 21)).tracking(6)
        Rectangle().frame(width: 21, height: 0.7)
      }.foregroundStyle(Color(Ink.brass))
    }
    .foregroundStyle(Color(Ink.cream))
    .accessibilityElement(children: .ignore).accessibilityLabel("Velvet Voltage")
  }
}

struct DecoRule: View {
  var body: some View {
    HStack(spacing: 7) {
      Rectangle().frame(height: 0.5)
      Rectangle().frame(width: 4, height: 4).rotationEffect(.degrees(45))
      Rectangle().frame(width: 7, height: 7).rotationEffect(.degrees(45))
      Rectangle().frame(width: 4, height: 4).rotationEffect(.degrees(45))
      Rectangle().frame(height: 0.5)
    }.foregroundStyle(Color(Ink.brass).opacity(0.7)).accessibilityHidden(true)
  }
}

struct MachineButtonStyle: ButtonStyle {
  let color: Color
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(Color(Ink.background))
      .background(
        LinearGradient(colors: [color, color.opacity(0.85)], startPoint: .top, endPoint: .bottom),
        in: RoundedRectangle(cornerRadius: 9)
      )
      .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(0.25), lineWidth: 0.7))
      .background(
        RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.3)).offset(y: 3)
      )
      .offset(y: configuration.isPressed ? 2 : 0)
      .brightness(configuration.isPressed ? -0.1 : 0)
  }
}

struct DotMatrixScore: View {
  let value: Int
  let color: Color
  private static let glyphs: [Character: [UInt8]] = [
    "0": [14, 17, 19, 21, 25, 17, 14],
    "1": [4, 12, 4, 4, 4, 4, 14],
    "2": [14, 17, 1, 2, 4, 8, 31],
    "3": [30, 1, 1, 14, 1, 1, 30],
    "4": [2, 6, 10, 18, 31, 2, 2],
    "5": [31, 16, 16, 30, 1, 1, 30],
    "6": [14, 16, 16, 30, 17, 17, 14],
    "7": [31, 1, 2, 4, 8, 8, 8],
    "8": [14, 17, 17, 14, 17, 17, 14],
    "9": [14, 17, 17, 15, 1, 1, 14],
  ]

  var body: some View {
    Canvas { context, size in
      let number = String(value)
      let characters = Array(String(repeating: "0", count: max(0, 6 - number.count)) + number)
      let columns = CGFloat(characters.count * 6 - 1)
      let cell = min(size.width / columns, size.height / 7)
      let origin = CGPoint(x: (size.width - cell * columns) / 2, y: (size.height - cell * 7) / 2)
      for (index, digit) in characters.enumerated() {
        let rows = Self.glyphs[digit] ?? Self.glyphs["0"]!
        for row in 0..<7 {
          for column in 0..<5 {
            let lit = rows[row] & (1 << (4 - column)) != 0
            let dot = CGRect(
              x: origin.x + CGFloat(index * 6 + column) * cell + cell * 0.12,
              y: origin.y + CGFloat(row) * cell + cell * 0.12,
              width: cell * 0.76, height: cell * 0.76
            )
            context.fill(Path(ellipseIn: dot), with: .color(color.opacity(lit ? 1 : 0.08)))
          }
        }
      }
    }
    .accessibilityElement().accessibilityLabel("\(value.formatted()) volts")
  }
}

struct ScorePoster: View {
  let score: ScoreCard
  let best: Int
  var newRecord = false
  var body: some View {
    GeometryReader { proxy in
      VStack(spacing: 0) {
        ZStack(alignment: .top) {
          Image("MidnightCity").resizable().scaledToFill()
            .frame(width: proxy.size.width, height: proxy.size.height * 0.48).clipped()
          LinearGradient(
            stops: [
              .init(color: .black.opacity(0.85), location: 0), .init(color: .clear, location: 0.55),
              .init(color: .black.opacity(0.65), location: 1),
            ],
            startPoint: .top, endPoint: .bottom)
          VStack(spacing: 7) {
            Text("THE ELECTRIC SOCIAL CLUB")
              .font(.custom("AvenirNextCondensed-DemiBold", size: 9)).tracking(2.5)
            Text("What a night.").font(.custom("Baskerville-Italic", size: 38))
            Spacer()
            Text(score.circuits > 0 ? "YOU BROUGHT THE CITY TO LIFE" : "THE CITY WANTS AN ENCORE")
              .font(.custom("AvenirNextCondensed-DemiBold", size: 9)).tracking(1.4)
          }.foregroundStyle(Color(Ink.cream)).padding(.vertical, 21)
        }
        .frame(height: proxy.size.height * 0.48)
        VStack(spacing: 0) {
          HStack {
            Text("AFTER HOURS")
            Spacer()
            Text("SESSION COMPLETE")
          }.font(.custom("AvenirNextCondensed-DemiBold", size: 9)).tracking(1.4)
          Rectangle().frame(height: 0.7).opacity(0.3).padding(.top, 10)
          Spacer(minLength: 10)
          DotMatrixScore(value: score.points, color: Color(Ink.background))
            .frame(height: min(49, proxy.size.height * 0.085))
            .accessibilityIdentifier("resultScore")
          Text("VOLTS GENERATED").font(.custom("AvenirNextCondensed-DemiBold", size: 9))
            .tracking(3).padding(.top, 9)
          Spacer(minLength: 10)
          HStack(spacing: 28) {
            Text("\(score.circuits) \(score.circuits == 1 ? "CIRCUIT" : "CIRCUITS")")
            Text("\(score.multiplier)× POWER")
          }.font(.custom("AvenirNextCondensed-DemiBold", size: 14)).tracking(1)
          Text(newRecord ? "A NEW HOUSE RECORD" : "PERSONAL BEST  \(best.formatted()) V")
            .font(.custom("AvenirNextCondensed-DemiBold", size: 10)).tracking(1.2).padding(.top, 8)
          Spacer(minLength: 10)
          Rectangle().frame(height: 0.7).opacity(0.3)
          HStack(alignment: .firstTextBaseline) {
            Text("Velvet Voltage").font(.custom("Baskerville-Italic", size: 21))
            Spacer()
            Text("PLAY IT AGAIN.").font(.custom("AvenirNextCondensed-DemiBold", size: 8)).tracking(
              1.3)
          }.padding(.top, 10)
        }
        .padding(20).foregroundStyle(Color(Ink.background))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(Ink.cream))
      }
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(Ink.brass), lineWidth: 1))
    }
  }
}

struct SharePoster: Identifiable {
  let id = UUID()
  let image: UIImage
  let text: String
}

struct ShareSheet: UIViewControllerRepresentable {
  let image: UIImage
  let text: String
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
