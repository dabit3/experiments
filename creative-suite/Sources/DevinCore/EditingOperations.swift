import Foundation

extension CanvasElement {
    public func worldPoint(_ point: Point2D) -> Point2D {
        let angle = rotation * .pi / 180, dx = point.x - width / 2, dy = point.y - height / 2
        return Point2D(x + width / 2 + dx * cos(angle) - dy * sin(angle), y + height / 2 + dx * sin(angle) + dy * cos(angle))
    }
    public func resizedBottomRight(to point: Point2D, preserveAspect: Bool) -> CanvasElement {
        let anchor = worldPoint(Point2D(0, 0)), angle = rotation * .pi / 180
        let dx = point.x - anchor.x, dy = point.y - anchor.y
        let w = max(8, dx * cos(angle) + dy * sin(angle))
        let h = preserveAspect ? max(8, w * height / width) : max(8, -dx * sin(angle) + dy * cos(angle))
        var result = self
        result.width = w; result.height = h
        result.x = anchor.x + w / 2 * cos(angle) - h / 2 * sin(angle) - w / 2
        result.y = anchor.y + w / 2 * sin(angle) + h / 2 * cos(angle) - h / 2
        result.points = points.map { Point2D($0.x * w / width, $0.y * h / height) }
        result.vectorPath = vectorPath?.map { $0.scaled(x: w / width, y: h / height) }
        return result
    }
}

extension CreativeDocument {
    public mutating func movePage(from source: Int, to destination: Int) throws {
        guard (0..<pageCount).contains(source), (0..<pageCount).contains(destination) else { throw DocumentError.invalid("The page index is invalid.") }
        guard source != destination else { return }
        for i in elements.indices {
            let page = elements[i].page
            if page == source { elements[i].page = destination }
            else if source < destination && page > source && page <= destination { elements[i].page -= 1 }
            else if source > destination && page >= destination && page < source { elements[i].page += 1 }
        }
    }
    public mutating func insertLayers(_ layers: [CanvasElement], page: Int, offset: Double = 0) throws -> [UUID] {
        guard layers.count <= 10000, Set(layers.map(\.id)).count == layers.count, (0..<pageCount).contains(page), offset.isFinite else { throw DocumentError.invalid("The layer data is invalid.") }
        let identifiers = Dictionary(uniqueKeysWithValues: layers.map { ($0.id, UUID()) })
        var copies = layers
        for i in copies.indices {
            copies[i].id = identifiers[copies[i].id]!
            copies[i].page = page; copies[i].locked = false; copies[i].x += offset; copies[i].y += offset
            copies[i].nextTextFrame = copies[i].nextTextFrame.flatMap { identifiers[$0] }
            for k in copies[i].keyframes.indices { copies[i].keyframes[k].id = UUID(); copies[i].keyframes[k].x += offset; copies[i].keyframes[k].y += offset }
            if var channels = copies[i].animationChannels {
                for c in channels.indices { for k in channels[c].keyframes.indices { channels[c].keyframes[k].id = UUID(); if [.positionX, .positionY].contains(channels[c].property) { channels[c].keyframes[k].value += offset } } }
                copies[i].animationChannels = channels
            }
        }
        var candidate = self
        candidate.elements.append(contentsOf: copies)
        _ = try candidate.validated()
        self = candidate
        return copies.map(\.id)
    }
}

public enum WebDocumentBuilder {
    public static func render(html: String, css: String, javascript: String) -> String {
        let style = "<style>" + css.replacingOccurrences(of: "</style", with: "<\\/style", options: .caseInsensitive) + "</style>"
        let script = "<script>" + javascript.replacingOccurrences(of: "</script", with: "<\\/script", options: .caseInsensitive) + "</script>"
        guard html.range(of: "<html(?:\\s|>)", options: [.regularExpression, .caseInsensitive]) != nil else {
            return "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">\(style)</head><body>\(html)\(script)</body></html>"
        }
        var result = html
        if let head = result.range(of: "</head>", options: .caseInsensitive) { result.insert(contentsOf: style, at: head.lowerBound) }
        else if let opening = result.range(of: "<html[^>]*>", options: [.regularExpression, .caseInsensitive]) { result.insert(contentsOf: "<head>\(style)</head>", at: opening.upperBound) }
        if let body = result.range(of: "</body>", options: [.caseInsensitive, .backwards]) { result.insert(contentsOf: script, at: body.lowerBound) }
        else if let end = result.range(of: "</html>", options: [.caseInsensitive, .backwards]) { result.insert(contentsOf: script, at: end.lowerBound) }
        else { result += script }
        return result
    }
}
