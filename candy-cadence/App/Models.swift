import Foundation

struct PopNote: Codable, Identifiable {
  let id: Int
  let lane: Int
  let at: Double
}

struct Song: Codable, Identifiable {
  let id: String
  let title: String
  let genre: String
  let artist: String
  let bpm: Int
  let duration: Double
  let level: Int
  let notes: [PopNote]

  static let catalog: [Song] = {
    guard let url = Bundle.main.url(forResource: "songs", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let songs = try? JSONDecoder().decode([Song].self, from: data)
    else { fatalError("Bundled song catalog is missing") }
    return songs
  }()
}

struct HitCounts: Codable {
  var cool = 0
  var great = 0
  var good = 0
  var bad = 0
  var miss = 0
}

struct Peer: Codable, Identifiable {
  let id: String
  let name: String
  let connected: Bool
  let ready: Bool
  let score: Int
  let combo: Int
  let maxCombo: Int
  let groove: Int
  let counts: HitCounts
  let judged: [Int]
  let event: Int
  let verdict: String
  let lane: Int
  let delta: Double
  let automated: Bool
}

struct RoomState: Codable {
  let room: String
  let phase: String
  let songID: String
  let startAt: Double
  let serverTime: Double
  let match: Int
  let hostID: String
  let players: [Peer]
}

struct Envelope: Decodable {
  let type: String
  let playerID: String?
  let token: String?
  let room: String?
  let sent: Double?
  let serverTime: Double?
  let error: String?
}

struct Command: Encodable {
  let type: String
  var create: Bool?
  var room: String?
  var name: String?
  var playerID: String?
  var token: String?
  var automated: Bool?
  var songID: String?
  var lane: Int?
  var sequence: Int?
  var time: Double?
  var sent: Double?
}
