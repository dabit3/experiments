import AppKit
import Foundation

// Renders the app icon as a 16x16 pixel-art sprite: Clover the rabbit in her red kart on a
// checkered lawn under a banded console sky.
let destination = CommandLine.arguments[1]
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let palette: [Character: NSColor] = [
  "C": NSColor(srgbRed: 0.16, green: 0.42, blue: 0.93, alpha: 1),
  "c": NSColor(srgbRed: 0.36, green: 0.72, blue: 0.98, alpha: 1),
  "y": NSColor(srgbRed: 0.98, green: 0.85, blue: 0.13, alpha: 1),
  "w": NSColor(srgbRed: 0.99, green: 0.98, blue: 0.94, alpha: 1),
  "k": NSColor(srgbRed: 0.08, green: 0.07, blue: 0.12, alpha: 1),
  "r": NSColor(srgbRed: 0.91, green: 0.15, blue: 0.16, alpha: 1),
  "p": NSColor(srgbRed: 1, green: 0.62, blue: 0.72, alpha: 1),
  "g": NSColor(srgbRed: 0.36, green: 0.78, blue: 0.22, alpha: 1),
  "G": NSColor(srgbRed: 0.24, green: 0.62, blue: 0.18, alpha: 1),
]

let rows = [
  "CCCCCCCCCCCCCCCC",
  "CCCCCCCCCCCCyyCC",
  "ccccccccccccyycc",
  "cccccccccccccccc",
  "ccwwwccccccccccc",
  "cwwwwwcccccccccc",
  "cccccccccccwwwcc",
  "ccccccwwccwwcccc",
  "ccccccwpccpwcccc",
  "cccccckwwwwkcccc",
  "ccccckwkwwkwkccc",
  "ccccckwwwwwwkccc",
  "ccccckrrrrrrkccc",
  "gggkkrrrrrrrrkkg",
  "gkkkkrrrrrrkkkkg",
  "GkkkkGgGgGgkkkkG",
]

let cell = size.width / CGFloat(rows[0].count)
for (y, row) in rows.enumerated() {
  for (x, character) in row.enumerated() {
    guard let color = palette[character] else { continue }
    color.setFill()
    let rect = NSRect(
      x: CGFloat(x) * cell, y: size.height - CGFloat(y + 1) * cell, width: cell, height: cell)
    NSBezierPath(rect: rect).fill()
  }
}

image.unlockFocus()
guard let tiff = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else {
  fatalError("Could not render app icon")
}
try png.write(to: URL(fileURLWithPath: destination))
