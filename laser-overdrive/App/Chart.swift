import Foundation

struct Note: Codable {
  let id: Int
  let lane: Int
  let time: Double
  let duration: Double
  let kind: String
}

struct LaserPoint: Codable {
  let time: Double
  let x: Double
}

struct LaserPath: Codable {
  let id: Int
  let color: Int
  let points: [LaserPoint]

  var start: Double { points[0].time }
  var end: Double { points[points.count - 1].time }

  func position(at time: Double) -> Double {
    for index in 1..<points.count where time <= points[index].time {
      let a = points[index - 1]
      let b = points[index]
      let fraction = max(0, min(1, (time - a.time) / (b.time - a.time)))
      return a.x + (b.x - a.x) * fraction
    }
    return points[points.count - 1].x
  }
}

struct Chart: Codable {
  let id: String
  let title: String
  let artist: String
  let bpm: Int
  let duration: Double
  let tick: Double
  let notes: [Note]
  let lasers: [LaserPath]

  static func load() -> Chart {
    guard let url = Bundle.main.url(forResource: "chart", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let chart = try? JSONDecoder().decode(Chart.self, from: data)
    else { fatalError("The bundled chart is missing or invalid") }
    return chart
  }
}

struct Peer: Codable, Identifiable {
  let id: String
  let name: String
  let connected: Bool
  let ready: Bool
  let score: Int
  let combo: Int
  let maxCombo: Int
  let gauge: Double
  let critical: Int
  let near: Int
  let errors: Int
  let holdHits: Int
  let laserHits: Int
  let slamHits: Int
  let fxHits: Int
  let tapHits: Int
  let judgment: String
  let judgmentAt: Double
  let lasers: [Double]
  let inputCount: Int
  let manualInputs: Int
}

struct WireMessage: Codable {
  var type: String
  var id: String?
  var token: String?
  var name: String?
  var code: String?
  var create: Bool?
  var chart: String?
  var nextSeq: Int?
  var sent: Double?
  var serverNow: Double?
  var startAt: Double?
  var duration: Double?
  var phase: String?
  var epoch: Int?
  var players: [Peer]?
  var message: String?
  var kind: String?
  var lane: Int?
  var color: Int?
  var down: Bool?
  var x: Double?
  var time: Double?
  var seq: Int?
  var source: String?
}
