import AppKit
import SwiftUI

@main
struct IconGenerator {
  @MainActor static func main() {
    let image = ImageRenderer(
      content: ZStack {
        LinearGradient(
          colors: [Palette.ink, Palette.sky], startPoint: .topLeading, endPoint: .bottomTrailing)
        Circle().fill(Palette.cream.opacity(0.07)).frame(width: 830, height: 830).offset(y: 30)
        Circle().stroke(Palette.cream.opacity(0.12), lineWidth: 3).frame(width: 820, height: 820)
          .offset(y: 30)
        RaccoonArt(snacks: 2).frame(width: 900, height: 900).offset(x: -10, y: 40)
      }
      .frame(width: 1024, height: 1024))
    image.scale = 1
    guard let cgImage = image.cgImage,
      let data = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:])
    else { fatalError("Could not render icon") }
    do {
      try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    } catch {
      fatalError("Could not write icon: \(error)")
    }
  }
}
