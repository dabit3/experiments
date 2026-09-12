import AppKit
import Foundation

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let ink = NSColor(calibratedRed: 0.016, green: 0.024, blue: 0.066, alpha: 1)
let blue = NSColor(calibratedRed: 0.26, green: 0.50, blue: 1, alpha: 1)
let violet = NSColor(calibratedRed: 0.56, green: 0.40, blue: 1, alpha: 1)
let gold = NSColor(calibratedRed: 1, green: 0.92, blue: 0.74, alpha: 1)
let amber = NSColor(calibratedRed: 0.93, green: 0.74, blue: 0.42, alpha: 1)
NSGradient(colors: [
  NSColor(calibratedRed: 0.07, green: 0.11, blue: 0.26, alpha: 1), ink,
])!.draw(in: CGRect(origin: .zero, size: size), angle: -60)
NSGradient(colors: [violet.withAlphaComponent(0.35), .clear])!.draw(
  in: NSBezierPath(ovalIn: CGRect(x: 520, y: -260, width: 900, height: 900)),
  relativeCenterPosition: .zero)
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
for (index, alpha) in [0.22, 0.16, 0.10, 0.05].enumerated() {
  let radius = 130.0 - Double(index) * 24
  amber.withAlphaComponent(alpha).setFill()
  NSBezierPath(
    ovalIn: CGRect(
      x: 382 - 175 - Double(index) * 80 - radius, y: 515 - radius, width: radius * 2,
      height: radius * 2)
  ).fill()
}
let shadow = NSShadow()
shadow.shadowColor = amber.withAlphaComponent(0.45)
shadow.shadowBlurRadius = 80
shadow.set()
gold.setFill()
comet.fill()
NSShadow().set()
NSGradient(colors: [NSColor.white, gold, amber])!.draw(in: comet, angle: -90)
ink.setFill()
NSBezierPath(ovalIn: CGRect(x: 380, y: 608, width: 27, height: 27)).fill()
gold.setFill()
for x in [612.0, 708] {
  NSBezierPath(ovalIn: CGRect(x: x, y: 501, width: 28, height: 28)).fill()
}
let spirit = NSBezierPath()
spirit.move(to: CGPoint(x: 780, y: 440))
spirit.line(to: CGPoint(x: 780, y: 540))
spirit.appendArc(
  withCenter: CGPoint(x: 850, y: 540), radius: 70, startAngle: 180, endAngle: 0, clockwise: true)
spirit.line(to: CGPoint(x: 920, y: 440))
for index in stride(from: 5, through: 0, by: -1) {
  spirit.line(
    to: CGPoint(x: 780 + Double(index) * 140 / 6, y: index % 2 == 0 ? 440 : 462))
}
spirit.close()
shadow.shadowColor = violet.withAlphaComponent(0.5)
shadow.set()
violet.setFill()
spirit.fill()
NSShadow().set()
for x in [818.0, 858] {
  NSColor.white.setFill()
  NSBezierPath(ovalIn: CGRect(x: x, y: 520, width: 22, height: 30)).fill()
  ink.setFill()
  NSBezierPath(ovalIn: CGRect(x: x + 3, y: 526, width: 12, height: 16)).fill()
}
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
let data = bitmap.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
