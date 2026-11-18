/**
 * Met à 0 la quantité disponible de TOUS les produits (stock global ET
 * stock par boutique), pour un test. Reproduit exactement ce que fait la
 * route POST /inventory/movements (type "ajustement") pour chaque ligne de
 * stock concernée :
 *   - crée un MouvementStock avec les snapshots stockInitial/stockFinal,
 *   - met à jour Stock ou StockBoutique à 0.
 *
 * Utilise le même DatabaseManager que le serveur (src/config/database.js),
 * donc les hooks de synchronisation Prisma ($extends dans
 * prisma-sync-hooks.js) s'appliquent normalement si CLOUD_DB_URL est
 * configuré : chaque mouvement et chaque mise à jour de stock est journalisé
 * pour la synchro cloud comme s'il venait de l'API, pas de la triche.
 *
 * Les produits "service" (estService = true) n'ont pas de stock et sont
 * ignorés.
 *
 * À lancer avec l'application LOGESCO complètement fermée (le fichier
 * SQLite ne doit pas être ouvert par un autre processus).
 *
 * Utilisation :
 *   node scripts/zero-all-stock.js                          (base locale par défaut, .env)
 *   node scripts/zero-all-stock.js --db "C:\chemin\vers\logesco.db"
 *   node scripts/zero-all-stock.js --dry-run
 */
const path = require('path');

function parseArgs() {
  const args = process.argv.slice(2);
  const dbIndex = args.indexOf('--db');
  const dbPath = dbIndex !== -1 ? args[dbIndex + 1] : null;
  const dryRun = args.includes('--dry-run');
  return { dbPath, dryRun };
}

async function main() {
  const { dbPath, dryRun } = parseArgs();

  require('dotenv').config({ path: path.join(__dirname, '../.env') });
  if (dbPath) {
    process.env.DATABASE_URL = `file:${path.resolve(dbPath)}`;
  }

  const databaseManager = require('../src/config/database');
  const prisma = await databaseManager.initialize();

  try {
    const produits = await prisma.produit.findMany({
      where: { estService: false },
      include: { stock: true, stocksBoutiques: true }
    });

    let nbStockGlobal = 0;
    let nbStockBoutique = 0;

    for (const produit of produits) {
      // ── Stock global ───────────────────────────────────────────────
      if (produit.stock && produit.stock.quantiteDisponible !== 0) {
        const stockInitial = produit.stock.quantiteDisponible;
        nbStockGlobal++;
        console.log(`[global] ${produit.nom} (#${produit.id}): ${stockInitial} -> 0`);

        if (!dryRun) {
          await prisma.$transaction(async (tx) => {
            await tx.mouvementStock.create({
              data: {
                produitId: produit.id,
                boutiqueId: null,
                typeMouvement: 'ajustement',
                changementQuantite: -stockInitial,
                stockInitial,
                stockFinal: 0,
                notes: 'Mise à zéro pour test (zero-all-stock.js)',
                typeReference: 'ajustement'
              }
            });
            await tx.stock.update({
              where: { produitId: produit.id },
              data: { quantiteDisponible: 0 }
            });
          });
        }
      }

      // ── Stock par boutique ─────────────────────────────────────────
      for (const sb of produit.stocksBoutiques) {
        if (sb.quantiteDisponible === 0) continue;
        const stockInitial = sb.quantiteDisponible;
        nbStockBoutique++;
        console.log(`[boutique ${sb.boutiqueId}] ${produit.nom} (#${produit.id}): ${stockInitial} -> 0`);

        if (!dryRun) {
          await prisma.$transaction(async (tx) => {
            await tx.mouvementStock.create({
              data: {
                produitId: produit.id,
                boutiqueId: sb.boutiqueId,
                typeMouvement: 'ajustement',
                changementQuantite: -stockInitial,
                stockInitial,
                stockFinal: 0,
                notes: 'Mise à zéro pour test (zero-all-stock.js)',
                typeReference: 'ajustement'
              }
            });
            await tx.stockBoutique.update({
              where: { boutiqueId_produitId: { boutiqueId: sb.boutiqueId, produitId: produit.id } },
              data: { quantiteDisponible: 0 }
            });
          });
        }
      }
    }

    console.log(`\n${dryRun ? '🧪 (dry-run) ' : '✅ '}${nbStockGlobal} ligne(s) de stock global et ${nbStockBoutique} ligne(s) de stock boutique mises à 0.`);
  } finally {
    await databaseManager.disconnect();
  }
}

main().catch((e) => {
  console.error('❌ Erreur:', e.message);
  process.exit(1);
});
