import AppKit
import Foundation

let frames: [(Int, String)] = [
    (0, "Hook / opening"), (60, "Hook / hold"),
    (134, "Hook → context / before"), (144, "Hook → context / dissolve"),
    (195, "Context / hold"), (254, "Context → build / before"),
    (264, "Context → build / dissolve"), (330, "01 Build + run / hold"),
    (404, "Build → Simulator / before"), (414, "Build → Simulator / dissolve"),
    (480, "02 Simulator / hold"), (569, "Simulator → fix / before"),
    (579, "Simulator → fix / dissolve"), (660, "03 Fix + retest / hold"),
    (734, "Fix → evidence / before"), (744, "Fix → evidence / dissolve"),
    (810, "04 Evidence / hold"), (899, "Evidence → outcome / before"),
    (909, "Evidence → outcome / dissolve"), (975, "Outcome / poster"),
    (1064, "Outcome → brand / before"), (1074, "Outcome → brand / dissolve"),
    (1150, "Brand / hold"), (1214, "Final encoded frame")
]
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let folder = root.appendingPathComponent("out/13-cinematic-macro", isDirectory: true)
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
let ffmpeg = Process()
ffmpeg.executableURL = URL(fileURLWithPath: "/usr/bin/env")
ffmpeg.arguments = [
    "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
    "-i", root.appendingPathComponent("out/13-cinematic-macro.mp4").path,
    "-vf", "select='\(frames.map { "eq(n,\($0.0))" }.joined(separator: "+"))'",
    "-fps_mode", "vfr", folder.appendingPathComponent("qa-%02d.png").path
]
try ffmpeg.run()
ffmpeg.waitUntilExit()
guard ffmpeg.terminationStatus == 0 else { fatalError("Frame extraction failed") }

let width = 2620
let height = 2608
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not create the contact sheet")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
NSColor(calibratedRed: 0.045, green: 0.065, blue: 0.08, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
func text(_ value: String, x: CGFloat, y: CGFloat, size: CGFloat, color: NSColor) {
    (value as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [
        .font: NSFont.systemFont(ofSize: size, weight: .medium),
        .foregroundColor: color
    ])
}
text("13 / CINEMATIC MACRO", x: 20, y: CGFloat(height - 48), size: 28, color: .white)
text("40.5 s  ·  1920 × 1080  ·  30 fps  ·  Encoded MP4 frames, chronological order",
     x: 20, y: CGFloat(height - 80), size: 18, color: .lightGray)
for (index, entry) in frames.enumerated() {
    let path = folder.appendingPathComponent(String(format: "qa-%02d.png", index + 1))
    guard let image = NSImage(contentsOf: path) else { fatalError("Missing frame \(entry.0)") }
    let x = CGFloat(12 + index % 4 * 652)
    let top = CGFloat(height - 112 - index / 4 * 416)
    image.draw(in: NSRect(x: x, y: top - 360, width: 640, height: 360))
    let seconds = Double(entry.0) / 30
    text(String(format: "%06.2f s  ·  %@", seconds, entry.1),
         x: x + 8, y: top - 389, size: 17, color: .lightGray)
}
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode PNG")
}
try png.write(to: folder.appendingPathComponent("contact-sheet.png"))
print("Wrote 24-frame contact sheet to \(folder.path)")
