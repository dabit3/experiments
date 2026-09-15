import AppKit
import SwiftUI
import DevinCore

extension StudioSession {
    var usesProfessionalWorkspace: Bool { [.pixel, .form, .cut, .press, .motion].contains(tool) }
    var selectedIDs: Set<UUID> { additionalSelection.union(selectedID.map { [$0] } ?? []) }
    func select(_ id: UUID?, extending: Bool = false) {
        if extending, let previous = selectedID { additionalSelection.insert(previous) }
        else { additionalSelection.removeAll() }
        if selectedID != id { editingMask = false }
        selectedID = id
    }
    func elementBinding<T>(_ path: WritableKeyPath<CanvasElement, T>, _ fallback: T) -> Binding<T> {
        Binding(get: { self.editableSelection?[keyPath: path] ?? fallback }, set: { value in self.updateElement { $0[keyPath: path] = value } })
    }
    func elementColor(_ path: WritableKeyPath<CanvasElement, String>) -> Binding<Color> {
        Binding(get: { Color(hex: self.selected?[keyPath: path] ?? "000000") }, set: { value in self.updateElement { $0[keyPath: path] = value.hex } })
    }
    func addElement(_ kind: ElementKind) {
        var layer = CanvasElement(kind: kind, name: kind == .text ? "Text" : "\(kind.rawValue.capitalized) \(document.elements.count + 1)", x: document.width * 0.25, y: document.height * 0.25, width: min(300, document.width * 0.5), height: min(200, document.height * 0.5), fill: drawingColor, page: page)
        if kind == .text { layer.text = "Your text here"; layer.fontSize = tool == .press ? 24 : 64; layer.typography = Typography() }
        if kind == .image {
            do { layer = try RasterEditing.paint(nil, document: document, points: [], size: 1, color: drawingColor, opacity: 1, erase: false, selection: nil); layer.page = page }
            catch { self.error = error.localizedDescription; return }
        }
        mutate { $0.elements.append(layer) }; select(layer.id)
    }
    func addMask() {
        guard let layer = selected, layer.kind == .image, !layer.locked else { return }
        guard let data = RasterEditing.selectionMask(selectionRect, layer: layer, path: effectiveSelectionPath) else { error = "The layer mask could not be created."; return }
        updateElement { $0.maskData = data; $0.maskEnabled = true; $0.maskInverted = false; $0.maskFeather = 0 }
        selectionRect = nil; editingMask = true
    }
    func rasterizeSelection() {
        guard let original = selected, original.kind != .image, !original.locked else { return }
        var document = CreativeDocument(title: "Rasterize", tool: .pixel)
        document.width = max(1, original.width); document.height = max(1, original.height)
        var element = original; element.x = 0; element.y = 0; element.rotation = 0; element.opacity = 1; element.blendMode = nil; element.page = 0
        document.elements = [element]
        guard let image = Renderer.image(document, transparent: true), let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { error = "The layer could not be rasterized."; return }
        mutate { d in
            guard let index = d.elements.firstIndex(where: { $0.id == original.id }) else { return }
            d.elements[index].kind = .image; d.elements[index].imageData = data; d.elements[index].vectorPath = nil; d.elements[index].points = []; d.elements[index].nextTextFrame = nil
            for i in d.elements.indices where d.elements[i].nextTextFrame == original.id { d.elements[i].nextTextFrame = nil }
        }
    }
    func flattenPage() {
        guard let image = Renderer.image(document, page: page), let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { return }
        var element = CanvasElement(kind: .image, name: "Background", x: 0, y: 0, width: document.width, height: document.height, page: page)
        element.imageData = data
        let page = self.page
        mutate { d in
            let removed = Set(d.elements.filter { $0.page == page }.map(\.id))
            d.elements.removeAll { removed.contains($0.id) }
            for i in d.elements.indices where d.elements[i].nextTextFrame.map(removed.contains) == true { d.elements[i].nextTextFrame = nil }
            d.elements.append(element)
        }
        select(element.id)
    }
    func combineShapes(_ operation: String) {
        let layers = currentElements.filter { selectedIDs.contains($0.id) && !$0.locked && [.rectangle, .ellipse, .path].contains($0.kind) }
        guard let first = layers.first, layers.count >= 2 else { message = "Shift-select at least two shape layers first."; return }
        var result = VectorGeometry.worldPath(first)
        for layer in layers.dropFirst() {
            let other = VectorGeometry.worldPath(layer)
            switch operation {
            case "Subtract": result = result.subtracting(other, using: .winding)
            case "Intersect": result = result.intersection(other, using: .winding)
            case "Exclude": result = result.symmetricDifference(other, using: .winding)
            default: result = result.union(other, using: .winding)
            }
        }
        guard !result.isEmpty else { message = "The selected operation produces an empty shape."; return }
        let element = VectorGeometry.element(from: result, name: operation, fill: first.fill, page: page)
        let ids = Set(layers.map(\.id))
        mutate { $0.elements.removeAll { ids.contains($0.id) }; $0.elements.append(element) }
        select(element.id)
    }
    func alignSelection(_ alignment: String) {
        let ids = selectedIDs
        let layers = currentElements.filter { ids.contains($0.id) && !$0.locked }
        guard !layers.isEmpty else { return }
        let minX = layers.count > 1 ? layers.map(\.x).min()! : 0
        let maxX = layers.count > 1 ? layers.map { $0.x + $0.width }.max()! : document.width
        let minY = layers.count > 1 ? layers.map(\.y).min()! : 0
        let maxY = layers.count > 1 ? layers.map { $0.y + $0.height }.max()! : document.height
        mutate { d in
            for i in d.elements.indices where ids.contains(d.elements[i].id) && !d.elements[i].locked {
                switch alignment {
                case "left": d.elements[i].x = minX
                case "right": d.elements[i].x = maxX - d.elements[i].width
                case "top": d.elements[i].y = minY
                case "bottom": d.elements[i].y = maxY - d.elements[i].height
                case "vertical": d.elements[i].y = (minY + maxY - d.elements[i].height) / 2
                default: d.elements[i].x = (minX + maxX - d.elements[i].width) / 2
                }
            }
        }
    }
    func linkText(to target: UUID?) {
        guard let id = selectedID, let index = document.elements.firstIndex(where: { $0.id == id }) else { return }
        var copy = document; copy.elements[index].nextTextFrame = target
        do { _ = try copy.validated(); mutate { $0 = copy } }
        catch { self.error = error.localizedDescription }
    }
    var storyBinding: Binding<String> {
        var id = selectedID
        var visited = Set<UUID>()
        while let current = id, visited.insert(current).inserted, let previous = document.elements.first(where: { $0.nextTextFrame == current }) { id = previous.id }
        let rootID = id
        return Binding(get: { self.document.elements.first { $0.id == rootID }?.text ?? "" }, set: { text in self.updateElement(rootID) { $0.text = text } })
    }
    func insertAsset(_ asset: MediaAsset, at time: Double? = nil, track: Int = 0, start: Double = 0, end: Double? = nil) {
        var clip = MediaClip(url: asset.url, duration: asset.duration)
        clip.name = asset.name; clip.start = max(0, start); clip.end = min(asset.duration, end ?? asset.duration)
        guard clip.end > clip.start else { return }
        clip.timelineStart = max(0, time ?? document.sequenceDuration); clip.trackIndex = track; clip.audioOnly = !asset.hasVideo
        mutate { $0.clips.append(clip) }; select(clip.id)
    }
    func splitSelectedClip() {
        guard let index = document.clips.firstIndex(where: { $0.id == selectedID }), let entry = SequenceLayout.entries(document.clips).first(where: { $0.id == selectedID }) else { return }
        do {
            let pieces = try SequenceLayout.split(entry.clip, at: playhead, position: entry.position)
            mutate { $0.clips[index] = pieces.0; $0.clips.insert(pieces.1, at: index + 1) }
            select(pieces.1.id)
        } catch { message = error.localizedDescription }
    }
    func setAnimationScale(_ scale: Double, layerID: UUID) { setAnimationValue(scale, property: .scale, layerID: layerID) }
    func setInterpolation(_ interpolation: Interpolation) {
        guard let id = selectedID, let index = document.elements.firstIndex(where: { $0.id == id && !$0.locked }) else { return }
        mutate { d in
            d.elements[index].migrateAnimationChannels()
            for c in d.elements[index].animationChannels!.indices { for k in d.elements[index].animationChannels![c].keyframes.indices { d.elements[index].animationChannels![c].keyframes[k].interpolation = interpolation } }
        }
    }
}
