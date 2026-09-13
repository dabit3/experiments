import ApplicationServices
// Standalone TEST TOOL. Does not link to Metro Impact or send network input.
// Build: swiftc native_events.swift -o native_events
import Cocoa

struct Request: Decodable {
  var label: String?
  var focus: [Double]?
  var point: [Double]?
  var kind: String?
  var duration: Double?
}

struct Response: Encodable {
  var ok: Bool? = nil
  var accessibility: Bool? = nil
  var postEvents: Bool? = nil
  var width: Int? = nil
  var height: Int? = nil
  var error: String? = nil
  var started: Double? = nil
  var ended: Double? = nil
  var uptime: Double? = nil
}

enum InputError: Error {
  case invalidPoint
}

func emit(_ value: Response) {
  let data = try! JSONEncoder().encode(value)
  FileHandle.standardOutput.write(data + Data([10]))
}
let trusted = AXIsProcessTrusted()
let allowed = CGPreflightPostEventAccess()
if CommandLine.arguments.contains("--preflight") {
  emit(
    Response(
      accessibility: trusted, postEvents: allowed,
      width: CGDisplayPixelsWide(CGMainDisplayID()),
      height: CGDisplayPixelsHigh(CGMainDisplayID())))
  exit(trusted && allowed ? 0 : 2)
}
guard trusted && allowed else {
  emit(
    Response(
      ok: false, error: "Enable Accessibility for the launching terminal/process before running."))
  exit(2)
}
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let panel = NSPanel(
  contentRect: NSRect(x: 970, y: 420, width: 600, height: 260),
  styleMask: [.borderless, .nonactivatingPanel],
  backing: .buffered, defer: false)
panel.level = .floating
panel.backgroundColor = NSColor(calibratedRed: 0.02, green: 0.04, blue: 0.09, alpha: 0.97)
panel.ignoresMouseEvents = true
panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
let label = NSTextField(wrappingLabelWithString: "")
label.frame = NSRect(x: 22, y: 18, width: 556, height: 224)
label.font = NSFont.monospacedSystemFont(ofSize: 20, weight: .semibold)
label.textColor = .white
panel.contentView?.addSubview(label)
panel.orderFrontRegardless()
let source = CGEventSource(stateID: .hidSystemState)!
source.localEventsSuppressionInterval = 0
func event(_ type: CGEventType, _ p: CGPoint) {
  let e = CGEvent(
    mouseEventSource: source, mouseType: type,
    mouseCursorPosition: p, mouseButton: .left)!
  e.setIntegerValueField(.mouseEventClickState, value: 1)
  e.post(tap: .cghidEventTap)
}
func point(_ a: [Double]) throws -> CGPoint {
  guard a.count == 2, a.allSatisfy({ $0.isFinite }) else { throw InputError.invalidPoint }
  return CGPoint(x: a[0], y: a[1])
}
func click(_ p: CGPoint, _ seconds: Double) {
  event(.mouseMoved, p)
  Thread.sleep(forTimeInterval: 0.03)
  event(.leftMouseDown, p)
  let end = ProcessInfo.processInfo.systemUptime + seconds
  while ProcessInfo.processInfo.systemUptime < end {
    Thread.sleep(forTimeInterval: 0.04)
    event(.leftMouseDragged, p)
  }
  event(.leftMouseUp, p)
  Thread.sleep(forTimeInterval: 0.05)
}
DispatchQueue.global().async {
  while let line = readLine() {
    do {
      let request = try JSONDecoder().decode(Request.self, from: Data(line.utf8))
      let title = request.label ?? "Native screen events"
      DispatchQueue.main.async {
        label.stringValue =
          "DEVIN COMPUTER-USE TEST\nTop: Beta-CG · Bottom: Alpha-CG\nIn-app drivers: OFF\n\n\(title)"
      }
      let started = Date().timeIntervalSince1970
      if let focus = request.focus {
        click(try point(focus), 0.04)
      }
      if let p = request.point {
        if request.kind == "move" {
          event(.mouseMoved, try point(p))
        } else {
          click(try point(p), request.duration ?? 0.08)
        }
      }
      emit(
        Response(
          ok: true, started: started, ended: Date().timeIntervalSince1970,
          uptime: ProcessInfo.processInfo.systemUptime))
    } catch {
      emit(Response(ok: false, error: String(describing: error)))
    }
  }
  DispatchQueue.main.async { app.terminate(nil) }
}
app.run()
