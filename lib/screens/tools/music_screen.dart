import 'package:flutter/material.dart';

import '../../models/settings.dart';
import '../../services/api_service.dart';
import '../../services/settings_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ayx_widgets.dart';

/// Music — search JioSaavn / iTunes / Spotify (free route only).
/// Same providers as the original MusicProviders: JioSaavn full streams,
/// iTunes 30s previews, Spotify search-only (matched on JioSaavn).
/// Lyrics come from GET /music/lyrics.
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  late final SettingsStore _store;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _store = SettingsStore(api: _api);
    _store.addListener((_) {
      if (mounted) setState(() {});
    });
    _store.load();
  }

  @override
  void dispose() {
    _api.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _searched = true;
    });
    final results = await _api.searchMusic(q, _store.current.musicProvider);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = _store.current.musicProvider;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music'),
        backgroundColor: AppTheme.bg,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: AyxSearchBar(
              controller: _searchCtrl,
              hint: 'Search songs, artists…',
              onChanged: (_) {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final p in AyxOptions.musicProviders)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                          AyxOptions.musicProviderLabels[p] ?? p),
                      selected: provider == p,
                      onSelected: (_) async {
                        await _store.update(
                            _store.current.copyWith(musicProvider: p));
                        if (mounted) setState(() {});
                        _search();
                      },
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_searched
                    ? const Center(
                        child: Text(
                          'Search a song — JioSaavn, iTunes or Spotify.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : _results.isEmpty
                        ? const Center(
                            child: Text(
                              'No results. Connect the gateway and try again.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, _) => const Divider(
                              color: AppTheme.border,
                              height: 1,
                            ),
                            itemBuilder: (context, i) {
                              final song = _results[i];
                              final title =
                                  song['title']?.toString() ?? 'Unknown';
                              final artist =
                                  song['artist']?.toString() ?? '';
                              return ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.music_note,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                      color: AppTheme.text),
                                ),
                                subtitle: Text(
                                  artist,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.lyrics_outlined,
                                    color: AppTheme.textSecondary,
                                  ),
                                  tooltip: 'Lyrics',
                                  onPressed: () =>
                                      _showLyrics(context, title),
                                ),
                                onTap: () => ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text('Playing "$title"…'),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLyrics(BuildContext context, String title) async {
    final lines = await _api.fetchLyrics(title);
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (lines.isEmpty)
              const Text(
                'No synced lyrics found for this song.',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              ...lines.take(20).map(
                    (l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        l['text']?.toString() ?? '',
                        style: const TextStyle(color: AppTheme.text),
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
