import Foundation

struct UnitState: Decodable, Identifiable {
  let id: String
  let name: String
  let team: Int
  let ai: Bool
  let cost: Int
  let maxHP: Double
  let hp: Double
  let x: Float
  let y: Float
  let z: Float
  let yaw: Float
  let boost: Double
  let ammo: Int
  let burst: Double
  let overdrive: Double
  let melee: Double
  let combo: Int
  let dodge: Double
  let invulnerable: Double
  let respawn: Double
  let overheated: Bool
  let target: String
  let damage: Int
  let kills: Int
  let shots: Int
  let swings: Int
  let steps: Int
  let flight: Double
  let blocking: Bool
  let connected: Bool
}

struct BeamState: Decodable, Identifiable {
  let id: Int
  let team: Int
  let x: Float
  let y: Float
  let z: Float
  let vx: Float
  let vy: Float
  let vz: Float
}

struct CombatEvent: Decodable {
  let id: Int
  let kind: String
  let unit: String
  let x: Float
  let y: Float
  let z: Float
  let amount: Int?
}

struct ArenaState: Decodable {
  let code: String
  let phase: String
  let round: Int
  let tick: Int
  let time: Double
  let countdown: Double
  let costs: [Int]
  let winner: Int
  let reason: String
  let ready: [String]
  let rematch: [String]
  let units: [UnitState]
  let projectiles: [BeamState]
  let events: [CombatEvent]
}

struct Envelope: Decodable {
  let type: String
  let id: String?
  let token: String?
  let code: String?
  let message: String?
  let sent: Double?
}

struct ClientMessage: Encodable {
  let type: String
  var name: String?
  var code: String?
  var token: String?
  var seq: Int?
  var x: Float?
  var z: Float?
  var boost: Bool?
  var guardAction: Bool?
  var actions: [String]?
  var sent: Double?

  enum CodingKeys: String, CodingKey {
    case type, name, code, token, seq, x, z, boost, actions, sent
    case guardAction = "guard"
  }
}
