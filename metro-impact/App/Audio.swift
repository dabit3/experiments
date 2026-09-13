import AVFoundation
import UIKit

@MainActor
final class SoundBank {
  static let shared = SoundBank()
  private var theme: AVAudioPlayer?
  private var effects: [String: [AVAudioPlayer]] = [:]
  private var muted = false

  func start() {
    guard theme == nil else { return }
    try? AVAudioSession.sharedInstance().setCategory(
      .playback, mode: .default, options: [.mixWithOthers])
    try? AVAudioSession.sharedInstance().setActive(true)
    if let url = Bundle.main.url(
      forResource: "harbor_theme", withExtension: "wav", subdirectory: "Assets")
    {
      theme = try? AVAudioPlayer(contentsOf: url)
      theme?.numberOfLoops = -1
      theme?.volume = 0.23
      theme?.play()
    }
    for name in ["hit", "block", "fire", "super", "ko", "start"] {
      guard
        let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Assets")
      else { continue }
      effects[name] = (0..<3).compactMap { _ in try? AVAudioPlayer(contentsOf: url) }
      for player in effects[name] ?? [] { player.prepareToPlay() }
    }
  }

  func play(_ name: String) {
    guard !muted,
      let player = effects[name]?.first(where: { !$0.isPlaying }) ?? effects[name]?.first
    else { return }
    player.currentTime = 0
    player.volume = 0.7
    player.play()
    if name == "hit" || name == "ko" { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
  }

  func mute(_ value: Bool) {
    muted = value
    theme?.volume = value ? 0 : 0.23
  }
}

func assetImage(_ name: String) -> UIImage {
  guard let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "Assets"),
    let image = UIImage(contentsOfFile: path)
  else { return UIImage() }
  return image
}
