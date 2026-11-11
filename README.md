# WhatsAyX v2

A **separate, new** WhatsApp tool app — Flutter (app) + Node.js (gateway).
This is NOT the old AyXWhatsapp (native Android). That app continues as-is.
WhatsAyX v2 is a clean rebuild in the WZH style: clear, roomy, uncluttered.

- **Package:** `com.wa.ayx`
- **App:** Flutter 3.24 (Dart)
- **Gateway:** Node.js + Express + Socket.IO + Baileys (`@whiskeysockets/baileys`)
- **Linked-device name:** the WhatsApp linked device appears as **iMAyX**
  (Baileys `browser: ['iMAyX', 'Desktop', '1.0.0']`).

## Features (v1 — full port, not a cut-down build)

**Everything from the original app is here — only the UI is new
(WZH-style).** Full audit: [`SETTINGS_INVENTORY.md`](SETTINGS_INVENTORY.md)
— 103 settings/features inventoried, 98 ported, 5 listed as not yet ported.

- Smooth splash with the gold AyX logo (centred, 1254×1254)
- Connect WhatsApp via pairing code / QR (gateway) — device shows as **iMAyX**
- Chats list with search, hidden chats (double-tap title to reveal),
  mute / hide / mark read / delete / block, new chat by contacts or number
- Chat detail: bubbles, send via gateway, long-press menu (reply, forward,
  react, edit, delete, translate, info), reply-to quote
- Status: list with mute, viewer with progress bar, download, reply
- Music: JioSaavn / iTunes / Spotify (free route) search + lyrics
- Schedule: send a message later (pending / sent / failed / cancelled)
- Deleted messages view (tombstones)
- Broadcast: JSON composer + delay timer + send progress
- **Settings — same 10 categories as the original:** General, Auto-reply,
  AI Assistant (master, image reply, groups, commands, language, excluded
  chats, API config, vision, lyrics APIs, image AI), AI Voice (TTS voices,
  voice-note reply, Sarvam key), AI Memory, Chat (wallpaper, 8 bubble
  styles, bubble colors, header blur, header pill), Appearance (theme
  System/Light/AMOLED, 5 UI styles, 15 accents, blur & animation, text
  animation, message motion, icon style, font, emoji, translation, status
  + voice-note styles), Sync (Drive backup), Broadcast, About, Support
  (UPI + USDT)
- AyX dark theme (`#1A1D24` bg, `#4DD0C4` primary)

When the gateway is not running the app shows demo data, so the UI is
always usable. Connect the gateway to see real chats.

## Gateway endpoints

```
GET  /health     GET  /settings      POST /settings
GET  /qr         POST /pair          POST /reconnect   POST /logout
GET  /me         GET  /presence      GET  /contacts    GET  /statuses
POST /send       POST /markread      POST /react       POST /forward
POST /editmessage POST /message/delete POST /chat/delete POST /block
POST /profile/name  POST /profile/bio
GET  /aimemory   POST /aimemory/clear
GET  /deleted
GET  /schedule   POST /schedule      DELETE /schedule/:id
POST /broadcast
GET  /music/search   GET  /music/lyrics
POST /backup
```

Live WhatsApp routes answer 503 until the gateway is linked; local routes
(settings, schedule, AI memory, deleted) always work. Settings are stored
in `backend/auth/settings.json` with the same defaults/keys as the
original gateway.

## Run the gateway

```bash
cd backend
cp .env.example .env
npm install
npm start
# GET http://localhost:3000/health
```

The gateway stores the Baileys session in `backend/auth/` (created on
first link). Never commit that folder. No credentials are hardcoded.

## Run the app

```bash
flutter pub get
flutter run
```

The app talks to the gateway at `http://10.0.2.2:3000` by default
(Android emulator loopback). On a real device, point `ApiService.baseUrl`
at the machine running the gateway.

## Build the APK

Pushes to `main` build a debug APK in GitHub Actions
(`.github/workflows/build.yml`) and upload it as an artifact
(`whats-ayx-debug`).

## Project layout

```
lib/            Flutter app (main, theme, screens, widgets, models, services)
lib/screens/settings/   All 10 settings categories + sub-pages
lib/screens/tools/      Music + Schedule screens
assets/icon/    Gold AyX logo (ayx-logo.png, 1254×1254, centred)
android/        Android shell, package com.wa.ayx (Kotlin DSL, AGP 8.7.3)
backend/        Node gateway (Express + Socket.IO + Baileys)
SETTINGS_INVENTORY.md   Full audit: every original setting/feature
```

## Notes

- Original code only. No copied WhatsApp code, no premium unlocks,
  no hidden surveillance.
- Android: `values/themes.xml` + `values-night/themes.xml` carry an
  `AppTheme` on the platform theme, and `material:1.12.0` is a
  dependency (on-device build checklist).
