import AppKit
import Foundation

struct Template: Decodable {
    let id: String
    let title: String
    let durationSeconds: Double
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let files = FileManager.default
let ids = try files.contentsOfDirectory(atPath: root.appendingPathComponent("templates").path)
    .filter { $0.range(of: #"^\d{2}-"#, options: .regularExpression) != nil }.sorted()
precondition(ids.count == 20, "Expected twenty templates")
let width = 2992
let height = 2610
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
NSColor(calibratedRed: 0.94, green: 0.96, blue: 0.94, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

func text(_ value: String, x: CGFloat, top: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular) {
    (value as NSString).draw(at: NSPoint(x: x, y: CGFloat(height) - top - size * 1.3),
        withAttributes: [.font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: NSColor(calibratedRed: 0.07, green: 0.13, blue: 0.11, alpha: 1)])
}

text("DEVIN / macOS + iOS", x: 32, top: 26, size: 25, weight: .medium)
text("Twenty launch directions", x: 32, top: 68, size: 58, weight: .medium)
text("1920 × 1080  /  30 fps  /  editable Remotion sources", x: 1610, top: 93, size: 26)
for (index, id) in ids.enumerated() {
    let template = try JSONDecoder().decode(Template.self, from: Data(contentsOf:
        root.appendingPathComponent("templates/\(id)/template.json")))
    let x = CGFloat(32 + (index % 4) * 740)
    let top = CGFloat(176 + (index / 4) * 478)
    guard let image = NSImage(contentsOf: root.appendingPathComponent("out/\(id)-poster.png")) else {
        fatalError("Missing poster: \(id)")
    }
    image.draw(in: NSRect(x: x, y: CGFloat(height) - top - 405, width: 720, height: 405),
        from: .zero, operation: .sourceOver, fraction: 1)
    let duration = template.durationSeconds.formatted(.number.precision(.fractionLength(0...1)))
    text("\(id.prefix(2))  \(template.title)  ·  \(duration)s", x: x, top: top + 420, size: 25, weight: .medium)
}
NSGraphicsContext.restoreGraphicsState()
let output = root.appendingPathComponent("out/devin-launch-montage.png")
try bitmap.representation(using: .png, properties: [:])!.write(to: output)
print(output.path)
