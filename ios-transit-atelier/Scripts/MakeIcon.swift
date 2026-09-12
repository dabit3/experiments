import AppKit
import Foundation

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let paper = NSColor(srgbRed: 0.97, green: 0.955, blue: 0.918, alpha: 1)
let navy = NSColor(srgbRed: 0.10, green: 0.18, blue: 0.23, alpha: 1)
let coral = NSColor(srgbRed: 0.86, green: 0.31, blue: 0.20, alpha: 1)
let teal = NSColor(srgbRed: 0.08, green: 0.49, blue: 0.48, alpha: 1)
paper.setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
navy.withAlphaComponent(0.12).setFill()
for x in stride(from: 32, to: 1024, by: 32) {
  for y in stride(from: 32, to: 1024, by: 32) {
    NSBezierPath(ovalIn: NSRect(x: x, y: y, width: 2, height: 2)).fill()
  }
}
let river = NSBezierPath()
river.move(to: NSPoint(x: 640, y: -50))
river.curve(
  to: NSPoint(x: 560, y: 1080), controlPoint1: NSPoint(x: 300, y: 350),
  controlPoint2: NSPoint(x: 950, y: 740))
navy.setStroke()
river.lineWidth = 100
river.stroke()
let redLine = NSBezierPath()
redLine.move(to: NSPoint(x: 230, y: 780))
redLine.line(to: NSPoint(x: 380, y: 470))
redLine.line(to: NSPoint(x: 790, y: 360))
redLine.line(to: NSPoint(x: 820, y: 200))
redLine.lineWidth = 28
redLine.lineCapStyle = .round
redLine.lineJoinStyle = .round
coral.setStroke()
redLine.stroke()
let blueLine = NSBezierPath()
blueLine.move(to: NSPoint(x: 220, y: 210))
blueLine.line(to: NSPoint(x: 380, y: 470))
blueLine.line(to: NSPoint(x: 730, y: 780))
blueLine.lineWidth = 28
blueLine.lineCapStyle = .round
teal.setStroke()
blueLine.stroke()
for point in [NSPoint(x: 230, y: 780), NSPoint(x: 380, y: 470), NSPoint(x: 820, y: 200)] {
  let station = NSBezierPath(
    ovalIn: NSRect(x: point.x - 35, y: point.y - 35, width: 70, height: 70))
  paper.setFill()
  station.fill()
  navy.setStroke()
  station.lineWidth = 10
  station.stroke()
}
for point in [NSPoint(x: 790, y: 360), NSPoint(x: 220, y: 210)] {
  let station = NSBezierPath(rect: NSRect(x: point.x - 33, y: point.y - 33, width: 66, height: 66))
  paper.setFill()
  station.fill()
  navy.setStroke()
  station.lineWidth = 10
  station.stroke()
}
let triangle = NSBezierPath()
triangle.move(to: NSPoint(x: 730, y: 824))
triangle.line(to: NSPoint(x: 689, y: 752))
triangle.line(to: NSPoint(x: 771, y: 752))
triangle.close()
paper.setFill()
triangle.fill()
navy.setStroke()
triangle.lineWidth = 10
triangle.stroke()
image.unlockFocus()
guard
  let tiff = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiff),
  let data = bitmap.representation(using: .png, properties: [:])
else { fatalError("Cannot render icon") }
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
