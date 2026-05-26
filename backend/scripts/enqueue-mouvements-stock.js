/**
 * Enqueue tous les mouvements de stock locaux manquants sur Neon
 */
require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');
const { Pool } = require('pg');

async function run() {
  const prisma = new PrismaClient();
  const pool = new Pool({
    connectionString: process.env.CLOUD_DB_URL,
    ssl: { rejectUnauthorized: false },
    max: 1,
    connectionTimeoutMillis: 8000,
  });

  try {
    const client = await pool.connect();

    // IDs existants sur Neon
    const neonIds = await client.query('SELECT id FROM mouvements_stock');
    const neonSet = new Set(neonIds.rows.map(r => r.id));
    client.release();

    // Mouvements locaux manquants sur Neon
    const localMvts = await prisma.$queryRawUnsafe('SELECT * FROM mouvements_stock');
    const missing = localMvts.filter(m => !neonSet.has(m.id));

    console.log(`📊 Local: ${localMvts.length}, Neon: ${neonSet.size}, Manquants: ${missing.length}`);

    // Ajouter dans la sync_queue
    let queued = 0;
    for (const mvt of missing) {
      const data = {
        id: mvt.id,
        produit_id: mvt.produit_id ?? mvt.produitId,
        boutique_id: mvt.boutique_id ?? mvt.boutiqueId ?? null,
        type_mouvement: mvt.type_mouvement ?? mvt.typeMouvement,
        changement_quantite: mvt.changement_quantite ?? mvt.changementQuantite,
        reference_id: mvt.reference_id ?? mvt.referenceId ?? null,
        type_reference: mvt.type_reference ?? mvt.typeReference ?? null,
        date_mouvement: (mvt.date_mouvement ?? mvt.dateMouvement ?? new Date()).toISOString?.() ?? mvt.date_mouvement,
        notes: mvt.notes ?? null
      };
      await prisma.$executeRawUnsafe(
        'INSERT INTO sync_queue (table_name, operation, record_id, data, synced) VALUES (?, ?, ?, ?, 0)',
        'mouvements_stock', 'INSERT', String(mvt.id), JSON.stringify(data)
      );
      queued++;
    }

    console.log(`✅ ${queued} mouvements de stock ajoutés à la sync_queue`);
    await pool.end();
  } catch (e) {
    console.error('❌', e.message);
    // Si Neon inaccessible, enqueuer tous les mouvements récents (30 derniers jours)
    const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    const mvts = await prisma.$queryRawUnsafe(
      `SELECT * FROM mouvements_stock WHERE date_mouvement > ? ORDER BY id DESC`, since
    );
    let queued = 0;
    for (const mvt of mvts) {
      const data = {
        id: mvt.id,
        produit_id: mvt.produit_id ?? mvt.produitId,
        boutique_id: mvt.boutique_id ?? mvt.boutiqueId ?? null,
        type_mouvement: mvt.type_mouvement ?? mvt.typeMouvement,
        changement_quantite: mvt.changement_quantite ?? mvt.changementQuantite,
        reference_id: mvt.reference_id ?? mvt.referenceId ?? null,
        type_reference: mvt.type_reference ?? mvt.typeReference ?? null,
        date_mouvement: (mvt.date_mouvement ?? mvt.dateMouvement ?? new Date()).toISOString?.() ?? mvt.date_mouvement,
        notes: mvt.notes ?? null
      };
      try {
        await prisma.$executeRawUnsafe(
          'INSERT INTO sync_queue (table_name, operation, record_id, data, synced) VALUES (?, ?, ?, ?, 0)',
          'mouvements_stock', 'INSERT', String(mvt.id), JSON.stringify(data)
        );
        queued++;
      } catch (_) {}
    }
    console.log(`✅ ${queued} mouvements récents ajoutés à la sync_queue (mode offline)`);
  } finally {
    await prisma.$disconnect();
  }
}

run().catch(e => { console.error(e.message); process.exit(1); });
