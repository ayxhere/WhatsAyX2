import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'settings_widgets.dart';

/// Broadcast — send bulk messages via JSON with a timer.
/// Same as the original BroadcastScreen.
class BroadcastPage extends StatefulWidget {
  const BroadcastPage({super.key, required this.api});

  final ApiService api;

  @override
  State<BroadcastPage> createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  final TextEditingController _jsonCtrl = TextEditingController();
  final TextEditingController _delayCtrl =
      TextEditingController(text: '5');
  String? _error;
  bool _sending = false;
  int _sent = 0;
  int _failed = 0;
  int _total = 0;
  bool _showPrompt = false;

  static const String _aiPrompt = '''
Create JSON for WhatsApp broadcast. Format must be exactly like this:
[
  {"phone": "919876543210", "message": "Hello! This is my message."},
  {"phone": "918765432109", "message": "Hi! Another message."}
]
Rules: phone = country code + number, no + or spaces. One object per line.
''';

  @override
  void dispose() {
    _jsonCtrl.dispose();
    _delayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      children: [
        const SettingsNote(
          'Broadcast messages are hidden from the chat list. Double-tap the WhatsAyX title to reveal them.',
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'AI Prompt',
                        style: TextStyle(
                          color: AppTheme.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await Clipboard.setData(
                            const ClipboardData(text: _aiPrompt));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Prompt copied!')),
                          );
                        }
                      },
                      child: const Text('Copy'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Copy this prompt and send it to any AI with your message and numbers. The AI will create JSON. Then paste the JSON here.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                TextButton(
                  onPressed: () => setState(() => _showPrompt = !_showPrompt),
                  child: Text(_showPrompt ? 'Hide prompt' : 'Show prompt'),
                ),
                if (_showPrompt)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      _aiPrompt,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ),
        settingsGap(),
        const Text(
          'Paste JSON here:',
          style: TextStyle(
            color: AppTheme.text,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _jsonCtrl,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText:
                '[\n  {"phone": "919876543210", "message": "Hello"},\n  ...\n]',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Delay between messages:',
          style: TextStyle(
            color: AppTheme.text,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _delayCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seconds',
                  suffixText: 'sec',
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => setState(() => _delayCtrl.text = '5'),
              child: const Text('Default 5s'),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppTheme.danger)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _sending ? null : _startBroadcast,
            child: Text(_sending ? 'Sending...' : 'Start Broadcast'),
          ),
        ),
        if (_total > 0) ...[
          const SizedBox(height: 16),
          Text(
            'Sent: $_sent / $_total',
            style: const TextStyle(color: AppTheme.text),
          ),
          if (_failed > 0)
            Text(
              'Failed: $_failed',
              style: const TextStyle(color: AppTheme.danger),
            ),
        ],
      ],
    );
  }

  Future<void> _startBroadcast() async {
    setState(() {
      _error = null;
      _sent = 0;
      _failed = 0;
      _total = 0;
    });
    List<dynamic> items;
    try {
      items = jsonDecode(_jsonCtrl.text) as List<dynamic>;
    } catch (_) {
      setState(() => _error = 'Invalid JSON — paste a JSON list.');
      return;
    }
    final parsed = <Map<String, dynamic>>[];
    for (final item in items) {
      if (item is Map) {
        final phone = item['phone']?.toString() ?? '';
        final message = item['message']?.toString() ?? '';
        if (phone.isNotEmpty && message.isNotEmpty) {
          parsed.add({'phone': phone, 'message': message});
        }
      }
    }
    if (parsed.isEmpty) {
      setState(() => _error = 'No valid entries found in JSON');
      return;
    }
    final delay = int.tryParse(_delayCtrl.text.trim()) ?? 0;
    if (delay <= 0) {
      setState(() => _error = 'Please set a valid timer');
      return;
    }
    setState(() {
      _sending = true;
      _total = parsed.length;
    });
    final result = await widget.api.sendBroadcast(parsed, delay);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (result != null) {
        _sent = (result['sent'] as num?)?.toInt() ?? 0;
        _failed = (result['failed'] as num?)?.toInt() ?? 0;
      } else {
        _error =
            'Gateway unreachable — broadcast not sent. Connect the gateway and try again.';
      }
    });
  }
}
