import AppKit

let size = 1024.0
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
NSColor(calibratedRed: 0.075, green: 0.035, blue: 0.11, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
let gold = NSColor(calibratedRed: 0.78, green: 0.64, blue: 0.4, alpha: 1)
let cyan = NSColor(calibratedRed: 0.39, green: 0.94, blue: 0.94, alpha: 1)
gold.setStroke()
for inset in [80.0, 98.0] {
  let frame = NSBezierPath(
    roundedRect: NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset),
    xRadius: 230, yRadius: 230)
  frame.lineWidth = 3
  frame.stroke()
}
for i in 0..<15 {
  let h = Double([90, 140, 180, 130, 220, 260, 210, 330, 250, 220, 170, 220, 140, 160, 100][i])
  let x = 175 + Double(i) * 45
  gold.setStroke()
  let rect = NSBezierPath(rect: NSRect(x: x, y: 555, width: 35, height: h))
  rect.lineWidth = 2
  rect.stroke()
  cyan.setFill()
  for row in 0..<Int(h / 22) {
    NSBezierPath(rect: NSRect(x: x + 14, y: 566 + Double(row) * 22, width: 5, height: 7)).fill()
  }
}
let text = "V/V" as NSString
let attributes: [NSAttributedString.Key: Any] = [
  .font: NSFont(name: "Didot", size: 330)!,
  .foregroundColor: NSColor(calibratedRed: 1, green: 0.36, blue: 0.39, alpha: 1),
]
text.draw(at: NSPoint(x: 200, y: 220), withAttributes: attributes)
cyan.setFill()
NSBezierPath(ovalIn: NSRect(x: 480, y: 157, width: 64, height: 64)).fill()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
let output = URL(fileURLWithPath: CommandLine.arguments[1])
try bitmap.representation(using: .png, properties: [:])!.write(to: output)
