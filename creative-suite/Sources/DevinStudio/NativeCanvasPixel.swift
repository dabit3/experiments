import AppKit
import DevinCore

struct PixelEditGesture {
    let sessionID: UUID
    let tool: DrawingTool
    let layer: CanvasElement
    let selected: CanvasElement?
    let page: Int
    let editingMask: Bool
    let selection: CGPath?
}

extension CanvasNSView {
    func validPixelEdit(_ gesture: PixelEditGesture) -> Bool {
        session.id == gesture.sessionID && session.tool == .pixel && session.drawingTool == gesture.tool && session.selected == gesture.selected && activePage == gesture.page && session.page == gesture.page && session.editingMask == gesture.editingMask && session.effectiveSelectionPath == gesture.selection
    }
    func pixelMouseDown(_ event: NSEvent, point p: CGPoint) -> Bool {
        guard session.tool == .pixel else { return false }
        let tool = session.drawingTool
        pixelGesture = nil; pixelEditGesture = nil; pixelPoints = []
        if tool != .polygonLasso { polygonSelectionPoints = [] }
        if tool == .singleRow || tool == .singleColumn {
            let rect = tool == .singleRow ? CGRect(x: 0, y: floor(p.y), width: session.document.width, height: 1) : CGRect(x: floor(p.x), y: 0, width: 1, height: session.document.height)
            session.setSelection(CGPath(rect: rect, transform: nil), mode: selectionMode(event), previous: session.effectiveSelectionPath)
            return true
        }
        if tool == .polygonLasso {
            if polygonSelectionPoints.isEmpty { pixelSelectionBefore = session.effectiveSelectionPath; pixelSelectionMode = selectionMode(event) }
            if polygonSelectionPoints.count >= 3 && (event.clickCount > 1 || hypot(p.x - polygonSelectionPoints[0].x, p.y - polygonSelectionPoints[0].y) < 8 / scale) { finishPolygonSelection() }
            else { polygonSelectionPoints.append(p) }
            return true
        }
        if tool == .selectionBrush {
            pixelSelectionBefore = session.effectiveSelectionPath; pixelSelectionMode = selectionMode(event)
            pixelGesture = tool; pixelPoints = [p]; return true
        }
        if tool == .magicWand {
            guard let layer = session.selected, layer.kind == .image else { session.message = "Select a pixel layer for color selection."; return true }
            do { let path = try PixelRasterTools.selection(layer, point: p, settings: session.pixelSettings); session.setSelection(path, mode: selectionMode(event), previous: session.effectiveSelectionPath) }
            catch { session.error = error.localizedDescription }
            return true
        }
        if tool == .eyedropper || tool == .colorSampler {
            do {
                guard let image = Renderer.image(session.document, page: activePage, maxDimension: 4096) else { return true }
                let pixels = try PixelRasterTools.grid(image)
                let color = pixels.average(x: Int(p.x / session.document.width * Double(pixels.width)), y: Int(p.y / session.document.height * Double(pixels.height)), radius: session.pixelSettings.sampleRadius)
                let hex = color.prefix(3).map { String(format: "%02X", Int(($0 * 255).rounded())) }.joined()
                if tool == .colorSampler {
                    if session.colorSamples.count >= 10 { session.colorSamples.removeFirst() }
                    session.colorSamples.append(PixelColorSample(point: p, color: hex))
                } else { session.drawingColor = hex }
            } catch { session.error = error.localizedDescription }
            return true
        }
        if tool == .ruler { pixelGesture = tool; pixelPoints = [p]; session.measurement = (p, p); return true }
        guard PixelRasterTools.strokes.contains(tool) || PixelRasterTools.fills.contains(tool) || tool == .brush || tool == .eraser else { return false }
        if let layer = session.selected, layer.locked || !layer.visible || layer.page != activePage { session.message = "Select an unlocked, visible layer on this page before painting."; return true }
        if session.editingMask && (![DrawingTool.brush, .eraser].contains(tool) || session.selected?.maskData == nil) { session.message = "Select the layer pixels before using this tool."; return true }
        if [.cloneStamp, .healingBrush].contains(tool), event.modifierFlags.contains(.option) {
            if let layer = session.selected, layer.kind == .image { session.cloneSource = PixelCloneSource(layer: layer, point: p); session.cloneOffset = nil; session.message = "Sample source set" }
            else { session.message = "Select a pixel layer before setting a source." }
            return true
        }
        guard session.brushOpacity > 0, session.effectiveSelectionPath?.isEmpty != true else { return true }
        do {
            let layer: CanvasElement
            if let selected = session.selected, selected.kind == .image { layer = selected }
            else if [.brush, .gradient, .paintBucket, .pencil].contains(tool) {
                var created = try RasterEditing.paint(nil, document: session.document, points: [], size: 1, color: session.drawingColor, opacity: 1, erase: false, selection: nil)
                created.page = activePage; layer = created
            } else { session.message = "Select a pixel layer, or rasterize the selected layer first."; return true }
            pixelEditGesture = PixelEditGesture(sessionID: session.id, tool: tool, layer: layer, selected: session.selected, page: activePage, editingMask: session.editingMask, selection: session.effectiveSelectionPath)
            pixelGesture = tool; pixelPoints = [p]
        } catch { session.error = error.localizedDescription }
        return true
    }
    func selectionMode(_ event: NSEvent) -> SelectionCombineMode {
        if event.modifierFlags.contains(.shift) && event.modifierFlags.contains(.option) { return .intersect }
        if event.modifierFlags.contains(.option) { return .subtract }
        if event.modifierFlags.contains(.shift) { return .add }
        return session.selectionMode
    }
    func pixelMouseDragged(_ event: NSEvent, point p: CGPoint) -> Bool {
        guard let tool = pixelGesture else { return false }
        if session.drawingTool != tool || pixelEditGesture.map({ !validPixelEdit($0) }) == true {
            pixelGesture = nil; pixelEditGesture = nil; pixelPoints = []; return true
        }
        if pixelPoints.count < 20000 { pixelPoints.append(p) }
        if tool == .ruler { session.measurement = (pixelPoints[0], p) }
        return true
    }
    func pixelMouseUp(_ event: NSEvent) -> Bool {
        guard let tool = pixelGesture else { return false }
        defer { pixelGesture = nil; pixelEditGesture = nil; pixelPoints = []; originalElement = nil }
        guard session.drawingTool == tool, !pixelPoints.isEmpty else { return true }
        let p = point(event)
        if pixelPoints.last != p { pixelPoints.append(p) }
        if tool == .ruler { session.measurement = (pixelPoints[0], p); return true }
        if tool == .selectionBrush {
            let path = CGMutablePath(); path.move(to: pixelPoints[0]); path.addLines(between: pixelPoints)
            if pixelPoints.count == 1 { path.addLine(to: CGPoint(x: p.x + 0.001, y: p.y)) }
            session.setSelection(path.copy(strokingWithWidth: session.brushSize, lineCap: .round, lineJoin: .round, miterLimit: 10), mode: pixelSelectionMode, previous: pixelSelectionBefore)
            return true
        }
        guard let gesture = pixelEditGesture, validPixelEdit(gesture) else { return true }
        do {
            var clone = session.cloneSource, offset = session.cloneOffset
            if [.cloneStamp, .healingBrush].contains(tool), var source = clone, let first = pixelPoints.first {
                if session.pixelSettings.aligned {
                    if offset == nil { offset = CGPoint(x: source.point.x - first.x, y: source.point.y - first.y) }
                    source.point = CGPoint(x: first.x + offset!.x, y: first.y + offset!.y)
                }
                clone = source
            }
            let updated: CanvasElement
            if tool == .brush || tool == .eraser {
                updated = try RasterEditing.paint(gesture.layer, document: session.document, points: pixelPoints, size: session.brushSize, color: session.drawingColor, opacity: session.brushOpacity, erase: tool == .eraser, selection: nil, selectionPath: gesture.selection, hardness: session.brushHardness, target: gesture.editingMask ? .mask : .pixels)
            } else {
                updated = try PixelRasterTools.apply(tool, layer: gesture.layer, document: session.document, points: pixelPoints, size: session.brushSize, opacity: session.brushOpacity, hardness: session.brushHardness, foreground: session.drawingColor, background: session.backgroundColor, settings: session.pixelSettings, selection: gesture.selection, clone: clone, pattern: session.patternSource, history: session.historyPaintSource)
            }
            guard updated != gesture.layer else { return true }
            session.mutate { document in
                var copy = document
                if let index = copy.elements.firstIndex(where: { $0.id == updated.id }) { copy.elements[index] = updated }
                else { copy.elements.append(updated) }
                document = copy
            }
            session.cloneOffset = offset; session.select(updated.id)
        } catch { session.error = error.localizedDescription }
        return true
    }
    func finishPolygonSelection() {
        guard polygonSelectionPoints.count >= 3 else { return }
        let path = CGMutablePath(); path.addLines(between: polygonSelectionPoints); path.closeSubpath()
        session.setSelection(path, mode: pixelSelectionMode, previous: pixelSelectionBefore)
        polygonSelectionPoints = []; needsDisplay = true
    }
    func pixelKeyDown(_ event: NSEvent) -> Bool {
        guard session.tool == .pixel else { return false }
        if event.keyCode == 36 && !polygonSelectionPoints.isEmpty { finishPolygonSelection(); return true }
        if event.keyCode == 53 && (pixelGesture != nil || !polygonSelectionPoints.isEmpty) {
            pixelGesture = nil; pixelEditGesture = nil; pixelPoints = []; polygonSelectionPoints = []; originalElement = nil; needsDisplay = true
            return true
        }
        guard !event.modifierFlags.contains(.command), !event.modifierFlags.contains(.control), let key = event.charactersIgnoringModifiers?.uppercased(), let tool = PixelToolbar.nextTool(key: key, current: session.drawingTool, cycling: event.modifierFlags.contains(.shift)) else { return false }
        session.drawingTool = tool; return true
    }
    func drawPixelOverlays(_ context: CGContext) {
        guard session.tool == .pixel else { return }
        context.saveGState(); defer { context.restoreGState() }
        context.setStrokeColor(NSColor.white.cgColor); context.setLineWidth(1 / scale)
        if let first = polygonSelectionPoints.first {
            context.move(to: first); for p in polygonSelectionPoints.dropFirst() { context.addLine(to: p) }; context.strokePath()
            for p in polygonSelectionPoints { context.strokeEllipse(in: CGRect(x: p.x - 3 / scale, y: p.y - 3 / scale, width: 6 / scale, height: 6 / scale)) }
        }
        if let first = pixelPoints.first, let last = pixelPoints.last {
            context.move(to: first)
            if pixelGesture == .gradient || pixelGesture == .ruler { context.addLine(to: last) }
            else { context.setLineWidth(session.brushSize); context.setLineCap(.round); context.setAlpha(0.35); for p in pixelPoints.dropFirst() { context.addLine(to: p) } }
            context.strokePath(); context.setAlpha(1); context.setLineWidth(1 / scale)
        }
        let points = session.colorSamples.map(\.point) + (session.cloneSource.map { [$0.point] } ?? [])
        for p in points {
            context.move(to: CGPoint(x: p.x - 6 / scale, y: p.y)); context.addLine(to: CGPoint(x: p.x + 6 / scale, y: p.y))
            context.move(to: CGPoint(x: p.x, y: p.y - 6 / scale)); context.addLine(to: CGPoint(x: p.x, y: p.y + 6 / scale)); context.strokePath()
        }
    }
}
