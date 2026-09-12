import AppKit
import Foundation

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
NSColor(calibratedRed: 0.025, green: 0.04, blue: 0.10, alpha: 1).setFill()
NSBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
let blue = NSColor(calibratedRed: 0.23, green: 0.44, blue: 1, alpha: 1)
let gold = NSColor(calibratedRed: 1, green: 0.9, blue: 0.68, alpha: 1)
for inset in [100.0, 155.0] {
  let orbit = NSBezierPath(
    ovalIn: CGRect(x: inset, y: inset, width: 1024 - 2 * inset, height: 1024 - 2 * inset))
  blue.withAlphaComponent(0.14).setStroke()
  orbit.lineWidth = 2
  orbit.stroke()
}
let circuit = NSBezierPath()
circuit.move(to: CGPoint(x: 75, y: 735))
circuit.line(to: CGPoint(x: 475, y: 735))
circuit.curve(
  to: CGPoint(x: 535, y: 795), controlPoint1: CGPoint(x: 520, y: 735),
  controlPoint2: CGPoint(x: 535, y: 750))
circuit.line(to: CGPoint(x: 535, y: 928))
circuit.move(to: CGPoint(x: 950, y: 275))
circuit.line(to: CGPoint(x: 585, y: 275))
circuit.curve(
  to: CGPoint(x: 530, y: 220), controlPoint1: CGPoint(x: 540, y: 275),
  controlPoint2: CGPoint(x: 530, y: 260))
circuit.line(to: CGPoint(x: 530, y: 95))
circuit.lineCapStyle = .round
blue.withAlphaComponent(0.18).setStroke()
circuit.lineWidth = 72
circuit.stroke()
blue.setStroke()
circuit.lineWidth = 5
circuit.stroke()
let comet = NSBezierPath()
comet.move(to: CGPoint(x: 382, y: 515))
comet.appendArc(
  withCenter: CGPoint(x: 382, y: 515), radius: 180, startAngle: 35, endAngle: 325, clockwise: false)
comet.close()
let shadow = NSShadow()
shadow.shadowColor = gold.withAlphaComponent(0.3)
shadow.shadowBlurRadius = 70
shadow.set()
gold.setFill()
comet.fill()
NSShadow().set()
NSColor(calibratedRed: 0.025, green: 0.04, blue: 0.10, alpha: 1).setFill()
NSBezierPath(ovalIn: CGRect(x: 380, y: 608, width: 27, height: 27)).fill()
gold.setFill()
for x in [612.0, 708, 804] {
  NSBezierPath(ovalIn: CGRect(x: x, y: 501, width: 28, height: 28)).fill()
}
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
let data = bitmap.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
