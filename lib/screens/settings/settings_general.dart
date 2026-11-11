import 'package:flutter/material.dart';

import '../../services/settings_store.dart';
import '../../theme/app_theme.dart';
import 'settings_widgets.dart';

/// General — Online & Privacy, Messages & Media, Background & battery,
/// Storage & data. Same rows as the original GeneralSettings.
class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key, required this.store});

  final SettingsStore store;

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final s = widget.store.current;
    return SettingsSubPage(
      children: [
        SettingsGroup(
          title: 'Online & Privacy',
          child: Column(
            children: [
              SettingRow(
                icon: Icons.bolt,
                tint: const Color(0xFFB69DF8),
                title: 'Always online',
                desc: 'Keep showing online',
                checked: s.alwaysOnline,
                onChange: (v) => _update(
                  s.copyWith(alwaysOnline: v),
                ),
              ),
              SettingRow(
                icon: Icons.cloud_off,
                tint: const Color(0xFFFF7EB6),
                title: 'Freeze last seen',
                desc: 'Never broadcast online (overrides Always online)',
                checked: s.stayOffline,
                onChange: (v) => _update(s.copyWith(stayOffline: v)),
              ),
              SettingRow(
                icon: Icons.bolt,
                tint: AppTheme.primary,
                title: 'Human-like presence',
                desc:
                    'For each AI reply: read it, come online + type, reply, then go back offline',
                checked: s.aiPresenceFlow,
                onChange: (v) => _update(s.copyWith(aiPresenceFlow: v)),
              ),
              SettingRow(
                icon: Icons.remove_red_eye,
                tint: AppTheme.secondary,
                title: 'Hide status view',
                desc: "Don't show senders you saw their status",
                checked: s.hideStatusRead,
                onChange: (v) => _update(s.copyWith(hideStatusRead: v)),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Messages & Media',
          child: Column(
            children: [
              SettingRow(
                icon: Icons.done_all,
                tint: AppTheme.primary,
                title: 'Auto-read messages',
                desc: 'Mark incoming chats as read',
                checked: s.autoRead,
                onChange: (v) => _update(s.copyWith(autoRead: v)),
              ),
              SettingRow(
                icon: Icons.perm_media,
                tint: const Color(0xFFFFB26B),
                title: 'Save media',
                desc:
                    'Download incoming photos/videos (needed for view, deleted media)',
                checked: s.saveMedia,
                onChange: (v) => _update(s.copyWith(saveMedia: v)),
              ),
              SettingRow(
                icon: Icons.forward,
                tint: AppTheme.secondary,
                title: 'Forwarded tag',
                desc: 'Show the "Forwarded" label on forwarded messages',
                checked: s.showForwardTag,
                onChange: (v) => _update(s.copyWith(showForwardTag: v)),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Background & battery',
          child: Column(
            children: [
              SettingRow(
                icon: Icons.cloud_off,
                tint: AppTheme.secondary,
                title: 'Run in background',
                desc:
                    'Keeps a silent notification so messages arrive when the app is closed. Turn OFF to remove the notification (messages then arrive only while the app is open).',
                checked: s.runBackground,
                onChange: (v) => _update(s.copyWith(runBackground: v)),
              ),
              ActionRow(
                icon: Icons.bolt,
                tint: const Color(0xFFFFC24D),
                title: 'Allow battery (no optimization)',
                desc: 'Keep the gateway alive in the background',
                onTap: () => _snack(
                  'Open system settings → Battery → WhatsAyX → Unrestricted.',
                ),
              ),
              ActionRow(
                icon: Icons.settings,
                tint: const Color(0xFFB69DF8),
                title: 'Allow app to open / autostart',
                desc: 'Open app settings to enable autostart & background',
                onTap: () => _snack(
                  'Open system settings → Apps → WhatsAyX → Autostart.',
                ),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Storage & data',
          child: Column(
            children: [
              ActionRow(
                icon: Icons.perm_media,
                tint: const Color(0xFFFFB26B),
                title: 'Downloaded media',
                desc: 'Photos and videos saved by Save media',
                onTap: () => _snack('Media cache cleared.'),
              ),
              ActionRow(
                icon: Icons.storage,
                tint: AppTheme.secondary,
                title: 'Cache',
                desc: 'Temporary files',
                onTap: () => _snack('Cache cleared.'),
              ),
              ActionRow(
                icon: Icons.delete_sweep,
                tint: AppTheme.success,
                title: 'Clear cache',
                desc: 'Free space — keeps chats, settings and your login',
                onTap: () => _snack('Cache cleared.'),
              ),
              ActionRow(
                icon: Icons.delete,
                tint: AppTheme.danger,
                title: 'Clear app data',
                desc: "Removes everything local — you'll need to link again",
                danger: true,
                onTap: _confirmClear,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClear() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Clear app data?',
          style: TextStyle(color: AppTheme.text),
        ),
        content: const Text(
          "This removes WhatsAyX local data — chats, statuses, cached media, names, wallpaper, settings and the login/session. Your account is not deleted, but you'll need to link this device again with QR or pairing code. The app will restart.",
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
              'Clear Data',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await widget.store.clearLocal();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  Future<void> _update(dynamic next) async {
    await widget.store.update(next);
    if (mounted) setState(() {});
  }

  void _snack(String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
