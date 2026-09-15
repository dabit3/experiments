import AppKit
import SwiftUI
import DevinCore

struct NativeCanvas: NSViewRepresentable {
    @ObservedObject var session: StudioSession
    var scale: Double
    var page: Int? = nil
    func makeNSView(context: Context) -> CanvasNSView { let view = CanvasNSView(session: session, scale: scale); view.previewPage = page; return view }
    func updateNSView(_ view: CanvasNSView, context: Context) { view.session = session; view.scale = scale; view.previewPage = page; view.needsDisplay = true }
}

final class CanvasNSView: NSView {
    var session: StudioSession {
        didSet { if session.id != oldValue.id { freeformGesture = nil } }
    }
    var scale: Double {
        didSet { if scale != oldValue { freeformGesture = nil } }
    }
    var freeformGesture: FreeformPenGesture?
    var dragOrigin = CGPoint.zero
    var originalElement: CanvasElement?
    var resizing = false
    var creating = false
    var cropRect: CGRect?
    var previewPage: Int?
    var activePage: Int { previewPage ?? session.page }
    var paintPoints: [CGPoint] = []
    var selectingMarquee = false
    var selectionBefore: CGPath?
    var selectionGestureMode: SelectionCombineMode = .replace
    var lassoPoints: [CGPoint] = []
    var activePenID: UUID?
    var penOutgoing: Point2D?
    var penGesture = false
    var anchorGesture: AnchorEditGesture?
    var draggedNode: (index: Int, control: Int)?
    var handScrollOrigin: CGPoint?
    var pixelGesture: DrawingTool?
    var pixelEditGesture: PixelEditGesture?
    var pixelPoints: [CGPoint] = []
    var polygonSelectionPoints: [CGPoint] = []
    var pixelSelectionBefore: CGPath?
    var pixelSelectionMode: SelectionCombineMode = .replace
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    init(session: StudioSession, scale: Double) {
        self.session = session; self.scale = scale
        super.init(frame: .zero)
        registerForDraggedTypes([.fileURL])
        setAccessibilityRole(.layoutArea)
        setAccessibilityLabel("Editable artwork canvas")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override func resignFirstResponder() -> Bool {
        freeformGesture = nil; needsDisplay = true
        return super.resignFirstResponder()
    }
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow !== window { freeformGesture = nil }
        super.viewWillMove(toWindow: newWindow)
    }
    func pose(_ layer: CanvasElement) -> CanvasElement { session.tool == .motion ? layer.evaluated(at: session.playhead) : layer }
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.scaleBy(x: scale, y: scale)
        let d = session.document
        drawCanvasDocument(d, in: context)
        if session.onionSkin && session.page > 0 {
            context.saveGState(); context.setAlpha(0.2); context.beginTransparencyLayer(auxiliaryInfo: nil)
            Renderer.draw(d, in: context, page: activePage - 1, background: false)
            context.endTransparencyLayer(); context.restoreGState()
        }
        if session.showGrid {
            context.setStrokeColor(NSColor.black.withAlphaComponent(0.12).cgColor)
            context.setLineWidth(0.5 / scale)
            for x in stride(from: 0.0, through: d.width, by: 50) { context.move(to: CGPoint(x: x, y: 0)); context.addLine(to: CGPoint(x: x, y: d.height)) }
            for y in stride(from: 0.0, through: d.height, by: 50) { context.move(to: CGPoint(x: 0, y: y)); context.addLine(to: CGPoint(x: d.width, y: y)) }
            context.strokePath()
        }
        if let raw = session.selected, raw.page == activePage, raw.visible, !session.isPlaying, cropRect == nil, session.showTransformControls {
            let e = pose(raw)
            context.saveGState()
            context.translateBy(x: e.x + e.width / 2, y: e.y + e.height / 2)
            context.rotate(by: e.rotation * .pi / 180)
            context.translateBy(x: -e.width / 2, y: -e.height / 2)
            context.setStrokeColor(NSColor(hex: "84B8FF").cgColor); context.setLineWidth(1 / scale)
            context.stroke(CGRect(x: 0, y: 0, width: e.width, height: e.height))
            let size = 7 / scale
            context.setFillColor(NSColor.white.cgColor)
            let handle = CGRect(x: e.width - size / 2, y: e.height - size / 2, width: size, height: size)
            context.fill(handle); context.stroke(handle)
            context.restoreGState()
        }
        if let cropRect {
            context.saveGState()
            context.addRect(CGRect(x: 0, y: 0, width: d.width, height: d.height)); context.addRect(cropRect)
            context.setFillColor(NSColor.black.withAlphaComponent(0.5).cgColor); context.drawPath(using: .eoFill)
            context.setStrokeColor(NSColor.white.cgColor); context.setLineWidth(1 / scale); context.stroke(cropRect)
            for fraction in [1.0 / 3, 2.0 / 3] {
                context.move(to: CGPoint(x: cropRect.minX + cropRect.width * fraction, y: cropRect.minY))
                context.addLine(to: CGPoint(x: cropRect.minX + cropRect.width * fraction, y: cropRect.maxY))
                context.move(to: CGPoint(x: cropRect.minX, y: cropRect.minY + cropRect.height * fraction))
                context.addLine(to: CGPoint(x: cropRect.maxX, y: cropRect.minY + cropRect.height * fraction))
            }
            context.setAlpha(0.4); context.strokePath(); context.restoreGState()
        }
        drawProfessionalOverlays(context)
        context.restoreGState()
    }
    func point(_ event: NSEvent) -> CGPoint {
        let p = convert(event.locationInWindow, from: nil)
        return CGPoint(x: p.x / scale, y: p.y / scale)
    }
    func localPoint(_ p: CGPoint, element e: CanvasElement) -> CGPoint {
        let dx = p.x - e.x - e.width / 2, dy = p.y - e.y - e.height / 2
        let angle = -e.rotation * .pi / 180
        return CGPoint(x: dx * cos(angle) - dy * sin(angle) + e.width / 2, y: dx * sin(angle) + dy * cos(angle) + e.height / 2)
    }
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        session.isPlaying = false
        let p = point(event)
        dragOrigin = p; resizing = false; creating = false; originalElement = nil; cropRect = nil
        session.page = activePage
        if professionalMouseDown(event, point: p) { needsDisplay = true; return }
        session.beginTransaction()
        if session.drawingTool == .crop { cropRect = CGRect(origin: p, size: .zero); return }
        if session.drawingTool == .select || session.drawingTool == .directSelect {
            if let raw = session.selected, !raw.locked, raw.visible, raw.page == activePage, session.showTransformControls {
                let selected = pose(raw)
                let local = localPoint(p, element: selected)
                if abs(local.x - selected.width) < 12 / scale && abs(local.y - selected.height) < 12 / scale {
                    originalElement = selected; resizing = true; return
                }
            }
            if session.tool == .pixel && !session.autoSelect { originalElement = session.selected.map(pose); return }
            let hit = session.currentElements.reversed().first { e in
                guard e.visible, !e.locked else { return false }
                let evaluated = pose(e), local = localPoint(p, element: pose(e))
                if evaluated.kind == .ellipse {
                    let dx = (local.x - evaluated.width / 2) / (evaluated.width / 2)
                    let dy = (local.y - evaluated.height / 2) / (evaluated.height / 2)
                    return dx * dx + dy * dy <= 1
                }
                return CGRect(x: -4 / scale, y: -4 / scale, width: evaluated.width + 8 / scale, height: evaluated.height + 8 / scale).contains(local)
            }?.id
            if event.modifierFlags.contains(.shift) || hit.map({ !session.selectedIDs.contains($0) }) != false { session.select(hit, extending: event.modifierFlags.contains(.shift)) }
            originalElement = session.selected.map(pose)
        } else {
            let tool = session.drawingTool
            let kind: ElementKind = tool == .brush || tool == .line ? .path : ElementKind(rawValue: tool.rawValue) ?? .rectangle
            var e = CanvasElement(kind: kind, name: tool.rawValue.capitalized, x: p.x, y: p.y, width: tool == .text ? 520 : 1, height: tool == .text ? 100 : 1, fill: session.drawingColor, page: activePage)
            if kind == .path { e.points = [Point2D(0, 0)]; e.stroke = session.drawingColor; e.strokeWidth = session.brushSize }
            if tool == .text { e.text = "Your text here"; e.fontSize = session.tool == .press ? 24 : 64; e.typography = Typography() }
            session.document.elements.append(e)
            session.selectedID = e.id; originalElement = e; creating = true
        }
        needsDisplay = true
    }
    override func mouseDragged(with event: NSEvent) {
        let p = point(event), dx = p.x - dragOrigin.x, dy = p.y - dragOrigin.y
        if professionalMouseDragged(event, point: p) { needsDisplay = true; return }
        if cropRect != nil {
            let rect = CGRect(x: min(p.x, dragOrigin.x), y: min(p.y, dragOrigin.y), width: abs(dx), height: abs(dy))
            cropRect = rect.intersection(CGRect(x: 0, y: 0, width: session.document.width, height: session.document.height))
            needsDisplay = true; return
        }
        guard let original = originalElement, let i = session.document.elements.firstIndex(where: { $0.id == original.id }), !original.locked else { return }
        if creating {
            if original.kind == .path {
                let new = Point2D(dx, dy)
                if session.drawingTool == .line { session.document.elements[i].points = [Point2D(0, 0), new] }
                else { session.document.elements[i].points.append(new) }
            } else if original.kind != .text || session.tool == .press {
                let w = max(1, abs(dx)), h = event.modifierFlags.contains(.shift) ? w : max(1, abs(dy))
                session.document.elements[i].x = dx < 0 ? dragOrigin.x - w : dragOrigin.x
                session.document.elements[i].y = dy < 0 ? dragOrigin.y - h : dragOrigin.y
                session.document.elements[i].width = w; session.document.elements[i].height = h
            }
        } else if resizing {
            let resized = original.resizedBottomRight(to: Point2D(p.x, p.y), preserveAspect: event.modifierFlags.contains(.shift))
            let factor = original.width / (session.transaction?.elements.first { $0.id == original.id }?.width ?? original.width)
            session.updateElement(original.id, recordHistory: false) { e in
                e.x = resized.x; e.y = resized.y; e.width = resized.width / factor; e.height = resized.height / factor
                if original.kind == .path { e.points = resized.points.map { Point2D($0.x / factor, $0.y / factor) }; e.vectorPath = resized.vectorPath?.map { $0.scaled(1 / factor) } }
            }
        } else {
            session.updateElement(original.id, recordHistory: false) { $0.x = original.x + dx; $0.y = original.y + dy }
            for id in session.additionalSelection where id != original.id {
                if let other = session.transaction?.elements.first(where: { $0.id == id && !$0.locked }) {
                    let initial = pose(other)
                    session.updateElement(id, recordHistory: false) { $0.x = initial.x + dx; $0.y = initial.y + dy }
                }
            }
        }
        needsDisplay = true
    }
    override func mouseUp(with event: NSEvent) {
        if professionalMouseUp(event) { needsDisplay = true; return }
        if let rect = cropRect {
            if rect.width >= 16, rect.height >= 16 {
                do { try session.document.crop(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height); session.selectedID = nil; session.zoom = 1 }
                catch { session.error = error.localizedDescription }
            } else { session.message = "Drag a crop of at least 16 × 16 pixels." }
            cropRect = nil; session.drawingTool = .select
        }
        if creating, let index = session.document.elements.firstIndex(where: { $0.id == session.selectedID }) {
            var e = session.document.elements[index]
            if e.kind == .path {
                let minX = e.points.map(\.x).min() ?? 0, minY = e.points.map(\.y).min() ?? 0
                let maxX = e.points.map(\.x).max() ?? 1, maxY = e.points.map(\.y).max() ?? 1
                e.x += minX; e.y += minY; e.width = max(1, maxX - minX); e.height = max(1, maxY - minY)
                e.points = e.points.map { Point2D($0.x - minX, $0.y - minY) }
            } else if e.width < 3 && e.height < 3 { e.width = 180; e.height = 180 }
            if session.drawingTool == .roundedRectangle { e.cornerRadius = min(e.width, e.height) * 0.15 }
            if session.drawingTool == .polygon {
                let sides = min(50, max(3, session.pixelSettings.polygonSides))
                e.kind = .path
                e.vectorPath = (0..<sides).map { i in
                    let angle = Double(i) / Double(sides) * .pi * 2 - .pi / 2
                    return VectorCommand(i == 0 ? .move : .line, Point2D(e.width / 2 + cos(angle) * e.width / 2, e.height / 2 + sin(angle) * e.height / 2))
                }
                e.vectorPath?.append(VectorCommand(.close, Point2D(0, 0)))
            }
            session.document.elements[index] = e
            if session.tool != .pixel && session.drawingTool != .brush { session.drawingTool = .select }
        }
        session.endTransaction(); originalElement = nil; resizing = false; creating = false
        needsDisplay = true
    }
    override func keyDown(with event: NSEvent) {
        if professionalKeyDown(event) { return }
        if event.keyCode == 53 {
            if let previous = session.transaction { session.document = previous }
            session.transaction = nil; cropRect = nil; originalElement = nil; creating = false; resizing = false
            session.drawingTool = .select; needsDisplay = true; return
        }
        if event.keyCode == 51 || event.keyCode == 117 { session.clearSelection(); return }
        if [123, 124, 125, 126].contains(event.keyCode) {
            let amount = event.modifierFlags.contains(.shift) ? 10.0 : 1.0
            session.updateElement { e in
                if !e.locked {
                    if event.keyCode == 123 { e.x -= amount }; if event.keyCode == 124 { e.x += amount }
                    if event.keyCode == 125 { e.y += amount }; if event.keyCode == 126 { e.y -= amount }
                }
            }
            return
        }
        let basic: [DrawingTool] = [.select, .directSelect, .marquee, .rectangle, .ellipse, .text, .brush, .eraser, .line, .crop, .pen, .eyedropper, .hand, .zoom]
        if let chars = event.charactersIgnoringModifiers?.uppercased(), let tool = basic.first(where: { $0.shortcut == chars }) { session.drawingTool = tool; return }
        super.keyDown(with: event)
    }
    override func magnify(with event: NSEvent) { session.zoom = min(4, max(0.15, session.zoom * (1 + event.magnification))) }
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        guard !urls.isEmpty else { return false }
        session.importURLs(urls); return true
    }
}
