import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // FlutterAppDelegate does not implement this selector, so there is no
  // super call to forward to.
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = mainFlutterWindow {
      MainFlutterWindow.apply(to: window)
      window.makeKeyAndOrderFront(nil)
    }
    NSApp.activate(ignoringOtherApps: true)
  }
}
