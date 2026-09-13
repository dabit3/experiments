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
  @Published var clock = 0.0
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
    clock += dt
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
  static let ink = Color.black
  static let navy = Color(red: 0, green: 0, blue: 0.66)
  static let blue = Color(red: 0.13, green: 0.22, blue: 0.93)
  static let sky = Color(red: 0.24, green: 0.74, blue: 0.99)
  static let yellow = Color(red: 0.97, green: 0.85, blue: 0.47)
  static let peach = Color(red: 0.99, green: 0.88, blue: 0.66)
  static let red = Color(red: 0.97, green: 0.22, blue: 0)
  static let pink = Color(red: 0.97, green: 0.47, blue: 0.97)
  static let cyan = Color(red: 0, green: 0.91, blue: 0.85)
  static let orange = Color(red: 0.99, green: 0.63, blue: 0.27)
  static let green = Color(red: 0.72, green: 0.97, blue: 0.09)
  static let gray = Color(red: 0.74, green: 0.74, blue: 0.74)
  static let steel = Color(red: 0.46, green: 0.46, blue: 0.46)
  static let shadow = Color(red: 0.23, green: 0.23, blue: 0.23)
  static let white = Color(red: 0.99, green: 0.99, blue: 0.99)
  static let rivals: [Color] = [red, pink, cyan, orange]
}

struct ArcadeView: View {
  @StateObject private var arcade = Arcade()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reducedMotion

  private var blink: Bool {
    reducedMotion || Int(arcade.clock * 2.5) % 2 == 0
  }

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
      Canvas { context, size in
        let tick = Int(arcade.clock * 2)
        var bright = Path()
        var dim = Path()
        for index in 0..<48 {
          let x = (CGFloat((index * 137 + 21) % 997) / 997 * size.width / 3).rounded() * 3
          let y = (CGFloat((index * 229 + 7) % 991) / 991 * size.height / 3).rounded() * 3
          let rect = CGRect(x: x, y: y, width: 3, height: 3)
          if (index + tick) % 7 == 0 && !reducedMotion {
            continue
          }
          if index % 4 == 0 { bright.addRect(rect) } else { dim.addRect(rect) }
        }
        context.fill(bright, with: .color(Palette.gray))
        context.fill(dim, with: .color(Palette.shadow))
      }.ignoresSafeArea().accessibilityHidden(true)
    }
  }

  private func titleView(size: CGSize) -> some View {
    let compact = size.height < 800
    let titleScale: CGFloat = size.width < 380 ? 4 : 5
    return VStack(spacing: 0) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          PixelText("HIGH SCORE", scale: 2, color: Palette.red)
          PixelText(String(format: "%06d", arcade.best), scale: 2, color: Palette.white)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 4) {
          PixelText("MAZE", scale: 2, color: Palette.red)
          PixelText(String(format: "%02d", arcade.deepest), scale: 2, color: Palette.white)
        }
        soundButton.padding(.leading, 10)
      }
      .fixedSize(horizontal: false, vertical: true)
      .padding(.top, 6)
      Spacer(minLength: 6)
      VStack(spacing: compact ? 6 : 10) {
        ZStack {
          PixelText("AFTERHOURS", scale: titleScale, color: Palette.red).offset(
            x: titleScale, y: titleScale)
          PixelText("AFTERHOURS", scale: titleScale, color: Palette.yellow)
        }
        HStack(spacing: 10) {
          PixelText("* MAZE *", scale: 3, color: Palette.cyan)
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("title")
      attract
        .frame(height: min(size.height * (compact ? 0.30 : 0.36), 330))
        .padding(.top, compact ? 12 : 18)
      PixelText(
        blink ? "TAP TO PLAY" : " ", scale: 2, color: Palette.white
      ).padding(.top, 12)
        .accessibilityHidden(true)
      Spacer(minLength: 6)
      VStack(alignment: .leading, spacing: 6) {
        mazeChoice(1, name: "BLUE HOUR")
        mazeChoice(2, name: "VELVET CIRCUIT")
      }
      .padding(.bottom, compact ? 10 : 14)
      primary("PUSH START", fill: Palette.red, id: "start") { arcade.start() }
      HStack {
        Button {
          arcade.showGuide = true
        } label: {
          PixelText("HOW TO PLAY", scale: 2, color: Palette.gray).frame(height: 46)
        }.accessibilityIdentifier("howToPlay")
        Spacer()
        PixelText("1 PLAYER", scale: 2, color: Palette.steel)
      }
    }
    .padding(.horizontal, 22).padding(.bottom, 8)
  }

  private var attract: some View {
    PixelPanel(border: Palette.blue) {
      MazeBoard(game: arcade.demo, reducedMotion: reducedMotion, attract: true)
        .aspectRatio(19.0 / 21, contentMode: .fit)
        .padding(12)
    }
    .contentShape(Rectangle())
    .onTapGesture { arcade.start() }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Live demo. Tap to play.")
    .accessibilityAddTraits(.isButton)
    .accessibilityIdentifier("attract")
  }

  private func mazeChoice(_ number: Int, name: String) -> some View {
    let selected = arcade.selectedMaze == number
    return Button {
      arcade.selectedMaze = number
      UISelectionFeedbackGenerator().selectionChanged()
    } label: {
      HStack(spacing: 12) {
        PixelText(">", scale: 2, color: selected && blink ? Palette.yellow : .clear)
        MazeThumbnail(index: number - 1).frame(width: 19, height: 21).accessibilityHidden(true)
        PixelText("MAZE \(number)", scale: 2, color: selected ? Palette.white : Palette.steel)
        PixelText(name, scale: 2, color: selected ? Palette.yellow : Palette.gray)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 6).frame(height: 40)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("maze\(number)")
    .accessibilityLabel("\(name), \(selected ? "selected" : "select maze")")
  }

  private func playView(size: CGSize) -> some View {
    let boardWidth = min(size.width - 24, max(240, (size.height - 380) * 19 / 21))
    let chase = arcade.game.frightened > 0
    return VStack(spacing: 0) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          PixelText(
            blink || arcade.game.phase != .playing ? "1UP" : " ", scale: 2, color: Palette.red)
          PixelText(String(format: "%06d", arcade.game.score), scale: 2, color: Palette.white)
            .accessibilityIdentifier("score")
        }
        Spacer()
        VStack(alignment: .center, spacing: 4) {
          PixelText("HIGH SCORE", scale: 2, color: Palette.red)
          PixelText(String(format: "%06d", arcade.best), scale: 2, color: Palette.white)
        }
        Spacer()
        Button {
          arcade.game.pause()
        } label: {
          PixelText("II", scale: 2, color: Palette.ink).frame(width: 44, height: 34)
        }
        .buttonStyle(PixelButtonStyle(fill: Palette.gray, text: Palette.ink, unit: 2))
        .accessibilityLabel("Pause").accessibilityIdentifier("pause")
      }
      .padding(.horizontal, 22).padding(.top, 6)
      ZStack {
        MazeBoard(game: arcade.game, reducedMotion: reducedMotion)
          .aspectRatio(19.0 / 21, contentMode: .fit)
        if arcade.game.phase == .ready
          || (arcade.game.phase == .lifeLost && arcade.game.hitTime < 0.4)
        {
          PixelText(
            arcade.game.phase == .lifeLost ? "GET READY" : "READY!", scale: 3,
            color: Palette.yellow
          )
          .padding(.horizontal, 12).padding(.vertical, 8).background(Palette.ink)
          .offset(y: boardWidth * 0.06)
        }
      }
      .frame(width: boardWidth)
      .padding(.top, 10)
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
      HStack(spacing: 0) {
        HStack(spacing: 5) {
          ForEach(0..<max(3, arcade.game.lives), id: \.self) { index in
            CometShape(mouth: 0.5)
              .fill(
                index < arcade.game.lives
                  ? Palette.yellow
                  : arcade.game.hitTime > 0 && index == arcade.game.lives
                    ? Palette.red : Palette.shadow
              )
              .frame(width: 16, height: 16)
          }
        }
        .accessibilityLabel("\(arcade.game.lives) lives")
        Spacer()
        PixelText(
          chase
            ? "POWER \(Int(ceil(arcade.game.frightened)))"
            : arcade.game.bonusTime > 0
              ? "+\(arcade.game.lastBonus) x\(arcade.game.combo)"
              : "\(arcade.game.remaining) LEFT",
          scale: 2,
          color: chase ? Palette.cyan : arcade.game.bonusTime > 0 ? Palette.green : Palette.gray
        )
        Spacer()
        HStack(spacing: 4) {
          MazeThumbnail(index: arcade.game.level - 1).frame(width: 13, height: 14)
          PixelText(
            "MAZE \(String(format: "%02d", arcade.game.level))", scale: 2, color: Palette.gray)
        }
      }
      .frame(width: boardWidth).padding(.top, 10)
      Spacer(minLength: 6)
      dpad.padding(.bottom, 6)
    }.padding(.bottom, 6)
  }

  private var dpad: some View {
    let arm: CGFloat = 58
    let unit: CGFloat = 3
    return ZStack {
      Rectangle().fill(Palette.shadow).frame(width: arm, height: arm * 3)
      Rectangle().fill(Palette.shadow).frame(width: arm * 3, height: arm)
      Rectangle().fill(Palette.steel).frame(width: arm - unit * 4, height: arm * 3 - unit * 4)
      Rectangle().fill(Palette.steel).frame(width: arm * 3 - unit * 4, height: arm - unit * 4)
      ForEach(Direction.allCases, id: \.rawValue) { direction in
        dpadArm(direction, arm: arm)
      }
      Rectangle().fill(Palette.shadow).frame(width: arm * 0.45, height: arm * 0.45)
    }
    .frame(width: arm * 3, height: arm * 3)
    .simultaneousGesture(
      DragGesture(minimumDistance: 14).onEnded { value in
        let dx = value.translation.width
        let dy = value.translation.height
        arcade.steer(abs(dx) > abs(dy) ? (dx > 0 ? .right : .left) : (dy > 0 ? .down : .up))
      }
    )
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Direction pad")
  }

  private func dpadArm(_ direction: Direction, arm: CGFloat) -> some View {
    let active = arcade.game.queued == direction
    let glyph = ["<", "^", ">", "v"][direction.rawValue]
    return Button {
      arcade.steer(direction)
    } label: {
      ZStack {
        Rectangle().fill(active ? Palette.red : .clear).padding(6)
        PixelText(glyph, scale: 3, color: active ? Palette.white : Palette.shadow)
      }
      .frame(width: arm, height: arm)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .offset(x: CGFloat(direction.dx) * arm, y: CGFloat(direction.dy) * arm)
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
      PixelText("PAUSE", scale: 4, color: Palette.yellow, shadow: Palette.red)
      PixelText("TAKE A BREATHER", scale: 2, color: Palette.gray).padding(.bottom, 10)
      primary("CONTINUE", fill: Palette.red, id: "resume") { arcade.game.resume() }
      HStack(spacing: 10) {
        Button {
          arcade.toggleSound()
        } label: {
          PixelText(arcade.sound ? "SOUND ON" : "SOUND OFF", scale: 2, color: Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(PixelButtonStyle(fill: Palette.gray, text: Palette.ink))
        .accessibilityIdentifier("pauseSound")
        Button {
          arcade.showGuide = true
        } label: {
          PixelText("HELP", scale: 2, color: Palette.ink).frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(PixelButtonStyle(fill: Palette.gray, text: Palette.ink))
      }
      Button {
        arcade.game.resume()
        arcade.inGame = false
      } label: {
        PixelText("QUIT TO TITLE", scale: 2, color: Palette.gray).frame(height: 44)
      }
      .accessibilityIdentifier("endRun")
    }
  }

  private var resultOverlay: some View {
    let cleared = arcade.game.phase == .cleared
    let record = arcade.game.score >= arcade.best && arcade.best > 0
    return modal {
      resultEmblem(cleared: cleared).padding(.bottom, 4)
      PixelText(
        cleared ? "MAZE CLEAR!" : "GAME OVER", scale: 4,
        color: cleared ? Palette.cyan : Palette.red,
        shadow: cleared ? Palette.navy : Palette.shadow)
      PixelText(
        cleared ? "BONUS 1000  +1 LIFE" : "THE SPIRITS GOT YOU", scale: 2, color: Palette.gray)
      VStack(spacing: 8) {
        PixelText("SCORE", scale: 2, color: Palette.red)
        PixelText(String(format: "%06d", arcade.game.score), scale: 5, color: Palette.white)
        if record {
          PixelText(blink ? "NEW HIGH SCORE!" : " ", scale: 2, color: Palette.yellow)
        } else {
          PixelText(" ", scale: 2)
        }
      }.padding(.vertical, 10).accessibilityIdentifier("resultScore")
      HStack {
        resultStat("MAZE", value: String(format: "%02d", arcade.game.level))
        Spacer()
        resultStat("DOTS", value: "\(arcade.game.collected)")
        Spacer()
        resultStat("HIGH", value: String(format: "%06d", arcade.best))
      }
      .padding(.horizontal, 12).padding(.bottom, 10)
      primary(
        cleared ? "NEXT MAZE" : "TRY AGAIN", fill: cleared ? Palette.blue : Palette.red,
        id: "replay"
      ) {
        if cleared { arcade.game.nextLevel() } else { arcade.start() }
      }
      Button {
        arcade.inGame = false
      } label: {
        PixelText("TITLE SCREEN", scale: 2, color: Palette.gray).frame(height: 44)
      }.accessibilityIdentifier("home")
    }
  }

  private var guideOverlay: some View {
    modal {
      PixelText("HOW TO PLAY", scale: 3, color: Palette.yellow, shadow: Palette.red)
      guideRow(
        Palette.yellow, title: "SWIPE OR D-PAD",
        detail: "TURNS QUEUE UNTIL THE NEXT CORNER. REVERSE ANY TIME.")
      guideRow(
        Palette.peach, title: "EAT EVERY DOT",
        detail: "10 PTS EACH. CLEAR THE MAZE FOR 1000 AND 1UP. TUNNELS WRAP.")
      guideRow(
        Palette.cyan, title: "POWER DOTS",
        detail: "50 PTS. SPIRITS TURN BLUE: EAT THEM FOR 200 400 800 1600.")
      HStack(spacing: 10) {
        ForEach(0..<4) { index in
          VStack(spacing: 8) {
            SpiritShape(identity: index).fill(Palette.rivals[index]).frame(width: 26, height: 26)
            PixelText(["HUNTS", "AMBUSH", "FLANK", "SHY"][index], scale: 1.5, color: Palette.gray)
          }.frame(maxWidth: .infinity)
        }
      }.padding(.vertical, 10)
      primary("OK!", fill: Palette.red, id: "closeGuide") { arcade.showGuide = false }
    }
  }

  private func guideRow(_ color: Color, title: String, detail: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Rectangle().fill(color).frame(width: 12, height: 12).padding(.top, 2)
      VStack(alignment: .leading, spacing: 6) {
        PixelText(title, scale: 2, color: Palette.white)
        PixelParagraph(text: detail, columns: 22)
      }
    }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
  }

  private func resultEmblem(cleared: Bool) -> some View {
    HStack(spacing: 14) {
      if cleared {
        ForEach(0..<3) { index in
          Rectangle().fill(Palette.peach).frame(width: 8, height: 8)
        }
        CometShape(mouth: 0.4).fill(Palette.yellow).frame(width: 39, height: 39)
      } else {
        CometShape(mouth: 0.9).fill(Palette.yellow).frame(width: 39, height: 39)
          .rotationEffect(.degrees(180))
        ForEach(0..<2) { index in
          SpiritShape(identity: index).fill(Palette.rivals[index]).frame(width: 39, height: 39)
        }
      }
    }
    .frame(height: 50).accessibilityHidden(true)
  }

  private func resultStat(_ label: String, value: String) -> some View {
    VStack(spacing: 6) {
      PixelText(label, scale: 2, color: Palette.red)
      PixelText(value, scale: 2, color: Palette.white)
    }
  }

  private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    let body = VStack(spacing: 14, content: content).padding(24).frame(maxWidth: 360)
    return ZStack {
      Palette.ink.opacity(0.9).ignoresSafeArea()
      ScrollView {
        PixelPanel(border: Palette.white) { body }
          .padding(20)
      }.scrollBounceBehavior(.basedOnSize)
        .defaultScrollAnchor(.center)
    }
  }

  private var soundButton: some View {
    Button {
      arcade.toggleSound()
    } label: {
      PixelText(arcade.sound ? "SND" : "MUTE", scale: 2, color: Palette.ink)
        .frame(width: 50, height: 32)
    }
    .buttonStyle(
      PixelButtonStyle(
        fill: arcade.sound ? Palette.gray : Palette.steel, text: Palette.ink, unit: 2)
    )
    .accessibilityLabel(arcade.sound ? "Mute sound" : "Enable sound").accessibilityIdentifier(
      "sound")
  }

  private func primary(_ text: String, fill: Color, id: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      PixelText(text, scale: 3, color: Palette.white, shadow: Palette.ink.opacity(0.5))
        .frame(maxWidth: .infinity).frame(height: 56)
    }
    .buttonStyle(PixelButtonStyle(fill: fill, text: Palette.white))
    .accessibilityIdentifier(id)
  }
}
