import AppKit
import CoreGraphics

struct PointerEvent: Codable {
  let target: String
  let control: String
  let x: Double
  let y: Double
  let hold: Double
  var downWall: Double?
  var upWall: Double?

  enum CodingKeys: String, CodingKey {
    case target, control, x, y, hold
    case downWall = "down_wall"
    case upWall = "up_wall"
  }
}

struct EventBatch: Codable {
  let events: [PointerEvent]
}

struct Failure: Encodable {
  let error: String
}

struct Ready: Encodable {
  let ready = true
  let width: Double
  let height: Double
  let osEvents = true
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let bounds = CGDisplayBounds(CGMainDisplayID())
func emit<Value: Encodable>(_ value: Value) {
  do {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let data = try encoder.encode(value)
    FileHandle.standardOutput.write(data + Data([10]))
  } catch {
    FileHandle.standardError.write(Data("Cannot encode pointer response: \(error)\n".utf8))
    exit(2)
  }
}
guard CGPreflightPostEventAccess() else {
  emit(Failure(error: "Grant Accessibility to the launching terminal/agent, then retry"))
  exit(2)
}
let statusPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : nil
let panel = NSPanel(
  contentRect: NSRect(
    x: bounds.width * 0.64, y: 80,
    width: bounds.width * 0.35, height: bounds.height - 140),
  styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
panel.backgroundColor = NSColor(calibratedRed: 0.035, green: 0.055, blue: 0.10, alpha: 1)
panel.level = .floating
panel.ignoresMouseEvents = true
let label = NSTextField(wrappingLabelWithString: "OS POINTER TEST\nPreparing")
label.frame = NSRect(x: 22, y: 20, width: panel.frame.width - 44, height: panel.frame.height - 115)
label.font = .monospacedSystemFont(ofSize: 22, weight: .medium)
label.textColor = .white
panel.contentView?.addSubview(label)
if statusPath != nil { panel.orderFrontRegardless() }
let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
  if let path = statusPath, let text = try? String(contentsOfFile: path, encoding: .utf8) {
    label.stringValue = text
  }
}
emit(Ready(width: bounds.width, height: bounds.height))
DispatchQueue.global().async {
  while let line = readLine() {
    do {
      let batch = try JSONDecoder().decode(EventBatch.self, from: Data(line.utf8))
      var completed = [PointerEvent]()
      for event in batch.events {
        let x = event.x
        let y = event.y
        let hold = event.hold
        guard (0...1024).contains(x), (0...768).contains(y),
          (0...1.5).contains(hold)
        else { throw NSError(domain: "Invalid event", code: 1) }
        let point = CGPoint(x: x * bounds.width / 1024, y: y * bounds.height / 768)
        CGEvent(
          mouseEventSource: nil, mouseType: .mouseMoved,
          mouseCursorPosition: point, mouseButton: .left)!.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.025)
        let start = Date().timeIntervalSince1970
        for (kind, delay) in [(CGEventType.leftMouseDown, hold), (.leftMouseUp, 0.12)] {
          let e = CGEvent(
            mouseEventSource: nil, mouseType: kind,
            mouseCursorPosition: point, mouseButton: .left)!
          e.setIntegerValueField(.mouseEventClickState, value: 1)
          e.post(tap: .cghidEventTap)
          Thread.sleep(forTimeInterval: delay)
        }
        var logged = event
        logged.downWall = start
        logged.upWall = Date().timeIntervalSince1970 - 0.12
        completed.append(logged)
      }
      emit(EventBatch(events: completed))
    } catch { emit(Failure(error: String(describing: error))) }
  }
  DispatchQueue.main.async { app.terminate(nil) }
}
app.run()
