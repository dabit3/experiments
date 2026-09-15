import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("out")
let video = output.appendingPathComponent("01-keynote-minimal.mp4")
let samples: [(Int, String)] = [
    (0, "Opening frame"), (60, "Hook / poster"),
    (164, "Hook → context"), (204, "Context"),
    (284, "Context → build"), (300, "Build / title"),
    (330, "Build / reveal midpoint"), (396, "Build / silent hold"),
    (464, "Build → interaction"), (480, "Interaction / title"),
    (510, "Interaction / reveal midpoint"), (570, "Interaction / silent hold"),
    (644, "Interaction → fix"), (660, "Fix / title"),
    (690, "Fix / reveal midpoint"), (750, "Fix / silent hold"),
    (824, "Fix → evidence"), (840, "Evidence / title"),
    (870, "Evidence / reveal midpoint"), (930, "Evidence / actual web QA"),
    (1004, "Evidence → outcome"), (1035, "Outcome / app"),
    (1094, "Outcome / price crossfade"), (1134, "Outcome / price"),
    (1184, "Outcome → end"), (1206, "End card"),
    (1260, "End card / hold"), (1319, "Final frame"),
]

func extract(frame: Int, destination: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
        "-ss", String(Double(frame) / 30), "-i", video.path,
        "-frames:v", "1", destination.path,
    ]
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw NSError(domain: "Frame extraction", code: Int(process.terminationStatus))
    }
}

func text(_ string: String, x: CGFloat, y: CGFloat, size: CGFloat, color: NSColor) {
    (string as NSString).draw(
        at: NSPoint(x: x, y: y),
        withAttributes: [
            .font: NSFont.systemFont(ofSize: size, weight: .medium),
            .foregroundColor: color,
        ]
    )
}

let margin: CGFloat = 24
let columns = 4
let cellWidth: CGFloat = 480
let cellHeight: CGFloat = 312
let header: CGFloat = 106
let width = margin + CGFloat(columns) * (cellWidth + margin)
let rows = (samples.count + columns - 1) / columns
let height = header + CGFloat(rows) * (cellHeight + margin) + margin
let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(width), pixelsHigh: Int(height),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(calibratedWhite: 0.93, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
text("KEYNOTE MINIMAL", x: margin, y: height - 47, size: 30, color: .black)
text(
    "44 seconds  ·  1920 × 1080  ·  30 fps  /  Scene holds + transition samples from the final MP4",
    x: margin, y: height - 80, size: 18, color: .darkGray
)

for (index, sample) in samples.enumerated() {
    let path = output.appendingPathComponent("keynote-frame-\(sample.0).png")
    try extract(frame: sample.0, destination: path)
    guard let image = NSImage(contentsOf: path) else {
        fatalError("Cannot decode frame \(sample.0)")
    }
    let x = margin + CGFloat(index % columns) * (cellWidth + margin)
    let y = height - header - CGFloat(index / columns + 1) * (cellHeight + margin)
    NSColor.white.setFill()
    NSRect(x: x, y: y, width: cellWidth, height: cellHeight).fill()
    image.draw(in: NSRect(x: x, y: y + 42, width: cellWidth, height: 270))
    let timestamp = String(format: "%05.2fs", Double(sample.0) / 30)
    text("\(timestamp)  \(sample.1)", x: x + 12, y: y + 13, size: 16, color: .darkGray)
}
NSGraphicsContext.restoreGraphicsState()
let destination = output.appendingPathComponent("01-keynote-minimal-contact-sheet.png")
try bitmap.representation(using: .png, properties: [:])!.write(to: destination)
print(destination.path)
