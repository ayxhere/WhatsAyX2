import 'package:flutter/services.dart';

import 'api_service.dart';

/// Dart side of the on-device Node gateway.
///
/// The gateway runs INSIDE the app (embedded Node, see
/// android/app/src/main/kotlin/com/wa/ayx/NodeRuntime.kt) and serves
/// HTTP on http://127.0.0.1:8765 — no Termux, no manual backend start,
/// no emulator-only 10.0.2.2 address.
class GatewayService {
  GatewayService({ApiService? api}) : _api = api ?? ApiService();

  static const MethodChannel _channel =
      MethodChannel('com.wa.ayx/gateway');

  final ApiService _api;

  /// Ask the native side to start the gateway (no-op if it is already
  /// running in this process). Retries a few times; returns true when
  /// the native side believes the node thread is alive.
  Future<bool> ensureStarted({int attempts = 3}) async {
    for (var i = 0; i < attempts; i++) {
      try {
        final started = await _channel.invokeMethod<bool>('startGateway');
        if (started == true) return true;
      } on PlatformException {
        // Native side failed to start; retry below.
      } catch (_) {
        // Channel missing (e.g. tests) — fall through to health polling.
        break;
      }
      if (i < attempts - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    return false;
  }

  /// True when the native node thread is believed alive.
  Future<bool> get isAlive async {
    try {
      return await _channel.invokeMethod<bool>('gatewayAlive') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Start the gateway (if needed) then poll GET /health until it
  /// answers or [timeout] elapses. Returns true when the gateway is
  /// reachable. The [api] defaults to the on-device base URL.
  Future<bool> waitForHealth({
    ApiService? api,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final service = api ?? _api;
    await ensureStarted();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await service.health()) return true;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }
}
