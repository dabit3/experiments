import AppKit
import DevinCore

struct AnchorEditGesture {
    let sessionID: UUID
    let tool: DrawingTool
    let original: CanvasElement
    let source: [VectorCommand]
    let anchor: Point2D?
    var commands: [VectorCommand]
    var node: (index: Int, control: Int)? = nil
}

extension DrawingTool {
    var isAnchorEditor: Bool { self == .addAnchor || self == .deleteAnchor || self == .convertAnchor }
}

extension CanvasNSView {
    func anchorMouseDown(_ event: NSEvent, point p: CGPoint) -> Bool {
        anchorGesture = nil
        guard session.tool == .pixel, scale.isFinite, scale > 0 else { return true }
        guard let layer = session.selected, layer.kind == .path, layer.visible, layer.page == activePage, !layer.locked, !session.editingMask else {
            session.message = "Select an unlocked, visible path layer before editing anchors. Shape primitives and masks are not supported."
            return true
        }
        let source = layer.vectorPath ?? layer.points.enumerated().map { VectorCommand($0.offset == 0 ? .move : .line, $0.element) }
        let local = localPoint(p, element: layer), target = Point2D(local.x, local.y), tolerance = 8 / scale
        var commands = source
        var anchor: Point2D?
        let hit: Bool
        switch session.drawingTool {
        case .addAnchor: hit = VectorPathEditor.addAnchor(to: &commands, at: target, tolerance: tolerance)
        case .deleteAnchor: hit = VectorPathEditor.deleteAnchor(from: &commands, at: target, tolerance: tolerance)
        case .convertAnchor:
            if let index = VectorPathEditor.nearestAnchorIndex(on: source, to: target, tolerance: tolerance) {
                anchor = source[index].point
                _ = VectorPathEditor.convertAnchor(in: &commands, at: source[index].point, tolerance: 0)
                hit = true
            } else { hit = false }
        default: return false
        }
        guard hit else {
            session.message = session.drawingTool == .addAnchor ? "Click a path segment away from its existing anchors." : "Click an anchor on the selected path. Drag Convert Anchor to create smooth handles."
            return true
        }
        anchorGesture = AnchorEditGesture(sessionID: session.id, tool: session.drawingTool, original: layer, source: source, anchor: anchor, commands: commands)
        session.message = nil
        return true
    }

    func validAnchorGesture(_ gesture: AnchorEditGesture) -> Bool {
        gesture.sessionID == session.id && session.tool == .pixel && session.drawingTool == gesture.tool && session.selectedID == gesture.original.id && session.selected == gesture.original && activePage == gesture.original.page && !session.editingMask && scale.isFinite && scale > 0
    }

    func anchorMouseDragged(_ event: NSEvent, point p: CGPoint) -> Bool {
        guard var gesture = anchorGesture else { return session.drawingTool.isAnchorEditor }
        guard validAnchorGesture(gesture) else { anchorGesture = nil; return true }
        if gesture.tool == .directSelect, let node = gesture.node {
            let local = localPoint(p, element: gesture.original)
            var commands = gesture.source
            _ = VectorPathEditor.moveNode(in: &commands, at: node.index, to: Point2D(local.x, local.y), control: node.control)
            gesture.commands = commands; anchorGesture = gesture
            return true
        }
        guard gesture.tool == .convertAnchor, let anchor = gesture.anchor else { return true }
        let local = localPoint(p, element: gesture.original), origin = localPoint(dragOrigin, element: gesture.original)
        var dx = local.x - origin.x, dy = local.y - origin.y
        var commands = gesture.source
        if hypot(dx, dy) * scale >= 3 {
            if event.modifierFlags.contains(.shift) {
                let length = hypot(dx, dy), angle = (atan2(dy, dx) / (.pi / 4)).rounded() * (.pi / 4)
                dx = length * cos(angle); dy = length * sin(angle)
            }
            guard VectorPathEditor.convertAnchor(in: &commands, at: anchor, tolerance: 0, outgoing: Point2D(anchor.x + dx, anchor.y + dy)) else {
                gesture.commands = gesture.source; anchorGesture = gesture; return true
            }
        } else { _ = VectorPathEditor.convertAnchor(in: &commands, at: anchor, tolerance: 0) }
        gesture.commands = commands; anchorGesture = gesture
        return true
    }

    func anchorMouseUp(_ event: NSEvent) -> Bool {
        guard anchorGesture != nil else { return session.drawingTool.isAnchorEditor }
        _ = anchorMouseDragged(event, point: point(event))
        guard let gesture = anchorGesture else { return true }
        defer { anchorGesture = nil }
        guard validAnchorGesture(gesture), gesture.commands != gesture.source else { return true }
        var updated = gesture.original
        updated.vectorPath = gesture.commands
        session.mutate { document in
            var copy = document
            if let index = copy.elements.firstIndex(where: { $0.id == updated.id && !$0.locked }) { copy.elements[index] = updated }
            document = copy
        }
        return true
    }

    var anchorPreviewLayer: CanvasElement? {
        guard let gesture = anchorGesture, validAnchorGesture(gesture) else { return session.selected }
        var layer = gesture.original
        layer.vectorPath = gesture.commands
        return layer
    }
}
