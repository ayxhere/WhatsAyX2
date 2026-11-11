import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ayx_widgets.dart';

/// Tools tab: a clean grid of quick-tool cards (WZH-style).
/// Each card opens a small sheet explaining the tool. Real AI
/// actions arrive with the gateway; v1 keeps the surface clean.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const List<_Tool> _tools = [
    _Tool(
      icon: Icons.auto_awesome,
      title: 'AI Reply',
      subtitle: 'Draft a smart reply for any chat.',
      color: AppTheme.primary,
    ),
    _Tool(
      icon: Icons.edit_note,
      title: 'AI Rewrite',
      subtitle: 'Rewrite a message in a better tone.',
      color: AppTheme.secondary,
    ),
    _Tool(
      icon: Icons.translate,
      title: 'Translate',
      subtitle: 'Translate messages instantly.',
      color: AppTheme.success,
    ),
    _Tool(
      icon: Icons.schedule,
      title: 'Schedule',
      subtitle: 'Send a message later, on time.',
      color: Color(0xFFFFB020),
    ),
    _Tool(
      icon: Icons.campaign,
      title: 'Broadcast',
      subtitle: 'Send one message to many chats.',
      color: Color(0xFFFF6B6B),
    ),
    _Tool(
      icon: Icons.mark_chat_read,
      title: 'Auto Reply',
      subtitle: 'Reply automatically when you are busy.',
      color: Color(0xFFB388FF),
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
              onTap: () => _showToolSheet(context, tool),
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

  void _showToolSheet(BuildContext context, _Tool tool) {
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
              const Text(
                'This tool runs through the Node gateway. Connect WhatsApp first, then it will work from any chat.',
                style: TextStyle(color: AppTheme.textSecondary),
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
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
