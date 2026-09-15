import Foundation

enum Film: String, Codable, CaseIterable, Identifiable, Sendable {
  case original, silver, noir, dune, faded

  var id: String { rawValue }
  var title: String {
    switch self {
    case .original: "Original"
    case .silver: "Silver"
    case .noir: "Noir"
    case .dune: "Dune"
    case .faded: "Faded"
    }
  }
  var code: String {
    switch self {
    case .original: "00"
    case .silver: "01"
    case .noir: "02"
    case .dune: "03"
    case .faded: "04"
    }
  }
  var note: String {
    switch self {
    case .original: "Light, exactly as you found it."
    case .silver: "Soft silver tones. Quiet, luminous detail."
    case .noir: "Deep blacks. A little more drama."
    case .dune: "Sun-warmed color. Gentle nostalgia."
    case .faded: "Lifted shadows. Color with a softer voice."
    }
  }
}

struct EditSettings: Codable, Equatable, Sendable {
  var film: Film = .original
  var exposure: Double = 0
  var contrast: Double = 1
  var warmth: Double = 0
  var quarterTurns: Int = 0
  var squareCrop: Bool = false

  var normalized: EditSettings {
    var copy = self
    copy.exposure = exposure.isFinite ? min(2, max(-2, exposure)) : 0
    copy.contrast = contrast.isFinite ? min(1.5, max(0.5, contrast)) : 1
    copy.warmth = warmth.isFinite ? min(1, max(-1, warmth)) : 0
    copy.quarterTurns = ((quarterTurns % 4) + 4) % 4
    return copy
  }

  var recipe: EditSettings {
    var copy = normalized
    copy.quarterTurns = 0
    copy.squareCrop = false
    return copy
  }
}

struct Negative: Codable, Identifiable, Equatable {
  var id: String
  var title: String
  var subtitle: String
  var resource: String
  var isSample: Bool
  var settings = EditSettings()
}

struct SliderScale {
  let range: ClosedRange<Double>
  var step: Double = 0.05

  func value(at fraction: Double) -> Double {
    let fraction = fraction.isFinite ? min(1, max(0, fraction)) : 0
    let distance = fraction * (range.upperBound - range.lowerBound)
    let value = range.lowerBound + (distance / step).rounded() * step
    return min(range.upperBound, max(range.lowerBound, value))
  }

  func fraction(for value: Double) -> Double {
    guard value.isFinite, range.upperBound > range.lowerBound else { return 0 }
    return min(1, max(0, (value - range.lowerBound) / (range.upperBound - range.lowerBound)))
  }
}

struct EditHistory {
  private(set) var undoStack: [EditSettings] = []
  private(set) var redoStack: [EditSettings] = []
  private var gestureStart: EditSettings?
  private let limit = 100

  mutating func beginGesture(at settings: EditSettings) {
    if gestureStart == nil { gestureStart = settings }
  }

  mutating func endGesture(at settings: EditSettings) {
    guard let start = gestureStart else { return }
    gestureStart = nil
    record(from: start, to: settings)
  }

  mutating func record(from previous: EditSettings, to next: EditSettings) {
    guard gestureStart == nil, previous != next else { return }
    undoStack.append(previous)
    if undoStack.count > limit { undoStack.removeFirst() }
    redoStack.removeAll()
  }

  mutating func undo(_ current: EditSettings) -> EditSettings? {
    endGesture(at: current)
    guard let previous = undoStack.popLast() else { return nil }
    redoStack.append(current)
    return previous
  }

  mutating func redo(_ current: EditSettings) -> EditSettings? {
    endGesture(at: current)
    guard let next = redoStack.popLast() else { return nil }
    undoStack.append(current)
    return next
  }
}

struct Recipe: Codable, Identifiable, Equatable {
  var id = UUID()
  var name: String
  var settings: EditSettings
}

struct LibraryState: Codable {
  var negatives: [Negative] = [
    Negative(
      id: "cove", title: "The cove", subtitle: "Mediterranean light",
      resource: "Cove", isSample: true),
    Negative(
      id: "still", title: "Quiet morning", subtitle: "A study in soft light",
      resource: "Still", isSample: true),
  ]
  var recipes: [Recipe] = []
}

struct LibraryDisk {
  let directory: URL
  var stateURL: URL { directory.appendingPathComponent("library.json") }

  func load() throws -> LibraryState {
    guard FileManager.default.fileExists(atPath: stateURL.path) else {
      return LibraryState()
    }
    return try JSONDecoder().decode(LibraryState.self, from: Data(contentsOf: stateURL))
  }

  func save(_ state: LibraryState) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try JSONEncoder().encode(state).write(to: stateURL, options: .atomic)
  }
}
