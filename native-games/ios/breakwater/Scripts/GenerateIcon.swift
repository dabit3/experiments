import AppKit

let output =
  CommandLine.arguments.dropFirst().first ?? "Assets.xcassets/AppIcon.appiconset/Icon.png"
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
let sea = NSColor(calibratedRed: 0.03, green: 0.25, blue: 0.28, alpha: 1)
let cream = NSColor(calibratedRed: 0.98, green: 0.94, blue: 0.83, alpha: 1)
let coral = NSColor(calibratedRed: 0.97, green: 0.43, blue: 0.32, alpha: 1)
let brass = NSColor(calibratedRed: 0.90, green: 0.73, blue: 0.43, alpha: 1)
let ink = NSColor(calibratedRed: 0.02, green: 0.14, blue: 0.17, alpha: 1)
sea.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
for row in 0..<30 {
  let wave = NSBezierPath()
  for column in 0...40 {
    let x = Double(column) * 27
    let y = Double(row) * 38 + sin(x / 120 + Double(row)) * 8
    if column == 0 {
      wave.move(to: NSPoint(x: x, y: y))
    } else {
      wave.line(to: NSPoint(x: x, y: y))
    }
  }
  cream.withAlphaComponent(0.045).setStroke()
  wave.lineWidth = 2
  wave.stroke()
}
let route = NSBezierPath()
route.move(to: NSPoint(x: 230, y: 100))
route.curve(
  to: NSPoint(x: 484, y: 507),
  controlPoint1: NSPoint(x: 640, y: 105), controlPoint2: NSPoint(x: 72, y: 290))
route.curve(
  to: NSPoint(x: 760, y: 780),
  controlPoint1: NSPoint(x: 830, y: 590), controlPoint2: NSPoint(x: 690, y: 625))
brass.setStroke()
route.lineWidth = 7
route.setLineDash([12, 17], count: 2, phase: 0)
route.stroke()
let ring = NSBezierPath(ovalIn: NSRect(x: 660, y: 680, width: 200, height: 200))
ring.lineWidth = 3
ring.stroke()
cream.setFill()
NSBezierPath(roundedRect: NSRect(x: 793, y: 656, width: 28, height: 260), xRadius: 6, yRadius: 6)
  .fill()
NSBezierPath(roundedRect: NSRect(x: 780, y: 656, width: 145, height: 28), xRadius: 6, yRadius: 6)
  .fill()
let transform = NSAffineTransform()
transform.translateX(by: 470, yBy: 462)
transform.concat()
let rotation = NSAffineTransform()
rotation.rotate(byDegrees: -28)
rotation.concat()
let hull = NSBezierPath()
hull.move(to: NSPoint(x: 0, y: 183))
hull.curve(
  to: NSPoint(x: 97, y: -75), controlPoint1: NSPoint(x: 120, y: 115),
  controlPoint2: NSPoint(x: 99, y: 10))
hull.line(to: NSPoint(x: 81, y: -151))
hull.curve(
  to: NSPoint(x: -81, y: -151),
  controlPoint1: NSPoint(x: 36, y: -172), controlPoint2: NSPoint(x: -36, y: -172))
hull.line(to: NSPoint(x: -97, y: -75))
hull.curve(
  to: NSPoint(x: 0, y: 183), controlPoint1: NSPoint(x: -99, y: 10),
  controlPoint2: NSPoint(x: -120, y: 115))
hull.close()
let shadow = NSShadow()
shadow.shadowColor = ink.withAlphaComponent(0.75)
shadow.shadowOffset = NSSize(width: 12, height: -22)
shadow.shadowBlurRadius = 18
shadow.set()
coral.setFill()
hull.fill()
shadow.shadowColor = .clear
shadow.set()
ink.setStroke()
hull.lineWidth = 10
hull.stroke()
cream.setFill()
NSBezierPath(roundedRect: NSRect(x: -58, y: -84, width: 116, height: 157), xRadius: 18, yRadius: 18)
  .fill()
ink.setFill()
NSBezierPath(roundedRect: NSRect(x: -44, y: 20, width: 88, height: 35), xRadius: 5, yRadius: 5)
  .fill()
brass.setFill()
NSBezierPath(ovalIn: NSRect(x: -17, y: -59, width: 34, height: 34)).fill()
ink.setFill()
NSBezierPath(ovalIn: NSRect(x: -20, y: -144, width: 40, height: 40)).fill()
image.unlockFocus()
guard let tiff = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else { fatalError("Unable to render app icon") }
try png.write(to: URL(fileURLWithPath: output))
