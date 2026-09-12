import SceneKit
import SwiftUI

@main
struct NeonBoardwalkApp: App {
  var body: some Scene {
    WindowGroup { BoardwalkView() }
  }
}

private enum Palette {
  static let mint = Color(red: 0.36, green: 1, blue: 0.86)
  static let pink = Color(red: 1, green: 0.35, blue: 0.63)
  static let navy = Color(red: 0.035, green: 0.055, blue: 0.12)
  static let muted = Color(red: 0.68, green: 0.75, blue: 0.82)
}

struct BoardwalkView: View {
  @StateObject private var game = GameStore()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reducedMotion

  var body: some View {
    ZStack {
      NativeTrack(game: game)
        .ignoresSafeArea()
      LinearGradient(
        stops: [
          .init(color: Palette.navy.opacity(0.80), location: 0),
          .init(color: .clear, location: 0.43),
          .init(color: .clear, location: 0.65),
          .init(color: Palette.navy.opacity(0.97), location: 1),
        ], startPoint: .top, endPoint: .bottom
      )
      .ignoresSafeArea()
      .allowsHitTesting(false)
      switch game.engine.phase {
      case .ready: title
      case .running: gameplay
      case .paused:
        gameplay.allowsHitTesting(false)
        pausePanel
      case .finished: resultPanel
      }
      if game.showGuide { guide }
    }
    .foregroundStyle(.white)
    .preferredColorScheme(.dark)
    .onChange(of: scenePhase) { _, phase in
      if phase != .active { game.pause() }
    }
    .onChange(of: reducedMotion) { _, value in game.reducedMotion = value }
    .onAppear { game.reducedMotion = reducedMotion }
  }

  private var title: some View {
    VStack(spacing: 0) {
      HStack {
        brand
        Spacer()
        soundButton
      }
      .padding(.top, 8)
      Spacer().frame(height: 17)
      VStack(alignment: .leading, spacing: 4) {
        eyebrow("THE COAST IS YOURS", color: Palette.mint)
        Text("NEON")
          .font(.system(size: 60, weight: .black, design: .rounded))
          .italic()
          .tracking(-3)
          .lineSpacing(-5)
        Text("BOARDWALK")
          .font(.system(size: 37, weight: .black, design: .rounded))
          .italic()
          .tracking(-1.8)
          .foregroundStyle(Palette.mint)
        Text("Chase the glow. Find your flow.")
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(.white.opacity(0.92))
          .padding(.horizontal, 12)
          .padding(.vertical, 9)
          .background(Palette.navy.opacity(0.82), in: Capsule())
          .padding(.top, 6)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Spacer(minLength: 20)
      VStack(spacing: 18) {
        HStack {
          Image(systemName: "laurel.leading").foregroundStyle(Palette.mint)
          VStack(alignment: .leading, spacing: 3) {
            eyebrow("PERSONAL BEST")
            Text("\(game.record.bestDistance.formatted()) m")
              .font(.system(size: 24, weight: .bold, design: .rounded))
              .monospacedDigit()
          }
          Spacer()
          VStack(alignment: .trailing, spacing: 4) {
            Text("\(game.record.totalCoins.formatted())")
              .font(.system(size: 20, weight: .bold, design: .rounded))
              .foregroundStyle(.yellow)
            eyebrow("LIFETIME COINS")
          }
        }
        .padding(.horizontal, 4)
        primary("LET’S RIDE", icon: "arrow.right", action: game.start)
          .accessibilityIdentifier("startRun")
        HStack(spacing: 6) {
          Image(systemName: "hand.draw")
          Text("Swipe to move · up to jump · down to slide")
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(Palette.muted)
        Button {
          game.showGuide = true
        } label: {
          Text("How to ride").font(.system(size: 14, weight: .semibold))
            .underline()
            .frame(minHeight: 36)
        }
        .accessibilityIdentifier("howToRide")
      }
      .padding(.bottom, 8)
    }
    .padding(.horizontal, 28)
  }

  private var brand: some View {
    HStack(spacing: 8) {
      Image(systemName: "sun.horizon.fill")
        .font(.system(size: 19, weight: .semibold))
        .foregroundStyle(Palette.pink)
      Text("AFTER HOURS / 01")
        .font(.system(size: 10, weight: .bold, design: .monospaced))
        .tracking(1.8)
    }
  }

  private var soundButton: some View {
    Button {
      game.sound.toggle()
    } label: {
      Image(systemName: game.sound ? "speaker.wave.2" : "speaker.slash")
        .font(.system(size: 17, weight: .semibold))
        .frame(width: 44, height: 44)
        .background(.white.opacity(0.08), in: Circle())
    }
    .accessibilityLabel(game.sound ? "Mute sound" : "Enable sound")
    .accessibilityIdentifier("soundToggle")
  }

  private var gameplay: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 3) {
          eyebrow("DISTANCE", color: Palette.mint)
          HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text("\(Int(game.engine.distance).formatted())")
              .font(.system(size: 37, weight: .heavy, design: .rounded))
              .monospacedDigit()
              .contentTransition(.numericText())
            Text("m").font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.muted)
          }
          Text("BEST \(game.record.bestDistance.formatted()) m")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(Palette.muted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
          "Distance \(Int(game.engine.distance)) metres. Best \(game.record.bestDistance) metres"
        )
        .accessibilityIdentifier("distance")
        Spacer()
        HStack(spacing: 6) {
          Image(systemName: "circle.inset.filled").foregroundStyle(.yellow)
          Text("\(game.engine.coins)").font(.system(size: 19, weight: .bold, design: .rounded))
            .monospacedDigit()
        }
        .padding(.horizontal, 13)
        .frame(height: 44)
        .background(Palette.navy.opacity(0.7), in: Capsule())
        .accessibilityLabel("\(game.engine.coins) coins")
        Button(action: game.pause) {
          Image(systemName: "pause.fill")
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 44, height: 44)
            .background(.white.opacity(0.12), in: Circle())
        }
        .accessibilityLabel("Pause")
        .accessibilityIdentifier("pauseRun")
      }
      .padding(.top, 8)
      HStack {
        if game.engine.isShielded {
          Label("SHIELD  \(Int(ceil(game.engine.shieldTime)))s", systemImage: "shield.fill")
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(Palette.mint)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Palette.mint.opacity(0.12), in: Capsule())
            .accessibilityIdentifier("shieldStatus")
        } else {
          Text(district)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(2)
            .foregroundStyle(Palette.muted)
        }
        Spacer()
      }
      .padding(.top, 14)
      Spacer()
      if game.engine.distance < 122 || game.shieldBreakTime > 0 {
        Text(coaching)
          .font(.system(size: 13, weight: .semibold))
          .padding(.horizontal, 16).padding(.vertical, 10)
          .background(Palette.navy.opacity(0.88), in: Capsule())
          .overlay(Capsule().strokeBorder(.white.opacity(0.12)))
          .padding(.bottom, 16)
          .allowsHitTesting(false)
      }
      controls
        .padding(.bottom, 6)
    }
    .padding(.horizontal, 24)
  }

  private var district: String {
    if game.engine.distance < 500 { return "01 / SUNSET STRIP" }
    if game.engine.distance < 1500 { return "02 / ELECTRIC MILE" }
    return "03 / AFTER HOURS"
  }

  private var coaching: String {
    if game.shieldBreakTime > 0 { return "Shield saved you · keep riding!" }
    if game.engine.isShielded { return "Shield ready · one hit protected." }
    if game.engine.distance < 46 { return "Amber barriers? Swipe up to jump." }
    if game.engine.distance < 83 { return "Pink signs? Swipe down to slide." }
    return "Catch the turquoise ring for a shield."
  }

  private var controls: some View {
    HStack(spacing: 12) {
      control(.left, symbol: "arrow.left", label: "LEFT")
      control(.jump, symbol: "arrow.up", label: "JUMP")
      control(.slide, symbol: "arrow.down", label: "SLIDE")
      control(.right, symbol: "arrow.right", label: "RIGHT")
    }
  }

  private func control(_ move: Move, symbol: String, label: String) -> some View {
    Button {
      game.move(move)
    } label: {
      VStack(spacing: 5) {
        Image(systemName: symbol).font(.system(size: 21, weight: .semibold))
        Text(label).font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(1.5)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 61)
      .background(Palette.navy.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
      .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.16)))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(move.rawValue.capitalized)
    .accessibilityIdentifier(move.rawValue)
  }

  private var pausePanel: some View {
    panel {
      Image(systemName: "moon.stars").font(.system(size: 34)).foregroundStyle(Palette.mint)
      eyebrow("TAKE A BREATHER", color: Palette.mint)
      Text("Coast is clear.").font(.system(size: 32, weight: .heavy, design: .rounded))
      Text("Your run is right where you left it.")
        .font(.system(size: 14)).foregroundStyle(Palette.muted)
      primary("KEEP ROLLING", icon: "play.fill", action: game.resume)
        .padding(.top, 12)
        .accessibilityIdentifier("resumeRun")
      HStack {
        soundButton
        Spacer()
        Button("End run") { game.home() }
          .font(.system(size: 14, weight: .semibold))
          .frame(minHeight: 44)
          .accessibilityIdentifier("endRun")
      }
    }
  }

  private var resultPanel: some View {
    panel {
      HStack {
        eyebrow(game.newBest ? "A NEW PERSONAL BEST" : "ONE MORE SUNSET?", color: Palette.mint)
        Spacer()
        Image(systemName: game.newBest ? "trophy.fill" : "sun.horizon.fill")
          .foregroundStyle(Palette.pink)
      }
      Text(game.newBest ? "Made your mark." : "Keep chasing.")
        .font(.system(size: 30, weight: .heavy, design: .rounded))
        .frame(maxWidth: .infinity, alignment: .leading)
      HStack(alignment: .firstTextBaseline, spacing: 7) {
        Text("\(Int(game.engine.distance).formatted())")
          .font(.system(size: 66, weight: .black, design: .rounded)).tracking(-2)
          .minimumScaleFactor(0.6).lineLimit(1)
        Text("metres").font(.system(size: 17, weight: .medium)).foregroundStyle(Palette.muted)
        Spacer(minLength: 0)
      }
      .accessibilityIdentifier("finalDistance")
      HStack {
        stat("COINS", value: "\(game.engine.coins)", icon: "circle.inset.filled", color: .yellow)
        Spacer()
        stat(
          "BEST RUN", value: "\(game.record.bestDistance) m", icon: "laurel.leading",
          color: Palette.mint)
      }
      .padding(18)
      .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 18))
      Text(crashAdvice)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(Palette.muted)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 5)
      primary("RIDE AGAIN", icon: "arrow.clockwise", action: game.start)
        .accessibilityIdentifier("retryRun")
      Button("Back to the boardwalk", action: game.home)
        .font(.system(size: 14, weight: .semibold))
        .frame(minHeight: 44)
        .accessibilityIdentifier("backHome")
    }
  }

  private var crashAdvice: String {
    switch game.engine.collision {
    case .barrier: return "Next time: jump the amber barrier, or switch lanes."
    case .sign: return "Next time: slide under the pink sign, or switch lanes."
    case .cart: return "Arcade carts fill a lane. Find the open route."
    case nil: return "A little further. A little smoother. Your coast awaits."
    }
  }

  private var guide: some View {
    panel {
      HStack {
        eyebrow("FIND YOUR FLOW", color: Palette.mint)
        Spacer()
        Button {
          game.showGuide = false
        } label: {
          Image(systemName: "xmark").frame(width: 44, height: 44)
        }.accessibilityLabel("Close guide")
      }
      Text("Four moves.\nEndless nights.")
        .font(.system(size: 31, weight: .heavy, design: .rounded))
        .frame(maxWidth: .infinity, alignment: .leading)
      guideRow(
        "arrow.left.and.right", title: "Pick your line",
        detail: "Swipe left or right to change lanes.", color: Palette.mint)
      guideRow(
        "arrow.up", title: "Rise above", detail: "Swipe up to jump amber barriers.", color: .orange)
      guideRow(
        "arrow.down", title: "Stay low", detail: "Swipe down to slide under pink signs.",
        color: Palette.pink)
      guideRow(
        "shield.fill", title: "Catch a little luck",
        detail: "Turquoise shields absorb one hit for 10s.", color: Palette.mint)
      Text(
        "Carts must be dodged. There’s always an open lane.\nPrefer taps? Use the four controls at the bottom."
      )
      .font(.system(size: 12)).foregroundStyle(Palette.muted).lineSpacing(4)
      .frame(maxWidth: .infinity, alignment: .leading)
      primary("GOT IT. LET’S RIDE.", icon: "arrow.right", action: game.start)
        .padding(.top, 4)
    }
  }

  private func guideRow(_ icon: String, title: String, detail: String, color: Color) -> some View {
    HStack(spacing: 15) {
      Image(systemName: icon).font(.system(size: 22, weight: .semibold))
        .foregroundStyle(color).frame(width: 46, height: 50)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
      VStack(alignment: .leading, spacing: 5) {
        Text(title).font(.system(size: 15, weight: .bold))
        Text(detail).font(.system(size: 12)).foregroundStyle(Palette.muted).fixedSize(
          horizontal: false, vertical: true)
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 3)
  }

  private func panel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Palette.navy.opacity(0.65).ignoresSafeArea()
      ScrollView {
        VStack(spacing: 17, content: content)
          .padding(26)
          .background(
            LinearGradient(
              colors: [Color(red: 0.085, green: 0.13, blue: 0.22), Palette.navy],
              startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 30)
          )
          .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(.white.opacity(0.13)))
          .padding(22)
      }
      .scrollBounceBehavior(.basedOnSize)
      .defaultScrollAnchor(.center)
    }
  }

  private func stat(_ title: String, value: String, icon: String, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 9) {
      eyebrow(title)
      Label(value, systemImage: icon)
        .font(.system(size: 21, weight: .bold, design: .rounded))
        .foregroundStyle(color)
    }
  }

  private func eyebrow(_ text: String, color: Color = Palette.muted) -> some View {
    Text(text).font(.system(size: 9, weight: .bold, design: .monospaced))
      .tracking(2).foregroundStyle(color)
  }

  private func primary(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack {
        Text(title).font(.system(size: 14, weight: .heavy)).tracking(1.1)
        Spacer()
        Image(systemName: icon).font(.system(size: 18, weight: .bold))
      }
      .foregroundStyle(Palette.navy)
      .padding(.horizontal, 23)
      .frame(height: 60)
      .background(Palette.mint, in: RoundedRectangle(cornerRadius: 19))
    }
    .buttonStyle(.plain)
  }
}

private struct NativeTrack: UIViewControllerRepresentable {
  @ObservedObject var game: GameStore

  func makeUIViewController(context: Context) -> TrackController {
    TrackController(game: game)
  }

  func updateUIViewController(_ controller: TrackController, context: Context) {
    controller.view.accessibilityLabel = game.engine.routeDescription
  }
}

private final class TrackController: UIViewController {
  private let game: GameStore
  override var canBecomeFirstResponder: Bool { true }

  init(game: GameStore) {
    self.game = game
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("Storyboard initialization is unsupported") }

  override func loadView() {
    let track = SCNView()
    track.scene = game.world.scene
    track.pointOfView = game.world.camera
    track.antialiasingMode = .multisampling4X
    track.preferredFramesPerSecond = 60
    track.isPlaying = true
    track.isAccessibilityElement = true
    track.accessibilityIdentifier = "boardwalk"
    track.accessibilityTraits = .updatesFrequently
    for direction: UISwipeGestureRecognizer.Direction in [.left, .right, .up, .down] {
      let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipe(_:)))
      recognizer.direction = direction
      track.addGestureRecognizer(recognizer)
    }
    view = track
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    becomeFirstResponder()
  }

  @objc private func swipe(_ gesture: UISwipeGestureRecognizer) {
    switch gesture.direction {
    case .left: game.move(.left)
    case .right: game.move(.right)
    case .up: game.move(.jump)
    case .down: game.move(.slide)
    default: break
    }
  }

  override var keyCommands: [UIKeyCommand]? {
    [
      UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(left)),
      UIKeyCommand(
        input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(right)),
      UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(jump)),
      UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(slide)),
      UIKeyCommand(input: " ", modifierFlags: [], action: #selector(togglePause)),
    ]
  }

  @objc private func left() { game.move(.left) }
  @objc private func right() { game.move(.right) }
  @objc private func jump() { game.move(.jump) }
  @objc private func slide() { game.move(.slide) }
  @objc private func togglePause() {
    if game.engine.phase == .paused { game.resume() } else { game.pause() }
  }
}
