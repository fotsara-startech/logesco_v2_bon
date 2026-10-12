/**
 * Validation du banc de pannes réseau LUI-MÊME (aucun accès Neon requis) : un serveur d'écho local sert de cible.
 *   node --test tests/e2e-sync/scenarios/20-banc-pannes.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const net = require('node:net');
const { execFile } = require('node:child_process');
const lancer = (args, env) => new Promise((resolve) => execFile(process.execPath, args, { env, encoding: 'utf8', timeout: 15000 }, (e, stdout, stderr) => resolve({ stdout, stderr })));
const { BancPannes, PRELOAD } = require('../harness/network-faults');

async function echo() {
  const s = net.createServer((c) => { c.on('data', (b) => c.write(b)); c.on('error', () => {}); });
  await new Promise((r) => s.listen(0, '127.0.0.1', r));
  return s;
}

async function banc(t) {
  const cible = await echo();
  const b = await BancPannes.demarrer({ host: '127.0.0.1', port: cible.address().port });
  t.after(async () => { await b.arreter(); cible.close(); });
  return b;
}

/** Envoie `octets` au banc et rend { duree, recus, evenement } */
function aller(b, octets, { delaiMs = 15000 } = {}) {
  return new Promise((resolve) => {
    const t0 = Date.now();
    let recus = 0;
    const c = net.connect(b.port, '127.0.0.1');
    c.on('connect', () => c.write(Buffer.alloc(octets, 1)));
    c.on('data', (d) => { recus += d.length; if (recus >= octets) { c.destroy(); resolve({ duree: Date.now() - t0, recus, evenement: 'ok' }); } });
    c.on('error', (e) => resolve({ duree: Date.now() - t0, recus, evenement: e.code || 'erreur' }));
    c.on('close', () => resolve({ duree: Date.now() - t0, recus, evenement: 'ferme' }));
    setTimeout(() => { c.destroy(); resolve({ duree: Date.now() - t0, recus, evenement: 'delai' }); }, delaiMs);
  });
}

test('banc : réseau parfait = transparent', async (t) => {
  const b = await banc(t);
  const r = await aller(b, 50000);
  assert.strictEqual(r.evenement, 'ok');
  assert.ok(r.duree < 1000, `${r.duree} ms`);
});

test('banc : latence 1 s = aller-retour d\'environ 1 s', async (t) => {
  const b = await banc(t);
  b.regler({ latenceMs: 1000 });
  const r = await aller(b, 100);
  assert.strictEqual(r.evenement, 'ok');
  assert.ok(r.duree >= 950 && r.duree < 2000, `${r.duree} ms`);
});

test('banc : plafond de débit 20 ko/s', async (t) => {
  const b = await banc(t);
  b.regler({ debitOctetsParSec: 20000 });
  const r = await aller(b, 40000);
  assert.strictEqual(r.evenement, 'ok');
  assert.ok(r.duree >= 1800 && r.duree < 4500, `${r.duree} ms pour 40 ko à 20 ko/s`);
});

test('banc : coupures aléatoires de connexion', async (t) => {
  const b = await banc(t);
  b.regler({ coupureConnexion: 0.5, coupureMinOctets: 100, coupureMaxOctets: 1000 });
  const res = [];
  for (let i = 0; i < 20; i++) res.push((await aller(b, 5000)).evenement);
  const ok = res.filter((x) => x === 'ok').length;
  assert.ok(ok >= 4 && ok <= 16, `${ok}/20 réussies (50 % attendues) : ${res.join(',')}`);
  assert.ok(b.stats.coupuresAleatoires > 0);
});

test('banc : coupure au milieu d\'une requête', async (t) => {
  const b = await banc(t);
  b.regler({ coupureRequete: 1 });
  const r = await aller(b, 5000);
  assert.notStrictEqual(r.evenement, 'ok');
  assert.ok(b.stats.coupuresRequete >= 1);
});

test('banc : trou noir puis reprise des octets gardés', async (t) => {
  const b = await banc(t);
  b.trouNoir(1500);
  const r = await aller(b, 100);
  assert.strictEqual(r.evenement, 'ok');
  assert.ok(r.duree >= 1400, `les octets doivent attendre la fin du trou noir (${r.duree} ms)`);
  b.trouNoir(Infinity);
  const r2 = await aller(b, 100, { delaiMs: 1500 });
  assert.strictEqual(r2.evenement, 'delai', 'rien ne revient pendant un trou noir');
  b.finTrouNoir();
});

test('banc : coupure totale tue l\'existant et refuse le neuf, puis rétablit', async (t) => {
  const b = await banc(t);
  const longue = net.connect(b.port, '127.0.0.1');
  const fin = new Promise((r) => { longue.on('close', () => r('ferme')); longue.on('error', () => {}); });
  await new Promise((r) => longue.on('connect', r));
  b.coupureTotale(1500);
  assert.strictEqual(await fin, 'ferme', 'la connexion ouverte est tuée');
  const r = await aller(b, 100);
  assert.notStrictEqual(r.evenement, 'ok', 'connexion refusée pendant la coupure');
  await new Promise((r2) => setTimeout(r2, 1600));
  assert.strictEqual((await aller(b, 100)).evenement, 'ok', 'réseau revenu');
});

test('banc : alternance marche/arrêt', async (t) => {
  const b = await banc(t);
  b.alternance({ marcheMs: [300, 400], arretMs: [300, 400] });
  const res = [];
  for (let i = 0; i < 20; i++) { res.push((await aller(b, 100, { delaiMs: 2000 })).evenement); await new Promise((r) => setTimeout(r, 120)); }
  b.arreterAlternance();
  const ok = res.filter((x) => x === 'ok').length;
  assert.ok(ok >= 3 && ok < 20, `${ok}/20 réussies : ${res.join(',')}`);
  assert.strictEqual((await aller(b, 100)).evenement, 'ok');
});

test('préchargement : une connexion vers un hôte quelconque :5432 passe par le banc', async (t) => {
  const b = await banc(t);
  const code = "const net=require('net');const c=net.connect({host:'hote-inexistant.invalid',port:5432});c.on('connect',()=>c.write('ping'));c.on('data',d=>{console.log('ECHO:'+d);process.exit(0)});c.on('error',e=>{console.log('ERR:'+e.code);process.exit(1)});";
  const r = await lancer(['-r', PRELOAD, '-e', code], { ...process.env, LOGESCO_FAULT_PROXY_PORT: String(b.port) });
  assert.match(r.stdout, /ECHO:ping/, r.stdout + r.stderr);
  assert.ok(b.stats.acceptees >= 1);
  // forme (port, hôte) utilisée par pg
  const code2 = "const net=require('net');const c=new net.Socket();c.connect(5432,'hote-inexistant.invalid');c.on('connect',()=>c.write('pong'));c.on('data',d=>{console.log('ECHO:'+d);process.exit(0)});c.on('error',e=>{console.log('ERR:'+e.code);process.exit(1)});";
  const r2 = await lancer(['-r', PRELOAD, '-e', code2], { ...process.env, LOGESCO_FAULT_PROXY_PORT: String(b.port) });
  assert.match(r2.stdout, /ECHO:pong/, r2.stdout + r2.stderr);
});
