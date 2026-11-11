import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Shared WZH-style settings building blocks (same look as the original's
/// SettingsGroup / SettingRow / ActionRow, restyled clean).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// A toggle row: icon chip + title + description + Switch.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    this.desc,
    required this.checked,
    required this.onChange,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String? desc;
  final bool checked;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (desc != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc!,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: checked,
            activeColor: AppTheme.primary,
            onChanged: onChange,
          ),
        ],
      ),
    );
  }
}

/// A tappable row that opens something (sub-page, picker, system screen).
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    this.desc,
    this.value,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String? desc;
  final String? value;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: danger ? AppTheme.danger : AppTheme.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (desc != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      desc!,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// A row that picks one value from a list (opens a simple dialog).
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    this.desc,
    required this.value,
    required this.options,
    required this.labels,
    required this.onPick,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String? desc;
  final String value;
  final List<String> options;
  final Map<String, String> labels;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ActionRow(
      icon: icon,
      tint: tint,
      title: title,
      desc: desc,
      value: labels[value] ?? value,
      onTap: () async {
        final picked = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
            backgroundColor: AppTheme.surface,
            title: Text(
              title,
              style: const TextStyle(color: AppTheme.text),
            ),
            children: options
                .map(
                  (o) => SimpleDialogOption(
                    onPressed: () => Navigator.of(ctx).pop(o),
                    child: Row(
                      children: [
                        if (o == value)
                          const Icon(
                            Icons.check,
                            color: AppTheme.primary,
                            size: 18,
                          )
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(
                          labels[o] ?? o,
                          style: const TextStyle(color: AppTheme.text),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        );
        if (picked != null) onPick(picked);
      },
    );
  }
}

/// Standard scrollable sub-page wrapper (matches the original's
/// SettingsSubPage: 16dp sides, 14dp gaps).
class SettingsSubPage extends StatelessWidget {
  const SettingsSubPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }
}

Widget settingsGap() => const SizedBox(height: 16);

/// Small note text under a group (same role as the original's helper Text).
class SettingsNote extends StatelessWidget {
  const SettingsNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
    );
  }
}
