import Foundation
import TerraCore
import Testing

@testable import TerraStudio

@Test @MainActor func journeyCancelPreservesOriginalAndHistory() throws {
  let directory = URL.cachesDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: directory) }
  let model = StudioModel(documents: directory)
  model.setWater(0.34)
  let original = model.terrain
  let undoCount = model.history.undoStack.count
  model.reducedMotion = true
  model.contours = true
  model.zoom = 1.3
  model.startJourney()
  #expect(!model.journeyPlaying)
  model.seekJourney(to: 43)
  #expect(model.terrain != original)
  model.persist()
  #expect(StudioModel(documents: directory).terrain == original)
  model.finishJourney(keep: false)
  #expect(model.terrain == original)
  #expect(model.history.undoStack.count == undoCount)
  #expect(model.contours)
  #expect(model.zoom == 1.3)
  #expect(!model.journeyActive)
}

@Test @MainActor func journeyKeepIsOneDurableUndoableChange() throws {
  let directory = URL.cachesDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: directory) }
  let model = StudioModel(documents: directory)
  let original = model.terrain
  model.startJourney()
  model.pauseJourney()
  model.seekJourney(to: 46)
  let kept = model.terrain
  model.finishJourney(keep: true)
  #expect(model.history.undoStack.count == 1)
  #expect(StudioModel(documents: directory).terrain == kept)
  model.undo()
  #expect(model.terrain == original)
  model.redo()
  #expect(model.terrain == kept)
  model.save()
  #expect(StudioModel(documents: directory).saved.first?.terrain == kept)
  let url = try #require(model.exportMesh())
  #expect(try String(contentsOf: url, encoding: .utf8) == kept.obj())
}

@Test @MainActor func journeyPlaybackCanPauseReplayAndRejectInvalidSeek() throws {
  let directory = URL.cachesDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: directory) }
  let model = StudioModel(documents: directory)
  model.startJourney()
  #expect(model.journeyPlaying)
  model.seekJourney(to: 900)
  #expect(model.journeyTime == LandscapeJourney.duration)
  #expect(!model.journeyPlaying)
  model.playJourney()
  #expect(model.journeyTime == 0)
  #expect(model.journeyPlaying)
  model.pauseJourney()
  model.seekJourney(to: .nan)
  #expect(model.journeyTime == 0)
  #expect(model.terrain.isValid)
  model.finishJourney(keep: false)
  model.playJourney()
  #expect(!model.journeyPlaying)
}
