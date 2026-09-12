import AppKit

let size = 1024.0
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
NSColor(red: 0.24, green: 0.21, blue: 0.18, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
for index in 0..<40 {
  let path = NSBezierPath()
  let x = Double(index) * 31
  path.move(to: NSPoint(x: x, y: 0))
  path.curve(
    to: NSPoint(x: x + 70, y: 1024),
    controlPoint1: NSPoint(x: x - 50, y: 300), controlPoint2: NSPoint(x: x + 120, y: 700))
  NSColor.black.withAlphaComponent(0.06).setStroke()
  path.lineWidth = 4
  path.stroke()
}
let base = NSBezierPath(
  roundedRect: NSRect(x: 130, y: 120, width: 764, height: 764), xRadius: 210, yRadius: 210)
NSColor(red: 0.51, green: 0.62, blue: 0.53, alpha: 1).setFill()
base.fill()
for (index, angle) in [-0.27, 0.0, 0.27].enumerated() {
  NSGraphicsContext.saveGraphicsState()
  let transform = AffineTransform(
    translationByX: 325 + Double(index) * 187, byY: 510 - Double(abs(index - 1)) * 48)
  (transform as NSAffineTransform).concat()
  let rotation = AffineTransform(rotationByRadians: angle)
  (rotation as NSAffineTransform).concat()
  NSColor.black.withAlphaComponent(0.18).setFill()
  NSBezierPath(
    roundedRect: NSRect(x: -42, y: -235, width: 157, height: 367), xRadius: 28, yRadius: 28
  ).fill()
  NSColor(red: 0.97, green: 0.94, blue: 0.86, alpha: 1).setFill()
  NSBezierPath(
    roundedRect: NSRect(x: -75, y: -170, width: 150, height: 355), xRadius: 25, yRadius: 25
  ).fill()
  NSColor(red: 0.26, green: 0.30, blue: 0.27, alpha: 1).setFill()
  for offset in [-90.0, 102.0] {
    NSBezierPath(ovalIn: NSRect(x: -13, y: offset, width: 26, height: 26)).fill()
  }
  NSColor.gray.withAlphaComponent(0.35).setFill()
  NSBezierPath(rect: NSRect(x: -58, y: 5, width: 116, height: 3)).fill()
  NSGraphicsContext.restoreGraphicsState()
}
NSColor(red: 0.86, green: 0.69, blue: 0.39, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 632, y: 192, width: 125, height: 125)).fill()
NSColor(red: 0.98, green: 0.87, blue: 0.63, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 648, y: 219, width: 76, height: 76)).fill()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(
  to: URL(fileURLWithPath: CommandLine.arguments[1]))
