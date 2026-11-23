/**
 * Routes comptabilité : enchaînement HTTP complet et contrôle des droits.
 * Exécution : node --test tests/compta-routes.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const express = require('express');
const { PrismaClient } = require('@prisma/client');
const referentiel = require('../src/compta/referentiel');
const { ComptaService } = require('../src/compta/compta-service');
const { createComptaRouter } = require('../src/routes/compta');
const { EtatsService } = require('../src/compta/etats');

const dossier = fs.mkdtempSync(path.join(os.tmpdir(), 'compta-routes-'));
const prisma = new PrismaClient({ datasources: { db: { url: `file:${path.join(dossier, 'test.db').replace(/\\/g, '/')}` } } });

// Utilisateurs fictifs : 1 administrateur, 2 lecteur, 3 comptable (saisie), 4 sans droit comptable
const utilisateurs = {
  1: { id: 1, isActive: true, role: { isAdmin: true, privileges: null } },
  2: { id: 2, isActive: true, role: { isAdmin: false, privileges: JSON.stringify({ accounting: ['READ'] }) } },
  3: { id: 3, isActive: true, role: { isAdmin: false, privileges: JSON.stringify({ accounting: ['READ', 'CREATE'] }) } },
  4: { id: 4, isActive: true, role: { isAdmin: false, privileges: JSON.stringify({ sales: ['READ'] }) } },
};
const facade = {
  comptaJournal: prisma.comptaJournal,
  utilisateur: { findUnique: async ({ where }) => utilisateurs[where.id] || null },
};
const authService = { verifyAccessToken: (t) => ({ userId: Number(t), nomUtilisateur: `u${t}`, email: 'x@x' }) };

let serveur;
let base;
const appel = async (jeton, methode, url, corps) => {
  const r = await fetch(base + url, {
    method: methode,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${jeton}` },
    body: corps ? JSON.stringify(corps) : undefined,
  });
  return { status: r.status, body: await r.json() };
};

test.before(async () => {
  for (const migration of ['add_compta_socle', 'add_compta_audit']) {
    const sql = fs.readFileSync(path.join(__dirname, `../prisma/migrations/${migration}/migration.sql`), 'utf8');
    for (const i of sql.split('\n').filter((l) => !l.trim().startsWith('--')).join('\n').split(';').map((s) => s.trim()).filter(Boolean)) {
      await prisma.$executeRawUnsafe(i);
    }
  }
  await referentiel.ensureReferentiel(prisma);
  const app = express();
  app.use(express.json());
  app.use('/compta', createComptaRouter({ authService, prisma: facade, comptaService: new ComptaService(prisma, null), etatsService: new EtatsService(prisma, new ComptaService(prisma, null)) }));
  await new Promise((ok) => { serveur = app.listen(0, '127.0.0.1', ok); });
  base = `http://127.0.0.1:${serveur.address().port}/compta`;
});

test.after(async () => {
  await new Promise((ok) => serveur.close(ok));
  await prisma.$disconnect();
  fs.rmSync(dossier, { recursive: true, force: true });
});

test('sans jeton : refusé', async () => {
  const r = await fetch(`${base}/comptes`);
  assert.ok([401, 403].includes(r.status), `statut ${r.status}`);
});

test('droits : administrateur, lecteur, comptable et utilisateur sans droit comptable', async () => {
  assert.strictEqual((await appel(4, 'GET', '/comptes')).status, 403);
  assert.strictEqual((await appel(2, 'GET', '/comptes')).status, 200);
  assert.strictEqual((await appel(2, 'POST', '/comptes', { numero: '57102', libelle: 'x' })).status, 403);
  assert.strictEqual((await appel(3, 'POST', '/comptes', { numero: '57102', libelle: 'Caisse 2' })).status, 201);
  assert.strictEqual((await appel(3, 'PUT', '/parametres', { regime: 'smt' })).status, 403);
  assert.strictEqual((await appel(1, 'PUT', '/parametres', { regime: 'smt' })).status, 200);
  assert.strictEqual((await appel(99, 'GET', '/comptes')).status, 403, 'utilisateur inconnu');
});

test('parcours complet : ouverture, saisie, validation, contre-passation, états', async () => {
  const ouv = await appel(1, 'POST', '/ouverture', {
    dateOuverture: '2027-01-01',
    regime: 'normal',
    soldes: [{ compteNumero: '571', debit: 100000 }, { compteNumero: '101', credit: 100000 }],
  });
  assert.strictEqual(ouv.status, 201);
  assert.strictEqual(ouv.body.data.ecart, 0);
  assert.strictEqual((await appel(1, 'POST', '/ouverture', { dateOuverture: '2027-01-01', soldes: [] })).status, 409);

  const lignes = [{ compteNumero: '601', debit: 25000 }, { compteNumero: '571', credit: 25000 }];
  const faux = await appel(3, 'POST', '/ecritures', { journalCode: 'CA', dateEcriture: '2027-02-01', libelle: 'Achat', lignes: [{ compteNumero: '601', debit: 25000 }, { compteNumero: '571', credit: 24000 }] });
  assert.strictEqual(faux.status, 400);
  assert.strictEqual(faux.body.code, 'DESEQUILIBRE');

  // Les champs réservés au moteur (origine, source, contre-passation) sont ignorés
  const cree = await appel(3, 'POST', '/ecritures', { journalCode: 'CA', dateEcriture: '2027-02-01', libelle: 'Achat de fournitures', lignes, origine: 'auto', source: { type: 'vente', id: 1, role: 'x' }, contrepasseId: 1 });
  assert.strictEqual(cree.status, 201);
  assert.strictEqual(cree.body.data.origine, 'manuelle');
  assert.strictEqual(cree.body.data.sourceType, null);
  assert.strictEqual(cree.body.data.contrepasseId, null);
  const id = cree.body.data.id;

  assert.strictEqual((await appel(3, 'POST', `/ecritures/${id}/valider`)).status, 403, 'saisir ne donne pas le droit de valider');
  const val = await appel(1, 'POST', `/ecritures/${id}/valider`);
  assert.strictEqual(val.status, 200);
  assert.strictEqual(val.body.data.numeroPiece, 'CA-2027-000001');
  assert.strictEqual((await appel(1, 'DELETE', `/ecritures/${id}`)).status, 409);

  const bal = await appel(2, 'GET', '/balance');
  assert.strictEqual(bal.body.data.equilibree, true);
  assert.strictEqual(bal.body.data.total.debit, 125000);

  const gl = await appel(2, 'GET', '/grand-livre?compte=571');
  assert.strictEqual(gl.body.data.soldeFin, 75000);
  assert.strictEqual((await appel(2, 'GET', '/grand-livre?compte=000')).status, 404);

  const contre = await appel(1, 'POST', `/ecritures/${id}/contrepasser`, { dateEcriture: '2027-02-02', motif: 'doublon' });
  assert.strictEqual(contre.status, 201);
  assert.strictEqual((await appel(1, 'POST', `/ecritures/${id}/contrepasser`, {})).status, 409);
  const gl2 = await appel(2, 'GET', '/grand-livre?compte=571');
  assert.strictEqual(gl2.body.data.soldeFin, 100000);

  const liste = await appel(2, 'GET', '/ecritures?journalCode=CA&statut=validee');
  assert.strictEqual(liste.body.data.total, 1);
  assert.strictEqual((await appel(1, 'PUT', '/exercices/' + ouv.body.data.exercice.id + '/periodes/2', { statut: 'verrouillee' })).status, 200);
  const bloque = await appel(3, 'POST', '/ecritures', { journalCode: 'CA', dateEcriture: '2027-02-10', libelle: 'Trop tard', lignes });
  assert.strictEqual(bloque.status, 409);
  assert.strictEqual(bloque.body.code, 'PERIODE_VERROUILLEE');
});
