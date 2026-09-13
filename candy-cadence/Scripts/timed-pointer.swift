import CoreGraphics
// Test-only OS pointer input. Does not access GameClient or send game messages.
import Foundation

// Each argument is epochSeconds,x,y in actual desktop pixels.
for arg in CommandLine.arguments.dropFirst() {
  let fields = arg.split(separator: ",").compactMap { Double($0) }
  guard fields.count == 3 else { fatalError("epochSeconds,x,y required") }
  let wait = fields[0] - Date().timeIntervalSince1970
  if wait > 0 { Thread.sleep(forTimeInterval: wait) }
  let point = CGPoint(x: fields[1], y: fields[2])
  CGEvent(
    mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)?
    .post(tap: .cghidEventTap)
  CGEvent(
    mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left
  )?.post(tap: .cghidEventTap)
  Thread.sleep(forTimeInterval: 0.035)
  CGEvent(
    mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)?
    .post(tap: .cghidEventTap)
  print("OS_POINTER \(Date().timeIntervalSince1970) x=\(point.x) y=\(point.y)")
}
