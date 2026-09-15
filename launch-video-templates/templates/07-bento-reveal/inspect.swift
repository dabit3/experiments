import AppKit
import Foundation

let samples: [(Int, String)] = [
    (0, "Hook / first frame"),
    (30, "Center-to-grid stagger"),
    (90, "Hook / complete grid"),
    (180, "Context / manual QA and CI"),
    (258, "01 / expanding"),
    (330, "01 / build and run"),
    (402, "01 / collapsing"),
    (420, "Grid / spatial continuity"),
    (438, "02 / expanding"),
    (480, "02 / tap"),
    (528, "02 / type"),
    (582, "02 / scroll"),
    (612, "02 / collapsing"),
    (648, "03 / expanding"),
    (696, "03 / reproduce, fix, retest"),
    (798, "03 / collapsing"),
    (834, "04 / expanding"),
    (900, "04 / actual web QA recording"),
    (972, "04 / recording progresses"),
    (1008, "04 / collapsing"),
    (1080, "Outcome / complete grid"),
    (1182, "Logo / transition"),
    (1260, "Logo / end card"),
    (1319, "Logo / final frame"),
]

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let out = root.appendingPathComponent("out")
let input = out.appendingPathComponent("07-bento-reveal.mp4")
let frames = out.appendingPathComponent("07-bento-reveal-frames")
try FileManager.default.createDirectory(at: frames, withIntermediateDirectories: true)

func extract(_ frame: Int, _ destination: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-ss", String(Double(frame) / 30), "-i", input.path,
        "-frames:v", "1", destination.path,
    ]
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw NSError(domain: "BentoQA.ffmpeg", code: Int(process.terminationStatus))
    }
}

let width = 2044
let height = 2044
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: width * 4, bitsPerPixel: 32
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Cannot allocate contact-sheet bitmap")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high
NSColor(calibratedWhite: 0.93, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

let headingAttributes: [NSAttributedString.Key: NSObject] = [
    .font: NSFont.systemFont(ofSize: 25, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.08, alpha: 1),
]
let labelAttributes: [NSAttributedString.Key: NSObject] = [
    .font: NSFont.monospacedSystemFont(ofSize: 15, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.16, alpha: 1),
]
("07 / BENTO REVEAL     44s · 1920 × 1080 · 30 fps" as NSString).draw(
    at: NSPoint(x: 32, y: height - 63), withAttributes: headingAttributes
)

for (index, sample) in samples.enumerated() {
    let destination = frames.appendingPathComponent(String(format: "frame-%04d.png", sample.0))
    try extract(sample.0, destination)
    guard let image = NSImage(contentsOf: destination) else {
        fatalError("Cannot read frame \(sample.0)")
    }
    let x = 32 + (index % 4) * 500
    let top = 96 + (index / 4) * 322
    image.draw(
        in: NSRect(x: x, y: height - top - 270, width: 480, height: 270),
        from: .zero, operation: .sourceOver, fraction: 1
    )
    let label = String(format: "%05.2fs  ", Double(sample.0) / 30) + sample.1
    (label as NSString).draw(
        at: NSPoint(x: x, y: height - top - 297), withAttributes: labelAttributes
    )
}
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Cannot encode contact sheet")
}
try png.write(to: out.appendingPathComponent("07-bento-reveal-contact-sheet.png"))
try extract(1080, out.appendingPathComponent("07-bento-reveal-poster.png"))
print("Extracted 24 full frames, full-frame poster and labeled contact sheet.")
