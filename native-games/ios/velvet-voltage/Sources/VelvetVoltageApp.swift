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
        Color(Ink.background).ignoresSafeArea()
        if game.screen == .results {
          results
        } else {
          VStack(spacing: 0) {
            if game.screen == .playing { scoreboard } else { masthead }
            ZStack {
              if let scene {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
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
    VStack(spacing: 7) {
      HStack {
        eyebrow("EST. AFTER DARK")
        Spacer()
        Button {
          settings = true
        } label: {
          Image(systemName: "slider.horizontal.3").font(.system(size: 18)).frame(
            width: 44, height: 44)
        }.accessibilityLabel("Settings").accessibilityIdentifier("settingsButton")
      }
      HStack(alignment: .firstTextBaseline, spacing: 9) {
        Text("Velvet").font(.custom("Didot-Italic", size: 47))
        Text("Voltage").font(.custom("Didot", size: 47))
      }
      .minimumScaleFactor(0.65).lineLimit(1)
      .foregroundStyle(Color(Ink.cream))
      Text("A LITTLE CITY. A LOT OF ELECTRICITY.")
        .font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1.8)
        .foregroundStyle(Color(Ink.brass))
    }
  }

  private var homeFooter: some View {
    VStack(spacing: 10) {
      HStack {
        eyebrow("PERSONAL BEST")
        Spacer()
        Text("\(game.best.formatted()) V").font(
          .system(size: 16, weight: .medium, design: .monospaced)
        )
        .foregroundStyle(Color(Ink.cyan))
      }
      primary("POWER ON", icon: "bolt.fill", identifier: "playButton") { game.start() }
      HStack(spacing: 6) {
        Text("3 BALLS").foregroundStyle(Color(Ink.cream))
        Text(" / ").foregroundStyle(Color(Ink.coral))
        Text("ONE CITY TO WAKE").foregroundStyle(Color(Ink.brass))
      }.font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.6)
    }
  }

  private var scoreboard: some View {
    VStack(spacing: 10) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 1) {
          eyebrow("VOLTAGE")
          Text(game.score.points.formatted())
            .font(.system(size: 33, weight: .light, design: .monospaced))
            .foregroundStyle(Color(Ink.cream)).contentTransition(.numericText())
            .accessibilityIdentifier("scoreValue")
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 4) {
          Text("\(game.score.multiplier)×").font(.custom("Didot-Italic", size: 27)).foregroundStyle(
            Color(Ink.cyan))
          Text("BALL \(game.ballNumber) / 3").font(
            .system(size: 12, weight: .medium, design: .monospaced)
          )
          .foregroundStyle(Color(Ink.brass)).accessibilityIdentifier("ballCount")
        }
        Button {
          game.pause()
        } label: {
          Image(systemName: "pause").font(.system(size: 19)).frame(width: 44, height: 44)
        }.accessibilityLabel("Pause game").accessibilityIdentifier("pauseButton")
      }
      HStack {
        Circle().fill(Color(Ink.cyan)).frame(width: 4, height: 4)
        Text(game.banner).font(.system(size: 12, weight: .medium, design: .monospaced)).tracking(
          0.7
        )
        .foregroundStyle(Color(Ink.cyan)).lineLimit(1).minimumScaleFactor(0.7)
        Spacer()
      }
    }
  }

  private var controls: some View {
    VStack(spacing: 8) {
      if !game.inFlight {
        Button {
          game.launch()
        } label: {
          HStack {
            Image(systemName: "arrow.up")
            Text(game.ballNumber == 1 ? "LAUNCH BALL" : "LAUNCH BALL \(game.ballNumber)")
            Image(systemName: "arrow.up")
          }
          .font(.system(size: 12, weight: .semibold, design: .monospaced)).tracking(1.5)
          .foregroundStyle(Color(Ink.background)).frame(maxWidth: .infinity).frame(height: 46)
          .background(Color(Ink.cyan), in: RoundedRectangle(cornerRadius: 7))
        }.accessibilityIdentifier("launchButton")
      } else {
        Text("TAP OR HOLD A SIDE TO FLIP")
          .font(.system(size: 11, weight: .medium, design: .monospaced)).tracking(1)
          .foregroundStyle(Color(Ink.brass)).frame(height: 46)
      }
      HStack(spacing: 12) {
        FlipperControl(left: true, game: game)
        FlipperControl(left: false, game: game)
      }
    }
  }

  private var tutorial: some View {
    VStack(alignment: .leading, spacing: 19) {
      eyebrow("YOUR FIRST NIGHT")
      Text("Make the\ncity hum.").font(.custom("Didot", size: 42)).foregroundStyle(Color(Ink.cream))
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
    .background(Color(Ink.background).opacity(0.97), in: RoundedRectangle(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(Ink.brass).opacity(0.5), lineWidth: 1))
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
        Text("The night\ncan wait.").font(.custom("Didot-Italic", size: 51)).multilineTextAlignment(
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
    Text(text).font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1.5)
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
      .font(.system(size: 13, weight: .semibold, design: .monospaced))
      .foregroundStyle(Color(Ink.background)).padding(.horizontal, 22).frame(height: 54)
      .background(Color(Ink.coral), in: RoundedRectangle(cornerRadius: 7))
    }.accessibilityIdentifier(identifier)
  }
}

struct FlipperControl: View {
  let left: Bool
  @ObservedObject var game: GameSession
  @State private var pressed = false
  var body: some View {
    Text(left ? "↖  LEFT" : "RIGHT  ↗")
      .font(.system(size: 13, weight: .semibold, design: .monospaced)).tracking(2)
      .frame(maxWidth: .infinity).frame(height: 56)
      .foregroundStyle(pressed ? Color(Ink.background) : Color(Ink.coral))
      .background(
        pressed ? Color(Ink.coral) : Color(Ink.coral).opacity(0.1),
        in: RoundedRectangle(cornerRadius: 8)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 8).stroke(Color(Ink.coral).opacity(0.6), lineWidth: 1)
      )
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

struct ScorePoster: View {
  let score: ScoreCard
  let best: Int
  var newRecord = false
  var body: some View {
    GeometryReader { proxy in
      VStack(spacing: 0) {
        Text("THE ELECTRIC SOCIAL CLUB").font(
          .system(size: 9, weight: .medium, design: .monospaced)
        ).tracking(2).padding(.top, 22)
        Spacer(minLength: 12)
        Text("What a\nnight.").font(
          .custom("Didot-Italic", size: min(57, proxy.size.height * 0.10))
        )
        .lineSpacing(-7).multilineTextAlignment(.center).foregroundStyle(Color(Ink.cream))
        Text(score.circuits > 0 ? "YOU BROUGHT THE CITY TO LIFE" : "THE CITY WANTS AN ENCORE")
          .font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(1.2).padding(
            .top, 15)
        Spacer(minLength: 12)
        CitySilhouette().frame(height: min(125, proxy.size.height * 0.23)).padding(.horizontal, 18)
        Rectangle().fill(Color(Ink.brass)).frame(height: 1).padding(.horizontal, 12)
        Text(score.points.formatted()).font(
          .system(size: 62, weight: .ultraLight, design: .monospaced)
        )
        .lineLimit(1).minimumScaleFactor(0.5).padding(.horizontal, 12)
        .foregroundStyle(Color(Ink.cyan)).padding(.top, 15).accessibilityIdentifier("resultScore")
        Text("V O L T S  G E N E R A T E D").font(
          .system(size: 8, weight: .medium, design: .monospaced))
        HStack(spacing: 26) {
          Text("\(score.circuits) \(score.circuits == 1 ? "CIRCUIT" : "CIRCUITS")")
          Text("\(score.multiplier)× POWER")
        }.font(.system(size: 10, weight: .medium, design: .monospaced)).padding(.top, 22)
        Text(newRecord ? "NEW PERSONAL BEST" : "PERSONAL BEST  \(best.formatted()) V").font(
          .system(size: 11, design: .monospaced)
        )
        .padding(.top, 10)
        Spacer(minLength: 12)
        Text("Velvet Voltage").font(.custom("Didot", size: 25)).foregroundStyle(Color(Ink.cream))
        Text("POWER THE NIGHT").font(.system(size: 7, weight: .medium, design: .monospaced))
          .tracking(3).padding(.top, 6).padding(.bottom, 22)
      }.frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color(Ink.brass))
        .background(Color(Ink.background))
        .overlay(Rectangle().stroke(Color(Ink.brass).opacity(0.5), lineWidth: 1))
    }
  }
}

struct CitySilhouette: View {
  var body: some View {
    Canvas { context, size in
      for index in 0..<23 {
        let width = size.width / 25
        let height =
          size.height
          * Double([3, 4, 3, 5, 4, 6, 4, 7, 5, 8, 6, 10, 7, 8, 5, 7, 4, 6, 4, 5, 3, 4, 2][index])
          / 10
        let x = Double(index) * (width + 1.2)
        let rect = CGRect(x: x, y: size.height - height, width: width, height: height)
        context.fill(Path(rect), with: .color(Color(Ink.panel)))
        context.stroke(Path(rect), with: .color(Color(Ink.brass).opacity(0.6)), lineWidth: 0.6)
        for row in 0..<max(1, Int(height / 9)) {
          let window = CGRect(
            x: x + width / 2, y: size.height - height + 5 + Double(row) * 9, width: 2, height: 3)
          context.fill(
            Path(window), with: .color(index % 3 == 0 ? Color(Ink.cyan) : Color(Ink.brass)))
        }
      }
    }.accessibilityHidden(true)
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
