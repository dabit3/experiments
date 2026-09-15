import Foundation

struct Chart: Codable, Identifiable {
  let id: String
  let title: String
  let artist: String
  let bpm: Double
  let level: String
  let color: String
  let duration: Double
  let tick: Double
  let notes: [Note]

  static let all: [Chart] = {
    guard let url = Bundle.main.url(forResource: "charts", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let charts = try? JSONDecoder().decode([Chart].self, from: data)
    else { return [] }
    return charts
  }()
}

struct Note: Codable, Identifiable {
  let id: Int
  let kind: String
  let time: Double
  let lane: Double
  let width: Double
  let endLane: Double
  let duration: Double
}

struct Counts: Codable {
  var critical: Int = 0
  var justice: Int = 0
  var attack: Int = 0
  var miss: Int = 0
}

struct Judgment: Codable {
  let id: String
  let judgment: String
  let lane: Double
  let width: Double
}

struct Player: Codable, Identifiable {
  let id: String
  let name: String
  let connected: Bool
  let ready: Bool
  let score: Int
  let combo: Int
  let maxCombo: Int
  let accuracy: Double
  let counts: Counts
  let last: Judgment?
}

struct RoomState: Codable {
  let room: String
  let phase: String
  let song: String
  let startAt: Double
  let round: Int
  let host: String
  let now: Double
  let players: [Player]
}

struct ServerMessage: Decodable {
  let type: String
  let id: String?
  let token: String?
  let room: String?
  let message: String?
  let sent: Double?
  let now: Double?
}

struct JoinMessage: Encodable {
  let type = "join"
  let name: String
  let create: Bool
  let room: String
  let token: String?
}

struct ControlMessage: Encodable {
  let type: String
  var song: String?
  var ready: Bool?
  var sent: Double?
}

struct TouchMessage: Encodable {
  let type = "input"
  let seq: Int
  let at: Double
  let pointer: String
  let action: String
  let x: Double
  let y: Double
}

enum Launch {
  static func value(_ key: String) -> String? {
    let args = ProcessInfo.processInfo.arguments
    guard let i = args.firstIndex(of: "--\(key)"), i + 1 < args.count else { return nil }
    return args[i + 1]
  }
  static func has(_ key: String) -> Bool {
    ProcessInfo.processInfo.arguments.contains("--\(key)")
  }
}
