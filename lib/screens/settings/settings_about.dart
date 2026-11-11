import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../services/settings_store.dart';
import '../../theme/app_theme.dart';
import 'settings_widgets.dart';

/// About — app information, links, privacy policy, unlink/reset.
/// Same as the original AboutSettings.
class AboutSettingsPage extends StatefulWidget {
  const AboutSettingsPage({
    super.key,
    required this.store,
    required this.api,
  });

  final SettingsStore store;
  final ApiService api;

  @override
  State<AboutSettingsPage> createState() => _AboutSettingsPageState();
}

class _AboutSettingsPageState extends State<AboutSettingsPage> {
  static const String _version = '1.0.0';
  static const String _igLabel = '@imayx1';
  static const String _tgLabel = '@whoraju';
  static const String _webLabel = 'imayx.in';

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      children: [
        SettingsGroup(
          title: 'About',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/icon/ayx-logo.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WhatsAyX',
                          style: TextStyle(
                            color: AppTheme.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'A clean WhatsApp tool app — Flutter + Node.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Version $_version',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Runs locally on your device. No data is collected. AI reply (if enabled) sends message text only to the API you configure.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Connect',
          child: Column(
            children: [
              ActionRow(
                icon: Icons.camera_alt,
                tint: const Color(0xFFFF7EB6),
                title: 'Instagram',
                desc: _igLabel,
                onTap: () => _snack('Instagram: $_igLabel'),
              ),
              ActionRow(
                icon: Icons.send,
                tint: AppTheme.secondary,
                title: 'Telegram',
                desc: _tgLabel,
                onTap: () => _snack('Telegram: $_tgLabel'),
              ),
              const SettingsNote(
                "If I'm unavailable everywhere, kindly contact me here.",
              ),
              ActionRow(
                icon: Icons.language,
                tint: AppTheme.primary,
                title: 'Website',
                desc: 'Personal site — $_webLabel',
                onTap: () => _snack('Website: https://$_webLabel'),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Legal',
          child: Column(
            children: [
              ActionRow(
                icon: Icons.shield,
                tint: AppTheme.success,
                title: 'Privacy Policy',
                desc: 'How your data is handled',
                onTap: _showPrivacyDialog,
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Account',
          child: Column(
            children: [
              ActionRow(
                icon: Icons.logout,
                tint: AppTheme.danger,
                title: 'Unlink / reset',
                desc: 'Log out this device and clear the session',
                danger: true,
                onTap: _confirmUnlink,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showPrivacyDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: AppTheme.text),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'WhatsAyX v2 runs on your device. Chats and media stay on your device and the gateway you run. No analytics, no ads, no tracking. When AI reply is enabled, message text is sent only to the AI API you configured yourself. You can unlink anytime — the WhatsApp session is deleted from the gateway.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnlink() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Unlink this device?',
          style: TextStyle(color: AppTheme.text),
        ),
        content: const Text(
          'This logs out WhatsApp on this device and clears the session. You will need to link again with QR or pairing code.',
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
              'Unlink',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await widget.api.logout();
      await widget.store.clearLocal();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
