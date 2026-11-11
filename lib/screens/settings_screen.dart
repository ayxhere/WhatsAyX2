import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import 'settings/settings_about.dart';
import 'settings/settings_ai.dart';
import 'settings/settings_ai_memory.dart';
import 'settings/settings_appearance.dart';
import 'settings/settings_autoreply.dart';
import 'settings/settings_broadcast.dart';
import 'settings/settings_chat.dart';
import 'settings/settings_general.dart';
import 'settings/settings_home.dart';
import 'settings/settings_support.dart';
import 'settings/settings_sync.dart';
import 'settings/settings_voice.dart';

/// Settings tab: full navigator with the SAME page structure as the
/// original AyXWhatsapp (same page ids, same titles, same parent chain).
///
/// Pages: home, general, autoreply, ai, imageai, aimemory, voice, chat,
/// wallpaper, appearance, accent, bluranim, textanim, msgmotion, iconstyle,
/// font, emoji, sync, broadcast, about, support.
/// Nested pages live inside their parent page in v2 (e.g. Image AI is a
/// group inside AI Assistant; Font/Emoji/Accent live inside Appearance),
/// so their ids route to the parent page.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _page = 'home';
  late final ApiService _api;
  late final SettingsStore _store;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _store = SettingsStore(api: _api);
    _store.addListener((_) {
      if (mounted) setState(() {});
    });
    _store.load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  String _title(String page) => switch (page) {
        'general' => 'General',
        'autoreply' => 'Auto-reply',
        'ai' => 'AI Assistant',
        'imageai' => 'Image AI',
        'aimemory' => 'AI Memory',
        'voice' => 'AI Voice',
        'chat' => 'Chat Settings',
        'wallpaper' => 'Chat Wallpaper',
        'appearance' => 'Appearance',
        'accent' => 'Accent Color',
        'bluranim' => 'Blur & Animation',
        'textanim' => 'Text Animation',
        'msgmotion' => 'Message Motion',
        'iconstyle' => 'Icon Style',
        'font' => 'App font',
        'emoji' => 'Emoji',
        'sync' => 'Sync',
        'broadcast' => 'Broadcast',
        'about' => 'About',
        'support' => 'Support Development',
        _ => 'Settings',
      };

  /// Parent page for nested back — same chain as the original.
  String _parent(String page) => switch (page) {
        'wallpaper' => 'chat',
        'imageai' => 'ai',
        'aimemory' => 'ai',
        'voice' => 'ai',
        'font' => 'appearance',
        'emoji' => 'appearance',
        'textanim' => 'appearance',
        'msgmotion' => 'appearance',
        'iconstyle' => 'appearance',
        'accent' => 'appearance',
        'bluranim' => 'appearance',
        _ => 'home',
      };

  void _open(String page) => setState(() => _page = page);

  bool _goBack() {
    if (_page == 'home') return false;
    setState(() => _page = _parent(_page));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isHome = _page == 'home';
    return PopScope(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title(_page)),
          backgroundColor: AppTheme.bg,
          leading: isHome
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _goBack,
                ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _buildPage(),
        ),
      ),
    );
  }

  Widget _buildPage() {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_page) {
      case 'general':
        return GeneralSettingsPage(key: const ValueKey('general'), store: _store);
      case 'autoreply':
        return AutoReplyPage(key: const ValueKey('autoreply'), store: _store);
      case 'ai':
      case 'imageai':
        return AiSettingsPage(
          key: const ValueKey('ai'),
          store: _store,
          api: _api,
          onOpenMemory: () => _open('aimemory'),
          onOpenVoice: () => _open('voice'),
        );
      case 'aimemory':
        return AiMemoryPage(key: const ValueKey('aimemory'), api: _api);
      case 'voice':
        return VoiceSettingsPage(key: const ValueKey('voice'), store: _store);
      case 'chat':
      case 'wallpaper':
        return ChatSettingsPage(key: const ValueKey('chat'), store: _store);
      case 'appearance':
      case 'accent':
      case 'bluranim':
      case 'textanim':
      case 'msgmotion':
      case 'iconstyle':
      case 'font':
      case 'emoji':
        return AppearanceSettingsPage(
          key: const ValueKey('appearance'),
          store: _store,
        );
      case 'sync':
        return SyncSettingsPage(
          key: const ValueKey('sync'),
          api: _api,
        );
      case 'broadcast':
        return BroadcastPage(key: const ValueKey('broadcast'), api: _api);
      case 'about':
        return AboutSettingsPage(
          key: const ValueKey('about'),
          store: _store,
          api: _api,
        );
      case 'support':
        return const SupportSettingsPage(key: ValueKey('support'));
      default:
        return SettingsHomePage(
          key: const ValueKey('home'),
          api: _api,
          onOpen: _open,
        );
    }
  }
}
