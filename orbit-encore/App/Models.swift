import Foundation

struct Point: Codable {
    let x: Double
    let y: Double

    static func target(_ lane: Int, radius: Double = 0.82) -> Point {
        let angle = Double.pi / 2 - (Double(lane) + 0.5) * Double.pi / 4
        return Point(x: cos(angle) * radius, y: sin(angle) * radius)
    }
}

struct Note: Codable, Identifiable {
    let id: Int
    let time: Double
    let lane: Int
    let kind: String
    let duration: Double
    let path: [Point]
}

struct Chart: Codable, Identifiable {
    let id: String
    let title: String
    let artist: String
    let bpm: Int
    let bars: Int
    let difficulty: String
    let level: Int
    let duration: Double
    let notes: [Note]
}

struct NoteState: Decodable {
    let state: String
    let checkpoint: Int
    let judgment: String
}

struct Judgment: Decodable {
    let id: Int
    let text: String
    let at: Double
    let lane: Int
}

struct Player: Decodable, Identifiable {
    let id: String
    let name: String
    let ready: Bool
    let connected: Bool
    let score: Int
    let combo: Int
    let maxCombo: Int
    let accuracy: Double
    let judged: Int
    let counts: [String: Int]
    let lastJudgment: Judgment?
    let notes: [NoteState]
}

struct Snapshot: Decodable {
    let room: String
    let phase: String
    let songID: String
    let startAt: Double
    let serverTime: Double
    let matchID: Int
    let players: [Player]
}

struct Envelope: Decodable {
    let type: String
    let id: String?
    let token: String?
    let room: String?
    let charts: [Chart]?
    let sentAt: Double?
    let serverTime: Double?
    let message: String?
}

struct Outbound: Encodable {
    var type: String
    var name: String?
    var room: String?
    var token: String?
    var songID: String?
    var ready: Bool?
    var sentAt: Double?
    var matchID: Int?
    var at: Double?
    var seq: Int?
    var pointer: Int?
    var phase: String?
    var x: Double?
    var y: Double?
}
