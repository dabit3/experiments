import AVFoundation
import Combine
import QuartzCore
import UIKit

@MainActor
final class GameStore: NSObject, ObservableObject {
    @Published private(set) var state: RunState = .ready
    @Published private(set) var score = 0
    @Published private(set) var runCoins = 0
    @Published private(set) var best: Int
    @Published private(set) var bank: Int
    @Published var selected: Plumage {
        didSet { defaults.set(selected.rawValue, forKey: "plumage") }
    }

    @Published var sound: Bool {
        didSet { defaults.set(sound, forKey: "sound") }
    }

    @Published var showWardrobe = false
    @Published var showGuide = false
    @Published private(set) var newBest = false
    @Published private(set) var unlockedNames: [String] = []
    let world = ToyWorld()
    private(set) var game: GameRules
    private let defaults: UserDefaults
    private var displayLink: CADisplayLink?
    private var lastTick: CFTimeInterval = 0
    private let audio = ToyAudio()
    var reducedMotion = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        best = defaults.integer(forKey: "best")
        bank = defaults.integer(forKey: "coins")
        selected = Plumage(rawValue: defaults.integer(forKey: "plumage")) ?? .sunshine
        sound = defaults.object(forKey: "sound") as? Bool ?? true
        game = GameRules(seed: UInt64.random(in: 1 ... UInt64.max))
        super.init()
        world.update(game, plumage: selected, delta: 1, reducedMotion: reducedMotion)
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    var reason: String {
        game.endReason
    }

    func start() {
        game = GameRules(seed: UInt64.random(in: 1 ... UInt64.max))
        score = 0
        runCoins = 0
        newBest = false
        unlockedNames = []
        game.start()
        state = game.state
        if sound {
            audio.play(.start)
        }
    }

    func home() {
        game = GameRules(seed: UInt64.random(in: 1 ... UInt64.max))
        state = .ready
        score = 0
        runCoins = 0
    }

    func move(_ direction: Direction) {
        if game.move(direction) {
            world.face(direction)
            if sound {
                audio.play(.hop)
            }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.45)
        }
    }

    func pause() {
        game.pause()
        state = game.state
    }

    func resume() {
        game.resume()
        state = game.state
        lastTick = 0
    }

    @objc private func tick(_ link: CADisplayLink) {
        let dt = lastTick == 0 ? 1.0 / 60 : min(link.timestamp - lastTick, 1.0 / 30)
        lastTick = link.timestamp
        game.step(dt)
        if score != game.furthest {
            score = game.furthest
        }
        if runCoins != game.coins {
            let added = game.coins - runCoins
            runCoins = game.coins
            bank += added
            defaults.set(bank, forKey: "coins")
            if sound {
                audio.play(.coin)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        if state != game.state {
            if game.state == .finished {
                newBest = score > best
                unlockedNames = Plumage.allCases.filter {
                    $0.unlocked(coins: bank, best: score) && !$0.unlocked(coins: bank - runCoins, best: best)
                }.map(\.name)
                best = max(best, score)
                defaults.set(best, forKey: "best")
                if sound {
                    audio.play(.end)
                }
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
            state = game.state
        }
        world.update(game, plumage: selected, delta: dt, reducedMotion: reducedMotion)
    }
}

@MainActor
private final class ToyAudio {
    enum Cue { case hop, coin, start, end }
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
    private var prepared = false

    func play(_ cue: Cue) {
        guard let format else { return }
        if !prepared {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            prepared = true
        }
        if !engine.isRunning {
            try? engine.start()
            player.play()
        }
        let duration = cue == .hop ? 0.06 : 0.22
        let frames = AVAudioFrameCount(44100 * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let samples = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = frames
        let base: Double = switch cue {
        case .hop: 520
        case .coin: 1050
        case .start: 660
        case .end: 240
        }
        for index in 0 ..< Int(frames) {
            let t = Double(index) / 44100
            let envelope = sin(.pi * t / duration) * exp(-t * 12)
            let frequency = base * (cue == .end ? 1 - t * 2 : 1 + t)
            samples[index] = Float(sin(2 * .pi * frequency * t) * envelope * 0.16)
        }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
    }
}
