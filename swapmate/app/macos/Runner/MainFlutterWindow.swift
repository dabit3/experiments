import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// Default content rect: comfortable for two boards side by side.
  /// `SWAPMATE_WINDOW` ("WxH[+X+Y]", content size and screen origin) overrides
  /// it so automation can place windows deterministically.
  static func preferredFrame() -> NSRect {
    var frame = NSRect(x: 120, y: 120, width: 1280, height: 860)
    if let spec = ProcessInfo.processInfo.environment["SWAPMATE_WINDOW"] {
      let parts = spec.split(whereSeparator: { $0 == "x" || $0 == "+" }).compactMap { Double($0) }
      if parts.count >= 2 {
        frame.size = NSSize(width: parts[0], height: parts[1])
        if parts.count >= 4 { frame.origin = NSPoint(x: parts[2], y: parts[3]) }
      }
    }
    return frame
  }

  static func apply(to window: NSWindow) {
    let rect = preferredFrame()
    window.setContentSize(rect.size)
    window.setFrameOrigin(rect.origin)
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.minSize = NSSize(width: 720, height: 560)
    self.title = "Swapmate"
    MainFlutterWindow.apply(to: self)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

}
