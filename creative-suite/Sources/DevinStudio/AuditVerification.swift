import AppKit
import AVFoundation
import SwiftUI
import DevinCore

@MainActor enum AuditVerification {
    static func run(directory: URL) async throws -> Int {
        var checks = 0
        var failures: [String] = []
        func check(_ condition: @autoclosure () -> Bool, _ name: String) {
            if condition() { checks += 1; print("PASS " + name) }
            else { failures.append(name); print("FAIL " + name) }
        }
        var document = CreativeDocument(title: "Audit", tool: .pixel)
        document.width = 200; document.height = 200
        var a = CanvasElement(kind: .rectangle, name: "A", x: 10, y: 10, width: 50, height: 50)
        a.locked = true; document.elements = [a]
        let session = StudioSession(tool: .pixel, document: document)
        session.select(a.id)
        session.updateElement { $0.x = 99; $0.fill = "FF0000" }
        check(session.selected?.x == 10 && session.selected?.fill == a.fill, "Locked layers reject inspector edits")
        session.updateElement { $0.locked = false }
        check(session.selected?.locked == false, "Locked layers can still be unlocked")
        var b = a; b.id = UUID(); b.page = 1
        session.document.pageCount = 2; session.document.elements.append(b)
        session.additionalSelection = [a.id]
        session.page = 1
        check(session.selectedIDs.isEmpty, "Page changes clear cross-page selections")
        var c = a; c.id = UUID(); c.name = "C"; c.locked = false
        session.document.elements = [a, b, c]
        session.reorder(a.id, offset: 1)
        check(session.document.elements.first?.id == c.id, "Layer ordering skips layers on other pages")
        let canvas = CanvasNSView(session: session, scale: 1)
        check(canvas.responds(to: NSSelectorFromString("copy:")) && canvas.responds(to: NSSelectorFromString("paste:")), "Canvas implements native clipboard commands")
        let fill = CanvasElement(kind: .rectangle, name: "Fill", x: 0, y: 0, width: 80, height: 40, fill: "FF0000")
        var imageDocument = CreativeDocument(title: "Paint", tool: .pixel)
        imageDocument.width = 80; imageDocument.height = 40; imageDocument.elements = [fill]
        let cg = Renderer.image(imageDocument)!
        var layer = CanvasElement(kind: .image, name: "Image", x: 0, y: 0, width: 80, height: 40)
        layer.imageData = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])
        let erased = try RasterEditing.paint(layer, document: imageDocument, points: [CGPoint(x: 10, y: 20), CGPoint(x: 60, y: 20)], size: 10, color: "000000", opacity: 0.5, erase: true, selection: nil)
        let alpha = NSBitmapImageRep(data: erased.imageData!)!.colorAt(x: 30, y: 20)!.alphaComponent
        check(alpha > 0.4 && alpha < 0.6, "Eraser opacity produces partial transparency")
        let soft = try RasterEditing.paint(nil, document: imageDocument, points: [CGPoint(x: 40, y: 20)], size: 30, color: "FF0000", opacity: 1, erase: false, selection: nil, hardness: 0.2)
        let softBitmap = NSBitmapImageRep(data: soft.imageData!)!
        check(softBitmap.colorAt(x: 40, y: 20)!.alphaComponent > softBitmap.colorAt(x: 52, y: 20)!.alphaComponent && softBitmap.colorAt(x: 52, y: 20)!.alphaComponent > 0, "Soft brushes produce a graded edge")
        var masked = layer
        masked.maskData = RasterEditing.selectionMask(nil, layer: layer)
        let paintedMask = try RasterEditing.paint(masked, document: imageDocument, points: [CGPoint(x: 15, y: 20)], size: 16, color: "000000", opacity: 1, erase: false, selection: nil, target: .mask)
        check(paintedMask.imageData == masked.imageData && paintedMask.maskData != masked.maskData, "Painting a mask leaves original image pixels unchanged")
        let visible = NSBitmapImageRep(cgImage: Renderer.processedImage(paintedMask)!)
        check(visible.colorAt(x: 15, y: 20)!.alphaComponent < 0.1 && visible.colorAt(x: 65, y: 20)!.alphaComponent > 0.9, "Painted masks affect the rendered image")
        imageDocument.elements = [layer]
        let clipboardSession = StudioSession(tool: .pixel, document: imageDocument)
        clipboardSession.select(layer.id); canvas.session = clipboardSession
        let board = NSPasteboard.withUniqueName()
        check(canvas.copyLayers(to: board), "Layer copy writes a private test clipboard")
        canvas.pasteLayers(from: board)
        check(clipboardSession.document.elements.count == 2 && Set(clipboardSession.document.elements.map(\.id)).count == 2, "Layer paste creates independently editable layers")
        clipboardSession.undo()
        check(clipboardSession.document.elements.count == 1, "Clipboard paste supports undo")
        board.releaseGlobally()
        clipboardSession.setSelection(CGPath(ellipseIn: CGRect(x: 10, y: 5, width: 60, height: 30), transform: nil))
        check(clipboardSession.effectiveSelectionPath!.contains(CGPoint(x: 40, y: 20)) && !clipboardSession.effectiveSelectionPath!.contains(CGPoint(x: 11, y: 6)), "Elliptical selections use the ellipse, not its bounding box")
        clipboardSession.invertSelection()
        check(!clipboardSession.effectiveSelectionPath!.contains(CGPoint(x: 40, y: 20)) && clipboardSession.effectiveSelectionPath!.contains(CGPoint(x: 2, y: 2)), "Selection inversion selects the complementary area")
        var animated = CanvasElement(kind: .rectangle, name: "Animated", x: 0, y: 0, width: 40, height: 40)
        animated.setPropertyKeyframe(.positionX, at: 0, value: 0); animated.setPropertyKeyframe(.positionX, at: 2, value: 100)
        var motionDocument = CreativeDocument(title: "Independent animation", tool: .motion)
        motionDocument.width = 160; motionDocument.height = 90; motionDocument.duration = 2; motionDocument.fps = 12; motionDocument.elements = [animated]
        let motion = StudioSession(tool: .motion, document: motionDocument); motion.select(animated.id); motion.playhead = 1
        motion.updateElement { $0.opacity = 0.5 }
        check(motion.selected!.effectiveAnimationChannels.count == 1 && motion.selected!.effectiveAnimationChannels[0].keyframes.count == 2, "Unanimated property edits do not add unrelated keyframes")
        motion.toggleAnimation(.opacity, layerID: animated.id); motion.playhead = 2; motion.updateElement { $0.opacity = 1 }
        check(motion.selected!.animationValue(.opacity, at: 1.5) == 0.75 && motion.selected!.animationValue(.positionX, at: 1.5) == 75, "Motion inspector edits animate properties independently")
        motion.updateElement { $0.locked = true }
        let locked = motion.document
        motion.setAnimationValue(10, property: .positionX, layerID: animated.id, addKey: true)
        check(motion.document == locked, "Locked animation channels cannot be changed")
        motion.playhead = motion.document.duration; motion.togglePlayback()
        check(motion.isPlaying && motion.playhead == motion.document.playbackArea.start, "Playback shortcuts restart Motion from the work-area start")
        motion.togglePlayback()
        let emptySound = StudioSession(tool: .sound); emptySound.togglePlayback()
        check(!emptySound.isPlaying, "Playback shortcuts do not start an empty audio session")
        let range = WorkArea(start: 0.5, end: 1.25)
        let rangeURL = directory.appendingPathComponent("work-area.mp4")
        try await ExportService.export(motionDocument, to: rangeURL, format: .mp4, range: range)
        let movie = AVURLAsset(url: rangeURL)
        let rangeDuration = try await movie.load(.duration).seconds
        check(abs(rangeDuration - range.duration) < 0.005, "Motion exports the selected work area with exact duration")
        let lens = StudioSession(tool: .lens, document: CreativeDocument(title: "Photos", tool: .lens))
        lens.importURLs([directory.appendingPathComponent("motion.png")])
        check(lens.document.pageCount == 1 && lens.selected?.kind == .image, "Lens import reuses an empty first page and selects the photo")
        let ratio = lens.selected!.width / lens.selected!.height
        lens.fitSelectedImage()
        check(abs(lens.selected!.width / lens.selected!.height - ratio) < 0.0001, "Image fitting preserves the source aspect ratio")
        let frameSession = StudioSession(tool: .frame, document: CreativeDocument(title: "Frames", tool: .frame))
        frameSession.importURLs([directory.appendingPathComponent("pixel.png"), directory.appendingPathComponent("form.png")])
        check(frameSession.document.pageCount == 2 && Set(frameSession.document.elements.map(\.page)).count == 2, "Frame imports multiple images as separate animation frames")
        let frameID = frameSession.document.elements[0].id
        frameSession.page = 0; frameSession.moveCurrentPage(1)
        check(frameSession.document.elements.first { $0.id == frameID }?.page == 1, "Frame ordering moves artwork without changing its identity")
        let tinyPage = CGRect(x: 0, y: 0, width: 20, height: 20)
        check(tinyPage.contains(PDFWorkspace.noteBounds(in: tinyPage)), "PDF note bounds stay inside small pages")
        let folio = StudioSession(tool: .folio)
        folio.importURLs([directory.appendingPathComponent("layout.pdf")])
        check(folio.document.pdfData != nil && StudioSession.importTypes(for: .folio).contains(.pdf), "Folio supports PDF import and the native Open file type")
        let cssURL = directory.appendingPathComponent("import.css"), jsURL = directory.appendingPathComponent("import.js")
        try "body { color: blue; }".write(to: cssURL, atomically: true, encoding: .utf8)
        try "console.log('imported');".write(to: jsURL, atomically: true, encoding: .utf8)
        let code = StudioSession(tool: .code)
        let originalHTML = code.document.html
        code.importURLs([cssURL, jsURL])
        check(code.document.html == originalHTML && code.document.css.contains("blue") && code.document.javascript.contains("imported"), "Code imports CSS and JavaScript without destroying the HTML")
        var spatial = Samples.document(for: .space)
        spatial.sceneCamera = SceneCamera(x: 4, y: 3, z: 9, pitch: -0.2, yaw: 0.3, roll: 0, fieldOfView: 50)
        let restored = try CreativeDocument.load(from: spatial.encoded())
        let camera = SceneGraph.make(restored).rootNode.childNode(withName: "camera", recursively: false)!
        check(abs(Double(camera.position.z) - 9) < 0.0001 && camera.camera?.fieldOfView == 50, "Space saves and restores the export camera")
        var invalidBatch = CreativeDocument(title: "Batch", tool: .batch); invalidBatch.elements = [layer]
        do { _ = try await ExportService.batch(invalidBatch, to: directory, format: .png, maxEdge: .nan, quality: 1, progress: { _ in }); check(false, "Batch rejects invalid resize dimensions") }
        catch { check(true, "Batch rejects invalid resize dimensions") }
        var transparent = imageDocument; transparent.elements = []; transparent.transparentBackground = true
        let pngURL = directory.appendingPathComponent("transparent.png"), jpegURL = directory.appendingPathComponent("flattened.jpeg")
        try await ExportService.export(transparent, to: pngURL, format: .png)
        try await ExportService.export(transparent, to: jpegURL, format: .jpeg)
        let png = NSBitmapImageRep(data: try Data(contentsOf: pngURL))!, jpeg = NSBitmapImageRep(data: try Data(contentsOf: jpegURL))!
        check(png.colorAt(x: 10, y: 10)!.alphaComponent < 0.01, "PNG export preserves a transparent canvas")
        check(jpeg.colorAt(x: 10, y: 10)!.redComponent > 0.95, "JPEG export flattens transparency onto white")
        check(FeatureInventory.all.count == 12 && FeatureInventory.all.allSatisfy { !$0.available.isEmpty && !$0.unavailable.isEmpty }, "Feature inventory covers all twelve apps and their remaining gaps")
        var logs: [String] = []
        let webWindow = NSWindow(contentRect: CGRect(x: -5000, y: -5000, width: 400, height: 300), styleMask: [.titled], backing: .buffered, defer: false)
        webWindow.contentView = NSHostingView(rootView: WebPreview(source: "<html><body><script>console.log('audit-console'); throw new Error('audit-error');</script></body></html>", onConsole: { logs.append($0) }).frame(width: 400, height: 300))
        webWindow.orderFront(nil)
        for _ in 0..<100 { if logs.contains(where: { $0.contains("audit-error") }) { break }; try await Task.sleep(nanoseconds: 40_000_000) }
        check(logs.contains { $0.contains("audit-console") } && logs.contains { $0.contains("audit-error") }, "WebKit surfaces console output and JavaScript errors")
        webWindow.orderOut(nil); webWindow.contentView = nil
        var sequence = motionDocument; sequence.width = 64; sequence.height = 64; sequence.duration = 0.25; sequence.transparentBackground = true; sequence.elements = []
        let frames = try await ExportService.frameSequence(sequence, to: directory)
        let files = try FileManager.default.contentsOfDirectory(at: frames, includingPropertiesForKeys: nil).filter { $0.pathExtension == "png" }
        let manifest = try JSONDecoder().decode(FrameSequenceManifest.self, from: Data(contentsOf: frames.appendingPathComponent("sequence.json")))
        check(files.count == 3 && manifest.fps == 12 && manifest.frames == 3, "Motion exports numbered image frames with timing metadata")
        let sequenceFrame = NSBitmapImageRep(data: try Data(contentsOf: frames.appendingPathComponent("frame_00000.png")))!
        check(sequenceFrame.colorAt(x: 10, y: 10)!.alphaComponent < 0.01, "Image-sequence export preserves transparent pixels")
        let beforeCancellation = Set(try FileManager.default.contentsOfDirectory(atPath: directory.path))
        let canceledSequence = Task { try await ExportService.frameSequence(sequence, to: directory) }
        canceledSequence.cancel()
        do { _ = try await canceledSequence.value; check(false, "Canceled frame export stops without partial files") }
        catch is CancellationError { let remaining = Set(try FileManager.default.contentsOfDirectory(atPath: directory.path)); check(remaining == beforeCancellation, "Canceled frame export stops without partial files") }
        if !failures.isEmpty { throw DocumentError.invalid("Feature audit failures: " + failures.joined(separator: "; ")) }
        return checks
    }
}
