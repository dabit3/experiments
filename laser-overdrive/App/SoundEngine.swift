import AVFoundation
import Foundation

@MainActor
final class SoundEngine {
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private let feedback = AVAudioPlayerNode()
  private let filter = AVAudioUnitEQ(numberOfBands: 1)
  private let drive = AVAudioUnitDistortion()
  private var file: AVAudioFile?
  private var baseOffset = 0.0
  private(set) var running = false
  private(set) var error: String?

  init() {
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback, mode: .default, options: [.mixWithOthers])
      try AVAudioSession.sharedInstance().setActive(true)
      guard let url = Bundle.main.url(forResource: "afterburn", withExtension: "m4a") else {
        return
      }
      let audio = try AVAudioFile(forReading: url)
      file = audio
      engine.attach(player)
      engine.attach(feedback)
      engine.attach(filter)
      engine.attach(drive)
      engine.connect(player, to: filter, format: audio.processingFormat)
      engine.connect(filter, to: drive, format: audio.processingFormat)
      engine.connect(drive, to: engine.mainMixerNode, format: audio.processingFormat)
      engine.connect(feedback, to: engine.mainMixerNode, format: audio.processingFormat)
      filter.bands[0].filterType = .lowPass
      filter.bands[0].frequency = 18000
      filter.bands[0].bypass = false
      drive.loadFactoryPreset(.multiBrokenSpeaker)
      drive.wetDryMix = 0
      player.volume = 0.8
      engine.prepare()
      try engine.start()
    } catch {
      self.error = error.localizedDescription
    }
  }

  func start(in delay: Double, offset: Double = 0) {
    guard let file else { return }
    do {
      if !engine.isRunning { try engine.start() }
      player.stop()
      baseOffset = max(0, offset)
      let frame = AVAudioFramePosition(baseOffset * file.processingFormat.sampleRate)
      guard frame < file.length else { return }
      player.scheduleSegment(
        file, startingFrame: frame,
        frameCount: AVAudioFrameCount(file.length - frame), at: nil)
      if delay > 0 {
        let host = mach_absolute_time() + AVAudioTime.hostTime(forSeconds: delay)
        player.play(at: AVAudioTime(hostTime: host))
      } else {
        player.play()
      }
      running = true
    } catch {
      self.error = error.localizedDescription
    }
  }

  var time: Double? {
    guard running, let render = player.lastRenderTime,
      let playback = player.playerTime(forNodeTime: render)
    else { return nil }
    return baseOffset + Double(playback.sampleTime) / playback.sampleRate
  }

  func effects(fxLeft: Bool, fxRight: Bool, laser: Double?) {
    drive.wetDryMix = fxLeft ? 24 : 0
    filter.bands[0].frequency = fxRight ? 1800 : Float(laser.map { 6000 + $0 * 12000 } ?? 18000)
  }

  func hit(lane: Int) {
    guard let format = file?.processingFormat,
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1600),
      let channels = buffer.floatChannelData
    else { return }
    buffer.frameLength = 1600
    for channel in 0..<Int(format.channelCount) {
      for frame in 0..<1600 {
        let time = Double(frame) / format.sampleRate
        channels[channel][frame] = Float(
          sin(time * 2 * .pi * Double(880 + lane * 110)) * exp(-time * 150) * 0.06)
      }
    }
    feedback.scheduleBuffer(buffer)
    if !feedback.isPlaying { feedback.play() }
  }

  func stop() {
    player.stop()
    running = false
  }
}
