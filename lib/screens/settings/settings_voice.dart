import 'package:flutter/material.dart';

import '../../models/settings.dart';
import '../../services/settings_store.dart';
import '../../theme/app_theme.dart';
import 'settings_widgets.dart';

/// AI Voice — voice reply, voice notes & voice artists.
/// Same as the original VoicePickerScreen.
class VoiceSettingsPage extends StatefulWidget {
  const VoiceSettingsPage({super.key, required this.store});

  final SettingsStore store;

  @override
  State<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends State<VoiceSettingsPage> {
  final TextEditingController _sarvamCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sarvamCtrl.text = widget.store.current.aiSarvamKey;
  }

  @override
  void dispose() {
    _sarvamCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store.current;
    return SettingsSubPage(
      children: [
        SettingsGroup(
          title: 'Voice reply',
          child: Column(
            children: [
              SettingRow(
                icon: Icons.mic,
                tint: AppTheme.primary,
                title: 'Transcribe voice notes',
                desc:
                    'Transcribe incoming voice notes, then AI-reply with text',
                checked: s.aiReplyVoice,
                onChange: (v) => _update(s.copyWith(aiReplyVoice: v)),
              ),
              SettingRow(
                icon: Icons.graphic_eq,
                tint: AppTheme.secondary,
                title: 'Reply with a voice note',
                desc: 'Reply to incoming voice notes WITH a voice note (TTS)',
                checked: s.aiVoiceNoteReply,
                onChange: (v) => _update(s.copyWith(aiVoiceNoteReply: v)),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Voice artist (TTS)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsNote(
                'Groq PlayAI voice used for voice-note replies and /voice. '
                'Tap a voice to hear a demo.',
              ),
              ChoiceRow(
                icon: Icons.record_voice_over,
                tint: AppTheme.primary,
                title: 'TTS voice',
                value: s.aiTtsVoice,
                options: AyxOptions.ttsVoices,
                labels: {for (final v in AyxOptions.ttsVoices) v: v},
                onPick: (v) async {
                  await _update(s.copyWith(aiTtsVoice: v));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voice set')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Demo: "${s.aiTtsVoice}" bol raha hai… (gateway /ttsdemo)',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Hear demo'),
                ),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Sarvam AI',
          child: Column(
            children: [
              TextField(
                controller: _sarvamCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Sarvam API key (voice)',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await _update(
                        s.copyWith(aiSarvamKey: _sarvamCtrl.text.trim()));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sarvam key saved')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _update(AyxSettings next) async {
    await widget.store.update(next);
    if (mounted) setState(() {});
  }
}
