import AVFoundation
import Foundation

@MainActor
final class HiveAudio {
  var muted = false {
    didSet {
      music?.volume = muted ? 0 : 0.12
      if muted {
        for voice in voices { voice.stop() }
      }
    }
  }
  private var voices: [AVAudioPlayer] = []
  private var music: AVAudioPlayer?
  private var lastSound = Date.distantPast

  func start() {
    guard music == nil else { return }
    try? AVAudioSession.sharedInstance().setCategory(
      .ambient, mode: .default, options: [.mixWithOthers])
    let notes = [
      196.0, 293.66, 392, 493.88, 440, 392, 293.66, 246.94,
      220, 329.63, 440, 523.25, 493.88, 392, 329.63, 293.66,
    ]
    var samples: [Int16] = []
    for frequency in notes {
      samples += tone(frequency: frequency, duration: 0.3, volume: 0.22)
    }
    music = try? AVAudioPlayer(data: wave(samples))
    music?.numberOfLoops = -1
    music?.volume = muted ? 0 : 0.12
    music?.play()
  }

  func play(_ kind: String) {
    guard !muted, Date().timeIntervalSince(lastSound) > 0.065 else { return }
    lastSound = Date()
    let notes: [Double]
    switch kind {
    case "deposit": notes = [523.25, 659.25, 783.99]
    case "berry": notes = [880]
    case "transform": notes = [392, 523.25, 659.25, 1046.5]
    case "hit": notes = [130.81, 87.31]
    case "claim": notes = [440, 587.33]
    case "victory": notes = [392, 523.25, 659.25, 783.99, 1046.5]
    default: return
    }
    let samples = notes.flatMap {
      tone(frequency: $0, duration: kind == "victory" ? 0.18 : 0.065, volume: 0.22)
    }
    if let player = try? AVAudioPlayer(data: wave(samples)) {
      voices.removeAll { !$0.isPlaying }
      voices.append(player)
      player.play()
    }
  }

  private func tone(frequency: Double, duration: Double, volume: Double) -> [Int16] {
    let count = Int(duration * 22050)
    return (0..<count).map { i in
      let phase = sin(2 * Double.pi * frequency * Double(i) / 22050)
      let envelope = min(1, Double(i) / 120) * pow(1 - Double(i) / Double(count), 1.5)
      return Int16((phase > 0 ? 1.0 : -1.0) * envelope * volume * 32767)
    }
  }

  private func wave(_ samples: [Int16]) -> Data {
    var data = Data()
    func text(_ s: String) { data.append(Data(s.utf8)) }
    func number<T: FixedWidthInteger>(_ value: T) {
      var little = value.littleEndian
      withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    text("RIFF")
    number(UInt32(36 + samples.count * 2))
    text("WAVEfmt ")
    number(UInt32(16))
    number(UInt16(1))
    number(UInt16(1))
    number(UInt32(22050))
    number(UInt32(44100))
    number(UInt16(2))
    number(UInt16(16))
    text("data")
    number(UInt32(samples.count * 2))
    for sample in samples { number(sample) }
    return data
  }
}
