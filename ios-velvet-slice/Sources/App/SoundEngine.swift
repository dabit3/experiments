import AVFoundation
import UIKit

@MainActor
final class SoundEngine {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var ready = false
    var enabled = true

    func play(combo: Bool = false, bomb: Bool = false) {
        guard enabled else { return }
        if !ready {
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1))
                try engine.start()
                player.play()
                ready = true
            } catch { return }
        }
        if !engine.isRunning {
            do { try engine.start(); player.play() } catch { return }
        }
        let duration = bomb ? 0.26 : (combo ? 0.2 : 0.095)
        let frames = AVAudioFrameCount(44100 * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let samples = buffer.floatChannelData else { return }
        buffer.frameLength = frames
        for i in 0 ..< Int(frames) {
            let time = Double(i) / 44100
            let envelope = sin(.pi * Double(i) / Double(frames)) * exp(-time * 13)
            let frequency: Double = bomb ? 95 : (combo ? 880 : 520)
            let modulation = bomb ? sin(time * 190) * 4 : time * time * 1400
            let phase = 2 * Double.pi * frequency * time + modulation
            samples[0][i] = Float(sin(phase) * envelope * 0.16)
        }
        player.scheduleBuffer(buffer)
        if bomb {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } else {
            UIImpactFeedbackGenerator(style: combo ? .medium : .light).impactOccurred(intensity: 0.6)
        }
    }
}
