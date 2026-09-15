import AppKit
import Foundation

// Run from launch-video-templates after rendering. Frame samples match config.ts.
let frames = [
    0, 20, 60, 119, 120, 140, 180, 239, 240, 260, 315, 389,
    390, 410, 449, 450, 480, 509, 510, 540, 569, 570, 590, 645,
    719, 720, 810, 899, 900, 920, 990, 1079, 1080, 1100, 1140, 1199,
]
let sceneStarts = [0, 120, 240, 390, 570, 720, 900, 1080]
let sceneNames = ["HOOK", "CONTEXT", "BUILD / RUN", "INTERACT", "FIX", "EVIDENCE", "OUTCOME", "LOGO"]
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let out = root.appendingPathComponent("out")
let frameDirectory = out.appendingPathComponent("09-brutalist-clean-frames")
let video = out.appendingPathComponent("09-brutalist-clean.mp4")

func run(_ arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = arguments
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw NSError(domain: "MediaQA", code: Int(process.terminationStatus))
    }
}

try FileManager.default.createDirectory(at: frameDirectory, withIntermediateDirectories: true)
let select = frames.map { "eq(n,\($0))" }.joined(separator: "+")
try run([
    "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", video.path,
    "-vf", "select='\(select)'", "-fps_mode", "vfr",
    frameDirectory.appendingPathComponent("%03d.png").path,
])
try run([
    "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-ss", "2", "-i", video.path,
    "-frames:v", "1", out.appendingPathComponent("09-brutalist-clean-poster.png").path,
])

let cellWidth = 480
let cellHeight = 306
let headerHeight = 96
let width = cellWidth * 4
let height = cellHeight * 9 + headerHeight
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not allocate contact-sheet bitmap")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
NSColor(calibratedWhite: 0.025, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
let heading: [NSAttributedString.Key: NSObject] = [
    .font: NSFont.boldSystemFont(ofSize: 30),
    .foregroundColor: NSColor.white,
]
("09 / BRUTALIST CLEAN — 40s · 1920 × 1080 · 30 fps" as NSString).draw(
    at: NSPoint(x: 22, y: height - 60), withAttributes: heading
)
let label: [NSAttributedString.Key: NSObject] = [
    .font: NSFont.monospacedSystemFont(ofSize: 17, weight: .medium),
    .foregroundColor: NSColor.white,
]
for (index, frame) in frames.enumerated() {
    let imageURL = frameDirectory.appendingPathComponent(String(format: "%03d.png", index + 1))
    guard let image = NSImage(contentsOf: imageURL) else {
        fatalError("Missing extracted frame: \(imageURL.path)")
    }
    let column = index % 4
    let row = index / 4
    let x = column * cellWidth
    let y = height - headerHeight - (row + 1) * cellHeight
    image.draw(in: NSRect(x: x, y: y, width: cellWidth, height: 270))
    let sceneIndex = sceneStarts.lastIndex(where: { $0 <= frame }) ?? 0
    let time = String(format: "%06.2fs / f%04d / ", Double(frame) / 30, frame)
    ((time + sceneNames[sceneIndex]) as NSString).draw(
        at: NSPoint(x: x + 12, y: y + 279), withAttributes: label
    )
}
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode contact sheet")
}
let destination = out.appendingPathComponent("09-brutalist-clean-contact-sheet.png")
try png.write(to: destination)
print("Saved full-frame poster, 36 sampled frames, and \(destination.lastPathComponent)")
