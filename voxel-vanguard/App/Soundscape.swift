import AVFoundation

final class Soundscape {
  private let engine = AVAudioEngine()
  private let music = AVAudioPlayerNode()
  private let effects = AVAudioPlayerNode()
  private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
  private var started = false

  func start() {
    guard !started else { return }
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback, mode: .default, options: [.mixWithOthers])
      try AVAudioSession.sharedInstance().setActive(true)
      engine.attach(music)
      engine.attach(effects)
      engine.connect(music, to: engine.mainMixerNode, format: format)
      engine.connect(effects, to: engine.mainMixerNode, format: format)
      try engine.start()
      let notes = [
        146.83, 174.61, 220.0, 293.66, 261.63, 220.0, 174.61, 130.81,
        146.83, 220.0, 293.66, 349.23, 329.63, 261.63, 220.0, 174.61,
      ]
      let duration = 12.0
      let buffer = AVAudioPCMBuffer(
        pcmFormat: format, frameCapacity: AVAudioFrameCount(duration * 44100))!
      buffer.frameLength = buffer.frameCapacity
      let samples = buffer.floatChannelData![0]
      for i in 0..<Int(buffer.frameLength) {
        let t = Double(i) / 44100
        let beat = Int(t / 0.75) % notes.count
        let local = t.truncatingRemainder(dividingBy: 0.75)
        let envelope = exp(-local * 5) * min(1, local * 90)
        let bell = sin(2 * .pi * notes[beat] * t) + 0.3 * sin(2 * .pi * notes[beat] * 2 * t)
        let drone = sin(2 * .pi * 73.416 * t) * 0.12
        samples[i] = Float(bell * envelope * 0.055 + drone * 0.045)
      }
      music.scheduleBuffer(buffer, at: nil, options: .loops)
      music.play()
      effects.play()
      started = true
    } catch { started = false }
  }

  func play(_ kind: String) {
    guard started else { return }
    let pitch: Double
    switch kind {
    case "slash": pitch = 130
    case "bow": pitch = 430
    case "hit": pitch = 85
    case "heal", "gem", "equip": pitch = 780
    case "artifact", "slam": pitch = 55
    case "clear", "victory": pitch = 587
    case "hurt", "down": pitch = 95
    default: return
    }
    let duration = kind == "victory" ? 1.5 : 0.12
    let buffer = AVAudioPCMBuffer(
      pcmFormat: format, frameCapacity: AVAudioFrameCount(44100 * duration))!
    buffer.frameLength = buffer.frameCapacity
    let samples = buffer.floatChannelData![0]
    for i in 0..<Int(buffer.frameLength) {
      let t = Double(i) / 44100
      let envelope = exp(-t / duration * 5) * min(1, t * 800)
      let wave = sin(2 * .pi * (pitch * t + pitch * t * t))
      samples[i] = Float(wave * envelope * 0.16)
    }
    effects.scheduleBuffer(buffer, completionHandler: nil)
  }
}
