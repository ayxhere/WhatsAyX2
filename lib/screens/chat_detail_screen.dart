import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// One-to-one chat view: clean bubbles, a roomy input bar.
/// Long-press a message for the action menu (reply, forward, react,
/// edit, delete, translate, info) — same as the original.
/// Sending goes through the gateway when connected, local otherwise.
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.chat});

  final ChatThread chat;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final ApiService _api = ApiService();
  late final List<ChatMessage> _messages;
  ChatMessage? _replyTo;

  @override
  void initState() {
    super.initState();
    _messages = List<ChatMessage>.from(DemoData.messages);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          id: 'm${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          isMe: true,
          time: 'now',
        ),
      );
      _inputCtrl.clear();
      _replyTo = null;
    });
    await _api.sendMessage(widget.chat.id, text);
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _messageMenu(ChatMessage m) async {
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
              leading: const Icon(Icons.reply),
              title: const Text('Reply',
                  style: TextStyle(color: AppTheme.text)),
              onTap: () => Navigator.of(ctx).pop('reply'),
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward',
                  style: TextStyle(color: AppTheme.text)),
              onTap: () => Navigator.of(ctx).pop('forward'),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('React',
                  style: TextStyle(color: AppTheme.text)),
              onTap: () => Navigator.of(ctx).pop('react'),
            ),
            if (m.isMe)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit',
                    style: TextStyle(color: AppTheme.text)),
                onTap: () => Navigator.of(ctx).pop('edit'),
              ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('Translate',
                  style: TextStyle(color: AppTheme.text)),
              onTap: () => Navigator.of(ctx).pop('translate'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Info',
                  style: TextStyle(color: AppTheme.text)),
              onTap: () => Navigator.of(ctx).pop('info'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.danger),
              title: const Text('Delete',
                  style: TextStyle(color: AppTheme.danger)),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'reply':
        setState(() => _replyTo = m);
        break;
      case 'forward':
        await _api.forwardMessage(widget.chat.id, m.id, []);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick chats to forward to.')),
        );
        break;
      case 'react':
        await _api.react(widget.chat.id, m.id, '❤️');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reacted ❤️')),
        );
        break;
      case 'edit':
        final ctrl = TextEditingController(text: m.text);
        final saved = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Edit message',
                style: TextStyle(color: AppTheme.text)),
            content: TextField(controller: ctrl, maxLines: 4),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        if (saved != null && saved.isNotEmpty) {
          await _api.editMessage(widget.chat.id, m.id, saved);
          setState(() {
            final i = _messages.indexWhere((x) => x.id == m.id);
            if (i >= 0) {
              _messages[i] = ChatMessage(
                id: m.id,
                text: saved,
                isMe: m.isMe,
                time: m.time,
              );
            }
          });
        }
        break;
      case 'translate':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translated: "${m.text}"')),
        );
        break;
      case 'info':
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Message info',
                style: TextStyle(color: AppTheme.text)),
            content: Text(
              'Sent: ${m.time}\nFrom: ${m.isMe ? 'You' : widget.chat.name}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        break;
      case 'delete':
        await _api.deleteMessage(widget.chat.id, m.id);
        setState(() => _messages.removeWhere((x) => x.id == m.id));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  Color(widget.chat.avatarColor).withOpacity(0.2),
              child: Text(
                widget.chat.name.isNotEmpty ? widget.chat.name[0] : '?',
                style: TextStyle(
                  color: Color(widget.chat.avatarColor),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'online',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isMe = m.isMe;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: () => _messageMenu(m),
                    child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          m.text,
                          style: TextStyle(
                            color: isMe ? Colors.black : AppTheme.text,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          m.time,
                          style: TextStyle(
                            color: isMe
                                ? Colors.black54
                                : AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_replyTo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.reply,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to: ${_replyTo!.text}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppTheme.textSecondary, size: 18),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      style: const TextStyle(color: AppTheme.text),
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        prefixIcon: Icon(
                          Icons.emoji_emotions_outlined,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
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
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
