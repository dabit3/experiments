import AVFoundation
import SwiftUI
import UIKit

@main
struct SugarTetherApp: App {
  var body: some Scene {
    WindowGroup { RootView() }
  }
}

enum Palette {
  static let paper = Color(red: 0.98, green: 0.95, blue: 0.88)
  static let ink = Color(red: 0.19, green: 0.29, blue: 0.25)
  static let muted = Color(red: 0.37, green: 0.42, blue: 0.33)
  static let mint = Color(red: 0.34, green: 0.59, blue: 0.45)
  static let deepMint = Color(red: 0.23, green: 0.43, blue: 0.33)
  static let pink = Color(red: 0.83, green: 0.39, blue: 0.40)
  static let gold = Color(red: 0.88, green: 0.66, blue: 0.24)
  static let cream = Color(red: 0.995, green: 0.975, blue: 0.93)
  static let blush = Color(red: 0.98, green: 0.89, blue: 0.83)
  static let honey = Color(red: 0.97, green: 0.81, blue: 0.47)
  static let caramel = Color(red: 0.70, green: 0.49, blue: 0.27)
  static let plum = Color(red: 0.62, green: 0.25, blue: 0.32)
}

@MainActor
final class GameStore: NSObject, ObservableObject {
  enum Page { case home, box, game }
  @Published var page: Page = .home
  @Published var game = PhysicsGame(puzzle: Puzzle.all[0])
  @Published var progress: Progress
  @Published var level = 0
  @Published var paused = false
  @Published var showResult = false
  @Published var sound: Bool
  @Published var trail: [V] = []
  @Published var cutFlash = 0.0
  @Published var puffFlash = 0.0
  @Published var sparkles: [Int: Double] = [:]
  @Published var hasBegun = false
  private var displayLink: CADisplayLink?
  private var previous: CFTimeInterval = 0
  private var ending = 0.0
  private let audio = SweetAudio()

  override init() {
    let defaults = UserDefaults.standard
    if let data = defaults.data(forKey: "sugar.progress"),
      let saved = try? JSONDecoder().decode(Progress.self, from: data),
      saved.stars.count == Puzzle.all.count,
      saved.stars.allSatisfy({ (-1...3).contains($0) })
    {
      progress = saved
    } else {
      progress = Progress()
    }
    sound = defaults.object(forKey: "sugar.sound") as? Bool ?? true
    super.init()
  }

  var nextLevel: Int {
    min(progress.stars.firstIndex(where: { $0 < 0 }) ?? 0, Puzzle.all.count - 1)
  }

  func start(_ index: Int) {
    level = index
    game = PhysicsGame(puzzle: Puzzle.all[index])
    paused = false
    showResult = false
    trail = []
    cutFlash = 0
    puffFlash = 0
    sparkles = [:]
    hasBegun = false
    ending = 0
    previous = 0
    page = .game
    displayLink?.invalidate()
    let link = CADisplayLink(target: self, selector: #selector(tick))
    link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  func leave(_ destination: Page) {
    displayLink?.invalidate()
    displayLink = nil
    page = destination
    paused = false
  }

  func toggleSound() {
    sound.toggle()
    UserDefaults.standard.set(sound, forKey: "sugar.sound")
  }

  func begin() {
    guard !paused, !showResult else { return }
    hasBegun = true
  }

  func cut(from a: V, to b: V) {
    guard !paused, !showResult else { return }
    if game.cut(from: a, to: b) > 0 {
      cutFlash = 1
      feedback(.snip)
    }
    trail.append(b)
    if trail.count > 12 { trail.removeFirst() }
  }

  func pop(at point: V) {
    guard !paused, !showResult else { return }
    if game.pop(at: point) { feedback(.pop) }
  }

  func puff() {
    guard !paused, !showResult else { return }
    begin()
    let count = game.puffs
    game.puff()
    if game.puffs > count {
      puffFlash = 1
      feedback(.pop)
    }
  }

  func feedback(_ note: SweetAudio.Note) {
    if sound { audio.play(note) }
    UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
  }

  @objc private func tick(_ link: CADisplayLink) {
    let delta = previous == 0 ? 0 : min(link.timestamp - previous, 0.05)
    previous = link.timestamp
    guard !paused, !showResult, hasBegun else { return }
    cutFlash = max(0, cutFlash - delta * 3)
    puffFlash = max(0, puffFlash - delta * 1.6)
    sparkles = sparkles.mapValues { $0 - delta * 1.7 }.filter { $0.value > 0 }
    if !trail.isEmpty { trail.removeFirst() }
    let stars = game.collected
    let priorOutcome = game.outcome
    game.advance(delta)
    if game.collected != stars {
      for index in game.collected.subtracting(stars) { sparkles[index] = 1 }
      feedback(.star)
    }
    if priorOutcome == .playing, game.outcome != .playing {
      if game.outcome == .fed {
        progress.record(level: level, stars: game.collected.count)
        if let data = try? JSONEncoder().encode(progress) {
          UserDefaults.standard.set(data, forKey: "sugar.progress")
        }
        feedback(.win)
      } else {
        feedback(.miss)
      }
    }
    if game.outcome != .playing {
      ending += delta
      if ending > 0.8 { showResult = true }
    }
  }
}

@MainActor
final class SweetAudio {
  enum Note { case snip, star, pop, win, miss }
  private var players: [AVAudioPlayer] = []

  func play(_ note: Note) {
    let frequencies: [Double]
    switch note {
    case .snip: frequencies = [740, 520]
    case .star: frequencies = [880, 1320]
    case .pop: frequencies = [430, 860]
    case .win: frequencies = [523.25, 659.25, 783.99, 1046.5]
    case .miss: frequencies = [330, 261.6]
    }
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
    let rate = 22050
    let duration = note == .win ? 0.14 : 0.07
    let sampleCount = Int(Double(rate) * duration * Double(frequencies.count))
    var data = Data()
    func text(_ value: String) { data.append(contentsOf: value.utf8) }
    func number<T: FixedWidthInteger>(_ value: T) {
      var little = value.littleEndian
      withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    text("RIFF")
    number(UInt32(36 + sampleCount * 2))
    text("WAVEfmt ")
    number(UInt32(16))
    number(UInt16(1))
    number(UInt16(1))
    number(UInt32(rate))
    number(UInt32(rate * 2))
    number(UInt16(2))
    number(UInt16(16))
    text("data")
    number(UInt32(sampleCount * 2))
    for sample in 0..<sampleCount {
      let time = Double(sample) / Double(rate)
      let index = min(frequencies.count - 1, Int(time / duration))
      let local = time.truncatingRemainder(dividingBy: duration)
      let envelope = min(1, local * 200) * pow(max(0, 1 - local / duration), 2)
      let wave = sin(2 * .pi * frequencies[index] * local)
      number(Int16(wave * envelope * 5000))
    }
    players.removeAll(where: { !$0.isPlaying })
    if let player = try? AVAudioPlayer(data: data) {
      players.append(player)
      player.play()
    }
  }
}

struct RootView: View {
  @StateObject private var store = GameStore()
  @Environment(\.scenePhase) private var scenePhase
  var body: some View {
    ZStack {
      SugarBackdrop().ignoresSafeArea().allowsHitTesting(false)
      switch store.page {
      case .home: HomeView(store: store)
      case .box: PuzzleBoxView(store: store)
      case .game: PlayView(store: store)
      }
    }
    .foregroundStyle(Palette.ink)
    .preferredColorScheme(.light)
    .onChange(of: scenePhase) { _, phase in
      if phase != .active, store.page == .game, !store.showResult { store.paused = true }
    }
  }
}

/// Buttery paper wash with a warm glow, drifting paper clouds and fine grain.
struct SugarBackdrop: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Palette.cream, Palette.paper, Palette.blush], startPoint: .top, endPoint: .bottom)
      RadialGradient(
        colors: [Palette.honey.opacity(0.35), .clear], center: .init(x: 0.8, y: 0.08),
        startRadius: 10, endRadius: 320)
      Canvas { context, size in
        let s = size.width / 390
        Art.cloud(&context, at: CGPoint(x: 50 * s, y: size.height * 0.18), scale: 1.3 * s)
        Art.cloud(&context, at: CGPoint(x: size.width - 40 * s, y: size.height * 0.42), scale: s)
        Art.cloud(&context, at: CGPoint(x: 70 * s, y: size.height * 0.74), scale: 0.9 * s)
        for i in 0..<1600 {
          let x = Double((i * 79) % 997) / 997 * size.width
          let y = Double((i * 137) % 991) / 991 * size.height
          context.fill(
            Path(ellipseIn: CGRect(x: x, y: y, width: 1.3, height: 1.3)),
            with: .color(Palette.ink.opacity(0.045)))
        }
      }
    }
    .accessibilityHidden(true)
  }
}

/// A felt panel with a soft drop, a pale rim and an inset running stitch.
struct FeltCard: ViewModifier {
  var fill: Color = .white
  var corner: CGFloat = 26
  var stitch: Color = Palette.caramel.opacity(0.35)
  var lift: CGFloat = 8
  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: corner).fill(fill)
          .shadow(color: Palette.caramel.opacity(0.18), radius: lift * 1.6, y: lift)
      )
      .overlay(
        RoundedRectangle(cornerRadius: max(2, corner - 6))
          .stroke(stitch, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
          .padding(6)
      )
      .overlay(RoundedRectangle(cornerRadius: corner).stroke(.white.opacity(0.9), lineWidth: 1.5))
  }
}

extension View {
  func felt(
    _ fill: Color = .white, corner: CGFloat = 26, stitch: Color = Palette.caramel.opacity(0.35),
    lift: CGFloat = 8
  ) -> some View {
    modifier(FeltCard(fill: fill, corner: corner, stitch: stitch, lift: lift))
  }
}

struct SweetButton: View {
  let title: String
  var icon: String = "arrow.right"
  var primary = true
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Spacer(minLength: 0)
        Text(title).font(.system(size: 17, weight: .bold, design: .rounded))
        Spacer(minLength: 0)
        Image(systemName: icon)
          .font(.system(size: 13, weight: .black))
          .foregroundStyle(primary ? Palette.ink : Palette.cream)
          .frame(width: 30, height: 30)
          .background(primary ? Palette.honey : Palette.mint, in: Circle())
          .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
      }
      .padding(.leading, 26).padding(.trailing, 13)
      .frame(height: 60)
      .foregroundStyle(primary ? Palette.cream : Palette.ink)
      .background(
        RoundedRectangle(cornerRadius: 22).fill(
          LinearGradient(
            colors: primary ? [Palette.mint, Palette.deepMint] : [.white, Palette.cream],
            startPoint: .top, endPoint: .bottom))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 17)
          .stroke(
            primary ? Palette.cream.opacity(0.55) : Palette.caramel.opacity(0.4),
            style: StrokeStyle(lineWidth: 1, dash: [3, 4])
          )
          .padding(5)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 22).stroke(
          primary ? Palette.deepMint : Palette.caramel.opacity(0.35), lineWidth: 1)
      )
      .background(
        RoundedRectangle(cornerRadius: 22)
          .fill(primary ? Palette.ink : Palette.caramel.opacity(0.45)).offset(y: 5)
      )
      .shadow(color: Palette.caramel.opacity(0.22), radius: 12, y: 8)
    }
    .buttonStyle(PressStyle())
  }
}

struct PressStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1)
      .offset(y: configuration.isPressed ? 2 : 0)
      .animation(reduceMotion ? nil : .spring(duration: 0.22), value: configuration.isPressed)
  }
}

struct RoundButton: View {
  let icon: String
  let label: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Palette.deepMint)
        .frame(width: 46, height: 46)
        .background(
          Circle().fill(
            LinearGradient(colors: [.white, Palette.cream], startPoint: .top, endPoint: .bottom)
          )
          .shadow(color: Palette.caramel.opacity(0.25), radius: 6, y: 4)
        )
        .overlay(
          Circle().stroke(
            Palette.caramel.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [2, 3])
          )
          .padding(4)
        )
        .overlay(Circle().stroke(.white, lineWidth: 1.5))
    }
    .buttonStyle(PressStyle())
    .accessibilityLabel(label)
  }
}

/// Small caps eyebrow text with a candy dot on either side.
struct Eyebrow: View {
  let text: String
  var color: Color = Palette.caramel
  var body: some View {
    HStack(spacing: 8) {
      Circle().frame(width: 4, height: 4)
      Text(text).font(.system(size: 10, weight: .bold, design: .rounded)).tracking(2.2)
      Circle().frame(width: 4, height: 4)
    }
    .foregroundStyle(color)
  }
}

/// The wordmark: a warm serif with a caramel-to-mint glaze and a stitched flourish.
struct Wordmark: View {
  var size: CGFloat = 50
  var body: some View {
    VStack(spacing: 6) {
      Text("Sugar Tether")
        .font(.system(size: size, weight: .bold, design: .serif))
        .tracking(-1.5)
        .foregroundStyle(
          LinearGradient(
            colors: [Palette.deepMint, Palette.ink], startPoint: .top, endPoint: .bottom)
        )
        .shadow(color: .white.opacity(0.9), radius: 0, y: 1.5)
        .shadow(color: Palette.caramel.opacity(0.25), radius: 10, y: 8)
      Canvas { context, canvasSize in
        let midY = canvasSize.height / 2
        let midX = canvasSize.width / 2
        var line = Path()
        line.move(to: CGPoint(x: midX - 110, y: midY))
        line.addQuadCurve(
          to: CGPoint(x: midX - 18, y: midY), control: CGPoint(x: midX - 64, y: midY - 7))
        line.move(to: CGPoint(x: midX + 18, y: midY))
        line.addQuadCurve(
          to: CGPoint(x: midX + 110, y: midY), control: CGPoint(x: midX + 64, y: midY - 7))
        context.stroke(
          line, with: .color(Palette.caramel.opacity(0.7)),
          style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [3, 3]))
        Art.candy(&context, at: V(x: midX, y: midY), radius: 7, rotation: 0.5)
      }
      .frame(width: 240, height: 18)
      .accessibilityHidden(true)
    }
  }
}

struct HomeView: View {
  @ObservedObject var store: GameStore
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  var body: some View {
    GeometryReader { geometry in
      let compact = geometry.size.height < 710
      VStack(spacing: compact ? 12 : 18) {
        HStack {
          HStack(spacing: 7) {
            Image(systemName: "leaf.fill").font(.system(size: 10))
            Text("POCKET CONFECTIONS")
              .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(2)
          }
          .foregroundStyle(Palette.caramel)
          .padding(.horizontal, 12).frame(height: 30)
          .felt(Palette.cream, corner: 15, lift: 3)
          Spacer()
          RoundButton(
            icon: store.sound ? "speaker.wave.2.fill" : "speaker.slash.fill",
            label: store.sound ? "Mute sound" : "Enable sound"
          ) { store.toggleSound() }
        }
        VStack(spacing: 8) {
          Wordmark(size: compact ? 44 : 50)
          Text("A LITTLE SNIP. A LITTLE MAGIC.")
            .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(2.4)
            .foregroundStyle(Palette.caramel)
        }
        TimelineView(.animation(paused: reduceMotion)) { timeline in
          HeroArt(phase: reduceMotion ? 0.6 : timeline.date.timeIntervalSinceReferenceDate * 1.4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        VStack(spacing: 7) {
          Text("Meet Pip. Pip loves sweets.")
            .font(.system(size: 22, weight: .semibold, design: .serif))
          Text("Cut silk threads. Catch golden stars.\nBring a little sweetness home.")
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(Palette.muted)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
        }
        VStack(spacing: 12) {
          SweetButton(title: store.progress.completed == 0 ? "Let’s play" : "Keep playing") {
            store.start(store.nextLevel)
          }
          Button {
            store.page = .box
          } label: {
            HStack(spacing: 10) {
              Image(systemName: "square.grid.2x2.fill").font(.system(size: 13))
                .foregroundStyle(Palette.deepMint)
              Text("The puzzle box")
              Text("\(store.progress.totalStars) / 24")
                .foregroundStyle(Palette.caramel)
              StarBadge(size: 11, earned: true)
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .padding(.horizontal, 18).frame(height: 44)
            .felt(Palette.cream, corner: 22, lift: 4)
          }
          .buttonStyle(PressStyle())
          .accessibilityLabel("The puzzle box, \(store.progress.totalStars) of 24 stars")
        }
        Eyebrow(text: "EIGHT HANDCRAFTED PUZZLES")
      }
      .padding(.horizontal, 26)
      .padding(.top, 8)
      .padding(.bottom, compact ? 10 : 18)
    }
  }
}

/// A candy-glass star drawn with the game art so UI stars match the playfield.
struct StarBadge: View {
  var size: CGFloat = 20
  var earned: Bool
  var body: some View {
    Canvas { context, canvasSize in
      let center = V(x: canvasSize.width / 2, y: canvasSize.height / 2)
      if earned {
        Art.star(&context, at: center, radius: size / 2)
      } else {
        let shape = Art.starPath(at: center, radius: size / 2)
        context.fill(shape, with: .color(Palette.caramel.opacity(0.12)))
        context.stroke(shape, with: .color(Palette.caramel.opacity(0.45)), lineWidth: 1)
      }
    }
    .frame(width: size + 6, height: size + 6)
    .accessibilityHidden(true)
  }
}

struct StarRow: View {
  let earned: Int
  var size: CGFloat = 23
  var body: some View {
    HStack(spacing: size * 0.28) {
      ForEach(0..<3) { index in
        StarBadge(size: size, earned: index < earned)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(earned) of 3 stars")
  }
}

struct PuzzleBoxView: View {
  @ObservedObject var store: GameStore
  private let accents = [
    Color(red: 0.99, green: 0.87, blue: 0.80), Color(red: 0.83, green: 0.92, blue: 0.83),
    Color(red: 0.98, green: 0.91, blue: 0.72), Color(red: 0.86, green: 0.90, blue: 0.96),
  ]
  var body: some View {
    VStack(spacing: 16) {
      HStack {
        RoundButton(icon: "arrow.left", label: "Back to title") { store.leave(.home) }
        Spacer()
        HStack(spacing: 6) {
          StarBadge(size: 13, earned: true)
          Text("\(store.progress.totalStars) / 24")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.caramel)
        }
        .padding(.horizontal, 14).frame(height: 36)
        .felt(Palette.cream, corner: 18, lift: 3)
      }
      VStack(spacing: 8) {
        Eyebrow(text: "PIP’S COLLECTION")
        Text("The puzzle box").font(.system(size: 34, weight: .bold, design: .serif))
          .foregroundStyle(
            LinearGradient(
              colors: [Palette.deepMint, Palette.ink], startPoint: .top, endPoint: .bottom))
        ProgressGauge(value: store.progress.totalStars, total: 24)
          .frame(width: 220, height: 12)
          .padding(.top, 4)
      }
      ScrollView(showsIndicators: false) {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
          ForEach(Puzzle.all.indices, id: \.self) { index in
            let unlocked = store.progress.unlocked(index)
            Button {
              if unlocked { store.start(index) }
            } label: {
              VStack(spacing: 8) {
                Text(String(format: "%02d", index + 1))
                  .font(.system(size: 22, weight: .bold, design: .serif))
                  .foregroundStyle(unlocked ? Palette.deepMint : Palette.muted)
                  .frame(width: 46, height: 46)
                  .background(
                    Circle().fill(unlocked ? accents[index % accents.count] : Palette.cream)
                      .shadow(color: Palette.caramel.opacity(0.18), radius: 3, y: 2)
                  )
                  .overlay(Circle().stroke(.white, lineWidth: 1.5))
                Text(Puzzle.all[index].title)
                  .font(.system(size: 13, weight: .bold, design: .rounded))
                  .foregroundStyle(unlocked ? Palette.ink : Palette.muted)
                if unlocked {
                  StarRow(earned: max(0, store.progress.stars[index]), size: 15)
                } else {
                  Label("Complete puzzle \(index)", systemImage: "lock.fill")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.muted)
                }
              }
              .frame(maxWidth: .infinity).frame(height: 118)
              .felt(
                unlocked ? .white : Palette.cream.opacity(0.7), corner: 24,
                stitch: Palette.caramel.opacity(unlocked ? 0.35 : 0.18), lift: unlocked ? 6 : 2)
            }
            .buttonStyle(PressStyle()).disabled(!unlocked)
            .accessibilityLabel(
              "Puzzle \(index + 1), \(Puzzle.all[index].title), \(unlocked ? "\(max(0, store.progress.stars[index])) stars" : "locked")"
            )
          }
        }
        .padding(.horizontal, 2)
        .padding(.top, 6)
        Text("Earn stars at your own pace. Replay any open puzzle.")
          .font(.system(size: 12, weight: .medium, design: .rounded))
          .foregroundStyle(Palette.muted)
          .padding(.vertical, 14)
      }
      .scrollIndicators(.visible)
    }
    .padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 12)
  }
}

/// A felt gauge filling with honey as stars are earned.
struct ProgressGauge: View {
  let value: Int
  let total: Int
  var body: some View {
    GeometryReader { geometry in
      let fraction = CGFloat(value) / CGFloat(max(1, total))
      ZStack(alignment: .leading) {
        Capsule().fill(Palette.cream)
          .overlay(Capsule().stroke(Palette.caramel.opacity(0.35), lineWidth: 1))
        Capsule()
          .fill(
            LinearGradient(
              colors: [Palette.honey, Palette.gold], startPoint: .top, endPoint: .bottom)
          )
          .frame(width: max(geometry.size.height, geometry.size.width * fraction))
          .overlay(alignment: .top) {
            Capsule().fill(.white.opacity(0.5)).frame(height: 3).padding(.horizontal, 5).padding(
              .top, 2)
          }
          .padding(1.5)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(value) of \(total) stars collected")
  }
}

struct PlayView: View {
  @ObservedObject var store: GameStore
  @State private var previousPoint: V?
  @State private var firstPoint: V?
  var body: some View {
    ZStack {
      VStack(spacing: 10) {
        HStack(alignment: .center) {
          RoundButton(icon: "pause.fill", label: "Pause game") { store.paused = true }
          Spacer()
          VStack(spacing: 3) {
            Text("BONBON \(String(format: "%02d", store.level + 1)) OF 08")
              .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.8)
              .foregroundStyle(Palette.caramel)
            Text(store.game.puzzle.title)
              .font(.system(size: 23, weight: .bold, design: .serif))
              .foregroundStyle(
                LinearGradient(
                  colors: [Palette.deepMint, Palette.ink], startPoint: .top, endPoint: .bottom))
          }
          Spacer()
          RoundButton(icon: "arrow.counterclockwise", label: "Retry puzzle") {
            store.start(store.level)
          }
        }
        HStack {
          Text(store.game.puzzle.subtitle)
            .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.6)
            .foregroundStyle(Palette.muted)
          Spacer()
          StarRow(earned: store.game.collected.count, size: 17)
            .padding(.horizontal, 10).frame(height: 32)
            .felt(Palette.cream, corner: 16, lift: 2)
        }.padding(.horizontal, 6).padding(.top, 4)
        GeometryReader { geometry in
          let scale = min(geometry.size.width / 360, geometry.size.height / 560)
          let width = 360 * scale
          let height = 560 * scale
          GameArt(
            game: store.game, trail: store.trail, cutFlash: store.cutFlash,
            puffFlash: store.puffFlash, sparkles: store.sparkles, hasBegun: store.hasBegun
          )
          .frame(width: width, height: height)
          .shadow(color: Palette.caramel.opacity(0.28), radius: 18, y: 12)
          .contentShape(Rectangle())
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { value in
                store.begin()
                let point = V(x: value.location.x / scale, y: value.location.y / scale)
                if let previousPoint {
                  store.cut(from: previousPoint, to: point)
                } else {
                  firstPoint = point
                }
                previousPoint = point
              }
              .onEnded { value in
                let point = V(x: value.location.x / scale, y: value.location.y / scale)
                if let firstPoint, firstPoint.distance(point) < 15 { store.pop(at: point) }
                previousPoint = nil
                firstPoint = nil
              }
          )
          .accessibilityLabel(
            "Puzzle playfield. Swipe across visible silk threads to cut. \(store.game.collected.count) stars collected."
          )
          .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        HStack(spacing: 12) {
          Image(systemName: store.game.bubbleActive ? "hand.tap.fill" : "hand.draw.fill")
            .font(.system(size: 18, weight: .medium)).foregroundStyle(Palette.cream)
            .frame(width: 38, height: 38)
            .background(
              Circle().fill(
                LinearGradient(
                  colors: [Palette.mint, Palette.deepMint], startPoint: .top, endPoint: .bottom)))
          Text(
            store.game.bubbleActive && store.game.collected.count == 3
              ? "All three stars! Tap the bubble now to float down to Pip."
              : store.game.puzzle.hint
          )
          .font(.system(size: 13.5, weight: .medium, design: .rounded))
          .foregroundStyle(Palette.ink.opacity(0.85)).lineSpacing(3)
          .fixedSize(horizontal: false, vertical: true)
          Spacer(minLength: 0)
          if store.game.puzzle.puff {
            Button {
              store.puff()
            } label: {
              VStack(spacing: 2) {
                Image(systemName: "wind").font(.system(size: 22, weight: .semibold))
                Text("PUFF").font(.system(size: 9, weight: .black, design: .rounded)).tracking(1.4)
              }
              .foregroundStyle(Palette.ink)
              .frame(width: 66, height: 66)
              .background(
                Circle().fill(
                  LinearGradient(
                    colors: [Color(red: 1, green: 0.9, blue: 0.6), Palette.honey], startPoint: .top,
                    endPoint: .bottom)
                )
                .shadow(color: Palette.caramel.opacity(0.35), radius: 6, y: 5)
              )
              .overlay(
                Circle().stroke(
                  Palette.caramel.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [2, 3])
                )
                .padding(5)
              )
              .overlay(Circle().stroke(.white, lineWidth: 1.5))
              .background(Circle().fill(Palette.caramel).offset(y: 4))
              .opacity(store.game.puffCooldown > 0 ? 0.5 : 1)
            }
            .buttonStyle(PressStyle()).accessibilityLabel("Air puff")
            .disabled(store.game.puffCooldown > 0)
          }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .frame(minHeight: 66)
        .felt(Palette.cream, corner: 24, lift: 4)
      }
      .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 10)
      if store.paused { pauseCard }
      if store.showResult { resultCard }
    }
  }

  private var pauseCard: some View {
    card(eyebrow: "PAUSED") {
      Text("A sweet little break")
        .font(.system(size: 29, weight: .bold, design: .serif))
      Text("Pip will keep your place.")
        .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(Palette.muted)
      MiniPip().frame(height: 128)
      SweetButton(title: "Keep going", icon: "play.fill") { store.paused = false }
      SweetButton(title: "Start this puzzle again", icon: "arrow.counterclockwise", primary: false)
      {
        store.start(store.level)
      }
      HStack(spacing: 14) {
        Button("The puzzle box") { store.leave(.box) }
          .foregroundStyle(Palette.deepMint)
          .padding(.horizontal, 16).padding(.vertical, 12)
          .felt(Palette.cream, corner: 22, lift: 3)
        RoundButton(
          icon: store.sound ? "speaker.wave.2.fill" : "speaker.slash.fill",
          label: store.sound ? "Mute sound" : "Enable sound"
        ) { store.toggleSound() }
      }.font(.system(size: 14, weight: .bold, design: .rounded))
    }
  }

  private var resultCard: some View {
    let won = store.game.outcome == .fed
    let finale = won && store.level == Puzzle.all.count - 1
    return card(eyebrow: won ? "DELIVERED WITH LOVE" : "EVERY SNIP IS A NEW START") {
      Text(won ? (finale ? "A box of little joys" : "Sweet delivery!") : "One more little try?")
        .font(.system(size: 31, weight: .bold, design: .serif))
        .multilineTextAlignment(.center)
        .foregroundStyle(
          LinearGradient(
            colors: [Palette.deepMint, Palette.ink], startPoint: .top, endPoint: .bottom))
      MiniPip(happy: won).frame(height: 122)
      if won {
        ResultStars(earned: store.game.collected.count)
      }
      Text(
        won
          ? "\(store.game.collected.count) \(store.game.collected.count == 1 ? "star" : "stars") for Pip. \(store.game.collected.count == 3 ? "Beautifully done." : "There’s more sweetness to find.")"
          : lossHint
      )
      .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(Palette.muted)
      .multilineTextAlignment(.center).lineSpacing(4)
      if won {
        HStack(spacing: 14) {
          Text("BEST \(max(0, store.progress.stars[store.level]))/3")
          Circle().frame(width: 3, height: 3)
          Text("YOUR BOX \(store.progress.totalStars)/24")
        }
        .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.2)
        .foregroundStyle(Palette.caramel)
        .padding(.horizontal, 14).frame(height: 28)
        .felt(Palette.cream, corner: 14, lift: 2)
      }
      SweetButton(
        title: won ? (finale ? "Back to the puzzle box" : "Next little puzzle") : "Try again",
        icon: won ? "arrow.right" : "arrow.counterclockwise"
      ) {
        if won {
          if finale { store.leave(.box) } else { store.start(store.level + 1) }
        } else {
          store.start(store.level)
        }
      }
      if won {
        SweetButton(
          title: "Replay for the joy of it", icon: "arrow.counterclockwise", primary: false
        ) {
          store.start(store.level)
        }
      }
      Button("The puzzle box") { store.leave(.box) }
        .font(.system(size: 14, weight: .bold, design: .rounded)).frame(height: 35)
        .foregroundStyle(Palette.deepMint)
    }
  }

  private var lossHint: String {
    switch store.game.lossReason {
    case .thorn:
      return "A thorn caught the pearl.\nWait for a clear path, then snip."
    case .bubbleEscaped:
      return "The bubble floated away.\nTap it as soon as you collect the top star."
    case .escaped, nil:
      if store.game.puzzle.startsInBubble {
        return "The pearl drifted past Pip.\nFree the threads together, then pop above him."
      }
      if store.game.puzzle.puff {
        return "The pearl drifted past Pip.\nTry one puff just after cutting the silk."
      }
      return "The pearl slipped away.\nSnip as it turns back toward Pip."
    }
  }

  private func card<Content: View>(
    eyebrow: String, @ViewBuilder content: () -> Content
  ) -> some View {
    ZStack {
      Palette.ink.opacity(0.32).ignoresSafeArea().contentShape(Rectangle())
      VStack(spacing: 16) {
        Eyebrow(text: eyebrow)
        content()
      }
      .padding(.horizontal, 24).padding(.top, 22).padding(.bottom, 20)
      .frame(maxWidth: 350)
      .background(
        RoundedRectangle(cornerRadius: 34).fill(
          LinearGradient(colors: [.white, Palette.paper], startPoint: .top, endPoint: .bottom)
        )
        .shadow(color: Palette.ink.opacity(0.28), radius: 28, y: 16)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 27)
          .stroke(Palette.caramel.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
          .padding(7)
      )
      .overlay(RoundedRectangle(cornerRadius: 34).stroke(.white, lineWidth: 2))
      .padding(20)
    }
    .accessibilityAddTraits(.isModal)
  }
}

/// Result stars pop in one after another; Reduce Motion shows them settled.
struct ResultStars: View {
  let earned: Int
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var shown = 0
  var body: some View {
    HStack(spacing: 12) {
      ForEach(0..<3) { index in
        StarBadge(size: 36, earned: index < earned)
          .scaleEffect(index < earned && shown <= index && !reduceMotion ? 0.2 : 1)
          .opacity(index < earned && shown <= index && !reduceMotion ? 0 : 1)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(earned) of 3 stars")
    .task {
      guard !reduceMotion else { return }
      for index in 0..<earned {
        try? await Task.sleep(for: .milliseconds(index == 0 ? 120 : 260))
        withAnimation(.spring(duration: 0.45, bounce: 0.45)) { shown = index + 1 }
      }
    }
  }
}
