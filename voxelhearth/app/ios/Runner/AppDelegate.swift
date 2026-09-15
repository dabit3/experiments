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
    // Launch overrides for automation: `SIMCTL_CHILD_VH_*` environment
    // variables and `-VH_KEY value` launch arguments.
    let channel = FlutterMethodChannel(
      name: "voxelhearth/launch", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "overrides" else {
        result(FlutterMethodNotImplemented)
        return
      }
      var out: [String: String] = [:]
      for (k, v) in ProcessInfo.processInfo.environment where k.hasPrefix("VH_") {
        out[k] = v
      }
      let args = ProcessInfo.processInfo.arguments
      for (i, a) in args.enumerated() where a.hasPrefix("-VH_") && i + 1 < args.count {
        out[String(a.dropFirst())] = args[i + 1]
      }
      result(out)
    }
  }
}
