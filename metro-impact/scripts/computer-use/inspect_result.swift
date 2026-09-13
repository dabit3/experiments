// Read-only OCR of actual two-device screenshot; no app instrumentation.
import Foundation
import ImageIO
import Vision

struct Window: Decodable {
  let window: [Int]
}
struct Configuration: Decodable {
  let alpha: Window
  let beta: Window
}
struct Text: Encodable {
  let text: String
  let confidence: Float
  let x: CGFloat
  let y: CGFloat
}
struct Output: Encodable {
  let image: String
  let width: Int
  let height: Int
  let alpha: [Text]
  let beta: [Text]
}
guard CommandLine.arguments.count == 3 else {
  fatalError("Usage: swift inspect_result.swift screenshot.png screen-config.json")
}
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let configuration = try JSONDecoder().decode(
  Configuration.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2])))
guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
  let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
else {
  fatalError("Cannot read screenshot")
}
func recognize(_ window: Window) throws -> [Text] {
  let r = window.window
  guard r.count == 4,
    let crop = image.cropping(to: CGRect(x: r[0], y: r[1], width: r[2], height: r[3]))
  else {
    throw NSError(domain: "Invalid window crop", code: 1)
  }
  let request = VNRecognizeTextRequest()
  request.recognitionLevel = .accurate
  request.usesLanguageCorrection = false
  try VNImageRequestHandler(cgImage: crop).perform([request])
  return (request.results ?? []).compactMap { observation -> Text? in
    guard let text = observation.topCandidates(1).first else { return nil }
    return Text(
      text: text.string, confidence: text.confidence,
      x: observation.boundingBox.midX, y: observation.boundingBox.midY)
  }
}
let output = Output(
  image: url.path, width: image.width, height: image.height,
  alpha: try recognize(configuration.alpha), beta: try recognize(configuration.beta))
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let data = try encoder.encode(output)
FileHandle.standardOutput.write(data)
