/**
 * Ajoute tous les stock_boutiques et stock locaux dans la sync_queue
 * pour qu'ils soient poussés vers Neon au prochain cycle de synchronisation
 */

require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');

async function run() {
  const prisma = new PrismaClient();

  try {
    console.log('📋 Ajout des stocks dans la sync_queue...\n');

    // stock_boutiques
    const stockBoutiques = await prisma.$queryRawUnsafe('SELECT * FROM stock_boutiques');
    let queued = 0;
    for (const row of stockBoutiques) {
      const data = {
        id: row.id,
        boutique_id: row.boutique_id ?? row.boutiqueId,
        produit_id: row.produit_id ?? row.produitId,
        quantite_disponible: row.quantite_disponible ?? row.quantiteDisponible,
        quantite_reservee: row.quantite_reservee ?? row.quantiteReservee ?? 0,
        derniere_maj: (row.derniere_maj ?? row.derniereMaj ?? new Date()).toISOString?.() ?? row.derniere_maj
      };
      try {
        await prisma.$executeRawUnsafe(
          `INSERT INTO sync_queue (table_name, operation, record_id, data, synced)
           VALUES (?, ?, ?, ?, 0)`,
          'stock_boutiques', 'UPDATE', String(row.id), JSON.stringify(data)
        );
        queued++;
      } catch (e) {
        // Ignorer les doublons
      }
    }
    console.log(`✅ stock_boutiques: ${queued}/${stockBoutiques.length} entrées ajoutées à la queue`);

    // stock global
    const stocks = await prisma.$queryRawUnsafe('SELECT * FROM stock');
    queued = 0;
    for (const row of stocks) {
      const data = {
        id: row.id,
        produit_id: row.produit_id ?? row.produitId,
        quantite_disponible: row.quantite_disponible ?? row.quantiteDisponible,
        quantite_reservee: row.quantite_reservee ?? row.quantiteReservee ?? 0,
        derniere_maj: (row.derniere_maj ?? row.derniereMaj ?? new Date()).toISOString?.() ?? row.derniere_maj
      };
      try {
        await prisma.$executeRawUnsafe(
          `INSERT INTO sync_queue (table_name, operation, record_id, data, synced)
           VALUES (?, ?, ?, ?, 0)`,
          'stock', 'UPDATE', String(row.id), JSON.stringify(data)
        );
        queued++;
      } catch (e) {
        // Ignorer les doublons
      }
    }
    console.log(`✅ stock global: ${queued}/${stocks.length} entrées ajoutées à la queue`);

    // Vérifier la queue
    const total = await prisma.$queryRawUnsafe(
      'SELECT COUNT(*) as count FROM sync_queue WHERE synced = 0'
    );
    console.log(`\n📊 Total en attente dans la queue: ${total[0].count}`);
    console.log('ℹ️  Les stocks seront poussés vers Neon au prochain cycle de sync (30s)');

  } finally {
    await prisma.$disconnect();
  }
}

run().catch(e => { console.error('❌', e.message); process.exit(1); });
