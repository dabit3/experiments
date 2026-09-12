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
      Palette.paper.ignoresSafeArea()
      PaperTexture().ignoresSafeArea().allowsHitTesting(false)
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

struct PaperTexture: View {
  var body: some View {
    Canvas { context, size in
      for i in 0..<1600 {
        let x = Double((i * 79) % 997) / 997 * size.width
        let y = Double((i * 137) % 991) / 991 * size.height
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: 1.3, height: 1.3)),
          with: .color(Palette.ink.opacity(0.045)))
      }
    }
    .accessibilityHidden(true)
  }
}

struct SweetButton: View {
  let title: String
  var icon: String = "arrow.right"
  var primary = true
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack {
        Spacer()
        Text(title).font(.system(size: 17, weight: .semibold, design: .rounded))
        Spacer()
        Image(systemName: icon).font(.system(size: 15, weight: .bold))
      }
      .padding(.horizontal, 23)
      .frame(height: 58)
      .foregroundStyle(primary ? Palette.paper : Palette.ink)
      .background(
        primary ? Palette.deepMint : Color.white.opacity(0.5),
        in: RoundedRectangle(cornerRadius: 20)
      )
      .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.ink.opacity(primary ? 0 : 0.12)))
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(primary ? Palette.ink : Palette.ink.opacity(0.08)).offset(y: 4))
    }
    .buttonStyle(PressStyle())
  }
}

struct PressStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
  }
}

struct RoundButton: View {
  let icon: String
  let label: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Image(systemName: icon)
        .font(.system(size: 17, weight: .medium))
        .frame(width: 46, height: 46)
        .background(.white.opacity(0.55), in: Circle())
        .overlay(Circle().stroke(Palette.ink.opacity(0.1)))
    }
    .buttonStyle(PressStyle())
    .accessibilityLabel(label)
  }
}

struct HomeView: View {
  @ObservedObject var store: GameStore
  var body: some View {
    GeometryReader { geometry in
      let compact = geometry.size.height < 710
      VStack(spacing: compact ? 13 : 20) {
        HStack {
          Label("POCKET CONFECTIONS", systemImage: "leaf")
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .tracking(2)
          Spacer()
          RoundButton(
            icon: store.sound ? "speaker.wave.2" : "speaker.slash",
            label: store.sound ? "Mute sound" : "Enable sound"
          ) { store.toggleSound() }
        }
        VStack(spacing: 7) {
          Text("Sugar Tether")
            .font(.system(size: compact ? 43 : 48, weight: .bold, design: .serif))
            .tracking(-2)
          HStack(spacing: 9) {
            Rectangle().frame(width: 21, height: 1)
            Text("A LITTLE SNIP. A LITTLE MAGIC.")
              .font(.system(size: 10, weight: .semibold)).tracking(1.5)
            Rectangle().frame(width: 21, height: 1)
          }
          .foregroundStyle(Palette.muted)
        }
        HeroArt().frame(maxWidth: .infinity, maxHeight: .infinity)
        VStack(spacing: 7) {
          Text("Meet Pip. Pip loves sweets.")
            .font(.system(size: 21, weight: .semibold, design: .serif))
          Text("Cut silk threads. Catch golden stars.\nBring a little sweetness home.")
            .font(.system(size: 14, design: .rounded))
            .foregroundStyle(Palette.muted)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
        }
        VStack(spacing: 13) {
          SweetButton(title: store.progress.completed == 0 ? "Let’s play" : "Keep playing") {
            store.start(store.nextLevel)
          }
          Button {
            store.page = .box
          } label: {
            HStack(spacing: 8) {
              Image(systemName: "square.grid.2x2")
              Text("The puzzle box")
              Text("· \(store.progress.totalStars)/24")
                .foregroundStyle(Palette.muted)
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .frame(height: 40)
          }
          .accessibilityLabel("The puzzle box, \(store.progress.totalStars) of 24 stars")
        }
        Text("8 HANDCRAFTED MOMENTS OF JOY")
          .font(.system(size: 10, weight: .medium)).tracking(1.7)
          .foregroundStyle(Palette.muted)
      }
      .padding(.horizontal, 28)
      .padding(.top, 8)
      .padding(.bottom, compact ? 12 : 22)
    }
  }
}

struct PuzzleBoxView: View {
  @ObservedObject var store: GameStore
  var body: some View {
    VStack(spacing: 18) {
      HStack {
        RoundButton(icon: "arrow.left", label: "Back to title") { store.leave(.home) }
        Spacer()
        Text("\(store.progress.totalStars) / 24  ★")
          .font(.system(size: 16, weight: .semibold, design: .rounded))
          .foregroundStyle(Palette.gold)
      }
      VStack(spacing: 9) {
        Text("The puzzle box").font(.system(size: 34, weight: .bold, design: .serif))
        Text("Small puzzles. Sweet discoveries.")
          .font(.system(size: 14, design: .rounded)).foregroundStyle(Palette.muted)
      }
      ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
          ForEach(Puzzle.all.indices, id: \.self) { index in
            let unlocked = store.progress.unlocked(index)
            Button {
              if unlocked { store.start(index) }
            } label: {
              VStack(spacing: 10) {
                Text(String(format: "%02d", index + 1))
                  .font(.system(size: 31, weight: .semibold, design: .serif))
                  .foregroundStyle(unlocked ? Palette.deepMint : Palette.muted)
                Text(Puzzle.all[index].title)
                  .font(.system(size: 12, weight: .semibold, design: .rounded))
                if unlocked {
                  StarRow(earned: max(0, store.progress.stars[index]), size: 14)
                } else {
                  Label("Complete puzzle \(index)", systemImage: "lock")
                    .font(.system(size: 11)).foregroundStyle(Palette.muted)
                }
              }
              .frame(maxWidth: .infinity).frame(height: 119)
              .background(
                .white.opacity(unlocked ? 0.65 : 0.2),
                in: RoundedRectangle(cornerRadius: 24)
              )
              .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.ink.opacity(0.1)))
            }
            .buttonStyle(PressStyle()).disabled(!unlocked)
            .accessibilityLabel(
              "Puzzle \(index + 1), \(Puzzle.all[index].title), \(unlocked ? "\(max(0, store.progress.stars[index])) stars" : "locked")"
            )
          }
        }
        .padding(.bottom, 12)
      }
      Text("Earn stars at your own pace. Replay any open puzzle.")
        .font(.system(size: 11, design: .rounded)).foregroundStyle(Palette.muted)
    }
    .padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 12)
  }
}

struct StarRow: View {
  let earned: Int
  var size: CGFloat = 23
  var body: some View {
    HStack(spacing: 7) {
      ForEach(0..<3) { index in
        Image(systemName: index < earned ? "star.fill" : "star")
          .font(.system(size: size, weight: .medium))
          .foregroundStyle(index < earned ? Palette.gold : Palette.muted.opacity(0.4))
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(earned) of 3 stars")
  }
}

struct PlayView: View {
  @ObservedObject var store: GameStore
  @State private var previousPoint: V?
  @State private var firstPoint: V?
  var body: some View {
    ZStack {
      VStack(spacing: 9) {
        HStack(alignment: .center) {
          RoundButton(icon: "pause", label: "Pause game") { store.paused = true }
          Spacer()
          VStack(spacing: 4) {
            Text("BONBON \(String(format: "%02d", store.level + 1)) / 08")
              .font(.system(size: 11, weight: .semibold)).tracking(1.5)
              .foregroundStyle(Palette.muted)
            Text(store.game.puzzle.title)
              .font(.system(size: 22, weight: .semibold, design: .serif))
          }
          Spacer()
          RoundButton(icon: "arrow.counterclockwise", label: "Retry puzzle") {
            store.start(store.level)
          }
        }
        HStack {
          Text(store.game.puzzle.subtitle)
            .font(.system(size: 10, weight: .semibold)).tracking(1.3)
            .foregroundStyle(Palette.muted)
          Spacer()
          StarRow(earned: store.game.collected.count, size: 17)
        }.padding(.horizontal, 9).padding(.top, 9)
        GeometryReader { geometry in
          let scale = min(geometry.size.width / 360, geometry.size.height / 560)
          let width = 360 * scale
          let height = 560 * scale
          GameArt(
            game: store.game, trail: store.trail, cutFlash: store.cutFlash,
            puffFlash: store.puffFlash, sparkles: store.sparkles, hasBegun: store.hasBegun
          )
          .frame(width: width, height: height)
          .background(Color.white.opacity(0.3), in: RoundedRectangle(cornerRadius: 28))
          .overlay(RoundedRectangle(cornerRadius: 28).stroke(Palette.ink.opacity(0.1)))
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
          Image(systemName: store.game.bubbleActive ? "hand.tap" : "hand.draw")
            .font(.system(size: 22, weight: .light)).foregroundStyle(Palette.deepMint)
          Text(
            store.game.bubbleActive && store.game.collected.count == 3
              ? "All three stars! Tap the bubble now to float down to Pip."
              : store.game.puzzle.hint
          )
          .font(.system(size: 14, design: .rounded))
          .foregroundStyle(Palette.muted).lineSpacing(3)
          .fixedSize(horizontal: false, vertical: true)
          if store.game.puzzle.puff {
            Button {
              store.puff()
            } label: {
              VStack(spacing: 3) {
                Image(systemName: "wind").font(.system(size: 23))
                Text("PUFF").font(.system(size: 9, weight: .bold)).tracking(1)
              }
              .foregroundStyle(Palette.paper)
              .frame(width: 72, height: 62)
              .background(Palette.deepMint, in: RoundedRectangle(cornerRadius: 18))
              .opacity(store.game.puffCooldown > 0 ? 0.55 : 1)
            }
            .buttonStyle(PressStyle()).accessibilityLabel("Air puff")
            .disabled(store.game.puffCooldown > 0)
          }
        }.frame(minHeight: 62).padding(.horizontal, 8)
      }
      .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 9)
      if store.paused { pauseCard }
      if store.showResult { resultCard }
    }
  }

  private var pauseCard: some View {
    card {
      Text("A sweet little break")
        .font(.system(size: 29, weight: .semibold, design: .serif))
      Text("Pip will keep your place.")
        .font(.system(size: 14, design: .rounded)).foregroundStyle(Palette.muted)
      MiniPip().frame(height: 128)
      SweetButton(title: "Keep going", icon: "play.fill") { store.paused = false }
      SweetButton(title: "Start this puzzle again", icon: "arrow.counterclockwise", primary: false)
      {
        store.start(store.level)
      }
      HStack {
        Button("Puzzle box") { store.leave(.box) }
        Spacer()
        RoundButton(
          icon: store.sound ? "speaker.wave.2" : "speaker.slash",
          label: store.sound ? "Mute sound" : "Enable sound"
        ) { store.toggleSound() }
      }.font(.system(size: 14, weight: .medium, design: .rounded))
    }
  }

  private var resultCard: some View {
    let won = store.game.outcome == .fed
    let finale = won && store.level == Puzzle.all.count - 1
    return card {
      Text(won ? "DELIVERED WITH LOVE" : "EVERY SNIP IS A NEW START")
        .font(.system(size: 9, weight: .semibold)).tracking(2).foregroundStyle(Palette.muted)
      Text(won ? (finale ? "A box of little joys" : "Sweet delivery!") : "One more little try?")
        .font(.system(size: 31, weight: .semibold, design: .serif))
        .multilineTextAlignment(.center)
      MiniPip(happy: won).frame(height: 122)
      if won {
        StarRow(earned: store.game.collected.count, size: 34)
      }
      Text(
        won
          ? "\(store.game.collected.count) stars for Pip. \(store.game.collected.count == 3 ? "Beautifully done." : "There’s more sweetness to find.")"
          : lossHint
      )
      .font(.system(size: 14, design: .rounded)).foregroundStyle(Palette.muted)
      .multilineTextAlignment(.center).lineSpacing(4)
      if won {
        Text(
          "BEST \(max(0, store.progress.stars[store.level]))/3  ·  YOUR BOX \(store.progress.totalStars)/24"
        )
        .font(.system(size: 10, weight: .semibold)).tracking(1).foregroundStyle(Palette.deepMint)
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
        .font(.system(size: 14, weight: .medium, design: .rounded)).frame(height: 35)
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

  private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Palette.ink.opacity(0.28).ignoresSafeArea().contentShape(Rectangle())
      VStack(spacing: 17, content: content)
        .padding(26)
        .frame(maxWidth: 350)
        .background(
          RoundedRectangle(cornerRadius: 32).fill(Palette.paper)
            .shadow(color: Palette.ink.opacity(0.2), radius: 24, y: 14)
        )
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(.white.opacity(0.8), lineWidth: 2))
        .padding(20)
    }
    .accessibilityAddTraits(.isModal)
  }
}
