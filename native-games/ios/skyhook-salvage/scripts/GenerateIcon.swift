import AppKit
import Foundation

let dimension = 1024
let image = NSImage(size: NSSize(width: dimension, height: dimension))
image.lockFocus()
let ink = NSColor(red: 0.13, green: 0.25, blue: 0.29, alpha: 1)
let sky = NSColor(red: 0.73, green: 0.85, blue: 0.87, alpha: 1)
let cream = NSColor(red: 0.98, green: 0.95, blue: 0.86, alpha: 1)
let orange = NSColor(red: 0.91, green: 0.35, blue: 0.17, alpha: 1)
let brass = NSColor(red: 0.78, green: 0.58, blue: 0.29, alpha: 1)
func rect(
  _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: NSColor, _ radius: Double = 0
) {
  color.setFill()
  NSBezierPath(
    roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: radius, yRadius: radius
  ).fill()
}
func ellipse(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: NSColor) {
  color.setFill()
  NSBezierPath(ovalIn: NSRect(x: x, y: y, width: w, height: h)).fill()
}
func line(_ points: [NSPoint], _ color: NSColor, _ width: Double) {
  let path = NSBezierPath()
  path.move(to: points[0])
  for point in points.dropFirst() { path.line(to: point) }
  path.lineWidth = width
  path.lineCapStyle = .round
  color.setStroke()
  path.stroke()
}
rect(0, 0, 1024, 1024, cream)
ellipse(61, 77, 902, 902, sky)
ellipse(658, 686, 150, 150, cream)
rect(137, 789, 725, 27, ink, 8)
rect(135, 276, 21, 522, ink, 5)
rect(497, 768, 83, 66, orange, 12)
line([NSPoint(x: 536, y: 770), NSPoint(x: 475, y: 625)], ink, 6)
rect(447, 603, 57, 39, brass, 7)
line([NSPoint(x: 475, y: 613), NSPoint(x: 475, y: 580), NSPoint(x: 497, y: 571)], ink, 9)
ellipse(286, 282, 526, 181, brass)
ellipse(312, 333, 474, 119, cream)
line([NSPoint(x: 319, y: 353), NSPoint(x: 782, y: 353)], brass, 4)
rect(283, 453, 532, 25, ink, 8)
rect(313, 468, 471, 7, orange, 3)
for x in [390.0, 535, 680] {
  line([NSPoint(x: x, y: 449), NSPoint(x: x, y: 299)], brass, 4)
}
rect(453, 251, 184, 51, ink, 16)
for x in [471.0, 523, 575] { ellipse(x, 270, 26, 22, sky) }
rect(427, 479, 225, 68, orange, 10)
rect(458, 483, 14, 62, brass)
rect(609, 483, 14, 62, brass)
rect(523, 502, 28, 28, cream, 5)
rect(386, 556, 300, 27, ink, 7)
rect(392, 562, 217, 12, cream, 2)
for x in stride(from: 402.0, through: 601.0, by: 15) { rect(x, 568, 6, 8, ink) }
line([NSPoint(x: 387, y: 598), NSPoint(x: 654, y: 639), NSPoint(x: 687, y: 601)], ink, 17)
line([NSPoint(x: 649, y: 628), NSPoint(x: 649, y: 581)], brass, 7)
line([NSPoint(x: 407, y: 557), NSPoint(x: 401, y: 546)], ink, 7)
line([NSPoint(x: 666, y: 557), NSPoint(x: 671, y: 490)], ink, 7)
image.unlockFocus()
guard let tiff = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else { fatalError("Could not render icon") }
try png.write(to: URL(fileURLWithPath: "Assets.xcassets/AppIcon.appiconset/AppIcon.png"))
