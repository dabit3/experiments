import AppKit
import CoreImage
import ImageIO
import UniformTypeIdentifiers
import DevinCore

private final class CachedImage: NSObject {
    let image: CGImage
    init(_ image: CGImage) { self.image = image }
}

enum Renderer {
    static let imageContext = CIContext(options: [.cacheIntermediates: false])
    private static let cache: NSCache<NSString, CachedImage> = {
        let cache = NSCache<NSString, CachedImage>()
        cache.totalCostLimit = 256 * 1024 * 1024
        return cache
    }()
    static func processedImage(_ element: CanvasElement) -> CGImage? {
        guard let data = element.imageData else { return nil }
        let a = element.adjustments
        let key = "\(data.hashValue)-\(element.maskData?.hashValue ?? 0)-\(element.maskEnabled ?? true)-\(element.maskInverted ?? false)-\(element.maskFeather ?? 0)-\(a.exposure)-\(a.contrast)-\(a.saturation)-\(a.temperature)-\(a.blur)" as NSString
        if let cached = cache.object(forKey: key) { return cached.image }
        guard let source = CIImage(data: data, options: [.applyOrientationProperty: true]) else { return nil }
        var image = source.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: a.exposure])
        image = image.applyingFilter("CIColorControls", parameters: [kCIInputContrastKey: a.contrast, kCIInputSaturationKey: a.saturation])
        image = image.applyingFilter("CITemperatureAndTint", parameters: ["inputNeutral": CIVector(x: 6500, y: 0), "inputTargetNeutral": CIVector(x: a.temperature, y: 0)])
        if a.blur > 0 { image = image.clampedToExtent().applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: a.blur]).cropped(to: source.extent) }
        if element.maskEnabled != false, let data = element.maskData, var mask = CIImage(data: data) {
            if element.maskInverted == true { mask = mask.applyingFilter("CIColorInvert") }
            if let radius = element.maskFeather, radius > 0 { mask = mask.clampedToExtent().applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius]).cropped(to: mask.extent) }
            let resized = mask.transformed(by: CGAffineTransform(scaleX: source.extent.width / mask.extent.width, y: source.extent.height / mask.extent.height))
            image = image.applyingFilter("CIBlendWithMask", parameters: [kCIInputBackgroundImageKey: CIImage(color: .clear).cropped(to: source.extent), kCIInputMaskImageKey: resized])
        }
        guard let cg = imageContext.createCGImage(image, from: source.extent) else { return nil }
        cache.setObject(CachedImage(cg), forKey: key, cost: cg.bytesPerRow * cg.height)
        return cg
    }
    static func draw(_ document: CreativeDocument, in context: CGContext, page: Int = 0, time: Double? = nil, background: Bool = true) {
        context.saveGState()
        context.clip(to: CGRect(x: 0, y: 0, width: document.width, height: document.height))
        if background && document.transparentBackground != true {
            context.setFillColor(NSColor(hex: document.background).cgColor)
            context.fill(CGRect(x: 0, y: 0, width: document.width, height: document.height))
        }
        let elements = document.tool == .press ? TextFlow.elements(document) : document.elements
        for layer in elements where layer.page == page && layer.visible {
            if let time, time < (layer.inPoint ?? 0) || time >= (layer.outPoint ?? .greatestFiniteMagnitude) { continue }
            draw(time.map { layer.evaluated(at: $0) } ?? layer, in: context)
        }
        context.restoreGState()
    }
    static func draw(_ e: CanvasElement, in context: CGContext) {
        context.saveGState()
        context.setAlpha(e.opacity)
        switch e.blendMode ?? .normal {
        case .normal: context.setBlendMode(.normal)
        case .multiply: context.setBlendMode(.multiply)
        case .screen: context.setBlendMode(.screen)
        case .overlay: context.setBlendMode(.overlay)
        case .darken: context.setBlendMode(.darken)
        case .lighten: context.setBlendMode(.lighten)
        case .colorDodge: context.setBlendMode(.colorDodge)
        case .colorBurn: context.setBlendMode(.colorBurn)
        case .softLight: context.setBlendMode(.softLight)
        case .hardLight: context.setBlendMode(.hardLight)
        case .difference: context.setBlendMode(.difference)
        case .exclusion: context.setBlendMode(.exclusion)
        }
        context.translateBy(x: e.x + e.width / 2, y: e.y + e.height / 2)
        context.rotate(by: e.rotation * .pi / 180)
        context.translateBy(x: -e.width / 2, y: -e.height / 2)
        context.setFillColor(NSColor(hex: e.fill).cgColor)
        context.setStrokeColor(NSColor(hex: e.stroke).cgColor)
        context.setLineWidth(max(0, e.strokeWidth))
        let rect = CGRect(x: 0, y: 0, width: e.width, height: e.height)
        switch e.kind {
        case .rectangle:
            let radius = min(e.cornerRadius, e.width / 2, e.height / 2)
            context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
            context.drawPath(using: e.strokeWidth > 0 ? .fillStroke : .fill)
        case .ellipse:
            context.addEllipse(in: rect); context.drawPath(using: e.strokeWidth > 0 ? .fillStroke : .fill)
        case .line:
            context.setLineWidth(max(1, e.strokeWidth)); context.setLineCap(.round)
            context.move(to: .zero); context.addLine(to: CGPoint(x: e.width, y: e.height)); context.strokePath()
        case .path:
            if let commands = e.vectorPath {
                context.addPath(VectorGeometry.path(e)); context.setLineCap(.round); context.setLineJoin(.round)
                context.drawPath(using: commands.contains(where: { $0.verb == .close }) ? (e.strokeWidth > 0 ? .fillStroke : .fill) : .stroke)
            } else if let first = e.points.first {
                context.setLineWidth(max(1, e.strokeWidth)); context.setLineCap(.round); context.setLineJoin(.round)
                context.move(to: CGPoint(x: first.x, y: first.y))
                if e.points.count == 1 { context.addLine(to: CGPoint(x: first.x + 0.01, y: first.y + 0.01)) }
                for point in e.points.dropFirst() { context.addLine(to: CGPoint(x: point.x, y: point.y)) }
                context.strokePath()
            }
        case .text:
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
            (e.text as NSString).draw(in: rect, withAttributes: TextFlow.attributes(e))
            NSGraphicsContext.restoreGraphicsState()
        case .image:
            if let image = processedImage(e) {
                context.interpolationQuality = .high
                context.translateBy(x: 0, y: e.height); context.scaleBy(x: 1, y: -1)
                context.draw(image, in: rect)
            }
        }
        context.restoreGState()
    }
    static func image(_ document: CreativeDocument, page: Int = 0, time: Double? = nil, maxDimension: Double? = nil, transparent: Bool = false) -> CGImage? {
        let scale = maxDimension.map { min(1, $0 / max(document.width, document.height)) } ?? 1
        let width = max(1, Int(document.width * scale)), height = max(1, Int(document.height * scale))
        guard width * height <= 100_000_000,
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: CGFloat(width) / document.width, y: -CGFloat(height) / document.height)
        draw(document, in: context, page: page, time: time, background: !transparent)
        return context.makeImage()
    }
    static func thumbnail(_ document: CreativeDocument, page: Int = 0) -> NSImage? {
        image(document, page: page, maxDimension: 240).map { NSImage(cgImage: $0, size: .zero) }
    }
    static func writeImage(_ image: CGImage, to url: URL, type: UTType, quality: Double = 0.92) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil) else {
            throw DocumentError.invalid("The image destination could not be opened.")
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw DocumentError.invalid("The image could not be encoded.") }
    }
    static func pdf(_ document: CreativeDocument, to url: URL) throws {
        var rect = CGRect(x: 0, y: 0, width: document.width, height: document.height)
        guard let context = CGContext(url as CFURL, mediaBox: &rect, [kCGPDFContextTitle as String: document.title] as CFDictionary) else {
            throw DocumentError.invalid("The PDF destination could not be opened.")
        }
        for page in 0..<document.pageCount {
            context.beginPDFPage(nil)
            context.saveGState()
            context.translateBy(x: 0, y: document.height); context.scaleBy(x: 1, y: -1)
            draw(document, in: context, page: page)
            context.restoreGState()
            context.endPDFPage()
        }
        context.closePDF()
    }
    static func gif(_ document: CreativeDocument, to url: URL) throws {
        guard document.width * document.height * Double(document.pageCount) <= 300_000_000 else { throw DocumentError.invalid("Reduce the canvas size or frame count before exporting this GIF.") }
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, document.pageCount, nil) else { throw DocumentError.invalid("The GIF destination could not be opened.") }
        CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        for page in 0..<document.pageCount {
            guard let image = image(document, page: page) else { throw DocumentError.invalid("An animation frame could not be rendered.") }
            let properties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1 / Double(document.fps), kCGImagePropertyGIFUnclampedDelayTime: 1 / Double(document.fps)]]
            CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        }
        guard CGImageDestinationFinalize(destination) else { throw DocumentError.invalid("The animation could not be encoded.") }
    }
}
