import Foundation

struct Note: Codable {
  let id: Int
  let lane: Int
  let time: Double
  let duration: Double
}

struct Chart: Codable {
  let id: String
  let title: String
  let subtitle: String
  let bpm: Int
  let duration: Double
  let difficulty: String
  let notes: [Note]
  let sections: [String]
}

struct Judgment: Codable {
  let text: String
  let delta: Int
  let lane: Int
  let serial: Int
}

struct Counts: Codable {
  let perfect: Int
  let great: Int
  let good: Int
  let bad: Int
  let poor: Int
}

struct Stats: Codable {
  let score: Int
  let combo: Int
  let maxCombo: Int
  let gauge: Double
  let judged: Int
  let counts: Counts
  let heads: [Int]
  let tails: [Int]
  let last: Judgment
}

struct Player: Codable {
  let id: String
  let name: String
  let online: Bool
  let ready: Bool
  let seq: Int
  let stats: Stats
}

struct RoomState: Codable {
  let room: String
  let phase: String
  let startAt: Double
  let round: Int
  let winner: String
  let players: [Player]
}

struct Packet: Codable {
  let type: String
  let you: String?
  let token: String?
  let chart: Chart?
  let state: RoomState?
  let sent: Double?
  let serverTime: Double?
  let message: String?
}

struct Command: Encodable {
  var type: String
  var room: String?
  var name: String?
  var create: Bool?
  var token: String?
  var sent: Double?
  var seq: Int?
  var lane: Int?
  var down: Bool?
  var time: Double?
}
