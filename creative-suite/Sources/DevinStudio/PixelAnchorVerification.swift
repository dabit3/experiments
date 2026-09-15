import AppKit
import DevinCore

@MainActor enum PixelAnchorVerification {
    static func run(directory: URL) throws -> Int {
        var checks = 0
        func require(_ condition: @autoclosure () -> Bool, _ name: String) throws {
            guard condition() else { throw DocumentError.invalid("Anchor verification failed: " + name) }
            checks += 1; print("PASS " + name)
        }
        func near(_ a: Point2D?, _ b: Point2D) -> Bool { a.map { hypot($0.x - b.x, $0.y - b.y) < 0.000001 } ?? false }
        var layer = CanvasElement(kind: .path, name: "Anchor fixture", x: 80, y: 60, width: 100, height: 100, fill: "A03060")
        layer.rotation = 30; layer.stroke = "202020"; layer.strokeWidth = 2; layer.opacity = 0.8
        layer.vectorPath = [.init(.move, Point2D(0, 0)), .init(.curve, Point2D(100, 0), control1: Point2D(0, 100), control2: Point2D(100, 100))]
        var document = CreativeDocument(title: "Native anchor tools", tool: .pixel)
        document.width = 400; document.height = 300; document.elements = [layer]
        let session = StudioSession(tool: .pixel, document: document)
        let canvas = CanvasNSView(session: session, scale: 2)
        let window = NSWindow(contentRect: CGRect(x: -4000, y: -4000, width: 800, height: 600), styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = canvas; canvas.frame = CGRect(x: 0, y: 0, width: 800, height: 600)
        defer { window.orderOut(nil); window.contentView = nil }
        func event(_ type: NSEvent.EventType, _ local: Point2D, flags: NSEvent.ModifierFlags = []) -> NSEvent {
            let world = layer.worldPoint(local)
            let p = CGPoint(x: world.x * canvas.scale, y: world.y * canvas.scale)
            return NSEvent.mouseEvent(with: type, location: canvas.convert(p, to: nil), modifierFlags: flags, timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1)!
        }
        func send(_ type: NSEvent.EventType, _ p: Point2D, flags: NSEvent.ModifierFlags = []) {
            let pointer = event(type, p, flags: flags)
            switch type {
            case .leftMouseDown: canvas.mouseDown(with: pointer)
            case .leftMouseDragged: canvas.mouseDragged(with: pointer)
            case .leftMouseUp: canvas.mouseUp(with: pointer)
            default: preconditionFailure("Unexpected pointer event")
            }
        }
        func click(_ p: Point2D) { send(.leftMouseDown, p); send(.leftMouseUp, p) }
        func drag(_ a: Point2D, _ b: Point2D, flags: NSEvent.ModifierFlags = []) {
            send(.leftMouseDown, a); send(.leftMouseDragged, b, flags: flags); send(.leftMouseUp, b, flags: flags)
        }
        func escape() {
            let key = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}", isARepeat: false, keyCode: 53)!
            canvas.keyDown(with: key)
        }
        func reset(_ value: CreativeDocument? = nil) {
            canvas.anchorGesture = nil; session.document = value ?? document; session.savedDocument = session.document
            session.selectedID = layer.id; session.additionalSelection = []; session.history = History(); session.editingMask = false; session.page = 0
            canvas.scale = 2; canvas.previewPage = nil
        }
        guard let group = PixelToolbar.groups.first(where: { $0.name == "Pen" }) else { throw DocumentError.invalid("Pen group missing") }
        let control = GroupedToolControl(session: session, group: group)
        let menu = control.makeChoicesMenu()
        for tool in [DrawingTool.freeformPen, .addAnchor, .deleteAnchor, .convertAnchor] {
            guard let item = menu.items.first(where: { ($0.representedObject as? String) == tool.rawValue }), let action = item.action else { throw DocumentError.invalid("Anchor menu action missing") }
            try require(item.isEnabled && NSApp.sendAction(action, to: item.target, from: item) && session.drawingTool == tool, "Pen flyout selects \(tool.title) through native menu action")
        }
        try require(group.choices.first(where: { $0.title == "Freeform Pen" })?.tool != nil && menu.items.first(where: { $0.title.hasPrefix("Freeform Pen") })?.isEnabled == true, "Freeform Pen is a real enabled Pen flyout tool")
        try require(menu.items.filter { !$0.isEnabled }.count == 1 && menu.items.first(where: { $0.title.hasPrefix("Curvature Pen") })?.isEnabled == false, "Curvature Pen remains explicitly unavailable")
        try require(PixelToolbar.nextTool(key: "P", current: .pen, cycling: true) == .freeformPen && PixelToolbar.nextTool(key: "P", current: .freeformPen, cycling: true) == .addAnchor && PixelToolbar.nextTool(key: "P", current: .addAnchor, cycling: true) == .deleteAnchor && PixelToolbar.nextTool(key: "P", current: .deleteAnchor, cycling: true) == .convertAnchor, "Shift-P cycles all implemented Pen variants")
        session.drawingTool = .addAnchor
        let middle = Point2D(50, 75)
        send(.leftMouseDown, middle)
        try require(canvas.dragOrigin != .zero, "Native pointer dispatch reaches the anchor canvas")
        try require(session.document == document && canvas.anchorGesture?.commands.count == 3, "Native Add Anchor previews without committing on mouse down")
        send(.leftMouseUp, middle)
        let inserted = session.document
        try require(inserted.elements.count == 1 && session.selected?.vectorPath?.count == 3 && near(session.selected?.vectorPath?[1].point, middle), "Native Add Anchor hits a rotated cubic at 200 percent zoom")
        try require(near(session.selected?.vectorPath?[1].control1, Point2D(0, 50)) && near(session.selected?.vectorPath?[1].control2, Point2D(25, 75)) && near(session.selected?.vectorPath?[2].control1, Point2D(75, 75)), "Native insertion uses de Casteljau handles instead of a raster or line fallback")
        try require(session.history.undoStack.count == 1 && session.isDirty, "Anchor insertion records exactly one undoable document edit")
        session.undo(); try require(session.document == document && !session.isDirty, "Add Anchor undo restores the original document")
        session.redo(); try require(session.document == inserted, "Add Anchor redo restores editable geometry")
        session.drawingTool = .deleteAnchor; click(middle)
        let deleted = session.document
        try require(session.selected?.vectorPath?.count == 2 && session.document.elements.count == 1, "Native Delete Anchor reconnects neighbors without deleting the layer")
        session.undo(); try require(session.document == inserted, "Delete Anchor undo restores both split curves")
        session.redo(); try require(session.document == deleted, "Delete Anchor redo restores the joined segment")
        reset(inserted); session.drawingTool = .convertAnchor
        click(middle)
        let corner = session.document
        try require(near(session.selected?.vectorPath?[1].control2, middle) && near(session.selected?.vectorPath?[2].control1, middle), "Native Convert Anchor click collapses only the anchor's incoming and outgoing handles")
        click(middle)
        try require(session.document == corner && session.history.undoStack.count == 1, "Clicking an existing corner is a no-op without history pollution")
        drag(middle, Point2D(70, 65))
        let smooth = session.document
        try require(near(session.selected?.vectorPath?[1].control2, Point2D(30, 85)) && near(session.selected?.vectorPath?[2].control1, Point2D(70, 65)), "Native Convert Anchor drag creates opposing equal-length handles in local coordinates")
        try require(session.history.undoStack.count == 2 && session.selected?.id == layer.id && session.selected?.rotation == layer.rotation && session.selected?.opacity == layer.opacity && session.selected?.stroke == layer.stroke, "Conversion preserves layer identity and appearance with one history entry per gesture")
        session.undo(); try require(session.document == corner, "Convert Anchor drag undo restores the corner")
        session.redo(); try require(session.document == smooth, "Convert Anchor drag redo restores the handles")
        try smooth.encoded().write(to: directory.appendingPathComponent("pixel-anchor-tools.devin"))
        let reopened = try CreativeDocument.load(from: smooth.encoded())
        try require(reopened == smooth, "Native anchor edits survive project serialization")
        let svg = SVGExporter.render(smooth)
        try require(svg.contains(smooth.elements[0].vectorPath![1].svg) && svg.contains(smooth.elements[0].vectorPath![2].svg), "Anchor edits export as editable SVG cubic commands")
        try svg.write(to: directory.appendingPathComponent("pixel-anchor-tools.svg"), atomically: true, encoding: .utf8)
        guard let image = Renderer.image(smooth) else { throw DocumentError.invalid("Anchor fixture did not render") }
        try Renderer.writeImage(image, to: directory.appendingPathComponent("pixel-anchor-tools.png"), type: .png)
        for tool in [DrawingTool.addAnchor, .deleteAnchor, .convertAnchor] {
            reset(inserted); session.drawingTool = tool
            let target = tool == .addAnchor ? Point2D(15.625, 56.25) : middle
            send(.leftMouseDown, target)
            if tool == .convertAnchor { send(.leftMouseDragged, Point2D(70, 65)) }
            escape(); send(.leftMouseUp, target)
            try require(session.document == inserted && session.history.undoStack.isEmpty && canvas.anchorGesture == nil, "Escape cancels \(tool.title) without modifying history")
            for state in ["locked", "hidden", "other page", "raster", "mask"] {
                reset(inserted); session.drawingTool = tool
                if state == "locked" { session.document.elements[0].locked = true }
                if state == "hidden" { session.document.elements[0].visible = false }
                if state == "other page" { session.document.elements[0].page = 1 }
                if state == "raster" { session.document.elements[0].kind = .image }
                if state == "mask" { session.editingMask = true }
                let before = session.document
                drag(target, Point2D(target.x + 10, target.y))
                try require(session.document == before && session.history.undoStack.isEmpty, "\(tool.title) safeguards a \(state) target without fallback geometry")
            }
        }
        reset(inserted); session.drawingTool = .convertAnchor
        send(.leftMouseDown, middle); send(.leftMouseDragged, Point2D(70, 65)); session.updateElement { $0.locked = true }
        let locked = session.document
        send(.leftMouseUp, Point2D(70, 65))
        try require(session.document == locked && session.history.undoStack.count == 1, "Locking during conversion cancels the edit without overwriting the lock")
        reset(inserted); session.drawingTool = .deleteAnchor
        send(.leftMouseDown, middle); session.selectedID = nil; send(.leftMouseUp, middle)
        try require(session.document == inserted && session.history.undoStack.isEmpty, "Changing selection during an anchor gesture cancels its mutation")
        reset(inserted); session.drawingTool = .deleteAnchor
        send(.leftMouseDown, middle); session.drawingTool = .addAnchor; send(.leftMouseUp, middle)
        try require(session.document == inserted && session.history.undoStack.isEmpty, "Changing Pen variants during a gesture cancels its mutation")
        reset(); session.drawingTool = .addAnchor
        click(Point2D(50, 85))
        try require(session.document == document && session.history.undoStack.isEmpty, "Add Anchor hit tolerance stays in screen points at 200 percent zoom")
        canvas.scale = 0.5; click(Point2D(50, 85))
        try require(session.selected?.vectorPath?.count == 3, "Add Anchor remains hittable when zoomed out")
        reset(); session.drawingTool = .deleteAnchor; session.selectedID = nil
        click(Point2D(0, 0))
        try require(session.document == document && session.history.undoStack.isEmpty, "Anchor tools require an explicitly selected path")
        reset(); session.document.elements[0].vectorPath = nil; session.document.elements[0].points = [Point2D(0, 0), Point2D(100, 0)]
        let legacy = session.document
        session.drawingTool = .addAnchor; click(Point2D(50, 0))
        try require(session.selected?.vectorPath?.count == 3 && session.selected?.kind == .path, "Add Anchor upgrades a legacy polyline to editable vector commands")
        session.undo(); try require(session.document == legacy, "Undo preserves the original legacy path representation")
        reset(inserted); session.drawingTool = .convertAnchor
        drag(middle, Point2D(75, 78), flags: .shift)
        try require(near(session.selected?.vectorPath?[2].control1, Point2D(50 + hypot(25, 3), 75)), "Shift-conversion constrains the local handle direction to 45-degree increments")
        reset(inserted); session.drawingTool = .directSelect
        drag(middle, Point2D(55, 80))
        try require(near(session.selected?.vectorPath?[1].point, Point2D(55, 80)), "An inserted anchor remains editable by native Direct Selection")
        let incoming = inserted.elements[0].vectorPath![1].control2!, outgoing = inserted.elements[0].vectorPath![2].control1!
        try require(near(session.selected?.vectorPath?[1].control2, Point2D(incoming.x + 5, incoming.y + 5)) && near(session.selected?.vectorPath?[2].control1, Point2D(outgoing.x + 5, outgoing.y + 5)), "Direct Selection moves an anchor with both attached Bezier handles")
        reset(inserted); session.drawingTool = .directSelect
        send(.leftMouseDown, middle); send(.leftMouseDragged, Point2D(60, 85)); session.updateElement { $0.locked = true }
        let directLocked = session.document
        send(.leftMouseUp, Point2D(65, 90))
        try require(session.document == directLocked && session.history.undoStack.count == 1, "Direct Selection cannot overwrite a layer locked during the drag")
        reset(); session.document.elements[0].locked = true; canvas.activePenID = layer.id; session.drawingTool = .addAnchor
        let unfinishedLocked = session.document
        click(middle)
        try require(session.document == unfinishedLocked && session.history.undoStack.isEmpty && canvas.activePenID == nil, "Switching from an unfinished Pen path cannot normalize a locked layer")
        reset(); session.document.elements[0].vectorPath?[1].control1 = Point2D(1000001, 0); session.drawingTool = .addAnchor
        let malformed = session.document
        click(middle)
        try require(session.document == malformed && session.history.undoStack.isEmpty, "Native anchor dispatch rejects invalid geometry without creating fallback layers")
        reset(inserted)
        var other = layer; other.id = UUID(); other.name = "Unedited secondary selection"
        session.document.elements.append(other); session.additionalSelection = [other.id]; session.drawingTool = .deleteAnchor
        click(middle)
        try require(session.document.elements[1] == other && session.additionalSelection == [other.id] && session.selectedID == layer.id, "Anchor tools edit only the primary path and preserve other selections")
        return checks
    }
}
