import AppKit

let size = 1024
let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: size * 4, bitsPerPixel: 32)!
let graphics = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics
let context = graphics.cgContext
context.setFillColor(NSColor(red: 0.025, green: 0.10, blue: 0.13, alpha: 1).cgColor)
context.fill(CGRect(x: 0, y: 0, width: size, height: size))
let colors =
    [
        NSColor(red: 0.10, green: 0.34, blue: 0.37, alpha: 1).cgColor,
        NSColor(red: 0.025, green: 0.10, blue: 0.13, alpha: 1).cgColor,
    ] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
context.drawRadialGradient(
    gradient, startCenter: CGPoint(x: 440, y: 700), startRadius: 0,
    endCenter: CGPoint(x: 440, y: 700), endRadius: 820, options: [])
let gold = NSColor(red: 0.84, green: 0.70, blue: 0.45, alpha: 1)
context.setStrokeColor(gold.withAlphaComponent(0.6).cgColor)
context.setLineWidth(2)
context.stroke(CGRect(x: 70, y: 70, width: 884, height: 884))
context.setLineWidth(18)
context.setLineCap(.round)
context.setStrokeColor(gold.cgColor)
context.move(to: CGPoint(x: 135, y: 180))
context.addLine(to: CGPoint(x: 803, y: 848))
context.strokePath()
context.setShadow(
    offset: CGSize(width: 10, height: -20), blur: 35, color: NSColor.black.withAlphaComponent(0.6).cgColor)
context.setFillColor(NSColor(red: 0.035, green: 0.045, blue: 0.06, alpha: 1).cgColor)
let ball = CGRect(x: 248, y: 248, width: 528, height: 528)
context.fillEllipse(in: ball)
context.setShadow(offset: .zero, blur: 0)
context.saveGState()
context.addEllipse(in: ball)
context.clip()
let ballGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        NSColor(red: 0.28, green: 0.34, blue: 0.39, alpha: 1).cgColor,
        NSColor(red: 0.015, green: 0.025, blue: 0.035, alpha: 1).cgColor,
    ] as CFArray, locations: [0, 1])!
context.drawRadialGradient(
    ballGradient, startCenter: CGPoint(x: 404, y: 681), startRadius: 5,
    endCenter: CGPoint(x: 430, y: 600), endRadius: 430, options: [])
context.restoreGState()
context.setFillColor(NSColor(red: 0.96, green: 0.94, blue: 0.86, alpha: 1).cgColor)
context.fillEllipse(in: CGRect(x: 380, y: 380, width: 264, height: 264))
let number = NSAttributedString(
    string: "8",
    attributes: [
        .font: NSFont.systemFont(ofSize: 213, weight: .medium),
        .foregroundColor: NSColor(red: 0.035, green: 0.055, blue: 0.075, alpha: 1),
    ])
number.draw(at: CGPoint(x: 512 - number.size().width / 2, y: 512 - number.size().height / 2 + 4))
let title = NSAttributedString(
    string: "M I D N I G H T",
    attributes: [.font: NSFont.systemFont(ofSize: 38, weight: .medium), .foregroundColor: gold])
title.draw(at: CGPoint(x: 512 - title.size().width / 2, y: 132))
NSGraphicsContext.restoreGraphicsState()
let output = CommandLine.arguments.dropFirst().first ?? "Assets.xcassets/AppIcon.appiconset/AppIcon.png"
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
