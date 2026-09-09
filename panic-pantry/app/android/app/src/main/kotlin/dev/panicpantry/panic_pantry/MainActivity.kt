package dev.panicpantry.panic_pantry

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "panic_pantry/launch")
            .setMethodCallHandler { call, result ->
                if (call.method == "config") result.success(launchConfig()) else result.notImplemented()
            }
    }

    /** `PP_*` launch parameters from the process environment and intent extras
     *  (`adb shell am start ... --es PP_ROOM ABCD`). */
    private fun launchConfig(): Map<String, String> {
        val config = HashMap<String, String>()
        for ((key, value) in System.getenv()) if (key.startsWith("PP_")) config[key] = value
        val extras = intent?.extras
        if (extras != null) {
            for (key in extras.keySet()) {
                if (key.startsWith("PP_")) extras.getString(key)?.let { config[key] = it }
            }
        }
        return config
    }
}
