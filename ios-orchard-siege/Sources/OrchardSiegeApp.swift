import SpriteKit
import SwiftUI

@main
struct OrchardSiegeApp: App {
  @StateObject private var game = GameModel()
  @Environment(\.scenePhase) private var phase

  var body: some Scene {
    WindowGroup {
      OrchardView(game: game)
        .preferredColorScheme(.light)
        .statusBarHidden()
        .onChange(of: phase) { _, value in
          if value != .active { game.setPaused(true) }
        }
    }
  }
}

private enum Palette {
  static let ink = Color(red: 0.15, green: 0.24, blue: 0.19)
  static let green = Color(red: 0.25, green: 0.38, blue: 0.26)
  static let cream = Color(red: 1, green: 0.97, blue: 0.88)
  static let coral = Color(red: 0.79, green: 0.31, blue: 0.23)
  static let muted = Color(red: 0.40, green: 0.45, blue: 0.34)
}

struct OrchardView: View {
  @ObservedObject var game: GameModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ZStack {
      Color(red: 0.96, green: 0.87, blue: 0.73).ignoresSafeArea()
      SpriteView(scene: game.scene, options: [.ignoresSiblingOrder])
        .ignoresSafeArea()
        .accessibilityLabel("Orchard slingshot playfield")
        .accessibilityIdentifier("playfield")
      switch game.screen {
      case .home: home
      case .levels: levelMap
      case .playing: gameplay
      }
      if game.paused { pausePanel }
      if game.showHelp { helpPanel }
      if let result = game.result { resultPanel(result) }
    }
    .font(.system(size: 15, weight: .medium, design: .rounded))
    .foregroundStyle(Palette.ink)
    .dynamicTypeSize(.xSmall ... .xxxLarge)
  }

  private var home: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        eyebrow("A LITTLE MISCHIEF. A LOVELY ORCHARD.")
        Spacer()
        iconButton(game.sound ? "speaker.wave.2" : "speaker.slash", label: "Toggle sound") {
          game.sound.toggle()
        }
        iconButton("questionmark", label: "How to play") { game.showHelp = true }
      }
      Spacer(minLength: 10)
      VStack(alignment: .leading, spacing: 10) {
        Text("Orchard\nSiege")
          .font(.custom("Georgia-Bold", size: 54))
          .lineSpacing(-8)
          .tracking(-2)
          .fixedSize()
        Text("Small fruit. Glorious destruction.")
          .font(.custom("Georgia-Italic", size: 15))
          .foregroundStyle(Palette.ink)
          .padding(.horizontal, 12)
          .padding(.vertical, 7)
          .background(Palette.cream.opacity(0.93), in: Capsule())
        HStack(spacing: 10) {
          primary("Let’s play", icon: "arrow.right", identifier: "play") {
            game.start(game.unlocked)
          }
          Button {
            game.screen = .levels
          } label: {
            Image(systemName: "square.grid.2x2")
              .font(.system(size: 19, weight: .semibold))
              .frame(width: 50, height: 50)
              .background(Palette.cream.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
              .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.ink.opacity(0.14)))
          }
          .accessibilityLabel("Choose a level")
          .accessibilityIdentifier("levels")
        }
        .padding(.top, 4)
      }
      Spacer(minLength: 10)
      HStack(spacing: 8) {
        Image(systemName: "leaf.fill")
        Text("SIX GARDEN FORTS")
        Text("·")
        Text("\(game.totalStars) / 18 STARS")
      }
      .font(.system(size: 10, weight: .bold, design: .rounded))
      .tracking(1.3)
      .foregroundStyle(Palette.cream)
    }
    .padding(.horizontal, 28)
    .padding(.vertical, 14)
  }

  private var levelMap: some View {
    ZStack {
      Palette.cream.opacity(0.92).ignoresSafeArea()
      VStack(spacing: 16) {
        HStack {
          iconButton("arrow.left", label: "Back to orchard") { game.home() }
          VStack(alignment: .leading, spacing: 2) {
            Text("The garden trail").font(.custom("Georgia-Bold", size: 28))
            Text("Six forts. Eighteen stars. A little room for mischief.")
              .font(.system(size: 12)).foregroundStyle(Palette.muted)
          }
          Spacer()
          Label("\(game.totalStars) / 18", systemImage: "star.fill")
            .foregroundStyle(Palette.green)
        }
        LazyVGrid(
          columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12
        ) {
          ForEach(Array(Level.all.enumerated()), id: \.offset) { index, level in
            let locked = index > game.unlocked
            Button {
              game.start(index)
            } label: {
              HStack(spacing: 12) {
                Text(String(format: "%02d", index + 1))
                  .font(.custom("Georgia", size: 26))
                  .foregroundStyle(locked ? Palette.muted : Palette.coral)
                VStack(alignment: .leading, spacing: 7) {
                  Text(level.name).font(.system(size: 14, weight: .bold))
                    .lineLimit(1).minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                  if locked {
                    Label("Clear the previous fort", systemImage: "lock.fill")
                      .font(.system(size: 9))
                  } else {
                    stars(game.stars[String(index)] ?? 0, size: 13)
                    Text("BEST  \(game.best[String(index)] ?? 0)")
                      .font(.system(size: 9, weight: .bold)).tracking(0.6)
                  }
                }
              }
              .padding(13)
              .frame(maxWidth: .infinity, alignment: .leading)
              .frame(height: 94)
              .multilineTextAlignment(.leading)
              .background(
                locked ? Color.white.opacity(0.3) : Color.white.opacity(0.68),
                in: RoundedRectangle(cornerRadius: 18)
              )
              .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.green.opacity(0.17)))
            }
            .disabled(locked)
            .accessibilityIdentifier("level-\(index + 1)")
          }
        }
        Text("Stars reward fewer shots. Unused fruit earns 1,500 bonus points each.")
          .font(.system(size: 11)).foregroundStyle(Palette.muted)
      }
      .padding(.horizontal, 28)
      .padding(.vertical, 12)
    }
  }

  private var gameplay: some View {
    VStack {
      HStack(spacing: 10) {
        iconButton("pause.fill", label: "Pause game") { game.setPaused(true) }
        HStack(spacing: 12) {
          Text(String(format: "%02d", game.currentLevel + 1))
            .font(.custom("Georgia-Bold", size: 27)).foregroundStyle(Palette.coral)
          VStack(alignment: .leading, spacing: 2) {
            Text(Level.all[game.currentLevel].subtitle)
              .font(.system(size: 8, weight: .bold)).tracking(1)
            Text(Level.all[game.currentLevel].name).font(.system(size: 14, weight: .bold))
          }
        }
        .padding(.horizontal, 14).frame(height: 50)
        .background(Palette.cream.opacity(0.96), in: RoundedRectangle(cornerRadius: 15))
        Spacer(minLength: 0)
        counter("leaf.fill", label: "PESTS", value: "\(game.targets)")
          .accessibilityLabel("\(game.targets) pests remaining")
        counter("sparkle", label: "SCORE", value: "\(game.score)")
          .accessibilityLabel("Score \(game.score)")
      }
      Spacer()
      HStack(spacing: 12) {
        HStack(spacing: 8) {
          Circle().fill(game.currentFruit == .plum ? Color.purple.opacity(0.6) : Palette.coral)
            .frame(width: 7, height: 7)
          Text(game.inFlight ? "IN FLIGHT" : game.currentFruit.label.uppercased())
            .font(.system(size: 10, weight: .heavy)).tracking(0.6)
          Text("·  \(game.shotsRemaining) LEFT")
            .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(Palette.cream)
        Spacer(minLength: 8)
        if game.canBurst {
          Button {
            game.scene.activateBurst()
          } label: {
            Label("Burst now", systemImage: "sparkles")
              .font(.system(size: 13, weight: .bold))
              .padding(.horizontal, 19).frame(height: 44)
              .background(
                Color(red: 0.88, green: 0.82, blue: 0.96),
                in: Capsule())
          }
          .accessibilityIdentifier("burst")
        } else {
          Text(game.inFlight ? "Watch the garden tumble…" : launchHint)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Palette.cream.opacity(0.92))
            .lineLimit(2)
        }
        iconButton("arrow.counterclockwise", label: "Retry level") {
          game.start(game.currentLevel)
        }
      }
      .opacity(game.result == nil ? 1 : 0)
      .allowsHitTesting(game.result == nil)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }

  private var launchHint: String {
    switch game.currentFruit {
    case .apple: return Level.all[game.currentLevel].hint
    case .plum: return "Pull, release, then tap Burst now near the fort."
    case .pear: return "Pull the heavy pear back. Aim for lower supports."
    }
  }

  private var pausePanel: some View {
    modal {
      VStack(spacing: 14) {
        eyebrow("TAKE A BREATHER")
        Text("The orchard can wait.").font(.custom("Georgia-Bold", size: 28))
        Text("Your fruit and fort are right where you left them.")
          .font(.system(size: 13)).foregroundStyle(Palette.muted)
        primary("Keep playing", icon: "play.fill", identifier: "resume") { game.setPaused(false) }
        HStack(spacing: 24) {
          textButton("Retry") { game.start(game.currentLevel) }
          textButton(game.sound ? "Sound on" : "Sound off") { game.sound.toggle() }
          textButton("Garden trail") { game.home(levels: true) }
        }
      }
      .padding(28)
    }
  }

  private var helpPanel: some View {
    modal {
      VStack(spacing: 15) {
        eyebrow("A FIELD GUIDE TO FRUIT FLINGING")
        Text("A good day to topple a fort.").font(.custom("Georgia-Bold", size: 27))
        HStack(alignment: .top, spacing: 22) {
          helpStep(
            "hand.draw", title: "Pull & release",
            text: "Drag the fruit backwards.\nThe dots show your arc.")
          helpStep(
            "sparkles", title: "Make it tumble",
            text: "Hit the supports.\nClear every garden pest.")
          helpStep(
            "bolt.circle", title: "Plum power",
            text: "Tap while a plum flies.\nBurst through nearby blocks.")
        }
        Text("Apples fly true · Pears hit hard · Plums burst on tap")
          .font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.muted)
        primary("Got it. Let’s grow.", icon: "checkmark", identifier: "dismiss-help") {
          game.showHelp = false
        }
      }
      .padding(25)
    }
  }

  private func resultPanel(_ result: HarvestResult) -> some View {
    modal {
      HStack(spacing: 25) {
        VStack(spacing: 13) {
          Image(uiImage: UIImage(cgImage: OrchardArt.fruit(result.won ? .apple : .plum).cgImage()))
            .resizable().scaledToFit().frame(width: 102, height: 113)
          stars(result.stars, size: 25)
          Text(result.won ? "FORT CLEARED" : "\(game.targets) PESTS REMAIN")
            .font(.system(size: 9, weight: .heavy)).tracking(1.5)
        }
        .frame(width: 133)
        Rectangle().fill(Palette.green.opacity(0.15)).frame(width: 1, height: 207)
        VStack(alignment: .leading, spacing: 10) {
          eyebrow(result.newBest ? "A FRESH PERSONAL BEST" : "THE HARVEST REPORT")
          Text(result.won ? "Sweet victory." : "One more fling?")
            .font(.custom("Georgia-Bold", size: 29)).tracking(-0.7)
          Text("\(result.score.formatted())")
            .font(.system(size: 36, weight: .bold, design: .rounded)).monospacedDigit()
          Text(
            result.won
              ? "\(result.shots) \(result.shots == 1 ? "shot" : "shots") used · \(game.shotsRemaining) fruit saved"
              : "Aim lower at the supports, or burst a plum nearby."
          )
          .font(.system(size: 12)).foregroundStyle(Palette.muted)
          .fixedSize(horizontal: false, vertical: true)
          if result.won {
            Text(
              result.stars == 3
                ? "A perfect three-star harvest."
                : "Use \(max(1, Level.all[game.currentLevel].par - 1)) shot\(Level.all[game.currentLevel].par > 2 ? "s" : "") for three stars."
            )
            .font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.green)
          }
          HStack(spacing: 12) {
            primary(
              result.won ? (game.currentLevel == 5 ? "Garden trail" : "Next fort") : "Try again",
              icon: "arrow.right", identifier: "result-primary"
            ) {
              if result.won && game.currentLevel == 5 {
                game.home(levels: true)
              } else {
                game.start(result.won ? game.currentLevel + 1 : game.currentLevel)
              }
            }
            if result.won {
              iconButton("arrow.counterclockwise", label: "Improve this harvest") {
                game.start(game.currentLevel)
              }
            }
          }
          textButton("Back to garden trail") { game.home(levels: true) }
        }
        .frame(width: 275, alignment: .leading)
      }
      .padding(26)
    }
  }

  private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Palette.ink.opacity(0.45).ignoresSafeArea().contentShape(Rectangle())
        .onTapGesture {}
      content()
        .background(Palette.cream, in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.7), lineWidth: 1.5))
        .shadow(color: Palette.ink.opacity(0.22), radius: 25, y: 12)
        .padding(12)
    }
  }

  private func helpStep(_ icon: String, title: String, text: String) -> some View {
    VStack(spacing: 8) {
      Image(systemName: icon).font(.system(size: 25)).foregroundStyle(Palette.coral)
        .frame(height: 30)
      Text(title).font(.system(size: 14, weight: .bold))
      Text(text).font(.system(size: 11)).foregroundStyle(Palette.muted)
        .multilineTextAlignment(.center).lineSpacing(3)
    }
    .frame(width: 150)
  }

  private func counter(_ icon: String, label: String, value: String) -> some View {
    HStack(spacing: 8) {
      Image(systemName: icon).foregroundStyle(Palette.green).font(.system(size: 17))
      VStack(alignment: .leading, spacing: 1) {
        Text(label).font(.system(size: 8, weight: .heavy)).tracking(1)
        Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).monospacedDigit()
      }
    }
    .padding(.horizontal, 13).frame(height: 50)
    .background(Palette.cream.opacity(0.96), in: RoundedRectangle(cornerRadius: 15))
  }

  private func stars(_ number: Int, size: CGFloat) -> some View {
    HStack(spacing: 5) {
      ForEach(0..<3) { index in
        Image(systemName: index < number ? "star.fill" : "star")
          .font(.system(size: size, weight: .semibold))
          .foregroundStyle(
            index < number
              ? Color(red: 0.78, green: 0.53, blue: 0.16)
              : Palette.muted.opacity(0.3))
      }
    }
    .accessibilityLabel("\(number) of 3 stars")
  }

  private func eyebrow(_ title: String) -> some View {
    Text(title).font(.system(size: 9, weight: .heavy, design: .rounded))
      .tracking(1.7).foregroundStyle(Palette.green)
  }

  private func primary(
    _ title: String, icon: String, identifier: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 20) {
        Text(title)
        Image(systemName: icon).font(.system(size: 13, weight: .bold))
      }
      .font(.system(size: 15, weight: .bold, design: .rounded))
      .padding(.horizontal, 22).frame(height: 50)
      .foregroundStyle(Palette.cream)
      .background(Palette.coral, in: RoundedRectangle(cornerRadius: 16))
      .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.18), lineWidth: 1))
      .shadow(color: Palette.coral.opacity(0.24), radius: 0, y: 4)
    }
    .buttonStyle(PressStyle())
    .accessibilityIdentifier(identifier)
  }

  private func iconButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View
  {
    Button(action: action) {
      Image(systemName: icon).font(.system(size: 16, weight: .semibold))
        .frame(width: 46, height: 46)
        .background(Palette.cream.opacity(0.96), in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Palette.ink.opacity(0.1)))
    }
    .accessibilityLabel(label)
    .accessibilityIdentifier(label)
  }

  private func textButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button(title, action: action)
      .font(.system(size: 12, weight: .bold))
      .foregroundStyle(Palette.green)
      .frame(minHeight: 36)
  }
}

private struct PressStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
      .opacity(configuration.isPressed ? 0.85 : 1)
      .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
  }
}
