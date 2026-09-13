import AppKit

// 8-bit app icon: a 32x32 pixel citrus slice and blade streak scaled 32x with hard edges.
let side = 1024
let grid = 32
let cell = CGFloat(side / grid)
let c = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
c.setShouldAntialias(false)

func rgb(_ r: Double, _ g: Double, _ b: Double) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: 1)
}

let navy = rgb(0.047, 0.047, 0.24), sky = rgb(0.36, 0.58, 0.99)
let white = rgb(0.988, 0.988, 0.988), black = rgb(0, 0, 0), orange = rgb(0.99, 0.6, 0.22)
let yellow = rgb(0.99, 0.88, 0), cream = rgb(0.99, 0.9, 0.66), green = rgb(0, 0.66, 0), darkGreen = rgb(0, 0.42, 0)

func color(_ x: Int, _ y: Int) -> CGColor {
    let stars: Set<[Int]> = [[3, 4], [27, 6], [6, 26], [25, 27], [14, 2], [29, 18], [2, 16]]
    if stars.contains([x, y]) {
        return white
    }
    let dx = Double(x) - 15.5, dy = Double(y) - 16.5
    let d = (dx * dx + dy * dy).squareRoot()
    let radius = 11.5
    // Blade streak: a stepped diagonal that passes behind the fruit.
    let onBlade = abs(Double(x) + Double(y) - 31) < 1.6 && d > radius + 1
    if onBlade {
        return white
    }
    if abs(Double(x) + Double(y) - 31) < 3, d > radius + 1 {
        return sky
    }
    if y < 5, d > radius {
        let leaf: Set<[Int]> = [[16, 4], [17, 4], [18, 3], [19, 3], [20, 2], [21, 2], [19, 2]]
        if leaf.contains([x, y]) {
            return green
        }
        if [[18, 4], [20, 3], [22, 1]].contains([x, y]) {
            return darkGreen
        }
        if [[15, 4], [22, 2], [23, 1], [19, 1], [21, 1]].contains([x, y]) {
            return black
        }
    }
    if d > radius + 1 {
        return navy
    }
    if d > radius {
        return black
    }
    let lit = dx + dy < -7
    if d > radius - 1.6 {
        return lit ? white : orange
    }
    if d > radius - 2.8 {
        return cream
    }
    let angle = atan2(dy, dx)
    let seg = angle / (.pi / 5)
    if abs(seg - seg.rounded()) < 0.09, d > 2.4 {
        return orange
    }
    if d < 1.8 {
        return cream
    }
    if dx + dy > 7, (x + y) % 2 == 0 {
        return orange
    }
    return yellow
}

for y in 0 ..< grid {
    for x in 0 ..< grid {
        c.setFillColor(color(x, y))
        c.fill(CGRect(x: CGFloat(x) * cell, y: CGFloat(grid - 1 - y) * cell, width: cell, height: cell))
    }
}

let bitmap = NSBitmapImageRep(cgImage: c.makeImage()!)
let data = bitmap.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
