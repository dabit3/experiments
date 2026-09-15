import AppKit
import Foundation

let samples: [(Int, String)] = [
    (0, "Hook / first frame"), (60, "Hook / native reveal"),
    (119, "Hook / hold"), (120, "Context / cut"),
    (180, "Context / CI wait"), (246, "Build / wireframe"),
    (267, "Build / 600ms resolve"), (276, "Build / screenshot"),
    (330, "Build / representative build"), (419, "Build / last frame"),
    (426, "Simulator / wireframe"), (447, "Simulator / resolve"),
    (456, "Simulator / screenshot"), (525, "Simulator / type"),
    (570, "Simulator / scroll"), (606, "Fix / wireframe"),
    (627, "Fix / resolve"), (636, "Fix / screenshot"),
    (750, "Fix / retest stage"), (786, "Evidence / wireframe"),
    (807, "Evidence / resolve"), (820, "Evidence / native screenshot"),
    (851, "Evidence / recording transition"), (885, "Evidence / actual web QA"),
    (959, "Evidence / last clip frame"), (960, "Outcome / cut"),
    (1040, "Outcome / hold"), (1080, "End card / cut"),
    (1140, "End card / logo"), (1199, "End card / last frame")
]

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let out = root.appendingPathComponent("out")
let frames = out.appendingPathComponent("15-wireframe-to-real-frames")
try FileManager.default.createDirectory(at: frames, withIntermediateDirectories: true)
let video = out.appendingPathComponent("15-wireframe-to-real.mp4")

func ffmpeg(_ arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["ffmpeg", "-v", "error", "-y"] + arguments
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw NSError(domain: "VideoQA", code: Int(process.terminationStatus))
    }
}

let selection = samples.map { "eq(n\\,\($0.0))" }.joined(separator: "+")
try ffmpeg(["-i", video.path, "-vf", "select='\(selection)'", "-fps_mode", "vfr",
            frames.appendingPathComponent("frame-%02d.png").path])
try ffmpeg(["-i", video.path, "-vf", "select='eq(n\\,330)'", "-frames:v", "1",
            "-update", "1", out.appendingPathComponent("15-wireframe-to-real-poster.png").path])

let columns = 5
let cellWidth = 480
let cellHeight = 308
let rows = (samples.count + columns - 1) / columns
let canvasWidth = columns * cellWidth
let canvasHeight = rows * cellHeight
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: canvasWidth,
    pixelsHigh: canvasHeight, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(calibratedRed: 0.94, green: 0.95, blue: 0.93, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight).fill()
for (index, sample) in samples.enumerated() {
    let column = index % columns
    let row = index / columns
    let x = column * cellWidth
    let y = canvasHeight - (row + 1) * cellHeight
    let imageURL = frames.appendingPathComponent(String(format: "frame-%02d.png", index + 1))
    guard let image = NSImage(contentsOf: imageURL) else {
        throw NSError(domain: "MissingQAFrame", code: index)
    }
    image.draw(in: NSRect(x: x, y: y + 38, width: cellWidth, height: 270),
               from: .zero, operation: .sourceOver, fraction: 1)
    let label = String(format: "%05.2fs  %@", Double(sample.0) / 30, sample.1)
    let caption = NSMutableAttributedString(string: label)
    let captionRange = NSRange(location: 0, length: caption.length)
    caption.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium), range: captionRange)
    caption.addAttribute(.foregroundColor, value: NSColor(calibratedWhite: 0.13, alpha: 1), range: captionRange)
    caption.draw(at: NSPoint(x: x + 10, y: y + 12))
}
NSGraphicsContext.restoreGraphicsState()
let png = bitmap.representation(using: .png, properties: [:])!
try png.write(to: out.appendingPathComponent("15-wireframe-to-real-contact-sheet.png"))
print("Saved 30 full-frame QA samples, 1920×1080 poster, and 2400×1848 contact sheet.")
