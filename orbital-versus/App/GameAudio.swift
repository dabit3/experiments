import AVFoundation
import Foundation

@MainActor
final class GameAudio {
  var muted = false {
    didSet {
      music?.volume = muted ? 0 : 0.18
      if muted {
        for voice in voices { voice.stop() }
      }
    }
  }
  private var music: AVAudioPlayer?
  private var voices: [AVAudioPlayer] = []
  func start() {
    guard music == nil else { return }
    try? AVAudioSession.sharedInstance().setCategory(
      .playback, mode: .default, options: [.mixWithOthers])
    try? AVAudioSession.sharedInstance().setActive(true)
    if let url = Bundle.main.url(forResource: "orbit", withExtension: "wav") {
      music = try? AVAudioPlayer(contentsOf: url)
      music?.numberOfLoops = -1
      music?.volume = muted ? 0 : 0.18
      music?.play()
    }
  }
  func play(_ name: String) {
    guard !muted, let url = Bundle.main.url(forResource: name, withExtension: "wav"),
      let voice = try? AVAudioPlayer(contentsOf: url)
    else { return }
    voices.removeAll { !$0.isPlaying }
    if voices.count > 12 { voices.removeFirst().stop() }
    voice.volume = name == "fire" ? 0.13 : 0.28
    voice.play()
    voices.append(voice)
  }
}
