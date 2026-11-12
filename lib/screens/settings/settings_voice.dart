import 'package:flutter/material.dart';

import '../../models/settings.dart';
import '../../services/settings_store.dart';
import '../../services/voice_service.dart';
import '../../theme/app_theme.dart';
import 'settings_widgets.dart';

/// Voice (on-device) — Supertonic 3 TTS via sherpa-onnx, downloaded
/// on first use.
///
/// Replaces the old Groq PlayAI + Sarvam page entirely: no API key, no
/// cloud, no per-voice server list. The model (~139 MB) downloads once
/// into the app documents dir and is never bundled in the APK.
/// Kokoro was the first fallback and was rejected by the user
/// ("Kokoro mat use kar"); VoxCPM was checked first and does NOT fit
/// a phone (2B params, ~5 GB weights, needs an 8 GB-VRAM GPU).
/// Supertonic 3 is the same soft Hindi voice family the Hindi dubbing
/// pipeline already uses — 31 languages incl. Hindi, 10 voices.
class VoiceSettingsPage extends StatefulWidget {
  const VoiceSettingsPage({super.key, required this.store});

  final SettingsStore store;

  @override
  State<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends State<VoiceSettingsPage> {
  final VoiceService _voice = VoiceService();

  bool _downloaded = false;
  int _downloadedBytes = 0;
  bool _downloading = false;
  double _progress = 0;
  String? _error;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _speed = widget.store.current.voiceSpeed;
    _refreshStatus();
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final downloaded = await _voice.isDownloaded();
    final bytes = await _voice.downloadedBytes();
    if (!mounted) return;
    setState(() {
      _downloaded = downloaded;
      _downloadedBytes = bytes;
    });
  }

  String get _sizeLabel =>
      '${(_downloadedBytes / (1024 * 1024)).toStringAsFixed(0)} MB';

  String get _statusText {
    if (_downloading) {
      return 'Downloading… ${(_progress * 100).toStringAsFixed(0)}%';
    }
    if (_downloaded) return 'Ready — Supertonic 3 on-device ($_sizeLabel)';
    if (_downloadedBytes > 0) {
      return 'Partial download ($_sizeLabel) — tap Download to finish';
    }
    return 'Not downloaded';
  }

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });
    try {
      await _voice.downloadModel(
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _progress =
                total > 0 ? (received / total).clamp(0.0, 1.0) : 0;
          });
        },
      );
      await _refreshStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Delete voice model?',
          style: TextStyle(color: AppTheme.text),
        ),
        content: const Text(
          'This frees ~139 MB. You can download it again any time.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _voice.deleteModel();
    await _refreshStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice model deleted')),
      );
    }
  }

  Future<void> _demo() async {
    if (!VoiceService.engineReady || !_downloaded) return;
    try {
      final s = widget.store.current;
      await _voice.synthesize(
        text: 'Namaste! Main aapki on-device awaaz hoon.',
        voice: s.voiceEngineVoice,
        speed: s.voiceSpeed,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store.current;
    final demoEnabled = VoiceService.engineReady && _downloaded;
    return SettingsSubPage(
      children: [
        SettingsGroup(
          title: 'Voice (on-device)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsNote(
                'Supertonic 3 runs fully on-device — no API key, no '
                'cloud. Same soft Hindi voice family as the dubbing '
                'pipeline: 10 voices (F1–F5 female, M1–M5 male), Hindi '
                'plus 30 more languages.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _downloaded
                        ? Icons.check_circle
                        : Icons.download_for_offline,
                    color: _downloaded
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusText,
                      style: const TextStyle(color: AppTheme.text),
                    ),
                  ),
                ],
              ),
              if (_downloading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _progress),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.danger),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      (_downloading || _downloaded) ? null : _download,
                  icon: const Icon(Icons.download),
                  label: Text(
                    _downloading
                        ? 'Downloading…'
                        : _downloaded
                            ? 'Downloaded'
                            : 'Download voice (~139 MB)',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const SettingsNote(
                'Download is ~139 MB — use Wi-Fi. The model is NOT '
                'bundled in the APK, so the app stays lite.',
              ),
              if (_downloaded || _downloadedBytes > 0) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _downloading ? null : _delete,
                    icon: const Icon(Icons.delete, color: AppTheme.danger),
                    label: const Text(
                      'Delete model',
                      style: TextStyle(color: AppTheme.danger),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Voice',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsNote(
                'Hindi voices: write Hindi in Devanagari for best '
                'results — Roman Hindi sounds wrong.',
              ),
              ChoiceRow(
                icon: Icons.record_voice_over,
                tint: AppTheme.primary,
                title: 'Voice',
                value: s.voiceEngineVoice,
                options: AyxOptions.supertonicVoices,
                labels: AyxOptions.supertonicVoiceLabels,
                onPick: (v) async {
                  await _update(s.copyWith(voiceEngineVoice: v));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voice set')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.speed,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  Expanded(
                    child: Slider(
                      value: _speed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: '${_speed.toStringAsFixed(1)}×',
                      onChanged: (v) => setState(() => _speed = v),
                      onChangeEnd: (v) async {
                        await _update(
                          widget.store.current.copyWith(voiceSpeed: v),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${_speed.toStringAsFixed(1)}×',
                      style: const TextStyle(color: AppTheme.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: demoEnabled ? _demo : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Hear demo'),
                ),
              ),
              if (!demoEnabled)
                const SettingsNote(
                  'Hear demo needs the voice model downloaded first.',
                ),
            ],
          ),
        ),
        settingsGap(),
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
                desc: 'Reply to incoming voice notes WITH a voice note',
                checked: s.aiVoiceNoteReply,
                onChange: (v) => _update(s.copyWith(aiVoiceNoteReply: v)),
              ),
              const SettingsNote(
                'Voice-note replies speak with the on-device voice once '
                'the model is downloaded.',
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
