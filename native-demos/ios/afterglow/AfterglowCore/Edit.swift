import Foundation

public enum FilmLook: String, Codable, CaseIterable, Sendable {
  case original = "Original"
  case ember = "Ember"
  case coast = "Coastal"
  case silver = "Silver"
  case dusk = "Dusk"

  public var note: String {
    switch self {
    case .original: "True to the moment"
    case .ember: "Warm highlights · soft shadows"
    case .coast: "Cool air · quiet color"
    case .silver: "Timeless monochrome"
    case .dusk: "Muted color · deep atmosphere"
    }
  }
}

public enum CropFormat: String, Codable, CaseIterable, Sendable {
  case original = "Full"
  case portrait = "4:5"
  case square = "1:1"
  case cinema = "16:9"

  public var ratio: Double? {
    switch self {
    case .original: nil
    case .portrait: 0.8
    case .square: 1
    case .cinema: 16.0 / 9.0
    }
  }
}

public struct Edit: Codable, Equatable, Sendable {
  public var look: FilmLook = .original
  public var lookAmount: Double = 1
  public var exposure: Double = 0
  public var contrast: Double = 1
  public var saturation: Double = 1
  public var warmth: Double = 0
  public var highlights: Double = 0
  public var shadows: Double = 0
  public var vibrance: Double = 0
  public var sharpness: Double = 0
  public var vignette: Double = 0
  public var crop: CropFormat = .original
  public var rotation: Int = 0
  public var zoom: Double = 1
  public var panX: Double = 0
  public var panY: Double = 0

  public init() {}

  private enum CodingKeys: String, CodingKey {
    case look, lookAmount, exposure, contrast, saturation, warmth, highlights, shadows
    case vibrance, sharpness, vignette, crop, rotation, zoom, panX, panY
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    look = try values.decodeIfPresent(FilmLook.self, forKey: .look) ?? .original
    crop = try values.decodeIfPresent(CropFormat.self, forKey: .crop) ?? .original
    rotation = try values.decodeIfPresent(Int.self, forKey: .rotation) ?? 0
    let fields: [(CodingKeys, WritableKeyPath<Edit, Double>, Double)] = [
      (.lookAmount, \.lookAmount, 1), (.exposure, \.exposure, 0),
      (.contrast, \.contrast, 1), (.saturation, \.saturation, 1), (.warmth, \.warmth, 0),
      (.highlights, \.highlights, 0), (.shadows, \.shadows, 0), (.vibrance, \.vibrance, 0),
      (.sharpness, \.sharpness, 0), (.vignette, \.vignette, 0),
      (.zoom, \.zoom, 1), (.panX, \.panX, 0), (.panY, \.panY, 0),
    ]
    for (key, path, fallback) in fields {
      self[keyPath: path] = try values.decodeIfPresent(Double.self, forKey: key) ?? fallback
    }
    self = sanitized()
  }

  public func sanitized() -> Edit {
    var result = self
    result.lookAmount = Self.bound(lookAmount, 0...1, fallback: 1)
    result.exposure = Self.bound(exposure, -2...2, fallback: 0)
    result.contrast = Self.bound(contrast, 0.5...1.5, fallback: 1)
    result.saturation = Self.bound(saturation, 0...2, fallback: 1)
    result.warmth = Self.bound(warmth, -1...1, fallback: 0)
    result.highlights = Self.bound(highlights, -1...1, fallback: 0)
    result.shadows = Self.bound(shadows, -1...1, fallback: 0)
    result.vibrance = Self.bound(vibrance, -1...1, fallback: 0)
    result.sharpness = Self.bound(sharpness, 0...1, fallback: 0)
    result.vignette = Self.bound(vignette, 0...1, fallback: 0)
    result.zoom = Self.bound(zoom, 1...2.5, fallback: 1)
    result.panX = Self.bound(panX, -1...1, fallback: 0)
    result.panY = Self.bound(panY, -1...1, fallback: 0)
    result.rotation = ((rotation % 4) + 4) % 4
    return result
  }

  private static func bound(
    _ value: Double, _ range: ClosedRange<Double>, fallback: Double
  ) -> Double {
    value.isFinite ? min(max(value, range.lowerBound), range.upperBound) : fallback
  }
}

public struct EditHistory: Codable, Equatable, Sendable {
  public private(set) var current = Edit()
  public private(set) var undoStack: [Edit] = []
  public private(set) var redoStack: [Edit] = []

  public init() {}
  public var canUndo: Bool { !undoStack.isEmpty }
  public var canRedo: Bool { !redoStack.isEmpty }

  public mutating func apply(_ edit: Edit) {
    let value = edit.sanitized()
    guard value != current else { return }
    undoStack.append(current)
    undoStack = Array(undoStack.suffix(60))
    current = value
    redoStack.removeAll()
  }

  public mutating func undo() {
    guard let previous = undoStack.popLast() else { return }
    redoStack.append(current)
    current = previous
  }

  public mutating func redo() {
    guard let next = redoStack.popLast() else { return }
    undoStack.append(current)
    current = next
  }
}

public struct ImportedPhoto: Codable, Equatable, Sendable, Identifiable {
  public let id: String
  public let fileName: String
  public let title: String
  public let width: Int
  public let height: Int

  public init(id: String, fileName: String, title: String, width: Int, height: Int) {
    self.id = id
    self.fileName = fileName
    self.title = title
    self.width = width
    self.height = height
  }
}

public struct Project: Codable, Equatable, Sendable {
  public var version = 1
  public var selectedID = "dunes"
  public var photos: [String: EditHistory] = [:]
  public var imports: [ImportedPhoto] = []
  public var favorites: Set<String> = []
  public init() {}

  private enum CodingKeys: String, CodingKey {
    case version, selectedID, photos, imports, favorites
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    version = try values.decode(Int.self, forKey: .version)
    selectedID = try values.decode(String.self, forKey: .selectedID)
    photos = try values.decode([String: EditHistory].self, forKey: .photos)
    imports = try values.decodeIfPresent([ImportedPhoto].self, forKey: .imports) ?? []
    favorites = try values.decodeIfPresent(Set<String>.self, forKey: .favorites) ?? []
    guard
      imports.allSatisfy({
        !$0.fileName.isEmpty && !$0.fileName.contains("/") && !$0.fileName.contains("..")
      })
    else { throw CocoaError(.fileReadCorruptFile) }
  }
}

public enum ProjectFile {
  public static func save(_ project: Project, to url: URL) throws {
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(project).write(to: url, options: .atomic)
  }

  public static func load(from url: URL) throws -> Project {
    let project = try JSONDecoder().decode(Project.self, from: Data(contentsOf: url))
    guard project.version == 1 else {
      throw CocoaError(.fileReadCorruptFile)
    }
    return project
  }
}
