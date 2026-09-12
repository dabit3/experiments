import AppKit

let destination =
  CommandLine.arguments.dropFirst().first
  ?? "Rippletone/Assets.xcassets/AppIcon.appiconset/Icon.png"
let size = 1024
let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
  samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB,
  bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(red: 0.025, green: 0.065, blue: 0.07, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
let gold = NSColor(red: 0.81, green: 0.72, blue: 0.47, alpha: 1)
for index in 0..<4 {
  let inset = CGFloat(105 + index * 34)
  gold.withAlphaComponent(index == 1 ? 0.85 : 0.18).setStroke()
  let circle = NSBezierPath(
    ovalIn: NSRect(x: inset, y: inset, width: 1024 - inset * 2, height: 1024 - inset * 2))
  circle.lineWidth = index == 1 ? 3 : 1.5
  circle.stroke()
}
func fish(x: CGFloat, y: CGFloat, angle: CGFloat, scale: CGFloat, color: NSColor) {
  NSGraphicsContext.saveGraphicsState()
  let transform = AffineTransform(translationByX: x, byY: y)
  let nsTransform = NSAffineTransform(transform: transform)
  nsTransform.rotate(byDegrees: angle)
  nsTransform.scale(by: scale)
  nsTransform.concat()
  let body = NSBezierPath()
  body.move(to: NSPoint(x: -180, y: 0))
  body.curve(
    to: NSPoint(x: 165, y: 0), controlPoint1: NSPoint(x: -30, y: -130),
    controlPoint2: NSPoint(x: 180, y: -75))
  body.curve(
    to: NSPoint(x: -180, y: 0), controlPoint1: NSPoint(x: 180, y: 75),
    controlPoint2: NSPoint(x: -30, y: 120))
  color.setFill()
  body.fill()
  let tail = NSBezierPath()
  tail.move(to: NSPoint(x: -168, y: 0))
  tail.curve(
    to: NSPoint(x: -280, y: -100), controlPoint1: NSPoint(x: -230, y: -20),
    controlPoint2: NSPoint(x: -260, y: -85))
  tail.curve(
    to: NSPoint(x: -245, y: 0), controlPoint1: NSPoint(x: -255, y: -60),
    controlPoint2: NSPoint(x: -247, y: -30))
  tail.curve(
    to: NSPoint(x: -280, y: 100), controlPoint1: NSPoint(x: -247, y: 30),
    controlPoint2: NSPoint(x: -255, y: 60))
  tail.curve(
    to: NSPoint(x: -168, y: 0), controlPoint1: NSPoint(x: -240, y: 80),
    controlPoint2: NSPoint(x: -210, y: 20))
  color.withAlphaComponent(0.75).setFill()
  tail.fill()
  NSColor(red: 0.025, green: 0.065, blue: 0.07, alpha: 1).setFill()
  NSBezierPath(ovalIn: NSRect(x: 114, y: 24, width: 12, height: 12)).fill()
  NSGraphicsContext.restoreGraphicsState()
}
fish(
  x: 395, y: 410, angle: 49, scale: 1.15,
  color: NSColor(red: 0.97, green: 0.65, blue: 0.49, alpha: 1))
fish(
  x: 677, y: 615, angle: 229, scale: 0.78,
  color: NSColor(red: 0.94, green: 0.93, blue: 0.84, alpha: 1))
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(
  to: URL(fileURLWithPath: destination))
