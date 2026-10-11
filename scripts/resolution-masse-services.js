/**
 * Résolution en masse des produits « service » marqués à tort.
 *
 * Décision prise par le responsable : AUCUN produit de cette base n'est un vrai service.
 *   1. Produit « service » vendu sans sortie de stock → on déduit les unités vendues (mouvement de
 *      correction tracé, option « apres_ventes » du centre de décisions) et le produit redevient physique.
 *   2. Produit « service » avec du stock mais sans vente non sortie → stock conservé, produit physique.
 *   3. Tout autre produit « service » (sans stock ni vente) → simplement repassé en produit physique.
 * Les réceptions peut-être en double et les écarts d'historique ne sont PAS touchés (même pour un produit
 * « service » ou vendu sans sortie) : ils restent des décisions individuelles dans l'écran « Décisions à
 * prendre », car le bon stock dépend d'un comptage physique.
 *
 * Utilisation (depuis le dossier du backend, avec DATABASE_URL / CLOUD_DB_URL de la base visée) :
 *   node scripts/resolution-masse-services.js             → simulation, n'écrit rien
 *   node scripts/resolution-masse-services.js --appliquer → applique
 *
 * Pour que les corrections atteignent les autres postes, la base doit être connectée au cloud AVANT
 * d'appliquer : le poste doit d'abord avoir réservé sa plage d'identifiants, sinon les nouveaux
 * mouvements prendraient des identifiants d'un autre poste.
 */
const path = require('path');
const fs = require('fs');

const dataDir = process.env.LOGESCO_DATA_DIR || path.join(__dirname, '..');
const envFile = path.join(dataDir, '.env');
if (fs.existsSync(envFile)) require('dotenv').config({ path: envFile, override: false });

const { PrismaClient } = require('@prisma/client');
const { DecisionCenter } = require('../src/services/decision-center');

const appliquer = process.argv.includes('--appliquer');

async function main() {
  const prisma = new PrismaClient();
  const sync = require('../src/services/sync-service');
  const centre = new DecisionCenter({ prisma, syncService: sync });
  sync.localPrisma = prisma;

  if (appliquer) {
    if (!process.env.CLOUD_DB_URL) throw new Error("CLOUD_DB_URL absent : les corrections ne seraient pas envoyées aux autres postes. Abandon.");
    // Pas de seconde synchronisation en parallèle du backend : on lit seulement l'identité du poste
    // (plage d'ids) ; les opérations créées ici restent « en attente » et le backend les envoie.
    await sync.ensureInstallationIdentity(prisma);
    const installation = require('../src/utils/installation');
    if (!installation.getInstallationId()) {
      throw new Error("Ce poste n'a pas encore de plage d'identifiants (démarrez d'abord le backend relié au cloud). Abandon, rien n'a été modifié.");
    }
    console.log(`Poste n°${installation.getInstallationId()} — les corrections seront envoyées par le backend.`);
  }

  const { cases } = await centre.listCases();
  const plan = [];
  const traites = new Set();
  // Les cas où le stock lui-même est douteux (réception peut-être saisie en double, écart avec l'historique)
  // dépendent d'un fait que seul le magasin connaît : on ne les tranche JAMAIS en masse, même si le produit est
  // aussi marqué « service » ou vendu sans sortie. Ils restent pour l'écran « Décisions à prendre ».
  const DOUTEUX = ['reception_en_double', 'ecart_historique'];
  const produitsDouteux = new Set();
  for (const c of cases) {
    const codes = c.raisons.map((r) => r.code);
    if (codes.some((x) => DOUTEUX.includes(x))) {
      produitsDouteux.add(c.produit.id);
      continue;
    }
    if (codes.includes('vente_sans_mouvement') && c.options.some((o) => o.id === 'apres_ventes')) {
      plan.push({ cas: c, option: 'apres_ventes' });
      traites.add(c.produit.id);
    } else if (c.produit.estService && codes.includes('service_avec_stock') && c.options.some((o) => o.id === 'garder')) {
      plan.push({ cas: c, option: 'garder' });
      traites.add(c.produit.id);
    }
  }
  const reste = await prisma.produit.findMany({ where: { estService: true } });
  // un produit « service » dont le stock est douteux garde son marquage jusqu'à la décision
  const autres = reste.filter((p) => !traites.has(p.id) && !produitsDouteux.has(p.id));
  const laisses = cases.filter((c) => !plan.some((p) => p.cas.key === c.key));

  console.log(`\n${appliquer ? 'APPLICATION' : 'SIMULATION'} — ${plan.length} cas de stock, ${autres.length} autre(s) produit(s) « service »`);
  for (const { cas, option } of plan) {
    const o = cas.options.find((x) => x.id === option);
    console.log(` • ${cas.produit.nom}${cas.boutique ? ' [' + cas.boutique.nom + ']' : ''} : ${o.consequence} — ${o.label}`);
  }
  console.log(` • ${autres.length} produit(s) sans stock ni vente à repasser en produit physique`);
  if (laisses.length) {
    console.log(`\nLaissés à vos soins (${laisses.length}) :`);
    for (const c of laisses) console.log(` - ${c.produit.nom} : ${c.raisons.map((r) => r.titre).join(' ; ')}`);
  }

  if (!appliquer) {
    console.log('\nSimulation terminée : rien n\'a été modifié. Ajoutez --appliquer pour appliquer.');
    await prisma.$disconnect();
    return;
  }

  let ok = 0;
  for (const { cas, option } of plan) {
    await centre.apply({ caseKey: cas.key, optionId: option, stockVu: cas.stockAffiche, marquerPhysique: true });
    ok++;
  }
  let reconvertis = 0;
  for (const p of autres) {
    const maj = await prisma.produit.update({ where: { id: p.id }, data: { estService: false } });
    await sync.enqueue('produits', 'UPDATE', maj);
    reconvertis++;
  }
  console.log(`\nTerminé : ${ok} cas de stock résolus, ${reconvertis} produit(s) repassé(s) en physique.`);
  await prisma.$disconnect();
  process.exit(0);
}

main().catch((e) => {
  console.error('Erreur :', e.message);
  process.exit(1);
});
