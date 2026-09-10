import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    RegisterGeneratedPlugins(registry: flutterViewController)

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
}
