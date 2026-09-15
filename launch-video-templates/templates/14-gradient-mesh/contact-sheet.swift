import AppKit
import Foundation

let samples: [(Int, String)] = [
    (0, "Opening frame"), (60, "Hook"), (134, "Before context"),
    (135, "Context cut"), (146, "Context entrance"), (195, "Context hold"),
    (254, "Before build"), (255, "Build cut"), (266, "Build entrance"),
    (330, "Build / run"), (404, "Before interaction"), (405, "Interaction cut"),
    (416, "Interaction entrance"), (480, "Tap / type / scroll"),
    (554, "Before iteration"), (555, "Iteration cut"), (566, "Iteration entrance"),
    (645, "Reproduce / fix / retest"), (719, "Before evidence"),
    (720, "Evidence cut"), (731, "Evidence early"), (760, "Source video A"),
    (825, "Review evidence"), (880, "Source video B"), (899, "Before outcome"),
    (900, "Outcome cut"), (911, "Outcome entrance"), (990, "Outcome / pricing"),
    (1064, "Before logo"), (1065, "Logo cut"), (1076, "Logo entrance"),
    (1140, "Logo end card"), (1199, "Final frame"),
]
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let out = root.appendingPathComponent("out")
let frames = out.appendingPathComponent("14-gradient-mesh-qa")
let movie = out.appendingPathComponent("14-gradient-mesh.mp4")
guard FileManager.default.fileExists(atPath: movie.path) else {
    fatalError("Run from launch-video-templates after rendering the MP4.")
}
try FileManager.default.createDirectory(at: frames, withIntermediateDirectories: true)
let selection = samples.map { "eq(n,\($0.0))" }.joined(separator: "+")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = [
    "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", movie.path,
    "-vf", "select='\(selection)'", "-fps_mode", "vfr",
    frames.appendingPathComponent("frame-%02d.png").path,
]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else { fatalError("Frame extraction failed.") }
try Data(contentsOf: frames.appendingPathComponent("frame-02.png"))
    .write(to: out.appendingPathComponent("14-gradient-mesh-poster.png"))

let columns = 4
let rows = Int(ceil(Double(samples.count) / Double(columns)))
let width = 1920
let height = 120 + rows * 320
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not create contact sheet canvas.")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
NSColor(calibratedRed: 0.94, green: 0.96, blue: 0.95, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
func text(_ string: String, x: Int, y: Int, size: CGFloat, weight: NSFont.Weight = .regular) {
    (string as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: NSColor(calibratedWhite: 0.16, alpha: 1),
    ])
}
text("14 / GRADIENT MESH", x: 24, y: height - 53, size: 28, weight: .medium)
text("40s · 1920 × 1080 · 30fps   |   Scene holds + every cut + entrance frames",
     x: 24, y: height - 88, size: 20)
for (index, sample) in samples.enumerated() {
    let x = 24 + (index % columns) * 480
    let y = height - 120 - ((index / columns) + 1) * 320 + 24
    let url = frames.appendingPathComponent(String(format: "frame-%02d.png", index + 1))
    guard let image = NSImage(contentsOf: url) else { fatalError("Missing \(url.path)") }
    image.draw(in: NSRect(x: CGFloat(x), y: CGFloat(y), width: 456, height: 256.5),
               from: .zero, operation: .copy, fraction: 1)
    let label = String(format: "%05.2fs · %@", Double(sample.0) / 30, sample.1)
    text(label, x: x, y: y + 266, size: 17, weight: .medium)
}
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode contact sheet.")
}
let contactSheet = out.appendingPathComponent("14-gradient-mesh-contact-sheet.png")
try png.write(to: contactSheet)
print("Extracted \(samples.count) full frames; wrote poster and \(contactSheet.lastPathComponent).")
