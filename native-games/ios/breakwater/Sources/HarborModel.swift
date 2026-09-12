import AVFoundation
import Combine
import SwiftUI
import UIKit

enum VoyagePhase: Equatable {
  case plotting, sailing, paused, won, lost
}

struct TowBoat {
  let index: Int
  let pickupDistance: Double
}

@MainActor
final class HarborModel: ObservableObject {
  @Published var chart = HarborChart.campaign[0]
  @Published var route: [SeaPoint] = []
  @Published var track: [SeaPoint] = []
  @Published var phase = VoyagePhase.plotting
  @Published var tug = SeaPoint(x: 72, y: 448)
  @Published var heading = -Double.pi / 2
  @Published var convoy: [TowBoat] = []
  @Published var travelled = 0.0
  @Published var fuelUsed = 0.0
  @Published var failure = ""
  @Published var showGuide = false
  @Published var pickupFlash = 0.0
  @Published var unlocked: Int
  @Published var best: [String: Int]
  @Published var dailyBest: Int
  @Published var hasLearned: Bool
  @Published var sound: Bool { didSet { defaults.set(sound, forKey: "sound") } }
  @Published var haptics: Bool { didSet { defaults.set(haptics, forKey: "haptics") } }
  private var routeDistance = 0.0
  private var strokeStarts: [Int] = []
  private var drawing = false
  private let defaults: UserDefaults
  private let feedback = HarborFeedback()

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    unlocked = max(1, defaults.integer(forKey: "unlocked"))
    best = defaults.dictionary(forKey: "best") as? [String: Int] ?? [:]
    dailyBest = defaults.integer(forKey: "dailyBest-\(HarborChart.dateSeed())")
    hasLearned = defaults.bool(forKey: "hasLearned")
    sound = defaults.object(forKey: "sound") as? Bool ?? true
    haptics = defaults.object(forKey: "haptics") as? Bool ?? true
    reset()
  }

  var remaining: Double { max(0, chart.fuel - fuelUsed) }
  var plottedLength: Double { HarborRules.routeLength(route) }
  var score: Int {
    HarborRules.score(rescued: convoy.count, fuelRemaining: remaining, routeLength: travelled)
  }
  var allRescued: Bool { convoy.count == chart.boats.count }
  var routeFits: Bool { plottedLength <= chart.fuel }
  var canLaunch: Bool { phase == .plotting && route.count > 1 }

  func select(_ chart: HarborChart) {
    self.chart = chart
    reset()
  }

  func reset(keepRoute: Bool = false) {
    phase = .plotting
    tug = chart.start
    heading = -Double.pi / 2
    convoy = []
    travelled = 0
    fuelUsed = 0
    routeDistance = 0
    track = [chart.start]
    failure = ""
    drawing = false
    pickupFlash = 0
    if !keepRoute {
      route = [chart.start]
      strokeStarts = []
    }
  }

  func draw(_ point: SeaPoint) {
    guard phase == .plotting else { return }
    let point = point.clamped
    if !drawing {
      drawing = true
      if point.distance(to: chart.start) < 25 {
        route = [chart.start]
        strokeStarts = []
      }
      strokeStarts.append(route.count)
    }
    if let last = route.last, point.distance(to: last) > 4 {
      route.append(point)
    }
  }

  func endDrawing() { drawing = false }

  func undo() {
    guard phase == .plotting, let count = strokeStarts.popLast() else { return }
    route = Array(route.prefix(max(1, count)))
  }

  func clear() {
    guard phase == .plotting else { return }
    route = [chart.start]
    strokeStarts = []
  }

  func launch() {
    guard canLaunch else { return }
    phase = .sailing
    hasLearned = true
    defaults.set(true, forKey: "hasLearned")
    feedback.play(.launch, sound: sound, haptics: haptics)
  }

  func pause() {
    if phase == .sailing { phase = .paused }
  }

  func resume() {
    if phase == .paused { phase = .sailing }
  }

  func step(_ elapsed: Double) {
    guard phase == .sailing else { return }
    let dt = min(max(0, elapsed), 1.0 / 20)
    pickupFlash = max(0, pickupFlash - dt)
    let length = plottedLength
    let old = tug
    routeDistance = min(length, routeDistance + dt * 61)
    let intended = HarborRules.point(on: route, distance: routeDistance)
    let current = HarborRules.current(at: intended, chart: chart)
    tug = intended + current * 1.35
    let moved = old.distance(to: tug)
    travelled += moved
    fuelUsed += moved * (1 + Double(convoy.count) * 0.012)
    if moved > 0.01 { heading = atan2(tug.y - old.y, tug.x - old.x) }
    track.append(tug)
    for index in chart.boats.indices
    where !convoy.contains(where: { $0.index == index }) {
      if tug.distance(to: chart.boats[index]) <= HarborRules.pickupRadius {
        convoy.append(TowBoat(index: index, pickupDistance: travelled))
        pickupFlash = 1
        feedback.play(.pickup, sound: sound, haptics: haptics)
      }
    }
    if HarborRules.collides(tug, chart: chart)
      || convoy.indices.contains(where: { HarborRules.collides(towPosition($0), chart: chart) })
    {
      lose("The tow touched a reef.\nGive the whole convoy room to turn.")
    } else if remaining <= 0 {
      lose("Fuel ran dry.\nDraw a shorter line through the harbor.")
    } else if tug.distance(to: chart.home) <= HarborRules.dockRadius && allRescued {
      win()
    } else if routeDistance >= length {
      lose(
        allRescued
          ? "Your route ended offshore.\nFinish inside the brass harbor ring."
          : "There are still boats waiting.\nPass close to every numbered beacon.")
    }
  }

  func towPosition(_ offset: Int) -> SeaPoint {
    guard convoy.indices.contains(offset) else { return tug }
    let boat = convoy[offset]
    let distance = max(boat.pickupDistance, travelled - Double(offset + 1) * 22)
    return HarborRules.point(on: track, distance: distance)
  }

  func towHeading(_ offset: Int) -> Double {
    let boat = convoy[offset]
    let distance = max(boat.pickupDistance, travelled - Double(offset + 1) * 22)
    let a = HarborRules.point(on: track, distance: max(0, distance - 3))
    let b = towPosition(offset)
    return atan2(b.y - a.y, b.x - a.x)
  }

  private func lose(_ reason: String) {
    failure = reason
    phase = .lost
    feedback.play(.failure, sound: sound, haptics: haptics)
  }

  private func win() {
    phase = .won
    best[chart.id] = max(best[chart.id] ?? 0, score)
    defaults.set(best, forKey: "best")
    if chart.chapter > 0 {
      unlocked = min(4, max(unlocked, chart.chapter + 1))
      defaults.set(unlocked, forKey: "unlocked")
    } else if let seed = chart.dailySeed {
      dailyBest = max(defaults.integer(forKey: "dailyBest-\(seed)"), chart.shift + 1)
      defaults.set(dailyBest, forKey: "dailyBest-\(seed)")
    }
    feedback.play(.win, sound: sound, haptics: haptics)
  }

  func next() {
    if let seed = chart.dailySeed {
      select(.daily(seed: seed, shift: chart.shift + 1))
    } else {
      select(HarborChart.campaign[min(3, chart.chapter)])
    }
  }
}

@MainActor
final class HarborFeedback {
  enum Note {
    case pickup, launch, win, failure
  }
  private var player: AVAudioPlayer?

  func play(_ note: Note, sound: Bool, haptics: Bool) {
    if haptics {
      if note == .win {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
      } else if note == .failure {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
      } else {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
      }
    }
    guard sound else { return }
    let frequencies: [Double]
    switch note {
    case .pickup: frequencies = [660, 880]
    case .launch: frequencies = [330, 440]
    case .win: frequencies = [523.25, 659.25, 783.99, 1046.5]
    case .failure: frequencies = [220, 164.8]
    }
    let rate = 22050
    let framesPerNote = 3307
    var pcm = Data()
    for frequency in frequencies {
      for frame in 0..<framesPerNote {
        let time = Double(frame) / Double(rate)
        let envelope = min(1, Double(frame) / 150) * exp(-time * 22)
        let signal = sin(time * frequency * 2 * .pi) + 0.2 * sin(time * frequency * 4 * .pi)
        var value = Int16(signal * envelope * 4600).littleEndian
        withUnsafeBytes(of: &value) { pcm.append(contentsOf: $0) }
      }
    }
    var wave = Data()
    func text(_ string: String) { wave.append(contentsOf: string.utf8) }
    func number<T: FixedWidthInteger>(_ number: T) {
      var little = number.littleEndian
      withUnsafeBytes(of: &little) { wave.append(contentsOf: $0) }
    }
    text("RIFF")
    number(UInt32(pcm.count + 36))
    text("WAVEfmt ")
    number(UInt32(16))
    number(UInt16(1))
    number(UInt16(1))
    number(UInt32(rate))
    number(UInt32(rate * 2))
    number(UInt16(2))
    number(UInt16(16))
    text("data")
    number(UInt32(pcm.count))
    wave.append(pcm)
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
    player = try? AVAudioPlayer(data: wave)
    player?.play()
  }
}
