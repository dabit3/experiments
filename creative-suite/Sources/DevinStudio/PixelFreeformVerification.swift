import AppKit
import DevinCore

@MainActor enum PixelFreeformVerification {
    static func run(directory: URL, check: (Bool, String) -> Void) throws {
        let h = PixelToolFixture(); defer { h.close() }; h.configure(.freeformPen)
        let original = h.session.document
        let points = (0...80).map { CGPoint(x: 12 + Double($0), y: 45 + 22 * sin(Double($0) / 15)) }
        func draw(_ fixture: PixelToolFixture, _ points: [CGPoint]) {
            fixture.send(.leftMouseDown, points[0])
            for point in points.dropFirst().dropLast() { fixture.send(.leftMouseDragged, point) }
            fixture.send(.leftMouseUp, points.last!)
        }
        func near(_ a: Point2D, _ b: CGPoint) -> Bool { hypot(a.x - b.x, a.y - b.y) < 0.000001 }
        check(h.session.freeformCurveFit == 2, "Curve Fit defaults to 2 document pixels")
        for (value, expected) in [(-1.0, 0.5), (11, 10), (.nan, 2), (.infinity, 2)] {
            h.session.freeformCurveFit = value
            check(h.session.freeformCurveFit == expected, "Curve Fit clamps finite values and rejects nonfinite values")
        }
        h.session.freeformCurveFit = 2
        h.send(.leftMouseDown, points[0])
        for point in points.dropFirst().dropLast() { h.send(.leftMouseDragged, point) }
        check(h.canvas.freeformGesture != nil && h.session.document == original && h.session.history.undoStack.isEmpty && !h.session.isDirty, "drag previews without changing artwork, dirty state, or history")
        h.send(.leftMouseUp, points.last!)
        guard let layer = h.session.selected, let path = layer.vectorPath else { throw DocumentError.invalid("Freeform Pen did not create editable vector commands.") }
        let created = h.session.document
        check(created.elements.count == 2 && created.elements[0] == original.elements[0] && layer.kind == .path && layer.imageData == nil && layer.points.isEmpty, "mouse-up creates one vector layer and preserves source pixels")
        check(path.dropFirst().allSatisfy { $0.verb == .curve && $0.control1 != nil && $0.control2 != nil } && path.count < points.count, "drag samples become smoothed editable cubic handles, not a polyline fallback")
        check(near(layer.worldPoint(path[0].point), points[0]) && near(layer.worldPoint(path.last!.point), points.last!), "normalization preserves the first point and the unsampled mouse-up endpoint")
        check(h.session.history.undoStack.count == 1 && h.session.isDirty && h.session.transaction == nil && h.canvas.freeformGesture == nil && h.session.drawingTool == .freeformPen, "one completed drag records one edit and keeps Freeform Pen active")
        h.session.undo(); check(h.session.document == original && !h.session.isDirty, "undo removes only the new path")
        h.session.redo(); check(h.session.document == created, "redo restores the same editable path")
        h.session.select(layer.id); h.configure(.directSelect)
        let endpoint = layer.worldPoint(path.last!.point)
        h.drag(CGPoint(x: endpoint.x, y: endpoint.y), CGPoint(x: endpoint.x + 3, y: endpoint.y + 4))
        check(h.session.selected?.vectorPath?.last?.point != path.last?.point && h.session.selectedID == layer.id, "Direct Selection edits a generated anchor without replacing the layer")
        h.session.undo(); check(h.session.document == created, "Direct Selection of a Freeform anchor remains undoable")
        let reopened = try CreativeDocument.load(from: created.encoded())
        check(reopened == created, "the project round trip preserves Freeform handles")
        let svg = SVGExporter.render(created)
        check(svg.contains(path[1].svg), "SVG export contains the generated cubic commands")
        try created.encoded().write(to: directory.appendingPathComponent("pixel-freeform-pen.devin"))
        try svg.write(to: directory.appendingPathComponent("pixel-freeform-pen.svg"), atomically: true, encoding: .utf8)
        guard let image = Renderer.image(created) else { throw DocumentError.invalid("Freeform Pen artwork did not render.") }
        try Renderer.writeImage(image, to: directory.appendingPathComponent("pixel-freeform-pen.png"), type: .png)
        var zoomPaths: [[VectorCommand]] = []
        for scale in [0.5, 2.0] {
            let fixture = PixelToolFixture(); defer { fixture.close() }; fixture.configure(.freeformPen); fixture.canvas.scale = scale
            draw(fixture, points)
            zoomPaths.append(fixture.session.selected?.vectorPath ?? [])
            let circle = (0...30).map { i -> CGPoint in
                let angle = Double(i) / 30 * .pi * 2
                return CGPoint(x: 64 + 30 * cos(angle), y: 48 + 30 * sin(angle))
            }
            draw(fixture, Array(circle.dropLast()) + [CGPoint(x: 94 + 4 / scale, y: 48)])
            check(fixture.session.selected?.vectorPath?.last?.verb == .close, "returning within 10 screen points closes the path at \(scale) scale")
            draw(fixture, Array(circle.dropLast()) + [CGPoint(x: 94 + 12 / scale, y: 48)])
            check(fixture.session.selected?.vectorPath?.last?.verb != .close, "release outside the closing radius keeps the path open at \(scale) scale")
        }
        let matchingGeometry = zoomPaths[0].count == zoomPaths[1].count && zip(zoomPaths[0], zoomPaths[1]).allSatisfy { a, b in
            a.verb == b.verb && zip([a.point, a.control1, a.control2], [b.point, b.control1, b.control2]).allSatisfy { x, y in
                guard let x, let y else { return x == nil && y == nil }
                return hypot(x.x - y.x, x.y - y.y) < 0.000000001
            }
        }
        check(!zoomPaths[0].isEmpty && matchingGeometry, "Curve Fit uses document pixels independently of zoom")
        var counts: [Int] = []
        for fit in [0.5, 10.0] {
            let fixture = PixelToolFixture(); defer { fixture.close() }; fixture.configure(.freeformPen); fixture.session.freeformCurveFit = fit
            draw(fixture, points)
            counts.append(fixture.session.selected?.vectorPath?.count ?? 0)
        }
        check(counts[0] > counts[1] && counts[1] > 1, "the Curve Fit control changes the generated anchor density")
        for state in ["locked", "hidden", "other page", "mask", "missing selection", "invalid scale"] {
            let fixture = PixelToolFixture(); defer { fixture.close() }; fixture.configure(.freeformPen)
            if state == "locked" { fixture.session.document.elements[0].locked = true }
            if state == "hidden" { fixture.session.document.elements[0].visible = false }
            if state == "other page" { fixture.session.document.pageCount = 2; fixture.session.document.elements[0].page = 1 }
            if state == "mask" { fixture.session.editingMask = true }
            if state == "missing selection" { fixture.session.selectedID = UUID() }
            if state == "invalid scale" { fixture.canvas.scale = 0 }
            let before = fixture.session.document
            draw(fixture, points)
            check(fixture.session.document == before && fixture.session.history.undoStack.isEmpty, "a \(state) target cannot create fallback artwork")
        }
        for change in ["lock", "hide", "selection", "secondary selection", "tool", "tool round trip", "delete", "escape", "undo", "redo", "page", "mask", "document", "zoom", "fit", "session"] {
            let fixture = PixelToolFixture(); defer { fixture.close() }; fixture.configure(.freeformPen)
            fixture.send(.leftMouseDown, points[0]); fixture.send(.leftMouseDragged, points[20])
            if change == "lock" { fixture.session.updateElement { $0.locked = true } }
            if change == "hide" { fixture.session.updateElement { $0.visible = false } }
            if change == "selection" { fixture.session.select(nil) }
            if change == "secondary selection" { fixture.session.additionalSelection = [UUID()] }
            if change == "tool" { fixture.session.drawingTool = .select }
            if change == "tool round trip" { fixture.session.drawingTool = .select; fixture.session.drawingTool = .freeformPen }
            if change == "delete" { fixture.session.deleteSelection() }
            if change == "escape" { fixture.key(53, "\u{1b}") }
            if change == "undo" { fixture.session.undo() }
            if change == "redo" { fixture.session.redo() }
            if change == "page" { fixture.session.page = 1 }
            if change == "mask" { fixture.session.editingMask = true }
            if change == "document" { fixture.session.mutate { $0.width += 1 } }
            if change == "zoom" { fixture.canvas.scale = 2 }
            if change == "fit" { fixture.session.freeformCurveFit = 10 }
            if change == "session" { fixture.canvas.session = StudioSession(tool: .pixel, document: fixture.session.document) }
            let before = fixture.session.document, count = fixture.session.history.undoStack.count, active = fixture.canvas.session.document
            fixture.send(.leftMouseDragged, points[40]); fixture.send(.leftMouseUp, points.last!)
            check(fixture.session.document == before && fixture.session.history.undoStack.count == count && fixture.canvas.session.document == active && fixture.canvas.freeformGesture == nil, "\(change) during a stroke cancels without overwriting other edits")
        }
        do {
            let fixture = PixelToolFixture(); defer { fixture.close() }; fixture.configure(.freeformPen)
            fixture.click(points[0]); fixture.drag(points[0], CGPoint(x: points[0].x + 0.1, y: points[0].y))
            check(fixture.session.document == fixture.session.savedDocument && fixture.session.history.undoStack.isEmpty, "clicks and subpixel jitter do not create degenerate paths")
            fixture.session.select(nil)
            draw(fixture, points)
            check(fixture.session.document.elements.count == 2 && fixture.session.selected?.kind == .path, "an empty layer selection can create a new path")
        }
        do {
            let fixture = PixelToolFixture(); defer { fixture.close() }; fixture.configure(.freeformPen)
            fixture.send(.leftMouseDown, points[0])
            _ = fixture.canvas.freeformMouseDragged(point: CGPoint(x: Double.nan, y: 0))
            fixture.send(.leftMouseUp, points.last!)
            check(fixture.session.document == fixture.session.savedDocument && fixture.session.history.undoStack.isEmpty, "invalid pointer coordinates cancel the entire path")
            fixture.send(.leftMouseDown, CGPoint(x: 0, y: 0))
            for i in 1...FreeformPathStroke.maximumSamples { _ = fixture.canvas.freeformMouseDragged(point: CGPoint(x: Double(i), y: 0)) }
            fixture.send(.leftMouseUp, points.last!)
            check(fixture.canvas.freeformGesture == nil && fixture.session.document == fixture.session.savedDocument && fixture.session.history.undoStack.isEmpty && fixture.session.message != nil, "the sample limit cancels with feedback instead of committing a truncated path")
        }
    }
}
