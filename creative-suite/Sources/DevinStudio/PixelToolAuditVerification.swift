import AppKit
import DevinCore

@MainActor final class PixelToolFixture {
    let session: StudioSession
    let canvas: CanvasNSView
    let window: NSWindow
    static func layer(textured: Bool = false) -> CanvasElement {
        let width = 128, height = 96
        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        for y in 0..<height { for x in 0..<width {
            let i = (y * width + x) * 4
            if textured {
                bytes[i] = UInt8(40 + (x * 3 + y * 7) % 170)
                bytes[i + 1] = UInt8(30 + (x / 4 + y / 4) % 2 * 160)
                bytes[i + 2] = UInt8(20 + (x * 5 + y * 2) % 190)
            } else { bytes[i] = x < 64 ? 255 : 0; bytes[i + 1] = 0; bytes[i + 2] = x < 64 ? 0 : 255 }
        } }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        var layer = CanvasElement(kind: .image, name: "Pixel audit fixture", x: 0, y: 0, width: Double(width), height: Double(height))
        layer.imageData = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
        return layer
    }
    init(textured: Bool = false) {
        var document = CreativeDocument(title: "Pixel tool audit", tool: .pixel)
        document.width = 128; document.height = 96; document.transparentBackground = true; document.elements = [Self.layer(textured: textured)]
        session = StudioSession(tool: .pixel, document: document)
        session.brushSize = 24; session.brushHardness = 1; session.drawingColor = "00FF00"; session.pixelSettings.tolerance = 0
        canvas = CanvasNSView(session: session, scale: 1)
        window = NSWindow(contentRect: CGRect(x: -5000, y: -5000, width: 128, height: 96), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false; window.contentView = canvas; canvas.frame = CGRect(x: 0, y: 0, width: 128, height: 96)
    }
    func close() { window.orderOut(nil); window.contentView = nil }
    func send(_ type: NSEvent.EventType, _ point: CGPoint, flags: NSEvent.ModifierFlags = [], clicks: Int = 1) {
        let scaled = CGPoint(x: point.x * canvas.scale, y: point.y * canvas.scale)
        let event = NSEvent.mouseEvent(with: type, location: canvas.convert(scaled, to: nil), modifierFlags: flags, timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: clicks, pressure: 1)!
        switch type {
        case .leftMouseDown: canvas.mouseDown(with: event)
        case .leftMouseDragged: canvas.mouseDragged(with: event)
        case .leftMouseUp: canvas.mouseUp(with: event)
        default: break
        }
    }
    func click(_ point: CGPoint, flags: NSEvent.ModifierFlags = []) { send(.leftMouseDown, point, flags: flags); send(.leftMouseUp, point, flags: flags) }
    func drag(_ from: CGPoint, _ to: CGPoint, flags: NSEvent.ModifierFlags = []) { send(.leftMouseDown, from, flags: flags); send(.leftMouseDragged, to, flags: flags); send(.leftMouseUp, to, flags: flags) }
    func key(_ code: UInt16, _ characters: String, flags: NSEvent.ModifierFlags = []) {
        canvas.keyDown(with: NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: window.windowNumber, context: nil, characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code)!)
    }
    func color(_ x: Int, _ y: Int, layer: CanvasElement? = nil) -> NSColor? {
        (layer ?? session.selected)?.imageData.flatMap { NSBitmapImageRep(data: $0)?.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) }
    }
    func configure(_ tool: DrawingTool) {
        session.drawingTool = tool
        if [.cloneStamp, .healingBrush].contains(tool) { click(CGPoint(x: 20, y: 48), flags: .option) }
        if tool == .patternStamp { session.patternSource = Self.layer() }
        if tool == .historyBrush { session.historyPaintSource = session.selected; session.historyPaintSource?.imageData = Self.layer().imageData }
    }
}

@MainActor enum PixelToolAuditVerification {
    struct Observation: Codable { let tool: String; let behavior: String; let passed: Bool }
    static func run(directory: URL) throws -> Int {
        var observations: [Observation] = [], covered = Set<DrawingTool>()
        func check(_ value: Bool, _ tool: DrawingTool, _ behavior: String) {
            observations.append(Observation(tool: tool.rawValue, behavior: behavior, passed: value))
            print("\(value ? "PASS" : "FAIL") \(tool.title): \(behavior)")
        }
        func sameColor(_ a: NSColor?, _ b: NSColor?) -> Bool {
            guard let a, let b else { return false }
            return abs(a.redComponent - b.redComponent) < 0.015 && abs(a.greenComponent - b.greenComponent) < 0.015 && abs(a.blueComponent - b.blueComponent) < 0.015 && abs(a.alphaComponent - b.alphaComponent) < 0.015
        }
        for group in PixelToolbar.groups {
            let h = PixelToolFixture(); defer { h.close() }
            let control = GroupedToolControl(session: h.session, group: group)
            let menu = control.makeChoicesMenu()
            for choice in group.choices {
                guard let item = menu.items.first(where: { $0.title.hasPrefix(choice.title) }) else { throw DocumentError.invalid("Missing tool menu item: " + choice.title) }
                if let tool = choice.tool, let action = item.action {
                    check(item.isEnabled && NSApp.sendAction(action, to: item.target, from: item) && h.session.drawingTool == tool, tool, "native flyout activates the exact tool")
                    check(h.session.document == h.session.savedDocument && h.session.history.undoStack.isEmpty, tool, "choosing the tool cannot alter artwork")
                } else if item.isEnabled { throw DocumentError.invalid("An unavailable tool is enabled: " + choice.title) }
            }
        }
        let selectionTools: [DrawingTool] = [.marquee, .ellipseSelect, .lasso, .singleRow, .singleColumn, .polygonLasso, .selectionBrush, .magicWand]
        for tool in selectionTools {
            let h = PixelToolFixture(); defer { h.close() }; covered.insert(tool); h.configure(tool)
            let original = h.session.document
            if tool == .polygonLasso { h.click(CGPoint(x: 12, y: 12)); h.click(CGPoint(x: 72, y: 12)); h.click(CGPoint(x: 42, y: 72)); h.key(36, "\r") }
            else if tool == .lasso { h.send(.leftMouseDown, CGPoint(x: 12, y: 12)); h.send(.leftMouseDragged, CGPoint(x: 72, y: 12)); h.send(.leftMouseDragged, CGPoint(x: 42, y: 72)); h.send(.leftMouseUp, CGPoint(x: 12, y: 12)) }
            else if [.singleRow, .singleColumn, .magicWand].contains(tool) { h.click(CGPoint(x: 32, y: 40)) }
            else { h.drag(CGPoint(x: 12, y: 12), CGPoint(x: 72, y: 64)) }
            check(h.session.effectiveSelectionPath?.isEmpty == false, tool, "creates a nonempty selection through pointer events")
            check(h.session.document == original && h.session.history.undoStack.isEmpty && !h.session.isDirty, tool, "selection preserves all layers and original pixel data")
            if [.marquee, .ellipseSelect, .selectionBrush].contains(tool) {
                h.session.selectionRect = CGRect(x: 0, y: 0, width: 30, height: 96)
                h.drag(CGPoint(x: 20, y: 10), CGPoint(x: 80, y: 80), flags: [.shift, .option])
                check(h.session.effectiveSelectionPath?.contains(CGPoint(x: 28, y: 32)) == true && h.session.effectiveSelectionPath?.contains(CGPoint(x: 5, y: 45)) == false && h.session.effectiveSelectionPath?.contains(CGPoint(x: 60, y: 45)) == false, tool, "Shift-Option intersects instead of subtracting the selection")
            }
        }
        let rasterTools = [DrawingTool.brush, .eraser] + Array(PixelRasterTools.strokes.union(PixelRasterTools.fills)).sorted { $0.rawValue < $1.rawValue }
        for tool in rasterTools {
            let h = PixelToolFixture(textured: true); defer { h.close() }; covered.insert(tool); h.configure(tool)
            let original = h.session.document, outside = h.color(4, 4)
            let start = CGPoint(x: [.cloneStamp, .healingBrush].contains(tool) ? 100 : 48, y: 48)
            h.drag(start, CGPoint(x: start.x + 8, y: start.y))
            let result = h.session.document
            check(result != original && result.elements.count == 1 && h.session.selectedID == original.elements[0].id && h.session.error == nil, tool, "edits pixels without replacing the layer or creating fallback shapes")
            check(h.session.history.undoStack.count == 1 && h.session.isDirty, tool, "records one undoable stroke")
            if !PixelRasterTools.fills.contains(tool) { check(sameColor(h.color(4, 4), outside), tool, "preserves pixels outside the brush footprint") }
            h.session.undo(); check(h.session.document == original, tool, "undo restores the exact source document")
            h.session.redo(); check(h.session.document == result, tool, "redo restores the stroke")
            check((try? CreativeDocument.load(from: result.encoded())) == result, tool, "edited pixels survive a project round trip")
            for state in ["locked", "hidden", "other page", "zero opacity", "empty selection"] {
                let guarded = PixelToolFixture(textured: true); defer { guarded.close() }; guarded.configure(tool)
                if state == "locked" { guarded.session.document.elements[0].locked = true }
                if state == "hidden" { guarded.session.document.elements[0].visible = false }
                if state == "other page" { guarded.session.document.pageCount = 2; guarded.session.document.elements[0].page = 1 }
                if state == "zero opacity" { guarded.session.brushOpacity = 0 }
                if state == "empty selection" { guarded.session.setSelection(CGMutablePath()) }
                let before = guarded.session.document
                guarded.drag(start, CGPoint(x: start.x + 8, y: start.y))
                check(guarded.session.document == before && guarded.session.history.undoStack.isEmpty, tool, "a \(state) target is a non-destructive no-op")
            }
            for change in ["lock", "selection", "tool", "delete", "escape"] {
                let guarded = PixelToolFixture(textured: true); defer { guarded.close() }; guarded.configure(tool)
                guarded.send(.leftMouseDown, start); guarded.send(.leftMouseDragged, CGPoint(x: start.x + 8, y: start.y))
                if change == "lock" { guarded.session.updateElement { $0.locked = true } }
                if change == "selection" { guarded.session.select(nil) }
                if change == "tool" { guarded.session.drawingTool = .select }
                if change == "delete" { guarded.session.deleteSelection() }
                if change == "escape" { guarded.key(53, "\u{1b}") }
                let before = guarded.session.document, count = guarded.session.history.undoStack.count
                guarded.send(.leftMouseUp, CGPoint(x: start.x + 8, y: start.y))
                check(guarded.session.document == before && guarded.session.history.undoStack.count == count, tool, "\(change) during a gesture cannot overwrite or resurrect artwork")
            }
        }
        for tool in [DrawingTool.rectangle, .roundedRectangle, .ellipse, .polygon, .line, .text] {
            let h = PixelToolFixture(); defer { h.close() }; covered.insert(tool); h.configure(tool)
            let original = h.session.document
            h.drag(CGPoint(x: 12, y: 15), CGPoint(x: 72, y: 65))
            let created = h.session.document
            let expected: ElementKind = tool == .ellipse ? .ellipse : tool == .text ? .text : [.polygon, .line].contains(tool) ? .path : .rectangle
            check(created.elements.count == 2 && h.session.selected?.kind == expected, tool, "creates the intended editable element")
            check(created.elements[0] == original.elements[0] && h.session.history.undoStack.count == 1, tool, "preserves the source layer with one history entry")
            check(h.session.drawingTool == tool, tool, "remains active for the next drawing gesture")
            h.session.undo(); check(h.session.document == original, tool, "creation undoes without affecting the source layer")
        }
        for tool in [DrawingTool.eyedropper, .colorSampler, .ruler, .zoom] {
            let h = PixelToolFixture(); defer { h.close() }; covered.insert(tool); h.configure(tool)
            let original = h.session.document
            h.drag(CGPoint(x: 12, y: 16), CGPoint(x: 42, y: 56))
            check(h.session.document == original && h.session.history.undoStack.isEmpty, tool, "does not mutate artwork or history")
            if tool == .eyedropper { check(h.session.drawingColor == "FF0000", tool, "samples the visible pixel color") }
            if tool == .colorSampler { check(h.session.colorSamples.count == 1 && h.session.colorSamples.first?.color == "FF0000", tool, "stores a sampled document color") }
            if tool == .ruler { check(h.session.measurement.map { abs(hypot($0.end.x - $0.start.x, $0.end.y - $0.start.y) - 50) < 0.01 } == true, tool, "measures document-space distance") }
            if tool == .zoom { check(h.session.zoom == 1.25, tool, "zooms in on click"); h.click(CGPoint(x: 32, y: 32), flags: .option); check(abs(h.session.zoom - 1) < 0.001, tool, "Option-click zooms out") }
        }
        do {
            let h = PixelToolFixture(); defer { h.close() }; covered.insert(.hand); h.configure(.hand)
            let scroll = NSScrollView(frame: CGRect(x: 0, y: 0, width: 64, height: 48))
            h.window.contentView = scroll; scroll.documentView = h.canvas; h.canvas.frame = CGRect(x: 0, y: 0, width: 256, height: 192)
            scroll.contentView.scroll(to: CGPoint(x: 60, y: 60)); let origin = scroll.contentView.bounds.origin
            h.drag(CGPoint(x: 80, y: 80), CGPoint(x: 90, y: 90))
            check(scroll.contentView.bounds.origin != origin && h.session.document == h.session.savedDocument, .hand, "pans a native scroll viewport without moving artwork")
        }
        do {
            let h = PixelToolFixture(); defer { h.close() }; covered.insert(.select); h.configure(.select)
            let original = h.session.document
            h.drag(CGPoint(x: 40, y: 40), CGPoint(x: 50, y: 55))
            check(h.session.selected?.x == 10 && h.session.selected?.y == 15 && h.session.selected?.imageData == original.elements[0].imageData, .select, "moves the layer without rewriting source pixels")
            h.session.undo(); check(h.session.document == original, .select, "move is undoable")
            h.session.showTransformControls = false
            h.drag(CGPoint(x: 127, y: 95), CGPoint(x: 117, y: 85))
            check(h.session.selected?.width == 128 && h.session.selected?.height == 96, .select, "hidden transform handles cannot resize the layer")
        }
        do {
            let h = PixelToolFixture(); defer { h.close() }; covered.insert(.crop); h.configure(.crop)
            let original = h.session.document
            h.drag(CGPoint(x: 10, y: 10), CGPoint(x: 100, y: 80))
            check(h.session.document.width == 90 && h.session.document.height == 70 && h.session.selectedID == nil && h.session.document.elements[0].imageData == original.elements[0].imageData, .crop, "crop retains all original source pixels")
            h.session.undo(); check(h.session.document == original, .crop, "crop restores through undo")
        }
        do {
            let h = PixelToolFixture(); defer { h.close() }; covered.insert(.pen); h.configure(.pen)
            h.click(CGPoint(x: 10, y: 10)); h.drag(CGPoint(x: 60, y: 20), CGPoint(x: 70, y: 35)); h.click(CGPoint(x: 90, y: 70)); h.key(36, "\r")
            check(h.session.document.elements.count == 2 && (h.session.selected?.vectorPath?.filter { $0.verb == .curve }.count ?? 0) >= 2 && h.canvas.activePenID == nil, .pen, "creates and finishes an editable cubic path")
        }
        covered.insert(.freeformPen)
        try PixelFreeformVerification.run(directory: directory) { check($0, .freeformPen, $1) }
        for tool in [DrawingTool.directSelect, .addAnchor, .deleteAnchor, .convertAnchor] {
            let h = PixelToolFixture(); defer { h.close() }; covered.insert(tool)
            var path = CanvasElement(kind: .path, name: "Path audit", x: 0, y: 0, width: 128, height: 96)
            path.vectorPath = [.init(.move, Point2D(12, 12)), .init(.line, Point2D(100, 12)), .init(.line, Point2D(100, 80)), .init(.close, Point2D(12, 12))]
            h.session.document.elements = [path]; h.session.select(path.id); h.configure(tool)
            let original = h.session.document
            let start = tool == .addAnchor ? CGPoint(x: 56, y: 12) : CGPoint(x: 12, y: 12)
            if tool == .directSelect || tool == .convertAnchor { h.drag(start, CGPoint(x: 25, y: 25)) } else { h.click(start) }
            check(h.session.document != original && h.session.document.elements.count == 1 && h.session.selectedID == path.id, tool, "edits the selected path without deleting its layer")
            h.session.undo(); check(h.session.document == original, tool, "path edit undoes exactly")
        }
        do {
            let h = PixelToolFixture(); defer { h.close() }
            h.session.setSelection(CGPath(ellipseIn: CGRect(x: 10, y: 10, width: 40, height: 50), transform: nil))
            let original = h.session.document, pasteboard = NSPasteboard.withUniqueName()
            defer { pasteboard.releaseGlobally() }
            check(h.canvas.copyLayers(to: pasteboard), .magicWand, "pixel selection copies to a private pasteboard")
            let copied = try JSONDecoder().decode(LayerTransfer.self, from: pasteboard.data(forType: CanvasNSView.layerPasteboardType)!)
            check(copied.layers.count == 1 && copied.layers[0].width == 40 && copied.layers[0].height == 50, .magicWand, "copy uses selection bounds rather than the whole layer")
            check((h.color(0, 0, layer: copied.layers[0])?.alphaComponent ?? 1) < 0.05 && (h.color(20, 25, layer: copied.layers[0])?.alphaComponent ?? 0) > 0.95, .magicWand, "copied pixels preserve the actual selection shape")
            check(h.canvas.cutLayers(to: pasteboard) && h.session.document.elements.count == 1, .magicWand, "cut clears pixels but retains the layer")
            check((h.color(30, 35)?.alphaComponent ?? 1) < 0.05 && (h.color(90, 35)?.alphaComponent ?? 0) > 0.95, .magicWand, "cut preserves all pixels outside the selection")
            h.session.undo(); check(h.session.document == original, .magicWand, "cut supports exact undo")
            h.session.setSelection(CGMutablePath()); h.session.clearSelection()
            check(h.session.document == original, .magicWand, "clearing an empty selection cannot delete the layer")
        }
        for tool in [DrawingTool.marquee, .ellipseSelect] {
            let h = PixelToolFixture(); defer { h.close() }; h.configure(tool)
            h.send(.leftMouseDown, CGPoint(x: 10, y: 10)); h.send(.leftMouseUp, CGPoint(x: 80, y: 70))
            check(h.session.selectionRect?.width == 70 && h.session.selectionRect?.height == 60, tool, "uses the final mouse-up endpoint even without a drag event")
        }
        for tool in rasterTools {
            let h = PixelToolFixture(textured: true); defer { h.close() }; h.configure(tool)
            h.session.setSelection(CGPath(rect: CGRect(x: 0, y: 0, width: 40, height: 96), transform: nil))
            let outside = h.color(48, 48)
            h.drag(CGPoint(x: 36, y: 48), CGPoint(x: 55, y: 48))
            check(sameColor(outside, h.color(48, 48)), tool, "a stroke crossing the selection boundary cannot modify unselected pixels")
        }
        for tool in [DrawingTool.blur, .sharpen, .dodge, .burn, .sponge] {
            let h = PixelToolFixture(textured: true); defer { h.close() }; h.configure(tool); h.session.pixelSettings.strength = 0
            let original = h.session.document
            h.drag(CGPoint(x: 32, y: 48), CGPoint(x: 64, y: 48))
            check(h.session.document == original && h.session.history.undoStack.isEmpty, tool, "zero strength leaves pixels and undo history unchanged")
        }
        do {
            let h = PixelToolFixture(textured: true); defer { h.close() }; h.configure(.eyedropper)
            h.click(CGPoint(x: 20, y: 12))
            check(h.session.drawingColor == "B81E90", .eyedropper, "samples the known sRGB color from the correct row of an asymmetric image")
        }
        for tool in [DrawingTool.brush, .eraser] {
            let h = PixelToolFixture(); defer { h.close() }
            h.session.addMask(); h.configure(tool); h.session.drawingColor = "000000"
            let original = h.session.document
            h.drag(CGPoint(x: 20, y: 48), CGPoint(x: 32, y: 48))
            check(h.session.selected?.imageData == original.elements[0].imageData && h.session.selected?.maskData != original.elements[0].maskData, tool, "mask painting edits only the mask, never the source pixels")
            h.session.undo(); check(h.session.document == original, tool, "mask painting restores exactly through undo")
        }
        do {
            let h = PixelToolFixture(); defer { h.close() }; h.session.addMask()
            h.session.setSelection(CGPath(rect: CGRect(x: 10, y: 10, width: 20, height: 20), transform: nil))
            let original = h.session.document
            h.key(51, "\u{8}")
            let mask = h.session.selected?.maskData.flatMap { NSBitmapImageRep(data: $0) }
            check(h.session.selected?.imageData == original.elements[0].imageData && h.session.document.elements.count == 1 && (mask?.colorAt(x: 20, y: 20)?.usingColorSpace(.sRGB)?.redComponent ?? 1) < 0.01, .magicWand, "Delete on a selected mask region cannot delete the layer or its pixels")
            h.session.undo(); check(h.session.document == original, .magicWand, "selected-mask clearing has exact undo")
        }
        let missing = Set(PixelToolbar.groups.flatMap(\.tools)).subtracting(covered)
        guard missing.isEmpty else { throw DocumentError.invalid("Tools missing native audit coverage: " + missing.map(\.title).sorted().joined(separator: ", ")) }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(observations).write(to: directory.appendingPathComponent("pixel-tool-audit.json"), options: .atomic)
        let failures = observations.filter { !$0.passed }
        print("Pixel audit: \(covered.count) tools, \(observations.count) checks, \(failures.count) failures")
        if !failures.isEmpty { throw DocumentError.invalid("Pixel tool audit failed: " + failures.map { $0.tool + " — " + $0.behavior }.joined(separator: "; ")) }
        return observations.count
    }
}
