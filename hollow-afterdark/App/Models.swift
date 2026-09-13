import Foundation

struct CombatStats: Codable {
  var hits: Int
  var blocks: Int
  var shields: Int
  var jumps: Int
  var specials: Int
  var shifts: Int
  var `throws`: Int
}

struct Duelist: Codable, Identifiable {
  var id: String
  var name: String
  var slot: Int
  var connected: Bool
  var ready: Bool
  var wins: Int
  var x: Double
  var y: Double
  var vy: Double
  var face: Int
  var hp: Int
  var meter: Double
  var grd: Double
  var ascend: Bool
  var broken: Int
  var action: String
  var move: String
  var frame: Int
  var stun: Int
  var combo: Int
  var stats: CombatStats
}

struct Projectile: Codable {
  var id: String
  var owner: String
  var x: Double
  var y: Double
  var vx: Double
}

struct CombatEvent: Codable {
  var id: Int
  var tick: Int
  var type: String
  var owner: String
  var x: Double
  var y: Double
  var text: String
}

struct MatchState: Codable {
  var type: String
  var room: String
  var tick: Int
  var phase: String
  var round: Int
  var remaining: Int
  var countdown: Int
  var cycle: Int
  var cycleNumber: Int
  var winner: String
  var roundWinner: String
  var message: String
  var matchNumber: Int
  var players: [Duelist]
  var projectiles: [Projectile]
  var events: [CombatEvent]
}

struct Envelope: Decodable {
  var type: String
  var id: String?
  var token: String?
  var room: String?
  var message: String?
  var seq: Int?
}

struct HeldInput: Encodable {
  var left = false
  var right = false
  var `guard` = false
  var shield = false
}

struct InputPacket: Encodable {
  var type = "input"
  var seq: Int
  var held: HeldInput
  var press: String?
}

struct JoinPacket: Encodable {
  var type = "join"
  var room: String
  var name: String
  var id: String
  var token: String
}

struct CommandPacket: Encodable {
  var type: String
}
