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
        // DIAGNOSTIC (2026-11-12): Node autostart DISABLED — the v1.1.0+2
        // build (run #24, libc++ fix in) still dies on launch with NO Java
        // crash log, i.e. a NATIVE crash inside node::Start. Turning the
        // launch-time autostart off isolates it: if the app now opens,
        // Node startup is the killer and the gateway starts lazily from
        // the login screen ("startGateway" channel) instead. Re-enable
        // once the native crash cause is fixed.
        // Thread {
        //     try {
        //         NodeRuntime.ensureStarted(applicationContext)
        //     } catch (e: Exception) {
        //         android.util.Log.w("MainActivity", "gateway autostart failed: ${e.message}")
        //     }
        // }.start()
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
