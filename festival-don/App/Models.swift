import Foundation

struct Note: Codable, Identifiable {
    let id: Int
    let at: Double
    let kind: String
    let big: Bool
    let duration: Double
}

struct SongChart: Codable {
    let id: String
    let title: String
    let subtitle: String
    let bpm: Int
    let bars: Int
    let difficulty: String
    let duration: Double
    let notes: [Note]

    static func load(_ song: String, difficulty: String = "festival") -> SongChart {
        guard let url = Bundle.main.url(forResource: "\(song)-\(difficulty)", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let chart = try? JSONDecoder().decode(SongChart.self, from: data) else {
            preconditionFailure("Bundled song chart is missing")
        }
        return chart
    }
}

struct Drummer: Codable, Identifiable {
    let id: String
    let name: String
    let connected: Bool
    let ready: Bool
    let score: Int
    let combo: Int
    let maxCombo: Int
    let good: Int
    let ok: Int
    let bad: Int
    let rolls: Int
    let bigHits: Int
    let gauge: Double
    let consumed: [Int]
    let judgment: String
    let delta: Int
    let event: Int
    let inputCount: Int
}

struct Room: Codable {
    let code: String
    let phase: String
    let host: String
    let song: String
    let difficulty: String
    let startAt: Double
    let round: Int
    let winner: String
    let players: [Drummer]
}

struct ServerMessage: Decodable {
    let type: String
    let id: String?
    let token: String?
    let room: Room?
    let chart: SongChart?
    let sent: Double?
    let now: Double?
    let message: String?
}

struct ClientMessage: Encodable {
    var type: String
    var name: String?
    var code: String?
    var token: String?
    var sent: Double?
    var song: String?
    var difficulty: String?
    var ready: Bool?
    var seq: Int?
    var at: Double?
    var kind: String?
    var hand: String?
}

enum LaunchOptions {
    static func value(_ key: String) -> String? {
        guard let index = ProcessInfo.processInfo.arguments.firstIndex(of: key),
              ProcessInfo.processInfo.arguments.indices.contains(index + 1) else { return nil }
        return ProcessInfo.processInfo.arguments[index + 1]
    }
    static func has(_ key: String) -> Bool { ProcessInfo.processInfo.arguments.contains(key) }
}
