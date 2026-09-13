import AVFoundation
import Foundation

@MainActor
final class ArenaAudio {
  private let engine = AVAudioEngine()
  private let hit = AVAudioPlayerNode()
  private let music = AVAudioPlayerNode()
  private var enabled = false
  private var recording: AVAudioFile?
  private var renderBuffer: AVAudioPCMBuffer?
  private var renderTimer: Timer?
  private var renderStartedAt = 0.0

  func start() {
    guard !enabled else { return }
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback, mode: .default, options: [.mixWithOthers])
      try AVAudioSession.sharedInstance().setActive(true)
      let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
      engine.attach(hit)
      engine.attach(music)
      engine.connect(hit, to: engine.mainMixerNode, format: format)
      engine.connect(music, to: engine.mainMixerNode, format: format)
      if ProcessInfo.processInfo.arguments.contains("--capture-audio") {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
          .appendingPathComponent("arena-audio.caf")
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
        recording = try AVAudioFile(forWriting: url, settings: format.settings)
        renderBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096)
      }
      try engine.start()
      enabled = true
      if let buffer = buffer(seconds: 4, effect: "music") {
        music.scheduleBuffer(buffer, at: nil, options: .loops)
        music.play()
      }
      if recording != nil {
        renderStartedAt = Date.timeIntervalSinceReferenceDate
        let origin = renderStartedAt + Date.timeIntervalBetween1970AndReferenceDate
        let clockURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
          .appendingPathComponent("arena-audio-origin.json")
        try? JSONEncoder().encode(origin).write(to: clockURL)
        renderTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
          Task { @MainActor in self?.renderAudio() }
        }
      }
    } catch {
      print("Audio unavailable: \(error.localizedDescription)")
    }
  }

  func sound(_ effect: String) {
    guard enabled, let buffer = buffer(seconds: effect == "ko" ? 0.8 : 0.19, effect: effect) else {
      return
    }
    hit.scheduleBuffer(buffer)
    hit.play()
  }

  func mute(_ muted: Bool) {
    engine.mainMixerNode.outputVolume = muted ? 0 : 1
  }

  private func renderAudio() {
    guard let recording, let renderBuffer else { return }
    let target = AVAudioFramePosition(
      (Date.timeIntervalSinceReferenceDate - renderStartedAt) * 44100)
    while target > engine.manualRenderingSampleTime {
      let count = AVAudioFrameCount(min(4096, target - engine.manualRenderingSampleTime))
      guard (try? engine.renderOffline(count, to: renderBuffer)) == .success else { return }
      try? recording.write(from: renderBuffer)
    }
  }

  private func buffer(seconds: Double, effect: String) -> AVAudioPCMBuffer? {
    guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(seconds * 44100)),
      let channel = buffer.floatChannelData?[0]
    else { return nil }
    buffer.frameLength = buffer.frameCapacity
    var seed: UInt32 = 7
    for index in 0..<Int(buffer.frameLength) {
      let time = Double(index) / 44100
      let decay = exp(-time * (effect == "ko" ? 4 : 22))
      seed = 1_664_525 &* seed &+ 1_013_904_223
      let noise = Double(seed % 65536) / 32768 - 1
      if effect == "music" {
        let beat = time.truncatingRemainder(dividingBy: 0.5)
        let frequency = [55.0, 55, 65.41, 49][min(3, Int(time))]
        let bass = sin(time * frequency * 2 * .pi) * exp(-beat * 7)
        let pulse = sin(2 * .pi * (70 * beat + 5 * (1 - exp(-beat * 30)))) * exp(-beat * 28)
        channel[index] = Float(bass * 0.065 + pulse * 0.11 + noise * exp(-beat * 90) * 0.035)
      } else {
        let frequency = effect == "block" ? 840.0 : effect == "tag" ? 440 : 90
        channel[index] = Float((sin(time * frequency * 2 * .pi) * 0.6 + noise * 0.5) * decay * 0.4)
      }
    }
    return buffer
  }
}
