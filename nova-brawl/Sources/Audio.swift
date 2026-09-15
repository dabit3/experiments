import AVFoundation
import Foundation

@MainActor
final class ArenaAudio {
  var muted = false
  private let engine = AVAudioEngine()
  private var players: [AVAudioPlayerNode] = []
  private var index = 0
  private var buffers: [String: AVAudioPCMBuffer] = [:]

  init() {
    let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    for _ in 0..<8 {
      let player = AVAudioPlayerNode()
      players.append(player)
      engine.attach(player)
      engine.connect(player, to: engine.mainMixerNode, format: format)
    }
    for (name, frequency, duration) in [
      ("shot", 720.0, 0.19), ("hit", 130.0, 0.18), ("beamCharge", 190.0, 0.65),
      ("beam", 95.0, 0.7), ("dodge", 940.0, 0.16), ("melee", 260.0, 0.12),
      ("start", 440.0, 0.7), ("result", 330.0, 1.3),
    ] {
      let frames = AVAudioFrameCount(duration * 44_100)
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
      buffer.frameLength = frames
      if let samples = buffer.floatChannelData?[0] {
        var phase = 0.0
        for i in 0..<Int(frames) {
          let t = Double(i) / 44_100
          let progress = t / duration
          let sweep = name == "beamCharge" ? 1 + progress * 3 : 1 - progress * 0.7
          phase += 2 * .pi * frequency * sweep / 44_100
          let chord = name == "result" ? sin(phase * 1.25) * 0.3 + sin(phase * 1.5) * 0.3 : 0
          let noise = sin(Double(i * 73 % 997)) * (name == "hit" || name == "beam" ? 0.5 : 0.08)
          let envelope = min(t * 80, 1) * pow(1 - progress, 1.6)
          samples[i] = Float((sin(phase) * 0.5 + chord + noise) * envelope * 0.22)
        }
      }
      buffers[name] = buffer
    }
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
    try? AVAudioSession.sharedInstance().setActive(true)
    try? engine.start()
  }

  func play(_ name: String) {
    guard !muted, let buffer = buffers[name] else { return }
    if !engine.isRunning { try? engine.start() }
    let player = players[index % players.count]
    index += 1
    player.stop()
    player.scheduleBuffer(buffer)
    player.play()
  }
}
