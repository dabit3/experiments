import AVFoundation
import SwiftUI
import UIKit

@MainActor
final class GameStore: ObservableObject {
  @Published var archive: Archive
  @Published var home = true
  @Published var paused = false
  @Published var rules = false
  @Published var deckOpen = false
  @Published var pulse = 0
  @Published var enemyFeedback = ""
  @Published var playerFeedback = ""
  @Published var playerHurt = false
  private var player: AVAudioPlayer?
  private let saveURL: URL

  init() {
    let folder = URL.documentsDirectory
    saveURL = folder.appending(path: "paper-relics-v1.json")
    if let data = try? Data(contentsOf: saveURL),
      let saved = try? JSONDecoder().decode(Archive.self, from: data)
    {
      archive = saved
    } else {
      archive = Archive()
    }
  }

  func save() {
    archive.recordResult()
    if let data = try? JSONEncoder().encode(archive) {
      try? data.write(to: saveURL, options: .atomic)
    }
  }

  func act(_ action: (inout Run) -> Void) {
    guard !paused, var run = archive.run else { return }
    let before = run
    action(&run)
    let damage = run.damageDealt - before.damageDealt
    let health = run.hp - before.hp
    let block = run.block - before.block
    enemyFeedback = damage > 0 ? "−\(damage) FOE HEALTH" : ""
    playerHurt = health < 0
    if health < 0 {
      playerFeedback = "−\(-health) YOUR HEALTH"
    } else if block > 0 {
      playerFeedback = "+\(block) YOUR BLOCK"
    } else if health > 0 {
      playerFeedback = "+\(health) YOUR HEALTH"
    } else if run.turns > before.turns {
      playerFeedback = "PERFECT FOLD · NO HEALTH LOST"
    } else {
      playerFeedback = ""
    }
    archive.run = run
    pulse += 1
    save()
  }

  func start() {
    archive.start()
    enemyFeedback = ""
    playerFeedback = ""
    home = false
    paused = false
    if !archive.hasReadRules { rules = true }
    save()
  }

  func play(_ card: Card) {
    guard !paused, let run = archive.run else { return }
    let affordable = run.energy >= card.kind.cost
    act { _ = $0.play(card.id) }
    if affordable {
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      chime(frequency: card.kind.isDefense ? 440 : 660)
    } else {
      UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
  }

  func chime(frequency: Double) {
    guard archive.sound else { return }
    let rate = 22_050
    let count = rate / 9
    var bytes = Data()
    func word(_ value: UInt32, _ size: Int) {
      for index in 0..<size { bytes.append(UInt8((value >> (index * 8)) & 255)) }
    }
    bytes.append(contentsOf: "RIFF".utf8)
    word(UInt32(36 + count * 2), 4)
    bytes.append(contentsOf: "WAVEfmt ".utf8)
    word(16, 4)
    word(1, 2)
    word(1, 2)
    word(UInt32(rate), 4)
    word(UInt32(rate * 2), 4)
    word(2, 2)
    word(16, 2)
    bytes.append(contentsOf: "data".utf8)
    word(UInt32(count * 2), 4)
    for index in 0..<count {
      let time = Double(index) / Double(rate)
      let envelope = sin(Double(index) / Double(count) * .pi) * exp(-time * 24)
      let sample = Int16(sin(time * frequency * 2 * .pi) * envelope * 5_000)
      word(UInt32(UInt16(bitPattern: sample)), 2)
    }
    try? AVAudioSession.sharedInstance().setCategory(.ambient)
    player = try? AVAudioPlayer(data: bytes)
    player?.play()
  }
}

@main
struct PaperRelicsApp: App {
  @StateObject private var store = GameStore()
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
          if phase != .active {
            if !store.home && store.archive.run?.stage == .battle { store.paused = true }
            store.save()
          }
        }
    }
  }
}
