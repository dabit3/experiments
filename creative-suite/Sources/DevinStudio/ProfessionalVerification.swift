import AppKit
import AVFoundation
import DevinCore

@MainActor enum ProfessionalVerification {
    static func run(directory: URL) async throws -> Int {
        var checks = 0
        func require(_ condition: @autoclosure () -> Bool, _ name: String) throws {
            guard condition() else { throw DocumentError.invalid("Verification failed: " + name) }
            print("PASS " + name); checks += 1
        }
        var document = CreativeDocument(title: "Raster tools", tool: .pixel)
        document.width = 128; document.height = 128
        let session = StudioSession(tool: .pixel, document: document)
        let canvas = CanvasNSView(session: session, scale: 1)
        let window = NSWindow(contentRect: NSRect(x: -5000, y: -5000, width: 400, height: 300), styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = canvas; canvas.frame = CGRect(x: 0, y: 0, width: 400, height: 300)
        func mouse(_ type: NSEvent.EventType, _ point: CGPoint) -> NSEvent {
            NSEvent.mouseEvent(with: type, location: canvas.convert(point, to: nil), modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1)!
        }
        func drag(_ start: CGPoint, _ end: CGPoint) {
            canvas.mouseDown(with: mouse(.leftMouseDown, start)); canvas.mouseDragged(with: mouse(.leftMouseDragged, end)); canvas.mouseUp(with: mouse(.leftMouseUp, end))
        }
        session.drawingTool = .brush; session.drawingColor = "FF0000"; session.brushSize = 10
        drag(CGPoint(x: 10, y: 40), CGPoint(x: 100, y: 40))
        try require(session.selected?.kind == .image && session.selected?.imageData != nil, "Photoshop-style brush creates editable raster pixels")
        let painted = session.selected!
        let bitmap = NSBitmapImageRep(data: painted.imageData!)!
        try require((bitmap.colorAt(x: 30, y: 40)?.redComponent ?? 0) > 0.9, "Brush pixels use the foreground color")
        session.selectionRect = CGRect(x: 0, y: 0, width: 50, height: 128)
        session.drawingTool = .eraser
        drag(CGPoint(x: 10, y: 40), CGPoint(x: 100, y: 40))
        let erased = NSBitmapImageRep(data: session.selected!.imageData!)!
        try require((erased.colorAt(x: 30, y: 40)?.alphaComponent ?? 1) < 0.1 && (erased.colorAt(x: 80, y: 40)?.alphaComponent ?? 0) > 0.9, "Eraser respects the marquee selection")
        session.undo()
        try require(session.selected?.imageData == painted.imageData, "Raster strokes support undo")
        var masked = painted
        masked.maskData = RasterEditing.selectionMask(CGRect(x: 0, y: 0, width: 64, height: 128), layer: painted)
        let maskedBitmap = NSBitmapImageRep(cgImage: Renderer.processedImage(masked)!)
        try require((maskedBitmap.colorAt(x: 30, y: 40)?.alphaComponent ?? 0) > 0.9 && (maskedBitmap.colorAt(x: 80, y: 40)?.alphaComponent ?? 1) < 0.1, "Layer masks affect exported alpha without deleting pixels")
        var bottom = CanvasElement(kind: .rectangle, name: "Bottom", x: 0, y: 0, width: 128, height: 128, fill: "80FFFF")
        var top = bottom; top.id = UUID(); top.fill = "FF8080"; top.blendMode = .multiply
        document.elements = [bottom, top]
        let multiplied = NSBitmapImageRep(cgImage: Renderer.image(document)!)
        try require((multiplied.colorAt(x: 20, y: 20)?.redComponent ?? 1) < 0.6, "Multiply blend mode changes composited pixels")
        document.tool = .form; document.elements = []; document.width = 400; document.height = 300
        let form = StudioSession(tool: .form, document: document)
        canvas.session = form; form.drawingTool = .pen
        drag(CGPoint(x: 20, y: 20), CGPoint(x: 70, y: 20))
        drag(CGPoint(x: 120, y: 120), CGPoint(x: 160, y: 120))
        drag(CGPoint(x: 220, y: 20), CGPoint(x: 220, y: 20))
        let enter = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil, characters: "\r", charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36)!
        canvas.keyDown(with: enter)
        try require(form.selected?.vectorPath?.filter { $0.verb == .curve }.count == 2, "Pen gestures create cubic Bezier segments")
        try require(form.selected?.width == 200, "Completed pen paths normalize to their artwork bounds")
        form.drawingTool = .directSelect
        drag(CGPoint(x: 20, y: 20), CGPoint(x: 25, y: 30))
        try require(form.selected?.vectorPath?.first?.point == Point2D(5, 10), "Direct Selection edits individual path anchors")
        _ = try form.document.encoded()
        bottom = CanvasElement(kind: .rectangle, name: "A", x: 0, y: 0, width: 100, height: 100)
        top = CanvasElement(kind: .rectangle, name: "B", x: 50, y: 0, width: 100, height: 100)
        form.document.elements = [bottom, top]
        form.select(bottom.id); form.select(top.id, extending: true); form.combineShapes("Unite")
        try require(form.document.elements.count == 1 && form.selected?.width == 150, "Pathfinder unites actual vector geometry")
        let svg = SVGExporter.render(form.document)
        try require(svg.contains("<path") && svg.contains(" Z"), "Boolean results remain vector paths in SVG")
        var story = CreativeDocument(title: "Threaded story", tool: .press)
        var a = CanvasElement(kind: .text, name: "First frame", x: 20, y: 20, width: 160, height: 80)
        var b = CanvasElement(kind: .text, name: "Second frame", x: 200, y: 20, width: 160, height: 120)
        a.fontSize = 14; b.fontSize = 14
        a.text = String(repeating: "Text flows between linked frames. ", count: 30); b.text = ""
        a.nextTextFrame = b.id; story.elements = [a, b]
        let frames = TextFlow.elements(story)
        try require(!frames[0].text.isEmpty && frames[0].text.count < a.text.count && !frames[1].text.isEmpty, "InDesign-style text threading reflows the story")
        try require(TextFlow.overflows(story) == [b.id], "Overset detection identifies the final overflowing text frame")
        let press = StudioSession(tool: .press, document: story)
        press.addPage(duplicate: true)
        let copies = press.currentElements
        try require(copies[0].nextTextFrame == copies[1].id, "Duplicated pages keep independent text-frame links")
        press.deletePage()
        _ = try press.document.validated()
        press.select(b.id); press.deleteSelection()
        try require(press.document.elements[0].nextTextFrame == nil, "Deleting a linked text frame leaves a valid project")
        var first = MediaClip(url: directory.appendingPathComponent("motion.mp4"), duration: 0.5)
        first.timelineStart = 0; first.trackIndex = 0
        var second = first; second.id = UUID(); second.timelineStart = 0.25; second.trackIndex = 1
        var transform = VideoTransform(); transform.scale = 0.5; transform.x = 100
        second.videoTransform = transform
        let media = try await MediaEngine.compose([first, second], video: true)
        let trackCount = try await media.composition.loadTracks(withMediaType: .video).count
        try require(trackCount == 2, "Premiere-style tracks create separate composition tracks")
        let instructions = media.video?.instructions.compactMap { $0 as? AVVideoCompositionInstruction } ?? []
        try require(instructions.contains { $0.layerInstructions.count == 2 }, "Overlapping video tracks composite together")
        var cut = CreativeDocument(title: "Two tracks", tool: .cut); cut.clips = [first, second]
        let movie = directory.appendingPathComponent("multitrack.mp4")
        try await ExportService.export(cut, to: movie, format: .mp4)
        let asset = AVURLAsset(url: movie)
        let duration = try await asset.load(.duration).seconds
        try require(abs(duration - cut.sequenceDuration) < 0.005, "Multitrack movie export preserves the explicit sequence duration")
        var audioA = MediaClip(url: directory.appendingPathComponent("demo.wav"), duration: 1)
        audioA.end = 0.5; audioA.timelineStart = 0; audioA.gain = 0.25
        var audioB = audioA; audioB.id = UUID(); audioB.timelineStart = 0.2; audioB.trackIndex = 1
        var sound = CreativeDocument(title: "Audio mix", tool: .sound); sound.clips = [audioA, audioB]
        let wav = directory.appendingPathComponent("multitrack.wav")
        try await ExportService.export(sound, to: wav, format: .wav)
        let audio = try AVAudioFile(forReading: wav)
        try require(abs(Double(audio.length) / audio.processingFormat.sampleRate - 0.7) < 0.02, "Overlapping audio tracks mix to the correct duration")
        for tool in [StudioTool.pixel, .form, .press, .motion, .cut] {
            AppCoordinator.shared.installProfessionalMenus(StudioSession(tool: tool))
            let names = NSApp.mainMenu?.items.map(\.title) ?? []
            let expected = tool == .pixel ? "Image" : tool == .form ? "Object" : tool == .press ? "Layout" : tool == .motion ? "Composition" : "Sequence"
            try require(names.contains(expected), "\(tool.name) has its own native menu structure")
        }
        window.contentView = nil
        return checks
    }
}
