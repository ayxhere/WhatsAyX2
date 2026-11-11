import 'package:flutter/material.dart';

import '../../models/settings.dart';
import '../../services/api_service.dart';
import '../../services/settings_store.dart';
import '../../theme/app_theme.dart';
import 'settings_widgets.dart';

/// AI Assistant — replies, AI tools, commands, reply language, excluded
/// chats, API config, AI Lyrics, Image AI. Same as the original AiSettings.
class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({
    super.key,
    required this.store,
    required this.api,
    required this.onOpenMemory,
    required this.onOpenVoice,
  });

  final SettingsStore store;
  final ApiService api;
  final VoidCallback onOpenMemory;
  final VoidCallback onOpenVoice;

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  late final TextEditingController _langCtrl;
  late final TextEditingController _apiUrlCtrl;
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _apiModelCtrl;
  late final TextEditingController _sysCtrl;
  late final TextEditingController _visionUrlCtrl;
  late final TextEditingController _visionKeyCtrl;
  late final TextEditingController _visionModelCtrl;
  late final TextEditingController _excludeCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.store.current;
    _langCtrl = TextEditingController(text: s.aiReplyLang);
    _apiUrlCtrl = TextEditingController(text: s.aiApiUrl);
    _apiKeyCtrl = TextEditingController(text: s.aiApiKey);
    _apiModelCtrl = TextEditingController(text: s.aiModel);
    _sysCtrl = TextEditingController(text: s.aiSystemPrompt);
    _visionUrlCtrl = TextEditingController(text: s.aiVisionApiUrl);
    _visionKeyCtrl = TextEditingController(text: s.aiVisionApiKey);
    _visionModelCtrl = TextEditingController(text: s.aiVisionModel);
    _excludeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _langCtrl.dispose();
    _apiUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _apiModelCtrl.dispose();
    _sysCtrl.dispose();
    _visionUrlCtrl.dispose();
    _visionKeyCtrl.dispose();
    _visionModelCtrl.dispose();
    _excludeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store.current;
    return SettingsSubPage(
      children: [
        const SettingsNote('Powered by Groq AI'),
        SettingsGroup(
          title: 'Replies',
          child: Column(
            children: [
              SettingRow(
                icon: Icons.auto_awesome,
                tint: AppTheme.secondary,
                title: 'AI reply (master)',
                desc:
                    'Master switch — OFF stops ALL AI replies (text, image, voice, groups). Keyword rules still work',
                checked: s.aiReplyEnabled,
                onChange: (v) => _update(s.copyWith(aiReplyEnabled: v)),
              ),
              SettingRow(
                icon: Icons.image,
                tint: const Color(0xFFFFB26B),
                title: 'Image reply',
                desc:
                    'AI looks at incoming images (vision) then swipe-replies',
                checked: s.aiReplyImage,
                onChange: (v) => _update(s.copyWith(aiReplyImage: v)),
              ),
              SettingRow(
                icon: Icons.question_answer,
                tint: const Color(0xFFB69DF8),
                title: 'Group AI reply',
                desc:
                    'Answer greetings/questions in groups (max 10/day); /ai works anytime',
                checked: s.groupAiEnabled,
                onChange: (v) => _update(s.copyWith(groupAiEnabled: v)),
              ),
              const SettingsNote(
                'Image replies come as a swipe-left quote on the exact message. '
                'Voice note reply is now in "AI Voice" settings.',
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'AI tools',
          child: Column(
            children: [
              ActionRow(
                icon: Icons.memory,
                tint: AppTheme.secondary,
                title: 'AI Memory',
                desc: 'What the AI remembers about each contact',
                onTap: widget.onOpenMemory,
              ),
              ActionRow(
                icon: Icons.graphic_eq,
                tint: AppTheme.primary,
                title: 'AI Voice',
                desc: 'Voice reply, voice notes & voice artists',
                onTap: widget.onOpenVoice,
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Commands',
          child: Column(
            children: [
              SettingRow(
                icon: Icons.terminal,
                tint: const Color(0xFFB69DF8),
                title: 'Enable /create, /prompt & /voice',
                desc:
                    '/create <text> → image · /prompt on an image → its prompt · /voice <text> → voice note',
                checked: s.aiCommandsEnabled,
                onChange: (v) => _update(s.copyWith(aiCommandsEnabled: v)),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Reply language',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsNote(
                'Pick one language — the AI replies only in it (stops '
                'Hindi/Bangla mixing). "Auto" mirrors the sender\'s language.',
              ),
              ChoiceRow(
                icon: Icons.language,
                tint: AppTheme.secondary,
                title: 'Reply language',
                value: s.aiLangMode,
                options: AyxOptions.langModes,
                labels: AyxOptions.langModeLabels,
                onPick: (v) => _update(s.copyWith(aiLangMode: v)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _langCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Custom language instruction',
                  hintText:
                      'e.g. Reply only in Roman Bangla, English letters',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await _update(
                        s.copyWith(aiReplyLang: _langCtrl.text.trim()));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Language saved')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: "Don't reply to these chats",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsNote(
                'Add chats here to stop AI (and keyword auto-reply) from '
                'replying to them.',
              ),
              if (s.aiExcludeJids.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No excluded chats.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              for (final jid in s.aiExcludeJids)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          jid,
                          style: const TextStyle(color: AppTheme.text),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppTheme.danger,
                        ),
                        onPressed: () async {
                          final list =
                              List<String>.from(s.aiExcludeJids)..remove(jid);
                          await _update(s.copyWith(aiExcludeJids: list));
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _excludeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Chat name or number',
                        hintText: 'e.g. 919876543210',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () async {
                      final v = _excludeCtrl.text.trim();
                      if (v.isEmpty) return;
                      final list = List<String>.from(s.aiExcludeJids)
                        ..add(v);
                      _excludeCtrl.clear();
                      await _update(s.copyWith(aiExcludeJids: list));
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'API configuration (text/voice)',
          child: Column(
            children: [
              TextField(
                controller: _apiUrlCtrl,
                decoration: const InputDecoration(labelText: 'API URL (text/voice)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _apiKeyCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'API key'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _apiModelCtrl,
                decoration: const InputDecoration(labelText: 'Model (text)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _sysCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'System prompt (optional)',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await _update(s.copyWith(
                      aiApiUrl: _apiUrlCtrl.text.trim(),
                      aiApiKey: _apiKeyCtrl.text.trim(),
                      aiModel: _apiModelCtrl.text.trim(),
                      aiSystemPrompt: _sysCtrl.text.trim(),
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API settings saved')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await widget.api.health();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Gateway reachable — API settings will apply on the next AI reply.'
                                : 'Gateway unreachable — check the gateway is running.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Test gateway connection'),
                ),
              ),
              if (s.aiApiKey.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await _update(s.copyWith(aiApiKey: ''));
                    _apiKeyCtrl.clear();
                    if (mounted) setState(() {});
                  },
                  child: const Text(
                    'Remove key',
                    style: TextStyle(color: AppTheme.danger),
                  ),
                ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Vision API (image replies)',
          child: Column(
            children: [
              TextField(
                controller: _visionUrlCtrl,
                decoration: const InputDecoration(labelText: 'Vision API URL'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _visionKeyCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Vision API key'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _visionModelCtrl,
                decoration:
                    const InputDecoration(labelText: 'Vision model'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await _update(s.copyWith(
                      aiVisionApiUrl: _visionUrlCtrl.text.trim(),
                      aiVisionApiKey: _visionKeyCtrl.text.trim(),
                      aiVisionModel: _visionModelCtrl.text.trim(),
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Vision settings saved')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'AI Lyrics',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsNote(
                'Lyrics translate APIs, tried in order. Add your own API '
                '(name + URL + key).',
              ),
              if (s.aiLyricsApis.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No lyrics APIs added.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              for (final api in s.aiLyricsApis)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              api.name,
                              style: const TextStyle(
                                color: AppTheme.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              api.url,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppTheme.danger,
                        ),
                        onPressed: () async {
                          final list =
                              List<LyricApi>.from(s.aiLyricsApis)..remove(api);
                          await _update(s.copyWith(aiLyricsApis: list));
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _editLyricApi(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add lyrics API'),
                ),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'AI image edit',
          child: Column(
            children: [
              SettingRow(
                icon: Icons.text_fields,
                tint: const Color(0xFF80DEEA),
                title: 'Read image text on phone',
                desc:
                    'Offline & unlimited. Screenshot/text image ka reply tab bhi jab vision API down ho.',
                checked: s.aiImageOcr,
                onChange: (v) => _update(s.copyWith(aiImageOcr: v)),
              ),
              SettingRow(
                icon: Icons.image,
                tint: const Color(0xFFFFB26B),
                title: 'Free image generation',
                desc: 'Generate images without a paid key',
                checked: s.aiImageFree,
                onChange: (v) => _update(s.copyWith(aiImageFree: v)),
              ),
              SettingRow(
                icon: Icons.forum,
                tint: AppTheme.secondary,
                title: 'Full conversation context',
                desc: 'Send the real recent conversation (both sides) to the AI every reply',
                checked: s.aiFullContext,
                onChange: (v) => _update(s.copyWith(aiFullContext: v)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editLyricApi(LyricApi? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final urlCtrl = TextEditingController(text: existing?.url ?? '');
    final keyCtrl = TextEditingController(text: existing?.key ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          existing == null ? 'Add lyrics API' : 'Edit lyrics API',
          style: const TextStyle(color: AppTheme.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'API URL'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'API key'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final name = nameCtrl.text.trim();
    final url = urlCtrl.text.trim();
    if (name.isEmpty || url.isEmpty) return;
    final s = widget.store.current;
    final list = List<LyricApi>.from(s.aiLyricsApis);
    if (existing == null) {
      list.add(LyricApi(name: name, url: url, key: keyCtrl.text.trim()));
    } else {
      final i = list.indexOf(existing);
      if (i >= 0) {
        list[i] = LyricApi(name: name, url: url, key: keyCtrl.text.trim());
      }
    }
    await _update(s.copyWith(aiLyricsApis: list));
  }

  Future<void> _update(AyxSettings next) async {
    await widget.store.update(next);
    if (mounted) setState(() {});
  }
}
