import Foundation
import SwiftUI

struct Fighter: Identifiable {
  let id: String
  let title: String
  let style: String
  let special: String
  let color: Color

  static let all: [Fighter] = [
    Fighter(
      id: "rook", title: "ROOK", style: "FLAME STRIKER", special: "Cinder Wave", color: .orange),
    Fighter(
      id: "vesper", title: "VESPER", style: "VIOLET ASSASSIN", special: "Night Rush", color: .purple
    ),
    Fighter(id: "atlas", title: "ATLAS", style: "IRON BOXER", special: "Titan Upper", color: .cyan),
    Fighter(id: "sora", title: "SORA", style: "SKY DANCER", special: "Phoenix Rise", color: .pink),
    Fighter(
      id: "kestrel", title: "KESTREL", style: "ICE DUELIST", special: "Frost Wave", color: .blue),
    Fighter(id: "jin", title: "JIN", style: "GOLDEN FIST", special: "Tiger Rush", color: .yellow),
  ]

  static func named(_ id: String) -> Fighter {
    all.first { $0.id == id } ?? all[0]
  }
}

struct MemberState: Codable {
  var fighter: String
  var hp: Int
}

struct PeerState: Codable {
  var id: String
  var name: String
  var roster: [MemberState]
  var connected: Bool
  var ready: Bool
  var active: Int
  var meter: Int
  var x: Double
  var y: Double
  var face: Double
  var pose: String
  var guardValue: Int
  var guarding: Bool
  var crouch: Bool
  var combo: Int
  var ack: Int
  var rematch: Bool
  var damage: Int
  var knockouts: Int

  enum CodingKeys: String, CodingKey {
    case id, name, roster, connected, ready, active, meter, x, y, face, pose
    case guardValue = "guard"
    case guarding, crouch, combo, ack, rematch, damage, knockouts
  }

  var member: MemberState { roster[min(active, roster.count - 1)] }
}

struct ProjectileState: Codable {
  var id: String
  var owner: String
  var x: Double
  var y: Double
  var direction: Double
  var isSuper: Bool
  var fighter: String

  enum CodingKeys: String, CodingKey {
    case id, owner, x, y, direction, fighter
    case isSuper = "super"
  }
}

struct CombatEvent: Codable {
  var id: Int
  var tick: Int
  var kind: String
  var player: String?
  var target: String?
  var damage: Int?
  var combo: Int?
  var action: String?
  var x: Double?
  var y: Double?
}

struct MatchState: Codable {
  var code: String
  var tick: Int
  var phase: String
  var match: Int
  var round: Int
  var timer: Int
  var wait: Int
  var winner: String
  var paused: Bool
  var peers: [PeerState]
  var projectiles: [ProjectileState]
  var events: [CombatEvent]
}

struct Welcome: Decodable {
  var code: String
  var token: String
  var ack: Int
}

struct MessageKind: Decodable {
  var type: String
  var message: String?
}

struct WireMessage: Encodable {
  var type: String
  var id: String?
  var name: String?
  var code: String?
  var create: Bool?
  var roster: [String]?
  var token: String?
  var seq: Int?
  var move: Int?
  var guardValue: Bool?
  var crouch: Bool?
  var run: Bool?
  var action: String?

  enum CodingKeys: String, CodingKey {
    case type, id, name, code, create, roster, token, seq, move, crouch, run, action
    case guardValue = "guard"
  }
}

struct InputState {
  var move = 0
  var guardValue = false
  var crouch = false
  var run = false
}

func launchValue(_ key: String) -> String? {
  let arguments = ProcessInfo.processInfo.arguments
  guard let index = arguments.firstIndex(of: key), arguments.indices.contains(index + 1) else {
    return nil
  }
  return arguments[index + 1]
}
