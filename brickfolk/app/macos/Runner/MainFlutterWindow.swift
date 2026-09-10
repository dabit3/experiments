import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var pinnedContentSize: NSSize?
  private var pinUntil = Date.distantPast

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    pinContentSizeFromEnvironment()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  /// `BRICKFOLK_WINDOW=WIDTHxHEIGHT` pins the content size (and centers the
  /// window) so automated captures are the same size on every launch. The
  /// size is re-applied if anything else resizes the window during startup.
  private func pinContentSizeFromEnvironment() {
    guard let spec = ProcessInfo.processInfo.environment["BRICKFOLK_WINDOW"] else { return }
    let parts = spec.lowercased().split(separator: "x").compactMap { Double($0) }
    guard parts.count == 2, parts[0] >= 320, parts[1] >= 240 else { return }
    let size = NSSize(width: parts[0], height: parts[1])
    pinnedContentSize = size
    pinUntil = Date().addingTimeInterval(5)
    applyPinnedContentSize()
    NotificationCenter.default.addObserver(
      forName: NSWindow.didResizeNotification, object: self, queue: nil
    ) { [weak self] _ in
      guard let self, Date() < self.pinUntil else { return }
      if self.contentLayoutRect.size != size { self.applyPinnedContentSize() }
    }
  }

  private func applyPinnedContentSize() {
    guard let size = pinnedContentSize else { return }
    self.setContentSize(size)
    self.center()
  }
}
