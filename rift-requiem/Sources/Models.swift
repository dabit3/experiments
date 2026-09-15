import Foundation

struct Duelist: Codable, Identifiable {
    var id: String
    var name: String
    var style: String
    var slot: Int
    var connected: Bool
    var ready: Bool
    var wins: Int
    var hp: Double
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var facing: Double
    var meter: Double
    var pose: String
    var attack: String
    var frame: Int
    var stun: Int
    var dash: Int
    var airDash: Bool
    var slow: Int
    var combo: Int
    var seq: Int
    var rematch: Bool
}

struct Projectile: Codable {
    var id: Int
    var owner: String
    var x: Double
    var y: Double
    var direction: Double
    var style: String
}

struct CombatEvent: Codable {
    var id: Int
    var tick: Int
    var type: String
    var player: String
    var x: Double
    var y: Double
    var text: String?
    var color: String?
    var combo: Int?
    var counter: Bool?
    var attacker: String?
    var amount: Int?
}

struct MatchState: Codable {
    var code: String
    var tick: Int
    var phase: String
    var round: Int
    var seconds: Double
    var countdown: Int
    var winner: String
    var roundWinner: String
    var paused: Bool
    var matches: Int
    var players: [Duelist]
    var projectiles: [Projectile]
    var events: [CombatEvent]
}

struct Envelope: Decodable {
    var type: String
    var id: String?
    var token: String?
    var code: String?
    var seq: Int?
    var message: String?
}

struct ClientMessage: Encodable {
    var type: String
    var name: String?
    var style: String?
    var code: String?
    var token: String?
    var seq: Int?
    var action: String?
    var value: Int?
}

enum Launch {
    static func value(_ key: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-\(key)"), index + 1 < args.count else { return nil }
        return args[index + 1]
    }
    static var automated: Bool { value("auto") == "1" }
}
