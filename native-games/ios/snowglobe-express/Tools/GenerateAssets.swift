import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let ink = NSColor(srgbRed: 0.045, green: 0.105, blue: 0.12, alpha: 1)
let powder = NSColor(srgbRed: 0.65, green: 0.77, blue: 0.77, alpha: 1)
let cream = NSColor(srgbRed: 0.96, green: 0.94, blue: 0.87, alpha: 1)
let cranberry = NSColor(srgbRed: 0.53, green: 0.15, blue: 0.21, alpha: 1)
let amber = NSColor(srgbRed: 0.83, green: 0.69, blue: 0.43, alpha: 1)
let full = NSBezierPath(rect: CGRect(origin: .zero, size: size))
NSGradient(starting: ink, ending: NSColor(srgbRed: 0.16, green: 0.28, blue: 0.29, alpha: 1))!
  .draw(in: full, angle: 45)

func fill(_ path: NSBezierPath, _ color: NSColor) {
  color.setFill()
  path.fill()
}
func round(_ rect: CGRect, _ radius: CGFloat, _ color: NSColor) {
  fill(NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius), color)
}
func polygon(_ points: [CGPoint], _ color: NSColor) {
  let path = NSBezierPath()
  path.move(to: points[0])
  for point in points.dropFirst() { path.line(to: point) }
  path.close()
  fill(path, color)
}
let globe = NSBezierPath(ovalIn: CGRect(x: 110, y: 135, width: 804, height: 804))
fill(globe, powder.withAlphaComponent(0.12))
powder.withAlphaComponent(0.8).setStroke()
globe.lineWidth = 5
globe.stroke()
let glint = NSBezierPath()
glint.appendArc(withCenter: CGPoint(x: 512, y: 537), radius: 380, startAngle: 115, endAngle: 155)
NSColor.white.withAlphaComponent(0.7).setStroke()
glint.lineWidth = 13
glint.lineCapStyle = .round
glint.stroke()
fill(NSBezierPath(ovalIn: CGRect(x: 164, y: 241, width: 696, height: 316)), powder)
fill(NSBezierPath(ovalIn: CGRect(x: 165, y: 258, width: 694, height: 310)), cream)

func house(x: CGFloat, y: CGFloat, scale: CGFloat, red: Bool) {
  let s = scale
  round(CGRect(x: x, y: y, width: 160 * s, height: 158 * s), 8, cream)
  round(CGRect(x: x + 123 * s, y: y + 9 * s, width: 30 * s, height: 145 * s), 2, powder)
  polygon(
    [
      CGPoint(x: x - 24 * s, y: y + 146 * s),
      CGPoint(x: x + 77 * s, y: y + 254 * s),
      CGPoint(x: x + 183 * s, y: y + 146 * s),
    ], red ? cranberry : ink)
  polygon(
    [
      CGPoint(x: x - 24 * s, y: y + 153 * s),
      CGPoint(x: x + 77 * s, y: y + 266 * s),
      CGPoint(x: x + 188 * s, y: y + 153 * s),
      CGPoint(x: x + 152 * s, y: y + 160 * s),
      CGPoint(x: x + 77 * s, y: y + 238 * s),
      CGPoint(x: x + 3 * s, y: y + 160 * s),
    ], .white)
  for dx: CGFloat in [25, 103] {
    round(CGRect(x: x + dx * s, y: y + 66 * s, width: 32 * s, height: 46 * s), 4, amber)
  }
  round(CGRect(x: x + 69 * s, y: y, width: 30 * s, height: 58 * s), 4, cranberry)
}
house(x: 354, y: 450, scale: 1.05, red: true)
house(x: 620, y: 397, scale: 0.8, red: false)
for tree in 0..<3 {
  let x = CGFloat(230 + tree * 36)
  let y = CGFloat(420 + tree * 65)
  polygon(
    [
      CGPoint(x: x - 54, y: y), CGPoint(x: x, y: y + 173), CGPoint(x: x + 54, y: y),
    ], ink)
  polygon(
    [
      CGPoint(x: x - 32, y: y + 70), CGPoint(x: x, y: y + 180), CGPoint(x: x + 32, y: y + 70),
    ], .white)
}
fill(NSBezierPath(ovalIn: CGRect(x: 310, y: 296, width: 85, height: 85)), ink)
fill(NSBezierPath(ovalIn: CGRect(x: 538, y: 296, width: 85, height: 85)), ink)
round(CGRect(x: 275, y: 344, width: 367, height: 168), 43, cranberry)
round(CGRect(x: 277, y: 494, width: 264, height: 28), 12, cream)
round(CGRect(x: 533, y: 424, width: 82, height: 65), 10, powder)
round(CGRect(x: 356, y: 390, width: 63, height: 53), 4, cream)
round(CGRect(x: 383, y: 390, width: 8, height: 53), 1, cranberry)
round(CGRect(x: 639, y: 315, width: 53, height: 99), 12, powder)
round(CGRect(x: 600, y: 363, width: 38, height: 25), 8, amber)
round(
  CGRect(x: 253, y: 115, width: 518, height: 79), 18,
  NSColor(srgbRed: 0.65, green: 0.48, blue: 0.3, alpha: 1))
round(CGRect(x: 240, y: 182, width: 544, height: 26), 9, cream)
for index in 0..<42 {
  let x = CGFloat(180 + (index * 127) % 656)
  let y = CGFloat(580 + (index * 53) % 240)
  fill(
    NSBezierPath(
      ovalIn: CGRect(x: x, y: y, width: index % 3 == 0 ? 7 : 4, height: index % 3 == 0 ? 7 : 4)),
    .white.withAlphaComponent(0.6))
}
image.unlockFocus()
let tiff = image.tiffRepresentation!
let bitmap = NSBitmapImageRep(data: tiff)!
let png = bitmap.representation(using: .png, properties: [:])!
try png.write(
  to: root.appendingPathComponent("SnowglobeExpress/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
)

var pcm = Data()
let sampleRate = 22_050
for index in 0..<Int(Double(sampleRate) * 0.65) {
  let t = Double(index) / Double(sampleRate)
  let wave = (sin(t * 2 * .pi * 784) + sin(t * 2 * .pi * 1174) * 0.4) * exp(-t * 7)
  var sample = Int16(wave * 8_000).littleEndian
  withUnsafeBytes(of: &sample) { pcm.append(contentsOf: $0) }
}
var wav = Data()
func appendString(_ value: String) { wav.append(contentsOf: value.utf8) }
func append32(_ value: UInt32) {
  var little = value.littleEndian
  withUnsafeBytes(of: &little) { wav.append(contentsOf: $0) }
}
func append16(_ value: UInt16) {
  var little = value.littleEndian
  withUnsafeBytes(of: &little) { wav.append(contentsOf: $0) }
}
appendString("RIFF")
append32(UInt32(pcm.count + 36))
appendString("WAVEfmt ")
append32(16)
append16(1)
append16(1)
append32(UInt32(sampleRate))
append32(UInt32(sampleRate * 2))
append16(2)
append16(16)
appendString("data")
append32(UInt32(pcm.count))
wav.append(pcm)
try wav.write(to: root.appendingPathComponent("SnowglobeExpress/delivery.wav"))
print("Generated icon and delivery chime.")
