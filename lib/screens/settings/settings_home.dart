import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../tools/music_screen.dart';
import '../tools/schedule_screen.dart';

/// Settings home — profile header, gateway status, then the same 10
/// category rows as the original SettingsHome, grouped under clear
/// section headers. Same page ids, same onOpen targets.
class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({
    super.key,
    required this.api,
    required this.onOpen,
  });

  final ApiService api;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        const SizedBox(height: 4),
        _ProfileCard(),
        const SizedBox(height: 12),
        _StatusCard(api: api),
        const SizedBox(height: 20),
        _Group(
          title: 'Messaging',
          rows: [
            _GroupRowData(
              icon: Icons.tune,
              tint: const Color(0xFFB69DF8),
              title: 'General',
              desc: 'Online, privacy and messages',
              onTap: () => onOpen('general'),
            ),
            _GroupRowData(
              icon: Icons.question_answer,
              tint: const Color(0xFFFFB26B),
              title: 'Auto-reply',
              desc: 'Keyword rules and automatic replies',
              onTap: () => onOpen('autoreply'),
            ),
            _GroupRowData(
              icon: Icons.chat,
              tint: AppTheme.primary,
              title: 'Chat',
              desc: 'Wallpaper, bubble style and header',
              onTap: () => onOpen('chat'),
            ),
          ],
        ),
        _Group(
          title: 'AI',
          rows: [
            _GroupRowData(
              icon: Icons.auto_awesome,
              tint: AppTheme.secondary,
              title: 'AI Assistant',
              desc: 'AI replies, groups and language',
              onTap: () => onOpen('ai'),
            ),
            _GroupRowData(
              icon: Icons.graphic_eq,
              tint: AppTheme.primary,
              title: 'AI Voice',
              desc: 'Voice reply, voice notes & voice artists',
              onTap: () => onOpen('voice'),
            ),
          ],
        ),
        _Group(
          title: 'App',
          rows: [
            _GroupRowData(
              icon: Icons.palette,
              tint: const Color(0xFFFF7EB6),
              title: 'Appearance',
              desc: 'Theme and accent color',
              onTap: () => onOpen('appearance'),
            ),
            _GroupRowData(
              icon: Icons.sync,
              tint: AppTheme.secondary,
              title: 'Sync',
              desc: 'Drive backup of API keys & prompts',
              onTap: () => onOpen('sync'),
            ),
            _GroupRowData(
              icon: Icons.share,
              tint: const Color(0xFFFFB26B),
              title: 'Broadcast',
              desc: 'Send bulk messages via JSON with timer',
              onTap: () => onOpen('broadcast'),
            ),
          ],
        ),
        _Group(
          title: 'Tools',
          rows: [
            _GroupRowData(
              icon: Icons.music_note,
              tint: const Color(0xFF4DD0E1),
              title: 'Music',
              desc: 'JioSaavn, iTunes & Spotify search + lyrics',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MusicScreen(),
                ),
              ),
            ),
            _GroupRowData(
              icon: Icons.schedule,
              tint: const Color(0xFFFFB020),
              title: 'Schedule',
              desc: 'Send a message later, on time',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ScheduleScreen(),
                ),
              ),
            ),
          ],
        ),
        _Group(
          title: 'About',
          rows: [
            _GroupRowData(
              icon: Icons.info,
              tint: const Color(0xFF6BA8FF),
              title: 'About',
              desc: 'App information and reset',
              onTap: () => onOpen('about'),
            ),
            _GroupRowData(
              icon: Icons.favorite,
              tint: AppTheme.success,
              title: 'Support Development',
              desc: 'Donate via UPI or crypto to support AyX',
              onTap: () => onOpen('support'),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Account header: gold AyX icon, app name, version.
class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/icon/ayx-logo.png',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
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
                  SizedBox(height: 2),
                  Text(
                    'Version 1.1.0',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'iMAyX',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatefulWidget {
  const _StatusCard({required this.api});

  final ApiService api;

  @override
  State<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<_StatusCard> {
  bool _reachable = false;
  bool _reconnecting = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await widget.api.health();
    if (mounted) {
      setState(() {
        _reachable = ok;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dot = !_checked
        ? const Color(0xFFFFC24D)
        : _reachable
            ? AppTheme.success
            : AppTheme.danger;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _PulseDot(color: dot),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    !_checked
                        ? 'Checking…'
                        : _reachable
                            ? 'Connected'
                            : 'Not linked',
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Engine ${_reachable ? 'up' : 'down'} · device "iMAyX"',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            if (!_reachable && _checked)
              FilledButton(
                onPressed: _reconnecting
                    ? null
                    : () async {
                        setState(() => _reconnecting = true);
                        await widget.api.reconnect();
                        await _check();
                        if (mounted) {
                          setState(() => _reconnecting = false);
                        }
                      },
                child: Text(_reconnecting ? '...' : 'Reconnect'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final a = 0.4 + 0.6 * _ctrl.value;
        return SizedBox(
          width: 20,
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(a * 0.22),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(a),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupRowData {
  const _GroupRowData({
    required this.icon,
    required this.tint,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String desc;
  final VoidCallback onTap;
}

/// A section: small header label + one 16dp-radius card holding
/// icon rows with chevrons, separated by hairlines.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});

  final String title;
  final List<_GroupRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    _GroupRow(row: rows[i]),
                    if (i < rows.length - 1)
                      const Divider(color: AppTheme.border, height: 1),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.row});

  final _GroupRowData row;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: row.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: row.tint.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(row.icon, color: row.tint, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.desc,
                    style: const TextStyle(color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
