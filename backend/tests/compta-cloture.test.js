/**
 * Phase 4 : immobilisations et amortissements, variation de stocks, clôture annuelle avec à-nouveaux,
 * tableau des flux de trésorerie (TFT) et rapprochement bancaire.
 * Exécution : node --test tests/compta-cloture.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execSync } = require('node:child_process');
const express = require('express');
const { PrismaClient } = require('@prisma/client');
const installation = require('../src/utils/installation');
const referentiel = require('../src/compta/referentiel');
const { ComptaService, ComptaError } = require('../src/compta/compta-service');
const { MoteurAuto } = require('../src/compta/moteur-auto');
const { EtatsService } = require('../src/compta/etats');
const { ImmobilisationService, amortissementCumule, moisInclus } = require('../src/compta/immobilisations');
const { ClotureService } = require('../src/compta/cloture');
const { createComptaRouter } = require('../src/routes/compta');

const dossier = fs.mkdtempSync(path.join(os.tmpdir(), 'compta-cloture-'));
const url = `file:${path.join(dossier, 'test.db').replace(/\\/g, '/')}`;
const prisma = new PrismaClient({ datasources: { db: { url } } });
const service = new ComptaService(prisma, null);
const moteur = new MoteurAuto(prisma, service);
const etats = new EtatsService(prisma, service);
const immos = new ImmobilisationService(prisma, service, moteur);
const cloture = new ClotureService(prisma, service, moteur, immos);

let fournisseur; let ex2027; let ordinateur; let serveur; let base;

const ecrire = (journalCode, dateEcriture, libelle, lignes) => service.creerEcriture({ journalCode, dateEcriture, libelle, lignes, valider: true });
const net = async (numero, filtre = {}) => {
  const compte = await prisma.comptaCompte.findUnique({ where: { numero } });
  const lignes = await prisma.comptaLigne.findMany({ where: { compteId: compte.id, ecriture: { statut: { in: ['validee', 'contrepassee'] }, ...filtre } } });
  return lignes.reduce((s, l) => s + l.debit - l.credit, 0);
};

test.before(async () => {
  execSync('npx prisma db push --schema=prisma/schema.prisma --skip-generate --accept-data-loss', {
    cwd: path.join(__dirname, '..'), env: { ...process.env, DATABASE_URL: url }, stdio: 'pipe',
  });
  await referentiel.ensureReferentiel(prisma);
  installation.setInstallationId(null);
  fournisseur = await prisma.fournisseur.create({ data: { nom: 'Grossiste SA' } });

  const o = await service.enregistrerOuverture({
    dateOuverture: '2027-01-01',
    soldes: [{ compteNumero: '571', debit: 1000000 }, { compteNumero: '521', debit: 500000 }, { compteNumero: '31', debit: 200000 }, { compteNumero: '101', credit: 1700000 }],
  });
  ex2027 = o.exercice;

  const app = express();
  app.use(express.json());
  app.use('/compta', createComptaRouter({ authService: {}, prisma, comptaService: service, moteurAuto: moteur, etatsService: etats, immobilisationService: immos, clotureService: cloture }));
  await new Promise((ok) => { serveur = app.listen(0, '127.0.0.1', ok); });
  base = `http://127.0.0.1:${serveur.address().port}/compta`;
});

test.after(async () => {
  await new Promise((ok) => serveur.close(ok));
  await prisma.$disconnect();
  fs.rmSync(dossier, { recursive: true, force: true });
});

test('calcul de l\'amortissement linéaire au mois près', () => {
  const i = { dateAcquisition: new Date('2027-04-15T00:00:00Z'), valeur: 600000, valeurResiduelle: 0, dureeMois: 36 };
  assert.strictEqual(moisInclus(i.dateAcquisition, new Date('2027-04-30T00:00:00Z')), 1);
  assert.strictEqual(amortissementCumule(i, new Date('2027-03-31T00:00:00Z')), 0, 'avant l\'acquisition');
  assert.strictEqual(amortissementCumule(i, new Date('2027-12-31T00:00:00Z')), 150000, 'avril à décembre : 9 mois sur 36');
  assert.strictEqual(amortissementCumule(i, new Date('2040-01-01T00:00:00Z')), 600000, 'jamais plus que la base amortissable');
  const arrondi = { dateAcquisition: new Date('2027-01-01T00:00:00Z'), valeur: 100000, valeurResiduelle: 1, dureeMois: 7 };
  const cumuls = [1, 2, 3, 4, 5, 6, 7].map((m) => amortissementCumule(arrondi, new Date(Date.UTC(2027, m - 1, 28))));
  assert.strictEqual(cumuls[6], 99999, 'le dernier mois solde exactement la base');
});

test('immobilisation : validations et compte d\'amortissement créé', async () => {
  await assert.rejects(immos.creer({ libelle: 'x', compteNumero: '601', dateAcquisition: '2027-04-15', valeur: 1000, dureeMois: 12 }), ComptaError);
  await assert.rejects(immos.creer({ libelle: 'x', compteNumero: '2183', dateAcquisition: '2027-04-15', valeur: 1000, dureeMois: 0 }), ComptaError);
  await assert.rejects(immos.creer({ libelle: 'x', compteNumero: '2183', dateAcquisition: '2027-04-15', valeur: 1000, valeurResiduelle: 1000, dureeMois: 12 }), ComptaError);
  ordinateur = await immos.creer({ libelle: 'Ordinateur', compteNumero: '2183', dateAcquisition: '2027-04-15', valeur: 600000, dureeMois: 36 });
  assert.strictEqual(ordinateur.compteAmortNumero, '28183');
  const amort = await prisma.comptaCompte.findUnique({ where: { numero: '28183' } });
  assert.ok(amort && amort.systeme === false);
  const plan = await immos.plan(ordinateur.id);
  assert.strictEqual(plan.lignes[0].annee, 2027);
  assert.strictEqual(plan.lignes[0].dotation, 150000);
  assert.strictEqual(plan.lignes[1].dotation, 200000);
  assert.strictEqual(plan.lignes.reduce((s, l) => s + l.dotation, 0), 600000);
});

test('exercice 2027 : activité courante', async () => {
  await ecrire('OD', '2027-04-15', 'Achat ordinateur', [{ compteNumero: '2183', debit: 600000 }, { compteNumero: '521', credit: 600000 }]);
  await ecrire('VT', '2027-03-10', 'Vente comptant', [{ compteNumero: '571', debit: 119250 }, { compteNumero: '701', credit: 100000 }, { compteNumero: '4431', credit: 19250 }]);
  await ecrire('AC', '2027-03-12', 'Achat marchandises', [
    { compteNumero: '601', debit: 40000 }, { compteNumero: '4452', debit: 7700 }, { compteNumero: '401', credit: 47700, tiersType: 'fournisseur', tiersId: fournisseur.id },
  ]);
  await ecrire('CA', '2027-03-15', 'Loyer', [{ compteNumero: '622', debit: 10000 }, { compteNumero: '571', credit: 10000 }]);
});

test('dotations de l\'exercice : une écriture, idempotente, régularisée si la valeur change', async () => {
  const r = await immos.dotationsExercice({ exerciceId: ex2027.id });
  assert.strictEqual(r.erreurs.length, 0, JSON.stringify(r.erreurs));
  assert.strictEqual(r.dotations[0].dotation, 150000);
  assert.strictEqual(await net('681'), 150000);
  assert.strictEqual(await net('28183'), -150000);
  assert.strictEqual((await immos.dotationsExercice({ exerciceId: ex2027.id })).ecritures, 0, 'relancer ne change rien');
});

test('stock : valorisation CUMP, variation idempotente et régularisée', async () => {
  const p = await prisma.produit.create({ data: { reference: 'S1', nom: 'Sac de riz', prixUnitaire: 30000, cump: 25000, prixAchat: 20000 } });
  const q = await prisma.produit.create({ data: { reference: 'S2', nom: 'Sans CUMP', prixUnitaire: 2000, prixAchat: 1000 } });
  const s = await prisma.produit.create({ data: { reference: 'S3', nom: 'Service', prixUnitaire: 5000, estService: true } });
  for (const [prod, quantite] of [[p, 4], [q, 10], [s, 99]]) await prisma.stock.create({ data: { produitId: prod.id, quantiteDisponible: quantite } });
  assert.strictEqual(await cloture.valeurStock(), 4 * 25000 + 10 * 1000, 'CUMP, à défaut prix d\'achat, services exclus');

  const a = await cloture.variationStocks({ exerciceId: ex2027.id, valeur: 180000 });
  assert.strictEqual(a.variation, -20000);
  assert.strictEqual(await net('6031'), 20000);
  assert.strictEqual(await net('31'), 180000);
  assert.strictEqual((await cloture.variationStocks({ exerciceId: ex2027.id, valeur: 180000 })).ecriture, false);
  await cloture.variationStocks({ exerciceId: ex2027.id, valeur: 190000 });
  assert.strictEqual(await net('31'), 190000, 'régularisation');
  await cloture.variationStocks({ exerciceId: ex2027.id, valeur: 180000 });
  assert.strictEqual(await net('31'), 180000);
  await assert.rejects(cloture.variationStocks({ exerciceId: ex2027.id, valeur: -5 }), ComptaError);
});

test('clôture refusée tant qu\'il reste un brouillon', async () => {
  const b = await service.creerEcriture({ journalCode: 'OD', dateEcriture: '2027-06-01', libelle: 'Brouillon', lignes: [{ compteNumero: '571', debit: 5 }, { compteNumero: '701', credit: 5 }] });
  await assert.rejects(cloture.cloturerExercice({ exerciceId: ex2027.id, valeurStock: 180000 }), (e) => e.code === 'BROUILLONS_EXISTANTS');
  await service.supprimerBrouillon(b.id);
});

test('TFT 2027 : les trois flux expliquent exactement la variation de trésorerie', async () => {
  const t = await etats.fluxTresorerie({ exerciceId: ex2027.id });
  assert.strictEqual(t.tresorerieOuverture, 1500000);
  assert.strictEqual(t.cafg, 30000, 'résultat −120 000 + dotations 150 000');
  assert.strictEqual(t.variationStocks, 20000);
  assert.strictEqual(t.variationCreancesDettes, 59250);
  assert.strictEqual(t.fluxOperationnels, 109250);
  assert.strictEqual(t.fluxInvestissement, -600000);
  assert.strictEqual(t.fluxFinancement, 0);
  assert.strictEqual(t.variationTresorerie, -490750);
  assert.strictEqual(t.tresorerieCloture, 1009250);
  assert.strictEqual(t.controle, true);
});

test('clôture 2027 : résultat, exercice suivant, à-nouveaux équilibrés, verrouillage', async () => {
  const r = await cloture.cloturerExercice({ exerciceId: ex2027.id, valeurStock: 180000 });
  assert.strictEqual(r.resultat, -120000, 'produits 100 000 − charges 220 000');
  assert.match(r.ecritureCloture, /^OD-2027-/);
  assert.strictEqual(r.exerciceSuivant.libelle, 'Exercice 2028');
  assert.match(r.ecritureANouveaux, /^AN-2028-/);

  const ex = await prisma.comptaExercice.findUnique({ where: { id: ex2027.id }, include: { periodes: true } });
  assert.strictEqual(ex.statut, 'cloture');
  assert.ok(ex.periodes.every((p) => p.statut === 'verrouillee'));
  assert.strictEqual(await net('139', { exerciceId: ex2027.id }), 120000, 'perte au débit de 139');
  for (const c of ['701', '601', '622', '6031', '681']) assert.strictEqual(await net(c, { exerciceId: ex2027.id }), 0, `${c} soldé`);

  const an = await prisma.comptaEcriture.findFirst({ where: { journal: { code: 'AN' }, exercice: { libelle: 'Exercice 2028' } }, include: { lignes: { include: { compte: true } } } });
  const solde = (num) => an.lignes.filter((l) => l.compte.numero === num).reduce((s, l) => s + l.debit - l.credit, 0);
  assert.strictEqual(solde('571'), 1109250);
  assert.strictEqual(solde('521'), -100000);
  assert.strictEqual(solde('31'), 180000);
  assert.strictEqual(solde('2183'), 600000);
  assert.strictEqual(solde('28183'), -150000);
  assert.strictEqual(solde('139'), 120000);
  assert.strictEqual(an.lignes.find((l) => l.compte.numero === '401').tiersId, fournisseur.id, 'dettes reportées tiers par tiers');
  assert.strictEqual(an.lignes.reduce((s, l) => s + l.debit, 0), an.lignes.reduce((s, l) => s + l.credit, 0));
  assert.strictEqual(an.lignes.every((l) => !['6', '7', '8'].includes(String(l.compte.classe))), true, 'aucun compte de gestion reporté');

  await assert.rejects(cloture.cloturerExercice({ exerciceId: ex2027.id }), (e) => e.code === 'EXERCICE_CLOTURE');
  await assert.rejects(ecrire('OD', '2027-12-01', 'Trop tard', [{ compteNumero: '571', debit: 5 }, { compteNumero: '701', credit: 5 }]), (e) => e.code === 'EXERCICE_CLOTURE');
});

test('après clôture : compte de résultat intact, bilan équilibré avec le résultat clos', async () => {
  const cr = await etats.compteDeResultat({ exerciceId: ex2027.id });
  assert.strictEqual(cr.resultatNet, -120000, 'l\'écriture de clôture ne vide pas le compte de résultat');
  const b = await etats.bilan({ exerciceId: ex2027.id });
  assert.strictEqual(b.equilibre, true);
  assert.strictEqual(b.resultatEnCours, 0);
  assert.strictEqual(b.passif.lignes.find((l) => l.id === 'resultat_clos').montant, -120000);
  const tft = await etats.fluxTresorerie({ exerciceId: ex2027.id });
  assert.strictEqual(tft.controle, true);
  assert.strictEqual(tft.variationTresorerie, -490750, 'à-nouveaux et clôture exclus du TFT');
});

test('exercice 2028 : ouverture par à-nouveaux, cession et TFT cohérent', async () => {
  const ex2028 = await prisma.comptaExercice.findFirst({ where: { libelle: 'Exercice 2028' } });
  const bilan0 = await etats.bilan({ exerciceId: ex2028.id, dateFin: '2028-01-02' });
  assert.strictEqual(bilan0.equilibre, true);

  const c = await immos.ceder(ordinateur.id, { date: '2028-06-10', prix: 300000 });
  assert.strictEqual(c.amortissementCumule, 250000, 'avril 2027 à juin 2028 : 15 mois sur 36');
  assert.strictEqual(c.valeurNetteComptable, 350000);
  assert.strictEqual(c.plusOuMoinsValue, -50000);
  assert.strictEqual(await net('2183', { exerciceId: ex2028.id }), 0);
  assert.strictEqual(await net('28183', { exerciceId: ex2028.id }), 0, 'amortissements cumulés repris à la cession');
  assert.strictEqual(await net('81', { exerciceId: ex2028.id }), 350000);
  assert.strictEqual(await net('82', { exerciceId: ex2028.id }), -300000);
  await assert.rejects(immos.ceder(ordinateur.id, { date: '2028-07-01' }), (e) => e.code === 'DEJA_CEDEE');

  const bal = await service.balance({});
  assert.strictEqual(bal.equilibree, true);
  const tft = await etats.fluxTresorerie({ exerciceId: ex2028.id });
  assert.strictEqual(tft.tresorerieOuverture, 1009250);
  assert.strictEqual(tft.variationTresorerie, 300000, 'seul le prix de cession encaissé');
  assert.strictEqual(tft.controle, true);
  const liste = await immos.lister();
  assert.strictEqual(liste[0].statut, 'cedee');
});

test('rapprochement bancaire : pointage, écart et annulation', async () => {
  const lignes = (await prisma.comptaLigne.findMany({ where: { compte: { numero: '521' }, ecriture: { dateEcriture: { lte: new Date('2027-12-31T00:00:00Z') } } }, include: { ecriture: true } }));
  const ouverture = lignes.find((l) => l.ecriture.origine === 'ouverture' && l.debit === 500000);
  const achat = lignes.find((l) => l.credit === 600000);
  const avant = await cloture.etatRapprochement({ compteNumero: '521', dateReleve: '2027-12-31', soldeReleve: 500000 });
  assert.strictEqual(avant.soldeComptable, -100000);
  assert.strictEqual(avant.soldePointe, 0);
  assert.strictEqual(avant.ecart, 500000);
  assert.strictEqual(avant.rapproche, false);

  const p = await cloture.pointer({ ligneIds: [ouverture.id], dateReleve: '2027-12-31' });
  assert.strictEqual(p.code, 'RB20271231');
  const apres = await cloture.etatRapprochement({ compteNumero: '521', dateReleve: '2027-12-31', soldeReleve: 500000 });
  assert.strictEqual(apres.soldePointe, 500000);
  assert.strictEqual(apres.rapproche, true);
  assert.deepStrictEqual(apres.enAttente.map((l) => l.id), [achat.id], 'le chèque non encore débité reste en attente');
  await assert.rejects(cloture.pointer({ ligneIds: [ouverture.id], dateReleve: '2027-12-31' }), (e) => e.code === 'DEJA_POINTEE');
  const tiers = await prisma.comptaLigne.findFirst({ where: { tiersId: { not: null } } });
  await assert.rejects(cloture.pointer({ ligneIds: [tiers.id], dateReleve: '2027-12-31' }), ComptaError);
  await cloture.depointer({ ligneIds: [ouverture.id] });
  assert.strictEqual((await cloture.etatRapprochement({ compteNumero: '521', dateReleve: '2027-12-31' })).soldePointe, 0);
  await assert.rejects(cloture.etatRapprochement({ compteNumero: '701' }), ComptaError);
});

test('routes : TFT, immobilisations, stock et clôture', async () => {
  const h = { Authorization: 'Bearer test-token', 'Content-Type': 'application/json' };
  const tft = await (await fetch(`${base}/etats/tft?exerciceId=${ex2027.id}&format=tableau`, { headers: h })).json();
  assert.strictEqual(tft.data.titre, 'Tableau des flux de trésorerie');
  assert.ok(tft.data.lignes.some((l) => l.libelle.startsWith('A. FLUX')));
  const xlsx = await fetch(`${base}/etats/tft?exerciceId=${ex2027.id}&format=xlsx`, { headers: h });
  assert.strictEqual(Buffer.from(await xlsx.arrayBuffer()).slice(0, 2).toString(), 'PK');

  const cree = await fetch(`${base}/immobilisations`, { method: 'POST', headers: h, body: JSON.stringify({ libelle: 'Étagères', compteNumero: '2183', dateAcquisition: '2028-02-01', valeur: 120000, dureeMois: 24 }) });
  assert.strictEqual(cree.status, 201);
  const liste = await (await fetch(`${base}/immobilisations`, { headers: h })).json();
  assert.ok(liste.data.length >= 2);
  const stock = await (await fetch(`${base}/stocks/valeur`, { headers: h })).json();
  assert.strictEqual(typeof stock.data.valeur, 'number');
  const refus = await fetch(`${base}/exercices/${ex2027.id}/cloturer`, { method: 'POST', headers: h, body: '{}' });
  assert.strictEqual(refus.status, 409);
  const rap = await fetch(`${base}/rapprochement?compte=521&dateReleve=2027-12-31&soldeReleve=500000`, { headers: h });
  assert.strictEqual(rap.status, 200);
});
