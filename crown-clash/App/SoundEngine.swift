import AVFoundation
import Foundation

@MainActor
final class SoundEngine {
  enum Cue: CaseIterable {
    case select, hit, guardHit, superHit, knockout, start, win, charge, jump, swing
  }
  private let engine = AVAudioEngine()
  private let music = AVAudioPlayerNode()
  private var voices: [AVAudioPlayerNode] = []
  private var buffers: [Cue: AVAudioPCMBuffer] = [:]
  private let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
  private var musicBuffer: AVAudioPCMBuffer?
  private var voice = 0
  private var musicStarted = false
  var muted = false {
    didSet { engine.mainMixerNode.outputVolume = muted ? 0 : 0.65 }
  }

  init() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
      try AVAudioSession.sharedInstance().setActive(true)
      engine.attach(music)
      engine.connect(music, to: engine.mainMixerNode, format: format)
      music.volume = 0.36
      for _ in 0..<8 {
        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        voices.append(node)
      }
      for cue in Cue.allCases { buffers[cue] = synth(cue) }
      musicBuffer = synthMusic()
      try engine.start()
    } catch {
      print("Audio unavailable: \(error.localizedDescription)")
    }
  }

  func play(_ cue: Cue) {
    guard engine.isRunning, !voices.isEmpty, let buffer = buffers[cue] else { return }
    let node = voices[voice % voices.count]
    voice += 1
    node.stop()
    node.scheduleBuffer(buffer)
    node.play()
  }

  func startMusic() {
    guard !musicStarted, let musicBuffer, engine.isRunning else { return }
    music.scheduleBuffer(musicBuffer, at: nil, options: .loops)
    music.play()
    musicStarted = true
  }

  func stopMusic() {
    music.stop()
    musicStarted = false
  }

  private func makeBuffer(seconds: Double) -> AVAudioPCMBuffer {
    let buffer = AVAudioPCMBuffer(
      pcmFormat: format, frameCapacity: AVAudioFrameCount(seconds * 22050))!
    buffer.frameLength = buffer.frameCapacity
    return buffer
  }

  private func synth(_ cue: Cue) -> AVAudioPCMBuffer {
    let duration: Double
    let pitch: Double
    switch cue {
    case .select:
      duration = 0.12
      pitch = 720
    case .hit:
      duration = 0.18
      pitch = 130
    case .guardHit:
      duration = 0.16
      pitch = 900
    case .superHit:
      duration = 0.65
      pitch = 65
    case .knockout:
      duration = 0.7
      pitch = 90
    case .start:
      duration = 0.6
      pitch = 440
    case .win:
      duration = 1.5
      pitch = 660
    case .charge:
      duration = 0.55
      pitch = 180
    case .jump:
      duration = 0.16
      pitch = 380
    case .swing:
      duration = 0.09
      pitch = 180
    }
    let buffer = makeBuffer(seconds: duration)
    guard let samples = buffer.floatChannelData?[0] else { return buffer }
    var seed: UInt32 = 12345
    for index in 0..<Int(buffer.frameLength) {
      let time = Double(index) / 22050
      let fade = pow(1 - time / duration, 2)
      seed = seed &* 1_664_525 &+ 1_013_904_223
      let noise = Double(seed % 10000) / 5000 - 1
      let metallic = cue == .guardHit || cue == .select
      let tone = sin(time * pitch * (1 + (cue == .charge ? time * 4 : -time * 0.4)) * .pi * 2)
      let noisy = [.hit, .superHit, .knockout, .swing].contains(cue)
      samples[index] = Float(
        (tone * (metallic ? 0.4 : 0.6) + (noisy ? noise * 0.6 : 0)) * fade * 0.45)
    }
    return buffer
  }

  private func synthMusic() -> AVAudioPCMBuffer {
    let beat = 60.0 / 128
    let buffer = makeBuffer(seconds: beat * 32)
    guard let samples = buffer.floatChannelData?[0] else { return buffer }
    let bass = [55.0, 55, 65.406, 49]
    let melody = [220.0, 261.626, 329.628, 391.995, 329.628, 261.626, 196, 164.814]
    var seed: UInt32 = 7654
    for index in 0..<Int(buffer.frameLength) {
      let time = Double(index) / 22050
      let beatIndex = Int(time / beat)
      let within = time.truncatingRemainder(dividingBy: beat)
      let eighth = time.truncatingRemainder(dividingBy: beat / 2)
      let bassFrequency = bass[(beatIndex / 8) % bass.count]
      let kick = sin(.pi * 2 * (55 * within + 5 * (1 - exp(-within * 40)))) * exp(-within * 22)
      seed = seed &* 1_664_525 &+ 1_013_904_223
      let noise = Double(seed % 10000) / 5000 - 1
      let snare = beatIndex % 2 == 1 ? noise * exp(-within * 24) * 0.38 : 0
      let hat = noise * exp(-eighth * 100) * 0.12
      let bassLine = tanh(sin(time * bassFrequency * .pi * 2) * 2) * exp(-within * 3) * 0.23
      let note = melody[Int(time / (beat / 2)) % melody.count]
      let lead =
        (sin(time * note * .pi * 2) + 0.2 * sin(time * note * .pi * 4)) * exp(-eighth * 9) * 0.12
      samples[index] = Float(kick * 0.42 + snare + hat + bassLine + lead)
    }
    return buffer
  }
}
