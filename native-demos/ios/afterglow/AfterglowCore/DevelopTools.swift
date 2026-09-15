import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum OutputFormat: String, CaseIterable, Sendable {
  case jpeg = "JPEG"
  case png = "PNG"
  public var fileExtension: String { self == .jpeg ? "jpg" : "png" }
}

public enum OutputSize: String, CaseIterable, Sendable {
  case original = "Full resolution"
  case large = "2048 px"
  case small = "1080 px"
  public var maxDimension: CGFloat? {
    switch self {
    case .original: nil
    case .large: 2048
    case .small: 1080
    }
  }
}

public struct Histogram: Sendable {
  public var red: [Double]
  public var green: [Double]
  public var blue: [Double]
  public var shadowsClipped: Double
  public var highlightsClipped: Double

  public static func measure(_ image: CGImage) -> Histogram {
    let longest = Double(max(image.width, image.height))
    let width = max(1, Int(Double(image.width) / longest * 160))
    let height = max(1, Int(Double(image.height) / longest * 160))
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    pixels.withUnsafeMutableBytes { buffer in
      let context = CGContext(
        data: buffer.baseAddress, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: width * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
      context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    var channels = Array(repeating: Array(repeating: 0.0, count: 64), count: 3)
    var black = 0.0
    var white = 0.0
    for index in stride(from: 0, to: pixels.count, by: 4) {
      for channel in 0..<3 { channels[channel][Int(pixels[index + channel]) / 4] += 1 }
      let values = [pixels[index], pixels[index + 1], pixels[index + 2]]
      if values.max()! <= 2 { black += 1 }
      if values.max()! >= 253 { white += 1 }
    }
    let count = Double(width * height)
    return Histogram(
      red: channels[0].map { $0 / count }, green: channels[1].map { $0 / count },
      blue: channels[2].map { $0 / count },
      shadowsClipped: black / count, highlightsClipped: white / count)
  }
}

public enum PhotoImport {
  public static func inspect(_ data: Data, title: String) throws -> ImportedPhoto {
    guard data.count <= 80_000_000,
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let type = CGImageSourceGetType(source),
      [UTType.jpeg.identifier, UTType.png.identifier, UTType.heic.identifier]
        .contains(type as String),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
        as? [CFString: NSObject],
      let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
      let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
      width.intValue > 0, height.intValue > 0,
      Double(width.intValue) * Double(height.intValue) <= 50_000_000
    else { throw ImportError.unsupported }
    let id = UUID().uuidString
    let fileExtension = UTType(type as String)?.preferredFilenameExtension ?? "jpg"
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
    let swapsAxes = (5...8).contains(orientation)
    return ImportedPhoto(
      id: id, fileName: "\(id).\(fileExtension)",
      title: trimmed.isEmpty ? "Untitled photograph" : String(trimmed.prefix(100)),
      width: swapsAxes ? height.intValue : width.intValue,
      height: swapsAxes ? width.intValue : height.intValue)
  }
}

public enum ImportError: LocalizedError {
  case unsupported
  public var errorDescription: String? {
    "Choose a JPEG, PNG or HEIC photograph under 50 megapixels and 80 MB."
  }
}
