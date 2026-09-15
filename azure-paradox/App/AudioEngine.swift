import AVFoundation
import Foundation

@MainActor
final class AudioEngine {
  static let shared = AudioEngine()
  private var music: AVAudioPlayer?
  private var voices: [AVAudioPlayer] = []
  var muted = false {
    didSet { music?.volume = muted ? 0 : 0.23 }
  }

  private init() {
    try? AVAudioSession.sharedInstance().setCategory(
      .playback, mode: .default, options: [.mixWithOthers])
    try? AVAudioSession.sharedInstance().setActive(true)
  }

  func startMusic() {
    guard music == nil, let url = Bundle.main.url(forResource: "battle", withExtension: "wav")
    else { return }
    music = try? AVAudioPlayer(contentsOf: url)
    music?.numberOfLoops = -1
    music?.volume = muted ? 0 : 0.23
    music?.play()
  }

  func stopMusic() {
    music?.stop()
    music = nil
  }

  func play(_ name: String) {
    guard !muted, let url = Bundle.main.url(forResource: name, withExtension: "wav"),
      let voice = try? AVAudioPlayer(contentsOf: url)
    else { return }
    voices.removeAll { !$0.isPlaying }
    voices.append(voice)
    if voices.count > 12 { voices.removeFirst().stop() }
    voice.volume = 0.5
    voice.play()
  }
}
