import AppKit

let destination =
  CommandLine.arguments.dropFirst().first ?? "Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> NSColor {
  NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1)
}
func rect(_ box: NSRect, radius: CGFloat, fill: NSColor) {
  fill.setFill()
  NSBezierPath(roundedRect: box, xRadius: radius, yRadius: radius).fill()
}
let paper = color(0.97, 0.95, 0.89)
let ink = color(0.17, 0.23, 0.20)
paper.setFill()
NSRect(origin: .zero, size: size).fill()
rect(NSRect(x: 107, y: 155, width: 810, height: 714), radius: 96, fill: ink)
rect(NSRect(x: 127, y: 175, width: 770, height: 674), radius: 79, fill: color(0.79, 0.56, 0.35))
rect(NSRect(x: 155, y: 203, width: 714, height: 618), radius: 60, fill: color(0.72, 0.77, 0.63))
for x in [180, 385] {
  for y in [249, 512] {
    rect(NSRect(x: x, y: y, width: 177, height: 235), radius: 51, fill: paper)
    rect(
      NSRect(x: x + 9, y: y + 17, width: 159, height: 204), radius: 38,
      fill: color(0.96, 0.48, 0.32))
    for line in 0..<4 {
      let path = NSBezierPath()
      path.move(to: NSPoint(x: x + 25, y: y + 45 + line * 43))
      path.line(to: NSPoint(x: x + 152, y: y + 74 + line * 43))
      color(1, 0.82, 0.64).setStroke()
      path.lineWidth = 8
      path.stroke()
    }
    rect(NSRect(x: x + 4, y: y + 99, width: 169, height: 40), radius: 6, fill: ink)
  }
}
rect(NSRect(x: 588, y: 193, width: 15, height: 638), radius: 6, fill: ink)
for y in [282, 555] {
  let circle = NSRect(x: 638, y: y, width: 191, height: 191)
  color(0.97, 0.58, 0.17).setFill()
  NSBezierPath(ovalIn: circle).fill()
  color(1, 0.87, 0.56).setStroke()
  let ring = NSBezierPath(ovalIn: circle.insetBy(dx: 12, dy: 12))
  ring.lineWidth = 8
  ring.stroke()
  for index in 0..<8 {
    let angle = Double(index) * .pi / 4
    let path = NSBezierPath()
    path.move(to: NSPoint(x: 733.5, y: Double(y) + 95.5))
    path.line(to: NSPoint(x: 733.5 + cos(angle) * 78, y: Double(y) + 95.5 + sin(angle) * 78))
    path.lineWidth = 5
    path.stroke()
  }
}
image.unlockFocus()
guard let tiff = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else { fatalError("Could not render icon") }
try png.write(to: URL(fileURLWithPath: destination))
print("Wrote \(destination)")
