import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let assets = root.appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset")
let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8,
  samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
  bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

func color(_ hex: UInt32) -> NSColor {
  NSColor(
    red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
    blue: CGFloat(hex & 255) / 255, alpha: 1
  )
}

func polygon(_ points: [CGPoint], _ fill: UInt32) {
  let path = NSBezierPath()
  path.move(to: points[0])
  for point in points.dropFirst() { path.line(to: point) }
  path.close()
  color(fill).setFill()
  path.fill()
}

NSGradient(colors: [color(0xC99D9D), color(0x254C69), color(0x173B58)])!.draw(
  in: NSRect(x: 0, y: 0, width: 1024, height: 1024), angle: 90
)
color(0xF7D7AA).setFill()
NSBezierPath(ovalIn: CGRect(x: 720, y: 633, width: 115, height: 115)).fill()
polygon(
  [CGPoint(x: -140, y: 225), CGPoint(x: 379, y: 763), CGPoint(x: 884, y: 208)],
  0x7F9EAF
)
polygon(
  [
    CGPoint(x: 379, y: 763), CGPoint(x: 411, y: 583), CGPoint(x: 643, y: 232),
    CGPoint(x: 884, y: 208),
  ], 0x456B89
)
polygon(
  [
    CGPoint(x: 277, y: 657), CGPoint(x: 379, y: 763), CGPoint(x: 493, y: 637),
    CGPoint(x: 396, y: 680), CGPoint(x: 370, y: 628), CGPoint(x: 338, y: 674),
  ], 0xD5E5E8
)
polygon(
  [CGPoint(x: 441, y: 206), CGPoint(x: 786, y: 550), CGPoint(x: 1169, y: 154)],
  0x325770
)
polygon(
  [
    CGPoint(x: 704, y: 470), CGPoint(x: 786, y: 550), CGPoint(x: 885, y: 448),
    CGPoint(x: 793, y: 487), CGPoint(x: 764, y: 447),
  ], 0xA3BDC8
)
let slope = NSBezierPath()
slope.move(to: CGPoint(x: 0, y: 380))
slope.curve(
  to: CGPoint(x: 1024, y: 169), controlPoint1: CGPoint(x: 300, y: 90),
  controlPoint2: CGPoint(x: 670, y: 390)
)
slope.line(to: .init(x: 1024, y: 0))
slope.line(to: .zero)
slope.close()
color(0xE4EEEA).setFill()
slope.fill()
let trail = NSBezierPath()
trail.move(to: CGPoint(x: 71, y: 240))
trail.curve(
  to: CGPoint(x: 646, y: 258), controlPoint1: CGPoint(x: 262, y: 157),
  controlPoint2: CGPoint(x: 443, y: 272)
)
color(0xACC7D1).setStroke()
trail.lineWidth = 6
trail.lineCapStyle = .round
trail.stroke()
let board = NSBezierPath()
board.move(to: CGPoint(x: 615, y: 262))
board.curve(
  to: CGPoint(x: 712, y: 276), controlPoint1: CGPoint(x: 650, y: 248),
  controlPoint2: CGPoint(x: 688, y: 263)
)
color(0x233F53).setStroke()
board.lineWidth = 9
board.lineCapStyle = .round
board.stroke()
polygon(
  [
    CGPoint(x: 643, y: 272), CGPoint(x: 650, y: 311), CGPoint(x: 678, y: 316),
    CGPoint(x: 697, y: 279), CGPoint(x: 685, y: 270), CGPoint(x: 669, y: 293),
    CGPoint(x: 659, y: 268),
  ], 0x233F53
)
polygon(
  [
    CGPoint(x: 647, y: 306), CGPoint(x: 664, y: 357), CGPoint(x: 688, y: 352),
    CGPoint(x: 682, y: 309),
  ], 0xDE8974
)
color(0x233F53).setFill()
NSBezierPath(ovalIn: CGRect(x: 663, y: 353, width: 30, height: 32)).fill()
color(0xF6D5A6).setFill()
NSBezierPath(roundedRect: CGRect(x: 681, y: 361, width: 22, height: 10), xRadius: 5, yRadius: 5)
  .fill()
let scarf = NSBezierPath()
scarf.move(to: CGPoint(x: 665, y: 350))
scarf.curve(
  to: CGPoint(x: 598, y: 355), controlPoint1: CGPoint(x: 640, y: 363),
  controlPoint2: CGPoint(x: 618, y: 345)
)
color(0xF2BE85).setStroke()
scarf.lineWidth = 9
scarf.lineCapStyle = .round
scarf.stroke()
for index in 0..<17 {
  let x = CGFloat((index * 137 + 73) % 950)
  let y = CGFloat((index * 271 + 37) % 530 + 450)
  color(0xD1DCD9).withAlphaComponent(0.5).setFill()
  NSBezierPath(ovalIn: CGRect(x: x, y: y, width: 2.5, height: 2.5)).fill()
}
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(
  to: assets.appendingPathComponent("AppIcon.png"))

func wav(name: String, duration: Double, frequency: Double, kind: Int) throws {
  let rate = 22050
  let frames = Int(duration * Double(rate))
  var samples = Data()
  var noise: UInt64 = 217
  var low = 0.0
  for index in 0..<frames {
    let t = Double(index) / Double(rate)
    let phase = t / duration
    noise = noise &* 6_364_136_223_846_793_005 &+ 1
    let random = Double(noise >> 33) / Double(UInt32.max) * 2 - 0.5
    low = low * 0.97 + random * 0.03
    let envelope = min(1, t * 35) * pow(max(0, 1 - phase), 2.0)
    let wave: Double
    switch kind {
    case 0:
      wave = sin(2 * .pi * (frequency * t + t * t * 220)) * envelope * 0.18
    case 1:
      wave =
        (sin(2 * .pi * frequency * t) + 0.32 * sin(2 * .pi * frequency * 2.5 * t)) * envelope * 0.23
    case 2:
      wave = (sin(2 * .pi * frequency * t) * 0.14 + low * 0.8) * envelope
    default:
      wave = low * 0.65 * (0.6 + 0.2 * sin(t * .pi / 2))
    }
    var sample = Int16(max(-1, min(1, wave)) * 30000).littleEndian
    withUnsafeBytes(of: &sample) { samples.append(contentsOf: $0) }
  }
  var data = Data()
  func word(_ value: UInt16) {
    var little = value.littleEndian
    withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
  }
  func dword(_ value: UInt32) {
    var little = value.littleEndian
    withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
  }
  data.append(Data("RIFF".utf8))
  dword(UInt32(samples.count + 36))
  data.append(Data("WAVEfmt ".utf8))
  dword(16)
  word(1)
  word(1)
  dword(UInt32(rate))
  dword(UInt32(rate * 2))
  word(2)
  word(16)
  data.append(Data("data".utf8))
  dword(UInt32(samples.count))
  data.append(samples)
  try data.write(to: root.appendingPathComponent("Resources/\(name).wav"))
}

try wav(name: "jump", duration: 0.32, frequency: 320, kind: 0)
try wav(name: "coin", duration: 0.22, frequency: 1174.66, kind: 1)
try wav(name: "land", duration: 0.40, frequency: 587.33, kind: 1)
try wav(name: "crash", duration: 0.6, frequency: 95, kind: 2)
try wav(name: "wind", duration: 8, frequency: 0, kind: 3)
print("Generated original Powderline icon and sound assets.")
