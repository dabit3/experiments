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
    let channel = FlutterMethodChannel(
      name: "nitrotots/launch", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "config" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(AppDelegate.launchConfig())
    }
  }

  /// `NT_*` values from the process environment (`SIMCTL_CHILD_NT_*` when
  /// launched through `xcrun simctl launch`) and from `--NT_KEY=value`
  /// launch arguments. Arguments win.
  static func launchConfig() -> [String: String] {
    var out: [String: String] = [:]
    for (key, value) in ProcessInfo.processInfo.environment where key.hasPrefix("NT_") {
      out[key] = value
    }
    for arg in CommandLine.arguments where arg.hasPrefix("--NT_") {
      let body = arg.dropFirst(2)
      if let eq = body.firstIndex(of: "=") {
        out[String(body[..<eq])] = String(body[body.index(after: eq)...])
      } else {
        out[String(body)] = "1"
      }
    }
    return out
  }
}
