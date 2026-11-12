package com.wa.ayx

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.wa.ayx/gateway"
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Start the on-device Node gateway early, off the UI thread
        // (extraction does blocking IO on first run / after an update).
        Thread {
            try {
                NodeRuntime.ensureStarted(applicationContext)
            } catch (e: Exception) {
                android.util.Log.w("MainActivity", "gateway autostart failed: ${e.message}")
            }
        }.start()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startGateway" -> {
                        // ensureStarted() is a no-op once node has started
                        // in this process; run it off the UI thread anyway
                        // (first-run extraction does blocking IO).
                        Thread {
                            try {
                                NodeRuntime.ensureStarted(applicationContext)
                                runOnUiThread { result.success(NodeRuntime.isStarted()) }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("GATEWAY_START_FAILED", e.message, null)
                                }
                            }
                        }.start()
                    }
                    "gatewayAlive" -> {
                        result.success(NodeRuntime.isStarted())
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
