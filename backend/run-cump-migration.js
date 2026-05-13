/**
 * Migration CUMP via Prisma raw
 */
const { PrismaClient } = require('@prisma/client');

async function run() {
  const prisma = new PrismaClient();

  const createTable = `
    CREATE TABLE IF NOT EXISTS historique_prix_achat (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      produit_id INTEGER NOT NULL,
      prix_achat REAL NOT NULL,
      source TEXT NOT NULL DEFAULT 'manuel',
      reference_id INTEGER,
      date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (produit_id) REFERENCES produits(id) ON DELETE CASCADE
    )`;

  try {
    try {
      await prisma.$executeRawUnsafe('ALTER TABLE produits ADD COLUMN cump REAL');
      console.log('✅ Colonne cump ajoutée');
    } catch(e) { console.log('⚠️  cump déjà existant'); }

    await prisma.$executeRawUnsafe(createTable);
    console.log('✅ Table historique_prix_achat créée');

    try {
      await prisma.$executeRawUnsafe('CREATE INDEX IF NOT EXISTS idx_historique_prix_achat_produit ON historique_prix_achat(produit_id)');
      await prisma.$executeRawUnsafe('CREATE INDEX IF NOT EXISTS idx_historique_prix_achat_date ON historique_prix_achat(date_creation)');
      console.log('✅ Index créés');
    } catch(e) { console.log('⚠️  index:', e.message); }

    const r1 = await prisma.$executeRawUnsafe(
      "INSERT INTO historique_prix_achat (produit_id, prix_achat, source) SELECT id, prix_achat, 'manuel' FROM produits WHERE prix_achat IS NOT NULL AND prix_achat > 0"
    );
    console.log('✅ Historique initialisé:', r1, 'entrées');

    const r2 = await prisma.$executeRawUnsafe(
      'UPDATE produits SET cump = prix_achat WHERE prix_achat IS NOT NULL AND prix_achat > 0'
    );
    console.log('✅ CUMP initialisé:', r2, 'produits');

    console.log('\n🎉 Migration CUMP terminée!');
  } catch(e) {
    console.error('❌ Erreur:', e.message);
  } finally {
    await prisma.$disconnect();
  }
}

run();
