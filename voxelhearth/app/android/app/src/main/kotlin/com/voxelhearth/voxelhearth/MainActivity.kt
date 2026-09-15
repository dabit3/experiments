package com.voxelhearth.voxelhearth

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Launch overrides for automation: `adb shell am start ... --es VH_NAME x`.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "voxelhearth/launch")
            .setMethodCallHandler { call, result ->
                if (call.method != "overrides") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val out = HashMap<String, String>()
                val extras = intent?.extras
                if (extras != null) {
                    for (k in extras.keySet()) {
                        if (k.startsWith("VH_")) extras.getString(k)?.let { out[k] = it }
                    }
                }
                result.success(out)
            }
    }
}
