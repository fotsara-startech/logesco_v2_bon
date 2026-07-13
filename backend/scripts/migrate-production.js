/**
 * Script de migration de production - LOGESCO
 * Applique toutes les colonnes manquantes de façon idempotente.
 * Sûr à relancer plusieurs fois.
 *
 * Usage : node scripts/migrate-production.js
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Vérifie si une colonne existe dans une table SQLite
async function columnExists(table, column) {
  const rows = await prisma.$queryRawUnsafe(`PRAGMA table_info(${table})`);
  return rows.some(r => r.name === column);
}

// Applique un ALTER TABLE seulement si la colonne est absente
async function addColumnIfMissing(table, column, type, defaultValue = null) {
  const exists = await columnExists(table, column);
  if (exists) {
    console.log(`  ✅ ${table}.${column} — déjà présent`);
    return false;
  }
  const def = defaultValue !== null ? ` DEFAULT ${defaultValue}` : '';
  await prisma.$executeRawUnsafe(`ALTER TABLE ${table} ADD COLUMN ${column} ${type}${def}`);
  console.log(`  ➕ ${table}.${column} — ajouté`);
  return true;
}

async function createIndexIfMissing(name, table, column) {
  await prisma.$executeRawUnsafe(
    `CREATE INDEX IF NOT EXISTS ${name} ON ${table}(${column})`
  );
}

async function main() {
  console.log('🚀 Migration de production LOGESCO\n');

  // ── 1. stock_boutiques.date_modification ─────────────────────────────────
  console.log('📋 stock_boutiques...');
  const sb = await addColumnIfMissing('stock_boutiques', 'date_modification', 'DATETIME');
  if (sb) {
    await prisma.$executeRawUnsafe(`UPDATE stock_boutiques SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL`);
    await createIndexIfMissing('idx_stock_boutiques_date_modification', 'stock_boutiques', 'date_modification');
  }

  // ── 2. mouvements_stock : stock_initial, stock_final, date_modification ──
  console.log('📋 mouvements_stock...');
  await addColumnIfMissing('mouvements_stock', 'stock_initial', 'INTEGER', 0);
  await addColumnIfMissing('mouvements_stock', 'stock_final', 'INTEGER', 0);
  const ms = await addColumnIfMissing('mouvements_stock', 'date_modification', 'DATETIME');
  if (ms) {
    await createIndexIfMissing('idx_mouvements_stock_date_modification', 'mouvements_stock', 'date_modification');
  }
  await createIndexIfMissing('idx_mouvements_stock_initial', 'mouvements_stock', 'stock_initial');
  await createIndexIfMissing('idx_mouvements_stock_final', 'mouvements_stock', 'stock_final');

  // ── 3. produits.image_url ─────────────────────────────────────────────────
  console.log('📋 produits...');
  await addColumnIfMissing('produits', 'image_url', 'TEXT');

  // ── 4. stock.date_modification ────────────────────────────────────────────
  console.log('📋 stock...');
  const st = await addColumnIfMissing('stock', 'date_modification', 'DATETIME');
  if (st) {
    await prisma.$executeRawUnsafe(`UPDATE stock SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL`);
    await createIndexIfMissing('idx_stock_date_modification', 'stock', 'date_modification');
  }

  // ── 5. comptes_fournisseurs.date_modification ────────────────────────────
  console.log('📋 comptes_fournisseurs...');
  const cf = await addColumnIfMissing('comptes_fournisseurs', 'date_modification', 'DATETIME');
  if (cf) {
    await prisma.$executeRawUnsafe(`UPDATE comptes_fournisseurs SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL`);
    await createIndexIfMissing('idx_comptes_fournisseurs_date_modification', 'comptes_fournisseurs', 'date_modification');
  }

  // ── 6. comptes_clients.date_modification ─────────────────────────────────
  console.log('📋 comptes_clients...');
  const cc = await addColumnIfMissing('comptes_clients', 'date_modification', 'DATETIME');
  if (cc) {
    await prisma.$executeRawUnsafe(`UPDATE comptes_clients SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL`);
    await createIndexIfMissing('idx_comptes_clients_date_modification', 'comptes_clients', 'date_modification');
  }

  // ── 7. cash_sessions.date_modification ───────────────────────────────────
  console.log('📋 cash_sessions...');
  const cs = await addColumnIfMissing('cash_sessions', 'date_modification', 'DATETIME');
  if (cs) {
    await prisma.$executeRawUnsafe(`UPDATE cash_sessions SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL`);
    await createIndexIfMissing('idx_cash_sessions_date_modification', 'cash_sessions', 'date_modification');
  }

  // ── 8. cash_movements.date_modification ──────────────────────────────────
  console.log('📋 cash_movements...');
  const cm = await addColumnIfMissing('cash_movements', 'date_modification', 'DATETIME');
  if (cm) {
    await prisma.$executeRawUnsafe(`UPDATE cash_movements SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL`);
    await createIndexIfMissing('idx_cash_movements_date_modification', 'cash_movements', 'date_modification');
  }

  // ── 9. transferts_stock.date_modification ────────────────────────────────
  console.log('📋 transferts_stock...');
  const ts = await addColumnIfMissing('transferts_stock', 'date_modification', 'DATETIME');
  if (ts) {
    await createIndexIfMissing('idx_transferts_stock_date_modification', 'transferts_stock', 'date_modification');
  }

  // ── 10. transactions_comptes.date_modification ───────────────────────────
  console.log('📋 transactions_comptes...');
  const tc = await addColumnIfMissing('transactions_comptes', 'date_modification', 'DATETIME');
  if (tc) {
    await createIndexIfMissing('idx_transactions_date_modification', 'transactions_comptes', 'date_modification');
  }

  // ── 11. stock_inventories.date_modification ──────────────────────────────
  console.log('📋 stock_inventories...');
  await addColumnIfMissing('stock_inventories', 'date_modification', 'DATETIME');

  // ── 12. inventory_items.date_modification ────────────────────────────────
  console.log('📋 inventory_items...');
  await addColumnIfMissing('inventory_items', 'date_modification', 'DATETIME');

  // ── 13. historique_prix_achat.date_modification ──────────────────────────
  console.log('📋 historique_prix_achat...');
  await addColumnIfMissing('historique_prix_achat', 'date_modification', 'DATETIME');

  // ── 14. commandes_approvisionnement.date_modification ────────────────────
  console.log('📋 commandes_approvisionnement...');
  await addColumnIfMissing('commandes_approvisionnement', 'date_modification', 'DATETIME');

  // ── 15. details_commandes_approvisionnement.date_modification ────────────
  console.log('📋 details_commandes_approvisionnement...');
  await addColumnIfMissing('details_commandes_approvisionnement', 'date_modification', 'DATETIME');

  // ── 16. ventes.date_modification ─────────────────────────────────────────
  console.log('📋 ventes...');
  await addColumnIfMissing('ventes', 'date_modification', 'DATETIME');

  // ── 17. details_ventes.date_modification ─────────────────────────────────
  console.log('📋 details_ventes...');
  await addColumnIfMissing('details_ventes', 'date_modification', 'DATETIME');

  console.log('\n✅ Migration terminée. Redémarre le backend.\n');
}

main()
  .catch(e => {
    console.error('\n❌ Erreur migration:', e.message);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
