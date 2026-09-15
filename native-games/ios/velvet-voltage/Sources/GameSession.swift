import AVFoundation
import Combine
import SwiftUI
import UIKit

enum AppScreen {
  case home, tutorial, playing, results
}

@MainActor
final class GameSession: ObservableObject {
  @Published var screen = AppScreen.home
  @Published var paused = false
  @Published var score = ScoreCard()
  @Published var inFlight = false
  @Published var ballNumber = 1
  @Published var banner = "THE CITY IS WAITING"
  @Published var best: Int
  @Published var lifetimeCircuits: Int
  @Published var gamesPlayed: Int
  @Published var newRecord = false
  @Published var sound: Bool { didSet { defaults.set(sound, forKey: "sound") } }
  @Published var haptics: Bool { didSet { defaults.set(haptics, forKey: "haptics") } }
  var reducedMotion = false
  var engine = PinballEngine()
  private let defaults: UserDefaults
  private var player: AVAudioPlayer?
  private var lastSound = 0.0
  private var recordedResult = false
  private var startingBest = 0

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    best = defaults.integer(forKey: "best")
    lifetimeCircuits = defaults.integer(forKey: "circuits")
    gamesPlayed = defaults.integer(forKey: "games")
    sound = defaults.object(forKey: "sound") as? Bool ?? true
    haptics = defaults.object(forKey: "haptics") as? Bool ?? true
  }

  func start() {
    if !defaults.bool(forKey: "learned") {
      screen = .tutorial
    } else {
      newGame()
    }
  }

  func newGame() {
    defaults.set(true, forKey: "learned")
    engine = PinballEngine()
    score = ScoreCard()
    ballNumber = 1
    inFlight = false
    paused = false
    recordedResult = false
    startingBest = best
    newRecord = false
    banner = "LAUNCH TO LIGHT THE CITY"
    screen = .playing
  }

  func launch() {
    guard screen == .playing, !paused else { return }
    engine.launch()
    inFlight = engine.inFlight
    ballNumber = engine.ballsUsed
    banner = "HIT 0\(score.nextDistrict + 1) · \(Self.districtNames[score.nextDistrict])"
    feedback(frequency: 240)
  }

  func setFlipper(left: Bool, pressed: Bool) {
    guard screen == .playing, !paused else { return }
    if left { engine.leftPressed = pressed } else { engine.rightPressed = pressed }
  }

  func pause() {
    guard screen == .playing else { return }
    paused = true
    engine.leftPressed = false
    engine.rightPressed = false
  }

  func consume(_ events: [TableEvent]) {
    for event in events {
      switch event {
      case .bumper(let index, let completed):
        score = engine.score
        best = max(best, score.points)
        defaults.set(best, forKey: "best")
        if completed {
          banner = "CIRCUIT LIVE · \(score.multiplier)× POWER"
        } else {
          banner = "HIT 0\(score.nextDistrict + 1) · \(Self.districtNames[score.nextDistrict])"
        }
        feedback(frequency: completed ? 880 : Double(400 + index * 160))
      case .flipper:
        feedback(frequency: 150)
      case .drain:
        inFlight = false
        if engine.finished {
          finish()
        } else {
          ballNumber = engine.ballsUsed + 1
          banner = "BALL LOST · \(engine.ballsRemaining) REMAIN"
          feedback(frequency: 100)
        }
      case .rail:
        break
      }
    }
  }

  private func finish() {
    guard !recordedResult else { return }
    recordedResult = true
    newRecord = score.points > startingBest
    gamesPlayed += 1
    lifetimeCircuits += score.circuits
    defaults.set(gamesPlayed, forKey: "games")
    defaults.set(lifetimeCircuits, forKey: "circuits")
    screen = .results
  }

  func feedback(frequency: Double) {
    if haptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    guard sound, ProcessInfo.processInfo.systemUptime - lastSound > 0.07 else { return }
    lastSound = ProcessInfo.processInfo.systemUptime
    let rate = 22050
    let count = 2205
    var data = Data()
    func bytes(_ value: UInt32, count: Int) {
      for index in 0..<count { data.append(UInt8((value >> (8 * index)) & 255)) }
    }
    data.append(contentsOf: "RIFF".utf8)
    bytes(UInt32(36 + count * 2), count: 4)
    data.append(contentsOf: "WAVEfmt ".utf8)
    bytes(16, count: 4)
    bytes(1, count: 2)
    bytes(1, count: 2)
    bytes(UInt32(rate), count: 4)
    bytes(UInt32(rate * 2), count: 4)
    bytes(2, count: 2)
    bytes(16, count: 2)
    data.append(contentsOf: "data".utf8)
    bytes(UInt32(count * 2), count: 4)
    for sample in 0..<count {
      let t = Double(sample) / Double(rate)
      let envelope = exp(-t * 45) * min(1, t * 500)
      let value = Int16(sin(t * frequency * 2 * .pi) * envelope * 10000)
      bytes(UInt32(UInt16(bitPattern: value)), count: 2)
    }
    player = try? AVAudioPlayer(data: data)
    player?.play()
  }

  static let districtNames = ["THE ARCADE", "THE SPIRE", "THE RIVIERA"]
}
