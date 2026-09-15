import AppKit
import DevinCore

@MainActor enum PixelToolbarVerification {
    static func run(directory: URL) throws -> Int {
        var checks = 0
        func require(_ condition: @autoclosure () -> Bool, _ name: String) throws {
            guard condition() else { throw DocumentError.invalid("Toolbar verification failed: " + name) }
            checks += 1; print("PASS " + name)
        }
        func fixture(_ left: String, _ right: String) -> CanvasElement {
            let context = CGContext(data: nil, width: 128, height: 96, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.setFillColor(NSColor(hex: left).cgColor); context.fill(CGRect(x: 0, y: 0, width: 64, height: 96))
            context.setFillColor(NSColor(hex: right).cgColor); context.fill(CGRect(x: 64, y: 0, width: 64, height: 96))
            var layer = CanvasElement(kind: .image, name: "Raster fixture", x: 0, y: 0, width: 128, height: 96)
            layer.imageData = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])
            return layer
        }
        func color(_ layer: CanvasElement, _ x: Int, _ y: Int) -> NSColor { NSBitmapImageRep(data: layer.imageData!)!.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)! }
        let layer = fixture("FF0000", "0000FF")
        var document = CreativeDocument(title: "Tool coverage", tool: .pixel); document.width = 128; document.height = 96; document.elements = [layer]
        var settings = PixelRasterSettings(); settings.tolerance = 0; settings.strength = 0.8
        func apply(_ tool: DrawingTool, source: CanvasElement? = nil, points: [CGPoint] = [CGPoint(x: 32, y: 48)], foreground: String = "00FF00", background: String = "FFFFFF", clone: PixelCloneSource? = nil, history: CanvasElement? = nil, pattern: CanvasElement? = nil) throws -> CanvasElement {
            try PixelRasterTools.apply(tool, layer: source ?? layer, document: document, points: points, size: 24, opacity: 1, hardness: 1, foreground: foreground, background: background, settings: settings, selection: nil, clone: clone, pattern: pattern, history: history)
        }
        let bucket = try apply(.paintBucket)
        try require(color(bucket, 32, 48).greenComponent > 0.95 && color(bucket, 100, 48).blueComponent > 0.95, "Paint Bucket fills the connected color region only")
        let erased = try apply(.magicEraser)
        try require(color(erased, 32, 48).alphaComponent < 0.01 && color(erased, 100, 48).alphaComponent > 0.99, "Magic Eraser removes only the selected color region")
        let gradient = try apply(.gradient, points: [CGPoint(x: 0, y: 0), CGPoint(x: 127, y: 0)], foreground: "000000")
        try require(color(gradient, 1, 40).redComponent < 0.15 && color(gradient, 126, 40).redComponent > 0.95, "Linear Gradient follows the drag endpoints")
        settings.radialGradient = true
        let radial = try apply(.gradient, points: [CGPoint(x: 64, y: 48), CGPoint(x: 90, y: 48)], foreground: "000000")
        try require(color(radial, 64, 48).redComponent < color(radial, 77, 48).redComponent && color(radial, 77, 48).redComponent < color(radial, 115, 48).redComponent && color(radial, 115, 48).redComponent > 0.95, "Radial Gradient increases monotonically toward the outer color")
        let clone = PixelCloneSource(layer: layer, point: CGPoint(x: 20, y: 48))
        let stamped = try apply(.cloneStamp, points: [CGPoint(x: 100, y: 48)], clone: clone)
        try require(color(stamped, 100, 48).redComponent > 0.95 && color(stamped, 100, 10).blueComponent > 0.95, "Clone Stamp transfers sampled pixels inside the brush footprint")
        let healed = try apply(.healingBrush, points: [CGPoint(x: 100, y: 48)], clone: clone)
        try require(color(healed, 100, 48).blueComponent > color(healed, 100, 48).redComponent, "Sampled healing corrects the source toward the destination tone")
        let restored = try apply(.historyBrush, source: bucket, history: layer)
        try require(color(restored, 32, 48).redComponent > 0.95 && color(restored, 10, 10).greenComponent > 0.95, "History Brush restores a saved layer region without reverting the whole image")
        let pattern = try apply(.patternStamp, pattern: fixture("FFFFFF", "FFFFFF"))
        try require(color(pattern, 32, 48).blueComponent > 0.95 && color(pattern, 10, 10).redComponent > 0.95, "Pattern Stamp paints the selected pattern through the brush")
        let blurred = try apply(.blur, points: [CGPoint(x: 64, y: 48)])
        try require(color(blurred, 62, 48).blueComponent > 0.02 && color(blurred, 10, 10).blueComponent < 0.01, "Blur Brush changes detail locally")
        let sharpened = try apply(.sharpen, source: blurred, points: [CGPoint(x: 62, y: 48)])
        try require(abs(color(sharpened, 62, 48).redComponent - color(blurred, 62, 48).redComponent) > 0.005, "Sharpen Brush changes edge contrast")
        let gray = fixture("808080", "808080")
        let dodge = try apply(.dodge, source: gray), burn = try apply(.burn, source: gray)
        try require(color(dodge, 32, 48).redComponent > color(gray, 32, 48).redComponent && color(burn, 32, 48).redComponent < color(gray, 32, 48).redComponent, "Dodge and Burn change local exposure in opposite directions")
        let sponge = try apply(.sponge)
        try require(color(sponge, 32, 48).greenComponent > 0.05, "Sponge reduces local color saturation")
        let replaced = try apply(.colorReplacement)
        try require(color(replaced, 32, 48).greenComponent > color(replaced, 32, 48).redComponent, "Color Replacement changes color inside the matching brush region")
        let background = try apply(.backgroundEraser, points: [CGPoint(x: 55, y: 48), CGPoint(x: 75, y: 48)])
        try require(color(background, 58, 48).alphaComponent < 0.01 && color(background, 72, 48).alphaComponent > 0.99, "Background Eraser preserves a different color under the stroke")
        let session = StudioSession(tool: .pixel, document: document)
        let window = NSWindow(contentRect: CGRect(x: -4000, y: -4000, width: 128, height: 96), styleMask: [.borderless], backing: .buffered, defer: false)
        let canvas = CanvasNSView(session: session, scale: 1); window.contentView = canvas; canvas.frame = CGRect(x: 0, y: 0, width: 128, height: 96)
        func event(_ type: NSEvent.EventType, _ point: CGPoint, flags: NSEvent.ModifierFlags = []) -> NSEvent { NSEvent.mouseEvent(with: type, location: canvas.convert(point, to: nil), modifierFlags: flags, timestamp: 0, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)! }
        func click(_ point: CGPoint, flags: NSEvent.ModifierFlags = []) { canvas.mouseDown(with: event(.leftMouseDown, point, flags: flags)); canvas.mouseUp(with: event(.leftMouseUp, point, flags: flags)) }
        let unselectedSnapshot = canvas.bitmapImageRepForCachingDisplay(in: canvas.bounds)!
        canvas.cacheDisplay(in: canvas.bounds, to: unselectedSnapshot)
        let originalInterior = unselectedSnapshot.colorAt(x: unselectedSnapshot.pixelsWide / 4, y: unselectedSnapshot.pixelsHigh / 2)!.usingColorSpace(.deviceRGB)!
        session.drawingTool = .magicWand; click(CGPoint(x: 20, y: 30))
        try require(session.effectiveSelectionPath!.contains(CGPoint(x: 20, y: 30)) && !session.effectiveSelectionPath!.contains(CGPoint(x: 100, y: 30)), "Native Magic Wand creates the expected selection")
        try require(session.document == document && session.history.undoStack.isEmpty && !session.isDirty, "Magic Wand selection preserves every source pixel and layer without a document edit")
        let selectedSnapshot = canvas.bitmapImageRepForCachingDisplay(in: canvas.bounds)!
        canvas.cacheDisplay(in: canvas.bounds, to: selectedSnapshot)
        try selectedSnapshot.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("magic-wand-selection.png"))
        let selectedInterior = selectedSnapshot.colorAt(x: selectedSnapshot.pixelsWide / 4, y: selectedSnapshot.pixelsHigh / 2)!.usingColorSpace(.deviceRGB)!
        try require(abs(selectedInterior.redComponent - originalInterior.redComponent) < 0.01 && abs(selectedInterior.greenComponent - originalInterior.greenComponent) < 0.01 && abs(selectedInterior.blueComponent - originalInterior.blueComponent) < 0.01, "Magic Wand outline does not cover the selected artwork")
        let deleteKey = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil, characters: "\u{8}", charactersIgnoringModifiers: "\u{8}", isARepeat: false, keyCode: 51)!
        canvas.keyDown(with: deleteKey)
        try require(session.document.elements.count == 1 && session.selectedID == layer.id, "Delete after Magic Wand clears selected pixels instead of removing the layer")
        try require(color(session.selected!, 32, 48).alphaComponent < 0.01 && color(session.selected!, 100, 48).alphaComponent > 0.99, "Delete preserves pixels outside the Magic Wand selection")
        session.undo(); try require(session.document == document, "Undo restores pixels cleared from a color selection")
        session.selectionRect = nil; session.drawingTool = .singleRow; click(CGPoint(x: 20, y: 30))
        try require(session.selectionRect?.height == 1, "Single Row Marquee creates a one-pixel selection")
        session.selectionRect = nil; session.drawingTool = .polygonLasso
        click(CGPoint(x: 10, y: 10)); click(CGPoint(x: 60, y: 10)); click(CGPoint(x: 35, y: 70)); canvas.finishPolygonSelection()
        try require(session.effectiveSelectionPath!.contains(CGPoint(x: 35, y: 30)) && !session.effectiveSelectionPath!.contains(CGPoint(x: 10, y: 60)), "Polygonal Lasso closes the clicked vertices")
        session.selectionRect = nil; session.drawingTool = .cloneStamp
        click(CGPoint(x: 20, y: 48), flags: .option); click(CGPoint(x: 100, y: 48))
        try require(color(session.selected!, 100, 48).redComponent > 0.95, "Native clone sampling and painting dispatch to the raster engine")
        session.undo(); try require(session.selected?.imageData == layer.imageData, "Retouching gestures undo as one operation")
        session.selectionRect = nil; session.drawingTool = .selectionBrush; session.brushSize = 10
        canvas.mouseDown(with: event(.leftMouseDown, CGPoint(x: 20, y: 20))); canvas.mouseDragged(with: event(.leftMouseDragged, CGPoint(x: 70, y: 20))); canvas.mouseUp(with: event(.leftMouseUp, CGPoint(x: 70, y: 20)))
        try require(session.effectiveSelectionPath!.contains(CGPoint(x: 40, y: 20)) && !session.effectiveSelectionPath!.contains(CGPoint(x: 40, y: 40)), "Selection Brush uses the painted stroke footprint")
        session.selectionRect = nil; session.drawingTool = .ruler
        canvas.mouseDown(with: event(.leftMouseDown, .zero)); canvas.mouseDragged(with: event(.leftMouseDragged, CGPoint(x: 30, y: 40))); canvas.mouseUp(with: event(.leftMouseUp, CGPoint(x: 30, y: 40)))
        try require(session.measurement.map { hypot($0.end.x - $0.start.x, $0.end.y - $0.start.y) == 50 } == true, "Ruler measures document-space distance")
        session.drawingTool = .pencil; session.brushSize = 1; session.drawingColor = "000000"
        click(CGPoint(x: 30.5, y: 30.5))
        try require(color(session.selected!, 30, 30).redComponent < 0.05, "Pencil writes a hard one-pixel mark")
        session.drawingTool = .roundedRectangle
        canvas.mouseDown(with: event(.leftMouseDown, CGPoint(x: 5, y: 5))); canvas.mouseDragged(with: event(.leftMouseDragged, CGPoint(x: 45, y: 45))); canvas.mouseUp(with: event(.leftMouseUp, CGPoint(x: 45, y: 45)))
        try require((session.selected?.cornerRadius ?? 0) > 0, "Rounded Rectangle creates editable corner geometry")
        session.drawingTool = .polygon; session.pixelSettings.polygonSides = 6
        canvas.mouseDown(with: event(.leftMouseDown, CGPoint(x: 50, y: 5))); canvas.mouseDragged(with: event(.leftMouseDragged, CGPoint(x: 90, y: 45))); canvas.mouseUp(with: event(.leftMouseUp, CGPoint(x: 90, y: 45)))
        try require(session.selected?.vectorPath?.count == 7 && session.selected?.kind == .path, "Polygon creates the configured number of editable sides")
        try require(PixelToolbar.nextTool(key: "B", current: .brush, cycling: true) == .pencil, "Shift shortcuts cycle grouped tools")
        try require(PixelToolbar.groups.flatMap(\.tools).allSatisfy { NSImage(systemSymbolName: $0.symbol, accessibilityDescription: nil) != nil }, "All supported toolbar tools have native icons")
        try document.encoded().write(to: directory.appendingPathComponent("toolbar-fixture.devin"))
        window.contentView = nil
        return checks
    }
}
