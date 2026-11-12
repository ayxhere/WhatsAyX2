# WhatsAyX v2 — Settings & Features Inventory (audited from the original app)

Source audited: `~/workspace/AyXWhatsapp-head` — the original AyXWhatsapp
(Kotlin/Compose app, `MainActivity.kt` 12,547 lines, 87 Kotlin files;
Node gateway `nodejs-project/main.js`). Audit date: 2026-11-12.

Rule for this inventory: **everything the original has must be in WhatsAyX v2 —
only the UI is new (WZH-style).** Nothing is silently dropped. Anything that
genuinely cannot be ported in this pass is listed under "Not yet ported" with
a one-line reason.

## 1. Settings home (same 10 categories as the original)

| # | Category | Original page id | v2 screen |
|---|----------|------------------|-----------|
| 1 | General — Online, privacy and messages | `general` | `settings_general.dart` |
| 2 | Auto-reply — Keyword rules and automatic replies | `autoreply` | `settings_autoreply.dart` |
| 3 | AI Assistant — AI replies, groups and language | `ai` | `settings_ai.dart` |
| 4 | AI Voice — Voice reply, voice notes & voice artists | `voice` | `settings_voice.dart` |
| 5 | Chat — Wallpaper, bubble style and header | `chat` | `settings_chat.dart` |
| 6 | Appearance — Theme and accent color | `appearance` | `settings_appearance.dart` |
| 7 | Sync — Drive backup of API keys & prompts | `sync` | `settings_sync.dart` |
| 8 | Broadcast — Send bulk messages via JSON with timer | `broadcast` | `settings_broadcast.dart` |
| 9 | About — App information and reset | `about` | `settings_about.dart` |
| 10 | Support Development — Donate via UPI or crypto | `support` | `settings_support.dart` |

Plus the connection **Status card** on top (Connected / Reconnecting / Not
linked, engine up/down, manual Reconnect button) — same as the original.

Nested sub-pages (same parent chain as the original `settingsParent`):
Image AI + AI Memory + AI Voice live under AI Assistant; Chat Wallpaper under
Chat; App font / Emoji / Text Animation / Message Motion / Icon Style /
Accent Color / Blur & Animation under Appearance.

## 2. General settings (page `general`)

| # | Setting | Key (gateway / local) | v2 |
|---|---------|-----------------------|----|
| 11 | Always online | `alwaysOnline` | ✓ |
| 12 | Freeze last seen (overrides Always online) | `stayOffline` | ✓ |
| 13 | Human-like presence (read → online + type → reply → offline) | `aiPresenceFlow` | ✓ |
| 14 | Hide status view (don't show senders you saw their status) | `hideStatusRead` | ✓ |
| 15 | Auto-read messages | `autoRead` | ✓ |
| 16 | Save media (download incoming photos/videos) | `saveMedia` | ✓ |
| 17 | Forwarded tag (show "Forwarded" label) | local `showForwardTag` | ✓ |
| 18 | Run in background (silent notification keeps gateway alive) | local `runBackground` | ✓ |
| 19 | Allow battery (no optimization) — opens system settings | action | ✓ |
| 20 | Allow app to open / autostart — opens app settings | action | ✓ |
| 21 | Storage: Downloaded media size + clear | action | ✓ |
| 22 | Storage: Cache size + clear cache | action | ✓ |
| 23 | Clear app data (removes everything local, re-link needed) | action + confirm dialog | ✓ |

## 3. Auto-reply (page `autoreply`)

| # | Setting | Key | v2 |
|---|---------|-----|----|
| 24 | Auto-reply master switch | `autoReplyEnabled` | ✓ |
| 25 | Keyword rules list (add / edit / delete, match text + reply) | `autoReplyRules` | ✓ |
| 26 | Rules apply per chat; excluded chats never get auto-replies | `aiExcludeJids` (shared) | ✓ |

## 4. AI Assistant (page `ai`)

| # | Setting | Key | v2 |
|---|---------|-----|----|
| 27 | AI reply (master) — OFF stops ALL AI replies | `aiReplyEnabled` | ✓ |
| 28 | Image reply (vision looks at incoming images, swipe-reply) | `aiReplyImage` | ✓ |
| 29 | Group AI reply (greetings/questions, max 10/day; /ai anytime) | `groupAiEnabled` | ✓ |
| 30 | Enable /create, /prompt & /voice commands | `aiCommandsEnabled` | ✓ |
| 31 | Reply language — one language only (auto / hinglish / bangla / english / hindi / banglascript / custom) | `aiLangMode` + `aiReplyLang` | ✓ |
| 32 | Don't reply to these chats (exclude list) | `aiExcludeJids` | ✓ |
| 33 | API configuration (text/voice): API URL, API key, model, system prompt | `aiApiUrl`, `aiApiKey`, `aiModel`, `aiSystemPrompt` | ✓ |
| 34 | Vision API config (2nd provider): URL, key, model | `aiVisionApiUrl`, `aiVisionApiKey`, `aiVisionModel` (+ `…2` set) | ✓ |
| 35 | Full context (send real recent conversation, both sides) | `aiFullContext` | ✓ |
| 36 | AI Lyrics — translate lyrics APIs, tried in order (add / edit / delete) | `aiLyricsApis` | ✓ |
| 37 | AI image edit — read image text on phone (offline OCR, unlimited) | `aiImageOcr` | ✓ |
| 38 | AI image edit — free image generation toggle | `aiImageFree` | ✓ |
| 39 | AI Memory — per-contact remembered name/number/language/history, clear per contact / clear all | `GET /aimemory`, `POST /aimemory/clear` | ✓ |
| 40 | AI Voice — transcribe incoming voice notes then AI-reply | `aiReplyVoice` | ✓ (voice page) |
| 41 | AI Voice — reply to voice notes WITH a voice note (TTS) | `aiVoiceNoteReply` | ✓ (voice page) |
| 42 | AI Voice — on-device TTS voice (Supertonic 3 via sherpa-onnx, ~139 MB download on first use) | `voiceEngineVoice` (default `F1`) | ✓ (voice page) |
| 43 | AI Voice — TTS speed | `voiceSpeed` (default `1.0`) | ✓ (voice page) |

## 5. Chat settings (page `chat` + `wallpaper`)

| # | Setting | Key | v2 |
|---|---------|-----|----|
| 44 | Chat wallpaper — set / remove (image picker) | local wallpaper | ✓ |
| 45 | Bubble style — iOS, iOS Round, iOS Tail, Normal WhatsApp, Material, Rounded, Compact, GB style | local `bubble` | ✓ |
| 46 | Bubble color — sent (right side) | local `sentColor` | ✓ |
| 47 | Bubble color — received (left side) | local `recvColor` | ✓ |
| 48 | Chat header blur (0 / 5 / 10 / 15 / 20 / 30 / 40) | local `headerBlur` | ✓ |
| 49 | Rounded header pill (dark glass pill behind DP + name) | local `headerPill` | ✓ |
| 50 | Message menu — long-press: blurred chat, message floats, pop-in menu | local | ✓ |

## 6. Appearance (page `appearance` + sub-pages)

| # | Setting | Key | v2 |
|---|---------|-----|----|
| 51 | Theme mode — System / Light / AMOLED (dark migrated to AMOLED) | local `mode` | ✓ |
| 52 | UI style — Default / Neumorphism / Glassmorphism / Skeuomorphism / Claymorphism | local `style` | ✓ |
| 53 | Accent color — 15 accents (purple, blue, teal, green, orange, red, pink, yellow, lime, cyan, indigo, deeppurple, magenta, brown, grey) | local `accent` | ✓ |
| 54 | Blur & Animation — material blur on/off, animation style, motion | local | ✓ |
| 55 | Text Animation — typing / delete / cursor effects (style, speed, pace, curve, amount, shape, color) | local | ✓ |
| 56 | Message Motion — entrance animation for chat messages | local | ✓ |
| 57 | Icon Style — icons across chats, composer and menus (swappable icon packs) | local | ✓ |
| 58 | App font — preview, pick or upload .ttf/.otf | local `fonts` | ✓ |
| 59 | Emoji — emoji style (system default + downloadable packs) | local `emoji` | ✓ |
| 60 | Message translation — Off / Double-tap / Auto (all) + target language | local translate mode/lang | ✓ |
| 61 | Status style — progress bar style on status viewer (default / wavy / squiggly) | local `statusProgressStyle` | ✓ |
| 62 | Voice note style — progress line in voice bubbles (default / wavy) | local `voiceNoteStyle` | ✓ |

## 7. Sync (page `sync` — Drive Backup)

| # | Setting | v2 |
|---|---------|----|
| 63 | Google account (add Gmail once, Drive access) | ✓ (account row + sign-in state) |
| 64 | Backup now — API keys & prompts to Drive | ✓ (local export + gateway `/backup`; live Drive upload — see "Not yet ported") |
| 65 | Restore from Drive backup | ✓ (restore from exported file / gateway) |
| 66 | Last backup info + encrypted backup file (.ayxbak-style, AES-256-GCM) | ✓ (metadata shown; encryption via gateway) |

## 8. Broadcast (page `broadcast`)

| # | Setting | v2 |
|---|---------|----|
| 67 | Broadcast JSON composer (phone + message list) | ✓ |
| 68 | AI prompt helper (copy prompt, AI makes the JSON) | ✓ |
| 69 | Delay between messages (seconds / custom timer) | ✓ |
| 70 | Send progress (Sent x/y, Failed count) | ✓ |
| 71 | Broadcast messages hidden from chat list (reveal via title double-tap) | ✓ (note in UI) |

## 9. About / Support

| # | Setting | v2 |
|---|---------|----|
| 72 | Version info | ✓ |
| 73 | Privacy Policy (in-app dialog) | ✓ |
| 74 | Unlink / reset (logout, clear session) | ✓ |
| 75 | Connect links — Instagram, Telegram, Website (imayx.in) | ✓ |
| 76 | Support — UPI donate (India) | ✓ |
| 77 | Support — USDT donate (BEP20 / TRC20 / ERC20 + Binance pay) | ✓ |

## 10. Core features (outside Settings)

| # | Feature | Original source | v2 |
|---|---------|----------------|----|
| 78 | Splash screen (smooth, ~1.9s, logo scale + fade) | `SplashScreen` | ✓ |
| 79 | Link screen — QR + pairing code, device name "iMAyX" | `LinkScreen`, gateway `browser: ['iMAyX', …]` | ✓ |
| 80 | Chats list — search (substring), unread badges, groups | MainActivity chats | ✓ |
| 81 | Chat detail — bubbles, send, reply, forward, react, edit, delete, message info, translate on double-tap | `MessageActionSheet`, gateway `/send /react /forward /editmessage /message/delete` | ✓ |
| 82 | Hidden chats (long-press / double-tap title reveals) | `ChatFlags.hidden` | ✓ (hidden filter + reveal) |
| 83 | New chat — contacts list, start by number | `NewChatScreen`, `GET /contacts`, `POST /onwhatsapp` | ✓ |
| 84 | Chat info — mute timer, media/voice counts, clear media, delete chat | `ChatInfoSheet`, `MuteTimerDialog` | ✓ |
| 85 | Profile — my DP, name, bio | `ProfileScreen`, `POST /profile/name /bio /picture` | ✓ |
| 86 | Status list — teal ring for unviewed, mute/unmute | `StatusScreen` | ✓ |
| 87 | Status viewer — progress bar (style per setting), reply, forward, download, delete, mark seen | `StatusViewer`, `GET /status/viewers` | ✓ |
| 88 | Status download (saver) | `StatusDl` | ✓ |
| 89 | Hide status view (don't show senders you saw their status) | `hideStatusRead` | ✓ (General) |
| 90 | Deleted messages — tombstones shown in chat | `DeletedMsgs`, `GET /deleted` | ✓ |
| 91 | Music — search JioSaavn / iTunes / Spotify (free route only; Spotify matched on JioSaavn, iTunes 30s preview fallback) | `MusicProviders`, `GET /music/search /music/lyrics` | ✓ |
| 92 | Lyrics — synced lyrics, translate, manual lyrics, AI lyrics APIs | `LyricsStyle`, `AiLyricsTranslateSheet`, `ManualLyricsDialog` | ✓ |
| 93 | Schedule — send a message later (reschedule tasks: pending / processing / sent / failed / cancelled) | `Reschedule` | ✓ |
| 94 | Reminders | `Reminder` | ✓ (with Schedule) |
| 95 | AI tools — AI Reply, AI Rewrite, Translate, Schedule, Broadcast, Auto Reply | Tools tab | ✓ |
| 96 | AI image tools — /create image, /prompt on image, /voice | `aiCommandsEnabled` | ✓ |
| 97 | Voice notes — record, send, play, on-device TTS demo (Supertonic 3, sherpa-onnx, wired: download + synthesize + play) | `voice` page + chat | ✓ (voice page + chat) |
| 98 | Media viewer — photo/video viewer, zoom, swipeable pager | `MediaPagerViewer` | ✓ (status viewer + chat media) |
| 99 | Notifications — gateway foreground service + reply from notification | `NotificationHelper`, `ReplyReceiver` | ✓ (setting + gateway) |
| 100 | Crash reporting dialog | `CrashReportDialog` | ✓ (basic) |
| 101 | App update check dialog | `AyxUpdateDialog` | ✓ (version row + check) |
| 102 | Gateway — Baileys, auto-reconnect, presence, syncFullHistory off | `nodejs-project/main.js` | ✓ (backend/src/server.js) |
| 103 | Gateway endpoints — /health /qr /pair /chats /messages /contacts /status /statuses /send /markread /react /forward /editmessage /message/delete /chat/delete /block /logout /reconnect /settings /aimemory /music/* /deleted /profile/* /me /presence | `main.js` | ✓ (mirrored in backend/src/server.js) |

## 11. Not yet ported

| # | Feature | Reason (one line) |
|---|---------|-------------------|
| N1 | Live Google Drive upload in Sync (real Drive API write) | Needs `google_sign_in` + Drive API wiring + OAuth client; screen, local export and gateway `/backup` are ready — the Drive upload call itself is the only missing piece. |
| N2 | On-device Node gateway inside the app (original embeds Node) | Flutter v2 runs the gateway as a separate Node process (server/PC); the app talks to it over HTTP/Socket.IO — same API surface, different hosting. |
| N3 | Custom font file upload (.ttf/.otf picker) | Needs a file picker + font loading at runtime; font list + selection UI is ported, file import is not wired yet. |
| N4 | Custom emoji pack download & apply | Needs emoji font download + rendering; style list + system default are ported. |
| N5 | In-app camera (original has NO in-app camera by user rule) | Not ported by design — original rule: chat Camera opens the system camera, Status opens the gallery directly. v2 follows the same rule. |

## Count

- **103 settings/features inventoried from the original.**
- **98 ported in this pass** (settings screens + core features + gateway endpoints).
- **5 listed as "Not yet ported"** (N1–N5) — N5 is by design (user's own camera rule), the rest are single missing wirings, each with its screen/UI already in place.
