import AppKit
import Foundation

let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
NSColor(red: 0.035, green: 0.12, blue: 0.11, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
let paper = NSColor(red: 0.94, green: 0.90, blue: 0.79, alpha: 1)
let copper = NSColor(red: 0.82, green: 0.57, blue: 0.33, alpha: 1)
copper.setStroke()
let ring = NSBezierPath(ovalIn: NSRect(x: 145, y: 145, width: 734, height: 734))
ring.lineWidth = 3
ring.stroke()
let inner = NSBezierPath(ovalIn: NSRect(x: 165, y: 165, width: 694, height: 694))
inner.lineWidth = 1
inner.stroke()
func shape(_ points: [NSPoint], color: NSColor) {
  let path = NSBezierPath()
  path.move(to: points[0])
  for point in points.dropFirst() { path.line(to: point) }
  path.close()
  color.setFill()
  path.fill()
}
for sign: CGFloat in [-1, 1] {
  func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: 512 + x * sign, y: y) }
  shape(
    [point(5, 537), point(160, 752), point(359, 714), point(271, 486), point(67, 463)], color: paper
  )
  shape([point(10, 463), point(155, 453), point(238, 301), point(69, 254)], color: copper)
  NSColor(red: 0.035, green: 0.12, blue: 0.11, alpha: 1).setFill()
  NSBezierPath(ovalIn: NSRect(x: 512 + sign * 186 - 47, y: 553, width: 94, height: 94)).fill()
  copper.setFill()
  NSBezierPath(ovalIn: NSRect(x: 512 + sign * 186 - 15, y: 585, width: 30, height: 30)).fill()
  let antenna = NSBezierPath()
  antenna.move(to: point(0, 540))
  antenna.line(to: point(45, 684))
  antenna.line(to: point(85, 705))
  copper.setStroke()
  antenna.lineWidth = 7
  antenna.stroke()
}
shape(
  [
    NSPoint(x: 512, y: 594), NSPoint(x: 543, y: 478), NSPoint(x: 512, y: 316),
    NSPoint(x: 481, y: 478),
  ], color: paper)
image.unlockFocus()
guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else { fatalError("Cannot render icon") }
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
