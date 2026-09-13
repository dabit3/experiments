import Foundation

struct AttackState: Decodable {
  let move: String
  let frame: Int
  let low: Bool
  let air: Bool
}

struct FighterState: Decodable, Identifiable {
  let id: String
  let name: String
  let character: String
  let slot: Int
  let connected: Bool
  let ready: Bool
  let rematch: Bool
  let x: Double
  let y: Double
  let facing: Double
  let hp: Int
  let meter: Int
  let wins: Int
  let pose: String
  let attack: AttackState?
  let stun: Int
  let seq: Int
  let combo: Int
  let comboTicks: Int
  let hits: Int
  let blocks: Int
  let actions: Int
  let damageDealt: Int
}

struct WaveState: Decodable, Identifiable {
  let id: Int
  let owner: String
  let x: Double
  let y: Double
  let vx: Double
  let `super`: Bool
}

struct ImpactState: Decodable {
  let id: Int
  let kind: String
  let x: Double
  let y: Double
  let owner: String
  let text: String
  let life: Int
}

struct MatchState: Decodable {
  let code: String
  let tick: Int
  let phase: String
  let phaseTicks: Int
  let remaining: Int
  let round: Int
  let match: Int
  let winner: String
  let roundWinner: String
  let paused: Bool
  let freeze: Int
  let effects: [ImpactState]
  let projectiles: [WaveState]
  let players: [FighterState]
}

struct Envelope: Decodable {
  let type: String
  let playerID: String?
  let token: String?
  let room: String?
  let seq: Int?
  let message: String?
  let sent: Double?
}

struct ClientMessage: Encodable {
  let type: String
  var name: String?
  var character: String?
  var room: String?
  var create: Bool?
  var playerID: String?
  var token: String?
  var seq: Int?
  var held: [String: Bool]?
  var action: String?
  var ready: Bool?
  var sent: Double?
}
