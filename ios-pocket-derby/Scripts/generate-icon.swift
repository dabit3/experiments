import AppKit

let destination = CommandLine.arguments[1]
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
func color(_ hex: UInt32) -> NSColor {
    NSColor(
        red: CGFloat((hex >> 16) & 255) / 255,
        green: CGFloat((hex >> 8) & 255) / 255,
        blue: CGFloat(hex & 255) / 255,
        alpha: 1
    )
}

func rounded(_ rect: NSRect, _ radius: CGFloat, _ fill: UInt32) {
    color(fill).setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

let gradient = NSGradient(starting: color(0x254E61), ending: color(0x091E30))!
gradient.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024), angle: 75)
rounded(NSRect(x: 65, y: 130, width: 894, height: 764), 115, 0x102D3B)
rounded(NSRect(x: 88, y: 155, width: 848, height: 720), 95, 0x2F766F)
for index in 0 ..< 6 {
    rounded(NSRect(x: 102 + index * 139, y: 167, width: 69, height: 693), 0, 0x327D74)
}

color(0x83BCA5).setStroke()
let ring = NSBezierPath(ovalIn: NSRect(x: 345, y: 347, width: 334, height: 334))
ring.lineWidth = 8
ring.stroke()
let midline = NSBezierPath()
midline.move(to: NSPoint(x: 512, y: 165))
midline.line(to: NSPoint(x: 512, y: 860))
midline.lineWidth = 6
midline.stroke()
rounded(NSRect(x: 66, y: 342, width: 39, height: 340), 15, 0x65E4FF)
rounded(NSRect(x: 919, y: 342, width: 39, height: 340), 15, 0xFF8865)
NSGraphicsContext.saveGraphicsState()
let transform = NSAffineTransform()
transform.translateX(by: 430, yBy: 407)
transform.rotate(byDegrees: 26)
transform.concat()
for index in 0 ..< 3 {
    rounded(NSRect(x: -305 - index * 53, y: -55 + index * 32, width: 182, height: 19), 9, 0x49C8D8)
}

rounded(NSRect(x: -210, y: -115, width: 440, height: 224), 75, 0x143941)
for x in [-134, 118] {
    rounded(NSRect(x: x, y: -117, width: 72, height: 56), 18, 0x081D2B)
    rounded(NSRect(x: x, y: 76, width: 72, height: 56), 18, 0x081D2B)
}

rounded(NSRect(x: -201, y: -91, width: 416, height: 201), 66, 0x3A99BD)
rounded(NSRect(x: -204, y: -63, width: 416, height: 184), 62, 0x65E4FF)
rounded(NSRect(x: -95, y: -43, width: 212, height: 142), 36, 0x173C51)
rounded(NSRect(x: -77, y: -31, width: 123, height: 118), 24, 0xA0EEED)
rounded(NSRect(x: 65, y: -17, width: 36, height: 91), 11, 0xD4FCF2)
rounded(NSRect(x: -216, y: -93, width: 38, height: 212), 9, 0xB5FAF4)
rounded(NSRect(x: 173, y: -33, width: 39, height: 28), 8, 0xFFFFD7)
rounded(NSRect(x: 173, y: 65, width: 39, height: 28), 8, 0xFFFFD7)
NSGraphicsContext.restoreGraphicsState()
color(0x163A43).setFill()
NSBezierPath(ovalIn: NSRect(x: 626, y: 550, width: 232, height: 174)).fill()
color(0xF6F3DD).setFill()
NSBezierPath(ovalIn: NSRect(x: 607, y: 596, width: 229, height: 229)).fill()
let pentagon = NSBezierPath()
for index in 0 ..< 5 {
    let a = Double(index) * 2 * Double.pi / 5 + .pi / 2
    let point = NSPoint(x: 721 + cos(a) * 46, y: 710 + sin(a) * 46)
    if index == 0 {
        pentagon.move(to: point)
    } else {
        pentagon.line(to: point)
    }
}

pentagon.close()
color(0x2C4C59).setFill()
pentagon.fill()
for index in 0 ..< 5 {
    let a = Double(index) * 2 * Double.pi / 5 + .pi / 2
    let line = NSBezierPath()
    line.move(to: NSPoint(x: 721 + cos(a) * 46, y: 710 + sin(a) * 46))
    line.line(to: NSPoint(x: 721 + cos(a) * 112, y: 710 + sin(a) * 112))
    line.lineWidth = 6
    color(0x64817F).setStroke()
    line.stroke()
}

image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination))
