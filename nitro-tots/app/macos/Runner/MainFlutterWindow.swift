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
    let target = NSSize(width: 1280, height: 800)
    guard let screen = self.screen ?? NSScreen.main else { return }
    let visible = screen.visibleFrame
    let w = min(target.width, visible.width - 40)
    let h = min(target.height, visible.height - 40)
    let origin = NSPoint(x: visible.midX - w / 2, y: visible.midY - h / 2)
    self.setFrame(NSRect(origin: origin, size: NSSize(width: w, height: h)), display: true, animate: false)
  }
}
