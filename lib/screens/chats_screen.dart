import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayx_widgets.dart';
import 'chat_detail_screen.dart';
import 'new_chat_screen.dart';

/// Chats tab (WZH-style): a clear search bar, a Connect card when
/// offline, then clean chat rows with lots of breathing room.
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _searchCtrl = TextEditingController();
  final ApiService _api = ApiService();
  String _query = '';
  final Set<String> _hiddenIds = {};
  bool _showHidden = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _api.dispose();
    super.dispose();
  }

  List<ChatThread> get _filtered {
    var list = DemoData.chats;
    // Hidden chats: long-press a row to hide; double-tap the
    // "WhatsAyX" title to reveal them (same as the original).
    if (!_showHidden) {
      list = list.where((c) => !_hiddenIds.contains(c.id)).toList();
    } else {
      list = list.where((c) => _hiddenIds.contains(c.id)).toList();
    }
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.lastMessage.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _chatMenu(ChatThread chat) async {
    final hidden = _hiddenIds.contains(chat.id);
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
              leading: const Icon(Icons.volume_off),
              title: const Text('Mute',
                  style: TextStyle(color: AppTheme.text)),
              onTap: () => Navigator.of(ctx).pop('mute'),
            ),
            ListTile(
              leading: Icon(hidden ? Icons.visibility : Icons.visibility_off),
              title: Text(hidden ? 'Unhide chat' : 'Hide chat',
                  style: const TextStyle(color: AppTheme.text)),
              onTap: () => Navigator.of(ctx).pop('hide'),
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_read),
              title: const Text('Mark as read',
                  style: TextStyle(color: AppTheme.text)),
              onTap: () => Navigator.of(ctx).pop('read'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.danger),
              title: const Text('Delete chat',
                  style: TextStyle(color: AppTheme.danger)),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppTheme.danger),
              title: const Text('Block',
                  style: TextStyle(color: AppTheme.danger)),
              onTap: () => Navigator.of(ctx).pop('block'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'hide':
        setState(() {
          if (hidden) {
            _hiddenIds.remove(chat.id);
          } else {
            _hiddenIds.add(chat.id);
          }
        });
        break;
      case 'read':
        await _api.markRead(chat.id);
        break;
      case 'delete':
        await _api.deleteChat(chat.id);
        break;
      case 'block':
        await _api.blockChat(chat.id);
        break;
      case 'mute':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${chat.name} muted.')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chats = _filtered;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: GestureDetector(
          onDoubleTap: () {
            // Double-tap the title reveals hidden chats (original behavior).
            setState(() => _showHidden = !_showHidden);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _showHidden
                      ? 'Hidden chats shown'
                      : 'Hidden chats hidden',
                ),
              ),
            );
          },
          child: Text(_showHidden ? 'Hidden chats' : 'WhatsAyX'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.of(context).pushNamed('/login');
            },
            tooltip: 'Link a device',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
            tooltip: 'More',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: AyxSearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AyxInfoCard(
              icon: Icons.link,
              title: 'Connect WhatsApp',
              subtitle:
                  'Link your number to see real chats here. Demo chats are shown for now.',
              onTap: () => Navigator.of(context).pushNamed('/login'),
            ),
          ),
          Expanded(
            child: chats.isEmpty
                ? const Center(
                    child: Text(
                      'No chats found.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: chats.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: AppTheme.border, height: 1),
                    itemBuilder: (context, i) {
                      final chat = chats[i];
                      return _ChatRow(
                        chat: chat,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ChatDetailScreen(chat: chat),
                            ),
                          );
                        },
                        onLongPress: () => _chatMenu(chat),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NewChatScreen(),
            ),
          );
        },
        child: const Icon(Icons.chat),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.chat,
    required this.onTap,
    required this.onLongPress,
  });

  final ChatThread chat;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: Color(chat.avatarColor).withValues(alpha: 0.2),
              child: Text(
                chat.name.isNotEmpty ? chat.name[0] : '?',
                style: TextStyle(
                  color: Color(chat.avatarColor),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        chat.time,
                        style: TextStyle(
                          color: chat.unread > 0
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: chat.unread > 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (chat.unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${chat.unread}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
