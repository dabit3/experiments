import Foundation

enum FlightMedal: String, CaseIterable {
  case firstSplash = "First splash"
  case riverRookie = "River rookie"
  case smoothSailor = "Smooth sailor"
  case otterAce = "Otter ace"
  case riverLegend = "River legend"

  init(score: Int) {
    switch score {
    case 50...: self = .riverLegend
    case 30..<50: self = .otterAce
    case 15..<30: self = .smoothSailor
    case 5..<15: self = .riverRookie
    default: self = .firstSplash
    }
  }

  var nextTarget: Int? {
    switch self {
    case .firstSplash: 5
    case .riverRookie: 15
    case .smoothSailor: 30
    case .otterAce: 50
    case .riverLegend: nil
    }
  }
}

struct FlightRecord: Codable, Equatable {
  private(set) var best = 0
  private(set) var flights = 0
  private(set) var totalGates = 0
  var sound = true
  var haptics = true

  mutating func complete(score: Int) {
    guard score >= 0 else { return }
    best = max(best, score)
    flights += 1
    totalGates += score
  }
}

struct RecordStorage {
  let defaults: UserDefaults
  private let key = "flappy-otter.record.v1"

  func load() -> FlightRecord {
    guard let data = defaults.data(forKey: key),
      let record = try? JSONDecoder().decode(FlightRecord.self, from: data)
    else { return FlightRecord() }
    return record
  }

  func save(_ record: FlightRecord) {
    if let data = try? JSONEncoder().encode(record) {
      defaults.set(data, forKey: key)
    }
  }
}
