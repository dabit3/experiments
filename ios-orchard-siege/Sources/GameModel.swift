import AVFoundation
import SpriteKit
import SwiftUI
import UIKit

enum Screen {
  case home, levels, playing
}

struct HarvestResult {
  let won: Bool
  let score: Int
  let stars: Int
  let shots: Int
  let newBest: Bool
}

final class GameModel: ObservableObject {
  @Published var screen = Screen.home
  @Published var currentLevel = 0
  @Published var score = 0
  @Published var targets = 0
  @Published var shotsRemaining = 0
  @Published var currentFruit = Fruit.apple
  @Published var inFlight = false
  @Published var canBurst = false
  @Published var paused = false
  @Published var showHelp = false
  @Published var result: HarvestResult?
  @Published var best: [String: Int]
  @Published var stars: [String: Int]
  @Published var sound: Bool {
    didSet { UserDefaults.standard.set(sound, forKey: "orchard.sound") }
  }
  let scene = OrchardScene(size: CGSize(width: 1400, height: 660))
  let audio = OrchardAudio()
  private var shotsUsed = 0

  init() {
    best = UserDefaults.standard.dictionary(forKey: "orchard.best") as? [String: Int] ?? [:]
    stars = UserDefaults.standard.dictionary(forKey: "orchard.stars") as? [String: Int] ?? [:]
    sound = UserDefaults.standard.object(forKey: "orchard.sound") as? Bool ?? true
    scene.game = self
    scene.scaleMode = .aspectFit
    scene.showGarden()
  }

  var totalStars: Int { stars.values.reduce(0, +) }
  var unlocked: Int {
    min(5, (0..<6).first(where: { (stars[String($0)] ?? 0) == 0 }) ?? 5)
  }

  func start(_ index: Int) {
    currentLevel = index
    score = 0
    targets = Level.all[index].targets.count
    shotsRemaining = Level.all[index].fruit.count
    shotsUsed = 0
    paused = false
    result = nil
    inFlight = false
    canBurst = false
    screen = .playing
    scene.isPaused = false
    scene.start(Level.all[index])
  }

  func fired(_ fruit: Fruit) {
    shotsUsed += 1
    shotsRemaining -= 1
    inFlight = true
    canBurst = fruit == .plum
    feedback(.launch)
  }

  func addPoints(_ value: Int) {
    score += value
  }

  func finish(won: Bool) {
    guard result == nil else { return }
    let final = Rules.finalScore(destruction: score, shotsRemaining: shotsRemaining, won: won)
    let rating = Rules.stars(won: won, shotsUsed: shotsUsed, par: Level.all[currentLevel].par)
    let key = String(currentLevel)
    let newBest = won && final > (best[key] ?? 0)
    if won {
      best[key] = max(best[key] ?? 0, final)
      stars[key] = max(stars[key] ?? 0, rating)
      UserDefaults.standard.set(best, forKey: "orchard.best")
      UserDefaults.standard.set(stars, forKey: "orchard.stars")
    }
    score = final
    inFlight = false
    canBurst = false
    result = HarvestResult(
      won: won, score: final, stars: rating, shots: shotsUsed, newBest: newBest)
    feedback(won ? .win : .impact)
  }

  func setPaused(_ value: Bool) {
    guard screen == .playing, result == nil else { return }
    paused = value
    scene.isPaused = value
  }

  func home(levels: Bool = false) {
    paused = false
    result = nil
    scene.isPaused = false
    screen = levels ? .levels : .home
    scene.showGarden()
  }

  func feedback(_ event: OrchardAudio.Event) {
    if sound { audio.play(event) }
    if event == .launch || event == .burst {
      UIImpactFeedbackGenerator(style: event == .burst ? .heavy : .light).impactOccurred()
    }
  }
}

final class OrchardAudio {
  enum Event { case launch, impact, burst, win }
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private var ready = false
  private var lastImpact = Date.distantPast

  func play(_ event: Event) {
    if event == .impact {
      guard Date().timeIntervalSince(lastImpact) > 0.09 else { return }
      lastImpact = Date()
    }
    if !ready {
      try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
      engine.attach(player)
      let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)
      engine.connect(player, to: engine.mainMixerNode, format: format)
      do {
        try engine.start()
        player.play()
        ready = true
      } catch { return }
    }
    guard let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1),
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 11025),
      let data = buffer.floatChannelData?[0]
    else { return }
    buffer.frameLength = event == .win ? 11025 : 5500
    for index in 0..<Int(buffer.frameLength) {
      let time = Double(index) / 22050
      let frequency: Double
      switch event {
      case .launch: frequency = 360 - time * 650
      case .impact: frequency = 130 - time * 180
      case .burst: frequency = 80 + time * 700
      case .win: frequency = [523.25, 659.25, 783.99, 1046.5][min(3, Int(time * 8))]
      }
      data[index] = Float(sin(time * frequency * .pi * 2) * exp(-time * 9) * 0.13)
    }
    player.scheduleBuffer(buffer)
  }
}
