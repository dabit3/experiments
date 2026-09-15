import ImageIO
import SwiftUI
import UIKit

struct SamplePhoto: Identifiable {
  let id: String
  let title: String
  let subtitle: String
  let url: URL?
  let dimensions: String
  let isImported: Bool

  static let all = [
    SamplePhoto(
      id: "dunes", title: "The quiet earth", subtitle: "NAMIB · LAST LIGHT",
      url: Bundle.main.url(forResource: "dunes", withExtension: "jpg"),
      dimensions: "1024 × 1536", isImported: false),
    SamplePhoto(
      id: "coast", title: "Where the tide turns", subtitle: "PACIFIC · GOLDEN HOUR",
      url: Bundle.main.url(forResource: "coast", withExtension: "jpg"),
      dimensions: "1024 × 1536", isImported: false),
    SamplePhoto(
      id: "bloom", title: "A study in stillness", subtitle: "STUDIO · WINDOW LIGHT",
      url: Bundle.main.url(forResource: "bloom", withExtension: "jpg"),
      dimensions: "1024 × 1536", isImported: false),
  ]
}

struct ExportedPhoto: Identifiable {
  let id = UUID()
  let url: URL
  let image: UIImage
  let width: Int
  let height: Int
  let bytes: Int
  let format: OutputFormat
}

@MainActor
final class EditorStore: ObservableObject {
  @Published private(set) var project = Project()
  @Published var draft = Edit()
  @Published var preview: UIImage?
  @Published var comparison: UIImage?
  @Published var histogram: Histogram?
  @Published var exporting = false
  @Published var importing = false
  @Published var rendering = false
  @Published var previewUnavailable = false
  @Published var exported: ExportedPhoto?
  @Published var error: String?
  @Published var thumbnails: [FilmLook: UIImage] = [:]
  @Published var libraryImages: [String: UIImage] = [:]
  @Published var copiedEdit: Edit?
  @Published var notice: String?
  private var generation = 0
  private var libraryGeneration = 0
  private var renderTask: Task<Void, Never>?
  private var noticeTask: Task<Void, Never>?
  private let fileURL: URL
  private var saveFailed = false
  private var comparisonKey: Edit?
  private var loadFailed = false

  var photos: [SamplePhoto] {
    SamplePhoto.all
      + project.imports.map {
        SamplePhoto(
          id: $0.id, title: $0.title, subtitle: "YOUR ORIGINAL · LOCAL LIBRARY",
          url: directory.appendingPathComponent("Originals/\($0.fileName)"),
          dimensions: "\($0.width) × \($0.height)", isImported: true)
      }
  }
  var directory: URL { fileURL.deletingLastPathComponent() }
  var photo: SamplePhoto {
    photos.first { $0.id == project.selectedID } ?? SamplePhoto.all[0]
  }
  var history: EditHistory { project.photos[photo.id] ?? EditHistory() }
  var isEdited: Bool { draft != Edit() }
  var isFavorite: Bool { project.favorites.contains(photo.id) }
  var status: String {
    if saveFailed || loadFailed { return "Not saved" }
    return draft != history.current ? "Adjusting" : (isEdited ? "All changes saved" : "Original")
  }

  init() {
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    fileURL = documents.appendingPathComponent("Afterglow/project.json")
    if FileManager.default.fileExists(atPath: fileURL.path) {
      do {
        project = try ProjectFile.load(from: fileURL)
      } catch {
        loadFailed = true
        self.error =
          "The saved library could not be read. It has been preserved on disk. "
          + "You can explore the samples and export, but changes will not overwrite this file."
      }
    }
    draft = history.current.sanitized()
    render()
    makeThumbnails()
    refreshLibrary()
  }

  func select(_ photo: SamplePhoto) {
    guard photo.id != self.photo.id else { return }
    commit()
    project.selectedID = photo.id
    draft = history.current.sanitized()
    preview = nil
    previewUnavailable = false
    comparison = nil
    comparisonKey = nil
    persist()
    render()
    makeThumbnails()
  }

  func change(_ update: (inout Edit) -> Void) {
    update(&draft)
    draft = draft.sanitized()
    commit()
  }

  func commit() {
    var updated = history
    updated.apply(draft)
    project.photos[photo.id] = updated
    draft = updated.current
    persist()
    render()
  }

  func undo() {
    var updated = history
    updated.undo()
    setHistory(updated)
  }

  func redo() {
    var updated = history
    updated.redo()
    setHistory(updated)
  }

  private func setHistory(_ history: EditHistory) {
    project.photos[photo.id] = history
    draft = history.current
    persist()
    render()
  }

  func toggleFavorite(_ id: String) {
    if project.favorites.contains(id) {
      project.favorites.remove(id)
    } else {
      project.favorites.insert(id)
    }
    persist()
  }

  func copyEdits() {
    copiedEdit = draft
    announce("Color & light copied")
  }

  func pasteEdits() {
    guard var value = copiedEdit else { return }
    value.crop = draft.crop
    value.rotation = draft.rotation
    value.zoom = draft.zoom
    value.panX = draft.panX
    value.panY = draft.panY
    change { $0 = value }
    announce("Color & light applied")
  }

  func announce(_ text: String) {
    noticeTask?.cancel()
    notice = text
    noticeTask = Task {
      try? await Task.sleep(for: .seconds(2))
      guard !Task.isCancelled else { return }
      notice = nil
    }
  }

  private func persist() {
    guard !loadFailed else { return }
    do {
      try ProjectFile.save(project, to: fileURL)
      saveFailed = false
    } catch {
      saveFailed = true
      self.error =
        "Your edit is still on screen, but could not be saved: \(error.localizedDescription)"
    }
  }

  func importFile(_ url: URL) async {
    let accessible = url.startAccessingSecurityScopedResource()
    defer { if accessible { url.stopAccessingSecurityScopedResource() } }
    do {
      let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
      guard size <= 80_000_000 else { throw ImportError.unsupported }
      let data = try await Task.detached { try Data(contentsOf: url) }.value
      await importData(data, title: url.deletingPathExtension().lastPathComponent)
    } catch { self.error = error.localizedDescription }
  }

  func importData(_ data: Data, title: String) async {
    guard !loadFailed else {
      error = "Resolve the unreadable saved library before importing."
      return
    }
    importing = true
    defer { importing = false }
    do {
      let folder = directory.appendingPathComponent("Originals")
      let record = try await Task.detached {
        let record = try PhotoImport.inspect(data, title: title)
        let url = folder.appendingPathComponent(record.fileName)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        do {
          _ = try PhotoRenderer.render(url: url, edit: Edit(), maxDimension: 400)
        } catch {
          try? FileManager.default.removeItem(at: url)
          throw error
        }
        return record
      }.value
      project.imports.append(record)
      persist()
      refreshLibrary()
      announce("Original added to your library")
    } catch { self.error = error.localizedDescription }
  }

  func render() {
    guard let url = photo.url else { return }
    renderTask?.cancel()
    generation += 1
    let ticket = generation
    let edit = draft
    let id = photo.id
    var geometry = Edit()
    geometry.crop = edit.crop
    geometry.rotation = edit.rotation
    geometry.zoom = edit.zoom
    geometry.panX = edit.panX
    geometry.panY = edit.panY
    let needsComparison = comparisonKey != geometry
    let neutral = geometry
    rendering = true
    renderTask = Task {
      try? await Task.sleep(for: .milliseconds(25))
      guard !Task.isCancelled else { return }
      let result = await Task.detached(priority: .userInitiated) {
        Result {
          let image = try PhotoRenderer.render(url: url, edit: edit, maxDimension: 1400)
          let original =
            needsComparison
            ? try PhotoRenderer.render(url: url, edit: neutral, maxDimension: 1400) : nil
          return (image, original, Histogram.measure(image))
        }
      }.value
      guard ticket == generation, !Task.isCancelled else { return }
      rendering = false
      switch result {
      case .success(let (image, original, distribution)):
        previewUnavailable = false
        preview = UIImage(cgImage: image)
        libraryImages[id] = preview
        histogram = distribution
        if let original {
          comparison = UIImage(cgImage: original)
          comparisonKey = neutral
        }
      case .failure(let failure):
        previewUnavailable = true
        error = failure.localizedDescription
      }
    }
  }

  private func makeThumbnails() {
    guard let url = photo.url else { return }
    let selected = photo.id
    thumbnails = [:]
    Task {
      let images = await Task.detached(priority: .utility) {
        FilmLook.allCases.compactMap { look -> (FilmLook, CGImage)? in
          var edit = Edit()
          edit.look = look
          guard let image = try? PhotoRenderer.render(url: url, edit: edit, maxDimension: 180)
          else { return nil }
          return (look, image)
        }
      }.value
      guard selected == photo.id else { return }
      thumbnails = Dictionary(uniqueKeysWithValues: images.map { ($0.0, UIImage(cgImage: $0.1)) })
    }
  }

  func refreshLibrary() {
    libraryGeneration += 1
    let ticket = libraryGeneration
    let items = photos
    let histories = project.photos
    Task {
      for item in items {
        guard let url = item.url else { continue }
        let edit = histories[item.id]?.current ?? Edit()
        let image = await Task.detached(priority: .utility) {
          try? PhotoRenderer.render(url: url, edit: edit, maxDimension: 650)
        }.value
        guard ticket == libraryGeneration else { return }
        guard (project.photos[item.id]?.current ?? Edit()) == edit else { continue }
        if let image { libraryImages[item.id] = UIImage(cgImage: image) }
      }
    }
  }

  func export(format: OutputFormat, size: OutputSize, quality: Double) {
    guard !exporting else { return }
    commit()
    guard let source = photo.url else { return }
    exporting = true
    let edit = draft
    let url = directory.appendingPathComponent("Exports")
      .appendingPathComponent(
        "Afterglow-\(photo.id)-\(UUID().uuidString.prefix(8)).\(format.fileExtension)")
    Task {
      let result = await Task.detached(priority: .userInitiated) {
        Result {
          let image = try PhotoRenderer.render(
            url: source, edit: edit, maxDimension: size.maxDimension)
          try PhotoRenderer.export(image: image, to: url, format: format, quality: quality)
          let preview = try PhotoRenderer.render(url: source, edit: edit, maxDimension: 900)
          return (preview, image.width, image.height, try Data(contentsOf: url).count)
        }
      }.value
      exporting = false
      switch result {
      case .success(let (image, width, height, count)):
        exported = ExportedPhoto(
          url: url, image: UIImage(cgImage: image),
          width: width, height: height, bytes: count, format: format)
      case .failure(let failure): error = failure.localizedDescription
      }
    }
  }
}
