import Foundation

enum PlayMode: String, CaseIterable {
    case arcade, practice
}

struct RoundRules {
    let mode: PlayMode
    private(set) var score = 0
    private(set) var sliced = 0
    private(set) var missed = 0
    private(set) var bombs = 0
    private(set) var bestCombo = 0
    private(set) var remaining: Double = 60
    private(set) var elapsed: Double = 0
    private(set) var finished = false

    mutating func advance(_ seconds: Double) {
        guard !finished, seconds > 0 else { return }
        elapsed += seconds
        if mode == .arcade {
            remaining = max(0, remaining - seconds)
            finished = remaining <= 0
        }
    }

    mutating func slice() {
        guard !finished else { return }
        sliced += 1
        score += 10
    }

    @discardableResult
    mutating func combo(_ count: Int) -> Int {
        guard !finished, count >= 3 else { return 0 }
        bestCombo = max(bestCombo, count)
        let bonus = count * 5
        score += bonus
        return bonus
    }

    mutating func miss() {
        guard !finished else { return }
        missed += 1
        if mode == .arcade {
            score = max(0, score - 2)
        }
    }

    mutating func hitBomb() {
        guard !finished, mode == .arcade else { return }
        bombs += 1
        score = max(0, score - 25)
        finished = bombs >= 3
    }

    mutating func finish() {
        finished = true
    }
}

struct Point2D {
    var x: Double
    var y: Double
}

enum SliceGeometry {
    static func intersects(from a: Point2D, to b: Point2D, center: Point2D, radius: Double) -> Bool {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return false }
        let t = max(0, min(1, ((center.x - a.x) * dx + (center.y - a.y) * dy) / lengthSquared))
        let distanceX = center.x - (a.x + t * dx)
        let distanceY = center.y - (a.y + t * dy)
        return distanceX * distanceX + distanceY * distanceY <= radius * radius
    }
}

struct WavePlan {
    let fruitCount: Int
    let bombLane: Int?
    let interval: Double

    init(wave: Int, mode: PlayMode) {
        fruitCount = mode == .practice ? 3 : min(5, 3 + wave / 10)
        bombLane = mode == .arcade && wave >= 3 && wave % 3 == 0 ? (wave / 3) % 2 : nil
        interval = mode == .practice ? 2.8 : max(1.8, 2.8 - Double(wave) * 0.025)
    }
}
