import AVFoundation
import Combine
import SwiftUI
import UIKit

enum Screen {
  case home, chapters, playing, paused, help, hurt, lost, won
}

struct Record: Codable {
  var score = 0
  var stars = 0
  var coins = 0
  var time = 0.0
}

@MainActor
final class GameModel: ObservableObject {
  @Published var screen = Screen.home
  @Published var snapshot = Game(levelIndex: 0)
  @Published var records: [String: Record] = [:]
  @Published var sound = true
  @Published var toast = ""
  @Published var lastWasBest = false
  let scene = ForestScene()
  private let defaults: UserDefaults
  private var audio = SoundBox()
  private var toastTask: Task<Void, Never>?
  private var helpReturn = Screen.home

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    if let data = defaults.data(forKey: "buttonwood.records"),
      let saved = try? JSONDecoder().decode([String: Record].self, from: data)
    {
      records = saved
    }
    sound = defaults.object(forKey: "buttonwood.sound") as? Bool ?? true
    scene.onChange = { [weak self] game, events in
      self?.receive(game, events: events)
    }
    scene.load(0, showcase: true)
  }

  var unlocked: Int {
    min(2, (0..<3).filter { records[String($0)] != nil }.count)
  }

  var totalBest: Int { records.values.reduce(0) { $0 + $1.score } }

  func start(_ index: Int) {
    scene.load(index)
    snapshot = scene.game
    screen = .playing
    announce(Level.all[index].hint, duration: 5)
  }

  func receive(_ game: Game, events: [GameEvent]) {
    snapshot = game
    for event in events {
      if sound { audio.play(event) }
      if event != .jump {
        scene.burst(event)
        UIImpactFeedbackGenerator(style: event == .hurt ? .medium : .soft).impactOccurred()
      }
      switch event {
      case .checkpoint: announce("Lantern lit • your new starting point")
      case .shield:
        announce(game.shield ? "Acorn guard • one hit protected" : "Guard used • keep going!")
      default: break
      }
    }
    switch game.phase {
    case .completed:
      guard screen == .playing else { return }
      save(game)
      screen = .won
      scene.running = false
    case .hurt:
      screen = .hurt
      scene.running = false
    case .gameOver:
      screen = .lost
      scene.running = false
    case .playing: break
    }
  }

  private func save(_ game: Game) {
    let key = String(game.levelIndex)
    var record = records[key] ?? Record()
    lastWasBest = game.score > record.score
    record.score = max(record.score, game.score)
    record.stars = max(record.stars, game.stars)
    record.coins = max(record.coins, game.coinCount)
    record.time = record.time == 0 ? game.time : min(record.time, game.time)
    records[key] = record
    if let data = try? JSONEncoder().encode(records) {
      defaults.set(data, forKey: "buttonwood.records")
    }
  }

  func pause() {
    guard screen == .playing else { return }
    scene.running = false
    scene.game.clearInput()
    screen = .paused
  }

  func resume() {
    scene.game.clearInput()
    screen = .playing
    scene.running = true
  }

  func retryCheckpoint() {
    scene.game.respawn()
    snapshot = scene.game
    resume()
  }

  func home() {
    scene.game.clearInput()
    scene.load(0, showcase: true)
    toastTask?.cancel()
    toast = ""
    screen = .home
  }

  func showHelp() {
    helpReturn = screen
    scene.running = false
    scene.game.clearInput()
    screen = .help
  }

  func dismissHelp() {
    screen = helpReturn
  }

  func toggleSound() {
    sound.toggle()
    defaults.set(sound, forKey: "buttonwood.sound")
  }

  func move(_ direction: Double) {
    guard screen == .playing else { return }
    scene.game.direction = direction
  }

  func jump(_ pressed: Bool) {
    guard screen == .playing else { return }
    if pressed { scene.game.pressJump() } else { scene.game.releaseJump() }
  }

  func announce(_ text: String, duration: Double = 3) {
    toastTask?.cancel()
    toast = text
    toastTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(duration))
      guard !Task.isCancelled else { return }
      self?.toast = ""
    }
  }
}

@MainActor
final class SoundBox {
  private var players: [AVAudioPlayer] = []

  init() {
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
  }

  func play(_ event: GameEvent) {
    let notes: [Double] =
      switch event {
      case .jump: [370, 520]
      case .coin: [880, 1175]
      case .stomp: [200, 400]
      case .shield: [440, 660, 880]
      case .checkpoint: [523, 659, 784, 1046]
      case .hurt: [290, 220, 145]
      case .finish: [523, 659, 784, 1046, 1318]
      }
    let rate = 22050
    let samplesPerNote = 1500
    let count = notes.count * samplesPerNote
    var data = Data()
    func append<T: FixedWidthInteger>(_ value: T) {
      var little = value.littleEndian
      withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    data.append(contentsOf: "RIFF".utf8)
    append(UInt32(36 + count * 2))
    data.append(contentsOf: "WAVEfmt ".utf8)
    append(UInt32(16))
    append(UInt16(1))
    append(UInt16(1))
    append(UInt32(rate))
    append(UInt32(rate * 2))
    append(UInt16(2))
    append(UInt16(16))
    data.append(contentsOf: "data".utf8)
    append(UInt32(count * 2))
    for i in 0..<count {
      let local = i % samplesPerNote
      let envelope = sin(.pi * Double(local) / Double(samplesPerNote))
      let sample = sin(Double(local) * notes[i / samplesPerNote] * 2 * .pi / Double(rate))
      append(Int16(sample * envelope * 2800))
    }
    players.removeAll { !$0.isPlaying }
    if let player = try? AVAudioPlayer(data: data) {
      player.volume = 0.4
      player.play()
      players.append(player)
    }
  }
}
