/**
 * Limiteur de débit : le refus est lisible par l'application, et chaque utilisateur a son propre compteur derrière le
 * proxy du cloud. Cas réel : « Trop de requêtes » en continu sur mobile (100 requêtes / 15 min pour TOUS les
 * utilisateurs, car le serveur voyait l'adresse du proxy), refus en texte brut que l'application affichait comme
 * « SyntaxError: Unexpected token 'T' ».
 *
 * Exécution :  node --test tests/rate-limit.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const express = require('express');
const MiddlewareManager = require('../src/middleware');

function serveur({ max = 2, trustProxy = false } = {}) {
  const app = express();
  if (trustProxy) app.set('trust proxy', 1);
  app.use('/api/', MiddlewareManager.createRateLimiter({ windowMs: 15 * 60 * 1000, max, standardHeaders: true, legacyHeaders: false }));
  app.get('/api/ping', (req, res) => res.json({ success: true }));
  const srv = app.listen(0);
  return { url: `http://127.0.0.1:${srv.address().port}/api/ping`, close: () => srv.close() };
}

test('au-delà de la limite : 429 en JSON avec un message clair, un code et le délai conseillé', async () => {
  const s = serveur({ max: 2 });
  try {
    assert.strictEqual((await fetch(s.url)).status, 200);
    assert.strictEqual((await fetch(s.url)).status, 200);
    const r = await fetch(s.url);
    assert.strictEqual(r.status, 429);
    assert.match(r.headers.get('content-type'), /application\/json/, 'JSON, pas du texte brut');
    assert.ok(Number(r.headers.get('retry-after')) >= 1, 'en-tête Retry-After');
    const corps = await r.json();
    assert.strictEqual(corps.success, false);
    assert.strictEqual(corps.code, 'RATE_LIMITED');
    assert.match(corps.message, /Patientez/);
    assert.ok(corps.retryAfterSeconds >= 1);
  } finally { s.close(); }
});

test('derrière le proxy du cloud (trust proxy) : chaque client a son propre compteur', async () => {
  const s = serveur({ max: 1, trustProxy: true });
  try {
    const avec = (ip) => fetch(s.url, { headers: { 'X-Forwarded-For': ip } });
    assert.strictEqual((await avec('203.0.113.1')).status, 200);
    assert.strictEqual((await avec('203.0.113.1')).status, 429, 'le même client est limité');
    assert.strictEqual((await avec('203.0.113.2')).status, 200, 'un autre client n\'est PAS pénalisé');
  } finally { s.close(); }
});

test('sans trust proxy (ancien comportement) : tous les clients partageaient le même compteur', async () => {
  const s = serveur({ max: 1, trustProxy: false });
  try {
    const avec = (ip) => fetch(s.url, { headers: { 'X-Forwarded-For': ip } });
    assert.strictEqual((await avec('203.0.113.1')).status, 200);
    assert.strictEqual((await avec('203.0.113.2')).status, 429, 'défaut d\'origine : un autre client est bloqué à tort');
  } finally { s.close(); }
});

test('limites par défaut : cloud réaliste (2000), local très large, test sans limite', () => {
  const garde = { ...process.env };
  const charger = () => { delete require.cache[require.resolve('../src/config/environment')]; return require('../src/config/environment'); };
  try {
    process.env.NODE_ENV = 'production';
    process.env.RENDER = 'true';
    delete process.env.RATE_LIMIT_MAX;
    delete process.env.TEST_MODE;
    assert.strictEqual(charger().getMiddlewareConfig().rateLimit.max, 2000);
    process.env.RATE_LIMIT_MAX = '500';
    assert.strictEqual(charger().getMiddlewareConfig().rateLimit.max, 500, 'réglable par RATE_LIMIT_MAX');
    process.env.NODE_ENV = 'test';
    assert.ok(charger().getMiddlewareConfig().rateLimit.max >= 999999);
  } finally {
    process.env = garde;
    charger();
  }
});
