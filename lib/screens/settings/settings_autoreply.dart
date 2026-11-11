import 'package:flutter/material.dart';

import '../../models/settings.dart';
import '../../services/settings_store.dart';
import '../../theme/app_theme.dart';
import 'settings_widgets.dart';

/// Auto-reply — master switch + keyword rules (add / edit / delete).
/// Same as the original AutoReplySection.
class AutoReplyPage extends StatefulWidget {
  const AutoReplyPage({super.key, required this.store});

  final SettingsStore store;

  @override
  State<AutoReplyPage> createState() => _AutoReplyPageState();
}

class _AutoReplyPageState extends State<AutoReplyPage> {
  @override
  Widget build(BuildContext context) {
    final s = widget.store.current;
    return SettingsSubPage(
      children: [
        SettingsGroup(
          title: 'Auto-reply',
          child: Column(
            children: [
              SettingRow(
                icon: Icons.question_answer,
                tint: const Color(0xFFFFB26B),
                title: 'Auto-reply',
                desc: 'Reply automatically to matching messages',
                checked: s.autoReplyEnabled,
                onChange: (v) async {
                  await widget.store
                      .update(s.copyWith(autoReplyEnabled: v));
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ),
        const SettingsNote(
          'Rules match incoming message text. When a rule matches, the app '
          'replies with its text. Excluded chats (AI Assistant → Don\'t reply '
          'to these chats) never get auto-replies.',
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Keyword rules (${s.autoReplyRules.length})',
          child: Column(
            children: [
              if (s.autoReplyRules.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No rules yet. Add one below.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              for (final rule in s.autoReplyRules)
                _RuleTile(
                  rule: rule,
                  onEdit: () => _editRule(rule),
                  onDelete: () async {
                    final rules = List<AutoReplyRule>.from(s.autoReplyRules)
                      ..removeWhere((r) => r.id == rule.id);
                    await widget.store
                        .update(s.copyWith(autoReplyRules: rules));
                    if (mounted) setState(() {});
                  },
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _editRule(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add rule'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editRule(AutoReplyRule? existing) async {
    final matchCtrl = TextEditingController(text: existing?.match ?? '');
    final replyCtrl = TextEditingController(text: existing?.reply ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          existing == null ? 'Add rule' : 'Edit rule',
          style: const TextStyle(color: AppTheme.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: matchCtrl,
              decoration: const InputDecoration(
                labelText: 'Keyword (match text)',
                hintText: 'e.g. price',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: replyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reply',
                hintText: 'e.g. Price list bhej raha hun…',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final match = matchCtrl.text.trim();
    final reply = replyCtrl.text.trim();
    if (match.isEmpty || reply.isEmpty) return;
    final s = widget.store.current;
    final rules = List<AutoReplyRule>.from(s.autoReplyRules);
    if (existing == null) {
      rules.add(AutoReplyRule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        match: match,
        reply: reply,
      ));
    } else {
      final i = rules.indexWhere((r) => r.id == existing.id);
      if (i >= 0) {
        rules[i] = AutoReplyRule(id: existing.id, match: match, reply: reply);
      }
    }
    await widget.store.update(s.copyWith(autoReplyRules: rules));
    if (mounted) setState(() {});
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.rule,
    required this.onEdit,
    required this.onDelete,
  });

  final AutoReplyRule rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.match,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rule.reply,
                  style: const TextStyle(color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.textSecondary),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppTheme.danger),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
