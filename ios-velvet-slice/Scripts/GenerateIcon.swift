import AppKit

let side = 1024
let c = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
c.setFillColor(NSColor(red: 0.025, green: 0.07, blue: 0.12, alpha: 1).cgColor)
c.fill(CGRect(x: 0, y: 0, width: side, height: side))
c.translateBy(x: 512, y: 510)
c.setShadow(offset: CGSize(width: 0, height: -30), blur: 65, color: NSColor.black.cgColor)
c.setFillColor(NSColor(red: 1, green: 0.51, blue: 0.14, alpha: 1).cgColor)
c.fillEllipse(in: CGRect(x: -310, y: -310, width: 620, height: 620))
c.setShadow(offset: .zero, blur: 0)
c.setFillColor(NSColor(red: 1, green: 0.93, blue: 0.71, alpha: 1).cgColor)
c.fillEllipse(in: CGRect(x: -287, y: -287, width: 574, height: 574))
c.saveGState()
c.addEllipse(in: CGRect(x: -265, y: -265, width: 530, height: 530))
c.clip()
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
    NSColor(red: 1, green: 0.8, blue: 0.29, alpha: 1).cgColor,
    NSColor(red: 0.98, green: 0.34, blue: 0.06, alpha: 1).cgColor,
] as CFArray, locations: [0, 1])!
c.drawLinearGradient(gradient, start: CGPoint(x: -150, y: 220), end: CGPoint(x: 160, y: -230), options: .drawsAfterEndLocation)
for i in 0 ..< 10 {
    c.saveGState()
    c.rotate(by: CGFloat(i) * .pi / 5)
    c.setStrokeColor(NSColor(red: 1, green: 0.94, blue: 0.71, alpha: 1).cgColor)
    c.setLineWidth(10)
    c.move(to: .zero)
    c.addLine(to: CGPoint(x: 270, y: 0))
    c.strokePath()
    for j in 0 ..< 7 {
        c.setFillColor(NSColor.white.withAlphaComponent(0.19).cgColor)
        c.fillEllipse(in: CGRect(x: 80 + j * 21, y: 20 + j % 2 * 20, width: 25, height: 10))
    }
    c.restoreGState()
}

c.restoreGState()
c.setFillColor(NSColor(red: 0.4, green: 0.76, blue: 0.36, alpha: 1).cgColor)
c.move(to: CGPoint(x: 0, y: 290))
c.addQuadCurve(to: CGPoint(x: 215, y: 405), control: CGPoint(x: 60, y: 480))
c.addQuadCurve(to: CGPoint(x: 0, y: 290), control: CGPoint(x: 160, y: 267))
c.fillPath()
c.setStrokeColor(NSColor(red: 0.78, green: 1, blue: 0.89, alpha: 1).cgColor)
c.setShadow(offset: .zero, blur: 18, color: NSColor(red: 0.5, green: 1, blue: 0.8, alpha: 1).cgColor)
c.setLineWidth(11)
c.setLineCap(.round)
c.move(to: CGPoint(x: -405, y: -310))
c.addQuadCurve(to: CGPoint(x: 417, y: 250), control: CGPoint(x: 80, y: -110))
c.strokePath()
let bitmap = NSBitmapImageRep(cgImage: c.makeImage()!)
let data = bitmap.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
