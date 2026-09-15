import AppKit
import DevinCore

enum SelectionCombineMode: String, CaseIterable {
    case replace, add, subtract, intersect
    var title: String { rawValue.capitalized }
}

enum PaintTarget { case pixels, mask }

enum TransparencyGrid {
    static let image: CGImage? = {
        guard let context = CGContext(data: nil, width: 16, height: 16, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.setFillColor(NSColor(hex: "B8B8B8").cgColor); context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        context.setFillColor(NSColor(hex: "E2E2E2").cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8)); context.fill(CGRect(x: 8, y: 8, width: 8, height: 8))
        return context.makeImage()
    }()
}

struct LayerTransfer: Codable {
    var version = 1
    var layers: [CanvasElement]
}

extension StudioSession {
    var effectiveSelectionPath: CGPath? {
        selectionPath ?? selectionRect.map { CGPath(rect: $0, transform: nil) }
    }
    func setSelection(_ path: CGPath, mode: SelectionCombineMode = .replace, previous: CGPath? = nil) {
        let canvas = CGPath(rect: CGRect(x: 0, y: 0, width: document.width, height: document.height), transform: nil)
        let clipped = path.intersection(canvas, using: .winding)
        let result: CGPath
        if let previous {
            switch mode {
            case .replace: result = clipped
            case .add: result = previous.union(clipped, using: .winding)
            case .subtract: result = previous.subtracting(clipped, using: .winding)
            case .intersect: result = previous.intersection(clipped, using: .winding)
            }
        } else { result = mode == .subtract ? CGMutablePath() : clipped }
        selectionRect = result.isEmpty ? .zero : result.boundingBoxOfPath
        selectionPath = result
    }
    func invertSelection() {
        guard let current = effectiveSelectionPath else { return }
        let canvas = CGPath(rect: CGRect(x: 0, y: 0, width: document.width, height: document.height), transform: nil)
        setSelection(canvas.subtracting(current, using: .winding))
    }
    func clearSelection() {
        guard tool == .pixel, let path = effectiveSelectionPath else { deleteSelection(); return }
        guard !path.isEmpty else { return }
        guard let layer = selected, layer.kind == .image, layer.visible, layer.page == page, !layer.locked else { message = "Select an unlocked, visible pixel layer before clearing a selection."; return }
        do {
            let updated = try RasterEditing.clear(layer, selection: path, target: editingMask ? .mask : .pixels)
            if updated != layer { updateElement { $0 = updated } }
        } catch { self.error = error.localizedDescription }
    }
    func copySelectionData() throws -> Data {
        var layers = currentElements.filter { selectedIDs.contains($0.id) }
        guard !layers.isEmpty else { throw DocumentError.invalid("Select a layer to copy.") }
        if tool == .pixel, let path = effectiveSelectionPath {
            guard let layer = selected, layer.kind == .image, layer.visible, layer.page == page else { throw DocumentError.invalid("Select a visible pixel layer to copy a pixel selection.") }
            layers = [try RasterEditing.extract(layer, document: document, selection: path, target: editingMask ? .mask : .pixels)]
        }
        return try JSONEncoder().encode(LayerTransfer(layers: layers))
    }
    func pasteLayerData(_ data: Data) throws {
        guard data.count <= 512_000_000 else { throw DocumentError.invalid("The clipboard data is too large.") }
        let transfer = try JSONDecoder().decode(LayerTransfer.self, from: data)
        guard transfer.version == 1 else { throw DocumentError.invalid("The clipboard format is not supported.") }
        var updated = document
        let ids = try updated.insertLayers(transfer.layers, page: page)
        mutate { $0 = updated }
        select(ids.last); additionalSelection = Set(ids.dropLast())
    }
    func moveCurrentPage(_ offset: Int) {
        let destination = page + offset
        guard (0..<document.pageCount).contains(destination) else { return }
        var updated = document
        do { try updated.movePage(from: page, to: destination); mutate { $0 = updated }; page = destination }
        catch { self.error = error.localizedDescription }
    }
    func fitSelectedImage(fill: Bool = false) {
        guard let layer = selected, !layer.locked, let data = layer.imageData, let image = NSImage(data: data)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let sx = document.width / Double(image.width), sy = document.height / Double(image.height)
        let factor = fill ? max(sx, sy) : min(sx, sy)
        let width = Double(image.width) * factor, height = Double(image.height) * factor
        updateElement { $0.x = (document.width - width) / 2; $0.y = (document.height - height) / 2; $0.width = width; $0.height = height }
    }
}

extension CanvasNSView {
    static var layerPasteboardType: NSPasteboard.PasteboardType { NSPasteboard.PasteboardType("ai.devin.creative.layers") }
    @objc func copy(_ sender: Any?) { _ = copyLayers(to: .general) }
    @objc func cut(_ sender: Any?) { _ = cutLayers(to: .general) }
    @discardableResult func cutLayers(to pasteboard: NSPasteboard) -> Bool {
        guard copyLayers(to: pasteboard) else { return false }
        session.clearSelection()
        return true
    }
    @objc func paste(_ sender: Any?) { pasteLayers(from: .general) }
    override func selectAll(_ sender: Any?) {
        if session.tool == .pixel { session.selectionRect = CGRect(x: 0, y: 0, width: session.document.width, height: session.document.height) }
        else { let ids = session.currentElements.filter { !$0.locked }.map(\.id); session.select(ids.last); session.additionalSelection = Set(ids.dropLast()) }
    }
    @discardableResult func copyLayers(to pasteboard: NSPasteboard) -> Bool {
        do {
            let data = try session.copySelectionData()
            let transfer = try JSONDecoder().decode(LayerTransfer.self, from: data)
            pasteboard.clearContents(); pasteboard.setData(data, forType: Self.layerPasteboardType)
            if let text = transfer.layers.last, text.kind == .text { pasteboard.setString(text.text, forType: .string) }
            if let layer = transfer.layers.last, layer.kind == .image, let image = Renderer.processedImage(layer), let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) { pasteboard.setData(png, forType: .png) }
            return true
        } catch { session.message = error.localizedDescription; return false }
    }
    func pasteLayers(from pasteboard: NSPasteboard) {
        do {
            if let data = pasteboard.data(forType: Self.layerPasteboardType) { try session.pasteLayerData(data); return }
            if let image = NSImage(pasteboard: pasteboard)?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                guard image.width * image.height <= 100_000_000 else { throw DocumentError.invalid("The clipboard image exceeds the pixel limit.") }
                let factor = min(1, session.document.width / Double(image.width), session.document.height / Double(image.height))
                var layer = CanvasElement(kind: .image, name: "Pasted image", x: 0, y: 0, width: Double(image.width) * factor, height: Double(image.height) * factor, page: session.page)
                layer.imageData = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
                session.mutate { $0.elements.append(layer) }; session.select(layer.id)
            } else if let text = pasteboard.string(forType: .string), !text.isEmpty {
                session.addElement(.text); session.updateElement { $0.text = text; $0.name = "Pasted text" }
            } else { session.message = "The clipboard has no supported layers, image, or text." }
        } catch { session.error = error.localizedDescription }
    }
}
