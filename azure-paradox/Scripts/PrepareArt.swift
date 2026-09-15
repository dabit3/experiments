import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
  fatalError("Usage: swift PrepareArt.swift source.png outputDirectory character")
}
let image = NSImage(contentsOfFile: arguments[1])!
var rect = NSRect(origin: .zero, size: image.size)
let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
let width = cg.width
let height = cg.height
let context = CGContext(
  data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!
context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
let pixels = context.data!.bindMemory(to: UInt8.self, capacity: width * height * 4)
for offset in stride(from: 0, to: width * height * 4, by: 4) {
  let red = Double(pixels[offset])
  let green = Double(pixels[offset + 1])
  let blue = Double(pixels[offset + 2])
  if green > 80 && green > red * 1.22 && green > blue * 1.18 {
    pixels[offset] = 0
    pixels[offset + 1] = 0
    pixels[offset + 2] = 0
    pixels[offset + 3] = 0
  }
}
let cleaned = context.makeImage()!
let sourceRects: [CGRect]
if arguments[3] == "seraph" {
  sourceRects = [
    CGRect(x: 10, y: 8, width: 367, height: 444),
    CGRect(x: 386, y: 40, width: 372, height: 410),
    CGRect(x: 762, y: 6, width: 354, height: 445),
    CGRect(x: 1115, y: 5, width: 410, height: 408),
    CGRect(x: 6, y: 556, width: 450, height: 420),
    CGRect(x: 385, y: 568, width: 405, height: 409),
    CGRect(x: 778, y: 459, width: 350, height: 520),
    CGRect(x: 1146, y: 424, width: 352, height: 553),
  ]
} else {
  sourceRects = [
    CGRect(x: 8, y: 17, width: 333, height: 432),
    CGRect(x: 344, y: 40, width: 392, height: 410),
    CGRect(x: 748, y: 55, width: 352, height: 399),
    CGRect(x: 1129, y: 35, width: 400, height: 368),
    CGRect(x: 4, y: 542, width: 403, height: 402),
    CGRect(x: 300, y: 617, width: 521, height: 331),
    CGRect(x: 770, y: 461, width: 321, height: 490),
    CGRect(x: 1084, y: 498, width: 441, height: 453),
  ]
}
for (index, crop) in sourceRects.enumerated() {
  let cropped = cleaned.cropping(to: crop)!
  let output = NSBitmapImageRep(cgImage: cropped)
  try output.representation(using: .png, properties: [:])!.write(
    to: URL(fileURLWithPath: arguments[2]).appendingPathComponent("\(arguments[3])-\(index).png"))
}
