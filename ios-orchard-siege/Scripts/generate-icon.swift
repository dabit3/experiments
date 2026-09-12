import AppKit

let destination = CommandLine.arguments[1]
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let canvas = NSRect(origin: .zero, size: size)
NSGradient(
  starting: NSColor(red: 0.20, green: 0.35, blue: 0.23, alpha: 1),
  ending: NSColor(red: 0.47, green: 0.57, blue: 0.31, alpha: 1))!.draw(in: canvas, angle: 90)
NSColor(red: 1, green: 0.87, blue: 0.58, alpha: 0.15).setFill()
NSBezierPath(ovalIn: NSRect(x: 77, y: 73, width: 870, height: 870)).fill()
NSColor(red: 0.94, green: 0.82, blue: 0.55, alpha: 0.35).setStroke()
let border = NSBezierPath(
  roundedRect: NSRect(x: 56, y: 56, width: 912, height: 912),
  xRadius: 182, yRadius: 182)
border.lineWidth = 3
border.stroke()
let stem = NSBezierPath()
stem.move(to: NSPoint(x: 517, y: 723))
stem.curve(
  to: NSPoint(x: 551, y: 866), controlPoint1: NSPoint(x: 515, y: 800),
  controlPoint2: NSPoint(x: 524, y: 833))
stem.lineWidth = 31
stem.lineCapStyle = .round
NSColor(red: 0.34, green: 0.23, blue: 0.16, alpha: 1).setStroke()
stem.stroke()
let leaf = NSBezierPath()
leaf.move(to: NSPoint(x: 535, y: 808))
leaf.curve(
  to: NSPoint(x: 741, y: 886), controlPoint1: NSPoint(x: 555, y: 943),
  controlPoint2: NSPoint(x: 683, y: 927))
leaf.curve(
  to: NSPoint(x: 535, y: 808), controlPoint1: NSPoint(x: 717, y: 781),
  controlPoint2: NSPoint(x: 600, y: 765))
NSColor(red: 0.70, green: 0.79, blue: 0.43, alpha: 1).setFill()
leaf.fill()
let apple = NSBezierPath()
apple.move(to: NSPoint(x: 513, y: 751))
apple.curve(
  to: NSPoint(x: 830, y: 554), controlPoint1: NSPoint(x: 730, y: 874),
  controlPoint2: NSPoint(x: 867, y: 746))
apple.curve(
  to: NSPoint(x: 513, y: 206), controlPoint1: NSPoint(x: 854, y: 309),
  controlPoint2: NSPoint(x: 675, y: 136))
apple.curve(
  to: NSPoint(x: 190, y: 555), controlPoint1: NSPoint(x: 322, y: 132),
  controlPoint2: NSPoint(x: 164, y: 335))
apple.curve(
  to: NSPoint(x: 513, y: 751), controlPoint1: NSPoint(x: 151, y: 755),
  controlPoint2: NSPoint(x: 332, y: 843))
apple.close()
NSGradient(
  starting: NSColor(red: 0.75, green: 0.24, blue: 0.18, alpha: 1),
  ending: NSColor(red: 1, green: 0.59, blue: 0.34, alpha: 1))!.draw(in: apple, angle: 90)
NSColor.white.withAlphaComponent(0.22).setFill()
NSBezierPath(ovalIn: NSRect(x: 262, y: 558, width: 57, height: 123)).fill()
for x in [390, 633] {
  NSColor(red: 1, green: 0.97, blue: 0.87, alpha: 1).setFill()
  NSBezierPath(ovalIn: NSRect(x: x - 58, y: 441, width: 113, height: 132)).fill()
  NSColor(red: 0.17, green: 0.24, blue: 0.18, alpha: 1).setFill()
  NSBezierPath(ovalIn: NSRect(x: x - 13, y: 463, width: 48, height: 68)).fill()
  NSColor.white.setFill()
  NSBezierPath(ovalIn: NSRect(x: x - 8, y: 504, width: 16, height: 18)).fill()
}
let smile = NSBezierPath()
smile.move(to: NSPoint(x: 460, y: 371))
smile.curve(
  to: NSPoint(x: 565, y: 371), controlPoint1: NSPoint(x: 487, y: 316),
  controlPoint2: NSPoint(x: 542, y: 316))
smile.lineWidth = 15
smile.lineCapStyle = .round
NSColor(red: 0.30, green: 0.21, blue: 0.16, alpha: 1).setStroke()
smile.stroke()
image.unlockFocus()
guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else { fatalError("Icon render failed") }
try png.write(to: URL(fileURLWithPath: destination))
