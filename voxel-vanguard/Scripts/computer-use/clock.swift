import AVFoundation
import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let height = NSScreen.main!.frame.height
let panel = NSPanel(
  contentRect: NSRect(x: 12, y: height - 210, width: 275, height: 175),
  styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
panel.backgroundColor = NSColor(calibratedWhite: 0.04, alpha: 0.95)
panel.level = .floating
panel.hidesOnDeactivate = false
let text = NSTextField(labelWithString: "")
text.frame = NSRect(x: 12, y: 10, width: 251, height: 155)
text.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
text.textColor = .white
text.maximumNumberOfLines = 9
panel.contentView!.addSubview(text)
let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
  let phase =
    (try? String(contentsOf: root.appendingPathComponent("phase.txt"), encoding: .utf8))
    ?? "Preparing capture"
  let host = AVAudioTime.seconds(forHostTime: mach_absolute_time())
  text.stringValue =
    "DEVIN COMPUTER-USE\nTwo real co-op peers\n\n\(phase)\n\nHOST \(String(format:"%.3f",host))\nWALL \(String(format:"%.3f",Date().timeIntervalSince1970))"
}
panel.orderFrontRegardless()
app.run()
