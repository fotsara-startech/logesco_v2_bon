/**
 * Ouverture par client et par fournisseur (reprise des soldes de la gestion), mouvements de caisse manuels,
 * TVA récupérable sur achats et journal d'audit.
 * Exécution : node --test tests/compta-ouverture.test.js
 */
const test = require('node:test');
const assert = require('node:assert');
const installation = require('../src/utils/installation');
const referentiel = require('../src/compta/referentiel');
const { ComptaService } = require('../src/compta/compta-service');
const { MoteurAuto, cibleMouvementCaisse, cibleCommande } = require('../src/compta/moteur-auto');
const { EtatsService } = require('../src/compta/etats');
const { ImmobilisationService } = require('../src/compta/immobilisations');
const { ClotureService } = require('../src/compta/cloture');

const { prisma, nettoyer } = require('./helpers/base-compta').creerBaseSync('ouverture');
const service = new ComptaService(prisma, null);
const moteur = new MoteurAuto(prisma, service);
const immos = new ImmobilisationService(prisma, service, moteur);
const cloture = new ClotureService(prisma, service, moteur, immos);
const etats = new EtatsService(prisma, service);

let clientA; let clientB; let fournisseur; let caisse; let session; let utilisateur;

const net = async (numero, filtre = {}) => {
  const compte = await prisma.comptaCompte.findUnique({ where: { numero } });
  const lignes = await prisma.comptaLigne.findMany({ where: { compteId: compte.id, ecriture: { statut: { in: ['validee', 'contrepassee'] }, ...(filtre.ecriture || {}) }, ...(filtre.ligne || {}) } });
  return lignes.reduce((s, l) => s + l.debit - l.credit, 0);
};

test.before(async () => {
  await referentiel.ensureReferentiel(prisma);
  installation.setInstallationId(null);
  utilisateur = await prisma.utilisateur.create({ data: { nomUtilisateur: 'comptable', motDePasseHash: 'x' } });
  clientA = await prisma.client.create({ data: { nom: 'Atangana', prenom: 'Paul' } });
  clientB = await prisma.client.create({ data: { nom: 'Biyiha' } });
  fournisseur = await prisma.fournisseur.create({ data: { nom: 'Grossiste SA' } });
  // Gestion : A doit 40 000 (solde négatif = dette), B a 15 000 d'avance, on doit 70 000 au fournisseur
  await prisma.compteClient.create({ data: { clientId: clientA.id, soldeActuel: -40000 } });
  await prisma.compteClient.create({ data: { clientId: clientB.id, soldeActuel: 15000 } });
  await prisma.compteFournisseur.create({ data: { fournisseurId: fournisseur.id, soldeActuel: 70000 } });
  caisse = await prisma.cashRegister.create({ data: { nom: 'Caisse 1', soldeActuel: 250000 } });
  session = await prisma.cashSession.create({ data: { caisseId: caisse.id, utilisateurId: utilisateur.id, soldeOuverture: 250000 } });
  const produit = await prisma.produit.create({ data: { reference: 'P1', nom: 'Riz', prixUnitaire: 30000, cump: 20000 } });
  await prisma.stock.create({ data: { produitId: produit.id, quantiteDisponible: 5 } });
});

test.after(async () => { await nettoyer(); });

test('propositions d\'ouverture reprises de la gestion', async () => {
  const p = await cloture.propositionsOuverture();
  assert.strictEqual(p.caisse, 250000);
  assert.strictEqual(p.stock, 100000);
  const parNom = Object.fromEntries(p.clients.map((c) => [c.nom, c.montant]));
  assert.strictEqual(parNom['Atangana Paul'], 40000, 'le client qui doit de l\'argent : créance positive');
  assert.strictEqual(parNom.Biyiha, -15000, 'avance du client : négatif');
  assert.deepStrictEqual(p.fournisseurs.map((f) => f.montant), [70000]);
});

test('ouverture tiers par tiers : comptabilité et gestion concordent dès le premier jour', async () => {
  const p = await cloture.propositionsOuverture();
  const r = await service.enregistrerOuverture({
    dateOuverture: '2027-01-01',
    soldes: [{ compteNumero: '571', debit: p.caisse }, { compteNumero: '31', debit: p.stock }],
    clients: p.clients.map((c) => ({ clientId: c.clientId, montant: c.montant })),
    fournisseurs: p.fournisseurs.map((f) => ({ fournisseurId: f.fournisseurId, montant: f.montant })),
    utilisateurId: utilisateur.id,
  });
  // actif = 250 000 + 100 000 + 40 000 = 390 000 ; passif = 15 000 + 70 000 = 85 000 → écart de 305 000 = capital à saisir
  assert.strictEqual(r.ecart, 305000);
  assert.strictEqual(await net('411', { ligne: { tiersId: clientA.id } }), 40000);
  assert.strictEqual(await net('4191', { ligne: { tiersId: clientB.id } }), -15000);
  assert.strictEqual(await net('401', { ligne: { tiersId: fournisseur.id } }), -70000);
  const controles = await moteur.controles();
  assert.deepStrictEqual(controles.clients, []);
  assert.deepStrictEqual(controles.fournisseurs, []);
  assert.strictEqual(controles.caisse.ecart, 0);
  assert.strictEqual(controles.coherent, true);
});

test('ouverture : montants non entiers refusés', async () => {
  const autre = new ComptaService(prisma, null);
  await assert.rejects(autre.enregistrerOuverture({ dateOuverture: '2027-01-01', soldes: [], clients: [{ clientId: 1, montant: 10.5 }] }), (e) => e.code === 'OUVERTURE_DEJA_FAITE' || /entiers/.test(e.message));
});

test('balance âgée dès l\'ouverture : la créance reportée est visible tiers par tiers', async () => {
  const a = await etats.balanceAgee({ type: 'client', dateRef: '2027-02-15' });
  const parNom = Object.fromEntries(a.tiers.map((t) => [t.nom, t]));
  assert.strictEqual(parNom['Atangana Paul'].total, 40000);
  assert.strictEqual(parNom['Atangana Paul'].tranche1, 40000, '45 jours');
  assert.strictEqual(parNom.Biyiha.avance, 15000);
});

test('mouvements de caisse manuels : contrepartie selon le libellé, sinon compte d\'attente', async () => {
  const cree = (type, description, montant, metadata) => prisma.cashMovement.create({ data: {
    caisseId: caisse.id, sessionId: session.id, type, montant, description, dateCreation: new Date('2027-03-05T10:00:00Z'), ...(metadata ? { metadata: JSON.stringify(metadata) } : {}),
  } });
  const apport = await cree('entree', 'Apport du patron', 100000);
  const banque = await cree('sortie', 'Remise en banque', 60000);
  const inconnue = await cree('sortie', 'Divers', 2500);
  const entree = await cree('entree', 'Rentrée', 700);
  const ignoreDepot = await cree('entree', 'Dépôt client', 5000, { categorie: 'depot_client', clientId: clientA.id });
  const ignoreFournisseur = await cree('sortie', 'Paiement fournisseur', 9000, { typeTransaction: 'paiement_fournisseur' });
  await moteur.generer({ force: true });

  assert.strictEqual(await net('462', { ecriture: { sourceType: 'mouvement_caisse', sourceId: apport.id } }), -100000);
  assert.strictEqual(await net('585', { ecriture: { sourceType: 'mouvement_caisse', sourceId: banque.id } }), 60000);
  assert.strictEqual(await net('4711', { ecriture: { sourceType: 'mouvement_caisse', sourceId: inconnue.id } }), 2500);
  assert.strictEqual(await net('4712', { ecriture: { sourceType: 'mouvement_caisse', sourceId: entree.id } }), -700);
  for (const m of [ignoreDepot, ignoreFournisseur]) {
    assert.strictEqual(await prisma.comptaEcriture.count({ where: { sourceType: 'mouvement_caisse', sourceId: m.id } }), 0, 'déjà couvert par un autre document');
  }
  assert.strictEqual(cibleMouvementCaisse({ type: 'entree', montant: 10, description: 'Prélèvement' }).find((l) => l.net < 0).compteNumero, '462');
  const avant = await prisma.comptaEcriture.count();
  await moteur.generer({ force: true });
  assert.strictEqual(await prisma.comptaEcriture.count(), avant, 'idempotent');
});

test('commande avec TVA récupérable : TVA déductible extraite du prix TTC', async () => {
  const produit = await prisma.produit.create({ data: { reference: 'P2', nom: 'Huile', prixUnitaire: 15000 } });
  const c = await prisma.commandeApprovisionnement.create({ data: {
    numeroCommande: 'CMD-TVA', fournisseurId: fournisseur.id, statut: 'recue', dateCommande: new Date('2027-04-01T10:00:00Z'), tvaRecuperable: true,
    montantTotal: 11925, montantPaye: 0, montantRestant: 11925,
    details: { create: [{ produitId: produit.id, quantiteCommandee: 1, quantiteRecue: 1, coutUnitaire: 11925 }] },
  } });
  const sans = await prisma.commandeApprovisionnement.create({ data: {
    numeroCommande: 'CMD-SANS', fournisseurId: fournisseur.id, statut: 'recue', dateCommande: new Date('2027-04-02T10:00:00Z'),
    montantTotal: 5000, montantPaye: 0, montantRestant: 5000,
    details: { create: [{ produitId: produit.id, quantiteCommandee: 1, quantiteRecue: 1, coutUnitaire: 5000 }] },
  } });
  await moteur.generer({ force: true });
  const filtre = (id) => ({ ecriture: { sourceType: 'achat', sourceId: id } });
  assert.strictEqual(await net('601', filtre(c.id)), 10000);
  assert.strictEqual(await net('4452', filtre(c.id)), 1925);
  assert.strictEqual(await net('401', { ...filtre(c.id), ligne: { tiersId: fournisseur.id } }), -11925);
  assert.strictEqual(await net('4452', filtre(sans.id)), 0, 'sans facture TVA : pas de TVA déductible');
  assert.strictEqual(await net('601', filtre(sans.id)), 5000);
  assert.strictEqual(cibleCommande({ statut: 'recue', fournisseurId: 1, montantPaye: 0, tvaRecuperable: true, details: [{ quantiteRecue: 2, coutUnitaire: 5962.5 }] }, 19.25).reduce((s, l) => s + l.net, 0), 0);

  const tva = await etats.declarationTva({ annee: 2027, mois: 4 });
  assert.strictEqual(tva.deductible, 1925);
  assert.strictEqual(tva.creditAReporter, 1925);

  await prisma.commandeApprovisionnement.update({ where: { id: c.id }, data: { tvaRecuperable: false } });
  await moteur.generer({ force: true });
  assert.strictEqual(await net('4452', filtre(c.id)), 0, 'décocher la TVA régularise l\'écriture');
  assert.strictEqual(await net('601', filtre(c.id)), 11925);
});

test('journal d\'audit : validation, contre-passation, suppression, ouverture, clôture', async () => {
  const brouillon = await service.creerEcriture({ journalCode: 'OD', dateEcriture: '2027-05-01', libelle: 'À valider', lignes: [{ compteNumero: '571', debit: 100 }, { compteNumero: '758', credit: 100 }] });
  await service.validerEcriture(brouillon.id, { utilisateurId: utilisateur.id });
  await service.contrepasser(brouillon.id, { dateEcriture: '2027-05-03', motif: 'erreur', utilisateurId: utilisateur.id });
  const autre = await service.creerEcriture({ journalCode: 'OD', dateEcriture: '2027-05-02', libelle: 'À supprimer', lignes: [{ compteNumero: '571', debit: 5 }, { compteNumero: '758', credit: 5 }] });
  await service.supprimerBrouillon(autre.id, { utilisateurId: utilisateur.id });
  await service.updateParametres({ modeAffichage: 'expert' }, { utilisateurId: utilisateur.id });
  const ex = (await service.listerExercices())[0];
  await service.changerStatutPeriode(ex.id, 5, 'verrouillee', { utilisateurId: utilisateur.id });
  await service.changerStatutPeriode(ex.id, 5, 'ouverte', { utilisateurId: utilisateur.id });

  const journal = await service.listerAudit({});
  const actions = journal.lignes.map((l) => l.action);
  for (const attendu of ['ouverture.enregistree', 'ecriture.validee', 'ecriture.contrepassee', 'ecriture.brouillon_supprime', 'parametres.modifies', 'periode.verrouillee', 'periode.rouverte']) {
    assert.ok(actions.includes(attendu), `action tracée : ${attendu}`);
  }
  const valid = journal.lignes.find((l) => l.action === 'ecriture.validee');
  assert.strictEqual(valid.utilisateur, 'comptable');
  assert.match(valid.details.numeroPiece, /^OD-2027-/);
  assert.strictEqual((await service.listerAudit({ action: 'periode.' })).total, 2);
  assert.strictEqual((await service.listerAudit({ dateDebut: '2000-01-01', dateFin: '2000-01-02' })).total, 0);
});

test('journal d\'audit : une panne d\'audit ne bloque pas l\'opération', async () => {
  const casse = new ComptaService({ ...prisma, comptaAudit: { create: async () => { throw new Error('panne'); } } }, null);
  await assert.doesNotReject(casse.tracer('test.panne', { utilisateurId: 1 }));
});
