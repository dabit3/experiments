import AppKit
import CoreImage
import DevinCore

struct PixelRasterSettings {
    var tolerance = 32.0
    var contiguous = true
    var aligned = true
    var strength = 0.5
    var radialGradient = false
    var sampleRadius = 0
    var polygonSides = 5
    var saturate = false
}
struct PixelCloneSource {
    var layer: CanvasElement
    var point: CGPoint
}
struct PixelColorSample: Identifiable {
    let id = UUID()
    var point: CGPoint
    var color: String
}

enum PixelRasterTools {
    static let strokes: Set<DrawingTool> = [.pencil, .cloneStamp, .healingBrush, .patternStamp, .historyBrush, .backgroundEraser, .blur, .sharpen, .dodge, .burn, .sponge, .colorReplacement]
    static let fills: Set<DrawingTool> = [.gradient, .paintBucket, .magicEraser]
    static func grid(_ image: CGImage) throws -> RasterGrid {
        guard image.width * image.height <= 16_777_216,
              let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue), let data = context.data else { throw DocumentError.invalid("This tool supports images up to 16 megapixels.") }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        var bytes = Array(UnsafeBufferPointer(start: data.assumingMemoryBound(to: UInt8.self), count: image.width * image.height * 4))
        for i in stride(from: 0, to: bytes.count, by: 4) {
            let alpha = Int(bytes[i + 3])
            for c in 0..<3 { bytes[i + c] = alpha == 0 ? 0 : UInt8(min(255, (Int(bytes[i + c]) * 255 + alpha / 2) / alpha)) }
        }
        return try RasterGrid(width: image.width, height: image.height, rgba: bytes)
    }
    static func image(_ layer: CanvasElement) throws -> CIImage {
        guard let data = layer.imageData, let image = CIImage(data: data, options: [.applyOrientationProperty: true]), image.extent.width * image.extent.height <= 16_777_216 else { throw DocumentError.invalid("Select a readable pixel layer of 16 megapixels or fewer.") }
        return image
    }
    static func bitmap(_ layer: CanvasElement) throws -> RasterGrid {
        let image = try image(layer)
        guard let cg = Renderer.imageContext.createCGImage(image, from: image.extent) else { throw DocumentError.invalid("The pixel layer could not be decoded.") }
        return try grid(cg)
    }
    static func pixelPoint(_ point: CGPoint, layer: CanvasElement, width: Int, height: Int) -> CGPoint {
        let local = point.applying(RasterEditing.inverseTransform(layer))
        return CGPoint(x: local.x * Double(width) / layer.width, y: local.y * Double(height) / layer.height)
    }
    static func grayImage(_ mask: [UInt8], width: Int, height: Int) throws -> CGImage {
        guard mask.count == width * height, let provider = CGDataProvider(data: Data(mask) as CFData), let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else { throw DocumentError.invalid("The selection mask could not be created.") }
        return image
    }
    static func region(_ layer: CanvasElement, point: CGPoint, settings: PixelRasterSettings) throws -> (RasterGrid, [UInt8]) {
        guard settings.tolerance.isFinite, (0...255).contains(settings.tolerance), point.x.isFinite, point.y.isFinite else { throw DocumentError.invalid("The color selection settings are invalid.") }
        let pixels = try bitmap(layer), p = pixelPoint(point, layer: layer, width: pixels.width, height: pixels.height)
        return (pixels, pixels.region(x: Int(floor(p.x)), y: Int(floor(p.y)), tolerance: Int(settings.tolerance), contiguous: settings.contiguous))
    }
    static func selection(_ layer: CanvasElement, point: CGPoint, settings: PixelRasterSettings) throws -> CGPath {
        let (pixels, mask) = try region(layer, point: point, settings: settings)
        let path = CGMutablePath()
        let transform = RasterEditing.inverseTransform(layer).inverted()
        var runs = 0
        for y in 0..<pixels.height {
            var x = 0
            while x < pixels.width {
                if mask[y * pixels.width + x] == 0 { x += 1; continue }
                let start = x
                while x < pixels.width && mask[y * pixels.width + x] != 0 { x += 1 }
                runs += 1
                guard runs <= 100000 else { throw DocumentError.invalid("This selection is too complex. Use a smaller image or a narrower tolerance.") }
                path.addRect(CGRect(x: Double(start) / Double(pixels.width) * layer.width, y: Double(y) / Double(pixels.height) * layer.height, width: Double(x - start) / Double(pixels.width) * layer.width, height: layer.height / Double(pixels.height)), transform: transform)
            }
        }
        return path
    }
    static func coverage(layer: CanvasElement, document: CreativeDocument, points: [CGPoint], size: Double, opacity: Double, hardness: Double, selection: CGPath?, stroke: Bool) throws -> CIImage {
        let source = try image(layer)
        if !stroke {
            guard let data = RasterEditing.selectionMask(nil, layer: layer, path: selection), let mask = CIImage(data: data) else { throw DocumentError.invalid("The selection could not be rendered.") }
            return mask.applyingFilter("CIMaskToAlpha").applyingFilter("CIColorMatrix", parameters: ["inputAVector": CIVector(x: 0, y: 0, z: 0, w: opacity)])
        }
        var empty = layer; empty.imageData = nil; empty.maskData = nil; empty.locked = false
        var dimensions = document; dimensions.width = source.extent.width; dimensions.height = source.extent.height
        let mask = try RasterEditing.paint(empty, document: dimensions, points: points, size: size, color: "FFFFFF", opacity: opacity, erase: false, selection: nil, selectionPath: selection, hardness: hardness)
        guard let data = mask.imageData, let result = CIImage(data: data) else { throw DocumentError.invalid("The brush mask could not be decoded.") }
        return result
    }
    static func apply(_ tool: DrawingTool, layer: CanvasElement, document: CreativeDocument, points: [CGPoint], size: Double, opacity: Double, hardness: Double, foreground: String, background: String, settings: PixelRasterSettings, selection: CGPath?, clone: PixelCloneSource?, pattern: CanvasElement?, history: CanvasElement?) throws -> CanvasElement {
        guard !layer.locked, let first = points.first else { throw DocumentError.invalid("Unlock and select a pixel layer before using this tool.") }
        guard size.isFinite, (1...500).contains(size), opacity.isFinite, (0...1).contains(opacity), hardness.isFinite, (0...1).contains(hardness), settings.strength.isFinite, (0...1).contains(settings.strength), points.count <= 20000, points.allSatisfy({ $0.x.isFinite && $0.y.isFinite && abs($0.x) <= 1_000_000 && abs($0.y) <= 1_000_000 }) else { throw DocumentError.invalid("The raster tool settings are invalid.") }
        guard opacity > 0, selection?.isEmpty != true else { return layer }
        if [.blur, .sharpen, .dodge, .burn, .sponge].contains(tool) && settings.strength == 0 { return layer }
        if tool == .pencil { return try RasterEditing.paint(layer, document: document, points: points, size: size, color: foreground, opacity: opacity, erase: false, selection: nil, selectionPath: selection, hardness: 1, antialias: false) }
        let source = try image(layer), extent = source.extent
        let width = Int(extent.width), height = Int(extent.height)
        let start = pixelPoint(first, layer: layer, width: width, height: height)
        var amount = try coverage(layer: layer, document: document, points: points, size: size, opacity: opacity, hardness: hardness, selection: selection, stroke: strokes.contains(tool))
        var effect: CIImage
        let color = CIColor(color: NSColor(hex: foreground))!
        switch tool {
        case .gradient:
            let end = pixelPoint(points.last ?? first, layer: layer, width: width, height: height)
            let c1 = CIColor(color: NSColor(hex: background))!
            if hypot(end.x - start.x, end.y - start.y) < 0.001 { effect = CIImage(color: color).cropped(to: extent) }
            else if settings.radialGradient {
                effect = CIFilter(name: "CIRadialGradient", parameters: ["inputCenter": CIVector(x: start.x, y: extent.height - start.y), "inputRadius0": 0, "inputRadius1": hypot(end.x - start.x, end.y - start.y), "inputColor0": color, "inputColor1": c1])!.outputImage!.cropped(to: extent)
            } else {
                effect = CIFilter(name: "CILinearGradient", parameters: ["inputPoint0": CIVector(x: start.x, y: extent.height - start.y), "inputPoint1": CIVector(x: end.x, y: extent.height - end.y), "inputColor0": color, "inputColor1": c1])!.outputImage!.cropped(to: extent)
            }
        case .paintBucket, .magicEraser, .backgroundEraser, .colorReplacement:
            var regionSettings = settings
            if tool == .backgroundEraser || tool == .colorReplacement { regionSettings.contiguous = false }
            let (pixels, mask) = try region(layer, point: first, settings: regionSettings)
            let region = CIImage(cgImage: try grayImage(mask, width: pixels.width, height: pixels.height)).applyingFilter("CIMaskToAlpha")
            amount = amount.applyingFilter("CISourceInCompositing", parameters: [kCIInputBackgroundImageKey: region])
            if tool == .magicEraser || tool == .backgroundEraser { effect = CIImage(color: .clear).cropped(to: extent) }
            else if tool == .colorReplacement { effect = CIImage(color: color).cropped(to: extent).applyingFilter("CIColorBlendMode", parameters: [kCIInputBackgroundImageKey: source]) }
            else { effect = CIImage(color: color).cropped(to: extent) }
        case .cloneStamp, .healingBrush:
            guard let clone, clone.layer.id == layer.id else { throw DocumentError.invalid("Option-click this pixel layer to set a sample source first.") }
            let sampled = try image(clone.layer)
            let sourcePoint = pixelPoint(clone.point, layer: layer, width: width, height: height)
            effect = sampled.transformed(by: CGAffineTransform(translationX: start.x - sourcePoint.x, y: sourcePoint.y - start.y))
            if tool == .healingBrush {
                let original = try bitmap(layer), reference = try bitmap(clone.layer)
                let radius = max(1, Int(size / layer.width * Double(width) / 2))
                let targetTone = original.average(x: Int(start.x), y: Int(start.y), radius: radius)
                let sourceTone = reference.average(x: Int(sourcePoint.x), y: Int(sourcePoint.y), radius: radius)
                effect = effect.applyingFilter("CIColorMatrix", parameters: ["inputBiasVector": CIVector(x: targetTone[0] - sourceTone[0], y: targetTone[1] - sourceTone[1], z: targetTone[2] - sourceTone[2], w: 0)])
            }
            effect = effect.composited(over: CIImage(color: .clear).cropped(to: extent)).cropped(to: extent)
        case .patternStamp:
            guard let pattern else { throw DocumentError.invalid("Use Set Pattern in the options bar before painting.") }
            effect = try image(pattern).applyingFilter("CIAffineTile").cropped(to: extent)
        case .historyBrush:
            guard let history, history.id == layer.id else { throw DocumentError.invalid("Set a history source for this layer before painting.") }
            effect = try image(history).cropped(to: extent)
        case .blur: effect = source.clampedToExtent().applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: max(0.1, size * settings.strength * Double(width) / layer.width / 8)]).cropped(to: extent)
        case .sharpen: effect = source.applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: settings.strength * 2])
        case .dodge, .burn: effect = source.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: settings.strength * (tool == .dodge ? 2 : -2)])
        case .sponge: effect = source.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 1 + settings.strength * (settings.saturate ? 1 : -1)])
        default: throw DocumentError.invalid("This pixel operation is not implemented.")
        }
        let result = effect.applyingFilter("CIBlendWithAlphaMask", parameters: [kCIInputBackgroundImageKey: source, kCIInputMaskImageKey: amount]).cropped(to: extent)
        guard let cg = Renderer.imageContext.createCGImage(result, from: extent), let data = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else { throw DocumentError.invalid("The pixel operation could not be encoded.") }
        var updated = layer; updated.imageData = data
        return updated
    }
}
