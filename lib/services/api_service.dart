import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/settings.dart';

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

  // ------------------------------------------------------------ settings
  // Gateway-owned settings (same keys as the original app).
  // Fails soft (null) when the gateway is unreachable.

  Future<AyxSettings?> fetchSettings() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/settings'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      return AyxSettings.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> pushSettings(AyxSettings settings) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/settings'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(settings.toGatewayJson()),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------ messages

  Future<bool> sendMessage(String jid, String text) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/send'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'jid': jid, 'text': text}),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markRead(String jid) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/markread'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'jid': jid}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> react(String jid, String messageId, String emoji) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/react'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'jid': jid, 'messageId': messageId, 'emoji': emoji}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> forwardMessage(
      String jid, String messageId, List<String> to) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/forward'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'jid': jid, 'messageId': messageId, 'to': to}),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> editMessage(
      String jid, String messageId, String text) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/editmessage'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'jid': jid, 'messageId': messageId, 'text': text}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMessage(String jid, String messageId) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/message/delete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'jid': jid, 'messageId': messageId}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteChat(String jid) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/chat/delete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'jid': jid}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> blockChat(String jid) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/block'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'jid': jid}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------ lists

  Future<List<Map<String, dynamic>>> fetchContacts() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/contacts'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body);
      if (body is List) {
        return body.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchMe() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/me'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchStatuses() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/statuses'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body);
      if (body is List) {
        return body.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchDeleted() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/deleted'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body);
      if (body is List) {
        return body.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ------------------------------------------------------------ AI memory

  Future<List<MemoryContact>> fetchAiMemory() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/aimemory'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body);
      if (body is List) {
        return body
            .map((e) => MemoryContact.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> clearAiMemory(String jid) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/aimemory/clear'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'jid': jid}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------ schedule

  Future<List<ScheduledTask>> fetchSchedule() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/schedule'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body);
      if (body is List) {
        return body
            .map((e) => ScheduledTask.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveScheduledTask(ScheduledTask task) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/schedule'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(task.toJson()),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelScheduledTask(String id) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl/schedule/$id'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------ music

  /// Search a music provider (saavn | itunes | spotify). Spotify is
  /// search-only on the free route; the gateway matches it on JioSaavn.
  Future<List<Map<String, dynamic>>> searchMusic(
      String query, String provider) async {
    try {
      final res = await http
          .get(Uri.parse(
              '$baseUrl/music/search?q=${Uri.encodeComponent(query)}&provider=$provider'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body);
      if (body is List) {
        return body.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchLyrics(String title) async {
    try {
      final res = await http
          .get(Uri.parse(
              '$baseUrl/music/lyrics?title=${Uri.encodeComponent(title)}'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body);
      if (body is List) {
        return body.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ------------------------------------------------------------ account

  Future<bool> reconnect() async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/reconnect'))
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/logout'))
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProfileName(String name) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/profile/name'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProfileBio(String bio) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/profile/bio'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'bio': bio}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Trigger a settings/keys backup on the gateway (Drive upload from
  /// the gateway is the "Not yet ported" item N1 — this stores the
  /// encrypted export locally on the gateway host for now).
  Future<bool> triggerBackup() async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/backup'))
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Send a broadcast list (original: BroadcastScreen JSON + timer).
  Future<Map<String, dynamic>?> sendBroadcast(
      List<Map<String, dynamic>> items, int delaySeconds) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/broadcast'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'items': items, 'delaySeconds': delaySeconds}),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
