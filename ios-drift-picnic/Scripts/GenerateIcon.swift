import AppKit
import Foundation

let destination = CommandLine.arguments[1]
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let green = NSColor(srgbRed: 0.09, green: 0.28, blue: 0.22, alpha: 1)
let cream = NSColor(srgbRed: 1, green: 0.97, blue: 0.85, alpha: 1)
let butter = NSColor(srgbRed: 1, green: 0.88, blue: 0.52, alpha: 1)
let pink = NSColor(srgbRed: 0.92, green: 0.28, blue: 0.36, alpha: 1)
func rounded(_ rect: NSRect, _ radius: CGFloat, _ color: NSColor) {
  color.setFill()
  NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
func oval(_ rect: NSRect, _ color: NSColor) {
  color.setFill()
  NSBezierPath(ovalIn: rect).fill()
}
rounded(NSRect(origin: .zero, size: size), 0, green)
oval(
  NSRect(x: 70, y: 60, width: 884, height: 884),
  NSColor(srgbRed: 0.16, green: 0.37, blue: 0.28, alpha: 1))
for x in 0..<9 {
  for y in 0..<3 {
    rounded(
      NSRect(x: x * 130 - 70, y: y * 100 - 35, width: 130, height: 100), 0,
      (x + y) % 2 == 0 ? cream.withAlphaComponent(0.10) : cream.withAlphaComponent(0.03))
  }
}
oval(NSRect(x: 209, y: 150, width: 610, height: 145), NSColor.black.withAlphaComponent(0.22))
rounded(NSRect(x: 209, y: 200, width: 132, height: 198), 52, NSColor(white: 0.12, alpha: 1))
rounded(NSRect(x: 685, y: 200, width: 132, height: 198), 52, NSColor(white: 0.12, alpha: 1))
rounded(NSRect(x: 267, y: 268, width: 490, height: 172), 65, butter)
rounded(NSRect(x: 250, y: 211, width: 524, height: 77), 33, cream)
rounded(NSRect(x: 287, y: 307, width: 450, height: 150), 57, butter)
rounded(NSRect(x: 469, y: 289, width: 86, height: 140), 12, cream)
oval(NSRect(x: 355, y: 392, width: 320, height: 313), cream)
rounded(NSRect(x: 373, y: 642, width: 106, height: 242), 53, cream)
rounded(NSRect(x: 548, y: 642, width: 106, height: 242), 53, cream)
rounded(NSRect(x: 403, y: 690, width: 45, height: 157), 22, pink.withAlphaComponent(0.5))
rounded(NSRect(x: 580, y: 690, width: 45, height: 157), 22, pink.withAlphaComponent(0.5))
oval(NSRect(x: 428, y: 547, width: 27, height: 35), green)
oval(NSRect(x: 575, y: 547, width: 27, height: 35), green)
oval(NSRect(x: 494, y: 508, width: 39, height: 23), pink)
oval(NSRect(x: 389, y: 493, width: 57, height: 30), pink.withAlphaComponent(0.35))
oval(NSRect(x: 582, y: 493, width: 57, height: 30), pink.withAlphaComponent(0.35))
rounded(NSRect(x: 394, y: 392, width: 246, height: 49), 24, green)
oval(NSRect(x: 700, y: 735, width: 125, height: 125), butter)
image.unlockFocus()
guard let tiff = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else {
  fatalError("Could not render app icon")
}
try png.write(to: URL(fileURLWithPath: destination))
