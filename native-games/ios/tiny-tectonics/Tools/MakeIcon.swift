import AppKit

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
func color(_ hex: UInt32) -> NSColor {
  NSColor(
    red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
    blue: CGFloat(hex & 255) / 255, alpha: 1)
}
func shape(_ points: [CGPoint], _ fill: UInt32) {
  let path = NSBezierPath()
  path.move(to: points[0])
  for point in points.dropFirst() { path.line(to: point) }
  path.close()
  color(fill).setFill()
  path.fill()
}
color(0xF4EFDF).setFill()
NSBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
let river = NSBezierPath()
river.move(to: CGPoint(x: 0, y: 340))
river.curve(
  to: CGPoint(x: 1050, y: 220), controlPoint1: CGPoint(x: 740, y: 560),
  controlPoint2: CGPoint(x: 300, y: 20))
river.lineWidth = 140
color(0x86C5BA).setStroke()
river.stroke()
for (index, center) in [CGPoint(x: 340, y: 620), CGPoint(x: 530, y: 450), CGPoint(x: 720, y: 280)]
  .enumerated()
{
  let w: CGFloat = 205
  let h: CGFloat = 103
  let depth: CGFloat = CGFloat(135 - index * 25)
  let n = CGPoint(x: center.x, y: center.y + h)
  let e = CGPoint(x: center.x + w, y: center.y)
  let s = CGPoint(x: center.x, y: center.y - h)
  let west = CGPoint(x: center.x - w, y: center.y)
  shape(
    [west, s, CGPoint(x: s.x, y: s.y - depth), CGPoint(x: west.x, y: west.y - depth)], 0xB65032)
  shape([s, e, CGPoint(x: e.x, y: e.y - depth), CGPoint(x: s.x, y: s.y - depth)], 0xD98B61)
  for band in 1...3 {
    let path = NSBezierPath()
    let dy = depth * CGFloat(band) / 4
    path.move(to: CGPoint(x: west.x, y: west.y - dy))
    path.line(to: CGPoint(x: s.x, y: s.y - dy))
    path.line(to: CGPoint(x: e.x, y: e.y - dy))
    color(0xE4B080).setStroke()
    path.lineWidth = 8
    path.stroke()
  }
  shape([n, e, s, west], 0xE7CC97)
  for inset in 1...3 {
    let ratio = 1 - CGFloat(inset) * 0.2
    let contour = NSBezierPath()
    contour.move(to: CGPoint(x: center.x, y: center.y + h * ratio))
    contour.line(to: CGPoint(x: center.x + w * ratio, y: center.y))
    contour.line(to: CGPoint(x: center.x, y: center.y - h * ratio))
    contour.line(to: CGPoint(x: center.x - w * ratio, y: center.y))
    contour.close()
    color(0xB69B66).withAlphaComponent(0.45).setStroke()
    contour.lineWidth = 2
    contour.stroke()
  }
  let tree = CGPoint(x: center.x - 100, y: center.y + 20)
  shape(
    [
      CGPoint(x: tree.x - 28, y: tree.y), CGPoint(x: tree.x + 28, y: tree.y),
      CGPoint(x: tree.x, y: tree.y + 100),
    ], 0x466E55)
}
let track = NSBezierPath()
track.move(to: CGPoint(x: 340, y: 620))
track.line(to: CGPoint(x: 530, y: 450))
track.line(to: CGPoint(x: 720, y: 280))
track.lineWidth = 28
color(0xFFF3D4).setStroke()
track.stroke()
let stone = NSBezierPath(ovalIn: CGRect(x: 280, y: 595, width: 115, height: 115))
color(0xFFFFFF).setFill()
stone.fill()
color(0xB65032).setFill()
NSBezierPath(ovalIn: CGRect(x: 300, y: 648, width: 22, height: 22)).fill()
let portal = NSBezierPath(ovalIn: CGRect(x: 679, y: 270, width: 82, height: 120))
portal.lineWidth = 20
color(0x258F88).setStroke()
portal.stroke()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
let png = bitmap.representation(using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
