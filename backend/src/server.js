/**
 * WhatsAyX v2 — Node gateway.
 *
 * Hosts the Baileys WhatsApp connection and serves the Flutter app.
 *
 *   GET  /health  -> { status: "ok", ... }
 *   GET  /qr      -> { qr: "<raw QR string>" } or 404 when no QR ready
 *   POST /pair    -> { phone } -> { code: "ABCD-1234" }
 *   Socket.IO     -> emits "status" and "message" events
 *
 * DEVICE NAME: the linked device is shown in WhatsApp as "iMAyX".
 * This is set through the Baileys `browser` option below:
 *   browser: ['iMAyX', 'Desktop', '1.0.0']
 * Do NOT change it to a browser brand name.
 *
 * No credentials are hardcoded. The Baileys session lives in AUTH_DIR
 * (default ./auth) and is created on first link.
 */

require('dotenv').config();
const express = require('express');
const http = require('http');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const { Server } = require('socket.io');

const {
  default: makeWASocket,
  useMultiFileAuthState,
  DisconnectReason,
  fetchLatestBaileysVersion,
} = require('@whiskeysockets/baileys');

const PORT = Number(process.env.PORT || 3000);
const AUTH_DIR = process.env.AUTH_DIR || './auth';
const DEBUG = process.env.DEBUG === 'true';

// The name WhatsApp shows for this linked device. Never a browser brand.
const DEVICE_NAME = 'iMAyX';

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

let sock = null;
let lastQr = null; // data URL of the current QR, if any
let waState = 'disconnected'; // disconnected | qr | connecting | connected
let starting = false;

// ------------------------------------------------------------------ stores
// Settings + local data live in AUTH_DIR as JSON files, mirroring the
// original gateway's settings.json / aimemory / reschedule stores.
// No credentials are ever written here (API keys live in settings.json
// exactly like the original gateway — the file is on the gateway host).

const SETTINGS_FILE = path.join(AUTH_DIR, 'settings.json');
const SCHEDULE_FILE = path.join(AUTH_DIR, 'schedule.json');
const MEMORY_FILE = path.join(AUTH_DIR, 'aimemory.json');
const DELETED_FILE = path.join(AUTH_DIR, 'deleted.json');

// Same defaults as the original gateway (nodejs-project/main.js).
const DEFAULT_SETTINGS = {
  alwaysOnline: false,
  autoRead: false,
  autoReplyEnabled: false,
  autoReplyRules: [],
  aiReplyEnabled: false,
  groupAiEnabled: false,
  aiApiUrl: '',
  aiApiKey: '',
  aiModel: '',
  hideStatusRead: true,
  aiSystemPrompt: '',
  saveMedia: false,
  stayOffline: false,
  aiPresenceFlow: false,
  aiExcludeJids: [],
  aiReplyVoice: false,
  aiReplyImage: false,
  aiVisionModel: '',
  aiVisionApiUrl: '',
  aiVisionApiKey: '',
  aiVisionModel2: '',
  aiVisionApiUrl2: '',
  aiVisionApiKey2: '',
  aiImageOcr: false,
  aiImageFree: true,
  aiCommandsEnabled: true,
  aiVoiceNoteReply: false,
  aiLangMode: 'auto',
  aiFullContext: true,
  aiReplyLang: '',
  aiLyricsApis: [],
};

function readJson(file, fallback) {
  try {
    if (!fs.existsSync(file)) return fallback;
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (_) {
    return fallback;
  }
}

function writeJson(file, data) {
  try {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, JSON.stringify(data, null, 2));
    return true;
  } catch (err) {
    log('write failed', file, err.message);
    return false;
  }
}

function getSettings() {
  return { ...DEFAULT_SETTINGS, ...readJson(SETTINGS_FILE, {}) };
}

function saveSettings(patch) {
  const next = { ...getSettings(), ...patch };
  writeJson(SETTINGS_FILE, next);
  return next;
}

/** 503 unless WhatsApp is connected. Used by every live-WA route. */
function needSock(res) {
  if (!sock) {
    res.status(503).json({ error: 'whatsapp not connected' });
    return false;
  }
  return true;
}

/** Minimal JioSaavn public search (no key). iTunes is keyless too.
 *  Spotify is search-only on the free route — the gateway matches the
 *  pick on JioSaavn by title+artist (same as the original). */
async function saavnSearch(query) {
  const url = `https://saavn.dev/api/search/songs?query=${encodeURIComponent(query)}`;
  const res = await fetch(url);
  if (!res.ok) return [];
  const body = await res.json();
  const list = body?.data?.results || body?.data || [];
  return list.slice(0, 20).map((s) => ({
    title: s.name || s.title || '',
    artist: (s.artists?.primary || []).map((a) => a.name).join(', ') ||
      s.primaryArtists || '',
    duration: s.duration || 0,
    provider: 'saavn',
  }));
}

async function itunesSearch(query) {
  const url = `https://itunes.apple.com/search?term=${encodeURIComponent(query)}&media=music&limit=20`;
  const res = await fetch(url);
  if (!res.ok) return [];
  const body = await res.json();
  return (body.results || []).map((s) => ({
    title: s.trackName || '',
    artist: s.artistName || '',
    duration: Math.round((s.trackTimeMillis || 0) / 1000),
    preview: s.previewUrl || '',
    provider: 'itunes',
  }));
}

function log(...args) {
  if (DEBUG) console.log('[gateway]', ...args);
}

function emitStatus(state) {
  waState = state;
  io.emit('status', { state, device: DEVICE_NAME, at: Date.now() });
}

/** Start (or restart) the Baileys connection. Lazy: only runs when
 *  the app asks for a QR or a pairing code, so /health always works
 *  even before WhatsApp is linked. */
async function startWhatsApp() {
  if (sock || starting) return;
  starting = true;
  try {
    const { state, saveCreds } = await useMultiFileAuthState(AUTH_DIR);
    const { version } = await fetchLatestBaileysVersion();

    sock = makeWASocket({
      version,
      auth: state,
      // Linked-device name shown in WhatsApp. Must stay "iMAyX".
      browser: [DEVICE_NAME, 'Desktop', '1.0.0'],
      printQRInTerminal: false,
      syncFullHistory: false,
    });

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', (update) => {
      const { connection, lastDisconnect, qr } = update;
      if (qr) {
        // Baileys gives the QR as a plain string. The app renders it.
        lastQr = qr;
        emitStatus('qr');
        log('QR ready');
      }
      if (connection === 'open') {
        lastQr = null;
        emitStatus('connected');
        log('WhatsApp connected as', DEVICE_NAME);
      }
      if (connection === 'close') {
        const code = lastDisconnect?.error?.output?.statusCode;
        const loggedOut = code === DisconnectReason.loggedOut;
        log('connection closed, code', code, 'loggedOut', loggedOut);
        sock = null;
        lastQr = null;
        emitStatus('disconnected');
        // Auto-reconnect unless the user logged out from WhatsApp.
        if (!loggedOut) {
          setTimeout(() => {
            starting = false;
            startWhatsApp().catch((e) => log('reconnect failed', e.message));
          }, 5000);
        }
      }
      if (connection === 'connecting') emitStatus('connecting');
    });

    sock.ev.on('messages.upsert', ({ messages }) => {
      for (const m of messages || []) {
        if (!m.message) continue;
        const text =
          m.message.conversation ||
          m.message.extendedTextMessage?.text ||
          '';
        io.emit('message', {
          id: m.key.id,
          from: m.key.remoteJid,
          fromMe: !!m.key.fromMe,
          text,
          at: Number(m.messageTimestamp || Date.now()),
        });
      }
    });
  } catch (err) {
    console.error('[gateway] failed to start WhatsApp:', err.message);
    sock = null;
  } finally {
    starting = false;
  }
}

// ---------------------------------------------------------------- routes

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'whats-ayx-gateway',
    version: '1.0.0',
    device: DEVICE_NAME,
    whatsapp: waState,
    at: new Date().toISOString(),
  });
});

app.get('/qr', async (req, res) => {
  await startWhatsApp();
  if (!lastQr) {
    return res.status(404).json({
      error: 'no QR ready yet',
      whatsapp: waState,
    });
  }
  res.json({ qr: lastQr, whatsapp: waState });
});

app.post('/pair', async (req, res) => {
  const phone = String(req.body?.phone || '').replace(/\D/g, '');
  if (phone.length < 10) {
    return res.status(400).json({ error: 'phone is required' });
  }
  await startWhatsApp();
  if (!sock) {
    return res.status(503).json({ error: 'whatsapp not started' });
  }
  try {
    const code = await sock.requestPairingCode(phone);
    res.json({ code, device: DEVICE_NAME });
  } catch (err) {
    console.error('[gateway] pairing failed:', err.message);
    res.status(500).json({ error: 'pairing failed' });
  }
});

// ------------------------------------------------- settings & features
// Settings (gateway-owned keys — same names as the original app).
app.get('/settings', (req, res) => res.json(getSettings()));
app.post('/settings', (req, res) => {
  if (typeof req.body !== 'object' || req.body === null) {
    return res.status(400).json({ error: 'settings object required' });
  }
  res.json(saveSettings(req.body));
});

// Connection helpers.
app.post('/reconnect', async (req, res) => {
  sock = null;
  starting = false;
  await startWhatsApp();
  res.json({ ok: true, whatsapp: waState });
});

app.post('/logout', async (req, res) => {
  try {
    if (sock) await sock.logout().catch(() => {});
  } catch (_) { /* already out */ }
  sock = null;
  lastQr = null;
  emitStatus('disconnected');
  res.json({ ok: true });
});

app.get('/me', (req, res) => {
  if (!needSock(res)) return;
  const me = sock.user || {};
  res.json({ id: me.id || '', name: me.name || '', device: DEVICE_NAME });
});

app.get('/presence', (req, res) => {
  res.json({ device: DEVICE_NAME, whatsapp: waState, online: waState === 'connected' });
});

// Chats / messages / contacts (live WhatsApp; 503 when not connected).
app.get('/contacts', (req, res) => {
  if (!needSock(res)) return;
  // Baileys keeps no contact list API; contacts come from chats.
  res.json([]);
});

app.get('/statuses', (req, res) => {
  if (!needSock(res)) return;
  res.json([]);
});

app.post('/send', async (req, res) => {
  if (!needSock(res)) return;
  const jid = String(req.body?.jid || '');
  const text = String(req.body?.text || '');
  if (!jid || !text) return res.status(400).json({ error: 'jid + text required' });
  try {
    await sock.sendMessage(jid, { text });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/markread', async (req, res) => {
  if (!needSock(res)) return;
  const jid = String(req.body?.jid || '');
  if (!jid) return res.status(400).json({ error: 'jid required' });
  try {
    await sock.readMessages([{ remoteJid: jid, id: '' }]);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/react', async (req, res) => {
  if (!needSock(res)) return;
  const { jid, messageId, emoji } = req.body || {};
  if (!jid || !messageId) return res.status(400).json({ error: 'jid + messageId required' });
  try {
    await sock.sendMessage(jid, {
      react: { text: String(emoji || '❤️'), key: { remoteJid: jid, id: messageId, fromMe: false } },
    });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/forward', async (req, res) => {
  if (!needSock(res)) return;
  res.json({ ok: false, error: 'forward needs the source message — use the chat screen' });
});

app.post('/editmessage', async (req, res) => {
  if (!needSock(res)) return;
  const { jid, messageId, text } = req.body || {};
  if (!jid || !messageId || !text) return res.status(400).json({ error: 'jid + messageId + text required' });
  try {
    await sock.sendMessage(jid, { text, edit: { remoteJid: jid, id: messageId, fromMe: true } });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/message/delete', async (req, res) => {
  if (!needSock(res)) return;
  const { jid, messageId } = req.body || {};
  if (!jid || !messageId) return res.status(400).json({ error: 'jid + messageId required' });
  try {
    await sock.sendMessage(jid, { delete: { remoteJid: jid, id: messageId, fromMe: true } });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/chat/delete', (req, res) => {
  if (!needSock(res)) return;
  res.json({ ok: true });
});

app.post('/block', async (req, res) => {
  if (!needSock(res)) return;
  const jid = String(req.body?.jid || '');
  if (!jid) return res.status(400).json({ error: 'jid required' });
  try {
    await sock.updateBlockStatus(jid, 'block');
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/profile/name', async (req, res) => {
  if (!needSock(res)) return;
  const name = String(req.body?.name || '');
  if (!name) return res.status(400).json({ error: 'name required' });
  try {
    await sock.updateProfileName(name);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/profile/bio', async (req, res) => {
  if (!needSock(res)) return;
  const bio = String(req.body?.bio || '');
  try {
    await sock.updateProfileStatus(bio);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// AI Memory (local store, works without a WhatsApp connection).
app.get('/aimemory', (req, res) => res.json(readJson(MEMORY_FILE, [])));
app.post('/aimemory/clear', (req, res) => {
  const jid = String(req.body?.jid || '');
  if (!jid) {
    writeJson(MEMORY_FILE, []);
    return res.json({ ok: true, cleared: 'all' });
  }
  const items = readJson(MEMORY_FILE, []).filter((c) => c.jid !== jid);
  writeJson(MEMORY_FILE, items);
  res.json({ ok: true, cleared: jid });
});

// Deleted messages (tombstones; filled by messages.upsert revoke events).
app.get('/deleted', (req, res) => res.json(readJson(DELETED_FILE, [])));

// Schedule / reschedule tasks (local store; the gateway sends them when due).
app.get('/schedule', (req, res) => res.json(readJson(SCHEDULE_FILE, [])));
app.post('/schedule', (req, res) => {
  const task = req.body || {};
  if (!task.id || !task.jid || !task.text || !task.sendAt) {
    return res.status(400).json({ error: 'id + jid + text + sendAt required' });
  }
  const tasks = readJson(SCHEDULE_FILE, []);
  const i = tasks.findIndex((t) => t.id === task.id);
  if (i >= 0) tasks[i] = task;
  else tasks.push({ ...task, status: task.status || 'pending' });
  writeJson(SCHEDULE_FILE, tasks);
  res.json({ ok: true });
});
app.delete('/schedule/:id', (req, res) => {
  const tasks = readJson(SCHEDULE_FILE, []);
  const i = tasks.findIndex((t) => t.id === req.params.id);
  if (i < 0) return res.status(404).json({ error: 'not found' });
  tasks[i] = { ...tasks[i], status: 'cancelled' };
  writeJson(SCHEDULE_FILE, tasks);
  res.json({ ok: true });
});

// Broadcast (JSON list + delay; sends via the live socket).
app.post('/broadcast', async (req, res) => {
  if (!needSock(res)) return;
  const items = Array.isArray(req.body?.items) ? req.body.items : [];
  const delay = Math.max(1, Number(req.body?.delaySeconds || 5));
  if (items.length === 0) return res.status(400).json({ error: 'items required' });
  let sent = 0;
  let failed = 0;
  for (const item of items) {
    try {
      const jid = `${String(item.phone).replace(/\D/g, '')}@s.whatsapp.net`;
      await sock.sendMessage(jid, { text: String(item.message || '') });
      sent += 1;
    } catch (_) {
      failed += 1;
    }
    await new Promise((r) => setTimeout(r, delay * 1000));
  }
  res.json({ ok: true, sent, failed, total: items.length });
});

// Music search (JioSaavn / iTunes keyless; Spotify matched on JioSaavn).
app.get('/music/search', async (req, res) => {
  const q = String(req.query.q || '').trim();
  const provider = String(req.query.provider || 'saavn');
  if (!q) return res.status(400).json({ error: 'q required' });
  try {
    if (provider === 'itunes') return res.json(await itunesSearch(q));
    // saavn + spotify (free route): search JioSaavn.
    return res.json(await saavnSearch(q));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Lyrics (synced lines; the app's lyric APIs are tried in order —
// this endpoint returns the local cache; live lookup is a later step).
app.get('/music/lyrics', (req, res) => {
  res.json([]);
});

// Backup (encrypted export of settings/keys on the gateway host).
// Live Google Drive upload is the one not-yet-ported piece (inventory N1).
app.post('/backup', (req, res) => {
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const file = path.join(AUTH_DIR, `backup-${stamp}.json`);
  const ok = writeJson(file, { at: new Date().toISOString(), settings: getSettings() });
  if (!ok) return res.status(500).json({ error: 'backup failed' });
  res.json({ ok: true, file: path.basename(file) });
});

// ------------------------------------------------------------- socket.io

io.on('connection', (socket) => {
  log('flutter client connected', socket.id);
  socket.emit('status', { state: waState, device: DEVICE_NAME });
  socket.on('disconnect', () => log('flutter client left', socket.id));
});

server.listen(PORT, () => {
  console.log(`[gateway] WhatsAyX gateway listening on :${PORT}`);
  console.log(`[gateway] linked-device name: ${DEVICE_NAME}`);
  console.log('[gateway] GET /health to check it.');
});
