import AVFoundation
import Foundation

@MainActor
final class NightAudio {
  private let engine = AVAudioEngine()
  private let music = AVAudioPlayerNode()
  private let effects = AVAudioPlayerNode()
  private var started = false
  var muted = false {
    didSet { engine.mainMixerNode.outputVolume = muted ? 0 : 0.65 }
  }

  func start() {
    guard !started else { return }
    do {
      try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
      let format = AVAudioFormat(standardFormatWithSampleRate: 22_050, channels: 1)!
      engine.attach(music)
      engine.attach(effects)
      engine.connect(music, to: engine.mainMixerNode, format: format)
      engine.connect(effects, to: engine.mainMixerNode, format: format)
      try engine.start()
      let buffer = makeMusic(format)
      music.scheduleBuffer(buffer, at: nil, options: .loops)
      music.volume = 0.36
      effects.volume = 0.7
      music.play()
      effects.play()
      started = true
    } catch {
      print("Audio unavailable: \(error.localizedDescription)")
    }
  }

  private func makeMusic(_ format: AVAudioFormat) -> AVAudioPCMBuffer {
    let rate = format.sampleRate
    let seconds = 16.0
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(rate * seconds))!
    buffer.frameLength = buffer.frameCapacity
    guard let samples = buffer.floatChannelData?[0] else { return buffer }
    let notes = [220.0, 261.63, 329.63, 392, 293.66, 261.63, 196, 246.94]
    for index in 0..<Int(buffer.frameLength) {
      let t = Double(index) / rate
      let step = Int(t * 4)
      let phase = (t * 4).truncatingRemainder(dividingBy: 1)
      let frequency = notes[(step / 2) % notes.count]
      let pluck = sin(2 * .pi * frequency * t) * exp(-phase * 6) * 0.19
      let bass = sin(2 * .pi * frequency * 0.25 * t) * 0.17
      let beat = (t * 2).truncatingRemainder(dividingBy: 1)
      let kick = sin(2 * .pi * (48 * beat + 15 * (1 - exp(-beat * 20)))) * exp(-beat * 14) * 0.35
      let hat = sin(t * 17_111) * sin(t * 13_713) * exp(-phase * 28) * 0.12
      let pad = sin(2 * .pi * frequency * 0.5 * t) * sin(.pi * t / 16) * 0.06
      samples[index] = Float(pluck + bass + kick + hat + pad)
    }
    return buffer
  }

  func play(_ type: String) {
    guard started, !muted,
      let format = AVAudioFormat(standardFormatWithSampleRate: 22_050, channels: 1)
    else { return }
    let length = ["ascend", "shift", "result"].contains(type) ? 0.5 : 0.12
    let buffer = AVAudioPCMBuffer(
      pcmFormat: format, frameCapacity: UInt32(format.sampleRate * length))!
    buffer.frameLength = buffer.frameCapacity
    guard let samples = buffer.floatChannelData?[0] else { return }
    for i in 0..<Int(buffer.frameLength) {
      let t = Double(i) / format.sampleRate
      let high = ["shield", "shift", "ascend"].contains(type)
      let frequency = high ? 780.0 : 110.0
      let tone = sin(2 * .pi * frequency * t * (1 + t * 3))
      let noise = sin(t * 9_937) * cos(t * 7_129)
      samples[i] = Float((tone * 0.32 + noise * (high ? 0.08 : 0.4)) * exp(-t * 12))
    }
    effects.scheduleBuffer(buffer)
  }
}
