import AppKit
import Foundation

// 32×32 pixel-art icon rendered at 1024: an overworld tile with a river, a red rail and a locomotive.
let cell = 32.0
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

func rgb(_ r: Double, _ g: Double, _ b: Double) -> NSColor {
  NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
}
let outline = rgb(0.06, 0.05, 0.12)
let grass = rgb(0.55, 0.82, 0.40)
let grassDeep = rgb(0.45, 0.72, 0.32)
let sand = rgb(0.93, 0.84, 0.62)
let water = rgb(0.24, 0.72, 0.98)
let waterDeep = rgb(0.10, 0.45, 0.85)
let white = rgb(0.98, 0.98, 0.96)
let red = rgb(0.94, 0.20, 0.16)
let sun = rgb(0.99, 0.86, 0.16)
let leaf = rgb(0.16, 0.52, 0.24)

/// Pixel coordinates use a top-left origin like the app's Canvas code.
func px(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: NSColor) {
  color.setFill()
  NSBezierPath(
    rect: NSRect(
      x: Double(x) * cell, y: 1024 - Double(y + h) * cell, width: Double(w) * cell,
      height: Double(h) * cell)
  ).fill()
}

px(0, 0, 32, 32, grass)
for x in 0..<8 {
  for y in 0..<8 where (x + y) % 2 == 0 {
    px(x * 4, y * 4, 4, 4, grassDeep)
  }
}
// River flowing diagonally from top-right to bottom-left with sandy banks.
let river: [(Int, Int)] = (0..<32).map { y in (22 - y * 14 / 31, y) }
for (x, y) in river { px(x - 3, y, 12, 1, sand) }
for (x, y) in river { px(x - 2, y, 10, 1, outline) }
for (x, y) in river { px(x - 1, y, 8, 1, water) }
for (x, y) in river { px(x + 2, y, 3, 1, waterDeep) }
for (x, y) in river where y % 4 == 1 { px(x, y, 2, 1, white) }
for (x, y) in river where y % 4 == 3 { px(x + 4, y, 2, 1, white) }
// Trees.
for (tx, ty) in [(4, 4), (26, 24), (5, 25)] {
  px(tx - 1, ty + 1, 4, 3, outline)
  px(tx, ty + 3, 2, 2, outline)
  px(tx - 1, ty, 4, 3, leaf)
  px(tx, ty - 1, 2, 1, leaf)
}
// Red rail: horizontal run with a tunnel under the river.
px(2, 15, 28, 5, outline)
px(3, 16, 26, 3, red)
for x in stride(from: 4, to: 28, by: 4) { px(x, 17, 2, 1, white) }
// Stations at both ends.
px(3, 12, 8, 8, outline)
px(4, 13, 6, 6, white)
px(22, 13, 7, 7, outline)
px(23, 14, 5, 5, white)
px(24, 15, 3, 3, outline)
// Locomotive riding the rail.
px(11, 9, 12, 6, outline)
px(12, 10, 10, 4, red)
px(20, 8, 3, 3, outline)
px(21, 9, 1, 1, sun)
px(13, 11, 2, 2, white)
px(16, 11, 2, 2, white)
px(12, 15, 3, 2, outline)
px(19, 15, 3, 2, outline)
px(13, 15, 1, 1, rgb(0.62, 0.66, 0.74))
px(20, 15, 1, 1, rgb(0.62, 0.66, 0.74))
// Smoke puffs.
px(8, 6, 2, 2, white)
px(5, 4, 2, 2, white)

image.unlockFocus()
guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else { fatalError("Could not encode icon") }
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
try png.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
