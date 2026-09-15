import AppKit
import DevinCore

enum IconGenerator {
    static func generate(at directory: URL) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for tool in [nil] + StudioTool.allCases.map(Optional.some) {
                let name = tool?.rawValue ?? "studio"
                let folder = directory.appendingPathComponent(name + ".iconset")
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                for size in [16, 32, 128, 256, 512] {
                    for factor in [1, 2] {
                        guard let image = image(tool: tool, size: size * factor) else { throw DocumentError.invalid("An icon could not be rendered.") }
                        let file = "icon_\(size)x\(size)\(factor == 2 ? "@2x" : "").png"
                        try Renderer.writeImage(image, to: folder.appendingPathComponent(file), type: .png)
                    }
                }
            }
        } catch { fputs("Icon generation failed: \(error.localizedDescription)\n", stderr); exit(1) }
    }
    static func image(tool: StudioTool?, size: Int) -> CGImage? {
        guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
        let accent = NSColor(hex: tool?.color ?? "B5E7C9")
        let rect = CGRect(x: 82, y: 82, width: 860, height: 860)
        let path = CGPath(roundedRect: rect, cornerWidth: 192, cornerHeight: 192, transform: nil)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -14), blur: 30, color: NSColor.black.withAlphaComponent(0.35).cgColor)
        context.setFillColor(NSColor(hex: "1C2620").cgColor); context.addPath(path); context.fillPath(); context.restoreGState()
        context.saveGState(); context.addPath(path); context.clip()
        let colors = [NSColor(hex: "354237").cgColor, NSColor(hex: "141D17").cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) { context.drawLinearGradient(gradient, start: CGPoint(x: 100, y: 924), end: CGPoint(x: 800, y: 80), options: []) }
        context.setStrokeColor(accent.withAlphaComponent(0.08).cgColor); context.setLineWidth(2)
        for i in 0..<8 { context.strokeEllipse(in: CGRect(x: 70 - i * 50, y: 120 - i * 50, width: 500 + i * 100, height: 500 + i * 100)) }
        context.restoreGState()
        context.setStrokeColor(accent.withAlphaComponent(0.35).cgColor); context.setLineWidth(3); context.addPath(path); context.strokePath()
        NSGraphicsContext.saveGraphicsState()
        context.translateBy(x: 0, y: 1024); context.scaleBy(x: 1, y: -1)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
        let text = tool?.monogram ?? "d"
        let font = NSFont.systemFont(ofSize: tool == nil ? 650 : 380, weight: .semibold)
        (text as NSString).draw(in: CGRect(x: 80, y: tool == nil ? 130 : 270, width: 864, height: 740), withAttributes: [.font: font, .foregroundColor: accent, .paragraphStyle: paragraph, .kern: -16])
        if tool != nil { ("DEVIN" as NSString).draw(in: CGRect(x: 100, y: 180, width: 824, height: 70), withAttributes: [.font: NSFont.systemFont(ofSize: 37, weight: .medium), .foregroundColor: accent.withAlphaComponent(0.6), .paragraphStyle: paragraph, .kern: 15]) }
        NSGraphicsContext.restoreGraphicsState()
        return context.makeImage()
    }
}
