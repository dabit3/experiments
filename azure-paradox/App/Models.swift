import Foundation

struct FighterState: Decodable, Identifiable {
  let id: String
  let name: String
  let character: String
  let slot: Int
  let connected: Bool
  let ready: Bool
  let wins: Int
  let x: Double
  let y: Double
  let vx: Double
  let vy: Double
  let face: Double
  let hp: Double
  let heat: Double
  let barrier: Double
  let danger: Int
  let stun: Int
  let frozen: Int
  let combo: Int
  let comboDamage: Int
  let comboTimer: Int
  let attack: String
  let attackTick: Int
  let jumps: Int
  let dash: Int
  let `guard`: Bool
  let rematch: Bool
  let dealt: Int
}

struct CombatEvent: Decodable {
  let id: Int
  let kind: String
  let text: String
  let player: String
  let tick: Int
  let x: Double?
  let y: Double?
  let damage: Int?
}

struct ProjectileState: Decodable {
  let id: Int
  let owner: String
  let x: Double
  let y: Double
  let face: Double
}

struct DuelState: Decodable {
  let code: String
  let tick: Int
  let phase: String
  let clock: Int
  let round: Int
  let winner: String
  let roundWinner: String
  let match: Int
  let phaseTicks: Int
  let paused: Bool
  let players: [FighterState]
  let events: [CombatEvent]
  let projectiles: [ProjectileState]
}

struct Envelope: Decodable {
  let type: String
  let id: String?
  let token: String?
  let message: String?
}

struct Command: Encodable {
  var type: String
  var version: Int?
  var room: String?
  var name: String?
  var character: String?
  var create: Bool?
  var token: String?
  var ready: Bool?
  var seq: Int?
  var axis: Double?
  var guardHeld: Bool?
  var action: String?

  enum CodingKeys: String, CodingKey {
    case type, version, room, name, character, create, token, ready, seq, axis, action
    case guardHeld = "guard"
  }
}
