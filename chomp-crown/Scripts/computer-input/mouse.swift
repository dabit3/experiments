import AppKit
import ApplicationServices
import Foundation
import Vision

enum Operation: String, Codable { case info, windows, viewport, ocr, place, click, drag }

struct Command: Decodable {
  let op: Operation
  let title: String?
  let path: String?
  let x: Double?
  let y: Double?
  let toX: Double?
  let toY: Double?
  let heldScreenshot: String?
}
struct Frame: Encodable {
  let x: Double
  let y: Double
  let width: Double
  let height: Double
  func contains(_ p: CGPoint) -> Bool {
    p.x > x && p.x < x + width && p.y > y && p.y < y + height
  }
}
struct WindowRecord: Encodable {
  let title: String
  let frame: Frame
}
struct TextRecord: Encodable {
  let text: String
  let confidence: Float
  let x: Double
  let y: Double
  let width: Double
  let height: Double
}
// Typed, flat envelope for the line-oriented caller.
struct Response: Encodable {
  var error: String?
  var helperVersion: String?
  var trusted: Bool?
  var postEvents: Bool?
  var screenCapture: Bool?
  var screenWidth: Double?
  var screenHeight: Double?
  var windows: [WindowRecord]?
  var frame: Frame?
  var texts: [TextRecord]?
  var op: Operation?
  var point: [Double]?
  var window: String?
  var hostSeconds: Double?
}
struct InputError: LocalizedError {
  let message: String
  var errorDescription: String? { message }
}
func require(_ value: String?, _ name: String) throws -> String {
  guard let value, !value.isEmpty else {
    throw InputError(message: "Required nonempty field: \(name)")
  }
  return value
}
func coordinate(_ x: Double?, _ y: Double?) throws -> CGPoint {
  guard let x, let y, x.isFinite, y.isFinite else {
    throw InputError(message: "Required finite coordinate pair")
  }
  return CGPoint(x: x, y: y)
}
// Untyped CF references are restricted to the native AX boundary.
func attribute(_ element: AXUIElement, _ key: String) -> CFTypeRef? {
  var value: CFTypeRef?
  guard AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success else {
    return nil
  }
  return value
}
func axValue(_ element: AXUIElement, _ key: String) throws -> AXValue {
  guard let raw = attribute(element, key), CFGetTypeID(raw) == AXValueGetTypeID() else {
    throw InputError(message: "Missing typed AX value: \(key)")
  }
  // Opaque CF bridge after an explicit runtime type-ID check.
  return unsafeBitCast(raw, to: AXValue.self)
}
func frame(_ element: AXUIElement) throws -> Frame {
  var point = CGPoint.zero
  var size = CGSize.zero
  guard AXValueGetValue(try axValue(element, kAXPositionAttribute), .cgPoint, &point),
    AXValueGetValue(try axValue(element, kAXSizeAttribute), .cgSize, &size)
  else {
    throw InputError(message: "Unreadable AX frame")
  }
  return Frame(x: point.x, y: point.y, width: size.width, height: size.height)
}
func simulatorApp() throws -> NSRunningApplication {
  guard
    let app = NSRunningApplication.runningApplications(
      withBundleIdentifier: "com.apple.iphonesimulator"
    ).first
  else {
    throw InputError(message: "Simulator is not running")
  }
  return app
}
func windows() throws -> [AXUIElement] {
  let app = AXUIElementCreateApplication(try simulatorApp().processIdentifier)
  guard let result = attribute(app, kAXWindowsAttribute) as? [AXUIElement] else {
    throw InputError(message: "Simulator windows inaccessible")
  }
  return result
}
func window(_ title: String) throws -> AXUIElement {
  let matches = try windows().filter { attribute($0, kAXTitleAttribute) as? String == title }
  guard matches.count == 1, let result = matches.first else {
    throw InputError(message: "Expected one exact Simulator window: \(title)")
  }
  return result
}
func viewport(_ window: AXUIElement) throws -> Frame {
  let children = attribute(window, kAXChildrenAttribute) as? [AXUIElement] ?? []
  let groups = try children.filter { element in
    guard attribute(element, kAXRoleAttribute) as? String == kAXGroupRole else { return false }
    return try frame(element).height > 400
  }
  guard groups.count == 1, let group = groups.first else {
    throw InputError(message: "Ambiguous Simulator screen frame")
  }
  return try frame(group)
}
func hostSeconds() -> Double {
  var tb = mach_timebase_info_data_t()
  mach_timebase_info(&tb)
  return Double(mach_absolute_time()) * Double(tb.numer) / Double(tb.denom) / 1e9
}
func emit(_ type: CGEventType, _ point: CGPoint) throws {
  guard
    let event = CGEvent(
      mouseEventSource: nil, mouseType: type,
      mouseCursorPosition: point, mouseButton: .left)
  else {
    throw InputError(message: "Could not construct CGEvent")
  }
  event.setIntegerValueField(.mouseEventClickState, value: 1)
  event.post(tap: .cghidEventTap)
}
func command(_ c: Command) throws -> Response {
  switch c.op {
  case .info:
    var r = Response()
    r.helperVersion = "2.0"
    r.trusted = AXIsProcessTrusted()
    r.postEvents = CGPreflightPostEventAccess()
    r.screenCapture = CGPreflightScreenCaptureAccess()
    r.screenWidth = NSScreen.main?.frame.width ?? 0
    r.screenHeight = NSScreen.main?.frame.height ?? 0
    return r
  case .windows:
    return Response(
      windows: try windows().map {
        WindowRecord(title: attribute($0, kAXTitleAttribute) as? String ?? "", frame: try frame($0))
      })
  case .viewport:
    return Response(frame: try viewport(window(require(c.title, "title"))))
  case .ocr:
    let path = try require(c.path, "path")
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    try VNImageRequestHandler(url: URL(fileURLWithPath: path)).perform([request])
    let records = (request.results ?? []).compactMap { result -> TextRecord? in
      guard let text = result.topCandidates(1).first else { return nil }
      let f = result.boundingBox
      return TextRecord(
        text: text.string, confidence: text.confidence,
        x: f.minX, y: f.minY, width: f.width, height: f.height)
    }
    return Response(texts: records)
  case .place, .click, .drag:
    break
  }
  guard AXIsProcessTrusted(), CGPreflightPostEventAccess() else {
    throw InputError(
      message: "Grant Accessibility/event-posting permission to the invoking terminal/helper")
  }
  let title = try require(c.title, "title")
  let target = try window(title)
  var point = try coordinate(c.x, c.y)
  if c.op == .place {
    guard point.x >= 0, point.y >= 25, let value = AXValueCreate(.cgPoint, &point),
      AXUIElementSetAttributeValue(target, kAXPositionAttribute as CFString, value) == .success
    else {
      throw InputError(message: "Invalid or rejected window placement")
    }
    return Response(frame: try frame(target))
  }
  let end = c.op == .drag ? try coordinate(c.toX, c.toY) : point
  let bounds = try viewport(target)
  guard bounds.contains(point), bounds.contains(end) else {
    throw InputError(message: "Input point outside the exact target device screen")
  }
  _ = try simulatorApp().activate(options: [])
  guard AXUIElementPerformAction(target, kAXRaiseAction as CFString) == .success else {
    throw InputError(message: "Cannot raise target Simulator window")
  }
  usleep(15000)
  try emit(.mouseMoved, point)
  usleep(12000)
  try emit(.leftMouseDown, point)
  var releasePoint = point
  defer { try? emit(.leftMouseUp, releasePoint) }
  if c.op == .drag {
    for index in 1...12 {
      releasePoint = CGPoint(
        x: point.x + (end.x - point.x) * Double(index) / 12,
        y: point.y + (end.y - point.y) * Double(index) / 12)
      try emit(.leftMouseDragged, releasePoint)
      usleep(15000)
    }
    if let path = c.heldScreenshot {
      guard !path.isEmpty else { throw InputError(message: "Empty heldScreenshot path") }
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
      process.arguments = ["-x", path]
      try process.run()
      process.waitUntilExit()
      guard process.terminationStatus == 0 else {
        throw InputError(message: "Held screenshot failed")
      }
    }
    usleep(100000)
  } else {
    usleep(45000)
  }
  return Response(op: c.op, point: [point.x, point.y], window: title, hostSeconds: hostSeconds())
}
let decoder = JSONDecoder()
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
while let line = readLine() {
  let response: Response
  do { response = try command(decoder.decode(Command.self, from: Data(line.utf8))) } catch {
    response = Response(error: error.localizedDescription)
  }
  do {
    FileHandle.standardOutput.write(try encoder.encode(response))
    FileHandle.standardOutput.write(Data([10]))
  } catch {
    FileHandle.standardOutput.write(Data("{\"error\":\"Response encoding failed\"}\n".utf8))
  }
  fflush(stdout)
}
