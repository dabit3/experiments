import Foundation
import SwiftUI

struct PlayerState: Decodable, Identifiable {
  let id: String
  let name: String
  let color: Int
  let connected: Bool
  let ready: Bool
  let score: Int
  let crowns: Int
  let x: Double
  let y: Double
  let dir: String
  let wanted: String
  let alive: Bool
  let power: Double
  let lastSeq: Int
  let shield: Double
  let kills: Int
}

struct GhostState: Decodable, Identifiable {
  let id: String
  let x: Double
  let y: Double
  let dir: String
  let respawn: Double
  let color: Int
}

struct PowerState: Decodable {
  let x: Int
  let y: Int
  let active: Bool
}

struct GameEvent: Decodable, Identifiable {
  let id: Int
  let kind: String
  let playerId: String?
  let x: Double?
  let y: Double?
}

struct ArenaState: Decodable {
  let code: String
  let tick: Int
  let clock: Double
  let phase: String
  let round: Int
  let remaining: Double
  let countdown: Double
  let winnerId: String?
  let roundWinnerId: String?
  let players: [PlayerState]
  let ghosts: [GhostState]
  let pellets: [String]
  let powers: [PowerState]
  let fruit: Bool
  let maze: [String]
  let events: [GameEvent]
  let pauseReason: String
  let you: String
}

struct Envelope: Decodable {
  let type: String
  let code: String?
  let you: String?
  let token: String?
  let lastSeq: Int?
  let message: String?
}

struct ClientMessage: Encodable {
  let type: String
  var create: Bool?
  var code: String?
  var playerId: String?
  var name: String?
  var token: String?
  var seq: Int?
  var direction: String?
}

enum Palette {
  static let ink = Color(red: 0.025, green: 0.035, blue: 0.095)
  static let gold = Color(red: 1, green: 0.84, blue: 0.17)
  static let cyan = Color(red: 0.28, green: 0.87, blue: 1)
  static let colors: [Color] = [
    gold, Color(red: 1, green: 0.31, blue: 0.65),
    cyan, Color(red: 0.56, green: 1, blue: 0.37),
  ]
  static func player(_ index: Int) -> Color { colors[index % colors.count] }
}
