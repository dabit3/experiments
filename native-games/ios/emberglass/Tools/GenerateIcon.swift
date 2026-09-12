import AppKit

let destination =
  CommandLine.arguments.dropFirst().first ?? "Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
NSColor(red: 0.025, green: 0.04, blue: 0.048, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
let halo = NSBezierPath(ovalIn: NSRect(x: 114, y: 95, width: 796, height: 840))
NSColor(red: 0.90, green: 0.35, blue: 0.14, alpha: 0.45).setStroke()
halo.lineWidth = 2
halo.stroke()
let vase = NSBezierPath()
vase.move(to: NSPoint(x: 408, y: 810))
vase.curve(
  to: NSPoint(x: 395, y: 640), controlPoint1: NSPoint(x: 430, y: 750),
  controlPoint2: NSPoint(x: 420, y: 690))
vase.curve(
  to: NSPoint(x: 275, y: 390), controlPoint1: NSPoint(x: 360, y: 560),
  controlPoint2: NSPoint(x: 265, y: 510))
vase.curve(
  to: NSPoint(x: 374, y: 213), controlPoint1: NSPoint(x: 276, y: 285),
  controlPoint2: NSPoint(x: 309, y: 232))
vase.curve(
  to: NSPoint(x: 650, y: 213), controlPoint1: NSPoint(x: 450, y: 173),
  controlPoint2: NSPoint(x: 574, y: 173))
vase.curve(
  to: NSPoint(x: 749, y: 390), controlPoint1: NSPoint(x: 715, y: 232),
  controlPoint2: NSPoint(x: 748, y: 285))
vase.curve(
  to: NSPoint(x: 629, y: 640), controlPoint1: NSPoint(x: 759, y: 510),
  controlPoint2: NSPoint(x: 664, y: 560))
vase.curve(
  to: NSPoint(x: 616, y: 810), controlPoint1: NSPoint(x: 604, y: 690),
  controlPoint2: NSPoint(x: 594, y: 750))
vase.close()
NSGraphicsContext.saveGraphicsState()
vase.addClip()
NSGradient(colors: [
  NSColor(red: 0.05, green: 0.20, blue: 0.24, alpha: 1),
  NSColor(red: 0.48, green: 0.89, blue: 0.82, alpha: 1),
  NSColor(red: 0.10, green: 0.38, blue: 0.46, alpha: 1),
  NSColor(red: 0.29, green: 0.25, blue: 0.60, alpha: 1),
  NSColor(red: 0.05, green: 0.10, blue: 0.15, alpha: 1),
])!.draw(in: NSRect(x: 270, y: 180, width: 484, height: 640), angle: 0)
for index in 0..<28 {
  let line = NSBezierPath()
  let y = 210 + CGFloat(index) * 22
  line.move(to: NSPoint(x: 250, y: y))
  line.curve(
    to: NSPoint(x: 770, y: y + 80), controlPoint1: NSPoint(x: 430, y: y - 100),
    controlPoint2: NSPoint(x: 600, y: y + 110))
  NSColor.white.withAlphaComponent(0.15).setStroke()
  line.lineWidth = 2
  line.stroke()
}
let highlight = NSBezierPath(
  roundedRect: NSRect(x: 380, y: 300, width: 12, height: 290), xRadius: 8, yRadius: 8)
NSColor.white.withAlphaComponent(0.65).setFill()
highlight.fill()
NSGraphicsContext.restoreGraphicsState()
NSColor(red: 0.76, green: 0.93, blue: 0.87, alpha: 0.8).setStroke()
vase.lineWidth = 3
vase.stroke()
let lip = NSBezierPath(ovalIn: NSRect(x: 408, y: 798, width: 208, height: 24))
NSColor(red: 0.02, green: 0.09, blue: 0.11, alpha: 1).setFill()
lip.fill()
NSColor(red: 0.95, green: 0.89, blue: 0.73, alpha: 1).setStroke()
lip.lineWidth = 3
lip.stroke()
image.unlockFocus()
guard let tiff = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else { fatalError("Icon rendering failed") }
try png.write(to: URL(fileURLWithPath: destination))
