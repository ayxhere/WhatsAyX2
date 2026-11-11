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
