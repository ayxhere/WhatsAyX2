import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Settings home — status card + the same 10 category cards as the
/// original SettingsHome.
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
        _StatusCard(api: api),
        const SizedBox(height: 12),
        _CategoryCard(
          icon: Icons.tune,
          tint: const Color(0xFFB69DF8),
          title: 'General',
          desc: 'Online, privacy and messages',
          onTap: () => onOpen('general'),
        ),
        _CategoryCard(
          icon: Icons.question_answer,
          tint: const Color(0xFFFFB26B),
          title: 'Auto-reply',
          desc: 'Keyword rules and automatic replies',
          onTap: () => onOpen('autoreply'),
        ),
        _CategoryCard(
          icon: Icons.auto_awesome,
          tint: AppTheme.secondary,
          title: 'AI Assistant',
          desc: 'AI replies, groups and language',
          onTap: () => onOpen('ai'),
        ),
        _CategoryCard(
          icon: Icons.graphic_eq,
          tint: AppTheme.primary,
          title: 'AI Voice',
          desc: 'Voice reply, voice notes & voice artists',
          onTap: () => onOpen('voice'),
        ),
        _CategoryCard(
          icon: Icons.chat,
          tint: AppTheme.primary,
          title: 'Chat',
          desc: 'Wallpaper, bubble style and header',
          onTap: () => onOpen('chat'),
        ),
        _CategoryCard(
          icon: Icons.palette,
          tint: const Color(0xFFFF7EB6),
          title: 'Appearance',
          desc: 'Theme and accent color',
          onTap: () => onOpen('appearance'),
        ),
        _CategoryCard(
          icon: Icons.sync,
          tint: AppTheme.secondary,
          title: 'Sync',
          desc: 'Drive backup of API keys & prompts',
          onTap: () => onOpen('sync'),
        ),
        _CategoryCard(
          icon: Icons.share,
          tint: const Color(0xFFFFB26B),
          title: 'Broadcast',
          desc: 'Send bulk messages via JSON with timer',
          onTap: () => onOpen('broadcast'),
        ),
        _CategoryCard(
          icon: Icons.info,
          tint: const Color(0xFF6BA8FF),
          title: 'About',
          desc: 'App information and reset',
          onTap: () => onOpen('about'),
        ),
        _CategoryCard(
          icon: Icons.favorite,
          tint: AppTheme.success,
          title: 'Support Development',
          desc: 'Donate via UPI or crypto to support AyX',
          onTap: () => onOpen('support'),
        ),
        const SizedBox(height: 16),
      ],
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
                  color: widget.color.withValues(alpha: a * 0.22),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: a),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tint, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
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
      ),
    );
  }
}
