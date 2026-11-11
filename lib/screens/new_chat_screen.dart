import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayx_widgets.dart';

/// New chat — contacts from the gateway, or start by number.
/// Same as the original NewChatScreen.
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _numberCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    _numberCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final contacts = await _api.fetchContacts();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _contacts;
    final q = _query.toLowerCase();
    return _contacts
        .where((c) =>
            (c['name']?.toString() ?? '').toLowerCase().contains(q) ||
            (c['number']?.toString() ?? '').contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New chat'),
        backgroundColor: AppTheme.bg,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: AyxSearchBar(
              controller: _searchCtrl,
              hint: 'Search name or number',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numberCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Start by number (e.g. 919876543210)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () {
                    final n = _numberCtrl.text.trim();
                    if (n.isEmpty) return;
                    Navigator.of(context).pop(n);
                  },
                  child: const Text('Chat'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : contacts.isEmpty
                    ? const Center(
                        child: Text(
                          'No contacts yet — connect WhatsApp first.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: contacts.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: AppTheme.border,
                          height: 1,
                        ),
                        itemBuilder: (context, i) {
                          final c = contacts[i];
                          final name =
                              c['name']?.toString() ?? c['number'] ?? '';
                          final number = c['number']?.toString() ?? '';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primary.withOpacity(0.2),
                              child: Text(
                                name.isNotEmpty ? name[0] : '?',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(color: AppTheme.text),
                            ),
                            subtitle: Text(
                              number,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary),
                            ),
                            onTap: () =>
                                Navigator.of(context).pop(number),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
