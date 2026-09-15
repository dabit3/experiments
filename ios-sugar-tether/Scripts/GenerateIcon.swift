import AppKit

let dimension = 1024
let image = NSImage(size: NSSize(width: dimension, height: dimension))
image.lockFocus()
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
  NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
}
func oval(_ rect: NSRect, _ fill: NSColor) {
  fill.setFill()
  NSBezierPath(ovalIn: rect).fill()
}
let cream = color(0.98, 0.94, 0.83)
let ink = color(0.18, 0.3, 0.24)
cream.setFill()
NSRect(x: 0, y: 0, width: 1024, height: 1024).fill()
oval(NSRect(x: 80, y: 70, width: 864, height: 864), color(0.94, 0.88, 0.72))
for index in 0..<2300 {
  let x = (index * 79) % dimension
  let y = (index * 137) % dimension
  oval(NSRect(x: x, y: y, width: 2, height: 2), color(0.9, 0.85, 0.73))
}
let thread = NSBezierPath()
thread.move(to: NSPoint(x: 512, y: 1024))
thread.line(to: NSPoint(x: 512, y: 762))
thread.lineWidth = 11
color(0.65, 0.48, 0.26).setStroke()
thread.stroke()
thread.lineWidth = 5
cream.setStroke()
thread.setLineDash([8, 7], count: 2, phase: 0)
thread.stroke()
oval(NSRect(x: 244, y: 90, width: 536, height: 92), color(0.8, 0.76, 0.61))
oval(NSRect(x: 272, y: 103, width: 145, height: 78), color(0.24, 0.43, 0.31))
oval(NSRect(x: 607, y: 103, width: 145, height: 78), color(0.24, 0.43, 0.31))
for side in [-1.0, 1.0] {
  let leaf = NSBezierPath()
  leaf.move(to: NSPoint(x: 512 + side * 115, y: 516))
  leaf.curve(
    to: NSPoint(x: 512 + side * 224, y: 671),
    controlPoint1: NSPoint(x: 512 + side * 228, y: 526),
    controlPoint2: NSPoint(x: 512 + side * 260, y: 634))
  leaf.curve(
    to: NSPoint(x: 512 + side * 115, y: 516),
    controlPoint1: NSPoint(x: 512 + side * 98, y: 669),
    controlPoint2: NSPoint(x: 512 + side * 82, y: 600))
  color(0.34, 0.57, 0.4).setFill()
  leaf.fill()
}
let body = NSBezierPath()
body.move(to: NSPoint(x: 512, y: 618))
body.curve(
  to: NSPoint(x: 787, y: 270), controlPoint1: NSPoint(x: 715, y: 629),
  controlPoint2: NSPoint(x: 802, y: 455))
body.curve(
  to: NSPoint(x: 512, y: 132), controlPoint1: NSPoint(x: 788, y: 120),
  controlPoint2: NSPoint(x: 652, y: 132))
body.curve(
  to: NSPoint(x: 237, y: 270), controlPoint1: NSPoint(x: 367, y: 132),
  controlPoint2: NSPoint(x: 237, y: 120))
body.curve(
  to: NSPoint(x: 512, y: 618), controlPoint1: NSPoint(x: 222, y: 455),
  controlPoint2: NSPoint(x: 309, y: 629))
body.close()
NSGradient(starting: color(0.35, 0.59, 0.43), ending: color(0.65, 0.79, 0.53))!.draw(
  in: body, angle: 90)
NSGraphicsContext.saveGraphicsState()
body.addClip()
for index in 0..<1800 {
  let x = 232 + (index * 43) % 564
  let y = 130 + (index * 97) % 494
  oval(NSRect(x: x, y: y, width: 2, height: 3), NSColor.white.withAlphaComponent(0.16))
}
NSGraphicsContext.restoreGraphicsState()
for side in [-1.0, 1.0] {
  oval(NSRect(x: 512 + side * 106 - 67, y: 374, width: 134, height: 160), cream)
  oval(NSRect(x: 512 + side * 106 - 25, y: 435, width: 50, height: 69), ink)
  oval(NSRect(x: 512 + side * 106 - 16, y: 475, width: 15, height: 19), .white)
  oval(NSRect(x: 512 + side * 192 - 43, y: 323, width: 86, height: 42), color(0.79, 0.55, 0.47))
}
let mouth = NSBezierPath(ovalIn: NSRect(x: 400, y: 212, width: 224, height: 156))
ink.setFill()
mouth.fill()
NSGraphicsContext.saveGraphicsState()
mouth.addClip()
oval(NSRect(x: 444, y: 189, width: 148, height: 97), color(0.83, 0.39, 0.4))
cream.setFill()
NSBezierPath(roundedRect: NSRect(x: 458, y: 321, width: 44, height: 59), xRadius: 9, yRadius: 9)
  .fill()
NSBezierPath(roundedRect: NSRect(x: 518, y: 321, width: 44, height: 59), xRadius: 9, yRadius: 9)
  .fill()
NSGraphicsContext.restoreGraphicsState()
let candy = NSBezierPath(ovalIn: NSRect(x: 416, y: 692, width: 192, height: 192))
color(0.86, 0.4, 0.4).setFill()
candy.fill()
NSGraphicsContext.saveGraphicsState()
candy.addClip()
for index in -2...2 {
  let stripe = NSBezierPath()
  stripe.move(to: NSPoint(x: 424 + index * 64, y: 692))
  stripe.curve(
    to: NSPoint(x: 562 + index * 64, y: 884),
    controlPoint1: NSPoint(x: 550 + index * 64, y: 730),
    controlPoint2: NSPoint(x: 436 + index * 64, y: 840))
  cream.setStroke()
  stripe.lineWidth = 28
  stripe.stroke()
}
NSGraphicsContext.restoreGraphicsState()
oval(NSRect(x: 445, y: 829, width: 71, height: 27), NSColor.white.withAlphaComponent(0.75))
for (x, y, radius) in [(207.0, 748.0, 53.0), (815.0, 708.0, 44.0)] {
  let star = NSBezierPath()
  for index in 0..<10 {
    let angle = Double(index) * .pi / 5 + .pi / 2
    let r = index % 2 == 0 ? radius : radius * 0.47
    let p = NSPoint(x: x + cos(angle) * r, y: y + sin(angle) * r)
    if index == 0 { star.move(to: p) } else { star.line(to: p) }
  }
  star.close()
  color(0.92, 0.69, 0.26).setFill()
  star.fill()
}
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
let opaque = CGContext(
  data: nil, width: dimension, height: dimension, bitsPerComponent: 8,
  bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
opaque.draw(bitmap.cgImage!, in: CGRect(x: 0, y: 0, width: dimension, height: dimension))
let png = NSBitmapImageRep(cgImage: opaque.makeImage()!).representation(
  using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))
