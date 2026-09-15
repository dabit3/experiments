import AppKit
import Foundation

struct Scene: Decodable {
    let id: String
    let from: Int
    let duration: Int
}

let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let out = root.appendingPathComponent("out")
let video = out.appendingPathComponent("06-kinetic-type.mp4")

func run(_ command: [String]) throws -> Data {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = command
    process.currentDirectoryURL = root
    process.standardOutput = pipe
    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw NSError(domain: "ContactSheet", code: Int(process.terminationStatus))
    }
    return data
}

let data = try run([
    "node", "--experimental-strip-types", "--input-type=module", "-e",
    "import {timeline} from './templates/06-kinetic-type/config.ts'; console.log(JSON.stringify(timeline));"
])
let scenes = try JSONDecoder().decode([Scene].self, from: data)
let cols = 4
let tileWidth = 480
let tileHeight = 310

func sheet(_ name: String, _ moments: [(Int, String)]) throws {
    let height = ((moments.count + cols - 1) / cols) * tileHeight
    let canvas = NSImage(size: NSSize(width: cols * tileWidth, height: height))
    canvas.lockFocus()
    NSColor(calibratedWhite: 0.10, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: cols * tileWidth, height: height).fill()
    for (index, moment) in moments.enumerated() {
        let frame = out.appendingPathComponent("qa-\(moment.0).png")
        _ = try run([
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-ss", String(Double(moment.0) / 30),
            "-i", video.path, "-frames:v", "1", frame.path
        ])
        guard let image = NSImage(contentsOf: frame) else {
            throw NSError(domain: "ContactSheet", code: 1)
        }
        let x = (index % cols) * tileWidth
        let y = height - (index / cols + 1) * tileHeight
        image.draw(in: NSRect(x: x, y: y + 40, width: 480, height: 270))
        let label = String(format: "%05.2fs  f%04d  %@", Double(moment.0) / 30, moment.0, moment.1)
        (label as NSString).draw(at: NSPoint(x: x + 12, y: y + 13), withAttributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ])
    }
    canvas.unlockFocus()
    guard let tiff = canvas.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ContactSheet", code: 2)
    }
    try png.write(to: out.appendingPathComponent(name))
    print("\(name): \(moments.count) full-frame samples")
}

let keyCuts = [0, 74, 75, 419, 420, 824, 825, 1124, 1125, 1199]
let holds = scenes.map { ($0.from + min(30, $0.duration / 2), $0.id) }
try sheet("06-kinetic-type-contact-sheet.png",
          holds + keyCuts.map { ($0, "key cut / boundary") })

let transitionFrames = scenes.dropFirst().flatMap { scene in
    [(scene.from - 1, "\(scene.id) / before"),
     (scene.from, "\(scene.id) / cut"),
     (scene.from + 8, "\(scene.id) / entrance")]
}
try sheet("06-kinetic-type-transitions-a.png", Array(transitionFrames.prefix(27)))
try sheet("06-kinetic-type-transitions-b.png", Array(transitionFrames.dropFirst(27)))
