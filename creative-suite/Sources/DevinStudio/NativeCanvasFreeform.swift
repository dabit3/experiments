import AppKit
import DevinCore

struct FreeformPenGesture {
    let sessionID: UUID
    let revision: Int
    let page: Int
    let scale: Double
    let additionalSelection: Set<UUID>
    let selection: CGPath?
    let color: String
    var stroke: FreeformPathStroke
}

extension CanvasNSView {
    func freeformMouseDown(point p: CGPoint) -> Bool {
        freeformGesture = nil
        guard session.tool == .pixel, scale.isFinite, scale > 0, !session.busy, session.transaction == nil,
              (0..<session.document.pageCount).contains(activePage) else { return true }
        if session.editingMask || (session.selectedID != nil && session.selected == nil) {
            session.message = "Select layer pixels before drawing a Freeform path."
            return true
        }
        if let layer = session.selected, layer.locked || !layer.visible || layer.page != activePage {
            session.message = "Select an unlocked, visible layer on this page before drawing a Freeform path."
            return true
        }
        var stroke = FreeformPathStroke(curveFit: session.freeformCurveFit)
        guard stroke.append(Point2D(p.x, p.y)) else { return true }
        freeformGesture = FreeformPenGesture(sessionID: session.id, revision: session.freeformRevision, page: activePage, scale: scale, additionalSelection: session.additionalSelection, selection: session.effectiveSelectionPath, color: session.drawingColor, stroke: stroke)
        session.message = nil
        return true
    }

    func validFreeformGesture(_ gesture: FreeformPenGesture) -> Bool {
        session.id == gesture.sessionID && session.freeformRevision == gesture.revision && session.tool == .pixel && session.drawingTool == .freeformPen && activePage == gesture.page && session.page == gesture.page && scale.isFinite && scale > 0 && scale == gesture.scale && session.additionalSelection == gesture.additionalSelection && session.effectiveSelectionPath == gesture.selection && !session.editingMask && !session.busy && session.transaction == nil
    }

    func freeformMouseDragged(point p: CGPoint, isFinal: Bool = false) -> Bool {
        guard var gesture = freeformGesture else { return session.drawingTool == .freeformPen }
        guard validFreeformGesture(gesture) else { freeformGesture = nil; return true }
        guard gesture.stroke.append(Point2D(p.x, p.y), isFinal: isFinal) else {
            freeformGesture = nil
            session.message = "Freeform stroke canceled. Use finite coordinates and at most \(FreeformPathStroke.maximumSamples) samples per stroke."
            return true
        }
        freeformGesture = gesture
        return true
    }

    func freeformMouseUp(_ event: NSEvent) -> Bool {
        guard freeformGesture != nil else { return session.drawingTool == .freeformPen }
        _ = freeformMouseDragged(point: point(event), isFinal: true)
        guard let gesture = freeformGesture else { return true }
        defer { freeformGesture = nil }
        guard validFreeformGesture(gesture), let commands = gesture.stroke.path(closingDistance: 10 / gesture.scale) else { return true }
        var world = CanvasElement(kind: .path, name: "Freeform Path \(session.document.elements.count + 1)", x: 0, y: 0, width: session.document.width, height: session.document.height, fill: gesture.color, page: gesture.page)
        world.vectorPath = commands
        var layer = VectorGeometry.element(from: VectorGeometry.path(world), name: world.name, fill: world.fill, page: world.page)
        layer.stroke = gesture.color; layer.strokeWidth = 2
        do {
            var updated = session.document
            updated.elements.append(layer)
            _ = try updated.validated()
            session.mutate { document in document = updated }
            session.select(layer.id)
        } catch { session.error = error.localizedDescription }
        return true
    }

    func drawFreeformOverlay(_ context: CGContext) {
        guard let gesture = freeformGesture, validFreeformGesture(gesture), let first = gesture.stroke.samples.first else { return }
        context.saveGState(); defer { context.restoreGState() }
        context.setStrokeColor(NSColor(hex: "4AA4FF").cgColor); context.setLineWidth(1 / scale)
        context.move(to: CGPoint(x: first.x, y: first.y))
        for point in gesture.stroke.samples.dropFirst() { context.addLine(to: CGPoint(x: point.x, y: point.y)) }
        context.strokePath()
        context.strokeEllipse(in: CGRect(x: first.x - 5 / scale, y: first.y - 5 / scale, width: 10 / scale, height: 10 / scale))
    }
}
