import AVFoundation
import SwiftUI
import UIKit

enum Screen {
  case home
  case riding
  case paused
  case results
}

@MainActor
final class RideStore: NSObject, ObservableObject {
  @Published var engine = RideEngine()
  @Published var screen = Screen.home
  @Published var records = RideRecords()
  @Published var soundEnabled = true
  @Published var showGuide = false
  @Published var toast = ""
  @Published var toastDetail = ""
  @Published var toastTime = 0.0
  @Published var sceneryTime = 0.0
  @Published var newBest = false
  var reduceMotion = false
  private var displayLink: CADisplayLink?
  private var lastFrame = 0.0
  private var players: [String: AVAudioPlayer] = [:]
  private var savedCurrentRide = false
  private let defaults: UserDefaults

  override convenience init() {
    self.init(defaults: .standard)
  }

  init(defaults: UserDefaults) {
    self.defaults = defaults
    super.init()
    if let data = defaults.data(forKey: "powderline.records.v1"),
      let saved = try? JSONDecoder().decode(RideRecords.self, from: data)
    {
      records = saved
    }
    soundEnabled = defaults.object(forKey: "powderline.sound") as? Bool ?? true
    prepareSound()
    let link = CADisplayLink(target: self, selector: #selector(frame))
    link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  func start(_ mode: RideMode) {
    engine = RideEngine(mode: mode, seed: UInt64.random(in: 1...UInt64.max))
    screen = .riding
    toast = ""
    toastTime = 0
    savedCurrentRide = false
    newBest = false
    lastFrame = 0
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    if soundEnabled { players["wind"]?.play() }
  }

  func press() {
    guard screen == .riding else { return }
    let canJump = engine.grounded
    engine.press()
    if canJump {
      play("jump")
      UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
    }
  }

  func release() {
    engine.release()
  }

  func pause() {
    guard screen == .riding else { return }
    engine.release()
    screen = .paused
    players["wind"]?.pause()
  }

  func resume() {
    guard screen == .paused else { return }
    screen = .riding
    lastFrame = 0
    if soundEnabled { players["wind"]?.play() }
  }

  func finish() {
    engine.release()
    saveRide()
    screen = .results
    players["wind"]?.pause()
  }

  func home() {
    engine.release()
    screen = .home
    players["wind"]?.pause()
  }

  func toggleSound() {
    soundEnabled.toggle()
    defaults.set(soundEnabled, forKey: "powderline.sound")
    if !soundEnabled {
      for player in players.values { player.stop() }
    } else if screen == .riding {
      players["wind"]?.play()
    }
  }

  func background() {
    pause()
    players["wind"]?.pause()
    lastFrame = 0
  }

  private func saveRide() {
    guard !savedCurrentRide else { return }
    savedCurrentRide = true
    newBest = engine.mode == .expedition && engine.score > records.bestScore
    records.save(engine.summary)
    if let data = try? JSONEncoder().encode(records) {
      defaults.set(data, forKey: "powderline.records.v1")
    }
  }

  @objc private func frame(_ link: CADisplayLink) {
    let delta = lastFrame == 0 ? 0 : min(0.05, link.timestamp - lastFrame)
    lastFrame = link.timestamp
    if screen == .home && !reduceMotion { sceneryTime += delta }
    guard screen == .riding else { return }
    sceneryTime += delta
    engine.advance(delta)
    toastTime = max(0, toastTime - delta)
    switch engine.event {
    case .coin:
      play("coin")
    case .landing(let count):
      toast = count == 1 ? "BACKFLIP" : "\(count) × BACKFLIP"
      toastDetail = "+\(count * 150 * engine.combo)  ·  \(engine.combo)× COMBO"
      toastTime = 2.4
      play("land")
      UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.65)
    case .crash:
      play("crash")
      UINotificationFeedbackGenerator().notificationOccurred(.warning)
      finish()
    case .rescued:
      toast = "A SOFT LANDING"
      toastDetail = "Practice gives you another chance"
      toastTime = 2.5
    case .jump, nil:
      break
    }
  }

  private func prepareSound() {
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
    for name in ["jump", "coin", "land", "crash", "wind"] {
      guard let url = Bundle.main.url(forResource: name, withExtension: "wav"),
        let player = try? AVAudioPlayer(contentsOf: url)
      else { continue }
      player.volume = name == "wind" ? 0.20 : 0.35
      if name == "wind" { player.numberOfLoops = -1 }
      player.prepareToPlay()
      players[name] = player
    }
  }

  private func play(_ name: String) {
    guard soundEnabled, let player = players[name] else { return }
    player.currentTime = 0
    player.play()
  }
}
