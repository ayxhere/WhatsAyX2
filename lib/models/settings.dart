/// Full settings model for WhatsAyX v2.
///
/// Mirrors the original AyXWhatsapp settings surface:
///  - Gateway-owned toggles == GatewayClient.Settings in the original
///    (also the defaults in nodejs-project/main.js `settings` object).
///  - Local-only prefs == ThemeStore / ChatStyle / UiStyleStore /
///    FontStore / EmojiStore / TranslateStore in the original.
///
/// Keys are kept IDENTICAL to the original so the gateway JSON and the
/// local store stay interchangeable.
library;

/// One auto-reply keyword rule (original: `autoReplyRules`).
class AutoReplyRule {
  final String id;
  final String match;
  final String reply;

  const AutoReplyRule({
    required this.id,
    required this.match,
    required this.reply,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'match': match, 'reply': reply};

  factory AutoReplyRule.fromJson(Map<String, dynamic> json) => AutoReplyRule(
        id: json['id']?.toString() ?? '',
        match: json['match']?.toString() ?? '',
        reply: json['reply']?.toString() ?? '',
      );
}

/// One lyrics-translate API (original: `aiLyricsApis`, tried IN ORDER).
class LyricApi {
  final String name;
  final String url;
  final String key;

  const LyricApi({required this.name, required this.url, this.key = ''});

  Map<String, dynamic> toJson() => {'name': name, 'url': url, 'key': key};

  factory LyricApi.fromJson(Map<String, dynamic> json) => LyricApi(
        name: json['name']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
        key: json['key']?.toString() ?? '',
      );
}

/// One scheduled message (original: Reschedule.RescheduleTask).
class ScheduledTask {
  final String id;
  final String jid;
  final String name;
  final String text;
  final DateTime sendAt;
  final String status; // pending | processing | sent | failed | cancelled
  final String kind; // manual | ai

  const ScheduledTask({
    required this.id,
    required this.jid,
    required this.name,
    required this.text,
    required this.sendAt,
    this.status = 'pending',
    this.kind = 'manual',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'jid': jid,
        'name': name,
        'text': text,
        'sendAt': sendAt.toIso8601String(),
        'status': status,
        'kind': kind,
      };

  factory ScheduledTask.fromJson(Map<String, dynamic> json) => ScheduledTask(
        id: json['id']?.toString() ?? '',
        jid: json['jid']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        sendAt: DateTime.tryParse(json['sendAt']?.toString() ?? '') ??
            DateTime.now(),
        status: json['status']?.toString() ?? 'pending',
        kind: json['kind']?.toString() ?? 'manual',
      );
}

/// One remembered contact for AI Memory (original: GatewayClient.MemContact).
class MemoryContact {
  final String jid;
  final String name;
  final String number;
  final String language;
  final int messageCount;

  const MemoryContact({
    required this.jid,
    required this.name,
    this.number = '',
    this.language = '',
    this.messageCount = 0,
  });

  factory MemoryContact.fromJson(Map<String, dynamic> json) => MemoryContact(
        jid: json['jid']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        number: json['number']?.toString() ?? '',
        language: json['language']?.toString() ?? '',
        messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      );
}

/// All settings, gateway-owned + local. One object, two stores:
/// gateway keys sync to the Node gateway (POST /settings), local keys
/// persist on-device via SettingsStore.
class AyxSettings {
  // ---- Gateway-owned (same names as the original) ----
  final bool alwaysOnline;
  final bool autoRead;
  final bool autoReplyEnabled;
  final List<AutoReplyRule> autoReplyRules;
  final bool aiReplyEnabled;
  final bool groupAiEnabled;
  final String aiApiUrl;
  final String aiApiKey;
  final String aiModel;
  final bool hideStatusRead;
  final String aiSystemPrompt;
  final bool saveMedia;
  final bool stayOffline;
  final bool aiPresenceFlow;
  final List<String> aiExcludeJids;
  final bool aiReplyVoice;
  final bool aiReplyImage;
  final String aiVisionModel;
  final String aiVisionApiUrl;
  final String aiVisionApiKey;
  final String aiVisionModel2;
  final String aiVisionApiUrl2;
  final String aiVisionApiKey2;
  final bool aiImageOcr;
  final bool aiImageFree;
  final bool aiCommandsEnabled;
  final bool aiVoiceNoteReply;
  /// On-device voice id (Supertonic 3) — local-only, NOT a gateway key.
  final String voiceEngineVoice;
  /// On-device voice speed multiplier — local-only.
  final double voiceSpeed;
  final String aiLangMode; // auto | hinglish | bangla | english | hindi | banglascript | custom
  final bool aiFullContext;
  final String aiReplyLang;
  final List<LyricApi> aiLyricsApis;

  // ---- Local-only (same names as the original stores) ----
  final String themeMode; // system | light | amoled
  final String uiStyle; // default | neumorphism | glassmorphism | skeuomorphism | claymorphism
  final String accent; // purple | blue | teal | ... (15 accents)
  final String bubbleStyle; // ios | iosround | iostail | whatsapp | material | rounded | compact | gb
  final int sentColor; // 0 = default/auto
  final int recvColor; // 0 = default/auto
  final int headerBlurDp; // 0 | 5 | 10 | 15 | 20 | 30 | 40
  final bool headerPillEnabled;
  final bool showForwardTag;
  final bool runBackground;
  final String appFont;
  final String emojiStyle; // System default | pack name
  final String translateMode; // off | manual | auto
  final String translateLang;
  final String statusProgressStyle; // default | wavy | squiggly
  final String voiceNoteStyle; // default | wavy
  final bool materialBlurEnabled;
  final String textAnimStyle;
  final String msgMotionStyle;
  final String iconStyle;
  final String musicProvider; // saavn | itunes | spotify
  final bool notificationsEnabled;

  const AyxSettings({
    this.alwaysOnline = false,
    this.autoRead = false,
    this.autoReplyEnabled = false,
    this.autoReplyRules = const [],
    this.aiReplyEnabled = false,
    this.groupAiEnabled = false,
    this.aiApiUrl = '',
    this.aiApiKey = '',
    this.aiModel = '',
    this.hideStatusRead = true,
    this.aiSystemPrompt = '',
    this.saveMedia = false,
    this.stayOffline = false,
    this.aiPresenceFlow = false,
    this.aiExcludeJids = const [],
    this.aiReplyVoice = false,
    this.aiReplyImage = false,
    this.aiVisionModel = '',
    this.aiVisionApiUrl = '',
    this.aiVisionApiKey = '',
    this.aiVisionModel2 = '',
    this.aiVisionApiUrl2 = '',
    this.aiVisionApiKey2 = '',
    this.aiImageOcr = false,
    this.aiImageFree = true,
    this.aiCommandsEnabled = true,
    this.aiVoiceNoteReply = false,
    this.voiceEngineVoice = 'F1',
    this.voiceSpeed = 1.0,
    this.aiLangMode = 'auto',
    this.aiFullContext = true,
    this.aiReplyLang = '',
    this.aiLyricsApis = const [],
    this.themeMode = 'system',
    this.uiStyle = 'default',
    this.accent = 'teal',
    this.bubbleStyle = 'ios',
    this.sentColor = 0,
    this.recvColor = 0,
    this.headerBlurDp = 10,
    this.headerPillEnabled = true,
    this.showForwardTag = true,
    this.runBackground = true,
    this.appFont = 'Default',
    this.emojiStyle = 'System default',
    this.translateMode = 'manual',
    this.translateLang = 'English',
    this.statusProgressStyle = 'squiggly',
    this.voiceNoteStyle = 'default',
    this.materialBlurEnabled = true,
    this.textAnimStyle = 'default',
    this.msgMotionStyle = 'default',
    this.iconStyle = 'default',
    this.musicProvider = 'saavn',
    this.notificationsEnabled = true,
  });

  AyxSettings copyWith({
    bool? alwaysOnline,
    bool? autoRead,
    bool? autoReplyEnabled,
    List<AutoReplyRule>? autoReplyRules,
    bool? aiReplyEnabled,
    bool? groupAiEnabled,
    String? aiApiUrl,
    String? aiApiKey,
    String? aiModel,
    bool? hideStatusRead,
    String? aiSystemPrompt,
    bool? saveMedia,
    bool? stayOffline,
    bool? aiPresenceFlow,
    List<String>? aiExcludeJids,
    bool? aiReplyVoice,
    bool? aiReplyImage,
    String? aiVisionModel,
    String? aiVisionApiUrl,
    String? aiVisionApiKey,
    String? aiVisionModel2,
    String? aiVisionApiUrl2,
    String? aiVisionApiKey2,
    bool? aiImageOcr,
    bool? aiImageFree,
    bool? aiCommandsEnabled,
    bool? aiVoiceNoteReply,
    String? voiceEngineVoice,
    double? voiceSpeed,
    String? aiLangMode,
    bool? aiFullContext,
    String? aiReplyLang,
    List<LyricApi>? aiLyricsApis,
    String? themeMode,
    String? uiStyle,
    String? accent,
    String? bubbleStyle,
    int? sentColor,
    int? recvColor,
    int? headerBlurDp,
    bool? headerPillEnabled,
    bool? showForwardTag,
    bool? runBackground,
    String? appFont,
    String? emojiStyle,
    String? translateMode,
    String? translateLang,
    String? statusProgressStyle,
    String? voiceNoteStyle,
    bool? materialBlurEnabled,
    String? textAnimStyle,
    String? msgMotionStyle,
    String? iconStyle,
    String? musicProvider,
    bool? notificationsEnabled,
  }) {
    return AyxSettings(
      alwaysOnline: alwaysOnline ?? this.alwaysOnline,
      autoRead: autoRead ?? this.autoRead,
      autoReplyEnabled: autoReplyEnabled ?? this.autoReplyEnabled,
      autoReplyRules: autoReplyRules ?? this.autoReplyRules,
      aiReplyEnabled: aiReplyEnabled ?? this.aiReplyEnabled,
      groupAiEnabled: groupAiEnabled ?? this.groupAiEnabled,
      aiApiUrl: aiApiUrl ?? this.aiApiUrl,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      aiModel: aiModel ?? this.aiModel,
      hideStatusRead: hideStatusRead ?? this.hideStatusRead,
      aiSystemPrompt: aiSystemPrompt ?? this.aiSystemPrompt,
      saveMedia: saveMedia ?? this.saveMedia,
      stayOffline: stayOffline ?? this.stayOffline,
      aiPresenceFlow: aiPresenceFlow ?? this.aiPresenceFlow,
      aiExcludeJids: aiExcludeJids ?? this.aiExcludeJids,
      aiReplyVoice: aiReplyVoice ?? this.aiReplyVoice,
      aiReplyImage: aiReplyImage ?? this.aiReplyImage,
      aiVisionModel: aiVisionModel ?? this.aiVisionModel,
      aiVisionApiUrl: aiVisionApiUrl ?? this.aiVisionApiUrl,
      aiVisionApiKey: aiVisionApiKey ?? this.aiVisionApiKey,
      aiVisionModel2: aiVisionModel2 ?? this.aiVisionModel2,
      aiVisionApiUrl2: aiVisionApiUrl2 ?? this.aiVisionApiUrl2,
      aiVisionApiKey2: aiVisionApiKey2 ?? this.aiVisionApiKey2,
      aiImageOcr: aiImageOcr ?? this.aiImageOcr,
      aiImageFree: aiImageFree ?? this.aiImageFree,
      aiCommandsEnabled: aiCommandsEnabled ?? this.aiCommandsEnabled,
      aiVoiceNoteReply: aiVoiceNoteReply ?? this.aiVoiceNoteReply,
      voiceEngineVoice: voiceEngineVoice ?? this.voiceEngineVoice,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      aiLangMode: aiLangMode ?? this.aiLangMode,
      aiFullContext: aiFullContext ?? this.aiFullContext,
      aiReplyLang: aiReplyLang ?? this.aiReplyLang,
      aiLyricsApis: aiLyricsApis ?? this.aiLyricsApis,
      themeMode: themeMode ?? this.themeMode,
      uiStyle: uiStyle ?? this.uiStyle,
      accent: accent ?? this.accent,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      sentColor: sentColor ?? this.sentColor,
      recvColor: recvColor ?? this.recvColor,
      headerBlurDp: headerBlurDp ?? this.headerBlurDp,
      headerPillEnabled: headerPillEnabled ?? this.headerPillEnabled,
      showForwardTag: showForwardTag ?? this.showForwardTag,
      runBackground: runBackground ?? this.runBackground,
      appFont: appFont ?? this.appFont,
      emojiStyle: emojiStyle ?? this.emojiStyle,
      translateMode: translateMode ?? this.translateMode,
      translateLang: translateLang ?? this.translateLang,
      statusProgressStyle: statusProgressStyle ?? this.statusProgressStyle,
      voiceNoteStyle: voiceNoteStyle ?? this.voiceNoteStyle,
      materialBlurEnabled: materialBlurEnabled ?? this.materialBlurEnabled,
      textAnimStyle: textAnimStyle ?? this.textAnimStyle,
      msgMotionStyle: msgMotionStyle ?? this.msgMotionStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      musicProvider: musicProvider ?? this.musicProvider,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  /// JSON for the gateway (gateway-owned keys only — same shape the
  /// original app POSTs to its gateway /settings).
  Map<String, dynamic> toGatewayJson() => {
        'alwaysOnline': alwaysOnline,
        'autoRead': autoRead,
        'autoReplyEnabled': autoReplyEnabled,
        'autoReplyRules':
            autoReplyRules.map((r) => r.toJson()).toList(),
        'aiReplyEnabled': aiReplyEnabled,
        'groupAiEnabled': groupAiEnabled,
        'aiApiUrl': aiApiUrl,
        'aiApiKey': aiApiKey,
        'aiModel': aiModel,
        'hideStatusRead': hideStatusRead,
        'aiSystemPrompt': aiSystemPrompt,
        'saveMedia': saveMedia,
        'stayOffline': stayOffline,
        'aiPresenceFlow': aiPresenceFlow,
        'aiExcludeJids': aiExcludeJids,
        'aiReplyVoice': aiReplyVoice,
        'aiReplyImage': aiReplyImage,
        'aiVisionModel': aiVisionModel,
        'aiVisionApiUrl': aiVisionApiUrl,
        'aiVisionApiKey': aiVisionApiKey,
        'aiVisionModel2': aiVisionModel2,
        'aiVisionApiUrl2': aiVisionApiUrl2,
        'aiVisionApiKey2': aiVisionApiKey2,
        'aiImageOcr': aiImageOcr,
        'aiImageFree': aiImageFree,
        'aiCommandsEnabled': aiCommandsEnabled,
        'aiVoiceNoteReply': aiVoiceNoteReply,
        'aiLangMode': aiLangMode,
        'aiFullContext': aiFullContext,
        'aiReplyLang': aiReplyLang,
        'aiLyricsApis': aiLyricsApis.map((a) => a.toJson()).toList(),
        // Local-only voice fields (not gateway-owned): kept here so
        // SettingsStore._saveLocal persists them in the local JSON blob.
        'voiceEngineVoice': voiceEngineVoice,
        'voiceSpeed': voiceSpeed,
      };

  factory AyxSettings.fromJson(Map<String, dynamic> json) {
    List<AutoReplyRule> rules = const [];
    final rawRules = json['autoReplyRules'];
    if (rawRules is List) {
      rules = rawRules
          .whereType<Map>()
          .map((m) => AutoReplyRule.fromJson(
              Map<String, dynamic>.from(m)))
          .toList();
    }
    List<LyricApi> apis = const [];
    final rawApis = json['aiLyricsApis'];
    if (rawApis is List) {
      apis = rawApis
          .whereType<Map>()
          .map((m) =>
              LyricApi.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    List<String> excluded = const [];
    final rawExcluded = json['aiExcludeJids'];
    if (rawExcluded is List) {
      excluded = rawExcluded.map((e) => e.toString()).toList();
    }
    bool b(String k, bool d) =>
        json[k] is bool ? json[k] as bool : d;
    String s(String k, String d) =>
        json[k] is String ? json[k] as String : d;
    return AyxSettings(
      alwaysOnline: b('alwaysOnline', false),
      autoRead: b('autoRead', false),
      autoReplyEnabled: b('autoReplyEnabled', false),
      autoReplyRules: rules,
      aiReplyEnabled: b('aiReplyEnabled', false),
      groupAiEnabled: b('groupAiEnabled', false),
      aiApiUrl: s('aiApiUrl', ''),
      aiApiKey: s('aiApiKey', ''),
      aiModel: s('aiModel', ''),
      hideStatusRead: b('hideStatusRead', true),
      aiSystemPrompt: s('aiSystemPrompt', ''),
      saveMedia: b('saveMedia', false),
      stayOffline: b('stayOffline', false),
      aiPresenceFlow: b('aiPresenceFlow', false),
      aiExcludeJids: excluded,
      aiReplyVoice: b('aiReplyVoice', false),
      aiReplyImage: b('aiReplyImage', false),
      aiVisionModel: s('aiVisionModel', ''),
      aiVisionApiUrl: s('aiVisionApiUrl', ''),
      aiVisionApiKey: s('aiVisionApiKey', ''),
      aiVisionModel2: s('aiVisionModel2', ''),
      aiVisionApiUrl2: s('aiVisionApiUrl2', ''),
      aiVisionApiKey2: s('aiVisionApiKey2', ''),
      aiImageOcr: b('aiImageOcr', false),
      aiImageFree: b('aiImageFree', true),
      aiCommandsEnabled: b('aiCommandsEnabled', true),
      aiVoiceNoteReply: b('aiVoiceNoteReply', false),
      voiceEngineVoice:
          AyxOptions.supertonicVoiceOrDefault(s('voiceEngineVoice', 'F1')),
      voiceSpeed: (json['voiceSpeed'] as num?)?.toDouble() ?? 1.0,
      aiLangMode: s('aiLangMode', 'auto'),
      aiFullContext: b('aiFullContext', true),
      aiReplyLang: s('aiReplyLang', ''),
      aiLyricsApis: apis,
      themeMode: s('themeMode', 'system'),
      uiStyle: s('uiStyle', 'default'),
      accent: s('accent', 'teal'),
      bubbleStyle: s('bubbleStyle', 'ios'),
      sentColor: (json['sentColor'] as num?)?.toInt() ?? 0,
      recvColor: (json['recvColor'] as num?)?.toInt() ?? 0,
      headerBlurDp: (json['headerBlurDp'] as num?)?.toInt() ?? 10,
      headerPillEnabled: b('headerPillEnabled', true),
      showForwardTag: b('showForwardTag', true),
      runBackground: b('runBackground', true),
      appFont: s('appFont', 'Default'),
      emojiStyle: s('emojiStyle', 'System default'),
      translateMode: s('translateMode', 'manual'),
      translateLang: s('translateLang', 'English'),
      statusProgressStyle: s('statusProgressStyle', 'squiggly'),
      voiceNoteStyle: s('voiceNoteStyle', 'default'),
      materialBlurEnabled: b('materialBlurEnabled', true),
      textAnimStyle: s('textAnimStyle', 'default'),
      msgMotionStyle: s('msgMotionStyle', 'default'),
      iconStyle: s('iconStyle', 'default'),
      musicProvider: s('musicProvider', 'saavn'),
      notificationsEnabled: b('notificationsEnabled', true),
    );
  }
}

/// Option lists (same values as the original stores).
class AyxOptions {
  static const List<String> themeModes = ['system', 'light', 'amoled'];
  static const Map<String, String> themeModeLabels = {
    'system': 'System',
    'light': 'Light',
    'amoled': 'AMOLED',
  };

  static const List<String> uiStyles = [
    'default',
    'neumorphism',
    'glassmorphism',
    'skeuomorphism',
    'claymorphism',
  ];
  static const Map<String, String> uiStyleLabels = {
    'default': 'Default',
    'neumorphism': 'Neumorphism',
    'glassmorphism': 'Glassmorphism',
    'skeuomorphism': 'Skeuomorphism',
    'claymorphism': 'Claymorphism',
  };

  /// 15 accents, same order + colors as ThemeStore.accents.
  static const List<MapEntry<String, int>> accents = [
    MapEntry('purple', 0xFFB69DF8),
    MapEntry('blue', 0xFF82AAFF),
    MapEntry('teal', 0xFF4DD0C4),
    MapEntry('green', 0xFF7BD88F),
    MapEntry('orange', 0xFFFFB26B),
    MapEntry('red', 0xFFFF6B6B),
    MapEntry('pink', 0xFFFF7EB6),
    MapEntry('yellow', 0xFFFFD54F),
    MapEntry('lime', 0xFFAED581),
    MapEntry('cyan', 0xFF4DD0E1),
    MapEntry('indigo', 0xFF7986CB),
    MapEntry('deeppurple', 0xFF9575CD),
    MapEntry('magenta', 0xFFE040FB),
    MapEntry('brown', 0xFFA1887F),
    MapEntry('grey', 0xFF90A4AE),
  ];

  static const List<String> bubbleStyles = [
    'ios',
    'iosround',
    'iostail',
    'whatsapp',
    'material',
    'rounded',
    'compact',
    'gb',
  ];
  static const Map<String, String> bubbleStyleLabels = {
    'ios': 'iOS',
    'iosround': 'iOS Round',
    'iostail': 'iOS Tail',
    'whatsapp': 'Normal WhatsApp',
    'material': 'Material',
    'rounded': 'Rounded',
    'compact': 'Compact',
    'gb': 'GB style',
  };

  static const List<int> headerBlurSteps = [0, 5, 10, 15, 20, 30, 40];

  /// Bubble color swatches (0 = default/auto), same as ChatStyle.bubblePalette.
  static const List<int> bubblePalette = [
    0,
    0xFF0A84FF,
    0xFF128C7E,
    0xFF005C4B,
    0xFF7C4DFF,
    0xFFE91E63,
    0xFFEF5350,
    0xFFFF9800,
    0xFF43A047,
    0xFF00ACC1,
    0xFF546E7A,
    0xFF2C2C2E,
    0xFF000000,
    0xFFE9E9EB,
    0xFFFFFFFF,
  ];

  static const List<String> langModes = [
    'auto',
    'hinglish',
    'bangla',
    'english',
    'hindi',
    'banglascript',
    'custom',
  ];
  static const Map<String, String> langModeLabels = {
    'auto': 'Auto (mirror sender)',
    'hinglish': 'Roman Hindi (Hinglish)',
    'bangla': 'Roman Bangla',
    'english': 'English',
    'hindi': 'Hindi',
    'banglascript': 'Bangla script',
    'custom': 'Custom (your text below)',
  };

  static const List<String> translateModes = ['off', 'manual', 'auto'];
  static const Map<String, String> translateModeLabels = {
    'off': 'Off',
    'manual': 'Double-tap',
    'auto': 'Auto (all)',
  };

  static const List<String> statusProgressStyles = [
    'default',
    'wavy',
    'squiggly',
  ];
  static const List<String> voiceNoteStyles = ['default', 'wavy'];

  /// Bundled app fonts (original FontStore.bundled; custom .ttf/.otf
  /// import is listed as not-yet-ported in SETTINGS_INVENTORY.md).
  static const List<String> fonts = [
    'Default',
    'Inter',
    'Roboto',
    'Poppins',
    'Nunito',
    'Montserrat',
  ];

  /// Emoji styles (original EmojiStore.styles; pack download is
  /// listed as not-yet-ported in SETTINGS_INVENTORY.md).
  static const List<String> emojiStyles = [
    'System default',
    'Noto Color Emoji',
    'Twemoji',
    'OpenMoji',
  ];

  /// Supertonic 3 on-device voices (voiceEngineVoice; default F1).
  /// Hindi voices: write Hindi in Devanagari, not Roman — Roman Hindi
  /// sounds wrong. The 10 styles live in voice.bin; sid 0–4 = F1–F5
  /// (female), sid 5–9 = M1–M5 (male). One model speaks all 31
  /// languages, so every voice works for Hindi and English.
  static const List<String> supertonicVoices = [
    'F1',
    'F2',
    'F3',
    'F4',
    'F5',
    'M1',
    'M2',
    'M3',
    'M4',
    'M5',
  ];
  static const Map<String, String> supertonicVoiceLabels = {
    'F1': 'F1 — Female (soft)',
    'F2': 'F2 — Female',
    'F3': 'F3 — Female',
    'F4': 'F4 — Female',
    'F5': 'F5 — Female',
    'M1': 'M1 — Male',
    'M2': 'M2 — Male',
    'M3': 'M3 — Male',
    'M4': 'M4 — Male',
    'M5': 'M5 — Male',
  };

  /// A stored voice id from an older engine (e.g. Kokoro's hf_alpha)
  /// is not a Supertonic voice — fall back to the F1 default instead
  /// of showing an unknown value in the picker.
  static String supertonicVoiceOrDefault(String v) =>
      supertonicVoices.contains(v) ? v : 'F1';

  static const List<String> musicProviders = ['saavn', 'itunes', 'spotify'];
  static const Map<String, String> musicProviderLabels = {
    'saavn': 'JioSaavn',
    'itunes': 'iTunes',
    'spotify': 'Spotify (free route)',
  };
}
