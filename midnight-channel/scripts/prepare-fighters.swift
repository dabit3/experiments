import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Figure {
  let pixels: [Int]
  let left: Int
  let top: Int
  let right: Int
  let bottom: Int
}

struct PoseBounds: Encodable {
  let top: Double
  let radius: Double
}

enum ArtError: Error {
  case invalidImage(String)
  case missingFigures(String, Int)
  case clippedFigure(String)
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let sources = root.appendingPathComponent("Resources/FighterSheets")
let destination = root.appendingPathComponent("Resources/Fighters.atlas")
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
let outputWidth = 896
let outputHeight = 640
let baseline = 600
let pivot = 384
var bounds: [String: PoseBounds] = [:]

try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

for (sheet, rows, names) in [
  ("rei", 3, ["rei"]),
  ("mika", 3, ["mika"]),
  ("companions", 2, ["antenna", "redshift"]),
] {
  let url = sources.appendingPathComponent("\(sheet).png")
  guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
  else { throw ArtError.invalidImage(sheet) }
  let width = image.width
  let height = image.height
  var pixels = [UInt8](repeating: 0, count: width * height * 4)
  pixels.withUnsafeMutableBytes { storage in
    let context = CGContext(
      data: storage.baseAddress, width: width, height: height,
      bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo)!
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
  }
  for pixel in 0..<(width * height) {
    let index = pixel * 4
    let r = Int(pixels[index])
    let g = Int(pixels[index + 1])
    let b = Int(pixels[index + 2])
    if g > r + 25 && g > b + 25 {
      pixels[index + 3] = 0
    } else if g > max(r, b) + 5 {
      pixels[index + 1] = UInt8(max(r, b))
    }
  }
  var visited = [Bool](repeating: false, count: width * height)
  var figures: [Figure] = []
  for seed in 0..<(width * height) where !visited[seed] && pixels[seed * 4 + 3] > 0 {
    var queue = [seed]
    visited[seed] = true
    var cursor = 0
    var left = width
    var top = height
    var right = 0
    var bottom = 0
    while cursor < queue.count {
      let index = queue[cursor]
      cursor += 1
      let x = index % width
      let y = index / width
      left = min(left, x)
      right = max(right, x)
      top = min(top, y)
      bottom = max(bottom, y)
      for dy in -1...1 {
        for dx in -1...1 {
          let nx = x + dx
          let ny = y + dy
          guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
          let neighbor = ny * width + nx
          if !visited[neighbor] && pixels[neighbor * 4 + 3] > 0 {
            visited[neighbor] = true
            queue.append(neighbor)
          }
        }
      }
    }
    if queue.count > 4_000 {
      figures.append(Figure(pixels: queue, left: left, top: top, right: right, bottom: bottom))
    }
  }
  guard figures.count == rows * 4 else { throw ArtError.missingFigures(sheet, figures.count) }
  figures.sort {
    let firstRow = min(rows - 1, $0.bottom * rows / height)
    let secondRow = min(rows - 1, $1.bottom * rows / height)
    return firstRow == secondRow ? $0.left < $1.left : firstRow < secondRow
  }
  for (index, figure) in figures.enumerated() {
    let character = sheet == "companions" ? index / 4 : 0
    let frame = sheet == "companions" ? index % 4 : index
    let neutral = figures[sheet == "companions" ? character * 4 : 0]
    let scale = Double(sheet == "companions" ? 460 : 420) / Double(neutral.bottom - neutral.top + 1)
    let feet = figure.pixels.filter { $0 / width >= figure.bottom - 35 }.map { $0 % width }
    let center = Double(feet.min()! + feet.max()!) / 2
    var isolated = [UInt8](repeating: 0, count: width * height * 4)
    for pixel in figure.pixels {
      for channel in 0..<4 { isolated[pixel * 4 + channel] = pixels[pixel * 4 + channel] }
    }
    let data = Data(isolated)
    let provider = CGDataProvider(data: data as CFData)!
    let isolatedImage = CGImage(
      width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
      bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
      provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
    let minX = Double(pivot) + (Double(figure.left) - center) * scale
    let maxX = Double(pivot) + (Double(figure.right) - center) * scale
    let topY = Double(baseline) - Double(figure.bottom - figure.top) * scale
    guard minX >= 0, maxX < Double(outputWidth), topY >= 0 else {
      throw ArtError.clippedFigure("\(sheet)-\(frame): x=\(minX)...\(maxX), top=\(topY)")
    }
    let context = CGContext(
      data: nil, width: outputWidth, height: outputHeight, bitsPerComponent: 8,
      bytesPerRow: outputWidth * 4, space: colorSpace, bitmapInfo: bitmapInfo)!
    context.interpolationQuality = .high
    context.translateBy(x: CGFloat(pivot) - center * scale, y: CGFloat(outputHeight - baseline))
    context.scaleBy(x: scale, y: scale)
    context.translateBy(x: 0, y: -Double(height - 1 - figure.bottom))
    context.draw(isolatedImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    let output = destination.appendingPathComponent("\(names[character])-\(frame).png")
    guard let result = context.makeImage(),
      let writer = CGImageDestinationCreateWithURL(
        output as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { throw ArtError.invalidImage(output.path) }
    CGImageDestinationAddImage(writer, result, nil)
    guard CGImageDestinationFinalize(writer) else { throw ArtError.invalidImage(output.path) }
    bounds["\(names[character])-\(frame)"] = PoseBounds(
      top: Double(baseline) - topY,
      radius: max(Double(pivot) - minX, maxX - Double(pivot)))
    print(
      "\(names[character])-\(frame): \(figure.pixels.count) opaque pixels, bounds \(figure.left),\(figure.top)–\(figure.right),\(figure.bottom)"
    )
  }
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
try encoder.encode(bounds).write(to: root.appendingPathComponent("Resources/FighterBounds.json"))
