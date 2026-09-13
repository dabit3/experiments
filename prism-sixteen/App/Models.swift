import Foundation

struct Note: Codable, Identifiable {
  let id: Int
  let cell: Int
  let time: Double
}

struct Song: Codable, Identifiable {
  let id: String
  let title: String
  let artist: String
  let bpm: Int
  let tagline: String
  let duration: Double
  let charts: [String: [Note]]

  static func load() -> [Song] {
    guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let songs = try? JSONDecoder().decode([Song].self, from: data)
    else { return [] }
    return songs
  }
}

struct Judgment: Decodable {
  let cell: Int
  let noteID: Int
  let label: String
  let error: Double
  let at: Double
  let source: String
}

struct Peer: Decodable, Identifiable {
  let id: String
  let name: String
  let connected: Bool
  let ready: Bool
  let score: Int
  let combo: Int
  let maxCombo: Int
  let accuracy: Double
  let shutter: Double
  let perfect: Int
  let great: Int
  let good: Int
  let miss: Int
  let ghost: Int
  let judged: [String: String]
  let last: Judgment?
}

struct Room: Decodable {
  let code: String
  let hostID: String
  let phase: String
  let songID: String
  let difficulty: String
  let round: Int
  let startAt: Double
  let players: [Peer]
}

struct ServerMessage: Decodable {
  let type: String
  let room: Room?
  let message: String?
  let serverTime: Double?
  let sent: Double?
  let id: String?
  let token: String?
  let code: String?
  let lastSequence: Int?
}

struct ClientMessage: Encodable {
  var type: String
  var name: String?
  var code: String?
  var playerID: String?
  var token: String?
  var sent: Double?
  var songID: String?
  var difficulty: String?
  var ready: Bool?
  var cell: Int?
  var at: Double?
  var seq: Int?
  var round: Int?
  var source: String?
}

struct LaunchOptions {
  private let arguments = ProcessInfo.processInfo.arguments

  func value(_ flag: String) -> String? {
    guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else {
      return nil
    }
    return arguments[index + 1]
  }

  func has(_ flag: String) -> Bool { arguments.contains(flag) }
}
