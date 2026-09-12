import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let navy = NSColor(calibratedRed: 0.08, green: 0.20, blue: 0.25, alpha: 1)
let cream = NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.88, alpha: 1)
let sea = NSColor(calibratedRed: 0.47, green: 0.73, blue: 0.67, alpha: 1)
let red = NSColor(calibratedRed: 0.88, green: 0.24, blue: 0.14, alpha: 1)
let butter = NSColor(calibratedRed: 0.98, green: 0.84, blue: 0.38, alpha: 1)

func rect(
  _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: NSColor, radius: CGFloat = 0
) {
  color.setFill()
  NSBezierPath(
    roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: radius, yRadius: radius
  ).fill()
}

func render(size: Int, target: URL, drawing: () -> Void) throws {
  let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
  )!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
  drawing()
  NSGraphicsContext.restoreGraphicsState()
  try bitmap.representation(using: .png, properties: [:])!.write(to: target)
}

try render(size: 1024, target: root.appendingPathComponent("AppIcon.appiconset/AppIcon.png")) {
  rect(0, 0, 1024, 1024, sea)
  let road = NSBezierPath()
  road.move(to: NSPoint(x: 140, y: 0))
  road.curve(
    to: NSPoint(x: 635, y: 1024), controlPoint1: NSPoint(x: 80, y: 510),
    controlPoint2: NSPoint(x: 660, y: 650))
  road.line(to: NSPoint(x: 1140, y: 1024))
  road.curve(
    to: NSPoint(x: 660, y: 0), controlPoint1: NSPoint(x: 1060, y: 590),
    controlPoint2: NSPoint(x: 540, y: 440))
  road.close()
  cream.setFill()
  road.fill()
  for y in stride(from: 50.0, to: 1024.0, by: 160) {
    rect(475 + sin(y / 400) * 80, y, 14, 74, butter, radius: 7)
  }
  let transform = NSAffineTransform()
  transform.translateX(by: 495, yBy: 484)
  transform.concat()
  let rotation = NSAffineTransform()
  rotation.rotate(byDegrees: -18)
  rotation.concat()
  rect(-13, -195, 26, 105, navy, radius: 13)
  rect(-13, 100, 26, 110, navy, radius: 13)
  rect(-6, -147, 12, 300, red, radius: 6)
  rect(-83, 105, 166, 16, navy, radius: 8)
  rect(-68, -66, 46, 108, navy, radius: 20)
  rect(22, -95, 46, 108, navy, radius: 20)
  rect(-89, 35, 32, 87, cream, radius: 16)
  rect(57, 35, 32, 87, cream, radius: 16)
  rect(-60, -22, 120, 160, red, radius: 40)
  rect(-60, 5, 120, 22, butter)
  rect(-39, 107, 78, 96, navy, radius: 34)
  rect(-31, 117, 62, 90, cream, radius: 30)
  rect(-14, 129, 8, 63, red, radius: 4)
  rect(6, 129, 8, 63, red, radius: 4)
}

try render(size: 256, target: root.appendingPathComponent("LaunchMark.imageset/LaunchMark.png")) {
  rect(0, 0, 256, 256, cream)
  let text = "P."
  let font = NSFont(name: "Georgia-BoldItalic", size: 155) ?? NSFont.boldSystemFont(ofSize: 155)
  text.draw(at: NSPoint(x: 27, y: 40), withAttributes: [.font: font, .foregroundColor: navy])
  rect(39, 37, 170, 8, red)
}
