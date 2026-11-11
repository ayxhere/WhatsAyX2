import 'package:flutter/material.dart';

import '../../models/settings.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'settings_widgets.dart';

/// AI Memory — per-contact remembered name/number/language/history.
/// Same as the original AiMemoryScreen.
class AiMemoryPage extends StatefulWidget {
  const AiMemoryPage({super.key, required this.api});

  final ApiService api;

  @override
  State<AiMemoryPage> createState() => _AiMemoryPageState();
}

class _AiMemoryPageState extends State<AiMemoryPage> {
  bool _loading = true;
  List<MemoryContact> _items = [];
  String? _expanded;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final items = await widget.api.fetchAiMemory();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Memory',
                        style: TextStyle(
                          color: AppTheme.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'What the AI remembers about each contact.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: _refresh,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _loading
              ? 'Loading…'
              : '${_items.length} contacts remembered',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        if (!_loading && _items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No memory yet. As people message you, their name, number, language and full chat history are saved here — and the AI uses exactly that to reply.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        for (final c in _items)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () =>
                  setState(() => _expanded = _expanded == c.jid ? null : c.jid),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              AppTheme.primary.withOpacity(0.2),
                          child: Text(
                            c.name.isNotEmpty ? c.name[0] : '?',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  color: AppTheme.text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${c.messageCount} messages remembered',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _expanded == c.jid
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                    if (_expanded == c.jid) ...[
                      const SizedBox(height: 12),
                      if (c.number.isNotEmpty)
                        _MemRow('Number', c.number),
                      if (c.language.isNotEmpty)
                        _MemRow('Language', c.language),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            await widget.api.clearAiMemory(c.jid);
                            _refresh();
                          },
                          child: const Text('Clear this contact'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (_items.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final yes = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: const Text(
                      'Clear all memory?',
                      style: TextStyle(color: AppTheme.text),
                    ),
                    content: const Text(
                      'Saari contacts ki chat history aur saved info delete ho jayegi.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Clear all',
                          style: TextStyle(color: AppTheme.danger),
                        ),
                      ),
                    ],
                  ),
                );
                if (yes == true) {
                  await widget.api.clearAiMemory('');
                  _refresh();
                }
              },
              child: const Text('Clear all memory'),
            ),
          ),
      ],
    );
  }
}

class _MemRow extends StatelessWidget {
  const _MemRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.text),
            ),
          ),
        ],
      ),
    );
  }
}
