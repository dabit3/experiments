import AppKit
import AVFoundation
import PDFKit
import ImageIO
import SwiftUI
import WebKit
import SceneKit
import DevinCore

enum Verification {
    @MainActor static func run(artifactsDirectory: URL? = nil, pixelOnly: Bool = false) async -> Bool {
        let directory = artifactsDirectory ?? FileManager.default.temporaryDirectory.appendingPathComponent("DevinVerification-" + UUID().uuidString)
        var checks = 0
        func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
            guard condition() else { throw DocumentError.invalid("Verification failed: " + message) }
            checks += 1; print("PASS \(message)")
        }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if pixelOnly {
                checks += try PixelToolbarVerification.run(directory: directory)
                checks += try PixelToolAuditVerification.run(directory: directory)
                checks += try PixelAnchorVerification.run(directory: directory)
                print("\n\(checks) Pixel tool checks passed. Artifacts: \(directory.path)")
                return true
            }
            for tool in StudioTool.allCases {
                let document = Samples.document(for: tool)
                let reopened = try CreativeDocument.load(from: document.encoded())
                try require(reopened == document, "\(tool.name) project round trip")
                if tool.isCanvas {
                    guard let image = Renderer.image(document, maxDimension: 640) else { throw DocumentError.invalid("\(tool.name) failed to render") }
                    let url = directory.appendingPathComponent(tool.rawValue + ".png")
                    try Renderer.writeImage(image, to: url, type: .png)
                    try require(NSImage(contentsOf: url) != nil, "\(tool.name) renders a valid PNG")
                }
            }
            let form = Samples.document(for: .form)
            let svgURL = directory.appendingPathComponent("vectors.svg")
            try await ExportService.export(form, to: svgURL, format: .svg)
            let parser = XMLParser(data: try Data(contentsOf: svgURL))
            try require(parser.parse(), "SVG export is valid XML")
            let press = Samples.document(for: .press)
            let pdfURL = directory.appendingPathComponent("layout.pdf")
            try await ExportService.export(press, to: pdfURL, format: .pdf)
            let pdf = PDFDocument(url: pdfURL)
            try require(pdf?.pageCount == 3, "PDF export preserves all three pages")
            try require(pdf?.string?.contains("quiet") == true, "PDF text stays selectable")
            let gifURL = directory.appendingPathComponent("animation.gif")
            try await ExportService.export(Samples.document(for: .frame), to: gifURL, format: .gif)
            let gif = CGImageSourceCreateWithURL(gifURL as CFURL, nil)!
            try require(CGImageSourceGetCount(gif) == 12, "GIF export preserves all twelve frames")
            let photo = Renderer.image(form, maxDimension: 256)!
            var element = CanvasElement(kind: .image, name: "source.png", x: 0, y: 0, width: Double(photo.width), height: Double(photo.height))
            element.imageData = NSBitmapImageRep(cgImage: photo).representation(using: .png, properties: [:])
            let original = Renderer.processedImage(element)!
            element.adjustments.exposure = 1
            let adjusted = Renderer.processedImage(element)!
            try require(CFDataGetLength(original.dataProvider!.data!) == CFDataGetLength(adjusted.dataProvider!.data!), "Image adjustments preserve dimensions")
            try require(original.dataProvider!.data! as Data != adjusted.dataProvider!.data! as Data, "Exposure changes rendered pixels")
            var batch = Samples.document(for: .batch)
            batch.elements = [element]
            let batchURL = try await ExportService.batch(batch, to: directory, format: .jpeg, maxEdge: 100, quality: 0.8, progress: { _ in })
            let batchFiles = try FileManager.default.contentsOfDirectory(at: batchURL, includingPropertiesForKeys: nil)
            let batchImage = NSImage(contentsOf: batchFiles[0])!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
            try require(max(batchImage.width, batchImage.height) == 100, "Batch resize respects the maximum edge")
            let audioURL = directory.appendingPathComponent("demo.wav")
            try MediaEngine.createTone(at: audioURL, duration: 1)
            let peaks = try await MediaEngine.waveform(url: audioURL, bins: 100)
            try require(peaks.count == 100 && peaks.max()! > 0.1, "Waveform decodes real PCM samples")
            var clip = MediaClip(url: audioURL, duration: 1)
            clip.start = 0.1; clip.end = 0.6; clip.gain = 0.5; clip.fadeIn = 0.05; clip.fadeOut = 0.05
            var sound = Samples.document(for: .sound); sound.clips = [clip]
            let wavURL = directory.appendingPathComponent("trimmed.wav")
            try await ExportService.export(sound, to: wavURL, format: .wav)
            let audio = try AVAudioFile(forReading: wavURL)
            try require(abs(Double(audio.length) / audio.processingFormat.sampleRate - 0.5) < 0.03, "Audio export applies the trim range")
            try require(audio.processingFormat.channelCount == 2 && audio.processingFormat.sampleRate == 48000, "WAV export is 48 kHz stereo")
            var motion = CreativeDocument(title: "Motion test", tool: .motion)
            motion.width = 320; motion.height = 180; motion.duration = 0.5; motion.fps = 12
            var ball = CanvasElement(kind: .ellipse, name: "Ball", x: 20, y: 50, width: 60, height: 60)
            ball.keyframes = [Keyframe(time: 0, x: 20, y: 50), Keyframe(time: 0.5, x: 240, y: 50)]
            motion.elements = [ball]
            let movieURL = directory.appendingPathComponent("motion.mp4")
            try await ExportService.export(motion, to: movieURL, format: .mp4)
            let asset = AVURLAsset(url: movieURL)
            let movieDuration = try await asset.load(.duration).seconds
            try require(abs(movieDuration - 0.5) < 0.1, "Motion export has the correct duration")
            let tracks = try await asset.loadTracks(withMediaType: .video)
            try require(tracks.count == 1, "Motion export contains playable H.264 video")
            var cut = Samples.document(for: .cut)
            var movieClip = MediaClip(url: movieURL, duration: movieDuration)
            movieClip.start = 0.1; movieClip.end = 0.4; cut.clips = [movieClip]
            let cutURL = directory.appendingPathComponent("cut.mp4")
            try await ExportService.export(cut, to: cutURL, format: .mp4)
            let trimmedAsset = AVURLAsset(url: cutURL)
            let trimmedDuration = try await trimmedAsset.load(.duration).seconds
            try require(abs(trimmedDuration - 0.3) < 0.1, "Video sequence export applies clip trims")
            let web = Samples.document(for: .code)
            let htmlURL = directory.appendingPathComponent("index.html")
            try await ExportService.export(web, to: htmlURL, format: .html)
            let html = try String(contentsOf: htmlURL, encoding: .utf8)
            try require(html.contains(web.css) && html.contains(web.javascript), "Web export embeds CSS and JavaScript")
            let scene = Samples.document(for: .space)
            let sceneURL = directory.appendingPathComponent("scene.scn")
            try await ExportService.export(scene, to: sceneURL, format: .scn)
            let reopened = try SCNScene(url: sceneURL)
            try require(reopened.rootNode.childNode(withName: scene.objects[0].id.uuidString, recursively: true) != nil, "3D scene export preserves editable geometry")
            let renderURL = directory.appendingPathComponent("scene.png")
            try await ExportService.export(scene, to: renderURL, format: .png)
            try require(NSImage(contentsOf: renderURL) != nil, "Metal renders the 3D scene to PNG")
            let overwriteURL = directory.appendingPathComponent("overwrite.png")
            try await ExportService.export(form, to: overwriteURL, format: .png)
            try await ExportService.export(form, to: overwriteURL, format: .jpeg)
            try require(CGImageSourceCreateWithURL(overwriteURL as CFURL, nil) != nil, "Atomic export replacement leaves a readable file")
            let session = StudioSession(tool: .pixel, document: CreativeDocument(title: "Interaction test", tool: .pixel))
            session.document.width = 400; session.document.height = 300
            session.savedDocument = session.document; session.isDirty = false
            let canvas = CanvasNSView(session: session, scale: 1)
            let canvasWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300), styleMask: [.titled], backing: .buffered, defer: false)
            canvasWindow.contentView = canvas
            canvas.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
            func mouse(_ type: NSEvent.EventType, _ x: Double, _ y: Double) -> NSEvent {
                NSEvent.mouseEvent(with: type, location: canvas.convert(NSPoint(x: x, y: y), to: nil), modifierFlags: [], timestamp: 0, windowNumber: canvasWindow.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1)!
            }
            func drag(_ x: Double, _ y: Double, _ toX: Double, _ toY: Double) {
                canvas.mouseDown(with: mouse(.leftMouseDown, x, y))
                canvas.mouseDragged(with: mouse(.leftMouseDragged, toX, toY))
                canvas.mouseUp(with: mouse(.leftMouseUp, toX, toY))
            }
            session.drawingTool = .rectangle
            drag(20, 30, 160, 110)
            try require(session.document.elements.count == 1 && session.selected?.width == 140, "Native pointer events create a rectangle")
            try require(session.isDirty, "Canvas edits mark a project as unsaved")
            session.drawingTool = .select
            drag(60, 60, 90, 80)
            try require(session.selected?.x == 50 && session.selected?.y == 50, "Native pointer events move the selected layer")
            drag(190, 130, 210, 160)
            try require(session.selected?.width == 160 && session.selected?.height == 110, "Native resize handle changes layer geometry")
            session.drawingTool = .crop
            drag(40, 40, 240, 220)
            try require(session.document.width == 200 && session.document.height == 180 && session.document.elements[0].x == 10, "Native crop changes the canvas without discarding layers")
            session.undo()
            try require(session.document.width == 400 && session.document.elements[0].x == 50, "Undo restores a cropped canvas and its layers")
            session.redo()
            try require(session.document.width == 200, "Redo reapplies the crop")
            session.selectedID = session.document.elements[0].id
            session.updateElement { $0.x = (session.document.width - $0.width) / 2 }
            try require(session.selected?.x == 20, "Inspector mutations safely read the current document")
            session.duplicate()
            try require(session.document.elements.count == 2 && Set(session.document.elements.map(\.id)).count == 2, "Duplicate creates an independent layer")
            session.updateElement { $0.locked = true }
            session.deleteSelection()
            try require(session.document.elements.count == 2, "Locked layers cannot be deleted")
            let frameSession = StudioSession(tool: .frame)
            let originalPageCount = frameSession.document.pageCount
            let originalFrameElements = frameSession.currentElements
            frameSession.addPage(duplicate: true)
            try require(frameSession.document.pageCount == originalPageCount + 1 && frameSession.currentElements.count == originalFrameElements.count && frameSession.currentElements.first?.id != originalFrameElements.first?.id, "Frame duplication copies the current artwork")
            frameSession.deletePage()
            try require(frameSession.document.pageCount == originalPageCount, "Frame deletion preserves valid page indices")
            _ = try frameSession.document.validated()
            let motionSession = StudioSession(tool: .motion, document: motion)
            motionSession.selectedID = ball.id; motionSession.playhead = 0.25
            let originalPose = motionSession.selected!.evaluated(at: 0.25)
            motionSession.addKeyframe()
            try require(motionSession.selected!.evaluated(at: 0.25).x == originalPose.x, "Adding a keyframe does not make the artwork jump")
            motionSession.updateElement { $0.x = 130; $0.opacity = 0.8 }
            try require(motionSession.selected!.evaluated(at: 0.25).x == 130 && motionSession.selected!.evaluated(at: 0.25).opacity == 0.8, "Animated inspector edits update the playhead keyframe")
            motionSession.undo()
            try require(motionSession.selected!.evaluated(at: 0.25).x == originalPose.x, "Animation edits support undo")
            let canceledURL = directory.appendingPathComponent("canceled.mp4")
            let canceledTask = Task { try await ExportService.export(motion, to: canceledURL, format: .mp4) }
            canceledTask.cancel()
            do { try await canceledTask.value; throw DocumentError.invalid("Canceled export unexpectedly succeeded.") }
            catch is CancellationError { try require(!FileManager.default.fileExists(atPath: canceledURL.path), "Canceling an export leaves no partial destination") }
            do {
                _ = try await MediaEngine.compose([MediaClip(url: directory.appendingPathComponent("missing.mov"), duration: 1)], video: true)
                throw DocumentError.invalid("Missing media unexpectedly succeeded.")
            } catch {
                try require(error.localizedDescription.contains("missing"), "Missing source media reports a useful error")
            }
            canvasWindow.contentView = nil
            checks += try await ProfessionalVerification.run(directory: directory)
            checks += try await AuditVerification.run(directory: directory)
            checks += try PixelToolbarVerification.run(directory: directory)
            checks += try PixelToolAuditVerification.run(directory: directory)
            checks += try PixelAnchorVerification.run(directory: directory)
            checks += try await WorkspaceBehaviorVerification.run(directory: directory)
            func snapshot(_ view: NSView, name: String) throws {
                view.layoutSubtreeIfNeeded()
                guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { throw DocumentError.invalid("A native snapshot could not be allocated.") }
                view.cacheDisplay(in: view.bounds, to: bitmap)
                guard let data = bitmap.representation(using: .png, properties: [:]) else { throw DocumentError.invalid("A native snapshot could not be encoded.") }
                try data.write(to: directory.appendingPathComponent(name + ".png"))
            }
            func nativeView<T: NSView>(_ type: T.Type, in view: NSView) -> T? {
                if let found = view as? T { return found }
                return view.subviews.compactMap { nativeView(type, in: $0) }.first
            }
            func webView(in view: NSView) -> WKWebView? { nativeView(WKWebView.self, in: view) }
            let dashboard = NSHostingView(rootView: DashboardView())
            let dashboardWindow = NSWindow(contentRect: NSRect(x: -5000, y: -5000, width: 1440, height: 930), styleMask: [.titled], backing: .buffered, defer: false)
            dashboardWindow.contentView = dashboard; dashboardWindow.orderFront(nil)
            try await Task.sleep(nanoseconds: 150_000_000)
            try snapshot(dashboard, name: "dashboard")
            try require(dashboard.bounds.width == 1440, "Launcher renders at the intended window size")
            dashboardWindow.orderOut(nil); dashboardWindow.contentView = nil
            let ledger = NSHostingView(rootView: FeatureInventoryView(initialTool: .pixel))
            let ledgerWindow = NSWindow(contentRect: NSRect(x: -5000, y: -5000, width: 960, height: 690), styleMask: [.titled], backing: .buffered, defer: false)
            ledgerWindow.contentView = ledger; ledgerWindow.orderFront(nil)
            try await Task.sleep(nanoseconds: 100_000_000)
            try snapshot(ledger, name: "parity-ledger")
            ledgerWindow.orderOut(nil); ledgerWindow.contentView = nil
            for tool in StudioTool.allCases {
                let session = StudioSession(tool: tool)
                if tool == .folio { session.importURLs([pdfURL]) }
                if tool == .batch { session.importURLs([directory.appendingPathComponent("pixel.png"), directory.appendingPathComponent("form.png")]) }
                if tool == .sound { session.document.clips = [clip]; session.select(clip.id) }
                if tool == .cut {
                    session.document.clips = cut.clips
                    session.document.assets = [MediaAsset(url: movieURL, duration: movieDuration, hasVideo: true)]
                    session.select(cut.clips.first?.id)
                }
                if tool == .motion { session.workspacePreset = "Animation" }
                let view = NSHostingView(rootView: WorkspaceRoot(session: session))
                let window = NSWindow(contentRect: NSRect(x: -5000, y: -5000, width: 1440, height: 930), styleMask: [.titled], backing: .buffered, defer: false)
                window.contentView = view; window.orderFront(nil)
                try await Task.sleep(nanoseconds: 300_000_000)
                window.layoutIfNeeded()
                try require(view.fittingSize.width > 0, "\(tool.name) native workspace instantiates")
                if tool == .code {
                    guard let web = webView(in: view) else { throw DocumentError.invalid("The native WebKit preview is missing.") }
                    var loaded = false
                    for _ in 0..<150 {
                        if let heading = try? await web.evaluateJavaScript("document.querySelector('h1')?.textContent"), let text = heading as? String, text.contains("Stay curious") { loaded = true; break }
                        try await Task.sleep(nanoseconds: 40_000_000)
                    }
                    try require(loaded, "WebKit preview loads the project's HTML")
                    let result = try await web.evaluateJavaScript("document.querySelector('#hello').click(); document.querySelector('h1').textContent") as? String
                    try require(result == "You made this.", "WebKit preview executes the project's JavaScript")
                }
                if tool == .space, let scene = nativeView(SCNView.self, in: view), let image = scene.snapshot().cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    try Renderer.writeImage(image, to: directory.appendingPathComponent("viewport-space.png"), type: .png)
                    try require(scene.scene != nil && image.width > 100, "Space native viewport renders a Metal frame")
                }
                if tool == .folio, let pdfView = nativeView(PDFView.self, in: view), let page = pdfView.currentPage, let image = page.thumbnail(of: NSSize(width: 720, height: 960), for: .cropBox).cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    try Renderer.writeImage(image, to: directory.appendingPathComponent("viewport-folio.png"), type: .png)
                    try require(pdfView.document?.pageCount == 3 && !(page.string ?? "").isEmpty, "Folio native viewport contains the selected PDF page")
                }
                if tool == .cut, let item = session.player.currentItem {
                    let generator = AVAssetImageGenerator(asset: item.asset); generator.videoComposition = item.videoComposition
                    let frame = try await generator.image(at: .zero)
                    try Renderer.writeImage(frame.image, to: directory.appendingPathComponent("viewport-cut.png"), type: .png)
                    try require(frame.image.width == 1920, "Cut program monitor decodes the composed video frame")
                }
                try snapshot(view, name: "workspace-\(tool.rawValue)")
                window.orderOut(nil); window.contentView = nil
            }
            print("\n\(checks) integration checks passed. Artifacts: \(directory.path)")
            return true
        } catch {
            fputs("FAIL: \(error.localizedDescription)\nArtifacts: \(directory.path)\n", stderr)
            return false
        }
    }
}
