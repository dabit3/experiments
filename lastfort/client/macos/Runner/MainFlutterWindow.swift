import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    var windowFrame = self.frame
    if let screen = NSScreen.main {
      let visible = screen.visibleFrame
      let width = min(1280.0, visible.width - 80)
      let height = min(820.0, visible.height - 80)
      windowFrame = NSRect(
        x: visible.midX - width / 2,
        y: visible.midY - height / 2,
        width: width,
        height: height)
    }
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 720, height: 480)
    self.title = "Lastfort"

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
