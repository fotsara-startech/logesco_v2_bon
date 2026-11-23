/**
 * Écritures automatiques (phase 2) : ventes, achats, dépenses, caisse, règlements, annulations,
 * idempotence et contrôles de cohérence. Base temporaire créée avec le schéma Prisma complet.
 * Exécution : node --test tests/compta-auto.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execSync } = require('node:child_process');
const installation = require('../src/utils/installation');
const referentiel = require('../src/compta/referentiel');
const { ComptaService } = require('../src/compta/compta-service');
const { MoteurAuto, compteDepense, cibleVente, cibleCommande } = require('../src/compta/moteur-auto');

const { prisma, nettoyer, postgres } = require('./helpers/base-compta').creerBaseSync('auto');
// Le schéma PostgreSQL du projet n'a pas de colonne dateModification sur les ventes ni les commandes : la date de régularisation retombe alors sur celle du document
const modif = (iso) => (postgres ? {} : { dateModification: new Date(iso) });
const service = new ComptaService(prisma, null);
const moteur = new MoteurAuto(prisma, service);

let utilisateur; let caisse; let session; let client; let fournisseur; let produit; let categorieLoyer;

/** Solde net (débit − crédit) d'un compte, éventuellement pour un tiers et un document source */
async function net(numero, { tiersId, sourceType, sourceId } = {}) {
  const compte = await prisma.comptaCompte.findUnique({ where: { numero } });
  const lignes = await prisma.comptaLigne.findMany({
    where: {
      compteId: compte.id,
      ecriture: { statut: { in: ['validee', 'contrepassee'] }, ...(sourceType ? { sourceType } : {}), ...(sourceId ? { sourceId } : {}) },
      ...(tiersId ? { tiersId } : {}),
    },
  });
  return lignes.reduce((s, l) => s + l.debit - l.credit, 0);
}

const vente = (extra = {}) => ({
  numeroVente: `V-${Math.random().toString(36).slice(2, 8)}`,
  sousTotal: 10000, montantRemise: 0, montantTva: 1925, montantTotal: 11925,
  montantPaye: 11925, montantRestant: 0, avanceUtilisee: 0, statut: 'terminee', modePaiement: 'comptant',
  dateVente: new Date('2027-03-10T10:00:00Z'),
  ...extra,
});

test.before(async () => {
  await referentiel.ensureReferentiel(prisma);
  installation.setInstallationId(null);

  utilisateur = await prisma.utilisateur.create({ data: { nomUtilisateur: 'caissier', motDePasseHash: 'x' } });
  caisse = await prisma.cashRegister.create({ data: { nom: 'Caisse 1', soldeActuel: 100000 } });
  session = await prisma.cashSession.create({ data: { caisseId: caisse.id, utilisateurId: utilisateur.id, soldeOuverture: 100000 } });
  client = await prisma.client.create({ data: { nom: 'Mballa' } });
  await prisma.compteClient.create({ data: { clientId: client.id, soldeActuel: 0 } });
  fournisseur = await prisma.fournisseur.create({ data: { nom: 'Fournisseur SA' } });
  await prisma.compteFournisseur.create({ data: { fournisseurId: fournisseur.id, soldeActuel: 0 } });
  produit = await prisma.produit.create({ data: { reference: 'P1', nom: 'Produit', prixUnitaire: 1000 } });
  categorieLoyer = await prisma.movementCategory.create({ data: { nom: 'loyer', displayName: 'Loyer' } });
});

test.after(async () => {
  await nettoyer();
});

test('sans ouverture enregistrée : rien n\'est généré', async () => {
  const r = await moteur.generer({ force: true });
  assert.match(r.ignore, /ouverture/);
});

test('seul le poste de référence génère', async () => {
  installation.setInstallationId(3);
  try {
    assert.match((await moteur.generer()).ignore, /référence/);
  } finally {
    installation.setInstallationId(null);
  }
});

test('ouverture puis vente comptant sans client : chiffre d\'affaires, TVA et caisse', async () => {
  await service.enregistrerOuverture({
    dateOuverture: '2027-01-01',
    soldes: [{ compteNumero: '571', debit: 100000 }, { compteNumero: '101', credit: 100000 }],
  });
  const v = await prisma.vente.create({ data: vente() });
  const r = await moteur.generer({ force: true });
  assert.strictEqual(r.erreurs.length, 0, JSON.stringify(r.erreurs));
  assert.strictEqual(r.parType.vente.ecritures, 1);
  assert.strictEqual(await net('701', { sourceType: 'vente', sourceId: v.id }), -10000);
  assert.strictEqual(await net('4431', { sourceType: 'vente', sourceId: v.id }), -1925);
  assert.strictEqual(await net('571', { sourceType: 'vente', sourceId: v.id }), 11925);
  assert.strictEqual(await net('411', { sourceType: 'vente', sourceId: v.id }), 0);
  const e = await prisma.comptaEcriture.findFirst({ where: { sourceType: 'vente', sourceId: v.id }, include: { journal: true } });
  assert.strictEqual(e.journal.code, 'VT');
  assert.strictEqual(e.statut, 'validee');
  assert.match(e.numeroPiece, /^VT-2027-\d{6}$/);
  assert.strictEqual(e.origine, 'auto');
});

test('relancer ne produit rien de plus (idempotence)', async () => {
  const avant = await prisma.comptaEcriture.count();
  const r = await moteur.generer({ force: true });
  assert.strictEqual(r.parType.vente.ecritures, 0);
  assert.strictEqual(await prisma.comptaEcriture.count(), avant);
});

test('vente antérieure à l\'ouverture : ignorée', async () => {
  const avant = await prisma.comptaEcriture.count();
  await prisma.vente.create({ data: vente({ dateVente: new Date('2026-12-30T10:00:00Z') }) });
  await moteur.generer({ force: true });
  assert.strictEqual(await prisma.comptaEcriture.count(), avant);
});

test('vente à crédit au client puis règlement : créance suivie par client, écriture de régularisation', async () => {
  const v = await prisma.vente.create({ data: vente({
    clientId: client.id, sousTotal: 20000, montantTva: 3850, montantTotal: 23850, montantPaye: 10000, montantRestant: 13850, modePaiement: 'credit',
  }) });
  await moteur.generer({ force: true });
  assert.strictEqual(await net('411', { tiersId: client.id }), 13850);
  assert.strictEqual(await net('571', { sourceType: 'vente', sourceId: v.id }), 10000);

  await prisma.vente.update({ where: { id: v.id }, data: { montantPaye: 23850, montantRestant: 0, ...modif('2027-04-02T09:00:00Z') } });
  await moteur.generer({ force: true });
  assert.strictEqual(await net('411', { tiersId: client.id }), 0);
  assert.strictEqual(await net('571', { sourceType: 'vente', sourceId: v.id }), 23850);
  const pieces = await prisma.comptaEcriture.findMany({ where: { sourceType: 'vente', sourceId: v.id }, orderBy: { id: 'asc' } });
  assert.strictEqual(pieces.length, 2);
  assert.match(pieces[1].libelle, /régularisation/);
  if (!postgres) assert.strictEqual(pieces[1].dateEcriture.toISOString().slice(0, 10), '2027-04-02');
});

test('annulation d\'une vente : tout est contre-passé, solde du document nul', async () => {
  const v = await prisma.vente.create({ data: vente({ dateVente: new Date('2027-05-05T10:00:00Z') }) });
  await moteur.generer({ force: true });
  assert.strictEqual(await net('701', { sourceType: 'vente', sourceId: v.id }), -10000);
  await prisma.vente.update({ where: { id: v.id }, data: { statut: 'annulee', ...modif('2027-05-06T10:00:00Z') } });
  await moteur.generer({ force: true });
  for (const compte of ['701', '4431', '571', '411']) assert.strictEqual(await net(compte, { sourceType: 'vente', sourceId: v.id }), 0, compte);
});

test('annulation partielle d\'articles : seule la différence est écrite', async () => {
  const v = await prisma.vente.create({ data: vente({ dateVente: new Date('2027-05-10T10:00:00Z') }) });
  await moteur.generer({ force: true });
  // moitié des articles annulés, remboursée en espèces (comme settleReleasedValue)
  await prisma.vente.update({ where: { id: v.id }, data: { sousTotal: 5000, montantTva: 962.5, montantTotal: 5962.5, montantPaye: 5962.5, ...modif('2027-05-11T10:00:00Z') } });
  await moteur.generer({ force: true });
  const ht = await net('701', { sourceType: 'vente', sourceId: v.id });
  const tva = await net('4431', { sourceType: 'vente', sourceId: v.id });
  const caisseV = await net('571', { sourceType: 'vente', sourceId: v.id });
  assert.strictEqual(ht + tva + caisseV, 0, 'document équilibré');
  assert.ok(ht > -5100 && ht < -4900, `CA ${ht}`);
});

test('avance du client consommée : compte 4191 débité à la place de la caisse', async () => {
  const v = await prisma.vente.create({ data: vente({
    clientId: client.id, dateVente: new Date('2027-06-01T10:00:00Z'), montantPaye: 11925, avanceUtilisee: 5000,
  }) });
  await moteur.generer({ force: true });
  assert.strictEqual(await net('4191', { sourceType: 'vente', sourceId: v.id }), 5000);
  assert.strictEqual(await net('571', { sourceType: 'vente', sourceId: v.id }), 6925);
});

test('dépôt d\'avance et règlement direct d\'un client', async () => {
  const compte = await prisma.compteClient.findUnique({ where: { clientId: client.id } });
  const depot = await prisma.transactionCompte.create({ data: {
    typeCompte: 'client', compteId: compte.id, typeTransaction: 'depot', typeTransactionDetail: 'depot_avance',
    montant: 8000, soldeApres: 8000, dateTransaction: new Date('2027-06-02T10:00:00Z'), referenceType: 'depot',
  } });
  const direct = await prisma.cashMovement.create({ data: {
    caisseId: caisse.id, sessionId: session.id, type: 'entree', montant: 3000, description: 'Paiement dette client',
    dateCreation: new Date('2027-06-03T10:00:00Z'), metadata: JSON.stringify({ categorie: 'paiement_client', clientId: client.id }),
  } });
  const autre = await prisma.cashMovement.create({ data: {
    caisseId: caisse.id, sessionId: session.id, type: 'entree', montant: 9999, description: 'Apport divers',
    dateCreation: new Date('2027-06-03T11:00:00Z'), metadata: JSON.stringify({ categorie: 'autre' }),
  } });
  await moteur.generer({ force: true });
  assert.strictEqual(await net('4191', { sourceType: 'depot_client', sourceId: depot.id }), -8000);
  assert.strictEqual(await net('571', { sourceType: 'depot_client', sourceId: depot.id }), 8000);
  assert.strictEqual(await net('411', { sourceType: 'reglement_client', sourceId: direct.id }), -3000);
  assert.strictEqual(await prisma.comptaEcriture.count({ where: { sourceType: 'reglement_client', sourceId: autre.id } }), 0, 'un mouvement sans client n\'est pas un règlement');
});

test('achat fournisseur : achats reçus, dette puis règlement', async () => {
  const c = await prisma.commandeApprovisionnement.create({ data: {
    numeroCommande: 'CMD-1', fournisseurId: fournisseur.id, statut: 'partiellement_recue', dateCommande: new Date('2027-07-01T10:00:00Z'),
    montantTotal: 20000, montantPaye: 4000, montantRestant: 16000,
    details: { create: [{ produitId: produit.id, quantiteCommandee: 20, quantiteRecue: 10, coutUnitaire: 1000 }] },
  } });
  await moteur.generer({ force: true });
  assert.strictEqual(await net('601', { sourceType: 'achat', sourceId: c.id }), 10000);
  assert.strictEqual(await net('401', { tiersId: fournisseur.id }), -6000);
  assert.strictEqual(await net('571', { sourceType: 'achat', sourceId: c.id }), -4000);

  await prisma.commandeApprovisionnement.update({ where: { id: c.id }, data: { montantPaye: 12000, ...modif('2027-07-05T10:00:00Z') } });
  await moteur.generer({ force: true });
  assert.strictEqual(await net('401', { tiersId: fournisseur.id }), 0);
  assert.strictEqual(await net('4091', { tiersId: fournisseur.id }), 2000, 'payé plus que reçu : avance fournisseur');
});

test('règlement fournisseur hors commande', async () => {
  const cf = await prisma.compteFournisseur.findUnique({ where: { fournisseurId: fournisseur.id } });
  const libre = await prisma.transactionCompte.create({ data: {
    typeCompte: 'fournisseur', compteId: cf.id, typeTransaction: 'paiement', montant: 1500, soldeApres: 0,
    dateTransaction: new Date('2027-07-06T10:00:00Z'), referenceType: 'paiement_direct',
  } });
  const lie = await prisma.transactionCompte.create({ data: {
    typeCompte: 'fournisseur', compteId: cf.id, typeTransaction: 'paiement', montant: 777, soldeApres: 0,
    dateTransaction: new Date('2027-07-06T11:00:00Z'), referenceType: 'approvisionnement', referenceId: 1,
  } });
  await moteur.generer({ force: true });
  assert.strictEqual(await net('401', { sourceType: 'reglement_fournisseur', sourceId: libre.id }), 1500);
  assert.strictEqual(await prisma.comptaEcriture.count({ where: { sourceType: 'reglement_fournisseur', sourceId: lie.id } }), 0, 'déjà dans montantPaye de la commande');
});

test('dépenses : compte selon la catégorie, annulation reprise', async () => {
  assert.strictEqual(compteDepense({ nom: 'loyer', displayName: 'Loyer' }), '622');
  assert.strictEqual(compteDepense({ nom: 'x', displayName: 'Électricité et eau' }), '605');
  assert.strictEqual(compteDepense({ nom: 'divers', displayName: 'Divers' }), '658');
  const m = await prisma.financialMovement.create({ data: {
    reference: 'MF-1', montant: 50000, categorieId: categorieLoyer.id, description: 'Loyer juillet', utilisateurId: utilisateur.id,
    date: new Date('2027-07-07T10:00:00Z'),
  } });
  await moteur.generer({ force: true });
  assert.strictEqual(await net('622', { sourceType: 'depense', sourceId: m.id }), 50000);
  assert.strictEqual(await net('571', { sourceType: 'depense', sourceId: m.id }), -50000);
  await prisma.financialMovement.update({ where: { id: m.id }, data: { statut: 'annule' } });
  await moteur.generer({ force: true });
  assert.strictEqual(await net('622', { sourceType: 'depense', sourceId: m.id }), 0);
  assert.strictEqual(await net('571', { sourceType: 'depense', sourceId: m.id }), 0);
});

test('écart de caisse à la fermeture d\'une session', async () => {
  const s = await prisma.cashSession.create({ data: {
    caisseId: caisse.id, utilisateurId: utilisateur.id, soldeOuverture: 0, isActive: false,
    dateFermeture: new Date('2027-07-08T18:00:00Z'), soldeFermeture: 9500, soldeAttendu: 10000, ecart: -500,
  } });
  await moteur.generer({ force: true });
  assert.strictEqual(await net('658', { sourceType: 'ecart_caisse', sourceId: s.id }), 500);
  assert.strictEqual(await net('571', { sourceType: 'ecart_caisse', sourceId: s.id }), -500);
});

test('une écriture automatique ne se contre-passe pas à la main', async () => {
  const e = await prisma.comptaEcriture.findFirst({ where: { origine: 'auto' } });
  await assert.rejects(service.contrepasser(e.id), (err) => err.code === 'ECRITURE_AUTO');
});

test('la balance reste équilibrée après toutes les générations', async () => {
  const b = await service.balance({});
  assert.ok(b.equilibree);
  assert.ok(b.total.debit > 0);
});

test('cibles toujours équilibrées, même avec des données incohérentes', async () => {
  const mauvais = cibleVente({ statut: 'terminee', montantTotal: 100, montantTva: 500, montantPaye: 0, avanceUtilisee: 0 });
  assert.strictEqual(mauvais.reduce((s, l) => s + l.net, 0), 0, 'la TVA est bornée au total : toujours équilibré');
  const c = cibleCommande({ statut: 'recue', fournisseurId: 1, montantPaye: 0, details: [{ quantiteRecue: 3, coutUnitaire: 1000.4 }] });
  assert.strictEqual(c.reduce((s, l) => s + l.net, 0), 0);
});

test('contrôles : comptes clients, fournisseurs et caisse comparés à la gestion', async () => {
  // Alignement volontaire de la gestion sur la comptabilité pour ce client / ce fournisseur
  const creance = await net('411', { tiersId: client.id });
  const avance = await net('4191', { tiersId: client.id });
  await prisma.compteClient.update({ where: { clientId: client.id }, data: { soldeActuel: -(creance + avance) } });
  const dette = await net('401', { tiersId: fournisseur.id });
  const avanceF = await net('4091', { tiersId: fournisseur.id });
  await prisma.compteFournisseur.update({ where: { fournisseurId: fournisseur.id }, data: { soldeActuel: -(dette + avanceF) } });
  const comptableCaisse = await net('571');
  await prisma.cashRegister.update({ where: { id: caisse.id }, data: { soldeActuel: comptableCaisse } });
  const ok = await moteur.controles();
  assert.deepStrictEqual(ok.clients, []);
  assert.deepStrictEqual(ok.fournisseurs, []);
  assert.strictEqual(ok.caisse.ecart, 0);
  assert.strictEqual(ok.coherent, true);

  await prisma.compteClient.update({ where: { clientId: client.id }, data: { soldeActuel: 777 } });
  const ko = await moteur.controles();
  assert.strictEqual(ko.coherent, false);
  assert.strictEqual(ko.clients.length, 1);
  assert.strictEqual(ko.clients[0].clientId, client.id);
});
