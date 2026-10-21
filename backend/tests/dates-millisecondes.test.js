/**
 * Dates stockées en millisecondes partout : conversion unique des dates en texte, réception du cloud qui écrit des nombres,
 * liste des ventes par période.
 *
 * Exécution :  node --experimental-sqlite --test tests/dates-millisecondes.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const http = require('node:http');
const express = require('express');
const { execSync } = require('node:child_process');
const { PrismaClient } = require('@prisma/client');

process.env.NODE_ENV = 'test';
process.env.CLOUD_DB_URL = 'postgresql://fake';

const { versMillisecondes, normaliserDates } = require('../src/services/dates-sqlite');
const migrationRunner = require('../src/services/migration-runner');
const syncService = require('../src/services/sync-service');

const dossier = fs.mkdtempSync(path.join(os.tmpdir(), 'dates-ms-'));
const url = `file:${path.join(dossier, 'essai.db').split(path.sep).join('/')}?connection_limit=1`;
let prisma;
const serveurs = [];

const T = (a, m, j, h = 10) => new Date(a, m - 1, j, h, 0, 0);
const typeDe = async (table, colonne, where = '1=1') =>
  (await prisma.$queryRawUnsafe(`SELECT typeof("${colonne}") AS t FROM ${table} WHERE ${where}`)).map((r) => r.t);

test.before(async () => {
  execSync('npx prisma db push --skip-generate --accept-data-loss', {
    cwd: path.join(__dirname, '..'),
    env: { ...process.env, DATABASE_URL: url },
    stdio: 'ignore',
  });
  prisma = new PrismaClient({ datasources: { db: { url } } });
  await prisma.$executeRawUnsafe('PRAGMA foreign_keys = OFF');
  syncService.localPrisma = prisma;
});

test.after(async () => {
  for (const s of serveurs) s.close();
  if (prisma) await prisma.$disconnect();
  fs.rmSync(dossier, { recursive: true, force: true });
});

test('conversion d une valeur en millisecondes : Date, nombre, texte ISO, texte SQL (UTC), illisible', () => {
  const ref = Date.UTC(2026, 6, 29, 7, 23, 14, 208);
  assert.strictEqual(versMillisecondes(new Date(ref)), ref);
  assert.strictEqual(versMillisecondes(ref), ref);
  assert.strictEqual(versMillisecondes('2026-07-29T07:23:14.208Z'), ref);
  assert.strictEqual(versMillisecondes('2026-07-29 07:23:14'), Date.UTC(2026, 6, 29, 7, 23, 14));
  assert.strictEqual(versMillisecondes('2026-07-29T08:23:14.208+01:00'), ref);
  assert.strictEqual(versMillisecondes('pas une date'), null);
  assert.strictEqual(versMillisecondes(null), null);
  assert.strictEqual(versMillisecondes(new Date('x')), null);
});

test('la conversion unique transforme le texte en nombre, sans toucher aux nombres, aux tables internes ni au texte illisible', async () => {
  await prisma.$executeRawUnsafe(`INSERT INTO ventes (numero_vente, sous_total, montant_total, date_vente) VALUES ('V-iso', 1, 1, '2026-07-29T07:23:14.208Z')`);
  await prisma.$executeRawUnsafe(`INSERT INTO ventes (numero_vente, sous_total, montant_total, date_vente) VALUES ('V-sql', 1, 1, '2026-07-29 07:23:14')`);
  await prisma.$executeRawUnsafe(`INSERT INTO ventes (numero_vente, sous_total, montant_total, date_vente) VALUES ('V-nombre', 1, 1, ${Date.UTC(2026, 6, 30)})`);
  await prisma.$executeRawUnsafe(`INSERT INTO ventes (numero_vente, sous_total, montant_total, date_vente) VALUES ('V-bizarre', 1, 1, 'pas une date')`);
  await prisma.$executeRawUnsafe(`INSERT INTO operation_log (operation_id, operation_type, table_name, record_id, data, timestamp) VALUES ('op1', 'INSERT', 'ventes', 1, '{}', '2026-07-29 07:23:14')`);

  const r = await normaliserDates(prisma);
  assert.ok(r.lignes >= 2, JSON.stringify(r));

  const lignes = await prisma.$queryRawUnsafe(`SELECT numero_vente n, typeof(date_vente) t, CAST(date_vente AS TEXT) d FROM ventes ORDER BY id`);
  const parNom = Object.fromEntries(lignes.map((l) => [l.n, l]));
  assert.deepStrictEqual([parNom['V-iso'].t, Number(parNom['V-iso'].d)], ['integer', Date.UTC(2026, 6, 29, 7, 23, 14, 208)]);
  assert.deepStrictEqual([parNom['V-sql'].t, Number(parNom['V-sql'].d)], ['integer', Date.UTC(2026, 6, 29, 7, 23, 14)]);
  assert.strictEqual(parNom['V-nombre'].t, 'integer');
  assert.strictEqual(parNom['V-bizarre'].t, 'text', 'une valeur illisible est laissée telle quelle');
  assert.deepStrictEqual(await typeDe('operation_log', 'timestamp'), ['text'], 'les tables internes de la synchro ne sont pas touchées');
  await prisma.$executeRawUnsafe("DELETE FROM ventes WHERE numero_vente = 'V-bizarre'"); // une valeur illisible fait échouer toute lecture de la table par l ORM
});

test('la conversion est relançable : une deuxième exécution ne change plus rien', async () => {
  const r = await normaliserDates(prisma);
  assert.strictEqual(r.lignes, 0);
});

test('après conversion, le filtre brut de l ORM et le tri par date sont justes', async () => {
  const apres2030 = await prisma.vente.count({ where: { dateVente: { gte: new Date(2030, 0, 1) }, numeroVente: { not: 'V-bizarre' } } });
  assert.strictEqual(apres2030, 0);
  const l = await prisma.vente.findMany({ where: { numeroVente: { not: 'V-bizarre' } }, orderBy: { dateVente: 'desc' }, select: { numeroVente: true } });
  assert.deepStrictEqual(l.map((v) => v.numeroVente), ['V-nombre', 'V-iso', 'V-sql']);
});

test('réception d une ligne du cloud : la date est écrite en NOMBRE (création puis mise à jour) et relue correctement', async () => {
  const date = new Date(Date.UTC(2026, 9, 20, 12, 30, 0, 123));
  await syncService._mergeRemoteRow('ventes', { id: 900, numero_vente: 'V-cloud', sous_total: 5, montant_total: 5, date_vente: date });
  assert.deepStrictEqual(await typeDe('ventes', 'date_vente', 'id = 900'), ['integer']);
  const lue = await prisma.vente.findUnique({ where: { id: 900 } });
  assert.strictEqual(lue.dateVente.getTime(), date.getTime());

  // la même ligne revient du cloud au cycle suivant : elle ne repasse pas en texte
  const plusTard = new Date(date.getTime() + 60000);
  await syncService._mergeRemoteRow('ventes', { id: 900, numero_vente: 'V-cloud', sous_total: 5, montant_total: 5, date_vente: plusTard });
  assert.deepStrictEqual(await typeDe('ventes', 'date_vente', 'id = 900'), ['integer']);
  assert.strictEqual((await prisma.vente.findUnique({ where: { id: 900 } })).dateVente.getTime(), plusTard.getTime());

  // une date envoyée sous forme de texte par le cloud est elle aussi convertie
  await syncService._mergeRemoteRow('ventes', { id: 901, numero_vente: 'V-cloud-txt', sous_total: 5, montant_total: 5, date_vente: '2026-10-20T12:30:00.000Z' });
  assert.deepStrictEqual(await typeDe('ventes', 'date_vente', 'id = 901'), ['integer']);
});

test('réception du cloud : les colonnes qui ne sont pas des dates ne sont pas modifiées', async () => {
  await syncService._mergeRemoteRow('ventes', { id: 902, numero_vente: '2026-10-20T12:30:00Z', sous_total: 5, montant_total: 5 });
  const l = await prisma.$queryRawUnsafe('SELECT numero_vente AS n, typeof(numero_vente) AS t FROM ventes WHERE id = 902');
  assert.deepStrictEqual([l[0].t, l[0].n], ['text', '2026-10-20T12:30:00Z']);
});

test('migration au démarrage : convertit une seule fois, puis ne refait plus rien', async () => {
  await prisma.$executeRawUnsafe(`INSERT INTO ventes (numero_vente, sous_total, montant_total, date_vente) VALUES ('V-avant-migration', 1, 1, '2026-08-01T10:00:00.000Z')`);
  await migrationRunner.run(prisma, { freshInstall: false });
  assert.deepStrictEqual(await typeDe('ventes', 'date_vente', `numero_vente = 'V-avant-migration'`), ['integer']);

  await prisma.$executeRawUnsafe(`INSERT INTO ventes (numero_vente, sous_total, montant_total, date_vente) VALUES ('V-apres-migration', 1, 1, '2026-08-02T10:00:00.000Z')`);
  await migrationRunner.run(prisma, { freshInstall: false });
  assert.deepStrictEqual(await typeDe('ventes', 'date_vente', `numero_vente = 'V-apres-migration'`), ['text'], 'déjà faite : pas de nouvelle conversion');
});

test('liste des ventes par période (requête SQL directe) : le 5 au 22 octobre renvoie B, C, D, quel que soit le format', async () => {
  const createSalesRouter = require('../src/routes/sales');
  const donnees = [['A', T(2026, 10, 1), 'iso'], ['B', T(2026, 10, 10), 'ms'], ['C', T(2026, 10, 15), 'iso'], ['D', T(2026, 10, 20), 'ms'], ['E', T(2026, 10, 25), 'iso']];
  for (const [n, d, f] of donnees) {
    await prisma.$executeRawUnsafe(
      `INSERT INTO ventes (numero_vente, sous_total, montant_total, statut, date_vente, vendeur_id) VALUES (?, 1, 1, 'terminee', ?, 1)`,
      `LST-${n}`, f === 'ms' ? d.getTime() : d.toISOString(),
    );
  }
  const app = express();
  app.use('/', createSalesRouter({ prisma, authService: {}, syncService: null }));
  const serveur = http.createServer(app);
  await new Promise((r) => serveur.listen(0, r));
  serveurs.push(serveur);
  const reponse = await fetch(`http://127.0.0.1:${serveur.address().port}/?dateDebut=2026-10-05T00:00:00&dateFin=2026-10-22T00:00:00&limit=50`, {
    headers: { authorization: 'Bearer test-token' },
  });
  const texte = await reponse.text();
  assert.strictEqual(reponse.status, 200, texte.slice(0, 300));
  const trouves = [...new Set([...texte.matchAll(/LST-([A-E])/g)].map((m) => m[1]))].sort();
  assert.deepStrictEqual(trouves, ['B', 'C', 'D']);
});
