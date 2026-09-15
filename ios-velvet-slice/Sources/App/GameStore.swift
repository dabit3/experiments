import Combine
import SwiftUI

enum GameScreen { case home, playing, results }

@MainActor
final class GameStore: ObservableObject {
    @Published var screen: GameScreen = .home
    @Published var mode: PlayMode = .arcade
    @Published var round = RoundRules(mode: .arcade)
    @Published var paused = false
    @Published var countdown = 3
    @Published var best = 0
    @Published var practiceBest = 0
    @Published var newBest = false
    @Published var soundOn = true
    @Published var showRules = false
    let sound = SoundEngine()
    lazy var scene = SliceScene(store: self)
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        best = defaults.integer(forKey: "arcadeBest")
        practiceBest = defaults.integer(forKey: "practiceBest")
        soundOn = defaults.object(forKey: "soundOn") as? Bool ?? true
        sound.enabled = soundOn
    }

    func begin(_ mode: PlayMode) {
        self.mode = mode
        round = RoundRules(mode: mode)
        countdown = 3
        paused = false
        newBest = false
        scene.resetRound()
        screen = .playing
    }

    func toggleSound() {
        soundOn.toggle()
        sound.enabled = soundOn
        defaults.set(soundOn, forKey: "soundOn")
    }

    func pause() {
        guard screen == .playing else { return }
        paused = true
        scene.cancelSwipe()
    }

    func finish() {
        guard screen == .playing else { return }
        round.finish()
        paused = false
        let old = mode == .arcade ? best : practiceBest
        newBest = round.score > old
        if mode == .arcade {
            best = max(best, round.score)
            defaults.set(best, forKey: "arcadeBest")
        } else {
            practiceBest = max(practiceBest, round.score)
            defaults.set(practiceBest, forKey: "practiceBest")
        }
        screen = .results
    }
}
