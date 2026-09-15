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
      name: "panic_pantry/launch", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "config" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(AppDelegate.launchConfig())
    }
  }

  /// `PP_*` launch parameters: process environment (`SIMCTL_CHILD_PP_*` when
  /// launched through `xcrun simctl launch`) and `PP_KEY=value` arguments.
  static func launchConfig() -> [String: String] {
    var config: [String: String] = [:]
    for (key, value) in ProcessInfo.processInfo.environment where key.hasPrefix("PP_") {
      config[key] = value
    }
    for arg in CommandLine.arguments.dropFirst() where arg.hasPrefix("PP_") {
      if let eq = arg.firstIndex(of: "=") {
        config[String(arg[..<eq])] = String(arg[arg.index(after: eq)...])
      }
    }
    return config
  }
}
