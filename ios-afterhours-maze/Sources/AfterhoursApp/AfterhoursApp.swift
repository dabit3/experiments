import AfterhoursCore
import Combine
import SwiftUI

@main
struct AfterhoursApp: App {
  var body: some Scene {
    WindowGroup {
      ArcadeView()
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
  }
}

@MainActor
final class Arcade: ObservableObject {
  @Published var game = Game()
  @Published var inGame = false
  @Published var best = UserDefaults.standard.integer(forKey: "afterhours.best")
  @Published var deepest = max(1, UserDefaults.standard.integer(forKey: "afterhours.deepest"))
  @Published var sound = !UserDefaults.standard.bool(forKey: "afterhours.muted")
  @Published var showGuide = false
  @Published var selectedMaze = 1
  private var ticker: AnyCancellable?
  private let audio = ArcadeAudio()
  private var lastTick = Date()
  private var pelletSounds = 0

  init() {
    ticker = Timer.publish(every: 1.0 / 60, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] date in
        MainActor.assumeIsolated { self?.tick(date) }
      }
  }

  func start() {
    game = Game(level: selectedMaze, seed: UInt64.random(in: 1...UInt64.max))
    inGame = true
    lastTick = Date()
    if sound { audio.play(.power) }
  }

  func tick(_ date: Date) {
    let dt = min(1.0 / 30, date.timeIntervalSince(lastTick))
    lastTick = date
    guard inGame else { return }
    game.update(dt)
    if game.score > best {
      best = game.score
      UserDefaults.standard.set(best, forKey: "afterhours.best")
    }
    if game.level > deepest {
      deepest = game.level
      UserDefaults.standard.set(deepest, forKey: "afterhours.deepest")
    }
    for event in game.events {
      if case .pellet = event {
        pelletSounds += 1
        if sound && pelletSounds % 3 == 0 { audio.play(event) }
      } else {
        if sound { audio.play(event) }
        switch event {
        case .hit: UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .power, .clear: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .rival: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        default: break
        }
      }
    }
  }

  func steer(_ direction: Direction) {
    guard game.phase == .playing || game.phase == .ready else { return }
    game.steer(direction)
  }

  func toggleSound() {
    sound.toggle()
    UserDefaults.standard.set(!sound, forKey: "afterhours.muted")
  }
}

enum Palette {
  static let ink = Color(red: 0.025, green: 0.037, blue: 0.09)
  static let panel = Color(red: 0.05, green: 0.075, blue: 0.15)
  static let pearl = Color(red: 1, green: 0.91, blue: 0.70)
  static let muted = Color(red: 0.48, green: 0.56, blue: 0.72)
  static let blue = Color(red: 0.24, green: 0.47, blue: 1)
  static let mint = Color(red: 0.48, green: 0.96, blue: 0.84)
  static let rivals: [Color] = [
    Color(red: 1, green: 0.40, blue: 0.49),
    Color(red: 0.78, green: 0.57, blue: 1),
    Color(red: 0.37, green: 0.86, blue: 0.91),
    Color(red: 1, green: 0.68, blue: 0.38),
  ]
}

struct ArcadeView: View {
  @StateObject private var arcade = Arcade()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reducedMotion

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        backdrop
        if arcade.inGame {
          playView(size: geometry.size)
        } else {
          titleView(size: geometry.size)
        }
        if arcade.inGame && arcade.game.phase == .paused { pauseOverlay }
        if arcade.inGame && [.over, .cleared].contains(arcade.game.phase)
          && arcade.game.hitTime < 0.3
        {
          resultOverlay
        }
        if arcade.showGuide { guideOverlay }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active { arcade.game.pause() }
    }
  }

  private var backdrop: some View {
    ZStack {
      Palette.ink.ignoresSafeArea()
      RadialGradient(
        colors: [Palette.blue.opacity(0.19), .clear],
        center: .init(x: 0.5, y: 0.33), startRadius: 0, endRadius: 420
      ).ignoresSafeArea()
      Canvas { context, size in
        for index in 0..<55 {
          let x = CGFloat((index * 137 + 21) % 997) / 997 * size.width
          let y = CGFloat((index * 229 + 7) % 991) / 991 * size.height
          let radius: CGFloat = index % 5 == 0 ? 1.1 : 0.5
          context.fill(
            Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
            with: .color(Palette.muted.opacity(0.3)))
        }
      }.ignoresSafeArea().accessibilityHidden(true)
    }
  }

  private func titleView(size: CGSize) -> some View {
    VStack(spacing: 0) {
      HStack {
        micro("A MIDNIGHT ARCADE", color: Palette.muted)
        Spacer()
        soundButton
      }
      .padding(.top, 8)
      Spacer(minLength: 8)
      VStack(spacing: 1) {
        Text("afterhours").font(
          .system(size: min(size.width * 0.14, 60), weight: .black, design: .rounded)
        )
        .tracking(-3).foregroundStyle(Palette.pearl)
        Text("M A Z E").font(.system(size: 14, weight: .bold, design: .monospaced))
          .tracking(8).foregroundStyle(Palette.blue)
      }
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("title")
      Text("Be the light. Lose the shadows.")
        .font(.system(size: 14, weight: .medium)).foregroundStyle(Palette.muted).padding(.top, 15)
      ZStack {
        Circle().stroke(Palette.blue.opacity(0.12), lineWidth: 1).frame(width: 220, height: 220)
        Circle().stroke(Palette.blue.opacity(0.10), style: StrokeStyle(lineWidth: 1, dash: [3, 8]))
          .frame(width: 268, height: 268)
        TitleArt().frame(width: 310, height: 235)
      }
      .frame(height: min(size.height * 0.31, 267))
      .accessibilityHidden(true)
      HStack(spacing: 6) {
        Image(systemName: "sparkle").foregroundStyle(Palette.pearl)
        micro("YOUR BEST")
        Text(arcade.best.formatted()).font(.system(size: 20, weight: .bold, design: .rounded))
          .foregroundStyle(Palette.pearl).monospacedDigit()
      }
      .padding(.bottom, 22)
      HStack(spacing: 10) {
        mazeChoice(1, name: "BLUE HOUR", label: "01 / THE ORIGINAL")
        mazeChoice(2, name: "VELVET CIRCUIT", label: "02 / THE DETOUR")
      }
      .padding(.bottom, 16)
      primary("Enter the maze", icon: "arrow.right", id: "start") { arcade.start() }
      HStack {
        Button {
          arcade.showGuide = true
        } label: {
          Label("How to play", systemImage: "hand.draw")
            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.muted)
            .frame(height: 48)
        }.accessibilityIdentifier("howToPlay")
        Spacer()
        micro("OFFLINE · ALL YOURS", color: Palette.muted.opacity(0.75))
      }
      Spacer(minLength: 4)
    }
    .padding(.horizontal, 26)
  }

  private func mazeChoice(_ number: Int, name: String, label: String) -> some View {
    Button {
      arcade.selectedMaze = number
    } label: {
      VStack(alignment: .leading, spacing: 7) {
        HStack {
          MazeThumbnail(index: number - 1)
            .frame(width: 48, height: 48)
            .accessibilityHidden(true)
          Spacer()
          if arcade.selectedMaze == number {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.pearl)
              .font(.system(size: 17))
          }
        }
        micro(label, color: arcade.selectedMaze == number ? Palette.blue : Palette.muted)
        Text(name).font(.system(size: 12, weight: .bold, design: .rounded))
          .foregroundStyle(arcade.selectedMaze == number ? Palette.pearl : Palette.muted)
      }
      .frame(maxWidth: .infinity, alignment: .leading).padding(13)
      .background(
        arcade.selectedMaze == number ? Palette.blue.opacity(0.13) : Palette.panel.opacity(0.6),
        in: RoundedRectangle(cornerRadius: 14)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14).stroke(
          arcade.selectedMaze == number ? Palette.blue.opacity(0.6) : Palette.muted.opacity(0.15),
          lineWidth: 1))
    }
    .accessibilityIdentifier("maze\(number)")
    .accessibilityLabel("\(name), \(arcade.selectedMaze == number ? "selected" : "select maze")")
  }

  private func playView(size: CGSize) -> some View {
    let boardWidth = min(size.width - 28, max(240, (size.height - 335) * 19 / 21))
    return VStack(spacing: 0) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 2) {
          micro("AFTERHOURS / \(String(format: "%02d", arcade.game.level))", color: Palette.blue)
          Text(arcade.game.maze.name).font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.pearl)
        }
        Spacer()
        Button {
          arcade.game.pause()
        } label: {
          Image(systemName: "pause.fill").font(.system(size: 16, weight: .bold))
            .foregroundStyle(Palette.pearl).frame(width: 46, height: 46)
            .background(Palette.panel, in: Circle())
            .overlay(Circle().stroke(Palette.blue.opacity(0.25), lineWidth: 1))
        }.accessibilityLabel("Pause").accessibilityIdentifier("pause")
      }
      .padding(.horizontal, 24).padding(.top, 5)
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 2) {
          micro("SCORE")
          Text(String(format: "%05d", arcade.game.score))
            .font(.system(size: 31, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.pearl).monospacedDigit()
            .accessibilityIdentifier("score")
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 5) {
          micro("BEST  \(arcade.best.formatted())")
          HStack(spacing: 7) {
            ForEach(0..<max(3, arcade.game.lives), id: \.self) { index in
              CometShape(mouth: 0.65)
                .fill(
                  index < arcade.game.lives
                    ? Palette.pearl
                    : arcade.game.hitTime > 0 && index == arcade.game.lives
                      ? Palette.rivals[0] : Palette.muted.opacity(0.18)
                )
                .frame(width: 17, height: 17)
            }
          }
          .accessibilityLabel("\(arcade.game.lives) lives")
        }
      }.padding(.horizontal, 26).padding(.top, 12).padding(.bottom, 12)
      ZStack {
        MazeBoard(game: arcade.game, reducedMotion: reducedMotion)
          .aspectRatio(19.0 / 21, contentMode: .fit)
        if arcade.game.phase == .ready
          || (arcade.game.phase == .lifeLost && arcade.game.hitTime < 0.4)
        {
          VStack(spacing: 8) {
            micro(
              arcade.game.phase == .lifeLost
                ? "\(arcade.game.lives) \(arcade.game.lives == 1 ? "LIFE" : "LIVES") LEFT"
                : "THE NIGHT IS YOURS",
              color: Palette.pearl)
            Text(arcade.game.phase == .lifeLost ? "Try another path" : "Ready, comet?")
              .font(.system(size: 26, weight: .bold, design: .rounded))
            Text(
              arcade.game.phase == .lifeLost
                ? "A fresh start. Find a new route." : "Swipe to turn · tap arrows to steer"
            )
            .font(.system(size: 12)).foregroundStyle(Palette.muted)
          }
          .padding(22).background(Palette.ink.opacity(0.94), in: RoundedRectangle(cornerRadius: 18))
        }
      }
      .frame(width: boardWidth)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 12).onEnded { value in
          let dx = value.translation.width
          let dy = value.translation.height
          arcade.steer(abs(dx) > abs(dy) ? (dx > 0 ? .right : .left) : (dy > 0 ? .down : .up))
        }
      )
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(
        "Maze. \(arcade.game.remaining) lights remaining. \(arcade.game.frightened > 0 ? "Rivals frightened" : "Rivals chasing")."
      )
      .accessibilityIdentifier("mazeBoard")
      VStack(spacing: 8) {
        HStack(spacing: 8) {
          Image(systemName: arcade.game.frightened > 0 ? "sparkles" : "circle.dotted")
          Text(
            arcade.game.frightened > 0
              ? "CHASE · \(Int(ceil(arcade.game.frightened)))s"
              : "\(arcade.game.remaining) LIGHTS LEFT"
          )
          .tracking(1)
          Spacer()
          Text(
            arcade.game.bonusTime > 0
              ? "+\(arcade.game.lastBonus) · \(arcade.game.combo)×"
              : arcade.game.frightened > 0 ? "CATCH RIVALS" : "10 pts / light"
          )
          .monospacedDigit()
        }
        .font(.system(size: 12, weight: .bold, design: .monospaced))
        .foregroundStyle(arcade.game.frightened > 0 ? Palette.mint : Palette.muted)
        GeometryReader { meter in
          ZStack(alignment: .leading) {
            Capsule().fill(Palette.blue.opacity(0.12))
            Capsule().fill(arcade.game.frightened > 0 ? Palette.mint : Palette.blue)
              .frame(
                width: meter.size.width
                  * (arcade.game.frightened > 0
                    ? min(1, arcade.game.frightened / 10)
                    : Double(arcade.game.collected)
                      / Double(arcade.game.maze.pellets.count + arcade.game.maze.powers.count)))
          }
        }.frame(height: 3)
      }.frame(width: boardWidth - 16).padding(.top, 13)
      Spacer(minLength: 8)
      ZStack {
        Circle().stroke(Palette.blue.opacity(0.16), lineWidth: 1).frame(width: 64, height: 64)
        Image(systemName: "sparkle").font(.system(size: 16)).foregroundStyle(
          Palette.blue.opacity(0.5))
        directionButton(.left, symbol: "arrow.left").offset(x: -82)
        directionButton(.up, symbol: "arrow.up").offset(y: -45)
        directionButton(.down, symbol: "arrow.down").offset(y: 45)
        directionButton(.right, symbol: "arrow.right").offset(x: 82)
      }.frame(width: 240, height: 143).padding(.top, 4)
    }.padding(.bottom, 8)
  }

  private func directionButton(_ direction: Direction, symbol: String) -> some View {
    Button {
      arcade.steer(direction)
    } label: {
      Image(systemName: symbol).font(.system(size: 20, weight: .semibold))
        .foregroundStyle(arcade.game.queued == direction ? Palette.pearl : Palette.muted)
        .frame(width: 64, height: 49)
        .background(
          arcade.game.queued == direction ? Palette.blue.opacity(0.23) : Palette.panel,
          in: RoundedRectangle(cornerRadius: 15)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 15).stroke(
            arcade.game.queued == direction
              ? Palette.blue.opacity(0.75) : Palette.muted.opacity(0.12), lineWidth: 1))
    }
    .accessibilityLabel(String(describing: direction))
    .accessibilityIdentifier("direction_\(direction)")
    .keyboardShortcut(
      KeyEquivalent(
        direction == .left
          ? "\u{F702}"
          : direction == .right ? "\u{F703}" : direction == .up ? "\u{F700}" : "\u{F701}"),
      modifiers: [])
  }

  private var pauseOverlay: some View {
    modal {
      micro("TAKE A BREATHER", color: Palette.blue)
      Text("The night can wait.").font(.system(size: 30, weight: .bold, design: .rounded))
        .foregroundStyle(Palette.pearl).multilineTextAlignment(.center)
      Text("Your comet is right where you left it.")
        .font(.system(size: 14)).foregroundStyle(Palette.muted).padding(.bottom, 10)
      primary("Keep glowing", icon: "play.fill", id: "resume") { arcade.game.resume() }
      HStack {
        Button {
          arcade.toggleSound()
        } label: {
          Label(
            arcade.sound ? "Sound on" : "Sound off",
            systemImage: arcade.sound ? "speaker.wave.2" : "speaker.slash"
          )
          .frame(maxWidth: .infinity, minHeight: 48)
        }.accessibilityIdentifier("pauseSound")
        Button {
          arcade.showGuide = true
        } label: {
          Label("Guide", systemImage: "questionmark.circle").frame(
            maxWidth: .infinity, minHeight: 48)
        }
      }.font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.muted)
      Button("End run") {
        arcade.game.resume()
        arcade.inGame = false
      }
      .font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.muted)
      .frame(height: 44).accessibilityIdentifier("endRun")
    }
  }

  private var resultOverlay: some View {
    let cleared = arcade.game.phase == .cleared
    return modal {
      Image(systemName: cleared ? "sparkles" : "moon.stars")
        .font(.system(size: 32, weight: .light)).foregroundStyle(Palette.pearl).padding(.bottom, 4)
      micro(cleared ? "EVERY LIGHT, FOUND" : "UNTIL NEXT TIME", color: Palette.blue)
      Text(cleared ? "Night, illuminated." : "A beautiful run.")
        .font(.system(size: 29, weight: .bold, design: .rounded)).foregroundStyle(Palette.pearl)
        .minimumScaleFactor(0.7).lineLimit(1)
      Text(
        cleared
          ? "Maze cleared. +1,000 points & an extra life."
          : "The shadows caught up. Your glow stays."
      )
      .font(.system(size: 13)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
      VStack(spacing: 4) {
        Text(arcade.game.score.formatted()).font(.system(size: 62, weight: .bold, design: .rounded))
          .tracking(-2).foregroundStyle(Palette.pearl).monospacedDigit()
        micro(
          arcade.game.score >= arcade.best && arcade.best > 0
            ? "YOUR PERSONAL BEST" : "POINTS COLLECTED", color: Palette.pearl.opacity(0.6))
      }.padding(.vertical, 14).accessibilityIdentifier("resultScore")
      HStack {
        resultStat("MAZE", value: String(format: "%02d", arcade.game.level))
        Spacer()
        resultStat("LIGHTS", value: "\(arcade.game.collected)")
        Spacer()
        resultStat("BEST", value: arcade.best.formatted())
      }
      .padding(16).background(Palette.ink.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
      .padding(.bottom, 10)
      primary(cleared ? "Into the next night" : "One more run", icon: "arrow.right", id: "replay") {
        if cleared { arcade.game.nextLevel() } else { arcade.start() }
      }
      Button("Back to the arcade") { arcade.inGame = false }
        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.muted)
        .frame(height: 44).accessibilityIdentifier("home")
    }
  }

  private var guideOverlay: some View {
    modal {
      micro("A FIELD GUIDE TO THE NIGHT", color: Palette.blue)
      Text("Keep your glow.").font(.system(size: 32, weight: .bold, design: .rounded))
        .foregroundStyle(Palette.pearl)
      guideRow(
        "hand.draw", title: "Swipe before the corner",
        detail:
          "Your next turn is queued. Use the arrow pads if you prefer; opposite turns reverse instantly."
      )
      guideRow(
        "circle.dotted", title: "Find every little light",
        detail:
          "Pearls are 10 points. Clear the maze for 1,000 and an extra life. Side tunnels wrap around."
      )
      guideRow(
        "sparkle", title: "Big lights turn the chase",
        detail: "Power orbs are 50 points. Catch frightened rivals for 200, 400, 800, then 1,600.")
      HStack(spacing: 14) {
        ForEach(0..<4) { index in
          VStack(spacing: 8) {
            SpiritShape(identity: index).fill(Palette.rivals[index]).frame(width: 27, height: 30)
            Text(["HUNTS", "AMBUSH", "FLANKS", "SHY"][index])
              .font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(
                Palette.muted)
          }.frame(maxWidth: .infinity)
        }
      }.padding(.vertical, 12)
      primary("Got it. Let’s glow.", icon: "arrow.right", id: "closeGuide") {
        arcade.showGuide = false
      }
    }
  }

  private func guideRow(_ icon: String, title: String, detail: String) -> some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: icon).foregroundStyle(Palette.pearl).font(.system(size: 23, weight: .light))
        .frame(width: 30)
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(Palette.pearl)
        Text(detail).font(.system(size: 13)).foregroundStyle(Palette.muted).fixedSize(
          horizontal: false, vertical: true)
      }
    }.padding(.vertical, 6)
  }

  private func resultStat(_ label: String, value: String) -> some View {
    VStack(spacing: 7) {
      micro(label)
      Text(value).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(
        Palette.pearl)
    }
  }

  private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Palette.ink.opacity(0.86).ignoresSafeArea()
      ScrollView {
        VStack(spacing: 14, content: content)
          .padding(26).frame(maxWidth: 380)
          .background(
            LinearGradient(
              colors: [Palette.panel, Palette.ink], startPoint: .topLeading,
              endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28)
          )
          .overlay(
            RoundedRectangle(cornerRadius: 28).stroke(Palette.blue.opacity(0.3), lineWidth: 1)
          )
          .padding(20)
      }.scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(.center)
    }
  }

  private var soundButton: some View {
    Button {
      arcade.toggleSound()
    } label: {
      Image(systemName: arcade.sound ? "speaker.wave.2" : "speaker.slash")
        .font(.system(size: 15)).foregroundStyle(Palette.muted).frame(width: 44, height: 44)
    }.accessibilityLabel(arcade.sound ? "Mute sound" : "Enable sound").accessibilityIdentifier(
      "sound")
  }

  private func primary(_ text: String, icon: String, id: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      HStack {
        Text(text).font(.system(size: 16, weight: .bold, design: .rounded))
        Spacer()
        Image(systemName: icon).font(.system(size: 15, weight: .bold))
      }
      .foregroundStyle(Palette.ink).padding(.horizontal, 22).frame(height: 57)
      .background(
        LinearGradient(
          colors: [Palette.pearl, Color(red: 0.92, green: 0.77, blue: 0.48)],
          startPoint: .topLeading, endPoint: .bottomTrailing),
        in: RoundedRectangle(cornerRadius: 17))
    }.accessibilityIdentifier(id)
  }

  private func micro(_ text: String, color: Color = Palette.muted) -> some View {
    Text(text).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(0.8)
      .foregroundStyle(color)
  }
}
