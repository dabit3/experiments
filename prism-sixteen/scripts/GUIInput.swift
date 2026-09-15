import AppKit
import ApplicationServices

enum InputError: Error { case message(String) }

enum Command: String, Decodable {
  case windows, inspect, moveWindow, click, text
}

struct Request: Decodable {
  let command: Command
  let window: String?
  let point: [Double]?
  let epoch: Double?
  let hold: Double?
  let text: String?

  func target() throws -> AXUIElement {
    guard let window else { throw InputError.message("Window title required") }
    return try simulatorWindow(window)
  }

  func position() throws -> CGPoint {
    guard let point, point.count == 2, point.allSatisfy(\.isFinite) else {
      throw InputError.message("Two finite point coordinates required")
    }
    return CGPoint(x: point[0], y: point[1])
  }
}

struct Element: Encodable {
  let role: String
  let id: String
  let title: String
  let description: String
  let value: String
  let bounds: [Double]
  let enabled: Bool
}

struct Window: Encodable {
  let title: String
  let bounds: [Double]
}

struct Response: Encodable {
  var ok = true
  var error: String?
  var trusted: Bool?
  var display: [Double]?
  var windows: [Window]?
  var elements: [Element]?
  var bounds: [Double]?
  var downEpoch: Double?
  var upEpoch: Double?
  var point: [Double]?
}

func attr(_ element: AXUIElement, _ key: String) -> CFTypeRef? {
  var value: CFTypeRef?
  guard AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success else {
    return nil
  }
  return value
}
func string(_ element: AXUIElement, _ key: String) -> String {
  (attr(element, key) as? String) ?? ""
}
func children(_ element: AXUIElement, _ key: String = kAXChildrenAttribute) -> [AXUIElement] {
  (attr(element, key) as? [AXUIElement]) ?? []
}
func bounds(_ element: AXUIElement) -> [Double]? {
  guard let p = attr(element, kAXPositionAttribute),
    let s = attr(element, kAXSizeAttribute),
    CFGetTypeID(p) == AXValueGetTypeID(), CFGetTypeID(s) == AXValueGetTypeID()
  else { return nil }
  var point = CGPoint.zero
  var size = CGSize.zero
  AXValueGetValue(p as! AXValue, .cgPoint, &point)
  AXValueGetValue(s as! AXValue, .cgSize, &size)
  return [point.x, point.y, size.width, size.height]
}
func simulator() throws -> NSRunningApplication {
  guard
    let app = NSRunningApplication.runningApplications(
      withBundleIdentifier: "com.apple.iphonesimulator"
    ).first
  else { throw InputError.message("Simulator must be running") }
  return app
}
func windows() throws -> [AXUIElement] {
  children(AXUIElementCreateApplication(try simulator().processIdentifier), kAXWindowsAttribute)
}
func simulatorWindow(_ title: String) throws -> AXUIElement {
  let matches = try windows().filter { string($0, kAXTitleAttribute) == title }
  guard matches.count == 1 else {
    throw InputError.message("Expected one Simulator window named \(title), got \(matches.count)")
  }
  return matches[0]
}
func inspect(_ element: AXUIElement, depth: Int = 0) -> [Element] {
  guard depth < 24 else { return [] }
  var rows: [Element] = []
  if let rect = bounds(element), rect[2] > 0, rect[3] > 0 {
    rows.append(
      Element(
        role: string(element, kAXRoleAttribute),
        id: string(element, kAXIdentifierAttribute),
        title: string(element, kAXTitleAttribute),
        description: string(element, kAXDescriptionAttribute),
        value: string(element, kAXValueAttribute),
        bounds: rect,
        enabled: (attr(element, kAXEnabledAttribute) as? Bool) ?? true
      ))
  }
  for child in children(element) { rows += inspect(child, depth: depth + 1) }
  return rows
}
let source = CGEventSource(stateID: .hidSystemState)
func mouse(_ kind: CGEventType, _ point: CGPoint) {
  CGEvent(
    mouseEventSource: source, mouseType: kind, mouseCursorPosition: point,
    mouseButton: .left)?.post(tap: .cghidEventTap)
}
func execute(_ request: Request) throws -> Response {
  switch request.command {
  case .windows:
    return Response(
      trusted: AXIsProcessTrusted(),
      display: [
        CGDisplayBounds(CGMainDisplayID()).width, CGDisplayBounds(CGMainDisplayID()).height,
      ],
      windows: try windows().map {
        Window(title: string($0, kAXTitleAttribute), bounds: bounds($0) ?? [])
      })
  case .inspect:
    return Response(elements: inspect(try request.target()))
  case .moveWindow:
    let target = try request.target()
    var position = try request.position()
    let value = AXValueCreate(.cgPoint, &position)!
    guard AXUIElementSetAttributeValue(target, kAXPositionAttribute as CFString, value) == .success
    else { throw InputError.message("Cannot move Simulator window") }
    return Response(bounds: bounds(target) ?? [])
  case .click:
    let target = try request.target()
    _ = try simulator().activate()
    AXUIElementPerformAction(target, kAXRaiseAction as CFString)
    let point = try request.position()
    mouse(.mouseMoved, point)
    let due = request.epoch ?? Date().timeIntervalSince1970
    while true {
      let remaining = due - Date().timeIntervalSince1970
      guard remaining > 0 else { break }
      Thread.sleep(forTimeInterval: min(0.002, remaining))
    }
    let down = Date().timeIntervalSince1970
    mouse(.leftMouseDown, point)
    Thread.sleep(forTimeInterval: request.hold ?? 0.15)
    mouse(.leftMouseUp, point)
    return Response(
      downEpoch: down, upEpoch: Date().timeIntervalSince1970, point: [point.x, point.y])
  case .text:
    guard let value = request.text else { throw InputError.message("Text required") }
    let text =
      value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = [
      "-e",
      """
      tell application "System Events"
        keystroke "a" using command down
        delay 0.15
        keystroke "\(text)"
        key code 36
      end tell
      """,
    ]
    process.standardOutput = FileHandle.standardError
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      throw InputError.message("System Events keyboard permission/input failed")
    }
    return Response()
  }
}

let decoder = JSONDecoder()
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
while let line = readLine() {
  let result: Response
  do {
    result = try execute(decoder.decode(Request.self, from: Data(line.utf8)))
  } catch {
    result = Response(ok: false, error: String(describing: error))
  }
  let data = try encoder.encode(result)
  print(String(decoding: data, as: UTF8.self))
  fflush(stdout)
}
