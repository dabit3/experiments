import AppKit

let size = 1024
guard let canvas = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)
else { fatalError("Could not create icon canvas") }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: canvas, flipped: false)
let mint = NSColor(calibratedRed: 0.68, green: 0.86, blue: 0.73, alpha: 1)
let dark = NSColor(calibratedRed: 0.12, green: 0.27, blue: 0.25, alpha: 1)
let yellow = NSColor(calibratedRed: 1, green: 0.77, blue: 0.20, alpha: 1)
let coral = NSColor(calibratedRed: 0.94, green: 0.39, blue: 0.31, alpha: 1)
mint.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

func poly(_ points: [NSPoint], _ color: NSColor) {
    let path = NSBezierPath()
    path.move(to: points[0])
    for point in points.dropFirst() {
        path.line(to: point)
    }
    path.close()
    color.setFill()
    path.fill()
}

func point(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> NSPoint {
    NSPoint(x: 505 + (x - y) * 135, y: 270 + (x + y) * 65 + z * 140)
}

func block(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat, _ w: CGFloat, _ d: CGFloat, _ h: CGFloat, _ color: NSColor) {
    poly(
        [point(x, y, z), point(x + w, y, z), point(x + w, y, z + h), point(x, y, z + h)],
        color.blended(withFraction: 0.13, of: .black) ?? color
    )
    poly(
        [point(x, y, z), point(x, y + d, z), point(x, y + d, z + h), point(x, y, z + h)],
        color.blended(withFraction: 0.24, of: .black) ?? color
    )
    poly(
        [point(x, y, z + h), point(x + w, y, z + h), point(x + w, y + d, z + h), point(x, y + d, z + h)],
        color
    )
}

block(-2.7, -2.4, -0.18, 5.4, 5.0, 0.22, NSColor(calibratedRed: 0.48, green: 0.71, blue: 0.51, alpha: 1))
block(-2.7, 1.4, 0.05, 5.4, 1.15, 0.035, NSColor(calibratedRed: 0.28, green: 0.67, blue: 0.68, alpha: 1))
block(-2.7, -2.4, 0.05, 5.4, 0.85, 0.035, NSColor(calibratedRed: 0.34, green: 0.43, blue: 0.43, alpha: 1))
for x: CGFloat in [-2, -1, 0, 1, 2] {
    block(x, -2.05, 0.09, 0.35, 0.06, 0.015, .white)
}

block(-0.5, -0.38, 0.1, 0.4, 0.63, 0.12, coral)
block(0.45, -0.38, 0.1, 0.4, 0.63, 0.12, coral)
block(-0.82, -0.36, 0.24, 1.78, 1.65, 1.18, yellow)
block(-0.98, -0.25, 0.58, 0.18, 1.08, 0.57, yellow)
block(-0.50, -0.55, 1.39, 1.32, 1.07, 1.20, yellow)
block(-0.40, -1.15, 1.42, 1.10, 0.63, 0.25, coral)
block(-0.44, -0.57, 2.15, 0.14, 0.035, 0.17, dark)
block(0.53, -0.57, 2.15, 0.14, 0.035, 0.17, dark)
block(-2, 0.45, 0.05, 0.11, 0.11, 0.46, dark)
block(-2.13, 0.32, 0.48, 0.36, 0.36, 0.1, coral)
block(-1.8, -1.1, 0.05, 0.11, 0.11, 0.32, dark)
block(-1.93, -1.23, 0.35, 0.36, 0.36, 0.1, .white)
NSGraphicsContext.restoreGraphicsState()
guard let rendered = canvas.makeImage(),
      let data = NSBitmapImageRep(cgImage: rendered).representation(using: .png, properties: [:])
else { fatalError("Could not render icon") }
let destination = CommandLine.arguments[1]
try data.write(to: URL(fileURLWithPath: destination))
