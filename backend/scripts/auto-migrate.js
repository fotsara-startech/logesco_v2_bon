/**
 * Script de migration automatique pour clients
 * Intégré dans le build de production
 * Peut être exécuté de façon autonome
 */

const path = require('path');
const fs = require('fs');

// Trouver le dossier backend
const backendDir = __dirname.includes('scripts') 
  ? path.join(__dirname, '..')
  : __dirname;

// Charger le .env
const envPath = path.join(backendDir, '.env');
if (fs.existsSync(envPath)) {
  require('dotenv').config({ path: envPath });
}

// Déterminer le chemin de la base de données
const dataDir = process.env.LOGESCO_DATA_DIR || backendDir;
const dbPath = path.join(dataDir, 'database', 'logesco.db').replace(/\\/g, '/');
const dbUrl = process.env.DATABASE_URL || `file:${dbPath}`;

// Vérifier que la DB existe
if (dbUrl.startsWith('file:')) {
  const filePath = dbUrl.replace(/^file:/, '').split('?')[0];
  if (!fs.existsSync(filePath)) {
    console.error('❌ Base de données introuvable:', filePath);
    process.exit(1);
  }
}

// Initialiser Prisma avec la bonne DATABASE_URL
process.env.DATABASE_URL = dbUrl;

let prisma;
try {
  const { PrismaClient } = require('@prisma/client');
  prisma = new PrismaClient({
    datasources: {
      db: { url: dbUrl }
    }
  });
} catch (error) {
  console.error('❌ Erreur lors de l\'initialisation de Prisma:', error.message);
  console.error('   Vérifiez que tous les fichiers nécessaires sont présents.');
  process.exit(1);
}

// ── Fonctions utilitaires ────────────────────────────────────────────────

async function columnExists(table, column) {
  try {
    const rows = await prisma.$queryRawUnsafe(`PRAGMA table_info(${table})`);
    return rows.some(r => r.name === column);
  } catch {
    return false;
  }
}

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

// ── Fonction principale ───────────────────────────────────────────────────

async function main() {
  console.log('🚀 Migration automatique LOGESCO\n');
  console.log(`📂 Base de données: ${dbUrl}\n`);

  let migrationsApplied = 0;

  try {
    // Test de connexion
    await prisma.$queryRaw`SELECT 1`;
    console.log('✅ Connexion à la base de données établie\n');
  } catch (error) {
    console.error('❌ Impossible de se connecter à la base de données');
    console.error('   Erreur:', error.message);
    process.exit(1);
  }

  // ── 1. stock_boutiques.date_modification ─────────────────────────────────
  console.log('📋 Vérification de stock_boutiques...');
  try {
    const sb = await addColumnIfMissing('stock_boutiques', 'date_modification', 'DATETIME');
    if (sb) {
      migrationsApplied++;
      await prisma.$executeRawUnsafe(`UPDATE stock_boutiques SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL`);
      await createIndexIfMissing('idx_stock_boutiques_date_modification', 'stock_boutiques', 'date_modification');
    }
  } catch (e) {
    console.warn('  ⚠️  Erreur:', e.message);
  }

  // ── 2. mouvements_stock ──────────────────────────────────────────────────
  console.log('📋 Vérification de mouvements_stock...');
  try {
    if (await addColumnIfMissing('mouvements_stock', 'stock_initial', 'INTEGER', 0)) migrationsApplied++;
    if (await addColumnIfMissing('mouvements_stock', 'stock_final', 'INTEGER', 0)) migrationsApplied++;
    const ms = await addColumnIfMissing('mouvements_stock', 'date_modification', 'DATETIME');
    if (ms) {
      migrationsApplied++;
      await createIndexIfMissing('idx_mouvements_stock_date_modification', 'mouvements_stock', 'date_modification');
    }
    await createIndexIfMissing('idx_mouvements_stock_initial', 'mouvements_stock', 'stock_initial');
    await createIndexIfMissing('idx_mouvements_stock_final', 'mouvements_stock', 'stock_final');
  } catch (e) {
    console.warn('  ⚠️  Erreur:', e.message);
  }

  // ── 3. produits.image_url ─────────────────────────────────────────────────
  console.log('📋 Vérification de produits...');
  try {
    if (await addColumnIfMissing('produits', 'image_url', 'TEXT')) migrationsApplied++;
  } catch (e) {
    console.warn('  ⚠️  Erreur:', e.message);
  }

  // ── 4. stock.date_modification ────────────────────────────────────────────
  console.log('📋 Vérification de stock...');
  try {
    const st = await addColumnIfMissing('stock', 'date_modification', 'DATETIME');
    if (st) {
      migrationsApplied++;
      await prisma.$executeRawUnsafe(`UPDATE stock SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL`);
      await createIndexIfMissing('idx_stock_date_modification', 'stock', 'date_modification');
    }
  } catch (e) {
    console.warn('  ⚠️  Erreur:', e.message);
  }

  // ── 5. comptes_fournisseurs.date_modification ────────────────────────────
  console.log('📋 Vérification de comptes_fournisseurs...');
  try {
    const cf = await addColumnIfMissing('comptes_fournisseurs', 'date_modification', 'DATETIME');
    if (cf) {
      migrationsApplied++;
      await prisma.$executeRawUnsafe(`UPDATE comptes_fournisseurs SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL`);
      await createIndexIfMissing('idx_comptes_fournisseurs_date_modification', 'comptes_fournisseurs', 'date_modification');
    }
  } catch (e) {
    console.warn('  ⚠️  Erreur:', e.message);
  }

  // ── 6. comptes_clients.date_modification ─────────────────────────────────
  console.log('📋 Vérification de comptes_clients...');
  try {
    const cc = await addColumnIfMissing('comptes_clients', 'date_modification', 'DATETIME');
    if (cc) {
      migrationsApplied++;
      await prisma.$executeRawUnsafe(`UPDATE comptes_clients SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL`);
      await createIndexIfMissing('idx_comptes_clients_date_modification', 'comptes_clients', 'date_modification');
    }
  } catch (e) {
    console.warn('  ⚠️  Erreur:', e.message);
  }

  // ── 7. cash_sessions.date_modification ───────────────────────────────────
  console.log('📋 Vérification de cash_sessions...');
  try {
    const cs = await addColumnIfMissing('cash_sessions', 'date_modification', 'DATETIME');
    if (cs) {
      migrationsApplied++;
      await prisma.$executeRawUnsafe(`UPDATE cash_sessions SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL`);
      await createIndexIfMissing('idx_cash_sessions_date_modification', 'cash_sessions', 'date_modification');
    }
  } catch (e) {
    console.warn('  ⚠️  Erreur:', e.message);
  }

  // ── 8. cash_movements.date_modification ──────────────────────────────────
  console.log('📋 Vérification de cash_movements...');
  try {
    const cm = await addColumnIfMissing('cash_movements', 'date_modification', 'DATETIME');
    if (cm) {
      migrationsApplied++;
      await prisma.$executeRawUnsafe(`UPDATE cash_movements SET date_modification = CURRENT_TIMESTAMP WHERE date_modification IS NULL`);
      await createIndexIfMissing('idx_cash_movements_date_modification', 'cash_movements', 'date_modification');
    }
  } catch (e) {
    console.warn('  ⚠️  Erreur:', e.message);
  }

  // ── 9. transferts_stock.date_modification ────────────────────────────────
  console.log('📋 Vérification de transferts_stock...');
  try {
    const ts = await addColumnIfMissing('transferts_stock', 'date_modification', 'DATETIME');
    if (ts) {
      migrationsApplied++;
      await createIndexIfMissing('idx_transferts_stock_date_modification', 'transferts_stock', 'date_modification');
    }
  } catch (e) {
    console.warn('  ⚠️  Erreur:', e.message);
  }

  // ── 10. transactions_comptes.date_modification ───────────────────────────
  console.log('📋 Vérification de transactions_comptes...');
  try {
    const tc = await addColumnIfMissing('transactions_comptes', 'date_modification', 'DATETIME');
    if (tc) {
      migrationsApplied++;
      await createIndexIfMissing('idx_transactions_date_modification', 'transactions_comptes', 'date_modification');
    }
  } catch (e) {
    console.warn('  ⚠️  Erreur:', e.message);
  }

  // ── 11-17. Tables restantes ───────────────────────────────────────────────
  const remainingTables = [
    'stock_inventories',
    'inventory_items',
    'historique_prix_achat',
    'commandes_approvisionnement',
    'details_commandes_approvisionnement',
    'ventes',
    'details_ventes'
  ];

  for (const table of remainingTables) {
    console.log(`📋 Vérification de ${table}...`);
    try {
      if (await addColumnIfMissing(table, 'date_modification', 'DATETIME')) {
        migrationsApplied++;
      }
    } catch (e) {
      console.warn(`  ⚠️  Erreur sur ${table}:`, e.message);
    }
  }

  // ── Résumé ────────────────────────────────────────────────────────────────
  console.log('\n' + '='.repeat(60));
  if (migrationsApplied > 0) {
    console.log(`✅ ${migrationsApplied} migration(s) appliquée(s) avec succès`);
  } else {
    console.log('✅ Toutes les migrations sont déjà appliquées');
  }
  console.log('='.repeat(60));
  console.log('\n✅ Migration terminée. Vous pouvez redémarrer LOGESCO.\n');
}

// ── Exécution ─────────────────────────────────────────────────────────────

main()
  .catch(error => {
    console.error('\n❌ Erreur critique lors de la migration:');
    console.error('   ', error.message);
    console.error('\n   Détails:', error.stack);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
