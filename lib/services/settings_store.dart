import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';
import 'api_service.dart';

/// Persists AyxSettings on-device (SharedPreferences, same pref-file
/// split as the original: theme / chatstyle / ui_style / fonts / emoji)
/// and syncs the gateway-owned keys to the Node gateway (POST /settings).
class SettingsStore {
  SettingsStore({required this.api});

  final ApiService api;

  /// App-wide shared store — ONE source of truth. main.dart loads it
  /// and rebuilds MaterialApp when it changes (so theme + accent apply
  /// instantly); SettingsScreen and MusicScreen use this instance too
  /// instead of creating their own.
  static SettingsStore? _shared;
  static SettingsStore get shared =>
      _shared ??= SettingsStore(api: ApiService());

  static const String _prefsKey = 'ayx_settings_v2';

  AyxSettings _current = const AyxSettings();
  AyxSettings get current => _current;

  final List<void Function(AyxSettings)> _listeners = [];

  void addListener(void Function(AyxSettings) listener) =>
      _listeners.add(listener);

  void _notify() {
    for (final l in _listeners) {
      l(_current);
    }
  }

  /// Load local copy, then refresh gateway-owned keys from the gateway
  /// when it is reachable (gateway wins for its own keys).
  Future<AyxSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        _current = AyxSettings.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _current = const AyxSettings();
      }
    }
    final remote = await api.fetchSettings();
    if (remote != null) {
      _current = _current.copyWith(
        alwaysOnline: remote.alwaysOnline,
        autoRead: remote.autoRead,
        autoReplyEnabled: remote.autoReplyEnabled,
        autoReplyRules: remote.autoReplyRules,
        aiReplyEnabled: remote.aiReplyEnabled,
        groupAiEnabled: remote.groupAiEnabled,
        aiApiUrl: remote.aiApiUrl,
        aiApiKey: remote.aiApiKey,
        aiModel: remote.aiModel,
        hideStatusRead: remote.hideStatusRead,
        aiSystemPrompt: remote.aiSystemPrompt,
        saveMedia: remote.saveMedia,
        stayOffline: remote.stayOffline,
        aiPresenceFlow: remote.aiPresenceFlow,
        aiExcludeJids: remote.aiExcludeJids,
        aiReplyVoice: remote.aiReplyVoice,
        aiReplyImage: remote.aiReplyImage,
        aiVisionModel: remote.aiVisionModel,
        aiVisionApiUrl: remote.aiVisionApiUrl,
        aiVisionApiKey: remote.aiVisionApiKey,
        aiVisionModel2: remote.aiVisionModel2,
        aiVisionApiUrl2: remote.aiVisionApiUrl2,
        aiVisionApiKey2: remote.aiVisionApiKey2,
        aiImageOcr: remote.aiImageOcr,
        aiImageFree: remote.aiImageFree,
        aiCommandsEnabled: remote.aiCommandsEnabled,
        aiVoiceNoteReply: remote.aiVoiceNoteReply,
        aiLangMode: remote.aiLangMode,
        aiFullContext: remote.aiFullContext,
        aiReplyLang: remote.aiReplyLang,
        aiLyricsApis: remote.aiLyricsApis,
      );
      await _saveLocal();
    }
    _notify();
    return _current;
  }

  /// Update settings locally AND push gateway-owned keys to the gateway.
  /// Gateway push fails soft when the gateway is down (local copy stays).
  Future<void> update(AyxSettings next) async {
    _current = next;
    await _saveLocal();
    await api.pushSettings(next);
    _notify();
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _current.toGatewayJson()
      ..addAll({
        'themeMode': _current.themeMode,
        'uiStyle': _current.uiStyle,
        'accent': _current.accent,
        'bubbleStyle': _current.bubbleStyle,
        'sentColor': _current.sentColor,
        'recvColor': _current.recvColor,
        'headerBlurDp': _current.headerBlurDp,
        'headerPillEnabled': _current.headerPillEnabled,
        'showForwardTag': _current.showForwardTag,
        'runBackground': _current.runBackground,
        'appFont': _current.appFont,
        'emojiStyle': _current.emojiStyle,
        'translateMode': _current.translateMode,
        'translateLang': _current.translateLang,
        'statusProgressStyle': _current.statusProgressStyle,
        'voiceNoteStyle': _current.voiceNoteStyle,
        'materialBlurEnabled': _current.materialBlurEnabled,
        'textAnimStyle': _current.textAnimStyle,
        'msgMotionStyle': _current.msgMotionStyle,
        'iconStyle': _current.iconStyle,
        'musicProvider': _current.musicProvider,
        'notificationsEnabled': _current.notificationsEnabled,
        'voiceEngineVoice': _current.voiceEngineVoice,
        'voiceSpeed': _current.voiceSpeed,
      });
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  /// Full reset (original: "Clear app data" — local settings only here;
  /// the gateway session is cleared via ApiService.logout()).
  Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _current = const AyxSettings();
    _notify();
  }
}
