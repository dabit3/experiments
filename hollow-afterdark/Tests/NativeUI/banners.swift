import AppKit
import Foundation

struct Caption: Decodable {
  let text: String

  init(from decoder: Decoder) throws {
    var values = try decoder.unkeyedContainer()
    _ = try values.decode(Double.self)
    _ = try values.decode(Double.self)
    text = try values.decode(String.self)
  }
}

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let captions = try JSONDecoder().decode(
  [Caption].self, from: Data(contentsOf: root.appendingPathComponent("captions.json")))
func text(_ s: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: NSColor) {
  (s as NSString).draw(
    at: NSPoint(x: x, y: y),
    withAttributes: [
      .font: NSFont.systemFont(ofSize: size, weight: .medium), .foregroundColor: color,
    ])
}
for (i, row) in captions.enumerated() {
  let image = NSImage(size: NSSize(width: 1840, height: 660))
  image.lockFocus()
  NSColor(calibratedRed: 0.04, green: 0.03, blue: 0.08, alpha: 1).setFill()
  NSRect(x: 0, y: 0, width: 1840, height: 660).fill()
  text(
    "HOLLOW AFTERDARK / NATIVE CONTROLS / SCRIPTED UI - ALTERNATING DEVICES", 20, 625, 24, .white)
  text("REN / iPhone 17 / IN-APP DRIVER OFF", 20, 602, 18, .systemPink)
  text("AYA / iPhone 17 Pro / IN-APP DRIVER OFF", 940, 602, 18, .systemCyan)
  text(row.text, 20, 34, 22, .white)
  text(
    "One host pointer, not two humans | live AudioQueue sound | host-clock aligned | no added soundtrack",
    20, 10, 16, .lightGray)
  image.unlockFocus()
  let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
  try bitmap.representation(using: .png, properties: [:])!.write(
    to: root.appendingPathComponent(String(format: "banner-%02d.png", i)))
}
