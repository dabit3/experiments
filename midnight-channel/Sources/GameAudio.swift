import AVFoundation

@MainActor
final class GameAudio {
  private var music: AVAudioPlayer?
  private var effects: [AVAudioPlayer] = []
  var muted = false {
    didSet {
      music?.volume = muted ? 0 : 0.32
      if muted {
        for effect in effects { effect.stop() }
      }
    }
  }

  func start() {
    guard music == nil else { return }
    try? AVAudioSession.sharedInstance().setCategory(
      .playback, mode: .default, options: [.mixWithOthers])
    try? AVAudioSession.sharedInstance().setActive(true)
    guard let url = Bundle.main.url(forResource: "broadcast", withExtension: "wav") else { return }
    music = try? AVAudioPlayer(contentsOf: url)
    music?.numberOfLoops = -1
    music?.volume = muted ? 0 : 0.32
    music?.play()
  }

  func effect(_ kind: String) {
    guard !muted else { return }
    let name: String
    switch kind {
    case "hit", "heavy", "light": name = "impact"
    case "block", "card": name = "block"
    case "summon", "super", "burst", "awakening": name = "summon"
    case "ko", "fight", "round", "result": name = "sting"
    default: return
    }
    guard let url = Bundle.main.url(forResource: name, withExtension: "wav"),
      let player = try? AVAudioPlayer(contentsOf: url)
    else { return }
    effects.removeAll { !$0.isPlaying }
    effects.append(player)
    player.volume = 0.4
    player.play()
  }
}
