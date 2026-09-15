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
  static let ink = Color(red: 0.16, green: 0.24, blue: 0.19)
  static let green = Color(red: 0.27, green: 0.42, blue: 0.28)
  static let leaf = Color(red: 0.55, green: 0.66, blue: 0.36)
  static let cream = Color(red: 1, green: 0.973, blue: 0.9)
  static let paper = Color(red: 0.985, green: 0.95, blue: 0.86)
  static let coral = Color(red: 0.83, green: 0.34, blue: 0.25)
  static let coralDeep = Color(red: 0.69, green: 0.24, blue: 0.19)
  static let gold = Color(red: 0.85, green: 0.6, blue: 0.2)
  static let muted = Color(red: 0.42, green: 0.46, blue: 0.36)
  static let plum = Color(red: 0.48, green: 0.4, blue: 0.65)
}

private struct Paper: ViewModifier {
  var radius: CGFloat = 18
  var opacity: CGFloat = 0.97
  func body(content: Content) -> some View {
    content
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Palette.cream.opacity(opacity))
          RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(
              LinearGradient(
                colors: [.white.opacity(0.9), .white.opacity(0.2)], startPoint: .top,
                endPoint: .bottom), lineWidth: 1)
          RoundedRectangle(cornerRadius: radius - 3, style: .continuous)
            .strokeBorder(Palette.green.opacity(0.14), lineWidth: 1)
            .padding(3)
        }
      )
      .shadow(color: Color(red: 0.35, green: 0.22, blue: 0.1).opacity(0.16), radius: 10, y: 5)
  }
}

extension View {
  fileprivate func paper(radius: CGFloat = 18, opacity: CGFloat = 0.97) -> some View {
    modifier(Paper(radius: radius, opacity: opacity))
  }
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
    .animation(
      reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.82),
      value: game.result == nil && !game.paused && !game.showHelp)
  }

  private var home: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Spacer()
        iconButton(game.sound ? "speaker.wave.2.fill" : "speaker.slash.fill", label: "Toggle sound")
        {
          game.sound.toggle()
        }
        iconButton("questionmark", label: "How to play") { game.showHelp = true }
      }
      Spacer(minLength: 6)
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 8) {
          ornament
          Text("A GOLDEN-HOUR SLINGSHOT TALE")
            .font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(2)
        }
        .foregroundStyle(Palette.green)
        Text("Orchard\nSiege")
          .font(.custom("Georgia-Bold", size: 60))
          .lineSpacing(-10)
          .tracking(-2.5)
          .fixedSize()
          .foregroundStyle(Palette.ink)
          .shadow(color: Palette.cream.opacity(0.9), radius: 0, x: 0, y: 2)
          .shadow(color: Palette.ink.opacity(0.12), radius: 18, y: 10)
        Text("Small fruit. Glorious destruction.")
          .font(.custom("Georgia-Italic", size: 16))
          .foregroundStyle(Palette.coralDeep)
          .padding(.horizontal, 12).padding(.vertical, 5)
          .background(Palette.cream.opacity(0.86), in: Capsule())
        HStack(spacing: 10) {
          primary("Let’s play", icon: "arrow.right", identifier: "play") {
            game.start(game.unlocked)
          }
          Button {
            game.screen = .levels
          } label: {
            HStack(spacing: 8) {
              Image(systemName: "star.fill").font(.system(size: 12, weight: .bold))
                .foregroundStyle(Palette.gold)
              Text("\(game.totalStars) / 18")
                .font(.system(size: 14, weight: .bold, design: .rounded)).monospacedDigit()
            }
            .padding(.horizontal, 16).frame(height: 50)
            .paper(radius: 16)
          }
          .buttonStyle(PressStyle())
          .accessibilityLabel("Choose a level. \(game.totalStars) of 18 stars")
          .accessibilityIdentifier("levels")
        }
        .padding(.top, 6)
      }
      Spacer(minLength: 6)
      HStack(spacing: 8) {
        Text("SIX GARDEN FORTS")
        Text("·")
        Text("THREE BRAVE FRUIT")
        Text("·")
        Text("ONE LONG EVENING")
      }
      .font(.system(size: 9, weight: .bold, design: .rounded))
      .tracking(1.6)
      .foregroundStyle(Palette.cream.opacity(0.95))
      .shadow(color: Palette.ink.opacity(0.35), radius: 3, y: 1)
    }
    .padding(.horizontal, 28)
    .padding(.vertical, 14)
  }

  private var ornament: some View {
    HStack(spacing: 3) {
      Capsule().frame(width: 22, height: 2)
      Image(systemName: "leaf.fill").font(.system(size: 9))
    }
  }

  private var levelMap: some View {
    ZStack {
      LinearGradient(
        colors: [
          Palette.paper.opacity(0.7), Palette.paper.opacity(0.5), Palette.cream.opacity(0.72),
        ],
        startPoint: .top, endPoint: .bottom
      ).ignoresSafeArea()
      VStack(spacing: 14) {
        HStack(spacing: 14) {
          iconButton("arrow.left", label: "Back to orchard") { game.home() }
          VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
              ornament
              Text("CHOOSE A FORT").font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(2)
            }
            .foregroundStyle(Palette.green)
            Text("The garden trail").font(.custom("Georgia-Bold", size: 27)).tracking(-0.5)
          }
          Spacer()
          HStack(spacing: 7) {
            Image(systemName: "star.fill").foregroundStyle(Palette.gold)
            Text("\(game.totalStars) / 18").font(.system(size: 15, weight: .bold, design: .rounded))
              .monospacedDigit()
          }
          .padding(.horizontal, 15).frame(height: 44)
          .paper(radius: 14)
        }
        LazyVGrid(
          columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12
        ) {
          ForEach(Array(Level.all.enumerated()), id: \.offset) { index, level in
            levelCard(index, level)
          }
        }
        Text("Fewer shots earn more stars · Every fruit left in the basket is worth 1,500")
          .font(.system(size: 11, weight: .medium)).foregroundStyle(Palette.muted)
      }
      .padding(.horizontal, 28)
      .padding(.vertical, 10)
    }
  }

  private func levelCard(_ index: Int, _ level: Level) -> some View {
    let locked = index > game.unlocked
    return Button {
      game.start(index)
    } label: {
      HStack(alignment: .top, spacing: 12) {
        Text(String(format: "%02d", index + 1))
          .font(.custom("Georgia-Bold", size: 24))
          .foregroundStyle(locked ? Palette.muted.opacity(0.5) : Palette.coral)
          .frame(width: 34)
        VStack(alignment: .leading, spacing: 5) {
          Text(level.subtitle).font(.system(size: 7, weight: .heavy)).tracking(1.1)
            .foregroundStyle(Palette.green).lineLimit(1)
          Text(level.name).font(.system(size: 14, weight: .bold))
            .lineLimit(1).minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
          if locked {
            Label("Clear the previous fort", systemImage: "lock.fill")
              .font(.system(size: 9, weight: .semibold)).foregroundStyle(Palette.muted)
          } else {
            stars(game.stars[String(index)] ?? 0, size: 12)
            HStack(spacing: 6) {
              Text("BEST").font(.system(size: 8, weight: .heavy)).tracking(1)
                .foregroundStyle(Palette.muted)
              Text("\((game.best[String(index)] ?? 0).formatted())")
                .font(.system(size: 11, weight: .bold, design: .rounded)).monospacedDigit()
            }
          }
          HStack(spacing: -4) {
            ForEach(Array(level.fruit.enumerated()), id: \.offset) { _, kind in
              fruitIcon(kind, size: 15)
            }
          }
          .opacity(locked ? 0.35 : 1)
        }
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .frame(height: 104)
      .multilineTextAlignment(.leading)
      .paper(radius: 18, opacity: locked ? 0.55 : 0.97)
    }
    .buttonStyle(PressStyle())
    .disabled(locked)
    .accessibilityIdentifier("level-\(index + 1)")
  }

  private var gameplay: some View {
    VStack {
      HStack(spacing: 10) {
        iconButton("pause.fill", label: "Pause game") { game.setPaused(true) }
        HStack(spacing: 11) {
          Text(String(format: "%02d", game.currentLevel + 1))
            .font(.custom("Georgia-Bold", size: 26)).foregroundStyle(Palette.coral)
          Rectangle().fill(Palette.green.opacity(0.18)).frame(width: 1, height: 26)
          VStack(alignment: .leading, spacing: 2) {
            Text(Level.all[game.currentLevel].subtitle)
              .font(.system(size: 7.5, weight: .heavy)).tracking(1.2)
              .foregroundStyle(Palette.green)
            Text(Level.all[game.currentLevel].name).font(.system(size: 14, weight: .bold))
          }
        }
        .padding(.horizontal, 14).frame(height: 48)
        .paper(radius: 15)
        Spacer(minLength: 0)
        HStack(spacing: 0) {
          counter("ladybug.fill", label: "PESTS", value: "\(game.targets)")
            .accessibilityLabel("\(game.targets) pests remaining")
          Rectangle().fill(Palette.green.opacity(0.18)).frame(width: 1, height: 26)
          counter("sparkle", label: "SCORE", value: game.score.formatted())
            .accessibilityLabel("Score \(game.score)")
        }
        .frame(height: 48)
        .paper(radius: 15)
      }
      Spacer()
      HStack(spacing: 12) {
        HStack(spacing: 9) {
          fruitIcon(game.currentFruit, size: 26)
          VStack(alignment: .leading, spacing: 2) {
            Text(game.inFlight ? "IN FLIGHT" : game.currentFruit.label.uppercased())
              .font(.system(size: 9, weight: .heavy)).tracking(1)
              .foregroundStyle(Palette.green)
            HStack(spacing: 4) {
              ForEach(0..<Level.all[game.currentLevel].fruit.count, id: \.self) { index in
                Circle()
                  .fill(
                    index < game.shotsRemaining ? Palette.coral : Palette.muted.opacity(0.25)
                  )
                  .frame(width: 6, height: 6)
              }
              Text("\(game.shotsRemaining) LEFT")
                .font(.system(size: 9, weight: .bold)).tracking(0.5).padding(.leading, 3)
            }
          }
        }
        .padding(.horizontal, 12).frame(height: 46)
        .paper(radius: 15)
        Spacer(minLength: 8)
        if game.canBurst {
          Button {
            game.scene.activateBurst()
          } label: {
            Label("Burst now", systemImage: "sparkles")
              .font(.system(size: 13, weight: .bold, design: .rounded))
              .padding(.horizontal, 20).frame(height: 46)
              .foregroundStyle(Palette.cream)
              .background(
                LinearGradient(
                  colors: [Palette.plum.opacity(0.95), Palette.plum], startPoint: .top,
                  endPoint: .bottom), in: Capsule()
              )
              .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1))
              .shadow(color: Palette.plum.opacity(0.45), radius: 10, y: 4)
          }
          .buttonStyle(PressStyle())
          .accessibilityIdentifier("burst")
        } else {
          Text(game.inFlight ? "Watch the garden tumble…" : launchHint)
            .font(.custom("Georgia-Italic", size: 13))
            .foregroundStyle(Palette.cream)
            .shadow(color: Palette.ink.opacity(0.5), radius: 3, y: 1)
            .lineLimit(2)
            .multilineTextAlignment(.trailing)
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
        Text("The orchard can wait.").font(.custom("Georgia-Bold", size: 28)).tracking(-0.6)
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
        Text("A good day to topple a fort.").font(.custom("Georgia-Bold", size: 27)).tracking(-0.6)
        HStack(alignment: .top, spacing: 20) {
          helpStep(
            "hand.draw.fill", title: "Pull & release",
            text: "Drag the fruit backwards.\nThe dots show your arc.")
          helpStep(
            "sparkles", title: "Make it tumble",
            text: "Hit the supports.\nClear every garden pest.")
          helpStep(
            "bolt.circle.fill", title: "Plum power",
            text: "Tap while a plum flies.\nBurst through nearby blocks.")
        }
        HStack(spacing: 14) {
          fruitFact(.apple, "flies true")
          fruitFact(.pear, "hits hard")
          fruitFact(.plum, "bursts on tap")
        }
        primary("Got it. Let’s grow.", icon: "checkmark", identifier: "dismiss-help") {
          game.showHelp = false
        }
      }
      .padding(25)
    }
  }

  private func fruitFact(_ kind: Fruit, _ text: String) -> some View {
    HStack(spacing: 6) {
      fruitIcon(kind, size: 18)
      Text(
        "\((kind.label.split(separator: " ").last.map(String.init) ?? kind.label).capitalized) \(text)"
      )
      .font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.muted)
    }
  }

  private func resultPanel(_ result: HarvestResult) -> some View {
    modal {
      HStack(spacing: 24) {
        VStack(spacing: 14) {
          ZStack {
            Circle()
              .fill(
                RadialGradient(
                  colors: [
                    (result.won ? Palette.gold : Palette.plum).opacity(0.28), .clear,
                  ], center: .center, startRadius: 10, endRadius: 70)
              )
              .frame(width: 140, height: 140)
            Image(uiImage: OrchardArt.fruitImage(result.won ? .apple : .plum))
              .resizable().scaledToFit().frame(width: 100, height: 111)
              .shadow(color: Palette.ink.opacity(0.2), radius: 8, y: 6)
          }
          .frame(height: 120)
          ResultStars(count: result.stars, reduceMotion: reduceMotion)
          Text(
            result.won
              ? "FORT CLEARED"
              : "\(game.targets) \(game.targets == 1 ? "PEST REMAINS" : "PESTS REMAIN")"
          )
          .font(.system(size: 9, weight: .heavy)).tracking(1.6)
          .foregroundStyle(result.won ? Palette.green : Palette.coralDeep)
        }
        .frame(width: 140)
        Rectangle().fill(Palette.green.opacity(0.15)).frame(width: 1, height: 210)
        VStack(alignment: .leading, spacing: 9) {
          eyebrow(result.newBest ? "A FRESH PERSONAL BEST" : "THE HARVEST REPORT")
          Text(result.won ? "Sweet victory." : "One more fling?")
            .font(.custom("Georgia-Bold", size: 30)).tracking(-0.8)
          CountUp(value: result.score, reduceMotion: reduceMotion)
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
          .padding(.top, 2)
          textButton("Back to garden trail") { game.home(levels: true) }
        }
        .frame(width: 275, alignment: .leading)
      }
      .padding(26)
    }
  }

  private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Palette.ink.opacity(0.42).ignoresSafeArea().contentShape(Rectangle())
        .onTapGesture {}
      content()
        .background(
          ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Palette.cream)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
              .fill(
                LinearGradient(
                  colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .center))
            RoundedRectangle(cornerRadius: 22, style: .continuous)
              .strokeBorder(Palette.green.opacity(0.16), lineWidth: 1)
              .padding(6)
          }
        )
        .overlay(
          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(.white.opacity(0.8), lineWidth: 1.5)
        )
        .shadow(color: Palette.ink.opacity(0.3), radius: 30, y: 16)
        .padding(12)
        .transition(reduceMotion ? .opacity : .scale(scale: 0.94).combined(with: .opacity))
    }
  }

  private func helpStep(_ icon: String, title: String, text: String) -> some View {
    VStack(spacing: 8) {
      Image(systemName: icon).font(.system(size: 22)).foregroundStyle(Palette.coral)
        .frame(width: 48, height: 48)
        .background(Palette.coral.opacity(0.1), in: Circle())
      Text(title).font(.system(size: 14, weight: .bold))
      Text(text).font(.system(size: 11)).foregroundStyle(Palette.muted)
        .multilineTextAlignment(.center).lineSpacing(3)
    }
    .frame(width: 150)
  }

  private func counter(_ icon: String, label: String, value: String) -> some View {
    HStack(spacing: 8) {
      Image(systemName: icon).foregroundStyle(Palette.green).font(.system(size: 15))
      VStack(alignment: .leading, spacing: 1) {
        Text(label).font(.system(size: 7.5, weight: .heavy)).tracking(1.2)
          .foregroundStyle(Palette.green)
        Text(value).font(.system(size: 19, weight: .bold, design: .rounded)).monospacedDigit()
          .contentTransition(.numericText())
          .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: value)
      }
    }
    .padding(.horizontal, 14)
  }

  private func fruitIcon(_ kind: Fruit, size: CGFloat) -> some View {
    Image(uiImage: OrchardArt.fruitImage(kind))
      .resizable().scaledToFit().frame(width: size, height: size * 1.1)
  }

  private func stars(_ number: Int, size: CGFloat) -> some View {
    HStack(spacing: 4) {
      ForEach(0..<3) { index in
        Image(systemName: index < number ? "star.fill" : "star")
          .font(.system(size: size, weight: .semibold))
          .foregroundStyle(index < number ? Palette.gold : Palette.muted.opacity(0.3))
      }
    }
    .accessibilityLabel("\(number) of 3 stars")
  }

  private func eyebrow(_ title: String) -> some View {
    HStack(spacing: 8) {
      ornament
      Text(title).font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1.8)
    }
    .foregroundStyle(Palette.green)
  }

  private func primary(
    _ title: String, icon: String, identifier: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 18) {
        Text(title)
        Image(systemName: icon).font(.system(size: 13, weight: .bold))
      }
      .font(.system(size: 15, weight: .bold, design: .rounded))
      .padding(.horizontal, 22).frame(height: 50)
      .foregroundStyle(Palette.cream)
      .background(
        LinearGradient(
          colors: [Palette.coral, Palette.coralDeep], startPoint: .top, endPoint: .bottom),
        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .strokeBorder(
            LinearGradient(
              colors: [.white.opacity(0.45), .white.opacity(0.05)], startPoint: .top,
              endPoint: .bottom), lineWidth: 1)
      )
      .shadow(color: Palette.coralDeep.opacity(0.35), radius: 10, y: 5)
    }
    .buttonStyle(PressStyle())
    .accessibilityIdentifier(identifier)
  }

  private func iconButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View
  {
    Button(action: action) {
      Image(systemName: icon).font(.system(size: 15, weight: .bold))
        .foregroundStyle(Palette.green)
        .frame(width: 46, height: 46)
        .paper(radius: 15)
    }
    .buttonStyle(PressStyle())
    .accessibilityLabel(label)
    .accessibilityIdentifier(label)
  }

  private func textButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title).underline(true, pattern: .solid, color: Palette.green.opacity(0.35))
    }
    .font(.system(size: 12, weight: .bold))
    .foregroundStyle(Palette.green)
    .frame(minHeight: 36)
  }
}

private struct ResultStars: View {
  let count: Int
  let reduceMotion: Bool
  @State private var shown = 0

  var body: some View {
    HStack(spacing: 6) {
      ForEach(0..<3) { index in
        Image(systemName: index < count ? "star.fill" : "star")
          .font(.system(size: 26, weight: .semibold))
          .foregroundStyle(index < count ? Palette.gold : Palette.muted.opacity(0.3))
          .shadow(color: index < count ? Palette.gold.opacity(0.4) : .clear, radius: 6)
          .scaleEffect(index < count && index >= shown ? 0.3 : 1)
          .opacity(index < count && index >= shown ? 0 : 1)
      }
    }
    .accessibilityLabel("\(count) of 3 stars")
    .onAppear {
      guard !reduceMotion else {
        shown = 3
        return
      }
      for index in 0..<3 {
        withAnimation(
          .spring(response: 0.35, dampingFraction: 0.55).delay(0.25 + Double(index) * 0.2)
        ) {
          shown = index + 1
        }
      }
    }
  }
}

private struct CountUp: View {
  let value: Int
  let reduceMotion: Bool
  @State private var shown = 0

  var body: some View {
    Text(shown.formatted())
      .font(.system(size: 38, weight: .bold, design: .rounded)).monospacedDigit()
      .contentTransition(.numericText())
      .onAppear {
        guard !reduceMotion else {
          shown = value
          return
        }
        for step in 1...12 {
          withAnimation(.easeOut(duration: 0.1).delay(0.15 + Double(step) * 0.055)) {
            shown = value * step / 12
          }
        }
      }
  }
}

private struct PressStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
      .opacity(configuration.isPressed ? 0.85 : 1)
      .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
  }
}
