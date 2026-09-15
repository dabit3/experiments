import AppKit
import Foundation

struct Sample {
    let frame: Int
    let label: String
}

let samples = [
    Sample(frame: 30, label: "Hook / entrance settled"),
    Sample(frame: 90, label: "Hook / phone focus"),
    Sample(frame: 180, label: "Context / prior CI"),
    Sample(frame: 300, label: "Build / Xcode"),
    Sample(frame: 390, label: "Run / Simulator"),
    Sample(frame: 465, label: "Interact / tap"),
    Sample(frame: 540, label: "Interact / type"),
    Sample(frame: 600, label: "Interact / scroll"),
    Sample(frame: 675, label: "Loop / reproduce"),
    Sample(frame: 735, label: "Loop / fix"),
    Sample(frame: 795, label: "Loop / retest"),
    Sample(frame: 870, label: "Evidence / real web QA"),
    Sample(frame: 945, label: "Evidence / dialog zoom"),
    Sample(frame: 1020, label: "Evidence / cancel result"),
    Sample(frame: 1110, label: "Outcome / Linux pricing"),
    Sample(frame: 1260, label: "End / supplied logo"),
    Sample(frame: 0, label: "First encoded frame"),
    Sample(frame: 119, label: "Hook → context / before"),
    Sample(frame: 125, label: "Hook → context / entrance"),
    Sample(frame: 239, label: "Context → build / before"),
    Sample(frame: 245, label: "Context → build / entrance"),
    Sample(frame: 419, label: "Build → interact / before"),
    Sample(frame: 425, label: "Build → interact / entrance"),
    Sample(frame: 629, label: "Interact → loop / before"),
    Sample(frame: 635, label: "Interact → loop / entrance"),
    Sample(frame: 839, label: "Loop → evidence / before"),
    Sample(frame: 845, label: "Loop → evidence / entrance"),
    Sample(frame: 1049, label: "Evidence → outcome / before"),
    Sample(frame: 1055, label: "Evidence → outcome / entrance"),
    Sample(frame: 1199, label: "Outcome → logo / before"),
    Sample(frame: 1205, label: "Outcome → logo / entrance"),
    Sample(frame: 1319, label: "Final encoded frame"),
]

guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: swift qa.swift <finished.mp4> <ignored-output-directory>")
}
let source = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true).standardizedFileURL
guard FileManager.default.fileExists(atPath: source.path),
      FileManager.default.fileExists(atPath: output.path) else {
    fatalError("Video and output parent must already exist")
}
let frames = output.appendingPathComponent("20-screencast-studio-qa", isDirectory: true)
try FileManager.default.createDirectory(at: frames, withIntermediateDirectories: true)

func extract(frame: Int, to destination: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
        "-ss", String(format: "%.6f", Double(frame) / 30),
        "-i", source.path, "-frames:v", "1", destination.path,
    ]
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { fatalError("ffmpeg failed for frame \(frame)") }
}

for sample in samples {
    try extract(frame: sample.frame, to: frames.appendingPathComponent("frame-\(sample.frame).png"))
}
try extract(frame: 90, to: output.appendingPathComponent("20-screencast-studio-poster.png"))

let width = 1920
let cellWidth = 480
let imageHeight = 270
let rowHeight = 315
let headingHeight = 90
let rows = (samples.count + 3) / 4
let height = headingHeight + rows * rowHeight
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: width * 4, bitsPerPixel: 32
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Unable to allocate contact sheet")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high
NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.97, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
let titleAttributes: [NSAttributedString.Key: NSObject] = [
    .font: NSFont.systemFont(ofSize: 27, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.18, alpha: 1),
]
let labelAttributes: [NSAttributedString.Key: NSObject] = [
    .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.28, alpha: 1),
]
("20 / SCREENCAST STUDIO — scene + transition review" as NSString).draw(
    at: NSPoint(x: 18, y: height - 43), withAttributes: titleAttributes)
("44s · 1920 × 1080 · 30 fps · extracted from the final H.264 encode" as NSString).draw(
    at: NSPoint(x: 18, y: height - 69), withAttributes: labelAttributes)

for (index, sample) in samples.enumerated() {
    let x = (index % 4) * cellWidth
    let top = headingHeight + (index / 4) * rowHeight
    guard let image = NSImage(contentsOf: frames.appendingPathComponent("frame-\(sample.frame).png")) else {
        fatalError("Missing extracted frame")
    }
    image.draw(
        in: NSRect(x: x, y: height - top - imageHeight, width: cellWidth, height: imageHeight),
        from: .zero, operation: .sourceOver, fraction: 1)
    let label = String(format: "%05.2fs  ", Double(sample.frame) / 30) + sample.label
    (label as NSString).draw(
        at: NSPoint(x: x + 10, y: height - top - imageHeight - 26),
        withAttributes: labelAttributes)
}
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode contact sheet")
}
let sheet = output.appendingPathComponent("20-screencast-studio-contact-sheet.png")
try png.write(to: sheet)
print("Extracted \(samples.count) complete frames, poster and contact sheet: \(sheet.path)")
