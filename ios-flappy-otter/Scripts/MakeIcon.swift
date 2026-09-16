import AppKit
import Foundation

let image = NSImage(size: CGSize(width: 1024, height: 1024))
let otterURL = URL(fileURLWithPath: "App/Assets.xcassets/Otter.imageset/Otter.png")
guard let otter = NSImage(contentsOf: otterURL) else {
  fatalError("Missing supplied otter artwork")
}
image.lockFocus()
NSColor(red: 0.84, green: 0.92, blue: 0.84, alpha: 1).setFill()
NSBezierPath(rect: CGRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
NSColor(red: 1, green: 0.97, blue: 0.86, alpha: 1).setFill()
NSBezierPath(ovalIn: CGRect(x: 92, y: 92, width: 840, height: 840)).fill()
NSColor(red: 0.26, green: 0.57, blue: 0.51, alpha: 1).setFill()
let river = NSBezierPath()
river.move(to: CGPoint(x: 0, y: 0))
river.line(to: CGPoint(x: 0, y: 200))
river.curve(
  to: CGPoint(x: 1024, y: 215), controlPoint1: CGPoint(x: 300, y: 300),
  controlPoint2: CGPoint(x: 700, y: 90))
river.line(to: CGPoint(x: 1024, y: 0))
river.close()
river.fill()
otter.draw(in: CGRect(x: 99, y: 135, width: 826, height: 756))
image.unlockFocus()
guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else { fatalError("Could not render app icon") }
try png.write(to: URL(fileURLWithPath: "App/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))
