// Test-only native host pointer driver. No app internals or network access.
import AppKit
import ApplicationServices
import Foundation

struct TouchRequest: Decodable {
  let window: String
  let x: Double
  let y: Double
  let duration: Double?
}

struct TouchResponse: Encodable {
  let startHost: Double
  let endHost: Double
  let ok: Bool
}

func host() -> Double { ProcessInfo.processInfo.systemUptime }
guard AXIsProcessTrusted() else { fatalError("Grant Accessibility permission before running") }
guard
  let app = NSRunningApplication.runningApplications(
    withBundleIdentifier: "com.apple.iphonesimulator"
  ).first
else { fatalError("Open Simulator before running") }
let ax = AXUIElementCreateApplication(app.processIdentifier)
let encoder = JSONEncoder()
encoder.keyEncodingStrategy = .convertToSnakeCase
while let line = readLine() {
  do {
    let request = try JSONDecoder().decode(TouchRequest.self, from: Data(line.utf8))
    let duration = request.duration ?? 0.06
    guard request.x.isFinite, request.y.isFinite, duration.isFinite,
      (0...5).contains(duration)
    else { throw NSError(domain: "Invalid coordinates or duration (0–5 seconds)", code: 3) }
    var windows: CFTypeRef?
    AXUIElementCopyAttributeValue(ax, kAXWindowsAttribute as CFString, &windows)
    let title = request.window
    guard
      let window = (windows as? [AXUIElement])?.first(where: {
        var value: CFTypeRef?
        AXUIElementCopyAttributeValue($0, kAXTitleAttribute as CFString, &value)
        return (value as? String) == title
      })
    else { throw NSError(domain: "Missing simulator window \(title)", code: 1) }
    app.activate()
    guard AXUIElementPerformAction(window, kAXRaiseAction as CFString) == .success
    else { throw NSError(domain: "Cannot raise simulator", code: 2) }
    Thread.sleep(forTimeInterval: 0.06)
    let point = CGPoint(x: request.x, y: request.y)
    CGEvent(
      mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)!
      .post(tap: .cghidEventTap)
    let start = host()
    CGEvent(
      mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point,
      mouseButton: .left)!.post(tap: .cghidEventTap)
    Thread.sleep(forTimeInterval: duration)
    CGEvent(
      mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left
    )!.post(tap: .cghidEventTap)
    let result = TouchResponse(startHost: start, endHost: host(), ok: true)
    print(String(decoding: try encoder.encode(result), as: UTF8.self))
    fflush(stdout)
  } catch {
    print("{\"ok\":false,\"error\":\"native input failed\"}")
    fflush(stdout)
    exit(1)
  }
}
