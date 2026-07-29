/**
 * Fix complet : ajoute date_modification à TOUTES les tables qui en manquent
 * Compare chaque table de la DB avec le schéma Prisma
 */

const path = require('path');
const { PrismaClient } = require('@prisma/client');

const dbPath = path.join(process.env.LOCALAPPDATA, 'LOGESCO', 'backend', 'database', 'logesco.db');

const prisma = new PrismaClient({
  datasources: { db: { url: `file:${dbPath}` } }
});

// Toutes les tables de la base SQLite
async function getAllTables() {
  const rows = await prisma.$queryRaw`
    SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_prisma_%'
    ORDER BY name
  `;
  return rows.map(r => r.name);
}

async function getTableColumns(table) {
  const cols = await prisma.$queryRaw`SELECT name FROM pragma_table_info(${table})`;
  return cols.map(c => c.name);
}

async function addColumn(table, col, type) {
  try {
    await prisma.$executeRawUnsafe(`ALTER TABLE "${table}" ADD COLUMN "${col}" ${type}`);
    // Remplir les lignes existantes avec une date
    if (type === 'DATETIME') {
      await prisma.$executeRawUnsafe(
        `UPDATE "${table}" SET "${col}" = datetime('now') WHERE "${col}" IS NULL`
      );
    }
    return true;
  } catch (e) {
    console.error(`  ❌ ${table}.${col}: ${e.message}`);
    return false;
  }
}

async function main() {
  console.log('📂 DB:', dbPath);
  console.log('🔍 Scan de toutes les tables...\n');

  const tables = await getAllTables();
  console.log(`📋 ${tables.length} tables trouvées:`, tables.join(', '), '\n');

  let fixed = 0;

  for (const table of tables) {
    const cols = await getTableColumns(table);

    // Toute table avec date_creation devrait aussi avoir date_modification
    if (cols.includes('date_creation') && !cols.includes('date_modification')) {
      console.log(`⚠️  ${table}: date_modification manquante`);
      const ok = await addColumn(table, 'date_modification', 'DATETIME');
      if (ok) { console.log(`  ✅ Ajoutée`); fixed++; }
    }

    // Certaines tables n'ont pas date_creation mais ont besoin de date_modification
    // (détectées via les erreurs Prisma)
    const needsDateMod = [
      'commandes_approvisionnement',
      'details_commandes_approvisionnement',
      'details_ventes',
      'details_ventes_proforma',
      'mouvements_stock',
      'transferts_stock',
      'inventory_items',
      'stock_inventories',
      'transactions_comptes',
      'comptes_clients',
      'comptes_fournisseurs',
      'stock',
      'stock_boutiques',
      'ventes',
      'ventes_proforma',
      'cash_movements',
      'cash_registers',
      'cash_sessions',
      'boutiques',
      'categories',
      'dates_peremption',
      'financial_movements',
      'historique_prix_achat',
      'historique_recus',
      'parametres_entreprise',
      'utilisateurs',
    ];

    if (needsDateMod.includes(table) && !cols.includes('date_modification')) {
      console.log(`⚠️  ${table}: date_modification manquante`);
      const ok = await addColumn(table, 'date_modification', 'DATETIME');
      if (ok) { console.log(`  ✅ Ajoutée`); fixed++; }
    }
  }

  if (fixed === 0) {
    console.log('✅ Aucune colonne manquante détectée');
  } else {
    console.log(`\n✅ ${fixed} colonne(s) ajoutée(s)`);
  }

  // Vérification finale : tester les requêtes critiques
  console.log('\n=== Tests de vérification ===');
  const tests = [
    { name: 'commandes_approvisionnement', fn: () => prisma.commandeApprovisionnement.findFirst() },
    { name: 'produits', fn: () => prisma.produit.findFirst() },
    { name: 'clients', fn: () => prisma.client.findFirst() },
    { name: 'stock_inventories', fn: () => prisma.stockInventory.findFirst() },
  ];

  for (const test of tests) {
    try {
      await test.fn();
      console.log(`  ✅ ${test.name} OK`);
    } catch (e) {
      console.log(`  ❌ ${test.name}: ${e.message.split('\n')[0]}`);
    }
  }

  await prisma.$disconnect();
}

main().catch(e => { console.error(e); process.exit(1); });
