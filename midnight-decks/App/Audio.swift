import AVFoundation

@MainActor
final class DeckAudio {
  private var music: AVAudioPlayer?
  private var voices: [AVAudioPlayer] = []
  var scheduledRound = 0
  var enabled = true

  init() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
      if let url = Bundle.main.url(forResource: "afterimage", withExtension: "wav") {
        music = try AVAudioPlayer(contentsOf: url)
        music?.prepareToPlay()
      }
      for lane in 0...7 {
        let player = try AVAudioPlayer(data: Self.tone(lane: lane))
        player.prepareToPlay()
        voices.append(player)
      }
    } catch {
      print("AUDIO ERROR: \(error.localizedDescription)")
    }
  }

  var available: Bool { music != nil }
  var musicPosition: Double { music?.currentTime ?? 0 }

  func start(round: Int, songTime: Double) {
    guard scheduledRound != round, let music else { return }
    scheduledRound = round
    music.stop()
    music.currentTime = max(0, songTime / 1000)
    music.volume = enabled ? 0.8 : 0
    music.play(atTime: music.deviceCurrentTime + max(0, -songTime / 1000))
  }

  func stop() {
    music?.stop()
    scheduledRound = 0
  }

  func key(_ lane: Int) {
    guard enabled, lane < voices.count else { return }
    voices[lane].currentTime = 0
    voices[lane].volume = 0.18
    voices[lane].play()
  }

  private static func tone(lane: Int) -> Data {
    let rate = 22050
    let count = rate / 12
    var data = Data()
    func text(_ value: String) { data.append(contentsOf: value.utf8) }
    func u16(_ value: UInt16) {
      var little = value.littleEndian
      withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    func u32(_ value: UInt32) {
      var little = value.littleEndian
      withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    text("RIFF")
    u32(UInt32(36 + count * 2))
    text("WAVEfmt ")
    u32(16)
    u16(1)
    u16(1)
    u32(UInt32(rate))
    u32(UInt32(rate * 2))
    u16(2)
    u16(16)
    text("data")
    u32(UInt32(count * 2))
    for index in 0..<count {
      let t = Double(index) / Double(rate)
      let frequency = lane == 0 ? 140 + 2200 * t : 220 * pow(2, Double(lane) / 12)
      let wave = sin(2 * Double.pi * frequency * t) * exp(-t * 45)
      let sample = Int16(wave * 20000)
      u16(UInt16(bitPattern: sample))
    }
    return data
  }
}
