import AppKit

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let background = NSBezierPath(rect: CGRect(origin: .zero, size: size))
NSGradient(colors: [
  NSColor(srgbRed: 0.025, green: 0.05, blue: 0.14, alpha: 1),
  NSColor(srgbRed: 0.32, green: 0.12, blue: 0.34, alpha: 1),
])!.draw(in: background, angle: 90)
let sun = NSBezierPath(ovalIn: CGRect(x: 258, y: 340, width: 510, height: 510))
NSGradient(colors: [
  NSColor(srgbRed: 1, green: 0.25, blue: 0.54, alpha: 1),
  NSColor(srgbRed: 1, green: 0.73, blue: 0.49, alpha: 1),
])!.draw(in: sun, angle: 90)
let dark = NSColor(srgbRed: 0.065, green: 0.08, blue: 0.19, alpha: 1)
dark.setFill()
for index in 0..<6 {
  NSBezierPath(rect: CGRect(x: 245, y: 385 + index * 29, width: 540, height: 6 + index * 2)).fill()
}
let road = NSBezierPath()
road.move(to: CGPoint(x: 445, y: 460))
road.line(to: CGPoint(x: 579, y: 460))
road.line(to: CGPoint(x: 1005, y: 0))
road.line(to: CGPoint(x: 19, y: 0))
road.close()
dark.setFill()
road.fill()
let mint = NSColor(srgbRed: 0.3, green: 1, blue: 0.85, alpha: 1)
for (start, end) in [(445.0, 19.0), (579.0, 1005.0), (489.0, 345.0), (535.0, 679.0)] {
  let line = NSBezierPath()
  line.move(to: CGPoint(x: start, y: 460))
  line.line(to: CGPoint(x: end, y: 0))
  line.lineWidth = 8
  mint.setStroke()
  line.stroke()
}
func palm(x: CGFloat, y: CGFloat, scale: CGFloat) {
  let trunk = NSBezierPath()
  trunk.move(to: CGPoint(x: x, y: y))
  trunk.curve(
    to: CGPoint(x: x + 24 * scale, y: y + 270 * scale),
    controlPoint1: CGPoint(x: x + 5 * scale, y: y + 100 * scale),
    controlPoint2: CGPoint(x: x + 37 * scale, y: y + 190 * scale))
  trunk.lineWidth = 23 * scale
  dark.setStroke()
  trunk.stroke()
  for direction in [-1.0, 1.0] {
    for index in 0..<3 {
      let leaf = NSBezierPath()
      let point = CGPoint(x: x + 24 * scale, y: y + 270 * scale)
      leaf.move(to: point)
      leaf.curve(
        to: CGPoint(x: point.x + direction * 160 * scale, y: point.y - CGFloat(index) * 42 * scale),
        controlPoint1: CGPoint(x: point.x + direction * 60 * scale, y: point.y + 85 * scale),
        controlPoint2: CGPoint(x: point.x + direction * 160 * scale, y: point.y + 45 * scale))
      leaf.curve(
        to: point,
        controlPoint1: CGPoint(x: point.x + direction * 90 * scale, y: point.y + 5 * scale),
        controlPoint2: CGPoint(x: point.x + direction * 40 * scale, y: point.y + 14 * scale))
      dark.setFill()
      leaf.fill()
    }
  }
}
palm(x: 160, y: 270, scale: 1.1)
palm(x: 865, y: 365, scale: 0.78)
NSGraphicsContext.saveGraphicsState()
let transform = NSAffineTransform()
transform.translateX(by: 512, yBy: 320)
transform.rotate(byDegrees: -24)
transform.concat()
let deck = NSBezierPath(
  roundedRect: CGRect(x: -210, y: -60, width: 420, height: 120), xRadius: 60, yRadius: 60)
NSColor(srgbRed: 1, green: 0.22, blue: 0.57, alpha: 1).setFill()
deck.fill()
let stripe = NSBezierPath(
  roundedRect: CGRect(x: -155, y: -12, width: 310, height: 24), xRadius: 12, yRadius: 12)
mint.setFill()
stripe.fill()
for x in [-130, 130] {
  for y in [-68, 68] {
    let wheel = NSBezierPath(
      roundedRect: CGRect(x: x - 25, y: y - 17, width: 50, height: 34), xRadius: 12, yRadius: 12)
    mint.setFill()
    wheel.fill()
  }
}
NSGraphicsContext.restoreGraphicsState()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(
  to: URL(fileURLWithPath: CommandLine.arguments[1]))
