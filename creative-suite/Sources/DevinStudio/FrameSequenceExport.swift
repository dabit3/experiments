import Foundation
import DevinCore

struct FrameSequenceManifest: Codable {
    let fps: Int
    let frames: Int
    let sourceStart: Double
    let duration: Double
    let width: Double
    let height: Double
}

extension ExportService {
    static func frameSequence(_ document: CreativeDocument, to directory: URL, range: WorkArea? = nil, progress: @escaping (Double) -> Void = { _ in }) async throws -> URL {
        _ = try document.validated()
        guard document.tool == .motion || document.tool == .frame else { throw DocumentError.invalid("Image-sequence export is available in Motion and Frame.") }
        let area = range ?? WorkArea(start: 0, end: document.tool == .frame ? Double(document.pageCount) / Double(document.fps) : document.duration)
        guard area.start.isFinite, area.end.isFinite, area.start >= 0, area.duration > 0, document.tool != .motion || area.end <= document.duration else { throw DocumentError.invalid("The frame-sequence range is invalid.") }
        let count = document.tool == .frame ? document.pageCount : max(1, Int(ceil(area.duration * Double(document.fps) - 0.000000001)))
        guard count <= 10000 else { throw DocumentError.invalid("Export a work area with at most 10,000 frames.") }
        let id = UUID().uuidString
        let temporary = directory.appendingPathComponent(".devin-frames-" + id, isDirectory: true)
        let destination = directory.appendingPathComponent("Devin Frames " + id, isDirectory: true)
        try Task.checkCancellation()
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: temporary) }
        for index in 0..<count {
            try Task.checkCancellation()
            try autoreleasepool {
                let time = area.start + Double(index) / Double(document.fps)
                guard let image = Renderer.image(document, page: document.tool == .frame ? index : 0, time: document.tool == .motion ? time : nil) else { throw DocumentError.invalid("A sequence frame could not be rendered.") }
                try Renderer.writeImage(image, to: temporary.appendingPathComponent(String(format: "frame_%05d.png", index)), type: .png)
            }
            progress(Double(index + 1) / Double(count))
        }
        let manifest = FrameSequenceManifest(fps: document.fps, frames: count, sourceStart: area.start, duration: area.duration, width: document.width, height: document.height)
        try JSONEncoder().encode(manifest).write(to: temporary.appendingPathComponent("sequence.json"), options: .atomic)
        try Task.checkCancellation()
        try FileManager.default.moveItem(at: temporary, to: destination)
        return destination
    }
}
