import Foundation

struct FighterState: Decodable, Identifiable {
  let id: String
  let name: String
  let slot: Int
  let connected: Bool
  let ready: Bool
  let wins: Int
  let x: Double
  let y: Double
  let hp: Int
  let meter: Double
  let cards: Int
  let breakTicks: Int
  let burst: Double
  let face: Double
  let move: String
  let frame: Int
  let stun: Int
  let `guard`: Bool
  let axis: Double
  let companion: Int
  let combo: Int
  let awakened: Bool
  let invulnerable: Int
  let lastSeq: Int
  var title: String { slot == 0 ? "REI" : "MIKA" }
  var spirit: String { slot == 0 ? "ANTENNA" : "REDSHIFT" }
}

struct CombatEvent: Decodable {
  let id: Int
  let tick: Int
  let kind: String
  let player: String
  let target: String?
  let damage: Int?
  let x: Double?
  let y: Double?
  let combo: Int?
}

struct MatchState: Decodable {
  let code: String
  let tick: Int
  let phase: String
  let round: Int
  let time: Double
  let phaseTicks: Int
  let winner: String
  let match: Int
  let paused: Bool
  let fighters: [FighterState]
  let events: [CombatEvent]
}

struct ServerMessage: Decodable {
  let type: String
  let playerID: String?
  let token: String?
  let slot: Int?
  let lastSeq: Int?
  let message: String?
}

struct ClientMessage: Encodable {
  let type: String
  var code: String?
  var name: String?
  var playerID: String?
  var token: String?
  var seq: Int?
  var axis: Double?
  var guardHeld: Bool?
  var action: String?
  enum CodingKeys: String, CodingKey {
    case type, code, name, playerID, token, seq, axis, action
    case guardHeld = "guard"
  }
}
