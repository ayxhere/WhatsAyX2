import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayx_widgets.dart';
import 'tools/music_screen.dart';
import 'tools/schedule_screen.dart';

/// Tools tab: a clean grid of quick-tool cards (WZH-style).
/// Music + Schedule open real screens wired to the gateway; the rest
/// open a sheet (same tools as the original).
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final ApiService _api = ApiService();

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  static const List<_Tool> _tools = [
    _Tool(
      id: 'aireply',
      icon: Icons.auto_awesome,
      title: 'AI Reply',
      subtitle: 'Draft a smart reply for any chat.',
      color: AppTheme.primary,
    ),
    _Tool(
      id: 'airewrite',
      icon: Icons.edit_note,
      title: 'AI Rewrite',
      subtitle: 'Rewrite a message in a better tone.',
      color: AppTheme.secondary,
    ),
    _Tool(
      id: 'translate',
      icon: Icons.translate,
      title: 'Translate',
      subtitle: 'Translate messages instantly.',
      color: AppTheme.success,
    ),
    _Tool(
      id: 'schedule',
      icon: Icons.schedule,
      title: 'Schedule',
      subtitle: 'Send a message later, on time.',
      color: Color(0xFFFFB020),
    ),
    _Tool(
      id: 'broadcast',
      icon: Icons.campaign,
      title: 'Broadcast',
      subtitle: 'Send one message to many chats.',
      color: Color(0xFFFF6B6B),
    ),
    _Tool(
      id: 'autoreply',
      icon: Icons.mark_chat_read,
      title: 'Auto Reply',
      subtitle: 'Reply automatically when you are busy.',
      color: Color(0xFFB388FF),
    ),
    _Tool(
      id: 'music',
      icon: Icons.music_note,
      title: 'Music',
      subtitle: 'JioSaavn, iTunes & Spotify search + lyrics.',
      color: Color(0xFF4DD0E1),
    ),
    _Tool(
      id: 'deleted',
      icon: Icons.delete_outline,
      title: 'Deleted messages',
      subtitle: 'See messages that were deleted.',
      color: Color(0xFFFF7EB6),
    ),
    _Tool(
      id: 'imageai',
      icon: Icons.image,
      title: 'AI Image Edit',
      subtitle: 'Read image text, /create images.',
      color: Color(0xFF82AAFF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AyxAppBar(title: 'Tools'),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.92,
        ),
        itemCount: _tools.length,
        itemBuilder: (context, i) {
          final tool = _tools[i];
          return Card(
            child: InkWell(
              onTap: () => _onToolTap(tool),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: tool.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(tool.icon, color: tool.color, size: 25),
                    ),
                    const Spacer(),
                    Text(
                      tool.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onToolTap(_Tool tool) {
    switch (tool.id) {
      case 'music':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MusicScreen()),
        );
        return;
      case 'schedule':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ScheduleScreen()),
        );
        return;
      case 'broadcast':
      case 'autoreply':
        // These live in Settings — switch to the Settings tab is handled
        // by the parent; here we just explain where they are.
        _showToolSheet(
          context,
          tool,
          note: tool.id == 'broadcast'
              ? 'Open Settings → Broadcast to compose JSON and send with a timer.'
              : 'Open Settings → Auto-reply to add keyword rules.',
        );
        return;
      case 'deleted':
        _showDeletedSheet(tool);
        return;
      default:
        _showToolSheet(context, tool);
    }
  }

  Future<void> _showDeletedSheet(_Tool tool) async {
    final deleted = await _api.fetchDeleted();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tool.title,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (deleted.isEmpty)
                const Text(
                  'No deleted messages yet. When someone deletes a message, it shows here (Save media must be on).',
                  style: TextStyle(color: AppTheme.textSecondary),
                )
              else
                ...deleted.take(10).map(
                      (d) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${d['name'] ?? d['chat'] ?? ''}: ${d['text'] ?? ''}',
                          style: const TextStyle(color: AppTheme.text),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showToolSheet(BuildContext context, _Tool tool, {String? note}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tool.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(tool.icon, color: tool.color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    tool.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                tool.subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                note ??
                    'This tool runs through the Node gateway. Connect WhatsApp first, then it will work from any chat.',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tool {
  const _Tool({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
