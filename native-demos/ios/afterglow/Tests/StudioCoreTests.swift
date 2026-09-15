import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest

@testable import AfterglowCore

final class StudioCoreTests: XCTestCase {
  private var sample: URL {
    URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent().appendingPathComponent("Assets/dunes.jpg")
  }

  func testLegacyProjectDecodesNewDefaultsAndHistory() throws {
    let json = """
      {
        "version":1,"selectedID":"coast","photos":{"coast":{
          "current":{"look":"Ember","exposure":0.75,"crop":"4:5"},
          "undoStack":[{"look":"Original"}],"redoStack":[]
        }}
      }
      """
    let project = try JSONDecoder().decode(Project.self, from: Data(json.utf8))
    let history = try XCTUnwrap(project.photos["coast"])
    XCTAssertEqual(history.current.exposure, 0.75)
    XCTAssertEqual(history.current.lookAmount, 1)
    XCTAssertEqual(history.current.crop, .portrait)
    XCTAssertEqual(history.current.shadows, 0)
    XCTAssertEqual(history.current.vibrance, 0)
    XCTAssertEqual(history.undoStack, [Edit()])
    XCTAssertTrue(project.imports.isEmpty)
    XCTAssertTrue(project.favorites.isEmpty)
  }

  func testImportedLibraryFavoritesAndAdvancedEditsRoundTrip() throws {
    var project = Project()
    let imported = try PhotoImport.inspect(Data(contentsOf: sample), title: "  Evening  ")
    project.imports = [imported]
    project.favorites = [imported.id, "dunes"]
    project.selectedID = imported.id
    var history = EditHistory()
    var edit = Edit()
    edit.lookAmount = 0.4
    edit.highlights = -0.6
    edit.shadows = 0.7
    edit.vibrance = 0.3
    edit.sharpness = 0.4
    edit.vignette = 0.5
    history.apply(edit)
    project.photos[imported.id] = history
    XCTAssertEqual(imported.title, "Evening")
    XCTAssertEqual(imported.width, 1024)
    XCTAssertEqual(imported.height, 1536)
    XCTAssertEqual(
      try JSONDecoder().decode(Project.self, from: JSONEncoder().encode(project)), project)
  }

  func testImportRejectsUnsupportedBytesAndProjectPathTraversal() throws {
    XCTAssertThrowsError(try PhotoImport.inspect(Data("not a photo".utf8), title: "Bad"))
    var project = Project()
    project.imports = [
      ImportedPhoto(
        id: UUID().uuidString, fileName: "../project.json", title: "Unsafe",
        width: 100, height: 100)
    ]
    XCTAssertThrowsError(
      try JSONDecoder().decode(Project.self, from: JSONEncoder().encode(project)))
  }

  func testImportHonorsEXIFOrientationAndUsesSafeFilename() throws {
    let image = try PhotoRenderer.render(url: sample, edit: Edit(), maxDimension: 80)
    let data = NSMutableData()
    let destination = try XCTUnwrap(
      CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: 6] as CFDictionary)
    XCTAssertTrue(CGImageDestinationFinalize(destination))
    let imported = try PhotoImport.inspect(data as Data, title: " ../project.json ")
    XCTAssertEqual(imported.width, image.height)
    XCTAssertEqual(imported.height, image.width)
    XCTAssertFalse(imported.fileName.contains("/"))
    XCTAssertFalse(imported.fileName.contains(".."))
  }

  func testAdvancedControlsChangePixelsAndZeroLookAmountIsNeutral() throws {
    let original = try PhotoRenderer.render(url: sample, edit: Edit(), maxDimension: 160)
    let baseline = bytes(original)
    for key in [\Edit.highlights, \Edit.shadows, \Edit.vibrance, \Edit.sharpness, \Edit.vignette] {
      var edit = Edit()
      edit[keyPath: key] = 0.75
      let image = try PhotoRenderer.render(url: sample, edit: edit, maxDimension: 160)
      XCTAssertNotEqual(bytes(image), baseline, "\(key)")
    }
    for look in FilmLook.allCases {
      var edit = Edit()
      edit.look = look
      edit.lookAmount = 0
      XCTAssertEqual(
        bytes(try PhotoRenderer.render(url: sample, edit: edit, maxDimension: 160)), baseline)
    }
  }

  func testHighlightAndShadowAdjustmentsHaveCorrectDirection() throws {
    let original = try PhotoRenderer.render(url: sample, edit: Edit(), maxDimension: 160)
    var recover = Edit()
    recover.highlights = -0.8
    let recovered = try PhotoRenderer.render(url: sample, edit: recover, maxDimension: 160)
    XCTAssertLessThan(mean(recovered), mean(original))
    var lift = Edit()
    lift.shadows = 0.8
    let lifted = try PhotoRenderer.render(url: sample, edit: lift, maxDimension: 160)
    XCTAssertGreaterThan(mean(lifted), mean(original))
  }

  func testHistogramNormalizationAndClippingForBlackWhiteImages() throws {
    let context = try XCTUnwrap(
      CGContext(
        data: nil, width: 40, height: 200, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    for level in [0.0, 1.0] {
      context.setFillColor(CGColor(gray: level, alpha: 1))
      context.fill(CGRect(x: 0, y: 0, width: 40, height: 200))
      let histogram = Histogram.measure(try XCTUnwrap(context.makeImage()))
      for channel in [histogram.red, histogram.green, histogram.blue] {
        XCTAssertEqual(channel.count, 64)
        XCTAssertEqual(channel.reduce(0, +), 1, accuracy: 0.0001)
        XCTAssertEqual(channel[level == 0 ? 0 : 63], 1, accuracy: 0.0001)
      }
      XCTAssertEqual(histogram.shadowsClipped, level == 0 ? 1 : 0)
      XCTAssertEqual(histogram.highlightsClipped, level == 1 ? 1 : 0)
    }
  }

  func testFractionalResizeDoesNotIntroduceTransparentBorderPixels() throws {
    let image = try PhotoRenderer.render(url: sample, edit: Edit(), maxDimension: 100)
    let values = bytes(image)
    XCTAssertEqual(image.width, 66)
    XCTAssertEqual(image.height, 100)
    XCTAssertTrue(stride(from: 3, to: values.count, by: 4).allSatisfy { values[$0] == 255 })
  }

  func testPNGExportIsLosslessAndOutputSizeNeverUpscales() throws {
    var edit = Edit()
    edit.crop = .portrait
    edit.look = .ember
    edit.shadows = 0.3
    let image = try PhotoRenderer.render(
      url: sample, edit: edit, maxDimension: OutputSize.small.maxDimension)
    XCTAssertEqual(max(image.width, image.height), 1080)
    let full = try PhotoRenderer.render(
      url: sample, edit: Edit(), maxDimension: OutputSize.large.maxDimension)
    XCTAssertEqual(max(full.width, full.height), 1536)
    let url = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Caches/AfterglowTests/\(UUID().uuidString).png")
    defer { try? FileManager.default.removeItem(at: url) }
    try PhotoRenderer.export(image: image, to: url, format: .png, quality: 0.6)
    let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
    XCTAssertEqual(CGImageSourceGetType(source) as String?, UTType.png.identifier)
    let decoded = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
    XCTAssertEqual(decoded.width, image.width)
    XCTAssertEqual(decoded.height, image.height)
    XCTAssertEqual(bytes(decoded), bytes(image))
  }

  private func bytes(_ image: CGImage) -> [UInt8] {
    var values = [UInt8](repeating: 0, count: image.width * image.height * 4)
    values.withUnsafeMutableBytes { buffer in
      let context = CGContext(
        data: buffer.baseAddress, width: image.width, height: image.height,
        bitsPerComponent: 8, bytesPerRow: image.width * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
      context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    }
    return values
  }

  private func mean(_ image: CGImage) -> Double {
    let values = bytes(image)
    var sum = 0.0
    for index in stride(from: 0, to: values.count, by: 4) {
      sum += Double(values[index]) + Double(values[index + 1]) + Double(values[index + 2])
    }
    return sum / Double(image.width * image.height * 3)
  }
}
