import AVFoundation
import Foundation

@MainActor
final class AudioEngine {
    private var player: AVAudioPlayer?
    private let engine = AVAudioEngine()
    private let effect = AVAudioPlayerNode()
    private var effectBuffer: AVAudioPCMBuffer?
    private(set) var scheduledAt = 0.0
    private(set) var preparationTime = 0.0
    var volume: Float = 0.75 {
        didSet { player?.volume = volume }
    }

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            engine.attach(effect)
            guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
                  let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 3000),
                  let data = buffer.floatChannelData?[0] else { return }
            buffer.frameLength = 3000
            for i in 0..<3000 {
                let time = Double(i) / 44100
                data[i] = Float(sin(time * 2 * .pi * 1480) * exp(-time * 70) * 0.15)
            }
            effectBuffer = buffer
            engine.connect(effect, to: engine.mainMixerNode, format: format)
            try engine.start()
            effect.play()
        } catch {
            print("Audio setup: \(error.localizedDescription)")
        }
    }

    func play(song: String, startAt: Double, now: Double, offset: Double = 0) -> Bool {
        let requestedAt = ProcessInfo.processInfo.systemUptime
        stop()
        guard let url = Bundle.main.url(forResource: song, withExtension: "wav") else { return false }
        do {
            let next = try AVAudioPlayer(contentsOf: url)
            next.volume = volume
            next.prepareToPlay()
            preparationTime = ProcessInfo.processInfo.systemUptime - requestedAt
            let delay = (startAt - now) / 1000 + offset - preparationTime
            if delay < 0 {
                next.currentTime = min(-delay, max(0, next.duration - 0.01))
            }
            scheduledAt = next.deviceCurrentTime + max(0, delay)
            player = next
            return next.play(atTime: scheduledAt)
        } catch { return false }
    }

    func sparkle() {
        guard let effectBuffer else { return }
        effect.scheduleBuffer(effectBuffer)
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
