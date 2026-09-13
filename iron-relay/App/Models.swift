import Foundation
import SwiftUI

struct FighterState: Codable, Identifiable {
  let id: String
  let name: String
  let team: [Int]
  let online: Bool
  let ready: Bool
  let rematch: Bool
  let wins: Int
  let health: [Double]
  let red: [Double]
  let active: Int
  let x: Double
  let z: Double
  let y: Double
  let vx: Double
  let vz: Double
  let guardHeld: Bool
  let stun: Int
  let attack: String
  let age: Int
  let tagCooldown: Int
  let tagFlash: Int
  let combo: Int
  let comboDamage: Int
  let facing: Int
  let seq: Int

  enum CodingKeys: String, CodingKey {
    case id, name, team, online, ready, rematch, wins, health, red, active, x, z, y
    case vx, vz, stun, attack, age, tagCooldown, tagFlash, combo, comboDamage, facing, seq
    case guardHeld = "guard"
  }
}

struct ArenaEvent: Codable {
  let id: Int
  let tick: Int
  let kind: String
  let actor: String
  let target: String
  let value: Int
}

struct ArenaState: Codable {
  let code: String
  let tick: Int
  let phase: String
  let paused: Bool
  let round: Int
  let remaining: Int
  let countdown: Int
  let winner: String
  let roundWinner: String
  let players: [FighterState]
  let events: [ArenaEvent]
}

struct Envelope: Decodable {
  let type: String
  let id: String?
  let token: String?
  let message: String?
  let seq: Int?
}

struct Outbound: Encodable {
  let type: String
  var code: String?
  var name: String?
  var team: [Int]?
  var token: String?
  var seq: Int?
  var action: String?
  var x: Double?
  var z: Double?
  var down: Bool?
}

struct EvidenceRecord: Encodable {
  let type: String
  var action: String?
  var driver: String?
  var identity: String?
  var event: ArenaEvent?
  var state: ArenaState?
}

struct FighterStyle {
  let name: String
  let discipline: String
  let color: UIColor
  let skin: UIColor
  let description: String
  static let all: [FighterStyle] = [
    .init(
      name: "KADE", discipline: "IRON FIST",
      color: UIColor(red: 0.84, green: 0.12, blue: 0.19, alpha: 1),
      skin: UIColor(red: 0.64, green: 0.40, blue: 0.29, alpha: 1),
      description: "Precision boxer • balanced strings"),
    .init(
      name: "NYX", discipline: "NIGHT CIRCUIT",
      color: UIColor(red: 0.46, green: 0.36, blue: 0.9, alpha: 1),
      skin: UIColor(red: 0.83, green: 0.63, blue: 0.51, alpha: 1),
      description: "Cyber kickboxer • light-footed stance"),
    .init(
      name: "ATLAS", discipline: "HEAVY INDUSTRY",
      color: UIColor(red: 0.94, green: 0.62, blue: 0.17, alpha: 1),
      skin: UIColor(red: 0.34, green: 0.23, blue: 0.19, alpha: 1),
      description: "Armored bruiser • heavier impact"),
    .init(
      name: "SORA", discipline: "STILL THUNDER",
      color: UIColor(red: 0.17, green: 0.72, blue: 0.61, alpha: 1),
      skin: UIColor(red: 0.78, green: 0.57, blue: 0.41, alpha: 1),
      description: "Temple striker • flowing silhouette"),
  ]
}
