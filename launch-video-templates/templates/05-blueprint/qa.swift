import AppKit
import Foundation

struct MediaStream: Decodable {
    let codec_name: String
    let codec_type: String
    let width: Int?
    let height: Int?
    let pix_fmt: String?
    let r_frame_rate: String
    let nb_frames: String?
}

struct MediaFormat: Decodable {
    let duration: String
}

struct MediaProbe: Decodable {
    let streams: [MediaStream]
    let format: MediaFormat
}

struct Sample {
    let frame: Int
    let title: String
}

@discardableResult
func run(_ tool: String, _ arguments: [String]) throws -> Data {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [tool] + arguments
    let pipe = Pipe()
    process.standardOutput = pipe
    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw NSError(domain: "BlueprintQA", code: Int(process.terminationStatus),
                      userInfo: [NSLocalizedDescriptionKey: "\(tool) failed"])
    }
    return data
}

let root = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let output = root.appendingPathComponent("out")
let qa = output.appendingPathComponent("05-blueprint-qa")
let video = output.appendingPathComponent("05-blueprint.mp4")
try FileManager.default.createDirectory(at: qa, withIntermediateDirectories: true)

let probeData = try run("ffprobe", [
    "-v", "error", "-show_entries",
    "stream=codec_name,codec_type,width,height,pix_fmt,r_frame_rate,nb_frames:format=duration",
    "-of", "json", video.path
])
let probe = try JSONDecoder().decode(MediaProbe.self, from: probeData)
guard let stream = probe.streams.first(where: {$0.codec_type == "video"}),
      stream.codec_name == "h264", stream.width == 1920, stream.height == 1080,
      stream.r_frame_rate == "30/1", stream.nb_frames == "1320",
      stream.pix_fmt == "yuv420p", probe.streams.count == 1,
      let duration = Double(probe.format.duration), abs(duration - 44) < 0.001 else {
    fatalError("Unexpected media specification: \(String(decoding: probeData, as: UTF8.self))")
}
try probeData.write(to: qa.appendingPathComponent("ffprobe.json"))

let samples: [Sample] = [
    .init(frame: 72, title: "HOOK / Native workspace"),
    .init(frame: 210, title: "CONTEXT / Prior feedback path"),
    .init(frame: 366, title: "FEATURE 01 / Build + run"),
    .init(frame: 558, title: "FEATURE 02 / Simulator input"),
    .init(frame: 738, title: "FEATURE 03 / Reproduce + repair"),
    .init(frame: 894, title: "FEATURE 04 / Actual web QA clip"),
    .init(frame: 1074, title: "OUTCOME / Working app"),
    .init(frame: 1245, title: "END CARD / Supplied Devin logo"),
    .init(frame: 0, title: "First frame / Headline stays visible"),
    .init(frame: 12, title: "Hook / Construction-line completion"),
    .init(frame: 149, title: "Cut 01 / Before"),
    .init(frame: 150, title: "Cut 01 / Context begins"),
    .init(frame: 162, title: "Context / Entrance"),
    .init(frame: 269, title: "Cut 02 / Before"),
    .init(frame: 270, title: "Cut 02 / Build begins"),
    .init(frame: 282, title: "Build / Entrance"),
    .init(frame: 449, title: "Cut 03 / Before"),
    .init(frame: 450, title: "Cut 03 / Interact begins"),
    .init(frame: 462, title: "Interact / Entrance"),
    .init(frame: 629, title: "Cut 04 / Before"),
    .init(frame: 630, title: "Cut 04 / Repair begins"),
    .init(frame: 642, title: "Repair / Entrance"),
    .init(frame: 809, title: "Cut 05 / Before"),
    .init(frame: 810, title: "Cut 05 / Real recording begins"),
    .init(frame: 822, title: "Evidence / Frame assembled"),
    .init(frame: 989, title: "Cut 06 / Before"),
    .init(frame: 990, title: "Cut 06 / Outcome begins"),
    .init(frame: 1002, title: "Outcome / Entrance"),
    .init(frame: 1169, title: "Cut 07 / Before"),
    .init(frame: 1170, title: "Cut 07 / Logo begins"),
    .init(frame: 1182, title: "Logo / Entrance"),
    .init(frame: 1319, title: "Final frame / Clean hold"),
    .init(frame: 294, title: "Build / Plane assembly starts"),
    .init(frame: 314, title: "Build / Assembly midpoint"),
    .init(frame: 835, title: "Source insert / Dialog"),
    .init(frame: 975, title: "Source insert / Queue"),
]

let tileWidth = 640
let tileHeight = 404
let columns = 4
let rows = (samples.count + columns - 1) / columns
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: columns * tileWidth, pixelsHigh: rows * tileHeight,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Cannot allocate contact sheet")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high
NSColor(calibratedRed: 0.027, green: 0.11, blue: 0.17, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: columns * tileWidth, height: rows * tileHeight).fill()

for (index, sample) in samples.enumerated() {
    let file = qa.appendingPathComponent("frame-\(sample.frame).png")
    try run("ffmpeg", [
        "-y", "-hide_banner", "-loglevel", "error", "-i", video.path,
        "-vf", "select=eq(n\\,\(sample.frame))", "-frames:v", "1", "-update", "1", file.path
    ])
    guard let image = NSImage(contentsOf: file) else {fatalError("Missing frame \(sample.frame)")}
    let x = (index % columns) * tileWidth
    let y = (rows - index / columns - 1) * tileHeight
    image.draw(in: NSRect(x: x, y: y + 44, width: tileWidth, height: 360))
    let timestamp = String(format: "%.3fs", Double(sample.frame) / 30)
    let caption = "\(timestamp)  |  \(sample.title)"
    let attributes: [NSAttributedString.Key: NSObject] = [
        .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .medium),
        .foregroundColor: NSColor(calibratedRed: 0.7, green: 0.91, blue: 0.94, alpha: 1)
    ]
    NSAttributedString(string: caption, attributes: attributes)
        .draw(at: NSPoint(x: x + 14, y: y + 15))
}
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Cannot encode contact sheet")
}
try png.write(to: output.appendingPathComponent("05-blueprint-contact-sheet.png"))
try run("ffmpeg", [
    "-y", "-hide_banner", "-loglevel", "error", "-i", video.path,
    "-vf", "select=eq(n\\,72)", "-frames:v", "1", "-update", "1",
    output.appendingPathComponent("05-blueprint-poster.png").path
])
print("PASS: H.264 / yuv420p / 1920x1080 / 30 fps / 1320 frames / 44 s / no audio")
print("Exported full-frame poster and labeled \(samples.count)-frame contact sheet.")
