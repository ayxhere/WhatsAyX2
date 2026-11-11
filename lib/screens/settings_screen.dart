import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Settings tab: profile card + clean grouped rows.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _autoDownload = false;
  bool _readReceipts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icon/ayx-logo.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WhatsAyX',
                          style: TextStyle(
                            color: AppTheme.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'v1.0.0  •  com.wa.ayx',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('General'),
          _Row(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Message and status alerts',
            trailing: Switch(
              value: _notifications,
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _notifications = v),
            ),
          ),
          _Row(
            icon: Icons.download_outlined,
            title: 'Auto-download media',
            subtitle: 'Photos and videos on Wi-Fi',
            trailing: Switch(
              value: _autoDownload,
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _autoDownload = v),
            ),
          ),
          _Row(
            icon: Icons.done_all,
            title: 'Read receipts',
            subtitle: 'Let others see when you read',
            trailing: Switch(
              value: _readReceipts,
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _readReceipts = v),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('App'),
          _Row(
            icon: Icons.storage_outlined,
            title: 'Storage',
            subtitle: 'Manage media and cache',
            onTap: () {},
          ),
          _Row(
            icon: Icons.shield_outlined,
            title: 'Privacy',
            subtitle: 'Blocked contacts, disappearing messages',
            onTap: () {},
          ),
          _Row(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'WhatsAyX v2 — a separate app from AyXWhatsapp',
            onTap: () {},
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Account'),
          _Row(
            icon: Icons.logout,
            title: 'Log out',
            subtitle: 'Unlink this WhatsApp account',
            titleColor: AppTheme.danger,
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'WhatsAyX v2 • Flutter + Node • Made by imayx',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: titleColor ?? AppTheme.primary, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor ?? AppTheme.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null && onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
