import AVFoundation

@MainActor
final class GameAudio {
  var muted = false {
    didSet {
      music?.volume = muted ? 0 : 0.36
      if muted { for sound in voices { sound.stop() } }
    }
  }
  private var music: AVAudioPlayer?
  private var voices: [AVAudioPlayer] = []
  private var lastHit = Date.distantPast
  func start() {
    guard music == nil else { return }
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback, mode: .default, options: [.mixWithOthers])
      try AVAudioSession.sharedInstance().setActive(true)
      if let url = Bundle.main.url(forResource: "undercurrent", withExtension: "wav") {
        music = try AVAudioPlayer(contentsOf: url)
        music?.numberOfLoops = -1
        music?.volume = muted ? 0 : 0.36
        music?.play()
      }
    } catch { print("Audio unavailable: \(error.localizedDescription)") }
  }
  func play(_ kind: String) {
    guard !muted else { return }
    let name: String
    switch kind {
    case "hit", "specialHit", "hurt", "slam":
      guard Date().timeIntervalSince(lastHit) > 0.075 else { return }
      lastHit = Date()
      name = kind == "slam" ? "slam" : "hit"
    case "power": name = "power"
    case "jump": name = "jump"
    case "heal", "revive": name = "heal"
    case "clear", "gate": name = "clear"
    default: return
    }
    voices.removeAll { !$0.isPlaying }
    if let url = Bundle.main.url(forResource: name, withExtension: "wav"),
      let player = try? AVAudioPlayer(contentsOf: url)
    {
      player.volume = 0.6
      player.play()
      voices.append(player)
    }
  }
}
