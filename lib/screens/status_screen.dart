import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayx_widgets.dart';

/// Status tab: clean rows with a teal ring for unviewed updates.
/// Tapping one opens a full-screen viewer (download, reply, forward).
/// Same as the original StatusScreen + StatusViewer.
class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final ApiService _api = ApiService();
  List<StatusItem> _statuses = DemoData.statuses;
  final Set<String> _mutedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await _api.fetchStatuses();
    if (!mounted) return;
    if (rows.isNotEmpty) {
      setState(() {
        _statuses = rows
            .map(
              (r) => StatusItem(
                id: r['id']?.toString() ?? '',
                name: r['name']?.toString() ?? '',
                time: r['time']?.toString() ?? '',
                viewed: r['viewed'] == true,
                avatarColor: 0xFF4DD0C4,
              ),
            )
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        _statuses.where((s) => !_mutedIds.contains(s.id)).toList();
    final muted = _statuses.where((s) => _mutedIds.contains(s.id)).toList();
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
                  content: Text(
                    'Status upload — pick a photo/video from the gallery.',
                  ),
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
          ...visible.map((s) => _StatusRow(
                item: s,
                onMute: () => setState(() => _mutedIds.add(s.id)),
              )),
          if (muted.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Muted updates',
                  style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _mutedIds.clear()),
                  child: const Text('Show all'),
                ),
              ],
            ),
            ...muted.map((s) => _StatusRow(
                  item: s,
                  muted: true,
                  onMute: () => setState(() => _mutedIds.remove(s.id)),
                )),
          ],
          const SizedBox(height: 16),
          const Text(
            'Hide status view is in Settings → General → Hide status view.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.item,
    required this.onMute,
    this.muted = false,
  });

  final StatusItem item;
  final VoidCallback onMute;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openViewer(context, item),
      onLongPress: () => _showRowMenu(context),
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
                backgroundColor: Color(item.avatarColor).withOpacity(0.2),
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
            if (muted)
              const Icon(Icons.volume_off, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _showRowMenu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(muted ? Icons.volume_up : Icons.volume_off),
              title: Text(muted ? 'Unmute' : 'Mute',
                  style: const TextStyle(color: AppTheme.text)),
              onTap: () => Navigator.of(ctx).pop('mute'),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download status',
                  style: TextStyle(color: AppTheme.text)),
              onTap: () => Navigator.of(ctx).pop('download'),
            ),
          ],
        ),
      ),
    );
    if (action == 'mute') onMute();
    if (action == 'download' && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} status saved.')),
      );
    }
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
  final TextEditingController _replyCtrl = TextEditingController();
  final ApiService _api = ApiService();

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
    _replyCtrl.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    await _api.sendMessage(widget.item.id, text);
    if (!mounted) return;
    _replyCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reply sent to ${widget.item.name}.')),
    );
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
                      Color(widget.item.avatarColor).withOpacity(0.2),
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
                  icon: const Icon(Icons.download, color: Colors.white),
                  tooltip: 'Download status',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${widget.item.name} status saved.',
                        ),
                      ),
                    );
                  },
                ),
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Reply to ${widget.item.name}…',
                          hintStyle:
                              const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendReply(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.black),
                        onPressed: _sendReply,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
