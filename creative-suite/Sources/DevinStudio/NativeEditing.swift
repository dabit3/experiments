import AppKit
import CoreText
import CoreImage
import DevinCore

enum VectorGeometry {
    static func path(_ element: CanvasElement) -> CGPath {
        let path = CGMutablePath()
        let rect = CGRect(x: 0, y: 0, width: element.width, height: element.height)
        switch element.kind {
        case .rectangle: path.addRoundedRect(in: rect, cornerWidth: element.cornerRadius, cornerHeight: element.cornerRadius)
        case .ellipse: path.addEllipse(in: rect)
        case .line: path.move(to: .zero); path.addLine(to: CGPoint(x: element.width, y: element.height))
        default:
            if let commands = element.vectorPath {
                for c in commands {
                    let point = CGPoint(x: c.point.x, y: c.point.y)
                    switch c.verb {
                    case .move: path.move(to: point)
                    case .line: path.addLine(to: point)
                    case .curve:
                        let a = c.control1 ?? c.point, b = c.control2 ?? c.point
                        path.addCurve(to: point, control1: CGPoint(x: a.x, y: a.y), control2: CGPoint(x: b.x, y: b.y))
                    case .close: path.closeSubpath()
                    }
                }
            } else if let first = element.points.first {
                path.move(to: CGPoint(x: first.x, y: first.y))
                for p in element.points.dropFirst() { path.addLine(to: CGPoint(x: p.x, y: p.y)) }
            }
        }
        return path
    }
    static func worldPath(_ element: CanvasElement) -> CGPath {
        var transform = CGAffineTransform(translationX: element.x + element.width / 2, y: element.y + element.height / 2)
            .rotated(by: element.rotation * .pi / 180).translatedBy(x: -element.width / 2, y: -element.height / 2)
        return path(element).copy(using: &transform) ?? path(element)
    }
    static func element(from path: CGPath, name: String, fill: String, page: Int) -> CanvasElement {
        let bounds = path.boundingBoxOfPath
        var e = CanvasElement(kind: .path, name: name, x: bounds.minX, y: bounds.minY, width: max(1, bounds.width), height: max(1, bounds.height), fill: fill, page: page)
        var commands: [VectorCommand] = []
        var previous = Point2D(0, 0)
        path.applyWithBlock { pointer in
            let item = pointer.pointee
            func point(_ i: Int) -> Point2D { Point2D(item.points[i].x - bounds.minX, item.points[i].y - bounds.minY) }
            switch item.type {
            case .moveToPoint: commands.append(VectorCommand(.move, point(0))); previous = point(0)
            case .addLineToPoint: commands.append(VectorCommand(.line, point(0))); previous = point(0)
            case .addCurveToPoint: commands.append(VectorCommand(.curve, point(2), control1: point(0), control2: point(1))); previous = point(2)
            case .addQuadCurveToPoint:
                let control = point(0), end = point(1)
                commands.append(VectorCommand(.curve, end, control1: Point2D(previous.x + (control.x - previous.x) * 2 / 3, previous.y + (control.y - previous.y) * 2 / 3), control2: Point2D(end.x + (control.x - end.x) * 2 / 3, end.y + (control.y - end.y) * 2 / 3)))
                previous = end
            case .closeSubpath: commands.append(VectorCommand(.close, previous))
            @unknown default: break
            }
        }
        e.vectorPath = commands
        return e
    }
}

enum TextFlow {
    static func attributes(_ e: CanvasElement) -> [NSAttributedString.Key: Any] {
        let style = e.typography ?? Typography()
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        switch style.alignment {
        case .left: paragraph.alignment = .left
        case .center: paragraph.alignment = .center
        case .right: paragraph.alignment = .right
        case .justified: paragraph.alignment = .justified
        }
        if e.typography != nil { paragraph.minimumLineHeight = e.fontSize * style.leading; paragraph.maximumLineHeight = e.fontSize * style.leading }
        return [.font: NSFont(name: e.fontName, size: e.fontSize) ?? NSFont.systemFont(ofSize: e.fontSize), .foregroundColor: NSColor(hex: e.fill), .paragraphStyle: paragraph, .kern: style.tracking / 1000 * e.fontSize]
    }
    static func visibleCount(_ text: String, in element: CanvasElement) -> Int {
        let string = NSAttributedString(string: text, attributes: attributes(element))
        let framesetter = CTFramesetterCreateWithAttributedString(string)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: string.length), CGPath(rect: CGRect(x: 0, y: 0, width: element.width, height: element.height), transform: nil), nil)
        return CTFrameGetVisibleStringRange(frame).length
    }
    static func elements(_ document: CreativeDocument) -> [CanvasElement] {
        var result = document.elements
        let incoming = Set(result.compactMap(\.nextTextFrame))
        for root in document.elements where root.kind == .text && !incoming.contains(root.id) && root.nextTextFrame != nil {
            var remainder = root.text, current: UUID? = root.id, visited = Set<UUID>()
            while let id = current, visited.insert(id).inserted, let index = result.firstIndex(where: { $0.id == id }) {
                let count = min((remainder as NSString).length, visibleCount(remainder, in: result[index]))
                result[index].text = (remainder as NSString).substring(to: count)
                remainder = (remainder as NSString).substring(from: count)
                current = result[index].nextTextFrame
                if current == nil && !remainder.isEmpty { result[index].text += remainder }
            }
        }
        return result
    }
    static func overflows(_ document: CreativeDocument) -> Set<UUID> {
        Set(elements(document).filter { $0.kind == .text && $0.nextTextFrame == nil && visibleCount($0.text, in: $0) < ($0.text as NSString).length }.map(\.id))
    }
}

enum RasterEditing {
    static func inverseTransform(_ layer: CanvasElement) -> CGAffineTransform {
        CGAffineTransform(translationX: layer.x + layer.width / 2, y: layer.y + layer.height / 2)
            .rotated(by: layer.rotation * .pi / 180).translatedBy(x: -layer.width / 2, y: -layer.height / 2).inverted()
    }
    static func paint(_ original: CanvasElement?, document: CreativeDocument, points: [CGPoint], size: Double, color: String, opacity: Double, erase: Bool, selection: CGRect?, selectionPath: CGPath? = nil, hardness: Double = 1, target: PaintTarget = .pixels, antialias: Bool = true) throws -> CanvasElement {
        var layer = original ?? CanvasElement(kind: .image, name: "Layer \(document.elements.count + 1)", x: 0, y: 0, width: document.width, height: document.height, page: 0)
        guard !layer.locked else { throw DocumentError.invalid("Unlock the layer before painting.") }
        guard size.isFinite, size > 0, opacity.isFinite, (0...1).contains(opacity), hardness.isFinite, (0...1).contains(hardness) else { throw DocumentError.invalid("The brush settings are invalid.") }
        if original != nil && (points.isEmpty || opacity == 0 || selectionPath?.isEmpty == true || selectionPath == nil && selection?.isEmpty == true) { return layer }
        let sourceData = target == .mask ? layer.maskData : layer.imageData
        let source = sourceData.flatMap { CIImage(data: $0, options: [.applyOrientationProperty: true]) }
        let reference = layer.imageData.flatMap { CIImage(data: $0) }
        let width = max(1, Int(source.map { Double($0.extent.width) } ?? reference.map { Double($0.extent.width) } ?? document.width))
        let height = max(1, Int(source.map { Double($0.extent.height) } ?? reference.map { Double($0.extent.height) } ?? document.height))
        guard width * height <= 100_000_000, let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { throw DocumentError.invalid("The paint layer is too large.") }
        context.setShouldAntialias(antialias)
        context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: Double(width) / layer.width, y: -Double(height) / layer.height)
        var transform = inverseTransform(layer)
        if let path = selectionPath ?? selection.map({ CGPath(rect: $0, transform: nil) }), let local = path.copy(using: &transform) { context.addPath(local); context.clip() }
        let localPoints = points.map { $0.applying(transform) }
        if let first = localPoints.first {
            if hardness >= 0.999 {
                context.setStrokeColor(gray: 1, alpha: 1); context.setLineWidth(size); context.setLineCap(.round); context.setLineJoin(.round)
                context.move(to: first)
                for point in localPoints.dropFirst() { context.addLine(to: point) }
                if localPoints.count == 1 { context.addLine(to: CGPoint(x: first.x + 0.001, y: first.y)) }
                context.strokePath()
            } else {
                let colors = [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 1), CGColor(gray: 0, alpha: 1)] as CFArray
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceGray(), colors: colors, locations: [0, max(0.001, hardness), 1])!
                context.setBlendMode(.lighten)
                func dab(_ point: CGPoint) { context.drawRadialGradient(gradient, startCenter: point, startRadius: 0, endCenter: point, endRadius: size / 2, options: []) }
                dab(first)
                for (a, b) in zip(localPoints, localPoints.dropFirst()) {
                    let steps = max(1, min(10000, Int(ceil(hypot(b.x - a.x, b.y - a.y) / max(0.5, size * 0.12)))))
                    for i in 1...steps { let t = Double(i) / Double(steps); dab(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)) }
                }
            }
        }
        guard let mask = context.makeImage() else { throw DocumentError.invalid("The brush stroke could not be rendered.") }
        let extent = CGRect(x: 0, y: 0, width: width, height: height)
        let background = source ?? CIImage(color: target == .mask ? .white : .clear).cropped(to: extent)
        let amount = CIImage(cgImage: mask).applyingFilter("CIColorMatrix", parameters: ["inputRVector": CIVector(x: opacity, y: 0, z: 0, w: 0), "inputGVector": CIVector(x: 0, y: opacity, z: 0, w: 0), "inputBVector": CIVector(x: 0, y: 0, z: opacity, w: 0)])
        let chosen = NSColor(hex: color)
        let paintColor: CIColor
        if target == .mask {
            let gray = erase ? 0 : chosen.redComponent * 0.2126 + chosen.greenComponent * 0.7152 + chosen.blueComponent * 0.0722
            paintColor = CIColor(red: gray, green: gray, blue: gray)
        } else { paintColor = erase ? .clear : CIColor(color: chosen)! }
        let result = CIImage(color: paintColor).cropped(to: extent).applyingFilter("CIBlendWithMask", parameters: [kCIInputBackgroundImageKey: background, kCIInputMaskImageKey: amount])
        guard let image = Renderer.imageContext.createCGImage(result, from: extent), let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { throw DocumentError.invalid("The painted layer could not be encoded.") }
        if target == .mask { layer.maskData = data } else { layer.imageData = data }
        return layer
    }
    static func clear(_ layer: CanvasElement, selection: CGPath, target: PaintTarget = .pixels) throws -> CanvasElement {
        guard !layer.locked else { throw DocumentError.invalid("Unlock the layer before clearing pixels.") }
        let bounds = CGPath(rect: CGRect(x: 0, y: 0, width: layer.width, height: layer.height), transform: nil)
        var transform = inverseTransform(layer).inverted()
        guard let world = bounds.copy(using: &transform), !selection.intersection(world, using: .winding).isEmpty else { return layer }
        let data = target == .mask ? layer.maskData : layer.imageData
        guard let data, let source = CIImage(data: data, options: [.applyOrientationProperty: true]), let maskData = selectionMask(nil, layer: layer, path: selection), let mask = CIImage(data: maskData) else { throw DocumentError.invalid("Select readable layer pixels or a layer mask before clearing.") }
        let fill = CIImage(color: target == .mask ? .black : .clear).cropped(to: source.extent)
        let result = fill.applyingFilter("CIBlendWithMask", parameters: [kCIInputBackgroundImageKey: source, kCIInputMaskImageKey: mask])
        guard let image = Renderer.imageContext.createCGImage(result, from: source.extent), let encoded = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { throw DocumentError.invalid("The cleared pixels could not be encoded.") }
        var updated = layer
        if target == .mask { updated.maskData = encoded } else { updated.imageData = encoded }
        return updated
    }
    static func extract(_ layer: CanvasElement, document: CreativeDocument, selection: CGPath, target: PaintTarget = .pixels) throws -> CanvasElement {
        let rect = selection.boundingBoxOfPath.intersection(CGRect(x: 0, y: 0, width: document.width, height: document.height)).integral
        guard !selection.isEmpty, !rect.isNull, rect.width > 0, rect.height > 0, rect.width * rect.height <= 16_777_216,
              let context = CGContext(data: nil, width: Int(rect.width), height: Int(rect.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw DocumentError.invalid("Select a nonempty pixel region of 16 megapixels or fewer to copy.") }
        var source = layer
        if target == .mask {
            guard let mask = layer.maskData else { throw DocumentError.invalid("Select a readable layer mask before copying.") }
            source.imageData = mask; source.maskData = nil; source.adjustments = ImageAdjustments()
        }
        source.opacity = 1; source.blendMode = .normal; source.visible = true
        var copy = document; copy.elements = [source]
        context.translateBy(x: -rect.minX, y: rect.height + rect.minY); context.scaleBy(x: 1, y: -1)
        context.addPath(selection); context.clip()
        Renderer.draw(copy, in: context, page: layer.page, background: false)
        guard let image = context.makeImage(), let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { throw DocumentError.invalid("The selected pixels could not be copied.") }
        var result = CanvasElement(kind: .image, name: layer.name + " selection", x: rect.minX, y: rect.minY, width: rect.width, height: rect.height, page: layer.page)
        result.imageData = data
        return result
    }
    static func selectionMask(_ rect: CGRect?, layer: CanvasElement, path: CGPath? = nil) -> Data? {
        let image = layer.imageData.flatMap { CIImage(data: $0) }
        let width = max(1, Int(image.map { Double($0.extent.width) } ?? layer.width)), height = max(1, Int(image.map { Double($0.extent.height) } ?? layer.height))
        guard width * height <= 100_000_000, let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: Double(width) / layer.width, y: -Double(height) / layer.height)
        context.setFillColor(gray: 1, alpha: 1)
        var transform = inverseTransform(layer)
        if let selection = path ?? rect.map({ CGPath(rect: $0, transform: nil) }), let local = selection.copy(using: &transform) { context.addPath(local); context.fillPath() }
        else { context.fill(CGRect(x: 0, y: 0, width: layer.width, height: layer.height)) }
        return context.makeImage().flatMap { NSBitmapImageRep(cgImage: $0).representation(using: .png, properties: [:]) }
    }
}
