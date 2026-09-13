import Foundation
import SwiftUI

struct Hero {
  let name: String
  let weapon: String
  let role: String
  let hex: UInt32
  var color: Color { Color(uiColor: UIColor(hex: hex)) }
  static let all: [Hero] = [
    Hero(name: "RIPTIDE", weapon: "TWIN SABERS", role: "Balanced • flowing combos", hex: 0x27AFFF),
    Hero(
      name: "CINDER", weapon: "CHAIN BATONS", role: "Fast • close-range flurries", hex: 0xFF922E),
    Hero(name: "CIRCUIT", weapon: "VOLT STAFF", role: "Reach • wide power burst", hex: 0xBF70FF),
    Hero(name: "FANG", weapon: "TWIN PRONGS", role: "Heavy • devastating strikes", hex: 0xFF4260),
  ]
}

extension UIColor {
  convenience init(hex: UInt32) {
    self.init(
      red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
      blue: CGFloat(hex & 255) / 255, alpha: 1)
  }
}

struct PlayerStats: Codable {
  let attacks: Int
  let jumps: Int
  let specials: Int
  let damage: Int
  let revives: Int
  let distance: Double
}
struct PlayerState: Codable, Identifiable {
  let id: String
  let name: String
  let hero: Int
  let connected: Bool
  let ready: Bool
  let rematch: Bool
  let x: Double
  let y: Double
  let z: Double
  let face: Int
  let hp: Int
  let power: Int
  let score: Int
  let hits: Int
  let combo: Int
  let action: String
  let actionTime: Double
  let invuln: Double
  let down: Double
  let revive: Double
  let seq: Int
  let stats: PlayerStats
}
struct EnemyState: Codable, Identifiable {
  let id: String
  let kind: String
  let x: Double
  let y: Double
  let hp: Int
  let maxHP: Int
  let face: Int
  let action: String
  let timer: Double
  let stun: Double
  let targetX: Double
  let targetY: Double
  let attack: Int
}
struct SliceState: Codable, Identifiable {
  let id: String
  let x: Double
  let y: Double
}
struct GameEvent: Codable, Identifiable {
  let id: Int
  let tick: Int
  let kind: String
  let x: Double
  let y: Double
  let text: String
  let player: String
}
struct GameState: Codable {
  let type: String
  let code: String
  let tick: Int
  let match: Int
  let phase: String
  let sector: Int
  let sectorName: String
  let gate: Int
  let startAt: Int
  let elapsed: Double
  let banner: String
  let defeated: Int
  let waveClear: Bool
  let players: [PlayerState]
  let enemies: [EnemyState]
  let pickups: [SliceState]
  let events: [GameEvent]
}
struct Envelope: Codable {
  let type: String
  var id: String?
  var token: String?
  var code: String?
  var message: String?
  var resumed: Bool?
}
struct Outbound: Encodable {
  let type: String
  var name: String?
  var hero: Int?
  var code: String?
  var create: Bool?
  var token: String?
  var seq: Int?
  var dx: Double?
  var dy: Double?
  var action: String?
}
