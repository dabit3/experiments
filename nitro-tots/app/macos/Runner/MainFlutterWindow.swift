import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 720, height: 480)
    self.title = "Nitro Tots"

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    DispatchQueue.main.async { [weak self] in
      self?.applyDefaultFrame()
    }
  }

  private func applyDefaultFrame() {
    guard let screen = self.screen ?? NSScreen.main else { return }
    // Test harnesses pin the content area, e.g. NT_WINDOW=800x532, so captures
    // share an exact viewport with the web baseline.
    if let spec = ProcessInfo.processInfo.environment["NT_WINDOW"] {
      let parts = spec.split(separator: "x").compactMap { Double($0) }
      if parts.count == 2 {
        self.minSize = NSSize(width: 0, height: 0)
        self.setContentSize(NSSize(width: parts[0], height: parts[1]))
        self.setFrameTopLeftPoint(NSPoint(x: screen.visibleFrame.minX + 40, y: screen.visibleFrame.maxY - 40))
        return
      }
    }
    let target = NSSize(width: 1280, height: 800)
    let visible = screen.visibleFrame
    let w = min(target.width, visible.width - 40)
    let h = min(target.height, visible.height - 40)
    let origin = NSPoint(x: visible.midX - w / 2, y: visible.midY - h / 2)
    self.setFrame(NSRect(origin: origin, size: NSSize(width: w, height: h)), display: true, animate: false)
  }
}
