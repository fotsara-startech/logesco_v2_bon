/**
 * Les écrans qui filtrent par période, sur une VRAIE base SQLite où les dates sont en texte ET en nombre.
 *
 * Chaque table reçoit 5 lignes (A à E : 1er, 10, 15, 20 et 25 octobre) écrites dans trois formats différents. Chaque écran
 * est interrogé pour la période du 5 au 22 octobre : il doit renvoyer exactement B, C et D.
 * Avant le correctif : "date >= 5 oct" laissait passer tout le texte et "date <= 22 oct" l'éliminait : résultat VIDE.
 *
 * Exécution :  node --test tests/filtres-date-ecrans.test.js
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

process.env.NODE_ENV = 'test'; // le jeton "test-token" est accepté hors production

const dossier = fs.mkdtempSync(path.join(os.tmpdir(), 'filtres-ecrans-'));
const url = `file:${path.join(dossier, 'essai.db').split(path.sep).join('/')}?connection_limit=1`;
let prisma;
const serveurs = [];

const T = (a, m, j, h = 10) => new Date(a, m - 1, j, h, 0, 0);
const JOURS = [
  ['A', T(2026, 10, 1), 'iso'],
  ['B', T(2026, 10, 10), 'sql'],
  ['C', T(2026, 10, 15), 'ms'],
  ['D', T(2026, 10, 20), 'iso'],
  ['E', T(2026, 10, 25), 'ms'],
];
const ecrire = (date, forme) =>
  forme === 'ms' ? date.getTime() : forme === 'iso' ? date.toISOString() : date.toISOString().replace('T', ' ').replace(/\.\d+Z$/, '');

const DEBUT = T(2026, 10, 5, 0).toISOString();
const FIN = T(2026, 10, 22, 0).toISOString();
const ATTENDU = ['B', 'C', 'D'];

/** Lance un routeur Express sur un port libre et retourne une fonction GET */
async function monter(fabrique) {
  const app = express();
  app.use(express.json());
  app.use('/', fabrique());
  const serveur = http.createServer(app);
  await new Promise((r) => serveur.listen(0, r));
  serveurs.push(serveur);
  const port = serveur.address().port;
  return async (chemin) => {
    const r = await fetch(`http://127.0.0.1:${port}${chemin}`, { headers: { authorization: 'Bearer test-token' } });
    const texte = await r.text();
    return { statut: r.status, texte };
  };
}

/** Lettres trouvées dans la réponse pour un préfixe (ex. "PF-" -> "BCD") */
const lettres = (texte, prefixe) => [...new Set([...texte.matchAll(new RegExp(`${prefixe}([A-E])\\b`, 'g'))].map((m) => m[1]))].sort();

test.before(async () => {
  execSync('npx prisma db push --skip-generate --accept-data-loss', {
    cwd: path.join(__dirname, '..'),
    env: { ...process.env, DATABASE_URL: url },
    stdio: 'ignore',
  });
  prisma = new PrismaClient({ datasources: { db: { url } } });
  await prisma.$executeRawUnsafe('PRAGMA foreign_keys = OFF'); // une seule connexion : sans effet sur les autres

  await prisma.$executeRawUnsafe(`INSERT INTO produits (id, reference, nom, prix_unitaire, date_modification) VALUES (1, 'R1', 'Produit', 1, 0)`);
  await prisma.$executeRawUnsafe(`INSERT INTO utilisateurs (id, nom_utilisateur, mot_de_passe_hash, date_modification) VALUES (1, 'u', 'h', 0)`);
  await prisma.$executeRawUnsafe(`INSERT INTO boutiques (id, nom, date_modification) VALUES (1, 'B1', 0)`);
  await prisma.$executeRawUnsafe(`INSERT INTO fournisseurs (id, nom, date_modification) VALUES (1, 'F', 0)`);
  await prisma.$executeRawUnsafe(`INSERT INTO movement_categories (id, nom, display_name, date_modification) VALUES (1, 'cat', 'Cat', 0)`);
  await prisma.$executeRawUnsafe(`INSERT INTO ventes (id, numero_vente, sous_total, montant_total, statut) VALUES (1, 'V-0', 1, 1, 'terminee')`);

  const jourPlus = (j) => new Date(Date.now() + j * 86400000);
  const PEREMPTION = [['A', -30, 'iso'], ['B', -5, 'sql'], ['C', 3, 'ms'], ['D', 20, 'iso'], ['E', 200, 'ms']];
  for (const [n, j, f] of PEREMPTION) {
    await prisma.$executeRawUnsafe(`INSERT INTO dates_peremption (produit_id, date_peremption, quantite, numero_lot, date_modification) VALUES (1, ?, 5, ?, 0)`, ecrire(jourPlus(j), f), `LOT-${n}`);
  }

  for (const [n, d, f] of JOURS) {
    const v = ecrire(d, f);
    await prisma.$executeRawUnsafe(`INSERT INTO mouvements_stock (produit_id, type_mouvement, changement_quantite, notes, date_mouvement) VALUES (1, 'entree', 1, ?, ?)`, `MS-${n}`, v);
    await prisma.$executeRawUnsafe(`INSERT INTO ventes_proforma (numero_proforma, sous_total, montant_total, date_modification, date_creation) VALUES (?, 1, 1, 0, ?)`, `PF-${n}`, v);
    await prisma.$executeRawUnsafe(`INSERT INTO commandes_approvisionnement (numero_commande, fournisseur_id, date_commande) VALUES (?, 1, ?)`, `CMD-${n}`, v);
    await prisma.$executeRawUnsafe(`INSERT INTO historique_recus (vente_id, numero_recu, contenu_recu, date_generation) VALUES (1, ?, 'x', ?)`, `RCU-${n}`, v);
    await prisma.$executeRawUnsafe(
      `INSERT INTO financial_movements (reference, montant, categorie_id, description, utilisateur_id, date_modification, date, boutique_id) VALUES (?, 100, 1, 'd', 1, 0, ?, 1)`,
      `FM-${n}`, v,
    );
    await prisma.$executeRawUnsafe(
      `INSERT INTO ventes (numero_vente, sous_total, montant_total, statut, commercial_id, boutique_id, date_vente) VALUES (?, 10, 10, 'terminee', 1, 1, ?)`,
      `VC-${n}`, v,
    );
    const idVente = Number((await prisma.$queryRawUnsafe('SELECT last_insert_rowid() AS id'))[0].id);
    const qte = { A: 1, B: 10, C: 100, D: 1000, E: 10000 }[n];
    await prisma.$executeRawUnsafe(
      `INSERT INTO details_ventes (vente_id, produit_id, quantite, prix_unitaire, prix_affiche, prix_total) VALUES (?, 1, ?, 10, 10, 10)`,
      idVente, qte,
    );
  }
});

test.after(async () => {
  for (const s of serveurs) s.close();
  if (prisma) await prisma.$disconnect();
  fs.rmSync(dossier, { recursive: true, force: true });
});

const requete = `dateDebut=${encodeURIComponent(DEBUT)}&dateFin=${encodeURIComponent(FIN)}`;

test('mouvements de stock (inventaire) : la période du 5 au 22 renvoie B, C, D', async () => {
  const { createInventoryRouter } = require('../src/routes/inventory');
  const get = await monter(() => createInventoryRouter({ prisma, authService: {} }));
  const r = await get(`/movements?${requete}&limit=50`);
  assert.strictEqual(r.statut, 200, r.texte.slice(0, 300));
  assert.deepStrictEqual(lettres(r.texte, 'MS-'), ATTENDU);
});

test('export CSV des mouvements de stock : même période', async () => {
  const { createInventoryRouter } = require('../src/routes/inventory');
  const get = await monter(() => createInventoryRouter({ prisma, authService: {} }));
  const r = await get(`/movements/export/csv?${requete}`);
  assert.strictEqual(r.statut, 200, r.texte.slice(0, 300));
  assert.deepStrictEqual(lettres(r.texte, 'MS-'), ATTENDU);
});

test('proformas : la période du 5 au 22 renvoie B, C, D', async () => {
  const { createProformaRouter } = require('../src/routes/proformas');
  const get = await monter(() => createProformaRouter({ prisma, authService: {}, syncService: null }));
  const r = await get(`/?${requete}&limit=50`);
  assert.strictEqual(r.statut, 200, r.texte.slice(0, 300));
  assert.deepStrictEqual(lettres(r.texte, 'PF-'), ATTENDU);
});

test('approvisionnements : la période du 5 au 22 renvoie B, C, D', async () => {
  const { createProcurementRouter } = require('../src/routes/procurement');
  const get = await monter(() => createProcurementRouter({ prisma, authService: {} }));
  const r = await get(`/?${requete}&limit=50`);
  assert.strictEqual(r.statut, 200, r.texte.slice(0, 300));
  assert.deepStrictEqual(lettres(r.texte, 'CMD-'), ATTENDU);
});

test('historique des reçus (impression) : la période du 5 au 22 renvoie B, C, D', async () => {
  const createPrintingRouter = require('../src/routes/printing');
  const get = await monter(() => createPrintingRouter({ prisma, authService: {} }));
  const r = await get(`/receipts?${requete}&limit=50`);
  assert.strictEqual(r.statut, 200, r.texte.slice(0, 300));
  assert.deepStrictEqual(lettres(r.texte, 'RCU-'), ATTENDU);
});

test('mouvements financiers : liste et statistiques de la période du 5 au 22', async () => {
  const FinancialMovementService = require('../src/services/financial-movement');
  const svc = new FinancialMovementService(prisma, null);
  const liste = await svc.getMovements({ startDate: DEBUT, endDate: FIN, limit: 50 });
  assert.deepStrictEqual(lettres(JSON.stringify(liste.movements), 'FM-'), ATTENDU);
  assert.strictEqual(liste.pagination.total, 3);
  const stats = await svc.getStatistics({ startDate: DEBUT, endDate: FIN });
  assert.strictEqual(stats.totalMovements ?? stats.summary?.totalMovements ?? stats.total, 3, JSON.stringify(stats).slice(0, 300));
});

test('catégories de mouvements : statistiques de la période du 5 au 22', async () => {
  const MovementCategoryService = require('../src/services/movement-category');
  const svc = new MovementCategoryService(prisma);
  const stats = await svc.getCategoryStatistics({ startDate: DEBUT, endDate: FIN });
  const cat = stats.find((s) => s.category.id === 1);
  assert.strictEqual(cat.movementCount, 3);
  assert.strictEqual(cat.totalAmount, 300);
});

test('export comptable des mouvements : la période du 5 au 22', async () => {
  const MovementReportService = require('../src/services/movement-report');
  const svc = new MovementReportService(prisma, null);
  const lignes = await svc.getDetailedMovements(DEBUT, FIN);
  assert.strictEqual(lignes.length, 3);
});

test('rapport commercial : la période du 5 au 22 compte 3 ventes', async () => {
  const CommercialReportService = require('../src/services/commercial-report');
  const svc = new CommercialReportService(prisma);
  const r = await svc.getSummary(DEBUT, FIN);
  assert.strictEqual(r.totalCount, 3);
  assert.strictEqual(r.totalAmount, 30);
});

test('numéro de reçu : le compteur ne compte que les reçus DU JOUR', async () => {
  const { generateReceiptNumber } = require('../src/utils/transformers');
  const aujourdhui = new Date();
  await prisma.$executeRawUnsafe(`INSERT INTO historique_recus (vente_id, numero_recu, contenu_recu, date_generation) VALUES (1, 'RCU-AUJ-1', 'x', ?)`, aujourdhui.toISOString());
  const numero = await generateReceiptNumber(prisma);
  // Reçus du jour : celui qu on vient d insérer, plus ceux du jeu d essai qui tombent aujourd hui. La séquence est ce nombre + 1
  // (et non 7 comme si tous les reçus de la base étaient comptés).
  const duJour = 1 + JOURS.filter(([, d]) => d.toDateString() === aujourdhui.toDateString()).length;
  assert.ok(numero.includes('-' + String(duJour + 1).padStart(4, '0')), numero);
});

test('dates de péremption : périmés / non périmés (comparaison avec maintenant)', async () => {
  const { createExpirationDatesRouter } = require('../src/routes/expiration-dates');
  const get = await monter(() => createExpirationDatesRouter({ prisma, authService: {} }));
  const perimes = await get('/?estPerime=true&limit=50');
  assert.strictEqual(perimes.statut, 200, perimes.texte.slice(0, 300));
  assert.deepStrictEqual(lettres(perimes.texte, 'LOT-'), ['A', 'B'], 'seuls les lots dont la date est passée');
  const valides = await get('/?estPerime=false&limit=50');
  assert.deepStrictEqual(lettres(valides.texte, 'LOT-'), ['C', 'D', 'E']);
});

test('dates de péremption : alertes par niveau', async () => {
  const { createExpirationDatesRouter } = require('../src/routes/expiration-dates');
  const get = await monter(() => createExpirationDatesRouter({ prisma, authService: {} }));
  const perime = await get('/alertes?niveauAlerte=perime&limit=50');
  assert.strictEqual(perime.statut, 200, perime.texte.slice(0, 300));
  assert.deepStrictEqual(lettres(perime.texte, 'LOT-'), ['A', 'B']);
  const critique = await get('/alertes?niveauAlerte=critique&limit=50');
  assert.deepStrictEqual(lettres(critique.texte, 'LOT-'), ['C'], 'dans les 7 jours');
  const avert = await get('/alertes?niveauAlerte=avertissement&limit=50');
  assert.deepStrictEqual(lettres(avert.texte, 'LOT-'), ['C', 'D'], 'dans les 30 jours');
});

test('analyse des ventes par produit : seules les ventes de la période du 5 au 22 sont comptées', async () => {
  const createSalesRouter = require('../src/routes/sales');
  const get = await monter(() => createSalesRouter({ prisma, authService: {}, syncService: null }));
  const r = await get(`/analytics/products?${requete}`);
  assert.strictEqual(r.statut, 200, r.texte.slice(0, 300));
  // quantités vendues : B 10 + C 100 + D 1000 = 1110 (et non 11111 comme si toutes les ventes étaient comptées)
  const g = JSON.parse(r.texte).data.statistiquesGlobales;
  assert.strictEqual(g.quantiteTotaleVendue, 1110);
  assert.strictEqual(g.nombreTransactionsTotal, 3);
});

test('tableau de bord d une boutique : chiffre d affaires, nombre de ventes et mouvements de la période du 5 au 22', async () => {
  const { createBoutiquesRouter } = require('../src/routes/boutiques');
  const get = await monter(() => createBoutiquesRouter({ prisma, authService: {}, syncService: null }));
  const r = await get(`/1/dashboard?${requete}`);
  assert.strictEqual(r.statut, 200, r.texte.slice(0, 300));
  const d = JSON.parse(r.texte).data;
  assert.strictEqual(d.nbVentes, 3);
  assert.strictEqual(d.chiffreAffaires, 30);
  assert.strictEqual(d.totalMouvementsFinanciers, 300);
});
