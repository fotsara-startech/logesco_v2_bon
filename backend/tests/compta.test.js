/**
 * Comptabilité (phase 1) : référentiel, écritures en partie double, validation,
 * contre-passation, périodes, ouverture, grand livre et balance.
 * La base de test est construite avec le VRAI migration.sql livré aux postes.
 * Exécution : node --test tests/compta.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { PrismaClient } = require('@prisma/client');
const installation = require('../src/utils/installation');
const referentiel = require('../src/compta/referentiel');
const { ComptaService, ComptaError, numeroAuxiliaire } = require('../src/compta/compta-service');

const dossier = fs.mkdtempSync(path.join(os.tmpdir(), 'compta-test-'));
const prisma = new PrismaClient({ datasources: { db: { url: `file:${path.join(dossier, 'test.db').replace(/\\/g, '/')}` } } });
const operations = [];
const service = new ComptaService(prisma, { enqueue: async (table, op, row) => operations.push({ table, op, row }) });

async function rejette(promesse, code) {
  await assert.rejects(promesse, (e) => {
    assert.ok(e instanceof ComptaError, `ComptaError attendue, reçu : ${e && e.message}`);
    if (code) assert.strictEqual(e.code, code, e.message);
    return true;
  });
}

const od = (extra = {}) => ({
  journalCode: 'OD',
  dateEcriture: '2027-03-10',
  libelle: 'Test',
  lignes: [{ compteNumero: '571', debit: 1000 }, { compteNumero: '701', credit: 1000 }],
  ...extra,
});

test.before(async () => {
  for (const migration of ['add_compta_socle', 'add_compta_immobilisations']) {
    const sql = fs.readFileSync(path.join(__dirname, `../prisma/migrations/${migration}/migration.sql`), 'utf8');
    const instructions = sql.split('\n').filter((l) => !l.trim().startsWith('--')).join('\n').split(';').map((s) => s.trim()).filter(Boolean);
    for (const i of instructions) await prisma.$executeRawUnsafe(i);
  }
  await referentiel.ensureReferentiel(prisma);
  installation.setInstallationId(null);
});

test.after(async () => {
  await prisma.$disconnect();
  fs.rmSync(dossier, { recursive: true, force: true });
});

test('référentiel : numéros et identifiants uniques, chargement idempotent', async () => {
  const comptes = referentiel.comptesSysteme();
  assert.strictEqual(new Set(comptes.map((c) => c.numero)).size, comptes.length);
  assert.strictEqual(new Set(comptes.map((c) => c.id)).size, comptes.length);
  const avant = await prisma.comptaCompte.count();
  assert.strictEqual(avant, comptes.length);
  const r = await referentiel.ensureReferentiel(prisma);
  assert.strictEqual(r.comptes, 0);
  assert.strictEqual(await prisma.comptaCompte.count(), avant);
  assert.strictEqual(await prisma.comptaJournal.count(), 6);
  const c411 = await prisma.comptaCompte.findUnique({ where: { numero: '4311' } });
  assert.strictEqual(c411, null);
  const tva = await prisma.comptaCompte.findUnique({ where: { numero: '4431' } });
  assert.strictEqual(tva.parentNumero, '443');
});

test('référentiel : les identifiants des comptes système sont stables (position dans le plan)', () => {
  const comptes = referentiel.comptesSysteme();
  assert.strictEqual(comptes[0].id, referentiel.ID_BASE + 1);
  assert.strictEqual(comptes[0].numero, '10');
});

test('écriture sans exercice : refusée', async () => {
  await rejette(service.creerEcriture(od()), 'AUCUN_EXERCICE');
});

test('exercice : 12 périodes, pas de chevauchement, 24 mois maximum', async () => {
  const ex = await service.creerExercice({ libelle: 'Exercice 2027', dateDebut: '2027-01-01', dateFin: '2027-12-31' });
  assert.strictEqual(ex.periodes.length, 12);
  await rejette(service.creerExercice({ dateDebut: '2027-06-01', dateFin: '2028-05-31' }), 'EXERCICE_CHEVAUCHE');
  await rejette(service.creerExercice({ dateDebut: '2030-01-01', dateFin: '2032-12-31' }));
  await rejette(service.creerExercice({ dateDebut: '2031-05-01', dateFin: '2031-04-01' }));
});

test('partie double : déséquilibre, montants invalides et comptes inconnus refusés', async () => {
  await rejette(service.creerEcriture(od({ lignes: [{ compteNumero: '571', debit: 1000 }, { compteNumero: '701', credit: 900 }] })), 'DESEQUILIBRE');
  await rejette(service.creerEcriture(od({ lignes: [{ compteNumero: '571', debit: 10.5 }, { compteNumero: '701', credit: 10.5 }] })));
  await rejette(service.creerEcriture(od({ lignes: [{ compteNumero: '571', debit: 5, credit: 5 }, { compteNumero: '701', credit: 0 }] })));
  await rejette(service.creerEcriture(od({ lignes: [{ compteNumero: '571', debit: -5 }, { compteNumero: '701', credit: -5 }] })));
  await rejette(service.creerEcriture(od({ lignes: [{ compteNumero: '999999', debit: 5 }, { compteNumero: '701', credit: 5 }] })));
  await rejette(service.creerEcriture(od({ lignes: [{ compteNumero: '571', debit: 5 }] })));
  await rejette(service.creerEcriture(od({ lignes: [{ compteNumero: '571', debit: 0 }, { compteNumero: '701', credit: 0 }] })));
  await rejette(service.creerEcriture(od({ journalCode: 'AN' })), undefined);
  await rejette(service.creerEcriture(od({ libelle: '  ' })));
});

test('brouillon : numérotation à la validation, séquentielle par journal', async () => {
  const a = await service.creerEcriture(od());
  assert.strictEqual(a.statut, 'brouillon');
  assert.strictEqual(a.numeroPiece, null);
  const va = await service.validerEcriture(a.id);
  assert.strictEqual(va.numeroPiece, 'OD-2027-000001');
  const b = await service.creerEcriture(od({ valider: true }));
  assert.strictEqual(b.numeroPiece, 'OD-2027-000002');
  const v = await service.creerEcriture(od({ journalCode: 'VT', valider: true }));
  assert.strictEqual(v.numeroPiece, 'VT-2027-000001');
  await rejette(service.validerEcriture(a.id), 'DEJA_VALIDEE');
});

test('numéro de pièce : suffixe de poste, séquence propre à chaque poste', async () => {
  installation.setInstallationId(3);
  try {
    const e = await service.creerEcriture(od({ valider: true }));
    assert.strictEqual(e.numeroPiece, 'OD-2027-000001-P3');
    const f = await service.creerEcriture(od({ valider: true }));
    assert.strictEqual(f.numeroPiece, 'OD-2027-000002-P3');
  } finally {
    installation.setInstallationId(null);
  }
  const g = await service.creerEcriture(od({ valider: true }));
  assert.strictEqual(g.numeroPiece, 'OD-2027-000003');
});

test('brouillon modifiable et supprimable ; pièce validée figée', async () => {
  const e = await service.creerEcriture(od({ libelle: 'À corriger' }));
  const m = await service.modifierBrouillon(e.id, { libelle: 'Corrigé', lignes: [{ compteNumero: '571', debit: 2500 }, { compteNumero: '701', credit: 2500 }] });
  assert.strictEqual(m.libelle, 'Corrigé');
  assert.strictEqual(m.lignes.reduce((s, l) => s + l.debit, 0), 2500);
  await rejette(service.modifierBrouillon(e.id, { lignes: [{ compteNumero: '571', debit: 1 }, { compteNumero: '701', credit: 2 }] }), 'DESEQUILIBRE');
  await service.supprimerBrouillon(e.id);
  assert.strictEqual(await prisma.comptaEcriture.count({ where: { id: e.id } }), 0);
  assert.strictEqual(await prisma.comptaLigne.count({ where: { ecritureId: e.id } }), 0);

  const v = await service.creerEcriture(od({ valider: true }));
  await rejette(service.modifierBrouillon(v.id, { libelle: 'x' }), 'ECRITURE_VALIDEE');
  await rejette(service.supprimerBrouillon(v.id), 'ECRITURE_VALIDEE');
});

test('idempotence : une même source ne produit qu\'une pièce', async () => {
  const source = { type: 'vente', id: 4242, role: 'ca' };
  const a = await service.creerEcriture(od({ origine: 'auto', source, valider: true }));
  const b = await service.creerEcriture(od({ origine: 'auto', source, valider: true }));
  assert.strictEqual(a.id, b.id);
  assert.strictEqual(await prisma.comptaEcriture.count({ where: { sourceType: 'vente', sourceId: 4242 } }), 1);
  await rejette(service.modifierBrouillon(a.id, { libelle: 'x' }));
});

test('contre-passation : écriture inverse, solde nul, une seule fois', async () => {
  const dep = await service.creerEcriture(od({ dateEcriture: '2027-05-05', libelle: 'Vente erronée', lignes: [{ compteNumero: '411', debit: 7000, tiersType: 'client', tiersId: 12 }, { compteNumero: '701', credit: 7000 }], valider: true }));
  const avant = await service.balance({});
  const res = await service.contrepasser(dep.id, { dateEcriture: '2027-05-06', motif: 'erreur de saisie' });
  assert.strictEqual(res.originale.statut, 'contrepassee');
  assert.strictEqual(res.contre.statut, 'validee');
  assert.strictEqual(res.contre.contrepasseId, dep.id);
  assert.match(res.contre.libelle, /Contre-passation de OD-2027-/);
  assert.deepStrictEqual(res.contre.lignes.map((l) => [l.debit, l.credit]).sort(), [[0, 7000], [7000, 0]]);
  const apres = await service.balance({});
  const l411 = (b) => b.lignes.find((l) => l.numero === '411');
  assert.strictEqual(l411(apres).soldeDebiteur, 0);
  assert.strictEqual(apres.total.debit - avant.total.debit, 7000);
  assert.ok(apres.equilibree);
  await rejette(service.contrepasser(dep.id), 'DEJA_CONTREPASSEE');
  await rejette(service.contrepasser(res.contre.id));
});

test('période verrouillée et exercice clôturé : plus d\'écriture', async () => {
  await service.changerStatutPeriode((await service.listerExercices())[0].id, 8, 'verrouillee');
  await rejette(service.creerEcriture(od({ dateEcriture: '2027-08-15' })), 'PERIODE_VERROUILLEE');
  const brouillon = await service.creerEcriture(od({ dateEcriture: '2027-09-15' }));
  const ex = (await service.listerExercices())[0];
  await service.changerStatutPeriode(ex.id, 9, 'verrouillee');
  await rejette(service.validerEcriture(brouillon.id), 'PERIODE_VERROUILLEE');
  await service.changerStatutPeriode(ex.id, 9, 'ouverte');
  await service.validerEcriture(brouillon.id);

  await prisma.comptaExercice.update({ where: { id: ex.id }, data: { statut: 'cloture' } });
  await rejette(service.creerEcriture(od()), 'EXERCICE_CLOTURE');
  await rejette(service.changerStatutPeriode(ex.id, 8, 'ouverte'), 'EXERCICE_CLOTURE');
  await prisma.comptaExercice.update({ where: { id: ex.id }, data: { statut: 'ouvert' } });
});

test('grand livre : solde progressif, solde reporté, comptes auxiliaires, filtre boutique', async () => {
  const gl = await service.grandLivre({ compteNumero: '411' });
  assert.ok(gl.mouvements.length >= 2);
  let attendu = gl.soldeDebut;
  for (const m of gl.mouvements) {
    attendu += m.debit - m.credit;
    assert.strictEqual(m.solde, attendu);
  }
  assert.strictEqual(gl.soldeFin, attendu);
  assert.strictEqual(gl.mouvements[0].compteAuxiliaire, '411000012');

  const reporte = await service.grandLivre({ compteNumero: '411', dateDebut: '2027-05-06' });
  assert.strictEqual(reporte.soldeDebut, 7000);
  assert.strictEqual(reporte.mouvements.length, 1);

  const tiers = await service.grandLivre({ compteNumero: '411', tiersType: 'client', tiersId: 99 });
  assert.strictEqual(tiers.mouvements.length, 0);

  await service.creerEcriture(od({ boutiqueId: 5, libelle: 'Boutique 5', lignes: [{ compteNumero: '571', debit: 300 }, { compteNumero: '701', credit: 300 }], valider: true }));
  const b5 = await service.balance({ boutiqueId: 5 });
  assert.strictEqual(b5.total.debit, 300);
  assert.ok(b5.equilibree);
});

test('balance : toujours équilibrée, brouillons exclus', async () => {
  await service.creerEcriture(od({ lignes: [{ compteNumero: '571', debit: 999999 }, { compteNumero: '701', credit: 999999 }] }));
  const b = await service.balance({});
  assert.ok(b.equilibree);
  assert.ok(b.total.debit < 999999 + 1 && !b.lignes.some((l) => l.debit === 999999));
  assert.deepStrictEqual(b.lignes.map((l) => l.numero), [...b.lignes.map((l) => l.numero)].sort((x, y) => x.localeCompare(y, 'fr', { numeric: true })));
});

test('ouverture : écart sur compte d\'attente, une seule fois, exercice créé', async () => {
  const exercices = await service.listerExercices();
  for (const e of exercices) await prisma.comptaExercice.update({ where: { id: e.id }, data: { dateDebut: new Date('2020-01-01'), dateFin: new Date('2020-12-31') } });

  const r = await service.enregistrerOuverture({
    dateOuverture: '2028-01-01',
    regime: 'smt',
    soldes: [
      { compteNumero: '571', debit: 50000 },
      { compteNumero: '31', debit: 200000 },
      { compteNumero: '101', credit: 200000 },
      { compteNumero: '411', debit: 30000, tiersType: 'client', tiersId: 3 },
    ],
  });
  assert.strictEqual(r.ecart, 80000);
  assert.strictEqual(r.ecriture.numeroPiece, 'AN-2028-000001');
  assert.strictEqual(r.ecriture.lignes.length, 5);
  assert.ok(r.ecriture.lignes.some((l) => l.credit === 80000));
  assert.strictEqual(r.parametres.regime, 'smt');
  assert.strictEqual(r.parametres.ouvertureValidee, true);
  assert.strictEqual(r.exercice.periodes.length, 12);
  await rejette(service.enregistrerOuverture({ dateOuverture: '2028-01-01', soldes: [] }), 'OUVERTURE_DEJA_FAITE');
});

test('plan comptable : création de compte, doublon et numéro invalide refusés', async () => {
  const c = await service.creerCompte({ numero: '57101', libelle: 'Caisse boutique 1' });
  assert.strictEqual(c.parentNumero, '571');
  assert.strictEqual(c.nature, 'tresorerie');
  assert.strictEqual(c.systeme, false);
  await rejette(service.creerCompte({ numero: '57101', libelle: 'Doublon' }), 'COMPTE_EXISTANT');
  await rejette(service.creerCompte({ numero: '9', libelle: 'Trop court' }));
  await rejette(service.creerCompte({ numero: 'AB1', libelle: 'Lettres' }));
  await service.modifierCompte(c.id, { actif: false });
  await rejette(service.creerEcriture(od({ dateEcriture: '2028-02-02', lignes: [{ compteNumero: '57101', debit: 5 }, { compteNumero: '701', credit: 5 }] })));
});

test('synchronisation : écriture envoyée avant ses lignes, suppression d\'un brouillon propagée', async () => {
  operations.length = 0;
  const e = await service.creerEcriture(od({ dateEcriture: '2028-02-03' }));
  const tables = operations.map((o) => o.table);
  assert.strictEqual(tables[0], 'compta_ecritures');
  assert.ok(tables.slice(1).every((t) => t === 'compta_lignes'));
  assert.strictEqual(operations.filter((o) => o.table === 'compta_lignes').length, 2);
  operations.length = 0;
  await service.supprimerBrouillon(e.id);
  assert.deepStrictEqual(operations.map((o) => `${o.table}:${o.op}`), ['compta_lignes:DELETE', 'compta_lignes:DELETE', 'compta_ecritures:DELETE']);
});

test('numeroAuxiliaire : code du tiers complété à gauche', () => {
  assert.strictEqual(numeroAuxiliaire('411', 42, 6), '411000042');
  assert.strictEqual(numeroAuxiliaire('401', null), '401');
});

test('migration des immobilisations : table utilisable avec le client Prisma', async () => {
  const i = await prisma.comptaImmobilisation.create({ data: { libelle: 'Test', compteNumero: '2183', compteAmortNumero: '28183', dateAcquisition: new Date('2027-01-01'), valeur: 1000, dureeMois: 12 } });
  assert.strictEqual(i.compteDotationNumero, '681');
  assert.strictEqual(i.statut, 'en_service');
});
