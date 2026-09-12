import AppKit
import Foundation

struct AssetCatalog: Encodable {
  struct Image: Encodable {
    let filename: String
    let idiom = "universal"
  }
  struct Info: Encodable {
    let author = "xcode"
    let version = 1
  }
  let images: [Image]
  let info = Info()
}

enum ImportError: Error {
  case invalidArguments
  case invalidImage
  case emptySprite
}

guard CommandLine.arguments.count == 7 else {
  print("Usage: swift Tools/ImportSprites.swift atlas.png asset-directory Name1 Name2 Name3 Name4")
  throw ImportError.invalidArguments
}
let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
guard
  let source = NSImage(contentsOf: sourceURL)?.cgImage(
    forProposedRect: nil, context: nil, hints: nil)
else { throw ImportError.invalidImage }
let width = source.width / 2
let height = source.height / 2
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

for index in 0..<4 {
  let name = CommandLine.arguments[index + 3]
  guard
    let tile = source.cropping(
      to: CGRect(x: index % 2 * width, y: index / 2 * height, width: width, height: height))
  else { throw ImportError.invalidImage }
  var pixels = [UInt8](repeating: 0, count: width * height * 4)
  let sprite: CGImage = try pixels.withUnsafeMutableBytes { bytes in
    guard
      let context = CGContext(
        data: bytes.baseAddress, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { throw ImportError.invalidImage }
    context.draw(tile, in: CGRect(x: 0, y: 0, width: width, height: height))
    let data = bytes.bindMemory(to: UInt8.self)
    var minX = width
    var minY = height
    var maxX = 0
    var maxY = 0
    for y in 0..<height {
      for x in 0..<width {
        let offset = (y * width + x) * 4
        let red = Int(data[offset])
        let green = Int(data[offset + 1])
        let blue = Int(data[offset + 2])
        if min(red, blue) - green > 55 {
          for channel in 0..<4 { data[offset + channel] = 0 }
        } else if data[offset + 3] > 0 {
          minX = min(minX, x)
          minY = min(minY, y)
          maxX = max(maxX, x)
          maxY = max(maxY, y)
        }
      }
    }
    guard minX < maxX, minY < maxY else { throw ImportError.emptySprite }
    guard
      let image = context.makeImage()?.cropping(
        to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))
    else { throw ImportError.invalidImage }
    return image
  }
  let folder = outputURL.appendingPathComponent("\(name).imageset")
  try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  let filename = "\(name).png"
  guard let png = NSBitmapImageRep(cgImage: sprite).representation(using: .png, properties: [:])
  else { throw ImportError.invalidImage }
  try png.write(to: folder.appendingPathComponent(filename))
  try encoder.encode(AssetCatalog(images: [.init(filename: filename)]))
    .write(to: folder.appendingPathComponent("Contents.json"))
  print("\(name): \(sprite.width)×\(sprite.height)")
}
