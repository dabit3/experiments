import AppKit

let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let red = NSColor(srgbRed: 0.76, green: 0.19, blue: 0.12, alpha: 1)
let cream = NSColor(srgbRed: 0.98, green: 0.96, blue: 0.91, alpha: 1)
red.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
cream.setFill()
NSBezierPath(ovalIn: NSRect(x: 164, y: 164, width: 696, height: 696)).fill()
red.setStroke()
let rim = NSBezierPath(ovalIn: NSRect(x: 190, y: 190, width: 644, height: 644))
rim.lineWidth = 5
rim.stroke()
let inner = NSBezierPath(ovalIn: NSRect(x: 225, y: 225, width: 574, height: 574))
inner.lineWidth = 3
inner.stroke()
let font = NSFont(name: "Georgia-Italic", size: 540) ?? NSFont.systemFont(ofSize: 540)
let text = NSAttributedString(string: "s", attributes: [.font: font, .foregroundColor: red])
text.draw(at: NSPoint(x: 380, y: 230))
let leaf = NSBezierPath()
leaf.move(to: NSPoint(x: 612, y: 676))
leaf.curve(
  to: NSPoint(x: 733, y: 781), controlPoint1: NSPoint(x: 600, y: 758),
  controlPoint2: NSPoint(x: 667, y: 800))
leaf.curve(
  to: NSPoint(x: 612, y: 676), controlPoint1: NSPoint(x: 751, y: 695),
  controlPoint2: NSPoint(x: 657, y: 660))
NSColor(srgbRed: 0.23, green: 0.35, blue: 0.22, alpha: 1).setFill()
leaf.fill()
image.unlockFocus()
guard let tiff = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else { fatalError("Could not render icon") }
try png.write(to: URL(fileURLWithPath: "SupperClub/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))
