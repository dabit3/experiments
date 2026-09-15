import SwiftUI
import AppKit
import AVFoundation
import CoreVideo
import UniformTypeIdentifiers
import PDFKit
import DevinCore

enum ExportFormat: String, CaseIterable, Identifiable {
    case png, jpeg, tiff, svg, pdf, gif, mp4, wav, html, scn, pngSequence
    var id: String { rawValue }
    var title: String {
        switch self {
        case .png: return "PNG image"
        case .jpeg: return "JPEG image"
        case .tiff: return "TIFF image"
        case .svg: return "SVG vector"
        case .pdf: return "PDF document"
        case .gif: return "Animated GIF"
        case .mp4: return "H.264 movie"
        case .wav: return "WAV audio"
        case .html: return "HTML website"
        case .scn: return "SceneKit scene"
        case .pngSequence: return "PNG image sequence"
        }
    }
    var type: UTType {
        switch self {
        case .png: return .png; case .jpeg: return .jpeg; case .tiff: return .tiff
        case .svg: return .svg; case .pdf: return .pdf; case .gif: return .gif
        case .mp4: return .mpeg4Movie; case .wav: return .wav; case .html: return .html
        case .scn: return UTType(filenameExtension: "scn") ?? .data
        case .pngSequence: return .folder
        }
    }
    static func available(for tool: StudioTool) -> [ExportFormat] {
        switch tool {
        case .pixel: return [.png, .jpeg, .tiff, .pdf]
        case .form: return [.svg, .png, .pdf]
        case .press: return [.pdf, .png]
        case .lens, .batch: return [.jpeg, .png, .tiff]
        case .cut, .motion: return [.mp4] + (tool == .motion ? [.png, .pngSequence] : [])
        case .sound: return [.wav]
        case .frame: return [.gif, .png, .pngSequence]
        case .folio: return [.pdf]
        case .code: return [.html]
        case .space: return [.png, .scn]
        }
    }
}

struct ExportSheet: View {
    @ObservedObject var session: StudioSession
    @State private var format: ExportFormat = .png
    @State private var quality = 0.92
    @State private var maxEdge = 2048.0
    @State private var workAreaOnly = false
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 15) {
                if !session.usesProfessionalWorkspace { ToolBadge(tool: session.tool, size: 48) }
                VStack(alignment: .leading, spacing: 5) { Text(session.usesProfessionalWorkspace ? "Export" : "Ready for the world.").font(.system(size: 25, weight: .medium)).tracking(-0.5); Text(session.document.title).font(.system(size: 12)).foregroundStyle(Theme.muted) }
            }
            VStack(alignment: .leading, spacing: 14) {
                PanelHeading(title: "Export format")
                Picker("Format", selection: $format) { ForEach(ExportFormat.available(for: session.tool)) { Text($0.title + ($0 == .pngSequence ? " (folder)" : "  (." + $0.rawValue + ")")).tag($0) } }.labelsHidden()
                if format == .jpeg { LabeledSlider(title: "Image quality", value: $quality, range: 0.1...1) }
                if session.tool == .motion && [.mp4, .pngSequence].contains(format) {
                    Toggle("Export work area only", isOn: $workAreaOnly).toggleStyle(.checkbox)
                    if workAreaOnly { Text("\(session.document.playbackArea.start.formatted())–\(session.document.playbackArea.end.formatted()) seconds").font(.system(size: 11)) }
                }
                if session.tool == .batch { NumberField(label: "Maximum edge (px)", value: $maxEdge, range: 16...16384) }
                Text(detail).font(.system(size: 11)).foregroundStyle(Theme.muted).lineSpacing(4)
            }.padding(20).background(Theme.background, in: RoundedRectangle(cornerRadius: 9))
            Text("Your editable project is separate. Save it as a .devin file to keep working on it later.").font(.system(size: 10)).foregroundStyle(Theme.muted).lineSpacing(3)
            HStack {
                Button("Cancel") { session.showExport = false }.buttonStyle(StudioButtonStyle(professional: session.usesProfessionalWorkspace)).keyboardShortcut(.cancelAction)
                Spacer()
                Button(session.tool == .batch ? "Choose folder…" : "Export…") { chooseDestination() }.buttonStyle(StudioButtonStyle(primary: true, professional: session.usesProfessionalWorkspace)).keyboardShortcut(.defaultAction)
            }
        }.padding(32).frame(width: 440).background(session.usesProfessionalWorkspace ? ProTheme.panel : Theme.panel).foregroundStyle(Theme.text).preferredColorScheme(.dark)
            .onAppear { format = ExportFormat.available(for: session.tool).first ?? .png }
    }
    var detail: String {
        if session.tool == .batch { return "Convert every queued image, preserve its aspect ratio, and save to a new export subfolder. Smaller images are not enlarged." }
        switch format {
        case .mp4: return session.tool == .cut ? "1080p · 30 fps · H.264 video with your trimmed audio, gain, and fades." : "\(Int(session.document.width)) × \(Int(session.document.height)) · \(session.document.fps) fps · \(session.document.duration.formatted()) seconds. Keyframes render to H.264."
        case .wav: return "48 kHz · stereo · 16-bit PCM. The full sequence is rendered with trims, gain, and fades."
        case .gif: return "\(session.document.pageCount) frames · \(session.document.fps) fps · loops forever."
        case .pngSequence: return "Numbered PNG frames preserve canvas transparency. A new subfolder includes a manifest with frame rate and range. The export limit is 10,000 frames."
        case .pdf: return session.tool == .folio ? "All pages, rotations, and annotations are included." : "Every page is exported with vector shapes and selectable text. Dimensions are in PDF points; output uses RGB, not a CMYK print profile."
        case .svg: return "Editable vector shapes and text. Raster layers are embedded with their image adjustments. Fonts must be available on the receiving system."
        case .html: return "A single HTML file with your CSS and JavaScript included."
        case .scn: return "Native SceneKit scene with geometry, cameras, lighting, and materials."
        default: return session.tool == .space ? "1600 × 1200 pixels, rendered from the saved scene camera, or the default camera if no view is saved." : "Current page · \(Int(session.document.width)) × \(Int(session.document.height)) pixels · sRGB color."
        }
    }
    func chooseDestination() {
        let url: URL
        if session.tool == .batch || format == .pngSequence {
            let panel = NSOpenPanel(); panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.canCreateDirectories = true; panel.prompt = "Export Here"
            guard panel.runModal() == .OK, let selected = panel.url else { return }; url = selected
        } else {
            let panel = NSSavePanel(); panel.allowedContentTypes = [format.type]
            panel.nameFieldStringValue = session.document.title + "." + format.rawValue
            guard panel.runModal() == .OK, let selected = panel.url else { return }; url = selected
        }
        session.showExport = false; session.busy = true; session.progress = 0
        let document = session.document, page = session.page, time = session.playhead
        let chosenFormat = format, chosenQuality = quality, chosenEdge = maxEdge
        let chosenRange = workAreaOnly && document.tool == .motion ? document.playbackArea : nil
        session.exportTask = Task { @MainActor in
            defer { session.busy = false; session.exportTask = nil; session.progress = 0 }
            let worker = Task.detached(priority: .userInitiated) { () throws -> URL in
                let progress: (Double) -> Void = { value in DispatchQueue.main.async { session.progress = value } }
                if chosenFormat == .pngSequence { return try await ExportService.frameSequence(document, to: url, range: chosenRange, progress: progress) }
                if document.tool == .batch {
                    return try await ExportService.batch(document, to: url, format: chosenFormat, maxEdge: chosenEdge, quality: chosenQuality, progress: progress)
                }
                try await ExportService.export(document, to: url, format: chosenFormat, page: page, time: time, quality: chosenQuality, range: chosenRange, progress: progress)
                return url
            }
            do {
                let result = try await withTaskCancellationHandler(operation: { try await worker.value }, onCancel: { worker.cancel() })
                session.lastExportURL = result; session.message = "Export complete"
            } catch is CancellationError { session.message = "Export canceled" }
            catch { session.error = error.localizedDescription }
        }
    }
}

enum ExportService {
    static func export(_ document: CreativeDocument, to destination: URL, format: ExportFormat, page: Int = 0, time: Double = 0, quality: Double = 0.92, range: WorkArea? = nil, progress: @escaping (Double) -> Void = { _ in }) async throws {
        _ = try document.validated()
        guard quality.isFinite, (0...1).contains(quality), time.isFinite, (0..<document.pageCount).contains(page) || document.tool == .folio else { throw DocumentError.invalid("The export page, time, or quality is invalid.") }
        let temporary = destination.deletingLastPathComponent().appendingPathComponent(".devin-export-\(UUID().uuidString).\(format.rawValue)")
        defer { try? FileManager.default.removeItem(at: temporary) }
        try Task.checkCancellation()
        switch format {
        case .png, .jpeg, .tiff:
            let image: CGImage
            if document.tool == .space { image = try SceneGraph.snapshot(document) }
            else {
                var renderingDocument = document
                if format == .jpeg && document.transparentBackground == true { renderingDocument.transparentBackground = false; renderingDocument.background = "FFFFFF" }
                guard let rendered = Renderer.image(renderingDocument, page: page, time: document.tool == .motion ? time : nil) else { throw DocumentError.invalid("The canvas could not be rendered. Reduce its size and try again.") }
                image = rendered
            }
            try Renderer.writeImage(image, to: temporary, type: format.type, quality: quality)
        case .svg:
            var copy = document
            for index in copy.elements.indices where copy.elements[index].kind == .image {
                if let cg = Renderer.processedImage(copy.elements[index]) { copy.elements[index].imageData = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) }
            }
            try SVGExporter.render(copy, page: page).write(to: temporary, atomically: true, encoding: .utf8)
        case .pdf:
            if document.tool == .folio {
                guard let data = document.pdfData, let pdf = PDFDocument(data: data), pdf.pageCount > 0 else { throw DocumentError.invalid("Open a PDF before exporting.") }
                try data.write(to: temporary, options: .atomic)
            } else { try Renderer.pdf(document, to: temporary) }
        case .pngSequence: throw DocumentError.invalid("Use the image-sequence export command with a parent folder.")
        case .gif: try Renderer.gif(document, to: temporary)
        case .html: try document.webSource().write(to: temporary, atomically: true, encoding: .utf8)
        case .wav: try await MediaEngine.exportAudio(document.clips, to: temporary, progress: progress)
        case .mp4:
            if document.tool == .motion { try await renderMotion(document, to: temporary, range: range, progress: progress) }
            else { try await MediaEngine.exportMovie(document.clips, to: temporary, progress: progress) }
        case .scn:
            guard SceneGraph.make(document).write(to: temporary, options: nil, delegate: nil, progressHandler: nil) else { throw DocumentError.invalid("The scene could not be written.") }
        }
        try Task.checkCancellation()
        if FileManager.default.fileExists(atPath: destination.path) { _ = try FileManager.default.replaceItemAt(destination, withItemAt: temporary) }
        else { try FileManager.default.moveItem(at: temporary, to: destination) }
        progress(1)
    }
    static func batch(_ document: CreativeDocument, to directory: URL, format: ExportFormat, maxEdge: Double, quality: Double, progress: @escaping (Double) -> Void) async throws -> URL {
        _ = try document.validated()
        guard [.png, .jpeg, .tiff].contains(format), maxEdge.isFinite, (16...16384).contains(maxEdge), quality.isFinite, (0...1).contains(quality) else { throw DocumentError.invalid("The batch format, size, or quality is invalid.") }
        let images = document.elements.filter { $0.kind == .image }
        guard !images.isEmpty else { throw DocumentError.invalid("Add images to the queue before exporting.") }
        let folder = directory.appendingPathComponent("Devin Export " + UUID().uuidString.prefix(8))
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            for (index, image) in images.enumerated() {
                try Task.checkCancellation()
                guard let cg = Renderer.processedImage(image) else { throw DocumentError.invalid("\(image.name) could not be decoded.") }
                let ratio = min(1, maxEdge / Double(max(cg.width, cg.height)))
                let width = max(1, Int(Double(cg.width) * ratio)), height = max(1, Int(Double(cg.height) * ratio))
                guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw DocumentError.invalid("The resized image buffer could not be allocated.") }
                if format == .jpeg { context.setFillColor(NSColor.white.cgColor); context.fill(CGRect(x: 0, y: 0, width: width, height: height)) }
                context.interpolationQuality = .high
                context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
                guard let resized = context.makeImage() else { throw DocumentError.invalid("The resized image could not be created.") }
                let safeName = URL(fileURLWithPath: image.name).deletingPathExtension().lastPathComponent
                let url = folder.appendingPathComponent(String(format: "%03d-", index + 1) + safeName + "." + format.rawValue)
                try Renderer.writeImage(resized, to: url, type: format.type, quality: quality)
                progress(Double(index + 1) / Double(images.count))
            }
            try Task.checkCancellation()
        } catch { try? FileManager.default.removeItem(at: folder); throw error }
        return folder
    }
    static func renderMotion(_ document: CreativeDocument, to url: URL, range: WorkArea? = nil, progress: @escaping (Double) -> Void) async throws {
        let area = range ?? WorkArea(start: 0, end: document.duration)
        guard area.start.isFinite, area.end.isFinite, area.start >= 0, area.end <= document.duration, area.duration > 0 else { throw DocumentError.invalid("The render range is invalid.") }
        let width = max(16, Int(document.width / 2) * 2), height = max(16, Int(document.height / 2) * 2)
        guard width <= 3840, height <= 2160 else { throw DocumentError.invalid("Movie export supports canvases up to 3840 × 2160 pixels.") }
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA, kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height, kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true])
        guard writer.canAdd(input) else { throw DocumentError.invalid("The H.264 encoder is unavailable.") }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? DocumentError.invalid("Movie writing could not start.") }
        writer.startSession(atSourceTime: .zero)
        let count = max(1, Int(ceil(area.duration * Double(document.fps) - 0.000000001)))
        do {
            for frame in 0..<count {
                try Task.checkCancellation()
                while !input.isReadyForMoreMediaData {
                    if writer.status == .failed { throw writer.error ?? DocumentError.invalid("The video encoder stopped.") }
                    try await Task.sleep(nanoseconds: 2_000_000)
                }
                guard let pool = adaptor.pixelBufferPool else { throw DocumentError.invalid("The movie pixel buffer pool is unavailable.") }
                var optional: CVPixelBuffer?
                guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &optional) == kCVReturnSuccess, let buffer = optional else { throw DocumentError.invalid("A movie frame could not be allocated.") }
                CVPixelBufferLockBaseAddress(buffer, [])
                guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) else {
                    CVPixelBufferUnlockBaseAddress(buffer, []); throw DocumentError.invalid("The movie drawing context could not be created.")
                }
                context.setFillColor(NSColor.black.cgColor); context.fill(CGRect(x: 0, y: 0, width: width, height: height))
                context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: Double(width) / document.width, y: -Double(height) / document.height)
                Renderer.draw(document, in: context, time: area.start + Double(frame) / Double(document.fps))
                CVPixelBufferUnlockBaseAddress(buffer, [])
                var description: CMVideoFormatDescription?
                guard CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: buffer, formatDescriptionOut: &description) == noErr, let description else { throw DocumentError.invalid("The movie frame format could not be described.") }
                var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: CMTimeScale(document.fps)), presentationTimeStamp: CMTime(value: Int64(frame), timescale: CMTimeScale(document.fps)), decodeTimeStamp: .invalid)
                var sample: CMSampleBuffer?
                guard CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: buffer, formatDescription: description, sampleTiming: &timing, sampleBufferOut: &sample) == noErr, let sample, input.append(sample) else { throw writer.error ?? DocumentError.invalid("The encoded movie frame could not be written.") }
                progress(Double(frame + 1) / Double(count))
            }
            input.markAsFinished()
            writer.endSession(atSourceTime: CMTime(seconds: area.duration, preferredTimescale: 60000))
            await writer.finishWriting()
            guard writer.status == .completed else { throw writer.error ?? DocumentError.invalid("Movie finalization failed.") }
        } catch { writer.cancelWriting(); throw error }
    }
}
