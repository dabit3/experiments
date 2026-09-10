package dev.swapmate.swapmate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "swapmate/launch")
            .setMethodCallHandler { call, result ->
                if (call.method == "config") result.success(launchConfig()) else result.notImplemented()
            }
    }

    // Launch configuration for automation: `SWAPMATE_*` intent extras, e.g.
    // `adb shell am start -n <pkg>/.MainActivity -e SWAPMATE_TEST_ID android`.
    private fun launchConfig(): Map<String, String> {
        val out = HashMap<String, String>()
        val extras = intent?.extras ?: return out
        for (key in extras.keySet()) {
            if (key.startsWith("SWAPMATE_")) {
                extras.getString(key)?.let { out[key] = it }
            }
        }
        return out
    }
}
