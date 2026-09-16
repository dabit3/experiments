import AVFoundation
import Foundation

enum RiverCue: CaseIterable {
  case flap, point, splash
}

@MainActor
final class RiverAudio {
  private var players: [RiverCue: AVAudioPlayer] = [:]

  init() {
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
    for cue in RiverCue.allCases {
      if let player = try? AVAudioPlayer(data: Self.wave(cue)) {
        player.volume = 0.22
        player.prepareToPlay()
        players[cue] = player
      }
    }
  }

  func play(_ cue: RiverCue) {
    guard let player = players[cue] else { return }
    player.currentTime = 0
    player.play()
  }

  static func wave(_ cue: RiverCue) -> Data {
    let rate = 22_050
    let duration = cue == .splash ? 0.28 : 0.12
    let count = Int(Double(rate) * duration)
    var data = Data()
    func text(_ value: String) { data.append(contentsOf: value.utf8) }
    func number(_ value: UInt32, bytes: Int) {
      for shift in 0..<bytes {
        data.append(UInt8(truncatingIfNeeded: value >> (shift * 8)))
      }
    }
    text("RIFF")
    number(UInt32(36 + count * 2), bytes: 4)
    text("WAVEfmt ")
    number(16, bytes: 4)
    number(1, bytes: 2)
    number(1, bytes: 2)
    number(UInt32(rate), bytes: 4)
    number(UInt32(rate * 2), bytes: 4)
    number(2, bytes: 2)
    number(16, bytes: 2)
    text("data")
    number(UInt32(count * 2), bytes: 4)
    for index in 0..<count {
      let time = Double(index) / Double(rate)
      let progress = Double(index) / Double(count)
      let frequency: Double
      switch cue {
      case .flap: frequency = 480 + 480 * progress
      case .point: frequency = progress < 0.5 ? 880 : 1_175
      case .splash: frequency = 170 - 100 * progress
      }
      let envelope = sin(.pi * progress) * (1 - progress)
      let sample = Int16(sin(2 * .pi * frequency * time) * envelope * 20_000)
      number(UInt32(UInt16(bitPattern: sample)), bytes: 2)
    }
    return data
  }
}
