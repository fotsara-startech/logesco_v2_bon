/**
 * Migration complète : isolation des données par boutique
 * 1. Ajoute boutique_id aux tables qui ne l'ont pas
 * 2. Migre toutes les données existantes (null) vers la boutique principale
 */
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  console.log('🚀 === MIGRATION ISOLATION BOUTIQUE ===\n');

  // Trouver la boutique principale
  const principale = await prisma.boutique.findFirst({ where: { estPrincipale: true } });
  if (!principale) {
    console.error('❌ Aucune boutique principale trouvée !');
    process.exit(1);
  }
  const pid = principale.id;
  console.log(`✅ Boutique principale: ${principale.nom} (ID: ${pid})\n`);

  // ── ÉTAPE 1 : Ajouter boutique_id aux tables qui ne l'ont pas ──────────────

  const toAdd = [
    { table: 'cash_movements',              fk: 'boutiques(id)' },
    { table: 'cash_sessions',               fk: 'boutiques(id)' },
    { table: 'commandes_approvisionnement', fk: 'boutiques(id)' },
  ];

  console.log('── Étape 1 : Ajout des colonnes boutique_id ──');
  for (const { table, fk } of toAdd) {
    const cols = await prisma.$queryRawUnsafe(`PRAGMA table_info(${table})`);
    if (cols.some(c => c.name === 'boutique_id')) {
      console.log(`  ⏭️  ${table} : colonne déjà présente`);
    } else {
      await prisma.$executeRawUnsafe(`ALTER TABLE ${table} ADD COLUMN boutique_id INTEGER REFERENCES ${fk}`);
      try {
        await prisma.$executeRawUnsafe(`CREATE INDEX IF NOT EXISTS idx_${table}_boutique ON ${table}(boutique_id)`);
      } catch (_) {}
      console.log(`  ✅ ${table} : boutique_id ajouté`);
    }
  }

  // ── ÉTAPE 2 : Migrer toutes les lignes null vers la boutique principale ─────

  console.log('\n── Étape 2 : Migration des données vers la boutique principale ──');

  const migrations = [
    'mouvements_stock',
    'ventes',
    'cash_movements',
    'cash_registers',
    'cash_sessions',
    'commandes_approvisionnement',
    'financial_movements',
  ];

  for (const table of migrations) {
    try {
      const result = await prisma.$executeRawUnsafe(
        `UPDATE ${table} SET boutique_id = ${pid} WHERE boutique_id IS NULL`
      );
      console.log(`  ✅ ${table} : ${result} ligne(s) migrée(s) → boutique ${pid}`);
    } catch (e) {
      console.log(`  ⚠️  ${table} : ${e.message}`);
    }
  }

  // ── ÉTAPE 3 : Vérification finale ──────────────────────────────────────────

  console.log('\n── Étape 3 : Vérification ──');
  for (const table of migrations) {
    try {
      const nulls = await prisma.$queryRawUnsafe(`SELECT COUNT(*) as n FROM ${table} WHERE boutique_id IS NULL`);
      const total = await prisma.$queryRawUnsafe(`SELECT COUNT(*) as n FROM ${table}`);
      const ok = nulls[0].n === 0 || nulls[0].n === '0';
      console.log(`  ${ok ? '✅' : '❌'} ${table} : ${total[0].n} total, ${nulls[0].n} null restants`);
    } catch (e) {
      console.log(`  ⚠️  ${table} : ${e.message}`);
    }
  }

  console.log('\n✅ Migration terminée !');
  await prisma.$disconnect();
}

run().catch(e => { console.error('❌', e.message); process.exit(1); });
