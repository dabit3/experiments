import AppKit
import SwiftUI
import Combine
import AVFoundation
import PDFKit
import UniformTypeIdentifiers
import DevinCore

enum DrawingTool: String, CaseIterable {
    case select, directSelect, marquee, ellipseSelect, lasso, rectangle, ellipse, text, brush, eraser, line, crop, pen, eyedropper, hand, zoom
    case singleRow, singleColumn, polygonLasso, selectionBrush, magicWand, pencil, cloneStamp, healingBrush, patternStamp, historyBrush, backgroundEraser, magicEraser, gradient, paintBucket, blur, sharpen, dodge, burn, sponge, colorReplacement, roundedRectangle, polygon, colorSampler, ruler, addAnchor, deleteAnchor, convertAnchor, freeformPen
    var symbol: String {
        switch self {
        case .select: return "cursorarrow"
        case .directSelect: return "cursorarrow.rays"
        case .marquee: return "rectangle.dashed"
        case .ellipseSelect: return "circle.dashed"
        case .lasso: return "lasso"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .text: return "textformat"
        case .brush: return "paintbrush.pointed"
        case .eraser: return "eraser"
        case .line: return "line.diagonal"
        case .crop: return "crop"
        case .pen, .freeformPen: return "pencil.tip.crop.circle"
        case .eyedropper: return "eyedropper"
        case .hand: return "hand.draw"
        case .zoom: return "magnifyingglass"
        case .singleRow: return "rectangle.split.1x2"
        case .singleColumn: return "rectangle.split.2x1"
        case .polygonLasso: return "point.topleft.down.curvedto.point.bottomright.up"
        case .selectionBrush: return "paintbrush.pointed"
        case .magicWand: return "wand.and.stars"
        case .pencil: return "pencil"
        case .cloneStamp, .patternStamp: return "seal.fill"
        case .healingBrush: return "bandage"
        case .historyBrush: return "clock.arrow.circlepath"
        case .backgroundEraser, .magicEraser: return "eraser"
        case .gradient: return "rectangle.lefthalf.filled"
        case .paintBucket: return "drop.fill"
        case .blur: return "drop"
        case .sharpen: return "triangle"
        case .dodge: return "circle.lefthalf.filled"
        case .burn: return "flame"
        case .sponge: return "circle.dotted"
        case .colorReplacement: return "paintpalette"
        case .roundedRectangle: return "rectangle.roundedtop"
        case .polygon: return "pentagon"
        case .colorSampler: return "scope"
        case .ruler: return "ruler"
        case .addAnchor: return "plus.circle"
        case .deleteAnchor: return "minus.circle"
        case .convertAnchor: return "point.topleft.down.curvedto.point.bottomright.up"
        }
    }
    var title: String {
        switch self { case .select: return "Move / Selection"; case .directSelect: return "Direct Selection"; case .marquee: return "Rectangular Marquee"; case .ellipseSelect: return "Elliptical Marquee"; case .polygonLasso: return "Polygonal Lasso"; default: return rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).capitalized }
    }
    var shortcut: String {
        switch self {
        case .select: return "V"; case .directSelect: return "A"; case .marquee: return "M"; case .rectangle: return "U"
        case .ellipse: return "O"; case .text: return "T"; case .brush: return "B"; case .eraser: return "E"
        case .ellipseSelect: return "M"; case .lasso: return "L"
        case .line: return "\\"; case .crop: return "C"; case .pen, .freeformPen: return "P"; case .eyedropper: return "I"; case .hand: return "H"; case .zoom: return "Z"
        case .singleRow, .singleColumn: return "M"
        case .polygonLasso: return "L"
        case .selectionBrush: return ""
        case .magicWand: return "W"
        case .pencil, .colorReplacement: return "B"
        case .cloneStamp, .patternStamp: return "S"
        case .healingBrush: return "J"
        case .historyBrush: return "Y"
        case .backgroundEraser, .magicEraser: return "E"
        case .gradient, .paintBucket: return "G"
        case .blur, .sharpen: return ""
        case .dodge, .burn, .sponge: return "O"
        case .roundedRectangle, .polygon: return "U"
        case .colorSampler, .ruler: return "I"
        case .addAnchor, .deleteAnchor, .convertAnchor: return ""
        }
    }
}

final class StudioSession: ObservableObject {
    let id = UUID()
    weak var workspace: DocumentWorkspace?
    var needsInitialSave = false
    var freeformRevision = 0
    @Published var document: CreativeDocument {
        didSet { isDirty = needsInitialSave || document != savedDocument; freeformRevision &+= 1 }
    }
    @Published var isDirty = false
    @Published var selectedID: UUID? {
        didSet { if selectedID != oldValue { freeformRevision &+= 1 } }
    }
    @Published var page = 0 {
        didSet {
            if page != oldValue { selectedID = nil; additionalSelection.removeAll(); selectionRect = nil; editingMask = false; freeformRevision &+= 1 }
        }
    }
    @Published var drawingTool: DrawingTool = .select {
        didSet { if drawingTool != oldValue { freeformRevision &+= 1 } }
    }
    @Published private var freeformFit = FreeformPathStroke.defaultCurveFit
    var freeformCurveFit: Double {
        get { freeformFit }
        set {
            let value = FreeformPathStroke.clampedCurveFit(newValue)
            if value != freeformFit { freeformRevision &+= 1; freeformFit = value }
        }
    }
    @Published var pixelToolMemory: [String: DrawingTool] = [:]
    @Published var drawingColor = "B5E7C9"
    @Published var brushSize = 12.0
    @Published var brushOpacity = 1.0
    @Published var brushHardness = 1.0
    @Published var editingMask = false
    @Published var pixelSettings = PixelRasterSettings()
    @Published var cloneSource: PixelCloneSource?
    var cloneOffset: CGPoint?
    @Published var patternSource: CanvasElement?
    @Published var historyPaintSource: CanvasElement?
    @Published var colorSamples: [PixelColorSample] = []
    @Published var measurement: (start: CGPoint, end: CGPoint)?
    @Published var selectionMode: SelectionCombineMode = .replace
    @Published var selectionPath: CGPath?
    @Published var backgroundColor = "FFFFFF"
    @Published var selectionRect: CGRect? { didSet { selectionPath = nil } }
    @Published var additionalSelection = Set<UUID>()
    @Published var showRulers = true
    @Published var showGuides = true
    @Published var panelsHidden = false
    @Published var channelPreview: String?
    @Published var autoSelect = true
    @Published var showTransformControls = true
    @Published var canvasScale = 1.0
    @Published var workspacePreset = "Essentials"
    @Published var codeLanguage = "HTML"
    @Published var showFeatureInventory = false
    @Published var copiedAdjustments: ImageAdjustments?
    @Published var zoom = 1.0
    @Published var showGrid = false
    @Published var onionSkin = false
    @Published var playhead = 0.0
    @Published var isPlaying = false
    @Published var showExport = false
    @Published var showNew = false
    @Published var error: String?
    @Published var message: String?
    @Published var busy = false
    @Published var progress = 0.0
    @Published var history = History<CreativeDocument>()
    @Published var fileURL: URL?
    @Published var exportTask: Task<Void, Never>?
    var savedDocument: CreativeDocument
    var transaction: CreativeDocument?
    var player = AVPlayer()
    var lastExportURL: URL?
    var captureSceneCamera: (() -> SceneCamera?)?

    init(tool: StudioTool, document: CreativeDocument? = nil) {
        var initial = document ?? Samples.document(for: tool)
        if [.lens, .pixel].contains(tool), document == nil, let image = Renderer.image(initial) {
            var layer = CanvasElement(kind: .image, name: tool == .pixel ? "Sample artwork · editable pixels" : "Landscape study · generated sample", x: 0, y: 0, width: initial.width, height: initial.height)
            layer.imageData = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
            initial.elements = [layer]
        }
        self.document = initial; self.savedDocument = initial
        self.selectedID = initial.elements.last(where: { $0.page == 0 })?.id ?? initial.objects.first?.id ?? initial.clips.first?.id
        if tool == .motion, document == nil { self.playhead = 1.5 }
        if tool == .motion { workspacePreset = "Default" }
        if tool == .cut { workspacePreset = "Editing" }
        if [.pixel, .form, .press].contains(tool) { drawingColor = "000000" }
    }
    var tool: StudioTool { document.tool }
    var selected: CanvasElement? { document.elements.first { $0.id == selectedID } }
    var currentElements: [CanvasElement] { document.elements.filter { $0.page == page } }
    func mutate(_ body: (inout CreativeDocument) -> Void) {
        let previous = document
        var updated = previous
        body(&updated)
        if updated.duration != previous.duration, let area = updated.workArea {
            let end = min(updated.duration, area.end)
            updated.workArea = WorkArea(start: min(area.start, max(0, end - 1 / Double(updated.fps))), end: end)
            playhead = min(playhead, updated.playbackArea.lastFrame(fps: updated.fps))
        }
        document = updated
        history.record(previous, replacing: updated)
    }
    var editableSelection: CanvasElement? {
        guard var element = selected else { return nil }
        if tool == .motion {
            let pose = element.evaluated(at: playhead)
            element.x = pose.x; element.y = pose.y; element.rotation = pose.rotation; element.opacity = pose.opacity
        }
        return element
    }
    func updateElement(_ id: UUID? = nil, recordHistory: Bool = true, _ body: (inout CanvasElement) -> Void) {
        guard let index = document.elements.firstIndex(where: { $0.id == (id ?? selectedID) }) else { return }
        let original = document.elements[index]
        var updated = original
        let animated = tool == .motion && original.hasAnimation
        let pose = animated ? original.evaluated(at: playhead) : original
        updated.x = pose.x; updated.y = pose.y; updated.rotation = pose.rotation; updated.opacity = pose.opacity
        body(&updated)
        if original.locked {
            var allowed = original
            allowed.locked = updated.locked; allowed.visible = updated.visible; allowed.name = updated.name
            if recordHistory { mutate { $0.elements[index] = allowed } } else { document.elements[index] = allowed }
            return
        }
        if animated {
            let changes: [(AnimationProperty, Double, Double)] = [(.positionX, updated.x, pose.x), (.positionY, updated.y, pose.y), (.rotation, updated.rotation, pose.rotation), (.opacity, updated.opacity, pose.opacity)]
            updated.x = original.x; updated.y = original.y; updated.rotation = original.rotation; updated.opacity = original.opacity
            for (property, value, previous) in changes where value != previous {
                if updated.effectiveAnimationChannels.contains(where: { $0.property == property }) { updated.setPropertyKeyframe(property, at: playhead, value: value, tolerance: 0.5 / Double(document.fps)) }
                else { updated.setBaseValue(value, for: property) }
            }
        }
        if recordHistory { mutate { $0.elements[index] = updated } }
        else { document.elements[index] = updated }
    }
    func beginTransaction() { transaction = document }
    func endTransaction() {
        if let previous = transaction { history.record(previous, replacing: document) }
        transaction = nil
    }
    func undo() {
        freeformRevision &+= 1
        if let previous = history.undo(document) { document = previous; sanitizeSelection() }
    }
    func redo() {
        freeformRevision &+= 1
        if let next = history.redo(document) { document = next; sanitizeSelection() }
    }
    func sanitizeSelection() {
        let count = tool == .folio ? (document.pdfData.flatMap { PDFDocument(data: $0)?.pageCount } ?? 1) : document.pageCount
        page = min(page, max(0, count - 1))
        if selected?.maskData == nil { editingMask = false }
        additionalSelection.formIntersection(Set(document.elements.map(\.id)))
        if let id = selectedID, !document.elements.contains(where: { $0.id == id }) && !document.clips.contains(where: { $0.id == id }) && !document.objects.contains(where: { $0.id == id }) { selectedID = nil }
    }
    func duplicate() {
        var layers = currentElements.filter { selectedIDs.contains($0.id) }
        guard !layers.isEmpty else { return }
        for i in layers.indices { layers[i].name += " copy" }
        var updated = document
        do {
            let ids = try updated.insertLayers(layers, page: page, offset: tool == .pixel || tool == .motion ? 0 : 24)
            mutate { $0 = updated }; select(ids.last); additionalSelection = Set(ids.dropLast())
        } catch { self.error = error.localizedDescription }
    }
    func deleteSelection() {
        let ids = selectedIDs
        guard !ids.isEmpty else { return }
        mutate { d in
            let removed = Set(d.elements.filter { ids.contains($0.id) && !$0.locked }.map(\.id))
            d.elements.removeAll { removed.contains($0.id) }
            for i in d.elements.indices where d.elements[i].nextTextFrame.map(removed.contains) == true { d.elements[i].nextTextFrame = nil }
            d.clips.removeAll { ids.contains($0.id) }
            d.objects.removeAll { ids.contains($0.id) }
        }
        selectedID = nil; additionalSelection.removeAll()
    }
    func reorder(_ id: UUID, offset: Int) {
        guard let index = document.elements.firstIndex(where: { $0.id == id }) else { return }
        let indices = document.elements.indices.filter { document.elements[$0].page == document.elements[index].page }
        guard let position = indices.firstIndex(of: index), indices.indices.contains(position + offset) else { return }
        let destination = indices[position + offset]
        mutate { $0.elements.swapAt(index, destination) }
    }
    func addPage(duplicate: Bool = false) {
        let newPage = document.pageCount
        guard newPage < 1000 else { error = "A project can contain at most 1,000 pages."; return }
        var copies = duplicate ? currentElements : []
        let identifiers = Dictionary(uniqueKeysWithValues: copies.map { ($0.id, UUID()) })
        for i in copies.indices {
            copies[i].id = identifiers[copies[i].id]!
            copies[i].page = newPage
            copies[i].nextTextFrame = copies[i].nextTextFrame.flatMap { identifiers[$0] }
        }
        mutate { $0.pageCount += 1; $0.elements.append(contentsOf: copies) }
        page = newPage; selectedID = nil
    }
    func deletePage() {
        guard document.pageCount > 1 else { return }
        let index = page
        mutate { d in
            let removed = Set(d.elements.filter { $0.page == index }.map(\.id))
            d.elements.removeAll { removed.contains($0.id) }
            for i in d.elements.indices {
                if d.elements[i].page > index { d.elements[i].page -= 1 }
                if d.elements[i].nextTextFrame.map(removed.contains) == true { d.elements[i].nextTextFrame = nil }
            }
            d.pageCount -= 1
        }
        sanitizeSelection()
    }
    func addKeyframe() {
        guard let layer = selected, !layer.locked, let index = document.elements.firstIndex(where: { $0.id == layer.id }) else { return }
        let time = playhead
        let values = AnimationProperty.allCases.map { ($0, layer.animationValue($0, at: time)) }
        mutate { d in for (property, value) in values { d.elements[index].setPropertyKeyframe(property, at: time, value: value, tolerance: 0.5 / Double(d.fps)) } }
    }
    func save(as saveAs: Bool = false) -> Bool {
        var destination = fileURL
        if saveAs || destination == nil {
            let panel = NSSavePanel()
            panel.title = "Save Devin project"
            panel.allowedContentTypes = [UTType(filenameExtension: "devin") ?? .json]
            panel.nameFieldStringValue = document.title + ".devin"
            guard panel.runModal() == .OK, let url = panel.url else { return false }
            destination = url
        }
        guard let destination else { return false }
        do {
            let data = try document.encoded()
            guard data.count <= 512_000_000 else { throw DocumentError.invalid("This project exceeds the 512 MB limit. Reduce the embedded image sizes before saving.") }
            try data.write(to: destination, options: .atomic)
            fileURL = destination; savedDocument = document; needsInitialSave = false; isDirty = false
            RecentProjects.add(destination, tool: tool, title: document.title)
            message = "Project saved"
            return true
        } catch { self.error = error.localizedDescription; return false }
    }
    func confirmDiscard() -> Bool {
        guard isDirty else { return true }
        let alert = NSAlert()
        alert.messageText = "Save changes to “\(document.title)”?"
        alert.informativeText = "Your changes will be lost if you do not save them."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Don’t Save")
        switch alert.runModal() {
        case .alertFirstButtonReturn: return save()
        case .alertThirdButtonReturn: return true
        default: return false
        }
    }
    static func importTypes(for tool: StudioTool) -> [UTType] {
        switch tool {
        case .cut: return [.movie, .audio]
        case .sound: return [.audio]
        case .folio: return [.pdf]
        case .code: return [.html, UTType(filenameExtension: "css") ?? .plainText, UTType(filenameExtension: "js") ?? .sourceCode, .plainText]
        case .space: return []
        default: return [.image]
        }
    }
    func importFiles() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        guard tool != .space else { return }
        panel.allowsMultipleSelection = tool != .folio
        panel.allowedContentTypes = Self.importTypes(for: tool)
        guard panel.runModal() == .OK else { return }
        importURLs(panel.urls)
    }
    func importURLs(_ urls: [URL]) {
        if tool == .cut || tool == .sound {
            busy = true
            Task { @MainActor in
                defer { busy = false }
                do {
                    var clips: [MediaClip] = []
                    var assets: [MediaAsset] = []
                    for url in urls {
                        let asset = AVURLAsset(url: url)
                        let duration = try await asset.load(.duration).seconds
                        guard duration.isFinite, duration > 0, duration <= 86400 else { throw DocumentError.invalid("The media file has no playable duration.") }
                        let hasVideo = try await !asset.loadTracks(withMediaType: .video).isEmpty
                        assets.append(MediaAsset(url: url, duration: duration, hasVideo: hasVideo))
                        clips.append(MediaClip(url: url, duration: duration))
                    }
                    if tool == .cut {
                        let existing = document.mediaAssets
                        mutate { $0.assets = existing + assets }
                        selectedID = assets.last?.id
                    } else {
                        mutate { $0.clips.append(contentsOf: clips) }
                        selectedID = clips.first?.id
                    }
                } catch { self.error = error.localizedDescription }
            }
            return
        }
        do {
            switch tool {
            case .folio:
                guard let url = urls.first, let pdf = PDFDocument(url: url), !pdf.isLocked else { throw DocumentError.invalid("Open an unlocked, readable PDF file.") }
                guard let data = pdf.dataRepresentation() else { throw DocumentError.invalid("The PDF could not be read.") }
                mutate { $0.pdfData = data; $0.title = url.deletingPathExtension().lastPathComponent }; page = 0
            case .code:
                var updated = document
                for url in urls {
                    let text = try String(contentsOf: url, encoding: .utf8)
                    switch url.pathExtension.lowercased() {
                    case "css": updated.css = text; codeLanguage = "CSS"
                    case "js", "mjs": updated.javascript = text; codeLanguage = "JavaScript"
                    default: updated.html = text; updated.title = url.deletingPathExtension().lastPathComponent; codeLanguage = "HTML"
                    }
                }
                mutate { $0 = updated }
            default:
                var layers: [CanvasElement] = []
                var nextPage = document.pageCount
                for url in urls {
                    guard let image = NSImage(contentsOf: url), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { throw DocumentError.invalid("\(url.lastPathComponent) is not a supported image.") }
                    guard cg.width <= 32768, cg.height <= 32768, cg.width * cg.height <= 120_000_000 else { throw DocumentError.invalid("The image is too large. Import an image below 120 megapixels.") }
                    let data = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])
                    let scale = min(document.width / Double(cg.width), document.height / Double(cg.height), 1)
                    let w = Double(cg.width) * scale, h = Double(cg.height) * scale
                    var element = CanvasElement(kind: .image, name: url.lastPathComponent, x: (document.width-w)/2, y: (document.height-h)/2, width: w, height: h, page: page)
                    element.imageData = data
                    if tool == .lens || (tool == .frame && urls.count > 1) {
                        if document.elements.isEmpty && document.pageCount == 1 && layers.isEmpty { element.page = 0 }
                        else { element.page = nextPage; nextPage += 1 }
                    }
                    if tool == .batch { element.page = 0; element.width = Double(cg.width); element.height = Double(cg.height) }
                    layers.append(element)
                }
                mutate { $0.elements.append(contentsOf: layers); $0.pageCount = nextPage }
                if let last = layers.last { page = last.page; select(last.id) }
            }
        } catch { self.error = error.localizedDescription }
    }
    func showInFinder() { if let url = lastExportURL { NSWorkspace.shared.activateFileViewerSelecting([url]) } }
}

struct RecentProject: Codable, Identifiable {
    var id: String { url.path }
    let url: URL
    let title: String
    let tool: StudioTool
    let date: Date
}

enum RecentProjects {
    static let key = "devin.recentProjects"
    static var all: [RecentProject] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([RecentProject].self, from: data)) ?? []
    }
    static func add(_ url: URL, tool: StudioTool, title: String) {
        var items = all.filter { $0.url != url }
        items.insert(RecentProject(url: url, title: title, tool: tool, date: Date()), at: 0)
        if let data = try? JSONEncoder().encode(Array(items.prefix(12))) { UserDefaults.standard.set(data, forKey: key) }
    }
}
