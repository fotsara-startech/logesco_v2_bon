/**
 * États comptables (phase 3) : compte de résultat, bilan, TVA, balance âgée, lettrage,
 * livre des recettes et dépenses, résumé, exports CSV et Excel.
 * Exécution : node --test tests/compta-etats.test.js
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
const { EtatsService, enCsv } = require('../src/compta/etats');
const { createComptaRouter } = require('../src/routes/compta');

const dossier = fs.mkdtempSync(path.join(os.tmpdir(), 'compta-etats-'));
const url = `file:${path.join(dossier, 'test.db').replace(/\\/g, '/')}`;
const prisma = new PrismaClient({ datasources: { db: { url } } });
const service = new ComptaService(prisma, null);
const etats = new EtatsService(prisma, service);

let clientA; let clientB; let clientC; let fournisseur; let serveur; let base;

const ecrire = (journalCode, dateEcriture, libelle, lignes, extra = {}) =>
  service.creerEcriture({ journalCode, dateEcriture, libelle, lignes, valider: true, ...extra });

test.before(async () => {
  execSync('npx prisma db push --schema=prisma/schema.prisma --skip-generate --accept-data-loss', {
    cwd: path.join(__dirname, '..'), env: { ...process.env, DATABASE_URL: url }, stdio: 'pipe',
  });
  await referentiel.ensureReferentiel(prisma);
  installation.setInstallationId(null);
  clientA = await prisma.client.create({ data: { nom: 'Atangana', prenom: 'Paul' } });
  clientB = await prisma.client.create({ data: { nom: 'Biyiha' } });
  clientC = await prisma.client.create({ data: { nom: 'Chouaibou' } });
  fournisseur = await prisma.fournisseur.create({ data: { nom: 'Grossiste SA' } });

  await service.enregistrerOuverture({
    dateOuverture: '2027-01-01',
    soldes: [{ compteNumero: '571', debit: 100000 }, { compteNumero: '101', credit: 100000 }],
  });
  const A = { tiersType: 'client', tiersId: clientA.id };
  const B = { tiersType: 'client', tiersId: clientB.id };
  await ecrire('VT', '2027-01-10', 'Vente B', [{ compteNumero: '411', debit: 10000, ...B }, { compteNumero: '701', credit: 8000 }, { compteNumero: '4431', credit: 2000 }]);
  await ecrire('VT', '2027-02-01', 'Vente A à crédit', [{ compteNumero: '411', debit: 59625, ...A }, { compteNumero: '701', credit: 50000 }, { compteNumero: '4431', credit: 9625 }]);
  await ecrire('VT', '2027-03-10', 'Vente comptant', [{ compteNumero: '571', debit: 119250 }, { compteNumero: '701', credit: 100000 }, { compteNumero: '4431', credit: 19250 }]);
  await ecrire('AC', '2027-03-12', 'Achat marchandises', [
    { compteNumero: '601', debit: 40000 }, { compteNumero: '4452', debit: 7700 }, { compteNumero: '401', credit: 47700, tiersType: 'fournisseur', tiersId: fournisseur.id },
  ]);
  await ecrire('CA', '2027-03-15', 'Loyer', [{ compteNumero: '622', debit: 10000 }, { compteNumero: '571', credit: 10000 }]);
  await ecrire('CA', '2027-03-20', 'Règlement client A', [{ compteNumero: '571', debit: 20000 }, { compteNumero: '411', credit: 20000, ...A }]);
  // Liquidation de TVA en opérations diverses : ne doit pas fausser la déclaration
  await ecrire('OD', '2027-03-31', 'Liquidation TVA', [{ compteNumero: '4431', debit: 1000 }, { compteNumero: '4441', credit: 1000 }]);

  const app = express();
  app.use(express.json());
  app.use('/compta', createComptaRouter({ authService: {}, prisma, comptaService: service, etatsService: etats }));
  await new Promise((ok) => { serveur = app.listen(0, '127.0.0.1', ok); });
  base = `http://127.0.0.1:${serveur.address().port}/compta`;
});

test.after(async () => {
  await new Promise((ok) => serveur.close(ok));
  await prisma.$disconnect();
  fs.rmSync(dossier, { recursive: true, force: true });
});

const rub = (etat, id) => etat.lignes.find((l) => l.id === id).montant;

test('compte de résultat : marge, résultat d\'exploitation et résultat net', async () => {
  const r = await etats.compteDeResultat({});
  assert.strictEqual(rub(r, 'ventes_marchandises'), 158000);
  assert.strictEqual(rub(r, 'achats_marchandises'), 40000);
  assert.strictEqual(rub(r, 'marge_commerciale'), 118000);
  assert.strictEqual(rub(r, 'services_exterieurs'), 10000);
  assert.strictEqual(rub(r, 'ebe'), 108000);
  assert.strictEqual(rub(r, 'resultat_net'), 108000);
  assert.strictEqual(r.chiffreAffaires, 158000);
  assert.strictEqual(r.resultatNet, 108000);
});

test('compte de résultat : une période plus courte, un compte non classé compte quand même', async () => {
  const mars = await etats.compteDeResultat({ dateDebut: '2027-03-01', dateFin: '2027-03-31' });
  assert.strictEqual(mars.resultatNet, 100000 - 40000 - 10000);
  await ecrire('OD', '2027-04-02', 'Charge exotique', [{ compteNumero: '638', debit: 300 }, { compteNumero: '571', credit: 300 }]);
  const avril = await etats.compteDeResultat({ dateDebut: '2027-04-01', dateFin: '2027-04-30' });
  assert.strictEqual(rub(avril, 'services_exterieurs'), 300); // 63 : services extérieurs B
});

test('bilan : équilibré, résultat en cours inclus, trésorerie et dettes', async () => {
  const b = await etats.bilan({ dateFin: '2027-03-31' });
  const montant = (cote, id) => b[cote].lignes.find((l) => l.id === id).montant;
  assert.strictEqual(montant('actif', 'tresorerie_actif'), 229250);
  assert.strictEqual(montant('actif', 'creances_clients'), 49625);
  assert.strictEqual(montant('actif', 'autres_creances'), 7700 + 0);
  assert.strictEqual(montant('passif', 'capital'), 100000);
  assert.strictEqual(montant('passif', 'fournisseurs'), 47700);
  assert.strictEqual(montant('passif', 'resultat_en_cours'), 108000 - 0);
  assert.strictEqual(b.actif.total, b.passif.total);
  assert.strictEqual(b.equilibre, true);
  assert.deepStrictEqual(b.nonAffectes, []);
});

test('bilan : le solde créditeur d un client passe au passif sans compenser les autres', async () => {
  const avantA = await etats.bilan({ dateFin: '2027-03-31' });
  await ecrire('CA', '2027-03-25', 'Trop perçu client C', [
    { compteNumero: '571', debit: 4000 }, { compteNumero: '411', credit: 4000, tiersType: 'client', tiersId: clientC.id },
  ]);
  const b = await etats.bilan({ dateFin: '2027-03-31' });
  assert.strictEqual(b.equilibre, true);
  assert.strictEqual(b.actif.total - avantA.actif.total, 4000, 'la trésorerie augmente de 4000 sans que les créances des autres clients baissent');
  assert.strictEqual(b.passif.lignes.find((l) => l.id === 'clients_crediteurs').montant, 4000, 'avance du client C au passif, sans compensation avec les créances des autres');
  // retour à l'équilibre pour la suite
  await ecrire('CA', '2027-03-26', 'Remboursement client C', [
    { compteNumero: '411', debit: 4000, tiersType: 'client', tiersId: clientC.id }, { compteNumero: '571', credit: 4000 },
  ]);
});

test('TVA : collectée, déductible et due (les opérations diverses sont ignorées)', async () => {
  const mars = await etats.declarationTva({ annee: 2027, mois: 3 });
  assert.strictEqual(mars.collectee, 19250);
  assert.strictEqual(mars.deductible, 7700);
  assert.strictEqual(mars.tvaDue, 11550);
  const fev = await etats.declarationTva({ annee: 2027, mois: 2 });
  assert.strictEqual(fev.tvaDue, 9625);
  assert.strictEqual(fev.historique.length, 2);
  await assert.rejects(etats.declarationTva({ annee: 2027, mois: 13 }), ComptaError);
});

test('TVA : un crédit se reporte d\'un mois sur l\'autre', async () => {
  await ecrire('AC', '2027-04-10', 'Gros achat', [
    { compteNumero: '601', debit: 26000 }, { compteNumero: '4452', debit: 5000 }, { compteNumero: '401', credit: 31000, tiersType: 'fournisseur', tiersId: fournisseur.id },
  ]);
  await ecrire('VT', '2027-05-10', 'Vente mai', [{ compteNumero: '571', debit: 15000 }, { compteNumero: '701', credit: 12000 }, { compteNumero: '4431', credit: 3000 }]);
  const avril = await etats.declarationTva({ annee: 2027, mois: 4 });
  assert.strictEqual(avril.tvaDue, 0);
  assert.strictEqual(avril.creditAReporter, 5000);
  const mai = await etats.declarationTva({ annee: 2027, mois: 5 });
  assert.strictEqual(mai.creditReporte, 5000);
  assert.strictEqual(mai.tvaDue, 0);
  assert.strictEqual(mai.creditAReporter, 2000);
});

test('balance âgée des clients : règlements sur les plus anciennes échéances', async () => {
  const a = await etats.balanceAgee({ type: 'client', dateRef: '2027-04-15' });
  const parNom = Object.fromEntries(a.tiers.map((t) => [t.nom, t]));
  assert.strictEqual(parNom['Atangana Paul'].total, 39625);
  assert.strictEqual(parNom['Atangana Paul'].tranche2, 39625, '73 jours : tranche 61-90');
  assert.strictEqual(parNom.Biyiha.plus, 10000, '95 jours : plus de 90 jours');
  assert.strictEqual(a.total.total, 49625);
  assert.ok(!parNom.Chouaibou, 'client soldé : absent');
});

test('balance âgée des fournisseurs', async () => {
  const f = await etats.balanceAgee({ type: 'fournisseur', dateRef: '2027-04-15' });
  assert.strictEqual(f.tiers.length, 1);
  assert.strictEqual(f.tiers[0].total, 47700 + 31000);
  assert.strictEqual(f.tiers[0].courant, 31000);
  await assert.rejects(etats.balanceAgee({ type: 'banque' }), ComptaError);
});

test('lettrage : équilibre exigé, un seul tiers, annulation, lettrage automatique', async () => {
  const lignes = await etats.lignesOuvertes({ compteNumero: '411', tiersType: 'client', tiersId: clientC.id });
  assert.strictEqual(lignes.length, 2);
  await assert.rejects(etats.lettrer([lignes[0].id]), ComptaError);
  const autre = (await etats.lignesOuvertes({ compteNumero: '411', tiersId: clientA.id }))[0];
  await assert.rejects(etats.lettrer([lignes[0].id, autre.id]), ComptaError);
  const l = await etats.lettrer(lignes.map((x) => x.id));
  assert.match(l.code, /^L\d{5}$/);
  assert.strictEqual(l.montant, 4000);
  await assert.rejects(etats.lettrer(lignes.map((x) => x.id)), (e) => e.code === 'DEJA_LETTREE');
  assert.strictEqual((await etats.lignesOuvertes({ compteNumero: '411', tiersId: clientC.id })).length, 0);

  await etats.delettrer(l.code);
  const auto = await etats.lettrageAutomatique({ type: 'client' });
  assert.strictEqual(auto.lettrages, 1, 'seul le client C se solde exactement');
  await assert.rejects(etats.delettrer('L99999'), ComptaError);
});

test('livre des recettes et dépenses (SMT) : solde final égal au compte de caisse', async () => {
  const livre = await etats.livreRecettesDepenses({});
  const caisse = (await service.balance({})).lignes.find((l) => l.numero === '571');
  assert.strictEqual(livre.soldeFin, caisse.soldeDebiteur);
  assert.strictEqual(livre.totalRecettes - livre.totalDepenses + livre.soldeDebut, livre.soldeFin);
  assert.ok(livre.mouvements.some((m) => m.libelle === 'Loyer' && m.depense === 10000));
});

test('résumé du mode simple', async () => {
  const r = await etats.resume({ annee: 2027, mois: 3 });
  assert.strictEqual(r.chiffreAffaires, 100000);
  assert.strictEqual(r.produits, 100000);
  assert.strictEqual(r.charges, 50000);
  assert.strictEqual(r.resultat, 50000);
  assert.strictEqual(r.tvaAPayer, 11550);
  assert.strictEqual(r.topCharges[0].montant, 40000);
  assert.strictEqual(r.dettesFournisseurs, 47700);
});

test('journal exportable : une ligne par ligne d\'écriture', async () => {
  const j = await etats.journalLignes({});
  assert.ok(j.lignes.length > 10);
  const a = j.lignes.find((l) => l.libelle === 'Vente A à crédit' && l.compte === '411');
  assert.strictEqual(a.compteAuxiliaire, `411${String(clientA.id).padStart(6, '0')}`);
  assert.strictEqual(j.lignes.reduce((s, l) => s + l.debit, 0), j.lignes.reduce((s, l) => s + l.credit, 0));
});

test('export CSV : BOM, séparateur point-virgule, valeurs échappées', () => {
  const csv = enCsv({ colonnes: [{ cle: 'a', libelle: 'Libellé' }, { cle: 'b', libelle: 'Montant', type: 'montant' }, { cle: 'd', libelle: 'Date', type: 'date' }], lignes: [{ a: 'Vente; "spéciale"', b: 1500, d: new Date('2027-03-10T00:00:00Z') }] });
  const texte = csv.toString('utf8');
  assert.strictEqual(texte.charCodeAt(0), 0xFEFF);
  assert.strictEqual(texte.split('\r\n')[0].slice(1), 'Libellé;Montant;Date');
  assert.strictEqual(texte.split('\r\n')[1], '"Vente; ""spéciale""";1500;2027-03-10');
});

test('routes : JSON, CSV et Excel pour un même état, format invalide refusé', async () => {
  const h = { Authorization: 'Bearer test-token' };
  const json = await (await fetch(`${base}/etats/resultat`, { headers: h })).json();
  assert.strictEqual(json.data.resultatNet, json.data.lignes.find((l) => l.id === 'resultat_net').montant);

  const csv = await fetch(`${base}/etats/bilan?format=csv`, { headers: h });
  assert.strictEqual(csv.status, 200);
  assert.match(csv.headers.get('content-type'), /text\/csv/);
  assert.match(csv.headers.get('content-disposition'), /bilan-\d{4}-\d{2}-\d{2}\.csv/);
  assert.match(await csv.text(), /TOTAL ACTIF/);

  const xlsx = await fetch(`${base}/etats/tva?annee=2027&mois=3&format=xlsx`, { headers: h });
  assert.strictEqual(xlsx.status, 200);
  const octets = Buffer.from(await xlsx.arrayBuffer());
  assert.strictEqual(octets.slice(0, 2).toString(), 'PK', 'un fichier Excel est une archive zip');

  const tab = await (await fetch(`${base}/etats/resultat?format=tableau`, { headers: h })).json();
  assert.strictEqual(tab.data.titre, 'Compte de résultat');
  assert.ok(tab.data.colonnes.length === 2 && tab.data.lignes.length > 10);

  assert.strictEqual((await fetch(`${base}/etats/bilan?format=pdf`, { headers: h })).status, 400);
  assert.strictEqual((await fetch(`${base}/etats/tva?annee=2027&mois=15`, { headers: h })).status, 400);
  const gl = await fetch(`${base}/grand-livre?compte=571&format=csv`, { headers: h });
  assert.match(await gl.text(), /Solde reporté/);
  const ag = await (await fetch(`${base}/etats/balance-agee?type=client&dateRef=2027-04-15`, { headers: h })).json();
  assert.strictEqual(ag.data.total.total, 49625);
  const lettre = await fetch(`${base}/lettrage/auto`, { method: 'POST', headers: { ...h, 'Content-Type': 'application/json' }, body: JSON.stringify({ type: 'client' }) });
  assert.strictEqual(lettre.status, 200);
});
