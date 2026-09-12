import AppKit

let destination =
  CommandLine.arguments.dropFirst().first
  ?? "MoonMarket/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
let ink = NSColor(red: 0.045, green: 0.09, blue: 0.15, alpha: 1)
let mint = NSColor(red: 0.65, green: 0.9, blue: 0.79, alpha: 1)
let orange = NSColor(red: 1, green: 0.65, blue: 0.34, alpha: 1)
let cream = NSColor(red: 0.97, green: 0.93, blue: 0.83, alpha: 1)
func ellipse(_ x: Double, _ y: Double, _ width: Double, _ height: Double, _ color: NSColor) {
  color.setFill()
  NSBezierPath(ovalIn: NSRect(x: x, y: y, width: width, height: height)).fill()
}
func box(
  _ x: Double, _ y: Double, _ width: Double, _ height: Double, _ color: NSColor, radius: Double = 0
) {
  color.setFill()
  NSBezierPath(
    roundedRect: NSRect(x: x, y: y, width: width, height: height), xRadius: radius, yRadius: radius
  ).fill()
}
box(0, 0, 1024, 1024, ink)
for index in 0..<40 {
  ellipse(
    Double((index * 131 + 41) % 1024), Double((index * 59 + 520) % 1024), 3, 3,
    cream.withAlphaComponent(0.5))
}
ellipse(635, 675, 180, 180, mint.withAlphaComponent(0.08))
ellipse(658, 698, 134, 134, cream)
ellipse(689, 720, 34, 29, ink.withAlphaComponent(0.09))
ellipse(-180, -180, 1400, 560, NSColor(red: 0.26, green: 0.35, blue: 0.36, alpha: 1))
ellipse(160, 160, 710, 94, ink.withAlphaComponent(0.35))
box(260, 240, 16, 390, orange)
box(751, 240, 16, 390, orange)
orange.setFill()
let canopy = NSBezierPath()
canopy.move(to: NSPoint(x: 196, y: 590))
canopy.line(to: NSPoint(x: 300, y: 706))
canopy.line(to: NSPoint(x: 723, y: 706))
canopy.line(to: NSPoint(x: 829, y: 590))
canopy.close()
canopy.fill()
for index in 0..<7 {
  box(
    196 + Double(index) * 90.4, 548, 90.4, 55,
    index % 2 == 0 ? cream : NSColor(red: 0.83, green: 0.36, blue: 0.24, alpha: 1), radius: 17)
}
ellipse(439, 365, 145, 166, mint)
ellipse(477, 443, 17, 25, ink)
ellipse(534, 443, 17, 25, ink)
box(508, 523, 6, 28, mint)
ellipse(501, 548, 19, 19, orange)
box(238, 258, 550, 110, NSColor(red: 0.59, green: 0.29, blue: 0.22, alpha: 1), radius: 12)
box(219, 356, 590, 29, orange, radius: 9)
for index in 0..<3 {
  let x = 260 + Double(index) * 176
  for item in 0..<3 {
    ellipse(
      x + Double(item) * 38, 385, 45, 47,
      [mint, NSColor(red: 0.71, green: 0.6, blue: 0.85, alpha: 1), orange][index])
  }
  box(x + 30, 328, 80, 45, mint, radius: 5)
}
for x in [302.0, 718] {
  ellipse(x - 42, 434, 84, 104, orange.withAlphaComponent(0.1))
  ellipse(x - 26, 450, 52, 72, orange)
  box(x - 5, 462, 10, 46, cream.withAlphaComponent(0.7), radius: 4)
}
ellipse(290, 205, 76, 76, ink)
ellipse(662, 205, 76, 76, ink)
image.unlockFocus()
guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
  let data = bitmap.representation(using: .png, properties: [:])
else { fatalError("Could not render app icon") }
try data.write(to: URL(fileURLWithPath: destination))
