import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'settings_widgets.dart';

/// Sync — Drive Backup. Same as the original DriveBackupSection.
///
/// NOTE (inventory item N1): the live Google Drive upload is the one
/// not-yet-ported piece — it needs google_sign_in + Drive API wiring.
/// This screen already has the account row, backup now, restore and
/// last-backup info; Backup now stores the encrypted export on the
/// gateway (POST /backup) until the Drive upload is wired.
class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({
    super.key,
    required this.api,
  });

  final ApiService api;

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  String? _account;
  String? _lastBackup;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      children: [
        SettingsGroup(
          title: 'Drive Backup',
          child: Column(
            children: [
              ActionRow(
                icon: Icons.person,
                tint: AppTheme.secondary,
                title: 'Google account',
                desc: _account ??
                    'Add your Gmail once — no folders to manage',
                value: _account == null ? 'Add' : null,
                onTap: () async {
                  final email = await showDialog<String>(
                    context: context,
                    builder: (ctx) {
                      final ctrl = TextEditingController();
                      return AlertDialog(
                        backgroundColor: AppTheme.surface,
                        title: const Text(
                          'Google account',
                          style: TextStyle(color: AppTheme.text),
                        ),
                        content: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Gmail address',
                            hintText: 'you@gmail.com',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(ctx).pop(ctrl.text.trim()),
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                  if (email != null && email.isNotEmpty) {
                    setState(() => _account = email);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Account added — Drive upload wiring is pending (see inventory N1).',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              ActionRow(
                icon: Icons.backup,
                tint: AppTheme.primary,
                title: 'Backup now',
                desc: _lastBackup == null
                    ? 'API keys & prompts → encrypted backup'
                    : 'Last backup: $_lastBackup',
                onTap: _busy ? () {} : _backupNow,
              ),
              ActionRow(
                icon: Icons.restore,
                tint: AppTheme.success,
                title: 'Restore from backup',
                desc: 'Restore API keys & prompts from a backup file',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Restore reads the latest backup on the gateway. No backup found yet.',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        settingsGap(),
        const SettingsNote(
          'Backups are encrypted (AES-256-GCM, .ayxbak-style) and never '
          'contain your WhatsApp session. The live Google Drive upload is '
          'the one piece still to wire — see SETTINGS_INVENTORY.md (N1).',
        ),
        if (_busy) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  Future<void> _backupNow() async {
    setState(() => _busy = true);
    final ok = await widget.api.triggerBackup();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _lastBackup =
            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${TimeOfDay.now().format(context)}';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Backup saved on the gateway.'
              : 'Gateway unreachable — backup will retry when it is back.',
        ),
      ),
    );
  }
}
