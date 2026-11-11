import 'package:flutter/material.dart';

import '../../models/settings.dart';
import '../../services/settings_store.dart';
import '../../theme/app_theme.dart';
import 'settings_widgets.dart';

/// Appearance — theme, UI style, accent, blur & animation, text animation,
/// message motion, icon style, font, emoji, translation, status + voice
/// note styles. Same as the original AppearanceSettings + sub-pages.
class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key, required this.store});

  final SettingsStore store;

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  final TextEditingController _translateLangCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _translateLangCtrl.text = widget.store.current.translateLang;
  }

  @override
  void dispose() {
    _translateLangCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store.current;
    return SettingsSubPage(
      children: [
        SettingsGroup(
          title: 'Theme',
          child: Column(
            children: [
              ChoiceRow(
                icon: Icons.dark_mode,
                tint: AppTheme.primary,
                title: 'Theme mode',
                desc: 'Dark was removed — stored "dark" means AMOLED',
                value: s.themeMode,
                options: AyxOptions.themeModes,
                labels: AyxOptions.themeModeLabels,
                onPick: (v) => _update(s.copyWith(themeMode: v)),
              ),
              ChoiceRow(
                icon: Icons.style,
                tint: AppTheme.secondary,
                title: 'UI style',
                desc: 'Interface style — never resets theme or accent',
                value: s.uiStyle,
                options: AyxOptions.uiStyles,
                labels: AyxOptions.uiStyleLabels,
                onPick: (v) => _update(s.copyWith(uiStyle: v)),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Accent color',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsNote(
                'Theme and accent apply instantly across the whole app.',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AyxOptions.accents.map((a) {
                  final isSelected = a.key == s.accent;
                  return GestureDetector(
                    onTap: () => _update(s.copyWith(accent: a.key)),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Color(a.value),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.text
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Current: ${s.accent}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Effects',
          child: Column(
            children: [
              SettingRow(
                icon: Icons.blur_on,
                tint: AppTheme.secondary,
                title: 'Material blur',
                desc: 'Frosted surfaces and blurred headers',
                checked: s.materialBlurEnabled,
                onChange: (v) => _update(s.copyWith(materialBlurEnabled: v)),
              ),
              ChoiceRow(
                icon: Icons.animation,
                tint: AppTheme.primary,
                title: 'Text Animation',
                desc: 'Typing, delete and cursor effects',
                value: s.textAnimStyle,
                options: const ['default', 'typewriter', 'fade', 'slide'],
                labels: const {
                  'default': 'Default',
                  'typewriter': 'Typewriter',
                  'fade': 'Fade',
                  'slide': 'Slide',
                },
                onPick: (v) => _update(s.copyWith(textAnimStyle: v)),
              ),
              ChoiceRow(
                icon: Icons.motion_photos_on,
                tint: const Color(0xFFFF7EB6),
                title: 'Message Motion',
                desc: 'Entrance animation for chat messages',
                value: s.msgMotionStyle,
                options: const ['default', 'slide', 'fade', 'pop'],
                labels: const {
                  'default': 'Default',
                  'slide': 'Slide',
                  'fade': 'Fade',
                  'pop': 'Pop',
                },
                onPick: (v) => _update(s.copyWith(msgMotionStyle: v)),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Font & Emoji',
          child: Column(
            children: [
              ChoiceRow(
                icon: Icons.text_fields,
                tint: const Color(0xFFB69DF8),
                title: 'App font',
                desc: 'Current: ${s.appFont} · preview, pick or upload .ttf/.otf',
                value: s.appFont,
                options: AyxOptions.fonts,
                labels: {for (final f in AyxOptions.fonts) f: f},
                onPick: (v) => _update(s.copyWith(appFont: v)),
              ),
              ChoiceRow(
                icon: Icons.emoji_emotions,
                tint: const Color(0xFFB69DF8),
                title: 'Emoji',
                desc:
                    'Current: ${s.emojiStyle} · download & apply emoji style',
                value: s.emojiStyle,
                options: AyxOptions.emojiStyles,
                labels: {for (final e in AyxOptions.emojiStyles) e: e},
                onPick: (v) => _update(s.copyWith(emojiStyle: v)),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Message translation',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsNote(
                'Double-tap any message in a chat to translate it. Pick how it works:',
              ),
              ChoiceRow(
                icon: Icons.translate,
                tint: AppTheme.success,
                title: 'Translation',
                value: s.translateMode,
                options: AyxOptions.translateModes,
                labels: AyxOptions.translateModeLabels,
                onPick: (v) => _update(s.copyWith(translateMode: v)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _translateLangCtrl,
                decoration: const InputDecoration(
                  labelText: 'Translate to',
                ),
                onSubmitted: (v) async {
                  await _update(s.copyWith(
                      translateLang: v.trim().isEmpty ? 'English' : v.trim()));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Translate language saved')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Icons',
          child: Column(
            children: [
              ChoiceRow(
                icon: Icons.widgets,
                tint: AppTheme.primary,
                title: 'Icon Style',
                desc: 'Icons across chats, composer and menus',
                value: s.iconStyle,
                options: const ['default', 'material', 'ios', 'nothing'],
                labels: const {
                  'default': 'Default',
                  'material': 'Material',
                  'ios': 'iOS',
                  'nothing': 'Nothing',
                },
                onPick: (v) => _update(s.copyWith(iconStyle: v)),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Status',
          child: Column(
            children: [
              ChoiceRow(
                icon: Icons.circle_outlined,
                tint: AppTheme.primary,
                title: 'Status style',
                desc: 'Progress bar shown on top of the status viewer',
                value: s.statusProgressStyle,
                options: AyxOptions.statusProgressStyles,
                labels: {
                  for (final v in AyxOptions.statusProgressStyles)
                    v: v[0].toUpperCase() + v.substring(1),
                },
                onPick: (v) => _update(s.copyWith(statusProgressStyle: v)),
              ),
              ChoiceRow(
                icon: Icons.graphic_eq,
                tint: AppTheme.secondary,
                title: 'Voice note style',
                desc: 'Progress line shown in voice message bubbles',
                value: s.voiceNoteStyle,
                options: AyxOptions.voiceNoteStyles,
                labels: {
                  for (final v in AyxOptions.voiceNoteStyles)
                    v: v[0].toUpperCase() + v.substring(1),
                },
                onPick: (v) => _update(s.copyWith(voiceNoteStyle: v)),
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
