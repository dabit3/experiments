import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum RenderError: LocalizedError {
  case missingImage, failedRender, failedExport
  public var errorDescription: String? {
    switch self {
    case .missingImage: "The original image could not be opened."
    case .failedRender: "This image could not be developed. Try resetting the edit."
    case .failedExport: "The image could not be saved. Please try again."
    }
  }
}

public enum PhotoRenderer {
  private static let context = CIContext(options: [.cacheIntermediates: false])

  public static func cropRect(size: CGSize, edit: Edit) -> CGRect {
    let edit = edit.sanitized()
    let aspect = edit.crop.ratio ?? Double(size.width / size.height)
    var width = Double(size.width)
    var height = width / aspect
    if height > Double(size.height) {
      height = Double(size.height)
      width = height * aspect
    }
    width = max(1, floor(width / edit.zoom))
    height = max(1, floor(height / edit.zoom))
    let x = floor((Double(size.width) - width) * (edit.panX + 1) / 2)
    let y = floor((Double(size.height) - height) * (edit.panY + 1) / 2)
    return CGRect(x: x, y: y, width: width, height: height)
  }

  public static func render(url: URL, edit: Edit, maxDimension: CGFloat? = nil) throws
    -> CGImage
  {
    guard var image = CIImage(contentsOf: url, options: [.applyOrientationProperty: true])
    else { throw RenderError.missingImage }
    let edit = edit.sanitized()
    for _ in 0..<edit.rotation {
      image = image.oriented(.right)
    }
    image = image.transformed(
      by: CGAffineTransform(translationX: -image.extent.minX, y: -image.extent.minY))
    let crop = cropRect(size: image.extent.size, edit: edit)
    image = image.cropped(to: crop).transformed(
      by: CGAffineTransform(translationX: -crop.minX, y: -crop.minY))

    var outputBounds = image.extent
    if let maxDimension, max(image.extent.width, image.extent.height) > maxDimension {
      let scale = maxDimension / max(image.extent.width, image.extent.height)
      outputBounds = CGRect(
        x: 0, y: 0, width: max(1, floor(image.extent.width * scale)),
        height: max(1, floor(image.extent.height * scale)))
      image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        .cropped(to: outputBounds)
    }

    var exposure = edit.exposure
    var contrast = edit.contrast
    var saturation = edit.saturation
    var warmth = edit.warmth
    let amount = edit.lookAmount
    switch edit.look {
    case .original: break
    case .ember:
      exposure += 0.12 * amount
      contrast *= 1 + 0.08 * amount
      saturation *= 1 - 0.12 * amount
      warmth += 0.38 * amount
    case .coast:
      contrast *= 1 - 0.06 * amount
      saturation *= 1 - 0.22 * amount
      warmth -= 0.3 * amount
    case .silver:
      saturation *= 1 - amount
      contrast *= 1 + 0.16 * amount
    case .dusk:
      exposure -= 0.25 * amount
      saturation *= 1 - 0.34 * amount
      contrast *= 1 + 0.12 * amount
      warmth -= 0.14 * amount
    }
    let exposureFilter = CIFilter.exposureAdjust()
    exposureFilter.inputImage = image
    exposureFilter.ev = Float(exposure)
    image = exposureFilter.outputImage ?? image
    if edit.highlights < 0 || edit.shadows != 0 {
      let tonal = CIFilter.highlightShadowAdjust()
      tonal.inputImage = image
      tonal.highlightAmount = Float(1 + min(0, edit.highlights))
      tonal.shadowAmount = Float(edit.shadows)
      image = tonal.outputImage ?? image
    }
    if edit.highlights > 0 {
      let curve = CIFilter.toneCurve()
      curve.inputImage = image
      curve.point0 = CGPoint(x: 0, y: 0)
      curve.point1 = CGPoint(x: 0.25, y: 0.25)
      curve.point2 = CGPoint(x: 0.5, y: 0.5)
      curve.point3 = CGPoint(x: 0.75, y: 0.75 + edit.highlights * 0.16)
      curve.point4 = CGPoint(x: 1, y: 1)
      image = curve.outputImage ?? image
    }
    if warmth != 0 {
      let temperature = CIFilter.temperatureAndTint()
      temperature.inputImage = image
      temperature.neutral = CIVector(x: 6500, y: 0)
      temperature.targetNeutral = CIVector(x: 6500 - warmth * 2200, y: 0)
      image = temperature.outputImage ?? image
    }
    let color = CIFilter.colorControls()
    color.inputImage = image
    color.contrast = Float(contrast)
    color.saturation = Float(saturation)
    image = color.outputImage ?? image
    if edit.vibrance != 0 {
      let vibrance = CIFilter.vibrance()
      vibrance.inputImage = image
      vibrance.amount = Float(edit.vibrance)
      image = vibrance.outputImage ?? image
    }
    if edit.sharpness > 0 {
      let detail = CIFilter.sharpenLuminance()
      detail.inputImage = image
      detail.sharpness = Float(edit.sharpness)
      image = detail.outputImage ?? image
    }
    if edit.vignette > 0 {
      let vignette = CIFilter.vignette()
      vignette.inputImage = image
      vignette.intensity = Float(edit.vignette * 1.6)
      vignette.radius = Float(min(image.extent.width, image.extent.height) * 0.5)
      image = vignette.outputImage ?? image
    }
    guard
      let result = context.createCGImage(
        image,
        from: outputBounds,
        format: .RGBA8,
        colorSpace: CGColorSpace(name: CGColorSpace.sRGB))
    else { throw RenderError.failedRender }
    return result
  }

  public static func exportJPEG(image: CGImage, to url: URL) throws {
    try export(image: image, to: url, format: .jpeg, quality: 0.95)
  }

  public static func export(
    image: CGImage, to url: URL, format: OutputFormat, quality: Double
  ) throws {
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard
      let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        (format == .jpeg ? UTType.jpeg.identifier : UTType.png.identifier) as CFString, 1, nil)
    else { throw RenderError.failedExport }
    CGImageDestinationAddImage(
      destination, image,
      [kCGImageDestinationLossyCompressionQuality: min(1, max(0.5, quality))] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { throw RenderError.failedExport }
  }
}
