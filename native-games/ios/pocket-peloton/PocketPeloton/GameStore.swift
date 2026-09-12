import AVFoundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class GameStore: ObservableObject {
  @Published var course: Course = .riviera
  @Published var race = RaceState(course: .riviera)
  @Published var displayLane: Double = 1
  @Published var screen: Screen = .home
  @Published var paused = false
  @Published var showSettings = false
  @Published var showGuide = false
  @Published var results: [RaceResult] = []
  @Published var sound: Bool { didSet { defaults.set(sound, forKey: "sound") } }
  @Published var haptics: Bool { didSet { defaults.set(haptics, forKey: "haptics") } }
  @Published var coached: Bool { didSet { defaults.set(coached, forKey: "coached") } }
  private let defaults: UserDefaults
  private let feedback = UIImpactFeedbackGenerator(style: .light)
  private var audioPlayer: AVAudioPlayer?
  private var lastTick: Date?

  enum Screen { case home, racing, result }

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    sound = defaults.object(forKey: "sound") as? Bool ?? true
    haptics = defaults.object(forKey: "haptics") as? Bool ?? true
    coached = defaults.bool(forKey: "coached")
    if let data = defaults.data(forKey: "results"),
      let saved = try? JSONDecoder().decode([RaceResult].self, from: data)
    {
      results = saved
    }
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
  }

  func start() {
    race = RaceState(course: course)
    displayLane = 1
    paused = false
    lastTick = nil
    screen = .racing
    showGuide = !coached
    pulse()
  }

  func move(_ offset: Int) {
    guard screen == .racing, !paused, !showGuide else { return }
    let oldLane = race.lane
    race.move(to: max(0, min(2, race.lane + offset)))
    if oldLane != race.lane { pulse() }
  }

  func tick(_ date: Date) {
    defer { lastTick = date }
    guard screen == .racing, !paused, !showGuide, let previous = lastTick else { return }
    let previousCollision = race.collisions
    let previousReady = race.attackReady
    let delta = min(0.1, date.timeIntervalSince(previous))
    race.step(delta)
    displayLane += (Double(race.lane) - displayLane) * min(1, delta * 16)
    if race.collisions > previousCollision { pulse(frequency: 180) }
    if !previousReady && race.attackReady { pulse(frequency: 720) }
    if let result = race.result {
      results.append(result)
      if let data = try? JSONEncoder().encode(results.suffix(100)) {
        defaults.set(data, forKey: "results")
      }
      screen = .result
      pulse(frequency: result.rank == 1 ? 880 : 520)
    }
  }

  func pause() {
    guard screen == .racing else { return }
    race.sprintHeld = false
    paused = true
  }

  func best(for course: Course) -> RaceResult? {
    results.filter { $0.course == course }.min { $0.time < $1.time }
  }

  func pulse(frequency: Double = 420) {
    if haptics { feedback.impactOccurred() }
    guard sound else { return }
    let sampleRate = 22_050
    let count = 1_764
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
    append(UInt32(sampleRate))
    append(UInt32(sampleRate * 2))
    append(UInt16(2))
    append(UInt16(16))
    data.append(contentsOf: "data".utf8)
    append(UInt32(count * 2))
    for sample in 0..<count {
      let envelope = pow(1 - Double(sample) / Double(count), 2)
      let wave = sin(Double(sample) / Double(sampleRate) * frequency * .pi * 2)
      append(Int16(wave * envelope * 3_000))
    }
    audioPlayer = try? AVAudioPlayer(data: data)
    audioPlayer?.play()
  }
}
