import AppKit

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let context = NSGraphicsContext.current!.cgContext
func color(_ hex: UInt32) -> NSColor {
  NSColor(
    red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
    blue: CGFloat(hex & 255) / 255, alpha: 1)
}
func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ hex: UInt32) {
  color(hex).setFill()
  NSBezierPath(ovalIn: CGRect(x: x, y: y, width: w, height: h)).fill()
}
func rect(
  _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ hex: UInt32, _ radius: CGFloat = 0
) {
  color(hex).setFill()
  NSBezierPath(
    roundedRect: CGRect(x: x, y: y, width: w, height: h),
    xRadius: radius, yRadius: radius
  ).fill()
}
let gradient = CGGradient(
  colorsSpace: CGColorSpaceCreateDeviceRGB(),
  colors: [color(0x163B35).cgColor, color(0x729570).cgColor] as CFArray,
  locations: [0, 1])!
context.drawLinearGradient(
  gradient, start: CGPoint(x: 512, y: 1024), end: CGPoint(x: 512, y: 0), options: [])
ellipse(120, 70, 780, 780, 0xB5BC82)
ellipse(142, 93, 735, 735, 0x385F4B)
for i in 0..<9 {
  let x = CGFloat(i) * 140 - 80
  rect(x, 20, 35, 700, 0x244C3D, 16)
  ellipse(x - 100, 650, 255, 210, 0x2C5541)
}
ellipse(180, 64, 680, 145, 0x173D33)
rect(298, 111, 390, 390, 0xC96E44, 160)
rect(336, 136, 318, 52, 0xDAA75F, 16)
rect(255, 225, 115, 230, 0x775C3C, 45)
ellipse(309, 402, 386, 332, 0xF5D29D)
ellipse(279, 480, 81, 99, 0xDFB582)
ellipse(579, 469, 97, 47, 0xD78D71)
ellipse(559, 548, 33, 48, 0x243E32)
ellipse(566, 565, 9, 12, 0xFFF5D7)
ellipse(291, 636, 422, 191, 0x587B4B)
rect(326, 645, 343, 47, 0xC2A367, 15)
ellipse(250, 621, 508, 79, 0x8EA16A)
context.saveGState()
context.translateBy(x: 407, y: 806)
context.rotate(by: 0.35)
ellipse(-31, -12, 65, 180, 0xEDBA6B)
context.restoreGState()
ellipse(322, 381, 63, 59, 0xF2CC7C)
ellipse(689, 223, 68, 150, 0xEACC87)
ellipse(716, 318, 35, 81, 0xFFF0BB)
for i in 0..<7 {
  ellipse(CGFloat(92 + i * 137), CGFloat(700 + (i * 79 % 220)), 9, 9, 0xF3DFA1)
}
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
let png = bitmap.representation(using: .png, properties: [:])!
let destination = URL(fileURLWithPath: CommandLine.arguments[1])
try png.write(to: destination)
