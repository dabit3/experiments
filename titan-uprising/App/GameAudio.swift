import AVFoundation
import Foundation

@MainActor
final class GameAudio {
  var enabled = true {
    didSet {
      music?.volume = enabled ? 0.3 : 0
      if enabled { music?.play() }
    }
  }
  private var music: AVAudioPlayer?
  private var voices: [AVAudioPlayer] = []

  init() {
    try? AVAudioSession.sharedInstance().setCategory(
      .playback, mode: .default, options: .mixWithOthers)
    if let url = Bundle.main.url(forResource: "score", withExtension: "wav") {
      music = try? AVAudioPlayer(contentsOf: url)
      music?.numberOfLoops = -1
      music?.volume = 0.3
      music?.play()
    }
  }

  func play(_ name: String) {
    guard enabled, let url = Bundle.main.url(forResource: name, withExtension: "wav"),
      let voice = try? AVAudioPlayer(contentsOf: url)
    else { return }
    voices.removeAll { !$0.isPlaying }
    voices.append(voice)
    voice.volume = 0.5
    voice.play()
  }
}
