import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let size = 1024
let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
  bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false,
  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
let emerald = NSColor(red: 0.025, green: 0.15, blue: 0.12, alpha: 1)
let gold = NSColor(red: 0.88, green: 0.73, blue: 0.43, alpha: 1)
let cream = NSColor(red: 0.97, green: 0.93, blue: 0.82, alpha: 1)
emerald.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()
let gradient = NSGradient(
  starting: NSColor(red: 0.08, green: 0.29, blue: 0.22, alpha: 1), ending: emerald)!
gradient.draw(in: NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)), angle: -90)
gold.withAlphaComponent(0.45).setStroke()
for inset in [65.0, 81.0] {
  let ring = NSBezierPath(
    roundedRect: NSRect(x: inset, y: inset, width: 1024 - inset * 2, height: 1024 - inset * 2),
    xRadius: 145, yRadius: 145)
  ring.lineWidth = 3
  ring.stroke()
}
func polygon(_ points: [NSPoint], color: NSColor) {
  let path = NSBezierPath()
  path.move(to: points[0])
  for point in points.dropFirst() { path.line(to: point) }
  path.close()
  color.setFill()
  path.fill()
}
func ellipse(_ rect: NSRect, color: NSColor) {
  color.setFill()
  NSBezierPath(ovalIn: rect).fill()
}
let card = NSBezierPath(
  roundedRect: NSRect(x: 290, y: 211, width: 444, height: 607), xRadius: 38, yRadius: 38)
cream.setFill()
card.fill()
gold.setStroke()
card.lineWidth = 6
card.stroke()
polygon(
  [
    .init(x: 359, y: 652), .init(x: 511, y: 578), .init(x: 665, y: 652),
    .init(x: 629, y: 427), .init(x: 511, y: 320), .init(x: 393, y: 427),
  ], color: gold)
polygon([.init(x: 377, y: 621), .init(x: 429, y: 550), .init(x: 398, y: 558)], color: emerald)
polygon([.init(x: 647, y: 621), .init(x: 595, y: 550), .init(x: 626, y: 558)], color: emerald)
ellipse(NSRect(x: 427, y: 474, width: 37, height: 14), color: emerald)
ellipse(NSRect(x: 560, y: 474, width: 37, height: 14), color: emerald)
polygon([.init(x: 493, y: 385), .init(x: 531, y: 385), .init(x: 512, y: 368)], color: emerald)
func letter(_ text: String, at point: NSPoint) {
  let label = NSMutableAttributedString(string: text)
  let range = NSRange(location: 0, length: label.length)
  label.addAttribute(.font, value: NSFont(name: "Baskerville-Bold", size: 57)!, range: range)
  label.addAttribute(.foregroundColor, value: emerald, range: range)
  label.draw(at: point)
}
letter("V", at: NSPoint(x: 325, y: 715))
letter("♣", at: NSPoint(x: 642, y: 228))
for (x, y) in [(207.0, 570.0), (811.0, 460.0)] {
  polygon(
    [
      .init(x: x, y: y + 34), .init(x: x + 9, y: y + 9), .init(x: x + 34, y: y),
      .init(x: x + 9, y: y - 9), .init(x: x, y: y - 34), .init(x: x - 9, y: y - 9),
      .init(x: x - 34, y: y), .init(x: x - 9, y: y + 9),
    ], color: gold)
}
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(
  to: root.appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset/Icon.png"))

let rate = 22050
let length = Int(Double(rate) * 0.16)
var pcm = Data()
for n in 0..<length {
  let t = Double(n) / Double(rate)
  let envelope = exp(-t * 34) * min(1, t * 1000)
  let wave = (sin(2 * .pi * 660 * t) + 0.35 * sin(2 * .pi * 990 * t)) * envelope * 10000
  var sample = Int16(wave).littleEndian
  withUnsafeBytes(of: &sample) { pcm.append(contentsOf: $0) }
}
var wav = Data()
func ascii(_ value: String) { wav.append(contentsOf: value.utf8) }
func uint32(_ value: UInt32) {
  var little = value.littleEndian
  withUnsafeBytes(of: &little) { wav.append(contentsOf: $0) }
}
func uint16(_ value: UInt16) {
  var little = value.littleEndian
  withUnsafeBytes(of: &little) { wav.append(contentsOf: $0) }
}
ascii("RIFF")
uint32(UInt32(pcm.count + 36))
ascii("WAVEfmt ")
uint32(16)
uint16(1)
uint16(1)
uint32(UInt32(rate))
uint32(UInt32(rate * 2))
uint16(2)
uint16(16)
ascii("data")
uint32(UInt32(pcm.count))
wav.append(pcm)
try wav.write(to: root.appendingPathComponent("Resources/deal.wav"))
