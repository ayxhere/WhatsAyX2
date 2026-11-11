import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../theme/app_theme.dart';
import '../widgets/ayx_widgets.dart';

/// Status tab: clean rows with a teal ring for unviewed updates.
/// Tapping one opens a simple full-screen viewer.
class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AyxAppBar(title: 'Status'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          AyxInfoCard(
            icon: Icons.add_circle_outline,
            title: 'My status',
            subtitle: 'Tap to add a photo, video or text update.',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Status upload — coming in the next update.'),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent updates',
            style: TextStyle(
              color: AppTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...DemoData.statuses.map((s) => _StatusRow(item: s)),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.item});

  final StatusItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openViewer(context, item),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.viewed ? AppTheme.border : AppTheme.primary,
                  width: 2.5,
                ),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Color(item.avatarColor).withValues(alpha: 0.2),
                child: Text(
                  item.name.isNotEmpty ? item.name[0] : '?',
                  style: TextStyle(
                    color: Color(item.avatarColor),
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.time,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openViewer(BuildContext context, StatusItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _StatusViewer(item: item),
      ),
    );
  }
}

/// Minimal full-screen status viewer with an animated progress bar.
class _StatusViewer extends StatefulWidget {
  const _StatusViewer({required this.item});

  final StatusItem item;

  @override
  State<_StatusViewer> createState() => _StatusViewerState();
}

class _StatusViewerState extends State<_StatusViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: _ctrl.value,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primary,
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      Color(widget.item.avatarColor).withValues(alpha: 0.2),
                  child: Text(
                    widget.item.name.isNotEmpty ? widget.item.name[0] : '?',
                    style: TextStyle(
                      color: Color(widget.item.avatarColor),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.item.time,
                  style: const TextStyle(color: Colors.white60),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${widget.item.name}\nstatus preview',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
