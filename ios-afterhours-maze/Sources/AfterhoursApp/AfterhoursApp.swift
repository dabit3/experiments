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
  @Published var demo = Game(level: 1, seed: 7)
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
  private var demoRest = 0.0

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
    guard inGame else {
      runDemo(dt)
      return
    }
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
    UISelectionFeedbackGenerator().selectionChanged()
  }

  func toggleSound() {
    sound.toggle()
    UserDefaults.standard.set(!sound, forKey: "afterhours.muted")
  }

  private func runDemo(_ dt: Double) {
    if demo.phase == .over || demo.phase == .cleared {
      demoRest += dt
      if demoRest > 1.8 {
        demoRest = 0
        demo = Game(level: demo.level % 2 + 1, seed: UInt64.random(in: 1...UInt64.max))
      }
    } else if demo.player.next == nil {
      demo.steer(Autopilot.choose(for: demo))
    }
    demo.update(dt)
  }
}

enum Autopilot {
  static func choose(for game: Game) -> Direction {
    let maze = game.maze
    let tile = game.player.tile
    let fromPlayer = maze.distanceMap(to: tile)
    let lights = game.pellets.union(game.powers)
    guard
      let goal = lights.min(by: {
        (fromPlayer[$0, default: 999], $0.y * 19 + $0.x) < (
          fromPlayer[$1, default: 999], $1.y * 19 + $1.x
        )
      })
    else { return game.player.direction }
    let toGoal = maze.distanceMap(to: goal)
    let threats = game.rivals.filter { !$0.returning && $0.release == 0 }.map(\.runner.tile)
    let options = Direction.allCases.compactMap { direction in
      maze.neighbor(tile, direction).map { (direction, $0) }
    }
    let safe =
      game.frightened > 0
      ? options : options.filter { option in threats.allSatisfy { $0.distance(to: option.1) > 2 } }
    let pool = safe.isEmpty ? options : safe
    return pool.min { toGoal[$0.1, default: 999] < toGoal[$1.1, default: 999] }?.0
      ?? game.player.direction
  }
}

enum Palette {
  static let ink = Color(red: 0.016, green: 0.024, blue: 0.066)
  static let panel = Color(red: 0.055, green: 0.078, blue: 0.165)
  static let pearl = Color(red: 1, green: 0.92, blue: 0.74)
  static let gold = Color(red: 0.93, green: 0.74, blue: 0.42)
  static let muted = Color(red: 0.52, green: 0.59, blue: 0.75)
  static let blue = Color(red: 0.26, green: 0.50, blue: 1)
  static let violet = Color(red: 0.56, green: 0.40, blue: 1)
  static let mint = Color(red: 0.48, green: 0.96, blue: 0.84)
  static let rivals: [Color] = [
    Color(red: 1, green: 0.42, blue: 0.50),
    Color(red: 0.80, green: 0.58, blue: 1),
    Color(red: 0.38, green: 0.86, blue: 0.92),
    Color(red: 1, green: 0.70, blue: 0.40),
  ]
  static let pearlGradient = LinearGradient(
    colors: [Color(red: 1, green: 0.97, blue: 0.88), pearl, gold],
    startPoint: .top, endPoint: .bottom)
  static let rim = AngularGradient(
    colors: [
      blue.opacity(0.55), violet.opacity(0.35), pearl.opacity(0.25), blue.opacity(0.2),
      blue.opacity(0.55),
    ],
    center: .center)
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
        colors: [Palette.blue.opacity(0.22), .clear],
        center: .init(x: 0.2, y: 0.12), startRadius: 0, endRadius: 460
      ).ignoresSafeArea()
      RadialGradient(
        colors: [Palette.violet.opacity(0.16), .clear],
        center: .init(x: 0.9, y: 0.78), startRadius: 0, endRadius: 420
      ).ignoresSafeArea()
      Canvas { context, size in
        for index in 0..<70 {
          let x = CGFloat((index * 137 + 21) % 997) / 997 * size.width
          let y = CGFloat((index * 229 + 7) % 991) / 991 * size.height
          if index % 11 == 0 {
            context.draw(
              Text("✦").font(.system(size: 7)).foregroundStyle(Palette.pearl.opacity(0.35)),
              at: CGPoint(x: x, y: y))
          } else {
            let radius: CGFloat = index % 5 == 0 ? 1.1 : 0.55
            context.fill(
              Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
              with: .color(Palette.muted.opacity(index % 3 == 0 ? 0.42 : 0.22)))
          }
        }
      }.ignoresSafeArea().accessibilityHidden(true)
    }
  }

  private func titleView(size: CGSize) -> some View {
    let compact = size.height < 800
    return VStack(spacing: 0) {
      HStack {
        micro("A MIDNIGHT ARCADE", color: Palette.muted)
        Spacer()
        soundButton
      }
      .padding(.top, 6)
      Spacer(minLength: 4)
      VStack(spacing: -2) {
        Text("Afterhours")
          .font(.system(size: min(size.width * 0.16, 66), weight: .medium, design: .serif))
          .italic().tracking(-1.5)
          .foregroundStyle(Palette.pearlGradient)
          .shadow(color: Palette.gold.opacity(0.35), radius: 24)
        HStack(spacing: 12) {
          rule
          Text("M A Z E").font(.system(size: 13, weight: .semibold, design: .monospaced))
            .tracking(6).foregroundStyle(Palette.blue)
          rule
        }.frame(width: 190)
      }
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("title")
      Text("A tiny hungry comet against the shadows.")
        .font(.system(size: 14, weight: .regular, design: .serif)).italic()
        .foregroundStyle(Palette.muted).padding(.top, compact ? 8 : 12)
      attract
        .frame(height: min(size.height * (compact ? 0.28 : 0.31), 275))
        .padding(.top, compact ? 12 : 18)
      HStack(spacing: 8) {
        Image(systemName: "sparkle").font(.system(size: 11)).foregroundStyle(Palette.gold)
        micro("YOUR BEST")
        Text(arcade.best.formatted()).font(.system(size: 22, weight: .bold, design: .rounded))
          .foregroundStyle(Palette.pearlGradient).monospacedDigit()
        Spacer()
        micro("DEEPEST  \(String(format: "%02d", arcade.deepest))")
      }
      .padding(.horizontal, 4).padding(.top, compact ? 12 : 18).padding(.bottom, compact ? 10 : 14)
      HStack(spacing: 10) {
        mazeChoice(1, name: "Blue Hour", label: "01 · THE ORIGINAL")
        mazeChoice(2, name: "Velvet Circuit", label: "02 · THE DETOUR")
      }
      .padding(.bottom, compact ? 10 : 14)
      primary("Enter the maze", icon: "arrow.right", id: "start") { arcade.start() }
      HStack {
        Button {
          arcade.showGuide = true
        } label: {
          Label("How to play", systemImage: "hand.draw")
            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.muted)
            .frame(height: 46)
        }.accessibilityIdentifier("howToPlay")
        Spacer()
        micro("OFFLINE · ALL YOURS", color: Palette.muted.opacity(0.7))
      }
      Spacer(minLength: 2)
    }
    .padding(.horizontal, 24)
  }

  private var rule: some View {
    Rectangle().fill(
      LinearGradient(
        colors: [.clear, Palette.blue.opacity(0.7), .clear], startPoint: .leading,
        endPoint: .trailing)
    ).frame(height: 1)
  }

  private var attract: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 22).fill(Palette.ink.opacity(0.7))
      MazeBoard(game: arcade.demo, reducedMotion: reducedMotion, attract: true)
        .aspectRatio(19.0 / 21, contentMode: .fit)
        .padding(10)
      RoundedRectangle(cornerRadius: 22).fill(
        RadialGradient(
          colors: [.clear, .clear, Palette.ink.opacity(0.55)], center: .center,
          startRadius: 40, endRadius: 190))
      VStack {
        Spacer()
        HStack(spacing: 6) {
          Circle().fill(Palette.mint).frame(width: 5, height: 5)
            .shadow(color: Palette.mint, radius: 4)
          micro("ATTRACT MODE · TAP TO PLAY", color: Palette.muted)
        }.padding(.bottom, 12)
      }
    }
    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.rim, lineWidth: 1))
    .shadow(color: Palette.blue.opacity(0.22), radius: 30, y: 10)
    .contentShape(Rectangle())
    .onTapGesture { arcade.start() }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Live demo. Tap to play.")
    .accessibilityAddTraits(.isButton)
    .accessibilityIdentifier("attract")
  }

  private func mazeChoice(_ number: Int, name: String, label: String) -> some View {
    let selected = arcade.selectedMaze == number
    let accent = number == 1 ? Palette.blue : Palette.violet
    return Button {
      arcade.selectedMaze = number
      UISelectionFeedbackGenerator().selectionChanged()
    } label: {
      HStack(spacing: 12) {
        MazeThumbnail(index: number - 1)
          .frame(width: 40, height: 44)
          .padding(6)
          .background(Palette.ink.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 4) {
          micro(label, color: selected ? accent : Palette.muted.opacity(0.8))
          Text(name).font(.system(size: 15, weight: .semibold, design: .serif)).italic()
            .foregroundStyle(selected ? Palette.pearl : Palette.muted)
            .lineLimit(1).minimumScaleFactor(0.8)
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 12).padding(.vertical, 11)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        selected ? accent.opacity(0.16) : Palette.panel.opacity(0.55),
        in: RoundedRectangle(cornerRadius: 16)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16).stroke(
          selected ? accent.opacity(0.8) : Palette.muted.opacity(0.14), lineWidth: 1)
      )
      .overlay(alignment: .topTrailing) {
        if selected {
          Circle().fill(accent).frame(width: 8, height: 8)
            .shadow(color: accent, radius: 5).padding(9)
        }
      }
    }
    .accessibilityIdentifier("maze\(number)")
    .accessibilityLabel("\(name), \(selected ? "selected" : "select maze")")
  }

  private func playView(size: CGSize) -> some View {
    let boardWidth = min(size.width - 28, max(240, (size.height - 400) * 19 / 21))
    let chase = arcade.game.frightened > 0
    return VStack(spacing: 0) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 1) {
          micro("AFTERHOURS · \(String(format: "%02d", arcade.game.level))", color: Palette.blue)
          Text(arcade.game.maze.name).font(.system(size: 20, weight: .medium, design: .serif))
            .italic().foregroundStyle(Palette.pearl)
        }
        Spacer()
        Button {
          arcade.game.pause()
        } label: {
          Image(systemName: "pause.fill").font(.system(size: 15, weight: .bold))
            .foregroundStyle(Palette.pearl).frame(width: 44, height: 44)
            .background(Palette.panel.opacity(0.8), in: Circle())
            .overlay(Circle().stroke(Palette.rim, lineWidth: 1))
        }.accessibilityLabel("Pause").accessibilityIdentifier("pause")
      }
      .padding(.horizontal, 24).padding(.top, 4)
      HStack(alignment: .lastTextBaseline) {
        VStack(alignment: .leading, spacing: 0) {
          micro("SCORE")
          Text(String(format: "%05d", arcade.game.score))
            .font(.system(size: 36, weight: .bold, design: .rounded)).tracking(-0.5)
            .foregroundStyle(Palette.pearlGradient).monospacedDigit()
            .accessibilityIdentifier("score")
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 6) {
          micro("BEST  \(arcade.best.formatted())")
          HStack(spacing: 6) {
            ForEach(0..<max(3, arcade.game.lives), id: \.self) { index in
              CometShape(mouth: 0.65)
                .fill(
                  index < arcade.game.lives
                    ? Palette.pearl
                    : arcade.game.hitTime > 0 && index == arcade.game.lives
                      ? Palette.rivals[0] : Palette.muted.opacity(0.18)
                )
                .frame(width: 15, height: 15)
                .shadow(
                  color: index < arcade.game.lives ? Palette.gold.opacity(0.6) : .clear, radius: 4)
            }
          }
          .accessibilityLabel("\(arcade.game.lives) lives")
        }.padding(.bottom, 6)
      }.padding(.horizontal, 26).padding(.top, 8).padding(.bottom, 10)
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
              color: Palette.blue)
            Text(arcade.game.phase == .lifeLost ? "Try another path." : "Ready, comet?")
              .font(.system(size: 28, weight: .medium, design: .serif)).italic()
              .foregroundStyle(Palette.pearl)
            Text(
              arcade.game.phase == .lifeLost
                ? "A fresh start. Find a new route." : "Swipe the board · or turn the dial"
            )
            .font(.system(size: 12)).foregroundStyle(Palette.muted)
          }
          .padding(.horizontal, 26).padding(.vertical, 22)
          .background(Palette.ink.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
          .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.rim, lineWidth: 1))
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
        "Maze. \(arcade.game.remaining) lights remaining. \(chase ? "Rivals frightened" : "Rivals chasing")."
      )
      .accessibilityIdentifier("mazeBoard")
      VStack(spacing: 7) {
        HStack(spacing: 8) {
          Image(systemName: chase ? "sparkles" : "circle.dotted")
          Text(
            chase
              ? "CHASE · \(Int(ceil(arcade.game.frightened)))s"
              : "\(arcade.game.remaining) LIGHTS LEFT"
          )
          .tracking(1)
          Spacer()
          Text(
            arcade.game.bonusTime > 0
              ? "+\(arcade.game.lastBonus) · \(arcade.game.combo)×"
              : chase ? "CATCH RIVALS" : "10 pts / light"
          )
          .monospacedDigit()
          .foregroundStyle(
            arcade.game.bonusTime > 0 ? Palette.pearl : chase ? Palette.mint : Palette.muted)
        }
        .font(.system(size: 12, weight: .bold, design: .monospaced))
        .foregroundStyle(chase ? Palette.mint : Palette.muted)
        GeometryReader { meter in
          ZStack(alignment: .leading) {
            Capsule().fill(Palette.blue.opacity(0.12))
            Capsule()
              .fill(
                chase
                  ? AnyShapeStyle(Palette.mint)
                  : AnyShapeStyle(
                    LinearGradient(
                      colors: [Palette.blue, Palette.violet], startPoint: .leading,
                      endPoint: .trailing))
              )
              .frame(
                width: meter.size.width
                  * (chase
                    ? min(1, arcade.game.frightened / 10)
                    : Double(arcade.game.collected)
                      / Double(arcade.game.maze.pellets.count + arcade.game.maze.powers.count))
              )
              .shadow(color: (chase ? Palette.mint : Palette.blue).opacity(0.8), radius: 4)
          }
        }.frame(height: 3)
      }.frame(width: boardWidth - 12).padding(.top, 12)
      Spacer(minLength: 6)
      dial.padding(.bottom, 4)
    }.padding(.bottom, 6)
  }

  private var dial: some View {
    ZStack {
      Circle().fill(
        RadialGradient(
          colors: [Palette.panel, Palette.ink], center: .center, startRadius: 20, endRadius: 100))
      Circle().stroke(Palette.rim, lineWidth: 1)
      ForEach(Direction.allCases, id: \.rawValue) { direction in
        dialWedge(direction)
      }
      Circle().fill(Palette.ink).frame(width: 66, height: 66)
        .overlay(Circle().stroke(Palette.blue.opacity(0.35), lineWidth: 1))
      CometShape(mouth: 0.55).fill(Palette.pearlGradient)
        .frame(width: 22, height: 22)
        .rotationEffect(.radians(arcade.game.queued.angle))
        .shadow(color: Palette.gold.opacity(0.7), radius: 6)
        .animation(reducedMotion ? nil : .spring(duration: 0.25), value: arcade.game.queued)
    }
    .frame(width: 196, height: 196)
    .shadow(color: Palette.blue.opacity(0.18), radius: 24, y: 8)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Steering dial")
  }

  private func dialWedge(_ direction: Direction) -> some View {
    let active = arcade.game.queued == direction
    let symbol = ["arrow.left", "arrow.up", "arrow.right", "arrow.down"][direction.rawValue]
    return Button {
      arcade.steer(direction)
    } label: {
      ZStack {
        WedgeShape(direction: direction)
          .fill(active ? Palette.blue.opacity(0.28) : Palette.panel.opacity(0.35))
        WedgeShape(direction: direction)
          .stroke(active ? Palette.blue.opacity(0.9) : Palette.muted.opacity(0.10), lineWidth: 1)
        Image(systemName: symbol).font(.system(size: 19, weight: .semibold))
          .foregroundStyle(active ? Palette.pearl : Palette.muted)
          .offset(x: cos(direction.angle) * 68, y: sin(direction.angle) * 68)
      }
      .contentShape(WedgeShape(direction: direction))
    }
    .buttonStyle(.plain)
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
      Text("The night can wait.").font(.system(size: 32, weight: .medium, design: .serif))
        .italic().foregroundStyle(Palette.pearl).multilineTextAlignment(.center)
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
    let record = arcade.game.score >= arcade.best && arcade.best > 0
    return modal {
      ZStack {
        Circle().stroke(Palette.rim, lineWidth: 1).frame(width: 76, height: 76)
        Circle().stroke(
          Palette.blue.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [2, 6])
        ).frame(width: 96, height: 96)
        Image(systemName: cleared ? "sparkles" : "moon.stars")
          .font(.system(size: 30, weight: .light)).foregroundStyle(Palette.pearlGradient)
      }.padding(.bottom, 6)
      micro(cleared ? "EVERY LIGHT, FOUND" : "UNTIL NEXT TIME", color: Palette.blue)
      Text(cleared ? "Night, illuminated." : "A beautiful run.")
        .font(.system(size: 32, weight: .medium, design: .serif)).italic()
        .foregroundStyle(Palette.pearl).minimumScaleFactor(0.7).lineLimit(1)
      Text(
        cleared
          ? "Maze cleared. +1,000 points & an extra life."
          : "The shadows caught up. Your glow stays."
      )
      .font(.system(size: 13)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
      VStack(spacing: 6) {
        Text(arcade.game.score.formatted()).font(.system(size: 64, weight: .bold, design: .rounded))
          .tracking(-2.5).foregroundStyle(Palette.pearlGradient).monospacedDigit()
          .shadow(color: Palette.gold.opacity(0.35), radius: 20)
        micro(
          record ? "★  NEW PERSONAL BEST" : "POINTS COLLECTED",
          color: record ? Palette.gold : Palette.pearl.opacity(0.6))
      }.padding(.vertical, 12).accessibilityIdentifier("resultScore")
      HStack {
        resultStat("MAZE", value: String(format: "%02d", arcade.game.level))
        Spacer()
        resultStat("LIGHTS", value: "\(arcade.game.collected)")
        Spacer()
        resultStat("BEST", value: arcade.best.formatted())
      }
      .padding(16).background(Palette.ink.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
      .overlay(
        RoundedRectangle(cornerRadius: 14).stroke(Palette.blue.opacity(0.15), lineWidth: 1)
      )
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
      Text("Keep your glow.").font(.system(size: 34, weight: .medium, design: .serif)).italic()
        .foregroundStyle(Palette.pearl)
      guideRow(
        "hand.draw", title: "Swipe before the corner",
        detail:
          "Your next turn is queued. Turn the dial if you prefer; opposite turns reverse instantly."
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
              .shadow(color: Palette.rivals[index].opacity(0.6), radius: 6)
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
      Image(systemName: icon).foregroundStyle(Palette.pearlGradient)
        .font(.system(size: 22, weight: .light)).frame(width: 30)
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.system(size: 15, weight: .semibold, design: .serif)).italic()
          .foregroundStyle(Palette.pearl)
        Text(detail).font(.system(size: 13)).foregroundStyle(Palette.muted).fixedSize(
          horizontal: false, vertical: true)
      }
    }.padding(.vertical, 6)
  }

  private func resultStat(_ label: String, value: String) -> some View {
    VStack(spacing: 7) {
      micro(label)
      Text(value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(
        Palette.pearl
      ).monospacedDigit()
    }
  }

  private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Palette.ink.opacity(0.88).ignoresSafeArea()
      ScrollView {
        VStack(spacing: 14, content: content)
          .padding(26).frame(maxWidth: 380)
          .background(
            LinearGradient(
              colors: [Palette.panel, Palette.ink], startPoint: .topLeading,
              endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 30)
          )
          .overlay(RoundedRectangle(cornerRadius: 30).stroke(Palette.rim, lineWidth: 1))
          .shadow(color: Palette.blue.opacity(0.25), radius: 40, y: 12)
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
      .foregroundStyle(Palette.ink).padding(.horizontal, 22).frame(height: 56)
      .background(
        LinearGradient(
          colors: [Color(red: 1, green: 0.96, blue: 0.86), Palette.pearl, Palette.gold],
          startPoint: .top, endPoint: .bottom),
        in: RoundedRectangle(cornerRadius: 18)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 18)
          .stroke(
            LinearGradient(
              colors: [.white.opacity(0.9), .white.opacity(0.05)], startPoint: .top,
              endPoint: .bottom),
            lineWidth: 1)
      )
      .shadow(color: Palette.gold.opacity(0.35), radius: 18, y: 8)
    }.accessibilityIdentifier(id)
  }

  private func micro(_ text: String, color: Color = Palette.muted) -> some View {
    Text(text).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(0.8)
      .foregroundStyle(color)
  }
}

struct WedgeShape: Shape {
  let direction: Direction
  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let outer = rect.width / 2 - 4
    let inner = outer * 0.38
    let half = Double.pi / 4 - 0.045
    var path = Path()
    path.addArc(
      center: center, radius: outer, startAngle: .radians(direction.angle - half),
      endAngle: .radians(direction.angle + half), clockwise: false)
    path.addArc(
      center: center, radius: inner, startAngle: .radians(direction.angle + half),
      endAngle: .radians(direction.angle - half), clockwise: true)
    path.closeSubpath()
    return path
  }
}
