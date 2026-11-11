import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Talks to the Node gateway (backend/src/server.js).
///
/// The gateway hosts the Baileys WhatsApp connection and exposes:
///   GET  /health   -> gateway status
///   GET  /qr       -> current QR (data URL) or 404 when not ready
///   POST /pair     -> { phone } -> pairing code
///   Socket.IO      -> 'status' and 'message' events
///
/// When the gateway is unreachable every call fails soft and the UI
/// falls back to local demo data, so the app always stays usable.
class ApiService {
  ApiService({this.baseUrl = 'http://10.0.2.2:3000'});

  /// Default is the Android emulator loopback. On a real device the
  /// user changes this to the machine running the gateway.
  final String baseUrl;

  io.Socket? _socket;

  Future<bool> health() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return false;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Ask the gateway for a WhatsApp pairing code for [phone].
  /// Returns the code (e.g. "ABCD-1234") or null when unavailable.
  Future<String?> requestPairingCode(String phone) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/pair'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['code'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Current QR code as a data URL, or null when the gateway has
  /// none yet (connection not started or already paired).
  Future<String?> fetchQr() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/qr'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['qr'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Open a Socket.IO channel. [onStatus] gets 'connected' /
  /// 'disconnected' / 'qr' etc. [onMessage] gets incoming messages.
  void connectSocket({
    required void Function(String status) onStatus,
    required void Function(Map<String, dynamic> msg) onMessage,
  }) {
    _socket?.dispose();
    final socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );
    socket.onConnect((_) => onStatus('connected'));
    socket.onDisconnect((_) => onStatus('disconnected'));
    socket.on('status', (data) {
      if (data is Map) {
        onStatus(data['state']?.toString() ?? 'unknown');
      }
    });
    socket.on('message', (data) {
      if (data is Map<String, dynamic>) onMessage(data);
      if (data is Map) {
        onMessage(Map<String, dynamic>.from(data));
      }
    });
    _socket = socket;
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
