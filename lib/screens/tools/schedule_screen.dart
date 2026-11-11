import 'package:flutter/material.dart';

import '../../models/settings.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Schedule — send a message later. Same as the original Reschedule:
/// tasks are pending / processing / sent / failed / cancelled.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ApiService _api = ApiService();
  List<ScheduledTask> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final tasks = await _api.fetchSchedule();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Color _statusColor(String status) => switch (status) {
        'sent' => AppTheme.success,
        'failed' => AppTheme.danger,
        'cancelled' => AppTheme.textSecondary,
        'processing' => const Color(0xFFFFC24D),
        _ => AppTheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: AppTheme.bg,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No scheduled messages yet.\nTap + to schedule one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, i) {
                    final t = _tasks[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t.name,
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(t.status)
                                        .withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    t.status,
                                    style: TextStyle(
                                      color: _statusColor(t.status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.text,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sends at ${t.sendAt}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (t.status == 'pending')
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () async {
                                    await _api.cancelScheduledTask(t.id);
                                    _refresh();
                                  },
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: AppTheme.danger),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addTask() async {
    final jidCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    final minutesCtrl = TextEditingController(text: '60');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Schedule a message',
            style: TextStyle(color: AppTheme.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: jidCtrl,
              decoration: const InputDecoration(
                labelText: 'Chat (name or number)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minutesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Send in (minutes)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final jid = jidCtrl.text.trim();
    final text = textCtrl.text.trim();
    final minutes = int.tryParse(minutesCtrl.text.trim()) ?? 0;
    if (jid.isEmpty || text.isEmpty || minutes <= 0) return;
    final task = ScheduledTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      jid: jid,
      name: jid,
      text: text,
      sendAt: DateTime.now().add(Duration(minutes: minutes)),
    );
    await _api.saveScheduledTask(task);
    _refresh();
  }
}
