import Foundation

enum LaneKind: Equatable {
    case meadow, road, river
}

struct Lane {
    let row: Int
    let kind: LaneKind
    let speed: Double
    let phase: Double
    let coinColumn: Int?

    var spacing: Double {
        kind == .river ? 4.2 : 6.4
    }

    var objectLength: Double {
        kind == .river ? 3.1 : 1.35
    }

    func centers(at time: Double) -> [Double] {
        let offset = (phase + time * speed).truncatingRemainder(dividingBy: spacing)
        return (-3 ... 3).map { Double($0) * spacing + offset }
    }

    func supports(_ x: Double, at time: Double) -> Bool {
        centers(at: time).contains { abs($0 - x) < objectLength / 2 - 0.12 }
    }

    func collides(_ x: Double, at time: Double) -> Bool {
        centers(at: time).contains { abs($0 - x) < objectLength / 2 + 0.19 }
    }
}

struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }

    mutating func value(_ limit: Int) -> Int {
        Int((next() >> 32) % UInt64(limit))
    }
}

struct Course {
    let seed: UInt64

    func lane(_ row: Int) -> Lane {
        guard row > 0 else {
            return Lane(row: row, kind: .meadow, speed: 0, phase: 0, coinColumn: nil)
        }
        var random = SeededRandom(seed: seed &+ UInt64(row) &* 7919)
        let kind: LaneKind
        if row < 9 {
            switch row {
            case 2, 4: kind = .road
            case 6: kind = .river
            default: kind = .meadow
            }
        } else {
            let slot = row % 5
            var section = SeededRandom(seed: seed &+ UInt64(row / 5) &* 104_729)
            let water = section.value(3) == 0
            kind = slot == 0 || slot == 3 || slot == 4 ? .meadow : (water ? .river : .road)
        }
        let direction = random.value(2) == 0 ? -1.0 : 1.0
        let difficulty = min(Double(row) / 100, 0.65)
        let speed = kind == .river ? 0.42 + Double(random.value(15)) / 100 :
            0.75 + Double(random.value(30)) / 100 + difficulty
        let coin: Int? = kind == .meadow && row % 2 == 1 ? (row < 5 ? 0 : random.value(5) - 2) : nil
        return Lane(
            row: row,
            kind: kind,
            speed: direction * speed,
            phase: row == 2 ? 3.2 : Double(random.value(40)) / 10,
            coinColumn: coin
        )
    }
}

enum Direction {
    case forward, backward, left, right
}

enum RunState: Equatable {
    case ready, playing, paused, finished
}

struct Hop {
    let fromX: Double
    let fromRow: Int
    let toX: Double
    let toRow: Int
    var elapsed: Double = 0
    static let duration = 0.19
    var progress: Double {
        min(elapsed / Self.duration, 1)
    }
}

final class GameRules {
    let course: Course
    private(set) var state: RunState = .ready
    private(set) var time: Double = 0
    private(set) var x: Double = 0
    private(set) var row = 0
    private(set) var furthest = 0
    private(set) var coins = 0
    private(set) var collectedRows: Set<Int> = []
    private(set) var hop: Hop?
    private(set) var endReason = ""

    init(seed: UInt64) {
        course = Course(seed: seed)
    }

    var visibleX: Double {
        guard let hop else { return x }
        return hop.fromX + (hop.toX - hop.fromX) * hop.progress
    }

    var visibleRow: Double {
        guard let hop else { return Double(row) }
        return Double(hop.fromRow) + Double(hop.toRow - hop.fromRow) * hop.progress
    }

    var height: Double {
        hop.map { sin($0.progress * .pi) * 0.48 } ?? 0
    }

    func start() {
        state = .playing
    }

    func pause() {
        if state == .playing {
            state = .paused
        }
    }

    func resume() {
        if state == .paused {
            state = .playing
        }
    }

    func endRun() {
        if state == .playing || state == .paused {
            finish("A well-earned rest")
        }
    }

    @discardableResult
    func move(_ direction: Direction) -> Bool {
        guard state == .playing, hop == nil else { return false }
        var nextX = x
        var nextRow = row
        switch direction {
        case .forward: nextRow += 1
        case .backward: nextRow -= 1
        case .left: nextX -= 1
        case .right: nextX += 1
        }
        guard abs(nextX) <= 3.3, nextRow >= max(0, furthest - 5) else { return false }
        hop = Hop(fromX: x, fromRow: row, toX: nextX, toRow: nextRow)
        return true
    }

    func step(_ delta: Double) {
        guard state == .playing else { return }
        let dt = min(max(delta, 0), 1.0 / 30)
        time += dt
        if var current = hop {
            current.elapsed += dt
            hop = current
            if current.progress >= 1 {
                x = current.toX
                row = current.toRow
                hop = nil
            }
        } else if course.lane(row).kind == .river {
            x += course.lane(row).speed * dt
        }
        let collisionRow = Int(visibleRow.rounded())
        let lane = course.lane(collisionRow)
        if lane.kind == .road, abs(visibleRow - Double(collisionRow)) < 0.38,
           lane.collides(visibleX, at: time)
        {
            finish("A little traffic trouble")
            return
        }
        if hop == nil {
            if abs(x) > 3.65 {
                finish("Swept around the bend")
            } else if lane.kind == .river, !lane.supports(x, at: time) {
                finish("That was a splash!")
            } else {
                furthest = max(furthest, row)
                if let column = lane.coinColumn, abs(x - Double(column)) < 0.48,
                   !collectedRows.contains(row)
                {
                    coins += 1
                    collectedRows.insert(row)
                }
            }
        }
    }

    private func finish(_ reason: String) {
        state = .finished
        endReason = reason
    }
}

enum Plumage: Int, CaseIterable, Identifiable {
    case sunshine, peppermint, blossom, midnight
    var id: Int {
        rawValue
    }

    var name: String {
        switch self {
        case .sunshine: "Sunshine"
        case .peppermint: "Peppermint"
        case .blossom: "Blossom"
        case .midnight: "Midnight"
        }
    }

    var price: Int {
        [0, 4, 12, 24][rawValue]
    }

    var milestone: Int {
        [0, 8, 18, 35][rawValue]
    }

    func unlocked(coins: Int, best: Int) -> Bool {
        coins >= price || best >= milestone
    }
}
