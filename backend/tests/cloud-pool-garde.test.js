/**
 * Une connexion à Neon qui tombe pendant qu'elle sert une requête ne doit plus arrêter le serveur.
 *
 * Exécution :  node --test tests/cloud-pool-garde.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const { EventEmitter } = require('node:events');
const { Pool } = require('pg');
const { protegerConnexions } = require('../src/services/cloud-pool-garde');

test('SANS la garde : une erreur de connexion prêtée est une exception non capturée (le défaut)', () => {
  const client = new EventEmitter();
  assert.throws(() => client.emit('error', new Error('Connection terminated unexpectedly')), /Connection terminated unexpectedly/);
});

test('AVEC la garde : l erreur est journalisée, rien n est levé', () => {
  const pool = new EventEmitter();
  const messages = [];
  protegerConnexions(pool, (m) => messages.push(m));
  const client = new EventEmitter();
  pool.emit('connect', client);
  assert.doesNotThrow(() => client.emit('error', new Error('Connection terminated unexpectedly')));
  assert.strictEqual(messages.length, 1);
  assert.match(messages[0], /Connection terminated unexpectedly/);
});

test('la garde s applique à chaque nouvelle connexion, pas seulement à la première', () => {
  const pool = new EventEmitter();
  const messages = [];
  protegerConnexions(pool, (m) => messages.push(m));
  const c1 = new EventEmitter();
  const c2 = new EventEmitter();
  pool.emit('connect', c1);
  pool.emit('connect', c2);
  c1.emit('error', new Error('un'));
  c2.emit('error', new Error('deux'));
  assert.strictEqual(messages.length, 2);
});

test('avec un vrai pool pg : une connexion coupée pendant une requête fait échouer la requête, sans exception non capturée', async () => {
  // Faux serveur TCP qui accepte puis coupe aussitôt : le client pg voit "Connection terminated"
  const net = require('node:net');
  const serveur = net.createServer((socket) => socket.destroy());
  await new Promise((r) => serveur.listen(0, '127.0.0.1', r));
  const port = serveur.address().port;

  const nonCapturees = [];
  const ecouteur = (e) => nonCapturees.push(e);
  process.on('uncaughtException', ecouteur);

  const pool = new Pool({ host: '127.0.0.1', port, user: 'x', password: 'x', database: 'x', max: 1, connectionTimeoutMillis: 3000 });
  protegerConnexions(pool, () => {});
  pool.on('error', () => {});
  let erreur = null;
  try {
    await pool.connect();
  } catch (e) {
    erreur = e;
  }
  await new Promise((r) => setTimeout(r, 300));
  process.off('uncaughtException', ecouteur);
  await pool.end().catch(() => {});
  serveur.close();

  assert.ok(erreur, 'la connexion échoue normalement (erreur gérée par l appelant)');
  assert.deepStrictEqual(nonCapturees, [], 'aucune exception non capturée');
});
