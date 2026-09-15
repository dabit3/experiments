import AppKit
import Foundation

struct Sample: Decodable {
    let label: String
    let path: String
}

let samples = try JSONDecoder().decode(
    [Sample].self,
    from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
)
let columns = 4
let width = 480
let imageHeight = 270
let labelHeight = 38
let gap = 12
let rows = (samples.count + columns - 1) / columns
let canvasWidth = columns * width + (columns + 1) * gap
let canvasHeight = rows * (imageHeight + labelHeight + gap) + gap
let canvas = NSImage(size: NSSize(width: canvasWidth, height: canvasHeight))
canvas.lockFocus()
NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight).fill()
for (index, sample) in samples.enumerated() {
    guard let image = NSImage(contentsOfFile: sample.path) else {
        fatalError("Missing frame \(sample.path)")
    }
    let x = gap + (index % columns) * (width + gap)
    let y = canvasHeight - gap - (index / columns + 1) * (imageHeight + labelHeight + gap) + gap
    image.draw(in: NSRect(x: x, y: y + labelHeight, width: width, height: imageHeight))
    let label = NSMutableAttributedString(string: sample.label)
    let range = NSRange(location: 0, length: label.length)
    label.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 15, weight: .medium), range: range)
    label.addAttribute(.foregroundColor, value: NSColor.white, range: range)
    label.draw(in: NSRect(x: x + 9, y: y + 8, width: width - 18, height: 23))
}
canvas.unlockFocus()
guard let tiff = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not create contact sheet")
}
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
print("Contact sheet: \(canvasWidth) × \(canvasHeight)")
