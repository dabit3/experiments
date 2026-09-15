import Foundation

public enum LayerBlendMode: String, Codable, CaseIterable, Sendable {
    case normal, multiply, screen, overlay, darken, lighten, colorDodge, colorBurn, softLight, hardLight, difference, exclusion
    public var title: String {
        switch self {
        case .colorDodge: return "Color Dodge"
        case .colorBurn: return "Color Burn"
        case .softLight: return "Soft Light"
        case .hardLight: return "Hard Light"
        default: return rawValue.capitalized
        }
    }
}

public enum Interpolation: String, Codable, CaseIterable, Sendable {
    case linear, hold, easeInOut
    public var title: String { self == .easeInOut ? "Easy Ease" : rawValue.capitalized }
    public func evaluate(_ t: Double) -> Double {
        switch self { case .linear: return t; case .hold: return t < 1 ? 0 : 1; case .easeInOut: return t * t * (3 - 2 * t) }
    }
}

public enum VectorVerb: String, Codable, Sendable { case move, line, curve, close }
public struct VectorCommand: Codable, Equatable, Sendable {
    public var verb: VectorVerb
    public var point: Point2D
    public var control1: Point2D?
    public var control2: Point2D?
    public init(_ verb: VectorVerb, _ point: Point2D, control1: Point2D? = nil, control2: Point2D? = nil) {
        self.verb = verb; self.point = point; self.control1 = control1; self.control2 = control2
    }
    public var svg: String {
        switch verb {
        case .move: return "M \(point.x) \(point.y)"
        case .line: return "L \(point.x) \(point.y)"
        case .curve:
            let a = control1 ?? point, b = control2 ?? point
            return "C \(a.x) \(a.y) \(b.x) \(b.y) \(point.x) \(point.y)"
        case .close: return "Z"
        }
    }
    public func scaled(_ factor: Double) -> VectorCommand { scaled(x: factor, y: factor) }
    public func scaled(x: Double, y: Double) -> VectorCommand {
        func scale(_ p: Point2D) -> Point2D { Point2D(p.x * x, p.y * y) }
        return VectorCommand(verb, scale(point), control1: control1.map(scale), control2: control2.map(scale))
    }
}

public enum TextAlignment: String, Codable, CaseIterable, Sendable { case left, center, right, justified }
public struct Typography: Codable, Equatable, Sendable {
    public var alignment: TextAlignment
    public var leading: Double
    public var tracking: Double
    public init(alignment: TextAlignment = .left, leading: Double = 1.2, tracking: Double = 0) {
        self.alignment = alignment; self.leading = leading; self.tracking = tracking
    }
}

public struct PageSettings: Codable, Equatable, Sendable {
    public var margin = 36.0
    public var columns = 1
    public var gutter = 18.0
    public var bleed = 9.0
    public var facingPages = true
    public init() {}
}

public struct SceneCamera: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var pitch: Double
    public var yaw: Double
    public var roll: Double
    public var fieldOfView: Double
    public init(x: Double, y: Double, z: Double, pitch: Double, yaw: Double, roll: Double, fieldOfView: Double = 42) {
        self.x = x; self.y = y; self.z = z; self.pitch = pitch; self.yaw = yaw; self.roll = roll; self.fieldOfView = fieldOfView
    }
}

public struct VideoTransform: Codable, Equatable, Sendable {
    public var x = 0.0
    public var y = 0.0
    public var scale = 1.0
    public var rotation = 0.0
    public var opacity = 1.0
    public init() {}
}

public struct MediaAsset: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var url: URL
    public var name: String
    public var duration: Double
    public var hasVideo: Bool
    public init(url: URL, duration: Double, hasVideo: Bool) {
        self.url = url; self.duration = duration; self.hasVideo = hasVideo; self.name = url.deletingPathExtension().lastPathComponent
    }
}

public struct SequenceEntry: Equatable, Identifiable, Sendable {
    public var id: UUID { clip.id }
    public var clip: MediaClip
    public var position: Double
    public var track: Int { clip.trackIndex ?? 0 }
    public var end: Double { position + clip.duration }
}

public enum SequenceLayout {
    public static func entries(_ clips: [MediaClip]) -> [SequenceEntry] {
        var cursor = 0.0
        return clips.map { clip in
            let position = clip.timelineStart ?? cursor
            cursor = max(cursor, position + clip.duration)
            return SequenceEntry(clip: clip, position: position)
        }
    }
    public static func duration(_ clips: [MediaClip]) -> Double { entries(clips).map(\.end).max() ?? 0 }
    public static func split(_ clip: MediaClip, at time: Double, position: Double) throws -> (MediaClip, MediaClip) {
        let local = time - position
        guard local > 0.001, local < clip.duration - 0.001 else { throw DocumentError.invalid("Place the playhead inside the clip to split it.") }
        var first = clip, second = clip
        first.timelineStart = position; first.end = clip.start + local; first.fadeOut = 0
        second.id = UUID(); second.timelineStart = time; second.start = first.end; second.fadeIn = 0
        return (first, second)
    }
}

extension CreativeDocument {
    public var sequenceDuration: Double { SequenceLayout.duration(clips) }
    public var mediaAssets: [MediaAsset] {
        if let assets { return assets }
        var seen = Set<URL>()
        return clips.compactMap { clip in
            guard seen.insert(clip.url).inserted else { return nil }
            var asset = MediaAsset(url: clip.url, duration: clip.sourceDuration, hasVideo: clip.audioOnly != true)
            asset.id = clip.id
            return asset
        }
    }
    public func validateProfessionalProperties() throws {
        if let camera = sceneCamera {
            guard [camera.x, camera.y, camera.z, camera.pitch, camera.yaw, camera.roll, camera.fieldOfView].allSatisfy({ $0.isFinite && abs($0) <= 1_000_000 }), (5...160).contains(camera.fieldOfView) else { throw DocumentError.invalid("The scene camera is invalid.") }
        }
        let linkedTargets = elements.compactMap(\.nextTextFrame)
        guard Set(linkedTargets).count == linkedTargets.count else { throw DocumentError.invalid("A text frame cannot continue more than one story.") }
        for element in elements {
            if element.nextTextFrame != nil && element.kind != .text { throw DocumentError.invalid("Only text frames can contain story links.") }
            if let feather = element.maskFeather, !feather.isFinite || !(0...1000).contains(feather) { throw DocumentError.invalid("The mask feather radius is invalid.") }
            if let start = element.inPoint, !start.isFinite || start < 0 { throw DocumentError.invalid("A layer has an invalid in point.") }
            if let end = element.outPoint, !end.isFinite || end <= (element.inPoint ?? 0) { throw DocumentError.invalid("A layer has an invalid out point.") }
            if let style = element.typography, !style.leading.isFinite || !(0.5...5).contains(style.leading) || !style.tracking.isFinite || abs(style.tracking) > 1000 { throw DocumentError.invalid("A text frame has invalid typography.") }
            if let path = element.vectorPath {
                guard path.count <= 100000, path.allSatisfy({ command in
                    [command.point, command.control1, command.control2].compactMap { $0 }.allSatisfy { $0.x.isFinite && $0.y.isFinite && abs($0.x) <= 1_000_000 && abs($0.y) <= 1_000_000 }
                }) else { throw DocumentError.invalid("A vector path has invalid coordinates.") }
            }
            var visited = Set<UUID>([element.id]), next = element.nextTextFrame
            while let id = next {
                guard visited.insert(id).inserted, let target = elements.first(where: { $0.id == id && $0.kind == .text }) else { throw DocumentError.invalid("Text frame links contain a cycle or a missing frame.") }
                next = target.nextTextFrame
            }
        }
        if let settings = pageSettings {
            guard [settings.margin, settings.gutter, settings.bleed].allSatisfy({ $0.isFinite && $0 >= 0 && $0 <= 1000 }), (1...12).contains(settings.columns) else { throw DocumentError.invalid("The page margins or columns are invalid.") }
        }
        for clip in clips {
            guard (clip.timelineStart ?? 0).isFinite, (0...86400).contains(clip.timelineStart ?? 0), (0...15).contains(clip.trackIndex ?? 0) else { throw DocumentError.invalid("A clip has an invalid timeline position or track.") }
            if let transform = clip.videoTransform {
                guard [transform.x, transform.y, transform.scale, transform.rotation, transform.opacity].allSatisfy(\.isFinite), (0.01...10).contains(transform.scale), (0...1).contains(transform.opacity) else { throw DocumentError.invalid("A video clip has an invalid transform.") }
            }
        }
        if let assets {
            guard assets.count <= 10000, Set(assets.map(\.id)).count == assets.count, assets.allSatisfy({ $0.url.isFileURL && $0.duration.isFinite && (0.000001...86400).contains($0.duration) }) else { throw DocumentError.invalid("The project contains invalid media assets.") }
        }
    }
}
