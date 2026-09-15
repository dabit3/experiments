import AppKit
import Foundation

struct Sample {
    let frame: Int
    let label: String
}

let samples = [
    Sample(frame: 75, label: "Hook"),
    Sample(frame: 225, label: "Context"),
    Sample(frame: 375, label: "Build / run"),
    Sample(frame: 525, label: "Interact"),
    Sample(frame: 675, label: "Reproduce / fix / retest"),
    Sample(frame: 840, label: "Review / actual web QA insert"),
    Sample(frame: 1020, label: "Outcome"),
    Sample(frame: 1200, label: "Logo end card"),
    Sample(frame: 149, label: "Hook → context / before"),
    Sample(frame: 162, label: "Hook → context / entrance"),
    Sample(frame: 299, label: "Context → build / before"),
    Sample(frame: 312, label: "Context → build / entrance"),
    Sample(frame: 449, label: "Build → interact / before"),
    Sample(frame: 462, label: "Build → interact / entrance"),
    Sample(frame: 599, label: "Interact → iterate / before"),
    Sample(frame: 612, label: "Interact → iterate / entrance"),
    Sample(frame: 749, label: "Iterate → review / before"),
    Sample(frame: 762, label: "Iterate → review / entrance"),
    Sample(frame: 929, label: "Review → outcome / before"),
    Sample(frame: 942, label: "Review → outcome / entrance"),
    Sample(frame: 1109, label: "Outcome → logo / before"),
    Sample(frame: 1122, label: "Outcome → logo / entrance"),
    Sample(frame: 0, label: "First delivered frame"),
    Sample(frame: 1259, label: "Last delivered frame"),
]

guard CommandLine.arguments.count == 2 else {
    fatalError("Usage: swift templates/12-metrics-story/make-contact-sheet.swift out")
}
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let video = output.appendingPathComponent("12-metrics-story.mp4")
guard FileManager.default.fileExists(atPath: video.path) else {
    fatalError("Render the MP4 before making the contact sheet.")
}
let sortedFrames = samples.map(\.frame).sorted()
let filter = sortedFrames.map { "eq(n\\,\($0))" }.joined(separator: "+")
let extract = Process()
extract.executableURL = URL(fileURLWithPath: "/usr/bin/env")
extract.arguments = [
    "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
    "-i", video.path, "-vf", "select=\(filter)", "-fps_mode", "vfr",
    output.appendingPathComponent("12-qa-frame-%02d.png").path,
]
try extract.run()
extract.waitUntilExit()
guard extract.terminationStatus == 0 else { fatalError("Frame extraction failed.") }

let width = 1972
let height = 1996
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Cannot create contact-sheet bitmap.")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high
NSColor(calibratedWhite: 0.95, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

func text(_ value: String, x: CGFloat, y: CGFloat, size: CGFloat) {
    let attributes: [NSAttributedString.Key: NSObject] = [
        .font: NSFont.systemFont(ofSize: size, weight: .medium),
        .foregroundColor: NSColor(calibratedWhite: 0.12, alpha: 1),
    ]
    (value as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
}
text("METRICS STORY / 42s / 1920 × 1080 / 30 fps", x: 18, y: 1950, size: 25)
text("Scene holds · both sides of every cut · opening and final frames", x: 18, y: 1919, size: 18)
for (index, sample) in samples.enumerated() {
    guard let frameIndex = sortedFrames.firstIndex(of: sample.frame) else {
        fatalError("Missing sample index.")
    }
    let filename = String(format: "12-qa-frame-%02d.png", frameIndex + 1)
    guard let image = NSImage(contentsOf: output.appendingPathComponent(filename)) else {
        fatalError("Missing extracted frame: \(filename)")
    }
    let x = CGFloat(14 + (index % 4) * 488)
    let y = CGFloat(1900 - (index / 4) * 314 - 270)
    image.draw(in: NSRect(x: x, y: y, width: 480, height: 270))
    let label = String(format: "%05.2fs  %@", Double(sample.frame) / 30, sample.label)
    text(label, x: x + 2, y: y - 28, size: 16)
}
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Cannot encode PNG.")
}
let sheet = output.appendingPathComponent("12-metrics-story-contact-sheet.png")
try png.write(to: sheet)
print(sheet.path)
