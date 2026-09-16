import Observation
import QuartzCore
import UIKit

@MainActor @Observable
final class GameStore {
  private(set) var game = GameModel()
  private(set) var record: FlightRecord
  private(set) var home = true
  private(set) var newBest = false
  private let storage: RecordStorage
  private let audio = RiverAudio()
  private let feedback = UIImpactFeedbackGenerator(style: .light)
  private var lastFrame: Double?
  private var clock: FlightClock?

  init(defaults: UserDefaults = .standard) {
    storage = RecordStorage(defaults: defaults)
    record = storage.load()
  }

  func startClock() {
    guard clock == nil else { return }
    clock = FlightClock(store: self)
    clock?.start()
  }

  func stopClock() {
    clock?.stop()
    clock = nil
    lastFrame = nil
  }

  func prepareFlight() {
    game = GameModel()
    home = false
    newBest = false
    lastFrame = nil
    feedback.prepare()
  }

  func flap() {
    guard !home, game.phase == .ready || game.phase == .playing else { return }
    game.flap()
    if record.haptics { feedback.impactOccurred(intensity: 0.55) }
    if record.sound { audio.play(.flap) }
  }

  func update(at timestamp: Double) {
    defer { lastFrame = timestamp }
    guard !home, game.phase == .playing, let lastFrame else { return }
    let score = game.score
    game.advance(timestamp - lastFrame)
    if game.score > score {
      if record.sound { audio.play(.point) }
      if record.haptics { feedback.impactOccurred(intensity: 0.8) }
    }
    if game.phase == .finished {
      newBest = game.score > record.best
      record.complete(score: game.score)
      storage.save(record)
      if record.sound { audio.play(.splash) }
      if record.haptics {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
      }
    }
  }

  func pause() {
    game.pause()
    lastFrame = nil
  }

  func resume() {
    game.resume()
    lastFrame = nil
  }

  func goHome() {
    game = GameModel()
    home = true
    lastFrame = nil
  }

  func toggleSound() {
    record.sound.toggle()
    storage.save(record)
  }

  func toggleHaptics() {
    record.haptics.toggle()
    storage.save(record)
  }
}

@MainActor
private final class FlightClock: NSObject {
  private weak var store: GameStore?
  private var link: CADisplayLink?

  init(store: GameStore) {
    self.store = store
  }

  func start() {
    let link = CADisplayLink(target: self, selector: #selector(frame))
    link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
    link.add(to: .main, forMode: .common)
    self.link = link
  }

  func stop() {
    link?.invalidate()
    link = nil
  }

  @objc private func frame(_ link: CADisplayLink) {
    guard let store else {
      stop()
      return
    }
    store.update(at: link.timestamp)
  }
}
