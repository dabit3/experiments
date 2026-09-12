import Foundation

struct Vector: Equatable, Codable {
    var x: Double
    var y: Double
    static let zero = Vector(x: 0, y: 0)
    var length: Double { hypot(x, y) }
    var unit: Vector { length > 0.0001 ? self / length : .zero }
    var angle: Double { atan2(y, x) }
    func dot(_ other: Vector) -> Double { x * other.x + y * other.y }
    static func + (a: Vector, b: Vector) -> Vector { Vector(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: Vector, b: Vector) -> Vector { Vector(x: a.x - b.x, y: a.y - b.y) }
    static func * (a: Vector, b: Double) -> Vector { Vector(x: a.x * b, y: a.y * b) }
    static func / (a: Vector, b: Double) -> Vector { Vector(x: a.x / b, y: a.y / b) }
    static prefix func - (a: Vector) -> Vector { a * -1 }
    static func direction(_ angle: Double) -> Vector { Vector(x: cos(angle), y: sin(angle)) }
}

struct Ball: Identifiable, Codable {
    let id: Int
    var position: Vector
    var velocity = Vector.zero
    var pocketed = false
    var travel = 0.0
}

struct ShotEvents {
    var firstContact: Int?
    var pots: [(ball: Int, pocket: Int)] = []
    var railBalls: Set<Int> = []
    var railAfterContact = false
    var scratch: Bool { pots.contains { $0.ball == 0 } }
}

struct AimTrace {
    var end: Vector
    var ball: Int?
    var outgoing: Vector?
    var bank: Vector?
}

struct Table {
    static let width = 600.0
    static let height = 300.0
    static let radius = 8.5
    static let pockets: [Vector] = [
        Vector(x: 0, y: 0), Vector(x: 300, y: -2), Vector(x: 600, y: 0),
        Vector(x: 0, y: 300), Vector(x: 300, y: 302), Vector(x: 600, y: 300),
    ]
    var balls: [Ball] = []
    var events = ShotEvents()
    var spin = 0.0
    var collisionEnergy = 0.0
    var moving: Bool { balls.contains { !$0.pocketed && $0.velocity.length > 0 } }
    var cue: Ball { balls[0] }

    init() { rack() }

    mutating func rack() {
        balls = [Ball(id: 0, position: Vector(x: 150, y: 150))]
        let order = [1, 10, 2, 3, 8, 11, 12, 4, 13, 5, 6, 14, 7, 9, 15]
        var index = 0
        for row in 0..<5 {
            for column in 0...row {
                balls.append(
                    Ball(
                        id: order[index],
                        position: Vector(
                            x: 427 + Double(row) * 14.83,
                            y: 150 + (Double(column) - Double(row) / 2) * 17.15)))
                index += 1
            }
        }
        events = ShotEvents()
    }

    mutating func shoot(angle: Double, power: Double, spin: Double) {
        guard !moving && !cue.pocketed else { return }
        events = ShotEvents()
        self.spin = spin
        balls[0].velocity = Vector.direction(angle) * (150 + min(1, max(0, power)) * 880)
    }

    mutating func step(_ dt: Double) {
        collisionEnergy = 0
        for index in balls.indices where !balls[index].pocketed {
            let speed = balls[index].velocity.length
            balls[index].position = balls[index].position + balls[index].velocity * dt
            balls[index].travel += speed * dt
            if let pocket = Self.pockets.firstIndex(where: {
                (balls[index].position - $0).length < 17.5
            }) {
                balls[index].pocketed = true
                balls[index].velocity = .zero
                events.pots.append((balls[index].id, pocket))
                continue
            }
            let point = balls[index].position
            var rail = false
            let sideMouth = abs(point.x - 300) < 19
            let cornerMouth = point.x < 19 || point.x > 581
            if point.x < Self.radius && point.y > 18 && point.y < 282 {
                balls[index].position.x = Self.radius
                balls[index].velocity.x = abs(balls[index].velocity.x) * 0.84
                rail = true
            } else if point.x > 600 - Self.radius && point.y > 18 && point.y < 282 {
                balls[index].position.x = 600 - Self.radius
                balls[index].velocity.x = -abs(balls[index].velocity.x) * 0.84
                rail = true
            }
            if !sideMouth && !cornerMouth {
                if point.y < Self.radius {
                    balls[index].position.y = Self.radius
                    balls[index].velocity.y = abs(balls[index].velocity.y) * 0.84
                    rail = true
                } else if point.y > 300 - Self.radius {
                    balls[index].position.y = 300 - Self.radius
                    balls[index].velocity.y = -abs(balls[index].velocity.y) * 0.84
                    rail = true
                }
            }
            if point.x < -10 || point.x > 610 || point.y < -10 || point.y > 310 {
                let pocket =
                    Self.pockets.enumerated().min {
                        ($0.element - point).length < ($1.element - point).length
                    }?.offset ?? 0
                balls[index].pocketed = true
                balls[index].velocity = .zero
                events.pots.append((balls[index].id, pocket))
            }
            if rail {
                events.railBalls.insert(balls[index].id)
                if events.firstContact != nil { events.railAfterContact = true }
                collisionEnergy = max(collisionEnergy, speed * 0.5)
                if balls[index].id == 0 {
                    balls[index].velocity =
                        balls[index].velocity
                        + Vector(x: -balls[index].velocity.y, y: balls[index].velocity.x)
                        * spin * 0.12
                    spin *= 0.4
                }
            }
            let next = max(0, balls[index].velocity.length - (23 + speed * 0.30) * dt)
            balls[index].velocity = next < 5 ? .zero : balls[index].velocity.unit * next
        }
        for first in balls.indices where !balls[first].pocketed {
            for second in balls.indices where second > first && !balls[second].pocketed {
                let delta = balls[second].position - balls[first].position
                let distance = delta.length
                guard distance < Self.radius * 2 else { continue }
                let normal = distance > 0.001 ? delta / distance : Vector(x: 1, y: 0)
                let overlap = (Self.radius * 2 - distance + 0.001) * 0.5
                balls[first].position = balls[first].position - normal * overlap
                balls[second].position = balls[second].position + normal * overlap
                let relative = (balls[first].velocity - balls[second].velocity).dot(normal)
                guard relative > 0 else { continue }
                let impulse = normal * (relative * 0.98)
                balls[first].velocity = balls[first].velocity - impulse
                balls[second].velocity = balls[second].velocity + impulse
                collisionEnergy = max(collisionEnergy, relative)
                if balls[first].id == 0 && events.firstContact == nil {
                    events.firstContact = balls[second].id
                    balls[first].velocity = balls[first].velocity + normal * spin * relative * 0.26
                }
            }
        }
    }

    func canPlace(_ position: Vector, kitchen: Bool = false) -> Bool {
        position.x >= 22 && position.x <= (kitchen ? 150 : 578)
            && position.y >= 22 && position.y <= 278
            && balls.filter { $0.id != 0 && !$0.pocketed }.allSatisfy {
                ($0.position - position).length >= Self.radius * 2 + 1
            }
    }

    mutating func placeCue(_ position: Vector) {
        balls[0].position = position
        balls[0].velocity = .zero
        balls[0].pocketed = false
    }

    mutating func respot(_ id: Int) {
        guard let index = balls.firstIndex(where: { $0.id == id }) else { return }
        for x in stride(from: 425.0, through: 25.0, by: -19) {
            let point = Vector(x: x, y: 150)
            if balls.filter({ $0.id != id && !$0.pocketed }).allSatisfy({
                ($0.position - point).length > Self.radius * 2
            }) {
                balls[index].position = point
                balls[index].velocity = .zero
                balls[index].pocketed = false
                return
            }
        }
    }

    func trace(angle: Double) -> AimTrace {
        let origin = cue.position
        let direction = Vector.direction(angle)
        var distance = 900.0
        var hit: Ball?
        for ball in balls where ball.id != 0 && !ball.pocketed {
            let delta = ball.position - origin
            let along = delta.dot(direction)
            let perpendicular = delta.dot(delta) - along * along
            if along > 0 && perpendicular < pow(Self.radius * 2, 2) {
                let contact = along - sqrt(pow(Self.radius * 2, 2) - perpendicular)
                if contact > 0 && contact < distance {
                    distance = contact
                    hit = ball
                }
            }
        }
        var wallDistance = 900.0
        var horizontal = false
        if abs(direction.x) > 0.0001 {
            wallDistance = ((direction.x > 0 ? 591.5 : 8.5) - origin.x) / direction.x
        }
        if abs(direction.y) > 0.0001 {
            let vertical = ((direction.y > 0 ? 291.5 : 8.5) - origin.y) / direction.y
            if vertical < wallDistance {
                wallDistance = vertical
                horizontal = true
            }
        }
        if let hit, distance < wallDistance {
            let end = origin + direction * distance
            return AimTrace(
                end: end, ball: hit.id, outgoing: (hit.position - end).unit, bank: nil)
        }
        let reflected = Vector(
            x: horizontal ? direction.x : -direction.x,
            y: horizontal ? -direction.y : direction.y)
        return AimTrace(
            end: origin + direction * wallDistance, ball: nil, outgoing: nil, bank: reflected)
    }

    func pathClear(from: Vector, to: Vector, ignoring: Set<Int>, clearance: Double) -> Bool {
        let segment = to - from
        return balls.filter { !$0.pocketed && !ignoring.contains($0.id) }.allSatisfy { ball in
            let t = max(0, min(1, (ball.position - from).dot(segment) / max(1, segment.dot(segment))))
            return (ball.position - (from + segment * t)).length > clearance
        }
    }
}
