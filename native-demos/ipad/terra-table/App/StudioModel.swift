import Foundation
import SwiftUI

#if SWIFT_PACKAGE
  import TerraCore
#endif

@MainActor
final class StudioModel: ObservableObject {
  @Published var terrain = Terrain()
  @Published var brush: Brush = .raise
  @Published var radius: Float = 1.05
  @Published var strength: Float = 0.55
  @Published var contours = false
  @Published var history = TerrainHistory()
  @Published var saved: [SavedWorld] = []
  @Published var status = "Alpine island ready"
  @Published var error: String?
  @Published var revision = 0
  @Published var homeRevision = 0
  @Published var zoom: Float = 1
  @Published private(set) var journeyActive = false
  @Published private(set) var journeyPlaying = false
  @Published private(set) var journeyTime: Double = 0
  @Published var reducedMotion = false
  private(set) var journeyFrame = LandscapeJourney.frame(at: 0)
  private var journeyOriginal: Terrain?
  private var journeyOriginalContours = false
  private var journeyOriginalZoom: Float = 1
  private var journeyTask: Task<Void, Never>?
  private var transaction: Terrain?

  private let documents: URL
  private var autosaveURL: URL { documents.appendingPathComponent("Current.terra") }
  private var libraryURL: URL { documents.appendingPathComponent("Library.json") }

  init(documents: URL = .documentsDirectory) {
    self.documents = documents
    do {
      if FileManager.default.fileExists(atPath: autosaveURL.path) {
        let restored = try JSONDecoder().decode(Terrain.self, from: Data(contentsOf: autosaveURL))
        guard restored.isValid else { throw CocoaError(.fileReadCorruptFile) }
        terrain = restored
        status = "Current landscape restored"
      }
      if FileManager.default.fileExists(atPath: libraryURL.path) {
        saved = try JSONDecoder().decode([SavedWorld].self, from: Data(contentsOf: libraryURL))
        guard saved.allSatisfy({ $0.terrain.isValid }) else {
          saved = []
          throw CocoaError(.fileReadCorruptFile)
        }
      }
    } catch {
      self.error =
        "The saved file could not be read. A fresh island is ready; the file was not deleted."
    }
  }

  var journeyChapter: JourneyChapter {
    LandscapeJourney.chapters[LandscapeJourney.chapterIndex(at: journeyTime)]
  }

  func startJourney() {
    guard !journeyActive else { return }
    end()
    journeyOriginal = terrain
    journeyOriginalContours = contours
    journeyOriginalZoom = zoom
    journeyActive = true
    seekJourney(to: 0)
    if !reducedMotion { playJourney() }
  }

  func seekJourney(to time: Double) {
    guard journeyActive else { return }
    journeyTime = LandscapeJourney.boundedTime(time)
    journeyFrame = LandscapeJourney.frame(at: journeyTime)
    terrain = journeyFrame.terrain
    revision += 1
    status = "Live landscape study · \(journeyChapter.label)"
    if journeyTime == LandscapeJourney.duration { pauseJourney() }
  }

  func playJourney() {
    guard journeyActive, !journeyPlaying else { return }
    if journeyTime >= LandscapeJourney.duration { seekJourney(to: 0) }
    journeyPlaying = true
    journeyTask = Task { @MainActor [weak self] in
      let clock = ContinuousClock()
      var previous = clock.now
      while !Task.isCancelled {
        do {
          try await Task.sleep(for: .milliseconds(50))
        } catch {
          return
        }
        let now = clock.now
        let elapsed = previous.duration(to: now).components
        previous = now
        guard let self, self.journeyPlaying else { return }
        let delta = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
        self.seekJourney(to: self.journeyTime + min(0.25, delta))
      }
    }
  }

  func pauseJourney() {
    journeyTask?.cancel()
    journeyTask = nil
    journeyPlaying = false
  }

  func finishJourney(keep: Bool) {
    guard let original = journeyOriginal else { return }
    pauseJourney()
    journeyActive = false
    journeyOriginal = nil
    contours = journeyOriginalContours
    zoom = journeyOriginalZoom
    if keep {
      history.record(original, after: terrain)
      status = "Study landscape kept · undo to return"
    } else {
      terrain = original
      status = "Your landscape restored"
    }
    revision += 1
    homeRevision += 1
    persist()
  }

  func begin() {
    end()
    transaction = terrain
  }

  func end() {
    guard let before = transaction else { return }
    history.record(before, after: terrain)
    transaction = nil
    persist()
  }

  func sculpt(x: Float, z: Float) {
    terrain.apply(brush, x: x, z: z, radius: radius, strength: strength)
    revision += 1
    status = "\(brush.rawValue) stroke applied"
  }

  func setWater(_ value: Float) {
    let standalone = transaction == nil
    if standalone { begin() }
    terrain.water = max(0, min(0.85, value))
    revision += 1
    status = "Waterline at \(Int(terrain.water * 1000)) m"
    if standalone {
      end()
    } else {
      persist()
    }
  }

  func preset(_ landscape: Landscape) {
    begin()
    terrain = Terrain(landscape: landscape)
    revision += 1
    end()
    status = "\(landscape.rawValue) loaded · undo to return"
  }

  func undo() {
    end()
    if let restored = history.undo(terrain) {
      terrain = restored
      revision += 1
      persist()
      status = "Last change undone"
    }
  }

  func redo() {
    end()
    if let restored = history.redo(terrain) {
      terrain = restored
      revision += 1
      persist()
      status = "Change restored"
    }
  }

  func persist() {
    do {
      try JSONEncoder().encode(journeyOriginal ?? terrain).write(
        to: autosaveURL, options: .atomic)
    } catch {
      self.error = "Could not save this landscape: \(error.localizedDescription)"
    }
  }

  func save() {
    end()
    let world = SavedWorld(terrain: terrain)
    let next = [world] + saved
    do {
      try JSONEncoder().encode(next).write(to: libraryURL, options: .atomic)
      saved = next
      persist()
      status = "Snapshot saved to Library"
    } catch {
      self.error = "Could not save snapshot: \(error.localizedDescription)"
    }
  }

  func reopen(_ world: SavedWorld) {
    begin()
    terrain = world.terrain
    revision += 1
    end()
    status = "Reopened \(world.terrain.title)"
  }

  func exportMesh() -> URL? {
    do {
      let directory = documents.appendingPathComponent("Exports")
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      let url = directory.appendingPathComponent("TerraTable.obj")
      try terrain.obj().write(to: url, atomically: true, encoding: .utf8)
      status = "Mesh exported · 6,561 vertices / 12,800 faces"
      return url
    } catch {
      self.error = "Export failed: \(error.localizedDescription)"
      return nil
    }
  }
}
