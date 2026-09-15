import AVFoundation
import SwiftUI

@MainActor
@Observable
final class GameStore {
  var run: Run
  var records: Records
  var recordedResult: Bool
  var selected: Set<String> = []
  var lastScore: Score?
  var started = false
  var sound: Bool {
    didSet { UserDefaults.standard.set(sound, forKey: "velvet.sound") }
  }
  var hasSave: Bool
  private var player: AVAudioPlayer?

  init() {
    let data = UserDefaults.standard.data(forKey: "velvet.save.v1")
    let saved = data.flatMap { try? JSONDecoder().decode(SavedGame.self, from: $0) }
    run = saved?.run ?? Run()
    records = saved?.records ?? Records()
    recordedResult = saved?.recordedResult ?? false
    hasSave = saved != nil
    sound = UserDefaults.standard.object(forKey: "velvet.sound") as? Bool ?? true
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
  }

  var preview: Score? { run.preview(selected) }

  func save() {
    guard
      let data = try? JSONEncoder().encode(
        SavedGame(run: run, records: records, recordedResult: recordedResult))
    else { return }
    UserDefaults.standard.set(data, forKey: "velvet.save.v1")
    hasSave = true
  }

  func newRun() {
    run = Run()
    selected = []
    lastScore = nil
    recordedResult = false
    started = true
    save()
    feedback()
  }

  func select(_ card: Card) {
    if selected.contains(card.id) {
      selected.remove(card.id)
    } else if selected.count < 5 {
      selected.insert(card.id)
    } else {
      return
    }
    UISelectionFeedbackGenerator().selectionChanged()
  }

  func play() {
    guard let result = run.play(selected) else { return }
    lastScore = result
    selected = []
    records.bestHand = max(records.bestHand, run.bestHand)
    records.bestScore = max(records.bestScore, run.totalScore)
    records.mostBlinds = max(records.mostBlinds, run.cleared)
    if [.won, .lost].contains(run.phase), !recordedResult {
      records.runs += 1
      if run.phase == .won { records.wins += 1 }
      recordedResult = true
    }
    save()
    feedback()
  }

  func discard() {
    if run.discard(selected) {
      selected = []
      save()
      feedback()
    }
  }

  func buy(_ charm: Charm) {
    if run.buy(charm) {
      save()
      feedback()
    }
  }

  func feedback() {
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    guard sound, let url = Bundle.main.url(forResource: "deal", withExtension: "wav") else {
      return
    }
    player = try? AVAudioPlayer(contentsOf: url)
    player?.volume = 0.35
    player?.play()
  }
}

@main
struct LuckyVelvetApp: App {
  @State private var game = GameStore()
  var body: some Scene {
    WindowGroup {
      LoungeView(game: game)
        .preferredColorScheme(.dark)
        .tint(Palette.gold)
    }
  }
}
