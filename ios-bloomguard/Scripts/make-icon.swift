import AppKit

let side = 1024
let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 4,
  hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
func oval(_ x: Double, _ y: Double, _ width: Double, _ height: Double, _ color: NSColor) {
  color.setFill()
  NSBezierPath(ovalIn: NSRect(x: x, y: y, width: width, height: height)).fill()
}
func rectangle(
  _ x: Double, _ y: Double, _ width: Double, _ height: Double, _ color: NSColor, radius: Double = 0
) {
  color.setFill()
  NSBezierPath(
    roundedRect: NSRect(x: x, y: y, width: width, height: height), xRadius: radius, yRadius: radius
  ).fill()
}
let dark = NSColor(red: 0.13, green: 0.25, blue: 0.20, alpha: 1)
let leaf = NSColor(red: 0.40, green: 0.58, blue: 0.29, alpha: 1)
let gold = NSColor(red: 1, green: 0.74, blue: 0.23, alpha: 1)
rectangle(0, 0, 1024, 1024, dark)
oval(60, 75, 904, 904, NSColor(red: 0.20, green: 0.34, blue: 0.25, alpha: 1))
rectangle(480, 168, 65, 415, leaf, radius: 30)
oval(295, 223, 220, 105, leaf)
oval(520, 177, 230, 114, leaf)
for index in 0..<12 {
  let angle = Double(index) * .pi / 6
  oval(
    419 + cos(angle) * 206, 495 + sin(angle) * 206, 188, 206,
    index % 2 == 0 ? gold : NSColor(red: 0.93, green: 0.59, blue: 0.16, alpha: 1))
}
oval(332, 409, 363, 363, NSColor(red: 0.42, green: 0.25, blue: 0.15, alpha: 1))
oval(351, 442, 324, 303, NSColor(red: 0.63, green: 0.38, blue: 0.18, alpha: 1))
oval(410, 581, 44, 64, dark)
oval(568, 581, 44, 64, dark)
oval(422, 612, 13, 19, .white)
oval(580, 612, 13, 19, .white)
let smile = NSBezierPath()
smile.move(to: NSPoint(x: 467, y: 529))
smile.curve(
  to: NSPoint(x: 556, y: 529), controlPoint1: NSPoint(x: 492, y: 501),
  controlPoint2: NSPoint(x: 531, y: 501))
smile.lineWidth = 13
smile.lineCapStyle = .round
NSColor(red: 0.98, green: 0.93, blue: 0.79, alpha: 1).setStroke()
smile.stroke()
for index in 0..<12 {
  oval(
    Double((index * 83) % 950 + 22), Double((index * 71) % 320 + 24), 7, 7,
    gold.withAlphaComponent(0.5))
}
NSGraphicsContext.restoreGraphicsState()
let output = CommandLine.arguments[1]
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
