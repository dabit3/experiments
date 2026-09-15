import AVFoundation

@MainActor
final class FestivalAudio {
    private var song: AVAudioPlayer?
    private var samples: [String: [AVAudioPlayer]] = [:]
    private var cursor = 0
    private var fanfare: AVAudioPlayer?

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
            try AVAudioSession.sharedInstance().setActive(true)
            for key in ["don", "ka"] {
                samples[key] = (0..<8).compactMap { _ in Self.player(key) }
            }
            fanfare = Self.player("fanfare")
        } catch {
            print("Audio session unavailable: \(error.localizedDescription)")
        }
    }

    private static func player(_ resource: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        return player
    }

    func hit(_ kind: String) {
        guard let pool = samples[kind], !pool.isEmpty else { return }
        cursor += 1
        let player = pool[cursor % pool.count]
        player.currentTime = 0
        player.play()
    }

    func start(_ resource: String, secondsUntilStart: Double) {
        song?.stop()
        song = Self.player(resource)
        guard let song else { return }
        song.volume = 0.78
        if secondsUntilStart > 0 {
            song.play(atTime: song.deviceCurrentTime + secondsUntilStart)
        } else {
            song.currentTime = max(0, -secondsUntilStart)
            song.play()
        }
    }

    func preview(_ resource: String) {
        start(resource, secondsUntilStart: -2)
    }

    func stop() { song?.stop() }
    func finish() {
        stop()
        fanfare?.currentTime = 0
        fanfare?.play()
    }
}
