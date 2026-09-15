import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 34,
      let image = NSImage(contentsOfFile: arguments[1]),
      let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: 2590,
        pixelsHigh: 3222,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
      ),
      let context = NSGraphicsContext(bitmapImageRep: bitmap)
else {
  fatalError("Expected a 4 × 8 contact sheet and 32 frame numbers")
}

let attributes: [NSAttributedString.Key: NSObject] = [
  .font: NSFont.monospacedDigitSystemFont(ofSize: 19, weight: .medium),
  .foregroundColor: NSColor.white,
]
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
image.draw(in: NSRect(x: 0, y: 0, width: 2590, height: 3222))
for (index, argument) in arguments.dropFirst(2).enumerated() {
  guard let frame = Int(argument) else { fatalError("Invalid frame") }
  let seconds = Double(frame) / 30.0
  let label = String(format: "%05.2f s  /  frame %04d", seconds, frame)
  let x = 6 + (index % 4) * 646 + 16
  let y = 3222 - (6 + (index / 4) * 402 + 360 + 27)
  NSAttributedString(string: label, attributes: attributes)
    .draw(at: NSPoint(x: x, y: y))
}
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else {
  fatalError("Could not encode labeled contact sheet")
}
try png.write(to: URL(fileURLWithPath: arguments[1]))
