import AppKit
import Foundation

// Renders the 1024pt app icon as a 16x16 pixel moth on a navy stage, matching the
// in-app 8-bit palette. Usage: swift Scripts/make-icon.swift <output.png>

let size = 1024
let grid = 16
let cell = CGFloat(size) / CGFloat(grid)
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
NSGraphicsContext.current?.shouldAntialias = false

let palette: [Character: NSColor] = [
  "n": NSColor(red: 0.0, green: 0.12, blue: 0.42, alpha: 1),
  "k": NSColor(red: 0.04, green: 0.05, blue: 0.16, alpha: 1),
  "p": NSColor(red: 0.36, green: 0.13, blue: 0.55, alpha: 1),
  "v": NSColor(red: 0.58, green: 0.27, blue: 0.99, alpha: 1),
  "g": NSColor(red: 0.30, green: 0.86, blue: 0.28, alpha: 1),
  "y": NSColor(red: 0.97, green: 0.72, blue: 0.0, alpha: 1),
  "w": NSColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1),
  "r": NSColor(red: 0.85, green: 0.16, blue: 0.0, alpha: 1),
  "m": NSColor(red: 0.53, green: 0.08, blue: 0.0, alpha: 1),
  "b": NSColor(red: 0.63, green: 0.31, blue: 0.08, alpha: 1),
]

let rows = [
  "yyyyyyyyyyyyyyyy",
  "rmnnnnnnnnnnnnmr",
  "rmn..........nmr",
  "rmn.v..gg..v.nmr",
  "rmn.vv.gg.vv.nmr",
  "rmn.vvvvgvvvvnmr",
  "rmn.vvvyggyvvnmr",
  "rmn.vvvvggvvvvmr",
  "rmn..ppvggvpp.mr",
  "rmn..ppvggvpp.mr",
  "rmn...pvggvp..mr",
  "rmn....vggv...mr",
  "rmn.....gg....mr",
  "rmnnnnnnnnnnnnmr",
  "bbbbbbbbbbbbbbbb",
  "bkbkbkbkbkbkbkbk",
]

for (rowIndex, row) in rows.enumerated() {
  for (columnIndex, character) in row.enumerated() {
    let color = palette[character] ?? palette["k"]!
    color.setFill()
    let rect = NSRect(
      x: CGFloat(columnIndex) * cell, y: CGFloat(grid - 1 - rowIndex) * cell, width: cell,
      height: cell)
    NSBezierPath(rect: rect).fill()
  }
}

// Star field inside the stage window.
NSColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1).setFill()
for (x, y) in [(4, 2), (10, 2), (12, 3), (3, 7), (13, 9), (5, 11), (11, 12)] {
  let rect = NSRect(
    x: CGFloat(x) * cell + cell * 0.375, y: CGFloat(grid - 1 - y) * cell + cell * 0.375,
    width: cell * 0.25, height: cell * 0.25)
  NSBezierPath(rect: rect).fill()
}

image.unlockFocus()
guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else {
  fatalError("Could not encode icon")
}
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
try png.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
