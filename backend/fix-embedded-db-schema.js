/**
 * Correction complète du schéma de la base embarquée
 * Ajoute toutes les tables et colonnes manquantes
 */

const path = require('path');
const { PrismaClient } = require('@prisma/client');

const dbPath = path.join(process.env.LOCALAPPDATA, 'LOGESCO', 'backend', 'database', 'logesco.db');
const databaseUrl = `file:${dbPath}`;

console.log('📂 Base de données:', dbPath);

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: databaseUrl
    }
  }
});

async function fixSchema() {
  try {
    console.log('🔧 Correction du schéma...\n');

    // 1. Créer la table operation_log si elle n'existe pas
    console.log('=== Table operation_log ===');
    const hasOpLog = await prisma.$queryRaw`
      SELECT name FROM sqlite_master WHERE type='table' AND name='operation_log'
    `;
    
    if (!hasOpLog || hasOpLog.length === 0) {
      console.log('Création de la table operation_log...');
      await prisma.$executeRaw`
        CREATE TABLE operation_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operation_id TEXT NOT NULL UNIQUE,
          operation_type TEXT NOT NULL,
          table_name TEXT NOT NULL,
          record_id INTEGER,
          data TEXT,
          timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          synced_at DATETIME,
          status TEXT NOT NULL DEFAULT 'pending',
          error_message TEXT,
          device_id TEXT,
          user_id INTEGER
        )
      `;
      console.log('✅ Table operation_log créée');
      
      // Créer les index
      await prisma.$executeRaw`CREATE INDEX idx_operation_log_status_timestamp ON operation_log(status, timestamp)`;
      await prisma.$executeRaw`CREATE INDEX idx_operation_log_table_timestamp ON operation_log(table_name, timestamp)`;
      await prisma.$executeRaw`CREATE INDEX idx_operation_log_operation_id ON operation_log(operation_id)`;
      console.log('✅ Index créés');
    } else {
      console.log('✅ Table operation_log existe déjà');
    }

    // 2. Ajouter date_modification aux tables qui en ont besoin
    const tablesToFix = [
      'inventory_items',
      'stock_inventories',
      'transactions_comptes',
      'details_ventes',
      'mouvements_stock',
      'details_commandes_approvisionnement',
      'details_ventes_proforma'
    ];

    for (const table of tablesToFix) {
      console.log(`\n=== Table ${table} ===`);
      const columns = await prisma.$queryRaw`SELECT name FROM pragma_table_info(${table})`;
      const columnNames = columns.map(c => c.name);
      
      if (!columnNames.includes('date_modification')) {
        console.log(`Ajout de date_modification à ${table}...`);
        // SQLite n'accepte pas CURRENT_TIMESTAMP dans ALTER TABLE
        // On ajoute NULL puis on met à jour
        await prisma.$executeRawUnsafe(
          `ALTER TABLE ${table} ADD COLUMN date_modification DATETIME`
        );
        // Mettre à jour les lignes existantes avec une date
        await prisma.$executeRawUnsafe(
          `UPDATE ${table} SET date_modification = datetime('now') WHERE date_modification IS NULL`
        );
        console.log(`✅ Colonne ajoutée à ${table}`);
      } else {
        console.log(`✅ date_modification existe déjà dans ${table}`);
      }
    }

    // 3. Vérifier les autres colonnes critiques
    console.log('\n=== Vérification des autres colonnes ===');
    
    // Stock
    const stockCols = await prisma.$queryRaw`SELECT name FROM pragma_table_info('stock')`;
    const stockColNames = stockCols.map(c => c.name);
    if (!stockColNames.includes('date_modification')) {
      await prisma.$executeRaw`ALTER TABLE stock ADD COLUMN date_modification DATETIME`;
      console.log('✅ date_modification ajoutée à stock');
    }

    // comptes_clients
    const comptesCols = await prisma.$queryRaw`SELECT name FROM pragma_table_info('comptes_clients')`;
    const comptesColNames = comptesCols.map(c => c.name);
    if (!comptesColNames.includes('date_modification')) {
      await prisma.$executeRaw`ALTER TABLE comptes_clients ADD COLUMN date_modification DATETIME`;
      console.log('✅ date_modification ajoutée à comptes_clients');
    }

    // comptes_fournisseurs
    const comptesFournCols = await prisma.$queryRaw`SELECT name FROM pragma_table_info('comptes_fournisseurs')`;
    const comptesFournColNames = comptesFournCols.map(c => c.name);
    if (!comptesFournColNames.includes('date_modification')) {
      await prisma.$executeRaw`ALTER TABLE comptes_fournisseurs ADD COLUMN date_modification DATETIME`;
      console.log('✅ date_modification ajoutée à comptes_fournisseurs');
    }

    // produits - image_url
    const produitsCols = await prisma.$queryRaw`SELECT name FROM pragma_table_info('produits')`;
    const produitsColNames = produitsCols.map(c => c.name);
    if (!produitsColNames.includes('image_url')) {
      await prisma.$executeRaw`ALTER TABLE produits ADD COLUMN image_url TEXT`;
      console.log('✅ image_url ajoutée à produits');
    }

    console.log('\n✅ Toutes les corrections ont été appliquées !');
    console.log('🎉 Le backend embarqué est maintenant à jour');

  } catch (error) {
    console.error('\n❌ Erreur:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

fixSchema();
