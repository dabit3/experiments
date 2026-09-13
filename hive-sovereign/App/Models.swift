import Foundation

struct PlatformState: Decodable {
  let x: Double
  let y: Double
  let w: Double
}

struct UnitState: Decodable, Identifiable {
  let id: String
  let team: Int
  let slot: Int
  let role: String
  let x: Double
  let y: Double
  let vx: Double
  let vy: Double
  let facing: Double
  let grounded: Bool
  let berry: Bool
  let speed: Bool
  let dead: Double
  let invulnerable: Double
  let cooldown: Double
  let gateProgress: Double
  let human: Bool
  let diving: Bool
}

struct BerryState: Decodable, Identifiable {
  let id: String
  let x: Double
  let y: Double
}

struct GateState: Decodable {
  let x: Double
  let y: Double
  let kind: String
  let team: Int
}

struct SnailState: Decodable {
  let x: Double
  let y: Double
  let rider: String
  let team: Int
}

struct GameEvent: Decodable {
  let id: Int
  let kind: String
  let team: Int
  let x: Double
  let y: Double
  let detail: String
  let tick: Int
}

struct GameState: Decodable {
  let tick: Int
  let time: Double
  let phase: String
  let winner: Int
  let victory: String
  let score: [Int]
  let lives: [Int]
  let orders: [String]
  let snail: SnailState
  let units: [UnitState]
  let berries: [BerryState]
  let gates: [GateState]
  let events: [GameEvent]
  let platforms: [PlatformState]
  let deposits: [Int]
  let kills: [Int]
}

struct PeerState: Decodable, Identifiable {
  let id: String
  let name: String
  let team: Int
  let connected: Bool
  let ready: Bool
  let slot: Int
  let seq: Int
  let inputs: Int
}

struct Envelope: Decodable {
  let type: String
  var room: String?
  var you: String?
  var id: String?
  var token: String?
  var team: Int?
  var phase: String?
  var countdown: Int?
  var paused: Bool?
  var peers: [PeerState]?
  var game: GameState?
  var match: Int?
  var message: String?
}

struct Command: Encodable {
  var type: String
  var id: String?
  var name: String?
  var room: String?
  var token: String?
  var create: Bool?
  var seq: Int?
  var move: Double?
  var jump: Bool?
  var action: Bool?
  var dive: Bool?
  var slot: Int?
  var order: String?
}

struct GameInput {
  var move: Double = 0
  var jump = false
  var action = false
  var dive = false
}
