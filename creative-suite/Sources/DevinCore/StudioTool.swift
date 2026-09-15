import Foundation

public enum StudioTool: String, Codable, CaseIterable, Identifiable, Sendable {
    case pixel, form, press, lens, cut, motion, sound, frame, folio, code, batch, space

    public var id: String { rawValue }
    public var name: String { "Devin \(rawValue.capitalized)" }
    public var monogram: String {
        switch self {
        case .pixel: return "Pi"
        case .form: return "Fo"
        case .press: return "Pr"
        case .lens: return "Le"
        case .cut: return "Cu"
        case .motion: return "Mo"
        case .sound: return "So"
        case .frame: return "Fr"
        case .folio: return "Fl"
        case .code: return "Co"
        case .batch: return "Ba"
        case .space: return "Sp"
        }
    }
    public var subtitle: String {
        switch self {
        case .pixel: return "Images, with imagination."
        case .form: return "Give every idea a shape."
        case .press: return "Stories worth turning pages for."
        case .lens: return "Find your light."
        case .cut: return "Make the next great cut."
        case .motion: return "Nothing stands still."
        case .sound: return "Find your frequency."
        case .frame: return "A little movement. A lot of life."
        case .folio: return "A better kind of paperwork."
        case .code: return "From a thought to the web."
        case .batch: return "Less repetition. More creation."
        case .space: return "Think in another dimension."
        }
    }
    public var category: String {
        switch self {
        case .pixel, .form, .press: return "Design"
        case .lens: return "Photography"
        case .cut, .motion, .frame: return "Video & motion"
        case .sound: return "Audio"
        case .folio: return "Documents"
        case .code: return "Development"
        case .batch: return "Utilities"
        case .space: return "3D & materials"
        }
    }
    public var detail: String {
        switch self {
        case .pixel: return "Layered compositions, painting & image adjustments"
        case .form: return "Vector shapes, paths, typography & SVG export"
        case .press: return "Multi-page layouts, typography & print-ready PDFs"
        case .lens: return "Photo collections & non-destructive development"
        case .cut: return "Clip sequencing, trimming, playback & movie export"
        case .motion: return "Keyframed compositions & rendered animation"
        case .sound: return "Waveform editing, gain, fades & WAV export"
        case .frame: return "Frame-by-frame animation, onion skin & GIF export"
        case .folio: return "PDF reading, page organization & text annotations"
        case .code: return "HTML, CSS & JavaScript with a live web preview"
        case .batch: return "Batch image conversion, resizing & quality control"
        case .space: return "3D primitives, materials, lighting & scene export"
        }
    }
    public var color: String {
        switch self {
        case .pixel: return "A2B8FF"
        case .form: return "FBB88C"
        case .press: return "F5A9C8"
        case .lens: return "AED9C4"
        case .cut: return "BEB0FF"
        case .motion: return "CBA4E8"
        case .sound: return "A5DCD0"
        case .frame: return "F3D88E"
        case .folio: return "F5A9A2"
        case .code: return "A7CCEF"
        case .batch: return "D1D59A"
        case .space: return "CFBBA6"
        }
    }
    public var symbol: String {
        switch self {
        case .pixel: return "photo.artframe"
        case .form: return "square.on.circle"
        case .press: return "book.closed"
        case .lens: return "camera.aperture"
        case .cut: return "film"
        case .motion: return "move.3d"
        case .sound: return "waveform"
        case .frame: return "square.stack.3d.up"
        case .folio: return "doc.richtext"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .batch: return "square.3.layers.3d"
        case .space: return "cube.transparent"
        }
    }
    public var isCanvas: Bool { [.pixel, .form, .press, .lens, .motion, .frame].contains(self) }
}
