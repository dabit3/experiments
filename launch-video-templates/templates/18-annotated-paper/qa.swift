import AppKit
import Foundation

// Run from launch-video-templates: swift templates/18-annotated-paper/qa.swift
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("out/18-annotated-paper-qa")
let video = root.appendingPathComponent("out/18-annotated-paper.mp4")
let samples: [(Double, String)] = [
    (0, "Opening frame"), (2.8, "Hook"), (3.966667, "Hook exit"),
    (4, "Context cut"), (6.6, "Context"), (7.966667, "Context exit"),
    (8, "Build cut"), (11.3, "Build + run"), (12.966667, "Build exit"),
    (13, "Interaction cut"), (14.6, "Tap / start button"), (16.6, "Type / message field"),
    (18.6, "Scroll / chart rows"), (19, "Iteration cut"), (23.8, "Reproduce / fix / retest"),
    (24.966667, "Iteration exit"), (25, "Evidence cut"), (28.5, "Recorded web QA"),
    (30.966667, "Evidence exit"), (31, "Outcome cut"), (34.5, "Working app + price"),
    (36.966667, "Outcome exit"), (37, "Logo cut"), (41.966667, "Final frame"),
]

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

try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for (index, sample) in samples.enumerated() {
    let target = output.appendingPathComponent(String(format: "frame-%02d.png", index))
    try run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-ss", "\(sample.0)",
             "-i", video.path, "-frames:v", "1", target.path])
}
try run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-ss", "2.8",
         "-i", video.path, "-frames:v", "1",
         root.appendingPathComponent("out/18-annotated-paper-poster.png").path])

let columns = 3
let cellWidth = 640
let imageHeight = 360
let labelHeight = 42
let rows = (samples.count + columns - 1) / columns
let width = columns * cellWidth
let height = rows * (imageHeight + labelHeight)
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not create contact sheet")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
NSColor(calibratedWhite: 0.15, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
for (index, sample) in samples.enumerated() {
    let x = (index % columns) * cellWidth
    let top = height - (index / columns) * (imageHeight + labelHeight)
    let path = output.appendingPathComponent(String(format: "frame-%02d.png", index))
    guard let image = NSImage(contentsOf: path) else {
        fatalError("Missing sampled frame: \(path.path)")
    }
    image.draw(in: NSRect(x: x, y: top - imageHeight, width: cellWidth, height: imageHeight))
    let label = String(format: "%05.2fs  %@", sample.0, sample.1) as NSString
    label.draw(at: NSPoint(x: x + 14, y: top - imageHeight - 29), withAttributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .regular),
        .foregroundColor: NSColor.white,
    ])
}
NSGraphicsContext.restoreGraphicsState()
guard let data = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Contact sheet encoding failed")
}
try data.write(to: root.appendingPathComponent("out/18-annotated-paper-contact-sheet.png"))
print("Extracted 24 full-resolution QA frames, poster, and labelled contact sheet.")
