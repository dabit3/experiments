import AppKit
import Foundation

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .none
let ink = NSColor.black
let blue = NSColor(calibratedRed: 0.13, green: 0.22, blue: 0.93, alpha: 1)
let yellow = NSColor(calibratedRed: 0.97, green: 0.85, blue: 0.47, alpha: 1)
let peach = NSColor(calibratedRed: 0.99, green: 0.88, blue: 0.66, alpha: 1)
let red = NSColor(calibratedRed: 0.97, green: 0.22, blue: 0, alpha: 1)
let white = NSColor(calibratedRed: 0.99, green: 0.99, blue: 0.99, alpha: 1)
let navy = NSColor(calibratedRed: 0, green: 0, blue: 0.66, alpha: 1)

// 32 x 32 pixel canvas, each cell 32 pt.
let grid = 32.0
let px = 1024 / grid

func plot(_ x: Int, _ y: Int, _ color: NSColor) {
  color.setFill()
  CGRect(x: Double(x) * px, y: 1024 - Double(y + 1) * px, width: px, height: px).fill()
}

func rows(_ rows: [String], at origin: (Int, Int), color: NSColor, on: Character = "1") {
  for (y, row) in rows.enumerated() {
    for (x, bit) in row.enumerated() where bit == on {
      plot(origin.0 + x, origin.1 + y, color)
    }
  }
}

ink.setFill()
CGRect(origin: .zero, size: size).fill()

// Maze wall frame: hollow blue corridors.
let walls: [String] = [
  "11111111111111111111111111111111",
  "10000000000000000000000000000001",
  "10111111111111111111111111111101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10100000000000000000000000000101",
  "10111111111111111111111111111101",
  "10000000000000000000000000000001",
  "11111111111111111111111111111111",
]
rows(walls, at: (0, 0), color: blue)

// Dots along the corridor.
for x in stride(from: 5, through: 26, by: 3) {
  plot(x, 5, peach)
  plot(x, 26, peach)
}
for y in stride(from: 8, through: 23, by: 3) {
  plot(3, y, peach)
  plot(28, y, peach)
}

// Comet (13 x 13 sprite) facing right, mouth open.
let comet: [String] = [
  "0000111110000",
  "0011111111100",
  "0111111111110",
  "0111111111000",
  "1111111110000",
  "1111111100000",
  "1111111000000",
  "1111111100000",
  "1111111110000",
  "0111111111000",
  "0111111111110",
  "0011111111100",
  "0000111110000",
]
rows(comet, at: (4, 10), color: yellow)

// Spirit (13 x 13 sprite) with eyes looking left.
let spirit: [String] = [
  "0000111110000",
  "0011111111100",
  "0111111111110",
  "0122111221110",
  "1123111231111",
  "1123111231111",
  "1122111221111",
  "1111111111111",
  "1111111111111",
  "1111111111111",
  "1111111111111",
  "1101111011011",
  "1000110001001",
]
rows(spirit, at: (16, 10), color: red)
rows(spirit, at: (16, 10), color: white, on: "2")
rows(spirit, at: (16, 10), color: navy, on: "3")

image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
let data = bitmap.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
