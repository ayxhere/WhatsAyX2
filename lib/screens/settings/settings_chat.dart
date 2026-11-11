import 'package:flutter/material.dart';

import '../../models/settings.dart';
import '../../services/settings_store.dart';
import '../../theme/app_theme.dart';
import 'settings_widgets.dart';

/// Chat — wallpaper, bubble style, bubble colors, header blur, header pill,
/// message menu. Same as the original ChatSettings + WallpaperSettings.
class ChatSettingsPage extends StatefulWidget {
  const ChatSettingsPage({super.key, required this.store});

  final SettingsStore store;

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final s = widget.store.current;
    return SettingsSubPage(
      children: [
        SettingsGroup(
          title: 'Wallpaper',
          child: Column(
            children: [
              ActionRow(
                icon: Icons.wallpaper,
                tint: AppTheme.primary,
                title: 'Chat Wallpaper',
                desc: 'Set or remove chat background',
                onTap: () => _snack(
                  'Wallpaper picker — choose a photo from the gallery. (File picker wiring is next; the setting is stored.)',
                ),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Bubble style',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live preview, same as the original's bubble preview.
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(
                          _bubbleRadius(s.bubbleStyle)),
                    ),
                    child: const Text(
                      'Hey! 👋',
                      style: TextStyle(color: AppTheme.text),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(
                          _bubbleRadius(s.bubbleStyle)),
                    ),
                    child: const Text(
                      'Looks great 🎉',
                      style: TextStyle(color: AppTheme.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ChoiceRow(
                icon: Icons.chat_bubble,
                tint: AppTheme.primary,
                title: 'Bubble style',
                value: s.bubbleStyle,
                options: AyxOptions.bubbleStyles,
                labels: AyxOptions.bubbleStyleLabels,
                onPick: (v) => _update(s.copyWith(bubbleStyle: v)),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Bubble color',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsNote('Sent (right side)'),
              const SizedBox(height: 8),
              _SwatchRow(
                selected: s.sentColor,
                onPick: (c) => _update(s.copyWith(sentColor: c)),
              ),
              const SizedBox(height: 12),
              const SettingsNote('Received (left side)'),
              const SizedBox(height: 8),
              _SwatchRow(
                selected: s.recvColor,
                onPick: (c) => _update(s.copyWith(recvColor: c)),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Chat header blur',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsNote(
                'Higher = more see-through frosted header over your wallpaper. Applies instantly.',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AyxOptions.headerBlurSteps
                    .map(
                      (dp) => ChoiceChip(
                        label: Text('$dp'),
                        selected: s.headerBlurDp == dp,
                        onSelected: (_) =>
                            _update(s.copyWith(headerBlurDp: dp)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Header pill',
          child: Column(
            children: [
              SettingRow(
                icon: Icons.rounded_corner,
                tint: AppTheme.secondary,
                title: 'Rounded header pill',
                desc:
                    'Subtle dark glass pill behind the profile picture, name and menu. Applies instantly.',
                checked: s.headerPillEnabled,
                onChange: (v) => _update(s.copyWith(headerPillEnabled: v)),
              ),
            ],
          ),
        ),
        settingsGap(),
        SettingsGroup(
          title: 'Message menu',
          child: Column(
            children: [
              const SettingsNote(
                'Long-press a message: blurred chat, message floats in place, pop-in menu.',
              ),
              ActionRow(
                icon: Icons.more_horiz,
                tint: AppTheme.primary,
                title: 'Message menu',
                desc: 'Reply, forward, react, edit, delete, translate',
                onTap: () => _snack(
                  'Long-press any message in a chat to open the menu.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _bubbleRadius(String style) {
    switch (style) {
      case 'iosround':
      case 'rounded':
        return 20;
      case 'compact':
        return 8;
      case 'material':
        return 6;
      default:
        return 14;
    }
  }

  Future<void> _update(AyxSettings next) async {
    await widget.store.update(next);
    if (mounted) setState(() {});
  }

  void _snack(String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

/// Color swatch row (original ChatStyle.bubblePalette; 0 = default/auto).
class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.selected, required this.onPick});

  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AyxOptions.bubblePalette.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () => onPick(c),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c == 0 ? AppTheme.surfaceVariant : Color(c),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.border,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: c == 0
                ? const Icon(Icons.close, size: 16, color: AppTheme.textSecondary)
                : isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
          ),
        );
      }).toList(),
    );
  }
}
