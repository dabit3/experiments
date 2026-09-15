import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(name: "swapmate/launch", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "config" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(AppDelegate.launchConfig())
    }
  }

  /// Launch configuration for automation: `--SWAPMATE_KEY=value` argv entries
  /// (e.g. from `xcrun simctl launch`) merged over `SWAPMATE_*` environment.
  static func launchConfig() -> [String: String] {
    var out: [String: String] = [:]
    for (k, v) in ProcessInfo.processInfo.environment where k.hasPrefix("SWAPMATE_") {
      out[k] = v
    }
    for arg in ProcessInfo.processInfo.arguments where arg.hasPrefix("--SWAPMATE_") {
      let body = arg.dropFirst(2)
      if let eq = body.firstIndex(of: "=") {
        out[String(body[..<eq])] = String(body[body.index(after: eq)...])
      }
    }
    return out
  }
}
