import Foundation

public struct Point2D: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
}

public enum ElementKind: String, Codable, CaseIterable, Sendable {
    case rectangle, ellipse, text, line, path, image
}

public struct ImageAdjustments: Codable, Equatable, Sendable {
    public var exposure = 0.0
    public var contrast = 1.0
    public var saturation = 1.0
    public var temperature = 6500.0
    public var blur = 0.0
    public init() {}
}

public struct Keyframe: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var time: Double
    public var x: Double
    public var y: Double
    public var rotation: Double
    public var opacity: Double
    public var scale: Double
    public var interpolation: Interpolation?
    public init(time: Double, x: Double, y: Double, rotation: Double = 0, opacity: Double = 1, scale: Double = 1) {
        self.time = time; self.x = x; self.y = y
        self.rotation = rotation; self.opacity = opacity; self.scale = scale
    }
}

public struct CanvasElement: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var name: String
    public var kind: ElementKind
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var rotation = 0.0
    public var opacity = 1.0
    public var fill = "B3E8CA"
    public var stroke = "151716"
    public var strokeWidth = 0.0
    public var cornerRadius = 0.0
    public var text = "Something wonderful."
    public var fontSize = 64.0
    public var fontName = "HelveticaNeue-Bold"
    public var visible = true
    public var locked = false
    public var page = 0
    public var points: [Point2D] = []
    public var imageData: Data?
    public var adjustments = ImageAdjustments()
    public var keyframes: [Keyframe] = []
    public var animationChannels: [AnimationChannel]?
    public var baseScale: Double?
    public var blendMode: LayerBlendMode?
    public var vectorPath: [VectorCommand]?
    public var maskData: Data?
    public var maskEnabled: Bool?
    public var maskInverted: Bool?
    public var maskFeather: Double?
    public var typography: Typography?
    public var nextTextFrame: UUID?
    public var inPoint: Double?
    public var outPoint: Double?

    public init(kind: ElementKind, name: String, x: Double, y: Double, width: Double, height: Double, fill: String = "B3E8CA", page: Int = 0) {
        self.kind = kind; self.name = name; self.x = x; self.y = y
        self.width = width; self.height = height; self.fill = fill; self.page = page
    }

    public func evaluated(at time: Double) -> CanvasElement {
        var result = self
        result.x = animationValue(.positionX, at: time); result.y = animationValue(.positionY, at: time)
        result.rotation = animationValue(.rotation, at: time)
        result.opacity = animationValue(.opacity, at: time)
        let scale = animationValue(.scale, at: time)
        result.width *= scale; result.height *= scale
        result.fontSize *= scale; result.strokeWidth *= scale; result.cornerRadius *= scale
        result.points = points.map { Point2D($0.x * scale, $0.y * scale) }
        result.vectorPath = vectorPath?.map { $0.scaled(scale) }
        return result
    }

    public mutating func setPose(at time: Double, x: Double, y: Double, rotation: Double, opacity: Double, tolerance: Double = 0.0001) {
        let scale = evaluated(at: time).width / width
        if animationChannels != nil {
            for (property, value) in [(AnimationProperty.positionX, x), (.positionY, y), (.rotation, rotation), (.opacity, opacity), (.scale, scale)] { setPropertyKeyframe(property, at: time, value: value, tolerance: tolerance) }
            return
        }
        let existing = keyframes.first { abs($0.time - time) <= tolerance }
        keyframes.removeAll { abs($0.time - time) <= tolerance }
        var frame = Keyframe(time: time, x: x, y: y, rotation: rotation, opacity: opacity, scale: scale)
        if let existing { frame.id = existing.id; frame.interpolation = existing.interpolation }
        keyframes.append(frame)
        keyframes.sort { $0.time < $1.time }
    }
}

public struct MediaClip: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var url: URL
    public var name: String
    public var sourceDuration: Double
    public var start = 0.0
    public var end: Double
    public var gain = 1.0
    public var fadeIn = 0.0
    public var fadeOut = 0.0
    public var timelineStart: Double?
    public var trackIndex: Int?
    public var audioOnly: Bool?
    public var muted: Bool?
    public var videoTransform: VideoTransform?
    public var duration: Double { max(0, end - start) }
    public init(url: URL, duration: Double) {
        self.url = url; self.name = url.deletingPathExtension().lastPathComponent
        self.sourceDuration = duration; self.end = duration
    }
    public func amplitude(at time: Double) -> Double {
        guard muted != true, time >= 0, time <= duration else { return 0 }
        let fadeIn = min(self.fadeIn, duration / 2), fadeOut = min(self.fadeOut, duration / 2)
        let fadeInValue = fadeIn > 0 ? min(1, time / fadeIn) : 1
        let fadeOutValue = fadeOut > 0 ? min(1, (duration - time) / fadeOut) : 1
        return gain * max(0, min(fadeInValue, fadeOutValue))
    }
}

public struct SpatialObject: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var name: String
    public var primitive: String
    public var x = 0.0
    public var y = 0.0
    public var z = 0.0
    public var scale = 1.0
    public var rotation = 0.0
    public var color = "B3E8CA"
    public var metalness = 0.25
    public var roughness = 0.35
    public init(name: String, primitive: String) { self.name = name; self.primitive = primitive }
}

public struct CreativeDocument: Codable, Equatable, Sendable {
    public var version = 3
    public var id = UUID()
    public var title: String
    public var tool: StudioTool
    public var width = 1200.0
    public var height = 900.0
    public var background = "F5F2EB"
    public var transparentBackground: Bool?
    public var elements: [CanvasElement] = []
    public var pageCount = 1
    public var duration = 5.0
    public var workArea: WorkArea?
    public var fps = 24
    public var clips: [MediaClip] = []
    public var html = ""
    public var css = ""
    public var javascript = ""
    public var objects: [SpatialObject] = []
    public var sceneCamera: SceneCamera?
    public var pdfData: Data?
    public var assets: [MediaAsset]?
    public var pageSettings: PageSettings?

    public init(title: String, tool: StudioTool) { self.title = title; self.tool = tool }

    public mutating func crop(x: Double, y: Double, width: Double, height: Double) throws {
        guard [x, y, width, height].allSatisfy(\.isFinite), x >= 0, y >= 0,
              width >= 16, height >= 16, x + width <= self.width + 0.001, y + height <= self.height + 0.001 else {
            throw DocumentError.invalid("Choose a crop of at least 16 × 16 pixels inside the canvas.")
        }
        self.width = width; self.height = height
        for i in elements.indices {
            elements[i].x -= x; elements[i].y -= y
            if var channels = elements[i].animationChannels {
                for c in channels.indices { for k in channels[c].keyframes.indices {
                    if channels[c].property == .positionX { channels[c].keyframes[k].value -= x }
                    if channels[c].property == .positionY { channels[c].keyframes[k].value -= y }
                } }
                elements[i].animationChannels = channels
            }
            for k in elements[i].keyframes.indices {
                elements[i].keyframes[k].x -= x; elements[i].keyframes[k].y -= y
            }
        }
    }

    public func validated() throws -> CreativeDocument {
        guard (1...3).contains(version) else { throw DocumentError.invalid("This project version is not supported.") }
        guard width.isFinite, height.isFinite, (16...16384).contains(width), (16...16384).contains(height) else {
            throw DocumentError.invalid("Canvas dimensions must be between 16 and 16,384 pixels.")
        }
        guard (1...1000).contains(pageCount), (1...120).contains(fps), duration.isFinite, (0.1...3600).contains(duration) else {
            throw DocumentError.invalid("The page count, frame rate, or duration is not valid.")
        }
        guard elements.count <= 10000, Set(elements.map(\.id)).count == elements.count else {
            throw DocumentError.invalid("The project has too many layers or duplicate layer IDs.")
        }
        for e in elements {
            let values = [e.x, e.y, e.width, e.height, e.rotation, e.opacity, e.strokeWidth, e.cornerRadius, e.fontSize,
                          e.adjustments.exposure, e.adjustments.contrast, e.adjustments.saturation, e.adjustments.temperature, e.adjustments.blur]
            guard values.allSatisfy({ $0.isFinite && abs($0) <= 1_000_000 }), e.width > 0, e.height > 0,
                  (0..<pageCount).contains(e.page), (0...1).contains(e.opacity), e.fontSize > 0,
                  e.strokeWidth >= 0, e.cornerRadius >= 0, e.adjustments.blur >= 0,
                  e.points.allSatisfy({ $0.x.isFinite && $0.y.isFinite && abs($0.x) <= 1_000_000 && abs($0.y) <= 1_000_000 }) else {
                throw DocumentError.invalid("A layer contains invalid geometry.")
            }
            guard e.keyframes.count <= 10000, Set(e.keyframes.map(\.id)).count == e.keyframes.count, e.points.count <= 100000, e.keyframes.allSatisfy({ k in
                [k.time, k.x, k.y, k.rotation, k.opacity, k.scale].allSatisfy({ $0.isFinite && abs($0) <= 1_000_000 }) && (0...3600).contains(k.time) && k.scale > 0 && k.scale <= 100 && (0...1).contains(k.opacity)
            }) else { throw DocumentError.invalid("A layer contains invalid keyframes or too many path points.") }
        }
        guard clips.count <= 1000, Set(clips.map(\.id)).count == clips.count, clips.allSatisfy({ c in
            [c.sourceDuration, c.start, c.end, c.gain, c.fadeIn, c.fadeOut].allSatisfy(\.isFinite) &&
            c.url.isFileURL && c.sourceDuration <= 86400 && c.start >= 0 && c.end > c.start && c.end <= c.sourceDuration + 0.001 &&
            (0...4).contains(c.gain) && c.fadeIn >= 0 && c.fadeOut >= 0
        }) else { throw DocumentError.invalid("A media clip has an invalid range or gain.") }
        guard objects.count <= 1000, Set(objects.map(\.id)).count == objects.count, objects.allSatisfy({ o in
            [o.x, o.y, o.z, o.scale, o.rotation, o.metalness, o.roughness].allSatisfy({ $0.isFinite && abs($0) <= 1_000_000 }) &&
            (0.05...20).contains(o.scale) && (0...1).contains(o.metalness) && (0...1).contains(o.roughness) &&
            ["sphere", "box", "torus", "cone", "cylinder"].contains(o.primitive)
        }) else { throw DocumentError.invalid("A 3D object has invalid properties.") }
        try validateProfessionalProperties()
        try validateAnimationChannels()
        return self
    }

    public static func load(from data: Data) throws -> CreativeDocument {
        var document = try JSONDecoder().decode(Self.self, from: data).validated()
        document.version = 3
        return document
    }
    public func encoded() throws -> Data {
        _ = try validated()
        var document = self
        document.version = 3
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document)
    }
    public func webSource() -> String {
        WebDocumentBuilder.render(html: html, css: css, javascript: javascript)
    }
}

public enum DocumentError: LocalizedError {
    case invalid(String)
    public var errorDescription: String? { if case .invalid(let message) = self { return message }; return nil }
}

public struct History<Value: Equatable> {
    public private(set) var undoStack: [Value] = []
    public private(set) var redoStack: [Value] = []
    public let limit: Int
    public init(limit: Int = 60) { self.limit = max(1, limit) }
    public mutating func record(_ previous: Value, replacing current: Value) {
        guard previous != current else { return }
        undoStack.append(previous)
        if undoStack.count > limit { undoStack.removeFirst(undoStack.count - limit) }
        redoStack.removeAll()
    }
    public mutating func undo(_ current: Value) -> Value? {
        guard let previous = undoStack.popLast() else { return nil }
        redoStack.append(current); return previous
    }
    public mutating func redo(_ current: Value) -> Value? {
        guard let next = redoStack.popLast() else { return nil }
        undoStack.append(current); return next
    }
}

public enum SVGExporter {
    public static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
    public static func render(_ document: CreativeDocument, page: Int = 0) -> String {
        var lines = ["<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(document.width)\" height=\"\(document.height)\" viewBox=\"0 0 \(document.width) \(document.height)\">"]
        if document.transparentBackground != true { lines.append("<rect width=\"100%\" height=\"100%\" fill=\"#\(escape(document.background))\"/>") }
        for e in document.elements where e.visible && e.page == page {
            let style = "fill=\"#\(escape(e.fill))\" stroke=\"#\(escape(e.stroke))\" stroke-width=\"\(e.strokeWidth)\""
            lines.append("<g opacity=\"\(e.opacity)\" transform=\"translate(\(e.x) \(e.y)) rotate(\(e.rotation) \(e.width/2) \(e.height/2))\">")
            switch e.kind {
            case .rectangle: lines.append("<rect width=\"\(e.width)\" height=\"\(e.height)\" rx=\"\(e.cornerRadius)\" \(style)/>")
            case .ellipse: lines.append("<ellipse cx=\"\(e.width/2)\" cy=\"\(e.height/2)\" rx=\"\(e.width/2)\" ry=\"\(e.height/2)\" \(style)/>")
            case .line: lines.append("<line x1=\"0\" y1=\"0\" x2=\"\(e.width)\" y2=\"\(e.height)\" stroke=\"#\(escape(e.stroke))\" stroke-width=\"\(max(1,e.strokeWidth))\"/>")
            case .path:
                if let commands = e.vectorPath {
                    let fill = commands.contains(where: { $0.verb == .close }) ? "#" + escape(e.fill) : "none"
                    lines.append("<path d=\"\(commands.map(\.svg).joined(separator: " "))\" fill=\"\(fill)\" stroke=\"#\(escape(e.stroke))\" stroke-width=\"\(e.strokeWidth)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>")
                } else {
                    let points = e.points.map { "\($0.x),\($0.y)" }.joined(separator: " ")
                    lines.append("<polyline points=\"\(points)\" fill=\"none\" stroke=\"#\(escape(e.stroke))\" stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"\(max(1,e.strokeWidth))\"/>")
                }
            case .text:
                let alignment = e.typography?.alignment ?? .left
                let anchor = alignment == .center ? "middle" : alignment == .right ? "end" : "start"
                let x = alignment == .center ? e.width / 2 : alignment == .right ? e.width : 0
                let leading = e.typography?.leading ?? 1.18
                let spacing = (e.typography?.tracking ?? 0) / 1000 * e.fontSize
                lines.append("<text font-family=\"\(escape(e.fontName))\" font-size=\"\(e.fontSize)\" text-anchor=\"\(anchor)\" letter-spacing=\"\(spacing)\" \(style)>")
                for (i, line) in e.text.components(separatedBy: "\n").enumerated() {
                    lines.append("<tspan x=\"\(x)\" y=\"\(e.fontSize * (1 + Double(i) * leading))\">\(escape(line))</tspan>")
                }
                lines.append("</text>")
            case .image:
                if let data = e.imageData {
                    let mime = data.starts(with: [0xFF, 0xD8]) ? "image/jpeg" : data.starts(with: [0x47, 0x49, 0x46]) ? "image/gif" : "image/png"
                    lines.append("<image width=\"\(e.width)\" height=\"\(e.height)\" preserveAspectRatio=\"none\" href=\"data:\(mime);base64,\(data.base64EncodedString())\"/>")
                }
            }
            lines.append("</g>")
        }
        lines.append("</svg>")
        return lines.joined(separator: "\n")
    }
}
