import AVFoundation
import AfterhoursCore
import Foundation

@MainActor
final class ArcadeAudio {
  private var players: [AVAudioPlayer] = []

  init() {
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
  }

  func play(_ event: GameEvent) {
    let notes: [Double]
    let duration: Double
    switch event {
    case .pellet:
      notes = [820]
      duration = 0.045
    case .power:
      notes = [392, 523.25, 659.25, 783.99]
      duration = 0.065
    case .rival:
      notes = [659.25, 987.77]
      duration = 0.075
    case .hit:
      notes = [311.13, 233.08, 155.56]
      duration = 0.11
    case .clear:
      notes = [523.25, 659.25, 783.99, 1046.5]
      duration = 0.13
    }
    let data = wave(notes: notes, duration: duration)
    players.removeAll { !$0.isPlaying }
    guard let player = try? AVAudioPlayer(data: data) else { return }
    player.volume = 0.24
    players.append(player)
    player.play()
  }

  private func wave(notes: [Double], duration: Double) -> Data {
    let rate = 22_050
    let samplesPerNote = Int(Double(rate) * duration)
    var samples = Data()
    for note in notes {
      for index in 0..<samplesPerNote {
        let t = Double(index) / Double(rate)
        let progress = Double(index) / Double(samplesPerNote)
        let envelope = min(1, progress * 20) * pow(1 - progress, 1.6)
        let signal = sin(2 * .pi * note * t) + 0.15 * sin(4 * .pi * note * t)
        var value = Int16(signal * envelope * 12_000).littleEndian
        withUnsafeBytes(of: &value) { samples.append(contentsOf: $0) }
      }
    }
    var data = Data("RIFF".utf8)
    append(UInt32(36 + samples.count), to: &data)
    data.append(Data("WAVEfmt ".utf8))
    append(UInt32(16), to: &data)
    append(UInt16(1), to: &data)
    append(UInt16(1), to: &data)
    append(UInt32(rate), to: &data)
    append(UInt32(rate * 2), to: &data)
    append(UInt16(2), to: &data)
    append(UInt16(16), to: &data)
    data.append(Data("data".utf8))
    append(UInt32(samples.count), to: &data)
    data.append(samples)
    return data
  }

  private func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
    var value = value.littleEndian
    withUnsafeBytes(of: &value) { data.append(contentsOf: $0) }
  }
}
