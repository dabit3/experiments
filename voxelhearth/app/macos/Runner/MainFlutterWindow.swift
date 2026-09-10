import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var cursorChannel: FlutterMethodChannel?
  private var mouseMonitor: Any?
  private var cursorCaptured = false

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    RegisterGeneratedPlugins(registry: flutterViewController)
    installCursorChannel(flutterViewController)

    super.awakeFromNib()
    applyRequestedSize()
  }

  /// VH_WINDOW=1280x800 pins the logical content size so automation can
  /// compare this window against the web client at the same viewport.
  func applyRequestedSize() {
    guard let spec = ProcessInfo.processInfo.environment["VH_WINDOW"] else { return }
    let parts = spec.split(separator: "x").compactMap { Double($0) }
    guard parts.count == 2 else { return }
    isRestorable = false
    setContentSize(NSSize(width: parts[0], height: parts[1]))
    center()
  }

  /// `voxelhearth/cursor`: first-person mouse look. While captured the cursor
  /// is hidden and frozen in place and raw deltas stream to Dart as `move`.
  private func installCursorChannel(_ controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "voxelhearth/cursor", binaryMessenger: controller.engine.binaryMessenger)
    cursorChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "capture":
        self?.setCursorCaptured(true)
        result(true)
      case "release":
        self?.setCursorCaptured(false)
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setCursorCaptured(_ on: Bool) {
    guard on != cursorCaptured else { return }
    cursorCaptured = on
    if on {
      warpCursorToCenter()
      CGAssociateMouseAndMouseCursorPosition(0)
      NSCursor.hide()
      mouseMonitor = NSEvent.addLocalMonitorForEvents(
        matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
      ) { [weak self] event in
        self?.cursorChannel?.invokeMethod("move", arguments: [event.deltaX, event.deltaY])
        return event
      }
    } else {
      if let monitor = mouseMonitor {
        NSEvent.removeMonitor(monitor)
        mouseMonitor = nil
      }
      CGAssociateMouseAndMouseCursorPosition(1)
      NSCursor.unhide()
    }
  }

  private func warpCursorToCenter() {
    guard let view = contentView else { return }
    let inWindow = view.convert(NSPoint(x: view.bounds.midX, y: view.bounds.midY), to: nil)
    let onScreen = convertToScreen(NSRect(origin: inWindow, size: .zero)).origin
    let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
    CGWarpMouseCursorPosition(CGPoint(x: onScreen.x, y: primaryHeight - onScreen.y))
  }

  override func resignKey() {
    super.resignKey()
    if cursorCaptured {
      setCursorCaptured(false)
      cursorChannel?.invokeMethod("released", arguments: nil)
    }
  }
}
